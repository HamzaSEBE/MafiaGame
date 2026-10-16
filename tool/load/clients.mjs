import {readFile,writeFile} from 'node:fs/promises';
import {randomUUID} from 'node:crypto';
import {initializeApp,deleteApp} from 'firebase/app';
import {getAuth,signInWithCustomToken,connectAuthEmulator} from 'firebase/auth';
import {getFirestore,connectFirestoreEmulator,doc,collection,query,where,onSnapshot,disableNetwork,enableNetwork,terminate} from 'firebase/firestore';

// Every simulated human owns an authenticated client SDK and live listeners.
// Admin SDK is intentionally absent from measured traffic.
const config=JSON.parse(await readFile(process.env.FIREBASE_CONFIG_FILE,'utf8'));
const seeds=JSON.parse(await readFile(process.env.LOAD_SEEDS_FILE,'utf8'));
const api=process.env.GAME_API_URL;
const local=config.projectId.startsWith('demo-');
if(!local && process.env.LOAD_PROJECT_ACK!==config.projectId)throw Error('LOAD_PROJECT_ACK must name the dedicated staging project');
if(config.projectId==='mafiagame-351f8')throw Error('Production project is excluded');
const shard=Number(process.env.SHARD_INDEX??0),shards=Number(process.env.SHARD_COUNT??1),limit=Number(process.env.CLIENTS_PER_SHARD??1000);
const duration=Number(process.env.DURATION_SECONDS??300),ramp=Number(process.env.CONNECT_PER_SECOND??10),interval=Number(process.env.ACTION_INTERVAL_SECONDS??60);
if(!api || !Number.isInteger(shard)||shard<0||shard>=shards||limit<1||ramp<1||duration<10)throw Error('Invalid load configuration');
const users=seeds.filter((_,i)=>i%shards===shard).slice(0,limit);
const pendingDelays=new Set(),jobs=[];
const clients=[],latencies=[],errors={},metrics={target:users.length,authenticated:0,ready:0,listeners:0,commands:0,accepted:0,snapshots:0,reconnects:0};
let stopping=false;
const pause=ms=>new Promise(resolve=>{const item={timer:null,resolve};item.timer=setTimeout(()=>{pendingDelays.delete(item);resolve();},ms);pendingDelays.add(item);});
function failure(code){errors[code]=(errors[code]??0)+1;}
async function connect(seed,index){
 const app=initializeApp(config,`${shard}-${index}`),auth=getAuth(app),db=getFirestore(app);
 if(local){connectAuthEmulator(auth,`http://${process.env.EMULATOR_HOST??'127.0.0.1'}:9099`,{disableWarnings:true});connectFirestoreEmulator(db,process.env.EMULATOR_HOST??'127.0.0.1',8085);}
 const client={app,auth,db,seed,unsub:[],room:null,secret:null,versions:new Map(),ready:false};clients.push(client);
 try{
  await signInWithCustomToken(auth,seed.customToken);metrics.authenticated++;
  const watch=(reference,consume)=>{
   metrics.listeners++;
   client.unsub.push(onSnapshot(reference,{includeMetadataChanges:true},snapshot=>{
    if(snapshot.metadata.fromCache)return;metrics.snapshots++;consume(snapshot);
    if(!client.ready && client.room && (seed.isHost||client.secret)){client.ready=true;metrics.ready++;}
   },error=>failure(`listener:${error.code}`)));
  };
  watch(doc(db,'sessionsV2',seed.sessionId),s=>client.room=s.data());
  if(seed.isHost){
   watch(collection(db,'sessionsV2',seed.sessionId,'seats'),()=>{});
   watch(collection(db,'sessionsV2',seed.sessionId,'actionRequests'),()=>{});
  }else{
   watch(doc(db,'sessionsV2',seed.sessionId,'secrets',seed.seatId),s=>client.secret=s.data());
   watch(collection(db,'sessionsV2',seed.sessionId,'roster'),()=>{});
   watch(query(collection(db,'sessionsV2',seed.sessionId,'actionRequests'),where('uid','==',seed.uid)),s=>{for(const d of s.docs)client.versions.set(`${d.data().revision}:${d.data().actionType}`,d.data().submissionVersion??0);});
   // Jitter avoids an artificial synchronized timer spike.
   const run=async()=>{
    await pause(Math.random()*interval*1000);
    while(!stopping){
     const room=client.room,secret=client.secret,prompt=secret?.requiredActions?.[0];
     if(room?.actionsOpen && prompt?.availableTargets?.length && secret.promptRevision===room.actionRevision){
      const expected=client.versions.get(`${room.actionRevision}:${prompt.type}`)??0;
      if(prompt.type==='vote'||expected===0){
       const start=performance.now();metrics.commands++;
       try{
        const token=await auth.currentUser.getIdToken();
        const headers={'Content-Type':'application/json',Authorization:`Bearer ${token}`};
        if(process.env.APP_CHECK_TOKEN)headers['X-Firebase-AppCheck']=process.env.APP_CHECK_TOKEN;
        const response=await fetch(`${api}/v2/sessions/${seed.sessionId}/action`,{method:'POST',headers,body:JSON.stringify({protocolVersion:2,commandId:randomUUID(),seatId:seed.seatId,actionType:prompt.type,targetId:prompt.availableTargets[Math.floor(Math.random()*prompt.availableTargets.length)],expectedRevision:room.actionRevision,expectedActionVersion:expected}),signal:AbortSignal.timeout(25000)});
        const result=await response.json();
        if(response.ok){metrics.accepted++;client.versions.set(`${room.actionRevision}:${prompt.type}`,result.submissionVersion);}else failure(`api:${result.code}`);
       }catch(error){failure(error.name??'request');}
       latencies.push(performance.now()-start);
      }
     }
     await pause(interval*1000*(.8+Math.random()*.4));
    }
   };void run();
  }
 }catch(error){failure(`auth:${error.code??error.name}`);}
}
const started=Date.now();
for(let i=0;i<users.length;i++){
 if(stopping)break;
 jobs.push(connect(users[i],i));
 await pause(1000/ramp);
 if(i%100===0)console.log(JSON.stringify({event:'ramp',...metrics}));
}
await Promise.allSettled(jobs);
// Optional reconnect scenario uses the actual SDK transport.
let reconnectTimer;
if(process.env.RECONNECT_PERCENT){reconnectTimer=setTimeout(async()=>{
 const count=Math.ceil(clients.length*Number(process.env.RECONNECT_PERCENT)/100);
 for(const client of clients.slice(0,count)){await disableNetwork(client.db);await pause(250);await enableNetwork(client.db);metrics.reconnects++;await pause(1000/ramp);}
},duration*500);}
await pause(duration*1000);stopping=true;if(reconnectTimer)clearTimeout(reconnectTimer);
for(const item of pendingDelays){clearTimeout(item.timer);item.resolve();}pendingDelays.clear();
for(const client of clients){for(const unsub of client.unsub)unsub();await terminate(client.db);await deleteApp(client.app);}
latencies.sort((a,b)=>a-b);
const percentile=p=>latencies.length?latencies[Math.min(latencies.length-1,Math.floor(latencies.length*p))]:null;
const report={protocolVersion:2,projectId:config.projectId,shard,shards,durationSeconds:(Date.now()-started)/1000,...metrics,errors,latencyMs:{p50:percentile(.5),p95:percentile(.95),p99:percentile(.99)},pass:metrics.ready===metrics.target && metrics.accepted>=metrics.commands*.999 && (percentile(.95)??Infinity)<500};
await writeFile(process.env.REPORT_FILE??`load-report-${shard}.json`,JSON.stringify(report,null,2));console.log(JSON.stringify(report));
process.exitCode=report.pass?0:1;

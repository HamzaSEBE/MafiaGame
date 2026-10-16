import {writeFile} from 'node:fs/promises';
import {initializeApp,applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore,Timestamp} from 'firebase-admin/firestore';
import {randomUUID} from 'node:crypto';
const projectId=process.env.GCLOUD_PROJECT;
if(!projectId || projectId==='mafiagame-351f8' || !(projectId.startsWith('demo-')||projectId.startsWith('mafia-staging-')||projectId.startsWith('mafia-load-')))throw Error('Seed only a dedicated demo, mafia-staging-* or mafia-load-* project');
const count=Number(process.env.TARGET_CLIENTS??21);
if(!Number.isInteger(count)||count<2||count>100000||(!projectId.startsWith('demo-')&&process.env.LOAD_PROJECT_ACK!==projectId))throw Error('Invalid target or staging acknowledgment');
initializeApp(projectId.startsWith('demo-')?{projectId}:{projectId,credential:applicationDefault()});
const db=getFirestore(),auth=getAuth(),seeds=[],at=new Date().toISOString();
for(let base=0;base<count;base+=21){
 const id=`load-${randomUUID()}`,people=Math.min(20,count-base-1);
 if(people<1)break;
 const host=await auth.createUser({uid:`host-${id}`});
 const players=[];for(let n=0;n<people;n++){
  const uid=`player-${id}-${n}`;await auth.createUser({uid});
  players.push({id:`p${n}`,name:`Player ${n}`,role:n===0?'mafiaSheikh':'goodCitizen',isAlive:true,isSilenced:false,hasSniper:false,isCitizenSheikhRevealed:false,createdAt:at,uid});
 }
 const state={id,phase:'voting',round:2,players:players.map(({uid,...p})=>p),eventHistory:[],winner:null,rules:{},initialMafiaCount:1,correctMafiaExecutionsCount:0};
 const response=await fetch(`${process.env.GAME_ENGINE_URL}/reduce`,{method:'POST',headers:{'Content-Type':'application/json',...(process.env.ENGINE_ID_TOKEN?{Authorization:`Bearer ${process.env.ENGINE_ID_TOKEN}`}:{})},body:JSON.stringify({protocolVersion:2,command:'project',commandId:'seed',revision:1,state,actions:[],at})});
 if(!response.ok)throw Error('Engine seed projection failed');const result=await response.json();
 const ref=db.collection('sessionsV2').doc(id),batch=db.batch();
 batch.create(ref,{id,hostUid:host.uid,hostInstanceId:'load-host',hostEpoch:1,leaseUntil:Timestamp.fromMillis(Date.now()+3600000),status:'active',protocolVersion:2,stateVersion:1,actionRevision:1,actionsOpen:true,phase:'voting',round:2,actionsPhase:'voting',actionsRound:2,winner:null,createdAt:Timestamp.now(),expiresAt:Timestamp.fromMillis(Date.now()+86400000)});
 batch.create(ref.collection('hostState').doc('current'),{schemaVersion:1,state:result.state});
 for(const player of players){
  batch.create(ref.collection('seats').doc(player.id),{...result.projection.seats[player.id],linkedUid:player.uid,status:'linked'});
  batch.create(ref.collection('roster').doc(player.id),{...result.projection.seats[player.id],status:'linked'});
  batch.create(ref.collection('secrets').doc(player.id),result.projection.secrets[player.id]);
  batch.create(ref.collection('members').doc(player.uid),{uid:player.uid,seatId:player.id,lastActionAt:0});
 }
 await batch.commit();
 seeds.push({uid:host.uid,sessionId:id,isHost:true,customToken:await auth.createCustomToken(host.uid)});
 for(const player of players)seeds.push({uid:player.uid,seatId:player.id,sessionId:id,customToken:await auth.createCustomToken(player.uid)});
 if(base%210===0)console.log(JSON.stringify({seeded:seeds.length,target:count}));
}
await writeFile(process.env.LOAD_SEEDS_FILE??'seeds.local.json',JSON.stringify(seeds),{mode:0o600});
// Tokens are secret local test credentials; never print them or commit them.
console.log(JSON.stringify({seeded:seeds.length,projectId}));

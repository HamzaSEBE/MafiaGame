import {test,after} from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID,createHash} from 'node:crypto';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {GameService,HttpEngine,Engine} from '../src/game_service.js';
import {ApiError,validateAction} from '../src/contracts.js';
import {drainResults} from '../src/outbox.js';
const integration=process.env.FIRESTORE_EMULATOR_HOST==='127.0.0.1:8085';
const app=integration?initializeApp({projectId:'demo-mafia-review'},'api-test'):null;
const db=app?getFirestore(app):null;
const real=integration?new HttpEngine('http://127.0.0.1:8087'):null;
after(async()=>{if(app)await deleteApp(app);});
function fixture(engine:Engine=real!){
 let now=Date.now(); const service=new GameService(db!,engine,()=>now);
 const id=randomUUID(),host='host-'+id,device='device-'+id;
 const uid=(n:number)=>`user-${id}-${n}`;
 const contract=async()=>{const r=(await service.room(id).get()).data()!;return {hostInstanceId:device,hostEpoch:r.hostEpoch,expectedVersion:r.stateVersion};};
 const advance=async(phase:string,prompts=false,commandId=randomUUID())=>service.transition(host,id,{...await contract(),desiredPhase:phase,hasPrompts:prompts,commandId});
 const create=async(stopAtDay=false)=>{
  const players=['mafiaSheikh','citizensGirl','citizensSheikh','goodCitizen','goodCitizen'].map((role,i)=>({id:`p${i+1}`,name:`player${i+1}`,role}));
  await service.create(host,id,{hostInstanceId:device,state:{players,rules:{}}});
  for(let i=1;i<=5;i++){await service.requestSeat(uid(i),id,{seatId:`p${i}`,displayName:`player${i}`});await service.approve(host,id,{...await contract(),seatId:`p${i}`,playerUid:uid(i)});}
  await advance('roleReveal');await advance('night');await advance('day');if(!stopAtDay)await advance('voting',true);
 };
 return {service,id,host,device,uid,contract,advance,create,tick:()=>now+=200,expire:()=>now+=121000};
}
test('deny stale revision, closed gate and forged target',()=>{
 const room={status:'active',actionsOpen:true,phase:'voting',round:2,actionsPhase:'voting',actionsRound:2,actionRevision:4};
 const seat={id:'a',linkedUid:'u',isAlive:true},secret={promptRevision:4,allowedTargetsByAction:{vote:['b']}},action={expectedRevision:4,actionType:'vote',targetId:'b'};
 validateAction(room,seat,secret,action,'u');
 for(const [r,s,a] of [[{...room,actionsOpen:false},secret,action],[room,secret,{...action,expectedRevision:3}],[room,secret,{...action,targetId:'c'}],[room,{...secret,promptRevision:3},action]] as any)assert.throws(()=>validateAction(r,seat,s,a,'u'),ApiError);
});
test('real engine and Firestore: idempotency, ballot CAS, freeze, checkpoint',{skip:!integration},async()=>{
 const f=fixture();await f.create();const r=(await f.service.room(f.id).get()).data()!;
 const a={seatId:'p4',actionType:'vote',targetId:'p5',expectedRevision:r.actionRevision,expectedActionVersion:0,commandId:randomUUID()};
 const result=await f.service.action(f.uid(4),f.id,a);assert.equal(result.submissionVersion,1);assert.deepEqual(await f.service.action(f.uid(4),f.id,a),result);
 f.tick();await assert.rejects(()=>f.service.action(f.uid(4),f.id,{...a,commandId:randomUUID()}),(e:any)=>e.code==='BALLOT_CONFLICT');
 const frozen=await f.service.freeze(f.host,f.id,{...await f.contract(),expectedRevision:r.actionRevision});assert.equal(frozen.actions.length,1);
 f.tick();await assert.rejects(()=>f.service.action(f.uid(4),f.id,{...a,expectedActionVersion:1,commandId:randomUUID()}),(e:any)=>e.code==='WINDOW_CLOSED');
 const closed=await f.advance('elimination');assert.equal(closed.state.players.find((p:any)=>p.id==='p5').isAlive,false);
 assert.deepEqual((await f.service.room(f.id).collection('hostState').doc('current').get()).data()!.state,closed.state);
 await db!.recursiveDelete(f.service.room(f.id));
});
test('lost engine response recovers via durable intent and old host is fenced',{skip:!integration},async()=>{
 let fail=false;const f=fixture({reduce:async body=>{if(fail){fail=false;throw Error('lost reply');}return real!.reduce(body);}});await f.create();
 const body={...await f.contract(),commandId:randomUUID(),desiredPhase:'voting',hasPrompts:true};fail=true;
 await assert.rejects(()=>f.service.transition(f.host,f.id,body));assert.equal((await f.service.room(f.id).get()).data()!.actionsOpen,false);
 const result=await f.service.transition(f.host,f.id,body);assert.equal(result.room.actionRevision,5);assert.deepEqual(await f.service.transition(f.host,f.id,body),result);
 f.expire();const room=await f.service.claim(f.host,f.id,{hostInstanceId:'new-device'});assert.equal(room.hostEpoch,2);
 const old=await f.contract();await assert.rejects(()=>f.service.freeze(f.host,f.id,{...old,expectedRevision:room.actionRevision}),(e:any)=>e.code==='HOST_LEASE_LOST');
 await db!.recursiveDelete(f.service.room(f.id));
});
test('new host adopts a pending transition after lease expiry',{skip:!integration},async()=>{
 let fail=false;const f=fixture({reduce:async body=>{if(fail){fail=false;throw Error('engine down');}return real!.reduce(body);}});await f.create();const commandId=randomUUID();fail=true;
 const body={...await f.contract(),commandId,desiredPhase:'voting',hasPrompts:true};await assert.rejects(()=>f.service.transition(f.host,f.id,body));
 f.expire();const r=await f.service.claim(f.host,f.id,{hostInstanceId:'adopter'});
 const result=await f.service.transition(f.host,f.id,{...body,hostInstanceId:'adopter',hostEpoch:r.hostEpoch,expectedVersion:r.stateVersion});assert.equal(result.room.hostEpoch,2);assert.equal(result.room.pendingTransition,undefined);
 await db!.recursiveDelete(f.service.room(f.id));
});
test('concurrent host commands commit one transition',{skip:!integration},async()=>{
 const f=fixture();await f.create();const base=await f.contract();
 const results=await Promise.allSettled([1,2].map(()=>f.service.transition(f.host,f.id,{...base,commandId:randomUUID(),desiredPhase:'voting',hasPrompts:true})));
 assert.equal(results.filter(r=>r.status==='fulfilled').length,1);await db!.recursiveDelete(f.service.room(f.id));
});
test('concurrent result deliveries increment stats once',{skip:!integration},async()=>{
 const f=fixture();await f.create();const r=(await f.service.room(f.id).get()).data()!;
 await f.service.action(f.uid(4),f.id,{seatId:'p4',actionType:'vote',targetId:'p1',expectedRevision:r.actionRevision,expectedActionVersion:0,commandId:randomUUID()});
 await f.service.freeze(f.host,f.id,{...await f.contract(),expectedRevision:r.actionRevision});const result=await f.advance('winCheck');assert.equal(result.state.winner,'citizens');
 await Promise.all([drainResults(db!,real!),drainResults(db!,real!)]);const stats=(await db!.collection('users').doc(f.host).collection('stats').doc('player4').get()).data()!;
 assert.equal(stats.gamesPlayed,1);assert.equal(stats.citizenWins,1);
 const account=db!.collection('users').doc(f.host),careerRef=account.collection('stats').doc('career');
 const career=(await careerRef.get()).data()!;assert.equal(career.gamesPlayed,1);assert.equal(career.citizenWins,1);
 const summary=account.collection('games').doc(f.id),detail=account.collection('gameDetails').doc(f.id);
 assert.deepEqual(Object.keys((await summary.get()).data()!).sort(),['date','id','playerCount','schemaVersion','winningTeam']);
 assert.equal((await detail.get()).data()!.players.length,5);
 const receipt=account.collection('resultReceipts').doc(createHash('sha256').update(`${f.host}/${f.id}`).digest('hex'));
 assert.deepEqual((await receipt.get()).data(),{processed:true});
 // A delayed delivery after deletion must not restore the report or counters.
 await summary.delete();await detail.delete();
 const event=(await f.service.room(f.id).collection('outbox').get()).docs[0];
 assert.ok(event);
 await event.ref.update({status:'pending',state:result.state});await drainResults(db!,real!);
 assert.equal((await summary.get()).exists,false);assert.equal((await detail.get()).exists,false);
 assert.deepEqual((await careerRef.get()).data(),career);
 await db!.recursiveDelete(f.service.room(f.id));await db!.recursiveDelete(account);
});

test('discussion clock persists, fences stale hosts and preserves prompt revision',{skip:!integration},async()=>{
 const f=fixture();await f.create(true);const base=await f.contract(),before=(await f.service.room(f.id).get()).data()!;
 const paused=await f.service.clock(f.host,f.id,{...base,remainingSeconds:42,paused:true});
 assert.equal(paused.state.discussionDeadlineAt,null);assert.equal(paused.state.discussionPaused,true);
 assert.equal(paused.state.discussionRemainingSeconds,42);assert.equal(paused.room.actionRevision,before.actionRevision);
 await assert.rejects(()=>f.service.clock(f.host,f.id,{...base,remainingSeconds:60,paused:false}),(e:any)=>e.code==='STALE_STATE');
 const resumed=await f.service.clock(f.host,f.id,{...await f.contract(),remainingSeconds:90,paused:false});
 assert.equal(Date.parse(resumed.state.discussionDeadlineAt)-Date.now()>80000,true);
 assert.deepEqual((await f.service.room(f.id).collection('hostState').doc('current').get()).data()!.state,resumed.state);
 await db!.recursiveDelete(f.service.room(f.id));
});

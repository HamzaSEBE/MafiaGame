import { createHash } from 'node:crypto';
import { Firestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { Engine } from './game_service.js';
import { Json, protocolVersion } from './contracts.js';

function statsId(name:string):string {
  if(!name || name==='.' || name==='..' || name.includes('/') || name.startsWith('__encoded__')) return '__encoded__'+Buffer.from(name).toString('base64url')+( '='.repeat((4-Buffer.from(name).toString('base64url').length%4)%4));
  return name;
}
/** An immutable game marker makes repeated deliveries harmless. */
export async function drainResults(db:Firestore,engine:Engine,limit=20) {
  const pending=await db.collectionGroup('outbox').where('type','==','gameFinished').where('status','==','pending').limit(limit).get();
  let completed=0;
  for(const document of pending.docs) {
    const message=document.data();
    const computed=await engine.reduce({protocolVersion,command:'project',state:message.state,actions:[],revision:0,at:new Date().toISOString(),commandId:'result'});
    const account=db.collection('users').doc(message.hostUid),marker=account.collection('gameResultsV2').doc(message.gameId);
    const receipt=account.collection('resultReceipts').doc(createHash('sha256').update(`${message.hostUid}/${message.gameId}`).digest('hex'));
    await db.runTransaction(async tx=>{
      const [existing,event,processed]=await Promise.all([tx.get(marker),tx.get(document.ref),tx.get(receipt)]);
      if(event.data()?.status!=='pending')return;
      if(!existing.exists && !processed.exists) {
        tx.set(account.collection('gameDetails').doc(message.gameId),{id:message.gameId,date:message.createdAt.toDate().toISOString(),winningTeam:message.state.winner,players:message.state.players.map((p:Json)=>({name:p.name,roleName:p.role,team:['mafiaSheikh','mafiaGirl','normalMafia'].includes(p.role)?'mafia':p.role==='joker'?'independent':'citizens'})),newspaperText:'',gameStateJson:message.state});
        tx.set(account.collection('games').doc(message.gameId),{schemaVersion:2,id:message.gameId,date:message.createdAt.toDate().toISOString(),winningTeam:message.state.winner,playerCount:message.state.players.length});
        for(const [name,counters] of Object.entries(computed.resultStats as Record<string,Json>)) tx.set(account.collection('stats').doc(statsId(name)),{name,...Object.fromEntries(Object.entries(counters).map(([key,value])=>[key,FieldValue.increment(value)]))},{merge:true});
        tx.set(account.collection('stats').doc('career'),{gamesPlayed:FieldValue.increment(1),...(message.state.winner==='mafia'?{mafiaWins:FieldValue.increment(1)}:message.state.winner==='citizens'?{citizenWins:FieldValue.increment(1)}:{})},{merge:true});
        tx.create(receipt,{processed:true});
      }
      tx.update(document.ref,{status:'delivered',deliveredAt:Timestamp.now(),state:FieldValue.delete()});
    });
    completed++;
  }
  return {completed};
}

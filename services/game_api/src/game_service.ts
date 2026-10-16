import { randomUUID } from 'node:crypto';
import { Firestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import { GoogleAuth } from 'google-auth-library';
import { ApiError, Json, protocolVersion, requireValue, roomLimit, safeId, validateAction, transitionCommand } from './contracts.js';

export interface Engine { reduce(body: Json): Promise<Json>; }
export class HttpEngine implements Engine {
  private auth = new GoogleAuth();
  constructor(private url: string) {
    const parsed = new URL(url);
    requireValue(parsed.protocol === 'https:' || (process.env.FIRESTORE_EMULATOR_HOST && ['localhost','127.0.0.1'].includes(parsed.hostname)), 500, 'INSECURE_ENGINE_URL');
  }
  async reduce(body: Json): Promise<Json> {
    const headers: Record<string,string> = {'Content-Type':'application/json'};
    if (!process.env.FIRESTORE_EMULATOR_HOST) {
      const client = await this.auth.getIdTokenClient(this.url);
      const authHeaders = await client.getRequestHeaders();
      headers.Authorization = authHeaders.get('authorization')!;
    }
    const response = await fetch(`${this.url}/reduce`, {method:'POST',headers, body:JSON.stringify(body), signal:AbortSignal.timeout(15000)});
    requireValue(response.ok, response.status === 400 ? 409 : 503, 'ENGINE_UNAVAILABLE');
    return await response.json() as Json;
  }
}

/** Firestore coordination with no process-local authoritative game state. */
export class GameService {
  constructor(readonly db: Firestore, readonly engine: Engine, private now = () => Date.now()) {}
  room(id: string) { safeId(id); return this.db.collection('sessionsV2').doc(id); }
  private assertHost(room: Json, uid: string, body: Json) {
    requireValue(room,404,'ROOM_NOT_FOUND');
    requireValue(room.hostUid === uid,403,'NOT_HOST');
    requireValue(room.hostInstanceId === body.hostInstanceId && room.hostEpoch === body.hostEpoch && room.leaseUntil.toMillis() > this.now(),409,'HOST_LEASE_LOST');
    requireValue(room.stateVersion === body.expectedVersion,409,'STALE_STATE');
  }
  async create(uid: string, id: string, body: Json): Promise<Json> {
    safeId(body.hostInstanceId);
    const raw = body.state;
    requireValue(raw && Array.isArray(raw.players) && raw.players.length >= 5 && raw.players.length <= roomLimit);
    requireValue(new Set(raw.players.map((p: Json) => p.id)).size === raw.players.length);
    const roles = ['mafiaSheikh','mafiaGirl','normalMafia','citizensSheikh','citizensGirl','citizensBoy','goodCitizen','joker'];
    const players = raw.players.map((p: Json) => {
      safeId(p.id); requireValue(typeof p.name === 'string' && p.name.trim().length > 0 && p.name.length <= 80 && roles.includes(p.role));
      return {id:p.id, name:p.name.trim(), role:p.role, isAlive:true, isSilenced:false, hasSniper:p.hasSniper === true && !['mafiaSheikh','mafiaGirl','normalMafia','joker'].includes(p.role), isCitizenSheikhRevealed:false, createdAt:new Date(this.now()).toISOString()};
    });
    const mafia = players.filter((p: Json) => ['mafiaSheikh','mafiaGirl','normalMafia'].includes(p.role)).length;
    requireValue(mafia > 0 && mafia < players.length);
    const state = {id, phase:'roleReveal', round:1, players, rules:raw.rules ?? {}, eventHistory:[], winner:null, initialMafiaCount:mafia, correctMafiaExecutionsCount:0, victoryReason:null};
    const result = await this.engine.reduce({protocolVersion,state,command:'project',revision:0,at:new Date(this.now()).toISOString(),commandId:'create'});
    const ref = this.room(id);
    return this.db.runTransaction(async tx => {
      const [existing, account, profile] = await Promise.all([tx.get(ref), tx.get(this.db.collection('users').doc(uid).collection('settings').doc('activeSession')), tx.get(this.db.collection('users').doc(uid))]);
      if (existing.exists) { requireValue(existing.data()!.hostUid === uid,403); return existing.data()!; }
      if (account.exists && account.data()!.sessionId !== id) {
        const active = await tx.get(this.room(account.data()!.sessionId));
        requireValue(!active.exists || active.data()!.status === 'finished' || active.data()!.expiresAt.toMillis() <= this.now(),409,'ACTIVE_ROOM_EXISTS');
      }
      const themeId=body.themeId??'dark_blood';
      requireValue(['dark_blood','midnight_blue','emerald_shadow','royal_gold'].includes(themeId));
      const grant=profile.data()?.entitlements;
      const premium=Object.hasOwn(profile.data()??{},'entitlements') ? grant && grant.schemaVersion===1 && grant.status==='active' && Array.isArray(grant.features) && grant.features.every((f:unknown)=>typeof f==='string') && grant.features.includes('themes') && (grant.expiresAt==null || (typeof grant.expiresAt==='string' && Date.parse(grant.expiresAt)>this.now())) : profile.data()?.isPremium===true;
      requireValue(themeId==='dark_blood'||premium,403,'THEME_NOT_ENTITLED');
      const room = {sharedThemeId:themeId,themeVersion:1,id, protocolVersion,hostUid:uid,status:'waiting',phase:'roleReveal',round:1,actionRevision:0,stateVersion:0,hostEpoch:1,hostInstanceId:body.hostInstanceId,leaseUntil:Timestamp.fromMillis(this.now()+120000),actionsOpen:false,actionsPhase:null,actionsRound:null,winner:null,createdAt:Timestamp.fromMillis(this.now()),expiresAt:Timestamp.fromMillis(this.now()+86400000),globalAnnouncement:null};
      tx.create(ref,room);
      tx.set(ref.collection('hostState').doc('current'),{schemaVersion:1,state:result.state});
      tx.set(this.db.collection('users').doc(uid).collection('settings').doc('activeSession'),{sessionId:id,protocolVersion});
      for (const player of players) {
        tx.create(ref.collection('seats').doc(player.id),{...result.projection.seats[player.id],status:'unlinked',linkedUid:null});
        tx.create(ref.collection('roster').doc(player.id),{...result.projection.seats[player.id],status:'unlinked'});
        tx.create(ref.collection('secrets').doc(player.id),{id:player.id,role:null,promptRevision:0,requiredActions:[],allowedTargetsByAction:{}});
      }
      return room;
    });
  }
  async claim(uid: string, id: string, body: Json): Promise<Json> {
    safeId(body.hostInstanceId);
    return this.db.runTransaction(async tx => {
      const ref=this.room(id), snapshot=await tx.get(ref), room=snapshot.data();
      requireValue(room && room.hostUid === uid,403,'NOT_HOST');
      requireValue(room.status !== 'finished' && room.expiresAt.toMillis() > this.now(),410,'ROOM_EXPIRED');
      const same = room.hostInstanceId === body.hostInstanceId;
      requireValue(same || room.leaseUntil.toMillis() <= this.now() || body.takeOver === true,409,'HOST_BUSY');
      const pendingRef = room.pendingTransition ? ref.collection('transitions').doc(room.pendingTransition) : null;
      const pending = pendingRef ? await tx.get(pendingRef) : null;
      const next = {...room,hostInstanceId:body.hostInstanceId,hostEpoch:same ? room.hostEpoch : room.hostEpoch+1,leaseUntil:Timestamp.fromMillis(this.now()+120000)};
      if (!same && pendingRef && pending?.data()?.status === 'pending') tx.update(pendingRef, {hostEpoch: next.hostEpoch});
      tx.update(ref,{hostInstanceId:next.hostInstanceId,hostEpoch:next.hostEpoch,leaseUntil:next.leaseUntil});
      return next;
    });
  }
  async requestSeat(uid: string,id:string,body:Json) {
    safeId(body.seatId); requireValue(typeof body.displayName==='string' && body.displayName.trim().length>0 && body.displayName.length<=80);
    const ref=this.room(id);
    await this.db.runTransaction(async tx=>{
      const [room,seat,member,old]=await Promise.all([tx.get(ref),tx.get(ref.collection('seats').doc(body.seatId)),tx.get(ref.collection('members').doc(uid)),tx.get(ref.collection('joinRequests').doc(uid))]);
      requireValue(room.data()?.status==='waiting' && room.data()!.expiresAt.toMillis()>this.now(),409,'LOBBY_CLOSED');
      requireValue(seat.exists && !seat.data()!.linkedUid && !member.exists,409,'SEAT_UNAVAILABLE');
      requireValue(!old.exists || this.now()-old.data()!.timestamp.toMillis()>=1000,429,'TOO_FAST');
      tx.set(ref.collection('joinRequests').doc(uid),{uid,seatId:body.seatId,displayName:body.displayName.trim(),timestamp:Timestamp.fromMillis(this.now())});
    });
    return {ok:true};
  }
  async approve(uid:string,id:string,body:Json) {
    safeId(body.seatId); safeId(body.playerUid);
    const ref=this.room(id), seatRef=ref.collection('seats').doc(body.seatId),memberRef=ref.collection('members').doc(body.playerUid),requestRef=ref.collection('joinRequests').doc(body.playerUid);
    await this.db.runTransaction(async tx=>{
      const [room,seat,member,request]=await Promise.all([tx.get(ref),tx.get(seatRef),tx.get(memberRef),tx.get(requestRef)]);
      this.assertHost(room.data()!,uid,body);
      requireValue(room.data()!.status==='waiting',409,'LOBBY_CLOSED');
      if (seat.data()?.linkedUid===body.playerUid && member.data()?.seatId===body.seatId) return;
      requireValue(seat.exists && !seat.data()!.linkedUid && !member.exists && request.data()?.seatId===body.seatId,409,'SEAT_UNAVAILABLE');
      tx.update(seatRef,{linkedUid:body.playerUid,status:'linked'});
      tx.update(ref.collection('roster').doc(body.seatId),{status:'linked'});
      tx.create(memberRef,{uid:body.playerUid,seatId:body.seatId,lastActionAt:0});
      tx.delete(requestRef);
    });
    return {ok:true};
  }
  async reject(uid:string,id:string,body:Json) {
    safeId(body.playerUid);
    await this.db.runTransaction(async tx=>{ const room=await tx.get(this.room(id)); this.assertHost(room.data()!,uid,body); tx.delete(this.room(id).collection('joinRequests').doc(body.playerUid)); });
    return {ok:true};
  }
  async action(uid:string,id:string,body:Json):Promise<Json> {
    safeId(body.commandId); safeId(body.seatId); safeId(body.actionType);
    const ref=this.room(id), receiptRef=ref.collection('receipts').doc(`${uid}_${body.commandId}`), actionRef=ref.collection('actionRequests').doc(`${uid}_${body.actionType}`),memberRef=ref.collection('members').doc(uid);
    return this.db.runTransaction(async tx=>{
      const [roomDoc,seatDoc,secretDoc,member,previous,receipt,checkpoint]=await Promise.all([tx.get(ref),tx.get(ref.collection('seats').doc(body.seatId)),tx.get(ref.collection('secrets').doc(body.seatId)),tx.get(memberRef),tx.get(actionRef),tx.get(receiptRef),['citizenSheikhReveal','investigation'].includes(body.actionType)?tx.get(ref.collection('hostState').doc('current')):Promise.resolve(null)]);
      const fingerprint=JSON.stringify([body.seatId,body.actionType,body.targetId,body.expectedRevision,body.expectedActionVersion]);
      if(receipt.exists) { requireValue(receipt.data()!.fingerprint===fingerprint,409,'IDEMPOTENCY_CONFLICT'); return receipt.data()!.result; }
      const room=roomDoc.data(),seat=seatDoc.data(),secret=secretDoc.data();
      requireValue(room && seat && secret && member.data()?.seatId===body.seatId,403,'NOT_A_MEMBER');
      requireValue(room.expiresAt.toMillis()>this.now(),410,'ROOM_EXPIRED');
      validateAction(room,seat,secret,body,uid);
      requireValue(this.now()-(member.data()!.lastActionAt??0)>=150,429,'TOO_FAST');
      const old=previous.data(), same=old?.revision===body.expectedRevision;
      const version=same?(old!.submissionVersion??1):0;
      if(same && body.actionType!=='vote') { requireValue(old!.targetId===body.targetId,409,'ACTION_ALREADY_SUBMITTED'); return {ok:true,submissionVersion:version}; }
      requireValue(Number.isSafeInteger(body.expectedActionVersion) && body.expectedActionVersion===version,409,'BALLOT_CONFLICT');
      const action={id:actionRef.id,uid,seatId:body.seatId,actionType:body.actionType,targetId:body.targetId,revision:body.expectedRevision,submissionVersion:version+1,timestamp:Timestamp.fromMillis(this.now())};
      const result={ok:true,submissionVersion:version+1};
      tx.set(actionRef,action);tx.update(memberRef,{lastActionAt:this.now()});
      tx.create(receiptRef,{fingerprint,result,expiresAt:Timestamp.fromMillis(this.now()+86400000)});
      if(body.actionType==='citizenSheikhReveal') {
        const state=checkpoint!.data()!.state;
        state.players=state.players.map((p:Json)=>p.id===seat.id?{...p,isCitizenSheikhRevealed:true}:p);
        state.eventHistory.push({id:body.commandId,gameId:id,round:room.round,phase:room.phase,type:'citizenSheikhReveal',actorId:seat.id,targetId:null,timestamp:new Date(this.now()).toISOString(),metadata:{}});
        tx.update(ref.collection('hostState').doc('current'),{state});
        tx.update(ref.collection('seats').doc(seat.id),{isCitizenSheikhRevealed:true});tx.update(ref.collection('roster').doc(seat.id),{isCitizenSheikhRevealed:true});
        // A public reveal changes vote weighting; stale host snapshots must fail.
        tx.update(ref,{stateVersion:room.stateVersion+1,globalAnnouncement:`اللاعب ${seat.playerName} كشف هويته كشيخ المواطنين. أصبح صوته بثلاثة أصوات.`});
      }
      if(body.actionType==='investigation') {
        const target=checkpoint!.data()!.state.players.find((p:Json)=>p.id===body.targetId);
        requireValue(target,403,'INVALID_TARGET');
        tx.update(ref.collection('secrets').doc(body.seatId),{privateResult:`اللاعب ${target.name} ${['mafiaSheikh','mafiaGirl','normalMafia'].includes(target.role)?'من المافيا':'من المواطنين'}`});
      }
      return result;
    });
  }
  async freeze(uid:string,id:string,body:Json):Promise<Json> {
    const ref=this.room(id);
    const room=await this.db.runTransaction(async tx=>{
      const current=(await tx.get(ref)).data();requireValue(current,404,'ROOM_NOT_FOUND');this.assertHost(current,uid,body);
      requireValue(current.status==='active' && current.actionsPhase != null && current.actionRevision===body.expectedRevision,409,'STALE_WINDOW');
      if(!current.actionsOpen)return current;
      const next={...current,actionsOpen:false,stateVersion:current.stateVersion+1};tx.update(ref,{actionsOpen:false,stateVersion:next.stateVersion});return next;
    });
    const snapshot=await ref.collection('actionRequests').where('revision','==',body.expectedRevision).limit(roomLimit*9+1).get();
    requireValue(snapshot.size<=roomLimit*9,413,'TOO_MANY_ACTIONS');
    return {room,actions:snapshot.docs.map(d=>({...d.data(),timestamp:d.data().timestamp.toDate().toISOString()}))};
  }
  async transition(uid:string,id:string,body:Json):Promise<Json> {
    safeId(body.commandId);
    const ref=this.room(id), intentRef=ref.collection('transitions').doc(body.commandId);
    const intent: Json=await this.db.runTransaction(async tx=>{
      const [roomDoc,old,checkpoint]=await Promise.all([tx.get(ref),tx.get(intentRef),tx.get(ref.collection('hostState').doc('current'))]);
      const room=roomDoc.data();requireValue(room && checkpoint.exists,404,'ROOM_NOT_FOUND');
      requireValue(room.hostUid===uid,403,'NOT_HOST');
      if(old.exists) { requireValue(old.data()!.hostEpoch===body.hostEpoch && old.data()!.desiredPhase===body.desiredPhase && old.data()!.hasPrompts===!!body.hasPrompts,409,'IDEMPOTENCY_CONFLICT');return old.data()!; }
      this.assertHost(room,uid,body);requireValue(room.status!=='finished',410,'ROOM_FINISHED');
      requireValue(!room.pendingTransition,409,'TRANSITION_PENDING');
      if(room.status==='waiting') { const seats=await tx.get(ref.collection('seats'));requireValue(seats.docs.every(s=>s.data().status==='linked'),409,'UNLINKED_SEATS'); }
      const command=transitionCommand(checkpoint.data()!.state,body.desiredPhase,!!body.hasPrompts);
      const nextVersion=room.stateVersion+1;
      const value={command,desiredPhase:body.desiredPhase,hasPrompts:!!body.hasPrompts,hostEpoch:room.hostEpoch,baseVersion:nextVersion,revision:room.actionRevision,status:'pending',at:new Date(this.now()).toISOString(),state:checkpoint.data()!.state};
      tx.create(intentRef,value);tx.update(ref,{actionsOpen:false,stateVersion:nextVersion,pendingTransition:body.commandId});return value;
    });
    if(intent.status==='committed')return intent.result;
    const frozen=await ref.collection('actionRequests').where('revision','==',intent.revision).limit(roomLimit*9+1).get();
    requireValue(frozen.size<=roomLimit*9,413,'TOO_MANY_ACTIONS');
    const actions=frozen.docs.map(d=>d.data());
    const result=await this.engine.reduce({protocolVersion,state:intent.state,actions,command:intent.command==='retaliation' && !actions.some(a=>a.actionType==='retaliation')?'skipAbility':intent.command,revision:intent.revision+1,at:intent.at,commandId:body.commandId,nightActions:intent.hasPrompts || intent.command==='retaliation'});
    requireValue(Buffer.byteLength(JSON.stringify(result.state))<700000,413,'CHECKPOINT_TOO_LARGE');
    return this.db.runTransaction(async tx=>{
      const [roomDoc,currentIntent,seatsDoc]=await Promise.all([tx.get(ref),tx.get(intentRef),tx.get(ref.collection('seats'))]);
      if(currentIntent.data()!.status==='committed')return currentIntent.data()!.result;
      const room=roomDoc.data()!;
      requireValue(room.hostEpoch===intent.hostEpoch && room.stateVersion===intent.baseVersion && room.pendingTransition===body.commandId,409,'TRANSITION_FENCED');
      const projection=result.projection;
      const patch={status:result.state.phase==='winCheck'?'finished':'active',phase:projection.phase,round:projection.round,winner:projection.winner,actionRevision:intent.revision+1,stateVersion:room.stateVersion+1,actionsOpen:true,actionsPhase:projection.actionsPhase,actionsRound:projection.actionsRound,pendingTransition:FieldValue.delete(),leaseUntil:Timestamp.fromMillis(this.now()+120000)};
      const committedRoom: Json={...room,...patch};delete committedRoom.pendingTransition;
      for(const seat of seatsDoc.docs) {
        const pub=projection.seats[seat.id],priv=projection.secrets[seat.id];
        if(pub.isAlive!==seat.data().isAlive || pub.isCitizenSheikhRevealed!==seat.data().isCitizenSheikhRevealed){tx.update(seat.ref,pub);tx.update(ref.collection('roster').doc(seat.id),pub);}
        if(intent.command==='closeNight') {
          const investigation=actions.find(a=>a.seatId===seat.id && a.actionType==='investigation');
          const target=investigation && intent.state.players.find((p:Json)=>p.id===investigation.targetId);
          if(target)priv.privateResult=`اللاعب ${target.name} ${['mafiaSheikh','mafiaGirl','normalMafia'].includes(target.role)?'من المافيا':'من المواطنين'}`;
        }
        if(intent.command==='openNightActions')priv.privateResult=null;
        tx.set(ref.collection('secrets').doc(seat.id),priv,{merge:true});
      }
      tx.update(ref,patch);tx.set(ref.collection('hostState').doc('current'),{schemaVersion:1,state:result.state});
      const response={room:committedRoom,state:result.state};
      tx.update(intentRef,{status:'committed',result:response,state:FieldValue.delete()});
      if(patch.status==='finished')tx.set(ref.collection('outbox').doc('gameFinished'),{type:'gameFinished',status:'pending',gameId:id,hostUid:uid,state:result.state,createdAt:Timestamp.fromMillis(this.now())});
      return response;
    });
  }
  async clock(uid:string,id:string,body:Json): Promise<Json> {
    requireValue(Number.isSafeInteger(body.remainingSeconds) && body.remainingSeconds>=0 && body.remainingSeconds<=7200 && typeof body.paused==='boolean');
    return this.db.runTransaction(async tx=>{
      const ref=this.room(id),stateRef=ref.collection('hostState').doc('current');
      const [snapshot,checkpoint]=await Promise.all([tx.get(ref),tx.get(stateRef)]);
      const room=snapshot.data();this.assertHost(room!,uid,body);requireValue(room!.phase==='day' && room!.status==='active' && !room!.pendingTransition,409,'WRONG_PHASE');
      const state={...checkpoint.data()!.state,discussionDeadlineAt:body.paused?null:new Date(this.now()+body.remainingSeconds*1000).toISOString(),discussionRemainingSeconds:body.remainingSeconds,discussionPaused:body.paused};
      const patch={stateVersion:room!.stateVersion+1};tx.update(ref,patch);tx.update(stateRef,{state});
      return {room:{...room,...patch},state};
    });
  }
  async end(uid:string,id:string,body:Json) {
    return this.db.runTransaction(async tx=>{const ref=this.room(id),room=(await tx.get(ref)).data();requireValue(room,404);this.assertHost(room,uid,body);tx.update(ref,{status:'finished',actionsOpen:false,actionsPhase:null,actionsRound:null,hostEpoch:room.hostEpoch+1,stateVersion:room.stateVersion+1,expiresAt:Timestamp.fromMillis(this.now()+3600000)});return {ok:true};});
  }
  /** Scheduled, bounded recursive cleanup. TTL deletion alone leaves children. */
  async cleanup(limit=25) {
    const expired=await this.db.collection('sessionsV2').where('expiresAt','<=',Timestamp.fromMillis(this.now())).limit(limit).get();
    for(const room of expired.docs) {
      await this.db.runTransaction(async tx=>{const current=await tx.get(room.ref);if(current.exists)tx.update(room.ref,{status:'finished',actionsOpen:false,hostEpoch:current.data()!.hostEpoch+1});});
      const pending = await room.ref.collection('outbox').where('status','==','pending').limit(1).get();
      if (pending.empty) await this.db.recursiveDelete(room.ref);
    }
    return {deleted:expired.size};
  }
}

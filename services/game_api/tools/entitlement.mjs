import {initializeApp,applicationDefault} from 'firebase-admin/app';
import {getFirestore,Timestamp} from 'firebase-admin/firestore';
import {getAuth} from 'firebase-admin/auth';
const project=process.env.GCLOUD_PROJECT,uid=process.argv[2],expiry=process.argv[3];
if(!project||!uid||!expiry)throw Error('Usage: GCLOUD_PROJECT=project node tools/entitlement.mjs UID ISO_EXPIRY|revoke');
if(!project.startsWith('demo-')&&process.env.ENTITLEMENT_PROJECT_ACK!==project)throw Error('ENTITLEMENT_PROJECT_ACK must match the target project');
initializeApp(project.startsWith('demo-')?{projectId:project}:{projectId:project,credential:applicationDefault()});
if(!project.startsWith('demo-'))await getAuth().getUser(uid);
const revoke=expiry==='revoke';
if(!revoke && (!Number.isFinite(Date.parse(expiry)) || Date.parse(expiry)<=Date.now()))throw Error('A valid future expiry is required');
const db=getFirestore();
await db.runTransaction(async tx=>{
 const profile=db.collection('users').doc(uid),existing=await tx.get(profile);
 if(!existing.exists)throw Error('Profile does not exist; register the account first');
 tx.update(profile,{entitlements:{schemaVersion:1,status:revoke?'revoked':'active',features:revoke?[]:['themes'],expiresAt:revoke?new Date().toISOString():new Date(expiry).toISOString(),source:'manual',revision:(existing.data().entitlements?.revision??0)+1}});
 tx.create(db.collection('entitlementAudit').doc(),{uid,operation:revoke?'revoke':'grant',features:revoke?[]:['themes'],at:Timestamp.now(),source:'manual'});
});
console.log(JSON.stringify({uid,status:revoke?'revoked':'active',project}));

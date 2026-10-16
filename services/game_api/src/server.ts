import { createServer, IncomingMessage } from 'node:http';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getAppCheck } from 'firebase-admin/app-check';
import { getFirestore } from 'firebase-admin/firestore';
import { OAuth2Client } from 'google-auth-library';
import { GameService, HttpEngine } from './game_service.js';
import { ApiError, Json, requireValue, protocolVersion, safeId } from './contracts.js';
import { drainResults } from './outbox.js';

const emulator=!!process.env.FIRESTORE_EMULATOR_HOST;
initializeApp(emulator?{projectId:process.env.GCLOUD_PROJECT??'demo-mafia-review'}:{credential:applicationDefault()});
const engine=new HttpEngine(process.env.GAME_ENGINE_URL??'http://127.0.0.1:8087');
const service=new GameService(getFirestore(),engine);
const allowedOrigins=(process.env.ALLOWED_ORIGINS??'').split(',').filter(Boolean);
const auth=new OAuth2Client();
function serialize(value:any):any {
  if(value && typeof value.toDate==='function')return value.toDate().toISOString();
  if(Array.isArray(value))return value.map(serialize);
  if(value && typeof value==='object')return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,serialize(v)]));
  return value;
}
async function body(request:IncomingMessage):Promise<Json> {
  const chunks:Buffer[]=[];let count=0;
  for await(const chunk of request) { count+=chunk.length;requireValue(count<=900000,413,'PAYLOAD_TOO_LARGE');chunks.push(chunk); }
  try {const data=JSON.parse(Buffer.concat(chunks).toString());requireValue(data && typeof data==='object' && !Array.isArray(data));return data;} catch {throw new ApiError(400,'INVALID_JSON');}
}
const server=createServer(async (request,response)=>{
  const started=performance.now();
  response.setHeader('Content-Type','application/json');response.setHeader('Cache-Control','no-store');
  response.setHeader('Vary','Origin');
  const origin=request.headers.origin;
  if(origin && !allowedOrigins.includes(origin)) { response.writeHead(403);response.end('{"code":"ORIGIN_DENIED"}');return; }
  if(origin)response.setHeader('Access-Control-Allow-Origin',origin);
  response.setHeader('Access-Control-Allow-Headers','Authorization,Content-Type,X-Firebase-AppCheck');response.setHeader('Access-Control-Allow-Methods','POST,OPTIONS,GET');
  if(request.method==='OPTIONS'){response.writeHead(204);response.end();return;}
  let status=200,code='OK';
  try {
    if(request.url==='/health' && request.method==='GET'){response.end(JSON.stringify({ok:true,protocolVersion}));return;}
    requireValue(request.method==='POST',405,'METHOD_NOT_ALLOWED');
    const token=request.headers.authorization?.replace(/^Bearer /,'');requireValue(token,401,'UNAUTHENTICATED');
    if(request.url==='/internal/maintenance') {
      // Scheduler uses its service account's OIDC token; user Firebase tokens
      // cannot invoke cleanup or outbox processing.
      requireValue(process.env.MAINTENANCE_AUDIENCE && process.env.SCHEDULER_SERVICE_ACCOUNT,503,'MAINTENANCE_NOT_CONFIGURED');
      const ticket=await auth.verifyIdToken({idToken:token,audience:process.env.MAINTENANCE_AUDIENCE});
      requireValue(ticket.getPayload()?.email===process.env.SCHEDULER_SERVICE_ACCOUNT,403,'NOT_SCHEDULER');
      const results=await drainResults(service.db,engine);const cleanup=await service.cleanup();response.end(JSON.stringify({...results,...cleanup}));return;
    }
    let uid:string;
    try { uid=(await getAuth().verifyIdToken(token)).uid; } catch { throw new ApiError(401,'INVALID_TOKEN'); }
    if(!emulator) {
      const appToken=request.headers['x-firebase-appcheck'];requireValue(typeof appToken==='string',401,'APP_CHECK_REQUIRED');
      try {await getAppCheck().verifyToken(appToken);}catch{throw new ApiError(401,'INVALID_APP_CHECK');}
    }
    const path=request.url?.match(/^\/v2\/sessions\/([a-zA-Z0-9_-]{1,128})\/(create|claim|join|approve|reject|action|freeze|transition|clock|end)$/);
    requireValue(path,404,'NOT_FOUND');const id=path[1]!;safeId(id);
    const data=await body(request);requireValue(data.protocolVersion===protocolVersion,426,'CLIENT_UPGRADE_REQUIRED');
    const operations:Record<string,()=>Promise<Json>>={
      create:()=>service.create(uid,id,data),claim:()=>service.claim(uid,id,data),join:()=>service.requestSeat(uid,id,data),approve:()=>service.approve(uid,id,data),reject:()=>service.reject(uid,id,data),action:()=>service.action(uid,id,data),freeze:()=>service.freeze(uid,id,data),transition:()=>service.transition(uid,id,data),clock:()=>service.clock(uid,id,data),end:()=>service.end(uid,id,data),
    };
    const result=await operations[path[2]!]!();response.end(JSON.stringify(serialize(result)));
  } catch(error) {
    const problem=error instanceof ApiError?error:new ApiError(503,'SERVICE_UNAVAILABLE');status=problem.status;code=problem.code;
    response.writeHead(status);response.end(JSON.stringify({code,retryable:status>=500 || status===429}));
    if(!(error instanceof ApiError))console.error(JSON.stringify({severity:'ERROR',code,error:String(error)}));
  } finally {
    console.log(JSON.stringify({severity:status>=500?'ERROR':'INFO',event:'request',route:request.url?.split('/').at(-1),status,code,durationMs:Math.round(performance.now()-started)}));
  }
});
server.listen(Number(process.env.PORT??8086),'0.0.0.0');
process.on('SIGTERM',()=>server.close());

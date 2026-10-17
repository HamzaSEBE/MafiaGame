import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const source=readFileSync(new URL('./worker/index.js',import.meta.url),'utf8');
const {createHandler}=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
function setup(){
  const body=Buffer.from('verified-release');
  const asset={size:body.length,sha256:createHash('sha256').update(body).digest('hex'),key:'release-v1',type:'application/vnd.android.package-archive',download:true,filename:'game.apk'};
  const objects=new Map([[asset.key,body]]);let writes=0;
  const env={RELEASE_UPLOAD_KEY:'test-only-key',BUCKET:{async get(key,options){const data=objects.get(key);return data?{body:options?.range?data.subarray(options.range.offset,options.range.offset+options.range.length):data}:null;},async head(key){return objects.has(key)?{size:objects.get(key).length}:null;},async put(key,stream,options){const data=Buffer.from(await new Response(stream).arrayBuffer());assert.equal(createHash('sha256').update(data).digest('hex'),options.sha256);writes++;objects.set(key,data);return {size:data.length};},async delete(key){objects.delete(key);}}};
  return {handler:createHandler({'downloads/game.apk':asset}),env,body,asset,objects,get writes(){return writes;}};
}
test('public APK streams exact bytes with attachment headers; HEAD does not return a body',async()=>{
  const s=setup();const url='https://example.test/downloads/game.apk';
  const response=await s.handler.fetch(new Request(url),s.env);
  assert.equal(response.status,200);assert.deepEqual(Buffer.from(await response.arrayBuffer()),s.body);
  assert.equal(response.headers.get('Content-Disposition'),'attachment; filename="game.apk"');
  const head=await s.handler.fetch(new Request(url,{method:'HEAD'}),s.env);
  assert.equal(head.headers.get('Content-Length'),String(s.body.length));assert.equal(await head.text(),'');
});
test('downloads support resume and reject invalid ranges',async()=>{
  const s=setup(),url='https://example.test/downloads/game.apk';
  const part=await s.handler.fetch(new Request(url,{headers:{Range:'bytes=3-7'}}),s.env);
  assert.equal(part.status,206);assert.deepEqual(Buffer.from(await part.arrayBuffer()),s.body.subarray(3,8));
  const tail=await s.handler.fetch(new Request(url,{headers:{Range:'bytes=-4'}}),s.env);
  assert.deepEqual(Buffer.from(await tail.arrayBuffer()),s.body.subarray(-4));
  for(const range of ['bytes=999-','bytes=8-3','bytes=0-3,5-8','bytes=-0']){
    assert.equal((await s.handler.fetch(new Request(url,{headers:{Range:range}}),s.env)).status,416);
  }
});
test('conditional downloads return 304; changed If-Range returns a full response',async()=>{
  const s=setup(),url='https://example.test/downloads/game.apk';
  assert.equal((await s.handler.fetch(new Request(url,{headers:{'If-None-Match':`"${s.asset.sha256}"`}}),s.env)).status,304);
  assert.equal((await s.handler.fetch(new Request(url,{headers:{'Range':'bytes=3-7','If-Range':'"old"'}}),s.env)).status,200);
});
test('upload is disabled without a secret and unauthorized requests cannot write',async()=>{
  const s=setup(),url='https://example.test/internal/upload';
  assert.equal((await s.handler.fetch(new Request(url,{method:'PUT'}),s.env)).status,404);
  delete s.env.RELEASE_UPLOAD_KEY;
  assert.equal((await s.handler.fetch(new Request(url,{method:'PUT',headers:{'X-Release-Key':'test-only-key'}}),s.env)).status,404);
  assert.equal(s.writes,0);
});
test('authenticated upload is restricted to the manifest, exact size and pinned checksum',async()=>{
  const s=setup(),url='https://example.test/internal/upload';
  const headers={'X-Release-Key':'test-only-key','X-Asset-Path':'downloads/game.apk','Content-Length':String(s.body.length)};
  const request=()=>new Request(url,{method:'PUT',headers,body:s.body});
  assert.equal((await s.handler.fetch(request(),s.env)).status,201);assert.equal(s.writes,1);
  headers['X-Asset-Path']='private-data';assert.equal((await s.handler.fetch(request(),s.env)).status,400);
  headers['X-Asset-Path']='downloads/game.apk';headers['Content-Length']='1';assert.equal((await s.handler.fetch(request(),s.env)).status,400);
});
test('unknown public paths cannot read objects outside the publication manifest',async()=>{
  const s=setup();
  for(const path of ['private','__proto__','constructor','downloads/other.apk'])assert.equal((await s.handler.fetch(new Request('https://example.test/'+path),s.env)).status,404);
});

test('staged upload manifest never changes the public download before promotion',async()=>{
  const s=setup();
  const staged={'downloads/next.apk':{...s.asset,key:'next-key',filename:'next.apk'}};
  const handler=createHandler({'downloads/game.apk':s.asset},{},staged);
  assert.equal((await handler.fetch(new Request('https://example.test/downloads/next.apk'),s.env)).status,404);
  assert.equal((await handler.fetch(new Request('https://example.test/downloads/game.apk'),s.env)).status,200);
  const response=await handler.fetch(new Request('https://example.test/internal/upload',{method:'PUT',body:s.body,
    headers:{'X-Release-Key':'test-only-key','X-Asset-Path':'downloads/next.apk','Content-Length':String(s.body.length)}}),s.env);
  assert.equal(response.status,201);
  assert.equal((await handler.fetch(new Request('https://example.test/downloads/next.apk'),s.env)).status,404);
});

// Build placeholders are filled from the verified, rendered site files.
const ASSETS = /*ASSET_MANIFEST*/ {};
const UPLOADS = /*UPLOAD_MANIFEST*/ {};
const FALLBACK = /*BOOTSTRAP_ASSETS*/ {};

function rangeFor(header, size) {
  if (!header) return null;
  const match = /^bytes=(\d*)-(\d*)$/.exec(header);
  if (!match || (!match[1] && !match[2])) return false;
  let start, end;
  if (!match[1]) {const length=Number(match[2]); if(!Number.isSafeInteger(length)||length<=0)return false;start=Math.max(0,size-length);end=size-1;}
  else {start=Number(match[1]);end=match[2]?Number(match[2]):size-1;}
  if(!Number.isSafeInteger(start)||!Number.isSafeInteger(end)||start<0||start>=size||end<start)return false;
  end=Math.min(end,size-1);
  return {offset:start,length:end-start+1};
}

export function createHandler(assets=ASSETS, fallback=FALLBACK, uploads=Object.keys(UPLOADS).length?UPLOADS:assets) {
  return {
    async fetch(request, env) {
      const url=new URL(request.url);
      if(url.pathname==='/internal/upload') {
        if(!env.RELEASE_UPLOAD_KEY || request.headers.get('X-Release-Key')!==env.RELEASE_UPLOAD_KEY)return new Response('Not found',{status:404});
        if(request.method!=='PUT')return new Response('Method not allowed',{status:405});
        const path=request.headers.get('X-Asset-Path');
        const asset=Object.hasOwn(uploads,path)?uploads[path]:null;
        if(!asset)return new Response('Unknown asset',{status:400});
        if(request.headers.get('Content-Length')!==String(asset.size))return new Response('Wrong size',{status:400});
        const result=await env.BUCKET.put(asset.key,request.body,{
          sha256:asset.sha256,
          httpMetadata:{contentType:asset.type},
        });
        if(result.size!==asset.size){await env.BUCKET.delete(asset.key);return new Response('Wrong stored size',{status:400});}
        return new Response('Stored',{status:201,headers:{'Cache-Control':'no-store'}});
      }
      if(!['GET','HEAD'].includes(request.method))return new Response('Method not allowed',{status:405,headers:{Allow:'GET, HEAD'}});
      let path;
      try{path=decodeURIComponent(url.pathname).replace(/^\//,'');}catch{return new Response('Not found',{status:404});}
      if(path===''||path==='index.html')path='index.html';
      if(path==='mafia'||path==='mafia/')path='mafia.html';
      const asset=Object.hasOwn(assets,path)?assets[path]:null;
      if(!asset)return new Response('Not found',{status:404});
      const etag=`"${asset.sha256}"`;
      const headers=new Headers({'Content-Type':asset.type,'X-Content-Type-Options':'nosniff','ETag':etag,
        'Cache-Control':asset.download?'public, max-age=31536000, immutable':'no-cache',
        'Accept-Ranges':'bytes'});
      if(asset.download)headers.set('Content-Disposition',`attachment; filename="${asset.filename}"`);
      if(request.headers.get('If-None-Match')===etag)return new Response(null,{status:304,headers});
      const rangeHeader=request.headers.get('If-Range') && request.headers.get('If-Range')!==etag?null:request.headers.get('Range');
      const range=rangeFor(rangeHeader,asset.size);
      if(range===false){headers.set('Content-Range',`bytes */${asset.size}`);return new Response(null,{status:416,headers});}
      if(range)headers.set('Content-Range',`bytes ${range.offset}-${range.offset+range.length-1}/${asset.size}`);
      headers.set('Content-Length',String(range?range.length:asset.size));
      if(request.method==='HEAD') {
        const stored=await env.BUCKET.head(asset.key);
        if(!stored && !fallback[path])return new Response('Temporarily unavailable',{status:503,headers:{'Cache-Control':'no-store'}});
        return new Response(null,{status:range?206:200,headers});
      }
      const object=await env.BUCKET.get(asset.key,range?{range}:undefined);
      let body=object?.body;
      if(!object && fallback[path]) {
        const bytes=Uint8Array.from(atob(fallback[path]),c=>c.charCodeAt(0));
        body=range?bytes.slice(range.offset,range.offset+range.length):bytes;
      }
      if(!body)return new Response('Temporarily unavailable',{status:503,headers:{'Cache-Control':'no-store'}});
      return new Response(body,{status:range?206:200,headers});
    },
  };
}
export default createHandler();

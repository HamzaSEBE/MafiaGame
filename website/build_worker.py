#!/usr/bin/env python3
"""Package a small dependency-free Worker; R2 holds the published site files."""
from pathlib import Path
import base64
import hashlib
import json
import mimetypes
import shutil
import sys

ROOT=Path(__file__).resolve().parent

def build():
    dist=ROOT/'dist'
    stage=ROOT/'.site-static'
    if stage.exists():shutil.rmtree(stage)
    shutil.copytree(dist,stage)
    assets={}
    fallback={}
    for file in stage.rglob('*'):
        if not file.is_file() or '.openai' in file.parts:continue
        path=file.relative_to(stage).as_posix()
        data=file.read_bytes()
        mime=mimetypes.guess_type(file.name)[0] or 'application/octet-stream'
        if file.suffix in {'.html','.css','.js','.json','.txt','.xml'}:mime+='; charset=utf-8'
        sha=hashlib.sha256(data).hexdigest()
        assets[path]={'key':f'assets/{sha}/{path}','sha256':sha,'size':len(data),'type':mime}
        if '--bootstrap' in sys.argv and (file.suffix.lower() != '.jpg' or file.name == 'mafia_sheikh.jpg'):
            fallback[path]=base64.b64encode(data).decode()
    meta=json.loads((ROOT/'release.json').read_text())
    path='downloads/'+meta['file']
    assets[path]={'key':'releases/'+meta['sha256']+'/'+meta['file'],'sha256':meta['sha256'],
                  'size':meta['sizeBytes'],'type':'application/vnd.android.package-archive',
                  'download':True,'filename':meta['file']}
    public=json.loads((ROOT/'worker/published-manifest.json').read_text()) if '--stage-release' in sys.argv else assets
    worker=(ROOT/'worker/index.js').read_text().replace('/*ASSET_MANIFEST*/ {}',json.dumps(public,separators=(',',':'))).replace('/*UPLOAD_MANIFEST*/ {}',json.dumps(assets,separators=(',',':'))).replace('/*BOOTSTRAP_ASSETS*/ {}',json.dumps(fallback,separators=(',',':')))

    # Upload manifest is generated locally, never a credential or private account data.
    (stage/'upload-manifest.json').write_text(json.dumps(assets,indent=2))
    shutil.rmtree(dist)
    (dist/'server').mkdir(parents=True)
    (dist/'.openai').mkdir()
    (dist/'server/index.js').write_text(worker)
    shutil.copy2(ROOT/'.openai/hosting.json',dist/'.openai/hosting.json')
    print(f'Worker built: {len(assets)} assets; {len(worker.encode()):,} bytes; bootstrap={bool(fallback)}.')

if __name__=='__main__':build()

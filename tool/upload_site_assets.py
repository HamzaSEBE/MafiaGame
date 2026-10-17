#!/usr/bin/env python3
"""Stream SHA-pinned publication files to Sites R2. Token is hidden stdin only."""
from pathlib import Path
from urllib.request import Request,urlopen
import hashlib,json,sys,termios
ROOT=Path(__file__).resolve().parent.parent

def main():
    if sys.stdin.isatty():
        flags=termios.tcgetattr(sys.stdin.fileno());flags[3]&=~termios.ECHO
        termios.tcsetattr(sys.stdin.fileno(),termios.TCSANOW,flags)
    print('Ready for upload token on hidden stdin.',flush=True)
    token=sys.stdin.readline().strip()
    if not token:raise RuntimeError('Missing upload token')
    stage=ROOT/'website/.site-static'
    manifest=json.loads((stage/'upload-manifest.json').read_text())
    published_path=ROOT/'website/worker/published-manifest.json'
    published=json.loads(published_path.read_text()) if published_path.exists() else {}
    # Seed visual assets first; the bootstrap keeps the main pages available.
    for path,meta in sorted(manifest.items(),key=lambda item:item[1].get('download',False)):
        if '--force' not in sys.argv and published.get(path,{}).get('key')==meta['key']:
            print('Already published:',path,flush=True)
            continue
        source=ROOT/'releases'/meta['filename'] if meta.get('download') else stage/path
        with source.open('rb') as stream:assert hashlib.file_digest(stream,'sha256').hexdigest()==meta['sha256']
        with source.open('rb') as stream:
            request=Request('https://mafia-alshawareb.wavygrass32.chatgpt.site/internal/upload',data=stream,method='PUT',headers={
                'X-Release-Key':token,'X-Asset-Path':path,'Content-Length':str(meta['size']),
                'Content-Type':'application/octet-stream','User-Agent':'Mafia-release-verification'})
            with urlopen(request,timeout=60) as response:assert response.status==201
        print('Stored and checksum-verified:',path,flush=True)
    token=None
if __name__=='__main__':main()

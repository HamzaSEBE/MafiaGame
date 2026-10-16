#!/usr/bin/env python3
"""Package the static website without dependencies, servers or browsers."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parent
FILES = ('index.html', 'styles.css', 'app.js', 'robots.txt', 'sitemap.xml', 'release.json')

class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids, self.links, self.headings = set(), [], []
        self.main_count = 0

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if 'id' in a:
            assert a['id'] not in self.ids, f"Duplicate ID: {a['id']}"
            self.ids.add(a['id'])
        if tag == 'html':
            assert a.get('lang') == 'ar' and a.get('dir') == 'rtl'
        if tag == 'img':
            assert 'alt' in a and 'width' in a and 'height' in a, 'Image needs alt and dimensions'
        if tag == 'button':
            assert a.get('type') == 'button', 'Set explicit button type'
        if tag == 'main': self.main_count += 1
        if tag == 'h1': self.headings.append(tag)
        for key in ('href', 'src'):
            if key in a: self.links.append(a[key])


def build():
    page = Page()
    html = (ROOT / 'index.html').read_text()
    page.feed(html)
    assert page.main_count == 1 and len(page.headings) == 1
    for link in page.links:
        parsed = urlsplit(link)
        if parsed.scheme or parsed.netloc: continue
        if parsed.fragment:
            assert parsed.fragment in page.ids, f'Unknown anchor: {link}'
        if parsed.path:
            assert (ROOT / unquote(parsed.path)).is_file(), f'Missing asset: {link}'
    for filename in re.findall(r"'([a-z_]+\.jpg)'", (ROOT/'app.js').read_text()):
        assert (ROOT/'assets'/filename).is_file(), filename
    for filename in re.findall(r"url\(['\"]?([^)'\"]+)", (ROOT/'styles.css').read_text()):
        assert (ROOT/filename).is_file(), filename
    release = json.loads((ROOT/'release.json').read_text())
    assert release['file'] in html and f"{release['version']}" in html
    apk = ROOT.parent/'releases'/release['file']
    if apk.exists():
        digest = hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest()
        assert digest == release['sha256'] and apk.stat().st_size == release['sizeBytes']
    dist = ROOT/'dist'
    if dist.exists(): shutil.rmtree(dist)
    dist.mkdir()
    for filename in FILES: shutil.copy2(ROOT/filename,dist/filename)
    shutil.copytree(ROOT/'assets',dist/'assets')
    count = sum(1 for p in dist.rglob('*') if p.is_file())
    size = sum(p.stat().st_size for p in dist.rglob('*') if p.is_file())
    print(f'Static website verified: {count} files, {size:,} bytes; links, assets, Arabic semantics and APK metadata OK.')

if __name__ == '__main__': build()

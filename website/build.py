#!/usr/bin/env python3
"""Build the studio and project pages without dependencies or background services."""
from pathlib import Path
from html import escape
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parent
PAGES = ('index.html', 'mafia.html')
FILES = ('styles.css', 'brand.css', 'studio.css', 'app.js', 'studio.js',
         'robots.txt', 'sitemap.xml', 'release.json')
DOWNLOAD_BASE = 'https://github.com/HamzaSEBE/MafiaGame/raw/main/releases/'
VOID_TAGS = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
             'link', 'meta', 'param', 'source', 'track', 'wbr'}

class Page(HTMLParser):
    def __init__(self, name):
        super().__init__(convert_charrefs=True)
        self.name = name
        self.ids, self.links, self.headings, self.stack = set(), [], [], []
        self.main_count = 0

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag not in VOID_TAGS: self.stack.append(tag)
        if 'id' in a:
            assert a['id'] not in self.ids, f"{self.name}: duplicate ID {a['id']}"
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

    def handle_endtag(self, tag):
        if tag in VOID_TAGS: return
        assert self.stack and self.stack.pop() == tag, f'{self.name}: unbalanced {tag}'


def local_or_https(value):
    url = urlsplit(value)
    assert (url.scheme == 'https' and url.netloc) or (not url.scheme and not url.netloc), value
    assert not value.startswith('//') and not value.startswith('/') and '..' not in Path(url.path).parts, value
    return escape(value, quote=True)


def project_cards(release):
    projects = json.loads((ROOT/'projects.json').read_text())
    assert isinstance(projects, list) and projects, 'A published project is required'
    ids, cards = set(), []
    for project in projects:
        project_id = project['id']
        assert re.fullmatch('[a-z][a-z0-9-]*', project_id) and project_id not in ids
        ids.add(project_id)
        url, icon = local_or_https(project['url']), local_or_https(project['icon'])
        title, eyebrow, description, action, identity = (escape(project[field]) for field in ('title', 'eyebrow', 'description', 'actionLabel', 'identity'))
        labels = ''.join(f'<span>{escape(label)}</span>' for label in project['labels'])
        download = ''
        if project.get('download'):
            download = f'<a href="{DOWNLOAD_BASE}{escape(release["file"],quote=True)}" type="application/vnd.android.package-archive">تحميل APK <bdi>{escape(release["version"])}</bdi> <span aria-hidden="true">↓</span></a>'
        cards.append(f'''<article class="studio-project" data-project="{project_id}"><div class="project-main"><div class="project-copy"><span class="project-availability">متاح الآن</span><p class="project-eyebrow">{eyebrow}</p><h3>{title}</h3><p>{description}</p><div class="project-labels">{labels}</div><div class="project-actions"><a class="button" href="{url}">{action} <span aria-hidden="true">↙</span></a>{download}</div></div><a class="project-art" href="{url}" aria-label="استكشف {title}"><img src="{icon}" alt="أيقونة {title} الأصلية" width="1024" height="1024" loading="lazy"></a></div><div class="project-footer"><span>هوية المشروع: {identity}</span><a href="{url}">من أعمال <strong dir="ltr">ABWINI Labs</strong> <span aria-hidden="true">↗</span></a></div></article>''')
    return '\n'.join(cards)


def build():
    release = json.loads((ROOT/'release.json').read_text())
    assert re.fullmatch(r'[\w.-]+\.apk', release['file']), 'Invalid APK filename'
    rendered = {name:(ROOT/name).read_text() for name in PAGES}
    rendered['index.html'] = (rendered['index.html'].replace('{{PROJECTS}}',project_cards(release))
        .replace('{{APK_URL}}',DOWNLOAD_BASE + release['file'])
        .replace('{{VERSION}}',escape(release['version'])))
    parsed = {}
    for name, html in rendered.items():
        assert '{{' not in html, f'{name}: unresolved template'
        page = Page(name)
        page.feed(html)
        assert not page.stack and page.main_count == 1 and len(page.headings) == 1, name
        assert release['file'] in html and release['version'] in html, name
        parsed[name] = page
    for name, page in parsed.items():
        for link in page.links:
            url = urlsplit(link)
            if url.scheme or url.netloc: continue
            path = unquote(url.path) or name
            assert path in rendered or (ROOT/path).is_file(), f'{name}: missing {link}'
            if url.fragment and path in parsed:
                assert url.fragment in parsed[path].ids, f'{name}: unknown anchor {link}'
    for filename in re.findall(r"'([a-z_]+\.jpg)'", (ROOT/'app.js').read_text()):
        assert (ROOT/'assets'/filename).is_file(), filename
    for stylesheet in ROOT.glob('*.css'):
        for filename in re.findall(r"url\(['\"]?([^)'\"]+)", stylesheet.read_text()):
            assert (ROOT/filename).is_file(), filename
    apk = ROOT.parent/'releases'/release['file']
    if apk.exists():
        with apk.open('rb') as stream: digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        assert digest == release['sha256'] and apk.stat().st_size == release['sizeBytes']
    dist = ROOT/'dist'
    if dist.exists(): shutil.rmtree(dist)
    dist.mkdir()
    for name, html in rendered.items(): (dist/name).write_text(html)
    for filename in FILES: shutil.copy2(ROOT/filename,dist/filename)
    shutil.copytree(ROOT/'assets',dist/'assets')
    files = [p for p in dist.rglob('*') if p.is_file()]
    print(f'Studio and project pages verified: {len(files)} files, {sum(p.stat().st_size for p in files):,} bytes; cross-page links, HTML structure, assets and APK verified.')

if __name__ == '__main__': build()

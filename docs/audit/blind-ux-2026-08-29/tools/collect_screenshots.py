#!/usr/bin/env python3
"""Copy every screenshot referenced by the audit documents into ./screenshots/<session>/
and rewrite the scratch-directory paths to relative ones. Idempotent."""
import re, os, shutil, glob, sys
DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = '/private/tmp/claude-501/-Users-fischbeck3-cup-season/8472110b-9333-460b-8c1c-e243ac7cb2f3/scratchpad/harness/shots'
pat = re.compile(re.escape(SRC) + r'/([A-Za-z0-9_\-]+)/([A-Za-z0-9_\-\.]+\.png)')
files = [f for f in glob.glob(DIR + '/**/*', recursive=True) if f.endswith(('.md', '.json', '.csv')) and '/tools/' not in f]
copied = 0; missing = set(); rewritten = 0
for f in files:
    s = open(f, encoding='utf-8', errors='replace').read()
    refs = set(pat.findall(s))
    for sess, name in refs:
        src = f'{SRC}/{sess}/{name}'; dst = f'{DIR}/screenshots/{sess}/{name}'
        if os.path.exists(src):
            if not os.path.exists(dst):
                os.makedirs(os.path.dirname(dst), exist_ok=True); shutil.copy2(src, dst); copied += 1
        elif not os.path.exists(dst):
            missing.add(f'{sess}/{name}')
    # rewrite: raw/*.md live one level down, so their relative prefix differs
    rel = os.path.relpath(DIR + '/screenshots', os.path.dirname(f))
    new = pat.sub(lambda m: f'{rel}/{m.group(1)}/{m.group(2)}', s)
    if new != s:
        open(f, 'w', encoding='utf-8').write(new); rewritten += 1
print(f'copied {copied} new screenshots; rewrote paths in {rewritten} files; {len(missing)} references had no file on disk')
for m in sorted(missing)[:15]: print('  missing:', m)

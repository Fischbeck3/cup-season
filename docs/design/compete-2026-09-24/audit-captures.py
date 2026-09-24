#!/usr/bin/env python3
"""Audit required capture coverage and original image integrity; never edits images."""
from pathlib import Path
from collections import Counter
from PIL import Image
import argparse, hashlib, json
p=argparse.ArgumentParser()
p.add_argument('--gallery',type=Path,default=Path.home()/'cup-season-compete-explorations-review')
p.add_argument('--output',type=Path)
a=p.parse_args()
rows=[]
for path in sorted(a.gallery.glob('manifest-*.json')): rows.extend(json.loads(path.read_text()))
by_key={r['key']:r for r in rows}
errors=[]
if len(by_key)!=len(rows): errors.append('Duplicate manifest keys')
required=[]
for direction in ['scoreboard','race','broadsheet']:
 for fixture in ['tie','field','squads','upcoming','finished','multi']:
  for surface in ['root','season','entry']:
   for phone,size in [('standard','large'),('standard','ax3'),('small','large')]:
    for theme in ['dark','light']:
     required.append('-'.join([direction,fixture,surface,phone,size,theme]))
missing=sorted(set(required)-set(by_key))
if missing: errors.append(f'Missing {len(missing)} mandatory core captures')
if len(rows)!=564: errors.append(f'Expected 564 captures, got {len(rows)}')
dimensions=Counter()
for r in rows:
 path=a.gallery/r['file']
 if not path.is_file(): errors.append('Missing file: '+r['key']); continue
 data=path.read_bytes()
 if hashlib.sha256(data).hexdigest()!=r['sha256']: errors.append('Hash mismatch: '+r['key'])
 if len(data)!=r['bytes']: errors.append('Size mismatch: '+r['key'])
 with Image.open(path) as im:
  dimensions[f'{r["phone"]} {im.width}x{im.height}']+=1
  expected=(1206,2622) if r['phone']=='standard' else (750,1334)
  if im.size!=expected: errors.append('Unexpected dimensions: '+r['key'])
  body=im.convert('RGB').crop((0,im.height//4,im.width,im.height*3//4))
  if len(body.getcolors(im.width*im.height) or [])<=50: errors.append('Blank frame: '+r['key'])
report={'result':'FAIL' if errors else 'PASS','total':len(rows),'mandatoryCore':len(required),'mandatoryPresent':len(required)-len(missing),
 'byDirection':dict(Counter(r['direction'] for r in rows)),
 'byConfiguration':dict(Counter('/'.join([r['phone'],r['size'],r['theme']]) for r in rows)),
 'dimensions':dict(dimensions),'errors':errors,'missing':missing}
output=json.dumps(report,indent=2)+'\n'
if a.output: a.output.write_text(output)
print(output)
raise SystemExit(bool(errors))

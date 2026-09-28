#!/usr/bin/env python3
"""Native synthetic-fixture capture runner (S2/C3, 2026-09-28).

Drives `CupSeasonUITests/SyntheticRouteTests/testCapturePlan` on task-owned
simulators. Every capture is a `-cs_dev_synthetic <scenario> -cs_dev_open
<route>` launch whose intended root (`cs.screen.<root>`) is VERIFIED before the
screenshot is kept; a root that never appeared is recorded as a FAILED capture,
never as a shot of whatever screen was up.

It reads no secret, signs in to nothing and needs no network: the app answers
every request from its DEBUG-only synthetic world.

Usage (from anywhere):
  native-synthetic-captures.py --repo <worktree> --out <dir> \
      --device se3=<udid> --device 17pro=<udid> \
      [--plan tools/native-synthetic-plan.json] [--only name,name] \
      [--sizes large,AX3] [--themes dark,light] [--build]

Writes <out>/<phone>/<name>-<theme>-<size>.png, <out>/manifest.json (one row
per capture: file, sha256, source SHA, scenario, route, device UDID, theme,
text size, exact launch arguments, verification result) and <out>/failed.json.
One simulator is booted at a time and shut down afterwards. Never point
--device at a simulator you did not create for this purpose.
"""
import argparse, hashlib, json, plistlib, shutil, subprocess, sys, time
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--repo', required=True)
p.add_argument('--out', required=True)
p.add_argument('--device', action='append', required=True, help='phone=udid')
p.add_argument('--plan', default=None)
p.add_argument('--only', default=None, help='comma-separated plan names')
p.add_argument('--scenario', default=None, help='only plan rows of this scenario')
p.add_argument('--sizes', default='large,AX3')
p.add_argument('--themes', default='dark,light')
p.add_argument('--build', action='store_true', help='build-for-testing first')
p.add_argument('--keep-booted', action='store_true')
a = p.parse_args()

repo = Path(a.repo).resolve()
ios = repo / 'apps' / 'ios'
out = Path(a.out).resolve(); out.mkdir(parents=True, exist_ok=True)
dd = ios / 'build' / 'DD'
plan_path = Path(a.plan) if a.plan else repo / 'tools' / 'native-synthetic-plan.json'
plan = json.loads(plan_path.read_text())
if a.only:
    want = set(a.only.split(','))
    plan = [e for e in plan if e['name'] in want]
if a.scenario:
    plan = [e for e in plan if e['scenario'] == a.scenario]
if not plan:
    sys.exit('empty plan')
devices = dict(d.split('=', 1) for d in a.device)

def run(cmd, **kw):
    return subprocess.run(cmd, text=True, capture_output=True, **kw)

sha = run(['git', '-C', str(repo), 'rev-parse', 'HEAD']).stdout.strip()
dirty = bool(run(['git', '-C', str(repo), 'status', '--porcelain', '--', 'apps/ios', 'tools']).stdout.strip())

if a.build:
    cmd = ['xcodebuild', '-project', 'CupSeason.xcodeproj', '-scheme', 'CupSeason', '-configuration', 'Debug',
           '-destination', 'generic/platform=iOS Simulator', '-derivedDataPath', 'build/DD',
           '-clonedSourcePackagesDirPath', 'build/SourcePackages', '-disableAutomaticPackageResolution',
           '-jobs', '3', 'CODE_SIGNING_ALLOWED=NO', 'build-for-testing']
    log = out / 'build.log'
    with log.open('w') as f:
        rc = subprocess.run(cmd, cwd=ios, stdout=f, stderr=subprocess.STDOUT).returncode
    if rc != 0:
        sys.exit(f'build-for-testing failed ({rc}); see {log}')

products = dd / 'Build' / 'Products'
runs = sorted(products.glob('CupSeason_*.xctestrun'))
if not runs:
    sys.exit(f'no .xctestrun under {products} — run with --build')
base = runs[-1]
app = products / 'Debug-iphonesimulator' / 'CupSeason.app'

manifest_path = out / 'manifest.json'
rows = json.loads(manifest_path.read_text()) if manifest_path.exists() else []
by_plan = {e['name']: e for e in plan}

def sim(*args, check=False):
    return run(['xcrun', 'simctl', *args], check=check)

for phone, udid in devices.items():
    for other in devices.values():          # one task simulator booted at a time
        if other != udid:
            sim('shutdown', other)
    sim('boot', udid)
    sim('bootstatus', udid, '-b')
    sim('install', udid, str(app), check=True)
    sim('status_bar', udid, 'override', '--time', '9:41', '--dataNetwork', 'wifi', '--wifiMode', 'active',
        '--wifiBars', '3', '--batteryState', 'charged', '--batteryLevel', '100')
    phone_dir = out / phone; phone_dir.mkdir(exist_ok=True)
    for size in a.sizes.split(','):
        sim('ui', udid, 'content_size', 'accessibility-extra-large' if size == 'AX3' else 'large')
        time.sleep(4)
        d = plistlib.loads(base.read_bytes())
        env = d['CupSeasonUITests'].setdefault('EnvironmentVariables', {})
        env['CS_FX_PLAN'] = json.dumps(plan)
        env['CS_FX_THEMES'] = a.themes
        env['CS_FX_SIZE'] = size
        cfg = products / f'FX-{phone}-{size}.xctestrun'
        cfg.write_bytes(plistlib.dumps(d))
        stamp = time.strftime('%Y%m%d-%H%M%S')
        result = out / f'UI-{phone}-{size}-{stamp}.xcresult'
        log = out / f'ui-{phone}-{size}-{stamp}.log'
        cmd = ['xcodebuild', 'test-without-building', '-xctestrun', str(cfg),
               '-destination', f'platform=iOS Simulator,id={udid}', '-parallel-testing-enabled', 'NO',
               '-only-testing:CupSeasonUITests/SyntheticRouteTests/testCapturePlan', '-resultBundlePath', str(result)]
        with log.open('w') as f:
            status = subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT).returncode
        print(phone, size, 'xcodebuild exit', status, flush=True)
        export = out / f'export-{phone}-{size}-{stamp}'
        run(['xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(result), '--output-path', str(export)])
        mpath = export / 'manifest.json'
        if not mpath.exists():
            print('no attachments exported for', phone, size, flush=True)
            continue
        records = {}
        shots = []
        for test in json.loads(mpath.read_text()):
            for att in test.get('attachments', []):
                human = att['suggestedHumanReadableName']
                if human.startswith('fxrecord__'):
                    rec = json.loads((export / att['exportedFileName']).read_text())
                    records[(rec['name'], rec['theme'], rec['size'])] = rec
                elif human.startswith('fx__'):
                    shots.append((human, export / att['exportedFileName']))
        for human, src in shots:
            parts = human.split('__')
            name, theme, sz, verdict = parts[1], parts[2], parts[3], parts[4]
            counters = parts[5].split('_0_')[0] if len(parts) > 5 else ''
            dest = phone_dir / f'{name}-{theme}-{sz}.png'
            shutil.copyfile(src, dest)
            digest = hashlib.sha256(dest.read_bytes()).hexdigest()
            rec = records.get((name, theme, sz), {})
            entry = by_plan.get(name, {})
            rows = [r for r in rows if not (r['phone'] == phone and r['name'] == name and r['theme'] == theme and r['textSize'] == sz)]
            rows.append(dict(
                file=str(dest.relative_to(out)), sha256=digest, bytes=dest.stat().st_size,
                source=sha, sourceDirty=dirty, name=name, scenario=entry.get('scenario'), route=entry.get('route'),
                detail=entry.get('detail'), root=entry.get('root'), family=entry.get('family'), state=entry.get('state'),
                phone=phone, device=udid, theme=theme, textSize=sz,
                systemTextSize='accessibility-extra-large' if sz == 'AX3' else 'large',
                arguments=rec.get('arguments'), verification=verdict, rootFound=rec.get('found'),
                counters=rec.get('value', counters), identity='synthetic: Dev/Synthetic invented world (@example.invalid, fixture ids)',
                capturedAt=time.strftime('%Y-%m-%dT%H:%M:%S%z')))
        manifest_path.write_text(json.dumps(rows, indent=2) + '\n')
    if not a.keep_booted:
        sim('shutdown', udid)

failed = [r for r in rows if r['verification'] != 'PASS' or 'misses-0' not in (r.get('counters') or '').replace('=', '-')]
(out / 'failed.json').write_text(json.dumps(failed, indent=2) + '\n')
print(f'COMPLETE {len(rows)} rows, {len(failed)} failed or with unanswered requests', flush=True)

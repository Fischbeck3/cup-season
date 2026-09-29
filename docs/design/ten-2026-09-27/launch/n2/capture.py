#!/usr/bin/env python3
"""N2 capture runner (ten program, 2026-09-28) — adapted from FX's
tools/native-synthetic-captures.py.

Drives `CupSeasonUITests/N2CaptureTests/testCapturePlan` on N2's own
simulators. Every capture is a `-cs_dev_synthetic <scenario> -cs_dev_open
<place>` launch whose root (`cs.screen.<root>`) is verified before the shot is
kept; a root that never appeared is recorded FAIL. Beside every PNG goes the
accessibility tree it was taken from.

It reads no secret, signs in to nothing and needs no network: the app answers
every request from its DEBUG-only synthetic world.

  capture.py --repo <worktree> --out <gallery>/<tag> --plan plan.json \
      --device se3=<udid> [--device 17pro=<udid>] [--sizes large,AX3] \
      [--themes dark,light] [--only a,b]

Writes <out>/<phone>/<name>-<theme>-<size>.png (+ .ax.txt), and
<out>/manifest.json: file, sha256, source SHA, dirty flag, scenario, place,
detail, root, device UDID, theme, text size, exact launch arguments, verdict.
One simulator is booted at a time and shut down afterwards; xcodebuild waits
until fewer than two xcodebuild processes run on the machine.
"""
import argparse, hashlib, json, plistlib, shutil, subprocess, sys, time
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--repo', required=True)
p.add_argument('--out', required=True)
p.add_argument('--plan', required=True)
p.add_argument('--device', action='append', required=True, help='phone=udid')
p.add_argument('--only', default=None)
p.add_argument('--sizes', default='large,AX3')
p.add_argument('--themes', default='dark,light')
p.add_argument('--keep-booted', action='store_true')
a = p.parse_args()

repo = Path(a.repo).resolve()
ios = repo / 'apps' / 'ios'
out = Path(a.out).resolve(); out.mkdir(parents=True, exist_ok=True)
products = ios / 'build' / 'DD' / 'Build' / 'Products'
plan = json.loads(Path(a.plan).read_text())
if a.only:
    want = set(a.only.split(','))
    plan = [e for e in plan if e['name'] in want]
if not plan:
    sys.exit('empty plan')
devices = dict(d.split('=', 1) for d in a.device)

def run(cmd, **kw):
    return subprocess.run(cmd, text=True, capture_output=True, **kw)

def throttle():
    while True:
        n = len([l for l in run(['pgrep', '-x', 'xcodebuild']).stdout.split() if l.strip()])
        if n < 2:
            return
        time.sleep(15)

sha = run(['git', '-C', str(repo), 'rev-parse', 'HEAD']).stdout.strip()
dirty = bool(run(['git', '-C', str(repo), 'status', '--porcelain', '--', 'apps/ios']).stdout.strip())
runs = sorted(products.glob('CupSeason_*.xctestrun'))
if not runs:
    sys.exit(f'no .xctestrun under {products} — build-for-testing first')
base = runs[-1]
app = products / 'Debug-iphonesimulator' / 'CupSeason.app'
manifest_path = out / 'manifest.json'
rows = json.loads(manifest_path.read_text()) if manifest_path.exists() else []
by_plan = {e['name']: e for e in plan}

def sim(*args, check=False):
    return run(['xcrun', 'simctl', *args], check=check)

for phone, udid in devices.items():
    sim('boot', udid)
    sim('bootstatus', udid, '-b')
    sim('install', udid, str(app), check=True)
    sim('status_bar', udid, 'override', '--time', '9:41', '--dataNetwork', 'wifi', '--wifiMode', 'active',
        '--wifiBars', '3', '--batteryState', 'charged', '--batteryLevel', '100')
    phone_dir = out / phone; phone_dir.mkdir(exist_ok=True)
    for size in a.sizes.split(','):
        sim('ui', udid, 'content_size', 'accessibility-extra-large' if size == 'AX3' else 'large')
        time.sleep(3)
        d = plistlib.loads(base.read_bytes())
        env = d['CupSeasonUITests'].setdefault('EnvironmentVariables', {})
        env['CS_N2_PLAN'] = json.dumps(plan)
        env['CS_N2_THEMES'] = a.themes
        env['CS_N2_SIZE'] = size
        cfg = products / f'N2-{phone}-{size}.xctestrun'
        cfg.write_bytes(plistlib.dumps(d))
        stamp = time.strftime('%Y%m%d-%H%M%S')
        result = out / f'UI-{phone}-{size}-{stamp}.xcresult'
        log = out / f'ui-{phone}-{size}-{stamp}.log'
        cmd = ['xcodebuild', 'test-without-building', '-xctestrun', str(cfg),
               '-destination', f'platform=iOS Simulator,id={udid}', '-parallel-testing-enabled', 'NO',
               # a failed capture must not start a ten-minute `simctl diagnose`
               # that also sweeps every OTHER booted simulator's logs into the bundle
               '-collect-test-diagnostics', 'never',
               '-only-testing:CupSeasonUITests/N2CaptureTests/testCapturePlan', '-resultBundlePath', str(result)]
        throttle()
        with log.open('w') as f:
            status = subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT).returncode
        print(phone, size, 'xcodebuild exit', status, flush=True)
        export = out / f'export-{phone}-{size}-{stamp}'
        run(['xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(result), '--output-path', str(export)])
        mpath = export / 'manifest.json'
        if not mpath.exists():
            print('no attachments exported for', phone, size, flush=True)
            continue
        records, trees, shots = {}, {}, []
        for test in json.loads(mpath.read_text()):
            for att in test.get('attachments', []):
                human = att['suggestedHumanReadableName']
                src = export / att['exportedFileName']
                if human.startswith('n2record__'):
                    rec = json.loads(src.read_text())
                    records[(rec['name'], rec['theme'], rec['size'])] = rec
                elif human.startswith('n2ax__'):
                    _, name, theme, sz = human.split('__')[:4]
                    trees[(name, theme, sz.split('_0_')[0])] = src
                elif human.startswith('n2__'):
                    shots.append((human, src))
        for human, src in shots:
            parts = human.split('__')
            name, theme, sz, verdict = parts[1], parts[2], parts[3], parts[4]
            dest = phone_dir / f'{name}-{theme}-{sz}.png'
            shutil.copyfile(src, dest)
            tree = trees.get((name, theme, sz))
            if tree:
                shutil.copyfile(tree, phone_dir / f'{name}-{theme}-{sz}.ax.txt')
            rec = records.get((name, theme, sz), {})
            entry = by_plan.get(name, {})
            rows = [r for r in rows if not (r['phone'] == phone and r['name'] == name and r['theme'] == theme and r['textSize'] == sz)]
            rows.append(dict(
                file=str(dest.relative_to(out)), sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),
                source=sha, sourceDirty=dirty, name=name, finding=entry.get('finding'), state=entry.get('state'),
                scenario=entry.get('scenario'), place=entry.get('route'), detail=entry.get('detail'), root=entry.get('root'),
                phone=phone, device=udid, theme=theme, textSize=sz,
                systemTextSize='accessibility-extra-large' if sz == 'AX3' else 'large',
                arguments=rec.get('arguments'), steps=rec.get('steps'), verification=verdict,
                counters=rec.get('value'), identity='synthetic: Dev/Synthetic invented world (@example.invalid, fixture ids)',
                capturedAt=time.strftime('%Y-%m-%dT%H:%M:%S%z')))
        manifest_path.write_text(json.dumps(rows, indent=2) + '\n')
    # never leave the simulator at an accessibility size: the next run that
    # does not pin its reading size would inherit it
    sim('ui', udid, 'content_size', 'large')
    if not a.keep_booted:
        sim('shutdown', udid)

failed = [r for r in rows if r['verification'] != 'PASS' or 'misses=0' not in (r.get('counters') or '')]
(out / 'failed.json').write_text(json.dumps(failed, indent=2) + '\n')
print(f'COMPLETE {len(rows)} rows, {len(failed)} failed or with unanswered requests', flush=True)

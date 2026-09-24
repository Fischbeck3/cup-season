#!/usr/bin/env python3
"""Fixture-only simulator photographs. Never boots, erases or signs into a device.
Run once per already booted, isolated device; review HTML is generated separately.
"""
import argparse, hashlib, json, subprocess, time
from PIL import Image
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--device', required=True)
p.add_argument('--phone', choices=['standard', 'small'], required=True)
p.add_argument('--gallery', type=Path, default=Path.home() / 'cup-season-compete-explorations-review')
p.add_argument('--quick', action='store_true')
p.add_argument('--surface', action='append', help='Capture only this surface; repeatable.')
p.add_argument('--refresh', action='store_true', help='Replace matching captures in the manifest.')
a = p.parse_args()
a.gallery.mkdir(parents=True, exist_ok=True)
(a.gallery / 'captures').mkdir(exist_ok=True)
manifest = a.gallery / ('manifest-' + a.phone + '.json')
rows = json.loads(manifest.read_text()) if manifest.exists() else []
done = {r['key'] for r in rows}

def sim(*args, check=True):
    return subprocess.run(['xcrun', 'simctl', *args], text=True, capture_output=True, check=check)

sim('status_bar', a.device, 'override', '--time', '9:41', '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3', '--batteryState', 'charged', '--batteryLevel', '100')
shots=[]
for direction in ['scoreboard', 'race', 'broadsheet']:
    for fixture in ['tie', 'field', 'squads', 'upcoming', 'finished', 'multi']:
        for screen in ['root', 'season', 'entry']:
            shots.append((direction, fixture, screen, screen, []))
    shots.append((direction, 'multi', 'root-bottom', 'root-bottom', []))
    for fixture in ['field', 'squads', 'finished']:
        shots.append((direction, fixture, 'book', 'book', ['-cs_explore_mode', 'Weeks']))
    if direction in ['scoreboard', 'race']:
        for fixture in ['field', 'squads']:
            for surface, screen, extra in [
                ('totals', 'book', ['-cs_explore_mode', 'Totals']),
                ('race', 'race', ['-cs_explore_mode', 'Race']),
                ('week12', 'book', ['-cs_explore_mode', 'Weeks', '-cs_explore_week', '12']),
                ('receipt', 'receipt', []),
                ('adjustments', 'adjustments', ['-cs_explore_mode', 'Weeks'])]:
                shots.append((direction, fixture, surface, screen, extra))
        shots.append((direction, 'squads', 'contributions', 'book', ['-cs_explore_mode', 'Weeks', '-cs_explore_group', 'golfers', '-cs_explore_squad', '0']))
        shots.append((direction, 'finished', 'adjustments', 'adjustments', ['-cs_explore_mode', 'Weeks']))
        shots.append((direction, 'field', 'round', 'round', []))
        shots.append((direction, 'tie', 'book', 'book', []))
if a.quick: shots = [(d, 'field', 'root', 'root', []) for d in ['scoreboard','race','broadsheet']] + [('scoreboard','field','book','book',['-cs_explore_mode','Weeks'])]
if a.surface: shots = [s for s in shots if s[2] in a.surface]
sizes = ['large', 'ax3'] if a.phone == 'standard' and not a.quick else ['large']
for size in sizes:
    for theme in ['dark', 'light']:
        for direction, fixture, surface, screen, extra in shots:
            key = '-'.join([direction, fixture, surface, a.phone, size, theme])
            if not a.refresh and key in done and (a.gallery / 'captures' / (key+'.png')).exists(): continue
            args=['-cs_dev_compete_exploration', direction, '-cs_explore_fixture', fixture,
                  '-cs_explore_screen', screen, '-cs_dev_appearance', theme,
                  '-cs_dev_text_size', size, '-cs_dev_look', 'none'] + extra
            sim('launch', '--terminate-running-process', a.device, 'app.cupseason.ios', *args)
            time.sleep(0.75)
            path=a.gallery/'captures'/(key+'.png')
            previous = None
            for attempt in range(24):
                sim('io', a.device, 'screenshot', str(path))
                with Image.open(path) as im:
                    body=im.convert('RGB').crop((0, im.height//4, im.width, im.height*3//4))
                    rendered=len(body.getcolors(im.width*im.height) or []) > 50
                digest = hashlib.sha256(path.read_bytes()).hexdigest()
                if rendered and digest == previous: break
                previous = digest if rendered else None
                time.sleep(0.5)
            else: raise RuntimeError('Fixture did not render and settle: ' + key)
            rows = [r for r in rows if r['key'] != key]
            rows.append(dict(key=key, direction=direction, fixture=fixture, surface=surface,
                phone=a.phone, size=size, theme=theme, device=a.device,
                file='captures/'+path.name, arguments=args, bytes=path.stat().st_size,
                sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
            manifest.write_text(json.dumps(rows, indent=2)+'\n')
            print(f'{len(rows)} {key}', flush=True)
sim('terminate', a.device, 'app.cupseason.ios', check=False)
print(f'Complete: {len(rows)} captures on {a.phone}', flush=True)

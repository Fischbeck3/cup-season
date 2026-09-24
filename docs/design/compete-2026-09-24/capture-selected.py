#!/usr/bin/env python3
"""Capture the actual selected native renderers through the DEBUG fixture hatch.
The caller must boot/install only the task-owned simulator beforehand.
"""
import argparse,hashlib,json,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--device',required=True);p.add_argument('--phone',choices=['standard','small'],required=True);a=p.parse_args()
assert a.device in ['DC418592-2D15-43AA-9E83-B47D918D2956','D1B26067-F4EC-4A20-93BD-3D348CFA7802']
root=Path(__file__).resolve().parents[3];out=Path.home()/'cup-season-compete-explorations-review'/'selected';out.mkdir(exist_ok=True)
rev=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
scenes=[('root-tie','tie','root',[]),('root-multi','multi','root',[]),('season-squads','squads','season',[]),('weeks-squads','squads','book',[]),('weeks-golfers','squads','book',['-cs_selected_group','golfers']),('totals','squads','book',['-cs_selected_mode','Totals']),('race','squads','book',['-cs_selected_group','golfers','-cs_selected_mode','Race']),('receipt','squads','receipt',[]),('small-tie','tie','book',[]),('upcoming','upcoming','book',[]),('finished','finished','book',[])]
if a.phone=='small':scenes=[s for s in scenes if s[0] in ['root-tie','weeks-squads','race','small-tie']]
shots=[(name,kind,screen,extra,printing,'default') for name,kind,screen,extra in scenes for printing in ['dark','light']]
if a.phone=='standard':shots += [(name,kind,screen,extra,printing,'ax3') for name,kind,screen,extra in scenes if name in ['root-tie','weeks-golfers','receipt'] for printing in ['dark','light']]
def sim(*args,check=True):return subprocess.run(['xcrun','simctl',*args],capture_output=True,text=True,check=check)
sim('status_bar',a.device,'override','--time','9:41','--dataNetwork','wifi','--wifiMode','active','--wifiBars','3','--batteryState','charged','--batteryLevel','100')
rows=[]
for name,kind,screen,extra,printing,size in shots:
 filename=f'{a.phone}-{name}-{printing}-{size}.png';args=['-cs_dev_compete_selected','-cs_selected_fixture',kind,'-cs_selected_screen',screen,'-cs_dev_appearance',printing,'-cs_dev_look','none']+extra
 if size=='ax3':args+=['-cs_dev_text_size','ax3']
 sim('launch','--terminate-running-process',a.device,'app.cupseason.ios',*args);time.sleep(1.5)
 sim('io',a.device,'screenshot',str(out/filename))
 rows.append(dict(file=filename,phone=a.phone,surface=name,printing=printing,type=size,fixture=kind,source=rev,sha256=hashlib.sha256((out/filename).read_bytes()).hexdigest(),arguments=args))
 print(filename,flush=True)
(out/f'manifest-{a.phone}.json').write_text(json.dumps(rows,indent=2)+'\n')

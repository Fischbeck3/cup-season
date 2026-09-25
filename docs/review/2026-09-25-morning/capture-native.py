#!/usr/bin/env python3
"""Capture actual native views. Install the review build on a task-owned device first."""
import argparse,hashlib,json,subprocess,time,shutil
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--device',required=True);p.add_argument('--phone',choices=['standard','small','store'],required=True);a=p.parse_args()
root=Path(__file__).resolve().parent;out=root/'captures';out.mkdir(exist_ok=True)
def sim(*args):return subprocess.run(['xcrun','simctl',*args],text=True,capture_output=True,check=True).stdout.strip()
sim('status_bar',a.device,'override','--time','9:41','--dataNetwork','wifi','--wifiMode','active','--wifiBars','3','--batteryState','charged','--batteryLevel','100')
base=['-cs_dev_morning_review'];compete=['-cs_dev_compete_selected','-cs_selected_fixture','squads']
if a.phone=='store':
 scenes=[('01-season',compete+['-cs_selected_screen','season'],'dark','large'),
 ('02-setup',base+['-cs_review_scene','setup'],'light','large'),
 ('03-live',base+['-cs_review_scene','score'],'dark','large'),
 ('04-share',base+['-cs_review_scene','share'],'dark','large'),
 ('05-weeks',compete+['-cs_selected_screen','book','-cs_selected_group','golfers'],'light','large'),
 ('06-race',compete+['-cs_selected_screen','book','-cs_selected_group','golfers','-cs_selected_mode','Race'],'dark','large'),
 ('07-receipt',base+['-cs_review_scene','receipt'],'light','large'),
 ('08-finished',['-cs_dev_compete_selected','-cs_selected_fixture','finished','-cs_selected_screen','season'],'dark','large')]
else:
 scenes=[(scene,base+['-cs_review_scene',scene],theme,size) for scene in ['setup','live','share','receipt'] for theme,size in [('dark','large'),('light','large'),('dark','AX3')]]
 scenes += [('offline',base+['-cs_review_scene','offline'],'dark','large'),('share-photo',base+['-cs_review_scene','share','-cs_review_photo'],'dark','large')]
 if a.phone=='standard':scenes += [('share-long-photo',base+['-cs_review_scene','share','-cs_review_long','-cs_review_photo'],'dark','large'),('share-long',base+['-cs_review_scene','share','-cs_review_long'],'dark','large')]
rows=[]
for name,args,theme,size in scenes:
 args+=['-cs_dev_appearance',theme,'-cs_dev_look','none','-cs_dev_text_size',size]
 # app arguments directly after bundle ID; validated against the rendered screen.
 sim('launch','--terminate-running-process',a.device,'app.cupseason.ios',*args);time.sleep(2)
 file=f'{a.phone}-{name}-{theme}-{size}.png';sim('io',a.device,'screenshot',str(out/file))
 if a.phone=='standard' and name.startswith('share'):
  data=Path(sim('get_app_container',a.device,'app.cupseason.ios','data'))/'Documents'
  photo='photo' in name
  src=data/('round-share-with-photo.png' if photo else 'round-share-no-photo.png')
  if src.exists():shutil.copyfile(src,out/f'artifact-{name}.png')
  if (data/'review-photo.png').exists():shutil.copyfile(data/'review-photo.png',out/'fixture-photo.png')
 rows.append(dict(file=file,scene=name,theme=theme,textSize=size,arguments=args,sha256=hashlib.sha256((out/file).read_bytes()).hexdigest()))
 print(file,flush=True)
(root/f'manifest-{a.phone}.json').write_text(json.dumps(rows,indent=2)+'\n')

#!/usr/bin/env python3
"""Compose 6.9-inch store candidates from actual app screenshots; no fabricated UI."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
here=Path(__file__).resolve().parent;repo=here.parents[2]
tokens=json.loads((repo/'packages/tokens/tokens.json').read_text())['groups']
def token(key,theme):
 for group in tokens.values():
  if key in group.get('tokens',{}):
   t=group['tokens'][key];return t.get(theme,t.get('dark',t.get('value')))
 raise KeyError(key)
fonts=repo/'apps/ios/CupSeason/Resources/Fonts'
board=lambda size:ImageFont.truetype(str(fonts/'IBMPlexSansCondensed-Bold.ttf'),size)
mono=lambda size:ImageFont.truetype(str(fonts/'IBMPlexMono-Regular.ttf'),size)
shots=json.loads((here/'manifest-store.json').read_text());out=here/'store';out.mkdir(exist_ok=True)
captions=[('Your people.\nAll season.','A season with your own group.'),
 ('A round\nstarts here.','Choose the course, tees, group and game.'),
 ('Keep the\ngroup’s card.','Enter scores as the round unfolds.'),
 ('Send\nthe round.','A card to share from your round.'),
 ('The season,\nweek by week.','Open The Book to follow the record.'),
 ('See how\npoints add up.',"Today's counting points, placed by week."),
 ('Every point\nhas a receipt.','Open a round to see its scoring details.'),
 ('Keep\nthe season.','Return to the record after the finish.')]
rows=[]
for i,(shot,(headline,caption)) in enumerate(zip(shots,captions),1):
 theme=shot['theme'];bg=token('bg0',theme);ink=token('ink',theme);mut=token('mut',theme)
 canvas=Image.new('RGB',(1320,2868),bg);d=ImageDraw.Draw(canvas)
 # The signature uses the existing wordmark voice; the app capture carries the pennant.
 d.text((96,66),'CUP SEASON',font=board(36),fill=ink)
 label=f'{i:02d} / 08';width=d.textlength(label,font=mono(25));d.text((1224-width,76),label,font=mono(25),fill=mut)
 d.multiline_text((96,146),headline.upper(),font=board(110),fill=ink,spacing=0)
 d.text((96,404),caption,font=mono(25),fill=mut)
 assert d.textbbox((96,404),caption,font=mono(25))[2] <= 1224,caption
 raw=Image.open(here/'captures'/shot['file']).convert('RGB')
 assert raw.size == (1320,2868),raw.size
 # Keep every app pixel, including real system chrome, in its original aspect ratio.
 w=1056;h=round(raw.height*w/raw.width);x=(1320-w)//2;y=494
 assert y+h <= 2790
 canvas.paste(raw.resize((w,h),Image.Resampling.LANCZOS),(x,y))
 name=f'{i:02d}-{shot["scene"].split("-",1)[1]}.png';canvas.save(out/name,optimize=True)
 rows.append(dict(file=name,headline=headline,caption=caption,source=shot['file'],size=[1320,2868]))
(here/'store-captions.json').write_text(json.dumps(rows,indent=2)+'\n')
# A contact sheet for checking sequence and scale. Individual PNGs are the upload candidates.
thumbw=330;thumbh=717;sheet=Image.new('RGB',(thumbw*4,thumbh*2),token('bg0','dark'))
for i,row in enumerate(rows):sheet.paste(Image.open(out/row['file']).resize((thumbw,thumbh),Image.Resampling.LANCZOS),((i%4)*thumbw,(i//4)*thumbh))
sheet.save(here/'store-sequence.png',optimize=True)
print('8 store candidates at 1320 × 2868; RGB PNG, complete app capture, caption bounds verified.')

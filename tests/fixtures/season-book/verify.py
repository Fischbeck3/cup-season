"""Verify the real RPC in an explicitly supplied, task-owned local sandbox.
Seed first with seed.sql. Optional --export writes synthetic JSON test fixtures.
"""
import argparse, gzip, json, os, pathlib, subprocess, time
p=argparse.ArgumentParser();p.add_argument('--socket',required=True);p.add_argument('--port',required=True);p.add_argument('--export',action='store_true');a=p.parse_args()
assert a.socket.startswith('/private/tmp/cs-season-book-') and a.socket.endswith('/sock'), 'Only the isolated Book sandbox is allowed'
cmd=['/opt/homebrew/opt/postgresql@17/bin/psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',a.socket,'-p',a.port,'-U','postgres','-d','cupseason']
def bid(n):return 'c50b0000-0000-4000-8000-'+str(n).zfill(12)
def sql(s,fail=False):
 r=subprocess.run(cmd,input=s,text=True,capture_output=True)
 if fail:
  assert r.returncode and ('42501' in r.stderr or 'not available to you' in r.stderr or 'permission denied' in r.stderr),r.stderr
  return
 assert r.returncode==0,r.stderr
 return r.stdout.strip()
def read(lg=100,se=200,user=2):
 return json.loads(sql(f"set sim.uid='{bid(user)}';set role authenticated;select season_book('{bid(lg)}','{bid(se)}');"))
books={}
for name,lg,se in [('squads',100,200),('tie',101,201),('upcoming',102,202),('finished',103,203)]:
 start=time.monotonic();b=read(lg,se);ms=round((time.monotonic()-start)*1000);books[name]=b
 assert b['coverage_complete'];assert b['field_size']==(2 if name=='tie' else 16)
 assert len(b['weeks'])==15
 for r in b['rows']:
  assert r['reconciled'] and sum(e['contribution'] for e in r['entries'])==r['points']
  assert len(r['cells'])==15 and len({e['id'] for e in r['entries']})==len(r['entries'])
  assert r['unplaced_points']==sum(e['contribution'] for e in r['entries'] if e['week'] is None)
  for c in r['cells']:
   exact=[e for e in r['entries'] if e['week']==c['week']]
   through=[e for e in r['entries'] if e['week'] and e['week']<=c['week']]
   assert c['points']==(None if c['future'] or not exact else sum(e['contribution'] for e in exact))
   assert c['cumulative']==(None if c['future'] or not through else sum(e['contribution'] for e in through))
 raw=json.dumps(b,separators=(',',':')).encode();print(name,len(b['rows']),'rows',len(raw),'bytes',len(gzip.compress(raw)),'gzip bytes',ms,'ms')
 if a.export:pathlib.Path('tests/fixtures/season-book/'+name+'.json').write_bytes(raw+b'\n')
b=books['squads'];assert len(b['rows'])==36
for r in [r for r in b['rows'] if r['kind']=='squad']:
 contributions=[x for x in b['rows'] if x['kind']=='contribution' and x['squad_id']==r['squad_id']]
 assert sum(x['points'] for x in contributions)+sum(e['contribution'] for e in r['entries'] if e['kind']!='round')==r['points']
byid={r['id']:r for r in b['rows']};floor=byid['golfer:'+bid(11015)];floor=next(e for e in floor['entries'] if e['kind']=='floor_penalty');assert floor['points']==-5 and floor['contribution']==0 and floor['week']==9
assert byid['squad:'+bid(301)]['unplaced_points']==2
mine=byid['golfer:'+bid(11002)];assert len([e for e in mine['entries'] if e['week']==12 and e['kind']=='round'])==2
assert any(e['count_state']=='dropped' for e in mine['entries'])
assert all(r['points']==41 and r['points_rank']==1 and r['tied'] for r in books['tie']['rows'])
assert books['finished']['rules_note'] and not books['upcoming']['rows'][0]['entries']
assert sql("select has_function_privilege('anon','season_book(uuid,uuid)','execute');")=='f'
for user,lg,se in [(17,100,200),(18,100,200),(2,100,201),(2,100,999)]:
 sql(f"set sim.uid='{bid(user)}';set role authenticated;select season_book('{bid(lg)}','{bid(se)}');",fail=True)
sql(f"set role authenticated;select season_book('{bid(100)}','{bid(200)}');",fail=True)
for column in ['left_at','suspended_at']:
 sql(f"begin;set session_replication_role=replica;update league_members set {column}=now() where id='{bid(11002)}';set sim.uid='{bid(2)}';set role authenticated;select season_book('{bid(100)}','{bid(200)}');rollback;",fail=True)
home=json.loads(sql(f"set sim.uid='{bid(2)}';set role authenticated;select native_home();"))
if a.export:pathlib.Path('tests/fixtures/season-book/home.json').write_text(json.dumps(home,separators=(',',':'))+'\n')
m=next(m for m in home['memberships'] if m['league_id']==bid(101));assert m['standing']['rank']==m['standing']['points_rank']==1 and m['standing']['points_tied']
print('PASS: membership isolation, role grants, all cells and totals, adjustment scope/date, duplicate-week receipts, drops, ties, finished provenance and native_home parity')

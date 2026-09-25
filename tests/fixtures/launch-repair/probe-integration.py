import os, pathlib, socket, subprocess, tempfile, json
repo=pathlib.Path(__file__).resolve().parents[3]
repair=repo
root=pathlib.Path(tempfile.mkdtemp(prefix='cs-season-book-review-',dir='/private/tmp'))
(root/'sock').mkdir()
s=socket.socket();s.bind(('127.0.0.1',0));port=str(s.getsockname()[1]);s.close()
pgbin='/opt/homebrew/opt/postgresql@17/bin'
env=dict(os.environ,PGDATA=str(root/'pgdata'),SOCK=str(root/'sock'),PORT=port,PGBIN=pgbin,SIM_LOG=str(root/'apply.log'))
cmd=[pgbin+'/psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',str(root/'sock'),'-p',port,'-U','postgres','-d','cupseason']
print('EVIDENCE',root,flush=True)
def sql(q):
 r=subprocess.run(cmd,input=q,text=True,capture_output=True);assert r.returncode==0,r.stderr;return r.stdout.strip()
def bid(i):return 'c50b0000-0000-4000-8000-'+str(i).zfill(12)
def read():return json.loads(sql(f"set sim.uid='{bid(2)}';set role authenticated;select season_book('{bid(100)}','{bid(200)}');"))
try:
 with (root/'bootstrap-output.log').open('w') as log:
  r=subprocess.run(['bash','tests/sim/sandbox/apply.sh'],cwd=repo,env=env,stdout=log,stderr=subprocess.STDOUT)
 assert r.returncode==0,(root/'bootstrap-output.log').read_text()[-2000:]
 print('PASS full migration chain applied to new local PG17 cluster',flush=True)
 r=subprocess.run(cmd+['--single-transaction','-f',str(repo/'tests/fixtures/season-book/seed.sql')],capture_output=True,text=True);assert r.returncode==0,r.stderr
 r=subprocess.run(['python3','tests/fixtures/season-book/verify.py','--socket',str(root/'sock'),'--port',port],cwd=repo,capture_output=True,text=True)
 (root/'baseline-tests.txt').write_text(r.stdout+r.stderr)
 print('Baseline Book verification:',r.returncode,r.stdout[-700:],flush=True);assert r.returncode==0
 for prefix in ['2026111810','20261119','20261120','20261121','20261122','20261123','20261126']:
  f=next((repair/'supabase/migrations').glob(prefix+'*.sql'))
  r=subprocess.run(cmd+['--single-transaction','-f',str(f)],capture_output=True,text=True)
  (root/(f.stem+'.log')).write_text(r.stdout+r.stderr)
  print(('PASS' if r.returncode==0 else 'FAIL'),f.name,r.stderr[-900:] if r.returncode else '',flush=True)
  assert r.returncode==0,r.stderr  # integration: every repair, S3 included, re-runs cleanly
 b=read();print('Before synthetic late seat:',b['coverage_complete'],flush=True)
 sql(f"update squad_members set seated_at='2026-08-15 12:00-07' where member_id='{bid(11002)}';")
 b=read();bad=[{'name':r['name'],'kind':r['kind'],'total':r['points'],'entries_total':sum(e['contribution'] for e in r['entries'])} for r in b['rows'] if not r['reconciled']]
 (root/'late-seat-book.json').write_text(json.dumps(b,indent=2))
 print('After synthetic late seat:',json.dumps({'coverage_complete':b['coverage_complete'],'mismatches':bad}),flush=True)
 assert not bad and b['coverage_complete'],'integration: the Book must reconcile after a late seat'
finally:
 if (root/'pgdata/postmaster.pid').exists():subprocess.run([pgbin+'/pg_ctl','-D',str(root/'pgdata'),'-m','fast','stop'],capture_output=True)
 print('Task-owned local cluster stopped. No production connection.',flush=True)

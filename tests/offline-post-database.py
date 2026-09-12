"""Disposable PostgreSQL contract test. Never accepts a remote database URL.
Uses a deliberately small post_round fixture: validates wrapper atomicity and
concurrency, not Cup Season's already-existing scoring engine.
"""
import os, tempfile, subprocess, pathlib, json, uuid, concurrent.futures
root=pathlib.Path(__file__).resolve().parents[1]
bin=pathlib.Path('/opt/homebrew/opt/postgresql@17/bin')
with tempfile.TemporaryDirectory(prefix='cs-offline-pg-') as temp:
 d=pathlib.Path(temp); data=d/'data'; sock=d/'socket';sock.mkdir()
 subprocess.run([bin/'initdb','-D',data,'-A','trust','--no-locale'],check=True,capture_output=True)
 subprocess.run([bin/'pg_ctl','-D',data,'-l',d/'log','-o',f"-k {sock} -p 55437 -c listen_addresses=''",'start'],check=True,capture_output=True)
 def sql(text,ok=True):
  p=subprocess.run([bin/'psql','-h',sock,'-p','55437','-d','postgres','-v','ON_ERROR_STOP=1','-At'],input=text,text=True,capture_output=True)
  if ok and p.returncode:raise AssertionError(p.stderr)
  if not ok and not p.returncode:raise AssertionError('Expected rejection: '+text)
  return p.stdout.strip()
 try:
  sql('''create role anon; create role authenticated;
    create schema auth; create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    create table public.rounds(id uuid primary key default gen_random_uuid(),owner_id uuid,gross int);
    create table public.round_holes(round_id uuid references public.rounds(id) on delete cascade,hole_number int,strokes int check(strokes between 1 and 15));
    create function public.post_round(p_gross int,p_rating numeric,p_slope int,p_holes_played int default 18,p_nine_rating numeric default null,p_course_id text default null,p_course_label text default null,p_played_on date default current_date,p_photo_path text default null,p_played_with uuid[] default '{}') returns jsonb language plpgsql as $$
    declare r uuid; begin perform pg_sleep(0.15); insert into public.rounds(owner_id,gross) values(auth.uid(),p_gross) returning id into r;
    return jsonb_build_object('round',jsonb_build_object('id',r)); end $$;''')
  sql((root/'supabase/migrations/20261021090000_idempotent_phone_rounds.sql').read_text())
  a,b=str(uuid.uuid4()),str(uuid.uuid4()); key=str(uuid.uuid4())
  sql(f"insert into auth.users values('{a}'),('{b}');")
  payload=json.dumps(dict(gross=72,rating=72,slope=113,holes_played=18,played_on='2026-09-13',course_label='QA fixture'))
  def call(owner=a,request=key,body=payload,scores='ARRAY['+','.join(['4']*18)+']',role='authenticated'):
   return f"set request.jwt.claim.sub='{owner}';set role {role};select public.post_round_once('{request}','{body}'::jsonb,{scores},'{{}}'::uuid[]);"
  with concurrent.futures.ThreadPoolExecutor(2) as pool: out=list(pool.map(lambda _:sql(call()),range(2)))
  assert out[0]==out[1] and sql('select count(*) from rounds')=='1'
  assert sql('select count(*) from round_holes')=='18'
  # Response lost / new process: replay exact frozen envelope.
  assert sql(call())==out[0]
  sql(call(body=payload.replace('"gross": 72','"gross": 73')),ok=False)
  sql(call(owner=b));assert sql('select count(*) from rounds')=='2'
  sql(call(role='anon'),ok=False)
  sql('set role authenticated; select * from cupseason_private.round_post_receipts',ok=False)
  # Rollback after the wrapped post has inserted a round, during hole insert.
  sql('alter table round_holes add constraint fixture_fail check(strokes<>4) not valid')
  sql(call(request=str(uuid.uuid4())),ok=False)
  assert sql('select count(*) from rounds')=='2'
  assert sql('select count(*) from cupseason_private.round_post_receipts')=='2'
  sql('alter table round_holes drop constraint fixture_fail')
  sql(f"delete from rounds where owner_id='{a}'")
  assert sql(call())==out[0] and sql('select count(*) from rounds')=='1'
  sql(call(request=str(uuid.uuid4()),scores='ARRAY[4,4]'),ok=False)
  assert sql('select count(*) from rounds')=='1'
  print('PASS: concurrent retry, lost response, changed payload rejection, account isolation, atomic holes rollback, deleted-round tombstone, incomplete holes, private grants')
 finally:
  subprocess.run([bin/'pg_ctl','-D',data,'stop','-m','immediate'],check=True,capture_output=True)

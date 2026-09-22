#!/usr/bin/env python3
"""Isolated PostgreSQL test: never connects to Supabase or a linked database."""
import os, pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[1]
pg=pathlib.Path(os.environ.get('CS_PG_BIN','/opt/homebrew/opt/postgresql@17/bin'))
with tempfile.TemporaryDirectory(prefix='cs-course-',dir='/tmp') as temp:
    data=temp+'/data'
    def run(args, **kw): return subprocess.run([str(x) for x in args],check=True,capture_output=True,text=True,**kw)
    run([pg/'initdb','-D',data,'-A','trust','--no-locale'])
    run([pg/'pg_ctl','-D',data,'-l',temp+'/server.log','-o',f"-k {temp} -p 5543 -h ''",'-w','start'])
    try:
        schema=(root/'supabase/migrations/20260714050000_course_cache_reconcile.sql').read_text().split('-- soft link only')[0]
        migration=(root/'supabase/migrations/20261116090000_course_cache_atomic.sql').read_text()
        sql="create role anon; create role authenticated; create role service_role;\n"+schema+migration+(root/'tests/course-cache-checks.sql').read_text()
        result=run([pg/'psql','-h',temp,'-p','5543','-d','postgres','-v','ON_ERROR_STOP=1'],input=sql)
        print(result.stdout)
    finally: run([pg/'pg_ctl','-D',data,'-m','fast','-w','stop'])

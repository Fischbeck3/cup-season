#!/usr/bin/env python3
"""Q2 row 5: real RPC, all migrations, isolated PG17; no production option.
Proves the old two-squad sentence before the new migration, applies the new
migration twice, then checks every structure, guards, grants, and old posts.
"""
from pathlib import Path
import re, subprocess, tempfile

ROOT = Path(__file__).resolve().parents[1]
BIN = Path("/opt/homebrew/opt/postgresql@17/bin")
PATCH = ROOT / "supabase/migrations/20261220090000_two_squads_play_the_final.sql"

def run(args, **kw):
    p = subprocess.run([str(x) for x in args], capture_output=True, text=True, **kw)
    if p.returncode: raise RuntimeError(p.stderr[-4000:] or p.stdout[-4000:])
    return p.stdout + p.stderr

with tempfile.TemporaryDirectory(prefix="cs-q2-sprint-") as temp:
    tmp = Path(temp); data = tmp / "data"; sock = tmp / "socket"; sock.mkdir()
    run([BIN/"initdb", "-D", data, "-U", "sim", "-A", "trust", "-E", "UTF8", "--no-locale"])
    run([BIN/"pg_ctl", "-D", data, "-l", tmp/"postgres.log", "-o",
         f"-F -k {sock} -p 55449 -c listen_addresses='' -c wal_level=logical", "-w", "start"])
    try:
        base = [BIN/"psql", "-h", sock, "-p", "55449", "-X", "-q", "-v", "ON_ERROR_STOP=1"]
        run(base + ["-U", "sim", "-d", "postgres", "-c", "create database cupseason"])
        run(base + ["-U", "sim", "-d", "cupseason", "-f", ROOT/"tests/fixtures/release-bootstrap.sql"])
        chain = base + ["-U", "postgres", "-d", "cupseason", "--single-transaction"]
        migrations = sorted((ROOT/"supabase/migrations").glob("*.sql"))
        for f in migrations:
            if f == PATCH: continue
            body = re.sub(r'^\s*create extension if not exists (?:"supabase_vault"|pg_cron|pg_net).*?;[^\n]*$',
                          "-- Local service stub; migration on disk is unchanged.", f.read_text(), flags=re.I|re.M)
            try: run(chain, input=body)
            except Exception as exc: raise RuntimeError(f"Migration failed: {f.name}\n{exc}") from exc
        run(chain, input=(ROOT/"tests/fixtures/release-post-bootstrap.sql").read_text())
        print(run(chain, input="""
          begin;
          insert into auth.users(id,email) values('c5200000-0000-4000-8000-000000000001','q2-pro@example.test');
          select set_config('sim.uid','c5200000-0000-4000-8000-000000000001',true);
          do $$ declare lid uuid; got text; begin
            lid := (create_league('Q2 Parent Fixture','Q2PAR')->'league'->>'id')::uuid;
            update league_settings set structure='squads2' where league_id=lid;
            perform set_league_finish(lid,'cup_final');
            select body into got from posts where league_id=lid and body like 'The Pro set the finish:%';
            if got not like '%top seeds only.' then raise exception 'Parent control no longer reproduces: %',got; end if;
            raise notice 'PASS parent control reproduces the false cut on two squads';
          end $$;
          rollback;
        """), flush=True)
        run(chain, input=PATCH.read_text())
        run(chain, input=PATCH.read_text())
        print(f"PASS {len(migrations)} whole-chain migrations, zero skipped; Q2 reapplied idempotently", flush=True)
        print(run(chain, input=(ROOT/"tests/db/finish-announcement.sql").read_text()), flush=True)
        checks = run(chain, input=(ROOT/"tests/db-checks.sql").read_text())
        failures = [line for line in checks.splitlines() if "| FAIL" in line]
        # This cluster has a cron stand-in, not the pg_cron extension. Jobs
        # guarded by pg_extension cannot register here. Keep that limit explicit.
        unexpected = [line for line in failures if "1 · pg_cron jobs" not in line]
        if unexpected: raise AssertionError("\n".join(unexpected))
        print(checks, flush=True)
        print(f"PASS {59-len(failures)}/59 database checks; {len(failures)} runtime pg_cron check unavailable in the local stand-in", flush=True)
    finally:
        run([BIN/"pg_ctl", "-D", data, "-m", "immediate", "-w", "stop"])

"""Apply the release migration chain to disposable local Postgres, never production.
Uses the existing gameplay sandbox's Supabase service stubs. D345 remains held.
Cron and HTTP are stubs; this proves SQL compatibility, not real external delivery.
"""
from pathlib import Path
import re, subprocess, tempfile

ROOT = Path(__file__).resolve().parents[1]
BIN = Path("/opt/homebrew/opt/postgresql@17/bin")
HELD = {"20261024090000_the_loop_has_a_closing_act.sql"}

def command(args, **kwargs):
    p = subprocess.run([str(x) for x in args], capture_output=True, text=True, **kwargs)
    if p.returncode:
        raise RuntimeError(p.stderr[-5000:] or p.stdout[-5000:])
    return p.stdout

with tempfile.TemporaryDirectory(prefix="cs-release-chain-") as temp:
    tmp = Path(temp)
    data = tmp / "data"
    sock = tmp / "socket"
    sock.mkdir()
    command([BIN/"initdb", "-D", data, "-U", "sim", "-A", "trust", "-E", "UTF8", "--no-locale"])
    command([BIN/"pg_ctl", "-D", data, "-l", tmp/"postgres.log", "-o",
             f"-F -k {sock} -p 55439 -c listen_addresses='' -c shared_preload_libraries=pg_stat_statements -c wal_level=logical", "-w", "start"])
    try:
        base = [BIN/"psql", "-h", sock, "-p", "55439", "-X", "-q", "-v", "ON_ERROR_STOP=1"]
        command(base+["-U", "sim", "-d", "postgres", "-c", "create database cupseason"])
        command(base+["-U", "sim", "-d", "cupseason", "-f", ROOT/"tests/fixtures/release-bootstrap.sql"])
        sql = base+["-U", "postgres", "-d", "cupseason", "--single-transaction"]
        applied = []
        for f in sorted((ROOT/"supabase/migrations").glob("*.sql")):
            if f.name in HELD:
                print("HELD", f.name, flush=True)
                continue
            content = re.sub(r'^\s*create extension if not exists (?:"supabase_vault"|pg_cron|pg_net).*?;[^\n]*$',
                             "-- Local service stub; canonical migration is unchanged.",
                             f.read_text(), flags=re.I|re.M)
            try:
                command(sql, input=content)
            except Exception as exc:
                raise RuntimeError(f"Migration failed: {f.name}\n{exc}") from exc
            applied.append(f.name)
        command(sql, input=(ROOT/"tests/fixtures/release-post-bootstrap.sql").read_text())
        count=command(base+["-U","postgres","-d","cupseason","-At","-c",
            "select count(*) from pg_proc where pronamespace='public'::regnamespace"]).strip()
        print(f"PASS: {len(applied)} migrations applied; public functions {count}; D345 held.", flush=True)
    finally:
        command([BIN/"pg_ctl", "-D", data, "-m", "immediate", "-w", "stop"])

#!/usr/bin/env python3
"""Exercise the actual D345 function in a disposable PostgreSQL cluster.
Requires local PostgreSQL binaries; no database URL or production option exists.
Other Home branches use a deliberately minimal schema: this is not full staging QA.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
HOST = "a0000000-0000-4000-8000-000000000001"
GUEST = "a0000000-0000-4000-8000-000000000002"
OUTSIDE = "a0000000-0000-4000-8000-000000000003"
PLAN = "b0000000-0000-4000-8000-000000000001"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--pg-bin", default=str(Path(shutil.which("pg_ctl") or "/opt/homebrew/opt/postgresql@17/bin/pg_ctl").resolve().parent))
args = parser.parse_args()
binary = Path(args.pg_bin)

def process(cmd, **kwargs):
    return subprocess.run([str(x) for x in cmd], capture_output=True, text=True, **kwargs)

def require(ok, label):
    if not ok:
        raise AssertionError(label)
    print("PASS", label, flush=True)

with tempfile.TemporaryDirectory(prefix="cup-season-after-golf-test-") as temp:
    data = Path(temp) / "data"
    init = process([binary / "initdb", "-D", data, "-A", "trust", "--no-locale"])
    if init.returncode:
        raise RuntimeError(init.stderr)
    start = process([binary / "pg_ctl", "-D", data, "-l", Path(temp) / "postgres.log", "-o",
                     f"-F -k {temp} -p 55479 -c listen_addresses='' -c timezone=UTC", "-w", "start"])
    if start.returncode:
        raise RuntimeError(start.stderr)
    try:
        command = [binary / "psql", "-h", temp, "-p", "55479", "-d", "postgres", "-X", "-t", "-A", "-q", "-v", "ON_ERROR_STOP=1"]
        def sql(query, user=HOST, role=None, error=None):
            prefix = f"set request.jwt.claim.sub='{user}';"
            if role:
                prefix += f"set role {role};"
            result = process(command, input=prefix + query)
            if error:
                require(result.returncode != 0 and error in result.stderr, "rejects " + error)
            elif result.returncode:
                raise RuntimeError(result.stderr)
            return result.stdout.strip()
        def reset(day="current_date-1", host=HOST, tags="{}", course="null"):
            sql("truncate scheduled_rounds,round_rsvp,rounds,plan_followups cascade;")
            sql(f"insert into scheduled_rounds(id,profile_id,play_on,course_label,course_id,tagged) values('{PLAN}','{host}',{day},'Papago',{course},'{tags}');")
        def payload(day="current_date", user=HOST):
            return json.loads(sql(f"select home_dispatch(21,{day});", user=user, role="authenticated"))
        def prompts(day="current_date", user=HOST):
            return [x for x in payload(day,user)["items"] if x["key"].startswith("afterplan:")]
        def answer(value, user=HOST, day="current_date", error=None):
            return sql(f"select answer_plan_followup('{PLAN}',{value},{day});", user=user, role="authenticated", error=error)

        sql((ROOT / "tests/fixtures/after-golf-db.sql").read_text())
        migration = (ROOT / "supabase/migrations/20261024090000_the_loop_has_a_closing_act.sql").read_text()
        sql(migration)
        reset()
        require(len(prompts()) == 1 and prompts()[0]["route"]["kind"] == "composer", "actual Home RPC returns eligible host and composer")
        require(len(prompts("null")) == 0, "old client gets no premature after-golf prompt")
        require(len(prompts("current_date-1")) == 0, "local today never becomes yesterday")
        shifted = payload("current_date-1")
        require(any(x["key"] == "plan:"+PLAN for x in shifted["items"]), "upcoming read recovers local-today plan excluded by native_home UTC range")
        require(shifted["me"]["upcoming_rounds"][0]["play_on"] is not None, "returned ME payload uses the same local schedule")
        require(len(prompts(user=OUTSIDE)) == 0, "non-participant gets no prompt")
        reset(tags="{"+GUEST+"}")
        require("had you on the plan" in prompts(user=GUEST)[0]["headline"], "unanswered invitation does not assert attendance")
        sql(f"insert into round_rsvp values('{PLAN}','{GUEST}','maybe');")
        require(len(prompts(user=GUEST)) == 1, "maybe remains eligible")
        sql(f"update round_rsvp set status='out' where profile_id='{GUEST}';")
        require(len(prompts(user=GUEST)) == 0 and len(prompts()) == 1, "out excludes only that golfer")
        reset("current_date")
        require(not prompts(), "today excluded")
        answer("'later'", error="has not happened yet")
        reset("current_date-4")
        require(not prompts(), "four days ago ages out")
        reset()
        sql(f"insert into rounds values('{HOST}',current_date-1,false,null);")
        require(not prompts(), "same-day null-course posted round suppresses")
        sql("update rounds set voided=true;")
        require(len(prompts()) == 1, "voided round does not suppress")
        reset(course="'A'")
        sql(f"insert into rounds values('{HOST}',current_date-1,false,'B');")
        require(len(prompts()) == 1, "positive different-course evidence keeps prompt")
        sql("update rounds set api_course_id='A';")
        require(not prompts(), "same course suppresses")
        reset()
        sql(f"insert into scheduled_rounds(id,profile_id,play_on,tee_time,tagged) values('b0000000-0000-4000-8000-000000000002','{HOST}',current_date-1,'08:00','{{}}');")
        require(len(prompts()) == 1 and prompts()[0]["key"].endswith("2"), "one item per day chooses earliest tee, nulls last")
        reset()
        answer("'later'")
        require(not prompts() and len(prompts("current_date+1")) == 1, "Later hides today and returns tomorrow")
        require(sql("select count(*) from round_rsvp;") == "0", "answer leaves RSVP unchanged")
        answer("'didnt_play'")
        answer("'later'")
        require(sql("select answer from plan_followups;") == "didnt_play" and not prompts("current_date+1"), "stale Later cannot overwrite Didn't play")
        require(sql("select count(*) from plan_followups;", user=GUEST, role="authenticated") == "0", "RLS hides another golfer's answer")
        answer("'later'", user=OUTSIDE, error="Only the people")
        answer("'bogus'", error="That is not an answer")
        answer("null", error="That is not an answer")
        answer("'later'", user="", error="Sign in first")
        sql("select home_dispatch(21,current_date);", user="", role="anon", error="permission denied")
        sql("select cs_local_day(current_date);", role="authenticated", error="permission denied")
        sql("delete from scheduled_rounds;")
        require(not prompts() and sql("select count(*) from plan_followups;") == "0", "cancelled plan leaves no prompt or orphan answer")
        sql(migration)
        require(not prompts(), "migration reapply preserves valid empty response")
        print("PASS — actual D345 RPC, compatibility, dates, suppression, answers and role isolation", flush=True)
    finally:
        stopped = process([binary / "pg_ctl", "-D", data, "-m", "fast", "-w", "stop"])
        if stopped.returncode:
            raise RuntimeError(stopped.stderr)

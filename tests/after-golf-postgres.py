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
        # D353 · the band now waits for an explicit capability. Every existing
        # case below is a CAPABLE client, so they keep testing what they tested;
        # the incapable client gets its own cases.
        CAPS = "array['afterplan.v1']"
        def payload(day="current_date", user=HOST, caps=CAPS):
            return json.loads(sql(f"select home_dispatch(21,{day},{caps});", user=user, role="authenticated"))
        def prompts(day="current_date", user=HOST, caps=CAPS):
            return [x for x in payload(day,user,caps)["items"] if x["key"].startswith("afterplan:")]
        def answer(value, user=HOST, day="current_date", error=None):
            out = sql(f"select answer_plan_followup('{PLAN}',{value},{day});", user=user, role="authenticated", error=error)
            return json.loads(out) if out and not error else out

        sql((ROOT / "tests/fixtures/after-golf-db.sql").read_text())
        migration = (ROOT / "supabase/migrations/20261024090000_the_loop_has_a_closing_act.sql").read_text()
        sql(migration)
        # D353 · the forward fix. It patches the LIVE definition with asserted
        # replacements, so applying it here proves the patch finds its anchors.
        forward = (ROOT / "supabase/migrations/20261102090000_the_band_waits_for_a_client_that_can_answer.sql").read_text()
        sql(forward)
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
        # D353 · a plan that is not yours to answer is no longer a raised error
        # the golfer would read as a failure. It is not_available — the same
        # answer an absent plan gets, so a stranger learns nothing either way.
        out = answer("'later'", user=OUTSIDE)
        require(out["applied"] is False and out["reason"] == "not_available", "a plan that is not yours answers not_available")
        gone = sql("select answer_plan_followup('b0000000-0000-4000-8000-0000000000ff','later',current_date);", role="authenticated")
        require(json.loads(gone)["reason"] == "not_available", "an absent plan is indistinguishable from one that is not yours")
        answer("'bogus'", error="That is not an answer")
        answer("null", error="That is not an answer")
        answer("'later'", user="", error="Sign in first")
        sql("select home_dispatch(21,current_date);", user="", role="anon", error="permission denied")
        sql("select cs_local_day(current_date);", role="authenticated", error="permission denied")
        sql("delete from scheduled_rounds;")
        require(not prompts() and sql("select count(*) from plan_followups;") == "0", "cancelled plan leaves no prompt or orphan answer")
        # D353 · the reapply check now re-applies the HEAD of this function's
        # history, not D345. Re-running D345 after D353 correctly fails
        # ("cannot change return type of existing function") because it would
        # revert `answer_plan_followup` to void — and `db push` never re-runs a
        # recorded version, so that ordering does not occur.
        sql(forward)
        require(not prompts(), "migration reapply preserves valid empty response")
        # ── D353 · the capability gate, the context, and what an answer says ──
        reset()
        require(len(prompts()) == 1, "a capable client still sees the band")
        require(len(prompts(caps="null")) == 0, "a client that declares nothing gets no band")
        require(len(prompts(caps="array[]::text[]")) == 0, "an empty capability list gets no band")
        require(len(prompts(caps="array['something.else']")) == 0, "an unrelated capability does not open the band")
        require(len(prompts(caps="array['other','afterplan.v1']")) == 1, "the token is found among others")
        # the shipped Safari client sends a day and no capabilities: this is the
        # exact call that was showing an unanswerable card in production
        require(len(prompts(caps="null")) == 0, "the shipped client's own call no longer produces the card")

        ctx = prompts()[0]["context"]
        require(ctx["plan_id"] == PLAN, "the item carries the plan id outside the display key")
        require(ctx["play_on"] == sql("select (current_date-1)::text;"), "the item carries the day that was played")
        require(ctx["course_label"] == "Papago", "the item carries the raw course label, not the uppercased eyebrow")
        require(ctx["course_id"] is None, "a plan with no catalogue course says so rather than inventing one")
        reset(course="'A'")
        require(prompts()[0]["context"]["course_id"] == "A", "a plan with a catalogue course carries its id")

        reset()
        out = answer("'later'")
        require(out["applied"] is True and out["reason"] is None and out["answer"] == "later", "a recorded Later says it applied")
        require(out["snooze_until"] == sql("select (current_date+1)::text;"), "and says until when, from the server")
        out = answer("'didnt_play'")
        require(out["applied"] is True and out["snooze_until"] is None, "Didn't play applies and does not snooze")
        out = answer("'later'")
        require(out["applied"] is False and out["reason"] == "terminal", "a stale Later after Didn't play reports terminal, not success")
        require(sql("select answer from plan_followups;") == "didnt_play", "and writes nothing")

        reset()
        require(len(prompts()) == 1, "the eligibility rules are unchanged by the gate")
        answer("'later'")
        require(not prompts() and len(prompts("current_date+1")) == 1, "Later still hides today and returns tomorrow")

        sql(forward)
        require(len(prompts("current_date+1")) == 1, "the forward migration is idempotent")
        require(sql("select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='home_dispatch';") == "1",
                "home_dispatch still resolves to exactly one function")

        print("PASS — actual D345 RPC, compatibility, dates, suppression, answers and role isolation", flush=True)
        print("PASS — D353 capability gate, plan context and answer status", flush=True)
    finally:
        stopped = process([binary / "pg_ctl", "-D", data, "-m", "fast", "-w", "stop"])
        if stopped.returncode:
            raise RuntimeError(stopped.stderr)

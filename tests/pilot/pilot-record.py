#!/usr/bin/env python3
"""The pilot's own record (20261106090000) under restricted roles: the founder
may write and read cohorts and sessions; a golfer may not; anon may not; and a
retried client event with the same attempt id is stored once. Runs against
the sandbox with row security on. Exit non-zero on any FAIL."""
import subprocess, uuid, sys
PG = "/opt/homebrew/opt/postgresql@17/bin/psql"
R = []
def sql(stmt, uid=None, role="authenticated", ok_fail=True):
    pre = f"set role {role}; set sim.role = '{role}'; set sim.uid = '{uid or ''}';\n" if role else ""
    return subprocess.run([PG, "-h", "/tmp/cs-sim-sock", "-p", "5478", "-U", "postgres", "-d", "cupseason", "-X", "-q", "-t", "-A",
                           "-v", "ON_ERROR_STOP=1", "-c", pre + stmt], capture_output=True, text=True)
def ok(c, label, ev=""):
    R.append(c); print(("PASS" if c else "FAIL").ljust(6), label, f"[{ev[:90]}]" if ev else "", flush=True)
F, G = str(uuid.uuid4()), str(uuid.uuid4())
for uid, nm in ((F, "Founder"), (G, "Golfer")):
    sql(f"insert into auth.users(id, email) values ('{uid}','{nm.lower()}-{uid[:6]}@pilot.test'); update profiles set display_name='{nm}' where id='{uid}';", role=None)
sql(f"update profiles set is_founder = (id = '{F}');", role=None)
r = sql("select founder_id();", role=None); ok(r.stdout.strip() == F, "the sandbox founder is the seeded founder")
# cohorts
r = sql(f"insert into pilot_cohort_members(profile_id, cohort, group_key, added_by) values ('{G}','friends','galen-jade','{F}');", uid=F)
ok(r.returncode == 0, "the FOUNDER can add a golfer to a cohort", r.stderr.strip()[-60:])
r = sql(f"insert into pilot_cohort_members(profile_id, cohort, group_key, added_by) values ('{G}','independent','self','{G}');", uid=G)
ok(r.returncode != 0, "a GOLFER cannot add themselves to a cohort", r.stderr.strip()[-60:])
r = sql("select count(*) from pilot_cohort_members;", uid=G); ok(r.returncode == 0 and r.stdout.strip() == "0", "a GOLFER reads no cohort rows", r.stdout.strip() or r.stderr.strip()[-40:])
r = sql("select count(*) from pilot_cohort_members;", role="anon"); ok(r.returncode != 0, "ANON has no access to cohorts", r.stderr.strip()[-60:])
r = sql("select count(*) from pilot_cohort_members;", uid=F); ok(r.stdout.strip() == "1", "the FOUNDER reads the cohort rows")
# sessions
r = sql(f"insert into pilot_sessions(cohort, group_key, kind, golfers, notes) values ('friends','galen-jade','assisted', array['{G}']::uuid[], 'walked through first tee-off');", uid=F)
ok(r.returncode == 0, "the FOUNDER can log an assisted session", r.stderr.strip()[-60:])
r = sql(f"insert into pilot_sessions(cohort, group_key, kind, golfers) values ('friends','x','support', '{{}}');", uid=G)
ok(r.returncode != 0, "a GOLFER cannot log a session", r.stderr.strip()[-60:])
r = sql("select count(*) from pilot_sessions;", uid=G); ok(r.returncode == 0 and r.stdout.strip() == "0", "a GOLFER reads no sessions")
r = sql("select count(*) from pilot_sessions;", role="anon"); ok(r.returncode != 0, "ANON has no access to sessions")
# attempt de-duplication on client_events
A = str(uuid.uuid4())
r1 = sql(f"insert into client_events(event, props) values ('live_start_attempted', jsonb_build_object('attempt_id','{A}','platform','web'));", uid=G)
r2 = sql(f"insert into client_events(event, props) values ('live_start_attempted', jsonb_build_object('attempt_id','{A}','platform','web'));", uid=G)
n = sql(f"select count(*) from client_events where props->>'attempt_id'='{A}';", role=None).stdout.strip()
ok(r1.returncode == 0 and r2.returncode != 0 and n == "1", "a retried event with the same attempt id is stored ONCE (the second insert is refused)", f"rows={n}")
r3 = sql(f"insert into client_events(event, props) values ('live_start_attempted', jsonb_build_object('platform','web'));", uid=G)
r4 = sql(f"insert into client_events(event, props) values ('live_start_attempted', jsonb_build_object('platform','web'));", uid=G)
ok(r3.returncode == 0 and r4.returncode == 0, "events WITHOUT an attempt id are unaffected (older clients keep working)")
r = sql(f"insert into client_events(event, props) values ('x', jsonb_build_object('attempt_id','{A}'));", role="anon")
ok(r.returncode != 0, "ANON cannot write client_events")
print("\nPASS", sum(R), "FAIL", len(R) - sum(R)); sys.exit(0 if all(R) else 1)

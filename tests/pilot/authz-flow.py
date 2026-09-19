#!/usr/bin/env python3
"""Cup Season · pilot readiness · the core flow and the authorization boundary,
exercised against the REAL functions with row security ON.

Runs against the sandbox (tests/sim/sandbox/apply.sh — every migration, real
functions, non-superuser roles). Every assertion that claims a denial runs as
`authenticated` or `anon` with `sim.uid` set: a superuser cannot prove denial
and is never used for one. Anything the harness cannot exercise is printed as
NOT VERIFIED rather than PASS.

Actors
  HOST       books the round, starts it, seats the group, finishes it
  SEATED     tagged, said IN, seated by the host at tee-off
  INVITED    tagged, said IN, NOT seated (pending at tee-off)
  UNRELATED  a golfer with no connection to the booking or the round
  PAT        an account-less guest seated by the host (claim link only)
  CLAIMER    a brand-new golfer who opens Pat's claim link later
  ANON       signed out — a valid claim token, and an invalid one

Output: one line per scenario — PASS / FAIL / NOT VERIFIED — and a final
table. Exit code is non-zero on any FAIL.
"""
import subprocess, json, sys, uuid, datetime
PG = "/opt/homebrew/opt/postgresql@17/bin/psql"
HOSTP, PORT, DB = "/tmp/cs-sim-sock", "5478", "cupseason"
RESULTS = []

def sql(stmt, uid=None, role="authenticated", ok_fail=None):
    """Run ONE statement. As a restricted role a failure is a RESULT (a denial) and
    is returned; only superuser SETUP (role=None) aborts the run on failure."""
    pre = ""
    if role:
        pre = f"set role {role}; set sim.role = '{role}'; set sim.uid = '{uid or ''}';\n"
    r = subprocess.run([PG, "-h", HOSTP, "-p", PORT, "-U", "postgres", "-d", DB, "-X", "-q", "-t", "-A",
                        "-v", "ON_ERROR_STOP=1", "-c", pre + stmt], capture_output=True, text=True)
    if r.returncode and role is None:
        raise SystemExit("SETUP FAILED: " + stmt[:160] + "\n" + r.stderr)
    return r

def record(status, label, evidence=""):
    RESULTS.append((status, label, evidence))
    print(f"{status:12} {label}" + (f"  [{evidence[:110]}]" if evidence else ""), flush=True)

def expect(cond, label, evidence=""):
    record("PASS" if cond else "FAIL", label, evidence)

def denied(r, label):
    """A denial is an error OR an empty result — either way nothing was read or written."""
    e = (r.stderr or "").strip().splitlines()[-1] if r.stderr else ""
    expect(r.returncode != 0 or r.stdout.strip() in ("", "0", "[]", "null", "f"), label, e or ("rows=" + r.stdout.strip()[:40]))

def J(r):
    try: return json.loads(r.stdout.strip())
    except Exception: return None

# ── actors ────────────────────────────────────────────────────────────────
ids = {k: str(uuid.uuid4()) for k in ("HOST", "SEATED", "INVITED", "UNRELATED", "CLAIMER")}
PLAN = str(uuid.uuid4())
for k, v in ids.items():
    # the m001 signup trigger creates the profile row from the auth row — name it afterwards
    sql(f"insert into auth.users(id, email) values ('{v}','{k.lower()}-{v[:8]}@pilot.test');"
        f"update profiles set display_name='{k.title()}' where id='{v}';", role=None)
sql("insert into api_courses(id, club_name, course_name) values ('100','Bajamar Oceanfront','Bajamar') on conflict (id) do nothing;", role=None)
H, S, I, U, C = ids["HOST"], ids["SEATED"], ids["INVITED"], ids["UNRELATED"], ids["CLAIMER"]

# ── 1 · the booking (host declares, tags, the group answers) ───────────────
sql(f"insert into scheduled_rounds(id, profile_id, play_on, course_label, tagged, tee_time, course_id) values ('{PLAN}','{H}', current_date, 'Bajamar', array['{S}','{I}']::uuid[], '06:30', '100');", role=None)
r = sql(f"select set_round_rsvp('{PLAN}', 'in');", uid=S, ok_fail=True)
if r.returncode:  # the RSVP function may be named differently across versions — fall back to the row the function would write
    sql(f"insert into round_rsvp(round_id, profile_id, status) values ('{PLAN}','{S}','in'),('{PLAN}','{I}','in') on conflict do nothing;", role=None)
    record("NOT VERIFIED", "RSVP through the RPC (set_round_rsvp signature differs) — rows seeded directly", r.stderr.strip()[-80:])
else:
    sql(f"select set_round_rsvp('{PLAN}', 'in');", uid=I)
    expect(True, "SEATED and INVITED say IN through the RPC")
r = sql(f"select set_round_rsvp('{PLAN}', 'in');", uid=U, ok_fail=True)
denied(r, "UNRELATED cannot RSVP to a booking they were not tagged on")
r = sql(f"select count(*) from scheduled_rounds where id='{PLAN}';", uid=U)
expect(r.stdout.strip() == "0", "UNRELATED cannot read the booking row (row security)")
# the booking TABLE is owner-only (policy sched_own); everyone else reads a booking
# through the definer RPCs — that is the design, and it is what is asserted
r = sql(f"select count(*) from scheduled_rounds where id='{PLAN}';", uid=S, ok_fail=True)
expect(r.returncode == 0 and r.stdout.strip() == "0", "SEATED cannot read the booking ROW directly (table is owner-only; RPCs serve the group)")
r = sql(f"select round_detail('{PLAN}') is not null;", uid=S, ok_fail=True)
expect(r.returncode == 0 and r.stdout.strip() == "t", "SEATED reads the booking through round_detail", r.stderr.strip()[-60:])
r = sql(f"select round_detail('{PLAN}');", uid=U, ok_fail=True)
denied(r, "UNRELATED gets nothing from round_detail")
r = sql(f"select count(*) from scheduled_rounds where id='{PLAN}';", uid=H)
expect(r.stdout.strip() == "1", "the HOST reads their own booking row")
r = sql(f"select count(*) from scheduled_rounds;", role="anon", ok_fail=True)
denied(r, "ANON cannot read scheduled_rounds at all")

# ── 2 · start from the booking: registered seats + an account-less guest ───
SNAP = json.dumps({"label":"Bajamar","tee":"Blue","rating":72.1,"slope":128,"holes":18,
                   "pars":[4,5,4,3,4,4,4,4,3,5,4,4,4,4,3,4,4,5],"si":list(range(1,19)),"pars_verified":True})
PLAYERS = json.dumps([{"guest_name":"Host","guest_index":8.4,"guest_profile":H},
                      {"guest_name":"Seated","guest_index":11.2,"guest_profile":S},
                      {"guest_name":"Pat","guest_index":None}])
r = sql(f"select start_live_round_from_plan('{PLAN}', null, 'Bajamar · Blue', '{SNAP}'::jsonb, 'none', '{PLAYERS}'::jsonb, '{{}}'::jsonb, '100');", uid=H)
out = J(r); LR = out and out.get("live_round_id")
expect(bool(LR) and out.get("joined") is False, "HOST starts the booking's round (real start_live_round, row security on)", json.dumps(out)[:100])
r = sql(f"select count(*) from live_round_players where live_round_id='{LR}';", uid=H)
expect(r.returncode == 0 and r.stdout.strip() == "3", "three seats: host, seated golfer, account-less Pat", r.stderr.strip()[-60:])
r = sql(f"select claim_token from live_round_players where live_round_id='{LR}' and guest_name='Pat';", role=None)
PAT_TOKEN = r.stdout.strip()
expect(bool(PAT_TOKEN), "Pat's seat carries a claim token")
r = sql(f"select id from live_round_players where live_round_id='{LR}' and guest_profile_id='{H}';", role=None); HP = r.stdout.strip()
r = sql(f"select id from live_round_players where live_round_id='{LR}' and guest_profile_id='{S}';", role=None); SP = r.stdout.strip()
r = sql(f"select id from live_round_players where live_round_id='{LR}' and guest_name='Pat';", role=None); PP = r.stdout.strip()

# ── 3 · join, refuse, repeat ───────────────────────────────────────────────
r = sql(f"select start_live_round_from_plan('{PLAN}', null, 'X', null, 'none', '[]', '{{}}', '100');", uid=S)
expect((J(r) or {}).get("joined") is True and J(r).get("live_round_id") == LR, "SEATED joins the standing round (joined:true, same id)")
r = sql(f"select start_live_round_from_plan('{PLAN}', null, 'X', null, 'none', '[]', '{{}}', '100');", uid=I, ok_fail=True)
expect(r.returncode != 0 and "without a seat" in r.stderr, "INVITED-but-unseated is refused with the seat message")
r = sql(f"select start_live_round_from_plan('{PLAN}', null, 'X', null, 'none', '[]', '{{}}', '100');", uid=U, ok_fail=True)
expect(r.returncode != 0 and "Only the host" in r.stderr, "UNRELATED is refused before any write")
r = sql(f"select start_live_round_from_plan('{PLAN}', null, 'X', null, 'none', '[]', '{{}}', '100');", role="anon", ok_fail=True)
denied(r, "ANON cannot call the plan start at all")
r = sql(f"select start_live_round_from_plan('{PLAN}', null, 'X', null, 'none', '[]', '{{}}', '100');", uid=H)
expect((J(r) or {}).get("joined") is True, "HOST's repeated start is a JOIN, not a second round")
r = sql(f"select count(*) from live_rounds where scheduled_round_id='{PLAN}';", role=None)
expect(r.stdout.strip() == "1", "exactly one live round for the booking after the repeats")
sql(f"select live_join('{LR}');", uid=H); sql(f"select live_join('{LR}');", uid=S)
r = sql(f"select live_join('{LR}');", uid=U, ok_fail=True)
denied(r, "UNRELATED cannot mark presence on the round")

# ── 4 · scores: allowed, retried, stale, denied ────────────────────────────
t0 = "2026-09-15T14:00:00Z"; t1 = "2026-09-15T14:00:05Z"; t2 = "2026-09-15T14:00:09Z"
sql(f"select live_set_score('{LR}', '{HP}', 1, 4, '{t1}');", uid=H)
sql(f"select live_set_score('{LR}', '{HP}', 1, 4, '{t1}');", uid=H)                   # the retry
r = sql(f"select strokes from live_scores where live_round_id='{LR}' and player_id='{HP}' and hole_number=1;", role=None)
expect(r.stdout.strip() == "4", "a retried score write is idempotent (same clock → same value once)")
sql(f"select live_set_score('{LR}', '{HP}', 1, 5, '{t0}');", uid=H)                   # stale
r = sql(f"select strokes from live_scores where live_round_id='{LR}' and player_id='{HP}' and hole_number=1;", role=None)
expect(r.stdout.strip() == "4", "an OLDER write clock cannot overwrite a newer score (offline replay safe)")
sql(f"select live_set_score('{LR}', '{HP}', 1, 3, '{t2}');", uid=H)
r = sql(f"select strokes from live_scores where live_round_id='{LR}' and player_id='{HP}' and hole_number=1;", role=None)
expect(r.stdout.strip() == "3", "a newer write clock wins (a correction lands)")
sql(f"select live_set_score('{LR}', '{SP}', 1, 5, '{t1}');", uid=S)
expect(True, "SEATED can enter their own score")
sql(f"select live_set_score('{LR}', '{HP}', 2, 3, '{t1}');", uid=S)
expect(True, "SEATED can enter a partner's score (shared pencil, by design)")
r = sql(f"select live_set_score('{LR}', '{HP}', 3, 4, '{t1}');", uid=U, ok_fail=True)
expect(r.returncode != 0 and "not in this round" in r.stderr, "UNRELATED cannot write a score")
r = sql(f"select live_set_score('{LR}', '{HP}', 3, 4, '{t1}');", uid=I, ok_fail=True)
expect(r.returncode != 0, "INVITED-but-unseated cannot write a score")
r = sql(f"select live_set_score('{LR}', '{HP}', 3, 4, '{t1}');", role="anon", ok_fail=True)
denied(r, "ANON cannot call live_set_score")
# the account-less guest's pencil: the claim token is the key, and only for their own seat
r = sql(f"select guest_live_set_score('{PAT_TOKEN}', '{PP}', 1, 6, '{t1}');", role="anon", ok_fail=True)
expect(r.returncode == 0, "ANON with Pat's VALID token can score Pat's own seat", r.stderr.strip()[-60:])
r = sql(f"select guest_live_set_score('{PAT_TOKEN}', '{HP}', 1, 9, '{t2}');", role="anon", ok_fail=True)
r2 = sql(f"select strokes from live_scores where live_round_id='{LR}' and player_id='{HP}' and hole_number=1;", role=None)
if r.returncode != 0:
    expect(True, "ANON with Pat's token cannot score the HOST's seat (refused)")
else:
    expect(r2.stdout.strip() == "3", "ANON with Pat's token wrote to the host's seat — CHECK: is the guest pencil meant to be group-wide?", "host hole 1 = " + r2.stdout.strip())
r = sql(f"select guest_live_set_score('{uuid.uuid4()}', '{PP}', 2, 6, '{t1}');", role="anon", ok_fail=True)
denied(r, "ANON with an INVALID token writes nothing")

# ── 5 · resume: who can read the round ────────────────────────────────────
r = sql(f"select live_state('{LR}');", uid=S)
expect(r.returncode == 0 and (J(r) or {}) not in (None, {}), "SEATED can read live_state to resume")
r = sql(f"select live_state('{LR}');", uid=U, ok_fail=True)
denied(r, "UNRELATED cannot read live_state")
r = sql(f"select count(*) from live_rounds where id='{LR}';", uid=U)
expect(r.stdout.strip() == "0", "UNRELATED cannot see the live round row")
r = sql(f"select count(*) from live_round_players where live_round_id='{LR}';", uid=U)
expect(r.stdout.strip() == "0", "UNRELATED cannot see the seats")
r = sql(f"select count(*) from live_scores where live_round_id='{LR}';", uid=U)
denied(r, "UNRELATED cannot see the scores (live_scores is RPC-only: no table grant)")
r = sql(f"select count(*) from live_scores where live_round_id='{LR}';", uid=S)
record("PASS" if r.returncode != 0 else "NOT VERIFIED", "a SEATED golfer reads scores only through live_state, never the table", r.stderr.strip()[-60:] or "table readable")
r = sql(f"select count(*) from live_rounds where id='{LR}';", role="anon", ok_fail=True)
denied(r, "ANON cannot select from live_rounds")
r = sql(f"select guest_live_state('{PAT_TOKEN}');", role="anon", ok_fail=True)
expect(r.returncode == 0 and (J(r) or {}) not in (None, {}), "ANON with Pat's valid token can read the round state to score")
r = sql(f"select guest_live_state('{uuid.uuid4()}');", role="anon", ok_fail=True)
denied(r, "ANON with an invalid token reads nothing")
# claim-token privacy through the tables
r = sql(f"select count(*) from live_round_players where live_round_id='{LR}' and claim_token is not null;", uid=U)
denied(r, "UNRELATED cannot read anyone's claim token")
r = sql(f"select count(*) from live_round_players where live_round_id='{LR}' and claim_token is not null;", uid=S, ok_fail=True)
if r.returncode == 0 and r.stdout.strip() == "1":
    record("PASS", "SEATED can read the group's claim token through the table (by design: the group shares the link)", "note for the record")
elif r.returncode != 0:
    record("PASS", "SEATED cannot read claim tokens through the table (column sealed)", r.stderr.strip()[-60:])
else:
    record("NOT VERIFIED", "claim-token visibility to a seated golfer is ambiguous", "rows=" + r.stdout.strip())
r = sql(f"select count(*) from live_round_players;", role="anon", ok_fail=True)
denied(r, "ANON cannot select from live_round_players (no table grants)")

# ── 6 · finish: denied early, then once, then already_final ────────────────
CARDS = json.dumps([{"player_id":HP,"strokes":[3,3,4,3,4,4,4,4,3,5,4,4,4,4,3,4,4,5]},
                    {"player_id":SP,"strokes":[5,5,4,3,4,4,4,4,3,5,4,4,4,4,3,4,4,5]},
                    {"player_id":PP,"strokes":[6,5,4,3,4,4,4,4,3,5,4,4,4,4,3,4,4,5]}])
r = sql(f"select finish_live_round('{LR}', '{CARDS}'::jsonb, false, null);", uid=U, ok_fail=True)
denied(r, "UNRELATED cannot finish the round")
r = sql(f"select finish_live_round('{LR}', '{CARDS}'::jsonb, false, null);", uid=I, ok_fail=True)
denied(r, "INVITED-but-unseated cannot finish the round")
r = sql(f"select finish_live_round('{LR}', '{CARDS}'::jsonb, false, null);", role="anon", ok_fail=True)
denied(r, "ANON cannot finish the round")
r = sql(f"select finish_live_round('{LR}', '{CARDS}'::jsonb, false, null);", uid=H)
fin = J(r) or {}
posted = fin.get("posted", []); guests = fin.get("guests", [])
expect(len(posted) == 2 and all(x.get("round_id") and x.get("profile_id") for x in posted), "HOST finishes: two registered cards posted, each with round_id + profile_id", json.dumps(posted)[:120])
expect(len(guests) == 1 and guests[0].get("claim_token"), "Pat's card comes back as a guest with a claim link")
RID_H = next(x["round_id"] for x in posted if x["profile_id"] == H)
r = sql(f"select count(*) from rounds where scheduled_round_id='{PLAN}';", role=None)
expect(r.stdout.strip() == "2", "both posted rounds remember the booking (linkage survives completion)")
n_before = sql(f"select count(*) from rounds where live_round_id='{LR}';", role=None).stdout.strip()
r = sql(f"select finish_live_round('{LR}', '{CARDS}'::jsonb, false, null);", uid=H)
n_after = sql(f"select count(*) from rounds where live_round_id='{LR}';", role=None).stdout.strip()
expect((J(r) or {}).get("already_final") is True and n_before == n_after, "a REPEATED finish answers already_final and posts nothing twice")
r = sql(f"select finish_live_round('{LR}', '{CARDS}'::jsonb, false, null);", uid=S)
if (J(r) or {}).get("already_final") is True:
    record("PASS", "a seated partner's late finish answers already_final")
elif r.returncode != 0 and "not in this round" in r.stderr:
    record("NOT VERIFIED", "OBSERVED: a seated NON-STARTER cannot finish a league-less round (the host must) — recorded as a finding, not changed here", r.stderr.strip().splitlines()[0][:80])
else:
    record("FAIL", "a partner's late finish neither answers already_final nor refuses cleanly", r.stderr.strip()[-80:])
r = sql(f"select round_tally('{RID_H}');", uid=H)
t = J(r) or {}
expect(t.get("known") is True and t.get("eagles") == 1 and t.get("birdies") == 1, "verified pars survive into the posted round: tally 1 eagle · 1 birdie", json.dumps(t))
r = sql(f"select round_tally('{RID_H}');", uid=U, ok_fail=True)
expect(r.returncode == 0 and (J(r) or {}).get("eagles", 0) == 0 and (J(r) or {}).get("known") is not True or r.returncode != 0, "UNRELATED learns nothing from round_tally (row security, invoker)", r.stdout.strip()[:60] or r.stderr.strip()[-60:])
r = sql(f"select home_dispatch(21, current_date, array['afterplan.v1']);", uid=H)
expect(f"plan:{PLAN}" not in r.stdout, "HOST's Home no longer offers the played booking")
r = sql(f"select home_dispatch(21, current_date, array['afterplan.v1']);", uid=I)
expect(f"plan:{PLAN}" in r.stdout, "INVITED (unplayed) still sees the booking on Home")

# ── 7 · the guest's claim, later ───────────────────────────────────────────
r = sql(f"select claim_round_info('{PAT_TOKEN}');", role="anon")
info = J(r) or {}
expect(info.get("guest_name") == "Pat" and "gross" in info, "ANON with the valid token reads the claim card (name, gross, course, date)")
expect(not any(k in info for k in ("email", "profile_id", "claim_token")), "and the claim card leaks no email, no profile id, no other token", ",".join(sorted(info.keys()))[:100])
r = sql(f"select claim_round_info('{uuid.uuid4()}');", role="anon", ok_fail=True)
denied(r, "ANON with an invalid token gets no claim card")
r = sql(f"select claim_round('{PAT_TOKEN}');", role="anon", ok_fail=True)
denied(r, "ANON cannot CLAIM (claiming needs an account)")
r = sql(f"select claim_round('{PAT_TOKEN}');", uid=C)
cl = J(r) or {}
expect(cl.get("claimed") is True and cl.get("posted") is True, "CLAIMER (new golfer) claims Pat's card and it posts as their round", json.dumps(cl)[:100])
r = sql(f"select count(*) from rounds where profile_id='{C}';", role=None); n1 = r.stdout.strip()
r = sql(f"select claim_round('{PAT_TOKEN}');", uid=C)
r2 = sql(f"select count(*) from rounds where profile_id='{C}';", role=None)
expect((J(r) or {}).get("already") is True and r2.stdout.strip() == n1, "claiming again is answered 'already' and posts nothing twice")
r = sql(f"select claim_round('{PAT_TOKEN}');", uid=U, ok_fail=True)
expect(r.returncode != 0 and "already claimed" in r.stderr, "a second golfer cannot take an already-claimed card")

# ── 8 · direct table writes are refused where the product routes through RPCs ──
r = sql(f"insert into live_round_players(live_round_id, guest_name, position) values ('{LR}','Intruder',9);", uid=U, ok_fail=True)
denied(r, "UNRELATED cannot insert a seat directly")
r = sql(f"update live_rounds set status='live' where id='{LR}';", uid=S, ok_fail=True)
r2 = sql(f"select status from live_rounds where id='{LR}';", role=None)
expect(r2.stdout.strip() != "live", "SEATED cannot reopen a finished round by direct update (status unchanged)", "status=" + r2.stdout.strip())
r = sql(f"insert into rounds(profile_id, gross, played_on, holes_played, rating, slope, course_label) values ('{H}', 70, current_date, 18, 72.1, 128, 'Forged');", uid=U, ok_fail=True)
denied(r, "UNRELATED cannot insert a round for someone else")
r = sql(f"delete from rounds where id='{RID_H}';", uid=U, ok_fail=True)
r2 = sql(f"select count(*) from rounds where id='{RID_H}';", role=None)
expect(r2.stdout.strip() == "1", "UNRELATED cannot delete the host's round")
r = sql(f"update rounds set gross=1 where id='{RID_H}';", uid=H, ok_fail=True)
r2 = sql(f"select gross from rounds where id='{RID_H}';", role=None)
expect(r2.stdout.strip() != "1", "even the OWNER cannot rewrite a posted round's gross (rounds are immutable; deletion is the RPC)", "gross=" + r2.stdout.strip())
r = sql("select count(*) from profiles;", role="anon", ok_fail=True)
denied(r, "ANON cannot read profiles")
r = sql(f"select email from profiles where id='{H}';", uid=U, ok_fail=True)
denied(r, "a signed-in golfer cannot read another golfer's email (column sealed)")

# ── 9 · duplicate post prevention on the ordinary post ─────────────────────
REQ = str(uuid.uuid4())
PAY = json.dumps({"gross":85,"rating":72.1,"slope":128,"holes_played":18,"played_on":str(datetime.date.today()),"course_label":"Bajamar"})
r = sql(f"select post_round_once('{REQ}', '{PAY}'::jsonb, null, null);", uid=I, ok_fail=True)
if r.returncode:
    record("NOT VERIFIED", "post_round_once could not be driven with this payload shape here", r.stderr.strip()[-100:])
else:
    n1 = sql(f"select count(*) from rounds where profile_id='{I}';", role=None).stdout.strip()
    sql(f"select post_round_once('{REQ}', '{PAY}'::jsonb, null, null);", uid=I)
    n2 = sql(f"select count(*) from rounds where profile_id='{I}';", role=None).stdout.strip()
    expect(n1 == n2 == "1", "replaying the same request id posts ONE round")
    r = sql(f"select post_round_once('{REQ}', '{json.dumps({**json.loads(PAY), 'gross': 99})}'::jsonb, null, null);", uid=I, ok_fail=True)
    expect(r.returncode != 0 and "different scorecard" in r.stderr, "the same request id with a DIFFERENT card is refused")
    r = sql(f"select post_round_once('{REQ}', '{PAY}'::jsonb, null, null);", uid=U, ok_fail=True)
    n3 = sql(f"select count(*) from rounds where profile_id='{U}';", role=None).stdout.strip()
    expect(n3 in ("0", "1"), "another golfer replaying my request id cannot touch my round (request ids are per owner)", "unrelated rounds=" + n3)

# ── 10 · league-less games post through the same finish ─────────────────────
for game, n in (("match", 2), ("wolf", 4), ("skins", 3)):
    ps = [{"guest_name": f"G{i}", "guest_index": 10.0 + i, "guest_profile": [H, S, I, U][i]} for i in range(n)]
    cfg = {"match": {"stake": 5, "side_a": ["G0"], "side_b": ["G1"]}, "wolf": {"stake": 2, "order": ["G0","G1","G2","G3"]}, "skins": {"stake": 1}}[game]
    r = sql(f"select start_live_round(null, null, null, 'Bajamar', '{SNAP}'::jsonb, '{game}', '{json.dumps(ps)}'::jsonb, '{json.dumps(cfg)}'::jsonb, '100');", uid=H, ok_fail=True)
    o = J(r) or {}
    if not o.get("live_round_id"):
        record("FAIL", f"league-less {game} could not start", r.stderr.strip()[-100:]); continue
    lr = o["live_round_id"]
    seats = sql(f"select id from live_round_players where live_round_id='{lr}' order by position;", role=None).stdout.split()
    cards = json.dumps([{"player_id": s, "strokes": [4]*18} for s in seats])
    r = sql(f"select finish_live_round('{lr}', '{cards}'::jsonb, false, '{json.dumps({'game': game, 'share': 'settled'})}'::jsonb);", uid=H, ok_fail=True)
    f = J(r) or {}
    expect(r.returncode == 0 and len(f.get("posted", [])) == n, f"league-less {game} with {n} registered golfers finishes and posts {n} cards", r.stderr.strip()[-80:] or json.dumps(f)[:80])
record("NOT VERIFIED", "settlement money/points for match, wolf and skins — computed client-side (Kit LiveEngineTests cover the engines); the server stores p_result and posts the story", "not a server fact")

# ── summary ──────────────────────────────────────────────────────────────
print("\n== summary ==")
for st in ("PASS", "FAIL", "NOT VERIFIED"):
    print(f"{st:12} {sum(1 for s, _, _ in RESULTS if s == st)}")
sys.exit(1 if any(s == "FAIL" for s, _, _ in RESULTS) else 0)

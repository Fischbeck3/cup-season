#!/usr/bin/env python3
"""Cup Season · security review 2026-09-25 · Batch A (D392–D396), exercised against
the REAL functions with row security ON.

Runs against the sandbox (tests/sim/sandbox/apply.sh — every migration, real
functions, non-superuser roles). Point it at a cluster with the env vars
SIM_HOST / SIM_PORT / SIM_DB. Every denial is asserted as `authenticated` with
`sim.uid` set; the superuser only seeds.

Each block names the reach it closes and then proves the ordinary path beside it
still works: a guard that also blocks the golfers it protects is not a fix.

Output: one line per scenario — PASS / FAIL — and a final table. Non-zero exit on
any FAIL.
"""
import json, os, subprocess, sys, uuid

PG = os.environ.get("PSQL", "/opt/homebrew/opt/postgresql@17/bin/psql")
HOSTP = os.environ.get("SIM_HOST", "/tmp/cs-sim-sock")
PORT = os.environ.get("SIM_PORT", "5478")
DB = os.environ.get("SIM_DB", "cupseason")
RESULTS = []


def sql(stmt, uid=None, role="authenticated"):
    pre = ""
    if role:
        pre = f"set role {role}; set sim.role = '{role}'; set sim.uid = '{uid or ''}';\n"
    r = subprocess.run([PG, "-h", HOSTP, "-p", PORT, "-U", "postgres", "-d", DB, "-X", "-q", "-t", "-A",
                        "-v", "ON_ERROR_STOP=1", "-c", pre + stmt], capture_output=True, text=True)
    if r.returncode and role is None:
        raise SystemExit("SETUP FAILED: " + stmt[:200] + "\n" + r.stderr)
    return r


def val(stmt, uid=None, role="authenticated"):
    r = sql(stmt, uid, role)
    return r.stdout.strip() if r.returncode == 0 else None


def err(r):
    return (r.stderr or "").strip().splitlines()[-1] if r.stderr else ""


def refused(r, needle):
    """A refusal counts only for the stated reason: an error for any other cause is a FAIL."""
    return r.returncode != 0 and needle.lower() in (r.stderr or "").lower()


def record(ok, label, evidence=""):
    status = "PASS" if ok else "FAIL"
    RESULTS.append((status, label, evidence))
    print(f"{status:5} {label}" + (f"  [{evidence[:120]}]" if evidence else ""), flush=True)


def J(r):
    try:
        return json.loads(r.stdout.strip())
    except Exception:
        return None


# ── actors ───────────────────────────────────────────────────────────────────
A = {k: str(uuid.uuid4()) for k in ("STRANGER", "VICTIM", "HIDDEN", "BUDDY", "SHELL", "MATE", "LEAVER", "QUIET")}
for k, v in A.items():
    confirmed = "null" if k == "SHELL" else "now()"
    sql(f"insert into auth.users (id, email, aud, role, email_confirmed_at) values "
        f"('{v}', '{k.lower()}.{v[:6]}@reach.test', 'authenticated', 'authenticated', {confirmed})", role=None)
    if k != "SHELL":   # the shell never finishes its golfer card: no handle, no marker
        sql(f"update profiles set display_name = '{k.title()} Golfer', handle = '{k.lower()}_{v[:5]}', "
            f"marker = 'saguaro', city = 'Mesa', home_course = 'Papago', discoverable = 'everyone' "
            f"where id = '{v}'", role=None)
sql(f"update profiles set discoverable = 'nobody' where id = '{A['HIDDEN']}'", role=None)
sql(f"insert into friendships (requester, addressee, status, responded_at) values "
    f"('{A['STRANGER']}', '{A['BUDDY']}', 'accepted', now())", role=None)

SNAP = json.dumps({"rating": 72, "slope": 113, "holes": 18})
CARD18 = [4] * 18


def start(starter, seats, label="Papago GC"):
    return sql("select start_live_round(null, null, null, " + f"'{label}'" + ", "
               f"'{SNAP}'::jsonb, 'none', '{json.dumps(seats)}'::jsonb)", starter)


def seat_id(lr, profile):
    return val(f"select id from live_round_players where live_round_id = '{lr}' and guest_profile_id = '{profile}'",
               role=None)


def finish(starter, lr, seat):
    cards = json.dumps([{"player_id": seat, "strokes": CARD18}])
    return sql(f"select finish_live_round('{lr}', '{cards}'::jsonb, false, null)", starter)


def rounds_of(p):
    return int(val(f"select count(*) from rounds where profile_id = '{p}'", role=None) or 0)


# ── S1 · D392: a visitor's card posts only with their say-so ────────────────
r = start(A["STRANGER"], [{"guest_name": "V", "guest_profile": A["VICTIM"]}])
lr = (J(r) or {}).get("live_round_id")
record(r.returncode == 0 and lr, "S1 a findable stranger can still be seated by profile (D88 doorbell)", err(r))
before = rounds_of(A["VICTIM"])
f = finish(A["STRANGER"], lr, seat_id(lr, A["VICTIM"]))
out = J(f) or {}
record(f.returncode == 0 and rounds_of(A["VICTIM"]) == before and len(out.get("guests", [])) == 1,
       "S1 finish does NOT post to a stranger who never joined; the card becomes a claim link",
       f"rounds {before}->{rounds_of(A['VICTIM'])} guests={len(out.get('guests', []))}")

r = start(A["STRANGER"], [{"guest_name": "V", "guest_profile": A["VICTIM"]}])
lr = (J(r) or {}).get("live_round_id")
sql(f"update live_round_players set joined_at = now() where live_round_id = '{lr}' "
    f"and guest_profile_id = '{A['VICTIM']}'", role=None)
before = rounds_of(A["VICTIM"])
finish(A["STRANGER"], lr, seat_id(lr, A["VICTIM"]))
record(rounds_of(A["VICTIM"]) == before + 1, "S1 a visitor who JOINED from their own phone still gets the post")

r = start(A["STRANGER"], [{"guest_name": "B", "guest_profile": A["BUDDY"]}])
lr = (J(r) or {}).get("live_round_id")
before = rounds_of(A["BUDDY"])
finish(A["STRANGER"], lr, seat_id(lr, A["BUDDY"]))
record(rounds_of(A["BUDDY"]) == before + 1, "S1 a buddy's card still posts at finish (D107 for people you know)")

r = start(A["STRANGER"], [{"guest_name": "Me", "guest_profile": A["STRANGER"]}])
lr = (J(r) or {}).get("live_round_id")
before = rounds_of(A["STRANGER"])
finish(A["STRANGER"], lr, seat_id(lr, A["STRANGER"]))
record(rounds_of(A["STRANGER"]) == before + 1, "S1 the starter's own card still posts")

r = start(A["STRANGER"], [{"guest_name": "H", "guest_profile": A["HIDDEN"]}])
record(refused(r, "can't be added by name"), "S1 a golfer who hid themselves can't be seated by name", err(r))

# ── S3 · D393: every notification has a real sender; strangers are capped ────
nud = lambda p: int(val(f"select count(*) from push_nudges where profile_id = '{p}'", role=None) or 0)
row = val(f"select sender_id || '|' || from_stranger || '|' || title || '|' || body from push_nudges "
          f"where profile_id = '{A['VICTIM']}' order by created_at limit 1", role=None) or ""
record(row.startswith(A["STRANGER"] + "|true|") and "Papago" not in row,
       "S3 a stranger's push is stamped with its sender and carries fixed words, not the typed label", row)
v0 = nud(A["VICTIM"])
record(v0 == 2, "S3 per-pair cap: a stranger reaches the same golfer at most twice a day", f"victim nudges={v0}")
for _ in range(3):
    start(A["STRANGER"], [{"guest_name": "V", "guest_profile": A["VICTIM"]}], "cupseason-support.example: verify now")
record(nud(A["VICTIM"]) == v0, "S3 further stranger pushes to that golfer are dropped", f"nudges={nud(A['VICTIM'])}")

sql(f"insert into mutes (muter, muted) values ('{A['MATE']}', '{A['BUDDY']}')", role=None)
sql(f"insert into friendships (requester, addressee, status, responded_at) values "
    f"('{A['BUDDY']}', '{A['MATE']}', 'accepted', now())", role=None)
m0 = nud(A["MATE"])
start(A["BUDDY"], [{"guest_name": "M", "guest_profile": A["MATE"]}])
record(nud(A["MATE"]) == m0, "S3 a block wins even between buddies: no push reaches the blocker")

b0 = nud(A["BUDDY"])
start(A["STRANGER"], [{"guest_name": "B", "guest_profile": A["BUDDY"]}], "Encanto GC")
brow = val(f"select from_stranger || '|' || body from push_nudges where profile_id = '{A['BUDDY']}' "
           f"order by created_at desc limit 1", role=None) or ""
record(nud(A["BUDDY"]) == b0 + 1 and brow.startswith("false|") and "Encanto" in brow,
       "S3 a buddy's push is untouched: sender's own words, no cap", brow)

# ── S2 · D393: buddy requests ────────────────────────────────────────────────
r = sql(f"select friend_request('{A['SHELL']}')", A["STRANGER"])
record(refused(r, "isn't on Cup Season yet"), "S2 an unfinished card (OTP shell) can't be requested — so it can't be emailed", err(r))
fr = lambda a, b: int(val(f"select count(*) from friendships where requester = '{a}' and addressee = '{b}'",
                          role=None) or 0)
sql(f"create table if not exists public._reach_fr_log (n serial, a uuid, b uuid); "
    f"create or replace function public._reach_fr_t() returns trigger language plpgsql as $$ begin "
    f"insert into public._reach_fr_log (a, b) values (new.requester, new.addressee); return new; end $$; "
    f"drop trigger if exists _reach_fr_t on friendships; "
    f"create trigger _reach_fr_t after insert on friendships for each row execute function public._reach_fr_t();",
    role=None)
for _ in range(5):
    sql(f"select friend_request('{A['QUIET']}')", A["STRANGER"])
    sql(f"select unfriend('{A['QUIET']}')", A["STRANGER"])
ins = int(val(f"select count(*) from public._reach_fr_log where a = '{A['STRANGER']}' and b = '{A['QUIET']}'",
              role=None) or 0)
record(ins == 1, "S2 request → withdraw → request loops ring once, not five times (30 quiet days)", f"inserts={ins}")

r = sql(f"select friend_request('{A['LEAVER']}')", A["MATE"])
fid = val(f"select id from friendships where requester = '{A['MATE']}' and addressee = '{A['LEAVER']}'", role=None)
sql(f"select friend_respond('{fid}', false)", A["LEAVER"])
r2 = sql(f"select friend_request('{A['LEAVER']}')", A["MATE"])
record(r2.returncode == 0 and r2.stdout.strip() == "requested" and fr(A["MATE"], A["LEAVER"]) == 0,
       "S2 after a decline, a repeat reads 'requested' and writes nothing", r2.stdout.strip())

r = sql(f"select friend_request('{A['VICTIM']}')", A["QUIET"])
fid = val(f"select id from friendships where requester = '{A['QUIET']}' and addressee = '{A['VICTIM']}'", role=None)
sql(f"select friend_respond('{fid}', true)", A["VICTIM"])
acc = val(f"select status from friendships where id = '{fid}'", role=None)
record(r.returncode == 0 and acc == "accepted", "S2 an ordinary request → accept still works", acc or err(r))

# ── S4 · D395: the golfer card never sets a scored number ───────────────────
for d in ("2026-09-01", "2026-09-05", "2026-09-10"):
    sql(f"select post_round(p_gross => 85, p_rating => 72.0, p_slope => 113, "
        f"p_course_label => 'Home GC', p_played_on => '{d}'::date)", A["MATE"])
eng = val(f"select index_current from profiles where id = '{A['MATE']}'", role=None)
r = sql(f"select set_profile(p_name => 'Mate Golfer', p_index => 54, p_index_source => 'app')", A["MATE"])
after = val(f"select index_current from profiles where id = '{A['MATE']}'", role=None)
record(r.returncode == 0 and after == eng, "S4 set_profile leaves an engine index alone", f"engine={eng} after={after}")
r = sql(f"select set_profile(p_name => 'Leaver Golfer', p_index => 999)", A["LEAVER"])
record(refused(r, "Index looks off"), "S4 a starter index outside -10..54 is refused", err(r))
r = sql(f"select set_profile(p_name => 'Leaver Golfer', p_index => 18.4, p_index_source => 'self')", A["LEAVER"])
record(r.returncode == 0 and val(f"select index_current from profiles where id = '{A['LEAVER']}'", role=None) == "18.4",
       "S4 a real starter index before 3 rounds still saves")

# ── S12 · league codes are one code whatever the case ───────────────────────
r1 = sql("select create_league('Real League', 'REALAB12')", A["BUDDY"])
r2 = sql("select create_league('Copy League', 'realab12')", A["STRANGER"])
record(r1.returncode == 0 and refused(r2, "duplicate key"), "S12 a case-variant of an existing code is refused", err(r2))

# ── D394 · findable is not readable ─────────────────────────────────────────
# HIDDEN has no tie to VICTIM (QUIET became VICTIM's buddy in the S2 block above)
res = J(sql(f"select coalesce(json_agg(s), '[]') from search_golfers('victim_') s", A["HIDDEN"])) or []
row = next((x for x in res if x.get("profile_id") == A["VICTIM"]), None)
record(row is not None and row.get("city") is None and row.get("index_current") is None and row.get("handle"),
       "D394 a stranger finds a golfer by @handle but sees no city, course or index", json.dumps(row)[:120])
res = J(sql(f"select coalesce(json_agg(s), '[]') from search_golfers('buddy_') s", A["STRANGER"])) or []
row = next((x for x in res if x.get("profile_id") == A["BUDDY"]), None)
record(row is not None and row.get("city") == "Mesa", "D394 a buddy's search row keeps city, course and index")
res = J(sql(f"select coalesce(json_agg(s), '[]') from search_golfers('shell') s", A["STRANGER"])) or []
record(all(x.get("profile_id") != A["SHELL"] for x in res), "D394 search never returns an unfinished card")
res = J(sql(f"select coalesce(json_agg(s), '[]') from search_golfers('v') s", A["STRANGER"])) or []
record(res == [], "D394 a one-character search returns nothing")
tc = J(sql(f"select tour_card('{A['VICTIM']}')", A["MATE"])) or {}
record(tc.get("visible") is True and tc.get("stranger") is True and tc.get("recent") is None
       and (tc.get("profile") or {}).get("city") is None,
       "D394 a stranger's tour card is the card face only", json.dumps(tc)[:120])
tc = J(sql(f"select tour_card('{A['BUDDY']}')", A["STRANGER"])) or {}
record(tc.get("stranger") is None and (tc.get("profile") or {}).get("city") == "Mesa",
       "D394 a buddy's tour card is unchanged")

# ── invites (D393) ───────────────────────────────────────────────────────────
lg = (J(sql("select create_league('Stranger League', 'STRGAB34')", A["STRANGER"])) or {}).get("league", {}).get("id")
r = sql(f"select invite_golfer('{lg}', null, '{A['SHELL']}')", A["STRANGER"])
record(refused(r, "isn't on Cup Season yet"), "invite: an unfinished card can't be invited", err(r))
r = sql(f"select invite_golfer('{lg}', null, '{A['HIDDEN']}')", A["STRANGER"])
record(refused(r, "invite link instead"), "invite: a hidden stranger is reached by the link, not by name", err(r))
r = sql(f"select invite_golfer('{lg}', null, '{A['LEAVER']}')", A["STRANGER"])
record(r.returncode == 0 and r.stdout.strip() != "", "invite: a findable golfer can still be invited", err(r))

# ── D396 · deletion ──────────────────────────────────────────────────────────
mlg = (J(sql("select create_league('Mate League', 'MATEAB56')", A["MATE"])) or {}).get("league", {}).get("id")
mem = val(f"select id from league_members where league_id = '{mlg}' and profile_id = '{A['MATE']}'", role=None)
sql(f"insert into posts (league_id, kind, member_id, body) values ('{mlg}', 'chat', '{mem}', 'my private words')",
    role=None)
sql(f"insert into shares (token, kind, ref_id, created_by) values (gen_random_uuid(), 'person', '{A['MATE']}', "
    f"'{A['MATE']}')", role=None)
r = sql("select delete_account()", A["MATE"])
chat = val(f"select body from posts where member_id = '{mem}' and kind = 'chat'", role=None)
queued = val(f"select status from account_media_cleanup where profile_id = '{A['MATE']}'", role=None)
shares_open = val(f"select count(*) from shares where created_by = '{A['MATE']}' and not revoked", role=None)
email = val(f"select email from auth.users where id = '{A['MATE']}'", role=None)
record(r.returncode == 0 and chat == "[removed]" and queued == "pending" and shares_open == "0"
       and (email or "").endswith("@cupseason.invalid"),
       "D396 deletion blanks their words, queues their photos, withdraws their shares, scrubs the email",
       f"rc={r.returncode} chat={chat} queued={queued} open_shares={shares_open} email={email} {err(r)}")
record(rounds_of(A["MATE"]) == 3, "D396 their posted rounds stay (standings stay true)")

# ── scan consent, courses, direct doors ─────────────────────────────────────
r = sql("select set_scan_consent(true)", A["STRANGER"])
seen = val("select scan_consent_at is not null from profiles where id = auth.uid()", A["STRANGER"])
record(r.stdout.strip() == "t" and seen == "t", "scan consent is stored and readable by its golfer")
r = sql(f"select _courses_reserve('{A['STRANGER']}', 'search', 4)", A["STRANGER"])
record(refused(r, "permission denied for function _courses_reserve"), "courses: a client can't call the reservation itself", err(r))
sql("insert into app_flags (key, value) values ('courses', '{\"daily_per_user\": 8, \"daily_global\": 10}') "
    "on conflict (key) do update set value = excluded.value", role=None)
outs = [val(f"select _courses_reserve('{A['BUDDY']}', 'search', 4)", role="service_role") for _ in range(3)]
g = val(f"select _courses_reserve('{A['VICTIM']}', 'search', 4)", role="service_role")
record(outs == ["ok", "ok", "user_cap"] and g == "global_cap", "courses: units count against user and global caps",
       f"{outs} then {g}")
r = sql(f"insert into scheduled_rounds (profile_id, play_on, course_label, tagged) values "
        f"(auth.uid(), current_date + 3, 'x', array['{A['VICTIM']}']::uuid[])", A["STRANGER"])
record(refused(r, "permission denied for table scheduled_rounds"), "plans: no direct insert (declare_round is the door)", err(r))
r = sql("insert into push_subscriptions (profile_id, endpoint, p256dh, auth) values "
        "(auth.uid(), 'https://evil.example/hang', 'k', 'a')", A["STRANGER"])
record(refused(r, "push_subscriptions_endpoint_service"), "web push: an endpoint off the push services is refused", err(r))

# ── rate gate ────────────────────────────────────────────────────────────────
extra = []
for i in range(22):
    u = str(uuid.uuid4())
    sql(f"insert into auth.users (id, email, aud, role, email_confirmed_at) values "
        f"('{u}', 'fan{i}.{u[:6]}@reach.test', 'authenticated', 'authenticated', now())", role=None)
    sql(f"update profiles set handle = 'fan_{u[:8]}', marker = 'saguaro', display_name = 'Fan {i}' where id = '{u}'",
        role=None)
    extra.append(u)
codes = [sql(f"select friend_request('{u}')", A["LEAVER"]).returncode for u in extra]
last = sql(f"select friend_request('{extra[-1]}')", A["LEAVER"])
record(codes.count(0) == 20 and refused(last, "a lot for one day"), "rate: the 21st new buddy request in a day is refused",
       f"ok={codes.count(0)} refused={len(codes) - codes.count(0)}")


# ── the patched doors still open for the golfers they serve ─────────────────
r = sql("select join_league('realab12')", A["VICTIM"])
# the league is still in setup, so the join is refused by the phase rule — naming the league the
# lowercase code resolved to proves the lookup found the one league, past the new door gate
record(r.returncode == 0 or refused(r, "Real League isn't open yet"),
       "join: a code typed in any case still reaches the one league it names", err(r))
r = sql("select create_event('Stranger Ryder', (current_date + (7 - extract(dow from current_date)::int))::date, "
        "3, 1, 'team_pvi', 'Aces', 'Bogeys')", A["LEAVER"])
record(r.returncode == 0, "create_event still creates an event", err(r))
r = sql("select create_major('Stranger Major', current_date + 10)", A["LEAVER"])
record(r.returncode == 0, "create_major still creates a major", err(r))
dig = val(f"select cs_contact_digest(email) from auth.users where id = '{A['VICTIM']}'", role=None)
res = J(sql(f"select coalesce(json_agg(m), '[]') from match_contacts(array['{dig}']) m", A["HIDDEN"])) or []
row = next((x for x in res if x.get("id") == A["VICTIM"]), None)
record(row is not None and row.get("city") is None and row.get("index_current") is None,
       "D394 contact matching confirms the golfer, not where they play", json.dumps(row)[:120])


# ── S7 · plan comments carry who wrote them; blocked and taken-down ones don't show
PLAN = str(uuid.uuid4())
sql(f"insert into scheduled_rounds (id, profile_id, play_on, course_label, tagged) values "
    f"('{PLAN}', '{A['STRANGER']}', current_date + 2, 'Papago', array['{A['LEAVER']}', '{A['HIDDEN']}']::uuid[])",
    role=None)
sql(f"insert into round_comments (round_id, profile_id, body) values "
    f"('{PLAN}', '{A['LEAVER']}', 'from a golfer I blocked'), ('{PLAN}', '{A['HIDDEN']}', 'kept'), "
    f"('{PLAN}', '{A['HIDDEN']}', 'taken down')", role=None)
sql(f"update round_comments set hidden_at = now() where round_id = '{PLAN}' and body = 'taken down'", role=None)
sql(f"insert into mutes (muter, muted) values ('{A['STRANGER']}', '{A['LEAVER']}') on conflict do nothing", role=None)
rd = J(sql(f"select round_detail('{PLAN}')", A["STRANGER"])) or {}
cm = rd.get("comments") or []
record([c.get("body") for c in cm] == ["kept"] and cm[0].get("id") and cm[0].get("profile_id") == A["HIDDEN"],
       "S7 plan comments carry id + author; blocked and taken-down comments aren't shown", json.dumps(cm)[:120])

sql("drop trigger if exists _reach_fr_t on friendships; drop function if exists public._reach_fr_t(); "
    "drop table if exists public._reach_fr_log;", role=None)

fails = [x for x in RESULTS if x[0] == "FAIL"]
print(f"\n{len(RESULTS) - len(fails)} PASS / {len(fails)} FAIL")
sys.exit(1 if fails else 0)

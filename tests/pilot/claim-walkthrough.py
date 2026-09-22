#!/usr/bin/env python3
"""Cup Season · the guest-claim journey, stage by stage, against the REAL
functions with row security ON (sandbox: tests/sim/sandbox/apply.sh).

An account-less golfer is seated in a live round, the host finishes, and a
link is the only thing that golfer holds. Five stages, reported separately
so a failure names WHERE the journey dies:

  1 DELIVERY       the token exists and reaches the host to pass on
  2 OPENING        signed out, the link shows the card — and what it shows
                   for an unfinished round, a claimed one, and a bad token
  3 AUTHENTICATION claiming requires an account; the door says so
  4 COMPLETION     the claim posts exactly one round, once
  5 THE ROUND      the claimer can find it afterwards — by id, in their list

Every denial runs as `authenticated`/`anon` with sim.uid set; the superuser
is used only to seed. Exit non-zero on any FAIL."""
import subprocess, json, sys, uuid, datetime

PG = "/opt/homebrew/opt/postgresql@17/bin/psql"
R = []

def sql(stmt, uid=None, role="authenticated"):
    pre = f"set role {role}; set sim.role = '{role}'; set sim.uid = '{uid or ''}';\n" if role else ""
    r = subprocess.run([PG, "-h", "/tmp/cs-sim-sock", "-p", "5478", "-U", "postgres", "-d", "cupseason",
                        "-X", "-q", "-t", "-A", "-v", "ON_ERROR_STOP=1", "-c", pre + stmt],
                       capture_output=True, text=True)
    if r.returncode and role is None:
        raise SystemExit("SEED FAILED: " + stmt[:140] + "\n" + r.stderr)
    return r

def J(r):
    try: return json.loads(r.stdout.strip())
    except Exception: return None

def stage(n, title):
    print(f"\n── {n} · {title} " + "─" * max(0, 58 - len(title)), flush=True)

def ok(cond, label, ev=""):
    cond = bool(cond)
    R.append(cond)
    print(("PASS" if cond else "FAIL").ljust(5), label, (f"[{ev[:96]}]" if ev else ""), flush=True)

def note(label, ev=""):
    print("NOTE ", label, (f"[{ev[:96]}]" if ev else ""), flush=True)

# ── seed: a host, an account-less guest seat, and a newcomer who will claim ──
HOST, NEWCOMER, OTHER = (str(uuid.uuid4()) for _ in range(3))
for uid, nm in ((HOST, "Host"), (NEWCOMER, "Newcomer"), (OTHER, "Other")):
    sql(f"insert into auth.users(id, email) values ('{uid}','{nm.lower()}-{uid[:6]}@claim.test');"
        f"update profiles set display_name='{nm}' where id='{uid}';", role=None)
sql("insert into api_courses(id, club_name, course_name) values ('100','Bajamar Oceanfront','Bajamar') on conflict (id) do nothing;", role=None)

SNAP = json.dumps({"label": "Bajamar · Blue", "rating": 72.1, "slope": 128, "holes": 18,
                   "pars": [4,5,4,3,4,4,4,4,3,5,4,4,4,4,3,4,4,5], "si": list(range(1, 19)),
                   "pars_verified": True})
PLAYERS = json.dumps([{"guest_name": "Host", "guest_index": 8.4, "guest_profile": HOST},
                      {"guest_name": "Pat", "guest_index": None}])

# ══ 1 · DELIVERY ═════════════════════════════════════════════════════════
stage(1, "LINK DELIVERY — the token exists and reaches the host")
r = sql(f"select start_live_round(null,null,null,'Bajamar · Blue','{SNAP}'::jsonb,'none','{PLAYERS}'::jsonb,'{{}}'::jsonb,'100');", uid=HOST)
LR = (J(r) or {}).get("live_round_id")
ok(bool(LR), "a league-less round starts with an account-less seat", r.stderr.strip()[-70:])
PP = sql(f"select id from live_round_players where live_round_id='{LR}' and guest_name='Pat';", role=None).stdout.strip()
HP = sql(f"select id from live_round_players where live_round_id='{LR}' and guest_profile_id='{HOST}';", role=None).stdout.strip()
tok_before = sql(f"select coalesce(claim_token::text,'') from live_round_players where id='{PP}';", role=None).stdout.strip()
ok(bool(tok_before), "the seat carries a claim token from the START (not only at finish)", "token present" if tok_before else "none yet")

CARDS = json.dumps([{"player_id": HP, "strokes": [4]*18}, {"player_id": PP, "strokes": [5]*18}])
r = sql(f"select finish_live_round('{LR}', '{CARDS}'::jsonb, false, null);", uid=HOST)
fin = J(r) or {}
guests = fin.get("guests", [])
ok(len(guests) == 1 and guests[0].get("claim_token"), "the FINISH hands the host the guest's claim link to pass on",
   json.dumps(guests)[:90])
TOKEN = guests[0]["claim_token"]
ok(guests[0].get("name") == "Pat", "and names whose link it is, so the host knows who to send it to")
note("delivery is MANUAL by design: the host copies the link and sends it (text, chat). "
     "No email/SMS is sent by the product — nothing to fail, nothing to measure.")

# ══ 2 · OPENING ══════════════════════════════════════════════════════════
stage(2, "OPENING — signed out, what the link shows")
r = sql(f"select claim_round_info('{TOKEN}');", role="anon")
card = J(r)
ok(isinstance(card, dict) and card.get("guest_name") == "Pat", "a VALID token shows the card signed out",
   json.dumps(card)[:90] if card else r.stderr.strip()[-70:])
ok(card and card.get("gross") is not None and card.get("course_label") and card.get("played_on"),
   "and the card carries gross, course and date — enough to recognise the round")
leaky = [k for k in (card or {}) if k in ("email", "profile_id", "claim_token", "live_round_id", "id")]
ok(not leaky, "and leaks no email, profile id or token", ",".join(sorted((card or {}).keys()))[:90])
r = sql(f"select claim_round_info('{uuid.uuid4()}');", role="anon")
ok(J(r) is None or r.stdout.strip() in ("", "null"), "an INVALID token shows nothing")

# the unfinished-round case — 55 of production's 70 guest seats are here
PLAYERS2 = json.dumps([{"guest_name": "Host", "guest_profile": HOST}, {"guest_name": "Sam", "guest_index": None}])
r = sql(f"select start_live_round(null,null,null,'Papago','{SNAP}'::jsonb,'none','{PLAYERS2}'::jsonb,'{{}}'::jsonb,'100');", uid=HOST)
LR2 = (J(r) or {}).get("live_round_id")
TOK2 = sql(f"select claim_token from live_round_players where live_round_id='{LR2}' and guest_name='Sam';", role=None).stdout.strip()
r = sql(f"select claim_round_info('{TOK2}');", role="anon")
unfinished_shows = J(r)
ok(unfinished_shows is None or r.stdout.strip() in ("", "null"),
   "an UNFINISHED round's link shows nothing (no leak of a live card)")
note("**THE DEAD END.** `claim_round_info` returns NULL for an unfinished round, and the web "
     "then tries `scan_claim_info`, also null — so the golfer lands on the ordinary signed-out "
     "door with NO explanation. In production 55 of 70 guest seats are in rounds that were "
     "abandoned, i.e. every one of those links is this silent dead end.")
sql(f"update live_rounds set status='abandoned' where id='{LR2}';", role=None)
r = sql(f"select claim_round_info('{TOK2}');", role="anon")
ok(J(r) is None or r.stdout.strip() in ("", "null"), "an ABANDONED round's link likewise shows nothing")

# ══ 3 · AUTHENTICATION ═══════════════════════════════════════════════════
stage(3, "AUTHENTICATION — claiming requires an account")
r = sql(f"select claim_round('{TOKEN}');", role="anon")
ok(r.returncode != 0, "signed out, the CLAIM itself is refused", r.stderr.strip().splitlines()[-1][-80:] if r.stderr else "")
ok("permission denied" in (r.stderr or "") or "Sign in" in (r.stderr or ""),
   "refused at the GRANT, not by a message — anon holds no execute on claim_round",
   (r.stderr or "").strip().splitlines()[-1][-70:])
note("the clients never call claim_round signed out: the door shows the card, takes the email "
     "code, and claims after the session exists. The grant is the backstop, not the message.")
r = sql(f"select claim_round_info('{TOKEN}');", role="anon")
ok(J(r) is not None, "while the CARD stays readable signed out — you see it before you sign up")

# ══ 4 · COMPLETION ═══════════════════════════════════════════════════════
stage(4, "CLAIM COMPLETION — one round, once, to the right golfer")
before = sql(f"select count(*) from rounds where profile_id='{NEWCOMER}';", role=None).stdout.strip()
r = sql(f"select claim_round('{TOKEN}');", uid=NEWCOMER)
res = J(r) or {}
ok(res.get("claimed") is True and res.get("posted") is True, "the newcomer claims and the round POSTS",
   json.dumps(res)[:90] or r.stderr.strip()[-70:])
after = sql(f"select count(*) from rounds where profile_id='{NEWCOMER}';", role=None).stdout.strip()
ok(before == "0" and after == "1", "exactly one round appears on their record", f"{before}→{after}")
r = sql(f"select claim_round('{TOKEN}');", uid=NEWCOMER)
again = sql(f"select count(*) from rounds where profile_id='{NEWCOMER}';", role=None).stdout.strip()
ok((J(r) or {}).get("already") is True and again == "1", "claiming again says 'already' and posts nothing twice")
r = sql(f"select claim_round('{TOKEN}');", uid=OTHER)
ok(r.returncode != 0 and "already claimed" in (r.stderr or ""), "a second golfer cannot take a claimed card")
r = sql(f"select claim_round_info('{TOKEN}');", role="anon")
c2 = J(r)
ok(c2 is None or c2.get("claimed") is True, "and the link afterwards reports itself claimed rather than inviting again",
   json.dumps(c2)[:70] if c2 else "null")

# ══ 5 · THE RESULTING ROUND ══════════════════════════════════════════════
stage(5, "FINDING THE ROUND — the claimer can reach what they claimed")
RID = sql(f"select id from rounds where profile_id='{NEWCOMER}' limit 1;", role=None).stdout.strip()
r = sql(f"select count(*) from rounds where id='{RID}';", uid=NEWCOMER)
ok(r.returncode == 0 and r.stdout.strip() == "1", "the claimer can read their own round row", r.stderr.strip()[-60:])
r = sql(f"select round_card('{RID}');", uid=NEWCOMER)
rc = J(r)
ok(rc is not None, "and open its receipt (round_card)", (r.stderr or "").strip()[-70:])
r = sql(f"select gross, course_label, played_on::text, source, live_round_id is not null as from_live from rounds where id='{RID}';", role=None)
vals = r.stdout.strip().split("|")
ok(len(vals) >= 5 and vals[0] == "90" and vals[4] == "t",
   "the round carries the guest's real gross and points back at the live round", "|".join(vals)[:70])
r = sql(f"select count(*) from round_holes where round_id='{RID}';", uid=NEWCOMER)
ok(r.returncode == 0 and r.stdout.strip() == "18", "and its 18 holes are readable by the owner (20261107090000)",
   "holes=" + (r.stdout.strip() or r.stderr.strip()[-40:]))
r = sql(f"select count(*) from rounds where id='{RID}';", uid=OTHER)
ok(r.stdout.strip() == "0" or r.returncode != 0, "while an unrelated golfer still cannot read it")
r = sql(f"select round_tally('{RID}');", uid=NEWCOMER)
t = J(r) or {}
ok(t.get("known") is True, "the claimed round's tally is honest (pars were verified)", json.dumps(t))

print("\n== summary ==")
print("PASS", sum(R), "· FAIL", len(R) - sum(R))
sys.exit(1 if not all(R) else 0)

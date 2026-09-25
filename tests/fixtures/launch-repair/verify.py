"""Launch-audit repair scenarios on the isolated sandbox that run.sh builds and seeds with the
Book fixtures (tests/fixtures/season-book/seed.sql). Every scenario runs inside a transaction
that ROLLS BACK, as the real `authenticated` role where a client would call it. Synthetic data
only; the socket guard refuses anything but the task-owned /private/tmp cluster.
"""
import argparse, json, subprocess, sys
p = argparse.ArgumentParser(); p.add_argument('--socket', required=True); p.add_argument('--port', required=True)
a = p.parse_args()
assert a.socket.startswith('/private/tmp/cs-season-book-launch-repair-') and a.socket.endswith('/sock'), 'Only the isolated repair sandbox is allowed'
PSQL = ['/opt/homebrew/opt/postgresql@17/bin/psql', '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', a.socket, '-p', a.port, '-U', 'postgres', '-d', 'cupseason']

def bid(n): return 'c50b0000-0000-4000-8000-' + str(n).zfill(12)
def sql(s):
    r = subprocess.run(PSQL, input=s, text=True, capture_output=True)
    assert r.returncode == 0, r.stderr
    return r.stdout.strip()
def tx(setup, read, user=None):
    """setup as postgres, then `read` (an expression yielding one json value), as `user`
    under the real `authenticated` role when given — all rolled back."""
    who = f"select set_config('sim.uid', '{bid(user)}', true); set local role authenticated;" if user else ''
    out = sql(f"begin; {setup}; {who} select 'OUT:' || ({read})::text; rollback;")
    line = [l for l in out.splitlines() if l.startswith('OUT:')][-1]
    return json.loads(line[4:])

checks = []
def check(name, cond, detail=''):
    checks.append((name, bool(cond)))
    print(('PASS ' if cond else 'FAIL ') + name + (('  ' + str(detail)) if detail and not cond else ''))

# ── S3 · points standing and final placement stay apart ─────────────────────────────────
home = tx('', 'public.native_home()', user=2)
m = next(x for x in home['memberships'] if x['league_id'] == bid(101))
st = m['standing']
check('S3 live tie: rank == points_rank == 1 and points_tied', st['rank'] == st['points_rank'] == 1 and st['points_tied'], st)
check('S3 live tie: no final placement while live', st.get('final_place') is None and not st.get('is_champion'), st)
rec = tx('', "public.my_league_record()", user=2)
r = next(x for x in rec if x['season_id'] == bid(201))
check('S3 live tie: the record says 1st, tied', r['place'] == 1 and r['tied'] and not r['won'], r)

# A Final whose champion was NOT the points leader: league 103 (solo, complete). Crown the
# lowest-points golfer champion and the points leader runner-up, as a Cup Final can.
crown = f"""
  create temp table _t as select member_id, points from v_individual_standings where season_id = '{bid(203)}';
  update seasons set champion_member_id = (select member_id from _t order by points asc, member_id limit 1),
                     runnerup_member_id = (select member_id from _t order by points desc, member_id limit 1)
   where id = '{bid(203)}';
  grant select on _t to authenticated"""
leader = tx(crown, "select to_jsonb(x) from (select member_id, points from _t order by points desc, member_id limit 1) x")
champ = tx(crown, "select to_jsonb(x) from (select member_id, points from _t order by points asc, member_id limit 1) x")
def profile_of(member): return int(member[-12:]) - 11300
lead_home = tx(crown, "public.native_home()", user=profile_of(leader['member_id']))
lm = next(x for x in lead_home['memberships'] if x['league_id'] == bid(103))
check('S3 Final: the points leader keeps points_rank 1', lm['standing']['points_rank'] == 1, lm['standing'])
check('S3 Final: the points leader FINISHED 2nd, runner-up, not champion',
      lm['standing']['final_place'] == 2 and lm['standing']['is_runner_up'] and not lm['standing']['is_champion'], lm['standing'])
ch_home = tx(crown, "public.native_home()", user=profile_of(champ['member_id']))
cm = next(x for x in ch_home['memberships'] if x['league_id'] == bid(103))
check('S3 Final: the champion finished 1st though last on points',
      cm['standing']['final_place'] == 1 and cm['standing']['is_champion'] and cm['standing']['points_rank'] > 1, cm['standing'])
lead_rec = tx(crown, "public.my_league_record()", user=profile_of(leader['member_id']))
lr = next(x for x in lead_rec if x['season_id'] == bid(203))
check('S3 Final: the leader\'s record reads 2nd, runner-up, not WON', lr['place'] == 2 and lr['runner_up'] and not lr['won'], lr)

# ── I4 · the Book counts what the squad counts ───────────────────────────────────────────
# League 100 (squads4, season 200); golfer 2 = member 11002, squad 300 (Mudsharks).
BOOK = f"public.season_book('{bid(100)}','{bid(200)}')"
SEAT = f"update squad_members set seated_at = '2026-08-15 12:00-07' where member_id = '{bid(11002)}'"
def rows(b): return {r['id']: r for r in b['rows']}
def entries_total(r): return sum(e['contribution'] for e in r['entries'])
def squad_totals(extra=''):
    return tx(extra, f"select jsonb_object_agg(squad_id::text, points) from v_squad_standings where season_id = '{bid(200)}'")
before = tx('', BOOK, user=2)
after = tx(SEAT, BOOK, user=2)
auth = squad_totals(SEAT)
sq = rows(after)['squad:' + bid(300)]
check('I4 late seat: every row reconciles (coverage_complete)', after['coverage_complete'] and all(r['reconciled'] for r in after['rows']),
      [(r['id'], r['points'], entries_total(r)) for r in after['rows'] if not r['reconciled']][:3])
check('I4 late seat: the squad row equals v_squad_standings', sq['points'] == auth[bid(300)] == entries_total(sq), (sq['points'], auth[bid(300)], entries_total(sq)))
check('I4 late seat: the squad total really moved (the cut applied)', auth[bid(300)] < rows(before)['squad:' + bid(300)]['points'], (auth[bid(300)], rows(before)['squad:' + bid(300)]['points']))
g_before, g_after = rows(before)['golfer:' + bid(11002)], rows(after)['golfer:' + bid(11002)]
check("I4 late seat: the golfer's own row keeps every round", len(g_before['entries']) == len(g_after['entries']) and g_before['points'] == g_after['points'])
contrib = rows(after)['contribution:' + bid(300) + ':' + bid(11002)]
check('I4 late seat: the contribution row lists no pre-seat round', all(e['recorded_on'] >= '2026-08-14' for e in contrib['entries'] if e['kind'] == 'round'),
      [e['recorded_on'] for e in contrib['entries']][:4])
check('I4: a displaced round is still listed as dropped', any(e['count_state'] == 'dropped' for e in g_after['entries']))
floor_sq = rows(after)['squad:' + bid(303)]
check('I4: the squad floor penalty is still on its squad', any(e['kind'] == 'floor_penalty' and e['contribution'] == -5 for e in floor_sq['entries']))
check('I4: every entry carries withdrawn=false while live', all(e.get('withdrawn') is False for r in after['rows'] for e in r['entries']) and after['version'] == 2 and after['frozen'] is False)

# the close books the season; a counted round deleted AFTER the close keeps its line, flagged
CLOSE = SEAT + f"; select public.close_season('{bid(200)}')"
closed = tx(CLOSE, BOOK, user=2)
check('I4 close: the Book is frozen and says so', closed['frozen'] and 'closed with' in (closed['rules_note'] or ''), closed.get('rules_note'))
check('I4 close: every row still reconciles', closed['coverage_complete'])
counted = next(e for e in rows(closed)['golfer:' + bid(11002)]['entries'] if e['kind'] == 'round' and e['count_state'] == 'counting')
WITHDRAW = CLOSE + f"; delete from rounds where id = '{counted['round_id']}'"
gone = tx(WITHDRAW, BOOK, user=2)
g_gone = rows(gone)['golfer:' + bid(11002)]
w = next((e for e in g_gone['entries'] if e['round_id'] == counted['round_id']), None)
check('I4 withdrawal: the line stays with withdrawn=true and its points', w is not None and w['withdrawn'] and w['contribution'] == counted['contribution'], w)
check('I4 withdrawal: the golfer total and the squad total do not move',
      g_gone['points'] == rows(closed)['golfer:' + bid(11002)]['points']
      and rows(gone)['squad:' + bid(300)]['points'] == rows(closed)['squad:' + bid(300)]['points'],
      {'golfer': (rows(closed)['golfer:' + bid(11002)]['points'], g_gone['points']),
       'squad': (rows(closed)['squad:' + bid(300)]['points'], rows(gone)['squad:' + bid(300)]['points']),
       'withdrawn round recorded_on': counted['recorded_on']})
check('I4 withdrawal: still reconciled, and the explanation says why', gone['coverage_complete'] and 'Withdrawn by the golfer' in w['reason'])

# multiple seasons: a seat in season TWO never cuts season one's booked receipts
TWO = CLOSE + f"""; insert into seasons (id, league_id, number, starts_on, ends_on, status) values ('{bid(209)}', '{bid(100)}', 2, '2026-11-02', '2027-01-31', 'active');
  insert into squads (id, season_id, name, color) values ('{bid(309)}', '{bid(209)}', 'Season Two', 0);
  insert into squad_members (squad_id, member_id, seated_at) values ('{bid(309)}', '{bid(11003)}', now())"""
two = tx(TWO, BOOK, user=2)
check('I4 two seasons: season one is unchanged by a season-two seat',
      two['coverage_complete'] and rows(two)['squad:' + bid(300)]['points'] == rows(closed)['squad:' + bid(300)]['points'])
other = tx(SEAT, f"public.season_book('{bid(101)}','{bid(201)}')", user=2)
check('I4: another league is untouched by the seat', other['coverage_complete'] and all(r['points'] == 41 for r in other['rows']))

# ── I5b · one share, one attempt (Codex's native contract) ──────────────────────────────
def steps(setup, reads, user):
    """Several reads in ONE rolled-back transaction as `user`; each read is wrapped in
    pg_temp.try so an expected refusal comes back as {"error": …} instead of aborting."""
    who = f"select set_config('sim.uid', '{bid(user)}', true); set local role authenticated;"
    body = ' '.join((f"select 'OUT:' || pg_temp.run($q${r[1:]}$q$)::text;" if r.startswith('!')
                     else f"select 'OUT:' || pg_temp.try($q${r}$q$)::text;") for r in reads)
    out = sql(f"""begin; create function pg_temp.try(q text) returns jsonb language plpgsql as $f$
                  declare r jsonb; begin execute 'select (' || q || ')::jsonb' into r; return r;
                  exception when others then return jsonb_build_object('error', sqlerrm); end $f$;
                  create function pg_temp.run(q text) returns jsonb language plpgsql as $f$
                  begin execute q; return jsonb_build_object('ok', true);
                  exception when others then return jsonb_build_object('error', sqlerrm); end $f$;
                  grant execute on function pg_temp.try(text) to authenticated;
                  grant execute on function pg_temp.run(text) to authenticated;
                  {setup}; {who} {body} rollback;""")
    return [json.loads(l[4:]) for l in out.splitlines() if l.startswith('OUT:')]
R = bid(20201)   # golfer 2's round, week 1
PHOTO = f"update rounds set photo_path = '{bid(2)}/photo.jpg' where id = '{R}'"
A = lambda n: 'a0000000-0000-4000-8000-' + str(n).zfill(12)
prep = lambda att, inc: f"public.prepare_round_share('{R}', {str(inc).lower()}, '{A(att)}')"
fin = lambda att, done: f"public.finish_round_share('{A(att)}', {str(done).lower()})"
stat = f"public.round_share_status('{R}')"
s = steps(PHOTO, [prep(1, True), fin(1, True), stat,                      # 0-2 first share, completed
                  prep(2, True), fin(2, False), stat,                     # 3-5 reuse, then cancel the reuse
                  prep(3, False), stat, fin(3, False), stat,              # 6-9 consent change, then cancel it
                  prep(1, True), fin(1, True), fin(3, True)], user=2)     # 10-12 idempotence, late ack
t1 = s[0]['token']
check('I5b first share: a new token, created, photo included', s[0]['created'] and s[0]['include_photo'], s[0])
check('I5b completion makes the link durable', s[1]['active'] and s[2]['token'] == t1 and not s[2]['cleanup_pending'], (s[1], s[2]))
check('I5b same consent reuses the completed link', s[3]['token'] == t1 and s[3]['created'] is False, s[3])
check('I5b cancelling a REUSED link leaves it live', s[4]['state'] == 'cancelled' and s[5]['token'] == t1, (s[4], s[5]))
check('I5b a changed consent rotates: new token, old queued for cleanup',
      s[6]['created'] and s[6]['token'] != t1 and s[6].get('rotated') and s[7]['cleanup_pending'] and s[7]['token'] is None, (s[6], s[7]))
check('I5b cancelling a NEW token retires only it', s[8]['state'] == 'cancelled' and not s[8]['active']
      and any(c['token'] == s[6]['token'] for c in s[9]['cleanup']), (s[8], s[9]))
check('I5b prepare and finish are idempotent on the attempt', s[10]['token'] == t1 and s[10]['state'] == 'completed' and s[11]['state'] == 'completed', (s[10], s[11]))
check('I5b a late ack never reactivates a cancelled link', s[12]['state'] == 'cancelled' and not s[12]['active'], s[12])

c = steps(PHOTO, [prep(21, True), prep(22, True)], user=2)
check('I5b a second attempt never borrows or revokes an open one', 'already being shared' in c[1].get('error', ''), c)
EXPIRE = PHOTO + f"; select public.prepare_round_share('{R}', true, '{A(31)}'); update share_attempts set lease_expires_at = now() - interval '1 minute' where attempt_id = '{A(31)}'"
e = steps(EXPIRE.replace("select public.prepare", "select set_config('sim.uid','" + bid(2) + "',true); select public.prepare"), [prep(32, True), fin(31, True), stat], user=2)
check('I5b an abandoned preparation is reclaimed when its lease lapses', e[0].get('created') and e[1]['state'] == 'expired' and not e[1]['active'], e[:2])
w = steps(PHOTO, [prep(41, True), f"(select to_jsonb(public.clear_round_photo('{R}')))", fin(41, True), stat], user=2)
check('I5b a withdrawal during a preparation is never undone by its completion', w[2]['active'] is False and w[3]['token'] is None and w[3]['cleanup_pending'], w[2:])
LEGACY = PHOTO + f"; insert into shares (kind, ref_id, created_by) values ('round', '{R}', '{bid(2)}')"
g = steps(LEGACY, [prep(51, False)], user=2)
check('I5b a legacy link with unrecorded consent is rotated, not guessed', g[0].get('created') and g[0].get('rotated'), g)
o = steps(PHOTO, [prep(61, True), stat], user=3)
check('I5b another golfer can neither prepare nor read my round\'s share', 'error' in o[0] and 'error' in o[1], o)

# ── the payload fields · renewal_status beside in_season ─────────────────────────────────
S2 = f"""insert into seasons (id, league_id, number, starts_on, ends_on, status) values ('{bid(291)}', '{bid(101)}', 2, current_date + 10, current_date + 80, 'active');
         update seasons set status = 'complete' where id = '{bid(201)}'"""
def renewal(extra):
    h = tx(S2 + '; ' + extra, 'public.native_home()', user=2)
    m = next(x for x in h['memberships'] if x['league_id'] == bid(101))
    return m.get('renewal_status'), m.get('in_season')
check('renewal: an unanswered season two with no invitation is pending, not in season', renewal('select 1') == ('pending', False), renewal('select 1'))
INV = lambda st: f"insert into member_invites (league_id, profile_id, invited_by, status) values ('{bid(101)}', '{bid(2)}', '{bid(1)}', '{st}')"
check('renewal: a declined invitation reads declined', renewal(INV('declined')) == ('declined', False), renewal(INV('declined')))
check('renewal: a lapsed invitation reads expired', renewal(INV('lapsed')) == ('expired', False), renewal(INV('lapsed')))
check('renewal: a yes on record reads accepted and in season',
      renewal(f"update league_members set agreed_seasons = '{{1,2}}' where id = '{bid(11102)}'") == ('accepted', True))

# ── I6 · the Cup Final names its own seeds ───────────────────────────────────────────────
# League 100 in a Final whose drawn seeds are the two squads at the BOTTOM of the live table.
FINAL = f"""update league_settings set finish = 'cup_final' where league_id = '{bid(100)}';
  update seasons set status = 'cup_final', ends_on = current_date + 20 where id = '{bid(200)}';
  insert into cup_finalists (season_id, squad_id, seed, head_start, seed_rung)
  select '{bid(200)}', x.squad_id, row_number() over (order by x.points asc), 0, null
    from (select squad_id, points from v_squad_standings where season_id = '{bid(200)}' order by points asc limit 2) x"""
scen = tx(FINAL, f"public.season_scenarios('{bid(200)}')", user=2)
seeded = {r['id'] for r in scen['rows'] if r.get('seed')}
table_top = {r['id'] for r in sorted(scen['rows'], key=lambda r: -r['points'])[:2]}
check('I6 scenarios: locked, and the clinched rows are exactly the drawn seeds',
      scen['meta']['locked'] and {r['id'] for r in scen['rows'] if r['clinched']} == seeded and len(seeded) == 2, scen['meta'])
check('I6 scenarios: the live table\'s top two are not called seeds', not (table_top & seeded) and all(
      r['eliminated'] for r in scen['rows'] if r['id'] in table_top), [(r['name'], r['points'], r.get('seed')) for r in scen['rows']])
check('I6 scenarios: meta names the seeds in order, and rank stays the points rank',
      [s_['seed'] for s_ in scen['meta']['seeds']] == [1, 2] and min(r['rank'] for r in scen['rows'] if r['id'] in table_top) == 1)
story = tx(FINAL, f"public.season_story('{bid(200)}', null)", user=2)
fin_ = story.get('facts', story).get('final') if isinstance(story, dict) else None
fin_ = fin_ or next((v for k, v in story.items() if isinstance(v, dict) and 'seats' in v), None) if isinstance(story, dict) else None
check('I6 story: the Final facts carry locked, the drawn seeds and the race',
      fin_ is not None and fin_.get('locked') and len(fin_.get('seeds', [])) == 2 and fin_.get('race') is not None, str(fin_)[:300])

# ── S1–S12 re-verified on the combined chain (main + every repair) ───────────────────────
PRO = 1   # profile 1 is every fixture league's Pro
s1 = steps('', [f"(select to_jsonb(count(*)) from seasons where id = '{bid(200)}')",
                f"!update seasons set status = 'complete' where id = '{bid(200)}'",
                f"!insert into season_adjustments (season_id, member_id, month, kind, points) values ('{bid(200)}', '{bid(11002)}', '2026-08-01', 'override', 40)"], user=PRO)
check('S1: the Pro reads the season but cannot rewrite it or the ledger directly',
      s1[0] == 1 and 'permission denied' in s1[1].get('error', '') and 'permission denied' in s1[2].get('error', ''), s1)
late = tx(f"update seasons set status = 'complete' where id = '{bid(203)}'; " +
          f"insert into rounds (id, profile_id, course_label, played_on, holes_played, gross, rating, slope, index_at_post, differential, created_at) values ('{bid(29990)}', '{bid(2)}', 'Late', '2026-08-01', 18, 70, 72, 113, 12, -2, now())",
          f"(select jsonb_build_object('booked', (select count(*) from season_book_rows where season_id = '{bid(203)}'), 'late_in_lens', exists (select 1 from v_rounds_ranked where season_id = '{bid(203)}' and round_id = '{bid(29990)}')))")
check('S2: a completed season is booked, and a round posted after the close never enters it', late['booked'] > 0 and not late['late_in_lens'], late)
short = tx(f"update seasons set ends_on = starts_on + 27, status = 'active' where id = '{bid(201)}'; update league_settings set finish = 'cup_final' where league_id = '{bid(101)}'",
           f"(select jsonb_build_object('guard', position('[D384]' in pg_get_functiondef('public.daily_season_tick'::regproc)) > 0))")
check('S4: the tick carries the short-season guard', short['guard'])
s6 = tx('', "(select jsonb_build_object('lock', position('for update' in pg_get_functiondef('public.claim_round'::regproc)) > 0, 'trim', position('[S6]' in pg_get_functiondef('public.guest_live_state'::regproc)) > 0))")
check('S6: a claim locks its seat and a spent guest link shows its status only', s6['lock'] and s6['trim'])
TROPHY = f"""update seasons set status = 'complete', champion_member_id = '{bid(11101)}', points_king_member_id = '{bid(11101)}' where id = '{bid(201)}';
  insert into posts (league_id, season_id, kind, body) values ('{bid(101)}', '{bid(201)}', 'system', 'closed');
  insert into seasons (id, league_id, number, starts_on, ends_on, status, champion_member_id, points_king_member_id)
  values ('{bid(292)}', '{bid(101)}', 2, '2026-10-19', '2026-11-29', 'active', null, null);
  update seasons set status = 'complete', champion_member_id = '{bid(11101)}', points_king_member_id = '{bid(11101)}' where id = '{bid(292)}';
  select public.award_season_trophies('{bid(201)}'); select public.award_season_trophies('{bid(292)}')"""
tro = tx(TROPHY, f"(select to_jsonb(count(*)) from trophies where profile_id = '{bid(1)}' and league_id = '{bid(101)}' and placement = 'winner')")
check('S8: two seasons won in one year are two Champion trophies', tro == 2, tro)
rc = tx('', f"(select public.round_card('{bid(20201)}'))", user=2)
check('S10: the receipt explains a round with the league\'s own number', 'pvi' in rc and '[D387]' in sql("select pg_get_functiondef('public.round_card'::regproc)"), str(rc)[:120])
nine = tx(f"insert into rounds (id, profile_id, course_label, played_on, holes_played, gross, rating, slope, index_at_post, differential, created_at) values ('{bid(29991)}', '{bid(17)}', 'Nine', current_date - 1, 9, 38, 35, 113, 12, 3, now())",
          f"(select to_jsonb(bool_or(is_sub80)) from public.home_stories(21, null) where round_id = '{bid(29991)}')", user=17)
check('S12: a nine-hole 38 is not "Under 80 for the first time"', nine is False or nine is None, nine)

print(f"{sum(ok for _, ok in checks)}/{len(checks)} repair checks passed")
sys.exit(0 if all(ok for _, ok in checks) else 1)

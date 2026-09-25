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

print(f"{sum(ok for _, ok in checks)}/{len(checks)} repair checks passed")
sys.exit(0 if all(ok for _, ok in checks) else 1)

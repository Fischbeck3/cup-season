#!/usr/bin/env python3
"""D356 / D375 · exercise the two doors this checkpoint repaired, against the REAL
functions in a disposable PostgreSQL cluster built from the whole migration
chain. No database URL and no production option exists.

  1 · a Major invitation must seat a golfer the way every other door does.
      `respond_invite` used to insert (event_id, profile_id, seed) and nothing
      else, so `event_players.exhibition` took its default of false and a
      golfer with no established number was ranked for the jug and counted
      into the pot — against the rule both clients print in the room.

  2 · `run_it_back` must not report a length change it cannot establish.
      `v_months is distinct from v_settings.season_months` is TRUE whenever the
      stored value is NULL, which set every member's invitation back to pending
      and announced "The length changed" when nothing had.
"""
from pathlib import Path
import json, re, subprocess, tempfile

ROOT = Path(__file__).resolve().parents[1]
BIN = Path("/opt/homebrew/opt/postgresql@17/bin")
PORT = "55441"

PRO   = "d0000000-0000-4000-8000-000000000001"
NEW   = "d0000000-0000-4000-8000-000000000002"   # no rounds: no established number
OLD   = "d0000000-0000-4000-8000-000000000003"   # three rounds: established

def run(args, **kw):
    p = subprocess.run([str(x) for x in args], capture_output=True, text=True, **kw)
    if p.returncode:
        raise RuntimeError(p.stderr[-4000:] or p.stdout[-4000:])
    return p.stdout

def require(ok, label):
    if not ok:
        raise AssertionError(label)
    print("PASS", label, flush=True)

with tempfile.TemporaryDirectory(prefix="cs-events-consent-") as temp:
    tmp = Path(temp); data = tmp / "data"; sock = tmp / "socket"; sock.mkdir()
    run([BIN/"initdb", "-D", data, "-U", "sim", "-A", "trust", "-E", "UTF8", "--no-locale"])
    run([BIN/"pg_ctl", "-D", data, "-l", tmp/"postgres.log", "-o",
         f"-F -k {sock} -p {PORT} -c listen_addresses='' -c wal_level=logical", "-w", "start"])
    try:
        base = [BIN/"psql", "-h", sock, "-p", PORT, "-X", "-q", "-v", "ON_ERROR_STOP=1"]
        run(base + ["-U", "sim", "-d", "postgres", "-c", "create database cupseason"])
        run(base + ["-U", "sim", "-d", "cupseason", "-f", ROOT/"tests/fixtures/release-bootstrap.sql"])
        chain = base + ["-U", "postgres", "-d", "cupseason", "--single-transaction"]
        for f in sorted((ROOT/"supabase/migrations").glob("*.sql")):
            body = re.sub(r'^\s*create extension if not exists (?:"supabase_vault"|pg_cron|pg_net).*?;[^\n]*$',
                          "-- Local service stub; canonical migration is unchanged.",
                          f.read_text(), flags=re.I|re.M)
            try:
                run(chain, input=body)
            except Exception as exc:
                raise RuntimeError(f"Migration failed: {f.name}\n{exc}") from exc
        run(chain, input=(ROOT/"tests/fixtures/release-post-bootstrap.sql").read_text())

        def sql(q, user=PRO, role="authenticated", error=None):
            prefix = f"set sim.uid = '{user}';"
            if role: prefix += f"set role {role};"
            p = subprocess.run([str(x) for x in base + ["-U", "postgres", "-d", "cupseason", "-t", "-A"]],
                               input=prefix + q, capture_output=True, text=True)
            if error:
                require(p.returncode != 0 and error in p.stderr, "rejects " + error)
                return ""
            if p.returncode:
                raise RuntimeError(p.stderr[-3000:])
            return p.stdout.strip()

        # ── the cast ────────────────────────────────────────────────────────
        run(chain, input=f"""
          insert into auth.users(id,email) values
            ('{PRO}','pro@example.test'),('{NEW}','new@example.test'),('{OLD}','old@example.test');
          update profiles set display_name='Pro',    handle='pro', marker='jug'     where id='{PRO}';
          update profiles set display_name='Newcomer',handle='new', marker='azalea' where id='{NEW}';
          update profiles set display_name='Regular', handle='old', marker='no2'    where id='{OLD}';
        """)
        # three real rounds give OLD an established number; NEW posts none.
        run(chain, input=f"""
          insert into rounds(profile_id, played_on, gross, rating, slope, holes_played, course_label)
          select '{OLD}', current_date - g, 84, 71.2, 128, 18, 'Saguaro Flats' from generate_series(1,3) g;
        """)
        require(sql(f"select handicap_index('{OLD}') is not null;", role=None) == "t",
                "three rounds establish a number")
        require(sql(f"select handicap_index('{NEW}') is null;", role=None) == "t",
                "no rounds means no established number")

        # ── 1 · a Major invitation seats by the rule ────────────────────────
        lid = sql("select (create_league('Jug Club','JUGC')->'league'->>'id');")
        sql(f"select lock_league(p_league => '{lid}'::uuid);")
        for who in (NEW, OLD):
            sql(f"insert into league_members(league_id, profile_id, role) values('{lid}','{who}','player');", role=None)
        eid = sql(f"select create_major(p_name => 'The Bloom', p_final_on => current_date + 2, p_days => 3, p_buy_in => 0, p_league => '{lid}'::uuid)::text;")

        for who, want, label in ((NEW, "t", "a golfer with no established number is seated as an exhibition"),
                                 (OLD, "f", "a golfer with an established number is seated for the jug")):
            iv = sql(f"select invite_golfer(null,'{eid}'::uuid,'{who}'::uuid);")
            sql(f"select respond_invite('{iv}'::uuid, true);", user=who)
            got = sql(f"select exhibition from event_players where event_id='{eid}' and profile_id='{who}';", role=None)
            require(got == want, label)

        require(sql(f"select count(*) from event_players where event_id='{eid}';", role=None) == "3",
                "the organizer and both invitees hold seats")

        # A Ryder has no established-number rule, so its seat keeps the default.
        rid = sql(f"select create_event('The Clash', (date_trunc('week', current_date)::date + 6), 4, 1, 'team_pvi', 'Fixture Owls', 'Fixture Foxes', '{lid}'::uuid)::text;")
        iv = sql(f"select invite_golfer(null,'{rid}'::uuid,'{NEW}'::uuid);")
        sql(f"select respond_invite('{iv}'::uuid, true);", user=NEW)
        require(sql(f"select exhibition from event_players where event_id='{rid}' and profile_id='{NEW}';", role=None) == "f",
                "a Ryder seat is unaffected — it has no established-number rule to apply")

        require(sql(f"select status from member_invites where event_id='{rid}' and profile_id='{NEW}';", role=None) == "accepted",
                "accepting still records the acceptance")

        # ── 2 · the reported `run_it_back` length bug is UNREACHABLE ───────
        # `v_months is distinct from v_settings.season_months` would be TRUE for
        # a NULL, firing the covenant refire and announcing a change nobody
        # made. The column cannot hold a NULL — `integer DEFAULT 9 NOT NULL` in
        # the baseline, never relaxed — so the comparison is correct for every
        # value it can take. `run_it_back` is therefore left alone, and this is
        # the proof rather than a claim.
        sql(f"update league_settings set season_months = null where league_id='{lid}';",
            role=None, error="violates not-null constraint")

        # D375 supersedes D243's automatic re-seat: only the Pro's tap is
        # a yes. Everyone else receives the covenant invitation again.
        sql(f"update seasons set status='complete', ends_on = current_date - 1 where league_id='{lid}';", role=None)
        renewal = json.loads(sql(f"select run_it_back('{lid}'::uuid)::text;"))
        season_number = renewal["season"]["number"]
        require(renewal["seated"] == renewal["agreed"] == 1,
                "run it back records only the Pro's yes")
        require(renewal["asked"] == renewal["invited"] == 2,
                "both other members receive a new covenant invitation")
        require(sql(f"select count(*) from league_members where league_id='{lid}' and left_at is null;", role=None) == "3",
                "renewal retains the roster without inserting membership rows")
        for who, expected in ((PRO, "t"), (NEW, "f"), (OLD, "f")):
            require(sql(f"select {season_number} = any(agreed_seasons) from league_members where league_id='{lid}' and profile_id='{who}';", role=None) == expected,
                    "renewal records the current season only for the member who said yes")
        require(sql(f"select count(*) from member_invites where league_id='{lid}' and status='pending';", role=None) == "2",
                "the outstanding asks are pending invitations")
        invitation = sql(f"select id from member_invites where league_id='{lid}' and profile_id='{NEW}';", role=None)
        sql(f"select respond_invite('{invitation}'::uuid, true);", user=NEW)
        require(sql(f"select {season_number} = any(agreed_seasons) from league_members where league_id='{lid}' and profile_id='{NEW}';", role=None) == "t",
                "accepting the renewal covenant records that member's yes")
        require(sql(f"select {season_number} = any(agreed_seasons) from league_members where league_id='{lid}' and profile_id='{OLD}';", role=None) == "f",
                "another member's acceptance never seats the still-pending member")
        repeated = json.loads(sql(f"select run_it_back('{lid}'::uuid)::text;"))
        require(repeated["already_running"] and repeated["agreed"] == 2 and repeated["asked"] == 1,
                "a repeated renewal counts recorded yeses and remaining asks")
        require(sql(f"select count(*) from buy_ins b join seasons s on s.id=b.season_id where s.league_id='{lid}';", role=None) == "0",
                "and marks nobody paid")

        print("PASS — D356 / D375 · Major seating, the length constraint, and renewal's recorded consent", flush=True)
    finally:
        run([BIN/"pg_ctl", "-D", data, "-m", "immediate", "-w", "stop"])

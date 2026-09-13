"""Drive the REAL Cup Season engine in the isolated sandbox.

Uses the same RPCs a client calls (create_league, add_friend_to_league,
lock_league, assign_player, start_season, post_round, delete_round) and the
cron entry points called explicitly (close_month, enter_cup_final,
close_season), since pg_cron does not run in the sandbox.

Sandbox: scratchpad/sim/apply.sh builds it; port 5470, superuser `postgres`.
Identity is set per call with set_config('sim.uid', ...) which the stub
auth.uid() reads.

SANDBOX OVERRIDES (each is a place the replay is not exactly production):
  O1  the caller is a superuser, so RLS/GRANTs are bypassed; in-body guards
      (auth.uid(), is_commissioner) still run.
  O2  friendships are inserted directly (no request/accept round trip).
  O3  a late joiner's league_members.joined_at is set to the join date after
      add_friend_to_league (the RPC stamps now()); D161 reads joined_at.
  O4  rounds are posted with real-time created_at (today), so anything keyed
      on created_at (suspension cut-offs, 'posted late') is not modelled.
  O5  months are closed by calling close_month(season, month) directly, in
      order, after all of that month's rounds are posted — the cron would do
      the same on the 1st. enter_cup_final / close_season are called at the
      end; the daily tick's own sequencing is not exercised.
"""
from __future__ import annotations
import json, subprocess, uuid, os, secrets
from datetime import date, timedelta
from golfers import Golfer, Round, RATING, SLOPE, month_days

PSQL = ["/opt/homebrew/opt/postgresql@17/bin/psql", "-h", "/tmp", "-p", os.environ.get("SIM_PORT", "5470"), "-U", "postgres", "cupseason", "-tA", "-v", "ON_ERROR_STOP=1"]

def _uid(name: str) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, "sim." + name))

class Real:
    def __init__(self, tag: str):
        self.tag = tag  # unique per run so leagues never collide

    def sql(self, q: str, uid: str | None = None, role: str = "authenticated") -> str:
        pre = f"select set_config('sim.uid', '{uid or ''}', false), set_config('sim.role', '{role}', false);\n"
        r = subprocess.run(PSQL, input=pre + q, capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError(f"SQL failed: {r.stderr.strip()}\n--- {q[:400]}")
        lines = [l for l in r.stdout.strip().split("\n") if l]
        return lines[-1] if lines else ""

    def one(self, q, uid=None):
        return self.sql(q, uid)

    # ------------------------------------------------------------ setup
    def setup(self, G: dict[str, Golfer], bylaws, start: date, end: date, squads: list[str]):
        self.run = secrets.token_hex(2)
        self.uid = {n: _uid(f"{self.tag}.{self.run}.{n}") for n in G}   # fresh identities per run
        for n, u in self.uid.items():
            self.sql(f"insert into auth.users(id, email, raw_user_meta_data, created_at) values ('{u}','{u[:8]}@sim.invalid','{{}}', now()) on conflict do nothing;")
            self.sql(f"select set_profile('{n}', 'Tempe', null, null, null, null, null, null);", u)
        pro = next(iter(G)); self.pro = self.uid[pro]
        code = ("S" + secrets.token_hex(3)).upper()   # unique per invocation; leagues_code_key is unique
        j = json.loads(self.one(f"select create_league('Sim {self.tag}', '{code}');", self.pro))
        self.league = j.get("id") or j.get("league_id") or j["league"]["id"]
        # D112/D180: joins are refused in setup; the roster door opens at LOCK.
        structure = {1: "solo", 2: "squads2", 3: "squads3"}.get(len(squads), "squads4")
        months = max(1, round((end - start).days / 30))
        self.sql(f"""select lock_league('{self.league}', 'Sim {self.tag}', 'standard', {bylaws.allowance}, 'attested',
                    {bylaws.cap}, {bylaws.floor}, '{bylaws.penalty}', 'points', '{structure}', {getattr(bylaws,'buyin_cents',0)}, {months},
                    'random', 'cup_final', 60, 25, 15, '{start}', '{end}', null);""", self.pro)
        for n, u in self.uid.items():
            if u == self.pro: continue
            self.sql(f"insert into friendships(requester, addressee, status) values ('{self.pro}','{u}','accepted') on conflict do nothing;")
            self.sql(f"select add_friend_to_league('{self.league}','{u}');", self.pro)
        self.season = self.one(f"select id from seasons where league_id='{self.league}' order by number desc limit 1;")
        # squads in creation order -> the scenario's labels in order
        rows = self.one(f"select string_agg(id::text, ',' order by color) from squads where season_id='{self.season}';")
        self.squad_ids = dict(zip(squads, rows.split(","))) if rows else {}
        self.member = {n: self.one(f"select id from league_members where league_id='{self.league}' and profile_id='{u}';") for n, u in self.uid.items()}
        for n, g in G.items():
            if g.join_offset_days == 0 and self.squad_ids:
                self.sql(f"select assign_player('{self.squad_ids[g.squad]}','{self.member[n]}');", self.pro)
        self.sql(f"select start_season('{self.season}');", self.pro)
        self.late = {n: g for n, g in G.items() if g.join_offset_days > 0}
        self.start, self.end = start, end
        return self

    def late_join(self, n: str, g: Golfer, on: date):
        """O3: the Pro adds a golfer mid-season; joined_at is set to the join date."""
        self.sql(f"update league_members set joined_at = '{on}'::timestamptz where id='{self.member[n]}';")
        if self.squad_ids:
            self.sql(f"select assign_player('{self.squad_ids[g.squad]}','{self.member[n]}');", self.pro)

    # ------------------------------------------------------------ play
    def post(self, n: str, r: Round) -> str:
        j = self.one(f"""select post_round({r.gross}, {RATING}, {SLOPE}, 18, null, null, 'Sim Course', '{r.played_on}', null, '{{}}'::uuid[]);""", self.uid[n])
        try:
            d = json.loads(j); return d.get("id") or d.get("round", {}).get("id") or j
        except Exception:
            return j

    def delete(self, n: str, round_id: str):
        self.sql(f"select delete_round('{round_id}');", self.uid[n])

    def close_months(self):
        for mi, a, b in month_days(self.start, self.end):
            self.sql(f"select close_month('{self.season}', '{date(a.year, a.month, 1)}');")

    def finish(self):
        self.sql(f"select enter_cup_final('{self.season}');")
        self.sql(f"select close_season('{self.season}');")

    # ------------------------------------------------------------ read
    def read(self) -> dict:
        def rows(q):
            out = subprocess.run(PSQL + ["-c", q], capture_output=True, text=True).stdout.strip()
            return [l.split("|") for l in out.split("\n") if l]
        squads = {s: int(p) for s, p in rows(f"select q.name, coalesce(v.points,0) from squads q left join v_squad_standings v on v.squad_id=q.id where q.season_id='{self.season}'")}
        # map engine squad names back to scenario labels
        name_to_label = {}
        for lab, sid in self.squad_ids.items():
            nm = self.one(f"select name from squads where id='{sid}'"); name_to_label[nm] = lab
        squads = {name_to_label.get(k, k): v for k, v in squads.items()}
        ind = {}
        for pid, pts, rp in rows(f"select p.display_name, coalesce(v.points,0), coalesce(v.rounds_posted,0) from league_members lm join profiles p on p.id=lm.profile_id left join v_individual_standings v on v.member_id=lm.id and v.season_id='{self.season}' where lm.league_id='{self.league}'"):
            ind[pid] = {"points": int(pts), "rounds": int(rp)}
        counting = {}
        for pid, cnt, pts, pvi in rows(f"""select p.display_name, count(*) filter (where r.month_rank <= coalesce(ls.counting_cap,999)), coalesce(sum(r.points) filter (where r.month_rank <= coalesce(ls.counting_cap,999)),0), round(avg(r.pvi),2)
              from v_rounds_ranked r join league_members lm on lm.id=r.member_id join profiles p on p.id=lm.profile_id join league_settings ls on ls.league_id=lm.league_id
              where r.season_id='{self.season}' group by p.display_name"""):
            counting[pid] = {"counting": int(cnt), "counting_points": int(pts), "avg_pvi": float(pvi) if pvi else None}
        adj = [(k, m, int(a), (r or '')[:60]) for k, m, a, r in rows(f"select kind, to_char(month,'YYYY-MM'), coalesce(points,0), coalesce(reason,'') from season_adjustments where season_id='{self.season}' and kind<>'month_closed' order by month, kind")]
        cup = rows(f"select q.name, cf.seed, cf.head_start, coalesce(cf.seed_rung,'') from cup_finalists cf join squads q on q.id=cf.squad_id where cf.season_id='{self.season}' order by cf.seed")
        cup = [(name_to_label.get(n, n), int(s), int(h), r) for n, s, h, r in cup]
        se = rows(f"select status, coalesce(champion_score::text,''), coalesce(tiebreak_rung,''), coalesce((select name from squads where id=seasons.champion_squad_id),'') from seasons where id='{self.season}'")
        se = se[0] if se else []
        if se: se[3] = name_to_label.get(se[3], se[3])
        pay = rows(f"select coalesce(kind,''), coalesce(cents,0)::text, coalesce(p.display_name,'') from season_payouts sp left join league_members lm on lm.id=sp.member_id left join profiles p on p.id=lm.profile_id where sp.season_id='{self.season}' order by 1,3")
        pot = rows(f"select coalesce(pot_cents,0), coalesce(collected_cents,0) from seasons where id='{self.season}'")
        return {"squads": squads, "individual": ind, "counting": counting, "adjustments": adj, "cup_finalists": cup, "payouts": pay, "pot": pot[0] if pot else None,
                "season": {"status": se[0] if se else None, "champion_score": se[1] if se else None, "tiebreak_rung": se[2] if se else None, "champion": se[3] if se else None}}

"""A Python MIRROR of the Cup Season scoring engine.

THIS IS AN APPROXIMATION. It exists so scenarios can run without a database
and so the real engine's answers can be checked against an independent
reading of the spec. Every place it might differ from the deployed SQL is
marked `APPROX:` and listed by `assumptions()`. Where the sandbox is
available, `run.py` runs both and reports every disagreement.

Rules mirrored, with their source:
  spec §2.1 formulas · §2.2 bands · §3.1 cap (D142 default 3) · §3.2 floor,
  penalties, one bye (auto-bye per CLAUDE.md) · §14.0 floors waived in partial
  edge months · §14.1 late join before/after the 15th · §14.3 Cup Final
  fresh window, seeds at ends_on-27, tie ladder · §5 WHS-style index.
"""
from __future__ import annotations
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP

def r1(x) -> float:
    """Round to 1dp the way POSTGRES numeric does: half away from zero.
    Python's float round() is half-to-even on a binary approximation, so
    round(0.15,1)=0.1 where Postgres gives 0.2. PvI is rounded to 1dp and the
    band edges are exact comparisons, so the rounding MODE decides a band
    whenever PvI lands on x.x5. Any second implementation in IEEE floats
    (a browser prototype, a spreadsheet) will disagree with the engine there."""
    return float(Decimal(repr(float(x))).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))
from typing import Iterable
from golfers import Round, Golfer, month_days

# ---------------------------------------------------------------- index (§5)
# APPROX: WHS adjustment table for < 20 differentials, from the USGA 2020
# table. The engine's `handicap_index_asof()` "takes the best m of the last
# 20 through the WHS adjustment table and nothing else". Validate m and the
# adjustments against the dumped function before trusting a single value.
# DEPLOYED table, read from handicap_index_asof() in production 2026-09-12.
# It is NOT the WHS 2020 table: c=18 uses m=7 (WHS 6) and c=9..11 carry a
# -1.0 adjustment WHS does not. Kept as the engine has it.
def _m_adj(n):
    if n <= 5: m = 1
    elif n <= 8: m = 2
    elif n <= 11: m = 3
    elif n <= 14: m = 4
    elif n <= 16: m = 5
    elif n == 17: m = 6
    elif n == 18: m = 7
    else: m = 8
    adj = {3: -2.0, 4: -1.0, 6: -1.0}.get(n, -1.0 if 9 <= n <= 11 else 0.0)
    return m, adj
ESTABLISH_AT = 3   # spec: "establishes at 3 rounds"

def whs_index(diffs_newest_last: list[float]) -> float | None:
    last = diffs_newest_last[-20:]
    n = len(last)
    if n < ESTABLISH_AT: return None
    m, adj = _m_adj(n)
    best = sorted(last)[:m]
    return r1(sum(best) / m + adj)

# ------------------------------------------------------------ points (§2.1-2)
def pvi(index: float, allowance_pct: int, differential: float) -> float:
    """DECIMAL end to end, because the engine is.

    `v_rounds_ranked` computes `round(index_at_post * allowance/100 - differential, 1)`
    in Postgres NUMERIC, which is exact base-10. In IEEE doubles
    9.0 * 95/100 is 8.550000000000001, so 8.55 - 9.5 comes out -0.9499999999999993
    and rounds to -0.9 where the engine gets exactly -0.95 and rounds to -1.0.
    That is band 7 versus band 6 on the same round. Any reimplementation in
    floats (a browser prototype, a spreadsheet) inherits this."""
    d = (Decimal(str(index)) * Decimal(allowance_pct) / Decimal(100)) - Decimal(str(differential))
    return float(d.quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))

def band(p: float) -> int:
    # spec §2.2: +3.0 or better 12 · +1.0..+2.9 9 · −0.9..+0.9 7 · −3.0..−1.0 6 · worse 5
    # APPROX: the spec has a GAP between −1.0 and −0.9 (e.g. −0.95). Mirrored as
    # "> −1.0 is 7". Check `cup_points()` for the deployed boundary.
    if p >= 3.0:  return 12
    if p >= 1.0:  return 9
    if p > -1.0:  return 7
    if p >= -3.0: return 6
    return 5

# -------------------------------------------------------------- counting (§3)
@dataclass
class Bylaws:
    allowance: int = 95
    cap: int = 3              # D142 default
    floor: int = 2
    penalty: str = "deduct"   # none | deduct(-5/short) | forfeit
    bye_per_season: int = 1
    weeks: int = 13           # D206 default
    structure: str = "squads4" # squads2 => seed #1 gets +10 in the Final
    buyin_cents: int = 0
    final_days: int = 28      # §14.3 "final four weeks"

@dataclass
class Scored:
    r: Round
    index_at_post: float | None
    pvi: float | None
    points: int
    provisional: bool
    counting: bool = False

def score_rounds(golfer_rounds: dict[str, list[Round]], prior: dict[str, list[Round]],
                 bylaws: Bylaws) -> dict[str, list[Scored]]:
    """Score every round in posting order with the index AS OF that post
    (§16: 'every round snapshots how the handicap was known').
    D49: provisional rounds (index not yet established) score NORMALLY and are
    badged. APPROX: a golfer with NO prior differentials at all has no index;
    we score their first ESTABLISH_AT-1 rounds at the 7-point band as the only
    defensible stand-in, and mark them provisional. Check what post_round does
    when index_at_post is null."""
    out: dict[str, list[Scored]] = {}
    for g, rounds in golfer_rounds.items():
        hist = [r.differential for r in sorted(prior.get(g, []), key=lambda r: r.played_on)]
        scored = []
        for r in sorted(rounds, key=lambda r: (r.posted_on, r.played_on)):
            idx = whs_index(hist)
            if idx is None:
                scored.append(Scored(r, None, None, 7, True))
            else:
                p = pvi(idx, bylaws.allowance, r.differential)
                scored.append(Scored(r, idx, p, band(p), len(hist) < 20 and len(hist) < ESTABLISH_AT))
            # DEPLOYED: delete_round recomputes profiles.index_current but every
            # round already posted keeps its index_at_post snapshot. In these
            # scenarios the deletion happens after all posts, so the deleted round
            # was a real fact for every index taken after it: keep it in `hist`.
            hist.append(r.differential)
        out[g] = scored
    return out

def counting_for_month(scored: list[Scored], a: date, b: date, cap: int) -> list[Scored]:
    """Best `cap` by points within [a, b]. DEPLOYED order (v_rounds_ranked month_rank):
    points desc, pvi desc, played_on DESC — the LATER round wins a full tie."""
    inm = [s for s in scored if a <= s.r.played_on <= b and not s.r.voided]
    inm.sort(key=lambda s: (-s.points, -(s.pvi or 0), -s.r.played_on.toordinal()))   # deployed: played_on DESC
    for s in inm: s.counting = False
    for s in inm[:cap]: s.counting = True
    return inm

@dataclass
class MonthLine:
    month: int; a: date; b: date
    partial: bool
    per_golfer_points: dict[str, int] = field(default_factory=dict)
    per_golfer_rounds: dict[str, int] = field(default_factory=dict)
    penalties: dict[str, int] = field(default_factory=dict)   # negative
    byes_used: set = field(default_factory=set)
    forfeits: set = field(default_factory=set)

def close_months(scored: dict[str, list[Scored]], golfers: dict[str, Golfer],
                 start: date, end: date, bylaws: Bylaws) -> list[MonthLine]:
    byes_left = {g: bylaws.bye_per_season for g in golfers}
    lines = []
    for mi, a, b in month_days(start, end):
        full_a = date(a.year, a.month, 1)
        nxt = date(a.year + a.month // 12, a.month % 12 + 1, 1)
        full_b = nxt - timedelta(days=1)
        partial = (a != full_a) or (b != full_b)   # §14.0 partial edge month
        ml = MonthLine(mi, a, b, partial)
        for g, gl in golfers.items():
            cnt = counting_for_month(scored.get(g, []), a, b, bylaws.cap)
            n_rounds = len(cnt)
            pts = sum(s.points for s in cnt if s.counting)
            ml.per_golfer_rounds[g] = n_rounds
            # D161 (supersedes spec §14.1's 15th rule): the JOIN MONTH's floor is
            # waived entirely, whatever the day. Spec §14.1 is unamended text.
            # A founding member's joined_at is BEFORE the season (the engine stamps
            # the add), so no season month is their join month. Only a late joiner
            # gets the D161 waiver, for the month they were added.
            joined = start + timedelta(days=gl.join_offset_days)
            joined_this_month = gl.join_offset_days > 0 and a <= joined <= b
            waived = partial or joined_this_month
            short = max(0, bylaws.floor - n_rounds)
            if short and not waived and bylaws.penalty != "none":
                if byes_left[g] > 0:            # auto-bye forgives the FIRST missed floor
                    byes_left[g] -= 1; ml.byes_used.add(g)
                elif bylaws.penalty == "deduct":
                    ml.penalties[g] = -5 * short
                elif bylaws.penalty == "forfeit":
                    ml.forfeits.add(g); pts = 0
            ml.per_golfer_points[g] = pts
        lines.append(ml)
    return lines

def squad_table(lines: list[MonthLine], golfers: dict[str, Golfer]) -> dict[str, int]:
    tot: dict[str, int] = defaultdict(int)
    for ml in lines:
        for g, p in ml.per_golfer_points.items():
            tot[golfers[g].squad] += p + ml.penalties.get(g, 0)
    return dict(tot)

# --------------------------------------------------------------- the Cup (§14.3)
@dataclass
class CupResult:
    seeds: list[str]; lock_on: date; window: tuple[date, date]
    final_points: dict[str, int]; champion: str | None; tiebreak_used: str | None

def cup_final(scored, golfers, lines, start, end, bylaws) -> CupResult:
    lock_on = end - timedelta(days=bylaws.final_days - 1)       # ends_on - 27
    # seeds: top-2 squads by season total AS OF the lock day (months closed before it)
    # DEPLOYED (enter_cup_final): seeds rank on counting rounds with
    # played_on < ends_on-27 — the month in progress counts up to the lock day.
    table = defaultdict(int)
    for g, gl in golfers.items():
        for mi, a, b in month_days(start, end):
            cnt = counting_for_month(scored.get(g, []), a, b, bylaws.cap)
            table[gl.squad] += sum(s.points for s in cnt if s.counting and s.r.played_on < lock_on)
    for ml in lines:
        if ml.b < lock_on:
            for g, p in ml.penalties.items(): table[golfers[g].squad] += p
    seeds = sorted(table, key=lambda s: -table[s])[:2]
    # scored FRESH in the window under the league's own counting rules (cap per month)
    fin: dict[str, int] = defaultdict(int)
    for g, gl in golfers.items():
        if gl.squad not in seeds: continue
        # DEPLOYED (_cup_window_rounds): a window round counts only if it is within
        # the cap of its WHOLE calendar month; a strong pre-window round in the same
        # month can push a window round out. The window is not fresh for the cap.
        for mi, a, b in month_days(start, end):
            cnt = counting_for_month(scored.get(g, []), a, b, bylaws.cap)
            fin[gl.squad] += sum(s.points for s in cnt if s.counting and lock_on <= s.r.played_on <= end)
    for s in seeds: fin.setdefault(s, 0)
    # DEPLOYED (enter_cup_final): head_start +10 for the #1 seed under squads2 ONLY
    if bylaws.structure == "squads2" and seeds: fin[seeds[0]] += 10
    if len(seeds) < 2: return CupResult(seeds, lock_on, (lock_on, end), dict(fin), seeds[0] if seeds else None, None)
    a, b = seeds
    if fin[a] != fin[b]:
        return CupResult(seeds, lock_on, (lock_on, end), dict(fin), a if fin[a] > fin[b] else b, None)
    # §14.3 ladder: h2h months won -> best single month -> fewest rounds used -> coin flip
    # APPROX: "h2h months won" read as months where one seed out-scored the other over the WHOLE season.
    # DEPLOYED: a month is won by strictly beating the MAX of every other squad.
    squads = sorted({gl.squad for gl in golfers.values()})
    def mpts(ml, s): return sum(p for g, p in ml.per_golfer_points.items() if golfers[g].squad == s)
    won = {a: 0, b: 0}
    for ml in lines:
        for s_ in (a, b):
            if mpts(ml, s_) > max((mpts(ml, o) for o in squads if o != s_), default=-1): won[s_] += 1
    if won[a] != won[b]:
        return CupResult(seeds, lock_on, (lock_on, end), dict(fin), a if won[a] > won[b] else b, "h2h months won")
    best = {s: max((sum(p for g, p in ml.per_golfer_points.items() if golfers[g].squad == s) for ml in lines), default=0) for s in seeds}
    if best[a] != best[b]:
        return CupResult(seeds, lock_on, (lock_on, end), dict(fin), a if best[a] > best[b] else b, "best single month")
    used = {s: sum(1 for g in golfers if golfers[g].squad == s for x in scored.get(g, []) if x.counting) for s in seeds}
    if used[a] != used[b]:
        return CupResult(seeds, lock_on, (lock_on, end), dict(fin), a if used[a] < used[b] else b, "fewest rounds used")
    return CupResult(seeds, lock_on, (lock_on, end), dict(fin), None, "coin flip (unresolved)")

# --------------------------------------------------------------- the clash (D52)
def weekly_clash(scored, golfers, start, weeks) -> list[dict]:
    """One pairing per week; best band-of-week takes a W. NEVER cup points.
    APPROX: pairing = alphabetical rotation; the real picker is D52's."""
    names = sorted(golfers)
    out = []
    for w in range(weeks):
        a = start + timedelta(days=7 * w); b = a + timedelta(days=6)
        x, y = names[w % len(names)], names[(w + 1) % len(names)]
        def best(g): return max((s.points for s in scored.get(g, []) if a <= s.r.played_on <= b and not s.r.voided), default=None)
        bx, by = best(x), best(y)
        winner = None if bx == by else (x if (bx or 0) > (by or 0) else y)
        out.append({"week": w + 1, "a": x, "b": y, "a_best": bx, "b_best": by, "winner": winner})
    return out

def assumptions() -> list[str]:
    return [
      "Index m-table and adjustments copied from the DEPLOYED handicap_index_asof (differs from WHS 2020 at c=18 and c=9..11); the engine refreshes the index on every post, never monthly.",
      "Band edges as deployed in cup_points: >=3, >=1, >-1, >=-3, else 5. (A dead 7-arg score_round uses >=-1; ignored.)",
      "PvI and the index are rounded HALF AWAY FROM ZERO to match Postgres numeric; IEEE-float rounding disagrees at x.x5 and can move a band.",
      "Counting ties: points desc, pvi desc, played_on DESC — the later round wins — as deployed.",
      "A golfer with no established index (<3 differentials) scores 7 and is badged; the engine instead uses profiles.index_current or falls back to the round's own differential (PvI 0 => 7). Same points, different provenance.",
      "Auto-bye consumes the season's one bye on the FIRST missed floor (D14, deployed).",
      "Join-month floor waived entirely (D161, deployed via joined_at), not spec 14.1's 15th rule.",
      "Floors never assessed in a partial edge month (blanket, deployed).",
      "Cup seeds ranked on counting rounds with played_on < ends_on-27; window rounds count only within the cap of their whole calendar month (_cup_window_rounds); +10 head start for seed #1 under squads2 only.",
      "months_won = strictly beat the max of all other squads that month (deployed), not h2h; then best_month, rounds_used, random().",
      "One rated course (71.2/128) for every round; 18 holes only; no sim rounds; independent Gaussian differentials with no form or course effects.",
      "Clash pairing is a fixed rotation, not the deployed picker; only 'never cup points' is asserted.",
      "Majors and Ryder are not simulated; the engine dump shows they read rounds and write only event tables.",
      "The mirror has no notion of created_at, so suspension/leave cut-offs and 'posted late' provenance are not modelled.",
    ]

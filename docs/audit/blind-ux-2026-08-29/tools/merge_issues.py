#!/usr/bin/env python3
"""
merge_issues.py — build the FINAL issue dataset for the blind UX audit (2026-08-29).

Inputs (all relative to the audit directory, the parent of this tools/ folder)
  issues.json                 127 deduped master issues built from the 284 triage items
                              (run 1: observer/novice/organizer/joiner; run 2: casual/
                              skeptic/competitive/iOS).
  raw/persona-results.json    all 12 persona results (424 raw items). The FIRST-RUN
                              casual (A1..A36), skeptic (SK-01..32), competitive
                              (C2-01..32) and iOS (ISS-01..40) items were never in the
                              triage input — this script folds them in.
  raw/synthesis-and-validation-results.json
                              triage.topFive[].supportingIssueIds -> 'validation' field.
  raw/agent6-new-joiner-attempt1-harness-artifact.md
                              the joiner's first attempt; its "code never arrived" P0 is
                              a test-harness artifact and is kept as a P3 with a note.

Outputs (written next to issues.json)
  issues.json, issues.csv, issues-counts.json, issues-README.md

Usage
  python3 tools/merge_issues.py            # write everything
  python3 tools/merge_issues.py --review   # print the match table, write nothing

Matching (run-1 item -> existing master), in order of precedence:
  G1  difflib ratio >= 0.6 on observation text, against the master's observation OR any
      raw item the master already absorbs (the raw text is the fairer comparator).
  G2  same screen + same category + shared key phrase (a shared quoted UI string of
      >= 10 chars — containment counts — or >= 5 shared distinctive tokens, Jaccard >= 0.15).
  G3  same screen + a shared VERBATIM UI string of >= 12 chars, category ignored (two
      personas quoting the same on-screen copy are looking at the same thing).
  G4  same screen + ratio >= 0.45 + >= 6 shared distinctive tokens, category ignored
      (near-duplicate worded differently).
  Candidates that pass any gate are ranked by a composite score; the best wins.
  CURATED then applies hand-verified folds/overrides (each with a reason) — the match
  table was read line by line and the heuristic's misses and mis-folds corrected there.
Folding never changes an existing issue's severity, text or stage; it adds the run-1
agent label and the raw id.
"""
import csv
import difflib
import json
import os
import re
import sys
from collections import Counter, OrderedDict, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ISSUES_JSON = os.path.join(ROOT, "issues.json")
FIRST_PASS_JSON = os.path.join(ROOT, "raw", "issues.first-pass.json")   # pristine triage output
ISSUES_CSV = os.path.join(ROOT, "issues.csv")
COUNTS_JSON = os.path.join(ROOT, "issues-counts.json")
README_MD = os.path.join(ROOT, "issues-README.md")
PERSONA_JSON = os.path.join(ROOT, "raw", "persona-results.json")
VALIDATION_JSON = os.path.join(ROOT, "raw", "synthesis-and-validation-results.json")
ATTEMPT1_MD = os.path.join(ROOT, "raw", "agent6-new-joiner-attempt1-harness-artifact.md")

REVIEW = "--review" in sys.argv

# --------------------------------------------------------------------------------------
# Provenance map: which persona-results entry each raw-id prefix refers to.
# The triage input used run 2 for the four re-run families, so a bare 'A7' or 'SK-03' in
# an existing dedupedFrom means the run-2 item (verified: master observations are closer
# to the run-2 text for 34/42 A* and 33/38 SK-* ids; the rest are the same observation
# made twice). The run-1 items of those families are the ones merged here; their ids are
# written with a ' (run 1)' suffix because A*/SK-* collide across runs.
# --------------------------------------------------------------------------------------
TRIAGED_PREFIX_TO_INDEX = {
    "R7-": 0,   # observer, run 1
    "N-": 1,    # novice, run 1
    "ORG-": 2,  # organizer, run 1
    "IOS-": 7,  # iOS survey, run 2
    "J-": 8,    # joiner, run 1 (final attempt)
    "SK-": 9,   # skeptic, run 2
    "A": 10,    # casual, run 2
    "C-": 11,   # competitive, run 2
}
# index in persona-results.json -> (agent label used in issues.json, id prefix)
RUN1_TO_MERGE = OrderedDict([
    (4, ("A1-casual", "A")),        # casual run 1: A1..A36
    (5, ("A4-skeptic", "SK-")),     # skeptic run 1: SK-01..32
    (6, ("A2-competitive", "C2-")), # competitive run 1: C2-01..32
    (3, ("iOS-survey", "ISS-")),    # iOS survey run 1: ISS-01..40
])
RUN1_SUFFIX = " (run 1)"

# Hand-verified folds. key = run-1 raw id; value = (target, reason). A target of the
# form 'run1:<id>' means "the master that run-1 item <id> produced (or folded into)".
# 'NEW' forces a new master (used to undo a heuristic mis-fold with no better home).
CURATED = OrderedDict([
    # ---- casual run 1
    ("A1",     ("M-040", "points-preview vs 0 in standings — the TOP-4 pre-season observation")),
    ("A3",     ("M-054", "the only full explanation of the game is buried under You › How it works (TOP-5)")),
    ("A5",     ("M-094", "'Jordan · EST 18.0 IDX' estimated strokes with no explanation")),
    ("A6",     ("M-098", "'Casey def. Marco 1 up thru 3 · $5' card posted as a result with gaps")),
    ("A10",    ("M-060", "Points King / Most Improved / Iron Man defined only in a footnote")),
    ("A12",    ("M-078", "stacked sheets after posting; 'first round is on the board' twice")),
    ("A14",    ("M-044", "receipt shows differential formula unexplained; '-7.3' not tappable")),
    ("A15",    ("M-024", "the invite link reveals only 'Enter your email and you're in' before sign-in — landing copy, not the consent sheet")),
    ("A16",    ("M-025", "'Not now' drops the invite; a11y-only status")),
    ("A20",    ("NEW",   "'ONE LEAGUE: TABLE, BOARD, POT' — table/board/pot as undefined nouns; not the Board-shows-no-rounds defect")),
    ("A22",    ("NEW",   "teeing off with no course silently defaults to 'Course · 72/113' — a course problem, not the no-index estimate")),
    ("A18",    ("M-071", "orange ⊕ overlaps content")),
    ("A19",    ("M-070", "Schedule sub-tab leaves the Clubhouse for a full-screen calendar")),
    ("A23",    ("M-140", "handle silently rewritten to the display name")),
    ("A25",    ("M-139", "every member shows the identical marker; marker unexplained")),
    ("A26",    ("M-110", "Pot: '$0 collected · N still owe' beside ticked names")),
    ("A28",    ("M-090", "'Scrap this round' two-tap arm — behaviour M-090 already records")),
    ("A29",    ("M-155", "'THREE THINGS TO KNOW' above four bullets")),
    ("A31",    ("M-083", "four date formats")),
    ("A32",    ("M-032", "Form squads sheet: no back, nothing says who draws or when")),
    ("A34",    ("M-079", "display case 'No hardware yet' right after a milestone was 'pinned'")),
    # ---- skeptic run 1
    ("SK-01",  ("NEW",   "blank date → 'Post failed' (null played_on violates NOT NULL; orchestrator-verified P0) — not the rating/slope placeholder issue")),
    ("SK-03",  ("M-023", "consent sheet: four rows, 'Standard' not tappable, no dates/roster")),
    ("SK-04",  ("M-155", "welcome sheet: three things / four bullets; squad undefined")),
    ("SK-06",  ("M-042", "'7 days to first tee' above 'MONTH CLOSES in 2 days' — the pre-season contradiction (TOP-4), not the mid-season pills")),
    ("SK-08",  ("M-076", "tee list vanishes; blank rating/slope still previews")),
    ("SK-09",  ("M-045", "sign confusion: '-4.5 VS YOUR INDEX' / 'POSTED ANYWAY' / recap")),
    ("SK-12",  ("M-110", "Pot tab: '$0 collected · 4 still owe', checkbox rows, no payee/method")),
    ("SK-13",  ("M-054", "the actual rules sit under a collapsed disclosure (TOP-5)")),
    ("SK-15",  ("run1:A20", "'table / board / pot / The ⊕' introduced as nouns with no definition")),
    ("SK-16",  ("M-098", "match-play card 'Casey def. Marco 1 up thru 3' with gaps")),
    ("SK-17",  ("M-071", "⊕ overlaps 'See the squads'; Schedule button behind the nav — NOT the rating/slope issue")),
    ("SK-21",  ("M-003", "'Share the invite link' → only toast 'Invite code: THEPTCQ5' — NOT 'Share the card'")),
    ("SK-22",  ("M-136", "Notifications only behind ⚙; '[Enable on this device]'")),
    ("SK-25",  ("M-032", "Form squads copy: 'THE HAT SHUFFLES…', 'The Pro has the list.', pool count vs roster bar")),
    ("SK-28",  ("M-135", "You tab: 'Cups & events · 1 · Played in' with nothing played, twin post buttons, display case")),
    ("SK-29",  ("M-139", "ball-marker grid required with no statement of purpose")),
    ("SK-30",  ("M-082", "feed badge logic: 'Broke 80 — first time' then 'Personal best'; duplicated first-round line")),
    # ---- competitive run 1
    ("C2-02",  ("M-030", "member Home's largest CTA 'Lock it in and invite your crew' opens the wizard — NOT the 'You' tab mis-route")),
    ("C2-03",  ("M-058", "squad scoring — how counting rounds combine — never defined (TOP-5)")),
    ("C2-05",  ("NEW",   "course search returns NOTHING for 'TPC Scottsdale' / 'Papago' with five 502s (orchestrator-verified) — a distinct P1 failure mode from the duplicate-rows P2")),
    ("C2-06",  ("M-051", "a real 6.4 is a 'starting point' the app overwrites after 3 rounds")),
    ("C2-08",  ("M-023", "covenant rows have no tap targets; commit $50 under undefined terms")),
    ("C2-10",  ("M-044", "posted card: no points figure, no league, no season status")),
    ("C2-11",  ("M-079", "a 6.4 posting a 74 mints 'broke 80/90/100' trophies")),
    ("C2-14",  ("M-041", "'Squads · LIVE NOW — CAPTAINS READY' vs 'SQUADS ARE FORMING'")),
    ("C2-15",  ("M-032", "member reaches the Pro's blind-draw sheet; chips are unexplained buttons")),
    ("C2-16",  ("M-049", "'Casey gets 9' with no course-handicap math")),
    ("C2-17",  ("M-092", "Finish-round buttons indistinguishable")),
    ("C2-19",  ("M-094", "no-index player estimated at 18.0 into a $5 net game")),
    ("C2-20",  ("M-003", "share buttons produce nothing visible; text carries only a bare code")),
    ("C2-21",  ("M-060", "'bylaws §4' — no §4 exists in-app")),
    ("C2-22",  ("M-111", "pot split rounds to $151 of $150; 'champs' plural, per-player share unstated")),
    ("C2-23",  ("M-060", "squad / the Pro / pot sheet / your number / bylaws undefined at point of use")),
    ("C2-24",  ("M-123", "no head-to-head, no gap, no 'N more rounds' — Standings is a flat table")),
    ("C2-27",  ("M-080", "no edit/delete on a posted round anywhere obvious (only the unlabeled ✕ on You)")),
    ("C2-28",  ("M-135", "You tab: 'Cups & events · 1 · Played in', undefined FORM badge, twin post buttons")),
    ("C2-29",  ("M-070", "Schedule leaves the Clubhouse for a full-screen calendar")),
    ("C2-32",  ("M-057", "'short month' / 'season bye' undefined; floor copy differs by surface")),
    # ---- iOS survey run 1
    ("ISS-02", ("M-084", "iOS Board shows one line and ~65% empty screen")),
    ("ISS-04", ("M-102", "'SET UP THE ROUND' has no title bar, back/close or tab bar")),
    ("ISS-06", ("M-059", "gold 'LOCKED' pill on standings rows, unexplained")),
    ("ISS-07", ("M-059", "'Partial month · floors waived' / 'no floor to clear' unexplained")),
    ("ISS-08", ("M-059", "'COUNTING ROUNDS 1 / 4 ●○○○' tile unexplained")),
    ("ISS-09", ("M-055", "'EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS' — the only Cup Final hint, in the smallest caps")),
    ("ISS-10", ("M-153", "'… 13 wks · THE PRO · GALEN' league-card line; 'THE PRO' undefined in the iOS Clubhouse header")),
    ("ISS-12", ("M-139", "'NO. 2' (the ball marker) is the first element of the profile card")),
    ("ISS-19", ("M-147", "'QUIET SINCE YOUR LAST VISIT' two minutes after the last visit; the same 79 shown twice")),
    ("ISS-23", ("M-141", "'settings' lands on Card & settings with the 'Your card' segment selected")),
    ("ISS-13", ("M-076", "'41' / '43' placeholders in the nines read as filled values")),
    ("ISS-15", ("M-074", "four differently named entry points for a round")),
    ("ISS-20", ("M-074", "two orange '+' entry points on one screen")),
    ("ISS-22", ("M-148", "'REQUESTED' rows with no accept/decline")),
    ("ISS-26", ("M-074", "'tee sheet' used repeatedly and never defined")),
    ("ISS-28", ("M-144", "no signed-in screen says what Cup Season is or how you win")),
    ("ISS-29", ("M-059", "'— held' pill unexplained")),
    ("ISS-30", ("M-135", "'FORM ●●●●●' dots with no key")),
    ("ISS-31", ("M-135", "'Personal best · Diff 9.3' with a down-trending chart emoji")),
    ("ISS-32", ("M-079", "same 88 credited as 'Broke 100' and 'Broke 90'")),
    ("ISS-34", ("M-152", "content ghosts through the translucent tab bar (iOS visual consistency)")),
    ("ISS-36", ("M-152", "'THE BOARD' title styled unlike sibling screens (iOS visual consistency)")),
    ("ISS-37", ("M-150", "recent-course rows with no header; '72.1 / 142' undecoded")),
    ("ISS-39", ("M-121", "'YOUR INDEX · 11.3 · Season to date' — index told several ways, unexplained")),
])

SEV_RANK = {"P0": 0, "P1": 1, "P2": 2, "P3": 3}
CSV_COLUMNS = [
    "id", "agent", "screen", "journey", "observation", "expected", "actual", "severity",
    "category", "recommendation", "confidence", "evidence", "stage", "validation", "note",
    "dedupedFrom",
]

STOP = set("""
a an the and or of to in on for with at by from as is are was were be been being it its this
that these those there here then than into onto over under out up down off not no nor so if
but about after before again against all any both each few more most other some such only own
same too very can will just should now what when where which who whom why how does did do done
have has had having also via per one two three four five six seven eight nine ten first second
third user users tap taps tapped tapping shows shown show showed reads read screen sheet page
never nothing none still ever even every once twice you your yours i me my we our they
them their he she his her him same than
""".split())
SCREEN_STOP = set("the and from via web ios after before with for tab tabs sheet screen page".split())


def norm_text(s):
    return re.sub(r"\s+", " ", (s or "")).strip().lower()


def _singular(t):
    if len(t) > 4 and t.endswith("s") and not t.endswith("ss"):
        return t[:-1]
    return t


def key_tokens(s):
    toks = re.findall(r"[a-z0-9][a-z0-9'\-\.]*[a-z0-9]|[a-z0-9]", norm_text(s))
    return {_singular(t) for t in toks if len(t) >= 4 and t not in STOP}


def quoted_phrases(s):
    """Quoted UI strings, split on the ' · ' / ' — ' separators the app uses, >= 10 chars."""
    out = set()
    for m in re.findall(r"[\'‘\"“]([^\'’\"”]{10,160})[\'’\"”]", s or ""):
        whole = norm_text(m)
        out.add(whole)
        for piece in re.split(r"\s[·—/]\s", whole):
            piece = piece.strip(" .…")
            if len(piece) >= 10:
                out.add(piece)
    return out


def shared_phrase(a, b, min_len=10):
    """Longest phrase shared by containment between two phrase sets ('' if none)."""
    best = ""
    for x in a:
        for y in b:
            if len(x) < min_len or len(y) < min_len:
                continue
            if x in y or y in x:
                cand = x if len(x) <= len(y) else y
                if len(cand) > len(best):
                    best = cand
    return best


def screen_tokens(s):
    toks = re.findall(r"[a-z0-9][a-z0-9'\-]*", norm_text(re.sub(r"[›→/·(),;:]", " ", s or "")))
    return {_singular(t) for t in toks if len(t) >= 3 and t not in SCREEN_STOP}


def same_screen(a, b):
    if not a or not b:
        return False
    inter = a & b
    if a <= b or b <= a:
        return True
    if len(inter) >= 2:
        return True
    if len(inter) >= 1 and min(len(a), len(b)) <= 2:
        return True
    return len(inter) / len(a | b) >= 0.5


def seq_ratio(a, b):
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    if sm.quick_ratio() < 0.45:
        return 0.0
    return sm.ratio()


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def conf_to_10(v):
    """Raw persona items carry 0..1 floats; the master uses 1..10 ints."""
    try:
        v = float(v)
    except (TypeError, ValueError):
        return 5
    if v <= 1.0:
        v = v * 10
    return max(1, min(10, int(round(v))))


# --------------------------------------------------------------------------------------
# Stage inference (only for APPENDED run-1 issues; existing stages are left untouched)
# --------------------------------------------------------------------------------------
CASUAL_LETTERS = {"A": "activation", "B": "activation", "C": "activation", "D": "activation",
                  "E": "engagement", "F": "engagement", "G": "engagement"}
GENERIC_LETTERS = {"A": "activation", "B": "activation", "C": "activation", "D": "engagement",
                   "E": "retention", "F": "retention", "G": "retention"}


def infer_stage(journey, category, family_label):
    j = norm_text(journey)
    cat = norm_text(category)
    if cat == "monetization" or any(w in j for w in ("money", "pot", "stakes")):
        return "monetization"
    if cat == "retention":
        return "retention"
    if cat == "onboarding":
        return "activation"
    if any(w in j for w in ("retention", "competition-visibility", "rivalry", "finale",
                            "next season", "mid-season")):
        return "retention"
    if any(w in j for w in ("join", "sign-up", "signup", "sign-in", "signin", "discovery",
                            "invitation", "invite", "onboarding", "explore no league",
                            "create", "golfer card")):
        return "activation"
    if any(w in j for w in ("first round", "side game", "exploring", "rules hunt", "value hunt",
                            "information-hierarchy", "navigation", "social objects", "what now",
                            "what do i do now", "post", "board", "live")):
        return "engagement"
    # letter-only journeys ("E", "D/E/G", "F", "G / F") — persona-specific letter maps
    letters = re.findall(r"\b([A-G])\b", journey or "")
    if letters:
        table = CASUAL_LETTERS if family_label.startswith("A1-casual") else GENERIC_LETTERS
        return table[letters[0]]
    return "engagement"


# --------------------------------------------------------------------------------------
# Matching
# --------------------------------------------------------------------------------------
class Master:
    """Cached comparison features for one master issue (its text + its raw sources)."""

    def __init__(self, m, source_items):
        self.m = m
        srcs = [source_items[d] for d in m["dedupedFrom"] if d in source_items]
        self.obs = [norm_text(m["observation"])] + [norm_text(s["observation"]) for s in srcs]
        self.cat = norm_text(m["category"])
        self.screen = screen_tokens(m["screen"])
        self.tokens = key_tokens(m["observation"] + " " + m.get("actual", ""))
        self.quotes = quoted_phrases(m["observation"]) | quoted_phrases(m.get("actual", ""))
        for s in srcs:
            self.screen |= screen_tokens(s.get("screen", ""))
            self.tokens |= key_tokens(s["observation"] + " " + s.get("actual", ""))
            self.quotes |= quoted_phrases(s["observation"]) | quoted_phrases(s.get("actual", ""))


def best_match(item, cache):
    """Return (master_id, score, gate) or (None, best_near_score, best_near_master_id)."""
    obs = norm_text(item["observation"])
    itoks = key_tokens(item["observation"] + " " + item.get("actual", ""))
    iquotes = quoted_phrases(item["observation"]) | quoted_phrases(item.get("actual", ""))
    iscreen = screen_tokens(item.get("screen", "")) | screen_tokens(item.get("screen_alt", ""))
    icat = norm_text(item["category"])

    best = None                # (composite, master_id, gate)
    near = (0.0, None)
    for mc in cache:
        r = max(seq_ratio(obs, c) for c in mc.obs)
        scr = same_screen(iscreen, mc.screen)
        same_cat = mc.cat == icat
        shared_t = itoks & mc.tokens
        t_j = len(shared_t) / max(1, len(itoks | mc.tokens))
        phrase = shared_phrase(iquotes, mc.quotes, 10)
        gate = None
        if r >= 0.6:
            gate = "G1 ratio"
        elif scr and same_cat and (phrase or (len(shared_t) >= 5 and t_j >= 0.15)):
            gate = "G2 screen+category+phrases"
        elif scr and len(phrase) >= 12:
            gate = "G3 screen+verbatim-copy"
        elif scr and r >= 0.45 and len(shared_t) >= 6:
            gate = "G4 screen+near-duplicate"
        if gate is None:
            if r > near[0]:
                near = (r, mc.m["id"])
            continue
        composite = (r + (0.25 if phrase else 0.0) + (0.10 if same_cat else 0.0)
                     + 0.10 * min(1.0, len(shared_t) / 8.0) + (0.05 if scr else 0.0))
        if best is None or composite > best[0]:
            best = (composite, mc.m["id"], gate)
    if best:
        return best[1], best[0], best[2]
    return None, near[0], near[1]


# --------------------------------------------------------------------------------------
def main():
    # Re-runnable: the first run snapshots the triage output to raw/issues.first-pass.json
    # and every run reads from that snapshot, so issues.json is always rebuilt from scratch.
    if not os.path.exists(FIRST_PASS_JSON):
        with open(ISSUES_JSON, encoding="utf-8") as src, open(FIRST_PASS_JSON, "w", encoding="utf-8") as dst:
            dst.write(src.read())
    masters = load(FIRST_PASS_JSON)
    results = load(PERSONA_JSON)
    validation = load(VALIDATION_JSON)

    # raw items already represented (keyed by the bare ids used in dedupedFrom)
    source_items = {}
    for prefix, idx in TRIAGED_PREFIX_TO_INDEX.items():
        for it in results[idx]["issues"]:
            source_items[it["id"]] = it

    # sanity: every existing dedupedFrom id must resolve to a raw item
    for m in masters:
        for d in m["dedupedFrom"]:
            assert d in source_items, f"{m['id']}: unresolved dedupedFrom {d}"

    by_id = {m["id"]: m for m in masters}
    cache = [Master(m, source_items) for m in masters]
    next_num = max(int(m["id"].split("-")[1]) for m in masters) + 1
    match_log = []
    folded = []       # (raw_id, master_id, gate)
    appended = []     # (raw_id, master_id, stage)
    run1_home = {}    # raw id -> master id it produced or folded into
    curated_used = set()

    def fold(m, agent_r1, orig_id):
        agents = m["agent"].split(";")
        if agent_r1 not in agents:
            agents.append(agent_r1)
            m["agent"] = ";".join(agents)
        if orig_id not in m["dedupedFrom"]:
            m["dedupedFrom"].append(orig_id)

    for idx, (agent_label, prefix) in RUN1_TO_MERGE.items():
        res = results[idx]
        assert res.get("_run") == 1, f"result {idx} is not a run-1 result"
        agent_r1 = agent_label + RUN1_SUFFIX
        for it in res["issues"]:
            assert it["id"].startswith(prefix), (it["id"], prefix)
            orig_id = it["id"] + RUN1_SUFFIX
            mid, score, gate = best_match(it, cache)
            heuristic = (mid, gate)
            if it["id"] in CURATED:
                target, reason = CURATED[it["id"]]
                curated_used.add(it["id"])
                if target.startswith("run1:"):
                    target = run1_home[target[5:]]
                if target == "NEW":
                    mid, gate = None, f"curated NEW ({reason})"
                else:
                    assert target in by_id, f"CURATED target {target} for {it['id']} not found"
                    mid = target
                    gate = ("curated" if heuristic[0] != target else f"{heuristic[1]} (curated agrees)")
            if mid:
                m = by_id[mid]
                fold(m, agent_r1, orig_id)
                run1_home[it["id"]] = mid
                folded.append((it["id"], mid, gate))
                match_log.append(("FOLD", it["id"], mid, round(score, 2), gate,
                                  heuristic[0] or "-", it["observation"][:90], m["observation"][:90]))
            else:
                stage = infer_stage(it.get("journey", ""), it.get("category", ""), agent_label)
                new = OrderedDict([
                    ("id", f"M-{next_num:03d}"),
                    ("agent", agent_r1),
                    ("screen", it.get("screen", "") + (
                        f" / {it['screen_alt']}" if it.get("screen_alt") else "")),
                    ("journey", it.get("journey", "")),
                    ("observation", it.get("observation", "")),
                    ("expected", it.get("expected", "")),
                    ("actual", it.get("actual", "")),
                    ("severity", it.get("severity", "P2")),
                    ("category", it.get("category", "")),
                    ("recommendation", it.get("recommendation", "")),
                    ("confidence", conf_to_10(it.get("confidence"))),
                    ("evidence", it.get("evidence", "") if isinstance(it.get("evidence"), str)
                     else "; ".join(it.get("evidence") or [])),
                    ("stage", stage),
                    ("dedupedFrom", [orig_id]),
                ])
                next_num += 1
                masters.append(new)
                by_id[new["id"]] = new
                cache.append(Master(new, {}))   # later run-1 items can fold into it
                run1_home[it["id"]] = new["id"]
                appended.append((it["id"], new["id"], stage))
                match_log.append(("NEW", it["id"], new["id"], round(score, 2), gate or "-",
                                  "-", it["observation"][:90], ""))
    unused = set(CURATED) - curated_used
    assert not unused, f"CURATED entries never seen: {sorted(unused)}"

    # ---- (3) the joiner attempt-1 "code never arrived" item: keep it, P3, with a note
    harness_note = "harness artifact — Supabase recorded the send; the mail connector hid it"
    harness_id = "J-01 (attempt 1)"
    present = None
    for m in masters:
        if harness_id in m["dedupedFrom"] or re.search(
                r"(code|email).{0,40}never arriv", m["observation"], re.I):
            present = m
            break
    if present is None:
        present = OrderedDict([
            ("id", f"M-{next_num:03d}"),
            ("agent", "A6-joiner (attempt 1)"),
            ("screen", "Door — sign-in code step (invite-link landing)"),
            ("journey", "B — Sign-in"),
            ("observation", "Typed the invite email and tapped Go: 'Sent to jerecho+blind2@fischbeck3.com. "
             "Type the sign-in code from the newest email.' Tapped 'Resend code' ('Fresh code sent … "
             "the newest email wins.'), tapped Go again, reopened the link, tried a variant address "
             "— five 'Sent' assertions across two addresses, no code seen in 15+ minutes, console clean. "
             "The door's only diagnosis is the caption 'No code yet? Check spam for the newest Cup "
             "Season email — older codes retire when a new one sends.' and a ~28 s 'Resend code' "
             "cooldown; there is no 'something's wrong on our end', no contact, no alternate path."),
            ("expected", "A code within a minute, or an honest failure state that says what to do next."),
            ("actual", "TEST-HARNESS ARTIFACT, not a product defect: Supabase Auth logged every send; "
             "the audit's mail connector hid messages past the 5th in a thread, so the tester could "
             "not see them. The second attempt (agent6-new-joiner.md) signed in normally. What "
             "remains a real, minor observation: after repeated resends the door still offers only "
             "'check spam' — no support/status path."),
            ("severity", "P3"),
            ("category", "onboarding"),
            ("recommendation", "No email fix needed. Consider a third-resend fallback line ('Still "
             "nothing? Email hello@cupseason.app') so a genuinely stuck joiner has a human path."),
            ("confidence", 3),
            ("evidence", "raw/agent6-new-joiner-attempt1-harness-artifact.md §3 (timeline 14:14:45–14:52 UTC); "
             "shots 05-after-email-go.png, 07-signin-scrolled.png; orchestrator DB check: Supabase "
             "recorded the sends"),
            ("stage", "activation"),
            ("dedupedFrom", [harness_id]),
        ])
        next_num += 1
        masters.append(present)
    present["severity"] = "P3"
    present["note"] = harness_note

    # ---- (4) validation field from the top-five supporting ids
    support = defaultdict(list)
    for f in validation["triage"]["topFive"]:
        for sid in f["supportingIssueIds"]:
            if f["id"] not in support[sid]:
                support[sid].append(f["id"])
    for m in masters:
        tops = support.get(m["id"], [])
        m["validation"] = f"Confirmed UX problem ({', '.join(tops)})" if tops else ""
        m.setdefault("note", "")
    # ---- (4b) M-031 ("You tab opens the wizard") was refuted by the TOP-3 validators as a
    # test-harness artifact: bx.mjs resolved a bare click "You" by case-insensitive substring
    # and hit the hero button "Lock it in and invite YOUr crew". It stays in the dataset at
    # its triage severity (folding/annotation never changes severity, so the counts stay
    # reproducible) and carries a note; treat it as a symptom of M-030, not a route defect.
    for m in masters:
        if m["id"] == "M-031":
            m["note"] = ("harness artifact — validator-refuted: bx.mjs substring-matched 'You' to the hero "
                         "button 'Lock it in and invite Your crew'; switchView has no stats→wizard route. "
                         "Symptom of M-030; kept at triage severity so counts stay reproducible.")
    dangling = sorted(set(support) - {m["id"] for m in masters})
    assert not dangling, f"supportingIssueIds not in dataset: {dangling}"

    # ---- normalise key order for every issue
    order = ["id", "agent", "screen", "journey", "observation", "expected", "actual", "severity",
             "category", "recommendation", "confidence", "evidence", "stage", "validation",
             "note", "dedupedFrom"]
    masters = [OrderedDict((k, m.get(k, "" if k != "dedupedFrom" else [])) for k in order)
               for m in masters]
    ids = [m["id"] for m in masters]
    assert len(ids) == len(set(ids)), "duplicate ids"

    # ---- (5) counts
    def counter(key, split=None):
        c = Counter()
        for m in masters:
            v = m.get(key) or ""
            for part in (v.split(split) if split else [v]):
                c[part.strip()] += 1
        return OrderedDict(sorted(c.items(), key=lambda kv: (-kv[1], kv[0])))

    by_sev = OrderedDict(sorted(Counter(m["severity"] for m in masters).items(),
                                key=lambda kv: SEV_RANK.get(kv[0], 9)))
    raw_total = sum(len(r["issues"]) for r in results)
    gate_counts = Counter(g.split(" (")[0] for _, _, g in folded)
    counts = OrderedDict([
        ("masterIssues", len(masters)),
        ("originalItems", raw_total + 1),
        ("originalItemsBreakdown", OrderedDict([
            ("personaResultsJson", raw_total),
            ("triagedInFirstPass", sum(len(results[i]["issues"]) for i in TRIAGED_PREFIX_TO_INDEX.values())),
            ("mergedByThisScript", sum(len(results[i]["issues"]) for i in RUN1_TO_MERGE)),
            ("joinerAttempt1HarnessItem", 1),
        ])),
        ("mergeOutcome", OrderedDict([
            ("foldedIntoExisting", len(folded)),
            ("appendedAsNew", len(appended)),
            ("foldedByGate", OrderedDict(sorted(gate_counts.items()))),
            ("curatedEntries", len(CURATED)),
        ])),
        ("validatedTopFiveSupport", sum(1 for m in masters if m["validation"])),
        ("bySeverity", by_sev),
        ("byCategory", counter("category")),
        ("byStage", counter("stage")),
        ("byJourney", counter("journey")),
        ("byAgent", counter("agent", ";")),
    ])

    if REVIEW:
        for row in match_log:
            print(" | ".join(str(x) for x in row))
        print()
        print(json.dumps(counts, indent=1, ensure_ascii=False))
        return

    # ---- (6) write outputs
    with open(ISSUES_JSON, "w", encoding="utf-8") as f:
        json.dump(masters, f, indent=2, ensure_ascii=False)
        f.write("\n")
    with open(ISSUES_CSV, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=CSV_COLUMNS, quoting=csv.QUOTE_ALL)
        w.writeheader()
        for m in masters:
            row = dict(m)
            row["dedupedFrom"] = ";".join(m["dedupedFrom"])
            w.writerow({k: row.get(k, "") for k in CSV_COLUMNS})
    with open(COUNTS_JSON, "w", encoding="utf-8") as f:
        json.dump(counts, f, indent=2, ensure_ascii=False)
        f.write("\n")

    # round-trip check
    with open(ISSUES_CSV, encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    assert len(rows) == len(masters), (len(rows), len(masters))
    for r, m in zip(rows, masters):
        assert r["id"] == m["id"] and r["observation"] == m["observation"]
        assert r["dedupedFrom"].split(";") == m["dedupedFrom"]
        assert r["validation"] == m["validation"] and r["note"] == m["note"]

    write_readme(masters, counts, folded, appended)
    print(f"wrote {len(masters)} issues -> {ISSUES_JSON}, {ISSUES_CSV}, {COUNTS_JSON}, {README_MD}")
    print(json.dumps({k: counts[k] for k in ("masterIssues", "originalItems", "mergeOutcome",
                                              "validatedTopFiveSupport", "bySeverity",
                                              "byStage")}, indent=1))


def write_readme(masters, counts, folded, appended):
    def table(d):
        return "\n".join(f"| {k or '(blank)'} | {v} |" for k, v in d.items())

    def in_family(raw_id, prefix):
        return raw_id.startswith(prefix) and (prefix != "A" or raw_id[1:].isdigit())

    fam_lines = []
    for idx, (label, prefix) in RUN1_TO_MERGE.items():
        fam_f = sum(1 for f in folded if in_family(f[0], prefix))
        fam_a = sum(1 for a in appended if in_family(a[0], prefix))
        fam_lines.append(f"| {label} (run 1) | `{prefix}*` | {fam_f + fam_a} | {fam_f} | {fam_a} |")

    gates = counts["mergeOutcome"]["foldedByGate"]
    gate_lines = "\n".join(f"| {g} | {n} |" for g, n in gates.items())
    new_ids = ", ".join(a[1] for a in appended)

    text = f"""# issues.json / issues.csv — final issue dataset

Blind usability, gameplay and retention audit of Cup Season, 2026-08-29. Prod build
`34d20b6` (byte-identical `index.html` to this branch). Built by
`tools/merge_issues.py`; re-running it regenerates every file listed here from
`raw/issues.first-pass.json` (`--review` prints the match table without writing).

## Files

| File | What it is |
|---|---|
| `issues.json` | {counts['masterIssues']} deduplicated master issues, one object each (schema below). |
| `issues.csv` | The same rows, one per issue, every field quoted; `dedupedFrom` joined with `;`. |
| `issues-counts.json` | Counts by severity, category, stage, journey and agent, plus merge provenance. |
| `raw/issues.first-pass.json` | The 127-issue triage output the script starts from (snapshotted on first run; re-runs read it, never `issues.json`). |
| `raw/persona-results.json` | The {counts['originalItemsBreakdown']['personaResultsJson']} raw persona items the dataset is built from (12 results). |
| `raw/synthesis-and-validation-results.json` | Top-five findings + 15 validation verdicts; source of the `validation` field. |

## Schema (one issue)

| Field | Meaning |
|---|---|
| `id` | `M-NNN`. Stable but not contiguous: gaps below M-156 are first-pass triage merges; `M-156` onward were appended by this script. |
| `agent` | `;`-separated persona labels that reported it: `A1-casual`, `A2-competitive`, `A3-novice`, `A4-skeptic`, `A5-organizer`, `A6-joiner`, `A7-observer`, `iOS-survey`. A ` (run 1)` suffix marks the first run of a re-run persona (see Provenance); `A6-joiner (attempt 1)` is the superseded joiner attempt. |
| `screen` | Where it was seen (UI path; screenshot names live in `evidence`). |
| `journey` | The persona's own journey label (A Discovery, B Sign-up, C Create/Explore, D First round or Join, E Mid-season, F Finale, G Next season / Side games, plus free-text hunts). Per-persona, not normalised. |
| `observation` | What the persona saw, with UI copy quoted verbatim where captured. |
| `expected` | What a first-time user expected. |
| `actual` | What actually happened / the mechanism behind it. |
| `severity` | `P0` blocker · `P1` major · `P2` minor · `P3` polish. |
| `category` | comprehension, terminology, visual-hierarchy, gameplay, rules, navigation, onboarding, social, monetization, retention. |
| `recommendation` | The fix the persona/synthesis proposed. |
| `confidence` | 1–10 (raw persona items carried 0–1 floats; appended rows are ×10, rounded). |
| `evidence` | Screenshot paths, console text, `index.html` line numbers, report sections. |
| `stage` | Funnel stage: activation · engagement · retention · monetization. Set by triage for the first 127; inferred from journey/category for appended rows (`infer_stage()` in the script). |
| `validation` | `Confirmed UX problem (TOP-n[, TOP-m])` when the issue is a supporting issue of one of the five adversarially validated top findings; blank otherwise. |
| `note` | Free text; two rows carry one: `M-163` (the joiner attempt-1 "code never arrived" harness artifact) and `M-031` (the "You tab opens the wizard" symptom, validator-refuted as a harness artifact — see `critical-findings.md` TOP-3). |
| `dedupedFrom` | Raw persona item ids this row absorbs. Bare ids reference `raw/persona-results.json` (run 1 for `R7-`, `N-`, `ORG-`, `J-`; run 2 for `A*`, `SK-`, `C-`, `IOS-`). Ids ending ` (run 1)` are first-run items of the re-run personas (`A*`, `SK-`, `C2-`, `ISS-`). `J-01 (attempt 1)` is the joiner's superseded first attempt (markdown report only). |

## Counts

Master issues: **{counts['masterIssues']}** from **{counts['originalItems']}** raw items
({counts['originalItemsBreakdown']['personaResultsJson']} in `persona-results.json` + 1 from the joiner's attempt-1 report).
{counts['validatedTopFiveSupport']} issues carry a `validation` tag (they support TOP-1…TOP-5).

### By severity
| Severity | Issues |
|---|---|
{table(counts['bySeverity'])}

### By stage
| Stage | Issues |
|---|---|
{table(counts['byStage'])}

### By category
| Category | Issues |
|---|---|
{table(counts['byCategory'])}

### By agent (an issue reported by several personas counts under each)
| Agent | Issues |
|---|---|
{table(counts['byAgent'])}

`byJourney` is in `issues-counts.json`; journey labels are per-persona and were not normalised.

## Provenance

Seven blind personas drove prod (headless iPhone-viewport browser, real accounts) plus an iOS
screen survey (static landing screens, no taps). Four of them ran twice:

| Persona | Run 1 | Run 2 | In the first triage pass |
|---|---|---|---|
| A7-observer (owner's real account, read-only) | 32 items `R7-*` | — | run 1 |
| A3-novice (`+blind5`, Desert Dogs) | 38 `N-*` | — | run 1 |
| A5-organizer (`+blind1`, The Papago Grind) | 40 `ORG-*` | — | run 1 |
| A6-joiner (`+blind2`) | 32 `J-*` (final attempt) | — | run 1 |
| A1-casual (`+blind3`) | 36 `A*` | 36 `A*` | run 2 only |
| A4-skeptic (`+blind6`) | 32 `SK-*` | 35 `SK-*` | run 2 only |
| A2-competitive (`+blind4`) | 32 `C2-*` | 38 `C-*` | run 2 only |
| iOS-survey | 40 `ISS-*` | 33 `IOS-*` | run 2 only |

The first triage pass built 127 master issues from the 284 items in the right-hand column.
This script folded in the {counts['originalItemsBreakdown']['mergedByThisScript']} run-1 items of the four re-run personas:

| Family | Raw ids | Items | Folded into an existing issue | Appended as new |
|---|---|---|---|---|
{chr(10).join(fam_lines)}

How each fold was decided (the gate that fired; "curated" = hand-verified override or a
miss the heuristic could not make):

| Gate | Folds |
|---|---|
{gate_lines}

Gates: **G1** `difflib` ratio ≥ 0.6 on observation text against the master or any raw item
it absorbs · **G2** same screen + same category + shared quoted UI string (≥ 10 chars,
containment counts) or ≥ 5 shared distinctive tokens · **G3** same screen + shared verbatim
UI string ≥ 12 chars, category ignored · **G4** same screen + ratio ≥ 0.45 + ≥ 6 shared
tokens. Candidates passing any gate are ranked by a composite score. The {counts['mergeOutcome']['curatedEntries']}
`CURATED` entries in the script were added after reading the full match table line by
line; each carries a one-line reason. Folding adds the run-1 agent label and the raw id;
it never changes the existing row's severity, text or stage.

Appended rows: {new_ids}.

The run-2 personas signed out and re-drove the cold paths on accounts that had already been
used in run 1; they flagged that contamination in their own `blockers` (see
`raw/persona-results.json`). Where run 1 and run 2 saw the same thing, the issue now carries
both agent labels — that is two-run confirmation, not double counting.

## Known caveats

- **Joiner attempt 1 "code never arrived" is a harness artifact.** Supabase Auth recorded every
  send; the audit's mail connector hid messages past the 5th in a thread. The item is kept
  (severity `P3`, `note` field) rather than dropped, so the record shows it was seen and why it
  was discounted. Only that attempt's door/Terms observations are usable evidence, and those
  are covered by the final joiner run's `J-*` items; its other items were not merged.
- **M-031 ("You" opens the wizard) is a harness artifact too** — the TOP-3 validators reproduced
  it as a substring click on "You" hitting "Lock it in and invite **You**r crew". It keeps its
  triage severity (P1) so the counts above stay reproducible, carries a `note`, and is struck
  from every backlog in this folder; the real defect is M-030.
- Headless browser: no native share sheet or clipboard, so share/copy outcomes were judged on
  visible feedback only.
- No in-season play was observable (both test leagues defaulted the first tee to Sat Sep 5,
  a week out); no finished season existed, so finale/next-season items are inferred from what
  the live app says about endings.
- The owner's two real leagues have 2 players each; the observer made no writes (DB check: 0
  rounds, 0 posts). The App Review sandbox was unavailable.
- Course search hit five 502s from the `courses` edge function in one session ("TPC Scottsdale",
  "Papago"); "Ken Mc" hit the cache.
- `stage` on appended rows and `journey` everywhere are persona/heuristic labels, not ground
  truth; filter on `category` and `severity` for anything load-bearing. Severity of a folded
  row is the first-pass value; a run-1 item folded into a lower-severity row keeps the row's
  severity (the raw item still carries its own).
- Raw items also carry `impact`, `interpretation`, `userAssumption` and `timeOrAttempts`; those
  are not in the master schema — follow `dedupedFrom` back to `raw/persona-results.json`.
- Test footprint: accounts `jerecho+blind1..6@fischbeck3.com` and `+blind2x`; leagues
  'The Papago Grind' (`THEPTCQ5`) and 'Desert Dogs' (`DESEUU0K`); rounds, a $5 match-play
  story, guest 'Marco', a skins round and board messages inside those leagues only.

*Companion documents in this folder: `README.md` (start here) · `blind-ux-audit.md` (master report) · `critical-findings.md` · `user-journey-map.md` · `gameplay-loop.md` · `rules-and-mental-model-audit.md` · `retention-audit.md` · the six `synthesis-*.md` files · `raw/` (persona reports, `persona-results.json`, `synthesis-and-validation-results.json`) · `screenshots/`.*
"""
    with open(README_MD, "w", encoding="utf-8") as f:
        f.write(text)


if __name__ == "__main__":
    main()

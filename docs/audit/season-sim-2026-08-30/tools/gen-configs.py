#!/usr/bin/env python3
"""Generate the trial matrix.

The cast is drawn from archetypes that describe how real friend-league golfers
actually behave — not uniform bots.  `skill` is the differential they truly
play to, `vol` the spread of that, `freq` expected rounds per week, `trend`
drift per week (negative = getting better).  The ghost and the lurker are the
important ones: every real league has them, and they are what stress the
participation floor and the squad-size question.
"""
import json, pathlib

ARCH = {
    "scratch":     dict(skill=3.0,  vol=2.5, freq=1.5, trend=0.0),
    "pro-grinder": dict(skill=6.5,  vol=3.0, freq=1.9, trend=-0.05),
    "steady":      dict(skill=11.0, vol=3.5, freq=1.3, trend=0.0),
    "weekender":   dict(skill=14.0, vol=4.0, freq=1.0, trend=0.0),
    "streaky":     dict(skill=13.0, vol=7.0, freq=1.2, trend=0.0),
    "improver":    dict(skill=18.0, vol=4.5, freq=1.4, trend=-0.20),
    "high-index":  dict(skill=24.0, vol=5.5, freq=1.1, trend=0.0),
    "lurker":      dict(skill=16.0, vol=4.0, freq=0.6, trend=0.0),
    "ghost":       dict(skill=15.0, vol=5.0, freq=0.25, trend=0.0),
}

# a realistic mix, in the order seats are filled
MIX = ["pro-grinder", "steady", "weekender", "ghost", "improver", "streaky",
       "scratch", "lurker", "high-index", "steady", "weekender", "improver"]

NAMES = ["Ray Fairway", "Cal Bunker", "Dot Mulligan", "Gus Ghost", "Vic Slice",
         "Hank Chip", "Sal Birdie", "Moe Duffer", "Tio Wedge", "Rex Divot",
         "Ida Ace", "Bud Shank"]
MARKERS = ["saguaro", "shark", "dunes", "lonetree", "island", "pews", "beer",
           "lighthouse", "saguaro", "shark", "dunes", "lonetree"]


def cast(n):
    out = []
    for i in range(n):
        a = MIX[i % len(MIX)]
        base = ARCH[a]
        # the posted starter index sits a touch above true ability, the way a
        # self-reported number usually does
        out.append(dict(name=NAMES[i % len(NAMES)], archetype=a, marker=MARKERS[i % len(MARKERS)],
                        index=round(base["skill"] + 0.5, 1), **base))
    return out


def cfg(slug, name, structure, players, weeks, finish, observer=None,
        solo_run=False, **kw):
    d = dict(name=name, structure=structure, finish=finish, weeks=weeks,
             allowance=95, counting_cap=4, floor=2, floor_penalty="deduct",
             season_format="points", buyin_cents=5000, payout=[60, 25, 15],
             buyins_paid=True, phase_target="complete", cast=cast(players))
    d.update(kw)
    if observer:
        seat, email = observer
        d["cast"][seat]["email"] = email
        d["observer_seat"] = seat
    # solo_run: one replicate only (an observed league, not a measured one)
    d["_single"] = solo_run or observer is not None
    return slug, d


MATRIX = [
    # ---- the counts the owner asked about --------------------------------
    cfg("a-2v2-cup",       "Papago Two-Man",     "squads2", 4,  13, "cup_final"),
    cfg("b-3v3-cup",       "Encanto Threes",     "squads2", 6,  17, "cup_final"),
    cfg("c-6v6-cup",       "Dobson Sixes",       "squads2", 12, 26, "cup_final"),
    cfg("e-solo10-cup",    "Aguila Ten",         "solo",    10, 17, "cup_final"),

    # ---- the same league, the other endgame (the finish question) --------
    cfg("d-6v6-points",    "Dobson Sixes PT",    "squads2", 12, 26, "points_table"),
    cfg("f-solo10-points", "Aguila Ten PT",      "solo",    10, 17, "points_table"),

    # ---- more squads, fewer per squad ------------------------------------
    cfg("g-3sq-cup",       "Grayhawk Threes",    "squads3", 12, 17, "cup_final"),
    cfg("h-4sq-cup",       "Grayhawk Fours",     "squads4", 12, 17, "cup_final"),

    # ---- rule variants ----------------------------------------------------
    cfg("i-hybrid",        "Hybrid Eight",       "squads2", 8,  17, "cup_final",
        season_format="hybrid"),
    cfg("j-cutthroat",     "Cutthroat Eight",    "squads2", 8,  17, "cup_final",
        floor=4, floor_penalty="forfeit", counting_cap=2, allowance=90),
    cfg("k-casual",        "Casual Eight",       "squads2", 8,  17, "cup_final",
        floor=0, floor_penalty="none", counting_cap=8, allowance=100),

    # ---- lengths ----------------------------------------------------------
    cfg("l-short",         "Short Eight",        "squads2", 8,  9,  "cup_final"),
    cfg("m-marathon",      "Marathon Eight",     "squads2", 8,  39, "cup_final"),

    # ---- THE PILOT SHAPE: individual / solo, 8-12 golfers ------------------
    # The Arizona pilot starts 2026-09-06 as a solo league of 8-12. Two things
    # are structurally different in solo: the participation floor is never
    # assessed (close_month only walks seated squad members), and a cup_final
    # sends only the TOP TWO to the final — so everyone else has nothing left
    # to win but Points King. Both are worth measuring at the real roster size.
    cfg("s1-solo8-points",  "Pilot Eight PT",   "solo",  8, 13, "points_table"),
    cfg("s2-solo8-cup",     "Pilot Eight Cup",  "solo",  8, 13, "cup_final"),
    cfg("s3-solo12-points", "Pilot Twelve PT",  "solo", 12, 13, "points_table"),
    cfg("s4-solo12-cup",    "Pilot Twelve Cup", "solo", 12, 13, "cup_final"),
    cfg("s5-solo10-long",   "Pilot Ten Long",   "solo", 10, 26, "cup_final"),
    cfg("s6-solo10-short",  "Pilot Ten Short",  "solo", 10,  9, "points_table"),

    # ---- observable states, for the screenshot pass ------------------------
    # Each carries one OBSERVER seat: a routable address a human can sign in to
    # with an email code, so the product can be seen from inside a real season.
    # The observer plays like everyone else, so the standings are honest.
    # Seat 0 is the Pro; a middle seat is an ordinary player.
    # Three of the four are SOLO at the pilot's roster size, because that is the
    # league the owner is about to run and those are the screens they will see.
    # The fourth is a two-squad league kept purely for visual contrast.
    # The observer seat is chosen per league so the tour shows three different
    # people, not the same one three times. Seat order in MIX is
    # 0 pro-grinder, 1 steady, 2 weekender, 3 ghost, 4 improver, ...
    cfg("obs-solo-mid",  "Tempe Solo League", "solo",    10, 13, "cup_final",
        phase_target="mid",       observer=(3, "jerecho+sim1@fischbeck3.com")),
    cfg("obs-solo-cup",  "Papago Ten",        "solo",    10, 13, "cup_final",
        phase_target="cup_final", observer=(0, "jerecho+sim2@fischbeck3.com")),
    cfg("obs-solo-done", "Encanto Ten",       "solo",    10, 13, "cup_final",
        phase_target="complete",  observer=(1, "jerecho+sim3@fischbeck3.com")),
    cfg("obs-squad-mid", "Dobson Two-Squad",  "squads2",  8, 13, "cup_final",
        phase_target="mid",       observer=(1, "jerecho+sim4@fischbeck3.com")),
]

if __name__ == "__main__":
    # Replicates matter: the squad draw uses the engine's own random(), and the
    # golf itself is seeded off the slug.  One wire-to-wire blowout is a draw;
    # three out of three is the format.  Live configs exist for the screenshot
    # pass, so they get one run each.
    REPLICATES = 3
    out = pathlib.Path(__file__).parent / "cfg"
    out.mkdir(exist_ok=True)
    n = 0
    for slug, d in MATRIX:
        reps = 1 if d.pop("_single", False) else REPLICATES
        for r in range(1, reps + 1):
            s = slug if reps == 1 else f"{slug}-r{r}"
            e = dict(d, name=d["name"] if reps == 1 else f"{d['name']} {r}")
            (out / f"{s}.json").write_text(json.dumps(e, indent=2) + "\n")
            n += 1
        print(f"{slug:18s} {d['structure']:8s} {len(d['cast']):3d}p "
              f"{d['weeks']:3d}w {d['finish']:12s} {d['phase_target']:9s} x{reps}")
    print(f"\n{n} config files written to {out}")

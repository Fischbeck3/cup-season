# Season simulation study — 2026-08-30

**Question the owner asked:** *"I can't run a season start to finish without wasting a
ton of time. I want to be sure the play is sound for our biggest feature and that the
finish is exciting and engaging."* A pilot with friends in Arizona starts 2026-09-06.

This directory holds a harness that plays whole Cup Season seasons against the **real**
engine in minutes, plus the results and the report.

## Why it had to work this way

There is no local substrate — no Docker, no local Postgres — so the only place a season
can actually run is production. D65 already built a sandbox for exactly this ("a season in
an hour"), but it caps at 8 bots and cannot produce the 6v6 or 10-player counts the owner
asked about. This harness is built in its spirit and goes wider.

Everything it creates is namespaced and removable:

* cast members are real but **never-loginable** auth users on the unroutable
  `@sim.cupseason.test` domain, `discoverable='nobody'`
* every league it makes is flagged `sandbox = true`
* the harness lives in its own `sim` schema, never in `public`, so it cannot collide
  with the app's RPC surface or the D37 grant discipline
* **`00-teardown.sql` was written before anything was created** and rehearses clean

## Fidelity — the rules that make the results mean something

A simulator that builds leagues differently than the app tests nothing. So:

* leagues are born through the real `create_league()` and `lock_league()`, called with the
  commissioner's own identity via `request.jwt.claims`, so `is_commissioner()` and the §15
  phase-from-stored-structure law really run
* the draw is the real `randomize_squads()`, and `start_season()` is really passed —
  including its "minimum four to tee off / nobody left in the pool / no empty squad" gates
* rounds are **direct inserts** into `public.rounds`, which is exactly what the client does
  (`index.html:6830`); the `score_round` trigger fills the differential and index snapshot,
  and the WHS-lite engine evolves each golfer's index round by round
* the endgame is driven by calling the engine's own functions in the order the daily tick
  would have reached them — months close as they elapse, `enter_cup_final()` fires **before**
  the final four weeks are played (so seeds lock on regular-season standings only, as they
  really would), then `close_season()` behind its real 48-hour grace gate

`daily_season_tick()` is deliberately **not** called: it loops every active season in the
database and would reach into real leagues. The law is copied; the blast radius is not.

## Randomness

Golf is deterministic per run: differentials come from `hashtext`-seeded Box-Muller, keyed
on `slug:seat:week`, so any run reproduces exactly. Validated before use — uniform χ² = 5.71
on 9 df (critical 16.92), normal mean 0.0096 / sd 0.9949 / 68.6% within 1σ.

The **squad draw** is the engine's own `random()`, so it varies run to run. That is why
every measured config runs **three replicates**: one wire-to-wire blowout is a draw, three
out of three is the format.

## Layout

```
tools/00-teardown.sql     the safety net (rehearse with rollback; commit to scrap)
tools/10-sim-schema.sql   sim schema, cast creation, seeded RNG
tools/20-sim-run.sql      build / play / snapshot — the season itself
tools/30-sim-result.sql   the measurement layer
tools/gen-configs.py      the trial matrix
tools/run.sh              one config:  ./run.sh dry|live cfg/<slug>.json
tools/save.py             extract one run's result into data/
cfg/                      generated config files
data/                     one JSON result per simulated season
shots/                    screenshots from the observer seats
```

`dry` wraps a run in a transaction and rolls it back — all measurement still comes back,
because the result is computed inside the transaction. `live` commits, which is what the
screenshot pass needs and the only mode that leaves a footprint.

## Measures

Two owner questions, and the numbers that answer them:

*Is the play sound?* — `lead_changes`, `led_outright_from_week`, `weeks_led_unchallenged`,
`points_margin` / `margin_pct`, the `bands` histogram, per-member `ppr` (points per counting
round), and whether the participation floor ever actually fired.

*Is the finish exciting?* — `cup_flipped_result` (did the Cup Final crown someone other than
the regular-season leader), `head_start_decisive`, `champion_score` vs `runnerup_score`,
whether the Champion and the Points King are the same person, and `tiebreak_rung`.

`led_outright_from_week` is **hindsight** — the week after which the eventual winner was
never caught *in this run*. It is the right measure for "when did this stop being
interesting", but it is not the engine's own deliberately generous clinch math (D24) and
must never be quoted as what the app would have told a player at the time.

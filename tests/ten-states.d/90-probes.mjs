/* Defect probes (WX lane). Not gallery states: each runs only with
   `--only probe`, and each exists to reproduce one finding with evidence. */
export default [
  /* PROBE 1 · Play opened while the league roster read fails.
     primeRealRoster() (index.html ~12982) re-primes after loadLeagueData()
     whenever CS.members is empty; loadLeagueData() (~27787) leaves
     CS.members = [] on a failed read without throwing (requireRoom false),
     so the pair re-enter each other for as long as the read keeps failing.
     The harness caps the run at `requestLimit` and marks requestStorm. */
  { family: 'probe', id: 'play-roster-read-fails', variant: 'member', probe: true, requestLimit: 600,
    prepare: async (W) => { W.errors.when = [{ table: 'league_members', match: (q) => /league_id=eq\./.test(q), error: { __error: 'fixture: roster read failed', status: 503 } }] },
    drive: async (page) => { await page.evaluate(() => window.switchView('play')); await page.waitForTimeout(4000) },
    expectConsole: [/status of 503/, /loadLeagueData\] photo select failed/],
    expect: { view: 'view-play' } },
  /* PROBE 2 · the same pair when the roster read SUCCEEDS EMPTY -- what RLS
     returns once a golfer has been removed from the league while the app is
     open. No retry backoff throttles it: the harness cuts it off at the
     request limit and records requestStorm. */
  { family: 'probe', id: 'play-roster-read-empty', variant: 'member', probe: true, requestLimit: 800,
    prepare: async (W) => { W.errors.when = [{ table: 'league_members', match: (q) => /league_id=eq\./.test(q), error: [] }] },
    drive: async (page) => { await page.evaluate(() => window.switchView('play')); await page.waitForTimeout(3000) },
    expect: { view: 'view-play' } },
]

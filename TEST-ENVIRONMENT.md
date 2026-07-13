# Cup Season — Test Environment (get in / get out)

There is **no separate server**. The "test environment" is a set of **bot
accounts + fake leagues + a Ryder event seeded into the real production
project**. It's safe because:

- Bots are `discoverable = 'nobody'` → invisible to the real crew's search.
- Everything is **cascade-cleanable** — deleting the bot auth users wipes their
  profiles, memberships, rounds, and the event.
- Your own account, profile, and rounds are **never touched**.

**Golden rule: always `reset` before onboarding the real pilot crew.**

---

## One-time setup (do once, or after any change to the seed)

Run in **PowerShell** (these are your-environment commands — Claude can't run them):

```
supabase db push                       # applies any pending migrations
supabase functions deploy test-seed    # deploys/updates the seed function
```

> If you change nothing in `supabase/`, you don't need to repeat these.
> **A migration (`db push`) does NOT deploy the function** — they're separate.
> Any fix to `test-seed` requires `functions deploy test-seed` to take effect.

---

## GET IN — build the test world

Signed into your **real account** (not the demo) on cupseason.app, open the
browser console (**F12 → Console**) and run:

```js
await sb.functions.invoke('test-seed', { body:{ action:'seed' } }).then(r => console.log(JSON.stringify(r.data), r.error))
```

Success looks like `{"ok":true,"log":["bots: 8", "L1 … ✓", …, "Ryder event 'The Grudge' … ✓"]}`.

`seed` auto-`reset`s first, so **re-running it always gives a fresh world** — no
need to reset separately between rebuilds.

**What you get:** 8 bot golfers, four leagues (one of each state — 2-squad
mid-season, solo, 4-squad pre-kickoff, 2-squad Cup Final), weeks of scored
rounds, a friend graph, scheduled rounds, and **"The Grudge"** — a live Ryder
event attached to the Ridgeline Cup league.

**Where things show up after a reload:**
- Leagues + the Ryder → tap the **league name at the top** (or sidebar) to open
  the **Switch** sheet. Leagues are listed; the Ryder is under **Events → The
  Grudge** (opens the scoreboard). *The Ryder is not a tab.*
- Standings/board/calendar populate inside each league.

---

## GET OUT — wipe the test world

```js
await sb.functions.invoke('test-seed', { body:{ action:'reset' } }).then(r => console.log(JSON.stringify(r.data), r.error))
```

Success = `{"removed":{"events":N,"leagues":N,"bots":8,"errors":[]}}`.
**`errors: []` is the real success signal** — a nonempty `errors` array names
whatever is still holding a bot profile.

**Verify clean:**
```js
await sb.from('events').select('id,name').then(r => console.log('events', JSON.stringify(r.data)))   // → []
await sb.from('leagues').select('name,code').then(r => console.log('leagues', JSON.stringify(r.data))) // → [] (no TST… codes)
```

**Guaranteed fallback (no CLI):** Dashboard → **Authentication → Users** →
search `cupseason.test` → select all → **Delete**. Their data cascades away.

---

## The demo (a different "test mode")

The **demo** is unrelated to the seed — it's a client-side diorama (hardcoded
scenery, no database writes, no Ryder). Use it for a quick look at the UI
without an account.

- **In:** on the sign-in screen, join with code **`DEMO`**.
- **Out:** append **`/?exit`** to the URL (e.g. `cupseason.app/?exit`) — this
  also clears stuck tab-locks — or sign out.

---

## Troubleshooting (lessons already paid for)

| Symptom | Cause | Fix |
|---|---|---|
| `A user with this email address has already been registered` | Old bots weren't deleted | Redeploy the function, then `reset` (or dashboard-delete the `cupseason.test` users) |
| `reset` says `bots: 8` but re-seed still fails | You're running an **old** function version | `supabase functions deploy test-seed`, then retry |
| Ran `db push`, still old behavior | `db push` ≠ function deploy | `supabase functions deploy test-seed` |
| `reset` returns `errors: [...]` | A `RESTRICT` FK still references a bot | Paste the errors — they name the blocking table |
| Nothing shows in the app | On the **demo**, or not reloaded | Sign into the real account; hard-reload |

---

## Safety recap
- Bots can't be found by real users (`discoverable = 'nobody'`).
- Test leagues use `TST…` codes and are invisible unless you're a member.
- **Always `reset` before the real pilot** so no bot/league/event lingers.

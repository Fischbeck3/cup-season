# Cup Season — Privacy Policy

**DRAFT for counsel review — not yet legally binding. Last updated 2026-07-18.**
_Placeholders in ⟨angle brackets⟩ need a lawyer + real entity details before launch._

Cup Season ("we", "us") is a season-long fantasy-golf app for private friend
groups, operated by ⟨legal entity / sole proprietor name⟩ in Arizona, USA. This
policy explains what we collect, why, and your choices. We wrote it to be read.

## What we collect

**You give us:**
- **Email address** — to sign you in (one-time codes, no passwords) and send
  the notifications you opt into.
- **Golfer card** — display name, handle, city, home course, ball marker, and
  an optional starting handicap index. Optional **GHIN number** if you choose to
  add one (a reference field only — we never resell or publish it).
- **Rounds you post** — gross score, course, date, and (if you use the stepper
  or a scan) per-hole strokes. **Photos** you attach to a round or scan.
- **League activity** — the leagues you join, squads, buy-in tracking, board
  posts, reactions, and live-game (Match/Wolf/Skins) results.

**We generate:**
- A derived handicap index once you've posted enough rounds.
- Points, standings, trophies, and rivalry records computed from your rounds.
- Basic product analytics (which screens are used, funnel steps) tied to your
  account so we can fix friction. We do **not** use third-party ad trackers.

**We do not collect** payment card details (there is no in-app payment today),
precise location, contacts, or device identifiers beyond what a standard web app
sees.

## How the pot works (important)

Cup Season **tracks** buy-ins and payouts as a scoreboard. We **never hold,
transfer, or process any money.** All settlement happens directly between
players, off-platform. See the separate **Pot & Money Disclaimer**.

## How we use it

To run your leagues, score your rounds, show standings, send notifications you
turned on, and improve the product. That's the whole list. We don't sell your
data, and we don't share your handicap index or email with advertisers or data
brokers — ever.

## Who can see what

- Your **email is private** — never shown to other users, and not readable
  through the app's data layer by anyone but you.
- Your **golfer card, rounds, standings, and photos** are visible to people you
  share a league with, people you share a Ryder event with, and friends you've
  accepted. Search shows only the fields you make discoverable (you can set
  discoverability to "nobody").
- Scanned scorecards and round photos live in a private store and are served
  only to those connected users, via short-lived signed links.

## Service providers

We use **Supabase** (database, auth, storage — US region), **Netlify** (hosting),
**Brevo** (transactional email), and **Anthropic** (the scorecard-scan feature
sends the photo you choose to scan to Anthropic's API to read the numbers; images
are processed to return scores and are not used to train models). Each processes
data only to provide their service to us.

## Retention & deletion

You can delete your account from Settings. If your data underpins other players'
history (rounds in a shared league, ledger entries), we replace your identifying
fields with "Former member" and retire your login, keeping only the competition
records others' seasons depend on. Otherwise we remove your account outright and
free your email for reuse. Photos you delete are removed from storage.

## Your choices

Turn notifications on/off per type in Settings. Set discoverability. Add or
remove your GHIN at any time. Request a copy of your data or ask questions at
⟨privacy@cupseason.app⟩.

## Kids

Cup Season isn't directed to anyone under ⟨13 / 16 — counsel to set⟩ and we don't
knowingly collect their data.

## Changes

We'll note material changes in-app. Continued use after a change means you accept
the updated policy.

## Contact

⟨privacy@cupseason.app⟩ · ⟨mailing address if required by jurisdiction⟩

---
_Counsel checklist before launch: confirm the operating entity; CCPA/“sale”
language (we don't sell, state it formally); GDPR basis if any EU players; COPPA
age gate; data-processing agreements with Supabase/Netlify/Brevo/Anthropic;
breach-notification commitment; whether GHIN/handicap counts as sensitive data
in any state._

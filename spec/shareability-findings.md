# Shareability findings — recipient-side audit, 2026-07-22

Walked as the RECIPIENT: signed-out, 375×812 phone viewport, local build
(v23 dev, SW + caches cleared) + prod for OG/asset checks. Companion to
`spec/shareability-arc.md`; fixes marked INLINE ship this lane, ⚑ items are
named follow-ups.

## F1 · Invite link greets with the code, not the league — FIXED INLINE
`/?join=PIGL01` lands on the door reading **"You're invited: code PIGL01.
Enter your email…"** — machine voice at the warmest moment in the funnel.
The name lookup (`league_by_code`, anon-callable) already exists and fires on
*manual* code entry (`#joinGo` path stashes `cs_code_name`); the LINK path —
the one recipients actually take — never called it. Fix: resolve the name when
the `?join=` param lands, refresh the door line when it arrives ("You're
invited to **PIGL**…").

## F2 · Door + covenant carry the funnel well — no fix
Email box auto-opens on a pending join/claim (verified live); the covenant
(D3 three rules, D39 ledger language) shows once after join and ends on the
share ask. Time-to-value after a claim is real: "Claimed ✓ — your 84 is on
your card" + the career view refreshes.

## F3 · Dead claim link fails silent — FIXED INLINE
Valid token: the door leads with the round ("Marcus — 84 at Papago · …") —
the strongest copy in the app. Dead/claimed/garbage token: **nothing** — the
generic marketing door, no acknowledgment the tap meant anything. The token
also stayed in localStorage, so a later sign-in fired a doomed claim + error
toast. Fix: when both info RPCs return nothing, say so plainly ("That
scorecard link has expired or was already claimed…") and drop the stored
token. Same empty answer for every bad token — no enumeration surface.

## F4 · Recap + jug cards are screenshot-proof — register only
Both canvas artifacts (round recap, Major jug) are 1080×1350, 300px hero
number, wordmark + `cupseason.app` printed ON the card — a feed-size
screenshot survives with attribution intact. The jug card carries a verb
("START YOURS AT CUPSEASON.APP"); the round card's footer is quieter by
design (D30: keepsake first, not a billboard). Leave both.

## F5 · Game settlements produce no artifact — drives Part 2
Match/Wolf/Skins settle into a sheet + board post; only guest rows mint
links. The settlement story ("A def. B 3&2 · $10 on Venmo") — the exact
thing a group chat wants — never leaves the app as anything tappable.
Part 2's `kind='settlement'` share link is the fix (plus `round` and
`recap`).

## F6 · One OG for every link — static v1 accepted, ⚑ per-share OG
Prod head + `og-image.png` (1200×630, 207KB, live 200) are strong and
legible at feed size. But every deep link — `/?join=`, `/?claim=`, and the
new `/?share=` — unfurls as the same generic app card; a shared ROUND link
shows no round in iMessage/WhatsApp. Per-share OG needs an edge function
serving crawler-readable HTML per token. ⚑ Follow-up (Growth); static OG is
v1 by decision (arc brief).

## F7 · Stale join code can outrank a fresh claim landing — register only
`cs_code` persists across visits; a device that once tapped a join link
shows the invite copy on a later dead-claim landing. Valid claim info still
overwrites (its door card renders after). F3's token cleanup halves the
confusion; full priority rules not worth the machinery at pilot scale.

## Shipped this lane (Part 2)
Public share pages: `shares` table + `create_share`/`revoke_share`
(authenticated) + `share_info` (the ONE new anon endpoint, fail-closed
curated jsonb) · `/?share=TOKEN` card view on the shell · lazy mint from the
round-recap and settlement share moments. See decision D57 +
migration `20260722_public_shares`.

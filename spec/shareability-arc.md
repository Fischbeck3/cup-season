# Shareability arc — from "seen at the course" to "send me the link"

**Lane:** Growth (session-tracks: Growth/Launch gets it in front of people).
**Mission:** a golfer who *sees* Cup Season — over a shoulder, in a group text,
on a feed — should be one tap from wanting in. Audit every existing share
surface, sharpen it, and BUILD the missing one: public share pages.

## Decisions already made (owner, 2026-07-22)

- **Full send approved: build public share pages this lane** — a round card, a
  game settlement, and a season recap viewable WITHOUT an account, plus the
  anon-surface migration that serves them. Not proposals; shipping.
- Marketing canon stands: shareable artifacts are THE acquisition motion (no
  paid). D39 money language verbatim on anything showing a pot.

## Part 1 — sharpen what exists (audit → fix)

Walk each surface as the RECIPIENT (signed-out phone):
- **Invite link** `/?join=CODE` — landing copy, covenant, door friction.
- **Guest claim** `/?claim=` — the strongest funnel; time-to-value after claim.
- **Settlement + recap cards** — share-sheet output: legible at feed size? App
  name + URL on-card? Screenshot-proof (most shares are screenshots)?
- **OG image / title / description** — what a pasted link looks like in
  iMessage/WhatsApp/X.
- Register findings in the doc (`spec/shareability-findings.md`), fix inline
  where small, batch where not.

## Part 2 — public share pages (the build)

**Architecture (follow unless the code argues otherwise):**
- `shares` table: `token uuid pk default gen_random_uuid()`, `kind`
  (`round|settlement|recap`), `ref_id uuid`, `created_by uuid`, `revoked bool
  default false`, `created_at`. RLS on, no policies (definer-only).
- `create_share(p_kind, p_ref)` → token (authenticated; verifies the caller
  owns/played the artifact). `revoke_share(p_token)` (creator). Share buttons
  mint lazily — no share exists until a golfer chooses to share (§16 spirit:
  the golfer publishes, we never do).
- `share_info(p_token)` — **the ONE new anon endpoint.** Security definer,
  returns a curated jsonb snapshot (names, gross, bands language, course,
  date; NEVER email, never raw rows, no enumeration — unknown/revoked token =
  same empty answer). Grant anon + authenticated, revoke public.
- Client route `/?share=TOKEN`: lightweight card view on the existing shell —
  the artifact big, "Built with Cup Season" + one CTA ("Start your crew's
  season" → door). No nav, no app boot beyond what the card needs.
- Share sheet on round/settlement/recap surfaces: "Share a link" alongside the
  existing image share.

**Non-negotiable rails:**
- **D37 discipline:** migration carries explicit grant/revoke; update
  `tests/db-checks.sql` check #3 — the anon literal list goes 4 → 5
  (`share_info`) — and the CLAUDE.md line naming "the four public endpoints."
  Run checks 2+3+9 after push (owner runs; hand the SQL).
- **Decision-log entry BEFORE the anon migration** (hierarchy: IA/visibility
  touches §16 + D37): current state · problem · the token model · why
  fail-closed · tradeoffs.
- Tokens are the ONLY access path; ids never appear in share URLs.
- Per-share OG images need an edge function — ⚑ flag as follow-up, static OG
  is v1.
- Deploy split: migration = owner db push; state exact commands in handoff.

## Exit criteria

Findings doc pushed · existing-surface fixes live · shares migration + client
route + mint/revoke UI live behind owner's db push · db-checks updated (4→5) ·
D-log entry in `spec/decision-log.md` · handoff: push commands + checks 2/3/9
SQL + a test share link path for the owner to tap.

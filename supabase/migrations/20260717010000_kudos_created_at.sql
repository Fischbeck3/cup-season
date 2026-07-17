-- Reactions learn what time it is.
--
-- The Home digest answers "what happened since you were here" — and a reaction
-- landing on YOUR round is exactly that kind of news ("Ed 🔥'd your 84"). But
-- post_kudos has never carried a timestamp, so "since" was unanswerable.
--
-- Pre-existing rows get stamped at migration time. Acceptable: reactions are
-- days old at most (the feature shipped 2026-07-16), and the digest only
-- compares against each viewer's own seen-mark — worst case a reaction is
-- mentioned once as slightly newer than it really was, then ages out.
--
-- Deploy-skew: the client reads via select('*') and skips kudos rows with no
-- created_at in the payload (no time → no "since" claim). Neither order of
-- the two deploys breaks a live user, and nothing is ever substituted.

alter table public.post_kudos
  add column if not exists created_at timestamptz not null default now();

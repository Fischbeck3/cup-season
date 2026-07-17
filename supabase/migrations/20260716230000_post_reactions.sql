-- Post reactions — give post_kudos a curated, golf-flavored vocabulary.
--
-- Until now a "kudos" was one anonymous row per (post, member): a single
-- undifferentiated cheer. The board is meant to feel alive (product principle
-- 4), and a golf crew's reaction to a round is never one note — a suspicious
-- 79 collects a 🦅 AND a 🚨 in the same breath. So a reaction now carries an
-- emoji, and a member can stack distinct reactions on one post (Slack-style):
--   🔥 heater · 🦅 the eagle · ⛳ dialed · 🧊 ice · 🐍 snake · 🚨 sandbagger.
--
-- The table keeps its name (post_kudos) — renaming a live, realtime-published
-- table is churn for no gain; the client speaks "reactions" over it.
-- RLS (kudos_all), the supabase_realtime membership, and grants all ship in
-- the baseline and are untouched here. post_kudos has never had a client
-- writer (kudos were local-only echoes), so the table is empty in prod and the
-- primary-key repoint below is a no-op on existing data.

alter table public.post_kudos
  add column if not exists emoji text not null default '🔥';

-- light hygiene: an emoji, not an essay (a couple of code points at most)
alter table public.post_kudos
  drop constraint if exists post_kudos_emoji_len;
alter table public.post_kudos
  add constraint post_kudos_emoji_len check (char_length(emoji) <= 8);

-- repoint the PK so a member can hold more than one reaction per post
alter table public.post_kudos drop constraint if exists post_kudos_pkey;
alter table public.post_kudos
  add constraint post_kudos_pkey primary key (post_id, member_id, emoji);

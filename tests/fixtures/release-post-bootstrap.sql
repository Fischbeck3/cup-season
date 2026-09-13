-- post.sql — runs AFTER the migration chain. Recreates the one piece of the
-- production database that lives outside supabase/migrations: the signup
-- trigger on auth.users (created from the Supabase dashboard in prod; the
-- migrations only define public.handle_new_user() and refer to "the m001
-- signup trigger"). Without it a simulated signup mints no profile.
\set ON_ERROR_STOP on
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

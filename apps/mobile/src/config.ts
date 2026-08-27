/* Backend coordinates.
 *
 * Both values are already public — they are served in plain sight inside
 * index.html on every page load of cupseason.app, which is what "publishable"
 * means. The key grants nothing on its own: D37 left `anon` with ZERO relation
 * privileges in `public` and exactly ten callable RPCs, and that was proven by
 * probing prod with this key and getting zero rows from every table.
 *
 * So this is not a secret and does not belong in a secrets store. The things
 * that ARE secret — VAPID, PUSH_WEBHOOK_SECRET, BREVO, ANTHROPIC_API_KEY —
 * live in Supabase secrets and are never reachable from a client.
 */
export const SUPABASE_URL = 'https://zddbfcokmvneltrgukzf.supabase.co';
export const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_UoORp_4FTRWg6a7foKqxRA_N2f5kHVS';

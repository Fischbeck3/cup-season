/* The one Supabase client this app has.
 *
 * "One" is load-bearing. When realtime arrives in B4 it gets its own dedicated
 * client, because a channel join on the client that also serves queries and
 * auth fails with CHANNEL_ERROR / transport failure — verified the hard way on
 * the web, where a raw socket and a fresh client both subscribed fine on the
 * same machine with the same token while the busy one did not. Nothing in B1
 * lays groundwork that assumes otherwise; when the second client is created,
 * bind its token with `bindRealtimeAuth` from the shared layer.
 */
import 'react-native-url-polyfill/auto';
import { AppState } from 'react-native';
import { createClient } from '@supabase/supabase-js';
import { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from './config';
import { secureStorage } from './secure-store';

export const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    /* the Keychain, chunked — see secure-store.ts */
    storage: secureStorage,
    persistSession: true,
    autoRefreshToken: true,
    /* there is no URL to detect a session in; leaving this on makes the client
       reach for browser globals that do not exist here */
    detectSessionInUrl: false,
    /* deliberately NO `lock`. The web client passes a pass-through lock to dodge
       navigator.locks being origin-wide across tabs. In auth-js as installed
       here the option is deprecated outright — the client dedupes refreshes
       itself and lets the server resolve races — and passing one opts into a
       legacy path that wraps every auth call. A phone has no tabs and needs
       neither. */
  },
});

/* Tokens expire while the app is backgrounded. Supabase's auto-refresh runs on
   a timer that iOS suspends, so it is started and stopped with the app's own
   lifecycle instead — otherwise the first call after a long background sits on
   a dead token and fails once before recovering. */
AppState.addEventListener('change', (next) => {
  if (next === 'active') supabase.auth.startAutoRefresh();
  else supabase.auth.stopAutoRefresh();
});

/* Who is signed in, for the whole app.
 *
 * Everything auth-shaped here comes from `@cs/db` rather than from the
 * Supabase client directly. That is the point of the shared layer: the rules
 * this project paid to learn are encoded in those functions, so the phone
 * cannot quietly reintroduce a magic link or a six-digit input, and the Phase
 * D desktop rewrite will inherit the same protections for free.
 */
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { currentSession, onAuth, type Session } from '@cs/db';
import { supabase } from './supabase';

interface SessionState {
  session: Session | null;
  /** false until the stored session has been read back out of the Keychain.
   *  Rendering the signed-out screen before this is true produces a flash of
   *  the sign-in form on every cold start for someone already signed in. */
  ready: boolean;
}

const Ctx = createContext<SessionState>({ session: null, ready: false });

export function SessionProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<SessionState>({ session: null, ready: false });

  useEffect(() => {
    let alive = true;

    currentSession(supabase)
      .then((session) => { if (alive) setState({ session, ready: true }); })
      .catch(() => { if (alive) setState({ session: null, ready: true }); });

    /* onAuth defers the handler to a microtask. That deferral is why it is
       safe for anything downstream of setState to touch auth again: calling an
       auth method synchronously inside this callback is the deadlock with no
       error output, the worst failure this codebase has had, because there is
       no message to search for. */
    const off = onAuth(supabase, (_event, session) => {
      if (alive) setState({ session, ready: true });
    });

    return () => { alive = false; off(); };
  }, []);

  return <Ctx.Provider value={state}>{children}</Ctx.Provider>;
}

export const useSession = () => useContext(Ctx);

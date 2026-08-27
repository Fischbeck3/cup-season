/* Session storage in the iOS Keychain, chunked.
 *
 * The web client keeps its session in localStorage because that is all a
 * browser offers. A phone offers the Keychain, so the refresh token does not
 * sit in cleartext inside the app sandbox — and `navigator.locks`, the
 * origin-wide landmine that zombie tabs used to wedge, simply does not exist
 * here. That is the trade B1 makes: a better store, and one fewer landmine.
 *
 * Why chunking. expo-secure-store documents a 2048-byte ceiling per value and
 * warns (today) rather than throwing; a Supabase session — two JWTs plus the
 * user object — runs past it as soon as the token carries any real claims. A
 * warning that becomes an error in a later SDK, on the one value that decides
 * whether a person is signed in, is not something to discover later. So every
 * value is split, and the split is uniform: small values simply produce one
 * chunk.
 *
 * Layout for key K holding N chunks:
 *   K      -> "N"          (the count, always a plain integer string)
 *   K.0..N-1 -> the slices
 *
 * A partially-written or partially-wiped set reads back as null, which signs
 * the person out and asks for a fresh code. That is the correct failure: a
 * half-session is worse than no session, and the recovery costs one email.
 */
import * as SecureStore from 'expo-secure-store';

/* Comfortably under the documented 2048-byte ceiling. Session payloads are
   base64 and ASCII, so one character is one byte here. */
const CHUNK = 1536;

/* AFTER_FIRST_UNLOCK, not WHEN_UNLOCKED: the token must be readable while the
   phone is locked in a pocket, which is exactly when a background refresh (and,
   from B5, a push handler) needs it. THIS_DEVICE_ONLY keeps it out of iCloud
   Keychain — a session should not silently follow the account to a new phone. */
const OPTS: SecureStore.SecureStoreOptions = {
  keychainAccessible: SecureStore.AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY,
};

const part = (key: string, i: number) => `${key}.${i}`;

async function countAt(key: string): Promise<number> {
  const raw = await SecureStore.getItemAsync(key, OPTS);
  if (raw === null) return 0;
  const n = Number.parseInt(raw, 10);
  return Number.isInteger(n) && n >= 0 ? n : 0;
}

async function clear(key: string, n: number): Promise<void> {
  const kills: Promise<void>[] = [];
  for (let i = 0; i < n; i++) kills.push(SecureStore.deleteItemAsync(part(key, i), OPTS));
  await Promise.all(kills);
}

export const secureStorage = {
  async getItem(key: string): Promise<string | null> {
    const n = await countAt(key);
    if (n === 0) return null;

    const slices = await Promise.all(
      Array.from({ length: n }, (_, i) => SecureStore.getItemAsync(part(key, i), OPTS)),
    );
    /* any missing slice means the set is torn — treat the whole value as absent
       rather than handing back a truncated JSON blob that fails to parse
       somewhere far away from here */
    if (slices.some((s) => s === null)) {
      await this.removeItem(key);
      return null;
    }
    return slices.join('');
  },

  async setItem(key: string, value: string): Promise<void> {
    const slices: string[] = [];
    for (let i = 0; i < value.length; i += CHUNK) slices.push(value.slice(i, i + CHUNK));
    if (slices.length === 0) slices.push('');

    /* stale slices from a previous, longer value would otherwise survive and
       corrupt the next read, so the old count is captured before overwriting */
    const wasN = await countAt(key);

    await Promise.all(
      slices.map((s, i) => SecureStore.setItemAsync(part(key, i), s, OPTS)),
    );
    await SecureStore.setItemAsync(key, String(slices.length), OPTS);

    for (let i = slices.length; i < wasN; i++) {
      await SecureStore.deleteItemAsync(part(key, i), OPTS);
    }
  },

  async removeItem(key: string): Promise<void> {
    const n = await countAt(key);
    await clear(key, n);
    await SecureStore.deleteItemAsync(key, OPTS);
  },
};

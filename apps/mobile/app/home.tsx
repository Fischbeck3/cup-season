/* The landing screen, and B1's whole gate: wearing the real palette, with real
 * data behind it.
 *
 * It reads ONE RPC — `tour_card` — through the shared layer's typed `call()`.
 * That is deliberate. A screen that only proved auth would leave the RPC
 * contract and the deploy-skew retry untested on the phone until B2; one real
 * typed call proves the whole path end to end while still being nothing anyone
 * would mistake for a feature.
 *
 * Not here, and not by accident: scoring, the board, push, standings, the tee
 * sheet. And never on a phone at all — the wizard, the draft board, the ledger,
 * the founder desk. Those are the desk's job (D98).
 */
import { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, Pressable, ScrollView, Text, View } from 'react-native';
import { Redirect } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { call, signOut, type Json } from '@cs/db';
import { supabase } from '../src/supabase';
import { useSession } from '../src/session';
import { useTheme, type Theme } from '../src/theme';

interface Card {
  visible: boolean;
  profile?: { display_name?: string; handle?: string; marker?: string; city?: string; index_current?: number };
  career?: { rounds?: number; best?: number; avg_pvi?: number };
}

export default function Home() {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const { session, ready } = useSession();

  const [card, setCard] = useState<Card | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const load = useCallback(async (profileId: string) => {
    setErr(null);
    try {
      const data = await call(supabase, 'tour_card', { p_profile: profileId });
      setCard(data as unknown as Card);
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    }
  }, []);

  useEffect(() => {
    if (session?.user?.id) void load(session.user.id);
  }, [session?.user?.id, load]);

  if (!ready) return null;
  if (!session) return <Redirect href="/" />;

  const p = card?.profile;
  const name = p?.display_name || session.user.email || 'Golfer';

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.color.bg0 }}
      contentContainerStyle={{
        paddingHorizontal: 24,
        paddingTop: insets.top + 32,
        paddingBottom: insets.bottom + 32,
      }}
    >
      <Text style={{ color: t.color.mut, fontSize: 12, letterSpacing: 1.4, marginBottom: 10 }}>
        SIGNED IN
      </Text>

      <Text style={{ color: t.color.ink, fontFamily: t.font.serif, fontSize: 34, marginBottom: 6 }}>
        {name}
      </Text>
      <Text style={{ color: t.color.dim, fontSize: 14, fontFamily: t.font.mono, marginBottom: 28 }}>
        {session.user.email}
      </Text>

      {!card && !err ? (
        <ActivityIndicator color={t.color.brand} style={{ marginVertical: 24 }} />
      ) : null}

      {card?.visible ? (
        <View
          style={{
            flexDirection: 'row',
            gap: 12,
            marginBottom: 24,
          }}
        >
          <Stat t={t} label="INDEX" value={fmt(p?.index_current, 1)} tone={t.color.gold} />
          <Stat t={t} label="ROUNDS" value={fmt(card.career?.rounds, 0)} tone={t.color.ink} />
          <Stat t={t} label="BEST" value={fmt(card.career?.best, 1)} tone={t.color.pos} />
        </View>
      ) : null}

      {p?.marker ? (
        <Text style={{ color: t.color.mut, fontSize: 14, marginBottom: 8 }}>
          {`Ball marker · ${p.marker}`}
        </Text>
      ) : null}
      {p?.city ? (
        <Text style={{ color: t.color.mut, fontSize: 14, marginBottom: 8 }}>{p.city}</Text>
      ) : null}

      {err ? (
        <View
          style={{
            backgroundColor: t.color.bg1,
            borderColor: t.color.neg,
            borderWidth: 1,
            borderRadius: t.radius.rc,
            padding: 16,
            marginTop: 16,
          }}
        >
          <Text style={{ color: t.color.neg, fontSize: 14, lineHeight: 20 }}>{err}</Text>
        </View>
      ) : null}

      <View style={{ height: 1, backgroundColor: t.color.line, marginVertical: 32 }} />

      <Text style={{ color: t.color.dim, fontSize: 13, lineHeight: 20, marginBottom: 28 }}>
        B1 is the scaffold: it boots, it wears the palette, and it signs you in.
        The round, the board and push come next.
      </Text>

      <Pressable
        onPress={() => { void signOut(supabase); }}
        style={({ pressed }) => ({
          borderColor: t.color.line2,
          borderWidth: 1,
          borderRadius: t.radius.rc,
          paddingVertical: 14,
          alignItems: 'center',
          opacity: pressed ? 0.7 : 1,
        })}
      >
        <Text style={{ color: t.color.mut, fontSize: 16 }}>Sign out</Text>
      </Pressable>
    </ScrollView>
  );
}

/* A dash, never a zero: an index that has not been established yet is absent,
   and showing 0.0 would read as a scratch golfer. */
function fmt(n: number | null | undefined, places: number): string {
  return typeof n === 'number' && Number.isFinite(n) ? n.toFixed(places) : '—';
}

function Stat({ t, label, value, tone }: { t: Theme; label: string; value: string; tone: string }) {
  return (
    <View
      style={{
        flex: 1,
        backgroundColor: t.color.bg1,
        borderColor: t.color.line,
        borderWidth: 1,
        borderRadius: t.radius.rc,
        paddingVertical: 16,
        paddingHorizontal: 12,
        ...t.shadow.rest,
      }}
    >
      <Text style={{ color: t.color.dim, fontSize: 10, letterSpacing: 1.2, marginBottom: 6 }}>
        {label}
      </Text>
      <Text style={{ color: tone, fontSize: 24, fontFamily: t.font.mono }}>{value}</Text>
    </View>
  );
}

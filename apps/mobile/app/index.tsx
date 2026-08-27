/* The door: email in, eight digits back, signed in.
 *
 * Code-only OTP, and structurally so — `requestEmailCode` takes an email and
 * nothing else, so there is no `emailRedirectTo` to pass even by accident.
 * Gmail's link scanner consumes single-use tokens before the person clicks,
 * which is why every link-bearing template this project tried has burned.
 */
import { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator, KeyboardAvoidingView, Platform, Pressable,
  ScrollView, Text, TextInput, View,
} from 'react-native';
import { Redirect } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  OTP_LENGTH, humanAuthError, isCompleteCode, looksLikeEmail,
  normalizeCode, requestEmailCode, verifyEmailCode,
} from '@cs/db';
import { supabase } from '../src/supabase';
import { useSession } from '../src/session';
import { useTheme } from '../src/theme';

type Stage = 'email' | 'code';
type Note = { text: string; tone: 'mut' | 'neg' | 'pos' } | null;

export default function SignIn() {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const { session, ready } = useSession();

  const [stage, setStage] = useState<Stage>('email');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<Note>(null);
  const codeRef = useRef<TextInput>(null);

  const send = useCallback(async () => {
    if (busy) return;
    if (!looksLikeEmail(email)) return setNote({ text: 'That does not look like an email address.', tone: 'neg' });
    setBusy(true);
    setNote({ text: 'Sending your code…', tone: 'mut' });
    try {
      await requestEmailCode(supabase, email);
      setStage('code');
      setNote({ text: `Check your email for ${OTP_LENGTH} digits.`, tone: 'pos' });
      setTimeout(() => codeRef.current?.focus(), 250);
    } catch (e) {
      setNote({ text: humanAuthError(e, 'Could not send the code.'), tone: 'neg' });
    } finally {
      setBusy(false);
    }
  }, [busy, email]);

  const verify = useCallback(async (raw: string) => {
    if (busy) return;
    setBusy(true);
    setNote({ text: 'Checking the code…', tone: 'mut' });
    try {
      await verifyEmailCode(supabase, email, raw);
      /* no navigation here on purpose: the session provider hears SIGNED_IN and
         the redirect at the top of this component takes it from there, so there
         is exactly one path into the app */
      setNote({ text: 'Signed in.', tone: 'pos' });
    } catch (e) {
      setNote({ text: humanAuthError(e, 'That code did not take.'), tone: 'neg' });
      setCode('');
    } finally {
      setBusy(false);
    }
  }, [busy, email]);

  /* Supabase issues EIGHT digits — never six, and never a maxLength that says
     otherwise. Auto-submit the moment a full code is typed or pasted. */
  useEffect(() => {
    if (isCompleteCode(code) && !busy) void verify(code);
  }, [code]);

  if (!ready) return <Booting />;
  if (session) return <Redirect href="/home" />;

  const label = { color: t.color.mut, fontSize: 12, letterSpacing: 1.2, marginBottom: 8 };
  const field = {
    backgroundColor: t.color.bg1,
    borderColor: t.color.line,
    borderWidth: 1,
    borderRadius: t.radius.rc,
    color: t.color.ink,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 17,
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: t.color.bg0 }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        contentContainerStyle={{
          flexGrow: 1, justifyContent: 'center',
          paddingHorizontal: 24,
          paddingTop: insets.top + 24, paddingBottom: insets.bottom + 24,
        }}
        keyboardShouldPersistTaps="handled"
      >
        <Text style={{ color: t.color.ink, fontFamily: t.font.serif, fontSize: 40, marginBottom: 4 }}>
          Cup Season
        </Text>
        <Text style={{ color: t.color.mut, fontSize: 15, marginBottom: 40 }}>
          Season-long golf, for your actual friends.
        </Text>

        {stage === 'email' ? (
          <View>
            <Text style={label}>EMAIL</Text>
            <TextInput
              value={email}
              onChangeText={setEmail}
              style={field}
              placeholder="you@example.com"
              placeholderTextColor={t.color.dim}
              autoCapitalize="none"
              autoCorrect={false}
              keyboardType="email-address"
              textContentType="emailAddress"
              returnKeyType="go"
              onSubmitEditing={() => void send()}
              editable={!busy}
            />
            <Button t={t} busy={busy} label="Send my code" onPress={() => void send()} />
          </View>
        ) : (
          <View>
            <Text style={label}>{`THE ${OTP_LENGTH} DIGITS`}</Text>
            <TextInput
              ref={codeRef}
              value={code}
              onChangeText={(v) => setCode(normalizeCode(v))}
              style={[field, { fontFamily: t.font.mono, fontSize: 28, letterSpacing: 8, textAlign: 'center' }]}
              placeholder="••••••••"
              placeholderTextColor={t.color.dim}
              keyboardType="number-pad"
              /* iOS lifts the code straight out of the notification */
              textContentType="oneTimeCode"
              autoComplete="sms-otp"
              editable={!busy}
              autoFocus
            />
            <Button t={t} busy={busy} label="Verify" onPress={() => void verify(code)} />
            <Pressable
              onPress={() => { setStage('email'); setCode(''); setNote(null); }}
              hitSlop={12}
              style={{ marginTop: 20, alignSelf: 'center' }}
            >
              <Text style={{ color: t.color.dim, fontSize: 14 }}>
                {`Sent to ${email} — change it`}
              </Text>
            </Pressable>
          </View>
        )}

        {note ? (
          <Text style={{ color: t.color[note.tone], fontSize: 14, marginTop: 20, lineHeight: 20 }}>
            {note.text}
          </Text>
        ) : null}
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

function Button({ t, busy, label, onPress }: {
  t: ReturnType<typeof useTheme>; busy: boolean; label: string; onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={busy}
      style={({ pressed }) => ({
        backgroundColor: t.color.brand,
        opacity: busy ? 0.5 : pressed ? 0.85 : 1,
        borderRadius: t.radius.rc,
        paddingVertical: 16,
        alignItems: 'center',
        marginTop: 16,
        ...t.shadow.rest,
      })}
    >
      {busy
        ? <ActivityIndicator color={t.color.ink} />
        : <Text style={{ color: t.color.ink, fontSize: 17, fontWeight: '600' }}>{label}</Text>}
    </Pressable>
  );
}

function Booting() {
  const t = useTheme();
  return (
    <View style={{ flex: 1, backgroundColor: t.color.bg0, alignItems: 'center', justifyContent: 'center' }}>
      <ActivityIndicator color={t.color.brand} />
    </View>
  );
}

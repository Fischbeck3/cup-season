import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { SessionProvider } from '../src/session';
import { useTheme } from '../src/theme';

export default function RootLayout() {
  const t = useTheme();
  return (
    <SafeAreaProvider>
      <SessionProvider>
        {/* light glyphs: D76 Charcoal is the default, so bg0 is near-black */}
        <StatusBar style="light" />
        <Stack
          screenOptions={{
            headerShown: false,
            animation: 'fade',
            contentStyle: { backgroundColor: t.color.bg0 },
          }}
        />
      </SessionProvider>
    </SafeAreaProvider>
  );
}

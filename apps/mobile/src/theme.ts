/* The palette, converted for React Native — and ONLY converted.
 *
 * `packages/tokens` is the source of truth for all 34 tokens in both themes,
 * and preflight check 10 already guarantees the live web client cannot
 * disagree with it. This file is what lets a second surface share that
 * guarantee, because the tokens are CSS-shaped: `r` is the string "16px",
 * `sans` is a browser font stack, `shadow-lift` is a box-shadow string.
 *
 * The rule this file obeys, and the reason it is small: it CONVERTS, it never
 * INVENTS. Every colour passes through byte-for-byte — there is no lightening,
 * no opacity blending, no "close enough" substitute anywhere below. If the
 * phone needs a colour that is not in tokens.json, the answer is to add it to
 * tokens.json under a decision-log entry, not to mix one here.
 *
 * Two honest approximations are called out at their definitions: CSS blur
 * radius is twice RN's shadowRadius, and Android elevation has no CSS
 * equivalent at all. Both are unit conversions on numbers that come from the
 * tokens; neither introduces a value of its own.
 */
import { Platform } from 'react-native';
import type { TextStyle, ViewStyle } from 'react-native';
import { themes, defaultTheme, type ThemeName, type TokenName } from '@cs/tokens';

export type { ThemeName };

/* The colour-valued tokens, named explicitly so a future non-colour token
   cannot silently arrive in `color` and be handed to a style prop. */
export const colorTokens = [
  'bg0', 'bg1', 'bg2', 'line', 'line2', 'ink', 'mut', 'dim',
  'pos', 'neg', 'gold', 'brand', 'pine', 'dawn', 'focus',
  'warm', 'hot', 'fire', 'cool', 'sq0', 'sq1', 'sq2', 'sq3', 'glow',
] as const;
export type ColorToken = (typeof colorTokens)[number];

/* ---------------------------------------------------------------------------
 * Conversions.
 * ------------------------------------------------------------------------ */

/** "16px" -> 16. Throws rather than defaulting: a token that stops being a
 *  length is a change worth failing on, not one worth guessing through. */
function px(v: string): number {
  const n = Number.parseFloat(v);
  if (!Number.isFinite(n)) throw new Error(`theme: expected a length, got "${v}"`);
  return n;
}

/** Pick the first family in a CSS stack that the platform actually ships.
 *  The token keeps its full browser stack; this walks it rather than choosing
 *  a font of its own. `undefined` means "the platform's own default", which is
 *  what -apple-system / BlinkMacSystemFont mean on their native platforms. */
function family(stack: string, available: string[]): string | undefined {
  const wanted = stack.split(',').map((s) => s.trim().replace(/^['"]|['"]$/g, ''));
  for (const w of wanted) {
    const hit = available.find((a) => a.toLowerCase() === w.toLowerCase());
    if (hit) return hit;
  }
  return undefined;
}

/* Families genuinely present on each platform, so `family()` above has a real
   list to intersect the token's stack with. */
const PLATFORM_FAMILIES = Platform.select({
  ios: ['Menlo', 'Charter', 'Georgia', 'Palatino'],
  android: ['monospace', 'serif'],
  default: [] as string[],
}) as string[];

/** "0 18px 44px -12px rgba(0,0,0,.55)" -> RN shadow props.
 *
 *  The two approximations, both stated rather than hidden:
 *    - CSS blur is about twice RN's shadowRadius, so blur/2 is the standard
 *      equivalence. Spread has no RN counterpart and is dropped.
 *    - Android has no shadow primitive, only `elevation`, a single number.
 *      It is derived from the blur so a bigger CSS shadow is a bigger
 *      elevation; there is no exact mapping and there cannot be one.
 */
function shadow(css: string): ViewStyle {
  const rgba = css.match(/rgba?\(([^)]+)\)/);
  const lengths = css.replace(/rgba?\([^)]+\)/, '').trim().split(/\s+/).map(px);
  const [dx = 0, dy = 0, blur = 0] = lengths;

  /* No literal fallback on purpose: a shadow token without a colour is a
     malformed token, and preflight check 13 forbids this file from naming a
     colour of its own. Fail loudly rather than invent black. */
  if (!rgba) throw new Error(`theme: shadow token has no colour: "${css}"`);
  const parts = rgba[1].split(',').map((s) => s.trim());
  const [r, g, b] = parts;
  const color = `rgb(${r}, ${g}, ${b})`;
  const opacity = parts.length > 3 ? Number.parseFloat(parts[3]) : 1;

  return Platform.select({
    ios: {
      shadowColor: color,
      shadowOffset: { width: dx, height: dy },
      shadowRadius: blur / 2,
      shadowOpacity: opacity,
    },
    android: { elevation: Math.round(blur / 4) },
    default: {},
  }) as ViewStyle;
}

/* ---------------------------------------------------------------------------
 * The theme a screen actually consumes.
 * ------------------------------------------------------------------------ */
export interface Theme {
  name: ThemeName;
  color: Record<ColorToken, string>;
  radius: { r: number; rc: number; rs: number };
  font: { sans: TextStyle['fontFamily']; mono: TextStyle['fontFamily']; serif: TextStyle['fontFamily'] };
  shadow: { rest: ViewStyle; lift: ViewStyle };
  /** Every token verbatim, for anything this adapter has not needed yet.
   *  Reading a colour from here is fine; it is the same string. */
  raw: Record<TokenName, string>;
}

function build(name: ThemeName): Theme {
  const t = themes[name];
  const color = {} as Record<ColorToken, string>;
  for (const k of colorTokens) color[k] = t[k];   /* verbatim, always */

  return {
    name,
    color,
    radius: { r: px(t.r), rc: px(t.rc), rs: px(t.rs) },
    font: {
      sans: family(t.sans, PLATFORM_FAMILIES),
      mono: family(t.mono, PLATFORM_FAMILIES),
      serif: family(t.serif, PLATFORM_FAMILIES),
    },
    shadow: { rest: shadow(t['shadow-rest']), lift: shadow(t['shadow-lift']) },
    raw: t,
  };
}

const BUILT: Record<ThemeName, Theme> = { dark: build('dark'), light: build('light') };

/* D76 Charcoal: dark is the default, and a brand-new user lands in it. Both
   themes are built above and correct; B1 simply ships no picker yet, so this
   hook is a constant. When the picker arrives it becomes a context read and
   nothing that calls useTheme() has to change. */
export function useTheme(): Theme {
  return BUILT[defaultTheme];
}

export const getTheme = (name: ThemeName): Theme => BUILT[name];

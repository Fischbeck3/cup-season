#!/usr/bin/env node
/* Cup Season · synthetic copies of the legacy fixtures (WX lane, 2026-09-28).
 *
 *   node tests/ten-fixtures-build.mjs          # write the copies
 *   node tests/ten-fixtures-build.mjs --check  # fail if a copy is stale or leaks a name
 *
 * tests/fixtures/home-states.json and tests/fixtures/season-book/*.json carry
 * names that match real pilot people. Other suites depend on those files, so
 * they are NOT rewritten; this writes SYNTHETIC COPIES under
 * tests/fixtures/ten/ with every person, league, squad and course name
 * replaced by an invented one, and then scans each copy for every original
 * name (whole word, any case) -- one survivor fails the build. The ten
 * harness serves the copies in place of the originals. */
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { createHash } from 'node:crypto'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const FX = join(HERE, 'fixtures')
const OUT = join(FX, 'ten')
const check = process.argv.includes('--check')

/* longest-first; each pair is also applied in UPPER CASE */
const HOME_RENAMES = [
  ['Galen v Sam', 'Blake v Avery'],
  ['Sam Ridley', 'Avery Fixture'], ['Galen Marr', 'Blake Sample'], ['Tash Bell', 'Casey Placeholder'], ['Mike Fenner', 'Finley Stubbs'],
  ['@galen-marr', '@blake-sample-fx'], ['galen-marr', 'blake-sample-fx'],
  ['The Desert Showdown', 'The Fixture Showdown'], ['The Dew Sweepers', 'The Early Fixture Sweepers'],
  ['Fellas', 'North Grove (fixture)'], ['FELLAS', 'NGFX26'], ['DEWSWP', 'EFSWPX'],
  ['Galen', 'Blake'], ['Tash', 'Casey'], ['Jade', 'Devon'], ['Mike', 'Finley'], ['Sam', 'Avery'], ['Dev', 'Emery'],
]
const BOOK_RENAMES = [
  ['Priya Raghunathan', 'Noel Dryrun'], ['Jade Okafor', 'Emery Mockridge'], ['Galen Marr', 'Blake Sample'], ['Sam Ridley', 'Casey Placeholder'],
  ['Tash Bell', 'Devon Testwell'], ['Dev Rana', 'Finley Stubbs'], ['Mike Fenner', 'Gray Dummett'], ['Alex Park', 'Harper Examplar'],
  ['Cam Ellis', 'Indigo Longname-Fixturington'], ['Eli Brandt', 'Jules Sandbox'], ['Lee Santos', 'Kit Specimen'], ['Nora Vance', 'Lane Mockup'],
  ['Owen Pike', 'Morgan Stand-In'], ['Robin West', 'Oakley Proxy'], ['Ruth Salas', 'Parker Sampleton'],
  ['The Fellas', 'North Grove (fixture)'], ['The Autumn Cup', 'The Autumn Fixture Cup'], ['The Saturday Cup', 'The Saturday Fixture Cup'],
  ['The Summer Cup', 'The Summer Fixture Cup'],
  ['Galen', 'Blake'], ['Jade', 'Emery'], ['Lee', 'Kit'], ['Priya', 'Noel'], ['Fellas', 'North Grove (fixture)'],
  ['Sam', 'Casey'], ['Tash', 'Devon'], ['Dev', 'Finley'], ['Mike', 'Gray'], ['Alex', 'Harper'], ['Cam', 'Indigo'], ['Eli', 'Jules'],
  ['Nora', 'Lane'], ['Owen', 'Morgan'], ['Robin', 'Oakley'], ['Ruth', 'Parker'],
]
/* every token that must not survive, whole word, case-insensitive */
const FORBIDDEN = ['Alex', 'Cam', 'Eli', 'Nora', 'Owen', 'Robin', 'Ruth', 'Sam', 'Ridley', 'Galen', 'Marr', 'Tash', 'Jade', 'Dev', 'Mike', 'Fenner', 'Fellas', 'Okafor', 'Rana',
  'Priya', 'Raghunathan', 'Alex Park', 'Cam Ellis', 'Eli Brandt', 'Lee Santos', 'Nora Vance', 'Owen Pike', 'Robin West', 'Ruth Salas',
  'Tash Bell', 'Dew Sweepers', 'Desert Showdown', 'galen-marr']

/* X37 (2026-09-29) · the owner's and the pilot crew's own values, the owner's league, squads and city,
   and real course names were swept out of tests/ at their source; so that a copy can never carry
   them back without this file naming them, they are held as SHA-256 prefixes of the lowercased
   value, matched against every one- to three-word run of a copy */
const SEALED = new Set(["04919a87d26b85f9", "1d467e154a652525", "ff5a407957368a27", "7742f5a7759dd1c0", "014298608d74e939", "2c56f2d760fee01d", "8916b9ecfa71f502", "49043b0424b12252", "956a2746327f96f5", "6d9194a5de1e5ae7", "8ef0eede829c2059", "d51457357f3098fe", "da94b9192b1b9627", "f930293bf2be04b6", "39638f7cab095791", "27ee52946759413c", "017ecb3f4ebaf8d6", "5ba4c5ad7f67ea1a", "b4472cf9e37c221a", "1382dca91398a112", "d8710cb5d8462862"])
function sealedLeaks(text) {
  const words = (text.toLowerCase().match(/[a-z0-9]+/g) || [])
  let n = 0
  for (let i = 0; i < words.length; i++) for (let k = 1; k <= 3 && i + k <= words.length; k++) {
    if (SEALED.has(createHash('sha256').update(words.slice(i, i + k).join(' ')).digest('hex').slice(0, 16))) n++
  }
  return n
}
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
function rename(text, pairs) {
  const all = []
  for (const [a, b] of pairs) { all.push([a, b]); if (a.toUpperCase() !== a) all.push([a.toUpperCase(), b.toUpperCase()]) }
  all.sort((x, y) => y[0].length - x[0].length)
  for (const [a, b] of all) text = text.replace(new RegExp(`(?<![A-Za-z0-9])${esc(a)}(?![A-Za-z0-9])`, 'g'), b)
  /* the pilot handle "sam" as a JSON value */
  text = text.replace(/"handle":\s*"sam"/g, '"handle": "avery"')
  return text
}
function leaks(text) {
  const hits = []
  for (const w of FORBIDDEN) { const m = text.match(new RegExp(`(?<![A-Za-z0-9_])${esc(w)}(?![A-Za-z0-9_])`, 'i')); if (m) hits.push(w) }
  return hits
}

const jobs = [
  { src: join(FX, 'home-states.json'), dst: join(OUT, 'home-states.synthetic.json'), pairs: HOME_RENAMES },
  ...['upcoming', 'squads', 'tie', 'finished', 'home'].map((n) => ({ src: join(FX, 'season-book', n + '.json'), dst: join(OUT, `book-${n}.synthetic.json`), pairs: BOOK_RENAMES })),
]
let bad = 0
for (const j of jobs) {
  const raw = readFileSync(j.src, 'utf8')
  let text = rename(raw, j.pairs)
  const doc = JSON.parse(text)
  if (doc && typeof doc === 'object' && !Array.isArray(doc)) {
    doc._ten = { synthetic_copy_of: j.src.slice(join(HERE, '..').length + 1), note: 'Generated by tests/ten-fixtures-build.mjs. Every person, league, squad and course name is invented; edit the source fixture and regenerate, never this copy.' }
  }
  text = JSON.stringify(doc, null, 1) + '\n'
  const leak = leaks(text.replace(/"synthetic_copy_of":[^\n]*\n/, ''))
  if (leak.length) { console.log(`LEAK ${j.dst}: ${leak.join(', ')}`); bad++ }
  const sealed = sealedLeaks(text)
  if (sealed) { console.log(`LEAK ${j.dst}: ${sealed} sealed value(s)`); bad++ }
  if (check) {
    const cur = existsSync(j.dst) ? readFileSync(j.dst, 'utf8') : ''
    if (cur !== text) { console.log(`STALE ${j.dst}`); bad++ } else console.log(`ok   ${j.dst}`)
  } else {
    writeFileSync(j.dst, text)
    console.log(`wrote ${j.dst}`)
  }
}
process.exit(bad ? 1 : 0)

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
  ['Gold Canyon Golf Resort', 'Whispering Fixture Pines Resort'], ['Gold Canyon', 'Whispering Fixture Pines'],
  ['Desert Mountain', 'Mesquite Wash (fixture)'], ['Papago Golf Course', 'Papago Fixture Links'],
  ['Fellas', 'North Grove (fixture)'], ['FELLAS', 'NGFX26'], ['DEWSWP', 'EFSWPX'],
  ['Galen', 'Blake'], ['Tash', 'Casey'], ['Jade', 'Devon'], ['Mike', 'Finley'], ['Sam', 'Avery'], ['Dev', 'Emery'],
  ['Papago', 'Saguaro Flats'],
]
const BOOK_RENAMES = [
  ['Priya Raghunathan', 'Noel Dryrun'], ['Jade Okafor', 'Emery Mockridge'], ['Galen Marr', 'Blake Sample'], ['Sam Ridley', 'Casey Placeholder'],
  ['Tash Bell', 'Devon Testwell'], ['Dev Rana', 'Finley Stubbs'], ['Mike Fenner', 'Gray Dummett'], ['Alex Park', 'Harper Examplar'],
  ['Cam Ellis', 'Indigo Longname-Fixturington'], ['Eli Brandt', 'Jules Sandbox'], ['Lee Santos', 'Kit Specimen'], ['Nora Vance', 'Lane Mockup'],
  ['Owen Pike', 'Morgan Stand-In'], ['Robin West', 'Oakley Proxy'], ['Ruth Salas', 'Parker Sampleton'], ['Jerecho', 'Avery Fixture'],
  ['The Fellas', 'North Grove (fixture)'], ['The Autumn Cup', 'The Autumn Fixture Cup'], ['The Saturday Cup', 'The Saturday Fixture Cup'],
  ['The Summer Cup', 'The Summer Fixture Cup'], ['Coyotes', 'Fixture Wrens'], ['Mudsharks', 'Fixture Javelinas'],
  ['Roadrunners', 'Fixture Quail'], ['Saguaros', 'Fixture Gilas'],
  ['Galen', 'Blake'], ['Jade', 'Emery'], ['Lee', 'Kit'], ['Priya', 'Noel'], ['Fellas', 'North Grove (fixture)'],
  ['Sam', 'Casey'], ['Tash', 'Devon'], ['Dev', 'Finley'], ['Mike', 'Gray'], ['Alex', 'Harper'], ['Cam', 'Indigo'], ['Eli', 'Jules'],
  ['Nora', 'Lane'], ['Owen', 'Morgan'], ['Robin', 'Oakley'], ['Ruth', 'Parker'],
]
/* every token that must not survive, whole word, case-insensitive */
const FORBIDDEN = ['Alex', 'Cam', 'Eli', 'Nora', 'Owen', 'Robin', 'Ruth', 'Sam', 'Ridley', 'Galen', 'Marr', 'Tash', 'Jade', 'Dev', 'Mike', 'Fenner', 'Fellas', 'Jerecho', 'Okafor', 'Rana',
  'Priya', 'Raghunathan', 'Alex Park', 'Cam Ellis', 'Eli Brandt', 'Lee Santos', 'Nora Vance', 'Owen Pike', 'Robin West', 'Ruth Salas',
  'Tash Bell', 'Dew Sweepers', 'Desert Showdown', 'galen-marr', 'Coyotes', 'Mudsharks', 'Roadrunners', 'Saguaros']

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
  if (check) {
    const cur = existsSync(j.dst) ? readFileSync(j.dst, 'utf8') : ''
    if (cur !== text) { console.log(`STALE ${j.dst}`); bad++ } else console.log(`ok   ${j.dst}`)
  } else {
    writeFileSync(j.dst, text)
    console.log(`wrote ${j.dst}`)
  }
}
process.exit(bad ? 1 : 0)

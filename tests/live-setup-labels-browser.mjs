#!/usr/bin/env node
/* F08 web · the live setup's tee, rating and slope each keep a visible name
   and an accessible one once filled, at 44px, without overflow.
     node tests/live-setup-labels-browser.mjs [--base http://127.0.0.1:8801] */
import { createRequire } from 'node:module'
const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const { chromium } = require(process.env.CS_PLAYWRIGHT || (process.env.HOME || '') + '/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const b = await chromium.launch({ executablePath: (process.env.HOME || '') + '/Library/Caches/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-mac-arm64/chrome-headless-shell' })
let bad=0
for (const w of [320, 375, 402, 1280]) for (const theme of ['dark','light']) {
  const ctx = await b.newContext({ viewport: { width: w, height: 800 }, serviceWorkers: 'block' })
  await ctx.addInitScript(t => localStorage.setItem('cs_theme', t), theme)
  const p = await ctx.newPage()
  await p.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await p.goto(BASE + '/?exit', { waitUntil: 'load' }); await p.waitForTimeout(1500)
  const r = await p.evaluate(() => {
    const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'
    switchView('play'); document.getElementById('playSetup').style.display = ''
    const f = ['lrTee','lrRate','lrSlope'].map(id => { const i = document.getElementById(id); const lab = i.labels && i.labels[0]; const span = lab && lab.querySelector('span'); const r = i.getBoundingClientRect(); return { id, name: span ? span.textContent : null, labelShown: !!span && span.getClientRects().length > 0, value: i.value, h: Math.round(r.height), w: Math.round(r.width), clipped: i.scrollWidth > i.clientWidth + 2 } })
    const legend = document.querySelector('.teefields legend')?.textContent
    return { f, legend, overflow: document.documentElement.scrollWidth - innerWidth }
  })
  const ok = r.f.every(x => x.name && x.labelShown && x.h >= 44) && r.overflow <= 0
  if (!ok) bad++
  console.log(w, theme, ok ? 'OK' : 'BAD', JSON.stringify(r.f.map(x => `${x.name}=${x.value} ${x.w}x${x.h}`)), r.legend, 'overflow', r.overflow)
  await ctx.close()
}
await b.close(); process.exit(bad?1:0)

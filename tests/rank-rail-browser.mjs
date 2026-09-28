#!/usr/bin/env node
/* The rank rail's numeral on its painted states — your row (panel) and the
   leader's (gold) — on the season table and the friends board, both themes.
   They read --panelInk, a name no rule defines (the token is --panel-ink), so
   the numeral fell back to the page ink: ~1:1 in both themes. It also asserts
   every var() the stylesheet reads is defined, so a misspelt token cannot
   silently fall back again.
     node tests/rank-rail-browser.mjs [--base http://127.0.0.1:8801] */
import { createRequire } from 'node:module'
const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const { chromium } = require(process.env.CS_PLAYWRIGHT || '/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
let bad = 0
const b = await chromium.launch({ executablePath: '/Users/fischbeck3/Library/Caches/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-mac-arm64/chrome-headless-shell' })
for (const theme of ['dark','light']) {
  const ctx = await b.newContext({ viewport: { width: 1280, height: 900 }, serviceWorkers: 'block' })
  await ctx.addInitScript(t => localStorage.setItem('cs_theme', t), theme)
  const p = await ctx.newPage()
  await p.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await p.goto(BASE + '/?exit', { waitUntil: 'load' }); await p.waitForTimeout(1200)
  const got = await p.evaluate(() => {
    const lum = s => { const a = s.match(/[\d.]+/g).slice(0, 3).map(Number).map(c => { c /= 255; return c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4 }); return .2126 * a[0] + .7152 * a[1] + .0722 * a[2] }
    const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05) }
    const host = document.createElement('div'); host.innerHTML = '<table class="tbl"><tr class="mine"><td class="rk">02</td></tr><tr class="lead"><td class="rk">01</td></tr></table><div class="fbrow mine"><span class="rk">02</span></div>'; document.querySelector('.view.active').appendChild(host)
    const m = host.querySelector('tr.mine .rk'), l = host.querySelector('tr.lead .rk'), f = host.querySelector('.fbrow.mine .rk')
    const r = e => +ratio(getComputedStyle(e).color, getComputedStyle(e).backgroundColor).toFixed(2)
    const out = { tblMine: r(m), tblLead: r(l), fbMine: r(f) }; host.remove()
    /* every custom property the page reads resolves to something */
    const css = [...document.querySelectorAll('style')].map(s => s.textContent).join('\n')
    const used = new Set([...css.matchAll(/var\((--[A-Za-z0-9_-]+)\s*\)/g)].map(m => m[1]))
    const root = getComputedStyle(document.documentElement)
    /* defined = set on the root, or set anywhere in the page's own source
       (a rule, an inline style, or a script's setProperty, as the door's
       squad dots are) */
    const src = document.documentElement.outerHTML
    out.undefinedVars = [...used].filter(v => !root.getPropertyValue(v).trim() && !src.includes(v + ':') && !src.includes("'" + v + "'"))
    return out
  })
  const ok = got.tblMine >= 4.5 && got.tblLead >= 4.5 && got.fbMine >= 4.5 && got.undefinedVars.length === 0
  if (!ok) bad++
  console.log((ok ? '  PASS  ' : 'X FAIL  ') + theme + ' ' + JSON.stringify(got))
  await ctx.close()
}
await b.close(); process.exit(bad ? 1 : 0)

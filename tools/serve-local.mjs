#!/usr/bin/env node
/* Cup Season — a dependency-free static server for the web half's local walk.
 *
 *   node tools/serve-local.mjs [port] [seconds]
 *
 * Serves the repository root (so `index.html`, `sw.js`, the manifest and the
 * icons resolve exactly as Netlify's allowlist would) on 127.0.0.1 for a
 * bounded number of seconds, then exits. Dev-only: nothing here is served in
 * production, and `stamp-version.sh`'s allowlist keeps it out of `dist/`.
 * It exists because a review found the walk being run against whatever
 * happened to be listening on a shared port — this one is yours, and it says
 * which build it is serving. */
import { createServer } from 'node:http'
import { readFile } from 'node:fs/promises'
import { join, extname, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = dirname(dirname(fileURLToPath(import.meta.url)))
const port = parseInt(process.argv[2] || '8794', 10)
const seconds = parseInt(process.argv[3] || '300', 10)
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
                '.json': 'application/json', '.css': 'text/css', '.svg': 'image/svg+xml', '.png': 'image/png',
                '.webmanifest': 'application/manifest+json', '.ico': 'image/x-icon', '.jpg': 'image/jpeg' }

const server = createServer(async (req, res) => {
  let p = decodeURIComponent((req.url || '/').split('?')[0])
  if (p === '/') p = '/index.html'
  try {
    const data = await readFile(join(root, p))
    res.writeHead(200, { 'Content-Type': types[extname(p)] || 'application/octet-stream', 'Cache-Control': 'no-store' })
    res.end(data)
  } catch { res.writeHead(404); res.end() }
})
server.listen(port, '127.0.0.1', () => {
  console.log(`serving ${root} on http://127.0.0.1:${port}/ for ${seconds}s`)
})
setTimeout(() => { server.close(); process.exit(0) }, seconds * 1000)

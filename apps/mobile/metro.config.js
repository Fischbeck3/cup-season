/* Metro, taught where the shared layer lives.
 *
 * `packages/` sits outside this app's root, so Metro needs two things: to WATCH
 * it (or edits there never trigger a reload) and to resolve `@cs/tokens` /
 * `@cs/db` to it. Those two packages carry a three-line manifest each so the
 * import specifier is a name rather than a count of `../`.
 *
 * Note what is deliberately NOT here: a root package.json. Netlify runs an
 * automatic dependency install the moment it finds one at the repo root, and
 * this site has no dependencies to install — it is one HTML file and a shell
 * script. A nested manifest inside packages/ is invisible to that detection,
 * which is why the aliases below cost nothing at the deploy layer. (A4, and
 * the reason it still holds.)
 */
const { getDefaultConfig } = require('expo/metro-config');
const path = require('node:path');

const projectRoot = __dirname;
const repoRoot = path.resolve(projectRoot, '../..');

const config = getDefaultConfig(projectRoot);

/* watch the shared layer so editing a token or an RPC type hot-reloads */
config.watchFolders = [path.resolve(repoRoot, 'packages')];

/* This app owns the only node_modules in the tree. There is no root manifest
   by design, so there is no root node_modules above it and nothing to resolve
   upward into — which is also why `disableHierarchicalLookup` is deliberately
   NOT set here. It was, briefly, as a guard against a second copy of React
   loading from above; there is nothing above, and it broke a real dependency
   instead: npm nests @expo/metro-runtime under expo-router/node_modules and
   Metro has to be allowed to walk to it. */
config.resolver.nodeModulesPaths = [path.resolve(projectRoot, 'node_modules')];

/* `@cs/*` resolves into the shared layer. packages/tokens and packages/db each
   carry a three-line manifest so the specifier is a name rather than a count
   of `../` — and a NESTED manifest is not a root manifest, which is what keeps
   A4's Netlify reasoning intact. */
config.resolver.extraNodeModules = {
  '@cs/tokens': path.resolve(repoRoot, 'packages/tokens'),
  '@cs/db': path.resolve(repoRoot, 'packages/db'),
};

module.exports = config;

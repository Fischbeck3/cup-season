import assert from 'node:assert/strict';
import { access } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
import test from 'node:test';
import * as fc from 'fast-check';

const packageRoot = fileURLToPath(new URL('../../', import.meta.url));

test('runs as ESM with all isolated staging directories present', async () => {
  assert.equal(import.meta.url.startsWith('file:'), true);

  await Promise.all(
    ['src', 'fixtures', 'generated-evidence', 'test'].map((directory) =>
      access(join(packageRoot, directory)),
    ),
  );
});

test('loads the pinned fast-check dependency', () => {
  assert.equal(typeof fc.assert, 'function');
  assert.deepEqual(
    fc.sample(fc.constant('ember'), { numRuns: 3, seed: 76 }),
    ['ember', 'ember', 'ember'],
  );
});

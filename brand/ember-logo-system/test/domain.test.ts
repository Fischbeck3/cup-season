import assert from 'node:assert/strict';
import test from 'node:test';
import {
  ImmutableRecordStore,
  SchemaError,
  authorityStatementSchema,
  canonicalSerialize,
  checksumOf,
  logoSystemGraphSchema,
  sealRecord,
  selectionContextSchema,
  verifyRecordChecksum,
} from '../src/index.js';
import type {
  AuthorityStatement,
  Candidate,
  CompositionSpec,
  ConflictRecord,
  EvidenceArtifact,
  EvidencePackage,
  ExportSpec,
  GateResult,
  GeometryManifest,
  ImmutableRecord,
  LogoSystemGraph,
  MigrationEntry,
  OwnerException,
  StudyProtocol,
  ValidationResult,
  VariantSpec,
} from '../src/index.js';

const seal = <T extends ImmutableRecord>(input: Omit<T, 'checksum'>): T =>
  sealRecord<T>(input) as T;
const version = '1.0.0';

function validGraph(): LogoSystemGraph {
  const authority = seal<AuthorityStatement>({
    id: 'authority-d76', version, rank: 'vision', sourcePath: 'spec/decision-log.md',
    sourceSection: 'D76', statement: 'Charcoal identity semantics govern.', status: 'active',
  });
  const candidate = seal<Candidate>({
    id: 'candidate-ember', version, kind: 'new-territory', territoryName: 'Ember Cup',
    motionNative: true, primarySilhouetteId: 'path-cup', requiredDetailIds: ['path-ember'],
    negativeSpaceSignature: 'cup-held ember',
    semanticMappings: [
      { featureId: 'path-cup', visibleBehavior: 'cup silhouette', meaning: 'real-golf', authorityRefs: [authority.id] },
      { featureId: 'path-ember', visibleBehavior: 'rising ember', meaning: 'momentum', authorityRefs: [authority.id], colorRole: 'ember' },
    ],
    status: 'testing', sourceChecksum: checksumOf({ source: 'candidate.svg' }),
  });
  const composition = seal<CompositionSpec>({
    id: 'composition-core', version, candidateId: candidate.id, kind: 'core',
    geometryRef: 'geometry-core', clearSpaceRatio: 0.25,
  });
  const geometry = seal<GeometryManifest>({
    id: 'geometry-core', version, compositionId: composition.id, candidateId: candidate.id,
    artboard: { x: 0, y: 0, width: 100, height: 100 },
    viewBox: { x: 0, y: 0, width: 100, height: 100 },
    geometryBounds: { x: 10, y: 8, width: 80, height: 84 }, opticalCenter: { x: 50, y: 50 },
    silhouettePathIds: ['path-cup'], requiredDetailPathIds: ['path-ember'],
    closedContourPathIds: ['path-cup', 'path-ember'], minStroke: 2, minGap: 2, units: 'svg-unit',
  });
  const variant = seal<VariantSpec>({
    id: 'variant-dark', version, compositionId: composition.id, mode: 'full-dark',
    roleAssignments: { 'path-cup': 'paper', 'path-ember': 'ember' }, backgroundRole: 'charcoal',
    alphaPolicy: 'opaque', semanticUse: ['identity', 'live-momentum'],
  });
  const plannedExport = seal<ExportSpec>({
    id: 'export-svg', version, filename: 'candidate-ember-core.svg', compositionId: composition.id,
    variantId: variant.id, width: 100, height: 100, unit: 'px', format: 'svg', colorSpace: 'sRGB',
    colorValues: { charcoal: '#0C0D0F', paper: '#EFF2EE', ember: '#FF5A2E' },
    alphaPolicy: 'opaque', cropRule: 'none', consumer: 'acceptance preview',
  });
  const protocol = seal<StudyProtocol>({
    id: 'study-v1', version, panelMemberIds: Array.from({ length: 12 }, (_, index) => `p${index + 1}`),
    proCount: 4, golferCount: 8, exposureMs: 5000, displaySizes: [16, 32],
    comparisonMarkIds: Array.from({ length: 8 }, (_, index) => `comparison-${index + 1}`),
    promptVersion: version, responseOptionVersion: version, scoringVersion: version,
    presentationOrderSeed: 'ember-76',
  });
  const artifact = seal<EvidenceArtifact>({
    id: 'artifact-study', version, category: 'study', subjectRefs: [candidate.id],
    validatorOrProtocolVersion: version, inputChecksum: protocol.checksum,
    timestamp: '2026-07-20T12:00:00.000Z', outcome: 'fail', location: 'evidence/study.json',
  });
  const conflict = seal<ConflictRecord>({
    id: 'conflict-green', version, candidateId: candidate.id, lowerStatement: 'Use green.',
    governingAuthorityId: authority.id, resolution: 'exclude', decisionOwner: 'Brand owner',
    status: 'resolved', evidenceRefs: [artifact.id],
  });
  const validation = seal<ValidationResult>({
    id: 'validation-recognition', version, requirementRefs: ['12.3'], candidateId: candidate.id,
    compositionId: composition.id, variantId: variant.id, validatorVersion: version,
    inputChecksum: plannedExport.checksum, testDate: '2026-07-20',
    evaluatorComposition: '4 pros and 8 golfers', testMethod: 'recognition at 32 px',
    measured: { correct: 9 }, threshold: { minimum: 10 }, passRange: '10-12', failRange: '0-9',
    outcome: 'fail', evidenceRefs: [artifact.id],
  });
  const gate = seal<GateResult>({
    id: 'gate-result-recognition', version, gateId: 'recognition-32', candidateId: candidate.id,
    protocolId: protocol.id, measuredCounts: { correct: 9 }, passRange: '10-12', failRange: '0-9',
    outcome: 'fail', evidenceRefs: [artifact.id],
  });
  const exception = seal<OwnerException>({
    id: 'exception-recognition', version, failedGateId: gate.gateId, decisionOwner: 'Brand owner',
    decisionDate: '2026-07-20', rationale: 'Controlled acceptance.', scope: 'Preview only',
    requiredRemediation: 'Repeat recognition study before promotion.',
  });
  const migration = seal<MigrationEntry>({
    id: 'migration-mark', version, legacyPath: '/brand/mark.svg',
    legacyChecksum: checksumOf({ legacy: 'mark.svg' }), consumer: 'browser', treatment: 'replacement',
    replacementPath: '/staging/ember/mark.svg', replacementEvent: 'approved release',
    cacheLifetimeOrTrigger: 'service-worker version', validationMethod: 'HTTP and visual probe',
    archivePath: 'archive/legacy/mark.svg', rollbackMethod: 'restore archived path',
  });
  const evidencePackage = seal<EvidencePackage>({
    id: 'package-ember', version, packageVersion: version,
    authorityManifestChecksum: checksumOf([authority.checksum]), selectedCandidateId: candidate.id,
    matrix: [validation], gates: [gate], exceptions: [exception], migrationEntries: [migration],
    artifactRefs: [artifact.id], status: 'approved-by-exception',
  });
  return {
    authorities: [authority], conflicts: [conflict], candidates: [candidate], geometries: [geometry],
    compositions: [composition], variants: [variant], exports: [plannedExport],
    studyProtocols: [protocol], evidenceArtifacts: [artifact], evidencePackages: [evidencePackage],
  };
}
test('canonical serialization and checksums are independent of object key order', () => {
  const left = { z: [3, 2, 1], a: { heat: 'ember', active: true } };
  const right = { a: { active: true, heat: 'ember' }, z: [3, 2, 1] };
  assert.equal(canonicalSerialize(left), canonicalSerialize(right));
  assert.equal(checksumOf(left), checksumOf(right));
});

test('sealed records are deeply immutable and checksum-verifiable', () => {
  const authority = validGraph().authorities[0];
  assert.ok(authority);
  assert.equal(verifyRecordChecksum(authority), true);
  assert.equal(Object.isFrozen(authority), true);
  assert.throws(() => {
    (authority as { statement: string }).statement = 'mutated';
  }, TypeError);

  const tampered = { ...authority, statement: 'tampered' };
  assert.equal(verifyRecordChecksum(tampered), false);
  assert.throws(() => authorityStatementSchema.parse(tampered), /invalid checksum/);
});

test('immutable store rejects a different checksum for the same id and version', () => {
  const first = validGraph().authorities[0];
  assert.ok(first);
  const second = seal<AuthorityStatement>({
    id: first.id, version: first.version, rank: first.rank, sourcePath: first.sourcePath,
    sourceSection: first.sourceSection, statement: 'A different immutable statement.', status: 'active',
  });
  const store = new ImmutableRecordStore<AuthorityStatement>();
  assert.equal(store.add(first), first);
  assert.throws(() => store.add(second), /Immutable identity collision/);
});

test('parses the complete model graph and preserves immutable evidence', () => {
  const parsed = logoSystemGraphSchema.parse(validGraph());
  assert.equal(parsed.exports[0]?.colorValues.ember, '#FF5A2E');
  assert.equal(parsed.evidencePackages[0]?.matrix[0]?.testMethod, 'recognition at 32 px');
  assert.equal(Object.isFrozen(parsed.evidencePackages[0]?.matrix[0]), true);
  assert.equal(Object.isFrozen(parsed), true);
});
test('rejects unresolved and ownership-mismatched references', () => {
  const graph = validGraph();
  const original = graph.compositions[0];
  assert.ok(original);
  const invalid = seal<CompositionSpec>({
    id: original.id, version: original.version, candidateId: 'missing-candidate',
    kind: original.kind, geometryRef: original.geometryRef, clearSpaceRatio: original.clearSpaceRatio,
  });
  const malformed: LogoSystemGraph = { ...graph, compositions: [invalid] };
  assert.throws(
    () => logoSystemGraphSchema.parse(malformed),
    (error: unknown) => error instanceof SchemaError && /unresolved reference missing-candidate/.test(error.message),
  );
});

test('rejects dangling candidate feature mappings', () => {
  const graph = validGraph();
  const original = graph.candidates[0];
  assert.ok(original);
  const invalid = seal<Candidate>({
    id: original.id, version: original.version, kind: original.kind,
    territoryName: original.territoryName, motionNative: original.motionNative,
    primarySilhouetteId: original.primarySilhouetteId, requiredDetailIds: ['path-unmapped'],
    negativeSpaceSignature: original.negativeSpaceSignature,
    semanticMappings: original.semanticMappings, status: original.status,
    sourceChecksum: original.sourceChecksum,
  });
  assert.throws(
    () => logoSystemGraphSchema.parse({ ...graph, candidates: [invalid] }),
    /unresolved feature path-ember/,
  );
});

test('validates and freezes composition selection contexts', () => {
  const context = selectionContextSchema.parse({
    availableCssPx: 32, backgroundRole: 'charcoal', textSupported: false,
    requested: 'core', reducedMotion: true, process: 'screen', semanticUse: 'identity',
  });
  assert.equal(context.availableCssPx, 32);
  assert.equal(Object.isFrozen(context), true);
  assert.throws(
    () => selectionContextSchema.parse({ ...context, backgroundRole: 'green' }),
    /expected one of/,
  );
});

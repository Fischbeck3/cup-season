import { canonicalSerialize, deepFreeze, assertRecordIdentity, checksumOf } from './canonical.js';
import type {
  ApprovalStatus,
  AuthorityStatement,
  Box,
  Candidate,
  CompositionSpec,
  ConflictRecord,
  EvidenceArtifact,
  EvidencePackage,
  ExportSpec,
  GateResult,
  GeometryManifest,
  IdentityRole,
  LogoSystemGraph,
  MigrationEntry,
  OwnerException,
  Point,
  SelectionContext,
  StudyProtocol,
  ValidationResult,
  VariantSpec,
} from './domain.js';

export class SchemaError extends Error {
  constructor(readonly path: string, message: string) {
    super(`${path}: ${message}`);
    this.name = 'SchemaError';
  }
}

export interface Schema<T> {
  parse(value: unknown): Readonly<T>;
}

type Reader<T> = (value: unknown, path: string) => T;
type Shape = Readonly<Record<string, Field<unknown>>>;
interface Field<T> {
  readonly read: Reader<T>;
  readonly optional?: boolean;
}

const field = <T>(read: Reader<T>): Field<T> => ({ read });
const optional = <T>(entry: Field<T>): Field<T | undefined> => ({ ...entry, optional: true });
const stringField = field<string>((value, path) => {
  if (typeof value !== 'string' || value.trim() === '') throw new SchemaError(path, 'expected non-empty string');
  return value;
});
const booleanField = field<boolean>((value, path) => {
  if (typeof value !== 'boolean') throw new SchemaError(path, 'expected boolean');
  return value;
});
const finiteNumber = field<number>((value, path) => {
  if (typeof value !== 'number' || !Number.isFinite(value)) throw new SchemaError(path, 'expected finite number');
  return value;
});
const nonNegativeInteger = field<number>((value, path) => {
  if (!Number.isInteger(value) || (value as number) < 0) throw new SchemaError(path, 'expected non-negative integer');
  return value as number;
});
const positiveNumber = field<number>((value, path) => {
  const parsed = finiteNumber.read(value, path);
  if (parsed <= 0) throw new SchemaError(path, 'expected number greater than zero');
  return parsed;
});
const jsonField = field<unknown>((value, path) => {
  try {
    canonicalSerialize(value);
    return value;
  } catch (error) {
    throw new SchemaError(path, error instanceof Error ? error.message : 'expected JSON value');
  }
});
const enumeration = <T extends string>(...values: readonly T[]): Field<T> =>
  field((value, path) => {
    if (typeof value !== 'string' || !values.includes(value as T)) {
      throw new SchemaError(path, `expected one of ${values.join(', ')}`);
    }
    return value as T;
  });
const arrayOf = <T>(entry: Field<T>, minimum = 0): Field<readonly T[]> =>
  field((value, path) => {
    if (!Array.isArray(value) || value.length < minimum) {
      throw new SchemaError(path, `expected array with at least ${minimum} item(s)`);
    }
    return value.map((item, index) => entry.read(item, `${path}[${index}]`));
  });
const recordOf = <T>(entry: Field<T>): Field<Readonly<Record<string, T>>> =>
  field((value, path) => {
    if (!isPlainObject(value)) throw new SchemaError(path, 'expected object');
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, entry.read(item, `${path}.${key}`)]),
    );
  });

function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function readObject(value: unknown, path: string, shape: Shape): Record<string, unknown> {
  if (!isPlainObject(value)) throw new SchemaError(path, 'expected object');
  const unknownKeys = Object.keys(value).filter((key) => !(key in shape));
  if (unknownKeys.length > 0) throw new SchemaError(path, `unknown field(s): ${unknownKeys.join(', ')}`);
  const result: Record<string, unknown> = {};
  for (const [key, definition] of Object.entries(shape)) {
    if (!(key in value)) {
      if (!definition.optional) throw new SchemaError(`${path}.${key}`, 'required field is missing');
      continue;
    }
    result[key] = definition.read(value[key], `${path}.${key}`);
  }
  return result;
}

const objectField = (shape: Shape): Field<Record<string, unknown>> =>
  field((value, path) => readObject(value, path, shape));
const checksumField = field<string>((value, path) => {
  const parsed = stringField.read(value, path);
  if (!/^sha256:[a-f0-9]{64}$/.test(parsed)) throw new SchemaError(path, 'expected SHA-256 checksum');
  return parsed;
});
const versionField = field<string>((value, path) => {
  const parsed = stringField.read(value, path);
  if (!/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/.test(parsed)) {
    throw new SchemaError(path, 'expected semantic version');
  }
  return parsed;
});
const dateField = field<string>((value, path) => {
  const parsed = stringField.read(value, path);
  if (!/^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z)?$/.test(parsed)) {
    throw new SchemaError(path, 'expected ISO date or UTC timestamp');
  }
  return parsed;
});
const identityRole = enumeration<IdentityRole>(
  'charcoal', 'paper', 'slate', 'amber', 'ember', 'earned-metal',
);
const approvalStatus = enumeration<ApprovalStatus>(
  'ineligible', 'testing', 'not-approved', 'approved-by-gates', 'approved-by-exception',
);
const immutableShape = { id: stringField, version: versionField, checksum: checksumField } as const;

function recordSchema<T>(shape: Shape): Schema<T> {
  return {
    parse(value: unknown): Readonly<T> {
      const parsed = readObject(value, '$', { ...immutableShape, ...shape }) as T;
      try {
        assertRecordIdentity(parsed as never);
      } catch (error) {
        throw new SchemaError('$', error instanceof Error ? error.message : 'invalid record identity');
      }
      return deepFreeze(parsed);
    },
  };
}

const pointShape = { x: finiteNumber, y: finiteNumber } as const;
const boxField = objectField({ ...pointShape, width: positiveNumber, height: positiveNumber }) as unknown as Field<Box>;
const pointField = objectField(pointShape) as unknown as Field<Point>;
const stringArray = arrayOf(stringField);
const nonEmptyStringArray = arrayOf(stringField, 1);
const identityColorMap = field<Readonly<Partial<Record<IdentityRole, string>>>>((value, path) => {
  if (!isPlainObject(value)) throw new SchemaError(path, 'expected object');
  const roles: readonly IdentityRole[] = ['charcoal', 'paper', 'slate', 'amber', 'ember', 'earned-metal'];
  const result: Partial<Record<IdentityRole, string>> = {};
  for (const [key, color] of Object.entries(value)) {
    if (!roles.includes(key as IdentityRole)) throw new SchemaError(`${path}.${key}`, 'unknown identity role');
    const parsed = stringField.read(color, `${path}.${key}`);
    if (!/^#[A-Fa-f0-9]{6}$/.test(parsed)) throw new SchemaError(`${path}.${key}`, 'expected six-digit hex color');
    result[key as IdentityRole] = parsed.toUpperCase();
  }
  return result;
});

const semanticMappingField = objectField({
  featureId: stringField,
  visibleBehavior: stringField,
  meaning: enumeration('real-golf', 'season', 'crew-rivalry', 'momentum', 'ceremony', 'record'),
  authorityRefs: nonEmptyStringArray,
  colorRole: optional(identityRole),
});
export const authorityStatementSchema = recordSchema<AuthorityStatement>({
  rank: enumeration('vision', 'principle', 'information-architecture', 'mechanics', 'ui', 'implementation'),
  sourcePath: stringField,
  sourceSection: stringField,
  statement: stringField,
  status: enumeration('active', 'superseded'),
  supersededBy: optional(stringField),
});

export const conflictRecordSchema = recordSchema<ConflictRecord>({
  candidateId: optional(stringField),
  lowerStatement: stringField,
  governingAuthorityId: stringField,
  resolution: enumeration('exclude', 'proposed-resolution'),
  decisionOwner: stringField,
  status: enumeration('open', 'resolved'),
  evidenceRefs: stringArray,
});

export const candidateSchema = recordSchema<Candidate>({
  kind: enumeration('new-territory', 'legacy-evolution'),
  territoryName: stringField,
  motionNative: booleanField,
  primarySilhouetteId: stringField,
  requiredDetailIds: nonEmptyStringArray,
  negativeSpaceSignature: stringField,
  semanticMappings: arrayOf(semanticMappingField, 1),
  status: approvalStatus,
  sourceChecksum: checksumField,
});

export const geometryManifestSchema = recordSchema<GeometryManifest>({
  compositionId: stringField,
  candidateId: stringField,
  artboard: boxField,
  viewBox: boxField,
  geometryBounds: boxField,
  opticalCenter: pointField,
  silhouettePathIds: nonEmptyStringArray,
  requiredDetailPathIds: nonEmptyStringArray,
  closedContourPathIds: nonEmptyStringArray,
  minStroke: positiveNumber,
  minGap: positiveNumber,
  units: enumeration('svg-unit', 'mm'),
});

export const compositionSpecSchema = recordSchema<CompositionSpec>({
  candidateId: stringField,
  kind: enumeration('core', 'small-size', 'wordmark', 'horizontal', 'stacked', 'motion-settled'),
  geometryRef: stringField,
  exactText: optional(enumeration('Cup Season')),
  minCssPx: optional(positiveNumber),
  minMillimeters: optional(positiveNumber),
  clearSpaceRatio: positiveNumber,
  markGapRatio: optional(positiveNumber),
});

export const variantSpecSchema = recordSchema<VariantSpec>({
  compositionId: stringField,
  mode: enumeration('full-dark', 'full-light', 'one-dark', 'one-light', 'monochrome'),
  roleAssignments: recordOf(identityRole),
  backgroundRole: identityRole,
  alphaPolicy: enumeration('opaque', 'transparent-nonessential'),
  semanticUse: stringArray,
});
export const selectionContextSchema: Schema<SelectionContext> = {
  parse(value: unknown): Readonly<SelectionContext> {
    const parsed = readObject(value, '$', {
      availableCssPx: optional(positiveNumber),
      availableMillimeters: optional(positiveNumber),
      backgroundRole: identityRole,
      textSupported: booleanField,
      requested: enumeration('core', 'small-size', 'wordmark', 'horizontal', 'stacked', 'motion-settled'),
      reducedMotion: booleanField,
      qualifyingEntryEvent: optional(stringField),
      process: enumeration('screen', 'print', 'engrave', 'stamp', 'embroider'),
      semanticUse: enumeration('identity', 'live-momentum', 'earned-honor'),
    }) as unknown as SelectionContext;
    return deepFreeze(parsed);
  },
};

export const exportSpecSchema = recordSchema<ExportSpec>({
  filename: stringField,
  compositionId: stringField,
  variantId: stringField,
  width: positiveNumber,
  height: positiveNumber,
  unit: enumeration('px'),
  format: enumeration('svg', 'png', 'ico'),
  colorSpace: enumeration('sRGB'),
  colorValues: identityColorMap,
  alphaPolicy: stringField,
  cropRule: stringField,
  consumer: stringField,
});

export const validationResultSchema = recordSchema<ValidationResult>({
  requirementRefs: nonEmptyStringArray,
  candidateId: stringField,
  compositionId: optional(stringField),
  variantId: optional(stringField),
  validatorVersion: versionField,
  inputChecksum: checksumField,
  testDate: dateField,
  evaluatorComposition: stringField,
  testMethod: stringField,
  measured: jsonField,
  threshold: jsonField,
  passRange: stringField,
  failRange: stringField,
  outcome: enumeration('pass', 'fail', 'not-applicable', 'not-tested'),
  evidenceRefs: stringArray,
});

export const studyProtocolSchema = recordSchema<StudyProtocol>({
  panelMemberIds: nonEmptyStringArray,
  proCount: nonNegativeInteger,
  golferCount: nonNegativeInteger,
  exposureMs: positiveNumber,
  displaySizes: arrayOf(positiveNumber, 1),
  comparisonMarkIds: nonEmptyStringArray,
  promptVersion: versionField,
  responseOptionVersion: versionField,
  scoringVersion: versionField,
  presentationOrderSeed: stringField,
});

export const gateResultSchema = recordSchema<GateResult>({
  gateId: stringField,
  candidateId: stringField,
  protocolId: stringField,
  measuredCounts: recordOf(nonNegativeInteger),
  passRange: stringField,
  failRange: stringField,
  outcome: enumeration('pass', 'fail'),
  evidenceRefs: stringArray,
});

export const ownerExceptionSchema = recordSchema<OwnerException>({
  failedGateId: stringField,
  decisionOwner: stringField,
  decisionDate: dateField,
  rationale: stringField,
  scope: stringField,
  requiredRemediation: stringField,
});
export const migrationEntrySchema = recordSchema<MigrationEntry>({
  legacyPath: stringField,
  legacyChecksum: checksumField,
  consumer: stringField,
  treatment: enumeration('replacement', 'compatibility-alias', 'retirement', 'owner-exception'),
  replacementPath: optional(stringField),
  replacementEvent: stringField,
  cacheLifetimeOrTrigger: stringField,
  validationMethod: stringField,
  archivePath: stringField,
  rollbackMethod: stringField,
});

export const evidenceArtifactSchema = recordSchema<EvidenceArtifact>({
  category: enumeration(
    'authority', 'semantic', 'geometry', 'export', 'accessibility',
    'study', 'production', 'motion', 'migration',
  ),
  subjectRefs: stringArray,
  validatorOrProtocolVersion: versionField,
  inputChecksum: checksumField,
  timestamp: dateField,
  outcome: enumeration('pass', 'fail', 'not-applicable', 'not-tested'),
  location: stringField,
});

const nestedRecord = <T>(schema: Schema<T>): Field<Readonly<T>> =>
  field((value) => schema.parse(value));

export const evidencePackageSchema = recordSchema<EvidencePackage>({
  packageVersion: versionField,
  authorityManifestChecksum: checksumField,
  selectedCandidateId: optional(stringField),
  matrix: arrayOf(nestedRecord(validationResultSchema)),
  gates: arrayOf(nestedRecord(gateResultSchema)),
  exceptions: arrayOf(nestedRecord(ownerExceptionSchema)),
  migrationEntries: arrayOf(nestedRecord(migrationEntrySchema)),
  artifactRefs: stringArray,
  status: approvalStatus,
});

function parseArray<T>(value: unknown, path: string, schema: Schema<T>): readonly Readonly<T>[] {
  if (!Array.isArray(value)) throw new SchemaError(path, 'expected array');
  return value.map((item, index) => {
    try {
      return schema.parse(item);
    } catch (error) {
      if (error instanceof SchemaError) {
        throw new SchemaError(`${path}[${index}]${error.path.slice(1)}`, error.message.slice(error.path.length + 2));
      }
      throw error;
    }
  });
}

function requireReference(index: ReadonlyMap<string, unknown>, id: string, path: string): void {
  if (!index.has(id)) throw new SchemaError(path, `unresolved reference ${id}`);
}

function uniqueIndex(records: readonly { readonly id: string }[], path: string): Map<string, unknown> {
  const index = new Map<string, unknown>();
  for (const record of records) {
    if (index.has(record.id)) throw new SchemaError(path, `duplicate record id ${record.id}`);
    index.set(record.id, record);
  }
  return index;
}
function validateReferences(graph: LogoSystemGraph): void {
  const authorities = uniqueIndex(graph.authorities, '$.authorities');
  const conflicts = uniqueIndex(graph.conflicts, '$.conflicts');
  const candidates = uniqueIndex(graph.candidates, '$.candidates');
  const geometries = uniqueIndex(graph.geometries, '$.geometries');
  const compositions = uniqueIndex(graph.compositions, '$.compositions');
  const variants = uniqueIndex(graph.variants, '$.variants');
  const exports = uniqueIndex(graph.exports, '$.exports');
  const protocols = uniqueIndex(graph.studyProtocols, '$.studyProtocols');
  const artifacts = uniqueIndex(graph.evidenceArtifacts, '$.evidenceArtifacts');
  const packages = uniqueIndex(graph.evidencePackages, '$.evidencePackages');
  const nested = graph.evidencePackages.flatMap((item) => [
    ...item.matrix, ...item.gates, ...item.exceptions, ...item.migrationEntries,
  ]);
  const nestedRecords = uniqueIndex(nested, '$.evidencePackages records');
  const everyRecord = new Map<string, unknown>();
  for (const index of [authorities, conflicts, candidates, geometries, compositions, variants, exports, protocols, artifacts, packages, nestedRecords]) {
    for (const [id, record] of index) {
      if (everyRecord.has(id)) throw new SchemaError('$', `duplicate record id ${id}`);
      everyRecord.set(id, record);
    }
  }

  for (const authority of graph.authorities) {
    if (authority.status === 'superseded' && !authority.supersededBy) {
      throw new SchemaError(`$.authorities.${authority.id}.supersededBy`, 'superseded authority requires a reference');
    }
    if (authority.supersededBy) requireReference(authorities, authority.supersededBy, `$.authorities.${authority.id}.supersededBy`);
  }
  for (const conflict of graph.conflicts) {
    requireReference(authorities, conflict.governingAuthorityId, `$.conflicts.${conflict.id}.governingAuthorityId`);
    if (conflict.candidateId) requireReference(candidates, conflict.candidateId, `$.conflicts.${conflict.id}.candidateId`);
    for (const ref of conflict.evidenceRefs) requireReference(artifacts, ref, `$.conflicts.${conflict.id}.evidenceRefs`);
  }
  for (const candidate of graph.candidates) {
    const features = new Set([candidate.primarySilhouetteId, ...candidate.requiredDetailIds]);
    const mapped = new Set<string>();
    for (const mapping of candidate.semanticMappings) {
      if (!features.has(mapping.featureId)) throw new SchemaError(`$.candidates.${candidate.id}.semanticMappings`, `unresolved feature ${mapping.featureId}`);
      mapped.add(mapping.featureId);
      for (const ref of mapping.authorityRefs) requireReference(authorities, ref, `$.candidates.${candidate.id}.semanticMappings.authorityRefs`);
    }
    for (const feature of features) {
      if (!mapped.has(feature)) throw new SchemaError(`$.candidates.${candidate.id}.semanticMappings`, `feature ${feature} has no semantic mapping`);
    }
  }
  for (const geometry of graph.geometries) {
    const candidate = candidates.get(geometry.candidateId) as Candidate | undefined;
    requireReference(candidates, geometry.candidateId, `$.geometries.${geometry.id}.candidateId`);
    requireReference(compositions, geometry.compositionId, `$.geometries.${geometry.id}.compositionId`);
    if (candidate && !geometry.silhouettePathIds.includes(candidate.primarySilhouetteId)) {
      throw new SchemaError(`$.geometries.${geometry.id}.silhouettePathIds`, 'candidate primary silhouette is not present');
    }
    for (const detail of candidate?.requiredDetailIds ?? []) {
      if (!geometry.requiredDetailPathIds.includes(detail)) {
        throw new SchemaError(`$.geometries.${geometry.id}.requiredDetailPathIds`, `required candidate detail ${detail} is not present`);
      }
    }
  }
  for (const composition of graph.compositions) {
    requireReference(candidates, composition.candidateId, `$.compositions.${composition.id}.candidateId`);
    requireReference(geometries, composition.geometryRef, `$.compositions.${composition.id}.geometryRef`);
    const geometry = geometries.get(composition.geometryRef) as GeometryManifest;
    if (geometry.candidateId !== composition.candidateId || geometry.compositionId !== composition.id) {
      throw new SchemaError(`$.compositions.${composition.id}.geometryRef`, 'geometry ownership does not match composition');
    }
  }
  for (const variant of graph.variants) {
    requireReference(compositions, variant.compositionId, `$.variants.${variant.id}.compositionId`);
  }
  for (const plannedExport of graph.exports) {
    requireReference(compositions, plannedExport.compositionId, `$.exports.${plannedExport.id}.compositionId`);
    requireReference(variants, plannedExport.variantId, `$.exports.${plannedExport.id}.variantId`);
    const variant = variants.get(plannedExport.variantId) as VariantSpec;
    if (variant.compositionId !== plannedExport.compositionId) {
      throw new SchemaError(`$.exports.${plannedExport.id}.variantId`, 'variant belongs to another composition');
    }
  }

  const authorityChecksum = checksumOf(graph.authorities.map((item) => item.checksum));
  for (const evidencePackage of graph.evidencePackages) {
    if (evidencePackage.packageVersion !== evidencePackage.version) {
      throw new SchemaError(`$.evidencePackages.${evidencePackage.id}.packageVersion`, 'must equal record version');
    }
    if (evidencePackage.authorityManifestChecksum !== authorityChecksum) {
      throw new SchemaError(`$.evidencePackages.${evidencePackage.id}.authorityManifestChecksum`, 'does not match authority manifest');
    }
    if (evidencePackage.selectedCandidateId) {
      requireReference(candidates, evidencePackage.selectedCandidateId, `$.evidencePackages.${evidencePackage.id}.selectedCandidateId`);
    }
    for (const ref of evidencePackage.artifactRefs) requireReference(artifacts, ref, `$.evidencePackages.${evidencePackage.id}.artifactRefs`);
    const gateIds = new Set<string>();
    for (const gate of evidencePackage.gates) {
      if (gateIds.has(gate.gateId)) throw new SchemaError(`$.evidencePackages.${evidencePackage.id}.gates`, `duplicate gate id ${gate.gateId}`);
      gateIds.add(gate.gateId);
      requireReference(candidates, gate.candidateId, `$.gates.${gate.id}.candidateId`);
      requireReference(protocols, gate.protocolId, `$.gates.${gate.id}.protocolId`);
      for (const ref of gate.evidenceRefs) requireReference(artifacts, ref, `$.gates.${gate.id}.evidenceRefs`);
    }
    for (const exception of evidencePackage.exceptions) {
      if (!gateIds.has(exception.failedGateId)) {
        throw new SchemaError(`$.exceptions.${exception.id}.failedGateId`, `unresolved gate ${exception.failedGateId}`);
      }
    }
    for (const result of evidencePackage.matrix) {
      requireReference(candidates, result.candidateId, `$.matrix.${result.id}.candidateId`);
      if (result.compositionId) requireReference(compositions, result.compositionId, `$.matrix.${result.id}.compositionId`);
      if (result.variantId) requireReference(variants, result.variantId, `$.matrix.${result.id}.variantId`);
      for (const ref of result.evidenceRefs) requireReference(artifacts, ref, `$.matrix.${result.id}.evidenceRefs`);
    }
    for (const migration of evidencePackage.migrationEntries) {
      if ((migration.treatment === 'replacement' || migration.treatment === 'compatibility-alias') && !migration.replacementPath) {
        throw new SchemaError(`$.migrationEntries.${migration.id}.replacementPath`, `${migration.treatment} requires a replacement path`);
      }
    }
  }
  for (const artifact of graph.evidenceArtifacts) {
    for (const ref of artifact.subjectRefs) requireReference(everyRecord, ref, `$.evidenceArtifacts.${artifact.id}.subjectRefs`);
  }
}

const graphKeys = [
  'authorities', 'conflicts', 'candidates', 'geometries', 'compositions', 'variants',
  'exports', 'studyProtocols', 'evidenceArtifacts', 'evidencePackages',
] as const;

export const logoSystemGraphSchema: Schema<LogoSystemGraph> = {
  parse(value: unknown): Readonly<LogoSystemGraph> {
    if (!isPlainObject(value)) throw new SchemaError('$', 'expected object');
    const unknown = Object.keys(value).filter((key) => !graphKeys.includes(key as never));
    if (unknown.length > 0) throw new SchemaError('$', `unknown field(s): ${unknown.join(', ')}`);
    for (const key of graphKeys) if (!(key in value)) throw new SchemaError(`$.${key}`, 'required field is missing');
    const graph: LogoSystemGraph = {
      authorities: parseArray(value.authorities, '$.authorities', authorityStatementSchema),
      conflicts: parseArray(value.conflicts, '$.conflicts', conflictRecordSchema),
      candidates: parseArray(value.candidates, '$.candidates', candidateSchema),
      geometries: parseArray(value.geometries, '$.geometries', geometryManifestSchema),
      compositions: parseArray(value.compositions, '$.compositions', compositionSpecSchema),
      variants: parseArray(value.variants, '$.variants', variantSpecSchema),
      exports: parseArray(value.exports, '$.exports', exportSpecSchema),
      studyProtocols: parseArray(value.studyProtocols, '$.studyProtocols', studyProtocolSchema),
      evidenceArtifacts: parseArray(value.evidenceArtifacts, '$.evidenceArtifacts', evidenceArtifactSchema),
      evidencePackages: parseArray(value.evidencePackages, '$.evidencePackages', evidencePackageSchema),
    };
    validateReferences(graph);
    return deepFreeze(graph);
  },
};

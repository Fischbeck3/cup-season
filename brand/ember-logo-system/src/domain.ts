export type AuthorityRank =
  | 'vision'
  | 'principle'
  | 'information-architecture'
  | 'mechanics'
  | 'ui'
  | 'implementation';
export type CandidateKind = 'new-territory' | 'legacy-evolution';
export type Outcome = 'pass' | 'fail' | 'not-applicable' | 'not-tested';
export type ApprovalStatus =
  | 'ineligible'
  | 'testing'
  | 'not-approved'
  | 'approved-by-gates'
  | 'approved-by-exception';
export type IdentityRole =
  | 'charcoal'
  | 'paper'
  | 'slate'
  | 'amber'
  | 'ember'
  | 'earned-metal';
export type CompositionKind =
  | 'core'
  | 'small-size'
  | 'wordmark'
  | 'horizontal'
  | 'stacked'
  | 'motion-settled';

export interface ImmutableRecord {
  readonly id: string;
  readonly version: string;
  readonly checksum: string;
}

export interface Point {
  readonly x: number;
  readonly y: number;
}

export interface Box extends Point {
  readonly width: number;
  readonly height: number;
}
export interface AuthorityStatement extends ImmutableRecord {
  readonly rank: AuthorityRank;
  readonly sourcePath: string;
  readonly sourceSection: string;
  readonly statement: string;
  readonly status: 'active' | 'superseded';
  readonly supersededBy?: string;
}

export interface ConflictRecord extends ImmutableRecord {
  readonly candidateId?: string;
  readonly lowerStatement: string;
  readonly governingAuthorityId: string;
  readonly resolution: 'exclude' | 'proposed-resolution';
  readonly decisionOwner: string;
  readonly status: 'open' | 'resolved';
  readonly evidenceRefs: readonly string[];
}

export interface SemanticMapping {
  readonly featureId: string;
  readonly visibleBehavior: string;
  readonly meaning:
    | 'real-golf'
    | 'season'
    | 'crew-rivalry'
    | 'momentum'
    | 'ceremony'
    | 'record';
  readonly authorityRefs: readonly string[];
  readonly colorRole?: IdentityRole;
}

export interface Candidate extends ImmutableRecord {
  readonly kind: CandidateKind;
  readonly territoryName: string;
  readonly motionNative: boolean;
  readonly primarySilhouetteId: string;
  readonly requiredDetailIds: readonly string[];
  readonly negativeSpaceSignature: string;
  readonly semanticMappings: readonly SemanticMapping[];
  readonly status: ApprovalStatus;
  readonly sourceChecksum: string;
}

export interface GeometryManifest extends ImmutableRecord {
  readonly compositionId: string;
  readonly candidateId: string;
  readonly artboard: Box;
  readonly viewBox: Box;
  readonly geometryBounds: Box;
  readonly opticalCenter: Point;
  readonly silhouettePathIds: readonly string[];
  readonly requiredDetailPathIds: readonly string[];
  readonly closedContourPathIds: readonly string[];
  readonly minStroke: number;
  readonly minGap: number;
  readonly units: 'svg-unit' | 'mm';
}

export interface CompositionSpec extends ImmutableRecord {
  readonly candidateId: string;
  readonly kind: CompositionKind;
  readonly geometryRef: string;
  readonly exactText?: 'Cup Season';
  readonly minCssPx?: number;
  readonly minMillimeters?: number;
  readonly clearSpaceRatio: number;
  readonly markGapRatio?: number;
}
export interface VariantSpec extends ImmutableRecord {
  readonly compositionId: string;
  readonly mode:
    | 'full-dark'
    | 'full-light'
    | 'one-dark'
    | 'one-light'
    | 'monochrome';
  readonly roleAssignments: Readonly<Record<string, IdentityRole>>;
  readonly backgroundRole: IdentityRole;
  readonly alphaPolicy: 'opaque' | 'transparent-nonessential';
  readonly semanticUse: readonly string[];
}

export interface SelectionContext {
  readonly availableCssPx?: number;
  readonly availableMillimeters?: number;
  readonly backgroundRole: IdentityRole;
  readonly textSupported: boolean;
  readonly requested: CompositionKind;
  readonly reducedMotion: boolean;
  readonly qualifyingEntryEvent?: string;
  readonly process: 'screen' | 'print' | 'engrave' | 'stamp' | 'embroider';
  readonly semanticUse: 'identity' | 'live-momentum' | 'earned-honor';
}

export interface ExportSpec extends ImmutableRecord {
  readonly filename: string;
  readonly compositionId: string;
  readonly variantId: string;
  readonly width: number;
  readonly height: number;
  readonly unit: 'px';
  readonly format: 'svg' | 'png' | 'ico';
  readonly colorSpace: 'sRGB';
  readonly colorValues: Readonly<Partial<Record<IdentityRole, string>>>;
  readonly alphaPolicy: string;
  readonly cropRule: string;
  readonly consumer: string;
}

export interface ValidationResult extends ImmutableRecord {
  readonly requirementRefs: readonly string[];
  readonly candidateId: string;
  readonly compositionId?: string;
  readonly variantId?: string;
  readonly validatorVersion: string;
  readonly inputChecksum: string;
  readonly testDate: string;
  readonly evaluatorComposition: string;
  readonly testMethod: string;
  readonly measured: unknown;
  readonly threshold: unknown;
  readonly passRange: string;
  readonly failRange: string;
  readonly outcome: Outcome;
  readonly evidenceRefs: readonly string[];
}

export interface StudyProtocol extends ImmutableRecord {
  readonly panelMemberIds: readonly string[];
  readonly proCount: number;
  readonly golferCount: number;
  readonly exposureMs: number;
  readonly displaySizes: readonly number[];
  readonly comparisonMarkIds: readonly string[];
  readonly promptVersion: string;
  readonly responseOptionVersion: string;
  readonly scoringVersion: string;
  readonly presentationOrderSeed: string;
}
export interface GateResult extends ImmutableRecord {
  readonly gateId: string;
  readonly candidateId: string;
  readonly protocolId: string;
  readonly measuredCounts: Readonly<Record<string, number>>;
  readonly passRange: string;
  readonly failRange: string;
  readonly outcome: 'pass' | 'fail';
  readonly evidenceRefs: readonly string[];
}

export interface OwnerException extends ImmutableRecord {
  readonly failedGateId: string;
  readonly decisionOwner: string;
  readonly decisionDate: string;
  readonly rationale: string;
  readonly scope: string;
  readonly requiredRemediation: string;
}

export interface MigrationEntry extends ImmutableRecord {
  readonly legacyPath: string;
  readonly legacyChecksum: string;
  readonly consumer: string;
  readonly treatment:
    | 'replacement'
    | 'compatibility-alias'
    | 'retirement'
    | 'owner-exception';
  readonly replacementPath?: string;
  readonly replacementEvent: string;
  readonly cacheLifetimeOrTrigger: string;
  readonly validationMethod: string;
  readonly archivePath: string;
  readonly rollbackMethod: string;
}

export type EvidenceCategory =
  | 'authority'
  | 'semantic'
  | 'geometry'
  | 'export'
  | 'accessibility'
  | 'study'
  | 'production'
  | 'motion'
  | 'migration';

export interface EvidenceArtifact extends ImmutableRecord {
  readonly category: EvidenceCategory;
  readonly subjectRefs: readonly string[];
  readonly validatorOrProtocolVersion: string;
  readonly inputChecksum: string;
  readonly timestamp: string;
  readonly outcome: Outcome;
  readonly location: string;
}

export interface EvidencePackage extends ImmutableRecord {
  readonly packageVersion: string;
  readonly authorityManifestChecksum: string;
  readonly selectedCandidateId?: string;
  readonly matrix: readonly ValidationResult[];
  readonly gates: readonly GateResult[];
  readonly exceptions: readonly OwnerException[];
  readonly migrationEntries: readonly MigrationEntry[];
  readonly artifactRefs: readonly string[];
  readonly status: ApprovalStatus;
}

export interface LogoSystemGraph {
  readonly authorities: readonly AuthorityStatement[];
  readonly conflicts: readonly ConflictRecord[];
  readonly candidates: readonly Candidate[];
  readonly geometries: readonly GeometryManifest[];
  readonly compositions: readonly CompositionSpec[];
  readonly variants: readonly VariantSpec[];
  readonly exports: readonly ExportSpec[];
  readonly studyProtocols: readonly StudyProtocol[];
  readonly evidenceArtifacts: readonly EvidenceArtifact[];
  readonly evidencePackages: readonly EvidencePackage[];
}

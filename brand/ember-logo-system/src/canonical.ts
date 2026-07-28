import { createHash } from 'node:crypto';
import type { ImmutableRecord } from './domain.js';

export const CHECKSUM_PATTERN = /^sha256:[a-f0-9]{64}$/;
export const VERSION_PATTERN = /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/;

type JsonPrimitive = string | number | boolean | null;
export type JsonValue =
  | JsonPrimitive
  | readonly JsonValue[]
  | { readonly [key: string]: JsonValue };

function canonicalize(value: unknown, ancestors: Set<object>): string {
  if (value === null || typeof value === 'string' || typeof value === 'boolean') {
    return JSON.stringify(value);
  }
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) throw new TypeError('Canonical JSON requires finite numbers');
    return Object.is(value, -0) ? '0' : JSON.stringify(value);
  }
  if (typeof value !== 'object') {
    throw new TypeError(`Canonical JSON does not support ${typeof value}`);
  }
  if (ancestors.has(value)) throw new TypeError('Canonical JSON does not support cycles');
  ancestors.add(value);
  try {
    if (Array.isArray(value)) {
      return `[${value.map((entry) => canonicalize(entry, ancestors)).join(',')}]`;
    }
    const prototype = Object.getPrototypeOf(value);
    if (prototype !== Object.prototype && prototype !== null) {
      throw new TypeError('Canonical JSON requires plain objects');
    }
    const object = value as Record<string, unknown>;
    const entries = Object.keys(object)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${canonicalize(object[key], ancestors)}`);
    return `{${entries.join(',')}}`;
  } finally {
    ancestors.delete(value);
  }
}

export function canonicalSerialize(value: unknown): string {
  return canonicalize(value, new Set<object>());
}

export function checksumOf(value: unknown): string {
  const digest = createHash('sha256').update(canonicalSerialize(value), 'utf8').digest('hex');
  return `sha256:${digest}`;
}
function payloadOf(record: ImmutableRecord): Record<string, unknown> {
  const { checksum: _checksum, ...payload } = record;
  return payload;
}

export function checksumRecord(record: Omit<ImmutableRecord, 'checksum'> & object): string {
  return checksumOf(record);
}

export function verifyRecordChecksum(record: ImmutableRecord): boolean {
  return CHECKSUM_PATTERN.test(record.checksum) && checksumOf(payloadOf(record)) === record.checksum;
}

export function assertRecordIdentity(record: ImmutableRecord): void {
  if (record.id.trim().length === 0) throw new TypeError('Record id must not be empty');
  if (!VERSION_PATTERN.test(record.version)) {
    throw new TypeError(`Record ${record.id} has invalid semantic version ${record.version}`);
  }
  if (!verifyRecordChecksum(record)) {
    throw new TypeError(`Record ${record.id}@${record.version} has an invalid checksum`);
  }
}

export function deepFreeze<T>(value: T, seen = new Set<object>()): Readonly<T> {
  if (value === null || typeof value !== 'object' || seen.has(value)) return value;
  seen.add(value);
  for (const child of Object.values(value as Record<string, unknown>)) deepFreeze(child, seen);
  return Object.freeze(value);
}

export function sealRecord<T extends ImmutableRecord>(input: Omit<T, 'checksum'>): Readonly<T> {
  const checksum = checksumOf(input);
  const record = { ...input, checksum } as T;
  assertRecordIdentity(record);
  return deepFreeze(record);
}

export class ImmutableRecordStore<T extends ImmutableRecord> {
  readonly #records = new Map<string, Readonly<T>>();

  add(record: T): Readonly<T> {
    assertRecordIdentity(record);
    const identity = `${record.id}@${record.version}`;
    const existing = this.#records.get(identity);
    if (existing && existing.checksum !== record.checksum) {
      throw new Error(
        `Immutable identity collision for ${identity}: ${existing.checksum} != ${record.checksum}`,
      );
    }
    if (existing) return existing;
    const frozen = deepFreeze(record);
    this.#records.set(identity, frozen);
    return frozen;
  }

  get(id: string, version: string): Readonly<T> | undefined {
    return this.#records.get(`${id}@${version}`);
  }

  values(): readonly Readonly<T>[] {
    return [...this.#records.values()];
  }
}

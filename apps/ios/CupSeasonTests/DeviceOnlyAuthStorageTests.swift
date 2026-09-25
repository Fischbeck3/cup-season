import Foundation
import Testing
import Security
import Supabase
@testable import CupSeasonKit

@Suite struct DeviceOnlyAuthStorageTests {
  @Test func existingSDKSessionMigratesWithoutLosingItsBytes() throws {
    let service = "security-test-\(UUID())", key = "fixture-session"
    let old = KeychainLocalStorage(service: service)
    let storage = DeviceOnlyAuthStorage(service: service)
    defer { try? storage.remove(key: key) }
    let bytes = Data("synthetic-session".utf8)
    try old.store(key: key, value: bytes)
    #expect(try storage.retrieve(key: key) == bytes)
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                               kSecAttrService as String: service, kSecAttrAccount as String: key,
                               kSecReturnAttributes as String: true]
    var result: CFTypeRef?
    #expect(SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess)
    let attributes = try #require(result as? [String: Any])
    #expect(attributes[kSecAttrAccessible as String] as? String == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    try storage.store(key: key, value: Data("new-synthetic-session".utf8))
    #expect(try storage.retrieve(key: key) == Data("new-synthetic-session".utf8))
    try storage.remove(key: key)
    #expect(try storage.retrieve(key: key) == nil)
  }
}

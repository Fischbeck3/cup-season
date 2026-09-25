import Foundation
import Security
import Supabase

/// Keep the SDK's namespace, so an installed session migrates in place.
/// Credentials remain usable for background actions after the first unlock,
/// but do not travel to a different device through a backup restore.
public struct DeviceOnlyAuthStorage: AuthLocalStorage {
  let service: String
  public init(service: String = "supabase.gotrue.swift") { self.service = service }
  private func query(_ key: String) -> [String: Any] {
    [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: key]
  }
  private func check(_ status: OSStatus) throws {
    guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
  }
  public func store(key: String, value: Data) throws {
    let attributes: [String: Any] = [kSecValueData as String: value, kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
    let status = SecItemUpdate(query(key) as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      try check(SecItemAdd(query(key).merging(attributes) { _, new in new } as CFDictionary, nil))
    } else { try check(status) }
  }
  public func retrieve(key: String) throws -> Data? {
    var lookup = query(key)
    lookup[kSecReturnData as String] = true
    lookup[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(lookup as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    try check(status)
    // Upgrade an existing SDK session without deleting or re-creating it.
    try check(SecItemUpdate(query(key) as CFDictionary,
                           [kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as CFDictionary))
    return result as? Data
  }
  public func remove(key: String) throws {
    let status = SecItemDelete(query(key) as CFDictionary)
    if status != errSecItemNotFound { try check(status) }
  }
}

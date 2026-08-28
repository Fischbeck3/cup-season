// Cup Season — the Apple sign-in nonce (IOS-023).
//
// Apple signs the SHA-256 of a nonce into the identity token; Supabase checks
// that hash against the RAW nonce we hand it. The raw one never leaves the
// device except inside `signInWithApple(idToken:nonce:)`.

import Foundation
import CryptoKit
import Security

enum DoorNonce {
  /// `bytes` random bytes from the system CSPRNG, hex-encoded (2 chars each).
  static func make(bytes: Int = 32) -> String {
    var buf = [UInt8](repeating: 0, count: bytes)
    let status = SecRandomCopyBytes(kSecRandomDefault, buf.count, &buf)
    if status != errSecSuccess {
      // SecRandomCopyBytes has never failed on a shipping iPhone; if it does,
      // the system generator is the only other honest source.
      var g = SystemRandomNumberGenerator()
      buf = (0..<bytes).map { _ in UInt8.random(in: .min ... .max, using: &g) }
    }
    return buf.map { String(format: "%02x", $0) }.joined()
  }

  /// Lowercase hex SHA-256 of the UTF-8 bytes — what goes on the request.
  static func sha256(_ raw: String) -> String {
    SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
  }
}

// Cup Season — the sign-in rules, as shapes (mirror of packages/db/auth.ts).
//
// These lived as prose in index.html and cost real debugging sessions:
//   - Codes are EIGHT digits. Supabase issues 8, not 6. `otpLength` is the
//     only number a UI may read.
//   - No magic links, no redirect URL, ever: Gmail's link scanner consumes
//     single-use tokens before the person clicks. `SupabaseService.requestEmailCode`
//     takes an email and nothing else, so there is no parameter to pass one through.
//   - A resend retires the older code — the #1 cause of "invalid code".

import Foundation

public enum AuthRules {
  public static let otpLength = 8

  /// Strip everything that is not a digit and keep at most `otpLength`. Safe
  /// on every keystroke — pasted codes arrive with spaces and non-breaking
  /// hyphens from mail clients.
  public static func normalizeCode(_ raw: String) -> String {
    String(raw.filter(\.isNumber).prefix(otpLength))
  }

  public static func isCompleteCode(_ raw: String) -> Bool {
    normalizeCode(raw).count == otpLength
  }

  public static func normalizeEmail(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  public static func looksLikeEmail(_ raw: String) -> Bool {
    let e = normalizeEmail(raw)
    return e.count > 3 && e.contains("@") && !e.contains(" ") && !e.hasPrefix("@") && !e.hasSuffix("@")
  }

  /// The reviewer door (App Review cannot receive Brevo mail): exactly one
  /// address takes a password instead of a code. Invisible otherwise. Survives
  /// D98 and D99.
  public static let reviewerEmail = "reviewer@cupseason.app"
  public static func isReviewer(_ email: String) -> Bool { normalizeEmail(email) == reviewerEmail }

  /// Supabase's auth messages are written for developers. Map the ones a
  /// person meets at the door; fall through to the server's text otherwise
  /// (RPC business errors are already written for humans).
  public static func human(_ error: Error, fallback: String = "That did not take.") -> String {
    let m = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
    let s = m.lowercased()
    if s.contains("banned") || s.contains("deleted") || s.contains("403") {
      return "This account was closed and can't sign in again. Start fresh with a different email."
    }
    if s.contains("expired") || (s.contains("invalid") && s.contains("token")) || s.contains("otp") {
      return "That code has expired. Codes expire when a new one is sent — use the newest email."
    }
    if s.contains("rate limit") || s.contains("too many") || s.contains("429") {
      return "Too many sign-in emails for now — the mailer limits sends per hour."
    }
    if s.contains("network") || s.contains("offline") || s.contains("timed out") || s.contains("could not connect") {
      return "Connection hiccup — check your signal and try again."
    }
    return m.isEmpty ? fallback : m
  }
}

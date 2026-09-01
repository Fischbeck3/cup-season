// Cup Season — Sign in with Apple, the button (IOS-023).
//
// Apple's own control (the review guideline wants Apple's, not a lookalike):
// white on charcoal, black on paper, 50pt, the controls' radius. The nonce
// is minted per request; the RAW nonce and the identity token go to the
// model as strings — nothing else from the authorization crosses over.

import SwiftUI
import AuthenticationServices
import CSDesign

struct DoorAppleButton: View {
  @Environment(\.colorScheme) private var scheme
  /// (identity token, raw nonce, the name Apple gave — see `AppleName`)
  let onToken: (String, String, String?) -> Void
  let onFailure: (any Error) -> Void
  @State private var nonce = ""

  var body: some View {
    SignInWithAppleButton(.signIn) { request in
      let raw = DoorNonce.make()
      nonce = raw
      request.requestedScopes = [.fullName, .email]
      request.nonce = DoorNonce.sha256(raw)
    } onCompletion: { result in
      switch result {
      case .success(let auth):
        guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
              let data = cred.identityToken, let token = String(data: data, encoding: .utf8), !token.isEmpty
        else { onFailure(DoorAppleError.noToken); return }
        // D186 · Apple hands back `fullName` on the FIRST authorization ONLY —
        // never again, on any later sign-in, unless the person removes the app
        // from their Apple ID settings. This button requested the scope and
        // then dropped the result on the floor, so every Apple signup would
        // have reached the golfer card with an empty name and a relay address
        // (`…@privaterelay.appleid.com`) as the only thing we knew about them.
        // Capture it here or it is gone for good.
        onToken(token, nonce, AppleName.from(cred.fullName))
      case .failure(let error):
        onFailure(error)
      }
    }
    .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
    .id(scheme)   // the UIKit button fixes its style at creation; a theme change remakes it
    .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
    .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .accessibilityLabel("Sign in with Apple")
  }
}

/// D186 · the one-shot name from Apple, carried from the door to the golfer card.
///
/// It is written at the door and read once by `CardGateView`, because sign-in
/// reloads the app between them — a value held in memory would not survive the
/// trip. Stored under the same `cs_` convention as the rest of our defaults,
/// and cleared the moment it is consumed so a second golfer on a shared phone
/// never inherits the first one's name.
enum AppleName {
  static let key = "cs_apple_name"

  /// Apple gives `PersonNameComponents`; we want "First Last" the way the card
  /// asks for it ("First and last"). Returns nil rather than an empty string
  /// when Apple withholds it — which it does on every sign-in after the first.
  static func from(_ components: PersonNameComponents?) -> String? {
    guard let components else { return nil }
    let joined = PersonNameComponentsFormatter.localizedString(from: components, style: .default)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return joined.isEmpty ? nil : joined
  }

  static func stash(_ name: String?) {
    guard let name, !name.isEmpty else { return }
    UserDefaults.standard.set(name, forKey: key)
  }

  /// Read-and-clear: one card gets it, and only one.
  static func take() -> String? {
    let name = UserDefaults.standard.string(forKey: key)
    if name != nil { UserDefaults.standard.removeObject(forKey: key) }
    return (name?.isEmpty ?? true) ? nil : name
  }
}

enum DoorAppleError: LocalizedError {
  case noToken
  var errorDescription: String? { "Apple did not hand back a token." }

  /// The person closed Apple's sheet — not an error to show.
  static func isCancel(_ error: any Error) -> Bool {
    (error as? ASAuthorizationError)?.code == .canceled
  }
}

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
  /// (identity token, raw nonce)
  let onToken: (String, String) -> Void
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
        onToken(token, nonce)
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

enum DoorAppleError: LocalizedError {
  case noToken
  var errorDescription: String? { "Apple did not hand back a token." }

  /// The person closed Apple's sheet — not an error to show.
  static func isCancel(_ error: any Error) -> Bool {
    (error as? ASAuthorizationError)?.code == .canceled
  }
}

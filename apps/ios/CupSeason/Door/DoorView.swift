// Cup Season — the door (IOS-004 #8; audit 01 §1.1).
//
// Email in, eight digits back, signed in. Code-only, structurally: the service
// takes an email and nothing else. The reviewer address takes a password.
// The crest is the Forge's rest frame (ForgeView) — first run plays the show
// and hands off to the email stage; every run after rests on the mark.
// Sign in with Apple (IOS-023) is a second door behind `app_flags.ios.apple_sign_in`.

import SwiftUI
import CSDesign
import CupSeasonKit

struct DoorView: View {
  @Environment(\.cs) private var cs
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var vm = DoorModel()
  @State private var playForge: Bool? = nil
  @State private var risen = false
  @State private var flags = DoorFlags.closed
  @State private var toasts = CSToastCenter()   // the door sits above the tab host, so it carries its own
  @FocusState private var focus: Field?
  enum Field { case email, code, password }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        crest
          .padding(.top, 48)
          .padding(.bottom, 36)

        if risen {
          Group {
            switch vm.stage {
            case .email: emailStage
            case .code: codeStage
            case .password: passwordStage
            }

            if let note = vm.note {
              CSNote(note.text, tone: note.tone).padding(.top, 18)
            }

            legal.padding(.top, 36)
          }
          .transition(.opacity.combined(with: .offset(y: 10)))
        }
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 40)
    }
    .scrollDismissesKeyboard(.interactively)
    .csToasts(toasts)
    .onAppear {
      if playForge == nil {
        let play = ForgeState.shouldPlay(reduceMotion: reduceMotion)
        if play { ForgeState.markPlayed() }
        playForge = play
      }
    }
    // the flag never blocks the email field: it lands whenever it lands
    .task {
      #if DEBUG
      if DoorDev.forceApple { flags = DoorFlags(appleSignIn: true); return }
      #endif
      flags = await DoorFlags.load()
    }
    #if DEBUG
    // The developer hatch (the web's `/?exit` family): a simulator cannot type.
    // `-cs_dev_email a@b` requests the code; add `-cs_dev_code 12345678` on the
    // next launch to verify it. Code-only, DEBUG-only, never in a shipped build.
    .task { await vm.devHatch(ProcessInfo.processInfo.arguments) }
    #endif
  }

  // MARK: crest — the Forge, or its rest frame

  @ViewBuilder private var crest: some View {
    if let playForge {
      ForgeView(play: playForge) {
        withAnimation(playForge ? CSMotion.roll : nil) { risen = true }
        if focus == nil { focus = .email }
      }
    } else {
      // one frame before appearance decides; the rest frame keeps the layout
      ForgeFrame(t: ForgeTimeline.rest)
    }
  }

  // MARK: stages

  private var emailStage: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Email").csEyebrow()
      CSField("you@example.com", text: $vm.email)
        .keyboardType(.emailAddress)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(.go)
        .focused($focus, equals: .email)
        .onSubmit { send() }
      CSButton("Continue with email", busy: vm.busy) { send() }
        .padding(.top, 6)
      if flags.appleSignIn {
        DoorAppleButton(
          onToken: { token, nonce in Task { await vm.apple(idToken: token, nonce: nonce) } },
          onFailure: { error in vm.appleFailed(error) })
          .padding(.top, 4)
          .disabled(vm.busy)
      }
      Text("One code, no password. Codes come from the newest email.")
        .font(CSFont.footnote).foregroundStyle(cs.dimText).padding(.top, 4)
    }
  }

  private var codeStage: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("The \(AuthRules.otpLength) digits").csEyebrow()
      TextField("", text: $vm.code)
        .font(CSFont.code)
        .foregroundStyle(cs.ink)
        .kerning(6)
        .multilineTextAlignment(.center)
        .keyboardType(.numberPad)
        .textContentType(.oneTimeCode)   // iOS lifts the code out of the Mail notification
        .accessibilityLabel("The \(AuthRules.otpLength) digits")
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
          .stroke(focus == .code ? cs.focus : cs.line, lineWidth: focus == .code ? 2 : 1))
        .focused($focus, equals: .code)
        .onChange(of: vm.code) { _, new in
          let clean = AuthRules.normalizeCode(new)
          if clean != new { vm.code = clean }
          if AuthRules.isCompleteCode(clean) { verify() }
        }
      CSButton("Verify", busy: vm.busy) { verify() }
        .padding(.top, 6)
      HStack {
        Button(vm.resendIn > 0 ? "Resend in \(vm.resendIn)s" : "Resend the code") { resend() }
          .disabled(vm.resendIn > 0 || vm.busy)
        Spacer()
        Button("Change email") { vm.backToEmail(); focus = .email }
      }
      .font(CSFont.subhead).foregroundStyle(cs.mut)
      .padding(.top, 8)
    }
    .onAppear { focus = .code }
  }

  private var passwordStage: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Password").csEyebrow()
      SecureField("REVIEW PASSWORD", text: $vm.password)
        .font(CSFont.mono)
        .textContentType(.password)
        .accessibilityLabel("Review password")
        .padding(.horizontal, 14).frame(minHeight: 48)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .focused($focus, equals: .password)
        .onSubmit { reviewer() }
      CSButton("Sign in", busy: vm.busy) { reviewer() }
      Button("Change email") { vm.backToEmail(); focus = .email }
        .font(CSFont.subhead).foregroundStyle(cs.mut).padding(.top, 8)
    }
    .onAppear { focus = .password }
  }

  private var legal: some View {
    VStack(alignment: .leading, spacing: 6) {
      // the web's door line, verbatim: the two words are the links
      HStack(spacing: 0) {
        Text("By continuing you agree to the ").foregroundStyle(cs.mut)
        Link("Terms", destination: CSConfig.legal("terms")).foregroundStyle(cs.dawn)
        Text(" & ").foregroundStyle(cs.mut)
        Link("Privacy Policy", destination: CSConfig.legal("privacy")).foregroundStyle(cs.dawn)
        Text(".").foregroundStyle(cs.mut)
      }
      .font(CSFont.footnote)
      Text("v1 · build \(SessionStore.bundleBuild())").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
    }
  }

  // MARK: actions

  private func send() {
    Task {
      let was = vm.stage
      await vm.send()
      if vm.stage == .code { focus = .code; if was == .email { toasts.show("Code sent") } }
      else if vm.stage == .password { focus = .password }
    }
  }
  private func verify() { Task { await vm.verify() } }
  private func resend() { Task { await vm.resend() } }
  private func reviewer() { Task { await vm.reviewer() } }
}

@MainActor
@Observable
final class DoorModel {
  enum Stage { case email, code, password }
  struct Note { let text: String; let tone: CSTone }

  var stage: Stage = .email
  var email = ""
  var code = ""
  var password = ""
  var busy = false
  var note: Note? = nil
  var resendIn = 0
  private var ticker: Task<Void, Never>?
  private var spamHint: Task<Void, Never>?
  private let svc = SupabaseService.shared

  func send() async {
    guard !busy else { return }
    if AuthRules.isReviewer(email) {
      stage = .password
      note = Note(text: "Review access: enter the password from the notes.", tone: .pos)
      return
    }
    guard AuthRules.looksLikeEmail(email) else { note = Note(text: "That does not look like an email address.", tone: .neg); return }
    busy = true; note = Note(text: "Sending your code…", tone: .mut)
    defer { busy = false }
    do {
      try await svc.requestEmailCode(email)
      stage = .code; code = ""
      note = Note(text: "Sent to \(AuthRules.normalizeEmail(email)). Type the \(AuthRules.otpLength) digits from the newest email.", tone: .pos)
      startCooldown(); scheduleSpamHint()
    } catch {
      note = Note(text: AuthRules.human(error, fallback: "Could not send the code."), tone: .neg)
    }
  }

  func verify() async {
    guard !busy, AuthRules.isCompleteCode(code) else { return }
    busy = true; note = Note(text: "Checking the code…", tone: .mut)
    defer { busy = false }
    do {
      try await svc.verifyEmailCode(email: email, code: code)
      // no navigation here on purpose: the session store hears SIGNED_IN and
      // RootView switches — exactly one path into the app
      note = Note(text: "Signed in, loading…", tone: .pos)
      CSHaptic.success()
    } catch {
      note = Note(text: AuthRules.human(error, fallback: "That code did not take."), tone: .neg)
      code = ""
    }
  }

  func resend() async {
    guard !busy, resendIn == 0 else { return }
    busy = true
    defer { busy = false }
    do {
      try await svc.requestEmailCode(email)
      code = ""
      note = Note(text: "Fresh code sent to \(AuthRules.normalizeEmail(email)) — the newest email wins.", tone: .pos)
      startCooldown(); scheduleSpamHint()
    } catch {
      note = Note(text: AuthRules.human(error, fallback: "Could not resend."), tone: .neg)
    }
  }

  func reviewer() async {
    guard !busy else { return }
    // the web's floor (15015): a short string is a typo, not a sign-in attempt
    guard password.count >= 8 else { note = Note(text: "Enter the review password from the notes.", tone: .neg); return }
    busy = true; note = nil
    defer { busy = false }
    do {
      try await svc.signInReviewer(email: email, password: password)
      note = Note(text: "Signed in, loading…", tone: .pos)
    }
    catch { note = Note(text: AuthRules.human(error, fallback: "That password didn’t take."), tone: .neg) }
  }

  /// Sign in with Apple (IOS-023). Same shape as `verify`: no navigation here —
  /// the session store hears SIGNED_IN and RootView switches.
  func apple(idToken: String, nonce: String) async {
    guard !busy else { return }
    busy = true; note = Note(text: "Checking with Apple…", tone: .mut)
    defer { busy = false }
    do {
      try await svc.signInWithApple(idToken: idToken, nonce: nonce)
      note = Note(text: "Signed in, loading…", tone: .pos)
      CSHaptic.success()
    } catch {
      note = Note(text: AuthRules.human(error, fallback: "Apple did not sign you in. Your email still works."), tone: .neg)
    }
  }

  /// Apple's sheet failed before a token existed. A close is not an error.
  func appleFailed(_ error: any Error) {
    if DoorAppleError.isCancel(error) { note = nil; return }
    note = Note(text: AuthRules.human(error, fallback: "Apple did not sign you in. Your email still works."), tone: .neg)
  }

  #if DEBUG
  func devHatch(_ args: [String]) async {
    func arg(_ k: String) -> String? { args.firstIndex(of: k).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
    guard let e = arg("-cs_dev_email") else { return }
    email = e
    if let pw = arg("-cs_dev_password"), AuthRules.isReviewer(e) { stage = .password; password = pw; await reviewer(); return }
    if let c = arg("-cs_dev_code") { stage = .code; code = c; await verify() } else { await send() }
  }
  #endif

  func backToEmail() {
    stage = .email; code = ""; password = ""; note = nil
    spamHint?.cancel()
  }

  /// The web's `scheduleSpamHint` (index.html 15085): twenty seconds with the
  /// code box open and empty, and no error showing, earns one gentle pointer
  /// at the spam folder. Cancelled by a typed digit, a verify, or a resend.
  private func scheduleSpamHint() {
    spamHint?.cancel()
    spamHint = Task { [weak self] in
      try? await Task.sleep(for: .seconds(20))
      guard let self, !Task.isCancelled, self.stage == .code, self.code.isEmpty, self.note?.tone != .neg else { return }
      self.note = Note(text: "No code yet? Check spam for the newest Cup Season email — older codes retire when a new one sends.", tone: .mut)
    }
  }

  private func startCooldown() {
    resendIn = 30
    ticker?.cancel()
    ticker = Task { [weak self] in
      while let self, self.resendIn > 0 {
        try? await Task.sleep(for: .seconds(1))
        if Task.isCancelled { return }
        self.resendIn -= 1
      }
    }
  }
}

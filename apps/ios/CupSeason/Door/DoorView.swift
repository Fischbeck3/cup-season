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
  @State private var entering = false
  @State private var playForge: Bool? = nil
  @State private var risen = false
  @State private var flags = DoorFlags.closed
  @State private var toasts = CSToastCenter()   // the door sits above the tab host, so it carries its own
  /// QB-08 · what is waiting, said above the email field. Read once on
  /// appearance and again whenever a link lands while the door is up.
  @State private var pending: String? = PendingLink.doorLine()
  /// QB-08 · the cold-install answer, typed rather than tapped.
  @State private var codeEntry = false
  @State private var typedCode = ""
  @FocusState private var focus: Field?
  enum Field { case email, code, password, joinCode }
  /// IOS-064 · which register the door draws in. A pure read of the window and
  /// the reader's size — see `DoorLayout`.
  @Environment(\.dynamicTypeSize) private var typeSize
  private var working: Bool {
    DoorLayout.working(windowHeight: DoorLayout.windowHeight, typeSize: typeSize)
  }

  var body: some View {
    Group {
    if !entering { welcome } else {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          crest
            .background { CSTopoField().opacity(CSTokens.Alpha.a56) }
            .padding(.top, DoorLayout.crestTop(working: working))
            .padding(.bottom, DoorLayout.crestBottom(working: working))

          if risen {
            Group {
              // QB-08 · **THE INVITED STRANGER MEETS A SENTENCE, NOT A BOX.**
              //
              // `PendingLink.doorLine()` produces "You're joining The Fellas.
              // Sign in and you're on the roster.", is asserted verbatim by
              // `OnboardingTests`, and was called from no view — so somebody who
              // tapped a friend's link, installed, and came back met a bare email
              // field with nothing on the screen naming the season, the money or
              // the friend. "I have now created an account, agreed to Terms and a
              // Privacy Policy, and handed over my email — and I still do not
              // know what I am joining."
              //
              // IOS-064 · the SENTENCE is owed before the field in both
              // registers — it is what the email is being handed over for. The
              // generic PITCH is marketing, and on a working-register phone it
              // is 142pt of marketing between the mark and the only action on
              // the screen, so there it rides below.
              if vm.stage == .email, pending != nil { doorPitch }
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
      // **THE ACTION CLEARS THE KEYBOARD, AND THE MARK STAYS WHOLE.** The
      // system scrolls the FIELD into view and stops there, which on a 375pt
      // phone left `CONTINUE WITH EMAIL` entirely behind the keyboard. The
      // door scrolls its own primary instead, to the bottom edge, which is the
      // minimum scroll that reveals it — and clamps at zero, so the working
      // register (where the whole column already fits) does not move and the
      // crest never passes under the clock.
      .onChange(of: focus) { _, now in reach(proxy, focus: now) }
      .onChange(of: vm.stage) { _, _ in reach(proxy, focus: focus) }
    }
    }
    }
    // **DF-14 · NOTHING RENDERS UNDER THE CLOCK**, including the app mark. The
    // door was the one scrolling surface without the cap, so on any phone that
    // had to scroll the trophy was cut in half by the status bar.
    .csStatusCap(cs.bg0)
    .csToasts(toasts)
    .onAppear {
      pending = PendingLink.doorLine()
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

  private var welcome: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s5) {
        CSBrandMark().frame(width: 112, height: 64).foregroundStyle(cs.ink)
        Text(CSBrandCopy.tagline).csType(.lead).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityAddTraits(.isHeader)
        Text("Golf with your people, all season.").csType(.body).foregroundStyle(cs.mut)
        CSTopoField().frame(height: 120)
        Button("Get started", action: enter).buttonStyle(.csPrimary())
        Button("Sign in", action: enter).buttonStyle(.csSecondary())
      }
      .padding(CSTokens.Space.gutter)
      .padding(.top, CSTokens.Space.s6)
      .frame(maxWidth: 440, alignment: .leading)
      .frame(maxWidth: .infinity)
    }
    .background(cs.bg0)
  }

  private func enter() {
    entering = true
    risen = true
    focus = .email
  }

  private var crest: some View {
    HStack(spacing: CSTokens.Space.s3) {
      CSBrandMark().frame(width: CSTokens.Space.s6, height: CSTokens.Space.s5)
      Text("Cup Season").csType(.name)
    }.foregroundStyle(cs.ink)
  }

  /// The door's paragraph — the invited stranger's own sentence when there is
  /// one, the pitch when there is not. Drawn from one place because IOS-064
  /// draws it in two: above the field in the ceremony register, below the
  /// action in the working one.
  private var doorPitch: some View {
    Text(pending ?? OnboardingCopy.doorPitch)
      .csType(.story)
      .foregroundStyle(pending == nil ? cs.mut : cs.ink)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.bottom, 18)
      .accessibilityAddTraits(pending == nil ? [] : .isHeader)
  }

  /// **THE PRIMARY COMES OUT FROM BEHIND THE KEYBOARD.** Issued on every focus
  /// change and every stage change, after the keyboard's inset has landed on
  /// the scroll view — a scroll in the same runloop measures the pre-keyboard
  /// viewport and undershoots by exactly the keyboard's height.
  private func reach(_ proxy: ScrollViewProxy, focus: Field?) {
    guard focus != nil else { return }
    Task { @MainActor in
      try? await Task.sleep(for: DoorLayout.settle)
      // L-30 · the product's one curve, and it RESTS under reduced motion —
      // where the scroll still happens, it just arrives rather than travels.
      CSMotion.run(CSMotion.rise) { proxy.scrollTo(DoorLayout.action, anchor: .bottom) }
    }
  }

  // MARK: stages

  private var emailStage: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Email").csType(.agate, caps: true).foregroundStyle(cs.mut)
      CSField("you@example.com", text: $vm.email)
        .keyboardType(.emailAddress)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(.go)
        .focused($focus, equals: .email)
        .onSubmit { send() }
      Button("Continue with email") { send() }
        .buttonStyle(.csPrimary(busy: vm.busy))
        .padding(.top, CSTokens.Space.s2)
        .id(DoorLayout.action)
      if flags.appleSignIn {
        DoorAppleButton(
          onToken: { token, nonce, name in Task { await vm.apple(idToken: token, nonce: nonce, appleName: name) } },
          onFailure: { error in vm.appleFailed(error) })
          .padding(.top, 4)
          .disabled(vm.busy)
      }
      Text("One code, no password.")
        .csType(.bodyS).foregroundStyle(cs.mut).padding(.top, CSTokens.Space.s1)
      haveACode
    }
  }

  /// QB-08 · **THE COLD-INSTALL ANSWER, BUILT.**
  ///
  /// `PendingLink`'s own header names it: iOS has no deferred deep linking, so
  /// after an App Store install the system passes nothing and no token is ever
  /// stored — *"the cold case's answer is the door's 'I have a code'."* That
  /// control did not exist. The web's door has carried it since the beginning,
  /// so the two clients also disagreed about whether an invited stranger has a
  /// way in at all (R-C).
  ///
  /// It does not sign anybody in. It stores the code the way a tapped link
  /// does, so the sentence above the email field becomes theirs and the join
  /// resolves after the card — the one path into the app stays one path.
  @ViewBuilder private var haveACode: some View {
    if codeEntry {
      VStack(alignment: .leading, spacing: 8) {
        Text("League code").csType(.agate, caps: true).foregroundStyle(cs.mut)
        CSField("SATURDAY26", text: $typedCode)
          .textInputAutocapitalization(.characters).autocorrectionDisabled()
          .submitLabel(.done)
          .focused($focus, equals: .joinCode)
          .accessibilityLabel("League code")
          .onSubmit { takeCode() }
        Button("That\u{2019}s my code") { takeCode() }.buttonStyle(.csSecondary())
      }
      .padding(.top, 16)
    } else if pending == nil {
      Button("I have a code") { codeEntry = true; focus = .joinCode }
        .buttonStyle(.csTertiary(.content))
        .padding(.top, CSTokens.Space.s4)
    }
  }

  private var codeStage: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("The \(AuthRules.otpLength) digits").csType(.agate, caps: true).foregroundStyle(cs.mut)
      TextField("", text: $vm.code)
        .accessibilityLabel("The \(AuthRules.otpLength) digit code")
        .font(CSFont.code)
        .foregroundStyle(cs.ink)
        .kerning(6)
        .multilineTextAlignment(.center)
        .keyboardType(.numberPad)
        .textContentType(.oneTimeCode)   // iOS lifts the code out of the Mail notification
        .accessibilityLabel("The \(AuthRules.otpLength) digits")
        .padding(.vertical, CSTokens.Space.s3)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        // §7.2 · a field has NO border; focus is the one 2px brand ring
        .overlay {
          if focus == .code {
            RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
              .stroke(cs.brand, lineWidth: 2)
          }
        }
        .focused($focus, equals: .code)
        .onChange(of: vm.code) { _, new in
          let clean = AuthRules.normalizeCode(new)
          if clean != new { vm.code = clean }
          if AuthRules.isCompleteCode(clean) { verify() }
        }
      Button("Verify") { verify() }
        .buttonStyle(.csPrimary(busy: vm.busy))
        .padding(.top, CSTokens.Space.s2)
        .id(DoorLayout.action)
      // two text links side by side at reading sizes, stacked at the accessibility sizes; 44pt each
      A11yStack(spacing: CSTokens.Space.s3) {
        Button(vm.resendIn > 0 ? "Resend in \(vm.resendIn)s" : "Resend the code") { resend() }
          .buttonStyle(.csTertiary(.content))
          .disabled(vm.resendIn > 0 || vm.busy)
          .accessibilityHint(vm.resendIn > 0 ? "Available in \(vm.resendIn) seconds" : "")
        Spacer()
        Button("Change email") { vm.backToEmail(); focus = .email }
          .buttonStyle(.csTertiary(.content))
      }
      .padding(.top, CSTokens.Space.s1)
    }
    .onAppear { focus = .code }
  }

  private var passwordStage: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Password").csType(.agate, caps: true).foregroundStyle(cs.mut)
      SecureField("REVIEW PASSWORD", text: $vm.password)
        .accessibilityLabel("Password")
        .font(CSFont.mono)
        .textContentType(.password)
        .accessibilityLabel("Review password")
        .padding(.horizontal, 14).frame(minHeight: 48)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .focused($focus, equals: .password)
        .onSubmit { reviewer() }
      Button("Sign in") { reviewer() }.buttonStyle(.csPrimary(busy: vm.busy)).id(DoorLayout.action)
      Button("Change email") { vm.backToEmail(); focus = .email }
        .buttonStyle(.csTertiary(.content)).padding(.top, CSTokens.Space.s1)
    }
    .onAppear { focus = .password }
  }

  private var legal: some View {
    VStack(alignment: .leading, spacing: 6) {
      // the web's door line, verbatim: the two words are the links.
      //
      // **IT IS ONE `Text`, NOT FIVE IN AN `HStack`.** Five pieces cannot wrap
      // as a sentence — a `Link` is intrinsic and will not break, so the row
      // set "By continuing you agree to / the" on two lines with `Terms &
      // Privacy Policy.` hanging beside them, which is what the door's first
      // Wave 8 screenshot showed. Markdown in a `Text` keeps the links and
      // lets the sentence wrap like a sentence.
      Text(.init("By continuing you agree to the [Terms](\(CSConfig.legal("terms"))) & [Privacy Policy](\(CSConfig.legal("privacy")))."))
        .csType(.bodyS)
        .foregroundStyle(cs.mut)
        .tint(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text("v1 · build \(SessionStore.bundleBuild())").csType(.columnS).foregroundStyle(cs.mut)
    }
  }

  // MARK: actions

  private func send() {
    Task {
      await vm.send()
      // D297 · no "Code sent" toast: the live region under the field says
      // "Sent to … Type the 8 digits from the newest email." in the same tick.
      if vm.stage == .code { focus = .code }
      else if vm.stage == .password { focus = .password }
    }
  }
  private func verify() { Task { await vm.verify() } }

  /// QB-08 · a typed code is stored exactly as a tapped link stores one, name
  /// and all, so the door's own sentence and the covenant after the card both
  /// know which season this is.
  private func takeCode() {
    let code = JoinIntent.normalize(typedCode)
    guard code.count >= 4 else { toasts.show("That does not look like a code."); return }
    JoinIntent.store(code)
    codeEntry = false
    pending = PendingLink.doorLine()
    focus = .email
    Task {
      if let n = ((try? await JoinService().leagueName(code)) ?? nil), !n.isEmpty {
        JoinIntent.store(code, name: n)
        pending = PendingLink.doorLine()
      }
    }
  }
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
  func apple(idToken: String, nonce: String, appleName: String? = nil) async {
    guard !busy else { return }
    busy = true; note = Note(text: "Checking with Apple…", tone: .mut)
    defer { busy = false }
    do {
      // D186 · stash BEFORE the sign-in: SIGNED_IN swaps the root view out from
      // under us, so anything left until after the await may never run.
      AppleName.stash(appleName)
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

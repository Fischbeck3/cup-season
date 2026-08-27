// Cup Season — the door (IOS-004 #8; audit 01 §1.1).
//
// Email in, eight digits back, signed in. Code-only, structurally: the service
// takes an email and nothing else. The reviewer address takes a password.
// The full Forge (tracers, seared wordmark) lands in M6; M0 rests on the mark.

import SwiftUI
import CSDesign
import CupSeasonKit

struct DoorView: View {
  @Environment(\.cs) private var cs
  @State private var vm = DoorModel()
  @FocusState private var focus: Field?
  enum Field { case email, code, password }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        crest
          .padding(.top, 48)
          .padding(.bottom, 36)

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
      .padding(.horizontal, 24)
      .padding(.bottom, 40)
    }
    .scrollDismissesKeyboard(.interactively)
    .onAppear { focus = .email }
  }

  // MARK: crest

  private var crest: some View {
    VStack(alignment: .leading, spacing: 10) {
      Rectangle().fill(LinearGradient(colors: CSTokens.gradStops, startPoint: .leading, endPoint: .trailing))
        .frame(width: 44, height: 3)
      Text("Cup Season").font(CSFont.wordmark).foregroundStyle(cs.ink)
      Text("Rally your crew. Post real rounds.").font(CSFont.sentence).foregroundStyle(cs.mut)
      Text("Take the cup.").font(CSFont.sentenceBold).italic().foregroundStyle(cs.ink)
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
      SecureField("", text: $vm.password)
        .font(CSFont.mono)
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
      HStack(spacing: 14) {
        Link("Terms", destination: CSConfig.legal("terms"))
        Link("Privacy", destination: CSConfig.legal("privacy"))
      }
      .font(CSFont.footnote).foregroundStyle(cs.dawn)
      Text("v1 · build \(SessionStore.bundleBuild())").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
    }
  }

  // MARK: actions

  private func send() { Task { await vm.send() ; if vm.stage == .code { focus = .code } else if vm.stage == .password { focus = .password } } }
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
  private let svc = SupabaseService.shared

  func send() async {
    guard !busy else { return }
    if AuthRules.isReviewer(email) { stage = .password; note = nil; return }
    guard AuthRules.looksLikeEmail(email) else { note = Note(text: "That does not look like an email address.", tone: .neg); return }
    busy = true; note = Note(text: "Sending your code…", tone: .mut)
    defer { busy = false }
    do {
      try await svc.requestEmailCode(email)
      stage = .code; code = ""
      note = Note(text: "Sent to \(AuthRules.normalizeEmail(email)). Type the \(AuthRules.otpLength) digits from the newest email.", tone: .pos)
      startCooldown()
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
      note = Note(text: "Fresh code sent — the newest email wins.", tone: .pos)
      startCooldown()
    } catch {
      note = Note(text: AuthRules.human(error, fallback: "Could not resend."), tone: .neg)
    }
  }

  func reviewer() async {
    guard !busy, !password.isEmpty else { return }
    busy = true; note = nil
    defer { busy = false }
    do { try await svc.signInReviewer(email: email, password: password) }
    catch { note = Note(text: AuthRules.human(error, fallback: "That did not take."), tone: .neg) }
  }

  func backToEmail() {
    stage = .email; code = ""; password = ""; note = nil
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

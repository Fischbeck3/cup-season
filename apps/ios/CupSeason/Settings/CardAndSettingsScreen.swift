// Cup Season — "Card & settings" (audit 01 §1.6; index.html 13504–13840).
// Two panes, as the web: Your card (identity) · Settings (device & account).
// A long press on the build line opens the Developer section (IOS-022 item
// 8): the feedback door for everyone, the founder's desk and field note only
// when the server says founder.

import SwiftUI
import PhotosUI
import CSDesign
import CupSeasonKit

struct CardAndSettingsScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @State private var vm = CardSettingsModel()
  @State private var pane = CSDevHatch.settingsPane
  var openScoringHelp: () -> Void = {}

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        Text("Your card is what your buddies see · settings run the app").csEyebrow()
        Picker("", selection: $pane) {
          Text("Your card").tag(0)
          Text("Settings").tag(1)
        }
        .pickerStyle(.segmented)
        if pane == 0 {
          CardEditorPane(vm: vm, openScoringHelp: openScoringHelp)
        } else {
          SettingsPane(vm: vm)
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    .navigationTitle("Card & settings")
    .navigationBarTitleDisplayMode(.inline)
    .scrollDismissesKeyboard(.interactively)
    .task { await vm.load(userId: store.session?.user.id) }
  }
}

// MARK: - Model

@MainActor
@Observable
final class CardSettingsModel {
  let repo = ProfileRepository()
  var userId: UUID?
  var profile: ProfileRow?
  var avatar: URL?
  var leagues: [ProfileRepository.LeagueRow] = []

  // card fields
  var name = ""; var city = ""; var home = ""; var handle = ""; var ghin = ""; var marker: String? = nil
  var index = ""
  var dirty = false
  var saving = false
  var status: (String, CSTone)? = nil
  var photoBusy = false
  var indexBusy = false

  // settings
  var notifyRounds = true; var notifyChat = true
  var emailRecap: Bool? = nil     // nil = RPC absent → row hidden
  var deleteArmed = false; var deleting = false

  func load(userId: UUID?) async {
    guard let userId else { return }
    self.userId = userId
    async let p = repo.load(userId: userId)
    async let a = repo.avatarURL(userId: userId)
    async let l = repo.leagues(userId: userId)
    async let e = repo.emailRecap()
    profile = try? await p
    avatar = (profile?.photo_path ?? "").isEmpty ? nil : await a
    leagues = await l
    emailRecap = await e
    if let p = profile {
      name = p.display_name ?? ""; city = p.city ?? ""; home = p.home_course ?? ""
      handle = p.handle.map { "@\($0)" } ?? ""; ghin = p.ghin_number ?? ""; marker = p.marker
      index = p.index_current.map { String(format: "%.1f", $0) } ?? ""
      notifyRounds = p.notify_rounds ?? true; notifyChat = p.notify_chat ?? true
    }
    dirty = false
  }

  func save() async {
    let n = name.trimmingCharacters(in: .whitespaces)
    guard !n.isEmpty else { status = ("The card needs a name.", .neg); return }
    saving = true
    defer { saving = false }
    do {
      try await repo.saveCard(name: n, city: city.trimmingCharacters(in: .whitespaces), home: home.trimmingCharacters(in: .whitespaces),
                              marker: marker, ghin: ghin.trimmingCharacters(in: .whitespaces))
      let h = handle.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "^@", with: "", options: .regularExpression).lowercased()
      if !h.isEmpty, h != (profile?.handle ?? "") {
        do { try await repo.setHandle(h) }
        catch {
          await load(userId: userId)
          status = ("Card saved · handle: " + AuthRules.human(error, fallback: "not changed"), .mut)
          return
        }
      }
      await load(userId: userId)
      status = ("Card saved ✓", .pos)
    } catch {
      status = (AuthRules.human(error, fallback: "Save failed."), .neg)
    }
  }

  /// Returns the toast copy.
  func updateIndex() async -> String {
    guard let v = Double(index.replacingOccurrences(of: "+", with: "-")), (-10...54).contains(v) else {
      return "Index looks off: expected -10 to 54"
    }
    indexBusy = true
    defer { indexBusy = false }
    do {
      try await repo.setIndex(v)
      await load(userId: userId)
      return "Index updated to \(String(format: "%.1f", v)), posted to your league boards"
    } catch {
      // an established golfer's set is refused by design — information, not failure
      let m = AuthRules.human(error, fallback: "Index update failed.")
      return m.contains("comes from your scores") ? m : "Index update failed: \(m)"
    }
  }

  func setDiscoverable(_ mode: String) async -> String? {
    do { try await repo.setDiscoverable(mode); await load(userId: userId); return nil }
    catch { return AuthRules.human(error, fallback: "Could not update.") }
  }

  func addPhoto(_ jpeg: Data) async -> String {
    guard let userId else { return "Sign in first." }
    photoBusy = true
    defer { photoBusy = false }
    do {
      avatar = try await repo.uploadAvatar(userId: userId, jpeg: jpeg, currentName: name.isEmpty ? (profile?.display_name ?? "Golfer") : name)
      return "Photo on the card ✓"
    } catch { return AuthRules.human(error, fallback: "Could not add the photo.") }
  }

  func removePhoto() async -> String {
    guard let userId else { return "Sign in first." }
    photoBusy = true
    defer { photoBusy = false }
    do {
      try await repo.removeAvatar(userId: userId, currentName: name.isEmpty ? (profile?.display_name ?? "Golfer") : name)
      avatar = nil
      return "Back to the marker"
    } catch { return AuthRules.human(error, fallback: "Could not remove it.") }
  }

  func toggleRounds() async -> String? {
    let next = !notifyRounds
    do { try await repo.setNotifyRounds(next); notifyRounds = next; return nil }
    catch { return AuthRules.human(error, fallback: "Could not update.") }
  }
  func toggleChat() async -> String? {
    let next = !notifyChat
    do { try await repo.setNotifyChat(next); notifyChat = next; return nil }
    catch { return AuthRules.human(error, fallback: "Could not update.") }
  }
  func toggleEmail() async -> String? {
    guard let cur = emailRecap else { return nil }
    do { emailRecap = try await repo.setEmailRecap(!cur); return nil }
    catch { return AuthRules.human(error, fallback: "Could not update.") }
  }

  func deleteAccount() async -> String? {
    deleting = true
    defer { deleting = false }
    do { try await repo.deleteAccount(); return nil }
    catch { return AuthRules.human(error, fallback: "Could not delete the account.") }
  }
}

// MARK: - Your card

private struct CardEditorPane: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Bindable var vm: CardSettingsModel
  let openScoringHelp: () -> Void
  @State private var pick: PhotosPickerItem?
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      label("Name on the card")
      CSField("", text: $vm.name, font: CSFont.body).textContentType(.name).onChange(of: vm.name) { vm.dirty = true }
      HStack(spacing: 10) {
        VStack(alignment: .leading, spacing: 6) { label("City"); CSField("", text: $vm.city, font: CSFont.body).onChange(of: vm.city) { vm.dirty = true } }
        VStack(alignment: .leading, spacing: 6) { label("Home course"); CSField("", text: $vm.home, font: CSFont.body).onChange(of: vm.home) { vm.dirty = true } }
      }

      label("Ball marker").padding(.top, 4)
      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(CSMarkers.all) { m in
          Button { vm.marker = m.key; vm.dirty = true; CSHaptic.selection() } label: {
            VStack(spacing: 6) {
              CSMarkerView(m, size: 28).foregroundStyle(vm.marker == m.key ? cs.brand : cs.ink)
              Text(m.name).font(CSFont.label).foregroundStyle(cs.mut).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
              .stroke(vm.marker == m.key ? cs.brand : cs.line, lineWidth: vm.marker == m.key ? 2 : 1))
          }
          .buttonStyle(.plain)
          .accessibilityLabel(m.name)
          .accessibilityAddTraits(vm.marker == m.key ? .isSelected : [])
        }
      }

      label("Your photo · the marker always backs it up").padding(.top, 4)
      HStack(spacing: 10) {
        CSFace(photoURL: vm.avatar, marker: vm.marker ?? vm.profile?.marker, size: 56)
        PhotosPicker(selection: $pick, matching: .images) {
          MiniPill(text: vm.photoBusy ? "Uploading…" : (vm.avatar == nil ? "Add a photo" : "Change photo"))
        }
        .disabled(vm.photoBusy)
        if vm.avatar != nil {
          Button { Task { toast.show(await vm.removePhoto()) } } label: { MiniPill(text: "Remove") }.disabled(vm.photoBusy)
        }
      }
      .onChange(of: pick) { _, item in
        guard let item else { return }
        Task {
          defer { pick = nil }
          guard let data = try? await item.loadTransferable(type: Data.self), let jpeg = AvatarCrop.squareJPEG(data, side: 512, quality: 0.85) else {
            toast.show("Could not add the photo."); return
          }
          toast.show(await vm.addPhoto(jpeg))
        }
      }

      HStack(alignment: .top, spacing: 10) {
        VStack(alignment: .leading, spacing: 6) {
          label("Handle · moves once / 60 days")
          CSField("@handle", text: $vm.handle).textInputAutocapitalization(.never).autocorrectionDisabled().onChange(of: vm.handle) { vm.dirty = true }
        }
        VStack(alignment: .leading, spacing: 6) {
          label("Findable by")
          HStack(spacing: 6) {
            ForEach([("everyone", "All"), ("friends", "Buddies"), ("nobody", "Nobody")], id: \.0) { mode, title in
              let on = (vm.profile?.discoverable ?? "everyone") == mode
              Button { Task { if let e = await vm.setDiscoverable(mode) { toast.show(e) } } } label: {
                Text(title).font(CSFont.monoSmall).foregroundStyle(on ? cs.pos : cs.ink)
                  .padding(.horizontal, 10).padding(.vertical, 8)
                  .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
                  .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(on ? cs.pos : cs.line2, lineWidth: 1))
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      .padding(.top, 4)

      label("GHIN # · optional").padding(.top, 4)
      CSField("e.g. 1234567", text: $vm.ghin).keyboardType(.numberPad).frame(maxWidth: 200).onChange(of: vm.ghin) { vm.dirty = true }
      Text("A reference on your card — we never resell or verify it. Leave it blank if you'd rather not.")
        .font(CSFont.footnote).foregroundStyle(cs.dimText)

      HStack(spacing: 12) {
        Button { Task { await vm.save() } } label: { MiniPill(text: vm.saving ? "Saving…" : (vm.dirty ? "Save changes" : "Save card"), accent: vm.dirty) }
          .disabled(vm.saving)
        if let s = vm.status { CSNote(s.0, tone: s.1).font(CSFont.footnote) }
      }
      .padding(.top, 6)

      Text("Handicap index").csEyebrow().padding(.top, 16)
      HStack(spacing: 10) {
        CSField("", text: $vm.index).keyboardType(.decimalPad).frame(maxWidth: 110)
        Button { Task { toast.show(await vm.updateIndex()) } } label: { MiniPill(text: vm.indexBusy ? "Updating…" : "Update index") }.disabled(vm.indexBusy)
      }
      Text("Your index builds automatically from your posted scores (best of your recent rounds, WHS-style) — it appears once you've posted 3. Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced on your league boards, crew-policed.")
        .font(CSFont.footnote).foregroundStyle(cs.dimText)
      Button("How scoring works →", action: openScoringHelp).font(CSFont.footnote).foregroundStyle(cs.dawn)

      Text("Your leagues").csEyebrow().padding(.top, 16)
      if vm.leagues.isEmpty {
        Text("No league yet.").font(CSFont.footnote).foregroundStyle(cs.dimText)
      } else {
        ForEach(vm.leagues) { row in
          HStack {
            Text(row.leagues?.name ?? "League").font(CSFont.body).foregroundStyle(cs.ink)
            Spacer()
            Text("\(row.role == "commissioner" ? "PRO" : "PLAYER") · \(row.leagues?.code ?? "")").font(CSFont.label).foregroundStyle(cs.mut)
          }
          .padding(.vertical, 6)
        }
      }
    }
  }

  private func label(_ s: String) -> some View { Text(s).font(CSFont.label).tracking(1).textCase(.uppercase).foregroundStyle(cs.dimText) }
}

// MARK: - Settings

private struct SettingsPane: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.csAppearance) private var appearance
  @Environment(\.presenter) private var presenter
  @Bindable var vm: CardSettingsModel
  @State private var push = PushService.shared
  @State private var pricing = PricingFlags.hidden
  /// The Developer section, revealed by a long press on the build line.
  @State private var developer = CSDevHatch.developer

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Notifications").csEyebrow()
      PillFlow {
        pill(push.enabled ? "Disable on this device" : "Enable on this device") {
          Task { toast.show(push.enabled ? await push.disable() : await push.enable()) }
        }
        pill("Round pings: \(vm.notifyRounds ? "ON" : "OFF")") { Task { if let e = await vm.toggleRounds() { toast.show(e) } } }
        pill("Chat pings: \(vm.notifyChat ? "ON" : "OFF")") { Task { if let e = await vm.toggleChat() { toast.show(e) } } }
        if let mail = vm.emailRecap {
          pill("Season email: \(mail ? "ON" : "OFF")") { Task { if let e = await vm.toggleEmail() { toast.show(e) } } }
        }
      }
      Text("Moments, reveals, and month closes always come through. Round posts and chat each have their own switch.")
        .font(CSFont.footnote).foregroundStyle(cs.dimText)

      Text("Appearance").csEyebrow().padding(.top, 14)
      Picker("Appearance", selection: appearance) {
        ForEach(CSAppearance.allCases, id: \.self) { Text($0.label).tag($0) }
      }
      .pickerStyle(.segmented)
      .onChange(of: appearance.wrappedValue) { _, new in new.save() }

      Text("Membership & billing").csEyebrow().padding(.top, 14)
      // D56 / IOS-021: Founding · free season · (paid, future) — the PILOT stub verbatim while hidden
      MembershipCard(flags: pricing, memberships: store.me?.memberships ?? [], proNames: nil)
        .task { pricing = await PricingFlags.load() }

      CSButton("Sign out", style: .quiet) { Task { await store.signOut() } }.padding(.top, 12)

      Text("Danger zone").csEyebrow().padding(.top, 18)
      if !vm.deleteArmed {
        Button("Delete my account") { vm.deleteArmed = true; CSHaptic.warning() }.font(CSFont.footnote).foregroundStyle(cs.neg)
      } else {
        Text("This can't be undone. Your name and profile are removed and your login is closed for good. Rounds you've posted stay in the record so nobody else's standings or pot break — you'll just show as \"Former member\".")
          .font(CSFont.footnote).foregroundStyle(cs.mut)
        HStack(spacing: 8) {
          Button {
            Task {
              if let e = await vm.deleteAccount() { toast.show(e) } else { await store.signOut() }
            }
          } label: {
            Text(vm.deleting ? "Deleting…" : "Delete permanently").font(CSFont.button)
              .frame(maxWidth: .infinity, minHeight: 46)
              .foregroundStyle(cs.ink)
              .background(cs.neg, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          }
          .buttonStyle(.plain).disabled(vm.deleting)
          Button("Cancel") { vm.deleteArmed = false }.font(CSFont.subhead).foregroundStyle(cs.mut)
        }
      }

      Text("Cup Season · v1 · build \(store.build)").font(CSFont.footnote).foregroundStyle(cs.dimText).padding(.top, 20)
        .frame(minHeight: 44, alignment: .bottomLeading)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 1) {
          guard !developer else { return }
          CSHaptic.impact(.medium)
          withAnimation(CSMotion.roll) { developer = true }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Press and hold for the Developer section")
      if developer {
        PolishDeveloperSection(
          isFounder: store.founding.badge(for: store.me?.profile?.id) == .founder,
          openDesk: { presenter.showDesk = true },
          fieldNote: { presenter.showNote = true },
          feedback: { presenter.feedbackScreen = "settings"; presenter.showFeedback = true })
        .transition(.opacity)
      }
      HStack(spacing: 10) {
        Link("Privacy", destination: CSConfig.legal("privacy"))
        Text("·")
        Link("Terms", destination: CSConfig.legal("terms"))
        Text("·")
        Link("Prize pool", destination: CSConfig.legal("pot"))
      }
      .font(CSFont.footnote).foregroundStyle(cs.mut)
    }
  }

  private func pill(_ s: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(s).font(CSFont.monoMediumBody).foregroundStyle(cs.ink)
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
    }
    .buttonStyle(.plain)
    .disabled(push.busy)
  }
}

/// A wrapping HStack for pills.
struct PillFlow<Content: View>: View {
  @ViewBuilder let content: Content
  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8, alignment: .leading)], alignment: .leading, spacing: 8) { content }
  }
}

/// The web's `.mini` pill.
private struct MiniPill: View {
  @Environment(\.cs) private var cs
  let text: String
  var accent = false
  var body: some View {
    Text(text).font(CSFont.monoMediumBody).foregroundStyle(accent ? cs.bg0 : cs.ink)
      .padding(.horizontal, 14).padding(.vertical, 9)
      .background(accent ? cs.brand : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(accent ? .clear : cs.line2, lineWidth: 1))
  }
}

// MARK: - Developer (IOS-022 item 8)

/// Exactly the rows that left the You tab: the desk and the field note when
/// the SERVER says founder (`founding_ids()`), the feedback door for everyone.
private struct PolishDeveloperSection: View {
  let isFounder: Bool
  let openDesk: () -> Void
  let fieldNote: () -> Void
  let feedback: () -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSSectionHead("Developer")
      if isFounder {
        CSRow { YouDoorRow(glyph: Text("📈"), title: "Open the desk", action: openDesk) }
        CSRow { YouDoorRow(glyph: Text("✏️"), title: "Field note", action: fieldNote) }
      }
      CSRow(last: true) { YouDoorRow(glyph: Text("💬"), title: "Tell us how it's going", action: feedback) }
      if isFounder {
        Fine("Notes land in the feedback ledger · the desk shows signups, activity, errors, feedback.").padding(.top, 6)
      }
    }
  }
}

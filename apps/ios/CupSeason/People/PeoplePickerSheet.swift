// Cup Season — the one People Picker (`openPeoplePicker` 13452; the
// component the IA blueprint called "the real asset"). Two modes: befriend
// (→ `friend_request`) and invite (→ `invite_golfer` / staged "Added ✓").

import SwiftUI
import CSDesign
import CupSeasonKit

enum PeoplePickerMode {
  case befriend
  /// `excludeIds` already belong ("In"); `share` adds the league's
  /// "Share an invite link instead" footer (`openInvitePicker`, 16370).
  case invite(InviteTarget, excludeIds: Set<UUID> = [], share: (name: String, code: String)? = nil)
}

struct PeoplePickerSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var vm: PickerModel
  @State private var toasts: CSToastCenter
  let mode: PeoplePickerMode
  let title: String
  let sub: String
  let note: String?
  let onDone: () -> Void

  init(mode: PeoplePickerMode, title: String? = nil, sub: String? = nil, note: String? = nil, onDone: @escaping () -> Void) {
    self.mode = mode
    self.onDone = onDone
    self.note = note
    switch mode {
    case .befriend:
      self.title = title ?? "Add golfers"; self.sub = sub ?? "Search the app or your buddies"
    case .invite:
      self.title = title ?? "Add golfers"; self.sub = sub ?? "Invited golfers get a notification and choose to join"
    }
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: PickerModel(mode: mode, toasts: t))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          CSSheetHeader(title: title, sub: sub)
          CSField("Find golfers by name or @handle", text: $vm.query, font: CSFont.body)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
          list
          if case .invite(_, _, let share) = mode, let share {
            ShareLink(item: URL(string: "https://cupseason.app/?join=\(share.code)")!,
                      subject: Text("Cup Season"),
                      message: Text("You're invited to \(share.name) on Cup Season")) {
              Text("Share an invite link instead").font(CSFont.button).foregroundStyle(cs.ink)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
            }
            .padding(.top, 4)
          }
          if let note { CSFine(note) }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { onDone(); dismiss() }.foregroundStyle(cs.brand) } }
      .task { await vm.buddies() }
      .task(id: vm.query) { await vm.search() }
      .csToasts(toasts)
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  @ViewBuilder private var list: some View {
    if vm.rows.isEmpty {
      // S3-03: "No golfers found" only answers a SEARCH
      if vm.query.trimmingCharacters(in: .whitespaces).isEmpty {
        if vm.loaded { CSFine("Type a name or @handle to search — buddies you add appear here.") }
      } else if !vm.searching {
        CSFine("No golfers found. Invite links still work for everyone else.")
      }
    } else {
      ForEach(vm.rows) { r in
        PersonRow(person: r, links: CSLinks()) { action(r) }
      }
    }
  }

  @ViewBuilder private func action(_ r: Person) -> some View {
    switch mode {
    case .invite(_, let exclude, _):
      if exclude.contains(r.id) { CSTag(text: "In", tone: cs.pos) }
      else if vm.staged.contains(r.id) { CSTag(text: "Added ✓", tone: cs.pos) }
      else { CSMini("Add", busy: vm.busy.contains(r.id)) { Task { await vm.pick(r) } } }
    case .befriend:
      if let a = r.rel.action { CSMini(a, busy: vm.busy.contains(r.id)) { Task { await vm.add(r) } } }
      else if let t = r.rel.tag { CSTag(text: t, tone: r.rel == .friend ? cs.pos : nil) }
    }
  }
}

@MainActor
@Observable
final class PickerModel {
  var query = ""
  var rows: [Person] = []
  var staged = Set<UUID>()
  var busy = Set<UUID>()
  var loaded = false
  var searching = false
  private let mode: PeoplePickerMode
  private let toasts: CSToastCenter
  private let people = PeopleService()

  init(mode: PeoplePickerMode, toasts: CSToastCenter) { self.mode = mode; self.toasts = toasts }

  /// empty search = your accepted buddies (pilot walked back league-mate recommendations here)
  func buddies() async {
    if let l = try? await people.friends() { rows = l.buddies }
    loaded = true
  }

  func search() async {
    let q = query.trimmingCharacters(in: .whitespaces)
    if q.isEmpty { await buddies(); return }
    try? await Task.sleep(for: .milliseconds(350))
    guard !Task.isCancelled else { return }
    searching = true; defer { searching = false }
    rows = (try? await people.search(q)) ?? []
  }

  func add(_ r: Person) async {
    busy.insert(r.id); defer { busy.remove(r.id) }
    do {
      let rel = try await people.request(r.id)
      toasts.show(rel == .friend ? "Golf buddies ✓" : "Request sent")
      if let i = rows.firstIndex(where: { $0.id == r.id }) { rows[i].rel = rel == .friend ? .friend : .requested }
    } catch { toasts.show(HumanError.text(error, prefix: "Could not send.")) }
  }

  func pick(_ r: Person) async {
    guard case .invite(let target, _, _) = mode else { return }
    busy.insert(r.id); defer { busy.remove(r.id) }
    do { try await people.invite(r.id, to: target); staged.insert(r.id); CSHaptic.selection() }
    catch { toasts.show(HumanError.text(error, prefix: "Could not add.")) }
  }
}

#Preview("Find golfers") {
  PeoplePickerSheet(mode: .befriend, title: "Find golfers", sub: "Search by name or @handle to add buddies", onDone: {}).csTheme()
}

// Cup Season — staging invitees BEFORE the event exists (`openRyderSetup`
// 15966–15971, `openMajorSetup` 16094–16099): the setup sheets open the
// People Picker in invite mode with an `onPick` that STAGES; the invites
// fire once `create_event` / `create_major` returns an id. The one People
// Picker's invite mode needs a target that exists, so this sheet reuses its
// model (buddies first, one letter searches) and stages instead.

import SwiftUI
import CSDesign
import CupSeasonKit

struct EventStagePicker: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var vm: PickerModel
  @State private var toasts = CSToastCenter()
  let title: String
  let sub: String
  let excludeIds: Set<UUID>
  @Binding var staged: [Person]

  init(title: String, sub: String, excludeIds: Set<UUID>, staged: Binding<[Person]>) {
    self.title = title; self.sub = sub; self.excludeIds = excludeIds; _staged = staged
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: PickerModel(mode: .befriend, toasts: t))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          CSSheetHeader(title: title, sub: sub)
          CSField("Find golfers by name or @handle", text: $vm.query, font: CSFont.body)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
          if vm.rows.isEmpty {
            if vm.query.trimmingCharacters(in: .whitespaces).isEmpty {
              if vm.loaded { CSFine("Type a name or @handle to search — buddies you add appear here.") }
            } else if !vm.searching {
              CSFine("No golfers found. Invite links still work for everyone else.")
            }
          } else {
            ForEach(vm.rows) { r in
              PersonRow(person: r, links: CSLinks()) {
                if excludeIds.contains(r.id) { CSTag(text: "In", tone: cs.pos) }
                else if staged.contains(where: { $0.id == r.id }) { CSTag(text: "Added ✓", tone: cs.pos) }
                else { CSMini("Add") { staged.append(r); CSHaptic.selection() } }
              }
            }
          }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(cs.brand) } }
      .task { await vm.buddies() }
      .task(id: vm.query) { await vm.search() }
      .csToasts(toasts)
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }
}

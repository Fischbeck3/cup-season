// Cup Season — the bag, and the one place it is edited (D262, IOS-042, R-O).
//
// Fourteen clubs in the golfer's own words, the sideline under them, the ball
// at the bottom, and at the TOP the sentence the whole feature exists for:
// "Since the new driver went in: four rounds, two beat your playing HCP."
//
// THREE RULES THE SCREEN OBEYS, all of them R-O's:
//   * NO EQUIPMENT DATABASE. Two free-text fields per row and nothing else —
//     no picker, no catalogue, no autocomplete against a brand list.
//   * A CHANGE IS A POST, and the diff is the SERVER'S. This screen sends the
//     whole bag; `save_bag` decides what moved and whether anything is worth
//     saying. So a re-order or a typo fix posts nothing, and the screen never
//     has to guess (L-20/21/22).
//   * FOURTEEN. The button that would add a fifteenth says why it cannot,
//     rather than disappearing or failing at the server.

import SwiftUI
import CSDesign
import CupSeasonKit

struct BagSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var vm = BagEditor()
  /// The host reloads the You row's summary when the bag is saved.
  var onSaved: () -> Void = {}

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          CSSheetHeader(title: BagCopy.yours, sub: BagCopy.emptySub.uppercased())

          if vm.loading {
            CSFine("Opening your bag…")
          } else if vm.failed {
            // L-32 · a failed read is never an empty bag. Saying "nothing in
            // it yet" to a golfer whose fourteen clubs are on the other side
            // of a dead network is the lie this branch exists to refuse.
            CSNote("Could not open your bag. Nothing has been changed.")
            CSButton("Try again", style: .quiet) { Task { await vm.load() } }
          } else {
            if let since = vm.bag?.since {
              Text(BagCopy.sinceLine(since))
                .font(CSFont.sentence).foregroundStyle(cs.ink)
                .fixedSize(horizontal: false, vertical: true)
            }

            Text(BagCopy.inTheBag.uppercased()).csEyebrow().padding(.top, 4)
            ForEach($vm.clubs) { $club in
              row($club, inBag: true)
            }
            if vm.clubs.isEmpty { CSFine("Nothing in the bag yet.") }
            if vm.clubs.count >= BagCopy.cap {
              CSFine(BagCopy.full)
            } else {
              CSButton(BagCopy.addClub, style: .quiet) { vm.addClub() }
            }

            Text(BagCopy.sideline.uppercased()).csEyebrow().padding(.top, 8)
            CSFine(BagCopy.sidelineWhat)
            ForEach($vm.sideline) { $club in
              row($club, inBag: false)
            }
            CSButton("Add to the sideline", style: .quiet) { vm.addSideline() }

            Text(BagCopy.ballHead.uppercased()).csEyebrow().padding(.top, 8)
            CSField(BagCopy.ballPlaceholder, text: $vm.ball, font: CSFont.subhead)
              .accessibilityLabel("The ball you play")

            if let note = vm.note { CSNote(note, tone: .neg).padding(.top, 4) }

            CSButton("Save the bag", busy: vm.saving) {
              Task { if await vm.save() { onSaved(); dismiss() } }
            }
            .padding(.top, 8)
          }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .navigationTitle("")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }.font(CSFont.subhead).foregroundStyle(cs.brand)
        }
      }
    }
    .task { await vm.load() }
    .sliceToastHost()
  }

  /// One club: the slot, the thing, and the one menu that moves it. The whole
  /// row is two text fields — there is no picker, because there is no list to
  /// pick from and R-O refused the list.
  @ViewBuilder private func row(_ club: Binding<Bag.Item>, inBag: Bool) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      A11yStack(rowAlignment: .firstTextBaseline, spacing: 8, columnSpacing: 6) {
        CSField(BagCopy.slotPlaceholder, text: Binding(
          get: { club.wrappedValue.slot ?? "" },
          set: { club.wrappedValue.slot = $0 }), font: CSFont.subhead)
          .frame(maxWidth: 120)
          .accessibilityLabel("What kind of club")
        CSField(BagCopy.labelPlaceholder, text: club.label, font: CSFont.subhead)
          .accessibilityLabel("The club, in your own words")
        Menu {
          if inBag {
            Button("Move to the sideline") { vm.toSideline(club.wrappedValue) }
          } else {
            Button("Put in the bag") { vm.toBag(club.wrappedValue) }
          }
          Button("Move up") { vm.move(club.wrappedValue, by: -1) }
          Button("Move down") { vm.move(club.wrappedValue, by: 1) }
          Button("Remove", role: .destructive) { vm.remove(club.wrappedValue) }
        } label: {
          Image(systemName: "ellipsis").font(.system(size: 17, weight: .semibold))
            .foregroundStyle(cs.mut).frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .accessibilityLabel("Move or remove \(club.wrappedValue.line)")
      }
    }
  }
}

// MARK: - the editor

@MainActor
@Observable
final class BagEditor {
  var bag: Bag?
  var clubs: [Bag.Item] = []
  var sideline: [Bag.Item] = []
  var ball = ""
  var loading = true
  var saving = false
  /// true only when the READ failed — never when the bag came back empty.
  var failed = false
  var note: String?

  private let svc = BagService()

  func load() async {
    loading = true; failed = false; note = nil
    let read = await svc.load()
    loading = false
    guard let b = read, b.visible else { failed = true; return }
    bag = b
    clubs = b.clubs
    sideline = b.sideline
    ball = b.ball?.label ?? ""
  }

  func addClub() {
    guard clubs.count < BagCopy.cap else { note = BagCopy.full; return }
    note = nil
    clubs.append(Bag.Item(label: ""))
  }
  func addSideline() { sideline.append(Bag.Item(label: "")) }

  func toSideline(_ item: Bag.Item) {
    guard let i = clubs.firstIndex(where: { $0.localId == item.localId }) else { return }
    sideline.append(clubs.remove(at: i))
  }
  func toBag(_ item: Bag.Item) {
    guard clubs.count < BagCopy.cap else { note = BagCopy.full; return }
    guard let i = sideline.firstIndex(where: { $0.localId == item.localId }) else { return }
    note = nil
    clubs.append(sideline.remove(at: i))
  }
  func remove(_ item: Bag.Item) {
    clubs.removeAll { $0.localId == item.localId }
    sideline.removeAll { $0.localId == item.localId }
  }
  /// Driver → putter is the golfer's own order, so moving a row is the whole
  /// of ordering. It never crosses into the sideline: that is a different act
  /// and it has its own menu item.
  func move(_ item: Bag.Item, by delta: Int) {
    func shift(_ list: inout [Bag.Item]) -> Bool {
      guard let i = list.firstIndex(where: { $0.localId == item.localId }) else { return false }
      let j = i + delta
      guard j >= 0, j < list.count else { return true }
      list.swapAt(i, j)
      return true
    }
    if shift(&clubs) { return }
    _ = shift(&sideline)
  }

  /// Returns true when the save landed. The screen closes on true and stays
  /// open, with the reason, on false — a sheet that dismisses over a failed
  /// write tells the golfer their bag is saved when it is not.
  func save() async -> Bool {
    saving = true
    defer { saving = false }
    note = nil
    let typed = ball.trimmingCharacters(in: .whitespaces)
    do {
      let after = try await svc.save(clubs: clubs, sideline: sideline,
                                    ball: typed.isEmpty ? nil : typed, ballSet: true)
      bag = after
      clubs = after.clubs
      sideline = after.sideline
      ball = after.ball?.label ?? ""
      ToastCenter.shared.show(BagCopy.saved)
      return true
    } catch {
      note = SliceFormat.human(error, "Could not save your bag.")
      return false
    }
  }
}

#Preview("Bag") {
  BagSheet().csTheme()
}

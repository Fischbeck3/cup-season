// Cup Season — D163 · the round follows you.
//
// A live round used to be reachable from exactly one place: a banner on Home.
// Leave Home and the round you are playing vanished from the app — and for a
// golfer who JOINED one from someone else's phone (D158) there was nothing at
// all, because the resume banner only renders on a tab they may never open.
//
// This is a slim bar above the tabs, present on every screen while a round is
// live, and while an accepted invitation is waiting for its round to start. It
// is the same idea as the Live Activity, inside the app: whatever you are
// doing, the round is one tap away.
//
// It hides while the round itself is on screen — a bar offering to take you
// where you already are is furniture.

import SwiftUI
import CSDesign
import CupSeasonKit

struct LiveNowBar: View {
  @Environment(\.cs) private var cs
  @State private var store = LiveRoundStore.shared
  /// true while the tee sheet is presented — the bar stands down
  let presented: Bool
  let open: () -> Void

  @State private var breathe = false

  private var live: Bool { store.state.active && store.state.stage == .live }
  private var waiting: String? { store.awaitingFrom }

  var body: some View {
    Group {
      if !presented, live || waiting != nil {
        Button(action: open) {
          HStack(spacing: 9) {
            Circle().fill(cs.bg0).frame(width: 7, height: 7)
              .opacity(breathe ? 0.35 : 1)
            Text(live ? "LIVE" : "ON THE TEE")
              .font(CSFont.label.weight(.semibold)).tracking(1.4)
            Text(line)
              .font(CSFont.monoSmall)
              .lineLimit(1).truncationMode(.tail)
            Spacer(minLength: 6)
            Text("→").font(CSFont.monoSmall.weight(.semibold))
          }
          .foregroundStyle(cs.bg0)
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, minHeight: 34)
          .background(cs.brand)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(live ? "Live round in progress. \(line)" : line)
        .accessibilityHint("Opens the round")
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
          guard !UIAccessibility.isReduceMotionEnabled else { return }
          withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { breathe = true }
        }
      }
    }
    .animation(.easeOut(duration: 0.22), value: live)
    .animation(.easeOut(duration: 0.22), value: waiting)
  }

  /// The bar says where the round IS, not what it is called — a golfer glancing
  /// at it wants the hole, and the course only to know which round.
  private var line: String {
    if let who = waiting, !live {
      return "Waiting for \(LiveFmt.fn1(who)) to tee off"
    }
    let s = store.state
    let course = s.course.label.isEmpty ? "Your round" : s.course.label
    return "\(course) · Hole \(min(max(s.hole, 0), s.liveHoles - 1) + 1)"
  }
}

// Cup Season — You (IOS-002 §8). M0: the credential card and the settings
// that let the gate be tested honestly — appearance, sign out, the build line.

import SwiftUI
import CSDesign
import CupSeasonKit

struct YouView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.csAppearance) private var appearance
  @State private var armed = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if let p = store.me?.profile {
          CSCard(padding: 18) {
            HStack(spacing: 14) {
              CSFace(marker: p.marker, size: 56)
              VStack(alignment: .leading, spacing: 3) {
                Text(p.display_name ?? "Golfer").font(CSFont.title).foregroundStyle(cs.ink)
                Text([p.handle.map { "@\($0)" }, p.city].compactMap { $0 }.joined(separator: " · "))
                  .font(CSFont.monoSmall).foregroundStyle(cs.mut)
                if let since = p.member_since {
                  Text("Member since \(since.formatted(.dateTime.month(.abbreviated).year()))")
                    .font(CSFont.footnote).foregroundStyle(cs.dimText)
                }
              }
              Spacer()
              VStack(alignment: .trailing, spacing: 2) {
                Text(p.index_current != nil ? CSCopy.index(p.index_current) : "\(min(p.rounds_count ?? 0, 3)) of 3")
                  .font(CSFont.heroSmall).foregroundStyle(p.index_current != nil ? cs.gold : cs.ink).csTabular()
                Text(p.index_current != nil ? "index" : "building").csEyebrow()
              }
            }
          }
        }

        Text("Appearance").csEyebrow().padding(.top, 8)
        Picker("Appearance", selection: appearance) {
          ForEach(CSAppearance.allCases, id: \.self) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
        .onChange(of: appearance.wrappedValue) { _, new in new.save() }

        Text("Account").csEyebrow().padding(.top, 8)
        CSCard {
          VStack(alignment: .leading, spacing: 12) {
            if let email = store.email {
              Text(email).font(CSFont.monoSmall).foregroundStyle(cs.mut)
            }
            Button(armed ? "Sure? Sign out" : "Sign out") {
              if armed { Task { await store.signOut() } } else { armed = true; CSHaptic.warning() }
            }
            .font(CSFont.button).foregroundStyle(armed ? cs.neg : cs.ink)
          }
        }

        Text("Legal").csEyebrow().padding(.top, 8)
        HStack(spacing: 16) {
          Link("Privacy", destination: CSConfig.legal("privacy"))
          Link("Terms", destination: CSConfig.legal("terms"))
          Link("Prize pool", destination: CSConfig.legal("pot"))
        }
        .font(CSFont.subhead).foregroundStyle(cs.dawn)

        Text("Cup Season · v1 · build \(store.build) · M0")
          .font(CSFont.monoSmall).foregroundStyle(cs.dimText).padding(.top, 16)
      }
      .padding(20)
    }
    .background(cs.bg0)
    .navigationTitle("You")
    .navigationBarTitleDisplayMode(.inline)
  }
}

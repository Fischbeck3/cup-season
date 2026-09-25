#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

enum SecurityReviewFixture {
  static var on: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_security") }
}

/// Synthetic actions exercise the production sheets without contacting a backend.
struct SecurityReviewFixtureView: View {
  @Environment(\.cs) private var cs
  @State private var card: LinkConfirmation?
  @State private var scanning = false
  @State private var comment: CommentSafety?
  @State private var writes = 0
  @State private var result = "No action"
  @State private var busy = false
  private let owner = UUID(uuidString: "c5000000-0000-4000-8000-000000000001")!
  private let author = UUID(uuidString: "c5000000-0000-4000-8000-000000000002")!
  private var long: Bool { ProcessInfo.processInfo.arguments.contains("-cs_security_long") }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          Text("Security flow review").csType(.lead)
          ForEach(LinkConfirmation.Kind.allCases, id: \.rawValue) { kind in
            Button("Open \(kind.rawValue) link") {
              let token = UUID()
              switch kind {
              case .person: ShareIntent.person.store(token)
              case .plan: ShareIntent.plan.store(token)
              case .claim: ClaimIntent.store(token.uuidString)
              }
              card = LinkConfirmation(kind: kind, token: token, owner: owner, info: .object([
                "name": .string(long ? "Alexandria Montgomery-Fairbanks" : "Alex"),
                "host": .string(long ? "Alexandria Montgomery-Fairbanks" : "Alex"),
                "marker": .string("pin"), "index": .number(12.4), "gross": .number(84),
                "course": .string(long ? "The Championship Course at Desert Mountain" : "Papago"),
                "course_label": .string(long ? "The Championship Course at Desert Mountain" : "Papago"),
                "play_on": .string("2026-09-27"), "played_on": .string("2026-09-25"), "guest_name": .string("Alex")
              ]))
            }.buttonStyle(.csSecondary()).accessibilityIdentifier("open-" + kind.rawValue)
          }
          Button("Open scan consent") { scanning = true }.buttonStyle(.csSecondary()).accessibilityIdentifier("open-scan")
          Button("Open comment safety") { comment = CommentSafety(id: UUID(), kind: .comment, author: author, name: "Alex Ridley") }.buttonStyle(.csSecondary()).accessibilityIdentifier("open-comment")
          Button("Open plan comment safety") { comment = CommentSafety(id: UUID(), kind: .roundComment, author: author, name: "Alex Ridley") }.buttonStyle(.csSecondary()).accessibilityIdentifier("open-plan-comment")
          Button("Clear pending actions") {
            SessionActionCleanup.clear()
            result = LinkConfirmation.Kind.allCases.allSatisfy { LinkConfirmation.pending($0) == nil } ? "Pending actions cleared" : "Pending action remains"
          }.buttonStyle(.csSecondary()).accessibilityIdentifier("clear-actions")
          Text("Writes: \(writes)").accessibilityIdentifier("security-writes")
          Text(result).accessibilityIdentifier("security-result")
        }.padding(CSTokens.Space.gutter)
      }.background(cs.bg0)
    }
    .sheet(item: $card) { value in
      LinkConfirmationSheet(card: value, busy: busy, confirm: {
        guard !busy, value.isCurrent(owner: owner) else { return }
        busy = true; writes += 1; result = "Confirmed \(value.kind.rawValue)"; value.clear(); card = nil; busy = false
      }, decline: { value.clear(); result = "Not now"; card = nil })
    }
    .sheet(isPresented: $scanning) {
      ScanConsentSheet(busy: busy, agree: {
        guard !busy else { return }
        busy = true; writes += 1; result = "Scan permitted"; scanning = false; busy = false
      }, decline: { result = ScanConsentCopy.declined; scanning = false })
    }
    .sheet(item: $comment) { target in
      CommentSafetySheet(target: target, reportAction: { reason in
        writes += 1; result = "Reported \(target.kind.rawValue): \(reason)"
      }, blockAction: { writes += 1; result = "Blocked Alex" })
    }
  }
}
#endif

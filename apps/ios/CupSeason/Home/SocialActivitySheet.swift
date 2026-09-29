import SwiftUI
import Observation
import CSDesign
import CupSeasonKit

@MainActor @Observable final class SocialInboxStore {
  var items: [SocialNotice] = []
  var unread = 0
  var loading = false
  var missing = false
  var error: String?
  var nextBefore: String?
  var nextBeforeId: String?
  private var generation = 0
  private let service = RoundSocialService()

  func clear() {
    generation += 1; items = []; unread = 0; nextBefore = nil; nextBeforeId = nil; error = nil; missing = false; loading = false
  }
  func load(more: Bool = false) async {
    generation += 1
    let stamp = generation
    loading = true
    defer { if stamp == generation { loading = false } }
    do {
      var params: [String: JSONValue] = [:]
      if more {
        params["p_before"] = nextBefore.map(JSONValue.string) ?? .null
        if let nextBeforeId { params["p_before_id"] = .string(nextBeforeId) }
      }
      let answer = try await service.request("my_notifications", params)
      guard stamp == generation else { return }
      let rows = (answer["items"]?.array ?? []).compactMap(SocialNotice.init)
      if more {
        let known = Set(items.map(\.id)); items += rows.filter { !known.contains($0.id) }
      } else { items = rows }
      unread = answer["unread"]?.int ?? 0; nextBefore = answer["next_before"]?.string
      nextBeforeId = answer["next_before_id"]?.string
      error = nil; missing = false
    } catch {
      guard stamp == generation else { return }
      missing = (error as? RpcError)?.isMissingFunction == true
      if !missing { self.error = HumanError.text(error, prefix: "Could not load activity.") }
    }
  }
  func mark(_ id: UUID? = nil) async {
    generation += 1
    loading = false
    let stamp = generation
    do {
      let answer = try await service.request("mark_notifications_read", id.map { ["p_ids": .array([.string($0.uuidString)])] } ?? ["p_all": .bool(true)])
      guard stamp == generation else { return }
      unread = answer["unread"]?.int ?? unread
      for i in items.indices where id == nil || items[i].id == id { items[i].read = true }
      error = nil
    } catch {
      if stamp == generation { self.error = HumanError.text(error, prefix: "Could not mark activity read.") }
    }
  }
}

struct SocialActivitySheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @Bindable var inbox: SocialInboxStore
  @Environment(\.openSettings) private var openSettings
  @State private var door: RoundDiscussionDoor?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          Text("Activity").csType(.display).foregroundStyle(cs.ink)
          if inbox.unread > 0 {
            Button("Mark all read") { Task { await inbox.mark() } }.buttonStyle(.csTertiary(.content))
          }
          if inbox.missing {
            Text("Comment activity needs the latest server update.").csType(.body).foregroundStyle(cs.mut)
          } else if inbox.items.isEmpty && !inbox.loading && inbox.error == nil {
            Text("When someone comments on your round or replies to you, it will be here.")
              .csType(.body).foregroundStyle(cs.mut)
          }
          ForEach(inbox.items) { notice in
            CSRule()
            Button {
              door = RoundDiscussionDoor(roundId: notice.roundId, commentId: notice.commentId)
              Task { await inbox.mark(notice.id) }
            } label: {
              HStack(alignment: .top, spacing: CSTokens.Space.s3) {
                CSFace(.init(id: notice.actor.id, marker: notice.actor.marker), size: .slat, name: notice.actor.name)
                VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
                  Text(notice.sentence).csType(.body).foregroundStyle(cs.ink)
                  Text(notice.excerpt).csType(.bodyS).foregroundStyle(cs.mut).lineLimit(3)
                  if let course = notice.course { Text(course).csType(.agateS).foregroundStyle(cs.mut) }
                  Text(SocialDate.label(notice.createdAt)).csType(.agateS).foregroundStyle(cs.mut)
                }.frame(maxWidth: .infinity, alignment: .leading)
                if !notice.read { Circle().fill(cs.ink).frame(width: 8, height: 8).accessibilityLabel("Unread") }   // N4-091 · a notice mark is ink
              }
              .padding(.vertical, CSTokens.Space.s3)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("activity.\(notice.id.uuidString)")
          }
          if inbox.loading { Text("Loading activity…").csType(.bodyS).foregroundStyle(cs.mut) }
          if let error = inbox.error {
            Text(error).csType(.bodyS).foregroundStyle(cs.neg)
            Button("Try again") { Task { await inbox.load() } }.buttonStyle(.csTertiary(.content))
          }
          if inbox.nextBefore != nil {
            Button("Earlier activity") { Task { await inbox.load(more: true) } }
              .buttonStyle(.csSecondary()).disabled(inbox.loading)
          }
          // TEN / W6 · ONE NOTIFICATIONS SECTION (W2, owner C): the three
          // conversation switches are Settings' now. The inbox carries a door
          // to them rather than a second set that could disagree with the first.
          Button(ConversationPrefs.door) { dismiss(); openSettings() }
            .buttonStyle(.csTertiary(.content))
            .padding(.top, CSTokens.Space.s2)
        }
        .padding(CSTokens.Space.gutter)
      }
      .background(cs.bg0)
      .navigationTitle("").navigationBarTitleDisplayMode(.inline)
      .csCloseButton { dismiss() }
      .refreshable { await inbox.load() }
    }
    .task { await inbox.load() }
    .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await inbox.load() } } }
    .csSheet(item: $door) { target in
      RoundReceiptSheet(roundId: target.roundId, seed: nil, focusComments: true, focusComment: target.commentId)
    }
  }
}

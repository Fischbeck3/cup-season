import SwiftUI
import CSDesign
import CupSeasonKit

struct RoundDiscussionDoor: Identifiable {
  let roundId: UUID
  var commentId: UUID? = nil
  var id: String { roundId.uuidString + (commentId?.uuidString ?? "") }
}

struct RoundConversation: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var session
  let roundId: UUID
  var focusComment: UUID? = nil
  var onLoaded: (String?) -> Void = { _ in }
  @State private var thread: PostedRoundThread?
  @State private var draft = ""
  @State private var replying: SocialComment?
  @State private var pending: CommentIntent?
  @State private var busy = false
  @State private var loading = true
  @State private var unavailable = false
  @State private var error: String?
  @State private var report: SocialComment?
  @FocusState private var composing: Bool
  private let service = RoundSocialService()

  var body: some View {
    if !unavailable {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        HStack {
          CSSectionHead("Comments")
          Spacer()
          if let thread, thread.visible {
            Menu {
              Button(thread.state == "following" ? "Unfollow conversation" : "Follow conversation") {
                changeState(thread.state == "following" ? "none" : "following")
              }
              Button(thread.state == "muted" ? "Unmute conversation" : "Mute conversation") {
                changeState(thread.state == "muted" ? "none" : "muted")
              }
              Button("Refresh comments") { Task { await load() } }
            } label: {
              CSGlyph(.more, size: .inline).foregroundStyle(cs.mut).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Conversation options")
            .disabled(busy)
          }
        }
        if loading && thread == nil { Text("Loading comments…").csType(.bodyS).foregroundStyle(cs.mut) }
        if let thread {
          if !thread.visible {
            Text("This conversation is no longer available.").csType(.bodyS).foregroundStyle(cs.mut)
          } else {
            if thread.comments.isEmpty {
              Text("Start the conversation.").csType(.body).foregroundStyle(cs.mut)
            }
            ForEach(thread.roots) { root in
              comment(root)
              ForEach(thread.replies(to: root.id)) { reply in
                comment(reply).padding(.leading, CSTokens.Space.s4)
              }
              CSRule()
            }
            if thread.count > thread.comments.count {
              Text("Showing \(thread.comments.count) of \(thread.count) comments.")
                .csType(.bodyS).foregroundStyle(cs.mut)
            }
            if thread.state == "muted" {
              Text("Notifications muted for this conversation.").csType(.bodyS).foregroundStyle(cs.mut)
            }
            if thread.canComment { composer }
          }
        }
        if let error {
          Text(error).csType(.bodyS).foregroundStyle(cs.neg)
          if thread == nil { Button("Try again") { Task { await load() } }.buttonStyle(.csTertiary(.content)) }
        }
      }
      .task(id: session.session?.user.id) { await load() }
      .csSheet(item: $report) { comment in CommentReportSheet(comment: comment) }
    }
  }

  private func comment(_ item: SocialComment) -> some View {
    HStack(alignment: .top, spacing: CSTokens.Space.s2) {
      CSFace(.init(id: item.author.id, marker: item.author.marker), size: .slat, name: item.author.name)
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        Text(item.isMine ? "You" : item.author.name).csType(.social).foregroundStyle(cs.ink)
        if let name = item.replyTo { Text("Replying to \(CourseNames.first(name))").csType(.agateS).foregroundStyle(cs.mut) }
        Text(item.body).csType(.body).foregroundStyle(cs.ink).textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
        HStack(spacing: CSTokens.Space.s3) {
          Text(SocialDate.label(item.createdAt)).csType(.agateS).foregroundStyle(cs.mut)
          if item.fromBoard { Text("League board").csType(.agateS).foregroundStyle(cs.mut) }
          if item.canReply {
            Button("Reply") { replying = item; composing = true }
              .buttonStyle(.plain).csType(.bodyS).foregroundStyle(cs.ink).frame(minHeight: 44)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Menu {
        if item.isMine && !item.fromBoard {
          Button("Remove comment", role: .destructive) { Task { await remove(item) } }
        } else {
          Button("Report comment") { report = item }
          Button("Block \(CourseNames.first(item.author.name))") {
            Task {
              do { try await service.block(item.author.id); await load() }
              catch { self.error = HumanError.text(error, prefix: "Could not block this golfer.") }
            }
          }
        }
      } label: {
        CSGlyph(.more, size: .inline).foregroundStyle(cs.mut).frame(width: 44, height: 44)
      }
      .accessibilityLabel("Actions for \(item.author.name)’s comment")
      .accessibilityIdentifier("round.comment.actions.\(item.id.uuidString)")
    }
    .padding(.vertical, CSTokens.Space.s2)
    .padding(.horizontal, item.id == focusComment ? CSTokens.Space.s2 : 0)
    .background(item.id == focusComment ? cs.bg2 : Color.clear)
    .id(item.id.uuidString)
    .accessibilityIdentifier("round.comment.\(item.id.uuidString)")
  }

  private var composer: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      if let replying {
        HStack {
          Text("Reply to \(CourseNames.first(replying.author.name))").csType(.bodyS)
          Spacer()
          Button("Cancel reply") { self.replying = nil }.buttonStyle(.csTertiary(.content))
        }
      }
      CSField(placeholder: "Say something…", text: $draft, limit: 500, multiline: true)
        .focused($composing).disabled(busy).accessibilityIdentifier("round.comment.draft")
      HStack {
        Spacer()
        Button(replying == nil ? "Post comment" : "Post reply") { Task { await send() } }
          .buttonStyle(.csPrimary(busy: busy))
          .disabled(busy || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.count > 500)
          .accessibilityIdentifier("round.comment.send")
      }
    }
  }

  private func load(focus: UUID? = nil) async {
    let account = session.session?.user.id
    loading = true
    defer { loading = false }
    do {
      let target = focus ?? focusComment
      let answer = try await service.thread(roundId, focus: target)
      guard account == session.session?.user.id else { thread = nil; return }
      thread = answer; error = nil
      await Task.yield()
      onLoaded(target.flatMap { id in answer.comments.contains { $0.id == id } ? id.uuidString : nil })
    } catch {
      if (error as? RpcError)?.isMissingFunction == true { unavailable = true }
      else { self.error = HumanError.text(error, prefix: "Could not load comments.") }
    }
  }

  private func send() async {
    guard !busy else { return }
    let intent = pending?.forRetry(body: draft, parentId: replying?.id) ?? CommentIntent(body: draft, parentId: replying?.id)
    pending = intent; busy = true; error = nil
    defer { busy = false }
    do {
      let sent = try await service.send(roundId, intent: intent)
      draft = ""; replying = nil; pending = nil; composing = false
      await load(focus: sent)
    } catch { self.error = HumanError.text(error, prefix: "Your comment did not send. Try again.") }
  }
  private func changeState(_ state: String) {
    Task {
      busy = true
      defer { busy = false }
      do { try await service.state(roundId, state); await load() }
      catch { self.error = HumanError.text(error, prefix: "Could not change notifications.") }
    }
  }
  private func remove(_ comment: SocialComment) async {
    do { try await service.remove(comment.id); await load() }
    catch { self.error = HumanError.text(error, prefix: "Could not remove this comment.") }
  }
}

enum SocialDate {
  static func label(_ timestamp: String) -> String {
    let parser = ISO8601DateFormatter(); parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let date = parser.date(from: timestamp) ?? ISO8601DateFormatter().date(from: timestamp)
    guard let date else { return "" }
    return date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
  }
}

private struct CommentReportSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  let comment: SocialComment
  @State private var reason: String?
  @State private var busy = false
  @State private var error: String?
  var body: some View {
    SliceSheet(title: "Report comment", sub: SafetyCopy.reportSub) {
      Text(comment.body).csType(.body)
      ForEach(SafetyCopy.reasons, id: \.self) { value in
        Button { reason = value } label: {
          HStack { Text(value); Spacer(); if reason == value { Image(systemName: "checkmark") } }.frame(minHeight: 44)
        }.buttonStyle(.plain).foregroundStyle(cs.ink)
      }
      if let error { Text(error).csType(.bodyS).foregroundStyle(cs.neg) }
      Button("Send report") {
        guard let reason else { return }
        Task {
          busy = true
          defer { busy = false }
          do { try await RoundSocialService().report(comment.id, reason: reason); dismiss() }
          catch { self.error = HumanError.text(error, prefix: "Could not send this report.") }
        }
      }.buttonStyle(.csPrimary(busy: busy)).disabled(reason == nil || busy)
    }
  }
}

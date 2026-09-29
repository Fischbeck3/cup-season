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
        // N4-202 · D391's words, from the Kit's one table (TalkCopy, the web's
        // CS_TALK): "Conversation" with its count, and Follow as the web's
        // toggle, "Follow" / "Following", beside it
        HStack(spacing: CSTokens.Space.s2) {
          CSSectionHead(TalkCopy.head, count: thread.flatMap { $0.visible ? "\($0.count)" : nil })
          if let thread, thread.visible {
            let following = thread.state == "following"
            Button(following ? TalkCopy.following : TalkCopy.follow) {
              changeState(following ? "none" : "following")
            }
            .buttonStyle(.csTertiary(.content))
            .accessibilityAddTraits(following ? .isSelected : [])
            .accessibilityIdentifier("round.comment.follow")
            .disabled(busy)
            Menu {
              Button(thread.state == "muted" ? TalkCopy.unmute : TalkCopy.mute) {
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
            Text(TalkCopy.gone).csType(.bodyS).foregroundStyle(cs.mut)
          } else {
            // the older comments are the ones not sent, so the line sits above the rows
            if thread.truncated {
              Text(TalkCopy.truncated(thread.newest, of: thread.count))
                .csType(.bodyS).foregroundStyle(cs.mut)
            }
            if thread.comments.isEmpty {
              Text(TalkCopy.empty).csType(.body).foregroundStyle(cs.mut)
            }
            ForEach(thread.roots) { root in
              comment(root)
              ForEach(thread.replies(to: root.id)) { reply in
                comment(reply).padding(.leading, CSTokens.Space.s4)
              }
              CSRule()
            }
            if thread.canComment { composer(thread) }
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
        if let name = item.replyTo { Text(TalkCopy.to(name)).csType(.agateS).foregroundStyle(cs.mut) }
        Text(item.body).csType(.body).foregroundStyle(cs.ink).textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
        HStack(spacing: CSTokens.Space.s3) {
          Text(SocialDate.label(item.createdAt)).csType(.agateS).foregroundStyle(cs.mut)
          if item.fromBoard { Text("League board").csType(.agateS).foregroundStyle(cs.mut) }
          if item.canReply {
            Button("Reply") { replying = item; composing = true }
              .buttonStyle(.plain).csType(.bodyS).foregroundStyle(cs.ink).frame(minHeight: 44).contentShape(Rectangle())
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Menu {
        if item.isMine && !item.fromBoard {
          Button(TalkCopy.remove, role: .destructive) { Task { await remove(item) } }
        } else {
          Button(TalkCopy.report) { report = item }
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

  /// The composer says what it is writing ("Add a comment" / "Your reply"),
  /// and under the field what this golfer will hear about — the web's line.
  private func composer(_ thread: PostedRoundThread) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      if let replying {
        HStack {
          Text(TalkCopy.replyingTo(replying.author.name)).csType(.bodyS)
          Spacer()
          Button("Cancel reply") { self.replying = nil }.buttonStyle(.csTertiary(.content))
        }
      }
      CSField(label: replying == nil ? TalkCopy.add : TalkCopy.reply, placeholder: TalkCopy.placeholder,
              text: $draft,
              caption: TalkCopy.hint(state: thread.state, followedOn: thread.followedOn, repliesOn: thread.repliesOn),
              limit: 500, multiline: true)
        .focused($composing).disabled(busy).accessibilityIdentifier("round.comment.draft")
      HStack {
        Spacer()
        Button(replying == nil ? TalkCopy.send : TalkCopy.sendReply) { Task { await send() } }
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
      else { self.error = HumanError.text(error, prefix: TalkCopy.readFailed) }
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
    } catch { self.error = HumanError.text(error, prefix: TalkCopy.failed) }
  }
  private func changeState(_ state: String) {
    Task {
      busy = true
      defer { busy = false }
      do { try await service.state(roundId, state); await load() }
      catch { self.error = HumanError.text(error, prefix: TalkCopy.stateFailed) }
    }
  }
  private func remove(_ comment: SocialComment) async {
    do { try await service.remove(comment.id); await load() }
    catch { self.error = HumanError.text(error, prefix: TalkCopy.removeFailed) }
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
          HStack { Text(value); Spacer(); if reason == value { Image(systemName: "checkmark") } }.frame(minHeight: 44).contentShape(Rectangle())
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

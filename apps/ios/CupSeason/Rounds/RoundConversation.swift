import SwiftUI
import CSDesign
import CupSeasonKit

struct RoundDiscussionDoor: Identifiable {
  let roundId: UUID
  var commentId: UUID? = nil
  var id: String { roundId.uuidString + (commentId?.uuidString ?? "") }
}

/// D391 · a posted round's one conversation, in two shapes (D405).
///
/// `.page` is the round's own page: the whole conversation, replies nested
/// under their comment, under a head that says whose round it is. `.inline` is
/// the same thread opened IN PLACE under the round it is on — on Home and on
/// the board: the newest three comments, flat, oldest first, an "Earlier
/// comments (N)" button above them, and the composer at the foot. One thread,
/// one read (`posted_round_thread`), one write (`add_posted_round_comment`);
/// this is a second VIEW of it, never a second copy.
///
/// There is no Follow. Commenting turns a golfer's notices on (the server does
/// it), and the ··· menu carries the one setting, "Notify me about".
struct RoundConversation: View {
  enum Style { case page, inline }
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(SessionStore.self) private var session
  let roundId: UUID
  var style: Style = .page
  var focusComment: UUID? = nil
  /// inline · an empty conversation was opened to write in: the cursor goes to
  /// the composer once the thread has loaded
  var autoFocus = false
  /// inline · the owner of the page hands a counter that moves when it
  /// reloads, so a pull on Home also re-reads a thread that is open
  var reloadKey = 0
  /// The page's trailing closure: the comment a notice opened, once it is in the thread
  var onLoaded: (String?) -> Void = { _ in }
  @State private var thread: PostedRoundThread?
  /// what every view of this round's conversation shares: the draft, the comment replied to, the
  /// key of a send not yet answered, and the news that a comment landed (`RoundTalk`)
  @State private var talk: RoundTalk
  /// the last of its changes this view has acted on (one it made itself is read by its own send)
  @State private var seen: Int
  /// which read is the newest asked for: an answer to an older one is not drawn
  @State private var generation = 0
  @State private var busy = false
  @State private var loading = true
  @State private var unavailable = false
  @State private var error: String?
  @State private var report: SocialComment?
  /// inline · "Earlier comments (N)" was pressed: every loaded comment shows
  @State private var showAll = false
  @State private var focusDraft = false
  @FocusState private var composing: Bool
  private let service = RoundSocialService()

  init(roundId: UUID, style: Style = .page, focusComment: UUID? = nil, autoFocus: Bool = false, reloadKey: Int = 0,
       onLoaded: @escaping (String?) -> Void = { _ in }) {
    self.roundId = roundId; self.style = style; self.focusComment = focusComment
    self.autoFocus = autoFocus; self.reloadKey = reloadKey
    self.onLoaded = onLoaded
    let shared = CommentDrafts.talk(roundId)
    _talk = State(initialValue: shared)
    _seen = State(initialValue: shared.changes)
  }

  private struct LoadKey: Hashable { let account: UUID?; let reload: Int }

  var body: some View {
    if !unavailable {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        head
        if loading && thread == nil { Text("Loading comments…").csType(.bodyS).foregroundStyle(cs.mut) }
        if let thread {
          if !thread.visible {
            Text(TalkCopy.gone).csType(.bodyS).foregroundStyle(cs.mut)
          } else {
            rows(thread)
            if thread.canComment { composer(thread) }
          }
        }
        if let error {
          Text(error).csType(.bodyS).foregroundStyle(cs.neg)
          if thread == nil { Button("Try again") { Task { await load() } }.buttonStyle(.csTertiary(.content)) }
        }
      }
      .task(id: LoadKey(account: session.session?.user.id, reload: reloadKey)) { await load() }
      .onChange(of: talk.changes) { _, now in
        // a comment landed from another view of this conversation (the round's own page, the other
        // tab): this one reads it too, rather than keep showing the thread as it was
        guard now != seen else { return }
        seen = now
        Task { await load() }
      }
      .csSheet(item: $report) { comment in CommentReportSheet(comment: comment) }
    }
  }

  // MARK: - The head

  @ViewBuilder private var head: some View {
    switch style {
    case .page:
      // D405 · the page's conversation says whose round it is: "On Theo’s 84"
      HStack(spacing: CSTokens.Space.s2) {
        CSSectionHead(thread?.conversationHead ?? TalkCopy.head, count: thread.flatMap { $0.visible ? "\($0.count)" : nil })
        if let thread, thread.visible { options(thread) }
      }
    case .inline:
      if let thread, thread.visible {
        HStack(spacing: CSTokens.Space.s2) {
          let earlier = showAll ? 0 : thread.earlierCount(showing: thread.recent().count)
          if earlier > 0 {
            Button(TalkCopy.earlier(earlier)) { showAll = true }
              .buttonStyle(.csTertiary(.content))
              .frame(minHeight: 44)
              .accessibilityIdentifier("round.comment.earlier")
          } else if thread.count > 0 {
            Text(HomeWireCopy.commentsDoor(thread.count)).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              .accessibilityAddTraits(.isHeader)
          }
          Spacer(minLength: 0)
          options(thread)
        }
      }
    }
  }

  /// The ··· menu: the one setting, "Notify me about" (Every comment · Replies
  /// to me · Nothing), and a refresh. A round's owner already hears every
  /// comment, so theirs offers two choices.
  private func options(_ thread: PostedRoundThread) -> some View {
    Menu {
      Section(TalkCopy.notifyHead) {
        ForEach(thread.notifyOptions) { choice in
          Button {
            changeNotify(choice)
          } label: {
            if choice == thread.notify { Label(choice.label, systemImage: "checkmark") } else { Text(choice.label) }
          }
        }
      }
      Button("Refresh comments") { Task { await load() } }
    } label: {
      CSGlyph(.more, size: .inline).foregroundStyle(cs.mut).frame(width: 44, height: 44)
    }
    .accessibilityLabel("Conversation options")
    .accessibilityIdentifier("round.comment.options")
    .disabled(busy)
  }

  // MARK: - The comments

  @ViewBuilder private func rows(_ thread: PostedRoundThread) -> some View {
    // the older comments are the ones not sent, so the line sits above the rows
    if thread.truncated && (style == .page || showAll) {
      Text(TalkCopy.truncated(thread.newest, of: thread.count))
        .csType(.bodyS).foregroundStyle(cs.mut)
    }
    if thread.comments.isEmpty {
      Text(TalkCopy.empty).csType(.body).foregroundStyle(cs.mut)
    }
    switch style {
    case .page:
      ForEach(thread.roots) { root in
        comment(root)
        ForEach(thread.replies(to: root.id)) { reply in
          comment(reply).padding(.leading, CSTokens.Space.s4)
        }
        CSRule()
      }
    case .inline:
      ForEach(showAll ? thread.comments : thread.recent()) { comment($0) }
    }
  }

  /// One comment, in two lines: who said it, how long ago and the two things you
  /// can do to it (Reply, and ··· for report / block / remove) — then what they
  /// said, under their name. A thread is people; it should not read like a table.
  private func comment(_ item: SocialComment) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      // who and when on one side, Reply and ··· on the other; at the accessibility
      // sizes they stack instead of squeezing the name into a column of letters
      A11yStack(alignment: .leading, rowAlignment: .center, spacing: CSTokens.Space.s2, columnSpacing: 0) {
        HStack(alignment: .center, spacing: CSTokens.Space.s2) {
          CSFace(.init(id: item.author.id, marker: item.author.marker), size: .slat, name: item.author.name)
          VStack(alignment: .leading, spacing: 0) {
            // the face, the first name and how long ago
            A11yStack(alignment: .leading, rowAlignment: .firstTextBaseline, spacing: CSTokens.Space.s2, columnSpacing: 0) {
              Text(item.isMine ? "You" : CourseNames.first(item.author.name)).csType(.social).foregroundStyle(cs.ink)
              Text(SocialStamp.when(item.createdAt)).csType(.agateS).foregroundStyle(cs.mut)
              if item.fromBoard { Text("League board").csType(.agateS).foregroundStyle(cs.mut) }
            }
            if let name = item.replyTo { Text(TalkCopy.to(name)).csType(.agateS).foregroundStyle(cs.mut) }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        HStack(spacing: 0) {
          if item.canReply {
            Button("Reply") { talk.replying = item; focusDraft = true; composing = true }
              .buttonStyle(.plain).csType(.bodyS).foregroundStyle(cs.ink)
              .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
          }
          Menu {
            if item.isMine && !item.fromBoard {
              Button(TalkCopy.remove, role: .destructive) { Task { await remove(item) } }
            } else {
              Button(TalkCopy.report) { report = item }
              Button("Block \(CourseNames.first(item.author.name))") {
                Task {
                  do { try await service.block(item.author.id); wrote(); await load() }
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
      }
      Text(item.body).csType(.body).foregroundStyle(cs.ink).textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
        // under the name, not under the face
        .padding(.leading, CSFace.Size.slat.rawValue + CSTokens.Space.s2)
    }
    .padding(.bottom, CSTokens.Space.s2)
    .padding(.horizontal, item.id == focusComment ? CSTokens.Space.s2 : 0)
    .background(item.id == focusComment ? cs.bg2 : Color.clear)
    .id(item.id.uuidString)
    .accessibilityIdentifier("round.comment.\(item.id.uuidString)")
  }

  // MARK: - The composer

  /// The composer says what it is writing on ("Comment on Theo’s 84…"), and
  /// under the field what this golfer will hear about — the web's line. The
  /// page keeps its label ("Add a comment" / "Your reply") and a full-width
  /// Send; in line the field stands alone and Send sits beside the hint.
  private func composer(_ thread: PostedRoundThread) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      if let replying = talk.replying {
        HStack {
          Text(TalkCopy.replyingTo(replying.author.name)).csType(.bodyS)
          Spacer()
          Button("Cancel reply") { talk.replying = nil }.buttonStyle(.csTertiary(.content))
        }
      }
      if let failure = talk.sendError {
        Text(failure).csType(.bodyS).foregroundStyle(cs.neg)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityIdentifier("round.comment.error")
      }
      switch style {
      case .page:
        CSField(label: talk.replying == nil ? TalkCopy.add : TalkCopy.reply, placeholder: thread.placeholder,
                text: draft, caption: thread.hint, limit: 500, multiline: true, focusRequest: $focusDraft)
          .focused($composing).disabled(busy).accessibilityIdentifier("round.comment.draft")
        HStack {
          Spacer()
          Button(talk.replying == nil ? TalkCopy.send : TalkCopy.sendReply) { Task { await send() } }
            .buttonStyle(.csPrimary(busy: busy))
            .disabled(sendDisabled)
            .accessibilityIdentifier("round.comment.send")
        }
      case .inline:
        // at the accessibility sizes a one-line prompt is cut short ("Comment on Bl…"), so
        // what the comment is on is said as the field's label instead
        CSField(label: typeSize.isA11y ? thread.placeholder.trimmingCharacters(in: CharacterSet(charactersIn: "…")) : nil,
                placeholder: thread.placeholder, text: draft, limit: 500, multiline: true, focusRequest: $focusDraft)
          .focused($composing).disabled(busy).accessibilityIdentifier("round.comment.draft")
        A11yStack(alignment: .leading, rowAlignment: .firstTextBaseline, spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s1) {
          Text(thread.hint).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: 0)
          Button(talk.replying == nil ? TalkCopy.send : TalkCopy.sendReply) { Task { await send() } }
            .buttonStyle(.csTertiary(.content))
            .frame(minHeight: 44)
            .disabled(sendDisabled)
            .accessibilityIdentifier("round.comment.send")
        }
      }
    }
  }

  /// the field's text is the round's shared draft (`RoundTalk`), not this view's own
  private var draft: Binding<String> {
    Binding(get: { talk.text }, set: { edited in
      // only a real edit takes the refusal away: the field also writes its text back when it is disabled for a send
      // or loses the keyboard, and that is not the golfer changing their words
      guard edited != talk.text else { return }
      talk.text = edited
      talk.sendError = nil
    })
  }

  private var sendDisabled: Bool {
    busy || talk.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || talk.text.count > 500
  }

  // MARK: - Reads and writes

  private func load(focus: UUID? = nil) async {
    let account = session.session?.user.id
    generation += 1
    let mine = generation
    loading = true
    defer { if mine == generation { loading = false } }
    do {
      let target = focus ?? focusComment
      let answer = try await service.thread(roundId, focus: target)
      // a read asked for after this one is the answer that counts (the one a send makes when its
      // comment lands, a pull on Home): this one began before that comment and would put the thread
      // back as it was, the comment gone and the door's count with it
      guard mine == generation else { return }
      guard account == session.session?.user.id else { thread = nil; return }
      thread = answer; error = nil
      if answer.visible { talk.summarize(count: answer.count, newest: answer.comments.last) }
      await Task.yield()
      onLoaded(target.flatMap { id in answer.comments.contains { $0.id == id } ? id.uuidString : nil })
      // an empty conversation opened from its door is opened to be written in: once, so a thread
      // that reloads, or scrolls back into view, does not bring the keyboard up again
      if talk.takeAutoFocus(wanted: autoFocus, visible: answer.visible, canComment: answer.canComment, empty: answer.comments.isEmpty) {
        focusDraft = true
      }
    } catch {
      // a read that was cancelled (its owner reloaded, the account changed) or overtaken says nothing
      guard mine == generation, !Task.isCancelled else { return }
      if (error as? RpcError)?.isMissingFunction == true { unavailable = true }
      else { self.error = HumanError.text(error, prefix: TalkCopy.readFailed) }
    }
  }

  /// a write of this view landed: the other views of the conversation read it too
  private func wrote() {
    talk.wrote()
    seen = talk.changes
  }

  private func send() async {
    guard !busy else { return }
    let words = talk.text, parent = talk.replying?.id
    let intent = talk.pending?.forRetry(body: words, parentId: parent) ?? CommentIntent(body: words, parentId: parent)
    talk.pending = intent; talk.sendError = nil; busy = true; error = nil
    defer { busy = false }
    do {
      let sent = try await service.send(roundId, intent: intent)
      talk.text = ""; talk.replying = nil; talk.pending = nil; composing = false
      wrote()
      await load(focus: sent)
    } catch {
      // kept with the draft, not with this view: the view may be folded by the time the answer comes
      talk.sendError = HumanError.text(error, prefix: TalkCopy.failed)
    }
  }

  private func changeNotify(_ choice: TalkCopy.Notify) {
    Task {
      busy = true
      defer { busy = false }
      do { try await service.state(roundId, choice.state); wrote(); await load() }
      catch { self.error = HumanError.text(error, prefix: TalkCopy.stateFailed) }
    }
  }

  private func remove(_ comment: SocialComment) async {
    do { try await service.remove(comment.id); wrote(); await load() }
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

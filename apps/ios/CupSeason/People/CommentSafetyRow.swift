import SwiftUI
import CSDesign
import CupSeasonKit

struct CommentSafetyRow: View {
  @Environment(\.cs) private var cs
  let name: String
  let text: String
  let author: UUID?
  let target: CommentSafety?
  let refresh: () async -> Void
  @State private var safety = false
  var body: some View {
    HStack(alignment: .top, spacing: CSTokens.Space.s2) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        if let author {
          NavigationLink { PersonPage(profileId: author) } label: {
            Text(name).csType(.name).foregroundStyle(cs.ink).frame(minHeight: 44, alignment: .leading)
          }.buttonStyle(.plain).accessibilityLabel("Open \(name)’s golfer page")
        } else { Text(name).csType(.name).foregroundStyle(cs.ink) }
        Text(text).csType(.bodyS).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 0)
      if target != nil {
        Button { safety = true } label: {
          CSGlyph(.more, size: .inline).foregroundStyle(cs.mut).frame(width: 44, height: 44).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel("More actions for \(name)’s comment")
      }
    }
    .sheet(isPresented: $safety) {
      if let target { CommentSafetySheet(target: target, refresh: refresh) }
    }
  }
}

struct CommentSafetySheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(SessionStore.self) private var session
  let target: CommentSafety
  var refresh: () async -> Void = {}
  // Injected only by the local fixture; normal actions always use the same RPCs.
  var reportAction: ((String) async throws -> Void)? = nil
  var blockAction: (() async throws -> Void)? = nil
  @State private var reason = ""
  @State private var busy = false
  @State private var error: String?
  @State private var reported = false
  private var first: String { target.name.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? "this golfer" }
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          Text("BLOCK · REPORT").csEyebrow()
          if reported {
            Text("Reported — thanks. We’ll take a look.").csType(.body).accessibilityIdentifier("comment-reported")
          } else {
            Text("Your note goes to the founder desk with the comment.").csType(.bodyS).foregroundStyle(cs.mut)
            TextField("Say what’s wrong…", text: $reason, axis: .vertical).csType(.body)
              .onChange(of: reason) { _, value in reason = String(value.prefix(500)) }
              .accessibilityIdentifier("comment-report-reason")
            Button("Send the report") { Task { await report() } }.buttonStyle(.csPrimary(busy: busy))
              .accessibilityIdentifier("comment-report-send")
          }
          if let author = target.author, author != session.session?.user.id {
            CSRule()
            Text(SafetyCopy.muteSub).csType(.bodyS).foregroundStyle(cs.mut)
            Button("Block \(first)") { Task { await block(author) } }.buttonStyle(.csSecondary())
              .accessibilityIdentifier("comment-block")
          }
          if let error { Text(error).csType(.bodyS).foregroundStyle(cs.neg) }
        }.padding(CSTokens.Space.gutter)
      }.background(cs.bg0)
        .navigationTitle("\(first)’s comment").navigationBarTitleDisplayMode(.inline)
        .csCloseButton { dismiss() }
    }.disabled(busy).interactiveDismissDisabled(busy).presentationDetents([.large])
  }
  @MainActor private func report() async {
    guard !busy else { return }
    busy = true; error = nil; defer { busy = false }
    do {
      if let reportAction { try await reportAction(reason) }
      else { try await SupabaseService.shared.call(target.report(reason: reason)) }
      reported = true
    } catch { self.error = HumanError.text(error, prefix: "Could not send the report.") }
  }
  @MainActor private func block(_ author: UUID) async {
    guard !busy else { return }
    busy = true; error = nil; defer { busy = false }
    do {
      if let blockAction { try await blockAction() }
      else { try await SupabaseService.shared.call(Rpc.set_mute(p_profile: author, p_on: true)) }
      await refresh(); dismiss()
    } catch { self.error = HumanError.text(error, prefix: "Could not change that.") }
  }
}

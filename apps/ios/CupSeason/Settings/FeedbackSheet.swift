// Cup Season — "Tell us how it's going" (index.html 15347–15393) and the
// founder's field note / desk (15395–15457). The desk is owner-only; the
// server enforces — the phone only decides whether to show the door.

import SwiftUI
import CSDesign
import CupSeasonKit

struct FeedbackSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(SessionStore.self) private var store
  let screen: String
  let leagueId: UUID?
  let leagueName: String?
  @State private var category = ""
  @State private var body_ = ""
  @State private var busy = false
  private let repo = ProfileRepository()

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Text("What helped, what confused you, what you would change").csEyebrow()
        FlowRow {
          ForEach([("confusing", "Confusing"), ("friction", "Friction"), ("idea", "Idea"), ("bug", "Bug")], id: \.0) { key, title in
            let on = category == key
            Button { category = on ? "" : key } label: {
              Text(title).font(CSFont.monoMediumBody).foregroundStyle(on ? cs.brand : cs.ink)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(on ? cs.brand : cs.line2, lineWidth: 1))
            }
            .buttonStyle(.plain)
          }
        }
        TextEditor(text: $body_)
          .font(CSFont.body).foregroundStyle(cs.ink).scrollContentBackground(.hidden)
          .frame(minHeight: 120)
          .padding(10)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .overlay(alignment: .topLeading) {
            if body_.isEmpty {
              Text("Where did the app get in your way? Even a half-formed thought helps.")
                .font(CSFont.body).foregroundStyle(cs.dimText).padding(16).allowsHitTesting(false)
            }
          }
        CSButton("Send", busy: busy) { Task { await send() } }
        Text("Goes straight to Jerecho. We attach which screen you are on so we can find it fast.")
          .font(CSFont.footnote).foregroundStyle(cs.dimText)
        Spacer()
      }
      .padding(20)
      .background(cs.bg0)
      .navigationTitle("Tell us how it's going")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
    }
  }

  private func send() async {
    let text = body_.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { toast.show("Add a line first — anything helps"); return }
    busy = true
    defer { busy = false }
    let ctx: [String: JSONValue] = [
      "view": .string(screen),
      "version": .string("ios-build-\(store.build)"),
      "league_id": leagueId.map { .string($0.uuidString) } ?? .null,
      "league_name": leagueName.map { .string($0) } ?? .null,
      "demo": .bool(false),
      "path": .string("app"),
      "ua": .string("CupSeason iOS \(UIDevice.current.systemVersion) \(UIDevice.current.model)"),
    ]
    do {
      try await repo.submitFeedback(category: category.isEmpty ? "other" : category, body: text, context: ctx)
      dismiss()
      toast.show("Sent — thank you. This is how the app gets better.")
    } catch {
      toast.show(AuthRules.human(error, fallback: "Could not send."))
    }
  }
}

struct FounderNoteSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @State private var body_ = ""
  @State private var busy = false
  private let repo = ProfileRepository()

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Text("Straight into the feedback ledger, tagged founder").csEyebrow()
        TextEditor(text: $body_)
          .font(CSFont.body).foregroundStyle(cs.ink).scrollContentBackground(.hidden)
          .frame(minHeight: 120).padding(10)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .overlay(alignment: .topLeading) {
            if body_.isEmpty { Text("What you noticed, before it slips").font(CSFont.body).foregroundStyle(cs.dimText).padding(16).allowsHitTesting(false) }
          }
        CSButton("Save note", busy: busy) {
          let t = body_.trimmingCharacters(in: .whitespacesAndNewlines)
          guard !t.isEmpty else { toast.show("Write the note first"); return }
          busy = true
          Task {
            defer { busy = false }
            do { try await repo.founderNote(t); dismiss(); toast.show("Noted.") }
            catch { toast.show(AuthRules.human(error, fallback: "Could not save.")) }
          }
        }
        Spacer()
      }
      .padding(20).background(cs.bg0)
      .navigationTitle("Field note").navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
    }
  }
}

struct FounderDeskSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @State private var desk: JSONValue?
  @State private var error: String?
  private let repo = ProfileRepository()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text("Signups · activity · errors · feedback").csEyebrow()
          if let error {
            Text(error).font(CSFont.footnote).foregroundStyle(cs.mut)
          } else if let d = desk {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
              CSStat("Golfers", value: n(d["profiles_total"]))
              CSStat("New · 7d", value: n(d["profiles_new_7d"]))
              CSStat("Rounds", value: n(d["rounds_total"]))
              CSStat("Rounds · 7d", value: n(d["rounds_7d"]))
              CSStat("Leagues", value: n(d["leagues"]))
              CSStat("Events", value: n(d["events"]))
              CSStat("Live now", value: n(d["live_open"]))
              CSStat("Posts · 7d", value: n(d["posts_7d"]))
            }
            section("Newest golfer cards", d["newest"]?.array) { p in
              row(p["marker"]?.string != nil ? "⛳" : "👤", p["name"]?.string ?? "?",
                  "\(p["city"]?.string ?? "—") · \(when(p["at"]))\(p["marker"]?.string != nil ? "" : " · card not finished")")
            }
            section("Client events · last 30", d["client_events"]?.array) { e in
              let ev = e["event"]?.string ?? ""
              let props = e["props"].flatMap { v -> String? in
                guard case .object(let o) = v, !o.isEmpty, let data = try? JSONEncoder().encode(v) else { return nil }
                return String(decoding: data.prefix(120), as: UTF8.self)
              }
              row(ev.range(of: "error|reject", options: [.regularExpression, .caseInsensitive]) != nil ? "🐞" : "·", ev,
                  "\(e["who"]?.string ?? "?") · \(when(e["at"]))\(props.map { " · \($0)" } ?? "")")
            }
            section("Feedback ledger · last 20", d["feedback"]?.array) { f in
              let cat = f["cat"]?.string ?? ""
              row(cat == "founder" ? "✏️" : cat == "bug" ? "🐞" : "💬", String((f["body"]?.string ?? "").prefix(200)),
                  "\(cat) · \(f["who"]?.string ?? "?") · \(when(f["at"]))")
            }
            if let reports = d["reports"]?.array, !reports.isEmpty {
              section("Content reports · last 15", reports) { r in
                row(r["resolved"]?.bool == true ? "✓" : "🚩",
                    "\(r["kind"]?.string == "profile_photo" ? "Photo" : "Post") — \(r["target"]?.string ?? "?")",
                    "\(String((r["reason"]?.string ?? "").prefix(120))) · by \(r["who"]?.string ?? "?") · \(when(r["at"]))")
              }
            }
          } else {
            Text("Pulling the numbers…").font(CSFont.footnote).foregroundStyle(cs.mut)
          }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .navigationTitle("Founder's desk").navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
      .task {
        do { desk = try await repo.founderDesk() }
        catch { self.error = AuthRules.human(error, fallback: "The desk is not deployed yet — push the founder_desk migration.") }
      }
    }
  }

  private func n(_ v: JSONValue?) -> String { v?.int.map(String.init) ?? "0" }

  /// `fdWhen` — "12m ago", "3h ago", "2d ago".
  private func when(_ v: JSONValue?) -> String {
    guard let s = v?.string else { return "" }
    let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let f2 = ISO8601DateFormatter()
    guard let d = f.date(from: s) ?? f2.date(from: s) else { return "" }
    let mins = Int((Date().timeIntervalSince(d) / 60).rounded())
    if mins < 60 { return "\(mins)m ago" }
    if mins < 60 * 24 { return "\(Int((Double(mins) / 60).rounded()))h ago" }
    return "\(Int((Double(mins) / 1440).rounded()))d ago"
  }

  @ViewBuilder
  private func section(_ title: String, _ list: [JSONValue]?, @ViewBuilder _ item: @escaping (JSONValue) -> some View) -> some View {
    Text(title).csEyebrow().padding(.top, 10)
    if let list, !list.isEmpty {
      ForEach(Array(list.enumerated()), id: \.offset) { _, v in item(v) }
    } else {
      Text("Nothing yet.").font(CSFont.footnote).foregroundStyle(cs.dimText)
    }
  }

  private func row(_ icon: String, _ title: String, _ sub: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Text(icon).font(.system(size: 14)).frame(width: 22)
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(CSFont.subhead).foregroundStyle(cs.ink)
        Text(sub).font(CSFont.footnote).foregroundStyle(cs.mut)
      }
    }
    .padding(.vertical, 6)
  }
}

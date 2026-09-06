// Cup Season — the round as an object (`openRoundSheet` / `renderRoundSheet`
// 16733–16837; `loadRoundWeather` 16839; `openRetagSheet` 16852). Course
// info + weather + who's-in + a mini board. Everything degrades gracefully: a
// round with no linked course shows the typed name (never blank), and
// weather simply hides when there's no location or it's out of range.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ScheduledRoundSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var vm: RoundSheetModel
  @State private var toasts: CSToastCenter
  @State private var retag: RetagRequest? = nil
  @State private var card: CourseSheetRef? = nil
  let links: CSLinks
  let leagueId: UUID?

  init(roundId: UUID, fallback: ScheduledRound? = nil, leagueId: UUID? = nil, links: CSLinks = CSLinks()) {
    self.links = links
    self.leagueId = leagueId
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: RoundSheetModel(id: roundId, fallback: fallback, toasts: t))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        if let d = vm.detail { sheet(d) }
        else if vm.failed { CSFine("Couldn’t load that round").padding(20) }
        else { VStack(alignment: .leading, spacing: 10) { CSSheetHeader(title: "Round", sub: "Loading…"); CSFine("Loading the round…") }.padding(20) }
      }
      .background(cs.bg0)
      .scrollDismissesKeyboard(.interactively)
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(cs.brand) } }
      .task { await vm.load() }
      .csToasts(toasts)
      .sheet(item: $retag, onDismiss: { Task { await vm.load() } }) { r in RetagSheet(request: r, leagueId: leagueId) }
      .sheet(item: $card) { c in CourseCardSheet(courseId: c.id, label: c.label) }
    }
    .presentationDragIndicator(.visible)
  }

  private func sheet(_ d: RoundDetail) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      CSSheetHeader(title: d.title, sub: TeeTime.format(d.teeTime).isEmpty ? "On the schedule" : TeeTime.chip(d.teeTime))

      // D261 / R-N · L-32 · the read failed and this is the row we already had.
      // It is said once, at the top, before any fact it qualifies.
      if vm.stale {
        Text("Could not reach the server. This is the plan as your phone has it — who is in and the comments may have moved.")
          .font(CSFont.footnote).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }

      // course header — cache name if linked, else the typed label, else a word. NEVER blank.
      VStack(alignment: .leading, spacing: 3) {
        Text(d.courseName).font(CSFont.sentenceBold).foregroundStyle(cs.ink)
        if let c = d.course, !c.meta.isEmpty { Text(c.meta).font(CSFont.monoSmall).foregroundStyle(cs.mut) }
        if let c = d.course, !c.place.isEmpty { Text(c.place).font(CSFont.footnote).foregroundStyle(cs.dimText) }
        // D261 / R-N · the door the escalation asked for: the tees, the ratings
        // and slopes, and the card — from the phone, so it opens on a plane.
        // Offered only for a course this phone has actually kept, because a
        // door that opens on nothing is the one thing not permitted (L-32).
        if vm.kept, let id = d.courseId {
          Button("See the tees and the card") { card = CourseSheetRef(id: id, label: d.courseName) }
            .font(CSFont.button).foregroundStyle(cs.brand).frame(minHeight: 44)
        }
      }
      HStack(spacing: 8) {
        chip(TeeTime.chip(d.teeTime), fg: cs.ink, bg: cs.bg2, border: cs.line)
        if let w = vm.weather { chip(w.line, fg: cs.mut, bg: cs.gold.opacity(0.12), border: cs.gold.opacity(0.32)) }
      }
      // R-K / D256 · WHAT THIS ROUND IS WORTH. The server sends the cap and
      // the month's counters (`round_detail.worth`); the sentence is produced
      // once, in `RoundWorth`, and rendered by both clients. The subject is
      // "This round" and not the day and the course, because the header above
      // already carries both and a card that says one fact twice is DEF-2
      // (L-34). A database without the migration sends no `worth` key, and
      // nothing renders in its place (L-44).
      ForEach(Array(d.worthLines.enumerated()), id: \.offset) { _, worth in
        Text(worth).font(CSFont.footnote).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      if let n = d.note, !n.isEmpty { Text("“\(n)”").font(CSFont.sentence).italic().foregroundStyle(cs.ink) }
      if !d.mine, let r = RivalryTag.of(d.profileId, rivals: vm.rivals) {
        (Text("◇ ") + Text(r.text).foregroundStyle(cs.gold) + Text(" · ") + Text("one more round.").italic())
          .font(CSFont.footnote).foregroundStyle(cs.mut)
      }

      HStack { Text("Who’s in").csEyebrow(); Text("\(d.inCount) in").font(CSFont.label).foregroundStyle(cs.pos) }.padding(.top, 6)
      if d.rsvp.isEmpty {
        CSFine("Just you so far — tag your group.")
      } else {
        ForEach(d.rsvp) { r in
          CSCheckRow(marker: r.marker, title: r.profileId == d.profileId ? Text(r.name) + Text("  HOST").font(CSFont.label).foregroundStyle(cs.gold) : Text(r.name), sub: nil) {
            pill(r.label, status: r.status)
          }
          .contentShape(Rectangle())
          .onTapGesture { if let p = r.profileId { links.openTourCard?(p) } }
        }
      }
      // D69: RSVP is for the invited — the host or a tagged player
      if d.canRsvp {
        HStack(spacing: 8) {
          rsvpButton("I’m in", "in", on: cs.pos, ink: cs.bg0)
          rsvpButton("Maybe", "maybe", on: cs.gold, ink: Color(hex: 0x3A2C07))
          rsvpButton("Can’t", "out", on: cs.bg2, ink: cs.ink)
        }
      } else if !d.mine {
        // IOS-032 · the dead end, closed. A golfer who sees a buddy's plan and
        // wants in had NOWHERE to go: the row rendered and every control was
        // absent, because D69 says a tee sheet is the host's. "Ask for a seat"
        // is a REQUEST — one `rsvp` nudge to the host (R16), once per person
        // per plan — and it writes NOTHING to the tee sheet, so D69 stands
        // exactly where it stood.
        VStack(alignment: .leading, spacing: 6) {
          if vm.asked {
            Text("ASKED — IT’S WITH THEM").font(CSFont.label).tracking(0.9).foregroundStyle(cs.pos)
              .frame(minHeight: 32)
          } else {
            CSMini("Ask for a seat", busy: vm.asking) { Task { await vm.askForASeat() } }
          }
          CSFine("It sends \(d.hostName) a note. Only they can add you to the group.")
        }
        .padding(.top, 4)
      }

      Text("On the board").csEyebrow().padding(.top, 6)
      if d.comments.isEmpty {
        CSFine("No messages yet — kick it off.")
      } else {
        ForEach(d.comments) { c in
          HStack(alignment: .top, spacing: 10) {
            CSFace(marker: c.marker, size: 28)
            (Text(c.name).bold().foregroundStyle(cs.ink) + Text(" \(c.body)").foregroundStyle(cs.mut)).font(CSFont.subhead)
            Spacer(minLength: 0)
          }
        }
      }
      HStack(spacing: 8) {
        CSField("Say something to the group…", text: $vm.draft, font: CSFont.body)
          .onChange(of: vm.draft) { _, n in if n.count > 500 { vm.draft = String(n.prefix(500)) } }
          .onSubmit { Task { await vm.send() } }
        CSMini("Send", busy: vm.sending) { Task { await vm.send() } }
      }

      if d.mine {
        // D253 · THE PLAN LINK. Three screens promised a weekend invite link
        // that no read and no write ever minted; this is the one that mints
        // it. It is the host's control alone — the link is the only thing in
        // the product that can seat a stranger, and D69's rule that a tee
        // sheet is the host's is what bounds it.
        PlanInviteLink(roundId: d.id, course: d.courseLabel, day: d.playOn)
          .padding(.top, 8)
        HStack(spacing: 8) {
          CSMini("Edit group") {
            retag = RetagRequest(roundId: d.id, iso: d.playOn ?? CSDate.today(), courseLabel: d.courseLabel,
                                 tagged: d.rsvp.compactMap { $0.profileId }.filter { $0 != d.profileId })
          }
          CSArmedButton(label: "Cancel round", armedLabel: "Sure? Cancel it", busy: vm.scratching) {
            Task { if await vm.scratch() { dismiss() } }
          }
        }
        .padding(.top, 8)
      }
    }
    .padding(20)
  }

  private func chip(_ t: String, fg: Color, bg: Color, border: Color) -> some View {
    Text(t).font(CSFont.monoMediumBody).foregroundStyle(fg).padding(.horizontal, 10).padding(.vertical, 6)
      .background(bg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(border, lineWidth: 1))
  }

  private func pill(_ t: String, status: String?) -> some View {
    let tone: Color = status == "in" ? cs.pos : status == "maybe" ? cs.gold : cs.dimText
    return Text(t).font(CSFont.label).tracking(0.6).textCase(.uppercase).foregroundStyle(tone)
      .padding(.horizontal, 8).padding(.vertical, 5)
      .background((status == "in" || status == "maybe") ? tone.opacity(0.14) : cs.bg2, in: Capsule())
  }

  private func rsvpButton(_ label: String, _ status: String, on: Color, ink: Color) -> some View {
    let selected = vm.detail?.myRsvp == status
    return Button {
      Task { await vm.rsvp(status) }
    } label: {
      Text(label).font(CSFont.button)
        .foregroundStyle(selected ? ink : cs.ink)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(selected ? on : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(selected ? (status == "out" ? cs.line2 : on) : cs.line, lineWidth: 1))
    }
    .buttonStyle(.plain)
    .disabled(vm.rsvping)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}

@MainActor
@Observable
final class RoundSheetModel {
  let id: UUID
  var detail: RoundDetail?
  var failed = false
  /// D261 · the detail read did not answer and what is on screen is the row we
  /// already had. Never presented as live.
  var stale = false
  /// D261 · this phone holds a course book for this round's course.
  var kept = false
  var weather: Weather?
  var rivals: [Rpc.my_rivalries.Row] = []
  var draft = ""
  var sending = false
  var rsvping = false
  var scratching = false
  /// IOS-032 · "Ask for a seat" — a REQUEST to the host (R16), never a write
  /// to the tee sheet. `asked` is the local echo of the server's own state.
  var asking = false
  var asked = false
  private let fallback: ScheduledRound?
  private let toasts: CSToastCenter
  private let sched = ScheduleService()
  private let people = PeopleService()

  init(id: UUID, fallback: ScheduledRound?, toasts: CSToastCenter) { self.id = id; self.fallback = fallback; self.toasts = toasts }

  /// One nudge, once. The server enforces the same rule, so a second tap on
  /// another device is not a second ping either (L-20/L-21).
  func askForASeat() async {
    asking = true
    defer { asking = false }
    do {
      let state = try await people.askForASeat(id)
      asked = true
      toasts.show(state == "already_asked" ? "Already asked — it’s with them."
                : state == "already_in" ? "You’re already in that group."
                : "Asked. It’s up to them now.")
    } catch {
      toasts.show(HumanError.text(error, prefix: "Couldn’t send that."))
    }
  }

  func load() async {
    do { detail = try await sched.detail(id); stale = false }
    catch {
      // deploy-skew OR no signal: `round_detail` is not live yet, or nothing is.
      // Fall back to the schedule row we were handed and SAY the read failed —
      // a screen that quietly draws a thinner version of itself is the lie
      // L-32 forbids (D261).
      if let f = fallback { detail = RoundDetail(fallback: f); stale = true }
      else { failed = true; toasts.show("Couldn’t load that round"); return }
    }
    // D261 · does the phone hold this course? The door below is drawn only if
    // it does, so it can never open on nothing.
    kept = await CourseBookStore().book(detail?.courseId).book != nil
    rivals = await RivalsCache.shared.rivals()
    // weather rides in async; no location or out of range → the chip just stays hidden
    if let d = detail, let c = d.course, let lat = c.lat, let lon = c.lon, let on = d.playOn {
      weather = await sched.weather(lat: lat, lon: lon, date: on, courseId: d.courseId)
    } else { weather = nil }
  }

  func rsvp(_ status: String) async {
    rsvping = true; defer { rsvping = false }
    do { try await sched.rsvp(id, status: status); CSHaptic.selection(); await load() }
    catch { toasts.show(HumanError.text(error, prefix: "RSVP did not save.")) }
  }

  func send() async {
    let v = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !v.isEmpty, !sending else { return }
    sending = true; defer { sending = false }
    do { try await sched.comment(id, body: v); draft = ""; await load() }
    catch { toasts.show(HumanError.text(error, prefix: "Could not post.")) }
  }

  func scratch() async -> Bool {
    scratching = true; defer { scratching = false }
    do { try await sched.scratch(id); toasts.show("Round scratched"); return true }
    catch { toasts.show(HumanError.text(error, prefix: "Scratch failed.")); return false }
  }
}

struct CourseSheetRef: Identifiable, Equatable { let id: String; let label: String }

// MARK: - Tag your group (`openRetagSheet` 16852)

struct RetagRequest: Identifiable {
  let roundId: UUID
  let iso: String
  let courseLabel: String?
  let tagged: [UUID]
  var id: UUID { roundId }
}

struct RetagSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var toasts = CSToastCenter()
  @State private var candidates: [TagCandidate] = []
  @State private var loaded = false
  @State private var tagged = Set<UUID>()
  @State private var busy = false
  let request: RetagRequest
  let leagueId: UUID?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        CSSheetHeader(title: "Tag your group", sub: ScheduleDates.long(request.iso) + (request.courseLabel.map { " · \($0.uppercased())" } ?? ""))
        if loaded {
          if candidates.isEmpty { CSFine("No one to tag yet. Add buddies from the You tab.") }
          else { TagChips(candidates: candidates, tagged: $tagged, toasts: toasts) }
          CSFine("\(tagged.count) tagged")
        }
        CSButton("Save the group", busy: busy) { Task { await save() } }.padding(.top, 6)
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .csToasts(toasts)
    .task {
      candidates = await ScheduleService().tagCandidates(league: leagueId)
      let ids = Set(candidates.map(\.id))
      tagged = Set(request.tagged.filter { ids.contains($0) })
      loaded = true
    }
  }

  private func save() async {
    busy = true; defer { busy = false }
    do { try await ScheduleService().retag(request.roundId, tagged: Array(tagged)); toasts.show("Group updated"); dismiss() }
    catch { toasts.show(HumanError.text(error)) }
  }
}

#Preview("Round") {
  ScheduledRoundSheet(roundId: UUID()).csTheme()
}

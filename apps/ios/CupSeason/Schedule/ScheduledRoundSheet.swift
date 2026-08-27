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
    }
    .presentationDragIndicator(.visible)
  }

  private func sheet(_ d: RoundDetail) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      CSSheetHeader(title: d.title, sub: TeeTime.format(d.teeTime).isEmpty ? "On the tee sheet" : TeeTime.chip(d.teeTime))

      // course header — cache name if linked, else the typed label, else a word. NEVER blank.
      VStack(alignment: .leading, spacing: 3) {
        Text(d.courseName).font(CSFont.sentenceBold).foregroundStyle(cs.ink)
        if let c = d.course, !c.meta.isEmpty { Text(c.meta).font(CSFont.monoSmall).foregroundStyle(cs.mut) }
        if let c = d.course, !c.place.isEmpty { Text(c.place).font(CSFont.footnote).foregroundStyle(cs.dimText) }
      }
      HStack(spacing: 8) {
        chip(TeeTime.chip(d.teeTime), fg: cs.ink, bg: cs.bg2, border: cs.line)
        if let w = vm.weather { chip(w.line, fg: cs.mut, bg: cs.gold.opacity(0.12), border: cs.gold.opacity(0.32)) }
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
  var weather: Weather?
  var rivals: [Rpc.my_rivalries.Row] = []
  var draft = ""
  var sending = false
  var rsvping = false
  var scratching = false
  private let fallback: ScheduledRound?
  private let toasts: CSToastCenter
  private let sched = ScheduleService()

  init(id: UUID, fallback: ScheduledRound?, toasts: CSToastCenter) { self.id = id; self.fallback = fallback; self.toasts = toasts }

  func load() async {
    do { detail = try await sched.detail(id) }
    catch {
      // deploy-skew: round_detail not live yet — fall back to the schedule row
      if let f = fallback { detail = RoundDetail(fallback: f) } else { failed = true; toasts.show("Couldn’t load that round"); return }
    }
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

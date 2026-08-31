// Cup Season — "Put a round on the tee sheet" (`openDeclareSheet` 16670–16724;
// `attachCourseSearch` 6729; `bindTagChips` 16642). One sheet, two doors:
// the calendar and the ⊕ Plan card. Works league-less.

import SwiftUI
import CSDesign
import CupSeasonKit

/// What a door hands the sheet: a day, or a crew member's plan ("I'm in").
struct DeclarePrefill: Identifiable {
  var iso: String? = nil
  var course: String = ""
  var tee: String? = nil
  var courseId: String? = nil
  var tagPids: [UUID] = []
  var hostName: String? = nil
  var id: String { "\(iso ?? "")·\(hostName ?? "")·\(course)" }
}

struct DeclareRoundSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var vm: DeclareModel
  @State private var toasts: CSToastCenter
  let onDeclared: (UUID) -> Void

  init(prefill: DeclarePrefill? = nil, leagueId: UUID? = nil, onDeclared: @escaping (UUID) -> Void) {
    self.onDeclared = onDeclared
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: DeclareModel(prefill: prefill ?? DeclarePrefill(), leagueId: leagueId, toasts: t))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          CSSheetHeader(title: vm.hostName != nil ? "Get in on it" : "Put a round on the tee sheet",
                        sub: vm.hostName != nil ? "YOUR ROUND POSTS AND SCORES ON ITS OWN — YOU BOTH SHOW ON THE DAY" : "BUDDIES & LEAGUE MATES SEE IT THE MOMENT YOU POST")
          if let h = vm.hostName { CSFine("You're in — declaring your own round alongside \(h).", tone: cs.gold) }

          HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
              Text("Day").csEyebrow()
              DatePicker("Day", selection: $vm.day, displayedComponents: .date).labelsHidden().tint(cs.brand)
            }
            VStack(alignment: .leading, spacing: 6) {
              Text("Tee time · optional").csEyebrow(cs.gold)
              HStack(spacing: 6) {
                if vm.teeOn {
                  DatePicker("Tee time", selection: $vm.tee, displayedComponents: .hourAndMinute).labelsHidden().tint(cs.brand)
                  CSMini("", systemImage: "xmark") { vm.teeOn = false }.accessibilityLabel("Clear tee time")
                } else {
                  CSMini("Set a tee time") { vm.teeOn = true }
                }
              }
            }
          }

          Text("Course").csEyebrow().padding(.top, 4)
          CourseSearchField(text: $vm.course, courseId: $vm.courseId, toasts: toasts)

          Text("Note · optional").csEyebrow().padding(.top, 4)
          CSField("buddies trip, looking for a 4th", text: $vm.note, font: CSFont.body)
            .onChange(of: vm.note) { _, n in if n.count > 140 { vm.note = String(n.prefix(140)) } }

          if vm.candidatesLoaded {
            if vm.candidates.isEmpty {
              CSFine("No one to tag yet. Add buddies from the You tab, or invite the league.").padding(.top, 6)
            } else {
              Text("Tag your group · \(vm.tagged.count) tagged").csEyebrow().padding(.top, 6)
              TagChips(candidates: vm.candidates, tagged: $vm.tagged, toasts: toasts)
            }
          }

          CSButton(vm.hostName != nil ? "I'm in" : "On the tee sheet", busy: vm.busy) {
            Task { if let id = await vm.go() { onDeclared(id); dismiss() } }
          }
          .padding(.top, 6)
          CSFine("Posts to your leagues' boards: tagged golfers are named. Scratch it any time from the calendar.")
        }
        .padding(20)
      }
      .background(cs.bg0)
      .scrollDismissesKeyboard(.interactively)
      .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.foregroundStyle(cs.mut) } }
      .task { await vm.loadCandidates() }
      .csToasts(toasts)
    }
    .presentationDragIndicator(.visible)
  }
}

@MainActor
@Observable
final class DeclareModel {
  var day: Date
  var tee: Date
  var teeOn: Bool
  var course: String
  var courseId: String?
  var note = ""
  var tagged: Set<UUID>
  var candidates: [TagCandidate] = []
  var candidatesLoaded = false
  var busy = false
  let hostName: String?
  private let pendingTags: [UUID]
  private let leagueId: UUID?
  private let toasts: CSToastCenter
  private let sched = ScheduleService()

  init(prefill: DeclarePrefill, leagueId: UUID?, toasts: CSToastCenter) {
    let cal = ScheduleDates.gregorian
    let iso = prefill.iso.flatMap { $0.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil ? $0 : nil } ?? ScheduleDates.nextSaturday()
    day = CSDate.local(iso, calendar: cal) ?? Date()
    let tp = TeeTime.parts(prefill.tee)
    teeOn = tp != nil
    tee = cal.date(bySettingHour: tp?.hour ?? 7, minute: tp?.minute ?? 40, second: 0, of: Date()) ?? Date()
    course = prefill.course
    courseId = prefill.courseId
    hostName = prefill.hostName
    pendingTags = prefill.tagPids
    tagged = []
    self.leagueId = leagueId
    self.toasts = toasts
  }

  func loadCandidates() async {
    candidates = await sched.tagCandidates(league: leagueId)
    // "I'm in" seeds the host as a tag so both rounds cluster on the day
    let ids = Set(candidates.map(\.id))
    tagged = Set(pendingTags.filter { ids.contains($0) })
    candidatesLoaded = true
  }

  var teeValue: String? {
    guard teeOn else { return nil }
    let c = ScheduleDates.gregorian.dateComponents([.hour, .minute], from: tee)
    return TeeTime.hhmm(hour: c.hour ?? 0, minute: c.minute ?? 0)
  }

  func go() async -> UUID? {
    guard !busy else { return nil }
    busy = true; defer { busy = false }
    do {
      let id = try await sched.declare(playOn: CSDate.iso(day, calendar: ScheduleDates.gregorian), course: course, note: note,
                                       tagged: Array(tagged), tee: teeValue, courseId: courseId)
      CSHaptic.success()
      toasts.show(hostName != nil ? "You're in — it's on both boards"
                  : tagged.isEmpty ? "On the tee sheet: the boards know" : "On the tee sheet: your group is named on the boards")
      return id
    } catch { toasts.show(HumanError.text(error)); return nil }
  }
}

// MARK: - Tag chips (`tagChipHtml` / `bindTagChips`)

struct TagChips: View {
  @Environment(\.cs) private var cs
  let candidates: [TagCandidate]
  @Binding var tagged: Set<UUID>
  let toasts: CSToastCenter

  var body: some View {
    FlowLayout(spacing: 6) {
      ForEach(candidates) { c in
        let on = tagged.contains(c.id)
        Button {
          if on { tagged.remove(c.id) }
          else if tagged.count >= TagRules.cap { toasts.show(TagRules.capToast); return }
          else { tagged.insert(c.id) }
          CSHaptic.selection()
        } label: {
          HStack(spacing: 6) {
            CSMarkerView(key: c.marker, size: 16).foregroundStyle(on ? cs.pos : cs.ink)
            Text(c.name).font(CSFont.monoMediumBody).foregroundStyle(on ? cs.pos : cs.ink)
          }
          .padding(.horizontal, 12).frame(minHeight: 36)
          .background(cs.bg2, in: Capsule())
          .overlay(Capsule().stroke(on ? cs.pos : cs.line2, lineWidth: 1))
          .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
      }
    }
  }
}

/// Chips wrap like the web's inline buttons.
struct FlowLayout: Layout {
  var spacing: CGFloat = 6
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let w = proposal.width ?? 320
    var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
    for s in subviews {
      let sz = s.sizeThatFits(.unspecified)
      if x + sz.width > w, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
      x += sz.width + spacing; rowH = max(rowH, sz.height)
    }
    return CGSize(width: w, height: y + rowH)
  }
  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
    for s in subviews {
      let sz = s.sizeThatFits(.unspecified)
      if x + sz.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
      s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
      x += sz.width + spacing; rowH = max(rowH, sz.height)
    }
  }
}

// MARK: - Course search (cache first, then the API, merged; two stages)

struct CourseSearchField: View {
  @Environment(\.cs) private var cs
  @Binding var text: String
  @Binding var courseId: String?
  let toasts: CSToastCenter
  @State private var vm = CourseSearchModel()

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      CSField("Pebble Beach", text: $text, font: CSFont.body)
        .onChange(of: text) { _, q in
          // typing again after a pick unstamps the course id (the label no longer matches the row)
          if vm.pickedLabel != q { courseId = nil; vm.pickedLabel = nil }
          vm.queue(q)
        }
      switch vm.stage {
      case .hidden: EmptyView()
      case .courses:
        dropdown {
          if vm.courses.isEmpty {
            Text("No match — type the course, rating and slope by hand.").font(CSFont.footnote).foregroundStyle(cs.mut).padding(12)
          } else {
            ForEach(vm.courses) { c in
              ddRow(c.label, c.subline) { text = c.label; vm.pickedLabel = c.label; courseId = c.id; vm.showTees(c) }
            }
          }
        }
      case .tees(let c):
        dropdown {
          ddRow("‹ Back to courses", nil) { vm.stage = .courses }
          if c.tees.isEmpty {
            Text("No rated tees listed — type the rating and slope by hand.").font(CSFont.footnote).foregroundStyle(cs.mut).padding(12)
          } else {
            ForEach(c.tees) { t in
              ddRow(t.title, t.subtitle) {
                text = c.label + (t.tee_name.map { " · \($0)" } ?? "")
                vm.pickedLabel = text
                courseId = c.id
                vm.stage = .hidden
                toasts.show("Tees set — rating and slope filled")
                Task { await ScheduleService().cacheCourse(c.id) }
              }
            }
          }
        }
      }
    }
  }

  private func dropdown<C: View>(@ViewBuilder _ content: () -> C) -> some View {
    VStack(spacing: 0) { content() }
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
  }

  private func ddRow(_ b: String, _ s: String?, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 2) {
        Text(b).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        if let s { Text(s).font(CSFont.monoSmall).foregroundStyle(cs.mut) }
      }
      .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
      .padding(.horizontal, 12).padding(.vertical, 6)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

@MainActor
@Observable
final class CourseSearchModel {
  enum Stage { case hidden, courses, tees(CourseHit) }
  var stage: Stage = .hidden
  var courses: [CourseHit] = []
  var pickedLabel: String? = nil
  private var task: Task<Void, Never>?
  private var lastQ = ""
  private let sched = ScheduleService()

  func showTees(_ c: CourseHit) { stage = .tees(c) }

  /// 320 ms debounce, ≥3 chars (6814–6830).
  func queue(_ q: String) {
    task?.cancel()
    let q = q.trimmingCharacters(in: .whitespaces)
    lastQ = q
    // D172 · these are TWO different outcomes and merging them broke the tee
    // picker. Too short → hide the dropdown. Same query as the label we just
    // picked → do NOTHING, because that write came from the pick itself.
    //
    // Tapping a course row does `text = c.label`, and SwiftUI's .onChange is a
    // VALUE observer, so that programmatic write re-fires this very closure —
    // with q equal to pickedLabel. Merged into one guard, the else branch ran
    // and set `stage = .hidden`, wiping the `.tees(c)` stage the tap had just
    // set two statements earlier. The golfer got the course name in the field
    // and no tee list, which is exactly the report.
    //
    // The web never had this because a programmatic `input.value =` fires no
    // input event — index.html:7445 says so out loud. The port lost that
    // invariant, and the web's own two-branch shape (index.html:7531 hides on
    // a short query; :7532 RETURNS on a repeat) is restored here.
    guard q.count >= 3 else { stage = .hidden; courses = []; return }
    guard q != pickedLabel else { return }
    task = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(320))
      guard !Task.isCancelled, let self else { return }
      await self.run(q)
    }
  }

  private var inTees: Bool { if case .tees = stage { return true }; return false }

  private func run(_ q: String) async {
    let local = await sched.searchCache(q)
    // paint cached hits immediately — never yank the user out of the tee list, never let a stale response overwrite a newer query
    let fresh = { self.lastQ == q && !self.inTees }
    if !local.isEmpty, fresh() { courses = local; stage = .courses }
    do {
      let remote = try await sched.searchRemote(q)
      let merged = ScheduleService.merge(local: local, remote: remote)
      // show the list even when empty — the empty state IS the "type it by hand" row, so a no-match never looks like a dead field
      if fresh() { courses = merged; stage = .courses }
    } catch {
      // upstream down: cached hits stand; with nothing cached, still open the list so the manual-entry row answers (never silently .hidden)
      if fresh(), local.isEmpty { courses = []; stage = .courses }
    }
  }
}

#Preview("Declare") {
  DeclareRoundSheet(onDeclared: { _ in }).csTheme()
}

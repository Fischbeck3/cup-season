// Cup Season — `#playSetup` (index.html 2979–3037; `renderPlanBridge` 8349,
// `renderRoster` 8720, `renderCourt` 7268, `renderMatchPrev` 8660, the
// course-card engine 6900–6968, `openCardSheet` 9535).

import SwiftUI
import CSDesign
import CupSeasonKit

struct LiveSetupView: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.dynamicTypeSize) private var typeSize
  @Bindable var store: LiveRoundStore
  @State private var guestName = ""
  @State private var guestIdx = ""
  @State private var showCard = false
  @State private var showPicker = false
  @State private var stakeText = ""
  @State private var ratingText = ""
  @State private var slopeText = ""
  /// Counts tee-off taps — the trigger for the `.impact` (IOS-022 item 6).
  @State private var teeOffTaps = 0

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Set up the round").csEyebrow()
        if let sr = store.plan, !store.planDismissed { planBridge(sr) }
        courseCard
        foursomeCard
        gameCard
        nearbyCard
        CSButton("Tee off →", busy: store.busy) { teeOffTaps += 1; Task { await store.teeOff() } }
      }
      .padding(20)
    }
    // D168 · advertising now follows the APP, not this screen — it starts here
    // and in the tab shell whenever the app is foreground and the golfer has
    // opted in. Confining it to this one screen meant everybody had to be on
    // the same screen at the same time, which defeats the point: one person
    // builds the round, everyone else should just be asked. Leaving the screen
    // no longer stops it; backgrounding does (there is still no background
    // mode, and there must never be one).
    .onAppear { store.startNearby() }
    // D158 · someone on this tee wants you in their round. "Not me" is not a
    // decline of the golf — it is the honest answer when the name on the other
    // phone is not actually you.
    .alert("Join this round?", isPresented: Binding(get: { store.incoming != nil },
                                                    set: { if !$0 { store.answerIncoming(false) } })) {
      Button("Join") { store.answerIncoming(true) }
      Button("Not me", role: .cancel) { store.answerIncoming(false) }
    } message: {
      if let inv = store.incoming {
        Text("\(inv.name) wants you in a round at \(inv.course)\(inv.game.isEmpty ? "" : " · \(inv.game)").")
      }
    }
    .csFeedback(.teeOff, trigger: teeOffTaps)
    .scrollDismissesKeyboard(.interactively)
    .navigationTitle("Play now")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showCard) { LiveCardSheet(store: store) }
    .sheet(isPresented: $showPicker) { LiveRosterPickerSheet(store: store) }
    .onAppear {
      stakeText = store.state.stake > 0 ? LiveFmt.js(store.state.stake) : "0"
      ratingText = store.state.course.rating.map(LiveFmt.js) ?? ""
      slopeText = store.state.course.slope.map(String.init) ?? ""
    }
  }

  // MARK: plan bridge (8349–8375)

  private func planBridge(_ sr: ScheduledRound) -> some View {
    let withN = (sr.tagged_names ?? []).isEmpty ? "" : " · with " + (sr.tagged_names ?? []).joined(separator: " & ")
    return VStack(alignment: .leading, spacing: 4) {
      Text("On your tee sheet today\(sr.course_label.map { " · \($0)" } ?? "")").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
      Text("Load the course and your group into the tee sheet\(withN).").font(CSFont.footnote).foregroundStyle(cs.dimText)
      CSMini("Load it →") { store.loadPlan() }.padding(.top, 4)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.gold, lineWidth: 1))
  }

  // MARK: the course (2985–3003)

  private var courseCard: some View {
    CSCard {
      VStack(alignment: .leading, spacing: 10) {
        fieldLabel("Course")
        LiveCourseField(text: Binding(get: { store.state.course.label }, set: { v in
          if store.state.course.label != v { store.state.course.courseId = nil }
          store.state.course.label = v
        })) { course, tee in
          Task {
            await store.applyTee(course: course, tee: tee)
            ratingText = store.state.course.rating.map(LiveFmt.js) ?? ""
            slopeText = store.state.course.slope.map(String.init) ?? ""
            toast.show("Tees set — rating and slope filled")
          }
        }
        fieldLabel("Tee & rating — off the scorecard")
        // three fields across; stacked (and the tee field full-width) at the accessibility sizes
        A11yStack(spacing: 8) {
          CSField("Tee", text: Binding(get: { store.state.course.tee }, set: { store.state.course.tee = $0 }), font: CSFont.body)
            .frame(width: typeSize.isA11y ? nil : 96).accessibilityLabel("Tee")
          CSField("Rating", text: $ratingText).keyboardType(.decimalPad).accessibilityLabel("Rating")
            .onChange(of: ratingText) { _, v in store.state.course.rating = Double(v.replacingOccurrences(of: ",", with: ".")) }
          CSField("Slope", text: $slopeText).keyboardType(.numberPad).accessibilityLabel("Slope")
            .onChange(of: slopeText) { _, v in store.state.course.slope = Int(v) }
        }
        LiveSeg(options: [(18, "18 holes"), (9, "9 holes")], selected: store.state.holes) { store.setHoles($0) }
          .frame(maxWidth: typeSize.isA11y ? .infinity : 220, alignment: .leading)
        CSFine(store.state.course.note ?? LiveCourseCard.standardNote)
        CSMini("Enter the pars") { showCard = true }
      }
    }
  }

  private func fieldLabel(_ s: String) -> some View {
    Text(s).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
  }

  // MARK: the foursome (3004–3020; 8720–8817)

  private var foursomeCard: some View {
    CSCard {
      VStack(alignment: .leading, spacing: 10) {
        fieldLabel("The foursome · \(store.sel.count) / 4")
        if store.teamable {
          LiveSeg(options: [(LiveMode.teams, "2v2 teams"), (LiveMode.solo, "Everyone for themselves")], selected: store.state.mode) { store.setMode($0) }
        }
        if store.courtMode { LiveCourtView(store: store) } else { slots }
        fieldLabel("Tap to fill a slot").padding(.top, 6)   // the chip groups carry their own LEAGUE header — saying it twice read as a glitch
        chips
        CSMini("Search the app — add any golfer", systemImage: "person.2") { showPicker = true }
        fieldLabel("Add a guest").padding(.top, 4)
        A11yStack(spacing: 8) {
          CSField("Name", text: $guestName, font: CSFont.body).accessibilityLabel("Guest name")
          CSField("Index", text: $guestIdx).keyboardType(.decimalPad).frame(width: typeSize.isA11y ? nil : 96).accessibilityLabel("Guest index")
          CSMini("Add") {
            store.addGuest(name: guestName, index: Double(guestIdx.replacingOccurrences(of: ",", with: ".")))
            if !guestName.trimmingCharacters(in: .whitespaces).isEmpty { guestName = ""; guestIdx = "" }
          }
        }
        CSFine(store.leagueId == nil
          ? "Pick who plays with who under the game — pairings, stakes, the lot. Every complete card posts to its golfer at the finish; account-less guests play every game, post nothing. Leave index blank for an estimated 18."
          : "Pick who plays with who under the game — pairings, stakes, the lot. League members post to the season; guests play every game, post nothing, no account needed. Leave index blank for an estimated 18.")
      }
    }
  }

  private var slots: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: typeSize.isA11y ? 1 : 2), spacing: 8) {
      ForEach(0..<4, id: \.self) { k in
        if k < store.sel.count, store.sel[k] < store.roster.count {
          let idx = store.sel[k]
          LiveSlotChip(player: store.roster[idx], remove: store.roster[idx].locked ? nil : { store.remove(idx) })
        } else {
          VStack(alignment: .leading, spacing: 2) {
            Text("Open slot").font(CSFont.subhead).foregroundStyle(cs.dimText)
            Text("TAP A PLAYER BELOW").font(CSFont.label).tracking(1).foregroundStyle(cs.dimText)   // text never in `dim` (IOS-013)
          }
          .padding(10).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
          .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
          .accessibilityElement(children: .combine)
        }
      }
    }
  }

  /// D156 · the opt-in. Off until the golfer says yes, and it says plainly what
  /// it does and does not do — "local network" is a scary-sounding prompt and
  /// the honest answer to it is short.
  @ViewBuilder private var nearbyCard: some View {
    CSCard {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("Who's on this tee").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
            Text(store.nearbyOn ? "Looking for buddies nearby" : "Fill the foursome from the phones next to you")
              .font(CSFont.label).foregroundStyle(cs.dimText)
          }
          Spacer()
          Toggle("", isOn: Binding(get: { store.nearbyOn }, set: { store.nearbyOn = $0 }))
            .labelsHidden().tint(cs.brand)
            .accessibilityLabel("Find buddies on this tee")
        }
        CSFine("Bluetooth only — never your location, and nothing about where you are leaves your phone. A golfer who is not already your buddy or league mate stays invisible, and you still tap to add anyone.")
      }
    }
  }

  /// The pick lists — only unselected players show (8770–8805).
  private var chips: some View {
    // D154 · the regulars lead. A golfer appears in exactly ONE group, so the
    // later tests exclude anyone the earlier ones already claimed — a name in
    // two lists is a worse picker, not a better one.
    let groups: [(String, (LivePlayer) -> Bool)] = [
      ("You", { !$0.guest && $0.me }),
      ("Nearby", { $0.nearby == true && !$0.me }),
      ("You play with", { $0.regular != nil && $0.nearby != true && !$0.me }),
      ("League", { !$0.guest && !$0.me && $0.regular == nil && $0.nearby != true }),
      ("Buddies", { $0.guest && $0.buddy && $0.regular == nil && $0.nearby != true }),
      ("Guests", { $0.guest && !$0.buddy && $0.nearby != true }),
    ]
    let any = store.roster.indices.contains { !store.sel.contains($0) }
    return VStack(alignment: .leading, spacing: 8) {
      ForEach(groups, id: \.0) { label, test in
        let items = store.roster.indices.filter { !store.sel.contains($0) && test(store.roster[$0]) }
          .sorted { (store.roster[$0].regular ?? .max) < (store.roster[$1].regular ?? .max) }
        if !items.isEmpty {
          Text(label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
          LiveFlow(spacing: 6) {
            ForEach(items, id: \.self) { i in
              let p = store.roster[i]
              // D158 · a NEARBY chip asks; every other chip adds. Proximity
              // proposes an identity, so the tap that seats them belongs on
              // their phone, not this one.
              let isNear = p.nearby == true
              let waiting = isNear && p.pid.map { store.asking.contains($0) } == true
              Button { isNear ? store.askNearby(i) : store.pick(i) } label: {
                HStack(spacing: 6) {
                  if p.guest { Text(p.buddy ? "BUDDY" : "GUEST").font(CSFont.label).foregroundStyle(cs.dimText) }
                  else { RoundedRectangle(cornerRadius: 3).fill(cs.squad(p.ci)).frame(width: 8, height: 8) }
                  Text("\(p.n) · \(LiveFmt.idx(p.i))").font(CSFont.monoSmall).foregroundStyle(cs.ink)
                  if waiting { Text("ASKING…").font(CSFont.label).foregroundStyle(cs.gold) }
                  else if isNear { Text("ASK").font(CSFont.label).foregroundStyle(cs.brand) }
                }
                .padding(.horizontal, 10).frame(minHeight: 36)
                .background(cs.bg2, in: Capsule())
                .overlay(Capsule().stroke(cs.line2, lineWidth: 1))
                .frame(minHeight: 44).contentShape(Rectangle())   // the 44pt frame must be INSIDE the label to count
              }
              .buttonStyle(.plain)
              .disabled(waiting)
              .accessibilityLabel("\(p.n), index \(LiveFmt.idx(p.i))\(p.guest ? (p.buddy ? ", buddy" : ", guest") : "")\(waiting ? ", asked, waiting for them" : "")")
              .accessibilityHint(isNear ? "Asks them to join — they confirm on their own phone"
                                        : "Adds them to the foursome")
            }
          }
        }
      }
      if !any {
        if store.leagueId == nil {
          // D107: no league is a fine tee sheet — the add-golfer door leads
          CSMini("Bring your group — search the app", systemImage: "person.2") { showPicker = true }
        } else {
          CSFine("No league mates to tap yet — search the app or add a guest below.")
        }
      }
    }
  }

  // MARK: the game (3021–3035)

  private var gameCard: some View {
    CSCard {
      VStack(alignment: .leading, spacing: 10) {
        fieldLabel("Game for this round · pick one")
        LiveFlow(spacing: 6) {
          ForEach(LiveGame.allCases, id: \.self) { g in
            Button { store.setGame(g) } label: {
              Text(g.segLabel).font(CSFont.monoMediumBody)
                .foregroundStyle(store.state.game == g ? cs.bg0 : cs.ink)
                .padding(.horizontal, 12).frame(minHeight: 40)
                .background(store.state.game == g ? cs.brand : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
                .frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(store.state.game == g ? .isSelected : [])
          }
        }
        CSFine(store.state.game.note)
        if store.state.game.money {
          Divider().overlay(cs.line)
          fieldLabel(store.state.game.stakeLabel)
          CSField("0", text: $stakeText).keyboardType(.decimalPad).frame(width: 110).accessibilityLabel(store.state.game.stakeLabel)
            .onChange(of: stakeText) { _, v in store.setStake(Double(v.replacingOccurrences(of: ",", with: ".")) ?? 0) }
          if let prev = LiveCopy.preview(game: store.state.game, picked: store.picked, pairing: store.state.pairing, course: store.state.course, holes: store.state.liveHoles) {
            Text(LiveMarkdown.bold(prev)).font(CSFont.footnote).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
  }
}

/// `**name**` → bold, for the strokes preview.
enum LiveMarkdown {
  static func bold(_ s: String) -> AttributedString {
    (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
  }
}

/// A seat chip in a slot or on the court.
struct LiveSlotChip: View {
  @Environment(\.cs) private var cs
  let player: LivePlayer
  var picked = false
  var tradeable = false
  var remove: (() -> Void)?

  var body: some View {
    HStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          if player.guest { Text(player.buddy ? "B" : "G").font(CSFont.label).foregroundStyle(cs.dimText) }
          else { RoundedRectangle(cornerRadius: 3).fill(cs.squad(player.ci)).frame(width: 8, height: 8) }
          Text(player.n).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink).lineLimit(1)
        }
        Text("\(player.est ? "EST " : "")\(LiveFmt.idx(player.i)) IDX").font(CSFont.label).tracking(1).foregroundStyle(cs.dimText)
      }
      Spacer(minLength: 0)
      if tradeable { Text("⇄").font(CSFont.monoSmall).foregroundStyle(cs.brand) }
      if let remove {
        Button(action: remove) {
          Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(cs.mut)
            .frame(width: 28, height: 28).background(cs.bg2, in: Circle())
            .a11yHitSlop(vertical: 8, horizontal: 8)   // a 28pt glyph, a 44pt target
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(player.n)")
      }
    }
    .padding(10).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(picked ? cs.brand : cs.line2, lineWidth: picked ? 2 : 1))
    .accessibilityElement(children: .contain)
    .accessibilityLabel("\(player.n), \(player.est ? "estimated " : "")index \(LiveFmt.idx(player.i))\(player.guest ? (player.buddy ? ", buddy" : ", guest") : "")\(picked ? ", selected" : "")")
  }
}

/// The court (D75, `renderCourt` 7268): the four slots BECOME the two team
/// zones — drag a player across (or tap one, then another) and the sides
/// auto-balance. The trade target is a CHIP, never a zone.
struct LiveCourtView: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Bindable var store: LiveRoundStore

  var body: some View {
    let T = store.courtTeams
    // the two zones side by side; one over the other at the accessibility sizes (a seat chip needs the width)
    A11yStack(alignment: .center, rowAlignment: .top, spacing: 8) {
      zone(0, "Team A", T[0])
      Text("VS").font(CSFont.label).tracking(1.4).foregroundStyle(cs.dimText).padding(.top, typeSize.isA11y ? 0 : 28)
      zone(1, "Team B", T[1])
    }
  }

  private func zone(_ zi: Int, _ label: String, _ positions: [Int]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
      ForEach(positions, id: \.self) { k in
        if k < store.sel.count, store.sel[k] < store.roster.count {
          let idx = store.sel[k]
          let p = store.roster[idx]
          let tradeable = store.crtPicked != nil && store.crtPicked != k && (store.courtTeams[0].contains(store.crtPicked!)) != (zi == 0)
          LiveSlotChip(player: p, picked: store.crtPicked == k, tradeable: tradeable, remove: p.locked ? nil : { store.remove(idx) })
            .contentShape(Rectangle())
            .onTapGesture { store.courtTap(k) }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(store.crtPicked == nil ? "Double tap to pick, then a player on the other team to swap" : (tradeable ? "Double tap to swap" : ""))
            .draggable(String(k))
            .dropDestination(for: String.self) { items, _ in
              guard let s = items.first, let from = Int(s) else { return false }
              store.courtSwap(from, k)
              return true
            }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .padding(8)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
  }
}

/// `.seg` — the pill control, styled to the tokens.
struct LiveSeg<V: Hashable>: View {
  @Environment(\.cs) private var cs
  let options: [(V, String)]
  let selected: V
  let pick: (V) -> Void

  var body: some View {
    A11yStack(spacing: 4) {
      ForEach(options, id: \.0) { v, label in
        Button { pick(v) } label: {
          Text(label).font(CSFont.monoMediumBody)
            .foregroundStyle(selected == v ? cs.bg0 : cs.ink)
            .padding(.horizontal, 12).frame(maxWidth: .infinity, minHeight: 40)
            .background(selected == v ? cs.brand : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected == v ? .isSelected : [])
      }
    }
    .padding(3)
    .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
  }
}

/// Chips that wrap.
struct LiveFlow: Layout {
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

// MARK: - course search for the tee sheet (6729; cache first, then the API)

/// Like the calendar's `CourseSearchField`, but the tee pick hands back the
/// TEE (rating, slope, holes) so the live sheet can fill its card.
struct LiveCourseField: View {
  @Environment(\.cs) private var cs
  @Binding var text: String
  let onTee: (CourseHit, CourseTee) -> Void
  @State private var vm = LiveCourseSearchModel()

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      CSField("Search a course, or type your own", text: $text, font: CSFont.body)
        .onChange(of: text) { _, q in
          if vm.pickedLabel != q { vm.pickedLabel = nil }
          vm.queue(q)
        }
      switch vm.stage {
      case .hidden: EmptyView()
      case .courses:
        dropdown {
          if vm.courses.isEmpty {
            Text("No match — type the course, rating and slope by hand.").font(CSFont.footnote).foregroundStyle(cs.mut).padding(12)
          } else {
            ForEach(vm.courses) { c in ddRow(c.label, c.subline) { text = c.label; vm.pickedLabel = c.label; vm.stage = .tees(c) } }
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
                vm.stage = .hidden
                onTee(c, t)
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
final class LiveCourseSearchModel {
  enum Stage { case hidden, courses, tees(CourseHit) }
  var stage: Stage = .hidden
  var courses: [CourseHit] = []
  var pickedLabel: String?
  private var task: Task<Void, Never>?
  private var lastQ = ""
  private let sched = ScheduleService()

  /// 320 ms debounce, ≥3 chars (6814–6830).
  func queue(_ q: String) {
    task?.cancel()
    let q = q.trimmingCharacters(in: .whitespaces)
    lastQ = q
    guard q.count >= 3, q != pickedLabel else { stage = .hidden; courses = []; return }
    task = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(320))
      guard !Task.isCancelled, let self else { return }
      await self.run(q)
    }
  }

  private var inTees: Bool { if case .tees = stage { return true }; return false }

  private func run(_ q: String) async {
    let local = await sched.searchCache(q)
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

// MARK: - "Enter the pars" (`openCardSheet` 9535)

struct LiveCardSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(\.toast) private var toast
  @Bindable var store: LiveRoundStore
  @State private var f9 = ""
  @State private var b9 = ""

  private var nine: Bool { store.state.liveHoles == 9 }
  private func sum(_ s: String) -> Int { s.compactMap { Int(String($0)) }.reduce(0, +) }
  private func valid(_ s: String) -> Bool { s.count == 9 && s.allSatisfy { ("3"..."6").contains(String($0)) } }
  private func clean(_ s: String) -> String { String(s.filter { ("3"..."6").contains(String($0)) }.prefix(9)) }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          CSSheetHeader(title: "Course card", sub: ((store.state.course.label.isEmpty ? "Course" : store.state.course.label) + " · pars only").uppercased())
          side(nine ? "The nine" : "Front nine", $f9, placeholder: "453453543")
          if !nine { side("Back nine", $b9, placeholder: "434445345") }
          HStack {
            Text("Total par").font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
            Spacer()
            let ok = valid(f9) && (nine || valid(b9))
            Text(ok ? String(sum(f9) + (nine ? 0 : sum(b9))) : "—").font(CSFont.stat).foregroundStyle(ok ? cs.pos : cs.mut)
          }
          CSFine("Nine digits a side, 3–6. \(nine ? "The nine you played." : "Type it once and the card saves for every league.") Strokes fall by hole order; exact stroke index arrives with the course database.")
          CSButton("Save the card") {
            guard valid(f9), nine || valid(b9) else { toast.show("Nine digits a side, 3 through 6"); return }
            store.saveCard(front: f9.compactMap { Int(String($0)) }, back: nine ? nil : b9.compactMap { Int(String($0)) })
            dismiss()
          }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.foregroundStyle(cs.mut) } }
    }
    .presentationDetents([.medium, .large])
    .onAppear {
      f9 = store.state.course.pars.prefix(9).map(String.init).joined()
      b9 = store.state.course.pars.suffix(9).map(String.init).joined()
    }
  }

  private func side(_ label: String, _ text: Binding<String>, placeholder: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(label).font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
        Spacer()
        let v = text.wrappedValue
        Text(v.isEmpty ? "—" : String(sum(v))).font(CSFont.monoMediumBody).foregroundStyle(v.isEmpty ? cs.mut : (valid(v) ? cs.pos : cs.neg))
      }
      CSField(placeholder, text: text).keyboardType(.numberPad)
        .onChange(of: text.wrappedValue) { _, v in let c = clean(v); if c != v { text.wrappedValue = c } }
    }
  }
}

// MARK: - the foursome's people picker (8834–8850)

/// The app-wide search, landing a golfer as a non-posting player with their
/// identity (and index) pre-filled. Buddies lead when the search is empty.
struct LiveRosterPickerSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Bindable var store: LiveRoundStore
  @State private var query = ""
  @State private var rows: [LiveRosterHit] = []
  @State private var searching = false
  @State private var loaded = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          CSSheetHeader(title: "Add to the foursome", sub: store.leagueId == nil ? "Buddies are below — search anyone on the app" : "League mates and buddies are below — search anyone on the app")
          CSField("Find golfers by name or @handle", text: $query, font: CSFont.body)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
          if rows.isEmpty {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
              if loaded { CSFine("Type a name or @handle to search — buddies you add appear here.") }
            } else if !searching {
              CSFine("No golfers found. Invite links still work for everyone else.")
            }
          } else {
            ForEach(rows) { r in
              HStack(spacing: 12) {
                CSFace(marker: r.marker, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                  Text(r.name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
                  Text(r.subline).font(CSFont.monoSmall).foregroundStyle(cs.mut)
                }
                Spacer()
                if store.pickerExcluded.contains(r.id) { CSTag(text: "In", tone: cs.pos) }
                else { CSMini("Add") { store.addFromPicker(profileId: r.id, name: r.displayName, index: r.index); CSHaptic.selection() }.accessibilityLabel("Add \(r.name)") }
              }
              .padding(.vertical, 6)
            }
          }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(cs.brand) } }
      .task { await buddies() }
      .task(id: query) { await search() }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private func buddies() async {
    if let l = try? await SupabaseService.shared.call(Rpc.my_friends()) {
      rows = l.filter { $0.status == "accepted" }.compactMap(LiveRosterHit.init)
    }
    loaded = true
  }

  private func search() async {
    let q = query.trimmingCharacters(in: .whitespaces)
    if q.isEmpty { await buddies(); return }
    try? await Task.sleep(for: .milliseconds(350))
    guard !Task.isCancelled else { return }
    searching = true; defer { searching = false }
    rows = ((try? await SupabaseService.shared.call(Rpc.search_golfers(p_q: q))) ?? []).compactMap(LiveRosterHit.init)
  }
}

/// A search hit with the index the tee sheet needs (`r.index_current`, 8846).
struct LiveRosterHit: Identifiable {
  let id: UUID
  let displayName: String?
  let handle: String?
  let city: String?
  let marker: String?
  let index: Double?
  var name: String { displayName ?? "—" }
  var subline: String { "@\(handle ?? "?")" + (city.map { " · \($0)" } ?? "") }

  init?(_ r: Rpc.search_golfers.Row) {
    guard let id = r.profile_id else { return nil }
    self.id = id; displayName = r.display_name; handle = r.handle; city = r.city; marker = r.marker; index = r.index_current
  }
  init?(_ r: Rpc.my_friends.Row) {
    guard let id = r.profile_id else { return nil }
    self.id = id; displayName = r.display_name; handle = r.handle; city = r.city; marker = r.marker; index = r.index_current
  }
}

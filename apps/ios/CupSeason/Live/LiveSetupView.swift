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
        Text("Set up the round").csType(.agate, caps: true).foregroundStyle(cs.mut)
        if let sr = store.plan, !store.planDismissed { planBridge(sr) }
        courseCard
        foursomeCard
        gameCard
        nearbyCard
        Button("Tee off") { teeOffTaps += 1; Task { await store.teeOff() } }
          .buttonStyle(.csPrimary(busy: store.busy))
          .padding(.top, CSTokens.Space.s2)
      }
      .padding(CSTokens.Space.gutter)
    }
    .background(cs.bg0)
    // D168 · advertising now follows the APP, not this screen — it starts here
    // and in the tab shell whenever the app is foreground and the golfer has
    // opted in. Confining it to this one screen meant everybody had to be on
    // the same screen at the same time, which defeats the point: one person
    // builds the round, everyone else should just be asked. Leaving the screen
    // no longer stops it; backgrounding does (there is still no background
    // mode, and there must never be one).
    .onAppear { store.startNearby() }
    // D175 · the same doorbell the tab shell rings — see `csNearbyInvite`. This
    // copy exists because an alert cannot present from under a full-screen
    // cover, and this screen IS that cover.
    .csNearbyInvite(store)
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
    // gold may never touch a control (D269), and a gold border round a card
    // with a button in it is the clearest case of it in the product
    return CSBand(.tone, padding: CSTokens.Space.s3) {
      Text("Your round today\(sr.course_label.map { " · \($0)" } ?? "")").csType(.name).foregroundStyle(cs.ink)
      Text("Load the course and your group into the round\(withN).").csType(.bodyS).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
      CSMini("Load it") { store.loadPlan() }
    }
    .padding(.horizontal, CSTokens.Space.s3)
  }

  // MARK: the course (2985–3003)

  private var courseCard: some View {
    section {
        CSSectionHead("The course")
        LiveCourseField(text: Binding(get: { store.state.course.label }, set: { v in
          if store.state.course.label != v { store.state.course.courseId = nil }
          store.state.course.label = v
        })) { course, tee in
          Task {
            await store.applyTee(course: course, tee: tee)
            ratingText = store.state.course.rating.map(LiveFmt.js) ?? ""
            slopeText = store.state.course.slope.map(String.init) ?? ""
            toast.show("Tees set — rating and slope filled", kind: .confirmed)
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

  /// A block of the page, parted from the next by a rule — **not a card.** The
  /// four tiles this screen wore were containers with no job (non-negotiable
  /// 1): a bordered box round every question on a form is the audit's card
  /// census in one screen.
  @ViewBuilder private func section<C: View>(@ViewBuilder _ c: () -> C) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) { c() }
      .padding(.bottom, CSTokens.Space.s3)
      .overlay(alignment: .bottom) { CSRule() }
  }

  private func fieldLabel(_ s: String) -> some View {
    Text(s).csType(.agate, caps: true).foregroundStyle(cs.mut)
  }

  // MARK: the foursome (3004–3020; 8720–8817)

  private var foursomeCard: some View {
    section {
        // LV-08 · "the foursome" is retired (row 161) in favour of "the group",
        // which this screen's own new copy already says five ways.
        CSSectionHead("The group", count: "\(store.sel.count) of 4")
        if store.teamable {
          LiveSeg(options: [(LiveMode.teams, "2v2 teams"), (LiveMode.solo, "Everyone for themselves")], selected: store.state.mode) { store.setMode($0) }
        }
        if store.courtMode { LiveCourtView(store: store) } else { slots }
        fieldLabel("Tap to fill a slot").padding(.top, 6)   // the chip groups carry their own LEAGUE header — saying it twice read as a glitch
        chips
        CSMini("Search the app — add any golfer", glyph: .people) { showPicker = true }
        fieldLabel("Add a guest").padding(.top, 4)
        A11yStack(spacing: 8) {
          CSField("Name", text: $guestName, font: CSFont.body).accessibilityLabel("Guest name")
          // LV-19 · the slot chip on this same screen says NUMBER; the field said Index.
          CSField("Number", text: $guestIdx).keyboardType(.decimalPad).frame(width: typeSize.isA11y ? nil : 96).accessibilityLabel("Guest number")
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

  private var slots: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: typeSize.isA11y ? 1 : 2), spacing: 8) {
      ForEach(0..<4, id: \.self) { k in
        if k < store.sel.count, store.sel[k] < store.roster.count {
          let idx = store.sel[k]
          LiveSlotChip(player: store.roster[idx], remove: store.roster[idx].locked ? nil : { store.remove(idx) })
        } else {
          VStack(alignment: .leading, spacing: 2) {
            Text("Open slot").csType(.name).foregroundStyle(cs.mut)
            Text("Tap a player below").csType(.agate, caps: true).foregroundStyle(cs.mut)
          }
          .padding(CSTokens.Space.s3).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
          .background(cs.bg1)
          .accessibilityElement(children: .combine)
        }
      }
    }
  }

  /// D156 · the opt-in. Off until the golfer says yes, and it says plainly what
  /// it does and does not do — "local network" is a scary-sounding prompt and
  /// the honest answer to it is short.
  @ViewBuilder private var nearbyCard: some View {
    section {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("Who's on this tee").csType(.name).foregroundStyle(cs.ink)
            Text(store.nearbyOn ? "Looking for buddies nearby" : "Fill the group from the phones next to you")
              .csType(.agate, caps: true).foregroundStyle(cs.mut)
          }
          Spacer()
          Toggle("", isOn: Binding(get: { store.nearbyOn }, set: { store.nearbyOn = $0 }))
            .labelsHidden().tint(cs.brand)
            .accessibilityLabel("Find buddies on this tee")
        }
        CSFine("Bluetooth only — never your location, and nothing about where you are leaves your phone. A golfer who is not already your buddy or in a season with you stays invisible, and you still tap to add anyone.")
    }
  }

  /// One pickable golfer: the player itself plus where it sat when the row was
  /// drawn. Identity is the player's own id, never the position — see `chips`.
  private struct Pick: Identifiable {
    let i: Int
    let p: LivePlayer
    var id: String { p.id }
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
        // Each row carries the PLAYER, not an index into a roster that a
        // background load can replace under it. `prime()` rewrites
        // `store.roster` wholesale after its await, and `resolveNearby()` and
        // `markRegulars()` mutate and append to it — all of them after this
        // body has been evaluated, and SwiftUI may run a row closure against
        // the list it was drawn from a roster ago. Indexing back into the
        // store from inside the row trapped on a real phone at first paint
        // (build 669, 2026-09-03, `roster[i]` out of range). `slots` and
        // `zone` had already learned this and guard their own indexing; this
        // was the one picker that did not.
        let items: [Pick] = store.roster.indices
          .filter { !store.sel.contains($0) && test(store.roster[$0]) }
          .sorted { (store.roster[$0].regular ?? .max) < (store.roster[$1].regular ?? .max) }
          .map { Pick(i: $0, p: store.roster[$0]) }
        if !items.isEmpty {
          Text(label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.mut)
          LiveFlow(spacing: 6) {
            ForEach(items) { item in
              let p = item.p
              // D158 · a NEARBY chip asks; every other chip adds. Proximity
              // proposes an identity, so the tap that seats them belongs on
              // their phone, not this one.
              let isNear = p.nearby == true
              let waiting = isNear && p.pid.map { store.asking.contains($0) } == true
              // The position is resolved at TAP time, by identity: the row may
              // have been drawn against an older roster, and seating by a stale
              // position would seat the wrong golfer. Gone from the list, gone.
              Button {
                guard let idx = store.roster.firstIndex(where: { $0.id == p.id }) else { return }
                isNear ? store.askNearby(idx) : store.pick(idx)
              } label: {
                // §6 · a row with a person in it draws the person. A 8pt squad
                // swatch is not a face, and it was the same square for four
                // golfers on the same side.
                HStack(spacing: CSTokens.Space.s2) {
                  CSFace(Faces.of(p.pid, marker: p.mk, name: p.n, isViewer: p.me), size: .inline)
                  Text("\(p.n) · \(LiveFmt.idx(p.i))").csType(.nameS).foregroundStyle(cs.ink)
                  if waiting { Text("Asking…").csType(.agateS, caps: true).foregroundStyle(cs.mut) }
                  else if isNear { Text("Ask").csType(.agateS, caps: true).foregroundStyle(cs.brand) }
                }
                .padding(.horizontal, CSTokens.Space.s2).frame(minHeight: 36)
                .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
                .frame(minHeight: 44).contentShape(Rectangle())   // the 44pt frame must be INSIDE the label to count
              }
              .buttonStyle(.plain)
              .disabled(waiting)
              .accessibilityLabel("\(p.n), index \(LiveFmt.idx(p.i))\(p.guest ? (p.buddy ? ", buddy" : ", guest") : "")\(waiting ? ", asked, waiting for them" : "")")
              .accessibilityHint(isNear ? "Asks them to join — they confirm on their own phone"
                                        : "Adds them to the group")
            }
          }
        }
      }
      if !any {
        if store.leagueId == nil {
          // D107: no league is a fine tee sheet — the add-golfer door leads
          CSMini("Bring your group — search the app", glyph: .people) { showPicker = true }
        } else {
          CSFine("Nobody from your seasons to tap yet — search the app or add a guest below.")
        }
      }
    }
  }

  // MARK: the game (3021–3035)

  private var gameCard: some View {
    section {
        CSSectionHead("The game", count: "pick one")
        LiveFlow(spacing: 6) {
          ForEach(LiveGame.allCases, id: \.self) { g in
            // §7.2 · a chosen game INVERTS to the panel. It wore an ember fill,
            // and ember means "the live thing you can do now" — the one primary
            // on this screen is `Tee off`, not the game you picked.
            Button { store.setGame(g) } label: {
              CSChip(g.segLabel, selected: store.state.game == g)
                .frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
        CSFine(store.state.game.note)
        if store.state.game.money {
          CSRule()
          fieldLabel(store.state.game.stakeLabel)
          CSField("0", text: $stakeText).keyboardType(.decimalPad).frame(width: 110).accessibilityLabel(store.state.game.stakeLabel)
            .onChange(of: stakeText) { _, v in store.setStake(Double(v.replacingOccurrences(of: ",", with: ".")) ?? 0) }
          if let prev = LiveCopy.preview(game: store.state.game, picked: store.picked, pairing: store.state.pairing, course: store.state.course, holes: store.state.liveHoles) {
            Text(LiveMarkdown.bold(prev)).csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
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
      CSFace(Faces.of(player.pid, marker: player.mk, name: player.n, isViewer: player.me), size: .slat)
      VStack(alignment: .leading, spacing: 2) {
        Text(player.n).csType(.name).foregroundStyle(cs.ink).lineLimit(1)
        Text("\(player.est ? "Est " : "")\(LiveFmt.idx(player.i)) playing HCP")
          .csType(.agateS, caps: true).foregroundStyle(cs.mut)
      }
      Spacer(minLength: 0)
      if tradeable { CSGlyph(.chevron, size: .inline).foregroundStyle(cs.brand) }
      if let remove {
        Button(action: remove) {
          CSGlyph(.cross, size: .inline).foregroundStyle(cs.mut)
            .frame(width: 28, height: 28)
            .a11yHitSlop(vertical: 8, horizontal: 8)   // a 28pt glyph, a 44pt target
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(player.n)")
      }
    }
    .padding(CSTokens.Space.s3).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    .background(picked ? cs.panel : cs.bg2)
    .foregroundStyle(picked ? cs.panelInk : cs.ink)
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
      Text("vs").csType(.agate, caps: true).foregroundStyle(cs.mut).padding(.top, typeSize.isA11y ? 0 : 28)
      zone(1, "Team B", T[1])
    }
  }

  private func zone(_ zi: Int, _ label: String, _ positions: [Int]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label).csType(.agate, caps: true).foregroundStyle(cs.mut)
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
    .padding(CSTokens.Space.s2)
    .background(cs.bg1)
  }
}

/// `.seg` — the pill control, styled to the tokens.
struct LiveSeg<V: Hashable>: View {
  @Environment(\.cs) private var cs
  let options: [(V, String)]
  let selected: V
  let pick: (V) -> Void

  /// **The one segment (§7.2).** It was a pill inside a bordered tray with an
  /// EMBER fill on the selected item — a tab is not live, so the mark is a 2px
  /// `ink` underline and the tray is gone.
  var body: some View {
    CSSegment(options.map { ($0.0, $0.1) },
              selection: Binding(get: { selected }, set: { pick($0) }))
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
            Text(vm.offline ? CourseBookCopy.searchOffline : "No match — type the course, rating and slope by hand.")
              .csType(.bodyS).foregroundStyle(cs.mut).padding(12)
              .fixedSize(horizontal: false, vertical: true)
          } else {
            // D261 / R-N · a golf course is where the signal is worst. These
            // rows are the courses this phone kept, and the list says so.
            if vm.offline {
              Text(CourseBookCopy.searchOffline).csType(.bodyS).foregroundStyle(cs.mut)
                .padding(.horizontal, 12).padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(vm.courses) { c in ddRow(c.label, c.subline) { text = c.label; vm.pickedLabel = c.label; vm.stage = .tees(c) } }
          }
        }
      case .tees(let c):
        dropdown {
          ddRow("‹ Back to courses", nil) { vm.stage = .courses }
          if c.tees.isEmpty {
            Text("No rated tees listed — type the rating and slope by hand.").csType(.bodyS).foregroundStyle(cs.mut).padding(12)
          } else {
            ForEach(c.tees) { t in
              ddRow(t.title, t.subtitle) {
                text = c.label + (t.tee_name.map { " · \($0)" } ?? "")
                vm.pickedLabel = text
                vm.stage = .hidden
                onTee(c, t)
                Task { await CourseBookStore().keep(hit: c, tee: t) }
              }
            }
          }
        }
      }
    }
  }

  private func dropdown<C: View>(@ViewBuilder _ content: () -> C) -> some View {
    // the results sit on the raised ground and are parted by rules — a
    // bordered box round a list is a container with no job (non-negotiable 1)
    VStack(spacing: 0) { content() }
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
  }

  private func ddRow(_ b: String, _ s: String?, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 2) {
        Text(b).csType(.name).foregroundStyle(cs.ink)
        if let s { Text(s).csType(.columnS).foregroundStyle(cs.mut) }
      }
      .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
      .padding(.horizontal, CSTokens.Space.s3).padding(.vertical, CSTokens.Space.s2)
      .overlay(alignment: .bottom) { CSRule() }
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
  /// D261 · true when nothing on the network answered and these rows are the
  /// courses on this phone.
  var offline = false
  private var task: Task<Void, Never>?
  private var lastQ = ""
  private let sched = ScheduleService()
  private let books = CourseBookStore()

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
    let fresh = { self.lastQ == q && !self.inTees }
    let saved = await books.search(q).map(\.hit)
    if !saved.isEmpty, fresh() { courses = saved; stage = .courses }
    // D261 / R-N · ONE producer: the book, then our cache, then the API.
    let answer = await books.searchCourses(q)
    // show the list even when empty — the empty state IS the "type it by hand"
    // row, so a no-match never looks like a dead field
    if fresh() { courses = answer.hits; offline = answer.offline; stage = .courses }
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
            Text("Total par").font(CSFont.label).tracking(1.2).foregroundStyle(cs.mut)
            Spacer()
            let ok = valid(f9) && (nine || valid(b9))
            Text(ok ? String(sum(f9) + (nine ? 0 : sum(b9))) : "—").font(CSFont.stat).foregroundStyle(ok ? cs.pos : cs.mut)
          }
          CSFine("Nine digits a side, 3–6. \(nine ? "The nine you played." : "Type it once and the card saves for every league.") Strokes fall by hole order; exact stroke index arrives with the course database.")
          Button("Save the card") {
            guard valid(f9), nine || valid(b9) else { toast.show("Nine digits a side, 3 through 6", kind: .failed); return }
            store.saveCard(front: f9.compactMap { Int(String($0)) }, back: nine ? nil : b9.compactMap { Int(String($0)) })
            dismiss()
          }
            .buttonStyle(.csPrimary())
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
        Text(label).font(CSFont.label).tracking(1.2).foregroundStyle(cs.mut)
        Spacer()
        let v = text.wrappedValue
        Text(v.isEmpty ? "—" : String(sum(v))).csType(.nameS).foregroundStyle(v.isEmpty ? cs.mut : (valid(v) ? cs.pos : cs.neg))
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
          CSSheetHeader(title: "Add to the group", sub: store.leagueId == nil ? "Buddies are below — search anyone on the app" : "Buddies and the golfers in your seasons are below — search anyone on the app")
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
                CSFace(.init(id: r.id, marker: r.marker), size: .list)
                VStack(alignment: .leading, spacing: 2) {
                  Text(r.name).csType(.name).foregroundStyle(cs.ink)
                  Text(r.subline).csType(.columnS).foregroundStyle(cs.mut)
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
      .csCloseButton { dismiss() }
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

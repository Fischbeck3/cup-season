import SwiftUI
import CSDesign
import CupSeasonKit

struct CourseCircleSection: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var session
  @Environment(\.presenter) private var presenter
  let courseId: String
  let courseName: String
  var unavailable: () -> Void = {}
  var loaded: (CourseCirclePage) -> Void = { _ in }
  @State private var page: CourseCirclePage?
  @State private var loading = true
  @State private var missing = false
  @State private var error: String?
  @State private var friendsOnly = false
  @State private var generation = 0

  var body: some View {
    if !missing {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        if let page {
          if !page.people.isEmpty {
            selection(page)
            best(page)
            CSSectionHead("Who’s played here")
            Picker("Golfers", selection: $friendsOnly) {
              Text("Friends · \(page.people.filter { $0.relation == "friend" }.count)").tag(true)
              Text("Your circle · \(page.people.count)").tag(false)
            }.pickerStyle(.segmented).accessibilityIdentifier("course.people.scope")
            let people = page.people.filter { !friendsOnly || $0.relation == "friend" }
            if people.isEmpty {
              Text("No friends have a visible round here yet.").csType(.body).foregroundStyle(cs.mut)
            }
            ForEach(people) { golfer in
              CSRule()
              NavigationLink { CourseGolferHistory(golfer: golfer, courseName: courseName) } label: {
                HStack(spacing: CSTokens.Space.s3) {
                  CSFace(.init(id: golfer.id, marker: golfer.person.marker, isViewer: golfer.relation == "me"), size: .slat, name: golfer.person.name)
                  VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
                    Text(golfer.relation == "me" ? "You" : golfer.person.name).csType(.social).foregroundStyle(cs.ink)
                    Text(golferDetail(golfer))
                      .csType(.agateS).foregroundStyle(cs.mut)
                  }.frame(maxWidth: .infinity, alignment: .leading)
                  if let score = golfer.best {
                    VStack(alignment: .trailing, spacing: CSTokens.Space.s1) {
                      Text("\(score)").csType(.figureM).foregroundStyle(cs.ink)
                      Text("Best").csType(.agateS).foregroundStyle(cs.mut)
                    }
                  }
                  CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut)
                }
                .frame(minHeight: 60).contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .accessibilityIdentifier("course.golfer.\(golfer.id.uuidString)")
            }
            Text(page.json["scope"]?["note"]?.string ?? "From the rounds visible to you.")
              .csType(.bodyS).foregroundStyle(cs.mut)
            if let unknown = page.json["unknown_tee_rounds"]?.int, unknown > 0 {
              Text("\(unknown) \(unknown == 1 ? "round has" : "rounds have") no confirmed tee. Those scores stay in the history and do not set a best.")
                .csType(.bodyS).foregroundStyle(cs.mut)
            }
          } else {
            Text("No rounds from your circle here yet.").csType(.body).foregroundStyle(cs.mut)
          }
        }
        if loading { Text("Loading rounds…").csType(.bodyS).foregroundStyle(cs.mut) }
        if let error {
          Text(error).csType(.bodyS).foregroundStyle(cs.neg)
          Button("Try again") { Task { await load(tee: page?.tee, holes: page?.holes) } }.buttonStyle(.csTertiary(.content))
        }
      }
      .task(id: session.session?.user.id) { page = nil; await load() }
    }
  }

  private func selection(_ page: CourseCirclePage) -> some View {
    ViewThatFits(in: .horizontal) {
      HStack { teeMenu(page); Spacer(); holeMenu(page) }
      VStack(alignment: .leading) { teeMenu(page); holeMenu(page) }
    }
    .disabled(loading)
  }
  private func teeMenu(_ page: CourseCirclePage) -> some View {
    Menu {
      ForEach(Array((page.json["tees"]?.array ?? []).enumerated()), id: \.offset) { _, tee in
        if let key = tee["key"]?.string, let name = tee["name"]?.string {
          Button(name + (tee["gender"]?.string == "female" ? " · Women’s" : "")) {
            Task { await load(tee: key, holes: page.holes) }
          }
        }
      }
    } label: {
      Label(page.teeName ?? "No confirmed tees", systemImage: "chevron.down").csType(.bodyS).frame(minHeight: 44)
    }
    .foregroundStyle(cs.ink).accessibilityIdentifier("course.social.tee")
  }
  private func holeMenu(_ page: CourseCirclePage) -> some View {
    Menu {
      ForEach([18, 9], id: \.self) { holes in
        Button("\(holes) holes") { Task { await load(tee: page.tee, holes: holes) } }
      }
    } label: {
      Label("\(page.holes) holes", systemImage: "chevron.down").csType(.bodyS).frame(minHeight: 44)
    }.foregroundStyle(cs.ink)
  }
  @ViewBuilder private func best(_ page: CourseCirclePage) -> some View {
    if let gross = page.best {
      CSRule()
      Text(page.json["scope"]?["best_label"]?.string ?? "Your circle best")
        .csType(.agate, caps: true).foregroundStyle(cs.mut)
      HStack(alignment: .top, spacing: CSTokens.Space.s4) {
        Text("\(gross)").csType(.figureL).foregroundStyle(cs.ink)
          .accessibilityIdentifier("course.circle.best")
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          ForEach(Array((page.json["best"]?["holders"]?.array ?? []).enumerated()), id: \.offset) { _, holder in
            if let person = SocialPerson(holder["person"]), let round = holder["round_id"]?.string.flatMap(UUID.init) {
              Button { presenter.receipt = round } label: {
                VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
                  HStack {
                    Text(person.name).csType(.social)
                    CSGlyph(.chevron, size: .inline)
                  }
                  Text(holder["played_on"]?.string.map { LeagueDates.dowMonDay($0) } ?? "").csType(.agateS).foregroundStyle(cs.mut)
                }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).foregroundStyle(cs.ink)
              }.buttonStyle(.plain).accessibilityHint("Opens the round that set this best")
            }
          }
        }.frame(maxWidth: .infinity, alignment: .leading)
      }
      Text(page.selectionLine).csType(.agateS).foregroundStyle(cs.mut)
      if page.json["best"]?["tied"]?.bool == true {
        Text("Shared best").csType(.bodyS).foregroundStyle(cs.mut)
      }
      if let mine = page.myBest, let round = page.json["my_best"]?["round_id"]?.string.flatMap(UUID.init) {
        CSRule()
        Button { presenter.receipt = round } label: {
          HStack(spacing: CSTokens.Space.s3) {
            Text("Your best here").csType(.social).frame(maxWidth: .infinity, alignment: .leading)
            Text("\(mine)").csType(.figureM)
            CSGlyph(.chevron, size: .inline)
          }.foregroundStyle(cs.ink).frame(minHeight: 44)
        }.buttonStyle(.plain).accessibilityHint("Opens your round")
      }
    } else {
      Text(page.json["best_unavailable"]?.string == "nine_side_unrecorded"
        ? "Nines aren't compared: which nine was played isn't recorded. They stay in each golfer's history."
        : "No comparable score from these tees yet.").csType(.bodyS).foregroundStyle(cs.mut)
    }
  }
  private func golferDetail(_ golfer: CourseCircleGolfer) -> String {
    var parts = ["\(golfer.count) \(golfer.count == 1 ? "round" : "rounds")"]
    if let latest = golfer.latest { parts.append("last \(LeagueDates.monDay(latest))") }
    else { parts.append(relation(golfer.relation)) }
    return parts.joined(separator: " · ")
  }
  private func relation(_ value: String) -> String {
    switch value { case "me": "Your rounds"; case "friend": "Friend"; case "event": "In your Ryders and Majors"; default: "In your seasons" }
  }
  private func load(tee: String? = nil, holes: Int? = nil) async {
    generation += 1; let stamp = generation
    let account = session.session?.user.id
    loading = true
    defer { if stamp == generation { loading = false } }
    do {
      let json = try await RoundSocialService().request("course_page", ["p_course_id": .string(courseId),
        "p_tee": tee.map(JSONValue.string) ?? .null, "p_holes": holes.map { .number(Double($0)) } ?? .null])
      guard stamp == generation, account == session.session?.user.id else { return }
      guard json["ok"]?.bool == true else { page = nil; error = "This course’s rounds are not available."; return }
      let first = page == nil
      let answer = CourseCirclePage(json)
      page = answer; error = nil
      if first { friendsOnly = answer.people.contains { $0.relation == "friend" } }
      loaded(answer)
    } catch {
      guard stamp == generation else { return }
      if (error as? RpcError)?.isMissingFunction == true { missing = true; unavailable() }
      else { self.error = HumanError.text(error, prefix: "Could not load the rounds here.") }
    }
  }
}

private struct CourseGolferHistory: View {
  @Environment(\.cs) private var cs
  @Environment(\.presenter) private var presenter
  let golfer: CourseCircleGolfer
  let courseName: String
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        Text(golfer.relation == "me" ? "Your rounds" : golfer.person.name).csType(.display).foregroundStyle(cs.ink)
        Text(courseName).csType(.body).foregroundStyle(cs.mut)
        ForEach(golfer.rounds) { round in
          CSRule()
          Button { presenter.receipt = round.id } label: {
            HStack(spacing: CSTokens.Space.s3) {
              Text(round.detail).csType(.bodyS).foregroundStyle(cs.ink).frame(maxWidth: .infinity, alignment: .leading)
              if let gross = round.gross { Text("\(gross)").csType(.figureM).foregroundStyle(cs.ink) }
              CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut)
            }.frame(minHeight: 60).contentShape(Rectangle())
          }.buttonStyle(.plain).accessibilityHint("Opens the round")
            .accessibilityIdentifier("course.round.\(round.id.uuidString)")
        }
        if golfer.count > golfer.rounds.count {
          Text("Latest \(golfer.rounds.count) of \(golfer.count) rounds. Best scores include the full history.").csType(.bodyS).foregroundStyle(cs.mut)
        }
      }.padding(CSTokens.Space.gutter)
    }
    .background(cs.bg0).navigationTitle("").navigationBarTitleDisplayMode(.inline)
  }
}

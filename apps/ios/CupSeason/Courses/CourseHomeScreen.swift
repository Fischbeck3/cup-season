import SwiftUI
import CSDesign
import CupSeasonKit

/// D391 · the social front door. The phone's offline inventory remains a
/// separate destination, including on the signed-out recovery path.
struct CourseHomeScreen: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var session
  @State private var courses: [CourseHomeEntry] = []
  @State private var loading = true
  @State private var error: String?
  @State private var total = 0
  @State private var query = ""
  @State private var results: [CourseHit] = []
  @State private var searching = false
  @State private var offline = false
  @State private var generation = 0
  private var term: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        Text("Courses").csType(.agate, caps: true).foregroundStyle(cs.mut)
        Text("Places you play.").csType(.display).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
        CSField("Find a course", text: $query, font: CSFont.body)
          .accessibilityIdentifier("courses.search")
        if !term.isEmpty {
          searchResults
        } else {
          Text("From your rounds and your circle’s rounds.").csType(.bodyS).foregroundStyle(cs.mut)
          if loading && courses.isEmpty {
            Text("Finding the places you play…").csType(.body).foregroundStyle(cs.mut)
          }
          if let error {
            Text(error).csType(.bodyS).foregroundStyle(cs.neg)
            Button("Try again") { Task { await load() } }.buttonStyle(.csTertiary(.content))
          } else if !loading && courses.isEmpty {
            Text("The first round puts a course here.").csType(.story).foregroundStyle(cs.ink)
            Text("Find a course above to see its page.").csType(.bodyS).foregroundStyle(cs.mut)
          }
          ForEach(courses) { course in
            CSRule()
            NavigationLink {
              CourseScreen(courseId: course.id, label: course.name)
            } label: { courseRow(course) }
              .buttonStyle(.plain)
              .accessibilityIdentifier("courses.open.\(course.id)")
          }
          if total > courses.count {
            Text("\(courses.count) most recently played courses. Search to find another.")
              .csType(.bodyS).foregroundStyle(cs.mut)
          }
        }
        CSRule()
        NavigationLink { CoursesScreen() } label: {
          HStack {
            Text("Saved for offline").csType(.bodyS)
            Spacer()
            CSGlyph(.chevron, size: .inline)
          }.frame(minHeight: 44).foregroundStyle(cs.ink)
        }.buttonStyle(.plain).accessibilityIdentifier("courses.offline")
      }
      .padding(CSTokens.Space.gutter)
      .csPage("courses-home")
    }
    .background(cs.bg0.ignoresSafeArea())
    .navigationTitle("").navigationBarTitleDisplayMode(.inline)
    .task(id: session.session?.user.id) { courses = []; total = 0; await load() }
    .task(id: term) { await search() }
    .refreshable { await load() }
  }

  private func courseRow(_ course: CourseHomeEntry) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      HStack(alignment: .top, spacing: CSTokens.Space.s3) {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          Text(course.name).csType(.displayS).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
          if !course.place.isEmpty { Text(course.place).csType(.agateS).foregroundStyle(cs.mut) }
        }.frame(maxWidth: .infinity, alignment: .leading)
        CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut).padding(.top, CSTokens.Space.s1)
      }
      if !course.people.isEmpty {
        CSFaceRow(course.people.map { .init(id: $0.id, marker: $0.marker) }, style: .overlapped)
      }
      Text(course.line).csType(.bodyS).foregroundStyle(cs.mut)
    }
    .padding(.vertical, CSTokens.Space.s2)
    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    .contentShape(Rectangle())
  }

  @ViewBuilder private var searchResults: some View {
    if term.count < 2 {
      Text("Enter at least two letters.").csType(.bodyS).foregroundStyle(cs.mut)
    } else if searching {
      Text("Finding courses…").csType(.bodyS).foregroundStyle(cs.mut)
    } else {
      if offline { Text(CourseBookCopy.searchOffline).csType(.bodyS).foregroundStyle(cs.mut) }
      if results.isEmpty && !offline {
        Text("No courses found. Try another name or city.").csType(.bodyS).foregroundStyle(cs.mut)
      }
      ForEach(results) { hit in
        CSRule()
        NavigationLink { CourseScreen(courseId: hit.id, label: hit.label) } label: {
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text(hit.label).csType(.social).foregroundStyle(cs.ink)
            if !hit.place.isEmpty { Text(hit.place).csType(.agateS).foregroundStyle(cs.mut) }
          }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("courses.search.\(hit.id)")
      }
    }
  }

  private func load() async {
    generation += 1; let stamp = generation
    let account = session.session?.user.id
    loading = true; error = nil
    defer { if stamp == generation { loading = false } }
    do {
      let json = try await RoundSocialService().request("course_home")
      guard stamp == generation, account == session.session?.user.id else { return }
      guard json["ok"]?.bool == true else { error = "The courses in your circle could not be loaded."; return }
      courses = (json["courses"]?.array ?? []).compactMap(CourseHomeEntry.init)
      total = json["courses_total"]?.int ?? courses.count
    } catch {
      guard stamp == generation, account == session.session?.user.id else { return }
      self.error = HumanError.text(error, prefix: "Could not load your circle’s courses.")
    }
  }

  private func search() async {
    let wanted = term
    results = []; offline = false; searching = wanted.count >= 2
    guard wanted.count >= 2 else { return }
    do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
    let answer = await CourseHomeSearch.find(wanted)
    guard !Task.isCancelled, wanted == term else { return }
    results = answer.hits; offline = answer.offline; searching = false
  }
}

/// Shared by Home and the navigation test, so the test enters the real screen.
struct CourseHomeLink: View {
  var body: some View {
    NavigationLink { CourseHomeScreen() } label: {
      Text("Courses").csType(.bodyS).frame(minHeight: 44)
    }.accessibilityIdentifier("home.courses")
  }
}

private struct CourseHomeEntry: Identifiable {
  let id: String
  let name: String
  let place: String
  let friends: Int
  let rounds: Int
  let people: [SocialPerson]
  init?(_ json: JSONValue) {
    guard let id = json["api_course_id"]?.string, !id.isEmpty,
          let name = json["name"]?.string else { return nil }
    self.id = id; self.name = name
    place = [json["city"]?.string, json["state"]?.string].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    friends = json["friends_total"]?.int ?? 0
    rounds = json["rounds_total"]?.int ?? 0
    people = (json["people"]?.array ?? []).compactMap { SocialPerson($0["person"]) }
  }
  var line: String {
    let played = "\(rounds) \(rounds == 1 ? "round" : "rounds")"
    return friends > 0 ? "\(friends) \(friends == 1 ? "friend has" : "friends have") played here · \(played)" : "\(played) in your circle"
  }
}

private enum CourseHomeSearch {
  static func find(_ query: String) async -> CourseSearchAnswer {
    #if DEBUG
    if SocialBlendFixture.enabled {
      return .init(hits: query.localizedCaseInsensitiveContains("north")
        ? [.init(id: "fixture-north-grove", label: "North Grove", place: "Oak Valley, CA", tees: [])] : [], offline: false)
    }
    #endif
    return await CourseBookStore().searchCourses(query)
  }
}

// Cup Season — Home "Coming up" (`homeRoundCard` 10682, `renderHomeRounds`
// 10699, `fillHomeWeather` 10720; Stage 6 of the round-object arc). The next
// few rounds — yours + your circle (Home keeps buddies, D38) — as rich cards
// that tap into the round object, with a course + RSVP glance and a lazy
// weather peek.

import SwiftUI
import CSDesign
import CupSeasonKit

struct UpcomingRoundsSection: View {
  @Environment(\.cs) private var cs
  @State private var vm = UpcomingModel()
  @State private var openRoundId: UUID? = nil
  let links: CSLinks

  init(links: CSLinks = CSLinks()) { self.links = links }

  var body: some View {
    // D176 · this section used to VANISH when nothing was booked, which is
    // exactly the moment a golfer needs the calendar most — and even when it
    // showed, it listed rounds and never once offered the calendar itself,
    // though "Around your buddies" three slots up has offered THE BOARD ↗ all
    // along. Same pattern, same place, no new vocabulary.
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline) {
          Text("Coming up").csEyebrow(cs.mut)
          Spacer()
          NavigationLink(value: HomeRoute.schedule) { Text("THE CALENDAR ↗").csEyebrow(cs.dawn).a11yHitSlop() }
        }
        CSHairline()
      }
      .padding(.top, 10)

      if vm.rounds.isEmpty {
        NavigationLink(value: HomeRoute.schedule) {
          HStack(spacing: 10) {
            Image(systemName: "calendar.badge.plus").font(.system(size: 16)).foregroundStyle(cs.brand)
            Text("Put a round on the calendar").font(CSFont.subhead).foregroundStyle(cs.ink)
            Spacer()
            Text("→").font(CSFont.subhead).foregroundStyle(cs.brand)
          }
          .padding(12)
          .frame(minHeight: 44)
          .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
      } else {
        ForEach(vm.rounds) { sr in
          HomeRoundCard(sr: sr, weather: sr.id.flatMap { vm.weather[$0] })
            .contentShape(Rectangle())
            .onTapGesture { if let id = sr.id { if let f = links.openRound { f(id) } else { openRoundId = id } } }
        }
      }
    }
    .task { await vm.load() }
    .sheet(item: $openRoundId, onDismiss: { Task { await vm.load() } }) { id in
      ScheduledRoundSheet(roundId: id, fallback: vm.rounds.first { $0.id == id }, links: links)
    }
  }
}

struct HomeRoundCard: View {
  @Environment(\.cs) private var cs
  let sr: ScheduledRound
  let weather: Weather?

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      CSFace(marker: sr.marker, size: 36)
      VStack(alignment: .leading, spacing: 3) {
        (Text(sr.play_on.map { ScheduleDates.when($0) } ?? "").bold()
         + (sr.relTag.map { Text(" · ") + Text($0).font(CSFont.label).foregroundStyle(cs.dimText) } ?? Text("")))
          .font(CSFont.subhead).foregroundStyle(cs.ink)
        bits.font(CSFont.monoSmall).foregroundStyle(cs.mut)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      VStack(alignment: .trailing, spacing: 4) {
        if let n = sr.rsvp_in, n > 0 {
          Text("\(n) in").font(CSFont.label).foregroundStyle(cs.pos).padding(.horizontal, 8).padding(.vertical, 3).background(cs.pos.opacity(0.14), in: Capsule())
        }
        if let c = sr.comment_n, c > 0 {
          HStack(spacing: 3) { Image(systemName: "bubble.left").font(.system(size: 11)); Text("\(c)").font(CSFont.label) }.foregroundStyle(cs.mut)
        }
        if let w = weather { Text(w.glance).font(CSFont.label).foregroundStyle(cs.mut) }
      }
    }
    .padding(12)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
  }

  private var bits: Text {
    var t = Text(sr.who)
    if let c = sr.course_label { t = t + Text(" · \(c.uppercased())") }
    let tee = TeeTime.format(sr.tee_time)
    if !tee.isEmpty { t = t + Text(" · ") + Text(tee).foregroundStyle(cs.gold) }
    return t
  }
}

@MainActor
@Observable
final class UpcomingModel {
  var rounds: [ScheduledRound] = []
  var weather: [UUID: Weather] = [:]
  private let sched = ScheduleService()

  func load() async {
    let all = (try? await sched.watch()) ?? []
    rounds = CalendarBuilder.homeRounds(all)
    // lazy, cached server-side, fail-silent — no glance is fine, never a blank
    for sr in rounds {
      guard let id = sr.id, let cid = sr.course_id, let on = sr.play_on, weather[id] == nil else { continue }
      if let w = await sched.weather(lat: nil, lon: nil, date: on, courseId: cid) { weather[id] = w }
    }
  }
}

#Preview("Coming up") {
  let json = """
  {"id":"\(UUID().uuidString)","display_name":"Galen","marker":"saguaro","play_on":"\(CSDate.today())","course_label":"Papago GC",
   "tee_time":"07:40:00","mine":false,"is_friend":true,"shared_league":false,"rsvp_in":3,"comment_n":2}
  """
  let sr = try! JSONDecoder().decode(ScheduledRound.self, from: Data(json.utf8))
  return HomeRoundCard(sr: sr, weather: Weather(hi: 71, lo: 55, wind: 9, summary: "Clear", icon: "sun")).padding(20).csTheme()
}

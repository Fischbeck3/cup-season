#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

/// Actual production renderers on synthetic local RPC payloads. Never starts
/// auth, telemetry, push, or a network read. Every launch is explicitly opted in.
@MainActor enum CompeteSelectedFixture {
  static var on: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_compete_selected") }
  static func arg(_ key: String,_ fallback: String) -> String {
    let a=ProcessInfo.processInfo.arguments
    return a.firstIndex(of:key).flatMap { $0+1<a.count ? a[$0+1] : nil } ?? fallback
  }
  static var kind: String { arg("-cs_selected_fixture","squads") }
  static var screen: String { arg("-cs_selected_screen","book") }
  static let books: [SeasonBookSnapshot] = [SeasonBookFixtureJSON.squads,SeasonBookFixtureJSON.tie,SeasonBookFixtureJSON.upcoming,SeasonBookFixtureJSON.finished].map { try! JSONDecoder().decode(SeasonBookSnapshot.self,from:Data($0.utf8)) }
  static var book: SeasonBookSnapshot { books[["squads","tie","upcoming","finished"].firstIndex(of:kind) ?? 0] }
  static func book(_ league: UUID) -> SeasonBookSnapshot { books.first { $0.league_id == league } ?? book }
  static var me: Me {
    var json=try! JSONSerialization.jsonObject(with:Data(SeasonBookFixtureJSON.home.utf8)) as! [String:Any]
    // The shared decoder accepts Postgres's fractional ISO timestamps.
    if kind != "multi" { json["memberships"]=(json["memberships"] as! [[String:Any]]).filter { ($0["league_id"] as? String)==book.league_id.uuidString.lowercased() } }
    let decoder=JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let s=try decoder.singleValueContainer().decode(String.self)
      let f=ISO8601DateFormatter();f.formatOptions=[.withInternetDateTime,.withFractionalSeconds]
      if let d=f.date(from:s) { return d }; f.formatOptions=[.withInternetDateTime]
      if let d=f.date(from:s) { return d }; throw SeasonBookReadError.unavailable
    }
    return try! decoder.decode(Me.self,from:JSONSerialization.data(withJSONObject:json))
  }
  static func seed(_ model: LeagueRoomModel) {
    let b=book(model.leagueId), golfers=b.rows.filter { $0.kind == "golfer" }, squads=b.rows.filter { $0.kind == "squad" }
    let viewer=golfers.first { $0.mine } ?? golfers[0]
    model.seed(viewer:.init(id:viewer.member_id!,displayName:viewer.name,marker:"saguaro",indexCurrent:12,roundsCount:12),
      league:.init(id:b.league_id,name:b.name,code:"LOCAL",phase:b.status == "complete" ? "complete" : "season",commissioner_id:golfers[0].member_id),
      settings:.init(league_id:b.league_id,counting_cap:b.counting_cap,participation_floor:b.participation_floor,buyin_cents:0,structure:b.structure,finish:"points_table"),
      season:.init(id:b.season_id,starts_on:b.starts_on,ends_on:b.ends_on,status:b.status,champion_member_id:b.status == "complete" ? golfers[0].member_id : nil),
      members:golfers.map { .init(id:$0.member_id!,role:"player",profile_id:$0.member_id!,profile:.init(display_name:$0.name,marker:"saguaro",index_current:12)) },
      squads:squads.enumerated().map { i,s in .init(id:s.squad_id!,name:s.name,color:i,squad_members:b.rows.filter { $0.kind == "contribution" && $0.squad_id == s.squad_id }.map { .init(member_id:$0.member_id!) }) },
      squadStandings:squads.map { .init(squad_id:$0.squad_id!,points:Double($0.points)) },
      indiv:golfers.map { .init(member_id:$0.member_id!,points:Double($0.points),rounds_posted:$0.entries.filter(\.isRound).count) },today:"2026-09-24")
  }
}

struct CompeteSelectedFixtureView: View {
  @Environment(\.csLookAccent) private var livery
  @State private var path: [UUID] = []
  @State private var presenter=Presenter()
  @State private var receipt: UUID?
  private var links: LeagueRoomLinks { .init(openBoard:{},openSchedule:{},openWizard:{},openDraft:{},openReceipt:{ receipt=$0 },openTourCard:{ _ in },addGolfers:{}) }
  var body: some View {
    NavigationStack(path:$path) {
      Group {
        switch CompeteSelectedFixture.screen {
        case "root": CompeteScreen(links:CSLinks(),push: { route in if case .season(let id,_) = route { path.append(id) } })
        case "receipt":
          let b=CompeteSelectedFixture.book, r=b.rows.first { $0.kind == "golfer" && $0.mine }!
          SeasonBookReceipts(title:r.name + " · Week 12",entries:r.entries.filter { $0.week == 12 },names:Dictionary(uniqueKeysWithValues:b.rows.filter { $0.kind == "golfer" }.map { ($0.member_id!,$0.name) }),openRound:{ receipt=$0 })
        case "season": SeasonPage(leagueId:CompeteSelectedFixture.book.league_id,links:links)
        default: SeasonBookPage(fixture:CompeteSelectedFixture.book,openRound:{ receipt=$0 })
        }
      }.navigationDestination(for:UUID.self) { id in SeasonPage(leagueId:id,links:links) }
    }.environment(\.presenter,presenter)
      .tint(livery.accent) // Match the normal MainTabView shell.
      .sheet(item:$receipt) { id in Text("Round receipt fixture · \(id.uuidString)").padding() }
  }
}
#endif

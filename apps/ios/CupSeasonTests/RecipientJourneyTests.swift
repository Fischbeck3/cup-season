import Foundation
import Testing
import SwiftUI
import CSDesign
import CupSeasonKit
@testable import CupSeason

@MainActor @Suite struct RecipientJourneyTests {
  private let league = UUID(uuidString: "c5000000-0000-4000-8000-000000000100")!
  private func membership(_ code: String) -> Me.Membership {
    .init(league_id:league,name:"North Grove (fixture)",code:code,phase:"season",sandbox:true,
          role:"member",member_id:UUID(),marker:nil,commissioner_name:nil,settings:nil,
          season:nil,squad:nil,standing:nil,pulse:nil)
  }
  private func terms(_ agreed: Bool) -> Covenant {
    Covenant(name:"North Grove (fixture)",buyinCents:0,preset:"standard",floor:2,
             finish:"cup_final",seasonNumber:2,reup:true,agreed:agreed)
  }
  @Test func recordedYesOpensOnlyItsOwnSeasonAndSpendsOnlyItsOwnCode() throws {
    let key = "recipient-journey-" + UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName:key))
    defer { defaults.removePersistentDomain(forName:key) }
    let model = JoinModel(code:" ngfx26 ",toasts:CSToastCenter())
    model.covenant = terms(true)
    JoinIntent.store("NGFX26",name:"North Grove (fixture)",defaults:defaults)
    #expect(model.openExisting(in:[membership("OTHER"),membership("ngfx26")],defaults:defaults)==league)
    #expect(JoinIntent.pending(defaults:defaults)==nil && model.joinedId==nil && model.welcome==nil)
    JoinIntent.store("NEWONE",defaults:defaults)
    #expect(model.openExisting(in:[membership("NGFX26")],defaults:defaults)==league)
    #expect(JoinIntent.pending(defaults:defaults)?.code=="NEWONE")
  }
  @Test func missingMembershipOrUnagreedTermsKeepTheInvitation() throws {
    let key = "recipient-journey-" + UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName:key))
    defer { defaults.removePersistentDomain(forName:key) }
    JoinIntent.store("NGFX26",defaults:defaults)
    let model = JoinModel(code:"NGFX26",toasts:CSToastCenter())
    for agreed in [false,true] {
      model.covenant = terms(agreed)
      #expect(model.openExisting(in:agreed ? [] : [membership("NGFX26")],defaults:defaults)==nil)
      #expect(model.note != nil && JoinIntent.pending(defaults:defaults)?.code=="NGFX26")
    }
  }
  @Test func theAgreedSheetShowsAnAccessibleSeasonDoorWithoutJoinTerms() throws {
    for theme: ColorScheme in [.dark,.light] {
      for width: CGFloat in [375,402] {
        let host=HostedLayout(CovenantSheet(covenant:terms(true),onJoin:{},onNo:{},onOpen:{}),
                              width:width,height:1800,typeSize:.accessibility3,scheme:theme)
        defer { host.tearDown() }
        let door=try #require(host.elements(prefix:"covenant.openSeason").first)
        // CS name type renders uppercase; the spoken words must stay exact.
        #expect(door.label.lowercased()=="open the season", "Actual accessible label: \(door.label)")
        #expect(door.frame.height>=43.99)
        #expect(host.elements(prefix:"covenant.group.").isEmpty && host.horizontalScrollers.isEmpty)
      }
    }
  }
}

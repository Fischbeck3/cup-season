import Foundation

/// D400 · the widgets' read with nobody looking at the app.
///
/// The between-round widgets used to change only when Home loaded, so a golfer
/// who had not opened the app saw the same tile for days — and a widget that
/// only moves when the app is opened cannot bring anybody back to it. This is
/// Home's own read, minus the screen: `home_dispatch` once, the same
/// arrangement Home draws (`HomeRank.arrange`, served rank, F12's played-plan
/// drop), then the four slices. It writes nothing to the server.
///
/// The IOS-034 rules hold unchanged: it runs only for the golfer who owns the
/// snapshot (`DispatchSnapshot.belongs`), the extension still holds no client,
/// and every slice keeps its own clock. The app process runs it from a
/// `BGAppRefreshTask`; the session is the one already in the Keychain
/// (`DeviceOnlyAuthStorage`, readable after first unlock).
@MainActor public enum WidgetBackgroundRead {
  /// True when the ranker answered and What's On was written.
  @discardableResult
  public static func run(svc: SupabaseService = .shared) async -> Bool {
    guard let session = await svc.currentSession() else { return false }
    let owner = session.user.id
    let defaults = UserDefaults(suiteName: CSAppGroup.id)
    guard DispatchSnapshot.belongs(to: owner, defaults: defaults), !Task.isCancelled else { return false }
    guard let served = await HomeStreamRepository(svc).dispatch(days: 21), !Task.isCancelled else { return false }
    var items = served.items
    // F12 · a booking already PLAYED stops saying a round is scheduled (Home's own step)
    if items.contains(where: { $0.key.hasPrefix("plan:") }) {
      let rows = (try? await RoundsRepository(svc).myRounds(owner)) ?? []
      items = RoundReconcile.droppingPlayedPlans(items, myRounds: rows.map {
        RoundReconcile.Candidate(id: $0.id, courseId: $0.api_course_id, playedOn: $0.played_on)
      })
    }
    guard !Task.isCancelled else { return false }
    let ranked = HomeRank.arrange(items, leadSuppress: served.leadSuppress, useServerRank: true, allowLead: true)
    BetweenRoundsFeed.shared.publishWhatsOn(lead: ranked.lead, deck: ranked.deck, owner: owner)
    let me: Me?
    if let m = served.me { me = m } else { me = try? await SupabaseMeRepository(svc).load(userId: owner) }
    if let me, !Task.isCancelled {
      await BetweenRoundsFeed.shared.refresh(
        me: me, preferredLeague: UserDefaults.standard.string(forKey: CSConfig.lastLeagueKey).flatMap(UUID.init))
    }
    return true
  }
}

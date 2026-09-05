// Cup Season — IOS-034 · the app's half of the home-screen surface.
//
// `DispatchSnapshot` is compiled into the widget extension too, so it knows
// nothing about the Kit. This file is the Kit's half: it turns the ME strip and
// the ranked lead — the two producers Home already has — into the eight strings
// the widget draws, and writes them into the App Group.
//
// It produces NOTHING of its own. Every word here was written by
// `MeStripCopy` or by `home_dispatch`'s own ranker, which is what keeps L-34
// true across a surface the app cannot see: the widget and Home cannot
// disagree, because there is only one set of sentences.

import Foundation

public enum DispatchSnapshotFeed {

  /// The snapshot for a loaded Home. `lead` is the arranged lead card, or nil
  /// when the veto/fence left none — in which case the widget draws the season
  /// row and the facts, and offers no verb (L-44: never a door we cannot name).
  public static func make(strip: MeStripCopy.Strip, lead: HomeDispatch.Item?, now: Date = Date()) -> DispatchSnapshot {
    DispatchSnapshot(
      seasonRow: strip.seasonRow?.text,
      facts: strip.slots.map { .init(label: $0.label, value: $0.value) },
      leadEyebrow: lead?.eyebrow,
      leadHeadline: lead?.headline,
      leadVerb: lead?.action,
      leadRoute: lead.flatMap(routeURL),
      savedAt: now)
  }

  /// The deep link a lead's own route resolves to — and ONLY the ones this app
  /// actually claims today. `DeepLink.of(_:)` resolves exactly one custom-scheme
  /// URL (`cupseason://live`, D155's tap-back); everything else opens the app on
  /// Home, which is where the lead card is anyway. Writing `cupseason://season/…`
  /// here would be a door that does not open — the one dishonesty L-32 forbids —
  /// so a route the app cannot resolve is left nil and the widget links Home.
  /// A later wave that claims more URLs gets the rest of the routes by adding
  /// its case here.
  public static func routeURL(_ item: HomeDispatch.Item) -> String? {
    guard let route = item.route else { return nil }
    switch route {
    case .live: return "\(DeepLink.liveScheme)://\(DeepLink.liveHost)"
    default:    return nil
    }
  }

  /// Write it, unless nothing would be drawn. An empty snapshot is not written
  /// over a good one: a failed read is never an empty screen (L-32).
  @discardableResult
  public static func publish(strip: MeStripCopy.Strip, lead: HomeDispatch.Item?, now: Date = Date(),
                             defaults: UserDefaults? = UserDefaults(suiteName: CSAppGroup.id)) -> Bool {
    guard !strip.isEmpty || lead != nil else { return false }
    return make(strip: strip, lead: lead, now: now).write(defaults)
  }
}

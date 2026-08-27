// Cup Season — backend coordinates.
//
// Both values are public: they are served in plain sight inside index.html on
// every page load of cupseason.app, which is what "publishable" means. The key
// grants nothing on its own — D37 left `anon` with ZERO relation privileges and
// exactly ten callable RPCs, proven by probing prod with this key and getting
// zero rows from every table. The things that ARE secret (VAPID, the push
// webhook secret, Brevo, the Anthropic key, the APNs key) live in Supabase
// secrets and are never reachable from a client.

import Foundation

public enum CSConfig {
  public static let supabaseURL = URL(string: "https://zddbfcokmvneltrgukzf.supabase.co")!
  public static let supabasePublishableKey = "sb_publishable_UoORp_4FTRWg6a7foKqxRA_N2f5kHVS"
  public static let webOrigin = URL(string: "https://cupseason.app")!
  public static let legalURL = URL(string: "https://cupseason.app/legal.html")!
  /// legal.html#privacy · #terms · #pot
  public static func legal(_ anchor: String) -> URL { URL(string: "https://cupseason.app/legal.html#\(anchor)")! }

  /// Last league the person had open — the web's `cs_last_league`.
  public static let lastLeagueKey = "cs_last_league"
  /// Orientation shown once per device — the web's `cs_oriented`.
  public static let orientedKey = "cs_oriented"
  /// The Forge plays fully once per device — the web's `cs_forge`.
  public static let forgeKey = "cs_forge"
}

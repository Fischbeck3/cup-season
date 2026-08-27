// Cup Season — the board's text helpers, ported from index.html.
//
//   easeCaps   4651   server bodies arrive ALL CAPS; ease them into a sentence
//   csNames    4600   the proper-noun registry easeCaps restores from
//   dAgo/DOW   3722   date separators ("Wed · Aug 26", "Today · Aug 27")
//   dfmtShort  9654   "Aug 22"
//   humanError 4084   transport failures, phrased for a person

import Foundation

public enum BoardText {
  public static let MOS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  public static let DOW = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  /// #10: multi-word squad/course names that are ordinary golf phrases stay
  /// out of the registry.
  static let commonPhrases: Set<String> = [
    "back nine", "front nine", "the turn", "the open", "the pot", "par three", "par four",
    "par five", "no minimum", "the crew", "the books", "on the", "all square",
  ]

  /// The name registry (#13): lowercased → canonical. Multi-word only.
  public struct NameRegistry: Sendable, Equatable {
    public private(set) var names: [String: String] = [:]
    public init() {}
    public mutating func learn(_ list: [String?]) {
      for raw in list {
        let n = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let lc = n.lowercased()
        if n.count > 2, n.contains(" "), !BoardText.commonPhrases.contains(lc), names[lc] == nil {
          names[lc] = n
        }
      }
    }
  }

  /// `easeCaps` — mixed-case strings pass through untouched.
  public static func easeCaps(_ s: String?, names: NameRegistry = NameRegistry()) -> String {
    guard let s, !s.isEmpty, s == s.uppercased() else { return s ?? "" }
    var t = s.lowercased()
    t = replace(t, #"(^|[.!?]\s+|·\s+|—\s+)([a-z])"#) { m in m[1] + m[2].uppercased() }           // sentence & segment starts
    t = replace(t, #"(^|[^'])\b([b-hj-z])\b"#) { m in m[1] + m[2].uppercased() }                   // name initials (never a/i, never 's)
    t = replace(t, #"\b(sun|mon|tue|wed|thu|fri|sat|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\b"#) { m in
      m[1].prefix(1).uppercased() + m[1].dropFirst()                                                  // days & months
    }
    t = replace(t, #"\b(with|vs|to)\s+([a-z])"#, caseInsensitive: true) { m in m[1] + " " + m[2].uppercased() }  // names after with/vs/to
    t = replace(t, #"&\s+([a-z])"#) { m in "& " + m[1].uppercased() }                                // names after &
    let keys = names.names.keys.sorted { $0.count > $1.count }
    if !keys.isEmpty {
      let alt = keys.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
      t = replace(t, #"\b("# + alt + #")\b"#, caseInsensitive: true) { m in names.names[m[1].lowercased()] ?? m[1] }
    }
    return t
  }

  private static func replace(_ s: String, _ pattern: String, caseInsensitive: Bool = false, _ f: ([String]) -> String) -> String {
    guard let rx = try? NSRegularExpression(pattern: pattern, options: caseInsensitive ? [.caseInsensitive] : []) else { return s }
    let ns = s as NSString
    var out = ""
    var last = 0
    for m in rx.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
      out += ns.substring(with: NSRange(location: last, length: m.range.location - last))
      var groups: [String] = []
      for i in 0..<m.numberOfRanges {
        let r = m.range(at: i)
        groups.append(r.location == NSNotFound ? "" : ns.substring(with: r))
      }
      out += f(groups)
      last = m.range.location + m.range.length
    }
    out += ns.substring(from: last)
    return out
  }

  /// The board's date separator for a real post: "Wed · Aug 26" (14395).
  public static func dateLabel(_ date: Date, calendar: Calendar = .current) -> String {
    let c = calendar.dateComponents([.weekday, .month, .day], from: date)
    return "\(DOW[max(0, (c.weekday ?? 1) - 1)]) · \(MOS[max(0, (c.month ?? 1) - 1)]) \(c.day ?? 1)"
  }

  /// `dAgo(0)` — the synthetic row's separator: "Today · Aug 27" (3727).
  public static func todayLabel(_ now: Date = Date(), calendar: Calendar = .current) -> String {
    let c = calendar.dateComponents([.month, .day], from: now)
    return "Today · \(MOS[max(0, (c.month ?? 1) - 1)]) \(c.day ?? 1)"
  }

  /// `dfmtShort` — "Aug 22" from a calendar date, never through UTC.
  public static func shortDate(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return "" }
    let c = calendar.dateComponents([.month, .day], from: d)
    return "\(MOS[max(0, (c.month ?? 1) - 1)]) \(c.day ?? 1)"
  }

  /// `firstTeeText` — "Sun May 3": the REAL weekday, never a hardcoded Sun.
  public static func firstTee(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    let c = calendar.dateComponents([.weekday, .month, .day], from: d)
    return "\(DOW[max(0, (c.weekday ?? 1) - 1)]) \(MOS[max(0, (c.month ?? 1) - 1)]) \(c.day ?? 1)"
  }

  static func describe(_ error: Error?) -> String {
    guard let error else { return "" }
    if let e = error as? RpcError { return e.underlying }
    if let e = error as? LocalizedError, let d = e.errorDescription { return d }
    return String(describing: error)
  }

  /// `humanError(e, prefix)` — the web's phrasing for a failure, verbatim.
  public static func humanError(_ error: Error?, _ prefix: String? = nil) -> String {
    let m = describe(error).lowercased()
    let msg: String
    if matches(m, #"failed to fetch|networkerror|network request|load failed|timeout|offline|not connected"#) {
      msg = "Connection hiccup — check your signal and try again."
    } else if matches(m, #"jwt|not authenticated|auth session|invalid.*token|permission denied|row-level|not logged in"#) {
      msg = "Please sign in again."
    } else if matches(m, #"schema cache|does not exist|could not find the|no function matches|column .* does not"#) {
      msg = "Just updated — give it a second and try again."
    } else if matches(m, #"can rsvp to this round|only the host and tagged"#) {
      msg = "Only the host and the players they tagged can RSVP."
    } else if matches(m, #"duplicate key|already exists|unique constraint"#) {
      msg = "That already exists."
    } else if matches(m, #"violates|constraint|not-null|null value|invalid input"#) {
      msg = "That didn't go through — please try again."
    } else {
      msg = "Something went wrong — please try again."
    }
    return prefix.map { $0 + " " + msg } ?? msg
  }

  /// The scorecard's own skew line (10346): a missing function is the
  /// client shipping ahead of the migration, not the user's tap.
  public static func isSchemaSkew(_ error: Error?) -> Bool {
    matches(describe(error).lowercased(), #"function|schema cache"#)
  }

  private static func matches(_ s: String, _ pattern: String) -> Bool {
    s.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
  }
}

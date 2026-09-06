// Cup Season — ONBOARDING ASKS THREE THINGS, IN A GOLFER'S UNITS (D247, D233,
// D224; IOS-033; IA §5; CORE_FLOWS §1).
//
// Eight surfaces became four frames and three questions, and every sentence
// below is produced HERE so the phone and the web ask the same thing in the
// same words (D234). What changed, and why each change is a rule rather than a
// preference:
//
//   1 · THE HANDICAP IS ASKED IN SCORES. "What do you usually shoot?" in five
//       bands, not "index" in a decimal field. A golfer knows the first and
//       most do not know the second.
//
//   2 · THE MARKER AND THE HANDLE ARE DEFAULTED, NOT ASKED. L-08 requires them
//       SET, not CHOSEN. The handle auto-fills from the name (as it already
//       did); the marker is assigned from the fourteen and named in a footnote.
//       L-24 is satisfied — the marker is still the floor, still one of the
//       fourteen, still changeable — and NO SILHOUETTE STATE IS CREATED.
//
//   3 · THE GATE IS UNCHANGED AND STAYS `marker` AND `handle`. Defaulting is
//       not skipping: both are written by the save, so the m001 trigger's
//       email-derived row still cannot pass. CLAUDE.md's landmine — "gate
//       onboarding on marker AND handle" — is why `OnboardingGate` is a value
//       with a test rather than a condition inside a view.
//
//   4 · THE THIRD BRIEF QUESTION IS INFERRED, NOT ASKED. "What kind of golf do
//       you play?" comes from the buddy count, the arrival path and the first
//       round. There is no `profiles.play_style`, and D247 drops the four
//       dormant columns that were the standing temptation to ask a fourth
//       question.
//
// THE STARTER SHIPS IN ITS DECLINED FORM (build plan §4 item 1). D124 is an
// owner ruling and it declined seeding the engine from a starter; only the
// owner may overturn it. So the band's figure is held on the DEVICE, labels
// the ME strip `STARTER 13`, and never reaches `profiles` — `score_round`
// reaches its own-differential fallback exactly as D124 intended.

import Foundation
import CSDesign

// MARK: - Question 1 · what do you usually shoot?

/// The five bands, in the order they are read. `starter` is the figure the band
/// implies; **"No idea" implies nothing and says so** — a guess dressed as a
/// number is the thing L-14 and L-44 both forbid.
public enum ScoreBand: String, Sendable, Equatable, CaseIterable, Identifiable {
  case under80, eighties, nineties, hundredPlus, noIdea
  public var id: String { rawValue }

  /// D247's words, verbatim: *Under 80 · 80s · 90s · 100+ · No idea*.
  public var title: String {
    switch self {
    case .under80:     "Under 80"
    case .eighties:    "80s"
    case .nineties:    "90s"
    case .hundredPlus: "100+"
    case .noIdea:      "No idea"
    }
  }

  /// The starter figure, on a course of standard rating and slope. A band is a
  /// range and the figure is its middle — which is exactly why it is labelled
  /// `STARTER` wherever it renders and never `YOUR NUMBER`.
  public var starter: Double? {
    switch self {
    case .under80:     6
    case .eighties:    13
    case .nineties:    20
    case .hundredPlus: 28
    case .noIdea:      nil
    }
  }

  /// What the strip will say if this band is chosen — so the question can show
  /// its own consequence, and so a test can hold it.
  public var stripPreview: String {
    guard let s = starter else { return "— · BUILDING" }
    return "STARTER \(StarterIndex.text(s))"
  }
}

// MARK: - the copy

public enum OnboardingCopy {

  // ---- frame 1 · the door -------------------------------------------------

  /// QB-15 · **ONE SENTENCE THAT SURVIVES BEING READ BY A STRANGER.**
  ///
  /// The whole of what the product said in its first thirty seconds was the
  /// tagline — *"Rally your crew. Post real rounds. Take the cup."* — and two
  /// blind readers stopped on its last noun and never got it back: *"'Take the
  /// cup' — what cup? I still don't know if the cup is a trophy, a prize, or
  /// the money."* Neither could say what the app was, and one of them had come
  /// from a store page whose own first sentence says it plainly.
  ///
  /// So the store listing's sentence comes to the door, and it does the one
  /// thing the tagline could not: it defines the cup at the moment the word is
  /// used, by saying what taking it means. The tagline is untouched — it is
  /// the brand line and it is the same on both clients — and this stands under
  /// it for the stranger who needs it.
  ///
  /// It yields to `PendingLink.doorLine()`: a golfer who arrived from a
  /// friend's link is not a stranger and should be told whose season this is
  /// instead.
  public static let doorPitch =
    "The golf you already play, turned into a season with your friends \u{2014} a running table, and a cup for whoever takes it."

  // ---- frame 2 · the card, one scrolling frame ----------------------------

  public static let cardEyebrow = "Your card"
  public static let cardTitle = "Who’s on the card?"
  public static let cardSub = "Just a name to start — this card follows you into every season."

  /// Question 1, in a golfer's units.
  public static let shootQuestion = "What do you usually shoot?"
  public static let shootSub = "Your number builds itself from three posted rounds. This just gets you started."
  /// QB-08 · the four words the strip preview needed. Every blind reader who
  /// met `STARTER 20` cold on Home read it as a rank or a countdown; nobody
  /// read it as a handicap. It says what the figure IS, once, where the figure
  /// is chosen.
  public static let stripPreviewNote = "\u{2014} the handicap this starts you on."

  /// The one honesty rule that has to be on the screen, not only in the entry.
  public static let shootStarterNote =
    "We’ll call it a starter until three of your own rounds take over."

  public static let nameLabel = "Name"
  public static let namePlaceholder = "First and last"
  public static let nameMissing = "Your name goes on the card."

  /// The handle is DEFAULTED and shown, not asked — it is still editable,
  /// because D247 defaults it and never hides it.
  public static let handleLabel = "@handle"
  public static let handleRule = "3–20 letters, numbers or _. It changes once every 60 days."
  public static let handleBad = "A handle is 3–20 letters, numbers or underscores."

  /// The marker footnote. It names what was assigned, WHAT IT IS FOR, and
  /// where to change it — L-24's floor, stated on the screen that applies it.
  ///
  /// R-14 · the middle clause came back. The baseline sentence — "It's your
  /// face here until you add a photo — and your stamp on every round after."
  /// — is the one TERMINOLOGY §4 holds up as the pattern for defining a noun
  /// at first contact, and D247's replacement said only where to change it.
  /// The floor survived; the teaching did not.
  public static func markerFootnote(_ name: String) -> String {
    "Your marker is \(name) — your face here until you add a photo, and your stamp on every round after. Tap it to pick another, or change it any time from You."
  }
  public static let markerLabel = "Ball marker"

  /// GHIN is off onboarding entirely (D247). This is the sentence the card
  /// carries where it now lives.
  public static let ghinMovedNote = "Adding a GHIN number? It lives on your card, under You."

  public static let save = "Save my card"

  // ---- frame 3 · the crew step (D233) -------------------------------------

  public static let crewEyebrow = "Card saved"
  public static let crewTitle = "Who do you play with?"
  public static let crewSub =
    "Cup Season is a game you play with people you know. Bring one now and your first round already counts for something."

  /// FOUR routes, not three — R-G moved contacts matching from deferred to
  /// built, and it is the one that makes "three of your friends are already
  /// here" a sentence this product can say.
  public enum CrewRoute: String, Sendable, Equatable, CaseIterable, Identifiable {
    case contacts, search, link, later
    public var id: String { rawValue }

    public var title: String {
      switch self {
      case .contacts: "Find your friends"
      case .search:   "Search by name or @handle"
      case .link:     "Text an invite to somebody else"
      case .later:    "Nobody yet — I’ll add them later"
      }
    }

    public var sub: String? {
      switch self {
      case .contacts: "check your contacts for golfers already here"
      case .search:   "if you know what they go by here"
      case .link:     "they don’t need an account to see it"
      case .later:    nil
      }
    }
  }

  /// The order is the reading order: the one most likely to find somebody
  /// first, and the honest exit last. `later` is never dressed as a failure.
  public static let crewRoutes = CrewRoute.allCases

  /// The pinned exit once somebody HAS been added — because "Nobody yet" is
  /// then false, and a screen that offers a sentence it has just disproved is
  /// the thing L-44 forbids.
  public static let crewGo = "Take me in"

  // ---- D251 · consent, and the empty result -------------------------------

  /// The consent sentence, asked at the point of the ask and nowhere else
  /// (wizard step 1 and this step). Verbatim from D251.
  ///
  /// LV-15 · "hashes" is a developer's noun. It fails Test 1 (immediately
  /// understandable) and Test 2 (sounds like a real golfer), and L-33's rule
  /// is that copy says what happens to YOU, not what the system does. The
  /// claim underneath is unchanged and still true (`ContactHash` is a salted
  /// SHA-256 whose salt never leaves the server).
  public static let contactsConsent =
    "We’ll check your contacts against the golfers already here. Your names and numbers never leave the phone — we send a scrambled version, and we keep nothing that doesn’t match."
  public static let contactsAllow = "Check my contacts"
  /// Declining must FINISH the step, not trap it — R-G's own clause.
  public static let contactsDecline = "Not now"

  /// The empty result, specified before the happy path because it is the one
  /// most golfers will get (D251's own tradeoff).
  public static let contactsNone = "None of your contacts is here yet. Text one a link."
  /// The system refused the address book. A different fact from "nobody
  /// matched", and never rendered as one (L-32, L-44).
  public static let contactsRefused = "Contacts are off for Cup Season. You can turn them on in Settings, or search by name."
  /// F-19 · the SERVER is behind, not the golfer's app — they have the latest
  /// client. Blaming the client for a deploy skew sends somebody to the App
  /// Store for an update that does not exist.
  public static let contactsNotYet = "Contact matching isn’t switched on yet — try again shortly."

  /// One match, two matches, many — the sentence the brief asked for, and it
  /// is only ever printed over a real count.
  public static func contactsFound(_ n: Int) -> String? {
    switch n {
    case ..<1: return nil
    case 1:    return "One of your friends is already here."
    default:   return "\(n) of your friends are already here."
    }
  }

  // ---- the first Home the answer buys (D233) -------------------------------

  /// The crew step's answer CHANGES the first Home, and this is the value that
  /// says how — read by `HomeFallbackItems` so the promise is a producer rather
  /// than a paragraph in an entry.
  public enum FirstHome: String, Sendable, Equatable {
    /// One or more buddies added: the lead names them.
    case withPeople
    /// Nobody yet: the lead is the composer — the free door (L-40).
    case alone

    public static func of(buddiesAdded: Int) -> FirstHome { buddiesAdded > 0 ? .withPeople : .alone }
  }
}

// MARK: - the gate

/// CLAUDE.md's landmine as a value: **`marker` AND `handle`**. The m001 signup
/// trigger writes a `profiles` row with an email-derived display name and
/// neither of those, so a row existing proves nothing.
///
/// Defaulting is not skipping. D247 stops ASKING for the marker and the handle;
/// the save still WRITES both, and this is the predicate that says so — which
/// is why it is tested rather than inlined into a view.
public enum OnboardingGate {
  public static func passes(marker: String?, handle: String?) -> Bool {
    let m = (marker ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let h = (handle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return !m.isEmpty && !h.isEmpty
  }

  public static func passes(_ p: Me.Profile?) -> Bool {
    guard let p else { return false }
    return passes(marker: p.marker, handle: p.handle)
  }

  /// The handle the gate DEFAULTS from a typed name — the same derivation the
  /// three-step gate already used, kept so no golfer's handle changes shape.
  public static func handle(from name: String) -> String {
    String(name.lowercased().filter { $0.isLetter || $0.isNumber }.prefix(20))
  }

  /// Whether a defaulted handle is even legal. A one-letter name derives a
  /// one-letter handle, which `set_handle` refuses — so the card asks for the
  /// handle in that case instead of failing at Save.
  public static func handleIsLegal(_ h: String) -> Bool {
    h.range(of: "^[a-z0-9_]{3,20}$", options: .regularExpression) != nil
  }
}

// MARK: - the defaulted marker

/// L-08 needs the marker SET; L-24 needs it to be one of the fourteen and to
/// leave no silhouette. So it is assigned, named and changeable — never
/// chosen from a grid of in-jokes before a stranger has seen a single round.
///
/// The assignment is DETERMINISTIC on the handle so the same golfer gets the
/// same marker on both clients and across a reinstall, and so a test can hold
/// it. It is not random: a marker that changes when you come back is not a
/// floor, it is noise.
public enum MarkerDefault {
  /// The fourteen, read from the generated catalogue so a marker added or
  /// renamed there needs no edit here (and none in the tests).
  public static var allKeys: [String] { CSMarkers.all.map(\.key) }

  public static func assign(handle: String) -> String {
    let all = allKeys
    guard !all.isEmpty else { return "saguaro" }
    // djb2 with an EXPLICIT mod at every step, because the web's twin
    // (`csMarkerDefault`) must land on the same marker and a JS number stops
    // being an integer above 2^53. Accumulating in UInt64 and folding once at
    // the end would diverge on a long handle — and a golfer's marker would
    // differ between their phone and the desk, which is the one thing a floor
    // may not do.
    let seed = handle.unicodeScalars.reduce(into: UInt64(5381)) { acc, u in
      acc = (acc &* 33 &+ UInt64(u.value)) % 4_294_967_296
    }
    return all[Int(seed % UInt64(all.count))]
  }

  /// The marker's own name, for the footnote.
  public static func name(_ key: String) -> String { CSMarkers.marker(key).name }
}

// MARK: - the starter, held on the device

/// D124's declined form, built. The band's figure never leaves the phone: it
/// labels the ME strip and nothing else, and it is SPENT the moment the engine
/// has a number of its own (three posted rounds), because two numbers on one
/// card is the confusion L-34 exists to prevent.
public enum StarterIndex {
  public static let key = "cs_starter_index"

  public static func set(_ band: ScoreBand, defaults: UserDefaults = .standard) {
    if let s = band.starter { defaults.set(s, forKey: key) } else { defaults.removeObject(forKey: key) }
  }

  public static func clear(defaults: UserDefaults = .standard) { defaults.removeObject(forKey: key) }

  /// **A band is not a decimal.** `CSCopy.index` renders an established index
  /// to one place — `12.4` — because that is what the engine produces and what
  /// a golfer's card says. A starter is the MIDDLE OF A RANGE, and printing it
  /// as `13.0` dresses a guess in the engine's own precision, which is exactly
  /// what L-14 forbids and what the `STARTER` label exists to prevent. So a
  /// whole starter prints whole, and a fractional one (a returning golfer's
  /// carried figure) still shows its place.
  public static func text(_ v: Double) -> String {
    v == v.rounded() ? String(Int(v)) : CSCopy.index(v)
  }

  /// nil when there is none, or when the engine has taken over. `engineIndex`
  /// is `profiles.index_current` — the moment it exists the starter is spent.
  public static func current(engineIndex: Double?, defaults: UserDefaults = .standard) -> Double? {
    if engineIndex != nil { return nil }
    guard defaults.object(forKey: key) != nil else { return nil }
    let v = defaults.double(forKey: key)
    return v.isFinite && v > -10 && v < 54 ? v : nil
  }
}

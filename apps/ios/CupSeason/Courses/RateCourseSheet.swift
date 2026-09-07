// Cup Season — rating a course (D275, `surfaces/course.md` §3).
//
// **The rating is content, not a form field**, and the act of rating is a
// fitted sheet, not an alert. Six things in order: the eyebrow, the course,
// the control, the figure, the line, and the two numbers that give the figure
// something to be compared against.
//
// THE GEOMETRY ARGUMENT, STATED IN THE FILE THAT LIVES WITH IT. The first
// draft asserted "44pt minimum target per half", which the geometry cannot
// deliver: five stars × two halves is ten discrete targets and 10 × 44 = 440pt
// against a 362pt measure (335 on an SE). So the half-star hit region is
// **28pt** — above WCAG 2.5.8's 24 × 24, below this system's own 44 — and the
// **−½ / +½ stepper pair at 44pt** is what makes that legal (`UI_SYSTEM`
// §16.2 carries the carve-out by name). The rail is also
// `.accessibilityAdjustable` at 0.5 increments, so VoiceOver never has to hit
// a 28pt target at all.
//
// NO GOLD, IN OR OUT OF THE CONTROL. Filled stars are `ink`; the unfilled
// remainder is `mut`. An average of opinions is not earned (D275), and gold
// may never touch a control in any case (D269 / `LINT-11`).
//
// **D289 · THE STAR IS NO LONGER SET HERE, AND THIS SHEET IS NOT AN ERROR
// MESSAGE ANY MORE.** `rate_course` is LIVE (the owner pushed
// `20261007090000` on 2026-09-07; that file's own "HAS NOT BEEN RUN" header is
// stale), and the page's own rail now sets a star in ONE TAP with no sheet at
// all (`VISUAL_PASS` §5.1). What is left here is the thing a tap cannot do:
// **the sentence.** 140 characters, one line, saved with the star it belongs
// to — the owner's *"what we thought of the course"*, and the whole reason
// `course_ratings` grew a `note` column.
//
// The fine control stays because it is the ACCESSIBLE one: a 28pt half with
// 44pt steppers beside it and an adjustable rail for VoiceOver. A golfer who
// cannot hit a half star on the page can always come here.

import SwiftUI
import CSDesign
import CupSeasonKit

struct RateCourseSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var typeSize

  let courseId: String
  let course: String
  let rating: CourseRating
  let onChange: (CourseRating) -> Void

  @State private var stars: Double = 4.0
  @State private var note: String = ""
  @State private var busy = false
  @State private var failed = false
  /// The star landed and the sentence did not, because this database predates
  /// the column. Said out loud; never dismissed over.
  @State private var noteWaiting = false
  /// D289 · the sentence has a column and a constraint, and the field says so
  /// rather than truncating in silence.
  static let noteCap = 140

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          // T-01 · `YOUR RATING`, never "your card on this course": that noun
          // belongs to the person, and `TERMINOLOGY` §4 check 7 was widened to
          // catch exactly this phrasing aimed at a third object.
          Text("Your rating").csType(.agate, caps: true).foregroundStyle(cs.mut)
          Text(course).csType(.display).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)

          control

          HStack(alignment: .top, spacing: CSTokens.Space.s4) {
            CSFigure(CSRating.format(stars), size: .xl, metal: .ink, label: "Yours")
            Text("Half stars count. Change it any time — the number moves with you.")
              .csType(.body).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          sentence

          CSRule()
          others
          if failed { unavailable }
          if noteWaiting {
            Text("Your rating saved. The sentence needs the next update — it is not lost, it is just not stored yet.")
              .csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }

          CSDoor(.primary(busy ? "Saving" : "Save it") { Task { await save() } })
          if rating.mine != nil {
            Button("Take my rating off") { Task { await remove() } }
              .buttonStyle(.csTertiary(.content))
              .frame(maxWidth: .infinity, alignment: .center)
          }
        }
        .padding(CSTokens.Space.gutter)
      }
      .background(cs.bg0.ignoresSafeArea())
      .csCloseButton { dismiss() }
    }
    .csFittedSheet(560, large: true)
    .onAppear {
      stars = rating.mine ?? rating.stars ?? 4.0
      note = rating.mineNote ?? ""
    }
  }

  // MARK: the sentence (D289)

  /// **One line about the course, 140 characters.** The serif, because it is a
  /// person talking and not a form field — the same face `CSQuote` prints it
  /// back in on the page. There is no formatting, no second screen and no
  /// "read more": the cap is the column's, and a golfer who wants to write a
  /// paragraph about a course cannot.
  @ViewBuilder private var sentence: some View {
    CSField(label: "What you thought",
            placeholder: "Best muni in the state\u{2026}",
            text: $note,
            caption: "Optional. One line, and your golfers see it on the course.",
            limit: Self.noteCap)
      .onChange(of: note) { _, n in
        if n.count > Self.noteCap { note = String(n.prefix(Self.noteCap)) }
      }
  }

  // MARK: the control

  /// A continuous drag rail with a 44pt stepper on either side. The drag maps
  /// *x* to the nearest half and fires `.selection` on every half step; the
  /// steppers are the tap case, and the whole thing is one adjustable element
  /// to VoiceOver.
  private var control: some View {
    HStack(spacing: CSTokens.Space.s3) {
      step("−", enabled: stars > 0.5) { set(stars - 0.5) }
      GeometryReader { geo in
        CSStarRail(stars, size: 40)
          .frame(maxWidth: .infinity, alignment: .leading)
          .contentShape(Rectangle())
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { g in set(value(at: g.location.x, in: geo.size.width), haptic: true) }
          )
      }
      .frame(height: 56)
      step("+", enabled: stars < 5) { set(stars + 0.5) }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Your rating")
    .accessibilityValue(CSStarRail.spoken(stars))
    .accessibilityAdjustableAction { d in
      set(d == .increment ? stars + 0.5 : stars - 0.5, haptic: true)
    }
  }

  private func step(_ glyph: String, enabled: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(glyph).csType(.figureS).foregroundStyle(enabled ? cs.ink : cs.mut)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .accessibilityHidden(true)
  }

  /// *x* → the nearest half star. Five stars over the measure, clamped to the
  /// legal range, so the leading edge is half a star rather than zero: a rail
  /// you cannot drag to zero is the constraint the column carries.
  func value(at x: CGFloat, in width: CGFloat) -> Double {
    guard width > 0 else { return stars }
    let raw = Double(max(0, min(width, x)) / width) * 5
    return min(5, max(0.5, (raw * 2).rounded(.up) / 2))
  }

  private func set(_ v: Double, haptic: Bool = false) {
    let clamped = min(5, max(0.5, (v * 2).rounded() / 2))
    guard clamped != stars else { return }
    stars = clamped
    if haptic { CSHaptic.selection() }
  }

  // MARK: the comparison

  /// §3.7 · **two numbers on one shared rule**, and the `YOURS` cell is gone:
  /// the 56pt figure above IS yours, and printing 4.5 twice 90pt apart is the
  /// same fact rendered twice in one viewport.
  @ViewBuilder private var others: some View {
    if rating.stars != nil || rating.friends != nil {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        HStack(alignment: .top) {
          if let all = rating.stars {
            CSFigure(CSRating.format(all), size: .l, metal: .ink, label: "Cup Season")
          }
          Spacer(minLength: CSTokens.Space.s4)
          if let f = rating.friends {
            VStack(alignment: .trailing, spacing: CSTokens.Space.s1) {
              CSFigure(CSRating.format(f), size: .l, metal: .ink, label: "Your golfers")
            }
          }
        }
        if !rating.countLine.isEmpty {
          Text(rating.countLine).csType(.body).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  /// The write did not land. One sentence, in the product's voice, with the
  /// golfer's number still in the control — never a raw code, and never a
  /// promise that it was queued, because it was not.
  private var unavailable: some View {
    Text("That did not save. Your number is still here — try it again in a moment.")
      .csType(.bodyS).foregroundStyle(cs.mut)
      .fixedSize(horizontal: false, vertical: true)
  }

  // MARK: the write

  private func save() async {
    busy = true
    defer { busy = false }
    do {
      // D289 · the sentence rides the same call. `""` takes it off by the
      // column's own contract, which is why an empty field is sent rather
      // than swallowed.
      let wanted = note.trimmingCharacters(in: .whitespacesAndNewlines)
      let r = try await CourseRatingService().rate(courseId, stars: stars, note: wanted)
      onChange(r)
      // A DATABASE OLDER THAN THE COLUMN TAKES THE STAR AND NOT THE SENTENCE:
      // `p_note` is droppable, so `svc.call` retries without it and succeeds.
      // The aggregate comes back with no note on it, and that is the tell — so
      // the sheet SAYS SO rather than dismissing on a half-saved act.
      if !wanted.isEmpty && (r.mineNote ?? "") != wanted {
        noteWaiting = true
        CSHaptic.impact(.light)
        return
      }
      CSHaptic.impact(.light)
      dismiss()
    } catch {
      // Never a raw code. The sentence above says what is true, and the sheet
      // stays up with the golfer's number still in it.
      failed = true
    }
  }

  private func remove() async {
    busy = true
    defer { busy = false }
    do {
      let r = try await CourseRatingService().unrate(courseId)
      onChange(r)
      dismiss()
    } catch {
      failed = true
    }
  }
}

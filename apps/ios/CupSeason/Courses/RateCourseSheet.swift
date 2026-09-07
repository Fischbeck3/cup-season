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
// AND IT SAYS WHEN IT CANNOT SAVE. `rate_course` is written and NOT PUSHED
// (`supabase/migrations/20261007090000_…`), so on today's database every write
// fails. The sheet says so **in the product's voice, before the golfer
// commits**, rather than letting them drag a rail and meet an error — and it
// promises nothing it cannot do: the number is not queued and not kept. The
// primary is still offered, because a client ahead of its database is a state
// this repo ships deliberately (D261's own posture), and the moment the owner
// pushes, the same button starts working with no client change.

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
  @State private var busy = false
  @State private var failed = false

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

          CSRule()
          others
          if failed || rating.unavailable { unavailable }

          CSDoor(.primary(busy ? "Saving" : "Rate it") { Task { await save() } })
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
    .onAppear { stars = rating.mine ?? rating.stars ?? 4.0 }
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

  /// The client is ahead of its database, and it says so in the one place a
  /// golfer would otherwise meet a silent failure.
  private var unavailable: some View {
    Text("Ratings are not switched on yet, so this one cannot be saved. Everything else on the page is real.")
      .csType(.bodyS).foregroundStyle(cs.mut)
      .fixedSize(horizontal: false, vertical: true)
  }

  // MARK: the write

  private func save() async {
    busy = true
    defer { busy = false }
    do {
      let r = try await CourseRatingService().rate(courseId, stars: stars)
      onChange(r)
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

// Cup Season — D82: "How it works" — the guide sheets and the scoring help
// (index.html `GUIDE` 13011–13034, `openScoringHelp` 17025–17044).

import SwiftUI
import CSDesign
import CupSeasonKit

struct GuideSheetView: View {
  let sheet: GuideSheet
  var body: some View {
    SliceSheet(title: sheet.title, sub: sheet.sub) {
      ForEach(Array(sheet.paragraphs.enumerated()), id: \.offset) { _, p in
        Fine(markdown: p).padding(.bottom, 4)
      }
    }
    .presentationDetents([.medium, .large])
  }
}

struct ScoringHelpSheet: View {
  @Environment(\.cs) private var cs
  var body: some View {
    SliceSheet(title: GuideCopy.scoringTitle, sub: GuideCopy.scoringSub) {
      ForEach(GuideCopy.scoring) { s in
        if !s.eyebrow.isEmpty { Text(s.eyebrow).csEyebrow().padding(.top, 6) }
        ForEach(Array(s.paragraphs.enumerated()), id: \.offset) { _, p in Fine(markdown: p) }
        if !s.bands.isEmpty {
          CSCard(padding: 12) {
            VStack(alignment: .leading, spacing: 4) {
              ForEach(s.bands, id: \.self) { b in Fine(markdown: b) }
            }
          }
        }
      }
    }
  }
}

/// The five `.check` rows under "How it works".
struct HowItWorks: View {
  let open: (GuideCopy.Row) -> Void
  var body: some View {
    VStack(spacing: 8) {
      ForEach(GuideCopy.rows) { r in
        CheckDoor(glyph: Text(r.glyph), title: r.title, sub: r.sub) { open(r) }
      }
    }
  }
}

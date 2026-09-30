import Testing
import SwiftUI
import CSDesign
@testable import CupSeason

@MainActor @Suite struct OwnerN4094BoardTests {
  /// The chat column uses its full measure; the retired coloured spine used
  /// to indent the name and sentence by 3pt plus s3. Read actual laid-out text.
  @Test func chatHasNoSquadGutter() {
    for width: CGFloat in [375, 402] {
      for size: DynamicTypeSize in [.large, .accessibility3] {
        let host = HostedLayout(
          MessageRow {
            Text("Avery Fixture").csType(.name).accessibilityIdentifier("chat.name")
            Text("Anyone playing Saturday?").csType(.body).accessibilityIdentifier("chat.text")
          }.padding(.horizontal, 20), width: width, typeSize: size)
        defer { host.tearDown() }
        let name = host.element("chat.name"), text = host.element("chat.text")
        #expect(name != nil && text != nil)
        #expect(abs((name?.frame.minX ?? 0) - 20) < 1)
        #expect(abs((text?.frame.minX ?? 0) - 20) < 1)
        #expect(host.horizontalScrollers.isEmpty)
      }
    }
  }
}

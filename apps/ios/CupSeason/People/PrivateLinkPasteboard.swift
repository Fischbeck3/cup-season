import UIKit

enum PrivateLinkPasteboard {
  static func copy(_ text: String) {
    UIPasteboard.general.setItems([["public.utf8-plain-text": text]],
                                 options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(600)])
  }
}

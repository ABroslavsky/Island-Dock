import Foundation
import Observation

@MainActor
@Observable
final class IslandModel {
  var session: IslandSession
  let chrome: ChromeConfig
  let motion: MotionConfig
  let commands: CommandConfig
  let appName: String
  var notchCompactHeight: CGFloat
  var notchExpandedWidth: CGFloat
  var notchExpandedHeight: CGFloat

  init(session: IslandSession, config: AppConfig) {
    self.session = session
    self.chrome = config.chrome
    self.motion = config.motion
    self.commands = config.commands
    self.appName = config.appName
    self.notchCompactHeight = config.chrome.fallbackCapsuleHeight
    self.notchExpandedWidth = config.chrome.expandedWidth
    self.notchExpandedHeight = config.chrome.expandedHeight
  }

  func pointerEntered() { session.pointerEntered() }
  func pointerExited() { session.pointerExited() }
  func togglePin() { session.togglePin() }
  func showPinned() { session.pinOpen() }
  func select(_ id: String) { session.select(id) }
}

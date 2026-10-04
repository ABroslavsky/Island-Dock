import Foundation
import Observation

@MainActor
@Observable
final class IslandModel {
  var session: IslandSession
  let chrome: ChromeConfig
  let commands: CommandConfig
  let appName: String

  init(session: IslandSession, config: AppConfig) {
    self.session = session
    self.chrome = config.chrome
    self.commands = config.commands
    self.appName = config.appName
  }

  func pointerEntered() { session.pointerEntered() }
  func pointerExited() { session.pointerExited() }
  func togglePin() { session.togglePin() }
  func showPinned() { session.pinOpen() }
  func select(_ id: String) { session.select(id) }
}

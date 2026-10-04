import Foundation

struct IslandSession: Equatable {
  private(set) var isHovering = false
  private(set) var isPinned = false
  private(set) var activeModuleID: String
  private let moduleIDs: [String]

  init(moduleIDs: [String]) {
    self.moduleIDs = moduleIDs
    self.activeModuleID = moduleIDs.first ?? ""
  }

  var isExpanded: Bool { isHovering || isPinned }

  mutating func pointerEntered() { isHovering = true }
  mutating func pointerExited() { isHovering = false }
  mutating func togglePin() { isPinned.toggle() }
  mutating func pinOpen() { isPinned = true }

  mutating func select(_ id: String) {
    guard moduleIDs.contains(id) else { return }
    activeModuleID = id
  }
}

enum HoverTransition: Equatable {
  case enter
  case exit
  case ignore

  static func decide(inside: Bool, mouseInsideFrame: Bool) -> HoverTransition {
    if inside { return .enter }
    if mouseInsideFrame { return .ignore }
    return .exit
  }
}

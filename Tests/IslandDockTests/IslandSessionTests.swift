import AppKit
import Testing
@testable import IslandDockCore

struct IslandSessionTests {
  @Test func hoverExpandsAndExitCollapses() {
    var session = IslandSession(moduleIDs: ["timer", "todo"])
    #expect(!session.isExpanded)
    session.pointerEntered()
    #expect(session.isExpanded)
    session.pointerExited()
    #expect(!session.isExpanded)
  }

  @Test func pinHoldsOpenAfterExit() {
    var session = IslandSession(moduleIDs: ["timer"])
    session.pointerEntered()
    session.togglePin()
    session.pointerExited()
    #expect(session.isPinned)
    #expect(session.isExpanded)
    session.togglePin()
    #expect(!session.isExpanded)
  }

  @Test func showPinsWithoutHover() {
    var session = IslandSession(moduleIDs: ["timer"])
    session.pinOpen()
    #expect(session.isExpanded)
  }

  @Test func selectRejectsUnknownModule() {
    var session = IslandSession(moduleIDs: ["timer", "todo"])
    session.select("todo")
    #expect(session.activeModuleID == "todo")
    session.select("sports")
    #expect(session.activeModuleID == "todo")
  }

  @Test func emptyModuleListStaysCollapsedIdentity() {
    let session = IslandSession(moduleIDs: [])
    #expect(session.activeModuleID == "")
    #expect(!session.isExpanded)
  }
}

struct IslandPanelTests {
  @Test func panelFollowsSpacesInsteadOfStayingOnScreen() {
    let behavior = IslandPanel.spaceBehavior
    #expect(behavior.contains(.canJoinAllSpaces))
    #expect(behavior.contains(.fullScreenAuxiliary))
    #expect(behavior.contains(.transient))
    #expect(!behavior.contains(.stationary))
  }
}

struct HoverTransitionTests {
  @Test func enterExitAndSpuriousExit() {
    #expect(HoverTransition.decide(inside: true, mouseInsideFrame: false) == .enter)
    #expect(HoverTransition.decide(inside: false, mouseInsideFrame: false) == .exit)
    #expect(HoverTransition.decide(inside: false, mouseInsideFrame: true) == .ignore)
  }
}

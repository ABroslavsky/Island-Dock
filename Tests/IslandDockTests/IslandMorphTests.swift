import CoreGraphics
import SwiftUI
import Testing
@testable import IslandDockCore

struct IslandMorphTests {
  @Test func revealAndRadiusFollowTheBlob() {
    #expect(IslandMorph.reveal(height: 32, compact: 32, expanded: 300) == 0)
    #expect(IslandMorph.reveal(height: 300, compact: 32, expanded: 300) == 1)
    #expect(abs(IslandMorph.reveal(height: 166, compact: 32, expanded: 300) - 0.5) < 0.02)
    #expect(IslandMorph.reveal(height: 340, compact: 32, expanded: 300) == 1)
    #expect(IslandMorph.reveal(height: 32, compact: 32, expanded: 32) == 1)
    #expect(IslandMorph.radius(reveal: 0, compactHeight: 32, expandedRadius: 40) == 16)
    #expect(IslandMorph.radius(reveal: 1, compactHeight: 32, expandedRadius: 40) == 40)
    #expect(IslandMorph.contentScale(reveal: 0, minimum: 0.92) == 0.92)
    #expect(IslandMorph.contentScale(reveal: 1, minimum: 0.92) == 1)
  }

  @Test func openSpringOvershootsThenSettlesOnTheTopEdge() {
    let spring = Spring(duration: 0.5, bounce: 0.18)
    let from = CGRect(x: 100, y: 868, width: 200, height: 32)
    let to = CGRect(x: 0, y: 600, width: 440, height: 300)
    var peak = from.width
    var time = 0.0
    let end = IslandMorph.settled(spring)
    while time <= end {
      let frame = IslandMorph.frame(from: from, to: to, spring: spring, time: time)
      peak = max(peak, frame.width)
      #expect(abs(frame.maxY - to.maxY) < 0.01)
      time += 1.0 / 60.0
    }
    #expect(peak > to.width)
    let settled = IslandMorph.frame(from: from, to: to, spring: spring, time: end)
    #expect(abs(settled.width - to.width) < 0.5)
    #expect(abs(settled.height - to.height) < 0.5)
  }

  @Test func closeSpringShrinksWithoutPassingTheNotch() {
    let spring = Spring(duration: 0.36, bounce: 0)
    let from = CGRect(x: 0, y: 600, width: 440, height: 300)
    let to = CGRect(x: 110, y: 868, width: 220, height: 32)
    var time = 0.0
    let end = IslandMorph.settled(spring)
    while time < end {
      let frame = IslandMorph.frame(from: from, to: to, spring: spring, time: time)
      #expect(frame.height + 0.5 >= to.height)
      #expect(frame.height <= from.height + 0.5)
      #expect(abs(frame.maxY - to.maxY) < 0.01)
      time += 1.0 / 30.0
    }
    let settled = IslandMorph.frame(from: from, to: to, spring: spring, time: end)
    #expect(abs(settled.height - to.height) < 0.5)
  }
}

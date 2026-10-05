import CoreGraphics
import SwiftUI

extension MotionConfig {
  func spring(opening: Bool) -> Spring {
    opening
      ? Spring(duration: openDuration, bounce: openBounce)
      : Spring(duration: closeDuration, bounce: closeBounce)
  }
}

enum IslandMorph {
  static func frame(from: CGRect, to: CGRect, spring: Spring, time: TimeInterval) -> CGRect {
    let t = CGFloat(spring.value(target: 1.0, time: time))
    return CGRect(
      x: from.minX + (to.minX - from.minX) * t,
      y: from.minY + (to.minY - from.minY) * t,
      width: from.width + (to.width - from.width) * t,
      height: from.height + (to.height - from.height) * t
    )
  }

  static func settled(_ spring: Spring) -> TimeInterval {
    spring.settlingDuration(target: 1.0, epsilon: 0.001)
  }

  static func reveal(height: CGFloat, compact: CGFloat, expanded: CGFloat) -> CGFloat {
    let span = expanded - compact
    guard span > 0.5 else { return 1 }
    return min(max((height - compact) / span, 0), 1)
  }

  static func radius(reveal: CGFloat, compactHeight: CGFloat, expandedRadius: CGFloat) -> CGFloat {
    let compactRadius = compactHeight / 2
    return compactRadius + (expandedRadius - compactRadius) * reveal
  }

  static func contentScale(reveal: CGFloat, minimum: CGFloat) -> CGFloat {
    minimum + (1 - minimum) * reveal
  }
}

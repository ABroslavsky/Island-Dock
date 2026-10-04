import CoreGraphics
import Foundation

struct FrameMetrics: Equatable, Sendable {
  var expandedWidth: CGFloat
  var expandedHeight: CGFloat
  var fallbackWidth: CGFloat
  var fallbackHeight: CGFloat
}

struct ScreenSnapshot: Equatable, Sendable {
  var frame: CGRect
  var topInset: CGFloat
  var notchMinX: CGFloat
  var notchMaxX: CGFloat

  var hasNotch: Bool { topInset > 0 && notchMaxX - notchMinX > 1 }
}

enum NotchFrame {
  static func preferred(among screens: [ScreenSnapshot]) -> ScreenSnapshot? {
    screens.first(where: \.hasNotch) ?? screens.first
  }

  static func frame(screen: ScreenSnapshot, metrics: FrameMetrics, expanded: Bool) -> CGRect {
    let compact = compactFrame(screen: screen, metrics: metrics)
    guard expanded else { return compact }

    let width = min(max(metrics.expandedWidth, compact.width), screen.frame.width)
    let height = min(max(metrics.expandedHeight, compact.height), screen.frame.height)
    let rawX = compact.midX - width / 2
    let x = min(max(screen.frame.minX, rawX), screen.frame.maxX - width)
    let y = screen.frame.maxY - height
    return CGRect(x: x, y: y, width: width, height: height)
  }

  private static func compactFrame(screen: ScreenSnapshot, metrics: FrameMetrics) -> CGRect {
    if screen.hasNotch {
      return CGRect(
        x: screen.notchMinX,
        y: screen.frame.maxY - screen.topInset,
        width: screen.notchMaxX - screen.notchMinX,
        height: screen.topInset
      )
    }
    return CGRect(
      x: screen.frame.midX - metrics.fallbackWidth / 2,
      y: screen.frame.maxY - metrics.fallbackHeight,
      width: metrics.fallbackWidth,
      height: metrics.fallbackHeight
    )
  }
}

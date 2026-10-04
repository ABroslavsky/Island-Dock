import CoreGraphics
import Testing
@testable import IslandDockCore

struct NotchFrameTests {
  private let metrics = FrameMetrics(
    expandedWidth: 420,
    expandedHeight: 280,
    fallbackWidth: 200,
    fallbackHeight: 32
  )

  @Test func hardwareNotchUsesAuxiliaryEdges() {
    let screen = ScreenSnapshot(
      frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
      topInset: 37,
      notchMinX: 600,
      notchMaxX: 912
    )
    let frame = NotchFrame.frame(screen: screen, metrics: metrics, expanded: false)
    #expect(frame == CGRect(x: 600, y: 945, width: 312, height: 37))
  }

  @Test func expandedGrowsFromNarrowNotchAndStaysTopAligned() {
    let screen = ScreenSnapshot(
      frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
      topInset: 37,
      notchMinX: 600,
      notchMaxX: 912
    )
    let frame = NotchFrame.frame(screen: screen, metrics: metrics, expanded: true)
    #expect(frame == CGRect(x: 546, y: 702, width: 420, height: 280))
  }

  @Test func expandedDoesNotShrinkBelowWideNotch() {
    let screen = ScreenSnapshot(
      frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
      topInset: 37,
      notchMinX: 100,
      notchMaxX: 1000
    )
    let frame = NotchFrame.frame(screen: screen, metrics: metrics, expanded: true)
    #expect(frame == CGRect(x: 100, y: 702, width: 900, height: 280))
  }

  @Test func displayWithoutNotchUsesFallbackCapsule() {
    let screen = ScreenSnapshot(
      frame: CGRect(x: 1920, y: 0, width: 1440, height: 900),
      topInset: 0,
      notchMinX: 1920,
      notchMaxX: 3360
    )
    let frame = NotchFrame.frame(screen: screen, metrics: metrics, expanded: false)
    #expect(frame == CGRect(x: 2540, y: 868, width: 200, height: 32))
  }

  @Test func expandedClampsToScreen() {
    let screen = ScreenSnapshot(
      frame: CGRect(x: 0, y: 0, width: 300, height: 200),
      topInset: 0,
      notchMinX: 0,
      notchMaxX: 300
    )
    let frame = NotchFrame.frame(screen: screen, metrics: metrics, expanded: true)
    #expect(frame == CGRect(x: 0, y: 0, width: 300, height: 200))
  }

  @Test func prefersNotchedScreen() {
    let external = ScreenSnapshot(frame: CGRect(x: 0, y: 0, width: 800, height: 600), topInset: 0, notchMinX: 0, notchMaxX: 800)
    let builtIn = ScreenSnapshot(frame: CGRect(x: 0, y: 0, width: 1400, height: 900), topInset: 32, notchMinX: 500, notchMaxX: 900)
    #expect(NotchFrame.preferred(among: [external, builtIn]) == builtIn)
    #expect(NotchFrame.preferred(among: []) == nil)
  }
}

import AppKit
import QuartzCore
import SwiftUI

extension ScreenSnapshot {
  @MainActor
  static func capture(_ screen: NSScreen) -> ScreenSnapshot {
    let left = screen.auxiliaryTopLeftArea
    let right = screen.auxiliaryTopRightArea
    return ScreenSnapshot(
      frame: screen.frame,
      topInset: screen.safeAreaInsets.top,
      notchMinX: left?.maxX ?? screen.frame.minX,
      notchMaxX: right?.minX ?? screen.frame.maxX
    )
  }
}

@MainActor
final class IslandPanelController {
  let model: IslandModel
  let panel: IslandPanel
  private let metrics: FrameMetrics
  private let motion: MotionConfig
  private let hoverDelay: TimeInterval
  private var hoverTask: Task<Void, Never>?
  private var morph: Morph?
  private let ticker = FrameTicker()
  private let screenWatch = ScreenWatch()

  init(
    model: IslandModel,
    modules: [IslandModuleDescriptor],
    settings: SettingsModel,
    metrics: FrameMetrics,
    motion: MotionConfig,
    hoverDelay: TimeInterval
  ) {
    self.model = model
    self.metrics = metrics
    self.motion = motion
    self.hoverDelay = hoverDelay
    let panel = IslandPanel(
      contentRect: NSRect(x: 0, y: 0, width: metrics.fallbackWidth, height: metrics.fallbackHeight),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.isFloatingPanel = true
    panel.level = .statusBar
    panel.collectionBehavior = IslandPanel.spaceBehavior
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.isMovable = false
    panel.becomesKeyOnlyIfNeeded = false
    panel.isReleasedWhenClosed = false
    self.panel = panel

    let host = NSHostingView(
      rootView: IslandRootView(model: model, modules: modules, settings: settings, onLayout: { [weak self] in
        self?.layout(animated: true)
      })
    )
    let tracking = HoverView(frame: panel.contentView?.bounds ?? .zero)
    tracking.onHover = { [weak self] inside in
      self?.hover(inside)
    }
    tracking.addSubview(host)
    host.frame = tracking.bounds
    host.autoresizingMask = [.width, .height]
    panel.contentView = tracking
    screenWatch.token = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.layout(animated: false)
      }
    }
  }

  func start() {
    layout(animated: false)
  }

  func show() {
    model.showPinned()
    layout(animated: true)
  }

  func layout(animated: Bool) {
    let screens = NSScreen.screens.map(ScreenSnapshot.capture)
    guard let screen = NotchFrame.preferred(among: screens) else { return }
    let compact = NotchFrame.frame(screen: screen, metrics: metrics, expanded: false)
    let expanded = NotchFrame.frame(screen: screen, metrics: metrics, expanded: true)
    model.notchCompactHeight = compact.height
    model.notchExpandedWidth = expanded.width
    model.notchExpandedHeight = expanded.height
    let target = model.session.isExpanded ? expanded : compact
    panel.orderFrontRegardless()
    guard animated, panel.frame.width > 1, panel.frame.integral != target.integral else {
      morph = nil
      ticker.stop()
      panel.setFrame(target, display: true, animate: false)
      panel.contentView?.updateTrackingAreas()
      return
    }
    morph = Morph(
      from: panel.frame,
      to: target,
      spring: motion.spring(opening: model.session.isExpanded),
      startedAt: CACurrentMediaTime()
    )
    ticker.onFrame = { [weak self] time in
      self?.step(at: time)
    }
    ticker.start(on: panel)
  }

  private func step(at time: CFTimeInterval) {
    guard let morph else {
      ticker.stop()
      return
    }
    let elapsed = max(0, time - morph.startedAt)
    let frame: CGRect
    if elapsed >= IslandMorph.settled(morph.spring) {
      frame = morph.to
      self.morph = nil
      ticker.stop()
    } else {
      frame = IslandMorph.frame(from: morph.from, to: morph.to, spring: morph.spring, time: elapsed)
    }
    panel.setFrame(frame, display: true, animate: false)
    panel.contentView?.updateTrackingAreas()
  }

  private func hover(_ inside: Bool) {
    switch HoverTransition.decide(inside: inside, mouseInsideFrame: panel.frame.contains(NSEvent.mouseLocation)) {
    case .enter:
      hoverTask?.cancel()
      let delay = hoverDelay
      hoverTask = Task { @MainActor [weak self] in
        guard let self else { return }
        if delay > 0 {
          try? await Task.sleep(for: .seconds(delay))
        }
        guard !Task.isCancelled else { return }
        model.pointerEntered()
        layout(animated: true)
      }
    case .exit:
      hoverTask?.cancel()
      model.pointerExited()
      layout(animated: true)
    case .ignore:
      break
    }
  }
}

private struct Morph {
  var from: CGRect
  var to: CGRect
  var spring: Spring
  var startedAt: CFTimeInterval
}

@MainActor
private final class FrameTicker: NSObject {
  var onFrame: ((CFTimeInterval) -> Void)?
  nonisolated(unsafe) private var link: CADisplayLink?

  func start(on window: NSWindow) {
    guard link == nil else { return }
    let link = window.displayLink(target: self, selector: #selector(step))
    link.add(to: .main, forMode: .common)
    self.link = link
  }

  func stop() {
    link?.invalidate()
    link = nil
  }

  @objc nonisolated func step(_ link: CADisplayLink) {
    let time = link.timestamp
    MainActor.assumeIsolated {
      self.onFrame?(time)
    }
  }

  deinit { link?.invalidate() }
}

private final class ScreenWatch: @unchecked Sendable {
  var token: NSObjectProtocol?
  deinit {
    if let token {
      NotificationCenter.default.removeObserver(token)
    }
  }
}

final class IslandPanel: NSPanel {
  nonisolated static let spaceBehavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
}

final class HoverView: NSView {
  var onHover: (@MainActor (Bool) -> Void)?

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    for area in trackingAreas {
      removeTrackingArea(area)
    }
    addTrackingArea(
      NSTrackingArea(
        rect: bounds,
        options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
        owner: self,
        userInfo: nil
      )
    )
  }

  override func mouseEntered(with event: NSEvent) {
    onHover?(true)
  }

  override func mouseExited(with event: NSEvent) {
    onHover?(false)
  }

  override func mouseDown(with event: NSEvent) {
    NSApp.activate()
    window?.makeKey()
    super.mouseDown(with: event)
  }
}

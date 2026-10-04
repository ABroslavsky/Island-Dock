import AppKit
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
  private let hoverDelay: TimeInterval
  private var hoverTask: Task<Void, Never>?
  private let screenWatch = ScreenWatch()

  init(model: IslandModel, modules: [IslandModuleDescriptor], metrics: FrameMetrics, hoverDelay: TimeInterval) {
    self.model = model
    self.metrics = metrics
    self.hoverDelay = hoverDelay
    let panel = IslandPanel(
      contentRect: NSRect(x: 0, y: 0, width: metrics.fallbackWidth, height: metrics.fallbackHeight),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.isFloatingPanel = true
    panel.level = .statusBar
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.isMovable = false
    panel.becomesKeyOnlyIfNeeded = false
    panel.isReleasedWhenClosed = false
    self.panel = panel

    let host = NSHostingView(
      rootView: IslandRootView(model: model, modules: modules, onLayout: { [weak self] in
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
    layout(animated: false)
  }

  func layout(animated: Bool) {
    let screens = NSScreen.screens.map(ScreenSnapshot.capture)
    guard let screen = NotchFrame.preferred(among: screens) else { return }
    let frame = NotchFrame.frame(screen: screen, metrics: metrics, expanded: model.session.isExpanded)
    panel.setFrame(frame, display: true, animate: animated && panel.frame.width > 1)
    panel.contentView?.updateTrackingAreas()
    panel.orderFrontRegardless()
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

private final class ScreenWatch: @unchecked Sendable {
  var token: NSObjectProtocol?
  deinit {
    if let token {
      NotificationCenter.default.removeObserver(token)
    }
  }
}

final class IslandPanel: NSPanel {
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

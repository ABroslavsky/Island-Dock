import AppKit
import SwiftUI

public struct IslandDockApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

  public init() {}

  public var body: some Scene {
    MenuBarExtra(delegate.menuTitle, systemImage: delegate.menuSymbol) {
      IslandMenu(
        settings: delegate.settingsModel,
        settingsShortcut: delegate.settingsShortcut,
        onShow: { delegate.showIsland() }
      )
    }

    Settings {
      if let model = delegate.settingsModel {
        SettingsView(model: model)
      }
    }
  }
}

private struct IslandMenu: View {
  @Environment(\.openSettings) private var openSettings
  var settings: SettingsModel?
  let settingsShortcut: String
  let onShow: () -> Void

  private var locale: Locale { settings?.locale ?? Locale(identifier: "en") }

  var body: some View {
    Button(L10n.text("menu.show", locale: locale), action: onShow)
    Button(L10n.text("menu.settings", locale: locale)) {
      NSApp.activate()
      openSettings()
    }
    .keyboardShortcut(KeyEquivalent(settingsShortcut.first ?? Character(",")))
    Divider()
    Button(L10n.text("menu.quit", locale: locale)) { NSApp.terminate(nil) }
      .keyboardShortcut("q")
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let loaded: LoadedApp?
  private let failure: String?
  private(set) var settingsModel: SettingsModel?
  private var runtime: Runtime?

  override init() {
    switch Result(catching: { try ConfigStore.loadUserDomain() }) {
    case .success(let loaded):
      self.loaded = loaded
      self.failure = nil
      self.settingsModel = SettingsModel(loaded: loaded)
    case .failure(let error):
      self.loaded = nil
      self.failure = error.localizedDescription
      self.settingsModel = nil
    }
    super.init()
  }

  var menuTitle: String { loaded?.config.appName ?? "Island Dock" }
  var menuSymbol: String { loaded?.config.statusSymbol ?? "capsule" }
  var settingsShortcut: String { loaded?.config.settings.shortcut ?? "," }

  func applicationWillFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    guard let loaded, let settingsModel else {
      present(message: failure ?? ConfigError.missingDefaults.description)
      return
    }
    do {
      runtime = try Runtime(loaded: loaded, settings: settingsModel)
      runtime?.start()
    } catch {
      present(message: error.localizedDescription)
    }
  }

  func showIsland() {
    runtime?.show()
  }

  private func present(message: String) {
    let alert = NSAlert()
    alert.messageText = menuTitle
    alert.informativeText = message
    alert.runModal()
    NSApp.terminate(nil)
  }
}

@MainActor
private final class Runtime {
  private let controller: IslandPanelController

  init(loaded: LoadedApp, settings: SettingsModel) throws {
    let config = loaded.config
    let timer = try TimerModel(config: config.timer, url: loaded.directory.appending(path: config.files.timer))
    let snippets = try SnippetStore(url: loaded.directory.appending(path: config.files.snippets))
    let todos = try TodoStore(url: loaded.directory.appending(path: config.files.todos))
    let modules = ModuleCatalog.make(
      config: config,
      settings: settings,
      timer: timer,
      snippets: snippets,
      todos: todos
    )
    let model = IslandModel(session: IslandSession(moduleIDs: modules.map(\.id)), config: config)
    controller = IslandPanelController(
      model: model,
      modules: modules,
      settings: settings,
      metrics: config.chrome.frameMetrics,
      motion: config.motion,
      hoverDelay: config.chrome.hoverOpenDelay
    )
  }

  func start() { controller.start() }
  func show() { controller.show() }
}

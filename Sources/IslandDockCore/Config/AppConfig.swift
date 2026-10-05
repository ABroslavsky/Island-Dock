import CoreGraphics
import Foundation

struct AppConfig: Codable, Equatable, Sendable {
  var appName: String
  var storageDirectoryName: String
  var configFileName: String
  var statusSymbol: String
  var chrome: ChromeConfig
  var modules: [ModuleConfig]
  var files: FileNames
  var timer: TimerConfig
  var snippets: SnippetsConfig
  var commands: CommandConfig
  var settings: SettingsConfig
  var language: LanguageConfig
  var motion: MotionConfig

  func validate(knownModuleIDs: Set<String>) throws {
    func check(_ condition: Bool, _ field: String) throws {
      if !condition { throw ConfigError.invalid(field) }
    }

    try check(!appName.isEmpty, "appName")
    try check(Self.isSafeName(storageDirectoryName), "storageDirectoryName")
    try check(Self.isSafeName(configFileName), "configFileName")
    try check(!statusSymbol.isEmpty, "statusSymbol")
    try check(chrome.hoverOpenDelay >= 0, "chrome.hoverOpenDelay")
    try check(chrome.cornerRadius >= 0, "chrome.cornerRadius")
    try check(chrome.compactPadding >= 0, "chrome.compactPadding")
    try check(chrome.expandedPadding >= 0, "chrome.expandedPadding")
    try check(chrome.expandedWidth > 0, "chrome.expandedWidth")
    try check(chrome.expandedHeight > 0, "chrome.expandedHeight")
    try check(chrome.fallbackCapsuleWidth > 0, "chrome.fallbackCapsuleWidth")
    try check(chrome.fallbackCapsuleHeight > 0, "chrome.fallbackCapsuleHeight")

    let ids = modules.map(\.id)
    try check(Set(ids).count == ids.count, "modules.id")
    for module in modules {
      try check(knownModuleIDs.contains(module.id), "modules.id.\(module.id)")
      try check(!module.symbol.isEmpty, "modules")
    }

    for name in [files.snippets, files.todos, files.timer] {
      try check(Self.isSafeName(name), "files")
    }

    try check(timer.defaultSeconds > 0, "timer.defaultSeconds")
    try check(timer.maxMinutes >= 1, "timer.maxMinutes")
    try check(timer.tickSeconds > 0, "timer.tickSeconds")
    try check(!timer.presetSeconds.isEmpty && timer.presetSeconds.allSatisfy { $0 > 0 }, "timer.presetSeconds")
    try check(!timer.completionSound.isEmpty, "timer.completionSound")
    try check(snippets.copiedHintSeconds > 0, "snippets.copiedHintSeconds")
    try check(!commands.pinSymbol.isEmpty && !commands.unpinSymbol.isEmpty, "commands")
    try check(settings.shortcut.count == 1 && settings.width > 0 && settings.padding >= 0, "settings")
    let languageIDs = language.options.map(\.id)
    try check(!languageIDs.isEmpty && Set(languageIDs).count == languageIDs.count, "language.options")
    try check(language.options.allSatisfy { Self.isAvailableLanguage($0.id) && !$0.label.isEmpty }, "language.options")
    try check(languageIDs.contains(language.selected), "language.selected")
    try check(motion.openDuration > 0 && motion.closeDuration > 0, "motion.duration")
    try check((-1...1).contains(motion.openBounce) && (-1...1).contains(motion.closeBounce), "motion.bounce")
    try check(motion.contentScale > 0 && motion.contentScale <= 1, "motion.contentScale")
  }

  private static func isAvailableLanguage(_ id: String) -> Bool {
    Locale.availableIdentifiers.contains(id)
  }

  private static func isSafeName(_ name: String) -> Bool {
    !name.isEmpty && name != "." && name != ".." && !name.contains("/") && !name.contains("\\")
  }
}

struct ChromeConfig: Codable, Equatable, Sendable {
  var hoverOpenDelay: TimeInterval
  var cornerRadius: CGFloat
  var compactPadding: CGFloat
  var expandedPadding: CGFloat
  var expandedWidth: CGFloat
  var expandedHeight: CGFloat
  var fallbackCapsuleWidth: CGFloat
  var fallbackCapsuleHeight: CGFloat

  var frameMetrics: FrameMetrics {
    FrameMetrics(
      expandedWidth: expandedWidth,
      expandedHeight: expandedHeight,
      fallbackWidth: fallbackCapsuleWidth,
      fallbackHeight: fallbackCapsuleHeight
    )
  }
}

struct ModuleConfig: Codable, Equatable, Sendable, Identifiable {
  var id: String
  var enabled: Bool
  var symbol: String
}

struct FileNames: Codable, Equatable, Sendable {
  var snippets: String
  var todos: String
  var timer: String
}

struct TimerConfig: Codable, Equatable, Sendable {
  var defaultSeconds: TimeInterval
  var presetSeconds: [TimeInterval]
  var maxMinutes: Double
  var tickSeconds: TimeInterval
  var completionSound: String
}

struct SnippetsConfig: Codable, Equatable, Sendable {
  var copiedHintSeconds: TimeInterval
}

struct SettingsConfig: Codable, Equatable, Sendable {
  var shortcut: String
  var width: CGFloat
  var padding: CGFloat
}

struct LanguageOption: Codable, Equatable, Sendable, Identifiable {
  var id: String
  var label: String
}

struct MotionConfig: Codable, Equatable, Sendable {
  var openDuration: TimeInterval
  var openBounce: Double
  var closeDuration: TimeInterval
  var closeBounce: Double
  var contentScale: Double
}

struct LanguageConfig: Codable, Equatable, Sendable {
  var selected: String
  var followsSystem: Bool
  var options: [LanguageOption]
}

struct CommandConfig: Codable, Equatable, Sendable {
  var pinSymbol: String
  var unpinSymbol: String
}

enum ConfigError: Error, Equatable, CustomStringConvertible, LocalizedError {
  case missingDefaults
  case invalid(String)

  var description: String {
    switch self {
    case .missingDefaults:
      "Missing defaults.json"
    case .invalid(let field):
      "Invalid config: \(field)"
    }
  }

  var errorDescription: String? { description }
}

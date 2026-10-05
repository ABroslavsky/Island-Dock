import Foundation
import Testing
@testable import IslandDockCore

struct ConfigStoreTests {
  @Test func firstLaunchCopiesDefaults() throws {
    let config = try sampleConfig()
    #expect(config.appName == "Island Dock")
    #expect(config.modules.map(\.id) == [ModuleID.timer, ModuleID.snippets, ModuleID.todo])
    #expect(config.timer.defaultSeconds == 1500)
    #expect(config.timer.presetSeconds == [900, 1500, 3000])
    #expect(config.language.followsSystem)
    #expect(config.language.options.map(\.id) == ["en", "de", "fr", "es", "ru"])
    #expect(config.language.selected == ConfigStore.preferredLanguage(
      among: config.language.options.map(\.id),
      fallback: "en"
    ))
  }

  @Test func systemLanguageMatchesSupportedCatalog() {
    let ids = ["en", "de", "fr", "es", "ru"]
    #expect(ConfigStore.preferredLanguage(among: ids, preferences: ["ru-RU"], fallback: "en") == "ru")
    #expect(ConfigStore.preferredLanguage(among: ids, preferences: ["de-DE"], fallback: "en") == "de")
    #expect(ConfigStore.preferredLanguage(among: ids, preferences: ["fr-FR"], fallback: "en") == "fr")
    #expect(ConfigStore.preferredLanguage(among: ids, preferences: ["es-ES"], fallback: "en") == "es")
    #expect(ConfigStore.preferredLanguage(among: ids, preferences: ["ja-JP"], fallback: "en") == "en")
  }

  @Test func oldConfigReceivesLanguageFromDefaults() throws {
    try withTempDirectory { root in
      let first = try ConfigStore.load(directoryRoot: root)
      let url = first.directory.appending(path: first.config.configFileName)
      var object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
      object.removeValue(forKey: "language")
      object.removeValue(forKey: "settings")
      object.removeValue(forKey: "motion")
      try JSONSerialization.data(withJSONObject: object).write(to: url, options: .atomic)
      let second = try ConfigStore.load(directoryRoot: root)
      #expect(second.config.language.followsSystem)
      #expect(second.config.language.selected == ConfigStore.preferredLanguage(
        among: second.config.language.options.map(\.id),
        fallback: "en"
      ))
      #expect(second.config.language.options.map(\.id) == ["en", "de", "fr", "es", "ru"])
      #expect(second.config.settings.shortcut == ",")
      #expect(second.config.motion.openDuration == 0.5)
      #expect(second.config.motion.openBounce == 0.18)
    }
  }

  @Test func untouchedEnglishSelectionFollowsSystem() throws {
    try withTempDirectory { root in
      let first = try ConfigStore.load(directoryRoot: root)
      let url = first.directory.appending(path: first.config.configFileName)
      var object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
      var language = try #require(object["language"] as? [String: Any])
      language.removeValue(forKey: "followsSystem")
      language["selected"] = "en"
      object["language"] = language
      try JSONSerialization.data(withJSONObject: object).write(to: url, options: .atomic)
      let second = try ConfigStore.load(directoryRoot: root)
      #expect(second.config.language.followsSystem)
      #expect(second.config.language.selected == ConfigStore.preferredLanguage(
        among: second.config.language.options.map(\.id),
        fallback: "en"
      ))
    }
  }

  @Test func savedLanguageKeepsSelectionAndGainsNewLanguages() throws {
    try withTempDirectory { root in
      let first = try ConfigStore.load(directoryRoot: root)
      let url = first.directory.appending(path: first.config.configFileName)
      var object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
      object["language"] = [
        "selected": "ru",
        "options": [
          ["id": "en", "label": "English"],
          ["id": "ru", "label": "Русский"],
        ],
      ]
      try JSONSerialization.data(withJSONObject: object).write(to: url, options: .atomic)
      let second = try ConfigStore.load(directoryRoot: root)
      #expect(second.config.language.followsSystem == false)
      #expect(second.config.language.selected == "ru")
      #expect(second.config.language.options.map(\.id) == ["en", "de", "fr", "es", "ru"])
    }
  }

  @Test func unknownLanguageIsRejected() throws {
    var config = try sampleConfig()
    config.language.selected = "not-a-language"
    #expect(throws: ConfigError.self) {
      try config.validate(knownModuleIDs: ModuleID.all)
    }
  }

  @Test func userFileOverridesChromeButNotStorageLocation() throws {
    try withTempDirectory { root in
      let first = try ConfigStore.load(directoryRoot: root)
      var edited = first.config
      edited.chrome.expandedWidth = 512
      edited.storageDirectoryName = "Elsewhere"
      let url = first.directory.appending(path: first.config.configFileName)
      try JSONEncoder.island.encode(edited).write(to: url, options: .atomic)
      let second = try ConfigStore.load(directoryRoot: root)
      #expect(second.config.chrome.expandedWidth == 512)
      #expect(second.directory == first.directory)
      #expect(second.config.storageDirectoryName == "Island Dock")
    }
  }

  @Test func invalidUserFileThrowsAndKeepsTheFile() throws {
    try withTempDirectory { root in
      let first = try ConfigStore.load(directoryRoot: root)
      let url = first.directory.appending(path: first.config.configFileName)
      var edited = first.config
      edited.chrome.hoverOpenDelay = -1
      try JSONEncoder.island.encode(edited).write(to: url, options: .atomic)
      #expect(throws: ConfigError.self) {
        try ConfigStore.load(directoryRoot: root)
      }
      #expect(FileManager.default.fileExists(atPath: url.path))
    }
  }

  @Test func unknownModuleIdIsRejected() throws {
    var config = try sampleConfig()
    config.modules.append(ModuleConfig(id: "sports", enabled: true, symbol: "sportscourt"))
    #expect(throws: ConfigError.self) {
      try config.validate(knownModuleIDs: ModuleID.all)
    }
  }
}

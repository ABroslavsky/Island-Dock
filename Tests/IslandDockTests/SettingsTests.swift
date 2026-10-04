import Foundation
import Testing
@testable import IslandDockCore

@MainActor
struct SettingsModelTests {
  @Test func selectingLanguagePersists() throws {
    try withTempDirectory { root in
      let loaded = try ConfigStore.load(directoryRoot: root)
      let model = SettingsModel(loaded: loaded)
      model.selectLanguage("ru")
      #expect(model.languageID == "ru")
      let revived = try ConfigStore.load(directoryRoot: root)
      #expect(revived.config.language.selected == "ru")
    }
  }

  @Test func unknownLanguageIsLeftUnchanged() throws {
    try withTempDirectory { root in
      let loaded = try ConfigStore.load(directoryRoot: root)
      let model = SettingsModel(loaded: loaded)
      model.selectLanguage("nope")
      #expect(model.languageID == "en")
      let revived = try ConfigStore.load(directoryRoot: root)
      #expect(revived.config.language.selected == "en")
    }
  }

  @Test func failedSaveRestoresPreviousLanguage() throws {
    try withTempDirectory { root in
      let loaded = try ConfigStore.load(directoryRoot: root)
      let model = SettingsModel(config: loaded.config, fileURL: root)
      model.selectLanguage("ru")
      #expect(model.languageID == "en")
    }
  }
}

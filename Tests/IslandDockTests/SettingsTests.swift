import Foundation
import Testing
@testable import IslandDockCore

@MainActor
struct SettingsModelTests {
  @Test func selectingLanguagePersists() throws {
    try withTempDirectory { root in
      let loaded = try ConfigStore.load(directoryRoot: root)
      let model = SettingsModel(loaded: loaded)
      model.selectLanguage("de")
      #expect(model.languageID == "de")
      #expect(model.config.language.followsSystem == false)
      let revived = try ConfigStore.load(directoryRoot: root)
      #expect(revived.config.language.selected == "de")
      #expect(revived.config.language.followsSystem == false)
    }
  }

  @Test func unknownLanguageIsLeftUnchanged() throws {
    try withTempDirectory { root in
      let loaded = try ConfigStore.load(directoryRoot: root)
      let model = SettingsModel(loaded: loaded)
      let previous = model.languageID
      model.selectLanguage("nope")
      #expect(model.languageID == previous)
      let revived = try ConfigStore.load(directoryRoot: root)
      #expect(revived.config.language.selected == previous)
      #expect(revived.config.language.followsSystem)
    }
  }

  @Test func failedSaveRestoresPreviousLanguage() throws {
    try withTempDirectory { root in
      let loaded = try ConfigStore.load(directoryRoot: root)
      let model = SettingsModel(config: loaded.config, fileURL: root)
      let previous = model.languageID
      model.selectLanguage(previous == "de" ? "fr" : "de")
      #expect(model.languageID == previous)
      #expect(model.config.language.followsSystem)
    }
  }
}

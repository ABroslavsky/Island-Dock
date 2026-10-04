import Foundation
import Testing
@testable import IslandDockCore

struct LocalizationTests {
  @Test func everyLanguageTranslatesEveryEnglishKey() throws {
    let english = try catalog("en")
    #expect(!english.isEmpty)
    for code in ["de", "fr", "es", "ru"] {
      let translated = try catalog(code)
      #expect(Set(translated.keys) == Set(english.keys))
      #expect(translated.contains { key, value in
        !value.isEmpty && value != key && english[key] != value
      })
      for (key, value) in translated {
        #expect(!value.isEmpty)
        #expect(value != key)
      }
    }
  }

  @Test func lookupUsesTheSelectedLanguageAndFallsBackToEnglish() {
    #expect(L10n.text("timer.reset", locale: Locale(identifier: "de")) == "Zurücksetzen")
    #expect(L10n.text("timer.start", locale: Locale(identifier: "fr")) == "Démarrer")
    #expect(L10n.text("timer.start", locale: Locale(identifier: "es")) == "Iniciar")
    #expect(L10n.text("timer.start", locale: Locale(identifier: "ru")) == "Старт")
    #expect(L10n.text("timer.start", locale: Locale(identifier: "en")) == "Start")
    #expect(L10n.text("timer.start", locale: Locale(identifier: "ja")) == "Start")
    #expect(L10n.format("delete.item", "A", locale: Locale(identifier: "ru")) == "Удалить A")
    #expect(L10n.format("delete.item", "A", locale: Locale(identifier: "de")) == "A löschen")
  }

  private func catalog(_ code: String) throws -> [String: String] {
    let bundle = try #require(L10n.localizationBundle(language: code))
    let url = try #require(bundle.url(forResource: "Localizable", withExtension: "strings"))
    let data = try Data(contentsOf: url)
    return try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String])
  }
}

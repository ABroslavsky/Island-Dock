import Foundation

enum L10n {
  static let bundle = Bundle.module

  static func text(_ key: String, locale: Locale) -> String {
    let language = locale.language.languageCode?.identifier ?? locale.identifier
    if let localized = lookup(key, language: language), localized != key {
      return localized
    }
    return lookup(key, language: "en") ?? key
  }

  static func format(_ key: String, _ argument: String, locale: Locale) -> String {
    String(format: text(key, locale: locale), locale: locale, argument)
  }

  static func localizationBundle(language: String) -> Bundle? {
    bundle.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:))
  }

  private static func lookup(_ key: String, language: String) -> String? {
    localizationBundle(language: language)?.localizedString(forKey: key, value: key, table: nil)
  }
}

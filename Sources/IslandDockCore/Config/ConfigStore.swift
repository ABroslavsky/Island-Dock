import Foundation

struct LoadedApp: Equatable, Sendable {
  var config: AppConfig
  var directory: URL
}

enum ConfigStore {
  static func loadUserDomain() throws -> LoadedApp {
    let root = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    return try load(directoryRoot: root)
  }

  static func load(directoryRoot: URL, bundle: Bundle = .module) throws -> LoadedApp {
    guard let defaultsURL = bundle.url(forResource: "defaults", withExtension: "json") else {
      throw ConfigError.missingDefaults
    }
    let defaultsData = try Data(contentsOf: defaultsURL)
    let defaults = try JSONDecoder.island.decode(AppConfig.self, from: defaultsData)
    try defaults.validate(knownModuleIDs: ModuleID.all)

    let directory = directoryRoot.appending(path: defaults.storageDirectoryName, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let userURL = directory.appending(path: defaults.configFileName)

    let config: AppConfig
    if FileManager.default.fileExists(atPath: userURL.path) {
      config = try decodeUser(at: userURL, defaultsData: defaultsData, anchoringTo: defaults)
    } else {
      try defaultsData.write(to: userURL, options: .atomic)
      config = defaults
    }
    return LoadedApp(config: config, directory: directory)
  }

  static func save(_ config: AppConfig, to url: URL) throws {
    try JSONEncoder.island.encode(config).write(to: url, options: .atomic)
  }

  private static func decodeUser(at url: URL, defaultsData: Data, anchoringTo defaults: AppConfig) throws -> AppConfig {
    let filled = try fillingMissingTopLevelKeys(in: Data(contentsOf: url), from: defaultsData)
    var config = try JSONDecoder.island.decode(AppConfig.self, from: filled)
    config.storageDirectoryName = defaults.storageDirectoryName
    config.configFileName = defaults.configFileName
    try config.validate(knownModuleIDs: ModuleID.all)
    return config
  }

  private static func fillingMissingTopLevelKeys(in user: Data, from defaults: Data) throws -> Data {
    guard var userObject = try JSONSerialization.jsonObject(with: user) as? [String: Any],
          let defaultsObject = try JSONSerialization.jsonObject(with: defaults) as? [String: Any] else {
      throw ConfigError.invalid("json")
    }
    for (key, value) in defaultsObject where userObject[key] == nil {
      userObject[key] = value
    }
    return try JSONSerialization.data(withJSONObject: userObject)
  }
}

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
      config = try decodeUser(at: userURL, anchoringTo: defaults)
    } else {
      try defaultsData.write(to: userURL, options: .atomic)
      config = defaults
    }
    return LoadedApp(config: config, directory: directory)
  }

  private static func decodeUser(at url: URL, anchoringTo defaults: AppConfig) throws -> AppConfig {
    var config = try JSONDecoder.island.decode(AppConfig.self, from: Data(contentsOf: url))
    config.storageDirectoryName = defaults.storageDirectoryName
    config.configFileName = defaults.configFileName
    try config.validate(knownModuleIDs: ModuleID.all)
    return config
  }
}

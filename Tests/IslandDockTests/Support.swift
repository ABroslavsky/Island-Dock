import Foundation
@testable import IslandDockCore

func withTempDirectory<T>(_ body: (URL) throws -> T) throws -> T {
  let url = FileManager.default.temporaryDirectory.appending(path: "island-dock-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: url) }
  return try body(url)
}

func sampleConfig() throws -> AppConfig {
  try withTempDirectory { root in
    try ConfigStore.load(directoryRoot: root).config
  }
}

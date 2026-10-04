import Foundation
import os

private let storageLogger = Logger(subsystem: "IslandDock", category: "storage")

struct JSONFileStore<Value: Codable> {
  var url: URL
  var defaultValue: Value

  func load() throws -> Value {
    guard FileManager.default.fileExists(atPath: url.path) else {
      try save(defaultValue)
      return defaultValue
    }
    return try JSONDecoder.island.decode(Value.self, from: Data(contentsOf: url))
  }

  func save(_ value: Value) throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try JSONEncoder.island.encode(value).write(to: url, options: .atomic)
  }

  func saveOrLog(_ value: Value) {
    do {
      try save(value)
    } catch {
      storageLogger.error("\(error.localizedDescription, privacy: .public)")
    }
  }
}

extension JSONEncoder {
  static var island: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }
}

extension JSONDecoder {
  static var island: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}

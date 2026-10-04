import Foundation
import Observation
import os
import SwiftUI

@MainActor
@Observable
final class SettingsModel {
  private(set) var config: AppConfig
  private let fileURL: URL

  convenience init(loaded: LoadedApp) {
    self.init(config: loaded.config, fileURL: loaded.directory.appending(path: loaded.config.configFileName))
  }

  init(config: AppConfig, fileURL: URL) {
    self.config = config
    self.fileURL = fileURL
  }

  var languageID: String { config.language.selected }

  func selectLanguage(_ id: String) {
    guard config.language.options.contains(where: { $0.id == id }) else { return }
    let previous = config.language.selected
    guard previous != id else { return }
    config.language.selected = id
    do {
      try ConfigStore.save(config, to: fileURL)
    } catch {
      config.language.selected = previous
      Logger(subsystem: "IslandDock", category: "settings").error("\(error.localizedDescription, privacy: .public)")
    }
  }
}

struct SettingsView: View {
  var model: SettingsModel

  var body: some View {
    Form {
      Picker(model.config.settings.languageTitle, selection: language) {
        ForEach(model.config.language.options) { option in
          Text(option.label).tag(option.id)
        }
      }
      .pickerStyle(.radioGroup)
    }
    .padding(model.config.settings.padding)
    .frame(width: model.config.settings.width)
    .navigationTitle(model.config.settings.title)
  }

  private var language: Binding<String> {
    Binding(get: { model.languageID }, set: { model.selectLanguage($0) })
  }
}

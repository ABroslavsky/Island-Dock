import Foundation
import Testing
@testable import IslandDockCore

@MainActor
struct StoreTests {
  @Test func timerChimesOnceAndReloads() throws {
    try withTempDirectory { root in
      var config = try sampleConfig().timer
      config.defaultSeconds = 10
      let url = root.appending(path: "timer.json")
      let model = try TimerModel(config: config, url: url)
      let start = Date(timeIntervalSinceReferenceDate: 5_000)
      model.start(at: start)
      #expect(model.tick(at: start.addingTimeInterval(3)) == false)
      #expect(model.tick(at: start.addingTimeInterval(10)) == true)
      #expect(model.tick(at: start.addingTimeInterval(11)) == false)
      #expect(model.clock.remaining(at: start.addingTimeInterval(11)) == 0)

      let revived = try TimerModel(config: config, url: url)
      #expect(revived.clock.runningSince == nil)
      #expect(revived.clock.elapsedSeconds == 10)
      #expect(revived.tick(at: .now) == false)
    }
  }

  @Test func presetDoesNotChangeRunningTimer() throws {
    try withTempDirectory { root in
      let config = try sampleConfig().timer
      let model = try TimerModel(config: config, url: root.appending(path: "timer.json"))
      model.start(at: Date(timeIntervalSinceReferenceDate: 20))
      model.usePreset(900)
      #expect(model.clock.durationSeconds == config.defaultSeconds)
      let revived = try TimerModel(config: config, url: root.appending(path: "timer.json"))
      #expect(revived.clock.isRunning)
      #expect(revived.clock.runningSince == Date(timeIntervalSinceReferenceDate: 20))
    }
  }

  @Test func snippetsRejectBlankAndRoundTripPayload() throws {
    try withTempDirectory { root in
      let store = try SnippetStore(url: root.appending(path: "snippets.json"))
      #expect(store.add(title: "  ", body: "x") == nil)
      let id = try #require(store.add(title: " Sig ", body: " Hello "))
      #expect(store.payload(for: id) == "Hello")
      let revived = try SnippetStore(url: root.appending(path: "snippets.json"))
      #expect(revived.payload(for: id) == "Hello")
      revived.delete(id: id)
      let reloaded = try SnippetStore(url: root.appending(path: "snippets.json"))
      #expect(reloaded.items.isEmpty)
    }
  }

  @Test func todosToggleDeleteAndMove() throws {
    try withTempDirectory { root in
      let store = try TodoStore(url: root.appending(path: "todos.json"))
      #expect(store.add(title: "   ") == nil)
      let first = try #require(store.add(title: "a"))
      _ = store.add(title: "b")
      _ = store.add(title: "c")
      #expect(store.remaining == 3)
      store.setDone(id: first, isDone: true)
      #expect(store.remaining == 2)
      store.move(fromOffsets: IndexSet(integer: 0), toOffset: 2)
      #expect(store.items.map(\.title) == ["b", "a", "c"])
      store.delete(id: first)
      #expect(store.items.map(\.title) == ["b", "c"])
      let revived = try TodoStore(url: root.appending(path: "todos.json"))
      #expect(revived.items.map(\.title) == ["b", "c"])
    }
  }
}

@MainActor
struct ModuleCatalogTests {
  @Test func orderFollowsConfigAndSkipsDisabled() throws {
    try withTempDirectory { root in
      var config = try ConfigStore.load(directoryRoot: root).config
      config.modules = [
        ModuleConfig(id: ModuleID.todo, enabled: true, symbol: "checklist"),
        ModuleConfig(id: ModuleID.timer, enabled: false, symbol: "timer"),
        ModuleConfig(id: ModuleID.snippets, enabled: true, symbol: "doc.on.clipboard"),
      ]
      let timer = try TimerModel(config: config.timer, url: root.appending(path: config.files.timer))
      let snippets = try SnippetStore(url: root.appending(path: config.files.snippets))
      let todos = try TodoStore(url: root.appending(path: config.files.todos))
      let settings = SettingsModel(config: config, fileURL: root.appending(path: config.configFileName))
      let modules = ModuleCatalog.make(
        config: config,
        settings: settings,
        timer: timer,
        snippets: snippets,
        todos: todos
      )
      #expect(modules.map(\.id) == [ModuleID.todo, ModuleID.snippets])
      _ = modules[0].compact()
      _ = modules[1].expanded()
    }
  }
}

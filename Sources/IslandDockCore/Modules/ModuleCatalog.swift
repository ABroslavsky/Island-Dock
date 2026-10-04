import SwiftUI

enum ModuleID {
  static let timer = "timer"
  static let snippets = "snippets"
  static let todo = "todo"
  static let all: Set<String> = [timer, snippets, todo]
}

struct IslandModuleDescriptor: Identifiable {
  let id: String
  let title: String
  let symbolName: String
  let compact: @MainActor () -> AnyView
  let expanded: @MainActor () -> AnyView
}

@MainActor
enum ModuleCatalog {
  static func make(
    config: AppConfig,
    timer: TimerModel,
    snippets: SnippetStore,
    todos: TodoStore
  ) -> [IslandModuleDescriptor] {
    let builders: [String: (ModuleConfig) -> IslandModuleDescriptor] = [
      ModuleID.timer: { entry in
        IslandModuleDescriptor(
          id: entry.id,
          title: entry.title,
          symbolName: entry.symbol,
          compact: { AnyView(TimerCompact(model: timer, symbol: entry.symbol)) },
          expanded: { AnyView(TimerExpanded(model: timer, symbol: entry.symbol)) }
        )
      },
      ModuleID.snippets: { entry in
        IslandModuleDescriptor(
          id: entry.id,
          title: entry.title,
          symbolName: entry.symbol,
          compact: { AnyView(SnippetsCompact(model: snippets, symbol: entry.symbol)) },
          expanded: { AnyView(SnippetsExpanded(model: snippets, text: config.snippets)) }
        )
      },
      ModuleID.todo: { entry in
        IslandModuleDescriptor(
          id: entry.id,
          title: entry.title,
          symbolName: entry.symbol,
          compact: { AnyView(TodoCompact(model: todos, symbol: entry.symbol)) },
          expanded: { AnyView(TodoExpanded(model: todos, text: config.todo)) }
        )
      },
    ]
    return config.modules.compactMap { entry in
      guard entry.enabled else { return nil }
      return builders[entry.id]?(entry)
    }
  }
}

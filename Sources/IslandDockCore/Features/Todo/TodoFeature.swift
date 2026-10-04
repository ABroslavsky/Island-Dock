import Foundation
import Observation
import SwiftUI

struct TodoItem: Codable, Equatable, Identifiable, Sendable {
  var id: UUID
  var title: String
  var isDone: Bool
}

@MainActor
@Observable
final class TodoStore {
  private(set) var items: [TodoItem]
  private let store: JSONFileStore<[TodoItem]>

  init(url: URL) throws {
    let store = JSONFileStore<[TodoItem]>(url: url, defaultValue: [])
    self.store = store
    self.items = try store.load()
  }

  var remaining: Int { items.count(where: { !$0.isDone }) }

  @discardableResult
  func add(title: String) -> UUID? {
    let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else { return nil }
    let id = UUID()
    items.append(TodoItem(id: id, title: title, isDone: false))
    store.saveOrLog(items)
    return id
  }

  func setDone(id: UUID, isDone: Bool) {
    guard let index = items.firstIndex(where: { $0.id == id }) else { return }
    items[index].isDone = isDone
    store.saveOrLog(items)
  }

  func delete(id: UUID) {
    guard let index = items.firstIndex(where: { $0.id == id }) else { return }
    items.remove(at: index)
    store.saveOrLog(items)
  }

  func delete(at offsets: IndexSet) {
    items.remove(atOffsets: offsets)
    store.saveOrLog(items)
  }

  func move(fromOffsets source: IndexSet, toOffset destination: Int) {
    items.move(fromOffsets: source, toOffset: destination)
    store.saveOrLog(items)
  }
}

struct TodoCompact: View {
  let model: TodoStore
  let symbol: String

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: symbol)
      Text("\(model.remaining)")
        .monospacedDigit()
    }
    .font(.callout.weight(.semibold))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct TodoExpanded: View {
  let model: TodoStore
  let text: TodoConfig
  @State private var draft = ""

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        TextField(text.placeholder, text: $draft)
          .textFieldStyle(.plain)
          .onSubmit(add)
        Button(text.add, action: add)
      }
      if model.items.isEmpty {
        Text(text.empty)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List {
          ForEach(model.items) { item in
            HStack {
              Toggle(
                item.title,
                isOn: Binding(
                  get: { item.isDone },
                  set: { model.setDone(id: item.id, isDone: $0) }
                )
              )
              .strikethrough(item.isDone)
              Button {
                model.delete(id: item.id)
              } label: {
                Image(systemName: "xmark.circle.fill")
              }
              .buttonStyle(.plain)
              .accessibilityLabel("Delete \(item.title)")
            }
            .listRowBackground(Color.white.opacity(0.06))
          }
          .onDelete(perform: model.delete)
          .onMove(perform: model.move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
      }
    }
  }

  private func add() {
    guard model.add(title: draft) != nil else { return }
    draft = ""
  }
}

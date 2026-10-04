import AppKit
import Foundation
import Observation
import SwiftUI

struct Snippet: Codable, Equatable, Identifiable, Sendable {
  var id: UUID
  var title: String
  var body: String
}

@MainActor
@Observable
final class SnippetStore {
  private(set) var items: [Snippet]
  private let store: JSONFileStore<[Snippet]>

  init(url: URL) throws {
    let store = JSONFileStore<[Snippet]>(url: url, defaultValue: [])
    self.store = store
    self.items = try store.load()
  }

  @discardableResult
  func add(title: String, body: String) -> UUID? {
    let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let body = body.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty, !body.isEmpty else { return nil }
    let id = UUID()
    items.append(Snippet(id: id, title: title, body: body))
    store.saveOrLog(items)
    return id
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

  func payload(for id: UUID) -> String? {
    items.first { $0.id == id }?.body
  }
}

struct SnippetsCompact: View {
  let model: SnippetStore
  let symbol: String

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: symbol)
      Text("\(model.items.count)")
        .monospacedDigit()
    }
    .font(.callout.weight(.semibold))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct SnippetsExpanded: View {
  let model: SnippetStore
  var settings: SettingsModel
  @State private var title = ""
  @State private var bodyText = ""
  @State private var copiedID: UUID?

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        TextField(L10n.text("snippets.title", locale: settings.locale), text: $title)
        TextField(L10n.text("snippets.body", locale: settings.locale), text: $bodyText)
          .onSubmit(add)
        Button(L10n.text("snippets.add", locale: settings.locale), action: add)
      }
      .textFieldStyle(.plain)
      if model.items.isEmpty {
        Text(L10n.text("snippets.empty", locale: settings.locale))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List {
          ForEach(model.items) { snippet in
            HStack {
              Button {
                writeClipboard(snippet.body)
                copiedID = snippet.id
                let token = snippet.id
                Task {
                  try? await Task.sleep(for: .seconds(settings.config.snippets.copiedHintSeconds))
                  if copiedID == token { copiedID = nil }
                }
              } label: {
                VStack(alignment: .leading, spacing: 2) {
                  Text(snippet.title)
                  Text(copiedID == snippet.id ? L10n.text("snippets.copied", locale: settings.locale) : snippet.body)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
              }
              .buttonStyle(.plain)
              Button {
                model.delete(id: snippet.id)
              } label: {
                Image(systemName: "xmark.circle.fill")
              }
              .buttonStyle(.plain)
              .accessibilityLabel(L10n.format("delete.item", snippet.title, locale: settings.locale))
            }
            .listRowBackground(Color.white.opacity(0.06))
          }
          .onDelete(perform: model.delete)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
      }
    }
  }

  private func add() {
    guard model.add(title: title, body: bodyText) != nil else { return }
    title = ""
    bodyText = ""
  }
}

@MainActor
private func writeClipboard(_ string: String) {
  let pasteboard = NSPasteboard.general
  pasteboard.clearContents()
  pasteboard.setString(string, forType: .string)
}

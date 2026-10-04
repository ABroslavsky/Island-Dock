import SwiftUI

struct IslandRootView: View {
  @State private var model: IslandModel
  let modules: [IslandModuleDescriptor]
  let onLayout: () -> Void

  init(model: IslandModel, modules: [IslandModuleDescriptor], onLayout: @escaping () -> Void) {
    _model = State(initialValue: model)
    self.modules = modules
    self.onLayout = onLayout
  }

  var body: some View {
    VStack(spacing: 8) {
      if model.session.isExpanded {
        switcher
        activeExpanded
      } else {
        activeCompact
      }
    }
    .padding(model.session.isExpanded ? model.chrome.expandedPadding : model.chrome.compactPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .foregroundStyle(.white)
    .background(Color.black)
    .clipShape(RoundedRectangle(cornerRadius: model.chrome.cornerRadius, style: .continuous))
    .animation(.snappy, value: model.session.isExpanded)
    .animation(.snappy, value: model.session.activeModuleID)
  }

  private var active: IslandModuleDescriptor? {
    modules.first { $0.id == model.session.activeModuleID }
  }

  private var activeCompact: some View {
    Group {
      if let active {
        active.compact()
      } else {
        Text(model.appName).font(.caption)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var activeExpanded: some View {
    Group {
      if let active {
        active.expanded()
      } else {
        Text(model.appName)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var switcher: some View {
    HStack(spacing: 12) {
      ForEach(modules) { module in
        Button {
          model.select(module.id)
        } label: {
          Image(systemName: module.symbolName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(module.id == model.session.activeModuleID ? Color.white : Color.white.opacity(0.4))
        }
        .buttonStyle(.plain)
        .help(module.title)
        .accessibilityLabel(module.title)
      }
      Spacer(minLength: 0)
      Button {
        model.togglePin()
        onLayout()
      } label: {
        Image(systemName: model.session.isPinned ? model.commands.unpinSymbol : model.commands.pinSymbol)
      }
      .buttonStyle(.plain)
      .help(model.session.isPinned ? model.commands.unpin : model.commands.pin)
      .accessibilityLabel(model.session.isPinned ? model.commands.unpin : model.commands.pin)
    }
  }
}

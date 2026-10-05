import SwiftUI

struct IslandRootView: View {
  @State private var model: IslandModel
  var settings: SettingsModel
  let modules: [IslandModuleDescriptor]
  let onLayout: () -> Void

  init(
    model: IslandModel,
    modules: [IslandModuleDescriptor],
    settings: SettingsModel,
    onLayout: @escaping () -> Void
  ) {
    _model = State(initialValue: model)
    self.settings = settings
    self.modules = modules
    self.onLayout = onLayout
  }

  var body: some View {
    GeometryReader { geo in
      let reveal = IslandMorph.reveal(
        height: geo.size.height,
        compact: model.notchCompactHeight,
        expanded: model.notchExpandedHeight
      )
      let radius = IslandMorph.radius(
        reveal: reveal,
        compactHeight: model.notchCompactHeight,
        expandedRadius: model.chrome.cornerRadius
      )
      ZStack(alignment: .top) {
        expandedBody
          .frame(width: model.notchExpandedWidth, height: model.notchExpandedHeight, alignment: .top)
          .scaleEffect(IslandMorph.contentScale(reveal: reveal, minimum: model.motion.contentScale), anchor: .top)
          .opacity(reveal)
          .allowsHitTesting(reveal > 0.5)
        compactBody
          .opacity(1 - reveal)
          .allowsHitTesting(reveal <= 0.5)
      }
      .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
      .foregroundStyle(.white)
      .background(Color.black)
      .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
    .environment(\.locale, settings.locale)
  }

  private var active: IslandModuleDescriptor? {
    modules.first { $0.id == model.session.activeModuleID }
  }

  private var compactBody: some View {
    Group {
      if let active {
        active.compact()
      } else {
        Text(model.appName).font(.caption)
      }
    }
    .padding(model.chrome.compactPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var expandedBody: some View {
    VStack(spacing: 8) {
      switcher
      activeExpanded
    }
    .padding(model.chrome.expandedPadding)
    .animation(.spring(duration: model.motion.openDuration, bounce: model.motion.openBounce), value: model.session.activeModuleID)
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
        .help(L10n.text("module.\(module.id)", locale: settings.locale))
        .accessibilityLabel(L10n.text("module.\(module.id)", locale: settings.locale))
      }
      Spacer(minLength: 0)
      Button {
        model.togglePin()
        onLayout()
      } label: {
        Image(systemName: model.session.isPinned ? model.commands.unpinSymbol : model.commands.pinSymbol)
      }
      .buttonStyle(.plain)
      .help(L10n.text(model.session.isPinned ? "unpin" : "pin", locale: settings.locale))
      .accessibilityLabel(L10n.text(model.session.isPinned ? "unpin" : "pin", locale: settings.locale))
    }
  }
}

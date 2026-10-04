import AppKit
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class TimerModel {
  private(set) var clock: FocusClock
  private var didChime: Bool
  private let store: JSONFileStore<FocusClock>
  let config: TimerConfig

  init(config: TimerConfig, url: URL) throws {
    self.config = config
    let fresh = FocusClock(durationSeconds: config.defaultSeconds, elapsedSeconds: 0, runningSince: nil)
    let store = JSONFileStore(url: url, defaultValue: fresh)
    self.store = store
    let clock = try store.load()
    self.clock = clock
    self.didChime = clock.remaining(at: .now) <= 0 && clock.elapsedSeconds > 0
  }

  func start(at now: Date = .now) {
    clock.start(at: now)
    persist()
  }

  func pause(at now: Date = .now) {
    clock.pause(at: now)
    persist()
  }

  func toggle(at now: Date = .now) {
    if clock.isRunning { pause(at: now) } else { start(at: now) }
  }

  func reset() {
    clock.reset()
    didChime = false
    persist()
  }

  func setMinutes(_ value: Double) {
    guard !clock.isRunning else { return }
    clock.setDuration(seconds: value * 60)
    didChime = false
    persist()
  }

  func usePreset(_ seconds: TimeInterval) {
    guard !clock.isRunning else { return }
    clock.setDuration(seconds: seconds)
    didChime = false
    persist()
  }

  @discardableResult
  func tick(at now: Date) -> Bool {
    guard clock.isRunning, clock.remaining(at: now) <= 0 else { return false }
    clock.finish()
    persist()
    guard !didChime else { return false }
    didChime = true
    return true
  }

  private func persist() {
    store.saveOrLog(clock)
  }
}

struct TimerCompact: View {
  let model: TimerModel
  let symbol: String
  var prominent = false

  var body: some View {
    TimelineView(.periodic(from: .now, by: model.config.tickSeconds)) { context in
      HStack(spacing: 6) {
        Image(systemName: symbol)
        Text(ClockText.string(seconds: model.clock.remaining(at: context.date)))
          .monospacedDigit()
      }
      .onChange(of: context.date) { _, date in
        chimeIfNeeded(at: date)
      }
    }
    .font(prominent ? .system(size: 44, weight: .medium, design: .rounded) : .callout.weight(.semibold))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func chimeIfNeeded(at date: Date) {
    guard model.tick(at: date) else { return }
    NSSound(named: NSSound.Name(model.config.completionSound))?.play()
  }
}

struct TimerExpanded: View {
  let model: TimerModel
  let symbol: String
  var settings: SettingsModel

  var body: some View {
    VStack(spacing: 12) {
      TimerCompact(model: model, symbol: symbol, prominent: true)
      Slider(
        value: Binding(get: { model.clock.durationSeconds / 60 }, set: { model.setMinutes($0) }),
        in: 1...model.config.maxMinutes,
        step: 1
      )
      .disabled(model.clock.isRunning)
      .tint(.white)
      HStack {
        ForEach(model.config.presetSeconds, id: \.self) { seconds in
          Button(ClockText.string(seconds: seconds)) { model.usePreset(seconds) }
            .disabled(model.clock.isRunning)
        }
      }
      HStack {
        Button(L10n.text(model.clock.isRunning ? "timer.pause" : "timer.start", locale: settings.locale)) {
          model.toggle()
        }
        .disabled(!model.clock.isRunning && model.clock.remaining(at: .now) <= 0)
        Button(L10n.text("timer.reset", locale: settings.locale)) { model.reset() }
      }
    }
    .buttonStyle(.bordered)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

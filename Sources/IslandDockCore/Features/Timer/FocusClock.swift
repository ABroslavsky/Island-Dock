import Foundation

struct FocusClock: Codable, Equatable, Sendable {
  var durationSeconds: TimeInterval
  var elapsedSeconds: TimeInterval
  var runningSince: Date?

  var isRunning: Bool { runningSince != nil }

  func remaining(at now: Date) -> TimeInterval {
    let live = runningSince.map { max(0, now.timeIntervalSince($0)) } ?? 0
    return max(0, durationSeconds - elapsedSeconds - live)
  }

  mutating func start(at now: Date) {
    guard runningSince == nil, remaining(at: now) > 0 else { return }
    runningSince = now
  }

  mutating func pause(at now: Date) {
    guard let runningSince else { return }
    elapsedSeconds = min(durationSeconds, elapsedSeconds + max(0, now.timeIntervalSince(runningSince)))
    self.runningSince = nil
  }

  mutating func finish() {
    elapsedSeconds = durationSeconds
    runningSince = nil
  }

  mutating func reset() {
    elapsedSeconds = 0
    runningSince = nil
  }

  mutating func setDuration(seconds: TimeInterval) {
    guard runningSince == nil, seconds > 0 else { return }
    durationSeconds = seconds
    elapsedSeconds = 0
  }
}

enum ClockText {
  static func string(seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded(.towardZero)))
    return String(format: "%02d:%02d", total / 60, total % 60)
  }
}

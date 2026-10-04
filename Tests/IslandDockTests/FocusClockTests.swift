import Foundation
import Testing
@testable import IslandDockCore

struct FocusClockTests {
  private let start = Date(timeIntervalSinceReferenceDate: 1_000)

  @Test func countdownPausesAndResumes() {
    var clock = FocusClock(durationSeconds: 25, elapsedSeconds: 0, runningSince: nil)
    clock.start(at: start)
    #expect(clock.remaining(at: start.addingTimeInterval(4)) == 21)
    clock.pause(at: start.addingTimeInterval(4))
    #expect(clock.remaining(at: start.addingTimeInterval(100)) == 21)
    clock.start(at: start.addingTimeInterval(100))
    #expect(clock.remaining(at: start.addingTimeInterval(103)) == 18)
  }

  @Test func pauseCapsAtDuration() {
    var clock = FocusClock(durationSeconds: 10, elapsedSeconds: 0, runningSince: nil)
    clock.start(at: start)
    clock.pause(at: start.addingTimeInterval(50))
    #expect(clock.elapsedSeconds == 10)
    #expect(clock.remaining(at: start) == 0)
    #expect(!clock.isRunning)
  }

  @Test func startIsIgnoredWhenFinishedOrAlreadyRunning() {
    var clock = FocusClock(durationSeconds: 10, elapsedSeconds: 0, runningSince: nil)
    clock.start(at: start)
    clock.start(at: start.addingTimeInterval(1))
    #expect(clock.runningSince == start)
    clock.finish()
    clock.start(at: start.addingTimeInterval(30))
    #expect(!clock.isRunning)
    clock.reset()
    clock.start(at: start.addingTimeInterval(40))
    #expect(clock.isRunning)
  }

  @Test func setDurationIgnoredWhileRunning() {
    var clock = FocusClock(durationSeconds: 10, elapsedSeconds: 0, runningSince: nil)
    clock.start(at: start)
    clock.setDuration(seconds: 30)
    #expect(clock.durationSeconds == 10)
    clock.pause(at: start.addingTimeInterval(2))
    clock.setDuration(seconds: 30)
    #expect(clock.durationSeconds == 30)
    #expect(clock.elapsedSeconds == 0)
  }

  @Test func clockText() {
    #expect(ClockText.string(seconds: 0) == "00:00")
    #expect(ClockText.string(seconds: 90) == "01:30")
    #expect(ClockText.string(seconds: 1500) == "25:00")
    #expect(ClockText.string(seconds: -4) == "00:00")
  }
}

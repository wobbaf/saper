import Foundation
import Combine

/// Manages the countdown timer for timed mode.
class TimerManager: ObservableObject {
    @Published var remaining: TimeInterval = Constants.timedModeDuration
    @Published var isRunning: Bool = false

    private var timer: AnyCancellable?

    var isExpired: Bool { remaining <= 0 }

    func start() {
        remaining = Constants.timedModeDuration
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remaining > 0 {
                    self.remaining -= 1
                } else {
                    self.stop()
                }
            }
    }

    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func pause() {
        timer?.cancel()
        timer = nil
    }

    func resume() {
        guard isRunning, remaining > 0 else { return }
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remaining > 0 {
                    self.remaining -= 1
                } else {
                    self.stop()
                }
            }
    }

    var formattedTime: String {
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

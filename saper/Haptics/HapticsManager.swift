import CoreHaptics
import UIKit

/// Manages haptic feedback using CoreHaptics.
class HapticsManager {
    static let shared = HapticsManager()

    private var engine: CHHapticEngine?
    var isEnabled: Bool = true

    private init() {}

    func setup() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true

            engine?.stoppedHandler = { [weak self] reason in
                self?.restartEngine()
            }
            engine?.resetHandler = { [weak self] in
                self?.restartEngine()
            }

            try engine?.start()
        } catch {
            print("HapticsManager setup failed: \(error)")
        }
    }

    private func restartEngine() {
        do {
            try engine?.start()
        } catch {
            print("Haptic engine restart failed: \(error)")
        }
    }

    func play(_ pattern: HapticPattern) {
        guard isEnabled, let engine = engine else { return }

        do {
            let hapticPattern = try pattern.buildPattern()
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silently fail — haptics are non-essential
        }
    }
}

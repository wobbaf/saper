import Foundation

/// Predefined sound effects for game events.
enum SoundEffect {
    case tileReveal(number: Int)
    case floodFill
    case flagPlace
    case flagRemove
    case mineExplosion
    case sectorSolved
    case gemCollected
    case levelUp
    case uiTap
    case boosterUsed
    case chordReveal
    case lockedSectorTap

    var config: SoundConfig {
        switch self {
        case .tileReveal(let number):
            // Pentatonic scale mapping: 1=low C to 8=high C
            let baseFreq = 523.0  // C5
            let scale: [Double] = [1.0, 9.0/8, 5.0/4, 3.0/2, 5.0/3, 15.0/8, 2.0, 9.0/4, 5.0/2]
            let freq = baseFreq * scale[min(number, 8)]
            return SoundConfig(
                frequency: freq,
                waveform: .sine,
                duration: 0.08,
                attack: 0.005,
                decay: 0.04,
                volume: 0.25
            )

        case .floodFill:
            return SoundConfig(
                frequency: 800,
                waveform: .sine,
                duration: 0.06,
                attack: 0.003,
                decay: 0.03,
                volume: 0.15
            )

        case .flagPlace:
            return SoundConfig(
                frequency: 400,
                waveform: .square,
                duration: 0.1,
                attack: 0.005,
                decay: 0.05,
                volume: 0.2
            )

        case .flagRemove:
            return SoundConfig(
                frequency: 300,
                waveform: .sine,
                duration: 0.06,
                attack: 0.005,
                decay: 0.03,
                volume: 0.15
            )

        case .mineExplosion:
            return SoundConfig(
                frequency: 200,
                waveform: .noise,
                duration: 0.5,
                attack: 0.01,
                decay: 0.4,
                volume: 0.5
            )

        case .sectorSolved:
            return SoundConfig(
                frequency: 523,
                waveform: .sine,
                duration: 0.4,
                attack: 0.02,
                decay: 0.2,
                volume: 0.35
            )

        case .gemCollected:
            return SoundConfig(
                frequency: 784,
                waveform: .sine,
                duration: 0.3,
                attack: 0.01,
                decay: 0.15,
                volume: 0.3
            )

        case .levelUp:
            return SoundConfig(
                frequency: 440,
                waveform: .fmSine(modulatorFreq: 5.0, modulationIndex: 2.0),
                duration: 0.8,
                attack: 0.05,
                decay: 0.4,
                volume: 0.4
            )

        case .uiTap:
            return SoundConfig(
                frequency: 1200,
                waveform: .noise,
                duration: 0.03,
                attack: 0.001,
                decay: 0.02,
                volume: 0.1
            )

        case .boosterUsed:
            return SoundConfig(
                frequency: 600,
                waveform: .triangle,
                duration: 0.3,
                attack: 0.01,
                decay: 0.2,
                volume: 0.3
            )

        case .chordReveal:
            return SoundConfig(
                frequency: 700,
                waveform: .sine,
                duration: 0.1,
                attack: 0.005,
                decay: 0.05,
                volume: 0.2
            )

        case .lockedSectorTap:
            return SoundConfig(
                frequency: 150,
                waveform: .square,
                duration: 0.15,
                attack: 0.005,
                decay: 0.1,
                volume: 0.25
            )
        }
    }

    /// Compound sound for sector solved (ascending chord).
    static var sectorSolvedChord: CompoundSoundConfig {
        CompoundSoundConfig(
            notes: [
                SoundConfig(frequency: 523, waveform: .sine, duration: 0.3, attack: 0.02, decay: 0.15, volume: 0.3),
                SoundConfig(frequency: 659, waveform: .sine, duration: 0.3, attack: 0.02, decay: 0.15, volume: 0.3),
                SoundConfig(frequency: 784, waveform: .sine, duration: 0.4, attack: 0.02, decay: 0.2, volume: 0.35),
            ],
            delays: [0, 0.1, 0.2]
        )
    }

    /// Compound sound for gem collected (two-tone chime).
    static var gemChime: CompoundSoundConfig {
        CompoundSoundConfig(
            notes: [
                SoundConfig(frequency: 1047, waveform: .sine, duration: 0.15, attack: 0.005, decay: 0.08, volume: 0.25),
                SoundConfig(frequency: 1319, waveform: .sine, duration: 0.2, attack: 0.005, decay: 0.1, volume: 0.3),
            ],
            delays: [0, 0.08]
        )
    }

    /// Compound sound for level up (4-note ascending fanfare).
    static var levelUpFanfare: CompoundSoundConfig {
        CompoundSoundConfig(
            notes: [
                SoundConfig(frequency: 523, waveform: .sine, duration: 0.15, attack: 0.01, decay: 0.08, volume: 0.3),
                SoundConfig(frequency: 659, waveform: .sine, duration: 0.15, attack: 0.01, decay: 0.08, volume: 0.3),
                SoundConfig(frequency: 784, waveform: .sine, duration: 0.15, attack: 0.01, decay: 0.08, volume: 0.3),
                SoundConfig(frequency: 1047, waveform: .sine, duration: 0.4, attack: 0.02, decay: 0.2, volume: 0.4),
            ],
            delays: [0, 0.12, 0.24, 0.36]
        )
    }
}

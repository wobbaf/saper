import AVFAudio
import Foundation

/// Procedural cyberpunk music engine.
///
/// Generates a 128-BPM D-minor synthwave loop entirely in code — no audio files.
/// Layers: kick drum · sub bass · FM bass · triangle arpeggio · hi-hat · pad chord.
/// Pattern evolves every 8 bars to avoid sounding like a hard loop.
///
/// Call `attach(to:)` once during AudioManager setup, then `start()` / `stop()` / `pause()`.
final class MusicEngine {
    static let shared = MusicEngine()
    private init() {}

    // MARK: - Config

    private let sampleRate: Double = 44100
    private let bpm: Double = 128.0

    /// Master music volume — caller sets this from ambienceVolume (0–1).
    var outputVolume: Float = 0.28
    var isEnabled: Bool = true

    // MARK: - Engine attachment

    private var isAttached = false

    func attach(to engine: AVAudioEngine) {
        guard !isAttached else { return }
        isAttached = true
        cachedSPStep = samplesPerStep

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, abl -> OSStatus in
            self?.render(frameCount: Int(frameCount), abl: abl)
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
    }

    // MARK: - Public control (main thread)

    func start() {
        guard isEnabled else { return }
        fadeTarget = 1.0
        padTarget  = 0.16
        pendingReset = true
    }

    func stop() {
        fadeTarget = 0.0
        padTarget  = 0.0
    }

    func pause() {
        guard isEnabled else { return }
        fadeTarget = 0.12   // dim but audible under pause overlay
        padTarget  = 0.06
    }

    func resume() {
        guard isEnabled else { return }
        fadeTarget = 1.0
        padTarget  = 0.16
    }

    // MARK: - Sequencer constants

    private var samplesPerStep: Int { Int(sampleRate * 60.0 / (bpm * 4.0)) }

    // Precomputed at attach time so the render callback avoids division.
    private var cachedSPStep = 0

    // D minor / Dm7 frequencies
    // Bass line (16 steps = 1 bar at 16th-note resolution)
    // 0 = rest
    private let bassLine: [Double] = [
        73.42, 0,      0,      0,       // D2  beat 1
        110.0, 0,      0,      0,       // A2  beat 2
        87.31, 0,      0,      87.31,   // F2  beat 3, &3
        110.0, 0,      73.42,  0        // A2  beat 4, D2 &4
    ]

    // Sub bass mirrors bass but an octave lower
    private let subLine: [Double] = [
        36.71, 0,      0,      0,
        55.0,  0,      0,      0,
        43.65, 0,      0,      43.65,
        55.0,  0,      36.71,  0
    ]

    // Kick on beat 1 and beat 3
    private let kickPattern: [Bool] = [
        true,  false, false, false,
        false, false, false, false,
        true,  false, false, false,
        false, false, false, false
    ]

    // Hat on every 8th note (steps 0,2,4,6,8,10,12,14) + extra 16th on step 15
    private let hatPattern: [Bool] = [
        true,  false, true, false,
        true,  false, true, false,
        true,  false, true, false,
        true,  false, true, true
    ]

    // Three arp variations — index swapped every 8 bars (render-thread read, main-thread write is Int = atomic on ARM64)
    private let arpVariations: [[Double]] = [
        // Variation A — ascending Dm7 then back
        [146.83, 174.61, 220.00, 261.63,  220.00, 174.61, 146.83, 130.81,
         146.83, 220.00, 174.61, 261.63,  220.00, 174.61, 261.63, 146.83],
        // Variation B — wider jumps
        [146.83, 220.00, 261.63, 174.61,  220.00, 146.83, 174.61, 261.63,
         146.83, 174.61, 261.63, 220.00,  174.61, 261.63, 220.00, 146.83],
        // Variation C — starts on A3 for contrast
        [220.00, 174.61, 146.83, 261.63,  146.83, 220.00, 174.61, 130.81,
         261.63, 174.61, 220.00, 146.83,  174.61, 130.81, 146.83, 220.00]
    ]
    private var arpVariation = 0   // written from render thread only — no lock needed

    // MARK: - Render state (render thread only — no locks)

    // Sequencer
    private var stepCountdown = 0
    private var step = 0
    private var bar  = 0

    // Master fade
    private var fade: Float = 0
    private var fadeTarget: Float = 0          // written from main thread (Float = atomic ARM64)
    private let fadeRate: Float = 1.0 / (44100 * 2)   // 2-second fade

    // Pending reset flag (main → render)
    private var pendingReset: Bool = false     // Bool = atomic ARM64

    // Pad
    private var padAmp: Float = 0
    private var padTarget: Float = 0           // written from main thread
    private let padRise: Float = 1.0 / (44100 * 3)    // 3s rise
    private let padFall: Float = 1.0 / (44100 * 2)    // 2s fall
    private var padPh0 = 0.0                   // D3 = 146.83 Hz
    private var padPh1 = 0.0                   // F3 = 174.61 Hz
    private var padPh2 = 0.0                   // A3 = 220.00 Hz

    // Bass (FM synthesis)
    private var bassFreq = 0.0
    private var bassCarrierPh = 0.0
    private var bassModPh = 0.0
    private var bassAmp: Float = 0
    private let bassDecay: Float = 1.0 / (44100 * 28 / 100)   // 280 ms

    // Sub (pure sine)
    private var subFreq = 0.0
    private var subPh = 0.0
    private var subAmp: Float = 0
    private let subDecay: Float = 1.0 / (44100 * 38 / 100)    // 380 ms

    // Kick (pitch-swept sine + noise click)
    private var kickPh = 0.0
    private var kickFreq: Double = 0
    private var kickAmp: Float = 0
    private let kickDecay: Float = 1.0 / (44100 * 15 / 100)   // 150 ms
    private let kickFreqDecay: Double = 1.0 / (44100 * 8 / 100) // pitch drops over 80ms
    private var kickClickAmp: Float = 0
    private let kickClickDecay: Float = 1.0 / (44100 * 2 / 100) // 20 ms transient
    private var kickNoise: UInt64 = 0xC0FFEE1234567890

    // Arpeggio (triangle wave)
    private var arpFreq = 0.0
    private var arpPh = 0.0
    private var arpAmp: Float = 0
    private let arpDecay: Float = 1.0 / (44100 * 9 / 100)     // 90 ms

    // Hi-hat (high-passed noise)
    private var hatAmp: Float = 0
    private let hatDecay: Float = 1.0 / (44100 * 4 / 100)     // 40 ms
    private var hatNoise: UInt64 = 0xDEADBEEFCAFEBABE
    private var hatPrev: Float = 0   // for 1-pole high-pass

    // MARK: - Render

    private func render(frameCount: Int, abl: UnsafeMutablePointer<AudioBufferList>) {
        guard let buf = UnsafeMutableAudioBufferListPointer(abl)[0]
                .mData?.assumingMemoryBound(to: Float.self) else { return }

        // Handle pending reset (new run started)
        if pendingReset {
            pendingReset = false
            step = 0
            bar  = 0
            stepCountdown = 0
        }

        for i in 0..<frameCount {

            // Sequencer tick
            stepCountdown -= 1
            if stepCountdown <= 0 {
                stepCountdown = cachedSPStep
                triggerStep(step)
                step = (step + 1) & 15
                if step == 0 {
                    bar = (bar + 1) & 7
                    if bar == 0 {
                        arpVariation = (arpVariation + 1) % arpVariations.count
                    }
                }
            }

            // Fade (written from main thread as Float — atomic on ARM64)
            if fade < fadeTarget {
                fade = min(fade + fadeRate, fadeTarget)
            } else if fade > fadeTarget {
                fade = max(fade - fadeRate, 0)
            }

            // Pad envelope
            if padAmp < padTarget {
                padAmp = min(padAmp + padRise, padTarget)
            } else if padAmp > padTarget {
                padAmp = max(padAmp - padFall, padTarget)
            }

            // Early-out when fully silent
            if fade < 0.0001 && padAmp < 0.0001 { buf[i] = 0; continue }

            var s: Float = 0

            // --- Pad (3 sine tones, always running for smooth fade) ---
            if padAmp > 0.0001 {
                padPh0 += 146.83 / sampleRate; if padPh0 > 1 { padPh0 -= 1 }
                padPh1 += 174.61 / sampleRate; if padPh1 > 1 { padPh1 -= 1 }
                padPh2 += 220.00 / sampleRate; if padPh2 > 1 { padPh2 -= 1 }
                s += Float(sin(2 * .pi * padPh0)) * padAmp * 1.00
                s += Float(sin(2 * .pi * padPh1)) * padAmp * 0.75
                s += Float(sin(2 * .pi * padPh2)) * padAmp * 0.55
            }

            // --- Sub bass ---
            if subAmp > 0.0001 {
                subPh += subFreq / sampleRate; if subPh > 1 { subPh -= 1 }
                s += Float(sin(2 * .pi * subPh)) * subAmp * 0.28
                subAmp -= subDecay; if subAmp < 0 { subAmp = 0 }
            }

            // --- Kick (pitch-swept sine + click) ---
            if kickAmp > 0.0001 {
                kickPh += kickFreq / sampleRate; if kickPh > 1 { kickPh -= 1 }
                s += Float(sin(2 * .pi * kickPh)) * kickAmp * 0.38
                kickAmp -= kickDecay; if kickAmp < 0 { kickAmp = 0 }
                // Pitch sweep down
                kickFreq = max(35.0, kickFreq - kickFreqDecay * kickFreq)
            }
            if kickClickAmp > 0.0001 {
                kickNoise ^= kickNoise << 13; kickNoise ^= kickNoise >> 7; kickNoise ^= kickNoise << 17
                let click = Float(Int64(bitPattern: kickNoise)) / Float(Int64.max)
                s += click * kickClickAmp * 0.10
                kickClickAmp -= kickClickDecay; if kickClickAmp < 0 { kickClickAmp = 0 }
            }

            // --- FM bass ---
            if bassAmp > 0.0001 {
                bassModPh += (bassFreq * 2.0) / sampleRate; if bassModPh > 1 { bassModPh -= 1 }
                let mod = sin(2 * .pi * bassModPh) * bassFreq * 0.45
                bassCarrierPh += (bassFreq + mod) / sampleRate; if bassCarrierPh > 1 { bassCarrierPh -= 1 }
                s += Float(sin(2 * .pi * bassCarrierPh)) * bassAmp * 0.26
                bassAmp -= bassDecay; if bassAmp < 0 { bassAmp = 0 }
            }

            // --- Arp (triangle) ---
            if arpAmp > 0.0001 {
                arpPh += arpFreq / sampleRate; if arpPh > 1 { arpPh -= 1 }
                let tri = Float(abs(2.0 * arpPh - 1.0) * 2.0 - 1.0)
                s += tri * arpAmp * 0.11
                arpAmp -= arpDecay; if arpAmp < 0 { arpAmp = 0 }
            }

            // --- Hi-hat (HP-filtered noise) ---
            if hatAmp > 0.0001 {
                hatNoise ^= hatNoise << 13; hatNoise ^= hatNoise >> 7; hatNoise ^= hatNoise << 17
                let noise = Float(Int64(bitPattern: hatNoise)) / Float(Int64.max)
                let hp = noise - hatPrev; hatPrev = noise
                s += hp * hatAmp * 0.055
                hatAmp -= hatDecay; if hatAmp < 0 { hatAmp = 0 }
            }

            buf[i] = max(-1, min(1, s * outputVolume * fade))
        }
    }

    private func triggerStep(_ s: Int) {
        // Kick
        if kickPattern[s] {
            kickFreq = 155.0
            kickPh = 0
            kickAmp = 1.0
            kickClickAmp = 1.0
        }

        // Sub + bass
        let bf = bassLine[s]
        if bf > 0 {
            bassFreq = bf
            bassCarrierPh = 0
            bassModPh = 0
            bassAmp = 1.0
            subFreq = subLine[s]
            subPh = 0
            subAmp = 1.0
        }

        // Arp
        let af = arpVariations[arpVariation][s]
        if af > 0 {
            arpFreq = af
            arpPh = 0
            arpAmp = 1.0
        }

        // Hat
        if hatPattern[s] {
            hatAmp = 1.0
            hatPrev = 0
        }
    }
}

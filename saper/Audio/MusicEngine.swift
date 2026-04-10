import AVFAudio
import Foundation

/// Procedural cyberpunk music engine.
///
/// Generates a 128-BPM D-minor synthwave loop entirely in code — no audio files.
/// Layers: kick drum · sub bass · FM bass · triangle arpeggio · hi-hat · pad chord.
/// Pattern evolves every 8 bars to avoid sounding like a hard loop.
///
/// Reactive events (call from main thread):
///   triggerMineHit()      — dissonant dim7 FM stab
///   triggerSectorSolved() — ascending arp fill D4→F4→A4→D5
///   triggerLevelUp()      — queues a beat-locked 1-bar rise then drop
///
/// Dynamic intensity: set sectorsCompleted — at 6+ a second arp voice joins,
/// at 16+ a distorted bass layer thickens the sound.
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
        fadeTarget   = 1.0
        padTarget    = 0.16
        pendingReset = true
    }

    func stop() {
        fadeTarget = 0.0
        padTarget  = 0.0
    }

    func pause() {
        guard isEnabled else { return }
        fadeTarget = 0.12
        padTarget  = 0.06
    }

    func resume() {
        guard isEnabled else { return }
        fadeTarget = 1.0
        padTarget  = 0.16
    }

    // MARK: - Reactive event triggers (main thread → render thread, atomic on ARM64)

    /// Fires a dissonant dim7 stab — call on mine hit.
    func triggerMineHit() { pendingMineHit = true }

    /// Fires an ascending arp fill — call on sector solved.
    func triggerSectorSolved() { pendingSectorSolved = true }

    /// Queues a beat-locked 1-bar rise + drop — call on level up.
    func triggerLevelUp() { pendingLevelUp = true }

    /// Dynamic intensity tier. Write from main thread (Int is atomic on ARM64).
    var sectorsCompleted: Int = 0

    // MARK: - Sequencer constants

    private var samplesPerStep: Int { Int(sampleRate * 60.0 / (bpm * 4.0)) }
    private var cachedSPStep = 0

    // D minor / Dm7 frequencies
    private let bassLine: [Double] = [
        73.42, 0,      0,      0,
        110.0, 0,      0,      0,
        87.31, 0,      0,      87.31,
        110.0, 0,      73.42,  0
    ]
    private let subLine: [Double] = [
        36.71, 0,      0,      0,
        55.0,  0,      0,      0,
        43.65, 0,      0,      43.65,
        55.0,  0,      36.71,  0
    ]
    private let kickPattern: [Bool] = [
        true,  false, false, false,
        false, false, false, false,
        true,  false, false, false,
        false, false, false, false
    ]
    private let hatPattern: [Bool] = [
        true,  false, true, false,
        true,  false, true, false,
        true,  false, true, false,
        true,  false, true, true
    ]
    private let arpVariations: [[Double]] = [
        [146.83, 174.61, 220.00, 261.63,  220.00, 174.61, 146.83, 130.81,
         146.83, 220.00, 174.61, 261.63,  220.00, 174.61, 261.63, 146.83],
        [146.83, 220.00, 261.63, 174.61,  220.00, 146.83, 174.61, 261.63,
         146.83, 174.61, 261.63, 220.00,  174.61, 261.63, 220.00, 146.83],
        [220.00, 174.61, 146.83, 261.63,  146.83, 220.00, 174.61, 130.81,
         261.63, 174.61, 220.00, 146.83,  174.61, 130.81, 146.83, 220.00]
    ]
    private var arpVariation = 0

    // MARK: - Render state (render thread only)

    // Sequencer
    private var stepCountdown = 0
    private var step = 0
    private var bar  = 0

    // Master fade
    private var fade: Float = 0
    private var fadeTarget: Float = 0
    private let fadeRate: Float = 1.0 / (44100 * 2)

    // Pending flags
    private var pendingReset: Bool    = false
    private var pendingMineHit: Bool  = false
    private var pendingSectorSolved: Bool = false
    private var pendingLevelUp: Bool  = false

    // Pad
    private var padAmp: Float = 0
    private var padTarget: Float = 0
    private let padRise: Float = 1.0 / (44100 * 3)
    private let padFall: Float = 1.0 / (44100 * 2)
    private var padPh0 = 0.0
    private var padPh1 = 0.0
    private var padPh2 = 0.0

    // Bass (FM)
    private var bassFreq = 0.0
    private var bassCarrierPh = 0.0
    private var bassModPh = 0.0
    private var bassAmp: Float = 0
    private let bassDecay: Float = 1.0 / (44100 * 28 / 100)

    // Sub (pure sine)
    private var subFreq = 0.0
    private var subPh = 0.0
    private var subAmp: Float = 0
    private let subDecay: Float = 1.0 / (44100 * 38 / 100)

    // Kick
    private var kickPh = 0.0
    private var kickFreq: Double = 0
    private var kickAmp: Float = 0
    private let kickDecay: Float = 1.0 / (44100 * 15 / 100)
    private let kickFreqDecay: Double = 1.0 / (44100 * 8 / 100)
    private var kickClickAmp: Float = 0
    private let kickClickDecay: Float = 1.0 / (44100 * 2 / 100)
    private var kickNoise: UInt64 = 0xC0FFEE1234567890

    // Arp (triangle)
    private var arpFreq = 0.0
    private var arpPh = 0.0
    private var arpAmp: Float = 0
    private let arpDecay: Float = 1.0 / (44100 * 9 / 100)

    // Hi-hat (HP noise)
    private var hatAmp: Float = 0
    private let hatDecay: Float = 1.0 / (44100 * 4 / 100)
    private var hatNoise: UInt64 = 0xDEADBEEFCAFEBABE
    private var hatPrev: Float = 0

    // MARK: - Event: Mine hit — Ddim7 FM stab (D F Ab B)

    private let mineFreqs: [Double] = [146.83, 174.61, 207.65, 246.94]
    private var minePh    = [Double](repeating: 0, count: 4)
    private var mineModPh = [Double](repeating: 0, count: 4)
    private var mineAmp: Float = 0
    private let mineDecay: Float = 1.0 / Float(44100 * 25 / 100)  // 250 ms

    // MARK: - Event: Sector solved — ascending D4 F4 A4 D5 arp fill

    private let solveNotes: [Double] = [293.66, 349.23, 440.00, 587.33]
    private var solvePh: Double = 0
    private var solveFreq: Double = 0
    private var solveAmp: Float = 0
    private let solveNoteDecay: Float = 1.0 / Float(44100 * 7 / 100)  // 70 ms
    private var solveNoteIdx: Int = -1
    private var solveCountdown: Int = 0
    private let solveNoteSamples = Int(44100 * 60 / 1000)  // 60 ms per note

    // MARK: - Event: Level-up — beat-locked rise then drop
    //
    // State machine (render-thread only):
    //   0 idle     — nothing happening
    //   1 waitBar  — pendingLevelUp was set; waiting for next step==0 to begin
    //   2 rising   — 1-bar build: bass suppressed, riser sweeps up, arp double-timed
    //   3 drop     — fires on step==0 after rise: chord stab + kick + bass resumes
    //   4 decay    — dropAmp fades over ~2 bars, then back to idle

    private var luPhase: Int = 0
    private var luBarSamples: Int = 0    // samples left in current LU bar phase
    private var suppressBass: Bool = false

    // Rise: LP-filtered noise sweeping from 300 Hz to 7000 Hz cutoff
    private var riserAmp: Float = 0
    private let riserRise: Float = 1.0 / Float(44100 * 28 / 100)  // fade in over ~280ms (half a bar)
    private var riserCutoff: Double = 300.0
    private var riserFilterPrev: Float = 0
    private var riserNoise: UInt64 = 0xFEEDFACEDEADBEEF

    // Double-speed arp during rise (32nd notes)
    private var riseArpCountdown: Int = 0
    private var riseArpStep: Int = 0

    // Drop chord: D3 A3 D4 power chord stab
    private let dropFreqs: [Double] = [146.83, 220.00, 293.66]
    private var dropPh = [Double](repeating: 0, count: 3)
    private var dropAmp: Float = 0
    private let dropDecay: Float = 1.0 / Float(44100 * 60 / 100)  // 600 ms

    // MARK: - Dynamic intensity: second arp voice (octave up, tier 2+)

    private var arp2Freq = 0.0
    private var arp2Ph = 0.0
    private var arp2Amp: Float = 0
    private let arp2Decay: Float = 1.0 / Float(44100 * 9 / 100)

    // Distorted bass layer (tier 3+): waveshaper on a copy of the bass signal
    private var distBassCarrierPh = 0.0
    private var distBassModPh = 0.0
    private var distBassAmp: Float = 0
    private let distBassDecay: Float = 1.0 / Float(44100 * 28 / 100)
    private var distBassFreq = 0.0

    // MARK: - Render

    private func render(frameCount: Int, abl: UnsafeMutablePointer<AudioBufferList>) {
        guard let buf = UnsafeMutableAudioBufferListPointer(abl)[0]
                .mData?.assumingMemoryBound(to: Float.self) else { return }

        if pendingReset {
            pendingReset = false
            step = 0; bar = 0; stepCountdown = 0
            luPhase = 0; suppressBass = false
            riserAmp = 0; dropAmp = 0; mineAmp = 0; solveNoteIdx = -1
        }

        // Consume pending events (safe: Bool/Int atomic on ARM64)
        if pendingMineHit  { pendingMineHit  = false; fireMineHit() }
        if pendingSectorSolved { pendingSectorSolved = false; fireSectorSolved() }
        if pendingLevelUp && luPhase == 0 { pendingLevelUp = false; luPhase = 1 }

        let tier = sectorsCompleted  // snapshot once per buffer (atomic Int)

        for i in 0..<frameCount {

            // --- Sequencer tick ---
            stepCountdown -= 1
            if stepCountdown <= 0 {
                stepCountdown = cachedSPStep

                // Level-up: start rise on next bar boundary
                if luPhase == 1 && step == 0 {
                    luPhase = 2
                    luBarSamples = cachedSPStep * 16
                    suppressBass = true
                    riserCutoff = 300.0
                    riseArpCountdown = cachedSPStep / 2
                    riseArpStep = step
                }

                // Level-up: fire drop on bar boundary after rise
                if luPhase == 2 {
                    luBarSamples -= cachedSPStep
                    if luBarSamples <= 0 && step == 0 {
                        luPhase = 3
                    }
                }

                if luPhase == 3 {
                    fireDropStab()
                    suppressBass = false
                    riserAmp = 0
                    luPhase = 4
                }

                if !suppressBass {
                    triggerStep(step, tier: tier)
                } else {
                    // During rise: still fire kick + hat, skip bass/sub
                    triggerRiseStep(step, tier: tier)
                }

                step = (step + 1) & 15
                if step == 0 {
                    bar = (bar + 1) & 7
                    if bar == 0 { arpVariation = (arpVariation + 1) % arpVariations.count }
                    // End decay phase after 2 bars
                    if luPhase == 4 && dropAmp < 0.05 { luPhase = 0 }
                }
            }

            // --- Fade ---
            if fade < fadeTarget { fade = min(fade + fadeRate, fadeTarget) }
            else if fade > fadeTarget { fade = max(fade - fadeRate, 0) }

            // --- Pad ---
            if padAmp < padTarget { padAmp = min(padAmp + padRise, padTarget) }
            else if padAmp > padTarget { padAmp = max(padAmp - padFall, padTarget) }

            if fade < 0.0001 && padAmp < 0.0001 { buf[i] = 0; continue }

            var s: Float = 0

            // Pad
            if padAmp > 0.0001 {
                padPh0 += 146.83 / sampleRate; if padPh0 > 1 { padPh0 -= 1 }
                padPh1 += 174.61 / sampleRate; if padPh1 > 1 { padPh1 -= 1 }
                padPh2 += 220.00 / sampleRate; if padPh2 > 1 { padPh2 -= 1 }
                s += Float(sin(2 * .pi * padPh0)) * padAmp * 1.00
                s += Float(sin(2 * .pi * padPh1)) * padAmp * 0.75
                s += Float(sin(2 * .pi * padPh2)) * padAmp * 0.55
            }

            // Sub
            if subAmp > 0.0001 {
                subPh += subFreq / sampleRate; if subPh > 1 { subPh -= 1 }
                s += Float(sin(2 * .pi * subPh)) * subAmp * 0.28
                subAmp -= subDecay; if subAmp < 0 { subAmp = 0 }
            }

            // Kick
            if kickAmp > 0.0001 {
                kickPh += kickFreq / sampleRate; if kickPh > 1 { kickPh -= 1 }
                s += Float(sin(2 * .pi * kickPh)) * kickAmp * 0.38
                kickAmp -= kickDecay; if kickAmp < 0 { kickAmp = 0 }
                kickFreq = max(35.0, kickFreq - kickFreqDecay * kickFreq)
            }
            if kickClickAmp > 0.0001 {
                kickNoise ^= kickNoise << 13; kickNoise ^= kickNoise >> 7; kickNoise ^= kickNoise << 17
                let click = Float(Int64(bitPattern: kickNoise)) / Float(Int64.max)
                s += click * kickClickAmp * 0.10
                kickClickAmp -= kickClickDecay; if kickClickAmp < 0 { kickClickAmp = 0 }
            }

            // FM bass
            if bassAmp > 0.0001 {
                bassModPh += (bassFreq * 2.0) / sampleRate; if bassModPh > 1 { bassModPh -= 1 }
                let mod = sin(2 * .pi * bassModPh) * bassFreq * 0.45
                bassCarrierPh += (bassFreq + mod) / sampleRate; if bassCarrierPh > 1 { bassCarrierPh -= 1 }
                s += Float(sin(2 * .pi * bassCarrierPh)) * bassAmp * 0.26
                bassAmp -= bassDecay; if bassAmp < 0 { bassAmp = 0 }
            }

            // Distorted bass layer (tier 3+)
            if tier >= 16 && distBassAmp > 0.0001 {
                distBassModPh += (distBassFreq * 2.0) / sampleRate; if distBassModPh > 1 { distBassModPh -= 1 }
                let dmod = sin(2 * .pi * distBassModPh) * distBassFreq * 0.6
                distBassCarrierPh += (distBassFreq + dmod) / sampleRate; if distBassCarrierPh > 1 { distBassCarrierPh -= 1 }
                var db = Float(sin(2 * .pi * distBassCarrierPh)) * distBassAmp
                // Soft-clip waveshaper
                db = db > 0 ? 1 - exp(-db * 3) : -(1 - exp(db * 3))
                s += db * 0.18
                distBassAmp -= distBassDecay; if distBassAmp < 0 { distBassAmp = 0 }
            }

            // Arp (triangle)
            if arpAmp > 0.0001 {
                arpPh += arpFreq / sampleRate; if arpPh > 1 { arpPh -= 1 }
                let tri = Float(abs(2.0 * arpPh - 1.0) * 2.0 - 1.0)
                s += tri * arpAmp * 0.11
                arpAmp -= arpDecay; if arpAmp < 0 { arpAmp = 0 }
            }

            // Second arp voice (tier 2+, octave up)
            if tier >= 6 && arp2Amp > 0.0001 {
                arp2Ph += arp2Freq / sampleRate; if arp2Ph > 1 { arp2Ph -= 1 }
                let tri2 = Float(abs(2.0 * arp2Ph - 1.0) * 2.0 - 1.0)
                s += tri2 * arp2Amp * 0.07
                arp2Amp -= arp2Decay; if arp2Amp < 0 { arp2Amp = 0 }
            }

            // Hat
            if hatAmp > 0.0001 {
                hatNoise ^= hatNoise << 13; hatNoise ^= hatNoise >> 7; hatNoise ^= hatNoise << 17
                let noise = Float(Int64(bitPattern: hatNoise)) / Float(Int64.max)
                let hp = noise - hatPrev; hatPrev = noise
                s += hp * hatAmp * 0.055
                hatAmp -= hatDecay; if hatAmp < 0 { hatAmp = 0 }
            }

            // --- Rise riser (during level-up rise phase) ---
            if luPhase == 2 {
                // Ramp amp up over first half bar
                riserAmp = min(riserAmp + riserRise, 0.9)
                // Sweep cutoff from 300 Hz → 7000 Hz over the bar
                let progress = Double(max(0, cachedSPStep * 16 - luBarSamples)) / Double(cachedSPStep * 16)
                riserCutoff = 300.0 + progress * 6700.0
                // LP-filtered noise
                riserNoise ^= riserNoise << 13; riserNoise ^= riserNoise >> 7; riserNoise ^= riserNoise << 17
                let rn = Float(Int64(bitPattern: riserNoise)) / Float(Int64.max)
                let alpha = Float(1.0 - exp(-2.0 * .pi * riserCutoff / sampleRate))
                riserFilterPrev += alpha * (rn - riserFilterPrev)
                s += riserFilterPrev * riserAmp * 0.25

                // Double-speed arp
                riseArpCountdown -= 1
                if riseArpCountdown <= 0 {
                    riseArpCountdown = cachedSPStep / 2
                    let af = arpVariations[arpVariation][riseArpStep & 15]
                    if af > 0 { arpFreq = af * 2.0; arpPh = 0; arpAmp = 0.7 }
                    riseArpStep += 1
                }
            }

            // --- Drop chord stab ---
            if dropAmp > 0.0001 {
                for v in 0..<3 {
                    dropPh[v] += dropFreqs[v] / sampleRate; if dropPh[v] > 1 { dropPh[v] -= 1 }
                    s += Float(sin(2 * .pi * dropPh[v])) * dropAmp * 0.22
                }
                dropAmp -= dropDecay; if dropAmp < 0 { dropAmp = 0 }
            }

            // --- Mine hit stab (Ddim7 FM) ---
            if mineAmp > 0.0001 {
                for v in 0..<4 {
                    mineModPh[v] += (mineFreqs[v] * 1.5) / sampleRate
                    if mineModPh[v] > 1 { mineModPh[v] -= 1 }
                    let mmod = sin(2 * .pi * mineModPh[v]) * mineFreqs[v] * 0.8
                    minePh[v] += (mineFreqs[v] + mmod) / sampleRate
                    if minePh[v] > 1 { minePh[v] -= 1 }
                    s += Float(sin(2 * .pi * minePh[v])) * mineAmp * 0.12
                }
                mineAmp -= mineDecay; if mineAmp < 0 { mineAmp = 0 }
            }

            // --- Sector solve arp fill ---
            if solveNoteIdx >= 0 {
                solveCountdown -= 1
                if solveCountdown <= 0 {
                    solveNoteIdx += 1
                    if solveNoteIdx < solveNotes.count {
                        solveFreq = solveNotes[solveNoteIdx]
                        solvePh   = 0
                        solveAmp  = 0.55
                        solveCountdown = solveNoteSamples
                    } else {
                        solveNoteIdx = -1  // done
                    }
                }
                if solveNoteIdx >= 0 && solveAmp > 0.0001 {
                    solvePh += solveFreq / sampleRate; if solvePh > 1 { solvePh -= 1 }
                    let tri = Float(abs(2.0 * solvePh - 1.0) * 2.0 - 1.0)
                    s += tri * solveAmp * 0.13
                    solveAmp -= solveNoteDecay; if solveAmp < 0 { solveAmp = 0 }
                }
            }

            buf[i] = max(-1, min(1, s * outputVolume * fade))
        }
    }

    // MARK: - Step triggers

    private func triggerStep(_ s: Int, tier: Int) {
        if kickPattern[s] {
            kickFreq = 155.0; kickPh = 0; kickAmp = 1.0; kickClickAmp = 1.0
        }
        let bf = bassLine[s]
        if bf > 0 {
            bassFreq = bf; bassCarrierPh = 0; bassModPh = 0; bassAmp = 1.0
            subFreq = subLine[s]; subPh = 0; subAmp = 1.0
            if tier >= 16 {
                distBassFreq = bf; distBassCarrierPh = 0; distBassModPh = 0; distBassAmp = 1.0
            }
        }
        let af = arpVariations[arpVariation][s]
        if af > 0 {
            arpFreq = af; arpPh = 0; arpAmp = 1.0
            if tier >= 6 { arp2Freq = af * 2.0; arp2Ph = 0; arp2Amp = 0.7 }
        }
        if hatPattern[s] { hatAmp = 1.0; hatPrev = 0 }
        // Tier 2+: extra offbeat hats on odd 8th-note steps
        if tier >= 6 && (s == 1 || s == 3 || s == 5 || s == 7 || s == 9 || s == 11 || s == 13) {
            hatAmp = max(hatAmp, 0.5); hatPrev = 0
        }
    }

    /// Fires kick + hat during rise, but suppresses bass/sub re-triggers.
    private func triggerRiseStep(_ s: Int, tier: Int) {
        if kickPattern[s] {
            kickFreq = 155.0; kickPh = 0; kickAmp = 1.0; kickClickAmp = 1.0
        }
        if hatPattern[s] { hatAmp = 1.0; hatPrev = 0 }
    }

    // MARK: - Event fires (render thread)

    private func fireMineHit() {
        mineAmp = 1.0
        for v in 0..<4 { minePh[v] = 0; mineModPh[v] = 0 }
    }

    private func fireSectorSolved() {
        solveNoteIdx  = 0
        solveFreq     = solveNotes[0]
        solvePh       = 0
        solveAmp      = 0.55
        solveCountdown = solveNoteSamples
    }

    private func fireDropStab() {
        // Extra kick on the drop
        kickFreq = 155.0; kickPh = 0; kickAmp = 1.0; kickClickAmp = 1.0
        // Chord stab
        dropAmp = 1.0
        for v in 0..<3 { dropPh[v] = 0 }
    }
}

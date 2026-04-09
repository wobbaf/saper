import Foundation
import AVFAudio

/// Waveform types for sound synthesis.
enum Waveform {
    case sine
    case square
    case triangle
    case noise
    case fmSine(modulatorFreq: Double, modulationIndex: Double)
}

/// Configuration for a synthesized sound.
struct SoundConfig {
    let frequency: Double
    let waveform: Waveform
    let duration: Double
    let attack: Double
    let decay: Double
    let volume: Float

    init(frequency: Double = 440, waveform: Waveform = .sine, duration: Double = 0.2,
         attack: Double = 0.01, decay: Double = 0.1, volume: Float = 0.5) {
        self.frequency = frequency
        self.waveform = waveform
        self.duration = duration
        self.attack = attack
        self.decay = decay
        self.volume = volume
    }
}

/// Multi-voice sound with sequential or layered notes.
struct CompoundSoundConfig {
    let notes: [SoundConfig]
    let delays: [Double]  // Delay before each note starts
}

/// Generates audio waveforms in real-time for AVAudioSourceNode.
class SoundSynthesizer {
    private let sampleRate: Double = 44100
    private var activeVoices: [Voice] = []
    private let lock = NSLock()

    private class Voice {
        let config: SoundConfig
        var phase: Double = 0
        var sampleTime: Int = 0
        var volume: Float
        let totalSamples: Int
        let attackSamples: Int
        let decaySamples: Int
        var isFinished: Bool = false
        // For noise
        var noiseState: UInt64 = 12345

        init(config: SoundConfig, sampleRate: Double, volume: Float) {
            self.config = config
            self.volume = volume
            self.totalSamples = Int(config.duration * sampleRate)
            self.attackSamples = Int(config.attack * sampleRate)
            self.decaySamples = Int(config.decay * sampleRate)
        }
    }

    func play(_ config: SoundConfig, volume: Float = 1.0) {
        let voice = Voice(config: config, sampleRate: sampleRate, volume: config.volume * volume)
        lock.lock()
        // Limit active voices
        if activeVoices.count > 8 {
            activeVoices.removeFirst()
        }
        activeVoices.append(voice)
        lock.unlock()
    }

    func playCompound(_ compound: CompoundSoundConfig, volume: Float = 1.0) {
        for (index, note) in compound.notes.enumerated() {
            let delay = index < compound.delays.count ? compound.delays[index] : 0
            if delay <= 0 {
                play(note, volume: volume)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.play(note, volume: volume)
                }
            }
        }
    }

    func stopAll() {
        lock.lock()
        activeVoices.removeAll()
        lock.unlock()
    }

    func render(frameCount: UInt32, bufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
        guard let buffer = ablPointer.first,
              let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
            return noErr
        }

        lock.lock()
        let voices = activeVoices
        lock.unlock()

        // Clear buffer
        for frame in 0..<Int(frameCount) {
            data[frame] = 0
        }

        for voice in voices {
            for frame in 0..<Int(frameCount) {
                if voice.isFinished { break }

                let sample = generateSample(voice: voice)
                let envelope = calculateEnvelope(voice: voice)

                data[frame] += sample * envelope * voice.volume

                voice.sampleTime += 1
                if voice.sampleTime >= voice.totalSamples {
                    voice.isFinished = true
                }
            }
        }

        // Clamp output
        for frame in 0..<Int(frameCount) {
            data[frame] = max(-1.0, min(1.0, data[frame]))
        }

        // Remove finished voices
        lock.lock()
        activeVoices.removeAll { $0.isFinished }
        lock.unlock()

        return noErr
    }

    private func generateSample(voice: Voice) -> Float {
        let t = Double(voice.sampleTime) / sampleRate
        let freq = voice.config.frequency

        switch voice.config.waveform {
        case .sine:
            voice.phase += 2.0 * .pi * freq / sampleRate
            if voice.phase > 2.0 * .pi { voice.phase -= 2.0 * .pi }
            return Float(sin(voice.phase))

        case .square:
            voice.phase += 2.0 * .pi * freq / sampleRate
            if voice.phase > 2.0 * .pi { voice.phase -= 2.0 * .pi }
            return voice.phase < .pi ? 0.5 : -0.5

        case .triangle:
            voice.phase += 2.0 * .pi * freq / sampleRate
            if voice.phase > 2.0 * .pi { voice.phase -= 2.0 * .pi }
            let normalized = voice.phase / (2.0 * .pi)
            return Float(normalized < 0.5 ? 4.0 * normalized - 1.0 : 3.0 - 4.0 * normalized)

        case .noise:
            // Simple xorshift noise
            voice.noiseState ^= voice.noiseState << 13
            voice.noiseState ^= voice.noiseState >> 7
            voice.noiseState ^= voice.noiseState << 17
            return Float(Double(Int64(bitPattern: voice.noiseState)) / Double(Int64.max))

        case .fmSine(let modFreq, let modIndex):
            let modPhase = 2.0 * .pi * modFreq * t
            let modSignal = sin(modPhase) * modIndex * freq
            voice.phase += 2.0 * .pi * (freq + modSignal) / sampleRate
            if voice.phase > 2.0 * .pi { voice.phase -= 2.0 * .pi }
            return Float(sin(voice.phase))
        }
    }

    private func calculateEnvelope(voice: Voice) -> Float {
        let time = voice.sampleTime

        if time < voice.attackSamples {
            // Attack
            return Float(time) / Float(max(1, voice.attackSamples))
        } else if time > voice.totalSamples - voice.decaySamples {
            // Decay
            let remaining = voice.totalSamples - time
            return Float(remaining) / Float(max(1, voice.decaySamples))
        } else {
            return 1.0
        }
    }
}

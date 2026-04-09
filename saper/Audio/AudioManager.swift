import AVFAudio
import Foundation

/// Manages programmatic audio generation using AVAudioEngine.
class AudioManager {
    static let shared = AudioManager()

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private let synthesizer = SoundSynthesizer()
    private var isSetup = false

    var masterVolume: Float = 0.7 {
        didSet { engine?.mainMixerNode.outputVolume = masterVolume }
    }

    var sfxVolume: Float = 0.7
    var ambienceVolume: Float = 0.3
    var isEnabled: Bool = true

    private init() {}

    func setup() {
        guard !isSetup else { return }

        let engine = AVAudioEngine()
        self.engine = engine

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        let sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            return self.synthesizer.render(frameCount: frameCount, bufferList: audioBufferList)
        }
        self.sourceNode = sourceNode

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = masterVolume

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            isSetup = true
        } catch {
            print("AudioManager setup failed: \(error)")
        }
    }

    func play(_ sound: SoundEffect) {
        guard isEnabled else { return }
        synthesizer.play(sound.config, volume: sfxVolume)
    }

    func playCompound(_ compound: CompoundSoundConfig) {
        guard isEnabled else { return }
        synthesizer.playCompound(compound, volume: sfxVolume)
    }

    func stopAll() {
        synthesizer.stopAll()
    }

    func teardown() {
        engine?.stop()
        engine = nil
        sourceNode = nil
        isSetup = false
    }
}

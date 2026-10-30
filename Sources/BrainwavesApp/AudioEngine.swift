// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import AVFoundation
import BrainwavesCore

/// Wraps AVAudioEngine with one AVAudioSourceNode that pulls frames from a
/// `SessionRenderer`. The render block does only what `SessionRenderer.render`
/// does: no allocation, no locks that can block, no Objective-C messaging.
final class AudioEngine {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private(set) var renderer: SessionRenderer?
    private var configurationObserver: NSObjectProtocol?
    /// Called on the main queue if the output device changes and playback restarts.
    var onRestart: (() -> Void)?

    var isRunning: Bool { engine.isRunning }

    deinit {
        if let observer = configurationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func start(parameters: SessionParameters) throws {
        stop()
        let hardwareRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let sampleRate = hardwareRate > 0 ? hardwareRate : 48_000
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            throw AudioEngineError.unsupportedFormat
        }
        let renderer = SessionRenderer(sampleRate: sampleRate, parameters: parameters)
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let first = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            let second = buffers.count > 1 ? buffers[1].mData?.assumingMemoryBound(to: Float.self) ?? first : first
            renderer.render(left: first, right: second, frames: Int(frameCount))
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1
        engine.prepare()
        try engine.start()
        sourceNode = node
        self.renderer = renderer
        observeConfigurationChanges()
    }

    func update(_ parameters: SessionParameters) {
        renderer?.post(parameters)
    }

    func stop() {
        if engine.isRunning { engine.stop() }
        if let node = sourceNode {
            engine.detach(node)
            sourceNode = nil
        }
        renderer = nil
    }

    func readMeter() -> MeterReading {
        renderer?.readMeter() ?? .silent
    }

    /// When headphones are plugged in or removed, the engine stops; restart it with the same parameters.
    private func observeConfigurationChanges() {
        guard configurationObserver == nil else { return }
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            guard let self, let parameters = self.renderer?.parameters else { return }
            try? self.start(parameters: parameters)
            self.onRestart?()
        }
    }
}

enum AudioEngineError: LocalizedError {
    case unsupportedFormat

    var errorDescription: String? {
        "The audio output format is not supported."
    }
}

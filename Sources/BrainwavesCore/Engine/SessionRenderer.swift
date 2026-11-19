// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Passes parameters from the UI thread to the audio thread without ever
/// blocking the audio thread. The UI takes the lock; the audio thread only
/// *tries* it and keeps the previous parameters if it is busy.
final class ParameterMailbox: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: SessionParameters?

    func post(_ parameters: SessionParameters) {
        lock.lock()
        pending = parameters
        lock.unlock()
    }

    func take() -> SessionParameters? {
        guard lock.try() else { return nil }
        defer { lock.unlock() }
        let value = pending
        pending = nil
        return value
    }
}

/// Peak and RMS of the output since the last read.
public struct MeterReading: Sendable, Equatable {
    public var peak: Float
    public var rms: Double
    public var seconds: Double

    public static let silent = MeterReading(peak: 0, rms: 0, seconds: 0)
}

/// Real-time renderer for one listening session. Call `render` from the
/// audio thread and `post` / `readMeter` from any other thread.
/// See docs/design/audio-generation.md §2 for the signal flow.
public final class SessionRenderer: @unchecked Sendable {
    public let sampleRate: Double
    public private(set) var parameters: SessionParameters
    public private(set) var elapsedFrames: Int = 0

    private let mailbox = ParameterMailbox()
    private let meterLock = NSLock()
    private var meterPeak: Float = 0
    private var meterSumSquares: Double = 0
    private var meterFrames: Int = 0

    private let composer: GenerativeComposer
    private var noiseLeft: NoiseGenerator
    private var noiseRight: NoiseGenerator
    private var filterLeft = Biquad()
    private var filterRight = Biquad()
    private let reverb: Reverb
    private var texture = AmplitudeModulator()
    private var swell = AmplitudeModulator(phase: 0.5) // start at the quiet point, then rise ("inhale")
    private var gammaModulator = AmplitudeModulator()
    private var binaural = BinauralBeat()
    private var limiter: Limiter

    private var musicLevel: Smoother
    private var noiseLevel: Smoother
    private var master: Smoother
    private var brightness: Smoother
    private var textureDepth: Smoother
    private var swellDepth: Smoother
    private var binauralLevel: Smoother
    private var gammaDepth: Smoother

    private var controlCounter = 0
    private static let controlInterval = 32
    private static let fadeInSeconds = 2.0
    private static let reverbSend: Float = 0.2
    private static let noiseScale: Float = 1.0
    /// Makeup gain so that the default master (0.5) sits around −22 dBFS RMS.
    private static let musicMakeup: Float = 2.8

    public init(sampleRate: Double, parameters: SessionParameters) {
        let p = parameters.clamped()
        self.sampleRate = sampleRate
        self.parameters = p
        composer = GenerativeComposer(seed: p.seed, sampleRate: sampleRate, tempoBPM: p.tempoBPM,
                                      motifDensity: p.motifDensity, barsPerChord: p.barsPerChord,
                                      calm: p.mode != .focus)
        noiseLeft = NoiseGenerator(color: p.noiseColor, seed: p.seed &+ 101)
        noiseRight = NoiseGenerator(color: p.noiseColor, seed: p.seed &+ 202)
        reverb = Reverb(sampleRate: sampleRate)
        limiter = Limiter(sampleRate: sampleRate)
        musicLevel = Smoother(initial: p.musicLevel, sampleRate: sampleRate)
        noiseLevel = Smoother(initial: p.noiseLevel, sampleRate: sampleRate)
        master = Smoother(initial: p.masterGain, sampleRate: sampleRate)
        brightness = Smoother(initial: p.brightnessHz, sampleRate: sampleRate)
        textureDepth = Smoother(initial: p.amTexture.enabled ? p.amTexture.depth : 0, sampleRate: sampleRate)
        swellDepth = Smoother(initial: p.breathing.enabled ? p.breathing.depth : 0, sampleRate: sampleRate)
        binauralLevel = Smoother(initial: p.binaural.enabled ? p.binaural.level : 0, sampleRate: sampleRate)
        gammaDepth = Smoother(initial: p.gamma.enabled ? p.gamma.depth : 0, sampleRate: sampleRate)
        filterLeft.setLowPass(cutoff: p.brightnessHz, sampleRate: sampleRate)
        filterRight.setLowPass(cutoff: p.brightnessHz, sampleRate: sampleRate)
    }

    // MARK: - Any thread

    /// Queues new parameters. They take effect, smoothly, at the next render call.
    public func post(_ parameters: SessionParameters) {
        mailbox.post(parameters.clamped())
    }

    /// Returns and resets the output meter.
    public func readMeter() -> MeterReading {
        meterLock.lock()
        defer { meterLock.unlock() }
        let frames = max(meterFrames, 1)
        let reading = MeterReading(peak: meterPeak,
                                   rms: (meterSumSquares / Double(frames * 2)).squareRoot(),
                                   seconds: Double(meterFrames) / sampleRate)
        meterPeak = 0
        meterSumSquares = 0
        meterFrames = 0
        return reading
    }

    public var elapsedSeconds: Double { Double(elapsedFrames) / sampleRate }

    /// True once a timed session has passed its end (it outputs silence after that).
    public var isFinished: Bool {
        guard let duration = parameters.durationSeconds else { return false }
        return elapsedSeconds >= duration
    }

    // MARK: - Audio thread

    /// Renders `frames` stereo samples into non-interleaved buffers.
    /// Real-time safe: no allocation, no blocking locks, no I/O.
    public func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int) {
        if let incoming = mailbox.take() { apply(incoming) }
        let p = parameters
        var blockPeak: Float = 0
        var blockSquares: Double = 0
        let fadeInFrames = SessionRenderer.fadeInSeconds * sampleRate

        for n in 0..<frames {
            if controlCounter == 0 { updateControlRate() }
            controlCounter = (controlCounter + 1) % SessionRenderer.controlInterval

            let session = sessionGain(fadeInFrames: fadeInFrames, parameters: p)

            // Music bus → brightness → optional AM texture.
            var (ml, mr) = composer.next()
            ml = filterLeft.process(ml)
            mr = filterRight.process(mr)
            let textureGain = Float(texture.next(rate: p.amTexture.rateHz, depth: textureDepth.next(), sampleRate: sampleRate))
            let music = Float(musicLevel.next()) * SessionRenderer.musicMakeup
            ml *= textureGain * music
            mr *= textureGain * music

            // Ambience on the music only.
            let wet = reverb.process((ml + mr) * 0.5)
            var outL = ml + wet.left * SessionRenderer.reverbSend
            var outR = mr + wet.right * SessionRenderer.reverbSend

            // Steady noise bed (not modulated by the texture).
            let noise = Float(noiseLevel.next()) * SessionRenderer.noiseScale
            outL += noiseLeft.next() * noise
            outR += noiseRight.next() * noise

            // Experimental binaural layer.
            let beatLevel = Float(binauralLevel.next())
            if beatLevel > 0 || p.binaural.enabled {
                let tone = binaural.next(carrier: p.binaural.carrierHz, beat: p.binaural.beatHz, sampleRate: sampleRate)
                outL += tone.left * beatLevel
                outR += tone.right * beatLevel
            }

            // Breathing swell (Relax) and experimental 40 Hz modulation apply to the whole mix.
            let swellGain = Float(swell.next(rate: p.breathing.breathsPerMinute / 60.0, depth: swellDepth.next(), sampleRate: sampleRate))
            let gammaGain = Float(gammaModulator.next(rate: GammaSettings.rateHz, depth: gammaDepth.next(), sampleRate: sampleRate))
            let gain = swellGain * gammaGain * Float(master.next()) * session
            outL *= gain
            outR *= gain

            limiter.process(left: &outL, right: &outR)
            left[n] = outL
            right[n] = outR

            blockPeak = max(blockPeak, max(abs(outL), abs(outR)))
            blockSquares += Double(outL * outL + outR * outR)
            elapsedFrames += 1
        }

        if meterLock.try() {
            meterPeak = max(meterPeak, blockPeak)
            meterSumSquares += blockSquares
            meterFrames += frames
            meterLock.unlock()
        }
    }

    /// Convenience for offline use (CLI, tests). Allocates, so never call it on the audio thread.
    public func renderOffline(frames: Int, blockSize: Int = 512) -> (left: [Float], right: [Float]) {
        var left = [Float](repeating: 0, count: frames)
        var right = [Float](repeating: 0, count: frames)
        var offset = 0
        left.withUnsafeMutableBufferPointer { l in
            right.withUnsafeMutableBufferPointer { r in
                while offset < frames {
                    let count = min(blockSize, frames - offset)
                    render(left: l.baseAddress! + offset, right: r.baseAddress! + offset, frames: count)
                    offset += count
                }
            }
        }
        return (left, right)
    }

    // MARK: - Private

    private func apply(_ p: SessionParameters) {
        parameters = p
        composer.tempoBPM = p.tempoBPM
        composer.motifDensity = p.motifDensity
        composer.barsPerChord = p.barsPerChord
        composer.calm = p.mode != .focus
        noiseLeft.color = p.noiseColor
        noiseRight.color = p.noiseColor
        musicLevel.target = p.musicLevel
        noiseLevel.target = p.noiseLevel
        master.target = p.masterGain
        brightness.target = p.brightnessHz
        textureDepth.target = p.amTexture.enabled ? p.amTexture.depth : 0
        swellDepth.target = p.breathing.enabled ? p.breathing.depth : 0
        binauralLevel.target = p.binaural.enabled ? p.binaural.level : 0
        gammaDepth.target = p.gamma.enabled ? p.gamma.depth : 0
    }

    /// Runs every 32 samples: filter coefficients follow the smoothed brightness,
    /// and the cutoff rises with the breathing swell (a brighter "inhale").
    private func updateControlRate() {
        var cutoff = brightness.value
        for _ in 0..<SessionRenderer.controlInterval { cutoff = brightness.next() }
        let swellPosition = 1.0 - AmplitudeModulator.gain(phase: swell.phase, depth: 1.0)
        cutoff *= 1.0 + 0.5 * swellDepth.value * (1.0 - swellPosition)
        filterLeft.setLowPass(cutoff: cutoff, sampleRate: sampleRate)
        filterRight.setLowPass(cutoff: cutoff, sampleRate: sampleRate)
    }

    @inline(__always)
    private func sessionGain(fadeInFrames: Double, parameters p: SessionParameters) -> Float {
        let t = Double(elapsedFrames)
        var gain = t < fadeInFrames ? t / fadeInFrames : 1.0
        if let duration = p.durationSeconds {
            let end = duration * sampleRate
            let fade = min(p.fadeOutSeconds, duration) * sampleRate
            if t >= end {
                gain = 0
            } else if fade > 0, t > end - fade {
                let u = (t - (end - fade)) / fade
                gain *= 0.5 * (1.0 + cos(Double.pi * u))
            }
        }
        return Float(gain)
    }
}

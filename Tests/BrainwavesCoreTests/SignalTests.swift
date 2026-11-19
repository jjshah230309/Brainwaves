// SPDX-License-Identifier: MIT
import XCTest
@testable import BrainwavesCore

/// Signal acceptance criteria from docs/design/testing.md §2.
final class SignalTests: XCTestCase {
    let rate = 48_000.0

    private func render(_ p: SessionParameters, seconds: Double) -> (left: [Float], right: [Float]) {
        SessionRenderer(sampleRate: rate, parameters: p).renderOffline(frames: Int(seconds * rate))
    }

    private func slope(_ colour: NoiseColor, low: Double) -> Double {
        var generator = NoiseGenerator(color: colour, seed: 3)
        let x = (0..<(1 << 19)).map { _ in generator.next() }
        return Spectrum.octaveSlope(x, sampleRate: rate, low: low, high: 6_400)
    }

    func testWhiteNoiseIsFlat() {
        XCTAssertEqual(slope(.white, low: 100), 0, accuracy: 1)
    }

    func testPinkNoiseSlope() {
        XCTAssertEqual(slope(.pink, low: 100), -3, accuracy: 1.5)
    }

    func testBrownNoiseSlopeAboveCorner() {
        // The leaky integrator's corner is about 150 Hz at 48 kHz.
        XCTAssertEqual(slope(.brown, low: 400), -6, accuracy: 1.5)
    }

    func testAMTextureProducesEnvelopePeakAtRate() throws {
        try XCTSkipUnless(AmplitudeModulator.isCompiledIn)
        let p = isolated { $0.musicLevel = 1; $0.amTexture = AMTextureSettings(enabled: true, rateHz: 16, depth: 0.5) }
        let out = render(p, seconds: 8)
        // Envelope: rectify the last 4 s (after the fade-in).
        let envelope = out.left.suffix(Int(4 * rate)).map { abs($0) }
        let mean = envelope.reduce(0, +) / Float(envelope.count)
        let centred = envelope.map { $0 - mean }
        let atRate = Spectrum.goertzel(centred, frequency: 16, sampleRate: rate)
        let neighbours = [12.0, 14.0, 18.0, 20.0].map { Spectrum.goertzel(centred, frequency: $0, sampleRate: rate) }
        XCTAssertGreaterThan(atRate, 10 * (neighbours.max() ?? 0))
    }

    func testBinauralCarriersAreOffsetPerEar() {
        let p = isolated { $0.binaural = BinauralSettings(enabled: true, carrierHz: 200, beatHz: 10, level: 0.2) }
        let out = render(p, seconds: 4)
        let left = Array(out.left.suffix(Int(2 * rate)))
        let right = Array(out.right.suffix(Int(2 * rate)))
        XCTAssertGreaterThan(Spectrum.goertzel(left, frequency: 195, sampleRate: rate),
                             100 * Spectrum.goertzel(left, frequency: 205, sampleRate: rate))
        XCTAssertGreaterThan(Spectrum.goertzel(right, frequency: 205, sampleRate: rate),
                             100 * Spectrum.goertzel(right, frequency: 195, sampleRate: rate))
    }

    func testEveryModeIsFiniteAndBelowCeiling() {
        for mode in Mode.allCases {
            var p = ModePreset.parameters(for: mode, seed: 5)
            p.masterGain = 1
            p.noiseLevel = 1
            p.musicLevel = 1
            p.durationSeconds = nil
            let out = render(p, seconds: 20)
            let all = out.left + out.right
            XCTAssertTrue(all.allSatisfy(\.isFinite), "\(mode) produced non-finite samples")
            XCTAssertLessThanOrEqual(all.map(abs).max() ?? 0, Limiter.defaultCeiling + 1e-6, "\(mode) exceeded ceiling")
            XCTAssertGreaterThan(all.map(abs).max() ?? 0, 0.01, "\(mode) is silent")
        }
    }

    func testSameSeedIsBitIdentical() {
        let p = ModePreset.parameters(for: .relax, seed: 77)
        let a = render(p, seconds: 3), b = render(p, seconds: 3)
        XCTAssertEqual(a.left, b.left)
        XCTAssertEqual(a.right, b.right)
    }

    func testDifferentSeedsDiffer() {
        let a = render(ModePreset.parameters(for: .focus, seed: 1), seconds: 3)
        let b = render(ModePreset.parameters(for: .focus, seed: 2), seconds: 3)
        XCTAssertNotEqual(a.left, b.left)
    }

    func testAbruptParameterChangeIsSmoothed() {
        var p = ModePreset.parameters(for: .focus, seed: 4)
        p.masterGain = 0
        p.durationSeconds = nil
        let renderer = SessionRenderer(sampleRate: rate, parameters: p)
        _ = renderer.renderOffline(frames: Int(3 * rate))
        p.masterGain = 1
        p.noiseLevel = 1
        renderer.post(p)
        let out = renderer.renderOffline(frames: Int(rate))
        // RMS in 1 ms blocks: the level must rise gradually (τ = 50 ms), not jump.
        let block = Int(rate / 1_000)
        func rms(_ start: Int) -> Float {
            let slice = out.left[start..<(start + block)]
            return (slice.map { $0 * $0 }.reduce(0, +) / Float(block)).squareRoot()
        }
        let settled = rms(out.left.count - block)
        XCTAssertLessThan(rms(0), 0.1 * settled, "level jumped instead of ramping")
        XCTAssertGreaterThan(rms(Int(0.3 * rate)), 0.8 * settled, "level did not settle within 300 ms")
    }

    func testTimedSessionFadesToSilenceAndFinishes() {
        var p = ModePreset.parameters(for: .focus, seed: 4)
        p.durationSeconds = 4
        p.fadeOutSeconds = 2
        let renderer = SessionRenderer(sampleRate: rate, parameters: p)
        let out = renderer.renderOffline(frames: Int(5 * rate))
        XCTAssertTrue(renderer.isFinished)
        XCTAssertEqual(out.left.suffix(Int(0.9 * rate)).map(abs).max() ?? 1, 0, accuracy: 1e-3)
    }

    func testMeterReportsAndResets() {
        let renderer = SessionRenderer(sampleRate: rate, parameters: ModePreset.parameters(for: .focus))
        _ = renderer.renderOffline(frames: Int(rate))
        let reading = renderer.readMeter()
        XCTAssertEqual(reading.seconds, 1, accuracy: 0.01)
        XCTAssertGreaterThan(reading.rms, 0)
        XCTAssertEqual(renderer.readMeter().seconds, 0)
    }

    func testRendersFasterThanRealTime() {
        let renderer = SessionRenderer(sampleRate: rate, parameters: ModePreset.parameters(for: .focus))
        let start = Date()
        _ = renderer.renderOffline(frames: Int(10 * rate))
        let elapsed = Date().timeIntervalSince(start)
        // A loose bound for debug builds on CI; release builds are roughly 50× real time.
        XCTAssertLessThan(elapsed, 10)
    }
}

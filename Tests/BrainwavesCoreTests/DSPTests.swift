// SPDX-License-Identifier: MIT
import XCTest
@testable import BrainwavesCore

final class DSPTests: XCTestCase {
    func testLimiterNeverExceedsCeiling() {
        var limiter = Limiter(sampleRate: 48_000)
        var maxOut: Float = 0
        for n in 0..<48_000 {
            // +12 dB sine, plus occasional spikes.
            var l = Float(4 * sin(2 * Double.pi * 440 * Double(n) / 48_000))
            var r = n % 997 == 0 ? Float(20) : l
            limiter.process(left: &l, right: &r)
            maxOut = max(maxOut, abs(l), abs(r))
        }
        XCTAssertLessThanOrEqual(maxOut, Limiter.defaultCeiling + 1e-6)
    }

    func testLimiterRemovesNonFiniteSamples() {
        var limiter = Limiter(sampleRate: 48_000)
        var l = Float.nan, r = Float.infinity
        limiter.process(left: &l, right: &r)
        XCTAssertTrue(l.isFinite && r.isFinite)
    }

    func testLimiterPassesQuietSignalUnchanged() {
        var limiter = Limiter(sampleRate: 48_000)
        var l: Float = 0.3, r: Float = -0.2
        limiter.process(left: &l, right: &r)
        XCTAssertEqual(l, 0.3, accuracy: 1e-6)
        XCTAssertEqual(r, -0.2, accuracy: 1e-6)
    }

    func testAmplitudeModulatorRangeAndDepth() throws {
        try XCTSkipUnless(AmplitudeModulator.isCompiledIn)
        var am = AmplitudeModulator()
        var lo = 2.0, hi = -1.0
        for _ in 0..<48_000 {
            let g = am.next(rate: 16, depth: 0.4, sampleRate: 48_000)
            lo = min(lo, g); hi = max(hi, g)
        }
        XCTAssertEqual(hi, 1.0, accuracy: 1e-3)
        XCTAssertEqual(lo, 0.6, accuracy: 1e-3)
        XCTAssertEqual((hi - lo) / hi, 0.4, accuracy: 0.01)
    }

    func testLowPassAttenuatesAboveCutoff() {
        var filter = Biquad.lowPass(cutoff: 500, sampleRate: 48_000)
        func gain(at frequency: Double) -> Double {
            filter.reset()
            var peak: Float = 0
            for n in 0..<9_600 {
                let y = filter.process(Float(sin(2 * Double.pi * frequency * Double(n) / 48_000)))
                if n > 4_800 { peak = max(peak, abs(y)) }
            }
            return Double(peak)
        }
        XCTAssertEqual(gain(at: 100), 1, accuracy: 0.05)
        XCTAssertEqual(gain(at: 500), 0.707, accuracy: 0.05)
        XCTAssertLessThan(gain(at: 4_000), 0.03)
    }

    func testSmootherConvergesWithTimeConstant() {
        var s = Smoother(initial: 0, timeConstant: 0.05, sampleRate: 1_000)
        s.target = 1
        for _ in 0..<50 { _ = s.next() }
        XCTAssertEqual(s.value, 1 - exp(-1), accuracy: 0.01)
    }

    func testSeededRandomIsDeterministicAndUniform() {
        var a = SeededRandom(seed: 9), b = SeededRandom(seed: 9)
        var sum = 0.0
        for _ in 0..<10_000 {
            let x = a.nextUnit()
            XCTAssertEqual(x, b.nextUnit())
            XCTAssertTrue((0..<1).contains(x))
            sum += x
        }
        XCTAssertEqual(sum / 10_000, 0.5, accuracy: 0.02)
    }

    func testPentatonicDegrees() {
        XCTAssertEqual((0...6).map(PentatonicScale.semitones(degree:)), [0, 2, 4, 7, 9, 12, 14])
    }

    func testParametersAreClampedIncludingNaN() {
        var p = ModePreset.parameters(for: .focus)
        p.amTexture.rateHz = 1_000
        p.amTexture.depth = .nan
        p.masterGain = 5
        p.volumeCap = 0.6
        p.brightnessHz = -10
        let c = p.clamped()
        XCTAssertEqual(c.amTexture.rateHz, 20)
        XCTAssertEqual(c.amTexture.depth, 0)
        XCTAssertEqual(c.masterGain, 0.6)
        XCTAssertEqual(c.brightnessHz, 300)
    }

    func testSleepPresetRespectsVolumeCap() {
        var p = ModePreset.parameters(for: .sleep)
        p.masterGain = 1
        XCTAssertLessThanOrEqual(p.clamped().masterGain, VolumeCeiling.sleepModeCap)
    }

    func testWAVHeader() {
        let data = WAVWriter.encode(left: [0, 1], right: [0, -1], sampleRate: 48_000)
        XCTAssertEqual(data.count, 44 + 8)
        XCTAssertEqual(String(decoding: data[0..<4], as: UTF8.self), "RIFF")
        XCTAssertEqual(String(decoding: data[8..<12], as: UTF8.self), "WAVE")
    }
}

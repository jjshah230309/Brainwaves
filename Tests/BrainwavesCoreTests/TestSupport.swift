// SPDX-License-Identifier: MIT
import Foundation
@testable import BrainwavesCore

enum Spectrum {
    /// In-place iterative radix-2 FFT. `real.count` must be a power of two.
    static func fft(real: inout [Double], imag: inout [Double]) {
        let n = real.count
        var j = 0
        for i in 1..<n {
            var bit = n >> 1
            while j & bit != 0 { j ^= bit; bit >>= 1 }
            j ^= bit
            if i < j { real.swapAt(i, j); imag.swapAt(i, j) }
        }
        var length = 2
        while length <= n {
            let angle = -2 * Double.pi / Double(length)
            for start in stride(from: 0, to: n, by: length) {
                for k in 0..<(length / 2) {
                    let wr = cos(angle * Double(k)), wi = sin(angle * Double(k))
                    let a = start + k, b = start + k + length / 2
                    let tr = real[b] * wr - imag[b] * wi
                    let ti = real[b] * wi + imag[b] * wr
                    real[b] = real[a] - tr; imag[b] = imag[a] - ti
                    real[a] += tr; imag[a] += ti
                }
            }
            length <<= 1
        }
    }

    /// Power spectrum of a Hann-windowed signal (first power-of-two samples).
    static func power(_ x: [Float]) -> [Double] {
        var n = 1
        while n * 2 <= x.count { n *= 2 }
        var re = (0..<n).map { i in Double(x[i]) * (0.5 - 0.5 * cos(2 * Double.pi * Double(i) / Double(n - 1))) }
        var im = [Double](repeating: 0, count: n)
        fft(real: &re, imag: &im)
        return (0...(n / 2)).map { re[$0] * re[$0] + im[$0] * im[$0] }
    }

    /// Least-squares slope (dB per octave) of mean band power in octave bands from `low` to `high`.
    static func octaveSlope(_ x: [Float], sampleRate: Double, low: Double, high: Double) -> Double {
        let p = power(x)
        let n = (p.count - 1) * 2
        var xs: [Double] = [], ys: [Double] = []
        var f = low
        while f * 2.0.squareRoot() <= high {
            let lo = Int(f / 2.0.squareRoot() * Double(n) / sampleRate)
            let hi = Int(f * 2.0.squareRoot() * Double(n) / sampleRate)
            let band = p[lo..<hi]
            xs.append(log2(f))
            ys.append(10 * log10(band.reduce(0, +) / Double(band.count) + 1e-30))
            f *= 2
        }
        let mx = xs.reduce(0, +) / Double(xs.count), my = ys.reduce(0, +) / Double(ys.count)
        var num = 0.0, den = 0.0
        for i in 0..<xs.count { num += (xs[i] - mx) * (ys[i] - my); den += (xs[i] - mx) * (xs[i] - mx) }
        return num / den
    }

    /// Goertzel power at `frequency`.
    static func goertzel(_ x: [Float], frequency: Double, sampleRate: Double) -> Double {
        let w = 2 * Double.pi * frequency / sampleRate
        let coefficient = 2 * cos(w)
        var s1 = 0.0, s2 = 0.0
        for sample in x {
            let s0 = Double(sample) + coefficient * s1 - s2
            s2 = s1; s1 = s0
        }
        return s1 * s1 + s2 * s2 - coefficient * s1 * s2
    }
}

/// Parameters with only one layer audible, for isolating signal tests.
func isolated(_ configure: (inout SessionParameters) -> Void) -> SessionParameters {
    var p = ModePreset.parameters(for: .focus, seed: 42)
    p.musicLevel = 0
    p.noiseLevel = 0
    p.masterGain = 1
    p.durationSeconds = nil
    configure(&p)
    return p
}

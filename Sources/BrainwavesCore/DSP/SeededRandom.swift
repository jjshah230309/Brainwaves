// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Deterministic SplitMix64 generator. The same seed always produces the same
/// audio, which makes renders reproducible for tests and research.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform in [0, 1).
    @inline(__always)
    public mutating func nextUnit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    /// Uniform in [-1, 1).
    @inline(__always)
    public mutating func nextBipolar() -> Float {
        Float(nextUnit() * 2.0 - 1.0)
    }

    public mutating func chance(_ probability: Double) -> Bool {
        nextUnit() < probability
    }

    /// Uniform integer in a closed range.
    public mutating func int(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }

    /// Standard normal sample (Box–Muller).
    public mutating func nextGaussian() -> Double {
        let u1 = max(nextUnit(), 1e-300)
        let u2 = nextUnit()
        return (-2.0 * log(u1)).squareRoot() * cos(2.0 * Double.pi * u2)
    }
}

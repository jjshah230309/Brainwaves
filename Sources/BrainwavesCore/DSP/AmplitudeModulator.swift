// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Raised-cosine amplitude modulator (tremolo):
///
///     g(t) = 1 - (d / 2) * (1 - cos(2π f_m t)),   g ∈ [1 - d, 1]
///
/// The phase accumulates continuously, so changing the rate never clicks.
/// Building with `-Xswiftc -DBRAINWAVES_NO_AM` compiles amplitude modulation
/// out completely (see docs/design/legal.md §3).
public struct AmplitudeModulator: Sendable {
    /// Phase in cycles, in [0, 1).
    public private(set) var phase: Double = 0

    public init(phase: Double = 0) {
        self.phase = phase
    }

    public static var isCompiledIn: Bool {
        #if BRAINWAVES_NO_AM
        return false
        #else
        return true
        #endif
    }

    @inline(__always)
    public static func gain(phase: Double, depth: Double) -> Double {
        1.0 - (depth / 2.0) * (1.0 - cos(2.0 * Double.pi * phase))
    }

    @inline(__always)
    public mutating func next(rate: Double, depth: Double, sampleRate: Double) -> Double {
        #if BRAINWAVES_NO_AM
        return 1.0
        #else
        let g = AmplitudeModulator.gain(phase: phase, depth: depth)
        phase += rate / sampleRate
        if phase >= 1.0 { phase -= phase.rounded(.down) }
        return g
        #endif
    }
}

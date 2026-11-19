// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Experimental binaural-beat layer. The left ear hears f_c - Δ/2 and the right
/// ear hears f_c + Δ/2. This needs headphones. Evidence that it entrains brain
/// rhythms is inconsistent (docs/research/evidence-review.md §4.3).
public struct BinauralBeat: Sendable {
    private var phaseLeft: Double = 0
    private var phaseRight: Double = 0

    public init() {}

    @inline(__always)
    public mutating func next(carrier: Double, beat: Double, sampleRate: Double) -> (left: Float, right: Float) {
        let left = Float(sin(2.0 * Double.pi * phaseLeft))
        let right = Float(sin(2.0 * Double.pi * phaseRight))
        phaseLeft += (carrier - beat / 2.0) / sampleRate
        phaseRight += (carrier + beat / 2.0) / sampleRate
        if phaseLeft >= 1.0 { phaseLeft -= 1.0 }
        if phaseRight >= 1.0 { phaseRight -= 1.0 }
        return (left, right)
    }
}

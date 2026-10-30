// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Second-order IIR filter (transposed direct form II) with
/// RBJ "Audio EQ Cookbook" low-pass coefficients.
public struct Biquad: Sendable {
    private var b0: Float = 1, b1: Float = 0, b2: Float = 0
    private var a1: Float = 0, a2: Float = 0
    private var z1: Float = 0, z2: Float = 0

    public init() {}

    public static func lowPass(cutoff: Double, q: Double = 0.7071, sampleRate: Double) -> Biquad {
        var filter = Biquad()
        filter.setLowPass(cutoff: cutoff, q: q, sampleRate: sampleRate)
        return filter
    }

    /// Recomputes coefficients and keeps the filter state, so cutoff changes don't click.
    public mutating func setLowPass(cutoff: Double, q: Double = 0.7071, sampleRate: Double) {
        let fc = min(max(cutoff, 10.0), sampleRate * 0.45)
        let w0 = 2.0 * Double.pi * fc / sampleRate
        let cosW0 = cos(w0)
        let alpha = sin(w0) / (2.0 * q)
        let a0 = 1.0 + alpha
        b0 = Float(((1.0 - cosW0) / 2.0) / a0)
        b1 = Float((1.0 - cosW0) / a0)
        b2 = b0
        a1 = Float((-2.0 * cosW0) / a0)
        a2 = Float((1.0 - alpha) / a0)
    }

    @inline(__always)
    public mutating func process(_ x: Float) -> Float {
        let y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }

    public mutating func reset() {
        z1 = 0
        z2 = 0
    }
}

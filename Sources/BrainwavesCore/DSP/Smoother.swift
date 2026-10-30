// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// One-pole parameter smoother: y[n] = y[n-1] + (x - y[n-1]) * (1 - e^{-1/(τ fs)}).
/// Prevents zipper noise and sudden jumps in level when the user moves a control.
public struct Smoother: Sendable {
    public private(set) var value: Double
    public var target: Double
    private let coefficient: Double

    public init(initial: Double, timeConstant: Double = 0.05, sampleRate: Double) {
        value = initial
        target = initial
        coefficient = 1.0 - exp(-1.0 / (max(timeConstant, 1e-6) * sampleRate))
    }

    @inline(__always)
    public mutating func next() -> Double {
        value += (target - value) * coefficient
        return value
    }

    /// Jumps straight to the target (used only when nothing is playing).
    public mutating func snap() {
        value = target
    }
}

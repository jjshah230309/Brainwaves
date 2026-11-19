// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Stereo-linked peak limiter with instant attack and exponential release.
/// Because the attack is instant, the output can never exceed `ceiling`.
/// A final clamp is applied anyway as a second safeguard.
public struct Limiter: Sendable {
    /// −1 dBFS.
    public static let defaultCeiling: Float = 0.891_250_9

    public let ceiling: Float
    public private(set) var gain: Float = 1
    private let releaseCoefficient: Float

    public init(ceiling: Float = Limiter.defaultCeiling, releaseSeconds: Double = 0.15, sampleRate: Double) {
        self.ceiling = ceiling
        releaseCoefficient = Float(1.0 - exp(-1.0 / (releaseSeconds * sampleRate)))
    }

    @inline(__always)
    public mutating func process(left: inout Float, right: inout Float) {
        let peak = max(abs(left), abs(right))
        let target: Float = peak > ceiling ? ceiling / peak : 1
        if target < gain {
            gain = target
        } else {
            gain += (target - gain) * releaseCoefficient
        }
        left = min(max(left * gain, -ceiling), ceiling)
        right = min(max(right * gain, -ceiling), ceiling)
        if !left.isFinite { left = 0 }
        if !right.isFinite { right = 0 }
    }
}

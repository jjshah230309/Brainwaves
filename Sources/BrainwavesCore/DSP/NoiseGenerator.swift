// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

public enum NoiseColor: String, Codable, CaseIterable, Sendable {
    /// Flat spectrum.
    case white
    /// 1/f spectrum, about −3 dB per octave.
    case pink
    /// 1/f² spectrum, about −6 dB per octave.
    case brown

    public var displayName: String {
        switch self {
        case .white: return "White"
        case .pink: return "Pink"
        case .brown: return "Brown"
        }
    }
}

/// Coloured-noise source. Pink noise uses Paul Kellett's refined filter;
/// brown noise uses a leaky integrator. See docs/design/audio-generation.md §3.1.
public struct NoiseGenerator: Sendable {
    public var color: NoiseColor
    private var rng: SeededRandom
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0
    private var b4: Float = 0, b5: Float = 0, b6: Float = 0
    private var brown: Float = 0

    public init(color: NoiseColor, seed: UInt64) {
        self.color = color
        self.rng = SeededRandom(seed: seed)
    }

    @inline(__always)
    public mutating func next() -> Float {
        let white = rng.nextBipolar()
        switch color {
        case .white:
            return white * 0.5
        case .pink:
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
            b6 = white * 0.115926
            return pink * 0.11
        case .brown:
            brown = (brown + 0.02 * white) / 1.02
            return brown * 3.5
        }
    }
}

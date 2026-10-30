// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

public enum BetaSampler {
    /// Gamma(shape, 1) by Marsaglia–Tsang. For shape < 1, uses the boost
    /// Γ(a) = Γ(a + 1) · U^{1/a}.
    public static func gamma(shape: Double, using rng: inout SeededRandom) -> Double {
        precondition(shape > 0, "shape must be positive")
        if shape < 1 {
            let u = max(rng.nextUnit(), 1e-300)
            return gamma(shape: shape + 1, using: &rng) * pow(u, 1 / shape)
        }
        let d = shape - 1.0 / 3.0
        let c = 1.0 / (9.0 * d).squareRoot()
        while true {
            var x: Double
            var v: Double
            repeat {
                x = rng.nextGaussian()
                v = 1 + c * x
            } while v <= 0
            v = v * v * v
            let u = rng.nextUnit()
            if u < 1 - 0.0331 * x * x * x * x { return d * v }
            if log(max(u, 1e-300)) < 0.5 * x * x + d * (1 - v + log(v)) { return d * v }
        }
    }

    /// Beta(α, β) = X / (X + Y), with X ~ Γ(α) and Y ~ Γ(β).
    public static func beta(alpha: Double, beta: Double, using rng: inout SeededRandom) -> Double {
        let x = gamma(shape: alpha, using: &rng)
        let y = gamma(shape: beta, using: &rng)
        return x / (x + y)
    }
}

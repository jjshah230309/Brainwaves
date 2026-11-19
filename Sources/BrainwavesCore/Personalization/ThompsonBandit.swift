// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Ratings collected after a session of at least 3 minutes.
public struct SessionFeedback: Codable, Equatable, Sendable {
    /// "How focused did you feel?" (Focus) or "How calm did you feel?" (Relax, Sleep): 1–5.
    public var primary: Int
    /// "How much did you enjoy the sound?": 1–5.
    public var enjoyment: Int

    public init(primary: Int, enjoyment: Int) {
        self.primary = min(max(primary, 1), 5)
        self.enjoyment = min(max(enjoyment, 1), 5)
    }

    /// R = 0.7 · (primary − 1)/4 + 0.3 · (enjoyment − 1)/4, in [0, 1].
    public var reward: Double {
        0.7 * Double(primary - 1) / 4.0 + 0.3 * Double(enjoyment - 1) / 4.0
    }

    public static let minimumSessionSeconds: Double = 180
}

public struct ArmState: Codable, Equatable, Sendable {
    public var alpha: Double
    public var beta: Double

    public init(alpha: Double = 1, beta: Double = 1) {
        self.alpha = alpha
        self.beta = beta
    }

    public var mean: Double { alpha / (alpha + beta) }
}

/// Beta-Bernoulli Thompson sampling with fractional rewards and forgetting
/// (docs/design/personalization.md §2). State is stored on the device only.
public struct ThompsonBandit: Codable, Equatable, Sendable {
    /// mode.rawValue → arm.rawValue → posterior.
    public private(set) var arms: [String: [String: ArmState]]
    public var discount: Double

    public init(discount: Double = 0.98) {
        arms = [:]
        self.discount = discount
    }

    public func state(mode: Mode, arm: PresetVariant) -> ArmState {
        arms[mode.rawValue]?[arm.rawValue] ?? ArmState()
    }

    /// Draws θ_k ~ Beta(α_k, β_k) for each eligible arm and returns the argmax.
    public func choose(mode: Mode, eligible: [PresetVariant], using rng: inout SeededRandom) -> PresetVariant {
        precondition(!eligible.isEmpty, "at least one arm must be eligible")
        var best = eligible[0]
        var bestDraw = -1.0
        for arm in eligible {
            let s = state(mode: mode, arm: arm)
            let draw = BetaSampler.beta(alpha: s.alpha, beta: s.beta, using: &rng)
            if draw > bestDraw {
                bestDraw = draw
                best = arm
            }
        }
        return best
    }

    /// Discounts every arm of this mode towards the prior, then adds the reward to the played arm.
    public mutating func update(mode: Mode, arm: PresetVariant, reward: Double) {
        let r = reward.clamped(to: 0...1)
        var modeArms = arms[mode.rawValue] ?? [:]
        for (key, s) in modeArms {
            modeArms[key] = ArmState(alpha: 1 + discount * (s.alpha - 1), beta: 1 + discount * (s.beta - 1))
        }
        var s = modeArms[arm.rawValue] ?? ArmState()
        s.alpha += r
        s.beta += 1 - r
        modeArms[arm.rawValue] = s
        arms[mode.rawValue] = modeArms
    }

    public mutating func reset() {
        arms = [:]
    }
}

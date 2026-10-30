// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

public enum Condition: String, Codable, Sendable { case a, b }

public enum PairOrder: String, Codable, Sendable {
    case ab, ba

    public func condition(at position: Int) -> Condition {
        switch (self, position) {
        case (.ab, 0), (.ba, 1): return .a
        default: return .b
        }
    }
}

public struct Trial: Codable, Equatable, Sendable {
    public var pair: Int
    public var position: Int
    public var condition: Condition
    public var result: ReactionTimeResult
    public var date: Date
}

/// A personal, randomised, balanced A/B crossover (docs/design/personalization.md §3).
public struct NOf1Experiment: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var labelA: String
    public var labelB: String
    public var parametersA: SessionParameters
    public var parametersB: SessionParameters
    public private(set) var schedule: [PairOrder]
    public private(set) var trials: [Trial]
    public var created: Date

    public static let pairRange: ClosedRange<Int> = 4...12

    public init(title: String, labelA: String, labelB: String, parametersA: SessionParameters,
                parametersB: SessionParameters, pairs: Int = 6, using rng: inout SeededRandom,
                id: UUID = UUID(), created: Date = Date()) {
        self.id = id
        self.title = title
        self.labelA = labelA
        self.labelB = labelB
        self.parametersA = parametersA
        self.parametersB = parametersB
        let count = min(max(pairs, Self.pairRange.lowerBound), Self.pairRange.upperBound)
        schedule = (0..<count).map { _ in rng.chance(0.5) ? .ab : .ba }
        trials = []
        self.created = created
    }

    /// The next session to run, or nil when every pair is complete.
    /// The UI shows only "Session \(position + 1)", never the condition.
    public var nextSession: (pair: Int, position: Int, condition: Condition)? {
        let done = trials.count
        guard done < schedule.count * 2 else { return nil }
        let pair = done / 2
        let position = done % 2
        return (pair, position, schedule[pair].condition(at: position))
    }

    public func parameters(for condition: Condition) -> SessionParameters {
        condition == .a ? parametersA : parametersB
    }

    public mutating func record(_ result: ReactionTimeResult, date: Date = Date()) {
        guard let next = nextSession else { return }
        trials.append(Trial(pair: next.pair, position: next.position, condition: next.condition,
                            result: result, date: date))
    }

    public var isComplete: Bool { nextSession == nil }

    /// Per-pair differences δ_i = RT_B − RT_A (positive means A was faster),
    /// using only complete pairs where both sessions have a median.
    public var pairedDifferences: [Double] {
        var differences: [Double] = []
        for pair in 0..<schedule.count {
            let pairTrials = trials.filter { $0.pair == pair }
            guard let a = pairTrials.first(where: { $0.condition == .a })?.result.medianMs,
                  let b = pairTrials.first(where: { $0.condition == .b })?.result.medianMs else { continue }
            differences.append(b - a)
        }
        return differences
    }

    /// Needs at least 3 complete pairs.
    public func analysis(seed: UInt64 = 7) -> NOf1Analysis? {
        let d = pairedDifferences
        guard d.count >= 3 else { return nil }
        var rng = SeededRandom(seed: seed)
        let ci = PairedStatistics.bootstrapCI(d, resamples: 2000, level: 0.95, using: &rng)
        let mean = PairedStatistics.mean(d)
        return NOf1Analysis(
            pairs: d.count, meanDifferenceMs: mean, ciLowMs: ci.low, ciHighMs: ci.high,
            pValue: PairedStatistics.signFlipPValue(d),
            message: UserFacingCopy.selfTestResult(meanDifferenceMs: mean, ciLow: ci.low, ciHigh: ci.high,
                                                   labelA: labelA, labelB: labelB))
    }
}

public struct NOf1Analysis: Equatable, Sendable {
    /// Design choice for a noticeable difference, not a published threshold.
    public static let meaningfulDifferenceMs = 15.0

    public var pairs: Int
    public var meanDifferenceMs: Double
    public var ciLowMs: Double
    public var ciHighMs: Double
    public var pValue: Double
    public var message: String
}

public enum PairedStatistics {
    public static func mean(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    /// Exact two-sided sign-flip permutation test of mean(δ) = 0.
    /// Enumerates all 2^m sign patterns (m ≤ 16).
    public static func signFlipPValue(_ differences: [Double]) -> Double {
        let m = differences.count
        guard m > 0, m <= 16 else { return 1 }
        let observed = abs(mean(differences))
        let total = 1 << m
        var extreme = 0
        for mask in 0..<total {
            var sum = 0.0
            for i in 0..<m {
                sum += (mask & (1 << i)) != 0 ? -differences[i] : differences[i]
            }
            if abs(sum / Double(m)) >= observed - 1e-12 { extreme += 1 }
        }
        return Double(extreme) / Double(total)
    }

    /// Percentile bootstrap confidence interval for the mean.
    public static func bootstrapCI(_ values: [Double], resamples: Int, level: Double,
                                   using rng: inout SeededRandom) -> (low: Double, high: Double) {
        guard !values.isEmpty else { return (0, 0) }
        var means = [Double](repeating: 0, count: resamples)
        for r in 0..<resamples {
            var sum = 0.0
            for _ in 0..<values.count { sum += values[rng.int(in: 0...(values.count - 1))] }
            means[r] = sum / Double(values.count)
        }
        means.sort()
        let alpha = (1 - level) / 2
        let lowIndex = Int((alpha * Double(resamples)).rounded(.down))
        let highIndex = min(Int(((1 - alpha) * Double(resamples)).rounded(.down)), resamples - 1)
        return (means[lowIndex], means[highIndex])
    }
}

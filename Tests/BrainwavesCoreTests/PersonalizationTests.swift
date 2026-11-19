// SPDX-License-Identifier: MIT
import XCTest
@testable import BrainwavesCore

final class PersonalizationTests: XCTestCase {
    func testBetaSamplerMean() {
        var rng = SeededRandom(seed: 1)
        let n = 20_000
        let mean = (0..<n).map { _ in BetaSampler.beta(alpha: 2, beta: 5, using: &rng) }.reduce(0, +) / Double(n)
        XCTAssertEqual(mean, 2.0 / 7.0, accuracy: 0.01)
    }

    func testGammaWithSmallShape() {
        var rng = SeededRandom(seed: 2)
        let n = 20_000
        let mean = (0..<n).map { _ in BetaSampler.gamma(shape: 0.5, using: &rng) }.reduce(0, +) / Double(n)
        XCTAssertEqual(mean, 0.5, accuracy: 0.03)
    }

    func testRewardFormula() {
        XCTAssertEqual(SessionFeedback(primary: 5, enjoyment: 5).reward, 1, accuracy: 1e-12)
        XCTAssertEqual(SessionFeedback(primary: 1, enjoyment: 1).reward, 0, accuracy: 1e-12)
        XCTAssertEqual(SessionFeedback(primary: 3, enjoyment: 5).reward, 0.65, accuracy: 1e-12)
        XCTAssertEqual(SessionFeedback(primary: 9, enjoyment: -2).primary, 5)
    }

    func testBanditLearnsBestArm() {
        var bandit = ThompsonBandit()
        var rng = SeededRandom(seed: 11)
        let arms = PresetVariant.eligible(amTextureAllowed: false)
        var lateBest = 0
        for round in 0..<500 {
            let arm = bandit.choose(mode: .focus, eligible: arms, using: &rng)
            let p = arm == .darker ? 0.8 : 0.4
            bandit.update(mode: .focus, arm: arm, reward: rng.chance(p) ? 1 : 0)
            if round >= 300, arm == .darker { lateBest += 1 }
        }
        XCTAssertGreaterThanOrEqual(Double(lateBest) / 200, 0.7)
    }

    func testBanditNeverChoosesTextureWithoutOptIn() {
        XCTAssertFalse(PresetVariant.eligible(amTextureAllowed: false).contains(.texture))
    }

    func testBanditDiscountPullsTowardsPrior() {
        var bandit = ThompsonBandit(discount: 0.5)
        bandit.update(mode: .relax, arm: .base, reward: 1)   // base: α = 2, β = 1
        bandit.update(mode: .relax, arm: .darker, reward: 0) // base discounted: α = 1.5
        XCTAssertEqual(bandit.state(mode: .relax, arm: .base).alpha, 1.5, accuracy: 1e-12)
        XCTAssertEqual(bandit.state(mode: .relax, arm: .darker).beta, 2, accuracy: 1e-12)
    }

    func testSignFlipExactPValue() {
        // All six differences positive and equal: only 2 of 64 patterns are as extreme.
        XCTAssertEqual(PairedStatistics.signFlipPValue([10, 10, 10, 10, 10, 10]), 2.0 / 64.0, accuracy: 1e-12)
        XCTAssertEqual(PairedStatistics.signFlipPValue([0, 0, 0]), 1, accuracy: 1e-12)
    }

    func testBootstrapCoverage() {
        var rng = SeededRandom(seed: 5)
        var covered = 0
        for _ in 0..<200 {
            let sample = (0..<12).map { _ in 20 + 30 * rng.nextGaussian() }
            let ci = PairedStatistics.bootstrapCI(sample, resamples: 1_000, level: 0.95, using: &rng)
            if ci.low <= 20 && 20 <= ci.high { covered += 1 }
        }
        // Percentile bootstrap slightly under-covers at n = 12 (nominal 95%); require ≥ 85%.
        XCTAssertGreaterThanOrEqual(covered, 170)
    }

    func testReactionTimeScoring() {
        let result = ReactionTimeTask.score(reactionTimesMs: [250, 300, 350, 600, 50], prematurePresses: 2)
        XCTAssertEqual(result.medianMs, 325)
        XCTAssertEqual(result.lapses, 1)
        XCTAssertEqual(result.falseStarts, 3)
        XCTAssertEqual(result.trials, 5)
    }

    func testReactionTimeScheduleFillsDuration() {
        var rng = SeededRandom(seed: 3)
        let waits = ReactionTimeTask.makeSchedule(durationSeconds: 180, using: &rng)
        XCTAssertTrue(waits.allSatisfy { ReactionTimeTask.interStimulusRange.contains($0) })
        XCTAssertGreaterThanOrEqual(waits.reduce(0) { $0 + $1 + 0.4 }, 180)
    }

    func testNOf1ExperimentFlow() {
        var rng = SeededRandom(seed: 8)
        let a = ModePreset.parameters(for: .focus)
        var b = a
        b.amTexture.enabled = true
        var experiment = NOf1Experiment(title: "Texture", labelA: "Texture off", labelB: "Texture on",
                                        parametersA: a, parametersB: b, pairs: 6, using: &rng)
        XCTAssertNil(experiment.analysis())
        var sessions = 0
        while let next = experiment.nextSession {
            // Simulate: A is 40 ms faster.
            let rt = next.condition == .a ? 300.0 : 340.0
            experiment.record(ReactionTimeResult(medianMs: rt + Double(next.pair), lapses: 0, falseStarts: 0, trials: 30))
            sessions += 1
        }
        XCTAssertEqual(sessions, 12)
        XCTAssertTrue(experiment.isComplete)
        let analysis = try! XCTUnwrap(experiment.analysis())
        XCTAssertEqual(analysis.meanDifferenceMs, 40, accuracy: 1e-9)
        XCTAssertEqual(analysis.pValue, 2.0 / 64.0, accuracy: 1e-12)
        XCTAssertTrue(analysis.message.contains("Texture off was faster"))
    }

    func testNOf1BalancedOrdersAndPairClamp() {
        var rng = SeededRandom(seed: 1)
        let p = ModePreset.parameters(for: .focus)
        let experiment = NOf1Experiment(title: "x", labelA: "A", labelB: "B", parametersA: p, parametersB: p,
                                        pairs: 99, using: &rng)
        XCTAssertEqual(experiment.schedule.count, 12)
        // Each pair contains exactly one A and one B.
        for order in experiment.schedule {
            XCTAssertNotEqual(order.condition(at: 0), order.condition(at: 1))
        }
    }

    func testNoClearDifferenceMessage() {
        let message = UserFacingCopy.selfTestResult(meanDifferenceMs: 3, ciLow: -10, ciHigh: 16, labelA: "A", labelB: "B")
        XCTAssertTrue(message.hasPrefix("No clear difference"))
    }
}

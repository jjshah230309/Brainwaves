// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// A short vigilance task modelled on the psychomotor vigilance test (PVT).
/// After a random wait the stimulus appears, and the user presses Space.
/// The app provides the UI; scoring lives here so it can be tested.
public enum ReactionTimeTask {
    public static let defaultDurationSeconds: Double = 180
    public static let interStimulusRange: ClosedRange<Double> = 2...10
    /// Responses slower than this count as lapses.
    public static let lapseThresholdMs: Double = 500
    /// Responses faster than this are anticipations and count as false starts.
    public static let anticipationThresholdMs: Double = 100

    /// Random waits that fill roughly `durationSeconds`, assuming about 0.4 s per response.
    public static func makeSchedule(durationSeconds: Double = defaultDurationSeconds,
                                    using rng: inout SeededRandom) -> [Double] {
        var waits: [Double] = []
        var total = 0.0
        let span = interStimulusRange.upperBound - interStimulusRange.lowerBound
        while total < durationSeconds {
            let wait = interStimulusRange.lowerBound + rng.nextUnit() * span
            waits.append(wait)
            total += wait + 0.4
        }
        return waits
    }

    public static func score(reactionTimesMs: [Double], prematurePresses: Int) -> ReactionTimeResult {
        let anticipations = reactionTimesMs.filter { $0 < anticipationThresholdMs }.count
        let valid = reactionTimesMs.filter { $0 >= anticipationThresholdMs }
        return ReactionTimeResult(
            medianMs: median(valid),
            lapses: valid.filter { $0 > lapseThresholdMs }.count,
            falseStarts: prematurePresses + anticipations,
            trials: reactionTimesMs.count)
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}

public struct ReactionTimeResult: Codable, Equatable, Sendable {
    public var medianMs: Double?
    public var lapses: Int
    public var falseStarts: Int
    public var trials: Int
}

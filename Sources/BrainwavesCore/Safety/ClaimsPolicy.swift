// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Forbids medical and over-claiming language in user-facing copy
/// (docs/design/safety.md §3). Unit tests check every string in `UserFacingCopy`.
public enum ClaimsPolicy {
    public static let bannedPhrases: [String] = [
        "cure", "cures", "treat ADHD", "treats ADHD", "treatment for", "clinically proven",
        "scientifically proven", "proven to", "guaranteed", "boost IQ", "brain hack",
        "medical-grade", "FDA-approved", "replace medication", "no side effects",
    ]

    /// Banned phrases found in `text`, matched case-insensitively on word boundaries.
    public static func violations(in text: String) -> [String] {
        bannedPhrases.filter { phrase in
            let escaped = NSRegularExpression.escapedPattern(for: phrase)
            guard let regex = try? NSRegularExpression(pattern: "\\b\(escaped)\\b", options: [.caseInsensitive]) else {
                return false
            }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        }
    }
}

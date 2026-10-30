// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

public enum EvidenceCertainty: String, Codable, Sendable {
    case moderate = "Moderate"
    case low = "Low"
    case veryLow = "Very low"
}

/// Plain-language evidence summary shown next to a feature.
public struct EvidenceCard: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let certainty: EvidenceCertainty
    public let sources: [String]
}

/// All user-facing text that makes or implies a claim. It lives in the
/// portable core so that tests can check it against `ClaimsPolicy`.
public enum UserFacingCopy {
    public static let disclaimer =
        "Brainwaves is a background-sound tool for comfort. It is not a medical device and does not diagnose, " +
        "treat or prevent any condition. Effects of sound on attention and sleep are small and differ between people."

    public static let privacyPromise =
        "Brainwaves collects nothing. There are no accounts, analytics or network requests. Your settings and " +
        "history stay in one file on this Mac, which you can export or delete at any time."

    public static let infantAdvisory =
        "Not for infants or very young children. Keep the volume low and use the sleep timer."

    public static let experimentalAdvisory =
        "Experimental layers have weak or mixed evidence. If you have epilepsy or a history of seizures, talk to a " +
        "clinician first. Stop if you notice discomfort, headache or worsening tinnitus. Binaural beats need headphones."

    public static let alarmAdvisory =
        "Do not use while driving, or when you need to hear alarms or other people."

    public static let exposureEstimateNote =
        "This is an estimate. The app cannot measure how loud your headphones are. Keep the volume moderate and take breaks."

    public static func exposureNotice(for status: ExposureMeter.Status) -> String? {
        switch status {
        case .ok: return nil
        case .approaching: return "You've used 80% of this week's estimated safe-listening allowance."
        case .exceeded: return "You've reached this week's estimated safe-listening allowance. Consider lowering the volume by 6 dB or taking a break."
        }
    }

    public static func modeDescription(_ mode: Mode) -> String {
        switch mode {
        case .focus:
            return "Instrumental, low-distraction music with an optional noise bed. No lyrics: lyrics tend to disrupt reading and writing."
        case .relax:
            return "Slow music that swells about six times a minute. Breathe in as it rises and out as it falls, if you like."
        case .sleep:
            return "A dark, steady sound bed for winding down, with a long fade-out and a capped volume."
        }
    }

    public static let selfTestIntro =
        "Compare two settings on yourself. You'll do pairs of short sessions in random order, each with a 3-minute " +
        "reaction-time game. Conditions are labelled only as Session 1 and Session 2."

    public static let selfTestLimitations =
        "This is a personal experiment, not a scientific study: the samples are small, you may still be able to hear " +
        "which condition is which, practice can affect scores, and reaction time is not the same as real-world productivity."

    /// Plain-language result of an n-of-1 comparison (docs/design/personalization.md §3.2).
    public static func selfTestResult(meanDifferenceMs: Double, ciLow: Double, ciHigh: Double,
                                      labelA: String, labelB: String) -> String {
        let excludesZero = ciLow > 0 || ciHigh < 0
        let magnitude = Int(abs(meanDifferenceMs).rounded())
        let faster = meanDifferenceMs > 0 ? labelA : labelB
        if !excludesZero {
            return "No clear difference between \(labelA) and \(labelB) in your tests. Choose whichever you prefer."
        }
        if abs(meanDifferenceMs) >= NOf1Analysis.meaningfulDifferenceMs {
            return "In your tests, \(faster) was faster by about \(magnitude) ms. That is a noticeable difference for you."
        }
        return "A difference showed up, but it is very small (about \(magnitude) ms) and unlikely to matter in practice."
    }

    public static let evidenceCards: [EvidenceCard] = [
        EvidenceCard(
            id: "lyrics", title: "Why no lyrics?",
            summary: "Across many studies, background speech and music with lyrics slightly impair reading and verbal memory. Instrumental music shows roughly no effect on average.",
            certainty: .moderate,
            sources: ["Vasilev et al., 2018, Perspectives on Psychological Science", "Souza & Leal Barbosa, 2023, Journal of Cognition"]),
        EvidenceCard(
            id: "noise", title: "Noise colours",
            summary: "White or pink noise gave a small benefit on lab attention tasks for young people with ADHD or many ADHD traits, and a small drawback for others. Brown noise has not been tested in controlled studies.",
            certainty: .moderate,
            sources: ["Nigg et al., 2024, J. Am. Acad. Child Adolesc. Psychiatry"]),
        EvidenceCard(
            id: "texture", title: "Pulse texture (amplitude modulation)",
            summary: "One study, run by researchers linked to a company that sells modulated music, found that fast pulsing in music helped some listeners with attention difficulties on a lab task. It has not yet been independently replicated. Try it with the self-test.",
            certainty: .low,
            sources: ["Woods et al., 2024, Communications Biology (authors with commercial interests)"]),
        EvidenceCard(
            id: "relax", title: "Relaxation",
            summary: "Music interventions reduce stress modestly on average. Slow breathing, around six breaths a minute, is linked to relaxation and higher heart-rate variability.",
            certainty: .moderate,
            sources: ["de Witte et al., 2020, Health Psychology Review", "Zaccaro et al., 2018, Frontiers in Human Neuroscience"]),
        EvidenceCard(
            id: "sleep", title: "Sleep",
            summary: "Listening to music may improve how well people feel they slept, in adults with insomnia symptoms. It is unclear whether it changes insomnia severity. Brainwaves makes no claims about deep sleep or memory.",
            certainty: .moderate,
            sources: ["Jespersen et al., 2022, Cochrane Database of Systematic Reviews"]),
        EvidenceCard(
            id: "binaural", title: "Binaural beats (experimental)",
            summary: "Some studies report small effects on memory, attention or anxiety, but evidence that binaural beats synchronise brain rhythms is inconsistent.",
            certainty: .low,
            sources: ["Garcia-Argibay et al., 2019, Psychological Research", "Ingendoh et al., 2023, PLOS ONE"]),
        EvidenceCard(
            id: "gamma", title: "40 Hz pulsing (experimental)",
            summary: "Studied for Alzheimer's disease in mice and in small pilot trials, with mixed results. There is no evidence that it improves focus in healthy adults.",
            certainty: .veryLow,
            sources: ["Chan et al., 2022, PLOS ONE", "Soula et al., 2023, Nature Neuroscience"]),
    ]

    /// Every user-facing string, for claims-policy tests.
    public static var allStrings: [String] {
        var strings = [disclaimer, privacyPromise, infantAdvisory, experimentalAdvisory, alarmAdvisory,
                       exposureEstimateNote, selfTestIntro, selfTestLimitations]
        strings += Mode.allCases.map(modeDescription)
        strings += [ExposureMeter.Status.approaching, .exceeded].compactMap(exposureNotice)
        strings += [selfTestResult(meanDifferenceMs: 40, ciLow: 10, ciHigh: 70, labelA: "A", labelB: "B"),
                    selfTestResult(meanDifferenceMs: 5, ciLow: 1, ciHigh: 9, labelA: "A", labelB: "B"),
                    selfTestResult(meanDifferenceMs: 5, ciLow: -9, ciHigh: 19, labelA: "A", labelB: "B")]
        for card in evidenceCards { strings += [card.title, card.summary] }
        strings += PresetVariant.allCases.map(\.displayName)
        return strings
    }
}

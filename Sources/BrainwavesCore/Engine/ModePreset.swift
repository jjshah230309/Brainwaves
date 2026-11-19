// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Evidence-informed defaults (docs/design/audio-generation.md §4). These are
/// comfortable starting points, not values prescribed by the literature.
public enum ModePreset {
    public static func parameters(for mode: Mode, seed: UInt64 = 1) -> SessionParameters {
        switch mode {
        case .focus:
            return SessionParameters(
                mode: .focus, seed: seed, tempoBPM: 80, brightnessHz: 3500, motifDensity: 0.22,
                barsPerChord: 4, musicLevel: 0.7, noiseColor: .pink, noiseLevel: 0.12,
                amTexture: AMTextureSettings(enabled: false, rateHz: 16, depth: 0.25),
                durationSeconds: 50 * 60, fadeOutSeconds: 10)
        case .relax:
            return SessionParameters(
                mode: .relax, seed: seed, tempoBPM: 60, brightnessHz: 2000, motifDensity: 0.12,
                barsPerChord: 4, musicLevel: 0.7, noiseColor: .pink, noiseLevel: 0.08,
                amTexture: AMTextureSettings(enabled: false, rateHz: 6, depth: 0.15),
                breathing: BreathingSettings(enabled: true, breathsPerMinute: 6, depth: 0.45),
                durationSeconds: 15 * 60, fadeOutSeconds: 30)
        case .sleep:
            return SessionParameters(
                mode: .sleep, seed: seed, tempoBPM: 48, brightnessHz: 900, motifDensity: 0.03,
                barsPerChord: 8, musicLevel: 0.45, noiseColor: .brown, noiseLevel: 0.35,
                amTexture: AMTextureSettings(enabled: false, rateHz: 6, depth: 0.15),
                volumeCap: VolumeCeiling.sleepModeCap,
                durationSeconds: 45 * 60, fadeOutSeconds: 5 * 60)
        }
    }
}

/// Discrete variations of a mode's defaults; these are the bandit's arms
/// (docs/design/personalization.md §2).
public enum PresetVariant: String, Codable, CaseIterable, Sendable {
    case base, brighter, darker, moreNoise = "more-noise", sparser, texture

    public var displayName: String {
        switch self {
        case .base: return "Standard"
        case .brighter: return "Brighter"
        case .darker: return "Darker"
        case .moreNoise: return "More noise"
        case .sparser: return "Sparser"
        case .texture: return "Pulse texture"
        }
    }

    public func apply(to parameters: SessionParameters) -> SessionParameters {
        var p = parameters
        switch self {
        case .base:
            break
        case .brighter:
            p.brightnessHz *= 1.4
        case .darker:
            p.brightnessHz *= 0.65
        case .moreNoise:
            p.noiseLevel += 0.10
        case .sparser:
            p.motifDensity *= 0.5
        case .texture:
            p.amTexture.enabled = true
        }
        return p.clamped()
    }

    /// Variants the bandit may choose. The texture arm requires the user's
    /// explicit opt-in and an AM-enabled build.
    public static func eligible(amTextureAllowed: Bool) -> [PresetVariant] {
        allCases.filter { $0 != .texture || (amTextureAllowed && AmplitudeModulator.isCompiledIn) }
    }
}

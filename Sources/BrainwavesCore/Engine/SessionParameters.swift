// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

public enum Mode: String, Codable, CaseIterable, Identifiable, Sendable {
    case focus, relax, sleep

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .focus: return "Focus"
        case .relax: return "Relax"
        case .sleep: return "Sleep"
        }
    }
}

public struct AMTextureSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var rateHz: Double
    public var depth: Double

    public init(enabled: Bool = false, rateHz: Double = 16, depth: Double = 0.25) {
        self.enabled = enabled
        self.rateHz = rateHz
        self.depth = depth
    }

    public static let rateRange: ClosedRange<Double> = 4...20
    public static let depthRange: ClosedRange<Double> = 0...0.5
}

public struct BreathingSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var breathsPerMinute: Double
    public var depth: Double

    public init(enabled: Bool = false, breathsPerMinute: Double = 6, depth: Double = 0.45) {
        self.enabled = enabled
        self.breathsPerMinute = breathsPerMinute
        self.depth = depth
    }

    public static let rateRange: ClosedRange<Double> = 3...12
    public static let depthRange: ClosedRange<Double> = 0...0.6
}

/// Experimental, opt-in layer.
public struct BinauralSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var carrierHz: Double
    public var beatHz: Double
    /// Linear level relative to full scale (0.063 ≈ −24 dB).
    public var level: Double

    public init(enabled: Bool = false, carrierHz: Double = 200, beatHz: Double = 10, level: Double = 0.063) {
        self.enabled = enabled
        self.carrierHz = carrierHz
        self.beatHz = beatHz
        self.level = level
    }

    public static let carrierRange: ClosedRange<Double> = 100...500
    public static let beatRange: ClosedRange<Double> = 1...30
    public static let levelRange: ClosedRange<Double> = 0...0.25
}

/// Experimental, opt-in 40 Hz amplitude modulation of the whole mix.
public struct GammaSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var depth: Double

    public init(enabled: Bool = false, depth: Double = 0.3) {
        self.enabled = enabled
        self.depth = depth
    }

    public static let rateHz: Double = 40
    public static let depthRange: ClosedRange<Double> = 0...0.5
}

/// Everything the renderer needs. A pure value type with no heap storage, so
/// copying it on the audio thread never allocates.
public struct SessionParameters: Codable, Equatable, Sendable {
    public var mode: Mode
    public var seed: UInt64
    public var tempoBPM: Double
    public var brightnessHz: Double
    public var motifDensity: Double
    public var barsPerChord: Int
    public var musicLevel: Double
    public var noiseColor: NoiseColor
    public var noiseLevel: Double
    public var amTexture: AMTextureSettings
    public var breathing: BreathingSettings
    public var binaural: BinauralSettings
    public var gamma: GammaSettings
    /// User volume, 0–1. It is always limited to `volumeCap`.
    public var masterGain: Double
    public var volumeCap: Double
    /// `nil` = open-ended session.
    public var durationSeconds: Double?
    public var fadeOutSeconds: Double

    public init(mode: Mode, seed: UInt64, tempoBPM: Double, brightnessHz: Double, motifDensity: Double,
                barsPerChord: Int, musicLevel: Double, noiseColor: NoiseColor, noiseLevel: Double,
                amTexture: AMTextureSettings = .init(), breathing: BreathingSettings = .init(),
                binaural: BinauralSettings = .init(), gamma: GammaSettings = .init(),
                masterGain: Double = VolumeCeiling.defaultMasterGain, volumeCap: Double = 1,
                durationSeconds: Double? = nil, fadeOutSeconds: Double = 10) {
        self.mode = mode
        self.seed = seed
        self.tempoBPM = tempoBPM
        self.brightnessHz = brightnessHz
        self.motifDensity = motifDensity
        self.barsPerChord = barsPerChord
        self.musicLevel = musicLevel
        self.noiseColor = noiseColor
        self.noiseLevel = noiseLevel
        self.amTexture = amTexture
        self.breathing = breathing
        self.binaural = binaural
        self.gamma = gamma
        self.masterGain = masterGain
        self.volumeCap = volumeCap
        self.durationSeconds = durationSeconds
        self.fadeOutSeconds = fadeOutSeconds
    }

    public static let tempoRange: ClosedRange<Double> = 30...120
    public static let brightnessRange: ClosedRange<Double> = 300...8000
    public static let densityRange: ClosedRange<Double> = 0...0.5

    /// Forces every value into its safe range. The renderer only ever uses clamped parameters.
    public func clamped() -> SessionParameters {
        var p = self
        p.tempoBPM = p.tempoBPM.clamped(to: Self.tempoRange)
        p.brightnessHz = p.brightnessHz.clamped(to: Self.brightnessRange)
        p.motifDensity = p.motifDensity.clamped(to: Self.densityRange)
        p.barsPerChord = min(max(p.barsPerChord, 1), 16)
        p.musicLevel = p.musicLevel.clamped(to: 0...1)
        p.noiseLevel = p.noiseLevel.clamped(to: 0...1)
        p.amTexture.rateHz = p.amTexture.rateHz.clamped(to: AMTextureSettings.rateRange)
        p.amTexture.depth = p.amTexture.depth.clamped(to: AMTextureSettings.depthRange)
        p.breathing.breathsPerMinute = p.breathing.breathsPerMinute.clamped(to: BreathingSettings.rateRange)
        p.breathing.depth = p.breathing.depth.clamped(to: BreathingSettings.depthRange)
        p.binaural.carrierHz = p.binaural.carrierHz.clamped(to: BinauralSettings.carrierRange)
        p.binaural.beatHz = p.binaural.beatHz.clamped(to: BinauralSettings.beatRange)
        p.binaural.level = p.binaural.level.clamped(to: BinauralSettings.levelRange)
        p.gamma.depth = p.gamma.depth.clamped(to: GammaSettings.depthRange)
        p.volumeCap = p.volumeCap.clamped(to: 0...1)
        p.masterGain = p.masterGain.clamped(to: 0...p.volumeCap)
        if let duration = p.durationSeconds { p.durationSeconds = max(duration, 1) }
        p.fadeOutSeconds = p.fadeOutSeconds.clamped(to: 0...600)
        return p
    }
}

extension Double {
    /// Clamps to a range. NaN and infinities map to the lower bound, so bad
    /// input can never reach the audio path.
    @inline(__always)
    func clamped(to range: ClosedRange<Double>) -> Double {
        guard isFinite else { return range.lowerBound }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

public enum VolumeCeiling {
    /// Default user volume: half of full scale.
    public static let defaultMasterGain = 0.5
    /// Sleep mode cannot exceed 60% of full scale.
    public static let sleepModeCap = 0.6
    /// Limiter ceiling in dBFS.
    public static let limiterCeilingDBFS = -1.0
}

/// Estimated weekly listening dose, following the WHO-ITU H.870 approach of
/// a reference level for 40 h a week with a 3 dB exchange rate
/// (docs/design/safety.md §2). This is an **estimate**: digital level cannot
/// be converted to sound pressure without calibrating the headphones.
public struct ExposureMeter: Codable, Equatable, Sendable {
    public enum Profile: String, Codable, CaseIterable, Sendable {
        /// 80 dB(A) for 40 h per week.
        case adult
        /// 75 dB(A) for 40 h per week (children or sensitive listeners).
        case sensitive

        public var referenceDB: Double { self == .adult ? 80 : 75 }
    }

    public enum Status: Equatable, Sendable {
        case ok
        case approaching
        case exceeded
    }

    public var profile: Profile
    /// Assumed SPL at 0 dBFS with system volume at maximum.
    public var calibrationOffsetDB: Double
    /// System output volume, 0–1, as entered by the user (1 if unknown).
    public var systemVolume: Double
    public private(set) var doseFraction: Double
    public private(set) var weekStart: Date

    public static let referenceHours = 40.0
    public static let exchangeRateDB = 3.0

    public init(profile: Profile = .adult, calibrationOffsetDB: Double = 100, systemVolume: Double = 1,
                now: Date = Date()) {
        self.profile = profile
        self.calibrationOffsetDB = calibrationOffsetDB
        self.systemVolume = systemVolume
        doseFraction = 0
        weekStart = ExposureMeter.startOfWeek(containing: now)
    }

    /// Allowed listening time at `levelDB`: T(L) = 40 h · 2^((L_ref − L)/3).
    public static func allowedSeconds(levelDB: Double, referenceDB: Double) -> Double {
        referenceHours * 3600 * pow(2, (referenceDB - levelDB) / exchangeRateDB)
    }

    /// Estimated level: dBFS(RMS) + 20·log10(system volume) + calibration offset.
    public func estimatedLevelDB(rms: Double) -> Double {
        guard rms > 0, systemVolume > 0 else { return -Double.infinity }
        return 20 * log10(rms) + 20 * log10(min(systemVolume, 1)) + calibrationOffsetDB
    }

    /// Adds `seconds` of listening at the given output RMS. Resets weekly.
    public mutating func accumulate(rms: Double, seconds: Double, now: Date = Date()) {
        let currentWeek = ExposureMeter.startOfWeek(containing: now)
        if currentWeek > weekStart {
            weekStart = currentWeek
            doseFraction = 0
        }
        let level = estimatedLevelDB(rms: rms)
        guard level.isFinite, seconds > 0 else { return }
        doseFraction += seconds / ExposureMeter.allowedSeconds(levelDB: level, referenceDB: profile.referenceDB)
    }

    public var status: Status {
        if doseFraction >= 1.0 { return .exceeded }
        if doseFraction >= 0.8 { return .approaching }
        return .ok
    }

    public mutating func reset(now: Date = Date()) {
        doseFraction = 0
        weekStart = ExposureMeter.startOfWeek(containing: now)
    }

    static func startOfWeek(containing date: Date) -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone.current
        return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
}

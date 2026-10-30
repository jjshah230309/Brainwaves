// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

public enum Pitch {
    /// Equal-tempered frequency of a MIDI note number (A4 = 69 = 440 Hz).
    @inline(__always)
    public static func frequency(midi: Double) -> Double {
        440.0 * pow(2.0, (midi - 69.0) / 12.0)
    }

    /// Frequency ratio for a detune in cents.
    @inline(__always)
    public static func ratio(cents: Double) -> Double {
        pow(2.0, cents / 1200.0)
    }
}

/// Major pentatonic (no semitone steps, so random melodic walks never clash).
public enum PentatonicScale {
    public static let intervals = [0, 2, 4, 7, 9]

    /// Semitone offset of a scale degree, which may span several octaves.
    public static func semitones(degree: Int) -> Int {
        let count = intervals.count
        let octave = Int((Double(degree) / Double(count)).rounded(.down))
        let index = degree - octave * count
        return octave * 12 + intervals[index]
    }
}

/// Diatonic triads in a major key and the progressions allowed between them.
public enum Chord: Int, CaseIterable, Sendable {
    case one, two, four, five, six

    /// Semitone offsets from the key root, in close voicing.
    public var tones: [Int] {
        switch self {
        case .one: return [0, 4, 7]
        case .two: return [2, 5, 9]
        case .four: return [5, 9, 12]
        case .five: return [7, 11, 14]
        case .six: return [9, 12, 16]
        }
    }

    public var rootOffset: Int { tones[0] }

    /// Focus mode allows gentle movement, including V.
    static func focusSuccessors(of chord: Chord) -> [Chord] {
        switch chord {
        case .one: return [.six, .four, .two]
        case .two: return [.five, .four]
        case .four: return [.one, .two, .five]
        case .five: return [.one, .six]
        case .six: return [.four, .two]
        }
    }

    /// Relax and Sleep use only I, IV and vi, so there is no dominant tension.
    static func calmSuccessors(of chord: Chord) -> [Chord] {
        switch chord {
        case .one: return [.four, .six]
        case .four: return [.one, .six]
        case .six: return [.four, .one]
        case .two, .five: return [.one]
        }
    }
}

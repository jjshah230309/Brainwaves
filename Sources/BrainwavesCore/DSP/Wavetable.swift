// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Single-cycle lookup tables with linear interpolation. Lookups are much
/// cheaper than calling `sin` for every partial of every voice on every sample.
public struct Wavetable: Sendable {
    public static let size = 4096
    private let table: [Float]

    /// Builds a table from harmonic amplitudes (index 0 is the fundamental).
    public init(harmonics: [Float]) {
        var values = [Float](repeating: 0, count: Wavetable.size + 1)
        let peak = harmonics.reduce(0, +)
        for i in 0...Wavetable.size {
            let phase = Double(i) / Double(Wavetable.size)
            var sum: Double = 0
            for (h, amplitude) in harmonics.enumerated() {
                sum += Double(amplitude) * sin(2.0 * Double.pi * Double(h + 1) * phase)
            }
            values[i] = Float(sum) / max(peak, 1e-6)
        }
        table = values
    }

    /// `phase` is in cycles and may be any value; it is wrapped to [0, 1).
    @inline(__always)
    public func value(at phase: Double) -> Float {
        let wrapped = phase - phase.rounded(.down)
        let position = wrapped * Double(Wavetable.size)
        let index = Int(position)
        let fraction = Float(position - Double(index))
        return table[index] + (table[index + 1] - table[index]) * fraction
    }

    public static let sine = Wavetable(harmonics: [1])
    /// Soft pad: partials 1 : 0.35 : 0.12 (docs/design/audio-generation.md §3.4).
    public static let pad = Wavetable(harmonics: [1, 0.35, 0.12])
}

// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// A small Schroeder reverb: 4 parallel damped comb filters followed by
/// 2 series all-pass filters per channel. All buffers are allocated in `init`,
/// so `process` never allocates.
public final class Reverb {
    private struct Comb {
        var buffer: [Float]
        var index = 0
        var filterStore: Float = 0

        init(length: Int) { buffer = [Float](repeating: 0, count: max(length, 1)) }

        @inline(__always)
        mutating func process(_ input: Float, feedback: Float, damping: Float) -> Float {
            let output = buffer[index]
            filterStore = output * (1 - damping) + filterStore * damping
            buffer[index] = input + filterStore * feedback
            index += 1
            if index == buffer.count { index = 0 }
            return output
        }
    }

    private struct AllPass {
        var buffer: [Float]
        var index = 0

        init(length: Int) { buffer = [Float](repeating: 0, count: max(length, 1)) }

        @inline(__always)
        mutating func process(_ input: Float) -> Float {
            let buffered = buffer[index]
            let output = buffered - input
            buffer[index] = input + buffered * 0.5
            index += 1
            if index == buffer.count { index = 0 }
            return output
        }
    }

    // Prime-ish delay lengths (samples at 44.1 kHz), scaled to the actual rate.
    private static let combLengths = [1117, 1187, 1277, 1361]
    private static let allPassLengths = [557, 443]
    private static let stereoSpread = 23

    private var combsL: [Comb]
    private var combsR: [Comb]
    private var allPassL: [AllPass]
    private var allPassR: [AllPass]

    public var feedback: Float = 0.80
    public var damping: Float = 0.35

    public init(sampleRate: Double) {
        let scale = sampleRate / 44_100.0
        func scaled(_ n: Int) -> Int { Int((Double(n) * scale).rounded()) }
        combsL = Reverb.combLengths.map { Comb(length: scaled($0)) }
        combsR = Reverb.combLengths.map { Comb(length: scaled($0 + Reverb.stereoSpread)) }
        allPassL = Reverb.allPassLengths.map { AllPass(length: scaled($0)) }
        allPassR = Reverb.allPassLengths.map { AllPass(length: scaled($0 + Reverb.stereoSpread)) }
    }

    @inline(__always)
    public func process(_ input: Float) -> (left: Float, right: Float) {
        let x = input * 0.25
        var left: Float = 0
        var right: Float = 0
        for i in 0..<combsL.count {
            left += combsL[i].process(x, feedback: feedback, damping: damping)
            right += combsR[i].process(x, feedback: feedback, damping: damping)
        }
        for i in 0..<allPassL.count {
            left = allPassL[i].process(left)
            right = allPassR[i].process(right)
        }
        return (left, right)
    }
}

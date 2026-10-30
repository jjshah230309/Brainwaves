// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Sustained pad note: two oscillators detuned by ±4 cents, read from the soft
/// additive pad table, with a linear attack and release envelope.
struct PadVoice {
    private(set) var isActive = false
    private var phaseA: Double = 0
    private var phaseB: Double = 0
    private var incrementA: Double = 0
    private var incrementB: Double = 0
    private var level: Float = 0
    private var gate = false
    private var attackStep: Float = 0
    private var releaseStep: Float = 0
    private(set) var age = 0
    var panLeft: Float = 0.707
    var panRight: Float = 0.707
    var amplitude: Float = 0.12

    mutating func noteOn(frequency: Double, attack: Double, release: Double, pan: Float, sampleRate: Double) {
        let detune = Pitch.ratio(cents: 4)
        incrementA = frequency * detune / sampleRate
        incrementB = frequency / detune / sampleRate
        attackStep = Float(1.0 / max(attack * sampleRate, 1))
        releaseStep = Float(1.0 / max(release * sampleRate, 1))
        // Equal-power pan; pan ∈ [-1, 1].
        let angle = Double(pan + 1) * Double.pi / 4
        panLeft = Float(cos(angle))
        panRight = Float(sin(angle))
        gate = true
        isActive = true
        age = 0
    }

    mutating func noteOff() {
        gate = false
    }

    @inline(__always)
    mutating func next(table: Wavetable) -> Float {
        guard isActive else { return 0 }
        if gate {
            level = min(1, level + attackStep)
        } else {
            level -= releaseStep
            if level <= 0 {
                level = 0
                isActive = false
                return 0
            }
        }
        let sample = (table.value(at: phaseA) + table.value(at: phaseB)) * 0.5
        phaseA += incrementA
        phaseB += incrementB
        if phaseA >= 1 { phaseA -= 1 }
        if phaseB >= 1 { phaseB -= 1 }
        age += 1
        return sample * level * amplitude
    }
}

/// Soft FM bell for sparse melodic motifs:
/// y = A(t) · sin(2π f_c t + I(t) · sin(2π f_m t)), with f_m/f_c = 2 and I(t) = I₀ e^{-t/0.4}.
struct BellVoice {
    private(set) var isActive = false
    private var carrierPhase: Double = 0
    private var modulatorPhase: Double = 0
    private var carrierIncrement: Double = 0
    private var modulatorIncrement: Double = 0
    private var amplitude: Float = 0
    private var peak: Float = 0
    private var attackRemaining = 0
    private var attackStep: Float = 0
    private var decay: Float = 1
    private var index: Double = 0
    private var indexDecay: Double = 1
    private(set) var age = 0
    var panLeft: Float = 0.707
    var panRight: Float = 0.707

    mutating func strike(frequency: Double, velocity: Float, pan: Float, sampleRate: Double) {
        carrierIncrement = frequency / sampleRate
        modulatorIncrement = 2.0 * frequency / sampleRate
        carrierPhase = 0
        modulatorPhase = 0
        peak = 0.10 * velocity
        amplitude = 0
        let attackSamples = max(Int(0.020 * sampleRate), 1)
        attackRemaining = attackSamples
        attackStep = peak / Float(attackSamples)
        decay = Float(exp(-1.0 / (1.2 * sampleRate)))
        index = 1.6
        indexDecay = exp(-1.0 / (0.4 * sampleRate))
        let angle = Double(pan + 1) * Double.pi / 4
        panLeft = Float(cos(angle))
        panRight = Float(sin(angle))
        isActive = true
        age = 0
    }

    @inline(__always)
    mutating func next(table: Wavetable) -> Float {
        guard isActive else { return 0 }
        if attackRemaining > 0 {
            amplitude += attackStep
            attackRemaining -= 1
        } else {
            amplitude *= decay
            if amplitude < 1e-4 {
                isActive = false
                return 0
            }
        }
        let modulator = Double(table.value(at: modulatorPhase))
        let sample = table.value(at: carrierPhase + index * modulator / (2.0 * Double.pi))
        carrierPhase += carrierIncrement
        modulatorPhase += modulatorIncrement
        if carrierPhase >= 1 { carrierPhase -= 1 }
        if modulatorPhase >= 1 { modulatorPhase -= 1 }
        index *= indexDecay
        age += 1
        return sample * amplitude
    }
}

// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Seeded, endless, low-salience music: diatonic pad chords, a bass note one
/// octave below, and sparse pentatonic bell motifs. Every voice is allocated
/// up front, so `next()` never allocates.
public final class GenerativeComposer {
    public var tempoBPM: Double
    public var motifDensity: Double
    public var barsPerChord: Int
    /// Calm harmony (I, IV, vi only) for Relax and Sleep.
    public var calm: Bool

    public let keyRoot: Int
    private let sampleRate: Double
    private var rng: SeededRandom
    private var pads = [PadVoice](repeating: PadVoice(), count: 6)
    private var bass = PadVoice()
    private var bells = [BellVoice](repeating: BellVoice(), count: 6)
    private var samplesUntilBeat: Double = 0
    private var beatCounter = 0
    private(set) var chord: Chord = .one
    private var motifDegree = 5
    private static let beatsPerBar = 4
    private let padTable = Wavetable.pad
    private let sineTable = Wavetable.sine

    public init(seed: UInt64, sampleRate: Double, tempoBPM: Double, motifDensity: Double, barsPerChord: Int, calm: Bool) {
        self.sampleRate = sampleRate
        self.tempoBPM = tempoBPM
        self.motifDensity = motifDensity
        self.barsPerChord = max(barsPerChord, 1)
        self.calm = calm
        var generator = SeededRandom(seed: seed)
        keyRoot = generator.int(in: 0...11)
        rng = generator
        bass.amplitude = 0.16
    }

    /// One stereo sample of the music bus (before brightness filtering and modulation).
    @inline(__always)
    public func next() -> (left: Float, right: Float) {
        samplesUntilBeat -= 1
        if samplesUntilBeat <= 0 {
            onBeat()
            samplesUntilBeat += 60.0 / max(tempoBPM, 1) * sampleRate
        }
        var left: Float = 0
        var right: Float = 0
        for i in 0..<pads.count where pads[i].isActive {
            let s = pads[i].next(table: padTable)
            left += s * pads[i].panLeft
            right += s * pads[i].panRight
        }
        let b = bass.next(table: sineTable)
        left += b * 0.707
        right += b * 0.707
        for i in 0..<bells.count where bells[i].isActive {
            let s = bells[i].next(table: sineTable)
            left += s * bells[i].panLeft
            right += s * bells[i].panRight
        }
        return (left, right)
    }

    private func onBeat() {
        let beatsPerChord = GenerativeComposer.beatsPerBar * max(barsPerChord, 1)
        if beatCounter % beatsPerChord == 0 {
            changeChord(first: beatCounter == 0)
        }
        if rng.chance(motifDensity) {
            playMotifNote()
        }
        beatCounter += 1
    }

    private func changeChord(first: Bool) {
        if !first {
            let options = calm ? Chord.calmSuccessors(of: chord) : Chord.focusSuccessors(of: chord)
            chord = options[rng.int(in: 0...(options.count - 1))]
        }
        for i in 0..<pads.count { pads[i].noteOff() }
        let attack = calm ? 3.5 : 2.5
        let release = calm ? 6.0 : 4.0
        for (n, tone) in chord.tones.enumerated() {
            let voice = freeOrOldestPad()
            let midi = Double(48 + keyRoot + tone)
            let pan = Float(n - 1) * 0.3
            pads[voice].noteOn(frequency: Pitch.frequency(midi: midi), attack: attack, release: release,
                               pan: pan, sampleRate: sampleRate)
        }
        let bassMidi = Double(36 + keyRoot + chord.rootOffset)
        bass.noteOn(frequency: Pitch.frequency(midi: bassMidi), attack: attack, release: release,
                    pan: 0, sampleRate: sampleRate)
    }

    private func playMotifNote() {
        let steps = [-2, -1, 1, 2]
        motifDegree = min(max(motifDegree + steps[rng.int(in: 0...3)], 0), 9)
        let midi = Double(60 + keyRoot + PentatonicScale.semitones(degree: motifDegree))
        let velocity = Float(0.5 + 0.3 * rng.nextUnit())
        let pan = Float(rng.nextUnit() * 0.8 - 0.4)
        let voice = freeOrOldestBell()
        bells[voice].strike(frequency: Pitch.frequency(midi: midi), velocity: velocity, pan: pan, sampleRate: sampleRate)
    }

    private func freeOrOldestPad() -> Int {
        var oldest = 0
        for i in 0..<pads.count {
            if !pads[i].isActive { return i }
            if pads[i].age > pads[oldest].age { oldest = i }
        }
        return oldest
    }

    private func freeOrOldestBell() -> Int {
        var oldest = 0
        for i in 0..<bells.count {
            if !bells[i].isActive { return i }
            if bells[i].age > bells[oldest].age { oldest = i }
        }
        return oldest
    }
}

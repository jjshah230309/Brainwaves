// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.
//
// bwrender: render a Brainwaves session to a WAV file, offline and deterministically.

import BrainwavesCore
import Foundation

let usage = """
Usage: bwrender [options]
  --mode focus|relax|sleep     Mode preset (default: focus)
  --seconds N                  Length in seconds (default: 30)
  --seed N                     Random seed (default: 1)
  --rate N                     Sample rate in Hz (default: 48000)
  --out PATH                   Output WAV path (default: brainwaves.wav)
  --noise white|pink|brown     Noise colour
  --noise-level X              Noise level, 0–1
  --music-level X              Music level, 0–1
  --am-rate HZ --am-depth X    Enable the AM texture (4–20 Hz, depth 0–0.5)
  --binaural HZ                Enable the experimental binaural beat (1–30 Hz)
  --gamma X                    Enable experimental 40 Hz modulation (depth 0–0.5)
  --master X                   Master gain, 0–1 (default 0.5)
  --help                       Show this help
"""

var arguments = Array(CommandLine.arguments.dropFirst())
var options: [String: String] = [:]
while !arguments.isEmpty {
    let key = arguments.removeFirst()
    if key == "--help" || key == "-h" {
        print(usage)
        exit(0)
    }
    guard key.hasPrefix("--"), !arguments.isEmpty else {
        FileHandle.standardError.write(Data("Invalid argument: \(key)\n\n\(usage)\n".utf8))
        exit(2)
    }
    options[String(key.dropFirst(2))] = arguments.removeFirst()
}

func number(_ key: String) -> Double? {
    guard let raw = options[key] else { return nil }
    guard let value = Double(raw), value.isFinite else {
        FileHandle.standardError.write(Data("--\(key) needs a number, got \(raw)\n".utf8))
        exit(2)
    }
    return value
}

guard let mode = Mode(rawValue: options["mode"] ?? "focus") else {
    FileHandle.standardError.write(Data("Unknown mode. Use focus, relax or sleep.\n".utf8))
    exit(2)
}
let seconds = number("seconds") ?? 30
let sampleRate = number("rate") ?? 48_000
let seed = UInt64(number("seed") ?? 1)
let outPath = options["out"] ?? "brainwaves.wav"

guard seconds > 0, seconds <= 3600, sampleRate >= 8000, sampleRate <= 192_000 else {
    FileHandle.standardError.write(Data("seconds must be in (0, 3600]; rate must be in [8000, 192000]\n".utf8))
    exit(2)
}

var parameters = ModePreset.parameters(for: mode, seed: seed)
parameters.durationSeconds = nil // offline renders run for exactly --seconds
if let colour = options["noise"] {
    guard let parsed = NoiseColor(rawValue: colour) else {
        FileHandle.standardError.write(Data("Unknown noise colour \(colour)\n".utf8))
        exit(2)
    }
    parameters.noiseColor = parsed
}
if let value = number("noise-level") { parameters.noiseLevel = value }
if let value = number("music-level") { parameters.musicLevel = value }
if let value = number("master") { parameters.masterGain = value }
if let rate = number("am-rate") {
    parameters.amTexture = AMTextureSettings(enabled: true, rateHz: rate, depth: number("am-depth") ?? 0.25)
}
if let beat = number("binaural") {
    parameters.binaural.enabled = true
    parameters.binaural.beatHz = beat
}
if let depth = number("gamma") {
    parameters.gamma = GammaSettings(enabled: true, depth: depth)
}

let renderer = SessionRenderer(sampleRate: sampleRate, parameters: parameters)
let frames = Int(seconds * sampleRate)
let output = renderer.renderOffline(frames: frames)
let wav = WAVWriter.encode(left: output.left, right: output.right, sampleRate: Int(sampleRate))

do {
    try wav.write(to: URL(fileURLWithPath: outPath))
} catch {
    FileHandle.standardError.write(Data("Could not write \(outPath): \(error)\n".utf8))
    exit(1)
}
let peak = max(output.left.map(abs).max() ?? 0, output.right.map(abs).max() ?? 0)
let peakDB = peak > 0 ? 20 * log10(Double(peak)) : -Double.infinity
let peakText = peakDB.isFinite ? String(format: "%.2f", peakDB) : "-inf"
print("Wrote \(outPath) (\(seconds) s, \(mode.rawValue) mode, seed \(seed), peak \(peakText) dBFS)")

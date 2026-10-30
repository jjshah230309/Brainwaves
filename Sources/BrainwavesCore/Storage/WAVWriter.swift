// SPDX-License-Identifier: MIT
// Brainwaves — open-source functional audio.

import Foundation

/// Minimal 16-bit PCM stereo WAV encoder, used by the offline renderer.
public enum WAVWriter {
    public static func encode(left: [Float], right: [Float], sampleRate: Int) -> Data {
        precondition(left.count == right.count, "channel lengths must match")
        let channels = 2
        let bitsPerSample = 16
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let dataSize = left.count * channels * bitsPerSample / 8

        var data = Data()
        data.reserveCapacity(44 + dataSize)
        func append(_ string: String) { data.append(contentsOf: Array(string.utf8)) }
        func append32(_ value: Int) { withUnsafeBytes(of: UInt32(value).littleEndian) { data.append(contentsOf: $0) } }
        func append16(_ value: Int) { withUnsafeBytes(of: UInt16(value).littleEndian) { data.append(contentsOf: $0) } }

        append("RIFF"); append32(36 + dataSize); append("WAVE")
        append("fmt "); append32(16); append16(1); append16(channels)
        append32(sampleRate); append32(byteRate); append16(channels * bitsPerSample / 8); append16(bitsPerSample)
        append("data"); append32(dataSize)
        for i in 0..<left.count {
            for sample in [left[i], right[i]] {
                let clipped = max(-1, min(1, sample))
                let value = Int16((clipped * 32767).rounded())
                withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
            }
        }
        return data
    }
}

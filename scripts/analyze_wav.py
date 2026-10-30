#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Analyse a Brainwaves WAV render: level, spectral slope, modulation and binaural checks.

Usage:
  analyze_wav.py FILE.wav [--expect-slope DB_PER_OCT] [--expect-am HZ] [--expect-binaural HZ]
Exits non-zero if an expectation fails. Needs numpy.
"""
import argparse
import sys
import wave

import numpy as np

CEILING_DBFS = -1.0


def read(path):
    with wave.open(path, "rb") as w:
        if w.getsampwidth() != 2 or w.getnchannels() != 2:
            raise SystemExit("expected 16-bit stereo WAV")
        rate = w.getframerate()
        raw = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64) / 32767.0
    return rate, raw[0::2], raw[1::2]


def octave_slope(x, rate, lo=100.0, hi=6400.0):
    """Least-squares slope of band power (dB) against octave number."""
    n = 1 << int(np.floor(np.log2(len(x))))
    spectrum = np.abs(np.fft.rfft(x[:n] * np.hanning(n))) ** 2
    freqs = np.fft.rfftfreq(n, 1.0 / rate)
    centres, powers = [], []
    f = lo
    while f * np.sqrt(2) <= hi:
        band = (freqs >= f / np.sqrt(2)) & (freqs < f * np.sqrt(2))
        # Mean power spectral density in the band (per-Hz), so slopes match S(f) ∝ f^-k.
        centres.append(np.log2(f))
        powers.append(10 * np.log10(np.mean(spectrum[band]) + 1e-30))
        f *= 2
    slope, _ = np.polyfit(centres, powers, 1)
    return slope


def envelope_peak(x, rate, fmin=2.0, fmax=50.0):
    env = np.abs(x)
    n = len(env)
    spectrum = np.abs(np.fft.rfft((env - env.mean()) * np.hanning(n)))
    freqs = np.fft.rfftfreq(n, 1.0 / rate)
    band = (freqs >= fmin) & (freqs <= fmax)
    return freqs[band][np.argmax(spectrum[band])]


def dominant(x, rate, fmin=50.0, fmax=600.0):
    n = len(x)
    spectrum = np.abs(np.fft.rfft(x * np.hanning(n)))
    freqs = np.fft.rfftfreq(n, 1.0 / rate)
    band = (freqs >= fmin) & (freqs <= fmax)
    return freqs[band][np.argmax(spectrum[band])]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--expect-slope", type=float)
    ap.add_argument("--slope-tolerance", type=float, default=1.5)
    ap.add_argument("--expect-am", type=float)
    ap.add_argument("--expect-binaural", type=float)
    args = ap.parse_args()

    rate, left, right = read(args.path)
    peak = max(np.max(np.abs(left)), np.max(np.abs(right)))
    rms = np.sqrt(np.mean((left ** 2 + right ** 2) / 2))
    peak_db = 20 * np.log10(max(peak, 1e-12))
    print(f"{args.path}: {len(left) / rate:.1f} s @ {rate} Hz")
    print(f"  peak {peak_db:.2f} dBFS, RMS {20 * np.log10(max(rms, 1e-12)):.2f} dBFS")
    failures = []
    if peak_db > CEILING_DBFS + 0.01:
        failures.append(f"peak {peak_db:.2f} dBFS exceeds the {CEILING_DBFS} dBFS ceiling")
    if not (np.all(np.isfinite(left)) and np.all(np.isfinite(right))):
        failures.append("non-finite samples")

    slope = octave_slope((left + right) / 2, rate)
    print(f"  spectral slope 100 Hz–6.4 kHz: {slope:.2f} dB/oct")
    if args.expect_slope is not None and abs(slope - args.expect_slope) > args.slope_tolerance:
        failures.append(f"slope {slope:.2f} not within ±{args.slope_tolerance} of {args.expect_slope}")

    if args.expect_am is not None:
        found = envelope_peak((left + right) / 2, rate)
        print(f"  envelope modulation peak: {found:.2f} Hz")
        if abs(found - args.expect_am) > 0.5:
            failures.append(f"AM peak {found:.2f} Hz, expected {args.expect_am}")

    if args.expect_binaural is not None:
        diff = dominant(right, rate) - dominant(left, rate)
        print(f"  binaural R−L dominant-frequency difference: {diff:.2f} Hz")
        if abs(diff - args.expect_binaural) > 0.5:
            failures.append(f"binaural difference {diff:.2f} Hz, expected {args.expect_binaural}")

    for f in failures:
        print("  FAIL:", f)
    print("  OK" if not failures else "  FAILED")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())

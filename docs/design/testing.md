# Testing Strategy

**Document:** D-08 · **Version:** 1.0 · **Date:** 2026-10-30

## 1. Test pyramid

| Layer | What | Where | Runs on |
|---|---|---|---|
| Unit | DSP maths, bandit, statistics, storage, claims policy | `Tests/BrainwavesCoreTests` | Linux and macOS CI |
| Signal verification | Spectral slope of the noise colours, AM rate and depth, binaural frequency difference, limiter ceiling, no NaN or Inf, determinism | `Tests/BrainwavesCoreTests/SignalTests.swift` | Linux and macOS CI |
| Offline render | `bwrender` WAV output; Python spectral analysis | `scripts/analyze_wav.py` | CI (Linux) |
| Static QA gate | Citations, banned claims, network APIs, trademark use, approval records | `scripts/qa_gate.py` | CI |
| Build | `.app` bundle assembled without Xcode | `scripts/build-app.sh` | macOS CI |
| Manual | Accessibility checklist; listening test; CPU profile | [`accessibility.md`](accessibility.md) | Before release |

## 2. Signal acceptance criteria

| Test | Method | Pass criterion |
|---|---|---|
| Pink slope | Average the DFT magnitudes in octave bands from 100 Hz to 6.4 kHz; least-squares slope | $-3 \pm 1.5$ dB/oct |
| Brown slope | Same, from 400 Hz, above the leaky-integrator corner (≈ 150 Hz at 48 kHz) | $-6 \pm 1.5$ dB/oct |
| White flatness | Same | $0 \pm 1$ dB/oct |
| AM rate | Envelope (rectify, then low-pass); Goertzel power at $f_m$ compared with neighbouring bins | Peak at $f_m$, at least 10× the neighbouring bins |
| AM depth | $(\max - \min)/\max$ of the gain trajectory | Within 0.01 of $d$ |
| Binaural | Goertzel on L and R separately | Peaks at $f_c \mp \Delta/2$ within 0.5 Hz |
| Limiter | Drive a +12 dB sine through the limiter | $\max|y| \le 10^{-1/20} + 10^{-6}$ |
| Stability | 60 s render in every mode | No NaN or Inf; peak ≤ ceiling |
| Determinism | Two renders with the same seed | Bit-identical |
| Smoothness | Jump the master from 0 to 1 in the middle of a render | 1 ms RMS right after the change < 10% of the settled RMS; ≥ 80% by 300 ms |

## 3. Statistical tests

| Component | Test |
|---|---|
| Beta sampler | The mean of 20,000 draws from Beta(2, 5) is within 0.01 of 2/7 |
| Thompson bandit | With simulated rewards (one arm at 0.8, the rest at 0.4), the best arm is chosen in ≥ 70% of the last 200 of 500 rounds |
| Sign-flip test | Known pairs give an exact $p$ (e.g., all six differences positive gives $p = 2/64$) |
| Bootstrap CI | Covers the true mean in ≥ 85% of 200 simulated datasets (normal, $n = 12$). Percentile bootstraps under-cover slightly at small $n$; about 90% was observed. |
| RT task scoring | Lapses and false starts are counted correctly on synthetic sequences |

## 4. Running the tests

```bash
swift test
```

```bash
swift run bwrender --mode focus --seconds 20 --out build/focus.wav
```

```bash
python3 scripts/analyze_wav.py build/focus.wav
```

```bash
python3 scripts/qa_gate.py
```

## 5. Known limits

- The SwiftUI layer has no automated UI tests in the MVP. It is covered by the manual checklist; snapshot and UI tests are planned for roadmap M4.
- Listening comfort can only be judged by people listening. A blinded listening panel is planned for M4.

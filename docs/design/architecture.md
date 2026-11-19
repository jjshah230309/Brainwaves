# Technical Architecture

**Document:** D-04 · **Version:** 1.0 · **Date:** 2026-10-30

## 1. Overview

```
┌──────────────────────────── Brainwaves.app (macOS 14+, SwiftUI) ────────────────────────────┐
│  Views (Player, Mixer, Experimental, Self-Test, Evidence, Privacy)                          │
│        │ @Observable AppModel (main actor)                                                  │
│        ▼                                                                                    │
│  AudioEngine ── AVAudioEngine ── AVAudioSourceNode(render block) ──▶ mainMixer ──▶ output   │
│        │                               │ pulls frames                                       │
└────────┼───────────────────────────────┼────────────────────────────────────────────────────┘
         │ params (try-lock mailbox)     ▼
┌────────▼──────────────── BrainwavesCore (pure Swift + Foundation; macOS & Linux) ───────────┐
│ Engine: SessionRenderer · SessionParameters · ModePreset · Mode                             │
│ DSP:    NoiseGenerator · Biquad · Smoother · AmplitudeModulator · BinauralBeat · Limiter    │
│         Reverb · SeededRandom                                                               │
│ Music:  GenerativeComposer · Scale · PadVoice · BellVoice                                   │
│ Personalization: ThompsonBandit · BetaSampler · NOf1Experiment · ReactionTimeTask           │
│ Safety: ExposureMeter · VolumeCeiling · ClaimsPolicy · UserFacingCopy                       │
│ Storage: LocalStore (protocol) · JSONFileStore · UserData (Codable)                         │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
         ▲                                    ▲
   bwrender CLI (offline WAV)          XCTest suite (runs on Linux CI and macOS)
```

## 2. Key decisions

| Decision | Choice | Why |
|---|---|---|
| Build system | **Swift Package Manager**; `scripts/build-app.sh` assembles the `.app` bundle | No Xcode project needed; reproducible from the command line |
| UI | SwiftUI with `@Observable` (Observation framework) | Modern, declarative, accessible by default |
| Audio | `AVAudioEngine` + `AVAudioSourceNode` | Low-latency pull model; system mixer; follows device changes |
| Core portability | `BrainwavesCore` imports Foundation only | DSP and logic are testable on Linux CI; reusable for a future iOS app |
| Dependencies | None | Small supply-chain attack surface |
| Persistence | One JSON file in `~/Library/Application Support/Brainwaves/` | Transparent and easy to export or delete |
| Concurrency | Swift 5 language mode; main-actor UI; real-time render thread | Predictable; avoids Swift 6 strict-concurrency friction with the AVFoundation callback |

## 3. Real-time audio rules

The render block runs on a real-time thread. In `SessionRenderer.render`:

1. **No allocation.** Voice pools, reverb buffers and scratch arrays are allocated in `init` or when the sample rate changes, never during render.
2. **No blocking.** Parameter updates go through a *mailbox*. The UI thread writes new parameters under an `NSLock`, and the render thread calls `lock.try()`. If the lock is busy, the render thread keeps the previous parameters for that buffer, at most one buffer of latency (about 10 ms).
3. **No I/O, logging or Objective-C messaging.**
4. **Smooth parameter changes** (50 ms one-pole), so there are no clicks.
5. **Metering out.** Peak and RMS statistics are written into a fixed struct and read by the UI timer at 4 Hz with `try()`.

## 4. Parameter flow

```
User moves slider ─▶ AppModel.params (main) ─▶ AudioEngine.update(params)
                    ─▶ renderer.mailbox.post(params)  [lock]
Render thread ─▶ mailbox.take() [try-lock] ─▶ smoothers.setTarget(...) ─▶ per-sample DSP
```

## 5. Storage schema (v1)

```json
{
  "schemaVersion": 1,
  "settings": { "exposureMode": "adult", "calibrationOffsetDB": 100, "personalizationEnabled": true,
                "amTextureAllowed": false, "experimentalUnlocked": false },
  "sessions": [ { "id": "UUID", "mode": "focus", "armID": "darker", "start": "ISO-8601",
                  "durationSeconds": 1500, "overridden": false, "primaryRating": 4, "enjoymentRating": 5 } ],
  "bandit": { "focus": { "base": [1.0, 1.0] } },
  "experiments": [ ],
  "exposure": { "weekStart": "ISO-8601", "doseFraction": 0.12 }
}
```

Writes are atomic (`Data.write(options: .atomic)`). Unknown future versions are refused rather than overwritten.

## 6. Build without Xcode

```bash
swift build -c release --product BrainwavesApp
```

```bash
scripts/build-app.sh            # → build/Brainwaves.app (ad-hoc signed)
```

```bash
open build/Brainwaves.app
```

Requirements: the Command Line Tools for Xcode (`xcode-select --install`), which provide the Swift toolchain and the macOS SDK. Neither the Xcode IDE nor an `.xcodeproj` is needed.

## 7. Repository layout

| Path | Contents |
|---|---|
| `Sources/BrainwavesCore` | Portable engine and logic |
| `Sources/BrainwavesApp` | SwiftUI app (compiled on macOS only, via a conditional target in `Package.swift`) |
| `Sources/bwrender` | Offline renderer CLI |
| `Tests/BrainwavesCoreTests` | Unit, DSP and property tests |
| `scripts/` | Build, analysis and QA gate |
| `docs/` | Research and design |
| `qa/` | Reviews, corrections, approvals |
| `.claude/agents/qa-reviewer.md` | Independent QA agent |

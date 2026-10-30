# Brainwaves

**A free, open-source, evidence-honest background-sound app for macOS: focus, relaxation and sleep wind-down.**
SwiftUI · SwiftPM (no Xcode project) · fully on-device · MIT licence

> [!IMPORTANT]
> Brainwaves is a background-sound tool for comfort. It is **not a medical device** and does not diagnose, treat or prevent any condition. Effects of sound on attention and sleep are small and differ between people.

---

## Why this exists

Commercial "functional music" apps often describe their sound as scientifically engineered to change your brain state. We reviewed the evidence ([full report](docs/research/evidence-review.md)) and found the following:

| Finding | Certainty |
|---|---|
| Lyrics hurt reading and verbal memory; instrumental music is roughly neutral on average | Moderate |
| White or pink noise helps young people with ADHD a little on lab tasks, and slightly *hurts* others | Moderate |
| Music modestly reduces stress; slow breathing (about 6 breaths/min) supports relaxation | Moderate |
| Music may improve how well people with insomnia *feel* they slept | Moderate |
| Fast amplitude modulation ("neural phase locking") music aided attention in one company-linked study; not yet independently replicated | Low |
| Binaural beats and 40 Hz stimulation: inconsistent or contested evidence | Low to very low |

See also the claim-by-claim [audit of marketing claims](docs/research/brainfm-claims-audit.md).

**Brainwaves' answer:**
- generate pleasant, low-distraction, lyric-free sound;
- let each person find what works *for them*, with on-device learning and a personal A/B **self-test**;
- explain the evidence honestly, next to every feature.

## Features

| Area | What you get |
|---|---|
| Modes | **Focus** (generative instrumental music + optional noise), **Relax** (breathing-paced swells), **Sleep** (dark noise bed, long fade, volume cap) |
| Sound engine | Real-time procedural synthesis: pads, bass, FM-bell motifs, pink/brown/white noise, reverb, limiter. Deterministic seeds. No samples. |
| Optional | "Pulse texture" (amplitude modulation, 4–20 Hz), off by default |
| Experimental (opt-in) | Binaural beats (headphones), 40 Hz pulsing, each with an evidence card |
| Personalisation | Thompson-sampling bandit learning from your 1–5 ratings, on device |
| Self-test | Blinded, randomised A/B sessions with a 3-minute reaction-time game; exact permutation test and bootstrap interval, explained in plain language |
| Safety | Limiter at −1 dBFS, smoothed controls, estimated weekly listening dose (WHO-ITU H.870 approach), infant and epilepsy advisories |
| Privacy | No network code, no accounts, no analytics; one local JSON file with export and delete |
| Accessibility | VoiceOver labels, keyboard control, Dynamic Type, Reduce Motion, no flashing |

## Build and run (macOS 14+, no Xcode IDE needed)

Install the Command Line Tools once:

```bash
xcode-select --install
```

Build the app bundle:

```bash
scripts/build-app.sh
```

Launch it:

```bash
open build/Brainwaves.app
```

Run the tests (also works on Linux for the portable core):

```bash
swift test
```

Render audio offline:

```bash
swift run bwrender --mode focus --seconds 30 --out build/focus.wav
```

## Repository map

| Path | Contents |
|---|---|
| `docs/research/` | Evidence review, marketing-claims audit, verified bibliography |
| `docs/design/` | Product spec, audio generation, personalisation, architecture, privacy, accessibility, safety, testing, metrics, roadmap, legal |
| `Sources/BrainwavesCore/` | Portable DSP, composer, renderer, personalisation, safety, storage |
| `Sources/BrainwavesApp/` | SwiftUI macOS app |
| `Sources/bwrender/` | Offline WAV renderer |
| `Tests/` | Unit, signal and statistics tests |
| `.claude/agents/qa-reviewer.md` | Independent QA reviewer agent |
| `qa/` | QA rubric, process, review records, corrections log, approvals |
| `scripts/` | App bundler, WAV analysis, QA gate |

## Quality assurance

Every AI-generated artifact in this repository goes through an **independent QA review**. The review covers scientific accuracy, source quality, originality, legal compliance, security, usability, bias and completeness. Weak work is rejected, and every correction is documented before approval. Releases are blocked unless every governed file is approved at its current content hash. See [`qa/PROCESS.md`](qa/PROCESS.md).

## Licence

MIT. See [`LICENSE`](LICENSE). Product names mentioned in the research documents belong to their owners and are used only to identify the claims reviewed.

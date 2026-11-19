# Product Specification: Brainwaves

**Document:** D-01 · **Version:** 1.0 · **Date:** 2026-10-30 · **Status:** subject to QA approval

## 1. Summary

Brainwaves is a **free, open-source (MIT) macOS app**. It generates instrumental background audio in real time for focus, relaxation and sleep wind-down. It is designed around what the evidence supports (see [`../research/evidence-review.md`](../research/evidence-review.md)):

- low-salience, lyric-free generative music;
- adjustable noise colours;
- optional amplitude-modulation texture;
- breathing-paced relaxation swells;
- sleep fade-out timers;
- **honest, on-device personalisation**, including an n-of-1 self-test so each user can check whether a setting actually helps *them*.

> [!IMPORTANT]
> **Positioning.** Brainwaves is a *comfort and environment* tool, not a medical device. It makes no claim to treat ADHD, insomnia, anxiety or any other condition. All copy is checked by `ClaimsPolicy` and the QA gate.

## 2. Users and jobs to be done

| Persona | Need | What Brainwaves offers |
|---|---|---|
| Knowledge worker | Mask office noise; settle into deep work | Focus mode: instrumental generative music + optional pink noise + optional AM texture |
| Student | Study without distraction from lyrics | Lyric-free music, with a timer (e.g., 25/50 min) |
| Person with ADHD traits | Wants to try noise or AM, which shows small, mixed effects | Easy A/B self-test, with evidence explained honestly |
| Stressed user | Wind down | Relax mode with swells at ~6 breaths/min |
| Light sleeper | Mask night noise at a safe level | Sleep mode: brown or pink noise + slow drone, volume cap, fade-out |

## 3. Functional requirements (MVP)

| ID | Requirement | Priority |
|---|---|---|
| FR-1 | Three modes (Focus, Relax, Sleep) with evidence-informed defaults | Must |
| FR-2 | Real-time procedural audio with no network and no bundled audio files | Must |
| FR-3 | Mixer: music level, noise colour and level, brightness, tempo | Must |
| FR-4 | Session timer with fade-out (5–120 min, or open-ended) | Must |
| FR-5 | Optional AM texture (rate 4–20 Hz, depth 0–0.5); off for new users | Must |
| FR-6 | Experimental section: binaural beats and 40 Hz AM; opt-in, headphone confirmation, evidence card | Should |
| FR-7 | Post-session rating (focus or calm, and enjoyment; 1–5) | Must |
| FR-8 | On-device personalisation (Thompson-sampling bandit) | Should |
| FR-9 | n-of-1 self-test: blinded A/B with a reaction-time task and plain-language result | Should |
| FR-10 | Safety: output limiter, volume ceiling, listening-dose meter, sleep-mode cap | Must |
| FR-11 | Privacy: local JSON store, export, delete-all, no telemetry | Must |
| FR-12 | Accessibility: VoiceOver, keyboard control, Dynamic Type, Reduce Motion, no flashing | Must |
| FR-13 | Offline renderer CLI (`bwrender`) for testing and research | Must |

## 4. Non-functional requirements

| ID | Requirement | Target |
|---|---|---|
| NFR-1 | CPU load during playback | < 5% of one core on Apple silicon |
| NFR-2 | Audio glitches | 0 under normal load (no allocation and no blocking in the render path) |
| NFR-3 | Output peak | ≤ −1 dBFS (limiter ceiling) |
| NFR-4 | Start latency | < 300 ms from pressing play to sound |
| NFR-5 | Platform | macOS 14+, built with SwiftPM (no Xcode project) |
| NFR-6 | Licence | MIT; no third-party runtime dependencies |

## 5. Out of scope (MVP)

- Accounts, cloud sync and any kind of analytics.
- Closed-loop EEG sleep stimulation (not feasible without hardware, and evidence is declining [@harlow2023]).
- Clinical or diagnostic features.
- iOS (see roadmap).

## 6. Related design documents

| Topic | Document |
|---|---|
| Audio generation | [`audio-generation.md`](audio-generation.md) |
| Personalisation and self-test | [`personalization.md`](personalization.md) |
| Architecture | [`architecture.md`](architecture.md) |
| Privacy | [`privacy.md`](privacy.md) |
| Accessibility | [`accessibility.md`](accessibility.md) |
| Safety | [`safety.md`](safety.md) |
| Testing | [`testing.md`](testing.md) |
| Success metrics | [`metrics.md`](metrics.md) |
| Roadmap | [`roadmap.md`](roadmap.md) |
| Legal and licensing | [`legal.md`](legal.md) |

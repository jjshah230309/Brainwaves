# MVP Roadmap

**Document:** D-10 · **Version:** 1.0 · **Date:** 2026-10-30

## 1. Milestones

| Milestone | Scope | Exit criteria | Status |
|---|---|---|---|
| **M0: Evidence and governance** | Literature review, claims audit, design docs, QA agent and gate | QA approval recorded for every research and design document | ✅ In this release |
| **M1: Core engine** | DSP, composer, three modes, limiter, `bwrender` CLI, signal tests | `swift test` passes; signal criteria in `testing.md` met | ✅ In this release |
| **M2: SwiftUI MVP** | Player, mixer, timer, modes, experimental opt-in, evidence cards, privacy screen | `.app` built in macOS CI; manual smoke test | ✅ Code in this release; ⏳ manual test on a Mac outstanding |
| **M3: Personalisation** | Thompson bandit, ratings, n-of-1 self-test with reaction-time task | Statistical tests pass; plain-language results reviewed by QA | ✅ Core; 🟨 UI basic |
| **M4: Release hardening** | Accessibility audit, listening panel, App Sandbox, Developer ID signing and notarisation, UI tests, localisation | Accessibility checklist complete; QA release approval; legal review of patent risk | ⏳ Planned |
| **M5: Beyond the MVP** | iOS/iPadOS app reusing the Core; Shortcuts and Focus-mode integration; preregistered community study protocol | Ethics review for any study | ⏳ Planned |

## 2. Release checklist (v1.0)

- [ ] `swift test` is green on Linux and macOS.
- [ ] `python3 scripts/qa_gate.py --release` is green: every governed file is approved at its current hash.
- [ ] The accessibility checklist is complete.
- [ ] A listening panel (n ≥ 5) finds no harsh or fatiguing artefacts.
- [ ] Counsel has reviewed the patent risk (see [`legal.md`](legal.md)).
- [ ] Developer ID signing and notarisation are done. Until then, users build from source or run an ad-hoc-signed build.

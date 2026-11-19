# Contributing to Brainwaves

Thank you for helping. Brainwaves aims to be **honest, safe and private**, and contributions are judged on those values first.

## Ground rules

1. **Evidence before claims.** Any statement about effects on attention, sleep, mood or the brain needs a peer-reviewed source added to `docs/research/bibliography.md`, with its DOI and independence flag. Mechanism (for example, "the brain follows the rhythm") must be kept separate from outcome (for example, "you focus better").
2. **No medical claims.** User-facing copy belongs in `UserFacingCopy.swift` and must pass `ClaimsPolicy`.
3. **No network code and no telemetry.** CI rejects them.
4. **Real-time safety.** Nothing in `SessionRenderer.render` may allocate, block, log or do I/O.
5. **Accessibility is required.** Every control needs an accessibility label and keyboard access, and must respect Reduce Motion.
6. **AI-generated contributions** must go through the QA process in `qa/PROCESS.md` before they are marked approved.

## Development

```bash
swift test
```

```bash
swift run bwrender --mode relax --seconds 20 --out build/relax.wav
```

```bash
python3 scripts/qa_gate.py
```

```bash
scripts/build-app.sh
```

## Code style

Follow the existing code: Swift API Design Guidelines, short doc comments that explain *why*, and the `// SPDX-License-Identifier: MIT` header on every source file.

## Conduct

See `CODE_OF_CONDUCT.md`.

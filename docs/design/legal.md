# Legal and Licensing Considerations

**Document:** D-11 · **Version:** 1.0 · **Date:** 2026-10-30

> [!CAUTION]
> **This is not legal advice.** It records engineering-level risk identification for an open-source project. A qualified patent attorney should review it before any public binary release (roadmap M4).

## 1. Licence

- **Code:** MIT (see `LICENSE`).
- **Generated audio:** produced at run time by the user's own copy of the software. The project claims no rights in audio the user renders. The MIT licence covers the code.
- **Dependencies:** none, so there are no licence-compatibility issues.

## 2. Trademarks

| Rule | Enforcement |
|---|---|
| "Brain.fm" and other product names appear only in research documents, as nominative references needed to identify the claims under review | `qa_gate.py` fails if "brain.fm" or "brainfm" appears anywhere in `Sources/` |
| No competitor logos, trade dress or slogans | QA review |
| The project name "Brainwaves" is a common descriptive term. Clear it with a trademark search before any store listing. | M4 checklist |

## 3. Patents: risk identification

Brain.fm (BrainFM Inc) holds US patents on modulating audio to produce neural stimulation. Examples include US 11,205,414 B2 (granted 2021, expected expiry about 2040) [@pat-us11205414] and US 7,674,224 B2 [@pat-us7674224]. Search results also list related grants (e.g., US 11,957,467 and US 11,966,661). Their exact claims were **not** verified in this review.

| Factor | Assessment |
|---|---|
| Open source is **not** an exemption | Making, using or distributing software that practises a patented claim can infringe, even when it is free |
| Prior art for amplitude modulation | Tremolo (periodic amplitude modulation) has been a standard musical effect for decades, in instrument amplifiers and electronic organs. Isochronic tones and AM "brainwave" audio also predate the 2019 priority date. |
| Claim scope matters | Granted claims are usually much narrower than the general idea. For example, US 11,205,414's description concerns modulating selected frequency ranges tied to cochlear regions and arranging them into a composition. Whether a simple full-band tremolo on a music bus falls within any claim can only be decided by claim-by-claim analysis. |
| **Design choices that reduce risk** (not guarantees) | (1) AM is a generic, user-controlled tremolo on the whole music bus, not selective modulation of a frequency band. (2) It is off by default. (3) It is not adapted to the beat structure of the music. (4) It is not marketed as neural stimulation. (5) The code is isolated in `AmplitudeModulator.swift`, so it can be removed by a build flag if counsel advises. |
| Action | Before v1.0: a freedom-to-operate review of the Brain.fm patent family by counsel. If any risk is found, ship with AM compiled out (`-D BRAINWAVES_NO_AM`). |

## 4. Health and consumer-protection law

- **Medical device regulation.** The app is positioned as a general-wellness and comfort tool with no disease claims. Disease claims, such as treating ADHD or insomnia, could bring it under medical-device rules in the US, UK or EU. `ClaimsPolicy` enforces this.
- **Advertising standards.** Under FTC rules, and under ASA/CAP rules in the UK, objective claims need substantiation. Our copy describes the sound and what the evidence shows, not outcomes.

## 5. Content originality

All research text and code in this repository were written for this project. Quotations from third-party pages are short, attributed and used for criticism or review. The QA reviewer checks originality, looking for verbatim copying beyond short quotations.

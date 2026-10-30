# Brain.fm Claims Audit: Marketing vs. Evidence

**Document:** Research report R-02 · **Version:** 1.0 · **Date:** 2026-10-30
**Purpose:** Test each public claim against independent, peer-reviewed evidence.
**Fairness note:** Brain.fm is named here only to identify the claims under review (nominative use). This audit makes no allegation of bad faith. It compares the wording of each claim with what the evidence shows. Claims are quoted from company pages accessed on 2026-10-30 [@brainfm-science; @brainfm-blog-works].

## Verdict scale

| Verdict | Meaning |
|---|---|
| ✅ **Supported** | Consistent independent evidence of at least moderate certainty |
| 🟩 **Partially supported** | True in a narrow sense; the wording goes beyond the evidence |
| 🟨 **Plausible but unproven** | Some evidence, but company-linked, unreplicated or low certainty |
| 🟧 **Unsupported** | No evidence cited or found |
| 🟥 **Contradicted** | Independent evidence points the other way |

## Executive summary

> [!IMPORTANT]
> Of the **12 claims** audited:
> - **0** are fully supported by independent evidence of at least moderate certainty;
> - **4** are partially supported;
> - **3** are plausible but unproven;
> - **4** are unsupported;
> - **1** is contradicted as worded, in that it states as fact that ordinary music makes focus worse.
>
> The company's *strongest* evidence is real and peer reviewed [@woods2024]. However, the marketing describes what one company-linked study observed as a settled mechanism ("shift your brain state").

## Claim-by-claim audit

| # | Claim (verbatim or close paraphrase) | Source | Evidence | Independence | Verdict |
|---|---|---|---|---|---|
| C1 | "Brain.fm contains patterns that shift your brain state with entrainment." | [@brainfm-science] | The brain does phase-lock to AM envelopes [@woods2024; @picton2003]. "Brain state shift" toward better cognition is not shown, and steady-state responses may be evoked responses rather than entrainment [@novembre2018]. | Mechanism: Ind. Product: COI | 🟩 Partially supported |
| C2 | "Holds patents on technology to elicit strong neural phase locking." | [@brainfm-science] | The patents exist [@pat-us11205414]. A patent shows a claimed invention, not an effect. Phase locking was measured in one company-linked EEG study ($n = 40$) [@woods2024]. | COI | 🟩 Partially supported (true patents; "strong" rests on one company-linked study) |
| C3 | "Our experiments always include a control ('placebo') of the same music without Brain.fm technology." | [@brainfm-science] | Matches the main paper's design [@woods2024]. Unmodulated music is an *active* control, not a placebo in the clinical sense, because participants are not blinded to how the music sounds. | COI | 🟩 Partially supported (control exists; "placebo" overstates the blinding) |
| C4 | "Binaural beats produce weak neural synchrony." | [@brainfm-science] | Independent systematic review: entrainment evidence is inconsistent (5 of 14 studies supportive) [@ingendoh2023; @chaieb2015]. | Ind | 🟩 Partially supported. "Inconsistent" is more accurate than "weak". |
| C5 | The Brain.fm method "has much stronger effects on brain activity" than binaural beats. | [@brainfm-science] | No head-to-head study of AM music versus binaural beats was found. | — | 🟧 Unsupported (no direct comparison) |
| C6 | "Most music in the world is designed to grab your attention, which leads to distraction." | [@brainfm-science] | Lyrics distract [@vasilev2018]. Instrumental music has about zero average effect [@kampfe2011]. Not all music distracts. | Ind | 🟨 Plausible but unproven (true for lyrics; overgeneralised) |
| C7 | Helps you "get into a concentrated state faster and stay there longer." | [@brainfm-blog-works] | No onset-latency or duration outcomes were found in the cited paper. The behavioural benefit in Experiment 1 was a *primacy* effect [@woods2024]. | COI | 🟧 Unsupported |
| C8 | "The biggest gains in sustained attention showed up in participants who scored highest on an ADHD symptom scale." | [@brainfm-blog-works] | Accurately reflects the reported interaction ($p = 0.048$). Based on self-report ASRS, not diagnosis, and not replicated [@woods2024]. | COI | 🟨 Plausible but unproven |
| C9 | Music that "many people with ADHD rely on." | [@brainfm-blog-works] | No usage data cited. A popularity claim, not an efficacy claim. | — | 🟧 Unsupported (no data) |
| C10 | "Ordinary music tends to make things worse." | [@brainfm-blog-works] | Independent meta-analyses: instrumental music ≈ neutral, lyrical music mildly harmful [@kampfe2011; @vasilev2018]. As a general statement, this is contradicted for instrumental music. | Ind | 🟥 Contradicted as worded |
| C11 | Focus music filters "high frequencies that tend to grab attention"; sleep music uses "spatial motion to create a gentle rocking sensation." | [@brainfm-blog-works] | Design descriptions. No outcome evidence was cited or found for these specific features. | — | 🟧 Unsupported (as efficacy claims) |
| C12 | "Supported by the National Science Foundation." | [@brainfm-science] | NSF STTR award 1720698 is acknowledged in the paper [@woods2024]. Grant funding shows that a project was judged worth funding, not that the product works. | Ind (funder record) | 🟨 Plausible but unproven (accurate as a funding fact; implies more than funding shows) |

> [!NOTE]
> **Corrections to the record.** After publication, the paper's competing-interests statement was corrected to disclose that two authors were Brain.fm employees with equity and that Brain.fm produced the test music [@woods2024]. Readers of the original version would not have seen this.

## Patterns to avoid in our own product copy

| Marketing pattern | Why it misleads | Our rule |
|---|---|---|
| Mechanism-as-proof ("phase locking" → "focus") | A brain response is not the same as a benefit | Describe the sound, not the brain |
| A patent used as credibility | Patents do not test efficacy | Never cite patents as evidence |
| "Placebo-controlled" without blinding | Suggests clinical rigour | Use "matched control" |
| Subgroup results presented as general | The effect appeared mainly in high-ASRS listeners | State who was studied |
| Comparison with no head-to-head data | Invented superiority | No comparative claims |

These rules are enforced in code by `ClaimsPolicy` (`Sources/BrainwavesCore/Safety/ClaimsPolicy.swift`) and in CI by `scripts/qa_gate.py`.

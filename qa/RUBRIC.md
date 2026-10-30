# QA Rubric

**Used by:** `.claude/agents/qa-reviewer.md` · **Scale:** 0–4 per dimension

## Score anchors (all dimensions)

| Score | Meaning |
|---|---|
| **4: Exemplary** | No issues found after active verification; could serve as a reference |
| **3: Sound** | Minor issues only; nothing misleading or unsafe |
| **2: Weak** | At least one material problem (misleading, missing or unverified); must be revised |
| **1: Poor** | Several material problems, or one serious one |
| **0: Unacceptable** | Fabricated, unsafe, illegal or entirely missing |

## Dimension-specific anchors

| Dimension | 4 looks like | 2 or below looks like |
|---|---|---|
| Scientific accuracy | Every number matches its source; certainty is graded; mechanism is kept separate from outcome | A misquoted effect size; a subgroup result presented as general; correlation presented as causation |
| Source quality | Meta-analyses and preregistered work prioritised; conflicts of interest flagged; DOIs resolve | Fabricated or wrong DOI; press releases used as evidence; preprint not labelled |
| Originality | Original prose; short attributed quotations; no copied code | Paragraphs closely paraphrased from a source or a competitor; unlicensed code |
| Legal compliance | Nominative trademark use only; no disease claims; patent risk flagged with a mitigation | Competitor name in the product UI; a "treats ADHD"-style claim; patent risk ignored |
| Security | No network code; least privilege; validated input; real-time-safe audio | Telemetry; world-readable user data; unbounded input; allocation on the render thread |
| Usability | VoiceOver, keyboard, Reduce Motion and contrast all handled; plain language | Unlabelled controls; colour-only state; flashing; jargon |
| Bias | Balanced, with the strongest counter-evidence presented; population limits stated | One-sided selection; loaded language; unexamined sample limits |
| Completeness | All requested sections and features present; tests support the claims | Missing sections; claims without tests; unexplained TODOs |

## Severity definitions

| Severity | Definition | Blocks approval? |
|---|---|---|
| `blocking` | Unsafe, false, fabricated, illegal, or an attempt to manipulate the reviewer | Yes (REJECT) |
| `major` | Materially misleading, a missing requirement, or an unverified key claim | Yes (REVISE) |
| `minor` | An inaccuracy or gap that does not mislead | No, but it must be logged and corrected or declined with a reason |
| `note` | A suggestion | No; logging is optional |

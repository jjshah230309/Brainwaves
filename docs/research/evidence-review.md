# Functional Audio: Evidence Review

**Document:** Research report R-01 · **Version:** 1.0 · **Date:** 2026-10-30
**Scope:** Brain.fm's published science, and the independent peer-reviewed evidence on functional music, auditory stimulation, attention, relaxation, sleep, neural entrainment and productivity.
**Status:** Must be approved by the independent QA reviewer before release. See `qa/approvals.json`.

---

## 1. Executive summary

> [!IMPORTANT]
> **Bottom line.** Sound can change how alert, calm and comfortable people feel, and in some groups it changes performance on lab attention tasks a little. The evidence **does not** support claims that any audio product reliably "steers your brain into" a focus, relaxation or sleep state for listeners in general. The most reliable findings are modest and depend on context:
> 1. **Lyrics hurt reading and verbal memory.** Instrumental music is roughly neutral on average [@vasilev2018; @souza2023; @salame1989].
> 2. **White or pink noise gives a small benefit on lab attention tasks for young people with ADHD or high ADHD symptoms, and a small *harm* for those without** [@nigg2024].
> 3. **Music interventions reduce self-reported and physiological stress** by a small-to-moderate amount [@dewitte2020].
> 4. **Music may improve *subjective* sleep quality in adults with insomnia** [@jespersen2022].
> 5. **Rhythmic sound produces measurable, frequency-following brain responses** (steady-state responses). That these responses improve thinking is a separate claim, and it is largely unproven [@picton2003; @nozaradan2011; @novembre2018].

> [!WARNING]
> **The core claim behind Brain.fm** is that its amplitude-modulated (AM) music improves sustained attention. That claim rests mainly on **one company-linked paper** [@woods2024]. The paper is peer reviewed and genuinely informative. However, its behavioural effects depended on presentation order and ADHD-symptom score, its online samples had high exclusion rates, it does not appear to have been preregistered, and the competing-interests statement was corrected after publication to disclose Brain.fm employment and equity. Independent replication had not been found as of this review's date.

### Evidence-strength summary

| # | Question | Best independent estimate | Certainty* | Practical meaning |
|---|---|---|---|---|
| 1 | Does background music help cognition in general? | Global effect ≈ null; specific effects cancel out [@kampfe2011] | Moderate | No reason to expect a general boost |
| 2 | Does music with lyrics hurt reading? | $d \approx -0.35$ for lyrical music; ≈ 0 for instrumental [@vasilev2018] | Moderate | Avoid lyrics for reading or writing |
| 3 | Does white or pink noise help attention in ADHD? | $g = 0.249,\ 95\%\ \text{CI}\ [0.135, 0.363]$ for ADHD; $g = -0.212\ [-0.355, -0.069]$ for non-ADHD [@nigg2024] | Moderate (GRADE, per authors) | Small; helps some people, hurts others |
| 4 | Do binaural beats improve cognition, anxiety or pain? | $g = 0.45$ pooled [@garciaargibay2019]; EEG entrainment inconsistent (5 of 14 studies supportive) [@ingendoh2023] | Low | Possible small effects; mechanism unclear |
| 5 | Does beta-rate AM music improve sustained attention? | Order- and moderator-dependent effects; one three-way interaction at $p = 0.048$ [@woods2024] | Low (one company-linked source) | Plausible; needs independent replication |
| 6 | Does 40 Hz stimulation improve cognition? | Mouse results contested [@iaccarino2016; @soula2023]; human pilot $n = 15$ [@chan2022] | Very low (for healthy users) | Experimental only |
| 7 | Does music reduce stress? | $d = 0.380$ physiological; $d = 0.545$ psychological; 104 RCTs [@dewitte2020] | Moderate | Reliable, modest |
| 8 | Does music help insomnia? | Better subjective sleep quality; insomnia severity unclear [@jespersen2022] | Moderate (quality) / very low (severity) | Reasonable for wind-down |
| 9 | Does acoustic stimulation in deep sleep boost memory? | Small, trend-level [@wunderlin2021]; effect declined over time and measurement reliability ≈ 0 [@harlow2023] | Low | Needs closed-loop EEG; not feasible in a consumer app |
| 10 | Does slow (~6 breaths/min) paced breathing relax? | Consistent HRV and self-report changes [@zaccaro2018; @lehrer2014] | Low–moderate | Good basis for a guided-breathing relax mode |

\*Certainty uses a GRADE-style scale (High / Moderate / Low / Very low). Where the source review reported its own GRADE rating, that rating is used. Otherwise it is this review's judgement, and it is marked down for single-source, non-independent, unpreregistered or heterogeneous evidence.

---

## 2. Method

| Step | What was done |
|---|---|
| Search | Targeted searches of PubMed/PMC, Crossref, publisher sites and Google Patents (October 2026) for meta-analyses, systematic reviews and pivotal experiments in each domain. Company pages were read directly. |
| Priority | Preregistered meta-analyses and Cochrane reviews first, then other systematic reviews, then single experiments. Company-funded work was kept but flagged. |
| Verification | Every DOI was resolved in Crossref, with author, year and title matched (see `bibliography.md`). Statistics were taken from abstracts or full texts, not from press coverage. |
| Grading | GRADE-style certainty, plus separate flags for **independence**, **preregistration**, **sample size** and **effect size**. |
| Limitations of this review | This is a rapid, targeted review, not a full PRISMA systematic review. It has a single reviewer pipeline, with an independent QA check. Some full texts were paywalled, so abstract-level figures were used and are marked as such. |

**Effect-size conventions.** Standardised mean differences are Cohen's $d$ or Hedges' $g$, where

$$
g = J \cdot \frac{\bar{x}_1 - \bar{x}_2}{s_p}, \qquad J = 1 - \frac{3}{4(n_1+n_2) - 9}.
$$

As rough benchmarks, $|g| \approx 0.2$ is small, $0.5$ moderate and $0.8$ large. Small lab effects often shrink in real-world use.

---

## 3. Brain.fm's own science

### 3.1 What the company claims

On its science page, Brain.fm states that its music "contains patterns that shift your brain state with entrainment". It also says it "holds patents on technology to elicit strong neural phase locking", that "binaural beats produce weak neural synchrony", that its experiments "always include a control ('placebo') of the same music without Brain.fm technology", and that it is "supported by the National Science Foundation" [@brainfm-science]. A company blog post adds that the music "helps you get into a concentrated state faster and stay there longer" [@brainfm-blog-works]. The claim-by-claim audit is in [`brainfm-claims-audit.md`](brainfm-claims-audit.md).

### 3.2 The core paper: Woods et al. 2024

*Communications Biology* 7:1376 [@woods2024]. This is a revised version of a 2019 preprint [@woods2019].

| Experiment | $n$ (analysed) | Sample | Design | Key result |
|---|---|---|---|---|
| 1A | 62 | MTurk | Valence and arousal ratings of tracks | Tracks differed in valence and arousal |
| 1B | 83 (of 160 recruited; 52% passed screening) | MTurk | SART; AM music vs. unmodulated control music vs. pink noise; counterbalanced | Benefit of AM music **only when it was heard first** (primacy effect) |
| 2 | 34 | Undergraduates | fMRI during SART | More activation in attention-related areas with AM music; group × condition interaction **not significant** at whole-brain level |
| 3 | 40 | Undergraduates | 64-channel EEG | Stronger stimulus–brain phase locking at modulation rates (e.g., 16 Hz) |
| 4A/4B | 175 (of 221 recruited) | MTurk | AM rate 8, 16 or 32 Hz (4A); depth low, medium or high (4B) | Rate × block × ASRS interaction $F(1,80) = 4.03,\ p = 0.048,\ \eta_p^2 = 0.048$: 16 Hz helped high-ASRS listeners most. **Depth: no significant effects.** |

Funding: NSF STTR award 1720698.

> [!NOTE]
> **Strengths.**
> - The control is well matched: the same music without the added modulation.
> - It converges behaviour, fMRI and EEG.
> - It targets an important population (people with attentional difficulties).
> - It was published in a peer-reviewed Nature Portfolio journal.

> [!CAUTION]
> **Weaknesses that limit how far the results generalise.**
> 1. **Conflict of interest.** Two authors were Brain.fm employees with equity, and the company produced the test music. The original statement said "no competing interests"; it was later corrected [@woods2024].
> 2. **Fragile behavioural effects.**
>    - The Experiment 1 benefit depended on presentation order.
>    - The key Experiment 4 result is a three-way interaction at $p = 0.048$.
>    - The depth manipulation produced nothing, although a dose–response relationship would be expected if the mechanism were simple.
> 3. **Measurement.** ADHD status was based on a self-report screener (ASRS), not a clinical diagnosis.
> 4. **No preregistration** is mentioned. Many analytic choices were made across many experiments, which increases the risk of false positives.
> 5. **Neural ≠ cognitive.** Phase locking to an amplitude envelope is an expected sensory response [@picton2003]. Showing it exists does not show that it *causes* better attention [@novembre2018].
> 6. **No independent replication** was found.

**Verdict.** This is credible preliminary evidence that adding beta-range AM to music *can* help some listeners with attentional difficulties on a lab vigilance task. It is **not** evidence that the commercial product improves focus or productivity for listeners in general.

### 3.3 Patents

Brain.fm's patents describe modulating parts of an audio signal to produce neural stimulation [@pat-us11205414; @pat-us7674224]. A patent is a legal claim to a method. **It is not evidence of efficacy**, and patent examiners do not assess clinical benefit. The legal implications for this project are covered in `docs/design/legal.md`.

---

## 4. Independent evidence by domain

### 4.1 Background music and cognition

- **General effect is near zero.** A meta-analysis found a null global effect of background music on adult performance. The authors argue that specific positive and negative effects cancel out [@kampfe2011].
- **Lyrics distract.** Background speech and music reliably impair reading [@vasilev2018]. Its meta-regression puts lyrical music at about $d = -0.35$ and instrumental music at about $0$ (moderator figures as summarised in [@souza2023]; overall effect $d \approx -0.19$). A within-subjects experiment found that lyrics impaired verbal memory, visual memory and reading by $d \approx -0.3$ [@souza2023]. This fits the classic *irrelevant sound effect*, in which vocal music disrupts phonological short-term memory [@salame1989]. Liking the music does not protect against this [@perham2014].
- **Arousal and mood explain the "Mozart effect".** The spatial-task benefit disappears once arousal and mood are controlled for [@thompson2001]. A meta-analysis of about 40 studies found little evidence for any specific Mozart effect [@pietschnig2010].
- **Workplace.** A small field study of software developers reported better mood and self-rated work quality with self-chosen music [@lesiuk2005]. It was small, with a within-person on/off (ABA) design rather than randomised conditions, and its outcomes were self-reported.

> [!TIP]
> **Design implication.** Use no lyrics and no speech. Keep salience low, with no sudden events. Let the user control the arousal level (tempo, brightness), because the right level differs from person to person.

### 4.2 Noise colours and attention

- The **moderate brain arousal** model predicts that people with low baseline arousal (for example, with ADHD) benefit from added noise, through a process like stochastic resonance [@soderlund2007].
- A **preregistered meta-analysis** found white or pink noise improved task performance in youth with ADHD or elevated symptoms, with $g = 0.249\ [0.135, 0.363]$ across 13 studies. It **hurt** comparison participants without ADHD, with $g = -0.212\ [-0.355, -0.069]$ across 11 studies [@nigg2024]. **No eligible studies of brown noise** were found.

> [!WARNING]
> Claims online that "brown noise helps ADHD" have **no direct controlled evidence** behind them. Noise is not a one-size-fits-all focus aid, because the average effect is *negative* for people without ADHD.

### 4.3 Binaural beats, monaural beats and isochronic tones

- A meta-analysis of 22 studies (35 effect sizes) reported a pooled $g = 0.45$ for memory, attention, anxiety and pain. The effect was moderated by frequency, exposure length and timing, and adding a noise mask made no difference [@garciaargibay2019].
- A systematic review of EEG entrainment found 5 studies supporting the entrainment hypothesis, 8 contradicting it and 1 mixed. The authors note large methodological heterogeneity [@ingendoh2023]. An earlier review reached a similar conclusion, describing the findings as often contradictory [@chaieb2015].
- **Isochronic tones** (pulsed tones) have very little dedicated controlled research. Functionally they are a form of deep amplitude modulation.

**Interpretation.** Behavioural effects may exist, but they are inconsistent. The claimed mechanism of entraining brainwaves to the beat frequency is **not** reliably shown. Binaural beats also require headphones.

### 4.4 Neural entrainment and steady-state responses

- The auditory system follows amplitude envelopes. This produces **auditory steady-state responses** that are strongest around 40 Hz and are used clinically for hearing assessment [@picton2003].
- EEG frequency-tagging shows responses at beat and meter frequencies in music [@nozaradan2011]. These responses may reflect a series of evoked responses rather than true oscillatory entrainment [@novembre2018].

> [!IMPORTANT]
> **Key distinction.** It is well established that the brain **responds at** a stimulus rate. It is **unproven** that this response **improves cognition**. Marketing often blurs the two. In a sentence like "neural phase locking", the first half (*the brain locks*) is true, and the implied second half (*so you focus better*) needs separate evidence.

### 4.5 40 Hz ("gamma") stimulation

- In Alzheimer's model mice, 40 Hz light flicker, and later combined light and sound, was reported to reduce amyloid [@iaccarino2016; @martorell2019].
- An independent group **failed to replicate** native gamma entrainment or amyloid reduction with 40 Hz light in mice [@soula2023].
- In humans, a small pilot RCT ($n = 15$, mild Alzheimer's) of daily 40 Hz audiovisual stimulation reported that it was safe and showed exploratory benefits. The authors had commercial conflicts [@chan2022].
- **No evidence** supports 40 Hz audio for focus or productivity in healthy adults.

### 4.6 Sleep

- **Music for insomnia.** A Cochrane review concluded that music may improve subjective sleep quality in adults with insomnia symptoms. It found no clear effect on insomnia severity (2 studies, $n = 63$, very low certainty) and no reported adverse events [@jespersen2022].
- **Acoustic stimulation in slow-wave sleep.** Clicks of pink noise timed to slow-oscillation up-states enhanced slow oscillations and memory [@ngo2013]. Meta-analyses found small, trend-level memory effects [@wunderlin2021]. The effect has *declined* across studies since 2013, and the memory outcome has near-zero test–retest reliability ($r = 0.01$) [@harlow2023]. This method needs **real-time EEG** and is **not** achievable with a playlist or continuous noise.
- **Safety.** Infant sleep machines can exceed recommended sound levels [@hugh2014] (see §5).

### 4.7 Stress, relaxation and breathing

- Across 104 RCTs, music interventions reduced stress, with $d = 0.380$ on physiological outcomes and $d = 0.545$ on psychological outcomes. The largest physiological effect was on heart rate [@dewitte2020].
- Slow breathing (below 10 breaths/min) is linked to higher heart-rate variability and to self-reported relaxation [@zaccaro2018]. Resonance-frequency breathing, about 6 breaths/min for many adults, is the basis of HRV biofeedback [@lehrer2014].

### 4.8 Productivity

Apart from small or self-reported field studies [@lesiuk2005], **no controlled evidence** was found that any functional-audio product improves real-world productivity. Lab vigilance tasks such as the SART are not the same as knowledge work.

---

## 5. Safety findings relevant to design

| Risk | Evidence | Design control |
|---|---|---|
| Noise-induced hearing loss | WHO-ITU H.870 sets a weekly allowance equivalent to 80 dBA for 40 h per week for adults, and 75 dBA for children or sensitive users [@who-h870] | Output ceiling, a listening-dose meter and gentle default levels |
| Infants | Sleep machines can exceed 50 dBA nursery limits, and some exceed 85 dBA at 30 cm [@hugh2014] | "Not for infants" notice, a sleep-mode volume cap and a sleep timer |
| Photosensitive seizures | Flashing visuals are a known risk [@wcag22] | No flashing visuals at all; animation honours Reduce Motion |
| ADHD medical claims | Small, mixed effects [@nigg2024; @woods2024] | No claims to treat, cure or substitute for treatment |
| Lyrics or salient events | Distraction [@vasilev2018] | Instrumental only, with smooth envelopes |

---

## 6. Implications for an open-source alternative

| Finding | Product decision |
|---|---|
| The right arousal level differs between people [@thompson2001; @nigg2024] | Personalise through user feedback, not fixed "brain states" |
| Lyrics distract [@vasilev2018] | Generate instrumental, low-salience music only |
| The AM benefit is plausible but unreplicated [@woods2024] | Make AM an *adjustable texture* (off by default for new users, with rate and depth exposed) and test it with the **n-of-1 self-test** |
| Binaural beats and 40 Hz have weak or contested evidence [@ingendoh2023; @soula2023] | Opt-in **Experimental** section with an in-app evidence card |
| Music and slow breathing reduce stress [@dewitte2020; @zaccaro2018] | Relax mode with swells paced to breathing |
| Music may help subjective sleep [@jespersen2022]; closed-loop stimulation is not feasible [@harlow2023] | Sleep mode = wind-down audio + fade-out timer; **no** claims about memory or deep sleep |
| Effects are small and individual | The app tells users plainly that it may not work for them, and offers a self-test |

---

## 7. Research gaps

1. Independent, preregistered replication of beta-rate AM music benefits, ideally with clinically diagnosed ADHD samples.
2. Dose–response data for modulation depth and rate.
3. Real-world productivity outcomes rather than lab vigilance tasks.
4. Long-term use: habituation, and whether effects persist.
5. Controlled studies of brown noise.
6. Standardised stimulation protocols for binaural-beat research [@ingendoh2023].

---

*Source details, DOIs and independence flags: [`bibliography.md`](bibliography.md). Claim-by-claim audit: [`brainfm-claims-audit.md`](brainfm-claims-audit.md).*

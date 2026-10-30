# Personalisation and the n-of-1 Self-Test

**Document:** D-03 · **Version:** 1.0 · **Date:** 2026-10-30 · **Implementation:** `Sources/BrainwavesCore/Personalization`

## 1. Why personalise

Effects of sound on attention vary between people and can reverse direction. Noise helps youth with ADHD on average but hurts others [@nigg2024], and arousal effects depend on the individual [@thompson2001]. A fixed "best setting" for everyone is therefore not justified. Instead, Brainwaves learns **from each user's own feedback, on their own device**.

> [!NOTE]
> All learning happens locally. No data leaves the Mac (see [`privacy.md`](privacy.md)).

## 2. Preference learning: Thompson-sampling bandit

**Arms.** Each mode has a small set of *variants*: discrete changes to the mode defaults. The MVP uses six per mode:

| Arm | Change from default |
|---|---|
| `base` | none |
| `brighter` | brightness × 1.4 |
| `darker` | brightness × 0.65 |
| `more-noise` | noise level + 0.10 |
| `sparser` | motif density × 0.5 |
| `texture` | AM texture on (Focus: 16 Hz / 0.25; Relax and Sleep: 6 Hz / 0.15)\* |

\*The `texture` arm is only eligible once the user has enabled AM in settings. Experimental layers are **never** chosen automatically.

**Reward.** After each session lasting at least 3 minutes, the user can give two 1–5 ratings: a primary rating (Focus: "How focused did you feel?"; Relax and Sleep: "How calm did you feel?") and an enjoyment rating. The reward is normalised to $[0, 1]$:

$$
R = 0.7 \cdot \frac{\text{primary} - 1}{4} + 0.3 \cdot \frac{\text{enjoyment} - 1}{4}.
$$

**Model.** Each arm $k$ holds a Beta posterior that is updated with fractional successes:

$$
\alpha_k \leftarrow \alpha_k + R, \qquad \beta_k \leftarrow \beta_k + (1 - R), \qquad \alpha_k^{(0)} = \beta_k^{(0)} = 1.
$$

**Choosing.** At the start of a session, the bandit samples $\theta_k \sim \text{Beta}(\alpha_k, \beta_k)$ for each eligible arm and plays $\arg\max_k \theta_k$. Beta samples are drawn from two Gamma draws (Marsaglia–Tsang), $\theta = X/(X+Y)$ with $X \sim \Gamma(\alpha)$ and $Y \sim \Gamma(\beta)$.

**Forgetting.** Preferences drift over time. Before each update, the counts are discounted towards the prior with $\lambda = 0.98$:

$$
\alpha_k \leftarrow 1 + \lambda(\alpha_k - 1).
$$

**Transparency and control.**
- The UI shows "Today's variant: Darker" and lets the user reset learning or switch it off.
- Users can always override any parameter manually. A session with manual overrides is **not** used as a reward signal.

## 3. n-of-1 self-test: does setting A beat setting B *for me*?

This tests one setting against another for one person. For example: AM texture on versus off, pink noise versus none, or a binaural beat versus a matched pure tone.

### 3.1 Design

| Element | Specification |
|---|---|
| Structure | $m$ pairs of sessions, with $m = 6$ by default and $m = 4$–$12$ allowed. Within each pair, the order of A and B is randomised by a fair coin (balanced crossover). |
| Blinding | Partial blinding. The UI labels conditions "Session 1" and "Session 2" and never names the setting. Blinding is weak for audible differences, and the results screen says so. |
| Outcome | A **3-minute reaction-time task** modelled on the psychomotor vigilance test (PVT), run after 10 minutes of listening while the audio keeps playing. A stimulus appears after a random interval of 2–10 s, and the user presses Space. Measures: median RT, lapses (> 500 ms), false starts (presses during the waiting interval). There is also an optional self-rating. |
| Washout | At least 30 min between the sessions in a pair (advisory). |

### 3.2 Analysis

For each pair $i$, the difference is $\delta_i = \text{RT}^{B}_i - \text{RT}^{A}_i$; a positive value means A was faster. The estimate is $\bar{\delta} = \tfrac{1}{m}\sum_i \delta_i$.

- **Exact sign-flip permutation test.** Under $H_0$, each $\delta_i$ is equally likely to be $\pm|\delta_i|$. All $2^m$ sign patterns are enumerated, which takes at most 4,096 for $m \le 12$. Then
$$
p = \frac{\#\{\,|\bar\delta^{*}| \ge |\bar\delta|\,\}}{2^m}.
$$
- **Bootstrap 95% CI** for $\bar\delta$: 2,000 resamples using the percentile method and a seeded PRNG.
- **Plain-language result**, following these rules:

| Condition | Message |
|---|---|
| CI excludes 0 and $|\bar\delta| \ge 15$ ms | "In your tests, **A** was faster by about X ms. This is a meaningful difference for you." |
| CI excludes 0 and $|\bar\delta| < 15$ ms | "A difference showed up, but it is very small (about X ms) and unlikely to matter in practice." |
| CI includes 0 | "**No clear difference** between A and B in your tests. Choose whichever you prefer." |

The 15 ms threshold for a meaningful difference is a design choice, not a published minimal clinically important difference. The UI states this.

> [!WARNING]
> **Limitations shown to the user.**
> - Small samples.
> - Practice effects, which the counterbalancing reduces but does not remove.
> - Imperfect blinding.
> - Reaction time is not the same as real-world productivity.
>
> The self-test is a personal experiment, not a scientific study.

## 4. Data model

| Entity | Fields |
|---|---|
| `SessionRecord` | id, mode, armID, start, duration, overridden flag, ratings |
| `BanditState` | per mode: arm → (α, β) |
| `Experiment` | id, A/B parameters, schedule (array of pair orders), trials (condition, RT samples, lapses, false starts) |
| `ExposureLog` | weekly dose fraction, week start |

All of these are stored as one JSON file (see [`architecture.md`](architecture.md)).

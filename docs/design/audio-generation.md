# Audio Generation

**Document:** D-02 · **Version:** 1.0 · **Date:** 2026-10-30 · **Implementation:** `Sources/BrainwavesCore/DSP`, `Sources/BrainwavesCore/Music`, `Sources/BrainwavesCore/Engine`

## 1. Principles

| Principle | Rationale | Implementation |
|---|---|---|
| **Procedural, not sampled** | No copyright or licensing risk; small app; endless non-repeating output | All sound is synthesised from oscillators and noise |
| **Deterministic** | Reproducible tests and research renders | Seeded PRNG (SplitMix64); same seed gives the same audio |
| **Low salience** | Lyrics and sudden events distract [@vasilev2018] | Instrumental only, pentatonic material, soft attacks, sparse motifs |
| **User-controlled arousal** | The right arousal level differs between people [@thompson2001] | Tempo, brightness and density are exposed |
| **Safe by construction** | Hearing safety [@who-h870] | Limiter at −1 dBFS, smoothed gains, volume ceiling |
| **Real-time safe** | No glitches | No allocation, locks or I/O on the render thread |

## 2. Signal flow

```
            ┌───────────── Music bus ──────────────┐
Composer ─▶ │ Pad voices ─┐                        │
(seeded)    │ Bass voice ─┼─▶ Low-pass ─▶ AM tex. ─┼─┐
            │ Motif (FM) ─┘   (brightness) (opt.)  │ │
            └──────────────────────────────────────┘ │   ┌──────────┐   ┌────────┐   ┌─────────┐
Noise gen (white/pink/brown) ─▶ level ───────────────┼─▶ │ Reverb   │─▶ │ Swell  │─▶ │ Master  │─▶ Limiter ─▶ out
Binaural (exp., L/R carriers) ───────────────────────┤   │ (send)   │   │ (relax)│   │ + fade  │   (−1 dBFS)
40 Hz AM (exp., whole mix) ──────────────────────────┘   └──────────┘   └────────┘   └─────────┘
```

## 3. Components and equations

### 3.1 Noise colours

- **White noise:** independent uniform samples $w[n] \in [-1, 1]$ from SplitMix64.
- **Pink noise** ($S(f) \propto 1/f$, −3 dB per octave). This uses Paul Kellett's "refined" filter, a weighted sum of seven one-pole filters applied to white noise:

$$
b_k[n] = a_k\, b_k[n-1] + c_k\, w[n], \qquad p[n] = \gamma\Big(\sum_{k=0}^{5} b_k[n] + b_6[n] + 0.5362\, w[n]\Big),
$$

  with $(a_k, c_k)$ for $k = 0, \dots, 5$ equal to $(0.99886, 0.0555179), (0.99332, 0.0750759), (0.969, 0.153852), (0.8665, 0.3104856), (0.55, 0.5329522), (-0.7616, -0.016898)$. The seventh term is simply $b_6[n] = 0.115926\, w[n-1]$. The scale factor is $\gamma = 0.11$.

- **Brown (red) noise** ($S(f) \propto 1/f^2$, −6 dB per octave). This is a leaky integrator:

$$
r[n] = \frac{r[n-1] + 0.02\, w[n]}{1.02}, \qquad \text{out} = 3.5\, r[n].
$$

Tests check that the measured spectral slope over the 100 Hz–5 kHz band is about −3 dB/oct for pink noise and about −6 dB/oct for brown noise, each within ±1.5 dB/oct.

### 3.2 Amplitude-modulation texture

A raised-cosine gain with depth $d \in [0, 1]$ and rate $f_m$:

$$
g_{AM}(t) = 1 - \frac{d}{2}\Big(1 - \cos 2\pi f_m t\Big), \qquad g_{AM} \in [1-d,\ 1].
$$

The gain is applied to the **music bus** only, so noise stays steady. The UI allows a rate of 4–20 Hz and a depth of 0–0.5. It is **off by default** for new users. When enabled, the defaults are 16 Hz and depth 0.25, motivated by, but not validated against, the 16 Hz condition in [@woods2024]. Changes to the rate keep the phase continuous, so no clicks occur. Because AM is a long-established musical effect (tremolo), its use here is not novel; the patent position is discussed in [`legal.md`](legal.md).

### 3.3 Breathing-paced swell (Relax mode)

The same raised-cosine gain is used at a breathing rate $r$ in breaths per minute:

$$
g_{B}(t) = 1 - \frac{D}{2}\Big(1 - \cos \tfrac{2\pi r}{60} t\Big),
$$

with a default of $r = 6$ [@lehrer2014; @zaccaro2018] and $D = 0.45$. The music low-pass cutoff rises with the swell (brighter while inhaling), which provides a non-visual breathing cue. An optional on-screen breathing guide follows the same phase and is static when Reduce Motion is on.

### 3.4 Generative music

| Element | Method |
|---|---|
| Key and scale | Root note picked by seed from C–B. Major pentatonic (Focus, Sleep) or Lydian-flavoured pentatonic (Relax). No semitone clashes. |
| Harmony | Seeded walk through a small diatonic progression table (degrees I, vi, IV, ii, V). Each chord lasts `barsPerChord` bars. |
| Pad | 3 chord tones × 2 detuned oscillators (±4 cents). Additive partials $1 : 0.35 : 0.12$ at harmonics $1, 2, 3$. Attack 2.5 s, release 4 s. Slight stereo spread. |
| Bass | Chord root two octaves down. Sine wave with slow attack. |
| Motif | On each beat, a note starts with probability $p$ (Focus 0.22, Relax 0.12, Sleep 0.03). The pitch moves by a random walk of ±1–2 scale steps, kept within a range. FM bell voice: $y = A(t)\sin\big(2\pi f_c t + I(t)\sin 2\pi f_m t\big)$, with ratio $f_m/f_c = 2$, decaying index $I(t) = I_0 e^{-t/0.4}$, a 20 ms attack and exponential decay $\tau = 1.2$ s. |
| Polyphony | Fixed pools allocated up front (6 pad notes, 1 bass, 6 motif voices); the oldest voice is reused. |
| Brightness | RBJ low-pass biquad on the music bus, cutoff 400–8000 Hz, $Q = 0.707$. |
| Ambience | Schroeder reverb: 4 parallel comb filters + 2 series all-pass filters. Delay lengths are prime numbers scaled to the sample rate. 20% send. |

RBJ low-pass coefficients, with $\omega_0 = 2\pi f_c / f_s$ and $\alpha = \sin\omega_0 / 2Q$:

$$
H(z) = \frac{\tfrac{1-\cos\omega_0}{2}\,(1 + 2z^{-1} + z^{-2})}{(1+\alpha) - 2\cos\omega_0\, z^{-1} + (1-\alpha)\, z^{-2}}.
$$

### 3.5 Experimental layers (opt-in)

| Layer | Method | Evidence card text (summary) |
|---|---|---|
| Binaural beat | $L = \sin 2\pi (f_c - \tfrac{\Delta}{2}) t,\ R = \sin 2\pi (f_c + \tfrac{\Delta}{2}) t$; $f_c = 200$ Hz, $\Delta \in [1, 30]$ Hz, at −24 dB relative to the mix. Headphones required. | "Some studies report small effects; brain-entrainment evidence is inconsistent" [@garciaargibay2019; @ingendoh2023] |
| 40 Hz AM | $g_{AM}$ with $f_m = 40$ Hz applied to the whole mix, depth ≤ 0.5 | "Studied for Alzheimer's in small trials; no evidence for focus in healthy adults" [@chan2022; @soula2023] |

### 3.6 Master stage

- **Smoothing.** Every user parameter goes through a one-pole smoother, $y[n] = y[n-1] + (x - y[n-1])(1 - e^{-1/(\tau f_s)})$ with $\tau = 50$ ms, so no zipper noise is heard.
- **Fade.** The session fade uses a raised cosine, $g_F(u) = \tfrac12(1 + \cos \pi u)$, for $u \in [0, 1]$ across the fade window.
- **Limiter.** The limiter takes the stereo peak $p = \max(|L|, |R|)$, computes a target $t = \min(1, c/p)$ with ceiling $c = 10^{-1/20} \approx 0.891$ and applies it as follows:
  - **Attack is instant:** when $t < g$, the gain is set to $g = t$.
  - **Release** follows an exponential with $\tau_r = 150$ ms.
  - Because the attack is instant, the output can **never** exceed the ceiling. A final clamp is applied anyway as a second safeguard.

## 4. Mode defaults

| Parameter | Focus | Relax | Sleep |
|---|---|---|---|
| Tempo (BPM) | 80 | 60 | 48 |
| Brightness (Hz) | 3500 | 2000 | 900 |
| Motif density $p$ | 0.22 | 0.12 | 0.03 |
| Bars per chord | 4 | 4 | 8 |
| Music level | 0.7 | 0.7 | 0.45 |
| Noise | pink 0.12 | pink 0.08 | brown 0.35 |
| AM texture | off (16 Hz, 0.25 when on) | off | off |
| Breathing swell | off | 6 /min, $D = 0.45$ | off |
| Default timer | 50 min | 15 min | 45 min |
| Fade-out | 10 s | 30 s | 5 min |
| Volume cap (of system output) | 1.0 | 1.0 | 0.6 |

These values are starting points chosen for comfort. The literature does not prescribe them. Personalisation adjusts them (see [`personalization.md`](personalization.md)).

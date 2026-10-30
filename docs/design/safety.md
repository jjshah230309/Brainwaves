# Safety

**Document:** D-07 · **Version:** 1.0 · **Date:** 2026-10-30 · **Implementation:** `Sources/BrainwavesCore/Safety`, `DSP/Limiter.swift`

## 1. Hazard analysis

| ID | Hazard | Severity | Likelihood | Controls | Residual risk |
|---|---|---|---|---|---|
| H-1 | Hearing damage from loud or long listening | High | Medium | Limiter at −1 dBFS; default master 0.5; weekly dose meter following WHO-ITU H.870 [@who-h870]; warnings at 80% and 100% of the weekly allowance | Low |
| H-2 | Sudden loud transient (e.g., a parameter jump) | Medium | Low | 50 ms parameter smoothing; fade-in at start; instant-attack limiter | Very low |
| H-3 | Use with infants | High | Medium | Prominent "Not for infants" notice; sleep-mode volume cap (0.6); defaults that encourage timers [@hugh2014] | Low |
| H-4 | Photosensitive seizure from visuals | High | Very low | No flashing UI; animation slower than 3 Hz [@wcag22] | Very low |
| H-5 | Discomfort from AM or 40 Hz (fatigue, irritation, tinnitus aggravation) | Low–medium | Medium | Off by default; depth ≤ 0.5; 40 Hz depth ≤ 0.5; tinnitus advisory; one-click "Turn off experimental" | Low |
| H-6 | Users replacing treatment (e.g., for ADHD) with the app | Medium | Low–medium | No medical claims (`ClaimsPolicy`); an evidence card stating "not a treatment" | Low |
| H-7 | Falling asleep with audio playing all night at high level | Medium | Medium | Sleep timer on by default; fade-out; volume cap | Low |
| H-8 | Masking safety-critical sounds (alarms) | Medium | Low | Advisory text; sleep-mode volume cap | Low |

## 2. Listening-dose model

A digital signal level cannot be converted to sound pressure without calibrating the headphones and the system volume. The app therefore **estimates** exposure and says so:

$$
\hat{L}_{\text{A}} \approx L_{\text{dBFS,RMS}} + 20\log_{10}(v_{\text{sys}}) + C,
$$

where $v_{\text{sys}}$ is the system output volume (0–1, entered by the user or assumed to be 1) and $C$ is a calibration offset. By default $C = 100$ dB, a conservative assumption that typical headphones reach about 100 dB SPL at full scale. The user can change it in settings.

The allowed time at level $L$ uses the 3 dB exchange rate, with a reference of 80 dB for 40 h in adult mode or 75 dB in child or sensitive mode:

$$
T(L) = 40\,\text{h} \times 2^{(L_{\text{ref}} - L)/3}, \qquad \text{Dose} = \sum_i \frac{t_i}{T(L_i)}.
$$

| Dose | App behaviour |
|---|---|
| ≥ 0.8 | Gentle notice: "You've used 80% of this week's estimated safe-listening allowance." |
| ≥ 1.0 | Notice, plus an offer to lower the volume by 6 dB (following H.870's monitoring and notification concept). The app never forces silence. |

> [!WARNING]
> The dose figure is an **estimate**. Without measuring the actual headphones, the app cannot know the true sound level. The UI states this, and the real guidance is simple: keep the volume moderate and take breaks.

## 3. Content safety (claims)

`ClaimsPolicy` lists banned phrases, matched case-insensitively on word boundaries. Unit tests check every user-facing string against it.

> "cure", "cures", "treat ADHD", "treats ADHD", "treatment for", "clinically proven", "scientifically proven", "proven to", "guaranteed", "boost IQ", "brain hack", "medical-grade", "FDA-approved", "replace medication", "no side effects"

Required disclosure (About screen and first-run screen): *"Brainwaves is a background-sound tool for comfort. It is not a medical device and does not diagnose, treat or prevent any condition. Effects of sound on attention and sleep are small and differ between people."*

## 4. Advisories shown in the app

| Advisory | Where |
|---|---|
| Not for infants or very young children | First run; Sleep mode |
| Epilepsy and seizure history: consult a clinician before using the experimental layers | Experimental section |
| Tinnitus: stop if symptoms worsen | Experimental section; Settings |
| Do not use while driving or when you must hear alarms | First run |

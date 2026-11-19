# Success Metrics

**Document:** D-09 · **Version:** 1.0 · **Date:** 2026-10-30

> [!NOTE]
> Brainwaves has **no telemetry**, so no metric is collected centrally. Product metrics are computed **on the user's device** and shown to them. Project-level metrics come from public signals (GitHub, opt-in surveys) and from engineering tests.

## 1. Metric framework

| Tier | Metric | Definition | MVP target | Source |
|---|---|---|---|---|
| **User value** | Session completion rate | Sessions that reach their timer ÷ sessions started | ≥ 70% | Local |
| | Mean session rating | Mean primary rating (1–5) | ≥ 3.5 | Local |
| | Personalisation lift | Mean reward over the last 10 sessions minus the first 10 | > 0 (shown to the user) | Local |
| | Self-test completion | Experiments finished ÷ experiments started | ≥ 50% | Local |
| **Honesty** | Claims-policy violations | Banned phrases in shipped copy | **0** | CI |
| | Evidence-card coverage | Features with an evidence card ÷ features | 100% | QA review |
| **Safety** | Over-ceiling samples | Samples above −1 dBFS | **0** | Tests |
| | Users warned at ≥ 80% dose | Shown locally | 100% of qualifying users | Local |
| **Quality** | Audio glitches per hour | Render overruns | 0 | Manual profile |
| | CPU usage | Average during Focus mode | < 5% of one core | Instruments / `top` |
| | Test pass rate | `swift test` | 100% | CI |
| | QA first-pass approval rate | Artifacts approved on first review | Tracked (expected < 50%) | `qa/` |
| **Community** | Contributors | Unique committers per quarter | ≥ 3 by M4 | GitHub |
| | Issue response time | Median time to first response | < 7 days | GitHub |
| | Accessibility issues open | Count | 0 high-severity | GitHub |

## 2. Optional research metrics

When users choose to share them, by manually exporting and sending a file, self-test results could support an open, preregistered *aggregate* study of AM texture effects. Doing so would need an ethics review and a separate consent flow. It is not part of the MVP.

## 3. Anti-metrics (deliberately not optimised)

- Total listening time. More listening is not better for hearing.
- Daily streaks and other engagement loops.
- Any metric that would need tracking.

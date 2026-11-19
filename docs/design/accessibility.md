# Accessibility

**Document:** D-06 · **Version:** 1.0 · **Date:** 2026-10-30 · **References:** [@apple-hig-a11y; @wcag22]

## 1. Commitments

| Need | Commitment | Implementation |
|---|---|---|
| Blind and low-vision users | Every control works with VoiceOver | `accessibilityLabel`, `accessibilityValue` and `accessibilityHint` on all custom controls; sliders state values in units ("Brightness, 3,500 hertz") |
| Keyboard-only use | Everything reachable without a mouse | Space = play/pause; ⌘1/⌘2/⌘3 = modes; ⌘T = timer; ⌘, = settings; standard focus ring |
| Low vision | Scales with text size | System text styles (`.body`, `.title`) only; no fixed font sizes; layouts reflow |
| Colour blindness | Colour is never the only signal | State shown with text and icons (e.g., "Playing" plus a symbol) |
| Contrast | WCAG 2.2 AA (4.5:1 for text) | System semantic colours; the pastel accent is used only on large fills, never as text colour |
| Vestibular and photosensitive users | No flashing, and minimal motion | No element flashes more than 3 times per second (WCAG 2.3.1). The breathing guide is a slow scale animation, replaced by a static ring with a text cue when **Reduce Motion** is on. |
| Hearing differences | Audio is the product, so the experience is made adjustable | Mono-compatible mix; balance and brightness controls; captions for every spoken or textual cue (there is no speech audio) |
| Cognitive load | Simple defaults | One-click modes; advanced controls collapsed under "Mixer"; plain-language evidence cards |
| Motor | Large targets | Minimum 28 × 28 pt hit areas on macOS controls |

## 2. Testing checklist (run before each release)

- [ ] Complete a full session using only VoiceOver (⌘F5).
- [ ] Complete a full session using only the keyboard.
- [ ] Set the largest accessibility text size; check that nothing is clipped.
- [ ] Turn on Increase Contrast and Reduce Transparency; check readability.
- [ ] Turn on Reduce Motion; the breathing guide becomes static.
- [ ] Run the Accessibility Inspector audit with no warnings.
- [ ] Check that any animation repeats more slowly than 3 Hz.

# Privacy

**Document:** D-05 · **Version:** 1.0 · **Date:** 2026-10-30

> [!IMPORTANT]
> **Privacy promise.** Brainwaves collects nothing. It has no accounts, analytics, crash reporting, advertising identifiers or network requests. Everything the app knows about you lives in one file on your Mac, which you can read, export or delete.

## 1. Data inventory

| Data | Purpose | Location | Retention | Leaves device? |
|---|---|---|---|---|
| Settings | Preferences | `~/Library/Application Support/Brainwaves/userdata.json` | Until deleted | No |
| Session records (mode, duration, ratings) | Personalisation and history | same file | Last 500 sessions (FIFO) | No |
| Bandit state | Personalisation | same file | Until reset | No |
| Self-test trials (reaction times) | n-of-1 results | same file | Until deleted | No |
| Weekly listening dose | Hearing safety | same file | Current and previous week | No |

**Not collected:** audio input, microphone, location, contacts, health data, device identifiers, IP address.

## 2. Controls

| Control | Where | Effect |
|---|---|---|
| Export | Settings → Privacy → Export | Saves the JSON file to a location the user chooses (via `NSSavePanel`) |
| Delete all | Settings → Privacy → Delete all data | Erases the file and resets in-memory state; requires confirmation |
| Pause learning | Settings → Personalisation | Stops reward updates; keeps current choices |
| Reset learning | Settings → Personalisation | Resets every arm to its Beta(1, 1) prior |

## 3. Technical safeguards

| Safeguard | Enforcement |
|---|---|
| No networking code | `scripts/qa_gate.py` fails the build if `URLSession`, `NWConnection`, `CFNetwork`, `Network` import, `URLRequest` or `WKWebView` appear in `Sources/` |
| No network entitlement | The `.app` is built without the `com.apple.security.network.client` entitlement. A sandboxed build (roadmap M4) will therefore have no outbound network access. |
| Atomic writes | `Data.write(options: .atomic)` |
| File permissions | Created with mode `0600` (owner read/write only) |
| No third-party SDKs | `Package.swift` has no dependencies |

## 4. Legal fit

- **GDPR and UK GDPR.** No personal data is processed by any controller other than the user on their own device, so the developers are not controllers for any user data.
- **App Store privacy label** (if ever distributed there): "Data Not Collected".
- **Children.** The app collects no data, but its audio is **not intended for infants** (see [`safety.md`](safety.md)).

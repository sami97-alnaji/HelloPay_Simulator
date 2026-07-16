# Android screenshot review

All evidence was captured from `emulator-5554` running the installed release
APK. Every file is a valid 480 × 854 PNG. SHA-256 comparison found 21 distinct
files. Visual inspection found no private notification, local filesystem path,
visible PIN, full PAN, overflow, or inconsistent money format.

| Filename | Screen | Source | Dimensions | Visual review | Privacy review | Duplicate check |
| --- | --- | --- | --- | --- | --- | --- |
| `01-splash.png` | Splash | Android emulator | 480×854 | PASS | PASS | Unique |
| `02-standby.png` | Standby / READY | Android emulator | 480×854 | PASS | PASS | Unique |
| `03-pairing.png` | Pairing OTP | Android emulator | 480×854 | PASS | PASS — fictional OTP | Unique |
| `04-payment-entry.png` | Payment entry | Android emulator | 480×854 | PASS | PASS | Unique |
| `05-test-cards.png` | Test Cards Library | Android emulator | 480×854 | PASS | PASS — masked fictional card | Unique |
| `06-contactless.png` | Card plus contactless interaction | Android emulator | 480×854 | PASS | PASS — masked card | Unique |
| `07-insert-card.png` | Chip insertion | Android emulator | 480×854 | PASS | PASS — masked card | Unique |
| `08-pin.png` | PIN keypad | Android emulator | 480×854 | PASS — no digits entered | PASS — no PIN visible | Unique |
| `09-processing.png` | Real processing steps / BUSY | Android emulator | 480×854 | PASS — stable, non-preview processing frame | PASS | Unique |
| `10-approved.png` | Payment approved | Android emulator | 480×854 | PASS | PASS — masked card | Unique |
| `11-declined.png` | Payment declined | Android emulator | 480×854 | PASS | PASS | Unique |
| `12-cancelled.png` | Customer cancelled | Android emulator | 480×854 | PASS | PASS | Unique |
| `13-timeout.png` | Request timed out | Android emulator | 480×854 | PASS | PASS | Unique |
| `14-refund.png` | Actual refund result | Android emulator | 480×854 | PASS — REFUND transaction shown | PASS | Unique |
| `15-void.png` | Actual void result | Android emulator | 480×854 | PASS — VOID transaction shown | PASS | Unique |
| `16-receipt.png` | Demo receipt | Android emulator | 480×854 | PASS | PASS — masked PAN, fictional IDs | Unique |
| `17-scenario-studio.png` | Scenario Studio | Android emulator | 480×854 | PASS | PASS | Unique |
| `18-history.png` | Transaction history | Android emulator | 480×854 | PASS | PASS | Unique |
| `19-settings.png` | Terminal settings | Android emulator | 480×854 | PASS | PASS — fictional terminal data | Unique |
| `20-api-monitor.png` | Local API monitor | Android emulator | 480×854 | PASS | PASS — sanitized monitor | Unique |
| `21-developer-docs.png` | Developer documentation | Android emulator | 480×854 | PASS | PASS | Unique |

The processing capture was re-taken from the real Android execution at BUSY to
remove a transitional frame. Refund and void are the operation-specific result
screens produced by their respective Android history actions, not renamed or
reused payment images.

**Total: 21 PASS, 0 FAIL, 0 duplicate.**

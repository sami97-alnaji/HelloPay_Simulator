# Android log review

**Session:** 2026-07-16 final release validation
**Device:** `emulator-5554`, Android 15 / API 35
**Filter:** application PID only (`18623` during the complete pre-reinstall
session); raw logs were not committed.

The final PID-filtered dump contained 575 lines. Searches covered:

- `FATAL EXCEPTION`, `AndroidRuntime`, unhandled Dart and Flutter errors;
- `RenderFlex`, disposed controller/state errors and leaked windows;
- socket bind, HTTP lifecycle, UDP lifecycle and Conscrypt warnings;
- duplicate execution and bad-state indicators.

## Findings

| Category | Count | Classification |
| --- | ---: | --- |
| Fatal exception / AndroidRuntime | 0 | Clean |
| Unhandled Dart / `E/flutter` | 0 | Clean |
| RenderFlex / Flutter layout exception | 0 | Clean |
| Socket bind / HTTP / UDP lifecycle error | 0 | Clean |
| Duplicate financial execution | 0 | Clean; also verified through history and last-transaction checks |
| Conscrypt warning | 0 | Not reproduced |
| HWUI 10-bit format initialization | 2 | Harmless emulator fallback; message reports `EGL_SUCCESS` and rendering continued |
| FrameTracker IME show/hide frames | 18 | Emulator/system keyboard performance telemetry, not an application exception |

The FrameTracker messages occurred only while the Android IME was shown or
hidden during card search/input testing. They did not coincide with a Flutter
error, clipped action, crash, or lost transaction. The HWUI warning appeared at
launch/graphics reconfiguration and Android fell back successfully.

Older Conscrypt socket-closed messages from the prior independent audit were
specifically monitored. They did not recur. Physical stop/restart, background,
resume, discovery, and active-reset testing produced the expected socket state,
so the older messages are classified as normal shutdown noise.

**Log gate: PASS — no release-blocking finding.**

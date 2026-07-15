# Phase 7 independent release audit

**Audit time:** 2026-07-15T19:09:54+03:00  
**Auditor environment:** Windows 11 10.0.28020.1921; Flutter 3.41.8 stable; Dart 3.11.5.  
**Repository:** `C:/Users/samis/StudioProjects/hellopay_simulator`  
**Release baseline:** `v0.1.0-simulator` -> `f3b1581ba9925b2ffbf5f46d7f3bb4a9648fdf9f`

## Identity and history

`git rev-parse --show-toplevel`, `git remote -v`, `git branch --show-current`,
`git rev-parse HEAD`, `git rev-parse origin/main`, `git status --short`,
`git log --oneline --decorate -15`, `git tag --list`, `git show --no-patch
--decorate v0.1.0-simulator`, and both `git ls-remote` checks were run.

At the start of this audit, local `HEAD` and `origin/main` were both
`f3b1581ba9925b2ffbf5f46d7f3bb4a9648fdf9f`, branch was `main`, and the tree
was clean. The remote `main` had the same SHA; remote tag object
`3b94028fe1094ae6f4be7ee70a36a0d35f2b3257` resolves to that release commit.
All requested commits exist and were inspected with `git show --stat --oneline`:
`81cd863`, `3cf0cbb`, `afa6969`, `0c857a8`, `2a6d2d0`, `aa9eb23`, `f3b1581`.
No rewritten or missing history was found.

## Fresh source gate

Ran `flutter clean`, `flutter pub get`, `dart format --output=none
--set-exit-if-changed .`, `flutter analyze`, `flutter test`, and `git diff
--check`. Dependency resolution reported 16 available versions incompatible
with the declared constraints; it was not a build or test failure. Format made
no changes in the fresh baseline run. Analyzer: **no issues**. Tests: **50
passed, 0 failed, 0 skipped**, finishing in about three seconds on the final
run. `git diff --check` had no whitespace error.

Test files were inspected as follows: `simulator_engine_test.dart` covers enum
parsing, OTP/pairing/session expiry, payment/tips/restrictions, refunds, void,
busy/cancellation and restoration; `local_api_server_test.dart` covers real
HTTP, v1 routing, idempotency, concurrency, sanitization and server lifecycle;
`simulator_ui_test.dart` covers navigation, tip representations, card/PIN
paths, duplicate execution, result/receipt/history/reset, responsive home and
bounded terminal reader. Several behaviours share assertions inside a single
test, so 50 tests must not be interpreted as 50 independent requirements.
Coverage is weaker for physical Android-only lifecycle transitions and full
manual refund/void initiation UI.

## Defect found and correction

The claimed v1 contract was not present: only legacy `/api/...` routes worked,
and UDP accepted a legacy literal instead of the requested JSON packet. The
following corrective changes were made after the baseline tag:

- mapped all documented `/api/v1/...` routes to the shared dispatcher;
- accepted JSON `HELLOPAY_DISCOVERY` and returned the required discovery keys;
- redacted certificate/fingerprint fields in API monitor and audit evidence;
- expanded the standalone example through payment, status, last transaction,
  refund and void, obtaining the OTP dynamically;
- bumped application version to `0.1.1+2`.

## Real HTTP and UDP evidence

`dart run tool/phase7_api_audit.dart` starts `LocalApiServer` on loopback and
uses `HttpClient` requests; it does not call the dispatcher directly. Sanitized
response files and the full machine-readable matrix are in `docs/audit/api/`.

| Endpoint group | Result |
| --- | --- |
| GET health; OTP handshake; pair | 200 / errorCode 0 |
| payment, refund, voidLastTransaction, storno | 200 / errorCode 0 |
| close, closeBatch, last transaction, tipping, terminal ID, terminal status | 200 / errorCode 0 |
| malformed JSON | 400 / 3011 |
| missing or unknown session | 401 / 3005 |
| expired session | 401 / 3004 |
| invalid amount, negative/forbidden tip, disabled integration | 422 / 1002, 1003, 1005, 1009 |
| concurrent financial call | first 200 / 0; second 409 / 1011 |
| unsupported endpoint | 404 / 1008 |

The physical loopback UDP test sent the exact JSON discovery packet to port
38383. It received `type`, `terminalId`, `deviceName`, `ipAddress`, `port`,
`protocol`, `version` and `apiVersion`. Duplicate start preserved the existing
port; stop made the server inactive; restart succeeded; final stop cleaned it
up. Browser UDP is not claimed.

## Android audit

Fresh `flutter build apk --release` succeeded and produced
`build/app/outputs/flutter-apk/app-release.apk` (51,021,186 bytes). It was
installed and launched on `emulator-5554`, model `sdk_gphone16k_x86_64`, Android
15/API 35, package `com.HelloPay.Simulator.hellopay_simulator`, release build.
`adb devices -l` and `flutter devices` were recorded. The app launched to READY.
The local API was started from the Android UI; `adb forward tcp:18443 tcp:8443`
allowed a separate host process to obtain 200 from `/api/v1/health`. The actual
example client then completed health, dynamic OTP pairing, payment, status,
last transaction, refund and void. It was stopped and the app was restarted.

Screens captured from the Android emulator are under `docs/screenshots/android/`.
The following were captured during this audit: splash, standby, pairing,
payment entry, cards, contactless presentation, processing, approved, receipt,
scenario studio, history, settings, API monitor and developer documentation.
The required insert/PIN/declined/cancelled/timeout/refund/void screenshots were
**not all proven visually in this session**, and are deliberately not treated
as release evidence. The relevant simulated behaviours are covered by the
widget/engine tests and HTTP audit but that is not a substitute for the required
manual emulator evidence.

Filtered log review found no `FATAL EXCEPTION`, `E/AndroidRuntime`,
`RenderFlex`, or unhandled-Dart exception. Two `Conscrypt` socket-closed
warnings were emitted during normal server stop and require future Android
lifecycle observation before declaring a clean long-running socket session.

## Responsive, security and lifecycle review

The widget suite rendered home at 360x800, 390x844, 600x960 and 800x1280 and
the terminal reader at phone size without a captured Flutter overflow. Scenario
Studio scrolling and all-card reachability are implemented but were not fully
exercised at every listed size on the emulator.

Searches inspected paths, token/secret/password/PIN text, private keys and
PAN-like numeric patterns. No user path, real PAN, private key or production
secret was committed. Demo `1234` appears only as fictional test-card behaviour;
PIN state is cleared after submission/screen entry and sanitizer redacts PIN,
token, secret, certificate and fingerprint fields. Cards are masked and receipt
screens state that no real money was processed. The local HTTP API is documented
as simulator-only and not production HTTPS.

HTTP and UDP sockets are stopped by the controller; timers/controllers have
dispose/cancel handling in the inspected UI. Start is idempotent, stop/restart
is tested, and duplicate execution has both API and UI regression tests.
Application pause/resume and a reset while the server is actively running were
not physically stress-tested.

## Documentation and builds

Verified/added: architecture, integration guide, API reference, test cards,
scenarios, error codes, recovery testing, limitations, testing, local API,
release checklist and Phase 6 completion report. New documentation labels
HTTP, idempotency and original-transaction refund semantics as simulator-only,
and states Web/UDP/production-payment limitations.

| Build | Result | Artifact |
| --- | --- | --- |
| Android release | passed | APK, 51,021,186 bytes |
| Web release | passed | `build/web`, 37,158,250 bytes |
| Windows release | passed | `build/windows/x64/runner/Release/hellopay_simulator.exe`, 91,136 bytes |

iOS and macOS were not available or executed.

## Verdict

**CONDITIONAL PASS — NOT RELEASE-TAG READY.** The v1/UDP defect was fixed and
all rerun automated/API/build gates listed above passed. A new tag must not be
created yet: the complete required 30-flow Android manual matrix, all 21
visually reviewed Android screenshots, exhaustive responsive checks, and
pause/reset lifecycle stress test were not completed in this audit session.
The existing `v0.1.0-simulator` tag remains unchanged. Once those missing gates
are completed successfully, the corrective release must use a new
`v0.1.1-simulator` tag rather than moving the old tag.

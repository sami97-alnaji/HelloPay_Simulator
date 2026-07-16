# Testing and QA

## Automated release gates

The release gate includes dependency resolution, static analysis, the complete
Flutter test suite, whitespace validation and a release APK build. The API tests
bind a real loopback server and cover health, pairing, invalid sessions,
payment, last transaction, settlement, idempotency, concurrent busy,
unsupported endpoints, lifecycle, sanitization and discovery serialization.

Final 2026-07-16 results:

- `flutter analyze`: no issues;
- `flutter test`: 55 passed, 0 failed, 0 skipped;
- `flutter build apk --release`: passed;
- `git diff --check`: passed (line-ending notices only, no whitespace error).

## Physical Android coverage

The complete 30-flow evidence is in `android-manual-test-matrix.md`. The 21
reviewed screenshots are in `screenshots/android/` and their review is in
`android-screenshot-review.md`. Lifecycle stress is in
`android-lifecycle-stress.md`.

## Responsive Android matrix

The release APK was physically resized through Android `wm size`. Each captured
PNG was checked to match the named logical dimensions. Evidence is under
`audit/responsive/`.

| Screen | 360×800 | 390×844 | 600×960 | 800×1280 |
| --- | --- | --- | --- | --- |
| Standby | PASS | PASS | PASS | PASS |
| Payment entry | PASS | PASS | PASS | PASS |
| Test cards | PASS | PASS | PASS | PASS |
| Card presentation | PASS | PASS | PASS | PASS |
| PIN | PASS | PASS | PASS | PASS |
| Processing / BUSY | PASS | PASS | PASS | PASS |
| Result | PASS | PASS | PASS | PASS |
| Scenario Studio | PASS | PASS | PASS | PASS |
| Receipt | PASS | PASS | PASS | PASS |
| Settings | PASS | PASS | PASS | PASS |
| API monitor | PASS | PASS | PASS | PASS |

Observed at every size:

- no RenderFlex error or clipped sticky action;
- buttons remained reachable by scrolling and the keyboard did not permanently
  cover the required action;
- Scenario Studio reached its final Run action and its custom controls;
- all 12 cards remained reachable in the library;
- phone layouts stacked content and tablet layouts used the available width
  without an excessive blank grid block;
- HUF amounts did not wrap incorrectly;
- processing showed real steps with BUSY and returned to READY.

**Responsive total: 44 PASS, 0 FAIL.**

## Accessibility review

| Check | Result | Evidence / limitation |
| --- | --- | --- |
| Default system font | PASS | Full manual matrix and screenshots. |
| Larger font (`font_scale=1.3`) | PASS | Standby, payment entry, result and settings remained readable and scrollable. |
| Primary-action semantics | PASS by inspection | Primary controls use labelled buttons; icon-only Back/Copy controls have tooltips. |
| Status text plus icon | PASS | READY/BUSY and result states use both text and icon/color. |
| Minimum touch targets | PASS by inspection | Theme buttons are at least 52 px; PIN keys are at least 64×52. |
| PIN keypad semantics | PASS by inspection | Key semantics expose digit labels; entered PIN remains visually masked. |
| Result announcement | PASS by inspection | Result container is a live semantic region with result text. |
| Reduced motion | PASS | Android animation scales set to zero; navigation and payment controls remained functional; scales restored afterward. |
| Forced `textScaleFactor` | PASS | Source search found no forced text scale. |
| TalkBack traversal | NOT AVAILABLE | The API 35 emulator image had accessibility disabled and no TalkBack service installed. This item is recorded as unavailable, not passed. |

No accessibility setting was left changed after the run.

# v0.1.1 simulator release checklist

- [x] Repository preflight matched expected `main` baseline and clean remote
- [x] Corrective application version is `0.1.1+2`
- [x] Fresh release APK built, installed and launched on Android 15 / API 35
- [x] Complete 30-flow physical Android matrix: 30 PASS
- [x] Financial actions execute once with correct IDs, amounts, history and receipts
- [x] Refund, void, void-ID mismatch and Close Batch are reachable in Android UI
- [x] PIN-blocked scenario follows the scenario override
- [x] HTTP lifecycle physical stress passed
- [x] UDP lifecycle physical stress passed
- [x] Active-payment background/resume and timeout recovery passed
- [x] Reset while HTTP/UDP active matched documented behavior
- [x] 21 Android screenshots captured and reviewed: 21 PASS, 21 unique
- [x] Real BUSY processing screenshot captured
- [x] Responsive Android review: 44 screen/size combinations passed
- [x] Larger-text and reduced-motion checks passed
- [x] TalkBack absence documented as unavailable, not passed
- [x] Sanitized Android log review found no release blocker
- [x] `flutter analyze`: no issues
- [x] `flutter test`: 55 passed
- [x] `flutter build apk --release`: passed
- [x] `git diff --check`: passed
- [x] Existing `v0.1.0-simulator` tag remains immutable

The release tag may be created only after the documentation commit is pushed,
local `HEAD` equals `origin/main`, and the remote tag lookup confirms the new
annotated `v0.1.1-simulator` object.

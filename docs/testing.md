# Testing and QA

The release gate is formatting, static analysis, the complete Flutter test
suite, whitespace validation, and successful builds for configured targets.
The API tests bind a real loopback server and cover health, pairing, invalid
sessions, payment, last transaction, settlement, idempotency, concurrent busy,
unsupported endpoints, lifecycle, sanitization, and discovery serialization.

Visual QA uses the 20 files in `docs/screenshots`. Chrome is checked at desktop
size, widget tests cover phone/tablet breakpoints, and Android emulator QA runs
the real payment flow from standby through card presentation and processing to
approval while checking logs for Flutter errors, crashes, and overflow.

# HelloPay Simulator

HelloPay Simulator is a Flutter development and demo terminal for exercising
pairing, payment, PIN, receipt, recovery, refund, and void flows without
processing real money. Its phone and tablet UI uses the same shared
`SimulatorEngine` as the domain tests, so widgets do not reimplement payment
rules.

> **Simulator only:** this application does not process real money, store real
> card details, or provide a legally/fiscally valid receipt.

## Current status

Phase 4 is implemented: the complete visual demo flow, reusable terminal
components, Riverpod state, routing, responsive layouts, accessibility
semantics, in-app developer documentation, and transaction history are
available. The Local HTTP API server is intentionally deferred to Phase 5.

## Supported visual flows

- Splash and responsive standby terminal
- OTP generation, one-time validation, pairing success, and session expiry
- Amount, nullable tip, service charge, payment method, and request metadata
- Twelve fictional masked test cards with search and filters
- Tap, insert, swipe, PIN, processing, approved, declined, cancelled, and
  timeout recovery flows
- Demo receipt preview and copy actions
- Scenario Studio with preset state-transition preview and custom JSON checks
- Auditable transaction history and detail views
- Terminal, tipping, pairing/session, simulator, and data settings
- Searchable developer reference

## Test cards

The app includes 12 fictional cards. They contain masked display values only;
no valid complete PAN is supported. Cards select expected interaction, PIN,
signature, payment method, and simulator result behavior.

## Run

```powershell
flutter pub get
flutter run -d chrome
```

Any Flutter-supported target generated for the project can use the same app
shell. Chrome is the verified Phase 4 runtime target.

## Test and validate

```powershell
dart format .
flutter analyze
flutter test
git diff --check
```

The engine suite groups the complete Phase 3 behavior matrix into focused
tests. The Phase 4 suite adds controller and widget coverage for splash,
standby, pairing, tip transmission modes, card/PIN routing, exact-once
execution, results, receipt, history, reset, and the required phone/tablet
sizes.

## Screenshots

Runtime captures are stored in [`docs/screenshots/`](docs/screenshots/):

- `standby.png`
- `payment-entry.png`
- `test-cards.png`
- `card-presentation.png`
- `pin-entry.png`
- `processing.png`
- `approved-result.png`
- `declined-result.png`
- `scenario-studio.png`
- `receipt.png`

## Simulator-specific behavior

Refunds may link to an original simulator transaction ID to test remaining
refundable balances. This is simulator-specific behavior, not a claim about a
production HelloPay protocol. The Local HTTP API and endpoint simulation will
be introduced in Phase 5.

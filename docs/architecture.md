# Architecture

HelloPay Simulator has one domain source of truth: `SimulatorEngine`. The
Riverpod `SimulatorController` drives the visual terminal, while
`SimulatorApiDispatcher` adapts HTTP requests to that same engine. Native
targets host the dispatcher with `LocalApiServer`; web builds receive a socket
stub and clearly report that server mode is unavailable.

The UI is split into route screens, reusable terminal widgets, state providers,
and the API monitor. Payment rules, session state, transactions, refund/void
rules, settlement, errors, cards, and scenarios remain in the domain layer.
The network layer adds envelopes, validation, idempotency, financial-request
locking, discovery, and sanitized observation without duplicating those rules.

No persistent database, real certificate, real PAN, real PIN, payment processor,
or production HelloPay connection is used.

# Limitations

This is a simulator, not a production payment implementation.

- HTTP is local and unencrypted. It must not be exposed as a production payment
  endpoint.
- Web builds cannot bind the local HTTP/UDP services.
- UDP discovery depends on emulator/device networking, firewalls and topology.
- Runtime sessions, OTPs, transactions and settings are in memory. A process
  restart begins a fresh simulator runtime.
- Reset clears pairing/session, OTP, history and temporary flow state. It does
  not stop an already enabled local API/UDP service; stop that service explicitly
  from Settings or Local API Monitor.
- Certificates, OTPs, IDs, receipts, cards and processors are fictional.
- Refund linking by `originalTransactionId` and the available void/settlement
  operations are simulator-specific behaviors.
- The app is portrait-oriented. Android viewport resizing was used for rebuild
  and responsive stress instead of unrestricted rotation.
- TalkBack traversal was not executable on the supplied API 35 emulator image
  because no screen-reader service was installed. Semantics were inspected and
  larger text/reduced motion were physically tested, but this is not a claim of
  a completed TalkBack audit.
- iOS and macOS were not part of this Android corrective release gate.

Protocol questions not settled by an authoritative HelloPay specification
remain unresolved rather than being presented as production behavior. In
particular: production authentication/key exchange, TLS/certificate trust,
discovery broadcast scope, settlement reconciliation, and the exact production
refund/void authorization contract.

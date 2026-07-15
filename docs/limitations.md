# Limitations

This is a simulator, not a production payment implementation. HTTP is local
and unencrypted; web builds cannot bind HTTP/UDP sockets; UDP discovery can be
limited by firewalls and network topology; state is in memory. Certificates,
OTPs, IDs, receipts, cards, and processors are fictional. Refund linking by
`originalTransactionId` is simulator-specific. Protocol questions not settled
by a real HelloPay specification remain intentionally out of scope.

# Known limitations

- This is not the production HelloPay protocol or a certification tool.
- HTTP is intentionally local and unencrypted; do not expose it publicly.
- Browser builds cannot host HTTP or UDP sockets.
- UDP broadcast behavior depends on the host network and firewall.
- Data and sessions are in-memory and reset when the app process exits.
- OTPs, certificates, receipts, cards, processors, and transaction IDs are fake.
- The simulator does not process real money or store a valid complete PAN/PIN.

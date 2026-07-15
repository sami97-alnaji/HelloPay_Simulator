# Integration guide

Use the simulator only on a private development network. Start **Local API
Monitor** on Android or Windows, then call the HTTP v1 contract at the
reported port. Pair first: generate an OTP using `otpHandshake`, then send it
to `pair` and include the returned `sessionId` in subsequent execute requests.

The API is plain local HTTP, not production HTTPS. It is an integration test
surface, not a production HelloPay endpoint.

See [local-api.md](local-api.md) and [api-reference.md](api-reference.md).

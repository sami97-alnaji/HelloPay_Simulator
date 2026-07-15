# Error codes

The simulator uses its local catalog: payment validation includes `1001` to
`1012`, permission errors include `1102`, transaction/refund/void errors use
`2000` to `2005`, and pairing/session/network errors use `3001` to `3013`.
Responses include a developer-safe error object and user message. These codes
are simulator contracts, not an asserted production HelloPay specification.

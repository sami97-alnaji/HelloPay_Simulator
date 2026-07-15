# Local API simulator

The native HelloPay Simulator can expose its existing `SimulatorEngine` over
plain HTTP for local-network integration tests. It does not implement a real
HelloPay production protocol and must not be exposed to the public internet.

## Start and discover

Open **Terminal settings** or **Local API monitor**, then start the server.
The defaults are HTTP `0.0.0.0:8443` and UDP discovery port `38383`. Send the
UTF-8 datagram `HELLOPAY_DISCOVER` to receive the simulator terminal ID,
protocol, API version, and HTTP port. Browsers cannot bind local sockets; use
Android or a desktop build for server mode.

## Envelope and session

All JSON responses include `requestId`, `errorCode`, `errorMessage`, and a UTC
`timestamp`. Call `POST /api/otpHandshake` to generate a simulator OTP, then
`POST /api/pair` with `token`, `posId`, and `posName`. Financial requests use:

```json
{
  "requestId": "PAY-1",
  "sessionId": "PS-...",
  "payload": {
    "base": 12500,
    "service": 0,
    "paymentMethod": "BANK",
    "userCode": "demo"
  }
}
```

## Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/health` | Health and terminal status |
| GET | `/api/terminalId` | Simulator terminal ID |
| GET | `/api/status` | Current terminal status |
| GET | `/api/tipping` | Tipping configuration |
| GET | `/api/lastTransaction` | Last transaction or null |
| POST | `/api/otpHandshake` | Generate a short-lived simulator OTP |
| POST | `/api/pair` | Create a paired session |
| POST | `/api/payment` | Execute payment through the shared engine |
| POST | `/api/refund` | Execute refund |
| POST | `/api/void` or `/api/storno` | Void the last eligible transaction |
| POST | `/api/close` or `/api/closeBatch` | Produce a settlement report |

Repeated financial `requestId` values return the cached response without
duplicating the transaction. A concurrent financial request receives error
`1011` (terminal busy). Malformed JSON, unsupported routes, invalid sessions,
expired sessions, and engine validation failures use the standard envelope.

The API monitor stores at most 200 sanitized exchanges. Tokens, PIN-like
fields, and secrets are redacted before display or copy.

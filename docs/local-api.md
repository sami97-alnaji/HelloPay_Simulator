# Local API simulator

The native HelloPay Simulator can expose its existing `SimulatorEngine` over
plain HTTP for local-network integration tests. It does not implement a real
HelloPay production protocol and must not be exposed to the public internet.

## Start and discover

Open **Terminal settings** or **Local API monitor**, then start the server.
The defaults are HTTP `0.0.0.0:8443` and UDP discovery port `38383`. Send the
UTF-8 JSON datagram `{"type":"HELLOPAY_DISCOVERY","version":"1.0"}` to
receive a `HELLOPAY_DISCOVERY_RESPONSE` with terminal ID, device name, bind
IP address, protocol, version, and HTTP port. Browsers cannot bind local
sockets; use Android or a desktop build for server mode.

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
| GET | `/api/v1/health` | Health and terminal status |
| POST | `/api/v1/execute/otpHandshake` | Generate a short-lived simulator OTP |
| POST | `/api/v1/pair` | Create a paired session |
| POST | `/api/v1/execute/payment` | Execute payment through the shared engine |
| POST | `/api/v1/execute/refund` | Execute refund |
| POST | `/api/v1/execute/voidLastTransaction` or `/storno` | Void the last eligible transaction |
| POST | `/api/v1/execute/close` or `/closeBatch` | Produce a settlement report |
| POST | `/api/v1/execute/getLastTransaction` | Read the last transaction |
| POST | `/api/v1/execute/getTippingConfiguration` | Read tipping configuration |
| POST | `/api/v1/execute/getTerminalId` or `/getTerminalStatus` | Read terminal identity/state |

Repeated financial `requestId` values return the cached response without
duplicating the transaction. A concurrent financial request receives error
`1011` (terminal busy). Malformed JSON, unsupported routes, invalid sessions,
expired sessions, and engine validation failures use the standard envelope.

The API monitor stores at most 200 sanitized exchanges. Tokens, PIN-like
fields, and secrets are redacted before display or copy.

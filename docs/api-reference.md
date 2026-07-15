# API reference

All responses contain `requestId`, `errorCode`, `errorMessage`, and a UTC
timestamp. The supported contract is:

| Method | Route |
| --- | --- |
| GET | `/api/v1/health` |
| POST | `/api/v1/pair` |
| POST | `/api/v1/execute/payment` |
| POST | `/api/v1/execute/refund` |
| POST | `/api/v1/execute/voidLastTransaction` |
| POST | `/api/v1/execute/storno` |
| POST | `/api/v1/execute/close` |
| POST | `/api/v1/execute/closeBatch` |
| POST | `/api/v1/execute/getLastTransaction` |
| POST | `/api/v1/execute/getTippingConfiguration` |
| POST | `/api/v1/execute/getTerminalId` |
| POST | `/api/v1/execute/getTerminalStatus` |
| POST | `/api/v1/execute/otpHandshake` |

Financial and execute routes require `sessionId`. A repeated financial
`requestId` returns the cached simulator response; this is simulator-specific,
not a claim about production HelloPay behavior. Legacy `/api/...` aliases are
retained for local compatibility.

# Android lifecycle stress validation

**Date:** 2026-07-16
**Device:** `emulator-5554`, Android 15 / API 35
**Build:** release `0.1.1+2`

## HTTP server

| Check | Physical result |
| --- | --- |
| Start from Android UI | PASS — monitor displayed `http://0.0.0.0:8443`. |
| External health | PASS — host request through `adb forward tcp:18443 tcp:8443` returned HTTP 200 and READY for `/api/v1/health`; legacy `/api/health` also returned 200. |
| Duplicate start attempt | PASS — the running-state UI replaces Start with Stop, so a second Start cannot bind; rapid repeated activation produced one server lifecycle and no bind exception. Idempotent start remains covered by the real-socket regression test. |
| Background / foreground | PASS — process PID stayed alive and health remained HTTP 200 after resume. |
| Stop | PASS — host call returned an empty connection response; the monitor showed stopped. |
| Restart | PASS — health returned HTTP 200 / READY again. |

## UDP discovery

The Android shell sent `HELLOPAY_DISCOVER` to UDP 38383. The application
returned the following sanitized response shape:

```json
{
  "type": "HELLOPAY_DISCOVERY_RESPONSE",
  "terminalId": "HP-SIM-001",
  "deviceName": "HelloPay Simulator",
  "ipAddress": "0.0.0.0",
  "protocol": "http",
  "port": 8443,
  "version": "1.0",
  "apiVersion": "v1"
}
```

| Check | Physical result |
| --- | --- |
| Start and discovery packet | PASS — one valid response. |
| Duplicate start | PASS — the shared running-state control prevents a second socket bind; no bind failure appeared. |
| Stop | PASS — a bounded discovery command returned no payload. |
| Restart | PASS — discovery response returned again. |
| Background / resume | PASS — response remained available after resume. |
| Reset while active | PASS — reset preserved the active local-service setting, as documented by the reset confirmation, and discovery continued with one response. |
| Final stop | PASS — no response remained; no orphan UDP socket was observed. |

## Active payment

- Began a slow 12,500 HUF contactless payment, backgrounded during processing,
  resumed, and observed exactly one approved transaction.
- The recorded transaction was `TXN-1784202928002-01410`; external
  `getLastTransaction` returned SUCCESS, request `REQ-DEMO-001`, the same amount
  and transaction ID, and a single receipt.
- Repeated the background/resume path with the network-timeout scenario. The
  timeout recovery screen appeared, no second transaction was created, and the
  terminal returned to READY.
- Navigated backward/forward where controls allowed it and repeatedly rebuilt
  the activity through Android logical-size changes. Execution stayed exactly
  once.
- Android resizing supplied the available orientation/rebuild stress. The app
  is portrait-oriented, so a free-rotation test was not applicable.

## Reset stress

Precondition: HTTP and UDP running, a POS session present, and a completed
transaction in history.

After confirming **Reset simulator**:

- pairing/session and OTP state were cleared;
- transaction and last-transaction history were cleared;
- simulator preferences returned to their reset values;
- HTTP and UDP remained active because the confirmation describes resetting
  pairing, settings, history and temporary flow state, not stopping local
  services;
- health still returned 200 / READY and UDP still returned one discovery
  response;
- a financial endpoint returned HTTP 401 after reset because the prior session
  was gone;
- stopping the service closed HTTP and UDP; restart succeeded.

This matches the application’s documented reset behavior and left no orphan
socket.

## Warning classification

No Conscrypt warning was reproduced in this complete run. Earlier
`SocketException: Socket closed` / Conscrypt messages occurred only during
intentional socket shutdown. Current stop/restart, background/resume and reset
checks all closed or preserved sockets as intended, so those older messages are
classified as harmless shutdown warnings rather than an active lifecycle
defect. No additional regression test was necessary.

**Lifecycle verdict: PASS.**

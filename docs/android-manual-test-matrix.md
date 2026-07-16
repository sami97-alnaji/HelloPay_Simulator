# Android manual release matrix

**Execution date:** 2026-07-16 (Asia/Amman)
**Build:** release APK, application version `0.1.1+2`
**Device:** `emulator-5554`, `sdk_gphone16k_x86_64`, Android 15 / API 35
**Package:** `com.HelloPay.Simulator.hellopay_simulator`

All rows below were executed from the installed Android application. Automated
tests were used only as regression protection and are not the evidence for a
manual PASS. Unless a row says otherwise, the terminal started READY, became
BUSY only during execution, returned to READY, and the PID-filtered log showed
no app exception, RenderFlex error, bind failure, or duplicate execution.

## Matrix

| # | Flow | Preconditions / card / scenario | Physical steps | Expected and actual result | History, IDs, receipt and status | Screenshot | Result |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 1 | Splash | Fresh release launch | Launch installed app | Flutter splash appeared and routed to standby | No transaction; READY after launch | `01-splash.png` | PASS |
| 2 | Standby | App launched | Observe terminal identity and status | HP-SIM-001 displayed; integration enabled; READY | No duplicate or synthetic history item | `02-standby.png` | PASS |
| 3 | Generate pairing OTP | Not paired | Open Pair Device; regenerate code | Six-digit fictional OTP generated with five-minute expiry | No financial history; READY | `03-pairing.png` | PASS |
| 4 | Successful pairing | Fresh OTP | Enter displayed OTP and pair | Active POS session created | Session active; READY; no financial history | `03-pairing.png` | PASS |
| 5 | Invalid OTP | Not paired | Enter a different six-digit code | Pairing rejected with invalid-OTP feedback | Session remained inactive; READY | `03-pairing.png` | PASS |
| 6 | Expired OTP | Generated OTP | Advance the simulator clock past five minutes and submit | Expired OTP rejected | Session inactive; READY | `03-pairing.png` | PASS |
| 7 | Reused OTP | OTP already used successfully | Submit the same OTP again | One-time OTP rejected | Existing session not duplicated; READY | `03-pairing.png` | PASS |
| 8 | Payment entry | Demo Visa Approved / approved contactless | Open payment, inspect and submit form | Amount, service, tip mode, payment method and integration fields usable | Request preview matched entered values | `04-payment-entry.png` | PASS |
| 9 | Omitted tip | Demo Visa Approved / approved contactless | Select “Omit tip field”; execute | Approved 12,500 HUF; request contained no `tip` key | One payment; request ID retained; unique `TXN-*`; receipt tip 0 HUF; READY | `10-approved.png` | PASS |
| 10 | Explicit tip = 0 | Demo Visa Approved / approved contactless | Select explicit zero; execute | Approved 12,500 HUF; request contained `tip: 0` | One payment; unique transaction; history and receipt correct; READY | `10-approved.png` | PASS |
| 11 | Positive custom tip | Demo Visa Approved / approved contactless | Enter a positive tip and execute | Total equaled base + tip + service | One payment; request/transaction IDs retained; receipt split correct; READY | `10-approved.png` | PASS |
| 12 | Contactless approved | Demo Visa Approved (1001) / approved contactless | Present card; tap | Payment approved for 12,500 HUF | One SUCCESS payment; `REQ-DEMO-001`; unique `TXN-*`; history/receipt present; READY | `06-contactless.png`, `10-approved.png` | PASS |
| 13 | Chip and correct PIN | Demo Mastercard PIN (1002) / approved chip and PIN | Insert card; enter demo PIN; confirm | Payment approved | PIN not exposed; one SUCCESS payment; receipt masks card; READY | `07-insert-card.png`, `08-pin.png` | PASS |
| 14 | Wrong PIN then success | Mastercard PIN / wrong PIN then approved | Enter wrong PIN once, then correct PIN | First attempt rejected; second approved | Exactly one financial transaction; one history entry; READY | `08-pin.png`, `10-approved.png` | PASS |
| 15 | PIN blocked | Mastercard PIN / PIN blocked | Insert; submit PIN | “PIN blocked” shown, then failed result | No successful payment or duplicate; READY | `08-pin.png`, `11-declined.png` | PASS |
| 16 | Customer cancelled | Demo Visa / customer cancelled | Present card; cancel | Customer cancelled result | One auditable failed/cancelled result; no receipt claiming payment; READY | `12-cancelled.png` | PASS |
| 17 | Payment declined | Decline card / payment rejected | Present card | Payment declined | One failed transaction with correct 12,500 HUF amount and IDs; READY | `11-declined.png` | PASS |
| 18 | Insufficient funds | Insufficient-funds card / insufficient funds | Present card | Insufficient-funds failure | One failed transaction; history status correct; READY | `11-declined.png` | PASS |
| 19 | Contactless fallback | Fallback card / fallback to insert | Tap three times; then insert | Reader requested chip after third tap; chip path completed | Exactly one final transaction; no tap-attempt duplicates; READY | `06-contactless.png`, `07-insert-card.png` | PASS |
| 20 | Unsupported card | Unsupported card / unsupported card | Present card | Unsupported-card failure | No successful payment; one auditable result; READY | `11-declined.png` | PASS |
| 21 | SZÉP with zero tip | SZÉP test card / approved | Select SZÉP; send tip 0 | Payment accepted | One payment; amount and method correct; receipt/history correct; READY | `10-approved.png` | PASS |
| 22 | SZÉP forbidden positive tip | SZÉP test card / tip not allowed | Enter positive tip | Validation rejected the request | No financial transaction or duplicate; READY | `04-payment-entry.png` | PASS |
| 23 | EP payment | EP test card / approved | Select EP and execute | EP payment approved | One transaction; method, IDs, history and receipt correct; READY | `10-approved.png` | PASS |
| 24 | SoftPOS tip restriction | SoftPOS test card / tip not allowed | Enter positive tip and execute | Tip restriction shown | No financial transaction; READY | `04-payment-entry.png` | PASS |
| 25 | Timeout and recovery | Demo Visa / network timeout | Execute slowly; background/resume; check last transaction | Request timed out; recovery control usable | No duplicate; one recoverable last-transaction state; READY | `13-timeout.png` | PASS |
| 26 | Refund success | Successful refundable sale / refund successful | Open history detail; refund remaining amount | Refund successful for 12,500 HUF | One refund linked to original ID; unique refund `requestId`/`TXN-*`; history and refund receipt correct; READY | `14-refund.png` | PASS |
| 27 | Refund failure | Successful refundable sale / refund failed | Select failure scenario; request refund | “Refund failed” and request failure text displayed | No successful refund record; original sale unchanged; READY | `14-refund.png` | PASS |
| 28 | Void success | Latest successful sale / default void | Open detail; void transaction | Void successful for 12,500 HUF | One VOID linked to exact sale ID; unique operation request/transaction IDs; history/receipt correct; READY | `15-void.png` | PASS |
| 29 | Void transaction-ID mismatch | Successful sale / default void | Use mismatch action | Void failed with transaction-ID mismatch | No void transaction added; original remains; READY | `15-void.png` | PASS |
| 30 | Close Batch | History contained 6 payments, 1 refund, 1 void | Tap Close Batch; inspect settlement report | Batch closed successfully | Report `SET-1784202459319-84530`; gross 75,000 HUF; refund 12,500 HUF; net 62,500 HUF; terminal READY | `18-history.png` | PASS |

## Financial invariants

- Every completed financial action produced exactly one history record.
- UI navigation, background/resume, viewport rebuilds and recovery checks did
  not create a second transaction.
- Request IDs were preserved in response/receipt details; successful operations
  received unique `TXN-*` identifiers. Mismatch/failure operations did not mint a
  successful transaction identifier.
- Card data stayed masked and no PIN value was recorded or shown.
- Successful transactions exposed the correct demo receipt; failures did not
  claim a successful receipt.
- The terminal returned to READY after every terminal result.

**Total: 30 PASS, 0 FAIL, 0 unexecuted.**

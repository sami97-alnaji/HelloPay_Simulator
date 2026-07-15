# Recovery testing

Use the timeout, app-terminated, and recovery scenarios to verify that the
terminal returns to READY and that clients inspect `getLastTransaction` before
retrying. Test terminal-busy by sending concurrent financial requests. Reset
or stop/start the local server between independent test runs.

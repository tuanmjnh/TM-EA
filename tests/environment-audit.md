# Environment audit — TM-EA

**Date:** 2026-11-11  
**Project:** `D:\Applications\TM-EA`  
**EA:** `TM_TrendFollowerScalper`  
**Strategy ID:** `TM_TFS_V1`

## Platform
- MetaTrader 5 / MetaEditor build: `5.0.0.6292`
- MetaEditor path: `C:\Program Files\MetaTrader 5 EXNESS\MetaEditor64.exe`
- Terminal path: `C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe`
- Terminal data path: `C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06`
- Compile check: temporary MQL5 EA compiled successfully with `0 errors, 0 warnings`.

## Account / broker (configured in terminal)
- Broker: Exness
- Server: `Exness-MT5Trial17`
- Login: `464140826`
- Account mode (hedging/netting): **to verify in MT5 before Phase 5**
- Account currency / leverage / initial balance: **to verify in MT5**

## Symbols
- Primary: `XAUUSD`
- Secondary (independent test only): `EURUSD`
- Symbol specifications (tick size, tick value, contract size, min/step/max volume, stop level, freeze level): **to verify in MT5 Market Watch / Symbol properties**
- Historical data availability for Strategy Tester: **to verify**

## Notes
- No project git repository exists; changes are tracked manually until a repository is initialized.
- The draft preset `config/sets/TM_TFS_XAUUSD_M5_BASELINE_DRAFT_v1_0.set` is unvalidated against compiled input names.
- A $50 account may be infeasible for XAUUSD if broker minimum volume creates risk above the configured risk cap. EA must skip instead of clamping volume upward.

## Phase 0 gate
- [x] MetaEditor build identified
- [x] Compile path verified
- [ ] Account mode verified
- [ ] XAUUSD symbol specs captured
- [ ] EURUSD symbol specs captured
- [ ] Tester data availability verified

## Automated tester attempt
- Attempted to run a temporary symbol-spec dump EA through MT5 Strategy Tester with real-tick model.
- The terminal did not complete/close automatically and no spec file was produced.
- Symbol specifications and account mode therefore remain to be captured manually in MT5 before Phase 4/5.

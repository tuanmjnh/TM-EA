# TM-EA — Simple Architecture & AI Build/Test Instructions

**Project:** TM-EA  
**EA name:** `TM_TrendFollowerScalper`  
**Strategy ID:** `TM_TFS_V1`  
**Platform:** MetaTrader 5 (MQL5)  
**Document status:** Initial implementation brief — not a profitability claim  
**Source requirements:** [`SOURCE_SPEC_V1.md`](SOURCE_SPEC_V1.md) — the single source of truth for strategy
requirements and the canonical input table. This brief adds implementation detail; where the two conflict,
the non-negotiable rules in section 2 below win, and the spec is expected to be corrected to match.

> ⚠️ **v2.0 (2026-11-12) — STRATEGY CHANGE.** Take Profit is now **enabled** (rule 1 below is superseded),
> Breakout is **removed** (§4.2 mentions Breakout only historically), and an **equity circuit breaker**
> (`Max_Equity_DD_Percent`) was added. See `docs/CHANGELOG.md` (v2.0) and `docs/MASTER.md` §3.

---

## 1. Mission

Build a maintainable MT5 Expert Advisor for small-account trend-following scalping, initially focused on XAUUSD. EURUSD may be enabled only after the same implementation has been tested independently on that symbol.

The EA should:

- Detect the higher-timeframe trend and trade only in that direction.
- Find entries on a lower timeframe using Pullback and/or Breakout.
- Never attach a Take Profit.
- Attach an initial Stop Loss to every new position.
- Manage open positions using a staged, adaptive trailing-stop engine.
- Allow a new entry only after a fresh, closed-bar setup; never re-enter merely because the trend remains active.
- Protect small accounts through risk-based sizing and account-level guards.
- Produce reproducible `.set` presets and complete backtest reports.

**No profitability, win-rate, or minimum-deposit guarantee is made.** A $50 account may be infeasible with a broker whose minimum trade size creates risk larger than the configured risk budget.

## 2. Non-negotiable rules

1. ~~`Use_TP=false`; do not send a TP price in entry or modification requests.~~ **[v2.0 — superseded]** Take Profit is enabled: `Use_TP=true` with `TP_ATR_Mult`; when `Use_TP=false`, do not send a TP price.
2. A new position must have a valid initial SL. If the broker cannot accept the SL with the entry, do not intentionally leave the trade unprotected.
3. No martingale, grid, averaging down, loss-recovery sizing, or lot escalation after losses.
4. Calculate volume from cash risk and the actual symbol contract/tick properties. Use `OrderCalcProfit()` where possible to estimate loss from entry to SL in account currency.
5. Round volume **down** to `SYMBOL_VOLUME_STEP`. If the resulting volume is below `SYMBOL_VOLUME_MIN`, or minimum volume breaches the risk cap, skip the trade. Never clamp volume upward to the minimum.
6. Enforce broker stop-level, freeze-level, tick-size, volume-step, margin and trading-session constraints.
7. Trailing SL may only move toward reduced risk: upward for BUY and downward for SELL. Never widen an SL.
8. Risk guards block new entries. They must not accidentally disable management of existing positions.
9. Use closed bars for signal decisions to avoid intrabar signal repainting. Trailing management may run on ticks.
10. All important decisions and rejected trades must be logged with a reason code.

## 3. High-level architecture

```text
OnInit / OnTick / OnTradeTransaction
              |
              v
        EA Orchestrator
              |
     +--------+---------+
     |                  |
     v                  v
Position Manager    Entry Scheduler
(trailing every     (once per new
 eligible tick)     closed entry bar)
     |                  |
     v                  v
Trailing Engine     Risk Guard
                         |
                         v
                  Market Regime /
                    Trend Filter
                         |
                         v
                     Entry Engine
                  /              \
             Pullback          Breakout
                  \              /
                   v            v
                  Risk & Volume Engine
                         |
                         v
                  Execution / Validation
                         |
                         v
                    MT5 Trade API

Shared services: Symbol Specs, Indicators, News Calendar,
Session Filter, Daily Statistics, Persistent State, Logging.
```

Keep modules separated in `.mqh` files where useful. Do not over-engineer the first release.

## 4. Modules and responsibilities

### 4.1 `CTrendFilter`

Inputs: trend timeframe, Fast EMA, Slow EMA, ADX period and threshold.

Initial rule set from the source specification:

- Uptrend: Fast EMA > Slow EMA, ADX > threshold, last closed trend candle closes above Fast EMA.
- Downtrend: Fast EMA < Slow EMA, ADX > threshold, last closed trend candle closes below Fast EMA.
- Otherwise: Sideways / no trade.

Use indicator handles created in `OnInit()`. Check `CopyBuffer()` return counts and `BarsCalculated()`. Release handles in `OnDeinit()`. Use only completed candles for trend state.

### 4.2 `CEntryEngine`

Support separately switchable entry modes:

- **Pullback:** price reaches the EMA pullback zone, then a completed candle confirms continuation in the trend direction.
- **Breakout:** define the breakout reference precisely (for example, previous completed bar high/low plus/minus an ATR-derived buffer). Require a completed-bar close beyond the level and optional EMA slope confirmation.

The source text's phrase “previous high + k*ATR” is ambiguous as a breakout definition. Implement a documented formula and unit-test it; do not silently interpret it differently in different code paths.

Return a structured signal containing direction, setup type, signal-bar time, proposed entry reference, invalidation/swing level and diagnostic reason. Prevent duplicate entries from the same signal bar.

### 4.3 `CInitialStop`

Calculate initial SL before order submission from a configurable structural swing and/or ATR distance. Validate:

- Correct side of market.
- Minimum stop distance and tick-size alignment.
- Estimated loss at SL, including a configurable cost allowance.
- Risk cap after volume-step rounding.

If no valid SL/volume combination exists, skip the trade.

### 4.4 `CTrailingEngine`

[v2.0: a fixed ATR Take Profit is set at entry; the trailing engine below remains for the stop.] Explicit states:

1. **Initial protection:** SL is attached at entry.
2. **Break-even eligibility:** after a configurable favourable move, move SL to entry plus estimated costs for BUY, or entry minus estimated costs for SELL. Do not assume raw entry price is true break-even.
3. **Profit lock:** optionally lock a fraction/step of open profit after a further threshold.
4. **ATR trail:** trail behind favourable price extreme by `ATR × multiplier`.
5. **Structure trail:** optionally trail behind a confirmed higher low for BUY or lower high for SELL.
6. **Exit:** broker SL closes the position. Optional emergency market-close logic may be used only for explicitly defined invalidation or platform/broker failure cases.

Rules:

- Never loosen SL.
- Respect tick size, stop level and freeze level.
- Modify only if the improvement exceeds `Trail_Step` and the new SL is valid.
- Avoid repeated modification requests on every tick.
- Store or reconstruct the favourable high-water/low-water mark safely after terminal restart.
- Do not let a news-entry block stop trailing management.
- Test gaps and slippage: SL is not a guaranteed execution price.

The first implementation may use ATR trailing only, then add break-even, profit lock and structure trailing as separately testable features. Do not combine all trailing modes before each works independently.

### 4.5 `CRiskManager`

Responsibilities:

- Risk percent per trade.
- Volume calculation from actual symbol properties.
- Maximum concurrent positions.
- Daily loss limit based on a clearly defined baseline and including floating P/L where configured.
- Consecutive-loss pause and cooldown.
- Equity drawdown stop.
- Margin safety check.
- Symbol and Magic Number isolation.

Define whether daily loss is measured from start-of-day equity or balance. Recommended initial definition: start-of-broker-day equity baseline, compared with current equity, with reset at broker server day. Persist the baseline so terminal restarts do not reset protection.

For a small account, start testing at 0.25%–0.5% risk per trade. These are test settings, not guaranteed feasible settings. A daily loss limit of 1%–2% is a safer initial experiment than the source draft's 5%; expose it as an input and test sensitivity.

### 4.6 `CNewsFilter`

Use the MT5 Economic Calendar where available. Filter high-impact events relevant to the traded symbol's currencies (for XAUUSD, at minimum USD-related events; symbol/currency mapping must be configurable).

- Block new entries inside configurable pre/post-event buffers.
- Log event name, currency, importance and blocked interval.
- Define explicit behavior when calendar data is unavailable. Default safe behavior: block new entries if news filtering is enabled and the calendar cannot be verified; continue managing existing positions.
- Do not claim that a calendar filter protects against every unscheduled event.

### 4.7 `CMarketGuards`

- Maximum spread in points, interpreted using symbol point and digits.
- Session filter using broker server time and documented daylight-saving assumptions.
- Volatility/spread anomaly guard.
- Optional Friday/weekend restrictions.
- Guard failures must have explicit log reasons.

### 4.8 `CTradeExecutor` and `CPositionManager`

Use `CTrade` or a consistently implemented request layer. Check trade result retcodes, not only the boolean return. Confirm actual position state after execution.

Support both account modes deliberately:

- **Hedging:** manage each position by ticket.
- **Netting:** one aggregate position per symbol; do not pretend multiple independent entries exist. Either implement netting semantics explicitly or restrict the first release to one position per symbol.

The first release should default to one concurrent position until hedging/netting behavior is verified.

### 4.9 `CLogger` and `CStats`

Log at least:

- Timestamp, symbol, timeframe, EA version, Magic Number.
- Trend state, ADX, EMA values, entry mode and signal-bar time.
- Spread, ATR, requested volume, estimated cash risk and initial SL.
- Order retcode and execution price.
- Every SL modification: old SL, new SL, reason and result.
- Exit reason, gross P/L, commission, swap, net P/L.
- Risk-guard state and reason for every skipped entry.

## 5. Suggested source layout

```text
MQL5/Experts/TM_TrendFollowerScalper.mq5
MQL5/Include/TM_EA/
  Inputs.mqh
  Types.mqh
  SymbolSpecs.mqh
  Indicators.mqh
  TrendFilter.mqh
  EntryEngine.mqh
  InitialStop.mqh
  TrailingEngine.mqh
  RiskManager.mqh
  NewsFilter.mqh
  MarketGuards.mqh
  TradeExecutor.mqh
  PositionManager.mqh
  DailyStats.mqh
  Logger.mqh
config/sets/
reports/backtests/
reports/forward/
tests/
```

If the project uses a different include layout, document it and keep module boundaries intact.

## 6. Input design

Group inputs in the MT5 Inputs tab:

- General: Enabled, MagicNumber, trade comment, symbol policy.
- Trend: timeframe, EMA periods, ADX period/threshold.
- Entry: timeframe, enabled modes, pullback EMA/buffer, breakout lookback/ATR buffer, confirmation rules.
- Initial SL: ATR period/multiplier, swing lookback, maximum allowed stop distance.
- Trailing: mode, activation threshold, break-even threshold, cost offset, ATR period/multiplier, profit-lock settings, structure lookback, minimum modification step.
- Money management: risk percent, maximum volume, volume policy.
- Risk guard: daily loss, equity drawdown, consecutive losses, cooldown, maximum positions.
- Execution: max spread, deviation/slippage, filling policy.
- News/session: enable flags, impact level, pre/post buffers, session times and fail-safe behavior.
- Diagnostics: verbose logging, dashboard.

Input names must remain stable after a release. If an input is renamed or its meaning changes, version the preset and document migration.

## 7. `.set` preset policy

Store all MT5 input presets under:

`config/sets/`

Naming convention:

`<strategy>_<symbol>_<timeframe>_<purpose>_v<major>_<minor>.set`

Examples:

- `TM_TFS_XAUUSD_M5_BASELINE_v1_0.set`
- `TM_TFS_XAUUSD_M5_CONSERVATIVE_v1_0.set`
- `TM_TFS_EURUSD_M5_BASELINE_v1_0.set`

Every preset must include a companion note (or metadata in the test manifest) stating:

- EA version/build.
- Symbol and broker/server.
- Account currency and account mode (hedging/netting).
- Contract size, tick size/value, minimum volume and volume step.
- Intended use: baseline, optimization candidate, out-of-sample, or demo.
- Date created and whether it has been validated against the compiled EA.

Never label a preset “profitable” based only on an optimization pass.

## 8. Backtest and report storage policy

Store every completed test under:

`reports/backtests/<symbol>/<YYYY-MM-DD>_<test-id>/`

Each test folder should contain, where available:

```text
<test-id>/
  report.html
  report.xml                 # if exported
  tester.log
  preset.set                # exact .set used
  manifest.md
  equity.png                # optional
  drawdown.png              # optional
  trades.csv                # optional
```

`manifest.md` must record:

- EA source version / Git commit / compiled EX5 hash if available.
- Exact preset filename and hash.
- Broker, server, symbol and symbol specifications.
- Account currency, initial deposit, leverage, hedging/netting mode.
- Test start/end dates and timezone.
- Strategy Tester model: **Every tick based on real ticks** where data is available.
- Spread mode/value, commission, swap, execution delay/slippage assumptions.
- Optimization ranges and objective, if applicable.
- Net profit, profit factor, expected payoff, trade count, equity/balance drawdown, recovery factor, Sharpe (if available), average win/loss, largest win/loss, consecutive losses.
- Known limitations and decision: reject / investigate / candidate for forward test.

Do not overwrite previous reports. Every run gets a unique folder. Keep failed and negative reports too; they are essential evidence.

## 9. Test plan and acceptance gates

### Gate A — Compile and static checks

- Compile without errors; eliminate warnings where practical.
- Validate all input defaults and enum ranges.
- If `Use_TP=true`, confirm the TP price is always on the correct side of entry; if `false`, confirm no TP is submitted. `[v2.0]`
- Confirm every entry has an SL.
- Confirm no martingale/grid/averaging code exists.
- Confirm volume rounding is downward and risk cap is never silently exceeded.

### Gate B — Unit / logic tests

Test BUY and SELL symmetry for:

- Trend classification.
- Pullback and breakout signals.
- ATR and swing stop calculation.
- Volume calculation across different tick sizes/values.
- Price normalization to tick size.
- Trailing monotonicity.
- Daily reset and persistent state.
- Hedging and netting behavior.
- News data unavailable / stale / event-buffer cases.
- Spread, stop-level, freeze-level and insufficient-margin rejection.

### Gate C — Historical backtests

- Prefer 3–5 years where reliable broker data exists; at minimum include different trend and ranging regimes.
- Use Every tick based on real ticks where available.
- Include realistic spread, commission, swap and execution assumptions.
- Test XAUUSD first. Test EURUSD independently; do not transfer parameters blindly.
- Split data chronologically into in-sample, validation and out-of-sample segments.
- Do not optimize against the final out-of-sample period.
- Run parameter sensitivity tests; reject fragile single-parameter peaks.
- Run stress scenarios with higher spread, commission and slippage (for example 1.5× and 2× baseline costs).

### Gate D — Forward demo

Run at least 2–4 weeks, preferably longer and across enough trades to be informative. Compare live demo execution against backtest assumptions. Do not move to live merely because a short demo period is profitable.

### Evaluation

Track net profit after all costs, profit factor, expected payoff, max equity drawdown, recovery factor, trade count, average win/loss, tail loss, consecutive losses, exposure time and cost sensitivity.

The source spec suggests PF >= 1.3 and MDD < 20% as initial goals. Treat them as provisional research gates, not proof of robustness. For a $50 account, also report dollar drawdown and whether minimum lot makes the configured per-trade risk impossible. A 35–45% win rate is not a required target; it is only a possible outcome for a trend-following system.

## 10. Development sequence for the AI coding agent

Implement in small, testable phases. Do not generate the entire EA in one pass.

1. **Phase 0 — Inspect environment:** verify MT5/MQL5 build, broker symbol properties, account mode and tester data availability. Write findings to `tests/environment-audit.md`.
2. **Phase 1 — Skeleton:** create EA, inputs, symbol-spec helper, logger and compile.
3. **Phase 2 — Trend filter:** implement closed-bar EMA/ADX classification and test.
4. **Phase 3 — Entry logic:** implement Pullback only; add Breakout after Pullback tests pass.
5. **Phase 4 — Initial SL and risk sizing:** prove risk calculation and minimum-lot rejection.
6. **Phase 5 — Execution and position tracking:** verify SL attached, retcodes, restart behavior and account modes.
7. **Phase 6 — Trailing:** ATR trail first; then break-even, profit lock and structure trail as independent options.
8. **Phase 7 — Risk guards:** daily loss, consecutive loss, cooldown, spread, session and news.
9. **Phase 8 — Dashboard and statistics:** only after trading logic is stable.
10. **Phase 9 — Backtest automation and reports:** save exact `.set` and report artifacts using the folder policy above.
11. **Phase 10 — Robustness and demo:** OOS, cost stress, forward demo and documented release decision.

At the end of each phase: compile, run relevant tests, save logs/results, update `tests/implementation-status.md`, and do not proceed if a critical safety test fails.

## 11. Definition of done for V1

V1 is ready for demo evaluation only when:

- It compiles and runs without critical runtime errors.
- TP (when enabled, v2.0) is always on the correct side of entry. `[v2.0]`
- Equity circuit breaker closes all positions and halts at `Max_Equity_DD_Percent`. `[v2.0]`
- Every opened position has a valid SL.
- Risk sizing never silently exceeds the configured cap.
- It cannot increase volume after losses.
- Trailing SL never loosens.
- Daily loss and restart persistence work.
- News/spread/session guards behave as documented.
- Hedging/netting behavior is explicit and tested.
- Backtest report and exact `.set` are saved together.
- OOS and cost-stress results are documented.
- Known limitations are recorded.

Passing these gates does not guarantee future profits and does not automatically authorize live trading.

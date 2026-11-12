# Robustness checklist — TM-EA V1

## Historical robustness
- [ ] 3-5 years of reliable broker data where available
- [ ] Different trend and ranging regimes included
- [ ] XAUUSD tested first
- [ ] EURUSD tested independently
- [ ] Chronological in-sample / validation / out-of-sample split
- [ ] No optimization against final out-of-sample period
- [ ] Parameter sensitivity checked; fragile single-parameter peaks rejected

## Cost stress
- [ ] Baseline spread/commission/swap/execution assumptions documented
- [ ] 1.5x cost stress run
- [ ] 2.0x cost stress run
- [ ] Results compared with baseline

## Safety verification
- [ ] No TP sent in tester logs
- [ ] Every opened position has SL
- [ ] Volume rounding downward verified
- [ ] Minimum-lot breach skips trade
- [ ] Trailing SL never loosens
- [ ] Daily loss and restart persistence verified
- [ ] News/spread/session guards behave as documented
- [ ] Hedging/netting behavior explicit and tested

## Forward demo
- [ ] Demo run 2-4 weeks minimum
- [ ] Live demo execution compared with backtest assumptions
- [ ] Forward report saved under reports/forward/

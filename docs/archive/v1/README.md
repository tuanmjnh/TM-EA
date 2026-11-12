# Archive — v1 (superseded)

Read-only history. Nothing here is a source of truth.

| File | Was | Replaced by |
|---|---|---|
| `TM_TrendFollowerScalper.md` | Byte-identical duplicate of the original strategy spec, kept under `docs/EA/` | [`docs/SOURCE_SPEC_V1.md`](../../SOURCE_SPEC_V1.md) |

Archived 2026-11-11 during the spec merge, because two copies of the same requirements document drift
apart on the first edit. The surviving copy in `docs/SOURCE_SPEC_V1.md` also carries the corrections made
in that merge:

- Removed the "clamp volume up to broker minimum" rule, which contradicted the risk-cap safety rule.
- Rewrote the volume formula around `OrderCalcProfit()` (the previous formula was mangled and ignored costs).
- Made the input table canonical and aligned it with `config/sets/` and `ARCHITECTURE.md`.
- Dropped the "(BÀO LỢI NHUẬN)" claim from the title.

Do not cite values from this archived copy.

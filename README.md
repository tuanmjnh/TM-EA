# TM-EA (Quantitative Scalping & Multi-Agent AI Trade Orchestrator)

**Dự án:** TM-EA  
**Chiến lược P0:** `TM_SessionBreakout` (H1 Asian Range Breakout)  
**Chiến lược P1:** `TM_GoldSweepScalper` (M5 London KZ Judas Liquidity Sweep - 9 module chuẩn hóa, 1Y real-tick profitable baseline PF 1.069, DD 7.39%)  
**Module AI:** `ai_trade` (Multi-Agent Committee 5 tác tử, Hard RiskGate 6 lớp, FastMCP MT5 Server)  
**Nền tảng:** MetaTrader 5 (Exness) / MQL5 / Python 3.11+  
**Cẩm nang sử dụng từ A - Z:** [docs/USER_GUIDE.md](file:///d:/Applications/TM-EA/docs/USER_GUIDE.md)  
**Tài liệu điều hành tối cao:** [docs/MASTER.md](file:///d:/Applications/TM-EA/docs/MASTER.md) (v5.0)  

---

## 1. Cấu trúc Dự án (Project Layout)

```text
TM-EA/
├── README.md
├── ai_trade/                    # Module Trí tuệ Nhân tạo & Giao tiếp MT5 (Python)
│   ├── bridge/
│   │   └── mt5_mcp_server.py    # MetaTrader 5 FastMCP Server (11 tools chuẩn)
│   ├── committee/               # Hội đồng 5 tác tử (Specialists, Debaters, Chair, Orchestrator)
│   ├── core/
│   │   ├── models.py            # Data contracts Pydantic
│   │   ├── provider_router.py   # Hot-swap router (TokenHarbor, Gemini, OpenAI, Ollama...)
│   │   ├── risk_gate.py         # Chốt chặn an toàn cứng (Hard RiskGate)
│   │   └── safety.py            # Module an toàn & Physical Kill-Switch
│   ├── signals/
│   │   └── detector.py          # Bộ quét tín hiệu MT5 real-time (M5 Sweep / H1 Breakout)
│   ├── storage/
│   │   └── db.py                # Quản lý cơ sở dữ liệu SQLite data/results.db
│   └── runner.py                # File thực thi trung tâm (Paper & Live Trade Runner)
├── config/
│   ├── ai/                      # Cấu hình AI: agents.json, providers.json, methods_registry.json
│   ├── sets/                    # Presets thông số chuẩn (.set) cho từng EA và mức vốn
│   └── test/                    # File cấu hình tester (.ini)
├── data/
│   └── results.db               # SQLite database lưu trữ lịch sử quyết định của AI
├── docs/
│   ├── README.md                # Bản đồ phân loại & hướng dẫn tài liệu tổng quan
│   ├── MASTER.md                # Tài liệu điều hành tối cao (v5.0 P0)
│   ├── USER_GUIDE.md            # CẨM NANG HƯỚNG DẪN SỬ DỤNG TỪ A - Z CHO NGƯỜI MỚI
│   ├── CHANGELOG.md             # Toàn bộ nhật ký cập nhật qua các phiên bản
│   ├── ARCHITECTURE.md          # Kiến trúc kỹ thuật và invariants rủi ro MQL5
│   ├── specs/                   # Đặc tả kỹ thuật (SPEC_GOLD_SCALPER, SPEC_AI_TRADE_MODULE...)
│   ├── plans/                   # Kế hoạch hành động (ACTION_PLAN_AI_TRADE, ACTION_PLAN_2026_11_19...)
│   ├── audits/                  # Báo cáo kiểm định và phân tích nguyên nhân gốc
│   ├── research/                # Các thuật toán thử nghiệm (Kim La, Wonderwhales...)
│   └── archive/v1/              # Kho lưu trữ mã nguồn và tài liệu thế hệ cũ
├── MQL5/
│   ├── Experts/                 # Mã nguồn EA MQL5: TM_GoldSweepScalper, TM_SessionBreakout (.mq5/.ex5)
│   └── Include/TM_EA/           # Module tái sử dụng: TimeService, RegimeEngine, RiskManager...
├── reports/
│   ├── backtests/               # Báo cáo kết quả backtest tick thật chi tiết
│   └── forward/                 # Nhật ký chạy thử nghiệm Demo thực tế
└── tests/                       # Test suite tự động (Pytest 6/6 tests passed 100%)
```

---

## 2. Hướng dẫn Vận hành Nhanh (Quick Start)

Xem hướng dẫn chi tiết từng bước tại **[docs/USER_GUIDE.md](file:///d:/Applications/TM-EA/docs/USER_GUIDE.md)**.

### A. Chạy AI Trade Runner ở Chế độ Paper (Không vào lệnh thật)
```powershell
# Chạy kiểm nghiệm 1 lần:
python -m ai_trade.runner --once --mode paper

# Chạy vòng lặp tự động liên tục mỗi 30s:
python -m ai_trade.runner --interval 30 --mode paper
```

### B. Chạy Tự động trên Tài khoản Exness Demo (Vào lệnh 0.01 lot)
```powershell
python -m ai_trade.runner --interval 30 --mode live --lot 0.01
```

### C. Ngắt Khẩn cấp & Đóng Sạch Lệnh (Physical Kill-Switch)
```powershell
python -m ai_trade.runner --kill
# Hoặc tạo file cờ trống: config/ai/KILL
```

## Document precedence

1. `docs/SOURCE_SPEC_V1.md` — strategy requirements, canonical input table.
2. `docs/ARCHITECTURE.md` — implementation detail. Where it conflicts with the spec, its **safety rules
   (section 2)** take priority; the spec was corrected accordingly on 2026-11-11.
3. `docs/archive/` — history only, never a source of truth.

## Important operating rules

- **v2.0:** Take Profit is now enabled by default (`Use_TP=true`, `TP_ATR_Mult`). When enabled, verify TP is always on the correct side of entry. (Pre-v2.0 builds had no TP.)
- Equity circuit breaker: when equity drawdown from the day baseline reaches `Max_Equity_DD_Percent`, close all positions and halt new entries for the day.
- Every opened position must have a valid initial Stop Loss attached. If the broker rejects the SL or the position is found without one, apply the documented emergency-protection procedure and block new entries.
- No martingale, grid, loss recovery sizing, or averaging down.
- Never force the broker's minimum lot if it exceeds the configured risk budget. Skip the trade instead.
- Trailing Stop may only move in the protective direction.
- A `.set` file is a configuration snapshot, not proof of a profitable strategy.
- Save every meaningful backtest report together with the exact `.set`, EA build/version, symbol, timeframe, broker specification, test dates, and modelling mode.

## Documentation & User Guides

- **Beginner & User Guide**: [docs/USER_GUIDE.md](docs/USER_GUIDE.md) — Step-by-step MT5 tester setup, preset selection, report export, and troubleshooting.
- **Master AI Manual**: [docs/MASTER.md](docs/MASTER.md) — Canonical reference, roadmap, strategy invariants, and developer manual.

## Current status

**v2.0 (2026-11-12) — deliberate strategy change:** entry is now **Pullback-only** (Breakout removed), **Take Profit is enabled** (`Use_TP=true`), and an **equity circuit breaker** (`Max_Equity_DD_Percent`) force-closes and halts on deep drawdown. Source updated; **NOT yet recompiled and NOT re-backtested.**

- ❌ The committed `TM_TrendFollowerScalper.ex5` predates the v2.0 source — must be rebuilt (BUG-006).
- ⚠️ **Every existing report is invalid for v2.0** (they were produced by the no-TP, Breakout-enabled build). Kept only as history.
- Open bugs: hard-coded FOK filling (BUG-002), consecutive-loss double-count on restart (BUG-003), news filter inactive in tester (BUG-004), sizing ignores commission (BUG-007), margin uses min volume (BUG-008) — see `tests/BUG_REPRODUCTIONS.md`.

Required next: compile → valid cost-stress (commission+slippage+news) → OOS, then Cent-account demo. Statuses in `tests/VALIDATION_RESULTS.md`; history in `reports/backtests/MANIFEST_INDEX.md`. **No backtest result here is proof of a profitable strategy.**

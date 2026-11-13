# TM-EA — TECHNICAL AUDIT (P1)

**Ngày audit:** 2026-11-12
**Phạm vi:** toàn bộ MQL5 source trong `MQL5/`, preset trong `config/sets/`, reports trong `reports/backtests/`.
**Nguyên tắc:** Chỉ đánh dấu **PASS** khi có bằng chứng thực tế từ source/artifact. Trạng thái dùng: `PASS (static)`, `PASS (build log)`, `FAIL`, `BLOCKED`, `NOT RUN`, `PARTIAL`.
**Giới hạn môi trường:** Audit này là phân tích tĩnh + đối chiếu artifact. **Không** có MT5/MetaEditor trong môi trường làm việc hiện tại, nên mọi test cần runtime (tester, order thật) được đánh dấu `NOT RUN` / `BLOCKED`.

> 🔄 **Cập nhật v2.0.1 (2026-11-13):** code đã đổi (bỏ Breakout, bật TP, thêm equity breaker, sửa breakeven). **Đã compile `0/0` và chạy backtest real-tick thực tế** — kết quả ÂM trên mọi preset (xem `reports/backtests/_v2/V2_BACKTEST_RESULTS.md`). Hash đã cập nhật.

**Source SHA256 (rút gọn 16 ký tự đầu):**

| File | SHA256[0:16] |
|---|---|
| `MQL5/Experts/TM_TrendFollowerScalper.mq5` | `9696E6951A236500` (v2.5) |
| `MQL5/Experts/TM_TrendFollowerScalper.ex5` | `F76C419727E08752` (v2.5, compiled 0/0) |
| `MQL5/Experts/TM_TrendFollowerScalper.ex5` | `B6EC2DAED291B047` |
| `MQL5/Include/TM_EA/Types.mqh` | `49A7443740C05E2A` (v2.1) |
| `MQL5/Include/TM_EA/Inputs.mqh` | `2620B7BAA5C36A49` (v2.5) |
| `MQL5/Include/TM_EA/SymbolSpecs.mqh` | `6D2BA261EA3CAAB4` |
| `MQL5/Include/TM_EA/Logger.mqh` | `2744AD6F335F4158` |
| `MQL5/Include/TM_EA/TrendFilter.mqh` | `FE7390BFBFCADA35` (v2.4, +slope) |
| `MQL5/Include/TM_EA/EntryEngine.mqh` | `4495A5A2630FAA27` (v2.4, +reclaim) |
| `MQL5/Include/TM_EA/InitialStop.mqh` | `0C537532C956341E` |
| `MQL5/Include/TM_EA/RiskManager.mqh` | `CA74C90DAB797D70` |
| `MQL5/Include/TM_EA/TradeExecutor.mqh` | `14C2C0D3D93FDC33` (v2.5, +ClosePartial) |
| `MQL5/Include/TM_EA/TrailingEngine.mqh` | `E046E6415D775206` (v2.2, ATR-gated breakeven) |
| `MQL5/Include/TM_EA/RiskGuard.mqh` | `EDABC9060B237D0A` (v2.0, +breaker) |

---

## 1. Audit CopyBuffer / CopyClose / CopyRates / array indexing

Không có `CopyRates` trong source. Toàn bộ dữ liệu giá dùng `iOpen/iHigh/iLow/iClose/iTime` hoặc `CopyBuffer`/`CopyClose`.

| Vị trí | Call | Kích thước | Index dùng | Đánh giá |
|---|---|---|---|---|
| `TrendFilter::Refresh` | `CopyBuffer(hFastEma,0,0,2,…)` | 2 | `[1]` | PASS (static) — `[1]` = nến HTF đã đóng |
| `TrendFilter::Refresh` | `CopyBuffer(hSlowEma,0,0,2,…)` | 2 | `[1]` | PASS (static) |
| `TrendFilter::Refresh` | `CopyBuffer(hAdx,0,0,2,…)` | 2 | `[1]` | PASS (static) |
| `TrendFilter::Refresh` | `CopyClose(sym,tf,0,2,…)` | 2 | `[1]` | PASS (static) |
| `EntryEngine::EvaluatePullback` | `CopyBuffer(hPullbackEma,0,0,2,…)` | 2 | `[1]` | PASS (static) |
| `EntryEngine::EvaluatePullback` | `iOpen/High/Low/Close/Time(…,1)` | — | shift 1 | PASS (static) |
| `EntryEngine::EvaluateBreakout` | `CopyBuffer(hPullbackEma,0,0,3,…)` | 3 | `[1]`,`[0]` | PASS (static) — `[1]`=bar1 (đóng), `[0]`=bar2 |
| `EntryEngine::EvaluateBreakout` | `iHigh/iLow(…,2)`, `iOpen/Close/Time(…,1)` | — | shift 1,2 | PASS (static) |
| `InitialStop::ATRValue` | `CopyBuffer(hATR,0,0,2,…)` | 2 | `[1]` | PASS (static) |

**Return-count guard:** mọi `CopyBuffer`/`CopyClose` đều kiểm tra `!= N` và fail an toàn (trả về tín hiệu invalid / `0.0`). Có thêm `BarsCalculated()` guard trước khi copy. → PASS (static).

**Kết luận mục 1:** PASS (static). Không phát hiện out-of-range hay copy thiếu guard.

---

## 2. Xác minh shift 0 và shift 1 (quy ước nến đã đóng)

- `shift 0` = nến **đang chạy** (có thể chưa đóng). `shift 1` = nến **vừa đóng**.
- **Toàn bộ quyết định tín hiệu** (trend, pullback, breakout, ATR, SL reference) dùng `shift 1` (hoặc `[1]`). Không có tín hiệu nào đọc `shift 0`.
- `shift 0` chỉ xuất hiện ở: `iTime(_Symbol, Entry_Timeframe, 0)` trong `OnTick`/`OnInit` để phát hiện **nến mới** (so sánh với `g_lastEntryBarTime`) — đây không phải đọc tín hiệu mà là trigger "đã sang nến mới". → đúng mục đích.
- Trailing chạy trên tick dùng `Bid`/`Ask` live, không dùng nến → đúng như ARCHITECTURE §2 rule 9.

**Kết luận mục 2:** PASS (static) — tất cả tín hiệu dùng cùng một quy ước nến đã đóng (`shift 1`).

---

## 3. Đồng bộ timestamp EMA / ADX / ATR / OHLC

| Chỉ báo | Nguồn | Bar dùng | Timestamp |
|---|---|---|---|
| EMA nhanh/chậm | `TrendFilter` (HTF) | `[1]` | cùng nến HTF đã đóng |
| ADX | `TrendFilter` (HTF) | `[1]` | cùng nến HTF đã đóng |
| Close HTF | `CopyClose` (HTF) | `[1]` | cùng nến HTF đã đóng |
| EMA pullback / slope | `EntryEngine` (entry TF) | `[1]` / `[1]`,`[0]` | cùng nến entry đã đóng |
| OHLC entry | `iOpen/High/Low/Close` (entry TF) | `1` (và `2` cho prev high/low) | cùng nến entry đã đóng |
| ATR (SL & trailing distance) | `InitialStop::ATRValue` (entry TF) | `[1]` | cùng nến entry đã đóng |

Các buffer trong cùng một hàm được copy với cùng `start=0,count=N`, nên index `[1]` luôn trỏ tới **cùng một cây nến** giữa EMA/ADX/Close/OHLC. → PASS (static).

**Kết luận mục 3:** PASS (static) — timestamp nhất quán trên cùng khung.

---

## 4. Indicator handle lifecycle

- Tạo handle trong `Init()`, release trong `Deinit()` (`TrendFilter::Deinit`, `EntryEngine::Deinit`).
- ATR handle dùng static dùng lại, release qua `CInitialStop::ReleaseATRHandle()` trong `OnDeinit`.
- `InitialStop::ATRValue` có logic tái tạo handle khi `symbol/timeframe/period` đổi (release handle cũ trước). → PASS (static).

---

## 5. ATR source mismatch — `ATR_Channel_Period` là input chết — `[v2.0: ĐÃ XỬ LÝ BẰNG CÁCH BỎ]`

**Phát hiện (FAIL):**

- `SOURCE_SPEC_V1.md` §4.2.2 yêu cầu breakout dùng `ATR_Channel` = ATR(`ATR_Channel_Period`) trên khung entry.
- Trong `TM_TrendFollowerScalper.mq5` dòng 178: `atrValue = CInitialStop::ATRValue(_Symbol, Entry_Timeframe, Trail_ATR_Period);` → breakout dùng **`Trail_ATR_Period`**, không phải `ATR_Channel_Period`.
- `ATR_Channel_Period` được khai báo (`Inputs.mqh` dòng 25) nhưng **không đọc ở bất kỳ đâu** trong source (grep: chỉ xuất hiện trong inputs và preset). Input chết.
- Hệ quả: khi người dùng đổi `Trail_ATR_Period`, khoảng breakout `k*ATR` cũng đổi theo. Với default cả hai = 14 nên trùng nhau → lỗi ẩn.

**Khuyến nghị:** hoặc dùng `ATR_Channel_Period` cho breakout (đúng spec), hoặc bỏ input và ghi rõ breakout dùng chung ATR với trailing. Không tự ý sửa vì chưa có test để chứng minh tác động lên kết quả.

---

## 6. Audit NewsFilter trong Strategy Tester

**Phát hiện (FAIL / BLOCKED):**

- `RiskGuard::CanOpenNewEntry` (dòng 177-213): khi `newsEnable`, gọi `CalendarValueHistory`. Nếu `< 0` (calendar không khả dụng) → **chỉ chặn fail-safe khi KHÔNG phải tester**:
  ```
  if(!((bool)MQLInfoInteger(MQL_TESTER))) { reason="news calendar unavailable"; return false; }
  ```
- Trong Strategy Tester, calendar lịch sử **không** được cấp → `CalendarValueHistory` lỗi → code **bỏ qua** và cho phép vào lệnh.
- **Kết luận:** `News_Enable=true` **không có tác dụng** trong mọi backtest. Không có historical news-data adapter nào được xây dựng.
- Đánh đổi này có chủ đích (changelog v1.2) để tester chạy được, nhưng nghĩa là chưa từng có backtest nào thực sự kiểm tra news filter.

**Hành động cần:** P1.5 yêu cầu "xây dựng historical news-data adapter nếu cần". **Chưa xây dựng** → BLOCKED cho tới khi có adapter (ví dụ: file CSV sự kiện import vào tester, hoặc dùng `CalendarValueHistory` khi chạy trên terminal live/demo).

---

## 7. Symbol filling mode, order retcodes, partial execution

**Phát hiện (FAIL):**

- `TradeExecutor::Init` **hard-code** `m_trade.SetTypeFilling(ORDER_FILLING_FOK)` (dòng 31).
  - Không đọc `SYMBOL_FILLING_MODE` từ broker. Nếu broker/symbol (ví dụ XAUUSDm trên Exness) chỉ hỗ trợ `ORDER_FILLING_IOC`, lệnh sẽ bị từ chối với retcode `TRADE_RETCODE_INVALID_FILL (10030)`.
  - Backtest dùng FOK và **có** khớp lệnh, nhưng đây không đảm bảo cho live/demo với symbol/account khác.
- Retcode: `OpenBuy/OpenSell` kiểm tra `ResultRetcode() != TRADE_RETCODE_DONE` → pass. NHƯNG `TRADE_RETCODE_PLACED`/`TRADE_RETCODE_DONE_PARTIAL` không được xử lý riêng.
- Partial execution: với FOK thì không partial; nhưng nếu chuyển sang IOC, chưa có logic xử lý khớp một phần.
- `OnTradeTransaction` (dòng 318-323) vẫn là **placeholder** — chưa có position tracking theo transaction.

**Kết luận mục 7:** FAIL — cần chọn filling mode động và xử lý retcode/partial.

---

## 8. RiskGuard — phục hồi trạng thái sau terminal restart

**Phát hiện (FAIL):**

Phần **được persist** (tốt):
- Daily baseline: `TM_EA_DailyBaseline_*` (GlobalVariable) — sống qua restart. → PASS.
- Daily date: `TM_EA_DailyDate_*` → reset baseline theo ngày server. → PASS.
- Cooldown: `TM_EA_CooldownUntil_*` → sống qua restart. → PASS.
- Consecutive losses: `TM_EA_ConsecutiveLosses_*` → sống qua restart. → PASS.

Phần **KHÔNG được persist** (bug):
- `m_lastProcessedDeal` khởi tạo `0` trong `Init()`. Sau restart, `RefreshClosedTradeHistory` quét lại **toàn bộ** OUT-deals từ đầu ngày và **cộng dồn lại** vào `ConsecutiveLosses` đã lưu → **đếm trùng chuỗi thua**, có thể kích cooldown sai.
- Ngoài ra, một lệnh đóng bằng nhiều partial-close sinh nhiều `DEAL_ENTRY_OUT` → mỗi phần lỗ bị tính là một "consecutive loss".

**Kết luận mục 8:** FAIL — daily/cooldown recover đúng, nhưng bộ đếm consecutive-loss không idempotent qua restart.

---

## 9. SessionFilter, spread, margin, symbol parameters

| Hạng mục | Thực tế | Đánh giá |
|---|---|---|
| Spread check | `(Ask-Bid)/Point > Max_Spread_Points` | PASS (static) |
| Session filter | hard-code `day_of_week 1..5`, `hour 7..20` server time | PARTIAL — chưa có xử lý DST; giờ cứng chưa tài liệu hoá theo broker offset |
| Margin check | `OrderCalcMargin` với `Min_Volume` (không phải volume thật) | PARTIAL — dùng volume min thay vì volume tính được → ước lượng margin thấp hơn thực |
| Symbol specs | `SymbolSpecs::Refresh` đọc point/tick/volume/stops/freeze/trade_mode | PASS (static) |
| Trade allowed | `SYMBOL_TRADE_MODE` != DISABLED | PASS (static) |

---

## 10. Cost model trong tính volume (đối chiếu SOURCE_SPEC §4.4 bước 3)

**Phát hiện (PARTIAL):** `RiskManager::CalculateVolume` ước tính lỗ tại SL bằng `OrderCalcProfit(...)`. **Không** cộng thêm spread hiện tại + commission ước tính như spec yêu cầu (bước 3). Với các backtest hiện tại (commission = 0, spread đã phản ánh trong tick), con số khớp; nhưng trên broker ECN có commission, risk thực sẽ **vượt** risk cap.

---

## 11. Tổng hợp trạng thái P1

| # | Hạng mục | Trạng thái |
|---|---|---|
| 1 | CopyBuffer/CopyClose/indexing | PASS (static) |
| 2 | Shift 0 / shift 1 | PASS (static) |
| 3 | Đồng bộ timestamp EMA/ADX/ATR/OHLC | PASS (static) |
| 4 | Indicator handle lifecycle | PASS (static) |
| 5 | ATR source (`ATR_Channel_Period`) | **RESOLVED v2.0** — input + Breakout đã bỏ |
| 6 | NewsFilter trong tester / adapter | **FAIL / BLOCKED** |
| 7 | Filling mode / retcodes / partial | **FAIL** |
| 8 | RiskGuard restart recovery | **FAIL** (consecutive-loss) |
| 9 | Session/spread/margin/symbol | PARTIAL |
| 10 | Cost model (spread+commission trong sizing) | PARTIAL (BUG-007 mở) |
| 11 | Take Profit đúng phía (v2.0) | PASS (static) — `TP = entry ± TP_ATR_Mult*ATR` |
| 12 | Equity circuit breaker (v2.0) | PASS (static) — close-all + flag persist; chưa runtime |

**Không có hạng mục nào ở trạng thái PASS-runtime.** Trạng thái "PASS (static)" nghĩa là logic đúng khi đọc source, chưa chạy kiểm chứng trên MT5.

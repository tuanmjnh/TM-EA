# MT5 EA - TREND FOLLOWER SCALPER (BÀO LỢI NHUẬN)
**Phiên bản:** 1.0
**Ngày:** 2026-11-11
**Nền tảng:** MetaTrader 5 (MQL5)
**Phong cách:** Scalping khung nhỏ, trend-following, no take-profit

---

## 1. TÓM TẮT MỤC TIÊU
EA chạy tự động trên MT5 với nhiệm vụ:
- Hoạt động ổn định với **số vốn tối thiểu ~50 USD** (không yêu cầu nạp lớn).
- Xác định **xu hướng** bằng bộ lọc khung lớn, chỉ giao dịch theo chiều trend.
- Tìm **điểm vào lệnh** theo 2 cơ chế (pullback + breakout) ở khung nhỏ.
- **Không đặt Take Profit** - thay vào đó dùng **Trailing Stop động** để ôm lợi nhuận theo sóng xu hướng.
- **Vào lệnh liên tục** (chuỗi lệnh "bào" theo từng nhịp sóng) khi điều kiện trend + entry lặp lại.
- Ưu tiên **giảm rủi ro** tuyệt đối để bảo vệ vốn mỏng: SL luôn bật, có giới hạn thua/ngày, có news filter, chặn spread lớn.

> TRIẾT LÝ CỐT LÕI: EA này **không dự đoán đỉnh/đáy**. Nó đi theo xu hướng, cắt lỗ nhanh khi sai, và để lệnh đúng chạy tới khi giá quay đầu chạm trailing stop. Chấp nhận tỷ lệ thắng thấp (35-45%) bù bằng lệnh thắng lớn.

---

## 2. YÊU CẦU KỸ THUẬT (REQUIREMENTS)

### 2.1. Vốn & tài khoản
| Hạng mục | Giá trị | Ghi chú |
|---|---|---|
| Vốn tối thiểu | 50 USD | Khuyến nghị 50-200 USD |
| Loại lot | **Micro lot (0.01)** | Bắt buộc - lot nhỏ nhất |
| Loại tài khoản | ECN/Raw nếu có, spread thấp | Spread cao sẽ ăn hết lợi nhuận lệnh nhỏ |
| Cặp giao dịch | XAUUSD (vàng), EURUSD | Vàng ưu tiên - hợp sở thích commodity |
| Khung chính | M1 / M5 (entry) | Cấu hình được |
| Khung xu hướng | M15 / M30 (filter) | Cấu hình được |

### 2.2. Quy tắc bất biến (không được phép vi phạm)
1. **Luôn có Stop Loss** - không bao giờ mở lệnh không SL.
2. **KHÔNG có Take Profit** - tắt hẳn; thoát lệnh chỉ qua trailing stop hoặc stop ngược.
3. **CẤM martingale / grid / gấp lệnh** - mỗi lệnh rủi ro cố định % vốn, không tăng lot sau khi thua.
4. **CẤM vào lệnh khi có tin lớn** - news filter bắt buộc.
5. **CẤM vào lệnh khi spread vượt ngưỡng** - tránh bị cắn phí.

---

## 3. KIẾN TRÚC (ARCHITECTURE)
EA chia thành các module độc lập, mỗi module 1 chức năng rõ ràng:

┌────────────────────────────────────────────┐ │ 1. TREND FILTER (xác định xu hướng) │ │ - EMA trên khung lớn (M15/M30) │ │ - ADX đo độ mạnh xu hướng │ ├────────────────────────────────────────────┤ │ 2. ENTRY LOGIC (tìm điểm vào) │ │ - Pullback về EMA khung nhỏ │ │ - Breakout qua kênh ATR │ ├────────────────────────────────────────────┤ │ 3. EXIT LOGIC (thoát lệnh) │ │ - Trailing Stop theo ATR (động) │ │ - KHÔNG dùng TP │ ├────────────────────────────────────────────┤ │ 4. MONEY MANAGEMENT (quản lý vốn) │ │ - Risk cố định %/lệnh │ │ - Tính lot theo stop distance │ ├────────────────────────────────────────────┤ │ 5. RISK GUARD (bảo vệ vốn) │ │ - News filter │ │ - Max daily loss / max consecutive lose │ │ - Max spread check │ │ - Max concurrent positions │ └────────────────────────────────────────────┘ ↑────── 6. CORE/TRADER (điều phối) ────┘


Dòng chảy xử lý mỗi tick/thanh:
1. **Risk Guard** kiểm tra: đang có tin? spread vượt ngưỡng? đã chạm max daily loss? → nếu vi phạm, **KHÔNG mở lệnh mới**.
2. **Trend Filter** trả về hướng: `UPTREND / DOWNTREND / SIDEWAYS`.
3. Nếu có trend rõ → **Entry Logic** xét điều kiện pullback hoặc breakout ở khung nhỏ.
4. Điều kiện vào đúng → **Money Management** tính lot theo risk%.
5. **Mở lệnh** với SL (chưa có TP).
6. Khi lệnh đang mở → **Exit Logic** cập nhật trailing stop mỗi tick/thanh.

---

## 4. CHI TIẾT TỪNG MODULE

### 4.1. TREND FILTER (Xác định xu hướng)
Mục tiêu: chỉ nhận lệnh cùng chiều xu hướng lớn, tránh đánh ngược.

Tham số:
- `Trend_Timeframe` = M15 hoặc M30 (cấu hình).
- `FastEMA` = 50, `SlowEMA` = 200 trên khung xu hướng.
- `ADX_Period` = 14, `ADX_Threshold` = 25.

Xác định:
- **UPTREND** nếu: `FastEMA > SlowEMA` VÀ `ADX > 25` VÀ giá đóng trên FastEMA.
- **DOWNTREND** nếu: `FastEMA < SlowEMA` VÀ `ADX > 25` VÀ giá đóng dưới FastEMA.
- **SIDEWAYS** nếu không thỏa điều kiện trên → KHÔNG giao dịch.

Quy tắc:
- Chỉ mở **BUY** khi UPTREND, chỉ mở **SELL** khi DOWNTREND.
- Sideways = đứng ngoài; KHÔNG đánh hai chiều.
- Bộ lọc này là "cổng" - nếu không có trend rõ, EA im lặng.

> Gợi ý: ADX có thể hiển thị giá trị trung bình của 14/25/50 trong dashboard để người dùng thấy độ mạnh trend.

### 4.2. ENTRY LOGIC (Tìm điểm vào lệnh)
Hai cơ chế vào lệnh, cấu hình bật/tắt từng cái.

#### 4.2.1. Chế độ PULLBACK (ưu tiên, R:R tốt hơn)
- Khung entry: `Entry_Timeframe` = M1 hoặc M5.
- `PullbackEMA` = EMA 20 trên khung entry.
- Điều kiện vào **BUY**: xu hướng = UPTREND, và:
    - Giá **pullback (hồi)** chạm/vượt xuống vùng `PullbackEMA` (hoặc khoảng `PullbackBuffer_pips` quanh EMA).
    - Sau đó có **nến đóng xác nhận** quay lên (close > open nến hiện tại, hoặc close > thân nến pullback).
- Điều kiện vào **SELL** đối xứng (giá hồi lên EMA rồi nến đóng xuống).

#### 4.2.2. Chế độ BREAKOUT (tăng tần suất lệnh)
- Dùng **ATR channel**: `ATR_Channel` = ATR(14) trên khung entry.
- Điểm vào **BUY**: giá **phá trên** đỉnh của nến trước + k*ATR (k = `BreakoutK`, mặc định 0.5-1.0), kèm nến đóng trên mức đó.
- Điểm vào **SELL**: giá phá dưới đáy + k*ATR.
- Breakout cho nhiều lệnh hơn nhưng dễ trúng giả breakout → lọc thêm bằng độ dốc EMA (EMA20 dốc lên/xuống) xác nhận.

#### 4.2.3. Điều kiện chung
- Chỉ tính tín hiệu khi **nến khung entry mới ĐÓNG** (không vào giữa nến để tránh nhiễu).
- Tính năng **Vào lệnh liên tục**: sau khi một lệnh bị trailing stop quét trong khi xu hướng vẫn còn, EA đợi điều kiện entry kế tiếp lặp lại rồi **mở lệnh mới cùng chiều** ("bào" theo sóng). Không giới hạn tổng chuỗi, chỉ giới hạn bởi `Max_Concurrent_Positions`.

---

### 4.3. EXIT LOGIC (Thoát lệnh - Trailing Stop, KHÔNG TP)
Mục tiêu: ôm lợi nhuận theo xu hướng, cắt khi giá quay đầu.

Cơ chế:
- **Trailing Stop động tính theo ATR** kèm **cỡ bước** (step).
- Mỗi tick/thanh mới cập nhật:
    - `TrailDistance = Trail_ATR_Mult * ATR(14) trên Entry_Timeframe`.
    - Sau khi giá chạy có lãi ≥ `Activate_After_Profit_pips` (mặc định 3-5 pips), kích hoạt trailing.
    - Vị trí SL mới = `Bid - TrailDistance` (BUY) hoặc `Ask + TrailDistance` (SELL), làm tròn theo tick size, **chỉ dịch về phía có lợi** (không bao giờ lùi SL).
    - Dùng `Trail_Step_pips` để tránh spam lệnh sửa mỗi tick: chỉ sửa khi SL mới chênh nhiều hơn bước này.
- **KHÔNG có TakeProfit** → tham số TP để rỗng/không gửi.

Hành vi khi trend mạnh:
- ATR nở lớn → trailing rộng → lệnh chịu được cú rung không lao lỗ, sóng lớn bắt trọn.
- Khi đảo chiều mạnh → giá quay chạm trailing → đóng lệnh với lãi còn giữ lại.

> LƯU Ý: vì không có TP nên lệnh có thể quay về gần điểm hòa vốn trước khi bị quét. Có thể thêm tùy chọn "trailing đưa **SL về break-even** sau khi có lãi ≥ X pips" để đảm bảo không biến lệnh thắng thành lỗ.

---

### 4.4. MONEY MANAGEMENT (Quản lý vốn - số vốn nhỏ)
Mục tiêu: mỗi lệnh rủi ro cố định, phù hợp vốn 50 USD.

Công thức tính lot:

risk_money = Balance RiskPercentPerTrade / 100 stop_loss_pips = |Entry - SL| / Point volume = risk_money / (stop_loss_pips tick_value_per_lot) volume = clamp(volume, Min_Volume, Max_Volume) // Min thường 0.01 Mt5SetSymbolInfo double cho tick value, làm tròn xuống đúng step volume.


Tham số:
- `RiskPercentPerTrade` = 0.5% – 1.0% mặc định (0.5% cho vốn mỏng, ~$0.25-0.5/lệnh khi 50u).
- `Min_Volume` = 0.01, `Max_Volume` = 0.05 (hoặc theo yêu cầu).
- Luôn ép lot xuống mức tối thiểu broker cho phép nếu risk% tính ra nhỏ hơn.

Nguyên tắc:
- **KHÔNG tăng lot sau khi thua** (cấm martingale).
- **KHÔNG tăng lot khi có nhiều lệnh mở** - mỗi lệnh độc lập với cùng risk%.
- Tổng vốn dùng đồng thời giới hạn bởi `Max_Concurrent_Positions`.

---

### 4.5. RISK GUARD (Bảo vệ vốn)
Ngăn chặn các điều kiện phá hủy tài khoản:

1. **News Filter:**
    - Đọc từ lịch tin tức (CalendarEvent); chặn mở lệnh mới trong `Min_News_Buffer_Minutes` (mặc định 15-30 phút) quanh tin có độ ảnh hưởng cao (CPI, FOMC, NFP, Nonfarm).
    - Lệnh đang mở có thể vẫn được phép trailing, hoặc tạm "neo" trailing trong lúc tin theo cấu hình.
2. **Max Daily Loss:** nếu tổng PnL hôm nay ≤ `Max_Daily_Loss_Percent` (mặc định -5%) → **dừng giao dịch hết ngày**.
3. **Max Consecutive Losses:** nếu thua liên tiếp `Max_Consecutive_Losses` (mặc định 3-5) lệnh → tạm nghỉ `CoolDown_Minutes` rồi mới vào lại.
4. **Max Concurrent Positions:** giới hạn số lệnh mở cùng lúc (`Mặc định 1-3`).
5. **Max Spread Check:** chặn mở lệnh khi `(Ask-Bid)/Point > Max_Spread_Points` (mặc định 30-40) - tránh bị cắn spread giờ tin/giờ đêm.
6. **Max Slippage:** đặt slippage tối đa khi mở lệnh.
7. **Session Filter (tùy chọn):** chỉ giao dịch trong giờ thanh khoản cao (phiên London/New York cho forex; giờ mở cửa cho vàng).

---

## 5. THAM SỐ CẤU HÌNH (INPUT PARAMETERS)
Bảng đầy đủ để đưa vào `input` MQL5 trong tab Inputs:

| Tên tham số | Kiểu | Giá trị mặc định | Mô tả |
|---|---|---|---|
| `Enabled` | bool | true | Bật/tắt EA |
| `MagicNumber` | int | 123456 | Nhận diện lệnh của EA |
| **Trend** ||||
| `Trend_Timeframe` | ENUM_TIMEFRAMES | PERIOD_M15 | Khung xác định xu hướng |
| `FastEMA_HTF` | int | 50 | EMA nhanh khung trend |
| `SlowEMA_HTF` | int | 200 | EMA chậm khung trend |
| `ADX_Period` | int | 14 | Chu kỳ ADX |
| `ADX_Threshold` | double | 25.0 | Ngưỡng độ mạnh trend |
| **Entry** ||||
| `Entry_Timeframe` | ENUM_TIMEFRAMES | PERIOD_M5 | Khung vào lệnh |
| `Entry_Mode` | int | 1 | 1=Pullback, 2=Breakout, 3=Both |
| `PullbackEMA` | int | 20 | EMA pullback khung entry |
| `Pullback_Buffer_pips` | int | 2 | Dung sai quanh EMA |
| `ATR_Channel_Period` | int | 14 | Chu kỳ ATR kênh breakout |
| `BreakoutK` | double | 0.7 | Hệ số k*ATR |
| **Exit (Trailing)** ||||
| `Use_TP` | bool | false | **Luôn false - không TP** |
| `Trail_ATR_Mult` | double | 2.0 | Khoảng trailing = mult*ATR |
| `Trail_ATR_Period` | int | 14 | Chu kỳ ATR cho trailing |
| `Activate_After_Profit_pips` | double | 4.0 | Kích hoạt trailing sau lãi ≥ này |
| `Trail_Step_pips` | double | 2.0 | Bước sửa SL tối thiểu |
| `Breakeven_After_pips` | double | 8.0 | Đưa SL về hòa vốn sau lãi ≥ này |
| **Risk / MM** ||||
| `RiskPercentPerTrade` | double | 0.5 | % vốn rủi ro/lệnh |
| `Min_Volume` | double | 0.01 | Lot tối thiểu |
| `Max_Volume` | double | 0.05 | Lot tối đa |
| `Max_Concurrent_Positions` | int | 2 | Số lệnh mở đồng thời tối đa |
| **Risk Guard** ||||
| `Max_Daily_Loss_Percent` | double | 5.0 | Dừng ngày khi lỗ ≤ -5% |
| `Max_Consecutive_Losses` | int | 4 | Nghỉ sau chuỗi thua |
| `CoolDown_Minutes` | int | 30 | Thời gian nghỉ |
| `Max_Spread_Points` | int | 35 | Chặn vào lệnh khi spread lớn |
| `News_Enable` | bool | true | Bật news filter |
| `News_Buffer_Minutes` | int | 20 | Chặn quanh tin |
| `Use_Session_Filter` | bool | true | Chỉ giao dịch khung giờ tốt |

---

## 6. CÁC HÀM MQL5 CẦN TRIỂN KHAI (PSEUDO-STRUCTURE)

// Khởi tạo: xác nhận symbol, tính tick value int OnInit();

// Mỗi tick: cập nhật trailing của mọi lệnh đang mở void OnTick();

// Mỗi nến khung entry đóng: scan tín hiệu void ProcessNewBar();

// 1) Xu hướng bool IsUptrend(); bool IsDowntrend(); bool IsSideways();

// 2) Điều kiện vào bool PullbackBuyCondition(); bool BreakoutBuyCondition(); bool PullbackSellCondition(); bool BreakoutSellCondition();

// 3) Mở lệnh void OpenBuy(double sl); void OpenSell(double sl);

// 4) Trailing void UpdateTrailingStops(); // duyệt lệnh magic, cập nhật SL double ATRValue(ENUM_TIMEFRAMES tf, int period);

// 5) Quản lý vốn double CalcVolume(double stop_pips);

// 6) Bảo vệ bool IsNewsBlocked(); bool HitDailyLoss(); double CurrentSpread(); bool CanOpenNewPosition();

// 7) Tiện ích double NormalizePrice(double price, int digits); int CountOpenPositions(); double DayPnL();


---

## 7. CHẠY THỬ & BACKTEST (BẮT BUỘC)
Trước khi dùng thật, EA phải được kiểm định:

1. **Backtest chuẩn:** dùng MT5 Strategy Tester, mô hình **"Every tick based on real ticks"** (không dùng "1 minute OHLC" - dữ liệu giả cho kết quả sai lệch).
2. **Có tính spread/phí:** chọn sàn thật với spread+commission tương đương tài khoản. Ảo nếu spread = 0.
3. **Khoảng thời gian dài:** tối thiểu 6-12 tháng, qua cả trend mạnh lẫn sideways + tin lớn.
4. **Multi-symbol test:** kiểm trên XAUUSD và EURUSD để phát hiện "curve-fit" (EA chỉ tốt 1 cặp/năm = dấu hiệu xấu).
5. **Chỉ số chấp nhận:** 
    - MDD (drawdown tối đa) < 20%.
    - Profit factor ≥ 1.3.
    - Tỷ lệ thắng 35-45% là BÌNH THƯỜNG cho trend-following (đừng tin EA báo thắng 80% - đó là martingale).
6. **Forward test:** chạy demo 2-4 tuần sau khi backtest đạt, theo dõi trước khi nạp tiền thật.

---

## 8. TRIỂN KHAI (DEPLOYMENT)
1. Đặt file `.mq5` vào thư mục `MQL5/Experts/` và biên dịch (F7).
2. Kéo EA lên chart cặp mong muốn (XAUUSD hoặc EURUSD), khung = `Entry_Timeframe`.
3. Điền đúng tham số theo mục 5.
4. **Kiểm tra "Allow Algo Trading" bật**, và `Tools > Options > Expert Advisors > Allow Algo Trading` = on.
5. Trước khi chạy thật, chạy demo 2-4 tuần.
6. Kiểm định lại sau mỗi tháng - kết quả thay đổi theo điều kiện thị trường.

---

## 9. KHÔNG GIAN PHÁT TRIỂN (ROADMAP - tùy chọn)
- Thêm **EMA dốc (slope)** làm bộ lọc phụ chống giả breakout.
- Thêm **ATR trailing thích nghi theo cấp** (rộng dần khi lãi nhiều).
- In **bảng dashboard** lên chart: hướng trend, ADX, spread hiện tại, số lệnh mở, PnL hôm nay, trạng thái (đang khóa/news).
- Hỗ trợ **multi-symbol** (quét vài cặp cùng lúc) với bộ đếm risk chung.
- Tùy chọn chuyển sang đa khung 3 lớp (MN trend, HTF, LTF entry) để nâng độ chắc.

---

## 10. CẢNH BÁO RỦI RO (DÀNH CHO NGƯỜI DÙNG)
- Vốn 50 USD rất mỏng; 1-2 cú thua lớn có thể ăn hết 5-10% - chỉ dùng tiền bạn chấp nhận mất.
- Trend-following có chuỗi thua nhiều lệnh nhỏ - cần kỷ luật, không tăng lot gỡ.
- Không có EA nào "ăn chắc" mọi chế độ thị trường; sideway kéo dài sẽ tiêu hao tài khoản qua spread.
- Luôn chạy demo/backtest đạt trước khi nạp tiền thật.
SCOPE TRENDLINE BOLLINGER (STB) - FULL SPEC & TEST ROADMAP
Dành cho AI lập trình MQL5 / MT5. Mục tiêu: 1 EA hoàn chỉnh, test được, tránh overfit.

1. MÔ TẢ TỔNG QUAN
Cặp: XAUUSD (gold) - primary. Thiết kế cho cả crypto nhưng ưu tiên tối ưu gold.
Timeframe chính: M5 (entry). Timeframe lọc: H1 + D1 (bias).
Phong cách: scalping trend-follow, no TP cứng, trailing bằng ATR.
Triết lý: chỉ vào 1 chiều theo bias khung lớn, dùng Trendline + Bollinger Bands làm tín hiệu đồng thuận trên M5.
2. KIẾN TRÚC 3 TẦNG
Tầng	Khung	Nhiệm vụ	Công cụ
Regime/Bias	D1 + H1	Xác định xu hướng + loại sideway	EMA nhanh/chậm + ADX + phiên
Signal	M5	Tìm điểm vào lệnh hợp lệ	Trendline + Bollinger Bands
Execution	M5	Vào/đi SL, trail, re-entry	ATR trailing, risk %
3. CHI TIẾT TỪNG TẦNG
3.1 REGIME/BIAse (D1 + H1)
D1: ADX(14) > 20 (có trend) và EMA50 > EMA200 (uptrend) hoặc ngược lại (downtrend).
H1: xác nhận EMA20 > EMA50 theo cùng chiều D1.
Phiên: chỉ trade phiên London (08:00–16:00) và NY (13:30–21:00) theo giờ server; bỏ phiên Á.
Output: bias = +1 (long) | -1 (short) | 0 (sideway/no trade).
3.2 TÍN HIỆU TRENslope + BOLLINGER (M5)
Bollinger Bands: Period 20, Deviation 2.0, dùng Close.
Trendline: auto-detect 2 swing point gần nhất (swing high/low, min 5 nến cách nhau), vẽ đường nối.
Quy tắc LONG (bias=+1): 1. Giá nằm trên dải giữa BB (xu hướng tăng sóng tính trên M5). 2. Giá hồi về dải giữa hoặc dải dưới rồi đóng nến quay lại trên dải giữa. 3. Cùng lúc giá phá lên trên trendline (breakout).
Quy tắc SHORT (bias=-1): ngược lại (dưới dải giữa, phá xuống trendline).
Từ chối vào lệnh: bias=0, hoặc chỉ 1 trong 2 tín hiệu xuất hiện đơn lẻ - bắt buộc đồng thuận cả 2.
3.3 QUẢN LÝ LỆNH
Entry: Market Order ngay sau nến xác nhận đóng cửa.
Stop Loss: chia theo độ dài chân hồi * hoặc ATR(14)x1.5, đặt dưới swing gần nhất.
Take Profit: KHÔNG TP cứng.
Trailing: sau khi có lời ≥ 1.0x ATR, kích hoạt trailing ATR x 1.2 (theo giá đóng).
Re-entry ("bào"): sau khi trailing dừng lệnh, nếu bias & tín hiệu BB+Trendline còn hợp lệ thì vào lại cùng chiều.
Giới hạn rủi ro: risk 1%/lệnh (hoặc cố định $ cho tài khoản nhỏ), max 1 lệnh cùng lúc, daily loss cap 4%.
4. TOÀN BỘ INPUT (AI CẦN ĐỌC TỪ input)
Symbol               = XAUUSD
LotType              = risk_percent | fixed
RiskPercent          = 1.0
FixedLot             = 0.01
BB_Period            = 20
BB_Deviation         = 2.0
ATR_Period           = 14
ADX_Period           = 14
ADX_Threshold        = 20
HTF_EMA_Fast         = 20
HTF_EMA_Slow         = 50
D1_EMA_Fast          = 50
D1_EMA_Slow          = 200
LondonStart          = 8
LondonEnd            = 16
NYStart              = 13
NYEnd                = 21
UseSessionFilter     = true
Trail_ATR_Mult       = 1.2
SL_ATR_Mult          = 1.5
TrailActivate_ATR    = 1.0
DailyLossCapPct      = 4.0
MaxSpreadPts         = (tùy cặp, gold thường 20-35)
ReEntryEnabled       = true
Tất cả input phải là input group trong MQL5 để AI tối ưu sau này.
Có switch bật/tắt tầng phiên và re-entry để test A/B.
5. TIÊU CHÍ KIỂM THỬ (DỮ LIỆU THẬT, KHÔNG OPTIMIZE Ở PHA ĐẦU)
Backtest M5, tick thật (tick based), ≥ 1 năm: ghi Profit Factor, Max DD %, Win rate, Profit/ATR per trade, số lệnh/tháng, exposure.
Ngưỡng đạt: PF > 1.3, MaxDD < 20%, ≥ 30 lệnh/tháng, tồn tại các năm lỗ nhỏ hơn lời stable.
No curve-fit: trước khi tối ưu, chạy bộ tham số gốc; mới optimize sau khi backtest cơ bản đạt.
6. LỘ TRÌNH 3 PHA
P1 (Ngày 1–2): code xong EA, test logic - đúng tín hiệu trên chart, không lệnh thật.
P2 (Ngày 3–10): backtest tick thật 1–2 năm, log báo cáo; nếu đạt ngưỡng → optimize nhẹ (walk-forward).
P3 (Tuần 2–6): forward demo 2–4 tuần, đối chiếu slippage/spread, chỉ khi khớp backtest ≥ 80% mới tính live $50.
7. CÁC LƯU Ý CHỐng OVERFIT & SAI LẦM
Bẫy chính: Trendline (momentum) vs Bollinger (mean-reversion) bắn ngược nhau - bắt buộc giữ bộ lọc bias, chỉ dùng BB kiểu breakout trong trend.
Tối ưu từng nhóm tham số riêng (BB / ATR trail / SL), không tối ưu tất cả cùng lúc.
Chạy với phí + slippage thật; dữ liệu tick dựa trên spread biến thiên.
8. FILE GIAO CHO AI ĐỂ CODE
Yêu cầu AI trả về: stb_ea.mq5 đầy đủ, có comment khối, log tín hiệu, và stb_backtest_report.xlsx từ Strategy Tester.
Sau khi code xong, chạy theo lộ trình P1→P3 ở trên.
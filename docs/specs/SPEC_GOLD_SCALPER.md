# TM_GoldSweepScalper - Spec bot scalp XAUUSD ổn định ("bào sàn")
Version 1.0 | 2026-11-18 | MT5/MQL5 | XAUUSD / XAUUSDm
Trạng thái: thiết kế để build. KHÔNG cam kết lợi nhuận.

## 1. Triết lý
- Tần suất THẤP, chất lượng cao (rare-fire). Không martingale, không grid, không averaging.
- Hai edge có bằng chứng: (a) Liquidity Sweep + Regime detection, (b) Opening-Range Breakout có kill-zone.
- Mọi nhánh chặn lệnh PHẢI log lý do. Không có "return im lặng".

## 2. Kiến trúc module (.mqh)
1. CSymbolSpecs    - chuẩn hóa point/tick/stop-level/freeze-level/volume-step, tự dò suffix.
2. CTimeService    - TỰ ĐỘNG dò GMT offset; dùng SymbolInfoSessionQuote/SymbolInfoSessionTrade để biết phiên thật.
3. CRegimeEngine   - TREND / RANGE / BREAKOUT với hysteresis (xác nhận + min-hold), dùng EMA/ADX/ATR.
4. CLiquidityMap   - swing, equal highs/lows, Asian range, PDH/PDL, round numbers, failed breakouts.
5. CStrategyHub    - thứ tự ưu tiên: SweepReversal -> ORB -> TrendPullback.
6. CRiskManager    - risk-%/lệnh, OrderCalcProfit, cộng spread + commission, DD room còn lại.
7. CTrailingEngine - breakeven ATR + ATR trail + partial tùy chọn.
8. CGuards         - spread, news, session, daily-loss, equity breaker, cooldown.
9. CLogger         - log MỌI lý do chặn + retcode.

## 3. Quy tắc vào lệnh
### 3.1 Kill-zone theo GIỜ GMT THẬT (convert sang server bằng offset tự dò)
- Asia range: 00:00-07:00 GMT | London KZ: 07:00-10:00 GMT | NY KZ: 12:30-15:00 GMT.
- Dò offset: `int off = (int)MathRound((double)(TimeTradeServer()-TimeGMT())/3600.0);`
- Trước khi gửi lệnh: kiểm tra SymbolInfoSessionTrade - phiên đóng thì bỏ.

### 3.2 Setup A - SweepReversal (ưu tiên)
- Giá quét qua swing high/low (hoặc PDH/PDL) rồi RECLAIM bằng nến M5 đóng.
- Xác nhận: regime RANGE hoặc TREND ngược hướng sweep.
- SL: sau extreme của sweep + buffer ATR(14) x 0.3. TP: RR 1.5-2.5 hoặc ATR trail.

### 3.3 Setup B - Opening-Range Breakout
- Range = [start,end) theo GMT (London 07:00-08:00, hoặc Asia 00:00-07:00).
- Phá range trên NẾN ĐÃ ĐÓNG + buffer 0.1-0.2 x ATR. Wick đơn không tính.
- Lọc: range size trong [Min_Range_ATR, Max_Range_ATR]; ADX(H1) >= 20; tick-volume filter.
- SL = cạnh đối diện range (hoặc ATR x 1.0). TP = RR 2-5 (plateau) hoặc trail.

### 3.4 Gating
- Max 1 vị thế đồng thời. 1 tín hiệu/nến. Tùy chọn 1 lệnh/kill-zone.

## 4. Quản trị rủi ro
| Tham số | Đề xuất |
|---|---|
| RiskPercentPerTrade | 0.25-0.5% khi test -> tối đa 1% |
| Max daily loss | 1.5-2% equity baseline, persist qua restart |
| Equity circuit-breaker | 8-10% DD -> đóng hết + khóa trong ngày |
| Max consecutive losses / cooldown | 3-4 lệnh / 30-60 phút |
| Max spread | cấu hình theo point thật của symbol (gold ~25-40 points) |
| Min_Volume | KHÔNG ép lên min nếu vượt risk -> SKIP và log |

## 5. Xử lý lỗi bắt buộc (chống "im lặng")
- Đọc SYMBOL_FILLING_MODE -> chọn FOK/IOC/RETURN hợp lệ (fix BUG-002).
- Kiểm tra SYMBOL_TRADE_STOPS_LEVEL / FREEZE_LEVEL trước khi gửi SL.
- Log retcode + mô tả cho MỌI OrderSend fail; log lý do cho MỌI nhánh return.
- Kiểm tra BarsCalculated()/CopyBuffer return trước khi dùng indicator.

## 6. Lộ trình kiểm định
1. Compile 0 errors + smoke test (in log offset phát hiện được).
2. Backtest real-tick (Model=4) 3 năm, có commission + slippage + spread thực tế.
3. Cost-stress: chạy lại với phí x2-x3. Report PHẢI khác baseline (tránh BUG-005).
4. Optimize walk-forward IS/OOS, tối đa 4 tham số.
5. Forward demo Cent-account >= 4-8 tuần, theo dõi slippage thực.
6. Chỉ cân nhắc vốn thật khi forward demo ổn định và DD trong ngưỡng.
Tiêu chí pass: PF > 1.3, MaxDD < 20%, >= 3-5 lệnh/tuần, không lỗi retcode.
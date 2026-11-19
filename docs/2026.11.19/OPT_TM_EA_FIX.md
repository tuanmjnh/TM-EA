# OPT - Sửa & tối ưu EA hiện tại (TM_SessionBreakout + TM_TrendFollowerScalper)
Version 1.0 | 2026-11-18

## PHẦN A - Fix lỗi "không vào lệnh" của TM_SessionBreakout (P0)

### A1. Thêm input GMT offset, bỏ giờ server cứng (P0)
- `input int BrokerGMTOffset = 999; // 999 = auto`
- Auto: `off = (int)MathRound((double)(TimeTradeServer()-TimeGMT())/3600.0);`
- Convert mọi mốc: `serverHour = gmtHour + BrokerGMTOffset;`
- Verify phiên: `SymbolInfoSessionTrade(_Symbol, dow, idx, from, to)` trước khi gửi lệnh.
- Vì sao: SB hard-code server-hour, window có thể lệch hẳn khỏi London/NY
  (xem MQL5 forum 461829 và MQL5 Book - Schedules of trading sessions).

### A2. Log MỌI nhánh bỏ lệnh (P0)
Thay `return` im lặng bằng log có dữ liệu:
`g_logger.Log("SB skip: <lý do> | hour=... adx=... spread=... range=...");`
Áp dụng tại: CopyBuffer fail, hour ngoài window, lọc range size, ADX < min,
spread > max, volume <= 0.

### A3. Fix sizing skip (P0)
- Nếu volume < Min_Volume và SL quá xa: thử giảm SL_Range_Fraction (0.5),
  hoặc nới risk có kiểm soát, hoặc bỏ OneTradePerDay để không phí cơ hội.
- Cộng spread + commission vào loss-per-lot (fix BUG-007).

### A4. Filling mode (P0)
- Đọc `(int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE)` và chọn
  FOK/IOC/RETURN hợp lệ -> tránh retcode 10030 (fix BUG-002).

### A5. Warmup & gating (P1)
- `if(BarsCalculated(h) < period+2) { log; return; }`
- Cổng hiện tại khiến giờ đầu window luôn fail -> dịch TradeStartHour
  hoặc bỏ điều kiện `t1 < rangeTo`.

## PHẦN B - Tối ưu TM_TrendFollowerScalper
| Vấn đề | Fix | Ref |
|---|---|---|
| v2.0 thua 6/6 (PF 0.12-0.60) | Test lại nhánh Breakout của v1.3 tách bạch | BUG-011 |
| Breakeven hủy lệnh thắng | Breakeven_ATR_Mult >= 1.0; cấm pip cố định < spread | BUG-013 |
| SL sai phía khi breakeven | Clamp SL về openPrice | BUG-010 |
| Đếm trùng consecutive-loss | Persist m_lastProcessedDeal | BUG-003 |
| Margin dùng Min_Volume | Dùng volume thực | BUG-008 |
| Report cost-stress giả | Verify report khác baseline khi đổi phí | BUG-005 |
| Session filter | Đổi sang GMT + SymbolInfoSessionTrade | như A1 |

## PHẦN C - Nâng cấp chiến lược
- Thêm module SweepReversal + Regime detection có hysteresis
  (tham khảo kezyandrew/xauusd-scalper).
- Thêm ORB có kill-zone theo GMT + tick-volume filter
  (tham khảo goldlab NY ORB, CRT-TBS tự detect GMT).
- Giữ chung một RiskManager cho mọi module; partial + breakeven + ATR trail
  quản lý vị thế đồng nhất.

## PHẦN D - Checklist verify demo (đúng thứ tự)
1. OnInit: in offset phát hiện, giờ window (server), symbol specs, filling mode.
2. Journal: xác nhận dòng "SB skip" xuất hiện -> biết chính xác lý do.
3. Không có "SB skip" mà cũng không có lệnh -> kiểm tra suffix symbol / INIT_FAILED.
4. So giờ broker vs GMT thật, chỉnh BrokerGMTOffset.
5. Chạy 1 tuần demo, đối chiếu số lệnh kỳ vọng (~1/ngày).
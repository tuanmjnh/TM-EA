# TM-EA — CHANGELOG

Định dạng theo `MASTER.md` §6.6.

---

```yaml
[2026-11-13] - v3.1 (SB REGIME FILTER - KET QUA TOT NHAT)
Thay đổi (code):
  - TM_SessionBreakout: them bo loc regime ADX(H1) (Use_ADX_Filter mac dinh true, ADX_Min=20),
    dai range theo ATR (Min/Max_Range_ATR). Mac dinh RR=5. Compiled 0/0; EX5=4E23415AEAE1E96C.
Ket qua (XAUUSDm, dep5000, risk1%):
  - 3Y: khong ADX PF 1.081/DD18.3 -> ADX20 PF 1.665/DD7.9; ADX30 PF 1.746/DD8.2.
  - Walk-forward ADX20 RR5: W1 1.033 (truoc 0.849) / W2 2.692 / W3 1.503 -> CA 3 NAM DUONG.
  - Plateau RR (ADX20, 3Y): RR4 1.445 / RR5 1.665 / RR6 1.680, DD ~8%.
Quyet dinh:
  - Bo loc ADX sua duoc nam am W1. Day la ket qua on dinh nhat cua du an. NHUNG chua xac nhan:
    can commission/slippage that + them symbol. Chua demo/tien that. Chi tiet: _sb/SB_RESEARCH.md.

[2026-11-13] - v3.0 (NEW STRATEGY: SESSION-BREAKOUT H1)
Thay đổi:
  - Thêm EA mới MQL5/Experts/TM_SessionBreakout.mq5 (logic mới hoàn toàn): phá range phiên Á
    (00-07 server) tại London/NY, 1 lệnh/ngày, SL = biên đối diện range, TP = RR*risk.
    Compiled 0/0; EX5 SHA256[0:16]=0476E2E990E99862. Giữ nguyên EA cũ.
  - Thêm runner tests/run_breakout.ps1; report reports/backtests/_sb/.
Lý do: chiến lược cũ thua 6/6 vòng (OOS PF < 1); thử khái niệm khác (volatility expansion theo phiên),
  tần suất thấp -> hợp vốn nhỏ.
Kết quả (XAUUSDm, dep5000, risk1%, real-tick):
  - RR5 3Y: PF 1.081, DD 18.3% | RR6 3Y: PF 1.578, DD 8.7% | RR3 3Y: PF 1.024.
  - Walk-forward RR5: W1(2023.11-24.10) PF 0.849 (AM) | W2 PF 2.023 | W3 PF 1.763 -> phụ thuộc regime.
  - EURUSDm 3Y: PF 0.667 (that bai). Vốn 500: 0 lệnh (min-lot).
Quyết định:
  - GIỮ làm hướng nghiên cứu chính (khac biet ro so voi chien luoc cu), nhung CHUA xac nhan.
    Can: commission/slippage that + loc regime + walk-forward dai. Chua demo/tien that.
    Chi tiet: reports/backtests/_sb/SB_RESEARCH.md.

[2026-11-13] - v2.5 (ROUND 6: SCALE-OUT)
Thay đổi (code):
  - Thêm scale-out: Use_Partial_Exit (default FALSE), Partial_Exit_ATR_Mult, Partial_Exit_Percent;
    CTradeExecutor::ClosePartial. Biên dịch 0/0; EX5 SHA256[0:16]=F76C419727E08752.
Kết quả ($5000, IS): no-partial PF 0.861 vs partial1.0 PF 0.845 vs partial1.5 PF 0.813;
  largest_win 151 -> 75. Scale-out LÀM GIẢM PF (cắt winner lớn).
Quyết định:
  - Bác bỏ B. Mặc định tắt. D (R:R qua TP) vô nghĩa vì TP không bind.
  - Tổng 6 vòng: 0 phương pháp cho OOS PF >= 1. Chi tiết: _v2/RESEARCH_LOG.md.

[2026-11-13] - v2.4 (ROUND 5: ENTRY QUALITY)
Thay đổi (code):
  - Thêm Use_EMA_Slope_Filter (lọc độ dốc EMA HTF) và Require_Close_Beyond_EMA
    (nến pullback phải đóng qua EMA). Biên dịch 0/0; EX5 SHA256[0:16]=129053A96E2C8D0F.
Kết quả:
  - IS: reclaim nâng PF 0.935->1.047, DD 11.8->7.9%. slope filter TRƠ (không đổi gì).
  - OOS: reclaim PF 0.699 (base 0.726), DD 16.1->10.7% -> vẫn <1.
Quyết định:
  - reclaim là bộ GIẢM RỦI RO tốt (giảm DD) nhưng KHÔNG tạo edge. Vẫn chưa sinh lời.
    Chi tiết: reports/backtests/_v2/RESEARCH_LOG.md (Round 5).

[2026-11-13] - v2.3 (RESEARCH ROUNDS 1-4)
Thay đổi (code):
  - Thêm input Trade_Direction (0=Both,1=Buy,2=Sell). Thêm SL_ATR_Mult (tách SL ban đầu khỏi trailing).
  - Biên dịch 0/0; EX5 SHA256[0:16]=CA67C0BBFAC98E5B.
Kết quả (IS 2026.05-07):
  - R1 hướng: long-only PF 0.767 < both 0.935 -> hướng không giúp.
  - R2 tách SL/trail: PF không tăng, DD tăng vọt 30-40%.
  - R3 timeframe: không cải thiện; H1 = 0 lệnh (thiếu warmup).
  - R4 EURUSDm: PF 0.51-0.62, DD 32-42% -> tệ hơn vàng.
Quyết định:
  - KHÔNG áp dụng thay đổi nào (không tạo edge). Vấn đề ở khái niệm entry, không phải tham số.
  - Chiến lược vẫn chưa sinh lời. Chi tiết: reports/backtests/_v2/RESEARCH_LOG.md.

[2026-11-13] - v2.2 (BUG-013 FIX + TEST)
Thay đổi:
  - Sửa BUG-013: thêm input Breakeven_ATR_Mult (default 1.0); breakeven chỉ kích hoạt khi lãi
    >= max(Breakeven_After_pips*pip, Breakeven_ATR_Mult*ATR) -> không còn dời SL về entry khi lãi < nhiễu.
  - Biên dịch 0/0; EX5 SHA256[0:16]=07ED385A5D67E86E.
Kết quả (vốn 500, risk 1%, Pullback+Breakout, atr1.5, act10 step5, ADX25):
  - IS  no-TP: PF 0.935 | IS  TP1.5: PF 0.935 (giống hệt) -> TP vô hiệu trên real-tick.
  - OOS no-TP: PF 0.726 | OOS TP1.5: PF 0.726 (giống hệt).
  - Gate test: Breakeven_ATR_Mult 0.25 -> PF 0.567; 1.0 -> 0.935; 4.0 -> 0.932.
Quyết định:
  - Áp dụng fix (đóng BUG-013 dạng source). Bỏ TP là vô hại/đúng thiết kế gốc (không phải đòn bẩy lãi).
  - Chiến lược VẪN PF < 1 -> chưa sinh lời, không demo/tiền thật. Chi tiết: _v2/OPTIMIZATION_STUDY.md §5.

[2026-11-13] - v2.1 (OPTIMIZATION STUDY)
Thay đổi:
  - Khôi phục Breakout trong code (CEntryEngine::EvaluateBreakout) nhưng có switch; thêm input
    Use_Breakout (default true), BreakoutK (0.7); đánh thức lại SETUP_BREAKOUT. Biên dịch 0/0.
    EX5 mới SHA256[0:16]=60B7454806D2C85A. (v2.0 đã gỡ Breakout; dữ liệu cho thấy cần test lại.)
  - Chạy grid optimization trên IS (2026.05-07) + kiểm chứng OOS (2026.08-10), real-tick.
Phát hiện:
  - BUG-013 (breakeven dời SL về entry quá sớm) là lỗi cơ chế lớn: tắt breakeven đưa PF 0.155 -> 0.897,
    largest_win 0.29 -> 22.66. Đây là cải thiện thật.
  - Khôi phục Breakout: lợi ích nhỏ (PF 0.914 -> 0.932).
  - Tối ưu ADX (IS PF 1.08 tại ADX20) GÃY trên OOS (PF 0.57) -> overfit, KHÔNG áp dụng.
Quyết định:
  - Áp dụng hướng fix breakeven (BUG-013); KHÔNG áp dụng tham số ADX tối ưu IS.
  - Chiến lược vẫn PF < 1 (chưa sinh lời). Không demo/tiền thật. Chi tiết: _v2/OPTIMIZATION_STUDY.md.

[2026-11-13] - v2.0.2 (SET SELECTION STUDY)
Thay đổi: chạy 8 preset trên 6 tháng real-tick (2026.05.01–2026.10.31) + đối chứng TP on/off.
Kết quả: 8/8 âm (PF 0.08–0.31); TẤT CẢ > cổng DD? không; TP on/off GIỐNG HỆT trên real-tick
  → lỗi ở entry (Pullback-only), không phải vốn/TP.
Xếp hạng least-bad: realistic_500 (PF 0.215, DD 4.33%) > standard_1000 (PF 0.168, DD 2.43%);
  tệ nhất: small_50/small_100 (DD 16–18%) và cost_stress_10000 (DD 20.1%).
Quyết định: KHÔNG set nào đáng giao dịch thật. Đề xuất khôi phục Breakout rồi chạy lại study.
  Chi tiết: reports/backtests/_v2/SET_SELECTION_STUDY.md.

[2026-11-13] - v2.0.1 (BACKTEST THỰC THI)
Thay đổi:
  - Biên dịch v2.0 bằng MetaEditor: 0 errors / 0 warnings (tests/compile-v2.log); EX5 SHA256[0:16]=0F50E9E0ADD72C90 (đóng BUG-006).
  - Thêm dump CSV chỉ-trong-tester (DumpTesterStats) vì khóa Report= của MT5 không hoạt động ở chế độ /config.
  - Thêm tests/run_backtest_v2.ps1 (chạy MT5 tester headless, tái lập được).
  - Chạy backtest real-tick (Model=4) 3 tháng cho 6 preset + 4 run kiểm soát.
Kết quả:
  - TẤT CẢ preset v2.0 đều LỖ: realistic_200 PF 0.16; realistic_500 0.41; standard_1000 0.40;
    conservative_5000 0.27; small_50 0.12 (DD 18.4%); cost_stress_10000 0.60.
  - Kiểm soát TP (Model=1): không TP PF 3.39 > TP1.5 PF 2.47 > TP0.2 PF 2.14 → TP không giúp.
  - Điểm bất thường: 1 lệnh thắng +203.77 không đổi theo mọi cấu hình TP (nghi gap real-tick) - CHƯA xác minh.
Quyết định:
  - REJECT v2.0 as-is. Giữ code + report làm bằng chứng. Không chạy tiền thật.
    Chi tiết: reports/backtests/_v2/V2_BACKTEST_RESULTS.md.

[2026-11-12] - v2.0 (STRATEGY CHANGE)
Thay đổi:
  - BỎ Breakout: xóa CEntryEngine::EvaluateBreakout; xóa input Entry_Mode, BreakoutK,
    ATR_Channel_Period; xóa enum ENUM_ENTRY_MODE và SETUP_BREAKOUT. Entry chỉ còn Pullback.
  - BẬT Take Profit: Use_TP mặc định false -> true; thêm input TP_ATR_Mult=1.5;
    OpenBuy/OpenSell nhận và gửi takeProfit = entry + direction * TP_ATR_Mult * ATR;
    bỏ chặn INIT_FAILED khi Use_TP=true.
  - THÊM equity circuit breaker: input Max_Equity_DD_Percent=10.0; mỗi tick nếu
    equity DD từ baseline ngày >= ngưỡng -> đóng toàn bộ vị thế (CTradeExecutor::CloseAllPositions)
    và khóa mở lệnh mới tới hết ngày (RiskGuard breaker flag persist qua restart).
  - SỬA breakeven cả hai nhánh (BUG-010): mức breakeven = openPrice ± spread nhưng
    clamp về openPrice khi SL rơi sai phía thị trường (trước đây bị broker từ chối vì
    SL cao hơn bid / thấp hơn ask khi spread (0.20-0.35) > ngưỡng breakeven (0.08)).
  - Đồng bộ 8 preset config/sets/: bỏ 3 input đã xóa, đặt Use_TP=true, thêm TP_ATR_Mult,
    Max_Equity_DD_Percent.
Lý do:
  - Theo yêu cầu chủ dự án: đơn giản hóa entry (Pullback-only), chốt lời bằng TP,
    và có cầu dao bảo vệ vốn để chặn DD 22-52% đã thấy trên preset vốn nhỏ.
  - ⚠️ Đây là THAY ĐỔI CHIẾN LƯỢC: ghi đè invariant "Không Take Profit" (MASTER §3, SOURCE_SPEC §2.2)
    và bỏ một trong hai cơ chế vào lệnh (SOURCE_SPEC §4.2). Đã cập nhật các tài liệu đó.
File ảnh hưởng:
  - MQL5/Include/TM_EA/Inputs.mqh, EntryEngine.mqh, Types.mqh, TradeExecutor.mqh,
    TrailingEngine.mqh, RiskGuard.mqh
  - MQL5/Experts/TM_TrendFollowerScalper.mq5
  - config/sets/ (toàn bộ 8 preset .set)
  - docs/MASTER.md, docs/SOURCE_SPEC_V1.md, docs/TECHNICAL_AUDIT.md,
    docs/SOURCE_REPORT_CONSISTENCY.md, docs/CHANGELOG.md
  - README.md, tests/implementation-status.md, tests/BUG_REPRODUCTIONS.md, tests/VALIDATION_RESULTS.md
Report/manifest kèm theo:
  - CHƯA có. Code v2.0 CHƯA được biên dịch lại và CHƯA chạy lại backtest.
Kết quả cost-stress:
  - Không áp dụng — cần chạy lại toàn bộ sau khi compile (mọi report cũ KHÔNG còn giá trị cho v2.0).
Quyết định:
  - Giữ; nhưng GIỮ NGUYÊN mọi report cũ làm lịch sử. Trạng thái bắt buộc: NOT RUN cho tới khi
    compile + cost-stress + OOS hoàn tất. Xem tests/BUG_REPRODUCTIONS.md (BUG-002/003/006/007/008 còn mở).

[2026-11-12] - audit-v1.3
Thay đổi:
  - Đối chiếu MASTER với source/preset/report thực tế; tạo TECHNICAL_AUDIT.md,
    SOURCE_REPORT_CONSISTENCY.md, tests/BUG_REPRODUCTIONS.md, tests/VALIDATION_RESULTS.md.
  - Tạo harness test tests/units/TM_EA_UnitTests.mq5 (dùng chính header thật).
  - Tạo manifest cho từng lần kiểm thử + reports/backtests/MANIFEST_INDEX.md.
  - Sửa SOURCE_SPEC_V1.md canonical table: Max_Concurrent_Positions 2->1, Max_Daily_Loss_Percent 5.0->1.5.
  - Rút lại tuyên bố cost-stress "PASSED"; viết lại MASTER §4.
Quyết định:
  - Giữ toàn bộ report cũ. Không PASS hạng mục thiếu bằng chứng.

[2026-11-12] - v1.2
Thay đổi:
  - Max_Spread_Points 35 -> 350 (3-digit gold spread); news calendar unavailable trong tester không chặn.
  - Chuẩn hóa 7 preset trong config/sets/.
  - Soạn docs/USER_GUIDE.md.
Quyết định: Giữ lại.

[2026-11-12] - v1.1
Thay đổi:
  - Chuẩn hóa bảng canonical inputs; thêm preset cost_stress/realistic_200/realistic_500.
  - Triển khai Breakout (EvaluateBreakout) trong EntryEngine và tích hợp vào Main EA.
  - Compile 0 errors/0 warnings; đồng bộ EX5.
Quyết định: Giữ lại. (Breakout đã bị bỏ ở v2.0.)
```

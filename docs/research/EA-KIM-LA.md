KIM LA - BẢN SPEC KỸ THUẬT ĐẦY ĐỦ
1. TRIẾT LÝ VÀ MỤC TIÊU (MANDATE)
Mục tiêu đơn nhất: KHÔNG CỤT VỐN. Ưu tiên bảo toàn trên lợi nhuận.
Kiến trúc đa khung: D1 = định hướng thời đại, H1 = bias thực chiến theo phiên, M5 = chỉ tìm điểm vào.
Chỉ giao dịch CÙNG hướng bias H1. Không bao giờ ngược hướng, không bao giờ "bắt dao rơi".
Mỗi lệnh dương phải khóa lãi bằng breakeven có đệm + trailing gia tốc.
Phong cách: day trading gold (XAUUSD), hợp đồng M5, trung bình vài lệnh/phiên.
Tài khoản mục tiêu: cent (USD cent = USC), số dư ~5.000 USC.
2. THÔNG SỐ CHÍNH (PARAMETERS - TẦM 3-5 BIẾN ĐỂ TRÁNH OVERFIT)
Biến	Giá trị mặc định	Ý nghĩa
Points_ATR	14	ATR period cho M5 và H1
RiskPct	1.0	% tài khoản rủi ro mỗi lệnh (của SL ban đầu)
ATR_EntryStop	1.8	SL ban đầu = 1.8 × ATR M5
ATR_BreakevenBuffer	0.7	Breakeven đặt tại entry + 0.7 × ATR M5 (không sát entry)
TrailStart	2.0	Bắt đầu trailing khi lãi ≥ 2.0 × ATR M5
TrailStep1	1.8	Khoảng cách trailing giai đoạn 1
TrailStep2	1.3	Khoảng cách trailing khi lãi ≥ 4 × ATR
TrailStep3	1.0	Khoảng cách trailing khi lãi ≥ 6 × ATR
ADX_EntryMin	22	Chỉ mở lệnh khi ADX(14) M5 ≥ 22
SessionLondonStart	08:00 GMT	Mở cửa bias London
SessionLondonEnd	17:00 GMT	
SessionNYStart	13:30 GMT	Mở cửa bias NY
SessionNYEnd	21:00 GMT	
MaxTradesPerSession	2	Giới hạn lệnh mỗi phiên
MaxSpread	25 points	Không mở lệnh nếu spread vượt mức này (tránh phí cao giờ tin)
MagicNumber	20261113	Nhận diện lệnh của riêng bot
LotMode	CENT	Chạy ở tài khoản cent
3. TẦNG 1 - XÁC ĐỊNH BỐI CẢNH D1 (REGIME)
Tính EMA 200 trên D1 và cấu trúc đỉnh/đáy D1 (swing high/low).
Xác định Regime:
TrendLong nếu giá D1 > EMA200 D1.
TrendShort nếu giá D1 < EMA200 D1.
Range nếu giá dao động trong ±1 × ATR D1 quanh EMA200 (sideway) → NẾU RANGE, CHỈ GIAO DỊCH PHIÊN CÓ TIN LỚN HOẶC ĐỨNG NGOÀI (an toàn nhất là đứng ngoài nếu không có tín hiệu rõ).
🔑 D1 KHÔNG phải tầng lọc trực tiếp từng lệnh. Nó quá chậm - chỉ để nắm "át chủ bài" và loại bỏ việc đánh ngược tuần. Nếu D1 Range, giảm nửa số lệnh và chỉ nhận tín hiệu thật sạch.

4. TẦNG 2 - BIAS H1 THEO PHIÊN (QUÂN BÀI CHỦ LỰC)
Tính EMA 50 H1 và cấu trúc đỉnh/đáy H1 (swing mới nhất).
Mỗi phiên (London 08:00-17:00 GMT, NY 13:30-21:00 GMT), tính lại bias một lần duy nhất lúc mở phiên và giữ nguyên trong suốt phiên đó:
H1_Bias = LONG nếu giá H1 > EMA50 H1 (pullback giữ trend).
H1_Bias = SHORT nếu giá H1 < EMA50 H1.
H1_Bias = NONE nếu giá bẹt quanh EMA (không rõ) → KHÔNG mở lệnh, chờ phiên sau.
Quy tắc phiên:

Phiên Châu Á (trước 08:00 GMT) = mỏng, dễ quét → KHÔNG mở lệnh mới trong phiên này (chỉ đóng/quản lý lệnh đang chạy).
Vào lệnh chỉ trong London hoặc NY.
Có thể dành riêng tín hiệu NY open (13:30-14:30 GMT) làm "giờ tin" - mở lệnh ở đây thường có năng lượng nhất, nhưng phải có ADX & pullback rõ.
5. TẦNG 3 - ĐIỂM VÀO M5
Chỉ mở lệnh khi ĐỦ 4 điều kiện đồng thời:

Cùng bias: Hướng lệnh = H1_Bias (chỉ LONG khi bias LONG, chỉ SHORT khi bias SHORT).
Động lượng đủ: ADX(14) M5 ≥ ADX_EntryMin (22).
Pullback/entry điểm tốt:
LONG: giá pullback về vùng EMA20 M5 HOẶC vùng hỗ trợ gần nhất (swing low / vùng giá trị) rồi có nến xác nhận (nến tăng đóng vượt high của nến trước, hoặc engulfing tăng).
SHORT: tương tự ngược lại - pullback về EMA20/vùng kháng cự, nến giảm xác nhận.
Không đuổi theo: KHÔNG mở lệnh nếu giá đã chạy quá xa khỏi điểm vào hoặc giá chạm biên phản kháng yếu. Chỉ vào ở vùng pullback, ưu tiên giới hạn điểm vào (limit) tại EMA20/vùng hỗ trợ thay vì market đuổi.
Loại entry: độ ưu tiên

1 (tốt nhất): Pullback chạm EMA20 M5 + xác nhận nến, cùng H1 bias.
2: Pullback chạm vùng value/hỗ trợ (swing low) cùng H1 bias.
3: Vùng này KHÔNG ngược trend bất kể điều gì.
6. ĐẶT LỆNH (ENTRY ENGINE)
Entry: GIỚI HẠN (limit) tại vùng EMA20 M5 hoặc vùng hỗ trợ/kháng cự đã chọn. Nếu giá không quay lại vùng đó trong MaxSeconds_EntryFill (mặc định 60 giây) → hủy, không đuổi theo market.
SL ban đầu: Entry ± (1.8 × ATR M5). SL ban đầu ĐƯỢC ĐẶT NGAY TỪ ĐẦU (không bao giờ mở lệnh "trần" không có SL) - đây là lớp bảo vệ đầu tiên, khác với việc bạn vẫn kéo trailing sau.
Risk mỗi lệnh: Lot = RiskPct% × Balance_Cent × 100 / (SL_pts × pip_value), trong đó kết quả tính theo lot cent (0.01 đến 0.1), làm tròn xuống. KHÔNG được vượt quá MaxLot (mặc định 0.1).
🔑 Dù triết lý là "SL chỉ về breakeven khi dương", bạn VẪN PHẢI đặt SL ban đầu ngay khi mở lệnh. Không bao giờ có lệnh không có điểm dừng - đó là "cụt vốn" theo cách lặng lẽ nhất.

7. QUẢN LÝ LỆNH (TRADE MANAGEMENT) - LÕI TRAILING
Thực thi tuần tự theo từng mốc lãi (tính bằng ATR M5 tại thời điểm kiểm tra mỗi tick):

Pha 1 - Breakeven có đệm: Khi lãi nổi ≥ ATR_BreakevenBuffer (0.7 × ATR), kéo SL lên Entry + 0.7 × ATR (LONG) hoặc Entry - 0.7 × ATR (SHORT). Từ đây gốc được bảo vệ gần như tuyệt đối (chỉ mất phí/spread).
Pha 2 - Trailing giai đoạn 1: Khi lãi nổi ≥ TrailStart (2 × ATR), kéo SL theo giá với khoảng cách TrailStep1 (1.8 × ATR). Nghĩa là SL luôn = giá hiện tại ∓ 1.8 × ATR, nhưng không bao giờ di chuyển ngược (ratchet: chỉ siết chặt, không nới ra).
Pha 3 - Gia tốc: Khi lãi nổi ≥ 4 × ATR → khoảng cách trailing siết về TrailStep2 (1.3 × ATR). Khi lãi ≥ 6 × ATR → TrailStep3 (1.0 × ATR). Càng chạy xa, khóa càng chặt - không nhả lại lãi lớn khi giá ngoặt.
Nguyên tắc quản lý bất biến (không được viết sai):

Ratchet một chiều: SL chỉ TĂNG với LONG / chỉ GIẢM với SHORT. Không bao giờ nới SL ngược lại từ lãi sang lỗ.
Không TP cố định: TP để mặc (0) - lối thoát do trailing quyết định. Nếu có TP tùy chọn, đặt ở ≥ 8 × ATR làm "lưới an toàn" phòng ngừa sự kiện, nhưng trailing thường đóng trước.
Thời điểm đóng lệnh: Trailing sẽ đóng lệnh khi SL bị chạm. Ngoài ra đóng bắt buộc nếu lệnh vẫn mở khi hết phiên hiện tại (khi phiên chuyển, đóng lệnh đang chạy bằng market, khóa lãi - tránh giữ qua phiên mỏng Châu Á mang rủi ro gap) → đây là cơ chế "không để cụt vốn" về thời gian.
8. GIỚI HẠN RỦI RO ỔN ĐỊNH
MaxSpread (25 points) - không mở lệnh mới trong giờ spread cao (tin, cắt thị trường).
Không martingale, không grid, không trung bình giá xuống - bị CẤM cứng, viết vào code như lỗi không thể xảy ra.
MaxTradesPerSession (2) - tối đa 2 lệnh mỗi phiên London/NY.
Trễ phiên: nếu vẫn còn lệnh mở khi kết thúc phiên → đóng market.
News filter (khuyến nghị): nếu có bộ lọc lịch tin, chặn mở lệnh mới trong ±15 phút quanh tin quan trọng vàng (CPI, FOMC, NFP). Nếu bot của bạn chưa có, để trống nhưng ưu tiên bật sau.
9. LOẠI BỎ TRƯỜNG HỢP LỖI (EDGE CASES - MANDATORY)
Re-quote/lệnh treo: nếu giới hạn entry không fill trong 60 giây → tự hủy, không chuyển sang market đuổi.
Mất kết nối: nếu mất kết nối VPS, khi phục hồi kiểm tra lại toàn bộ lệnh còn SL/trailing nguyên vẹn; KHÔNG mở lệnh mới trong 5 phút đầu sau reconnect.
Spread bất thường: nếu tại thời điểm mở lệnh spread > MaxSpread → bỏ lệnh này, không fill.
Trùng lệnh: kiểm tra MagicNumber - không bao giờ mở 2 lệnh cùng hướng cùng một vùng.
Lỗi tính lot: nếu RiskPct không khả dụng do SL quá gần (lot tính ra < 0.01) → bỏ lệnh, không ép lot tối thiểu.
Chỉ một lệnh mỗi hướng tại một thời điểm - không chất đống.
10. BACKTEST VÀ XÁC MINH (PHẢI LÀM TRƯỚC KHI CHẠY THẬT)
Chạy trên tài khoản CENT (usd cent, leverage 1:500), đơn vị USC, trong MT5 Strategy Tester - để lot 0.01 phản ánh đúng risk%.
Walk-forward: cắt dữ liệu 2 năm thành 2-3 đoạn. Tối ưu trên đoạn train, kiểm tra trên out-of-sample (OOS). Chấp nhận hệ thống CHỈ khi OOS thắng, không phải chỉ train thắng.
Cost-stress test: chạy lại với spread/commission/slippage gấp đôi để chắc "ăn ít" vẫn còn dương. Nếu lỗ dưới cost stress → tăng cường độ tín hiệu hoặc bỏ bớt lệnh nhiễu.
KPI mục tiêu: Win-rate trên ~40-50% (vì trailing), PF (profit factor) OOS ≥ 1.2, tiêu chí #1 là đường equity không thủng sâu (max drawdown < 8% tổng vốn).
Số lệnh đủ: tối thiểu 150-200 lệnh mỗi đoạn trước khi tin kết quả.
🔑 Con số "PF 2.45 trên 3% ticks" của bạn trước đó là OVERFIT - không tin nó. Tiêu chí thật là PF OOS ≥ 1.2 ổn định trên nhiều đoạn, chứ không phải PF cao ở đoạn tối ưu.

11. THỐNG KÊ GIÁM SÁT (BẮT BUỘC KHI CHẠY THẬT)
Log mỗi lệnh: thời gian mở, phiên, bias H1 lúc đó, ADX, entry/SL, mốc trailing đạt được, lý do đóng (trailing / breakeven / hết phiên / SL ban đầu).
Thống kê cuối tuần: win-rate, PF, % lệnh kết thúc ở breakeven-so với thắng-thật (nếu > 50% lệnh huề nghĩa là breakeven quá sát, cần nới đệm).
Nếu sau 1 tháng equity không tăng nhưng cũng không thủng → vẫn ĐẠT mục tiêu (không cụt vốn). Tối ưu thêm sau.
BOTTOM LINE
KIM LA đã sẵn - toàn bộ logic (D1 regime, H1 bias theo phiên London/NY, entry M5 pullback + ADX, breakeven có đệm, trailing gia tốc ratchet, đóng hết phiên, cấm martingale, backtest walk-forward cost-stress) đều viết đầy đủ ở trên, một AI lập trình có thể code trực tiếp không cần hỏi thêm. Nói ngắn: theo la bàn H1, vào M5, khóa từng bậc lãi, và không bao giờ không có SL.
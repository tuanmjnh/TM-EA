TM INDICATOR 2 - MQL5 EA BUILD SPECIFICATION
1. MỤC TIÊU
Xây dựng Expert Advisor cho MetaTrader 5 bằng MQL5, dựa trên logic của TM Indicator 2 v2.1.0 trong mã Pine Script được cung cấp.

EA cần:

Tạo tín hiệu LONG/SHORT trên nến đã đóng theo mặc định.
Hỗ trợ Market Entry và Pullback Limit.
Quản lý SL, TP từng phần, break-even, trailing, time-decay và timeout.
Áp dụng bộ lọc regime, MTF, BTC leader, liquidity, score, entry mode và giới hạn rủi ro.
Ghi log lý do vào/không vào lệnh để kiểm tra và đối chiếu.
Có tham số bật/tắt module, cho phép chạy ablation test.
Dùng dữ liệu và đặc tính giao dịch thực tế của symbol trên broker MT5.
Không được tuyên bố có lợi nhuận hoặc tối ưu hóa hiệu quả nếu chưa có kết quả test ngoài mẫu và kiểm tra trên dữ liệu tick phù hợp.

2. ĐẦU VÀO CẦN CUNG CẤP CHO AI LẬP TRÌNH
AI phải dùng:

Toàn bộ mã Pine Script v6 của TM Indicator 2 được đính kèm trong yêu cầu.
Tài liệu đặc tả này.
MetaTrader 5, ngôn ngữ MQL5.
Các điều kiện giao dịch của broker thực tế khi chạy EA: tick size/value, contract size, volume min/max/step, stop level, freeze level, commission, spread và margin mode.
Nếu không có đặc tính broker trong môi trường code, EA phải lấy chúng từ các hàm symbol/account của MT5 khi chạy. Không hard-code các giả định về contract size, pip value hoặc margin.

3. PHẠM VI VÀ ƯU TIÊN TRIỂN KHAI
3.1. Bắt buộc cho bản đầu tiên
Tín hiệu trên nến đóng.
EMA stack, RSI, MACD, ATR, ADX/DMI.
Market regime: trending, ranging, choppy/squeeze.
Cấu trúc swing, BOS/CHoCH và retest cần thiết cho scoring/mode.
Liquidity sweep theo các mức được bật.
MTF context và setup, chỉ dùng nến HTF đã đóng.
BTC leader filter cho cấu hình crypto liên quan.
Hai score LONG/SHORT riêng biệt, score margin và quality threshold.
Mode A: Trend Pullback; Mode B: Liquidity Sweep Reversal.
Mode C: Range Mean-Reversion, tắt mặc định.
Bộ lọc obstacle, overextension, cooldown, giới hạn lệnh/ngày và circuit breaker.
Market và pending limit entry, hết hạn limit sau K nến.
SL, TP1/TP2/TP3, partial close, break-even, trailing, time-decay và max holding bars.
Tính volume theo rủi ro tài khoản và thông số giao dịch của symbol.
Nhật ký lý do block, tín hiệu, khớp lệnh, huỷ lệnh và đóng lệnh.
3.2. Để sau, không cần có trong bản EA tối thiểu
Các tính năng thiên về hiển thị của Pine: dashboard, label, box, trendline đồ họa, tô màu volume, các bảng thống kê trực quan. Có thể thay bằng log, chart objects tùy chọn và báo cáo backtest.

EA không cần tạo lại giao diện Pine nếu điều đó làm tăng độ phức tạp hoặc gây ảnh hưởng đến tốc độ kiểm tra.

4. QUY TẮC ĐỒNG BỘ LOGIC PINE VÀ MQL5
Tạo tín hiệu một lần trên mỗi nến mới, dựa trên nến vừa đóng khi ConfirmOnly = true.
Dùng dữ liệu nến đã đóng cho các điều kiện chỉ báo và MTF.
MTF phải dùng nến HTF đã hoàn tất; không dùng giá trị HTF đang chạy để xác nhận tín hiệu.
Không dùng dữ liệu tương lai hoặc thông tin chỉ xuất hiện sau thời điểm vào lệnh.
Các swing pivot chỉ được xác nhận sau số nến phải tương ứng với tm_ms_swLen; không gán sự kiện về quá khứ như thể đã biết ngay tại pivot.
Tách riêng tín hiệu, đủ điều kiện giao dịch, lệnh gửi, lệnh khớp và vị thế đang mở. Không tính tín hiệu bị block là một giao dịch.
EA phải đối soát trạng thái nội bộ với lệnh/vị thế thật của MT5 sau restart.
Dùng magic number riêng và không quản lý lệnh thủ công hoặc lệnh của EA khác.
Hỗ trợ rõ ràng cả tài khoản netting và hedging; nếu chế độ tài khoản không tương thích với cấu hình, báo log và không mở lệnh.
5. INPUTS CẦN CÓ TRONG EA
Giữ các tham số Pine tương đương khi có ý nghĩa trong MT5. Có thể chuẩn hóa tên input theo MQL5, nhưng không tự ý đổi logic hoặc giá trị mặc định.

5.1. General
ConfirmOnly - mặc định true.
EnableLong, EnableShort.
MagicNumber.
MaxSlippagePoints.
MaxSpreadPoints hoặc giới hạn spread theo ATR.
TradeComment.
LogLevel.
PayloadMode chỉ cần nếu EA có gửi webhook.
5.2. Asset Profile và lọc thanh khoản
AssetMode: Auto, XAU, BTC, ETH, Liquid Altcoin, High-Risk Altcoin, Custom.
CryptoSessionNeutral.
MinVolCheck.
WeekendFilter.
BTCLeaderFilter, BTCTicker, BTCImpulseAtr.
Kiểm tra phải xác định và ghi log chính xác cách nhận biết crypto, vàng và symbol tùy chỉnh. Không phụ thuộc duy nhất vào tên ticker nếu broker đặt tên khác.
5.3. Entry và entry modes
Entry: Market on Confirm, Pullback Limit Strict, Auto Adaptive.
Limit source: 50% FVG, Order Block Edge, EMA Fast Pullback.
Limit cancel bars.
Cancel limit if TP1 reached first.
Bật/tắt mode filter.
Mode A, B, C bật/tắt.
Mode B confirmation window.
Mode A pullback tolerance ATR.
Mode C range-edge tolerance ATR.
5.4. Trade management
Auto BE, BE offset ATR.
Trailing bật/tắt.
Trailing type: ATR Dynamic hoặc Structure Swing.
Trailing distance ATR.
Time-decay bật/tắt.
Số nến stagnant.
Số nến giữ tối đa.
Tỷ lệ đóng từng phần tại TP1, TP2 và TP3. Mã Pine tính PnL theo tỷ lệ 40% / 40% / 20%; cần cho phép cấu hình và kiểm tra tổng bằng 100%.
5.5. Gates và regime
Gate regime, MTF, obstacle, overextension, circuit breaker và risk.
ADX threshold cho trending/choppy.
BBW lookback và squeeze percentile.
Obstacle buffer.
Max extension ATR.
Max signal-candle range ATR.
5.6. Indicators và MTF
Giữ các giá trị đầu vào gốc của Pine cho:

EMA fast/mid/slow.
ATR, RSI và ngưỡng RSI.
MACD fast/slow/signal.
DMI/ADX.
Context timeframe và EMA length.
Setup timeframe và EMA length.
HTF filter và HTF veto.
Kiểm tra Chart TF <= Setup TF <= Context TF. Nếu sai, hiển thị lỗi cấu hình và chặn giao dịch; không âm thầm bỏ qua bộ lọc.

5.7. Scoring
Giữ các weight, threshold, minimum quality, score margin và ablation config A-E tương ứng Pine.

Tính score LONG và SHORT độc lập trên thang 0-100.
Không suy ra score SHORT bằng cách đảo dấu score LONG.
Không cho regime/gate bù điểm cho score.
Ghi log từng thành phần score, tổng trọng số, score hai phía, score gap và lý do không chọn hướng.
5.8. Risk và giới hạn giao dịch
Risk percentage trên equity hoặc balance; lựa chọn phải được ghi rõ.
SL ATR multiplier, swing lookback, swing padding, min/max SL ATR.
TP1/TP2/TP3 theo R.
RR minimum tại TP2.
Số lệnh tối đa/ngày.
Cooldown theo nến.
Circuit breaker theo số lệnh thua liên tiếp.
Commission/spread/slippage phải tính theo điều kiện giao dịch của broker hoặc cấu hình được, không dùng giá trị phần trăm chung như thể đúng cho mọi symbol.
6. THUẬT TOÁN TÍN HIỆU
6.1. Indicator và regime
Tính các indicator tương ứng Pine từ dữ liệu MQL5:

EMA fast/mid/slow.
ATR.
RSI.
MACD.
ADX, DI+ và DI-.
Bollinger Width và vị trí tương đối trong lookback.
Volume MA/RelVol/OBV khi dữ liệu volume khả dụng.
Phân loại regime:

TRENDING: ADX vượt ngưỡng, EMA và slope xác nhận hướng, không ở squeeze.
CHOPPY/SQUEEZE: ADX thấp hoặc squeeze theo điều kiện gốc.
RANGING: các trường hợp còn lại.
Giữ nguyên công thức Pine trong bản parity ban đầu. Mọi sửa đổi phải được ghi trong changelog và có test so sánh.

6.2. Cấu trúc và liquidity
Tái tạo pivot high/low, trend state, BOS, CHoCH, MSS, retest, failed breakout, continuation và pullback khi chúng ảnh hưởng đến tín hiệu hoặc score.

Các mức liquidity gồm PDH/PDL, PWH/PWL, session high/low và equal highs/lows theo các input tương ứng.

Tất cả mức ngày/tuần phải lấy từ nến đã đóng.
Session phải dùng timezone có thể cấu hình và xử lý đúng DST nếu timezone hỗ trợ DST.
Không coi tick volume là volume giao dịch thực nếu broker chỉ cung cấp tick volume; log rõ nguồn dữ liệu volume.
6.3. FVG, OB và S/R
Tái tạo FVG và OB chỉ khi chúng tham gia entry, scoring hoặc obstacle gate. Lưu thời điểm hình thành, hướng, biên trên/dưới và trạng thái mitigated.

S/R zones cần:

Chỉ gộp các zone cùng phía, trừ khi quy tắc rõ ràng cho phép khác.
Cập nhật hoặc bảo toàn biên zone khi gộp.
Có quy tắc đánh dấu zone broken và loại bỏ zone.
Không để zone cũ không giới hạn ảnh hưởng đến tín hiệu.
Không sao chép lỗi trong đó support và resistance có thể bị gộp vào cùng zone hoặc broken không bao giờ cập nhật. Nếu cần giữ đúng parity với Pine trước tiên, thêm input tương thích và ghi rõ hành vi cũ; cấu hình EA mặc định nên dùng cách sửa đã mô tả.

6.4. Directional score
Tái tạo feature group theo mã Pine:

Trend.
Structure.
Liquidity.
Location/VWAP.
S/R, FVG, OB.
Candle.
Volume.
Momentum.
Session.
MTF.
Công thức directional contribution:

LONG nhận max(feature, 0).
SHORT nhận max(-feature, 0).
Score mỗi phía bằng tổng contribution có trọng số chia cho tổng trọng số đang bật, nhân 100, clamp 0-100.
Chỉ chọn hướng khi:

Có ít nhất một phía vượt ngưỡng NO TRADE.
Score gap đáp ứng ScoreMargin.
Không rơi vào NO_DIRECTION hoặc AMBIGUOUS_SETUP.
Điều kiện quality level và minimum quality phải khớp Pine.

Kiểm tra và sửa trước khi bật giao dịch: feature gSr hiện có thể nhận điểm bullish/bearish chỉ vì tồn tại một FVG còn active, không yêu cầu giá đang gần vùng đó. Đặc tả EA phải dùng vùng FVG/OB/S/R thực sự liên quan theo khoảng cách hoặc theo điều kiện giá được định nghĩa rõ, đồng thời ghi lại khác biệt so với Pine.

6.5. Entry modes
Mode A - Trend Pullback:

Chỉ hoạt động trong trending regime.
Hướng mode phải trùng hướng trend.
HTF không được chống lại hướng đó.
Cần pullback tới EMA/FVG/OB theo tolerance ATR và nến xác nhận cùng hướng.
Mode B - Liquidity Sweep Reversal:

Sweep phải được ghi nhớ cùng hướng, mức và thời điểm.
Chỉ chấp nhận xác nhận trong cửa sổ đã cấu hình.
Giá đóng cửa phải đáp ứng điều kiện xác nhận so với cực trị sweep.
Hủy setup nếu giá chấp nhận vượt qua cực trị theo hướng invalidation.
Mode C - Range Mean-Reversion:

Tắt mặc định.
Chỉ hoạt động trong ranging regime.
Giá cần ở gần biên range và có nến từ chối phù hợp.
Ưu tiên chọn mode theo thứ tự A, sau đó B, sau đó C, trừ khi có yêu cầu thay đổi rõ ràng.

7. ENTRY, SL VÀ TP
7.1. Entry
Market: gửi lệnh sau khi nến tín hiệu đóng, với giá khả dụng lúc gửi lệnh; log giá tín hiệu và giá khớp riêng.
Limit: tính từ nguồn được chọn; phải kiểm tra giá limit có hợp lệ so với bid/ask hiện tại, stop level và freeze level.
Auto Adaptive: dùng limit nếu overextended, nếu không dùng market, theo nguyên tắc Pine.
Pending order phải hết hạn sau số nến đã đặt.
Nếu giá chạm TP1 trước khi pending limit được khớp, hủy pending nếu input bật.
Trường hợp một nến OHLC có thể vừa chạm entry vừa chạm target không được mô phỏng theo thứ tự có lợi cho EA. Dùng dữ liệu real ticks trong Strategy Tester để kiểm tra thứ tự; nếu chỉ có OHLC, áp dụng giả định bảo thủ và ghi rõ giới hạn.
7.2. SL
Giữ nguyên logic gốc:

Tính khoảng cách SL từ ATR và swing anchor, padding ATR, sau đó giới hạn trong min/max ATR.
LONG: SL dưới entry.
SHORT: SL trên entry.
Trước khi gửi lệnh, kiểm tra SL hợp lệ theo:

Tick size và digits của symbol.
Stop level/freeze level của broker.
Khoảng cách hợp lệ từ giá khớp dự kiến.
Volume và margin khả dụng.
Nếu không hợp lệ, không gửi lệnh; log BLOCKED_BAD_SL hoặc mã lỗi phù hợp.

7.3. TP và partial close
TP1 = RR1, TP2 = RR2, TP3 = RR3 tính từ mức rủi ro ban đầu.
Bảo đảm khoảng cách tăng đúng thứ tự TP1 < TP2 < TP3 đối với LONG; đảo chiều tương ứng đối với SHORT.
Cần đóng một phần volume tại TP1/TP2/TP3 theo tỷ lệ cấu hình.
Làm tròn volume theo volume step. Nếu phần đóng nhỏ hơn volume tối thiểu, xử lý an toàn và ghi log; không gửi yêu cầu đóng volume không hợp lệ.
EA phải lưu trạng thái partial close để không đóng lặp lại sau tick mới hoặc sau khi terminal restart.
8. QUẢN LÝ VỊ THẾ
8.1. Break-even
Sau TP1, nếu Auto BE bật:

Dời SL về entry cộng/trừ BE offset.
Phí thực tế và slippage không được giả lập bằng offset ATR nếu người dùng yêu cầu BE theo phí; cần tính theo cấu hình broker.
Nếu Auto BE tắt, không dời SL và không được báo/cộng kết quả như thể đã hòa vốn.
Sửa lỗi bắt buộc: Pine hiện có thể ghi nhận kết quả TP1 + BE khi vị thế ở stage sau TP1 dù Auto BE tắt và stop chưa thực sự dời. EA không được lặp lại lỗi này.

8.2. Trailing
Sau khi đạt TP2:

Dời stop theo quy tắc gốc: dùng mức TP1 làm điểm khóa ban đầu.
ATR Dynamic: tính trailing theo ATR và khoảng cách cấu hình.
Structure Swing: phải triển khai bằng swing đã xác nhận; nếu chưa triển khai, không được để input này giả vờ hoạt động - hãy ẩn hoặc đánh dấu chưa hỗ trợ.
Không nới SL theo hướng làm tăng rủi ro ban đầu.
8.3. Time-decay và timeout
Time-decay khi đủ số nến, MFE nhỏ hơn ngưỡng R và ADX dưới ngưỡng, theo điều kiện Pine.
Max-hold đóng vị thế khi vượt số nến tối đa.
PnL thực hiện phải dựa trên fill price, partial close, commission và swap thực tế từ MT5; không dùng close của nến thay cho giá khớp thực khi thống kê live.
8.4. SL và target cùng bị chạm
Khi tester chỉ có dữ liệu OHLC và không xác định được thứ tự, ưu tiên SL trước.
Trên dữ liệu real ticks, sử dụng thứ tự tick thật.
Đưa quy tắc này vào báo cáo backtest.
9. TÍNH VOLUME VÀ RỦI RO
Tính volume theo số tiền có thể mất tại SL, không dùng trực tiếp công thức Pine riskUsd / dist cho mọi symbol.

Yêu cầu:

Tính khoảng cách entry-SL theo tick size.
Dùng tick value/tick size hoặc phương pháp tính PnL của symbol trong MT5 để tính tổn thất dự kiến mỗi lot.
Tính volume từ mức risk percentage.
Làm tròn xuống theo volume step.
Kiểm tra min/max volume, margin khả dụng, stop level và giới hạn của broker.
Từ chối lệnh nếu volume hợp lệ không đạt yêu cầu risk hoặc margin.
Ghi rõ risk tiền tệ, volume dự kiến, loss tại SL dự kiến và margin dự kiến.
Không lấy giá thanh lý từ công thức Pine làm bảo đảm an toàn. Nếu cần kiểm tra margin, ưu tiên API/đặc tính margin của MT5 và thông số broker; vẫn phải giới hạn volume và khoảng cách SL một cách độc lập.

10. GATES VÀ THỨ TỰ LÝ DO BLOCK
EA phải giữ mã lý do ngắn gọn, dễ lọc trong log. Tối thiểu gồm:

NO_DIRECTION
AMBIGUOUS_SETUP
BLOCKED_SCORE_LONG
BLOCKED_SCORE_SHORT
BLOCKED_MTF
BLOCKED_REGIME
BLOCKED_LIQUIDITY
BLOCKED_OBSTACLE
BLOCKED_OVEREXTENSION
BLOCKED_NO_ATR
BLOCKED_BAD_SL
BLOCKED_BAD_TP
BLOCKED_RR
BLOCKED_NET_RR
BLOCKED_MAX_LEV
BLOCKED_COOLDOWN
BLOCKED_DAILY_LIMIT
BLOCKED_CIRCUIT_BREAKER
BLOCKED_POSITION_OPEN
BTC_DUMPING_VETO
BTC_PUMPING_VETO
MODE_DISABLED
MODE_REGIME_MISMATCH
MODE_INVALIDATED
WAIT_CONFIRMATION
WAIT_PULLBACK
Log top blocker và toàn bộ blocker hiện tại. Không thay blocker thật bằng score hoặc quality.

Cần sửa: nếu timeframe hierarchy sai, phải block với mã cấu hình/MTF rõ ràng; không được coi hierarchy sai là điều kiện cho phép bỏ qua MTF.

11. DAILY LIMIT, COOLDOWN VÀ CIRCUIT BREAKER
Giới hạn số lệnh/ngày phải nêu rõ đang đếm lần gửi lệnh, pending order hay lệnh khớp. Đề xuất lưu riêng cả số lần gửi và số lệnh khớp.
Xác định timezone/reset day. Pine dùng ngày của dữ liệu chart, còn MT5 phụ thuộc broker/server; EA phải có input timezone hoặc quy tắc reset rõ ràng.
Cooldown phải tính từ nến giao dịch đã được xác định thống nhất.
Circuit breaker phải dựa trên lệnh đã đóng thật, tính cả partial close theo tổng PnL ròng.
Nếu circuit breaker reset hằng ngày, phải ghi rõ và có thể cấu hình.
12. TÍNH TƯƠNG THÍCH DỮ LIỆU
Forex/CFD có thể chỉ cung cấp tick volume; không coi đó là volume giao dịch tập trung.
Crypto perpetual, spot crypto và CFD crypto có thể có tick/contract size, phí, volume và giờ giao dịch khác nhau.
Gold/silver CFD khác hợp đồng futures; không giả định $1 biến động tương đương cùng một số tiền cho mọi lot.
Session filter cho crypto phải có thể tắt hoặc trung lập.
BTC leader ticker cần được cấu hình theo symbol mà terminal có dữ liệu; nếu không có dữ liệu BTC hợp lệ, log và áp dụng chính sách fail-safe rõ ràng. Không âm thầm coi thiếu dữ liệu là tín hiệu đạt gate.
Dữ liệu HTF và BTC phải được đồng bộ theo thời gian; xử lý thiếu bar hoặc symbol đóng cửa.
13. NHẬN XÉT BẮT BUỘC VỀ CÁC VẤN ĐỀ TRONG PINE
AI phải xử lý hoặc báo rõ các điểm sau trước khi hoàn thiện EA:

S/R merging: hàm thêm zone hiện có thể gộp zone bất kể support/resistance; sửa để chỉ gộp cùng phía.
S/R broken state: trường broken được khai báo nhưng trong mã gửi không thấy cập nhật; xác định điều kiện broken, cập nhật, rồi mới dùng để lọc.
Auto BE tắt: không được thống kê stop như BE khi stop thực tế vẫn ở mức SL ban đầu.
Trailing type: input Structure Swing phải có triển khai thật hoặc không được hiển thị như tính năng đang hoạt động.
Minimum volume check: input tm_minVolCheck cần có logic thật; nếu chưa có, triển khai hoặc bỏ/đánh dấu không sử dụng.
FVG trong score: không cộng điểm chỉ vì có FVG active; cần kiểm tra vị trí giá so với vùng và thống nhất rõ hành vi.
Limit và TP1 trên cùng nến: không giả định thứ tự khớp thuận lợi dựa trên OHLC.
Risk sizing: thay công thức sizing chung bằng tính toán dựa trên symbol/broker MT5.
Liquidation estimate: không dùng công thức ước lượng Pine như dữ liệu liquidation chính xác của broker.
ATR ở quản lý lệnh: xác định dùng ATR lúc vào lệnh hay ATR cập nhật mỗi bar cho BE/trailing; ghi rõ và dùng nhất quán.
Ngày và session: xác định timezone/reset day, đặc biệt khi dùng crypto 24/7 và server time khác timezone Pine.
Volume/fees: tách rõ tick volume, commission, spread, slippage và swap.
tm_liq_sweepOn: xác nhận đây chỉ là tùy chọn hiển thị hay là bật/tắt logic sweep; không để tên input gây hiểu lầm.
Các sửa đổi so với Pine phải được ghi trong changelog và có thể bật/tắt khi cần đối chiếu parity.

14. LOG VÀ TELEMETRY
Mỗi nến đánh giá tín hiệu cần log tối thiểu:

Timestamp server và timestamp bar.
Symbol, timeframe chart, setup TF, context TF.
Regime, hướng MTF, BTC gate nếu áp dụng.
LONG score, SHORT score, score gap, quality.
Entry mode và lý do chọn mode.
Giá entry/limit, SL, TP1/TP2/TP3, khoảng cách SL.
Volume, loss dự kiến tại SL, commission/spread ước lượng nếu có.
Top blocker và danh sách blocker.
Trạng thái order/position và mã lỗi retcode MT5.
Có input giới hạn log để tránh spam. Không ghi mỗi tick nếu không có sự kiện hoặc thay đổi trạng thái.

15. KIẾN TRÚC CODE GỢI Ý
Tách thành module hoặc nhóm hàm rõ ràng:

Inputs - tham số cấu hình.
SymbolInfo - tick/volume/contract/stop level.
NewBar - chỉ đánh giá một lần mỗi nến.
Indicators - indicator và dữ liệu MTF.
MarketStructure - pivot/BOS/CHoCH/retest/sweep.
Zones - S/R/FVG/OB.
Regime - classifier.
Scoring - LONG/SHORT score.
EntryModes - A/B/C.
Gates - blocker codes.
RiskSizing - volume, SL/TP và margin checks.
Execution - market/pending order, retry hợp lý, kiểm tra retcode.
PositionManager - partials, BE, trailing, time exit.
Persistence - khôi phục trạng thái sau restart.
Telemetry - log và dữ liệu phục vụ test.
Không tạo lệnh mới mỗi tick. Chống gửi trùng bằng magic number, symbol, bar time và trạng thái order/position.

16. TEST VÀ TIÊU CHUẨN NGHIỆM THU
16.1. Compile và kiểm thử chức năng
EA compile sạch, không có lỗi; warning phải được giải thích.
Kiểm tra LONG và SHORT riêng.
Kiểm tra netting và hedging nếu hỗ trợ.
Kiểm tra symbol có volume step khác nhau, digits khác nhau và stop level khác nhau.
Kiểm tra restart terminal khi có pending order và vị thế đang mở.
Kiểm tra lệnh bị từ chối, invalid volume, invalid stops, thiếu margin và thị trường đóng.
Kiểm tra partial close không lặp lại.
16.2. Đối chiếu với Pine
Trên cùng symbol, timeframe, timezone, inputs và dữ liệu:

So tín hiệu bar-by-bar.
So score LONG/SHORT, regime, MTF, entry mode, SL/TP và blocker.
Ghi các khác biệt do Pine repaint, broker data, intrabar execution hoặc các bug được sửa.
Không tuyên bố parity hoàn toàn nếu chưa có báo cáo đối chiếu.
16.3. Backtest
Dùng dữ liệu real ticks khi có thể, nhất là với scalp, pending order, SL/TP cùng nến và partial close.
Thêm spread, commission, slippage và swap thực tế hoặc giả định được ghi rõ.
Tách in-sample, validation và out-of-sample theo thời gian.
Làm walk-forward; tránh tối ưu trên toàn bộ dữ liệu rồi báo kết quả đó như kiểm chứng.
Báo cáo ít nhất: số lệnh, net profit, max drawdown, profit factor, expectancy, average R, win rate, tỷ lệ TP1 và các chi phí.
Tách kết quả LONG/SHORT, từng regime, từng mode, từng timeframe và từng asset.
So sánh ablation A-E; không giữ module chỉ vì làm đẹp kết quả trên một đoạn dữ liệu.
Thực hiện stress test tăng spread/slippage và thay đổi tham số quanh cấu hình gốc.
Chạy demo/forward test trước khi dùng tiền thật.
16.4. Tiêu chuẩn phát hành
Không đánh dấu EA “ready for live” nếu chưa:

Vượt kiểm tra compile và chức năng.
Kiểm tra volume/risk đúng với broker mục tiêu.
Có kết quả OOS và forward test được lưu.
Có giới hạn lỗ/ngày, giới hạn drawdown hoặc cơ chế dừng EA.
Có log đủ để truy ngược mọi lệnh và blocker.
17. QUYẾT ĐỊNH VỀ SCALP, INTRADAY VÀ SWING
Đây là hệ thống đa khung, không phải scalp thuần:

Cấu hình Pine mặc định dùng context D và setup H1; hierarchy yêu cầu chart không cao hơn setup TF. Vì vậy, mặc định hợp lý hơn với chart M15-H1, tùy symbol và cách broker cung cấp dữ liệu.
M1-M5 có thể được hỗ trợ, nhưng cần cấu hình entry, phí, spread, slippage, cooldown, ATR và độ chính xác dữ liệu riêng; không mặc định rằng thông số hiện tại phù hợp scalp.
Muốn swing dài hơn, cần cấu hình chart/setup/context timeframe cao hơn và kiểm tra lại toàn bộ cửa sổ nến, thời hạn pending, max holding bars và giới hạn rủi ro.
Không gộp kết quả scalp và swing vào một báo cáo hiệu suất; chúng phải được backtest và đánh giá riêng.
18. ĐẦU RA AI PHẢI TRẢ
AI lập trình phải bàn giao:

File .mq5 hoàn chỉnh.
Mã nguồn được chia hàm rõ ràng, có chú thích.
Hướng dẫn cài đặt và cấu hình trên MT5.
Danh sách input và giá trị mặc định.
Bảng mapping Pine-to-MQL5.
Danh sách bug đã sửa và khác biệt so với Pine.
Kết quả compile, test chức năng và backtest - không bịa kết quả.
Danh sách tính năng chưa triển khai.
Ví dụ log tín hiệu/block/lệnh/đóng lệnh.
Hướng dẫn chạy demo và điều kiện an toàn trước khi chạy live.
Quy tắc cuối: Nếu phần nào của Pine không thể chuyển đổi chính xác do khác biệt dữ liệu hoặc cách khớp lệnh giữa TradingView và MT5, AI phải nêu rõ, đề xuất quy tắc thay thế, và không tự ý giả lập hành vi có lợi cho kết quả backtest.
Wonderwhales MT5 EA - Đặc tả xây dựng
Phiên bản tài liệu: 1.0
Nền tảng: MetaTrader 5 / MQL5
Nguồn tín hiệu: Wonderwhales Pine Script v6 v1.2.0 do người dùng cung cấp
Mục tiêu: Port tín hiệu sang MT5 và cung cấp tùy chọn quản lý lệnh; không tự ý thay đổi logic tín hiệu gốc.
Chế độ khởi đầu: SignalOnly = true, EnableTrading = false.
1. Yêu cầu cho AI triển khai
Tạo EA MQL5 biên dịch được, không cần DLL hoặc thư viện ngoài.
Tách mã thành các phần: cấu hình, dữ liệu/indicator, tín hiệu, quản lý vị thế, tính lot/rủi ro, gửi lệnh và ghi log.
Cung cấp mã nguồn .mq5, hướng dẫn compile, danh sách input, kết quả kiểm thử và các giới hạn đã biết.
Không tự thêm bộ lọc, điều kiện vào/thoát hoặc cách tính rủi ro mà đặc tả không yêu cầu.
Những lựa chọn chưa có dữ liệu phải là input hoặc được ghi rõ cần người dùng xác nhận.
Bản đầu phải có chế độ chỉ ghi nhận tín hiệu, không gửi lệnh.
2. Thông tin chưa xác định
Không mặc định các thông tin sau; hãy cho phép cấu hình hoặc hỏi người dùng trước khi bật giao dịch:

Symbol và timeframe.
Broker, loại tài khoản netting/hedging và cách khớp lệnh.
Chế độ tín hiệu Wonderwhales.
Quy tắc khi có tín hiệu ngược.
Lot cố định hay lot theo phần trăm rủi ro.
Stop-loss, take-profit và có cho phép giao dịch không SL hay không.
Spread tối đa, deviation, giờ giao dịch và giới hạn số lệnh.
Nguồn volume nếu bật VSA: tick volume hay real volume.
Có cho phép giữ lệnh qua đêm/cuối tuần hay không.
3. Input đề xuất
3.1 Tín hiệu
InpSignalMode: PSAR_REVERSAL, EMA_CROSSOVER, SAR_EMA, SAR_EMA_ATR.
InpSignalTimeframe: mặc định PERIOD_CURRENT.
InpConfirmOnBarClose: mặc định true.
InpPSARStart: mặc định 0.02.
InpPSARIncrement: mặc định 0.02.
InpPSARMaximum: mặc định 0.2.
InpFastEMALength: mặc định 20.
InpSlowEMALength: mặc định 50.
InpATRLength: mặc định 14.
InpMinimumATRPercent: mặc định 0.5.
InpSignalOnly: mặc định true.
InpEnableTrading: mặc định false.
InpTradeOnStartupSignal: mặc định false.
3.2 Vị thế và quản lý lệnh
InpPositionPolicy:
ONE_POSITION_IGNORE_OPPOSITE: một vị thế; bỏ qua tín hiệu ngược.
CLOSE_ON_OPPOSITE: tín hiệu ngược đóng vị thế hiện tại, không mở vị thế ngược cùng tín hiệu.
CLOSE_AND_REVERSE: đóng vị thế hiện tại; chỉ mở hướng mới sau khi xác nhận đóng thành công.
ALLOW_MULTIPLE: cho phép nhiều vị thế theo giới hạn cấu hình.
InpMaxPositionsPerSymbolMagic: giới hạn số vị thế.
InpMagicNumber: magic number riêng của EA.
InpMaxBarsInPosition: 0 để tắt; nếu bật, đây là quy tắc mở rộng, không có trong Pine.
Chỉ quản lý vị thế đúng symbol và magic; không sửa hoặc đóng lệnh thủ công hay lệnh của EA khác.
3.3 Khối lượng và rủi ro
InpLotMode: lot cố định hoặc phần trăm rủi ro.
InpFixedLot: lot cố định, phải theo min/max/step của symbol.
InpRiskPercent: phần trăm equity hoặc balance cho mỗi lệnh; chỉ được dùng khi có SL hợp lệ.
InpStopLossMode: NONE, FIXED_POINTS, ATR_MULTIPLE, PSAR_LEVEL.
InpStopLossValue: tham số theo chế độ SL đã chọn.
InpTakeProfitMode: NONE, FIXED_POINTS, RISK_REWARD_MULTIPLE.
InpTakeProfitValue: tham số theo chế độ TP đã chọn.
InpAllowNoStopLoss: mặc định false khi bật giao dịch.
InpMaxSpreadPoints: 0 để tắt kiểm tra spread.
InpMaxDeviationPoints: deviation tối đa.
InpMaxTradesPerDay: 0 để không giới hạn.
InpMaxDailyLossPercent: 0 để tắt; nếu chạm ngưỡng thì ngừng mở lệnh mới trong ngày server.
Lưu ý: SL/TP, trailing stop, lot và giới hạn lỗ là phần quản lý chiến lược mới; Pine gốc không quy định các giá trị này. Không dùng PSAR làm trailing stop nếu người dùng chưa bật và xác nhận riêng.

3.4 VSA và log
InpVolumeSource: tick volume hoặc real volume.
InpVolumeMALength: mặc định 20.
Nếu tái tạo VSA, giữ các ngưỡng theo Pine; mặc định VSA không lọc tín hiệu giao dịch.
InpEnableVSAFilter: mặc định false; khi bật, phải đánh dấu đây là phần mở rộng.
InpLogLevel: ERROR, TRADE, SIGNAL, DEBUG.
InpWriteCSV: bật/tắt ghi CSV.
4. Định nghĩa tín hiệu
4.1 Quy ước nến
Shift 0 là nến đang chạy; shift 1 là nến vừa đóng.
Khi InpConfirmOnBarClose = true, chỉ đánh giá nến shift 1, vào thời điểm phát hiện nến mới.
Mỗi nến chỉ xử lý tín hiệu một lần; chống lặp bằng symbol, timeframe, thời gian nến, hướng tín hiệu và magic.
Khi khởi động EA, không vào lại một tín hiệu lịch sử, trừ khi InpTradeOnStartupSignal = true.
4.2 PSAR
Hướng tăng nếu PSAR < Close; hướng giảm nếu PSAR >= Close.
Buy flip khi hướng hiện tại tăng và hướng nến trước giảm.
Sell flip khi hướng hiện tại giảm và hướng nến trước tăng.
Không phát tín hiệu flip nếu thiếu dữ liệu hợp lệ để xác định cả hai hướng.
MQL5 iSAR chỉ có step và maximum; nếu InpPSARStart != InpPSARIncrement, dùng PSAR tự tính hoặc ghi rõ không đảm bảo parity.
Nếu tự tính PSAR, đối chiếu từng nến với TradingView, bao gồm khởi tạo, extreme point, gia tăng AF và giới hạn SAR theo các nến trước.
Tham khảo đặc tả MQL5 về iSAR.
4.3 EMA và ATR
EMA tính trên giá Close của symbol/timeframe tín hiệu.
EMA tăng khi EMA nhanh lớn hơn EMA chậm; EMA giảm khi EMA nhanh nhỏ hơn EMA chậm.
Buy crossover khi EMA nhanh chuyển từ <= EMA chậm sang > EMA chậm.
Sell crossover khi EMA nhanh chuyển từ >= EMA chậm sang < EMA chậm.
ATR phải tương thích với ta.atr() của Pine và được kiểm tra bằng so sánh dữ liệu.
ATRPercent = ATR / Close × 100; điều kiện ATR đạt khi phần trăm này lớn hơn hoặc bằng ngưỡng cấu hình.
Từ chối input không hợp lệ; không âm thầm đổi tham số.
4.4 Ánh xạ các chế độ
PSAR_REVERSAL: dùng PSAR flip.
EMA_CROSSOVER: dùng EMA crossover, độc lập với PSAR.
SAR_EMA: dùng PSAR flip nếu EMA xác nhận cùng hướng.
SAR_EMA_ATR: dùng PSAR flip nếu EMA xác nhận cùng hướng và ATR đạt ngưỡng.
VSA, RSI, Bollinger Bands và EMA 200 không tham gia tín hiệu gốc.
Ghi log riêng tín hiệu thô, tín hiệu hợp lệ và lý do bị lọc, như EMA không xác nhận hoặc ATR dưới ngưỡng.
4.5 Tín hiệu trong nến đang chạy
Khi xác nhận nến đóng bật, không dùng shift 0 để tạo lệnh.
Khi tắt xác nhận nến đóng, tín hiệu được đánh giá theo tick và có thể thay đổi trước lúc nến kết thúc.
Chống gửi lệnh lặp trong cùng nến và ghi rõ chế độ intrabar trong log.
Không diễn giải kết quả kiểm thử nến đóng như thể EA đã giao dịch đúng tại thời điểm tín hiệu intrabar.
5. Quản lý vị thế và gửi lệnh
Tách riêng phát hiện tín hiệu, áp dụng chính sách vị thế, tính lot/SL/TP, kiểm tra an toàn và gửi lệnh.
Với CLOSE_AND_REVERSE, không gửi lệnh mới nếu đóng vị thế cũ thất bại.
Xử lý khác biệt tài khoản netting và hedging; không xem nhiều deal trên tài khoản netting là nhiều vị thế độc lập.
Tính lot theo rủi ro dựa trên khoảng cách entry–SL cùng tick size và tick value của symbol.
Chuẩn hóa giá SL/TP theo tick size; kiểm tra stop level và freeze level.
Nếu broker từ chối SL/TP, ghi retcode; không bỏ SL để thử gửi lại khi InpAllowNoStopLoss = false.
Trước khi gửi lệnh, kiểm tra quyền giao dịch, trade mode của symbol, dữ liệu giá, spread, lot, margin, giới hạn lệnh và giới hạn lỗ ngày.
Sau khi gửi lệnh, kiểm tra retcode, ticket, deal, giá và volume khớp; kết quả trả về từ thư viện giao dịch không thay thế bước xác minh này.
6. Dữ liệu, handle và an toàn
Tạo indicator handle trong OnInit, kiểm tra lỗi và giải phóng trong OnDeinit.
Kiểm tra số bars đã tính và số phần tử nhận từ CopyBuffer; không dùng dữ liệu thiếu, EMPTY_VALUE hoặc dữ liệu chưa sẵn sàng.
Theo tài liệu CopyBuffer, vị trí bắt đầu 0 là nến hiện tại; kiểm tra thứ tự mảng để không nhầm shift.
Đọc OHLC theo đúng symbol/timeframe tín hiệu.
Dữ liệu volume TradingView và MT5 có thể khác; chọn rõ tick volume hoặc real volume. Nếu dữ liệu VSA không dùng được, ghi Unavailable, không biến nó thành tín hiệu.
Dùng OnTick để phát hiện nến mới; không xử lý lại cùng một nến ở mọi tick.
Không gửi lệnh nếu thiếu dữ liệu, indicator chưa sẵn sàng hoặc thông tin giá không hợp lệ.
7. Log và hiển thị
Mỗi lần có tín hiệu, bị lọc hoặc gửi lệnh, ghi tối thiểu:

Thời gian server, thời gian nến, symbol, timeframe và mode.
Close, PSAR, hướng SAR hiện tại/trước, EMA nhanh/chậm, ATR và ATR%.
Tín hiệu thô, tín hiệu hợp lệ, lý do bị chặn và chính sách vị thế áp dụng.
Spread, lot, entry, SL/TP dự kiến.
Kết quả gửi lệnh, retcode, ticket, giá và volume khớp.
CSV đề xuất:
time,symbol,timeframe,mode,bar_close,sar,fast_ema,slow_ema,atr,atr_pct,raw_signal,valid_signal,block_reason,spread,action,volume,sl,tp,retcode,ticket
Dashboard chart chỉ cần thể hiện trạng thái EA, symbol/timeframe, mode, spread, tín hiệu gần nhất, lý do không vào lệnh và trạng thái giao dịch. Không cần tái tạo giao diện TradingView để EA chạy đúng.

8. Kiểm thử và tiêu chí bàn giao
8.1 Kiểm tra tín hiệu
So sánh Pine và MT5 trên cùng symbol, timeframe và khoảng dữ liệu.
Đối chiếu từng nến đã đóng: OHLC, PSAR, hướng SAR, EMA, ATR, tín hiệu thô và tín hiệu hợp lệ.
Kiểm tra riêng trường hợp PSARStart = PSARIncrement và PSARStart != PSARIncrement.
Kiểm tra thiếu dữ liệu khởi tạo, SAR bằng Close, EMA bằng nhau, gap và dữ liệu lịch sử được cập nhật.
Báo cáo số nến khớp/lệch và sai số indicator; giải thích sai khác do dữ liệu giá, volume hoặc thuật toán nền tảng.
8.2 Kiểm tra sự kiện và vị thế
Xác nhận bar-close mode xử lý đúng một lần mỗi nến.
Restart hoặc gắn lại EA không gửi lại tín hiệu cũ, trừ khi input cho phép.
Kiểm tra tín hiệu intrabar xuất hiện rồi biến mất và ngăn gửi lệnh trùng.
Kiểm tra từng chính sách vị thế, tài khoản netting/hedging, đóng lệnh thất bại, partial fill, từ chối lệnh, spread vượt ngưỡng và margin không đủ.
Xác nhận EA chỉ sửa vị thế đúng symbol và magic.
8.3 Strategy Tester và báo cáo
Chạy SignalOnly trước khi bật giao dịch.
Kiểm thử khớp lệnh với spread, commission, swap và slippage phù hợp môi trường dự kiến.
Với xử lý intrabar hoặc SL/TP trong nến, dùng chế độ tick chi tiết; tham khảo tài liệu Strategy Tester MQL5.
Chia dữ liệu thành giai đoạn phát triển, ngoài mẫu và demo/forward; không đánh giá chỉ bằng kết quả tối ưu trong mẫu.
Báo cáo số lệnh, win rate, lãi/lỗ ròng, profit factor, drawdown tối đa, expectancy, lãi/lỗ trung bình, thời gian giữ lệnh và chi phí giao dịch.
Không tuyên bố EA có lợi nhuận hoặc phù hợp chạy tiền thật chỉ vì compile thành công hay một backtest có kết quả tốt.
8.4 Gói bàn giao
File .mq5 hoàn chỉnh và hướng dẫn cài đặt.
Danh sách input, giá trị mặc định, đơn vị và tác động.
Giải thích cách ánh xạ PSAR Pine–MQL5 cùng báo cáo parity test.
Log/CSV mẫu, báo cáo compile và Strategy Tester.
Danh sách rõ phần nào là port tín hiệu gốc, phần nào là tùy chọn mở rộng.
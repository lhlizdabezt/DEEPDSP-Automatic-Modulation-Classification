#import "../config.typ": *
#import "../facts.typ": facts

= KẾT QUẢ VÀ THẢO LUẬN

== Kiểm tra tín hiệu mô phỏng

#photo(
  "../assets/figures/01_iq_time_gallery.png",
  [Dạng sóng I/Q của sáu kiểu điều chế sau kênh tại SNR = 6 dB],
  height: 13.7cm,
) <fig-time>

@fig-time cho thấy PSK/QAM sau RRC có bao biến thiên do quá trình chuyển ký hiệu, trong khi FSK giữ bao gần hằng. Nhiễu và echo làm hai thành phần I/Q không còn quỹ đạo lý tưởng.

#photo(
  "../assets/figures/02_constellation_gallery.png",
  [Chòm sao quan sát tại SNR = 18 dB sau hiệu chỉnh CFO thô chỉ để trực quan],
  height: 12.0cm,
) <fig-constellation>

Chòm sao ở @fig-constellation không dùng đồng bộ ký hiệu hoàn chỉnh. Độ xoay còn lại và các điểm chuyển tiếp RRC giải thích vì sao hình không thành các cụm sắc như sơ đồ lý tưởng.

#photo(
  "../assets/figures/03_psd_gallery.png",
  [Mật độ phổ công suất Welch của sáu lớp tại SNR = 9 dB],
  height: 12.0cm,
) <fig-psd>

PSD phân biệt rõ hai họ. PSK/QAM tập trung quanh tần số mang băng gốc; FSK tạo nhiều vùng năng lượng theo các tần số trạng thái. 4FSK có độ trải phổ lớn hơn 2FSK.

#photo(
  "../assets/figures/04_dataset_balance.png",
  [Số khung ở từng tổ hợp lớp và SNR],
  height: 7.7cm,
) <fig-balance>

Mọi ô trong @fig-balance có đúng 100 khung. Vì vậy accuracy tổng thể không bị một lớp hoặc mức SNR chiếm ưu thế về số lượng.

== Không gian đặc trưng DSP

#photo(
  "../assets/figures/05_feature_pca.png",
  [Chiếu PCA hai chiều của 18 đặc trưng DSP trên tập test],
  height: 10.5cm,
) <fig-pca>

PCA chỉ là phép chiếu tuyến tính để quan sát, không phải đầu vào RF. Hai họ FSK tách tốt hơn, còn QPSK/8PSK/16QAM chồng lấn khi SNR thấp và có pha/CFO ngẫu nhiên.

== Quá trình huấn luyện CNN

#photo(
  "../assets/figures/06_training_curves.png",
  [Đường cong loss và validation accuracy của CompactIQCNN],
  height: 7.6cm,
) <fig-training>

CNN chạy #facts.cnn-epochs epoch trước khi early stopping, mất #facts.cnn-train-time trên CPU. Khoảng cách train–validation loss không tăng liên tục ở cuối, cho thấy early stopping đã dừng trước khi xu hướng overfit kéo dài.

== Kết quả tổng thể

#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 6pt,
  metric(facts.rf-f1, [RF macro-F1], note: facts.rf-accuracy, tone: "baseline"),
  metric(facts.cnn-f1, [CNN macro-F1], note: facts.cnn-accuracy),
  metric(
    facts.hybrid-f1,
    [Hybrid macro-F1],
    note: facts.hybrid-accuracy,
    tone: "best",
  ),
)

#v(0.15cm)

#tbl(
  standard-table(
    columns: (1.4fr, 1.15fr, 1.15fr, 1.35fr),
    [#cellhead[Mô hình]],
    [#cellhead[Accuracy]],
    [#cellhead[Macro-F1]],
    [#cellhead[Thời gian train]],
    [RF–DSP],
    [#facts.rf-accuracy],
    [#facts.rf-f1],
    [#facts.rf-train-time],
    [CNN–DSP],
    [#facts.cnn-accuracy],
    [#facts.cnn-f1],
    [#facts.cnn-train-time],
    [Hybrid],
    [#facts.hybrid-accuracy],
    [#facts.hybrid-f1],
    [Không train riêng],
  ),
  [Kết quả trên #facts.test-size khung test độc lập],
) <tab-main-results>

CNN tăng 0,1384 macro-F1 so với RF. Hybrid tăng thêm 0,0139 so với CNN và 0,1523 so với RF. Hệ số $alpha=#facts.hybrid-alpha$ được chọn trên validation, nên mức tăng hybrid không đến từ việc dò test.

#callout(
  [Diễn giải đúng phạm vi],
  [Hybrid tốt nhất trong cấu hình mô phỏng này. Sự khác biệt chưa được kiểm định qua nhiều lần huấn luyện độc lập và chưa chứng minh ưu thế trên dữ liệu SDR thật.],
  kind: "warning",
)

== Ma trận nhầm lẫn

#photo(
  "../assets/figures/07_confusion_rf.png",
  [Ma trận nhầm lẫn chuẩn hóa của Random Forest trên 18 đặc trưng DSP],
  height: 10.8cm,
) <fig-cm-rf>

RF nhận biết FSK tốt hơn nhóm PSK/QAM. Nhầm lẫn giữa QPSK và 8PSK phù hợp với việc các chòm sao có các điểm dùng chung và bị phá vỡ bởi noise, CFO, pha ngẫu nhiên @oshea2016.

#photo(
  "../assets/figures/08_confusion_cnn.png",
  [Ma trận nhầm lẫn chuẩn hóa của CompactIQCNN],
  height: 10.8cm,
) <fig-cm-cnn>

CNN giảm nhiều phần tử ngoài đường chéo so với RF, đặc biệt khi cần kết hợp mẫu hình cục bộ theo thời gian. Kết quả ủng hộ việc dùng biểu diễn tuần tự thay vì chỉ thống kê toàn khung.

#photo(
  "../assets/figures/09_confusion_hybrid.png",
  [Ma trận nhầm lẫn chuẩn hóa của mô hình tổ hợp xác suất],
  height: 10.8cm,
) <fig-cm-hybrid>

Hybrid giữ ưu điểm của CNN nhưng tận dụng xác suất RF ở các mẫu có dấu vết phổ/moment rõ. Không có luật thủ công theo lớp; hai vector xác suất được trộn cùng hệ số.

== Ảnh hưởng của SNR

#photo(
  "../assets/figures/10_accuracy_vs_snr.png",
  [Độ chính xác của ba phương pháp theo SNR],
  height: 8.5cm,
) <fig-snr>

Tại -12 dB, hybrid chỉ đạt 28,33%; thông tin điều chế bị nhiễu che lấp đáng kể. Đường cong tăng theo SNR và hybrid đạt đúng 90% ở #facts.hybrid-snr90, sau đó tiến đến 93,33% tại 15–18 dB.

Không nên chỉ báo một accuracy tổng thể vì nó trộn các vùng SNR khác nhau. Phân rã như @fig-snr giúp xác định vùng hoạt động thay vì che mất điểm gãy của hệ thống @oshea2016.

== Hiệu năng theo lớp

#photo(
  "../assets/figures/11_f1_by_class.png",
  [F1-score theo từng kiểu điều chế và phương pháp],
  height: 8.2cm,
) <fig-class-f1>

F1 theo lớp cho thấy độ khó không đồng đều. Các lớp FSK được hỗ trợ mạnh bởi cấu trúc tần số; PSK bậc cao chịu ảnh hưởng nhiều hơn từ noise và sai lệch pha.

== Độ quan trọng đặc trưng

#photo(
  "../assets/figures/12_feature_importance.png",
  [Độ quan trọng Gini của 18 đặc trưng trong Random Forest],
  height: 10.8cm,
) <fig-importance>

Feature importance là mức giảm impurity trung bình, không phải quan hệ nhân quả. Các đặc trưng tương quan có thể chia sẻ độ quan trọng; vì vậy biểu đồ dùng để giải thích xu hướng, không dùng để khẳng định một đại lượng là nguyên nhân duy nhất.

== Độ trễ cục bộ và demo

#tbl(
  compact-table(
    columns: (1.35fr, 1.25fr, 3fr),
    [#cellhead[Nhánh]],
    [#cellhead[ms/khung]],
    [#cellhead[Điều kiện đo]],
    [RF–DSP],
    [#facts.rf-latency],
    [Batch 256; không gồm thời gian trích 18 đặc trưng],
    [CNN–DSP],
    [#facts.cnn-latency],
    [CPU; batch 256; warm-up 5; 30 lần lặp],
  ),
  [Độ trễ suy luận đo trên máy chạy notebook],
) <tab-latency>

CNN nhanh hơn ở phần suy luận đã đo, nhưng so sánh chưa hoàn toàn đối xứng vì RF cần thêm bước trích đặc trưng. Các số này không đại diện cho vi điều khiển, FPGA hoặc pipeline SDR thời gian thực.

#photo(
  "../assets/figures/13_demo_prediction.png",
  [Demo một khung 16QAM tại SNR = 3 dB: chòm sao, PSD và xác suất hybrid],
  height: 7.8cm,
) <fig-demo>

@fig-demo gom ba góc nhìn cần thiết cho video: tín hiệu quan sát, dấu vết phổ và quyết định xác suất. Người xem có thể thay `demo_kind` và `demo_snr` trong notebook để tạo tình huống khác.

== Trả lời câu hỏi nghiên cứu

#callout(
  [Kết luận từ dữ liệu],
  [Trong cấu hình đã khóa, CNN–DSP cải thiện macro-F1 từ #facts.rf-f1 lên #facts.cnn-f1. Tổ hợp xác suất đạt #facts.hybrid-f1 và mốc 90% accuracy từ #facts.hybrid-snr90. Vì vậy hai nhánh có tính bổ sung trên dữ liệu mô phỏng đã nêu.],
  kind: "result",
)

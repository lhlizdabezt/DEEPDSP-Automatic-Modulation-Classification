#import "../config.typ": *
#import "../facts.typ": facts

= THIẾT KẾ THÍ NGHIỆM

== Kiến trúc tổng thể

#dsp-ai-pipeline() <fig-pipeline>

Chuỗi ở @fig-pipeline tách rõ phần vật lý tín hiệu, biểu diễn đặc trưng, mô hình phân loại và đánh giá. Mỗi kết quả cuối đều truy được về một cell notebook và một tệp hình trong thư mục `assets/figures`.

== Thiết kế dữ liệu

#tbl(
  standard-table(
    columns: (1.65fr, 1.45fr, 3fr),
    [#cellhead[Thành phần]],
    [#cellhead[Giá trị]],
    [#cellhead[Lý do]],
    [Lớp],
    [6],
    [Bao phủ PSK, QAM và FSK với mức phân biệt tăng dần],
    [SNR],
    [-12:3:18 dB],
    [Quan sát từ vùng nhiễu mạnh đến vùng ổn định],
    [Khung mỗi lớp–SNR],
    [100],
    [Dữ liệu cân bằng và thời gian chạy phù hợp CPU],
    [Độ dài khung],
    [256 mẫu],
    [Đủ 32 ký hiệu ở 8 mẫu/ký hiệu],
    [RRC],
    [$beta=0,35$; span 8],
    [Giới hạn băng thông cho PSK/QAM],
    [CFO],
    [$abs(Delta f) <= 0,002$],
    [Mô phỏng sai lệch dao động cục bộ nhẹ],
    [Echo],
    [0–0,20],
    [Đa đường nhẹ, trễ 1–4 mẫu],
    [Hạt giống],
    [22207056],
    [Tái lập đúng lần chạy],
  ),
  [Cấu hình bộ dữ liệu mô phỏng],
) <tab-data-config>

Mỗi khung được sinh độc lập từ chuỗi ký hiệu mới. Không dùng cửa sổ trượt trên một bản ghi dài; do đó các tập không chia sẻ đoạn tín hiệu gần trùng nhau.

Thiết kế tham khảo cách tổ chức dữ liệu tín hiệu tổng hợp và suy giảm kênh trong TorchSig @torchsig2026, nhưng bộ sinh của đồ án được viết riêng, tối giản cho phạm vi học phần và không sao chép mã nguồn.

== Các lớp điều chế

#tbl(
  compact-table(
    columns: (1.05fr, 1.3fr, 1.4fr, 2.25fr),
    [#cellhead[Lớp]],
    [#cellhead[Họ]],
    [#cellhead[Số trạng thái]],
    [#cellhead[Dấu vết DSP chính]],
    [BPSK],
    [PSK],
    [2 pha],
    [Moment chẵn và sai phân pha],
    [QPSK],
    [PSK],
    [4 pha],
    [Pha bốn cụm sau đồng bộ],
    [8PSK],
    [PSK],
    [8 pha],
    [Dễ nhầm QPSK ở SNR thấp],
    [16QAM],
    [QAM],
    [16 điểm],
    [Bao biên độ đa mức, PAPR cao hơn PSK],
    [2FSK],
    [FSK],
    [2 tần số],
    [Hai vùng năng lượng phổ],
    [4FSK],
    [FSK],
    [4 tần số],
    [Phổ rộng và nhiều trạng thái tần số],
  ),
  [Đặc điểm sáu lớp điều chế],
) <tab-classes>

== Chia dữ liệu và chống rò rỉ

Chỉ số mẫu được chia theo nhãn ghép `(class, SNR)`: 80% cho train+validation và 20% cho test. Phần train+validation được tách tiếp 15% làm validation.

Kết quả là #facts.train-size khung train, #facts.val-size validation và #facts.test-size test. Ba tập rời nhau theo chỉ số; phân bố lớp–SNR được giữ đồng đều.

SNR không xuất hiện trong vector 18 đặc trưng hay tensor CNN. Nó chỉ được dùng khi sinh nhiễu, phân tầng split và vẽ đường cong đánh giá.

== Hai nhánh biểu diễn

Nhánh RF tạo vector 18 chiều. Ngoài các moment, PAPR và entropy, vector còn có skewness/kurtosis bao, tỷ lệ đổi dấu I/Q, spectral flatness, centroid và spread.

Nhánh CNN tạo tensor $4 times 256$: I, Q, $abs(x)$ và $sin(Delta phi)$. Kênh sai phân pha giảm nhạy với pha khởi tạo, trong khi I/Q giữ quỹ đạo phức.

#cnn-architecture() <fig-cnn>

CompactIQCNN ở @fig-cnn có ba mức kênh 32, 64 và 96, hai lần max-pooling, global average pooling và lớp phân loại sáu đầu ra. Mạng có #facts.cnn-params tham số, đủ nhỏ để huấn luyện CPU trong notebook.

== Siêu tham số

#tbl(
  standard-table(
    columns: (2fr, 1.5fr, 2.5fr),
    [#cellhead[Hạng mục]],
    [#cellhead[Giá trị]],
    [#cellhead[Ghi chú]],
    [Random Forest],
    [400 cây],
    [min_samples_leaf=2; max_features=sqrt],
    [Optimizer],
    [AdamW],
    [learning rate $1,5 times 10^(-3)$; weight decay $10^(-4)$],
    [Batch],
    [256],
    [Giữ thời gian CPU ngắn],
    [Epoch tối đa],
    [22],
    [Early stopping patience 5],
    [Loss],
    [Cross-entropy],
    [Label smoothing 0,03],
    [Fusion],
    [$alpha in {0;0,05;...;1}$],
    [Chọn macro-F1 cao nhất trên validation],
  ),
  [Siêu tham số của hai mô hình và phép tổ hợp],
) <tab-hyperparameters>

== Quy trình đánh giá

Sau khi khóa mô hình, notebook tính accuracy và macro-F1 trên test. Ma trận nhầm lẫn được chuẩn hóa theo hàng để mỗi ô biểu thị tỷ lệ trong lớp thật.

Đường cong accuracy–SNR được tính từ các tập con test tương ứng. Mỗi điểm có 120 khung: 20 khung cho mỗi lớp tại một mức SNR.

Khoảng tin cậy 95% cho accuracy tổng thể dùng công thức Wilson. Độ trễ CNN được đo sau warm-up, batch 256 và 30 lần lặp; số đo RF loại trừ thời gian trích đặc trưng nên phải được chú thích đúng.

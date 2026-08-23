#import "../config.typ": *
#import "../facts.typ": facts

= TRIỂN KHAI NOTEBOOK VÀ ỨNG DỤNG DEMO

== Môi trường phần mềm

Notebook được chạy trên Windows 11, Python 3.14.3 và CPU. Các thư viện khoa học là NumPy 2.4.4, SciPy 1.17.1, scikit-learn 1.9.0, Matplotlib 3.10.9 và PyTorch 2.11.0+cpu.

SciPy cung cấp FFT, xử lý tín hiệu và thống kê số @scipy2020. Random Forest dùng API scikit-learn @sklearn2011. CNN được cài bằng lớp `torch.nn.Module` @paszke2019.

#callout(
  [Quy ước trình bày thuật toán],
  [Chương này dùng mã giả độc lập ngôn ngữ để làm rõ dữ liệu vào, dữ liệu ra, nhánh xử lý và điều kiện chống rò rỉ. Mã Python tương ứng được chuyển nguyên vẹn xuống Phụ lục A; notebook nộp kèm vẫn là nguồn thực thi đầy đủ.],
)

== Tạo xung RRC

Thuật toán 1 hiện thực ba miền của đáp ứng RRC ở @eq-rrc. Hai điểm suy biến được thay bằng giới hạn giải tích; bước cuối áp đặt bất biến năng lượng ở @eq-rrc-energy. Mã Python tương ứng nằm tại @code-rrc.

#pseudocode(
  [Sinh bộ hệ số RRC có năng lượng đơn vị],
  [$beta in (0,1]$: roll-off; $L$: số mẫu trên ký hiệu; $S$: độ dài theo ký hiệu],
  [Vector $g[0..S L]$ thỏa $sum_n abs(g[n])^2 = 1$],
  (
    pstep(
      0,
      [Đặt $N arrow.l S L$ và $t_n arrow.l (n-N/2)/L$, với $n=0,1,...,N$.],
    ),
    pstep(0, [#pkw[for] mỗi $n$ #pkw[do]]),
    pstep(1, [#pkw[if] $abs(t_n) < epsilon$ #pkw[then]]),
    pstep(2, [$g[n] arrow.l 1 + beta(4/pi - 1)$.]),
    pstep(1, [#pkw[else if] $||t_n|-1/(4 beta)| < epsilon$ #pkw[then]]),
    pstep(
      2,
      [Gán $g[n]$ bằng giới hạn giải tích của RRC tại $abs(t_n)=1/(4 beta)$.],
    ),
    pstep(1, [#pkw[else]]),
    pstep(2, [Đánh giá trực tiếp biểu thức RRC ở @eq-rrc tại $t=t_n$.]),
    pstep(1, [#pkw[end if]]),
    pstep(0, [#pkw[end for]]),
    pstep(0, [Chuẩn hóa $g arrow.l g / sqrt(sum_n abs(g[n])^2)$.]),
    pstep(0, [#pkw[return] $g$.]),
  ),
) <alg-rrc>

== Mô phỏng AWGN theo công suất đo

Công suất nhiễu được suy ra từ công suất của tín hiệu sau kênh. Cách này không ngầm giả sử công suất đầu vào bằng một và giữ đúng quan hệ ở @eq-noise-power. Mã triển khai nằm tại @code-awgn.

#pseudocode(
  [Chèn AWGN phức theo SNR yêu cầu],
  [Khung sạch $x[0..N-1]$ sau kênh và mức $gamma$ tính bằng dB],
  [Khung thu $r$ đã chuẩn hóa công suất],
  (
    pstep(0, [Tính $P_s arrow.l 1/N sum_n abs(x[n])^2$.]),
    pstep(0, [Đặt $P_w arrow.l P_s 10^(-gamma/10)$.]),
    pstep(0, [Sinh $u[n], v[n]$ độc lập theo $cal(N)(0,1)$.]),
    pstep(0, [Tạo $w[n] arrow.l sqrt(P_w/2)(u[n] + upright(j)v[n])$.]),
    pstep(0, [Cộng nhiễu: $r[n] arrow.l x[n] + w[n]$.]),
    pstep(
      0,
      [Chuẩn hóa $r arrow.l r / sqrt(1/N sum_n abs(r[n])^2 + epsilon)$.],
    ),
    pstep(0, [#pkw[return] $r$.]),
  ),
) <alg-awgn>

== Trích đặc trưng DSP

Nhánh cổ điển ánh xạ mỗi khung phức thành 18 đại lượng vô hướng. SNR không xuất hiện trong vector đặc trưng. Cửa sổ Hann giảm rò phổ trước FFT; phổ công suất chuẩn hóa được xem như một phân bố rời rạc để tính entropy, centroid và spread. Mã tính nhóm đặc trưng phổ nằm tại @code-features.

#pseudocode(
  [Trích vector đặc trưng DSP từ một khung I/Q],
  [Khung phức $z[0..N-1]$],
  [Vector đặc trưng $f in RR^18$ không chứa nhãn và SNR],
  (
    pstep(0, [Loại DC và chuẩn hóa RMS của $z$.]),
    pstep(
      0,
      [Tính thống kê biên độ: mean, độ lệch chuẩn, skewness, kurtosis và PAPR.],
    ),
    pstep(0, [Tính moment phức và độ tập trung sai phân pha.]),
    pstep(0, [Đặt $z_w[n] arrow.l z[n]w_"Hann"[n]$.]),
    pstep(0, [Tính $S[k] arrow.l abs("FFTshift"("FFT"(z_w))[k])^2$.]),
    pstep(0, [Chuẩn hóa $p[k] arrow.l S[k]/(sum_j S[j]+epsilon)$.]),
    pstep(0, [Tính centroid, spread và entropy phổ từ $p[k]$.]),
    pstep(
      0,
      [Ghép các nhóm thời gian, moment, pha và phổ theo thứ tự cố định.],
    ),
    pstep(0, [Kiểm tra $dim(f)=18$ và mọi phần tử của $f$ là hữu hạn.]),
    pstep(0, [#pkw[return] $f$.]),
  ),
) <alg-features>

== Tạo tensor CNN

Mỗi khung được đổi thành tensor bốn kênh $[I,Q,|x|,sin(Delta phi)]$. Hàm sin làm liên tục biểu diễn sai phân pha qua biên $-pi$ và $pi$; tensor không chứa SNR. Mã Python tương ứng nằm tại @code-tensor.

#pseudocode(
  [Tạo tensor bốn kênh cho CompactIQCNN],
  [Ma trận khung phức $X in CC^(B times N)$],
  [Tensor thực $T in RR^(B times 4 times N)$],
  (
    pstep(
      0,
      [Chuẩn hóa từng khung: $Z_b arrow.l X_b/sqrt("mean"(|X_b|^2)+epsilon)$.],
    ),
    pstep(0, [#pkw[for] $n=1,2,...,N-1$ #pkw[do]]),
    pstep(1, [$Delta phi_b[n] arrow.l angle(Z_b[n] Z_b^*[n-1])$.]),
    pstep(0, [#pkw[end for]]),
    pstep(0, [Sao chép giá trị biên để bổ sung $Delta phi_b[0]$.]),
    pstep(
      0,
      [Xếp kênh $T_b arrow.l [Re(Z_b), Im(Z_b), |Z_b|, sin(Delta phi_b)]$.],
    ),
    pstep(
      0,
      [Ép kiểu số thực 32 bit và kiểm tra kích thước $B times 4 times N$.],
    ),
    pstep(0, [#pkw[return] $T$.]),
  ),
) <alg-tensor>

== Chọn hệ số fusion

Hệ số $alpha$ chỉ được chọn trên validation. Tập test không tham gia tìm siêu tham số; đây là điều kiện cần để kết quả hybrid không bị lạc quan. Mã triển khai nằm tại @code-fusion.

#pseudocode(
  [Chọn trọng số tổ hợp xác suất mà không dùng tập test],
  [Xác suất RF/CNN trên validation và test; nhãn $y_"val"$; lưới $cal(A)$],
  [Trọng số $alpha^*$ và xác suất hybrid trên test],
  (
    pstep(0, [Khởi tạo ánh xạ điểm $J: cal(A) arrow.r RR$.]),
    pstep(0, [#pkw[for] mỗi $alpha in cal(A)$ #pkw[do]]),
    pstep(
      1,
      [$p_"val"^(alpha) arrow.l alpha p_"CNN,val" + (1-alpha)p_"RF,val"$.],
    ),
    pstep(
      1,
      [$J(alpha) arrow.l "macro-F1"(y_"val", arg max_c p_"val"^(alpha)(c))$.],
    ),
    pstep(0, [#pkw[end for]]),
    pstep(0, [Khóa $alpha^* arrow.l arg max_(alpha in cal(A)) J(alpha)$.]),
    pstep(
      0,
      [$p_"test" arrow.l alpha^* p_"CNN,test" + (1-alpha^*)p_"RF,test"$.],
    ),
    pstep(0, [#pkw[return] $(alpha^*, p_"test")$.]),
  ),
) <alg-fusion>

== Suy luận tương tác trên ứng dụng demo

Ứng dụng demo không đọc một dự đoán đã lưu. Mỗi lần bấm nút, nó sinh lại khung I/Q từ seed, áp kênh theo các tham số đang hiển thị, gọi đúng pipeline RF và checkpoint CNN của notebook, rồi mới dựng bốn đồ thị. Cơ chế này cho phép đối chiếu nhãn phát với nhãn dự đoán và lặp lại chính xác một phép thử. Mã điều phối tương ứng nằm tại @code-app-inference.

#pseudocode(
  [Suy luận một khung và tạo hồ sơ bằng chứng cho giao diện],
  [Lớp phát $c$; SNR $gamma$; seed $s$; biên echo $eta_h$; biên CFO $eta_f$; mô hình đã khóa $M_R, M_C$],
  [Dự đoán $hat(c)$; xác suất $p_R,p_C,p_H$; đồ thị $cal(V)$; nhật ký $cal(L)$],
  (
    pstep(0, [Khởi tạo bộ sinh số giả ngẫu nhiên $cal(R) arrow.l "PRNG"(s)$.]),
    pstep(0, [Sinh khung sạch $x$ thuộc lớp $c$; tạo dạng xung RRC với $L=8$.]),
    pstep(
      0,
      [Rút kênh hai tia, pha đầu, dịch thời gian và CFO trong các biên $eta_h, eta_f$.],
    ),
    pstep(0, [Đo công suất sau kênh và cộng AWGN để đạt $gamma$ dB.]),
    pstep(0, [Tính $f arrow.l "DSP18"(r)$ và $T arrow.l "IQTensor4"(r)$.]),
    pstep(
      0,
      [$p_R arrow.l M_R."predict_proba"(f)$; $p_C arrow.l "softmax"(M_C(T))$.],
    ),
    pstep(0, [$p_H arrow.l alpha^* p_C + (1-alpha^*)p_R$, với $alpha^*=0.55$.]),
    pstep(0, [$hat(c) arrow.l arg max_k p_H[k]$; $q arrow.l max_k p_H[k]$.]),
    pstep(
      0,
      [Kiểm tra $sum_k p_R[k] approx sum_k p_C[k] approx sum_k p_H[k] approx 1$ và mọi giá trị hữu hạn.],
    ),
    pstep(
      0,
      [Dựng $cal(V)$ gồm I/Q, chòm sao, PSD và ba vector xác suất; ghi seed, hệ số kênh, độ trễ vào $cal(L)$.],
    ),
    pstep(0, [#pkw[return] $(hat(c),q,p_R,p_C,p_H,cal(V),cal(L))$.]),
  ),
) <alg-app-inference>

#photo(
  "../assets/figures/14_demo_app.png",
  [Giao diện DEEPDSP-AMC Workbench khi suy luận trực tiếp một khung 16QAM tại SNR = 3 dB],
  height: 13.2cm,
) <fig-demo-app>

@fig-demo-app tổ chức màn hình theo hai miền: miền điều khiển khóa đầu vào phép thử và miền bằng chứng hiển thị nhãn, confidence, I/Q, chòm sao, PSD cùng xác suất RF–CNN–hybrid. Nhật ký trong ba tab cuối lưu hệ số kênh thực tế và thời gian từng công đoạn; nút quét sáu lớp chỉ là phép kiểm tra minh họa, không thay thế đánh giá trên 1.320 khung test.

#block(
  width: 100%,
  inset: (x: 10pt, y: 9pt),
  fill: pale-cyan,
  stroke: 0.75pt + cyan,
  radius: 2pt,
  breakable: false,
)[
  #set par(first-line-indent: 0pt, justify: false, leading: 0.38em)
  #grid(
    columns: (2.75cm, 1fr),
    column-gutter: 12pt,
    align: center + horizon,
    [
      #link(meta.video-url)[
        #plate-image("../assets/figures/15_video_demo_qr.png", height: 2.55cm)
      ]
    ],
    [
      #align(left)[
        #text(size: 8.2pt, weight: "bold", fill: cyan)[VIDEO DEMO TRỰC TUYẾN]
        #v(3pt)
        #text(
          weight: "bold",
          fill: navy,
        )[DEEPDSP-AMC — trình bày notebook, kết quả và ứng dụng tương tác]
        #v(4pt)
        Video dài 4 phút 50 giây, ghi lại quy trình xử lý tín hiệu và một lượt suy luận trực tiếp trên Workbench. Quét mã QR hoặc nhấn vào đường dẫn dưới đây.
        #v(4pt)
        #link(meta.video-url)[#text(weight: "bold")[Mở video demo trên YouTube]]
        #linebreak()
        #text(size: 8.5pt, fill: gray-4)[youtu.be/yl5Sk6plWXg]
      ]
    ],
  )
]

== Kiểm tra tự động

Notebook dừng bằng `assert` nếu dữ liệu chứa NaN/Inf, công suất chuẩn hóa sai, ba split giao nhau hoặc thiếu đầu ra. Notebook đã lưu có 33 cell; toàn bộ 22 cell code đều đã chạy và không có output lỗi. Ứng dụng được kiểm tra thêm bằng Streamlit AppTest và một trình duyệt thật: bốn nút, bốn biểu đồ, ba tab, suy luận đơn và quét sáu lớp đều hoạt động, không có exception hay lỗi console.

#tbl(
  compact-table(
    columns: (2.4fr, 1fr, 2.4fr, 1fr),
    [#cellhead[Chỉ tiêu]],
    [#cellhead[Giá trị]],
    [#cellhead[Chỉ tiêu]],
    [#cellhead[Giá trị]],
    [Tổng số cell],
    [33],
    [Code cell đã chạy],
    [22/22],
    [Output lỗi],
    [0],
    [Ảnh PNG nhúng],
    [13],
    [Tệp bắt buộc khác rỗng],
    [18/18],
    [Giao train/validation/test],
    [0 mẫu],
  ),
  [Kết quả kiểm tra notebook sau lần chạy phát hành],
) <tab-notebook-check>

== Đầu ra máy tạo

Notebook lưu `metrics.json`, lịch sử huấn luyện, dự đoán test, trọng số CNN, pipeline RF và 13 hình. Báo cáo chỉ dùng các số liệu có trong `metrics.json` của lần chạy cuối.

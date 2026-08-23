#import "../config.typ": *

= CƠ SỞ LÝ THUYẾT

== Biểu diễn băng gốc phức

Một khung tín hiệu thu được biểu diễn bởi

$ x[n] = I[n] + upright(j) Q[n], quad n = 0, 1, ..., N-1. $ <eq-iq>

Trong đó $I[n]$ là thành phần đồng pha, $Q[n]$ là thành phần vuông pha và $upright(j)^2=-1$. Biểu diễn này giữ được cả biên độ lẫn pha tức thời, phù hợp với chuỗi thu của SDR.

Công suất trung bình của khung dài $N$ là

$ P_x = 1/N sum_(n=0)^(N-1) abs(x[n])^2. $ <eq-power>

Notebook chuẩn hóa $x[n] arrow.l x[n]/sqrt(P_x + epsilon)$ trước khi trích đặc trưng. Bước này loại hệ số khuếch đại chung nhưng không loại cấu trúc điều chế.

== Ánh xạ ký hiệu số

Với $M$-PSK, ký hiệu lý tưởng có biên độ không đổi:

$
  a_k = exp(upright(j)(2 pi k/M + phi_"off")), quad k in {0, ..., M-1}.
$ <eq-psk>

16QAM dùng hai trục mức $I,Q in {-3,-1,1,3}$ và chuẩn hóa bởi $sqrt(10)$:

$ a_(p,q) = (p + upright(j) q)/sqrt(10). $ <eq-qam>

FSK mã hóa ký hiệu bằng tần số tức thời. Với chuỗi tần số chuẩn hóa $f_m[n]$, pha liên tục được tạo bởi

$
  phi[n] = phi[n-1] + 2 pi f_m[n], quad x[n] = exp(upright(j) phi[n]).
$ <eq-fsk>

Các công thức chòm sao và mô hình kênh băng gốc tuân theo cách trình bày chuẩn của truyền thông số @proakis2008.

== Tạo dạng xung RRC và tích chập

PSK/QAM được chèn không theo hệ số $L=8$ rồi lọc RRC. Với roll-off $beta=0,35$, đáp ứng xung liên tục chuẩn hóa là

$
  g(t) = (sin(pi t(1-beta)) + 4 beta t cos(pi t(1+beta)))
  / (pi t (1-(4 beta t)^2)).
$ <eq-rrc>

Hai điểm suy biến $t=0$ và $abs(t)=1/(4 beta)$ được tính bằng giới hạn giải tích. Vector hệ số sau cùng được chuẩn hóa năng lượng:

$ sum_n abs(g[n])^2 = 1. $ <eq-rrc-energy>

Phép lọc là tích chập của chuỗi chèn không $u[n]$ với $g[n]$:

$ s[n] = (u * g)[n] = sum_k u[k] g[n-k]. $ <eq-convolution>

Đây là ứng dụng trực tiếp của hệ LTI và tích chập đã học trong Bài 2 @dsp2026.

== Mô hình kênh

Kênh mô phỏng được viết gọn:

$
  r[n] = exp(upright(j)(2 pi Delta f n + phi_0)) (s * h)[n-n_0] + w[n].
$ <eq-channel>

$Delta f$ là CFO, $phi_0$ là lệch pha, $n_0$ là dịch thời gian. Đáp ứng $h[n]$ gồm tia chính và một echo yếu trễ 1–4 mẫu. Nhiễu $w[n]$ là Gaussian phức tròn.

Với công suất tín hiệu $P_s$, công suất nhiễu cho SNR yêu cầu được đặt bởi

$ P_w = P_s 10^(-"SNR"_"dB"/10). $ <eq-noise-power>

Hai thành phần nhiễu thực và ảo độc lập có phương sai $P_w/2$. Nhờ vậy tổng công suất nhiễu phức bằng $P_w$.

== Phân tích Fourier và mật độ phổ công suất

DFT của khung dài $N$ là

$ X[k] = sum_(n=0)^(N-1) x[n] exp(-upright(j) 2 pi k n/N). $ <eq-dft>

Nhân cửa sổ Hann trước FFT giảm rò phổ do quan sát hữu hạn; đánh đổi giữa độ rộng búp chính và búp phụ cần được hiểu đúng @harris1978.

Đồ án dùng phương pháp Welch để vẽ PSD. Tín hiệu được chia thành các đoạn chồng lấn, tính periodogram có cửa sổ rồi lấy trung bình @welch1967:

$
  hat(S)_"xx"[k] = 1/L sum_(l=1)^L 1/(N U) abs("DFT"(w[n] x_l[n]))^2.
$ <eq-welch>

PSD dùng để diễn giải khác biệt giữa FSK và PSK/QAM, đồng thời tạo entropy, centroid và spread phổ.

== Đặc trưng DSP

PAPR đo độ đỉnh của bao tín hiệu:

$ "PAPR" = max_n abs(x[n])^2 / (1/N sum_n abs(x[n])^2). $ <eq-papr>

Moment phức tổng quát được định nghĩa

$ M_(p,q) = E{x^(p-q) (x^*)^q}. $ <eq-moment>

Notebook dùng độ lớn của $E{x^2}$, $E{x^4}$ và $E{x^6}$ như các dấu vết bất biến tương đối với pha. Độ tập trung sai phân pha là

$
  R_(Delta phi) = abs(1/(N-1) sum_(n=1)^(N-1) exp(upright(j) Delta phi[n])).
$ <eq-phase-concentration>

Với phổ công suất chuẩn hóa $p_k$, entropy phổ là

$
  H_s = -1/(log_2 N) sum_(k=0)^(N-1) p_k log_2(p_k + epsilon).
$ <eq-spectral-entropy>

Giá trị gần 1 biểu thị năng lượng dàn đều; giá trị thấp cho thấy năng lượng tập trung. Tổng cộng 18 đặc trưng được đưa vào Random Forest.

== Random Forest

Random Forest là tổ hợp nhiều cây quyết định huấn luyện trên các mẫu bootstrap và tập con đặc trưng ngẫu nhiên @breiman2001. Xác suất lớp được lấy trung bình từ $T$ cây:

$ hat(p)_"RF"(c|x) = 1/T sum_(t=1)^T p_t(c|x). $ <eq-rf>

Ưu điểm trong đồ án là huấn luyện nhanh, xử lý quan hệ phi tuyến và cung cấp feature importance. Nhược điểm là phụ thuộc chất lượng đặc trưng thủ công.

== CNN 1-D và tổ hợp xác suất

Một lớp tích chập 1-D tính

$ y_k[n] = sigma(b_k + sum_c sum_(m=0)^(M-1) w_(k,c)[m] x_c[n-m]). $ <eq-conv1d>

Đầu ra cuối dùng softmax:

$ p(c|x) = exp(z_c) / sum_(j=1)^C exp(z_j). $ <eq-softmax>

CNN được huấn luyện bằng cross-entropy có label smoothing nhỏ. PyTorch cung cấp tensor, tự động vi phân và các kernel tối ưu cho chuỗi huấn luyện @paszke2019.

Hai vector xác suất được tổ hợp:

$ p_"hybrid" = alpha p_"CNN" + (1-alpha) p_"RF". $ <eq-fusion>

$alpha$ được quét trên validation và cố định trước test. Đây là ranh giới quan trọng để không dùng tập test như một tham số huấn luyện.

== Chỉ số đánh giá

Accuracy đo tỷ lệ dự đoán đúng toàn bộ:

$ "Accuracy" = (sum_c "TP"_c) / N. $ <eq-accuracy>

Với lớp $c$, precision và recall là

$
  "Precision"_c = "TP"_c/("TP"_c+"FP"_c), quad "Recall"_c = "TP"_c/("TP"_c+"FN"_c).
$ <eq-pr>

$ "F1"_c=2 P_c R_c/(P_c+R_c) $ và macro-F1 là trung bình không trọng số trên sáu lớp. Dù dữ liệu cân bằng, macro-F1 vẫn hữu ích để phát hiện lớp yếu.

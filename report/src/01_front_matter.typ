#import "../config.typ": *
#import "../facts.typ": facts

#let commitment-page() = [
  #unnumbered-chapter([CAM KẾT])
  Tôi cam đoan các số liệu và kết quả trong bản mô tả này được tạo từ notebook đi kèm với hạt giống ngẫu nhiên cố định. Các kết quả accuracy, macro-F1, thời gian huấn luyện và độ trễ suy luận đều được lấy từ lần chạy đã lưu; không dùng số liệu thay thế từ bài báo hoặc kho mã khác.

  Mã nguồn tham khảo, thư viện phần mềm và tài liệu học thuật được nêu rõ trong phần tài liệu tham khảo. Những giới hạn của dữ liệu mô phỏng và phạm vi đánh giá được trình bày cùng kết quả. Tôi chịu trách nhiệm kiểm tra lại nội dung, mã nguồn và sản phẩm nộp.

  #v(1.2cm)
  #align(right)[
    #set par(first-line-indent: 0pt, justify: false)
    #text(style: "italic")[Thành phố Hồ Chí Minh, tháng 08 năm 2026]
    #v(1.25cm)
    #strong[#meta.student]
    #linebreak()
    MSSV: #meta.student-id
  ]
  #pagebreak()
]

#let abstract-vi-page() = [
  #unnumbered-chapter([TÓM TẮT])
  Đồ án xây dựng một hệ thống nhận dạng điều chế tự động cho sáu dạng tín hiệu số BPSK, QPSK, 8PSK, 16QAM, 2FSK và 4FSK. Dữ liệu gồm #facts.total-frames khung I/Q, mỗi khung #facts.frame-len mẫu, được sinh cân bằng trên 11 mức SNR từ -12 dB đến 18 dB. Chuỗi mô phỏng có tạo dạng xung root-raised-cosine, lệch pha, sai lệch tần số sóng mang, đa đường nhẹ và nhiễu Gaussian trắng cộng.

  Hệ thống gồm hai nhánh. Nhánh học máy trích 18 đặc trưng DSP trong miền biên độ, pha, moment phức và phổ rồi huấn luyện Random Forest. Nhánh học sâu dùng CNN 1-D nhận tensor bốn kênh gồm I, Q, biên độ và sai phân pha. Hệ số tổ hợp xác suất được chọn trên tập validation, sau đó khóa trước khi đánh giá tập test độc lập.

  Trên #facts.test-size khung test, Random Forest đạt accuracy #facts.rf-accuracy và macro-F1 #facts.rf-f1; CNN đạt #facts.cnn-accuracy và #facts.cnn-f1. Mô hình hybrid đạt accuracy #facts.hybrid-accuracy, macro-F1 #facts.hybrid-f1 và chạm mốc 90% accuracy từ #facts.hybrid-snr90. Kết quả cho thấy đặc trưng học sâu và đặc trưng DSP có tính bổ sung trong điều kiện mô phỏng. Đồ án chưa thay thế đánh giá trên tín hiệu SDR thực; đây là hướng mở rộng chính.

  #noindent[
    #strong[Từ khóa:] nhận dạng điều chế tự động, tín hiệu I/Q, FFT, mật độ phổ công suất, Random Forest, CNN 1-D, SNR.
  ]
  #pagebreak()
]

#let abstract-en-page() = [
  #unnumbered-chapter([ABSTRACT])
  #set text(lang: "en")
  This project develops an automatic modulation classification system for six digital modulation families: BPSK, QPSK, 8PSK, 16QAM, 2FSK, and 4FSK. The balanced synthetic dataset contains #facts.total-frames complex baseband frames, each with #facts.frame-len I/Q samples, over eleven SNR levels from -12 dB to 18 dB. The channel model includes root-raised-cosine pulse shaping, phase offset, carrier-frequency offset, mild multipath, and additive white Gaussian noise.

  Two classification branches are evaluated. The machine-learning branch extracts 18 DSP features from amplitude, phase, higher-order complex moments, and spectrum, followed by a Random Forest classifier. The deep-learning branch uses a compact one-dimensional CNN with four input channels: I, Q, magnitude, and phase difference. A probability fusion weight is selected only on the validation set and then frozen for the independent test set.

  On #facts.test-size test frames, the Random Forest reaches #facts.rf-accuracy accuracy and #facts.rf-f1 macro-F1; the CNN reaches #facts.cnn-accuracy and #facts.cnn-f1. The hybrid model reaches #facts.hybrid-accuracy accuracy and #facts.hybrid-f1 macro-F1, attaining 90% accuracy from #facts.hybrid-snr90. The experiment supports the complementary use of engineered DSP features and learned temporal features under the stated simulation assumptions. Validation with over-the-air SDR captures remains future work.

  #noindent[
    #strong[Keywords:] automatic modulation classification, I/Q signal, digital signal processing, Random Forest, one-dimensional CNN, signal-to-noise ratio.
  ]
  #pagebreak()
]

#let abbreviations-page() = [
  #unnumbered-chapter([DANH SÁCH TỪ VIẾT TẮT])
  #tbl(
    standard-table(
      columns: (1.2fr, 2.2fr, 2.6fr),
      [#cellhead[Ký hiệu]],
      [#cellhead[Tiếng Anh]],
      [#cellhead[Giải thích]],
      [AMC],
      [Automatic Modulation Classification],
      [Nhận dạng điều chế tự động],
      [AWGN],
      [Additive White Gaussian Noise],
      [Nhiễu Gaussian trắng cộng],
      [CNN],
      [Convolutional Neural Network],
      [Mạng nơ-ron tích chập],
      [CFO],
      [Carrier Frequency Offset],
      [Sai lệch tần số sóng mang],
      [DFT/FFT],
      [Discrete/Fast Fourier Transform],
      [Biến đổi Fourier rời rạc/nhanh],
      [DSP],
      [Digital Signal Processing],
      [Xử lý tín hiệu số],
      [FSK],
      [Frequency-Shift Keying],
      [Điều chế dịch tần],
      [I/Q],
      [In-phase/Quadrature],
      [Hai thành phần tín hiệu băng gốc phức],
      [PAPR],
      [Peak-to-Average Power Ratio],
      [Tỷ số công suất đỉnh trên trung bình],
      [PSK],
      [Phase-Shift Keying],
      [Điều chế dịch pha],
      [PSD],
      [Power Spectral Density],
      [Mật độ phổ công suất],
      [QAM],
      [Quadrature Amplitude Modulation],
      [Điều chế biên độ cầu phương],
      [RF],
      [Random Forest],
      [Rừng ngẫu nhiên],
      [RRC],
      [Root-Raised-Cosine],
      [Bộ lọc tạo dạng xung căn cosine nâng],
      [SDR],
      [Software-Defined Radio],
      [Vô tuyến định nghĩa bằng phần mềm],
      [SNR],
      [Signal-to-Noise Ratio],
      [Tỷ số tín hiệu trên nhiễu],
    ),
    [Các từ viết tắt dùng trong báo cáo],
  )
  #pagebreak()
]


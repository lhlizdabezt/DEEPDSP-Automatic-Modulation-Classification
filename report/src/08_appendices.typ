#import "../config.typ": *

#unnumbered-chapter([PHỤ LỤC A — MÃ NGUỒN TRIỂN KHAI CHỌN LỌC])

Phụ lục này tập trung các đoạn mã Python đã được mô tả bằng mã giả trong Chương 4. Các listing được trích từ notebook phát hành; notebook `24DTV_DKD2_22207056_LuongHaiLong_SourceCode_AMC.ipynb` là nguồn đầy đủ và có thể thực thi.

#heading(level: 2, numbering: none)[A.1. Sinh bộ hệ số RRC]

#source-listing(
  [
    ```python
    def rrc_taps(beta, sps, span_symbols):
        n = np.arange(-span_symbols*sps/2, span_symbols*sps/2 + 1)
        t = n / sps
        taps = np.empty_like(t, dtype=float)
        for i, ti in enumerate(t):
            if np.isclose(ti, 0.0):
                taps[i] = 1 + beta * (4/np.pi - 1)
            elif np.isclose(abs(ti), 1/(4*beta)):
                taps[i] = (beta/np.sqrt(2)) * (
                    (1 + 2/np.pi)*np.sin(np.pi/(4*beta))
                    + (1 - 2/np.pi)*np.cos(np.pi/(4*beta))
                )
            else:
                num = np.sin(np.pi*ti*(1-beta))
                num += 4*beta*ti*np.cos(np.pi*ti*(1+beta))
                taps[i] = num / (np.pi*ti*(1-(4*beta*ti)**2))
        return taps / np.sqrt(np.sum(taps**2))
    ```
  ],
  [Hàm tạo bộ lọc RRC và xử lý hai điểm suy biến giải tích],
) <code-rrc>

#heading(level: 2, numbering: none)[A.2. Chèn AWGN theo công suất đo]

#source-listing(
  [
    ```python
    signal_power = float(np.mean(np.abs(shifted) ** 2))
    noise_power = signal_power / (10.0 ** (snr_db / 10.0))
    noise = np.sqrt(noise_power / 2.0) * (
        rng.standard_normal(len(clean))
        + 1j * rng.standard_normal(len(clean))
    )
    received = shifted + noise
    received /= np.sqrt(np.mean(np.abs(received) ** 2) + 1e-12)
    ```
  ],
  [Đặt công suất AWGN phức từ SNR và chuẩn hóa khung thu],
) <code-awgn>

#heading(level: 2, numbering: none)[A.3. Nhóm đặc trưng phổ]

#source-listing(
  [
    ```python
    windowed = z * signal.windows.hann(len(z), sym=False)
    spectrum = np.abs(np.fft.fftshift(np.fft.fft(windowed))) ** 2
    p = spectrum / (np.sum(spectrum) + 1e-12)
    freq = np.fft.fftshift(np.fft.fftfreq(len(z)))
    centroid = float(np.sum(freq * p))
    spread = float(np.sqrt(np.sum(((freq-centroid)**2) * p)))
    spectral_entropy = -np.sum(p*np.log2(p+1e-12)) / np.log2(len(p))
    ```
  ],
  [Trích centroid, spread và entropy từ phổ công suất đã chuẩn hóa],
) <code-features>

#heading(level: 2, numbering: none)[A.4. Tạo tensor bốn kênh]

#source-listing(
  [
    ```python
    def cnn_tensor(x_complex):
        z = x_complex / np.sqrt(
            np.mean(np.abs(x_complex)**2, axis=1, keepdims=True) + 1e-12
        )
        dphase = np.angle(z[:, 1:] * np.conj(z[:, :-1]))
        dphase = np.pad(dphase, ((0, 0), (1, 0)), mode="edge")
        return np.stack(
            [z.real, z.imag, np.abs(z), np.sin(dphase)], axis=1
        ).astype(np.float32)
    ```
  ],
  [Chuyển khung I/Q sang biểu diễn I–Q–biên độ–sai phân pha],
) <code-tensor>

#heading(level: 2, numbering: none)[A.5. Chọn hệ số fusion]

#source-listing(
  [
    ```python
    alpha_grid = np.linspace(0.0, 1.0, 21)
    scores = []
    for alpha in alpha_grid:
        val_prob = alpha*cnn_val_prob + (1-alpha)*rf_val_prob
        scores.append(f1_score(y_val, val_prob.argmax(1), average="macro"))
    best_alpha = float(alpha_grid[np.argmax(scores)])
    hybrid_prob = best_alpha*cnn_test_prob + (1-best_alpha)*rf_test_prob
    ```
  ],
  [Khóa trọng số tổ hợp trên validation trước khi suy luận tập test],
) <code-fusion>

#heading(level: 2, numbering: none)[A.6. Suy luận trực tiếp cho ứng dụng demo]

#source-listing(
  [
    ```python
    def infer_frame(bundle, modulation, channel, seed):
        rng = np.random.default_rng(seed)
        clean = generate_clean_frame(modulation, rng)
        received, channel_meta = apply_channel(clean, channel, rng)

        features = dsp_features(received)
        rf_prob = bundle.rf.predict_proba(features.reshape(1, -1))[0]
        cnn_input = torch.from_numpy(
            cnn_tensor(received.reshape(1, -1))
        ).to(bundle.device)
        with torch.inference_mode():
            cnn_prob = torch.softmax(bundle.cnn(cnn_input), dim=1)[0]
            cnn_prob = cnn_prob.cpu().numpy()

        hybrid_prob = (
            bundle.alpha_cnn * cnn_prob
            + (1.0 - bundle.alpha_cnn) * rf_prob
        )
        predicted_index = int(np.argmax(hybrid_prob))
        return {
            "received": received,
            "channel": channel_meta,
            "rf_probability": rf_prob,
            "cnn_probability": cnn_prob,
            "hybrid_probability": hybrid_prob,
            "prediction": bundle.classes[predicted_index],
        }
    ```
  ],
  [Điều phối bộ sinh tín hiệu, hai mô hình đã khóa và fusion cho một lần bấm nút],
) <code-app-inference>

Mã đầy đủ của giao diện, engine DSP, cấu hình theme và launcher Windows nằm trong gói `24DTV_DKD2_22207056_LuongHaiLong_DemoApp_AMC.zip`. Hai tệp mô hình kèm gói là bản sao nén của artifact do notebook tạo, không phải mô hình huấn luyện riêng cho demo.

#heading(level: 2, numbering: none)[A.7. Đối chiếu nguồn mở]

Kho TorchSig được khảo sát để hiểu cách một toolkit hiện đại tổ chức dữ liệu tín hiệu, lớp điều chế và impairment @torchsig2026. Bài báo CNN AMC của O'Shea và cộng sự định hướng cách đánh giá theo SNR @oshea2016.

Mã nguồn đồ án không sao chép module từ các kho trên. Bộ sinh, đặc trưng, CompactIQCNN, huấn luyện và hình vẽ đều nằm trong notebook nộp kèm; thư viện bên thứ ba được gọi qua API công khai.

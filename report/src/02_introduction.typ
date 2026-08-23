#import "../config.typ": *
#import "../facts.typ": facts

= GIỚI THIỆU

== Bối cảnh và lý do chọn đề tài

Nhận dạng điều chế tự động (automatic modulation classification — AMC) là bước xác định kiểu điều chế của tín hiệu đã phát hiện trước khi chọn bộ giải điều chế. Bài toán có ý nghĩa trong máy thu thích nghi, giám sát phổ và vô tuyến nhận thức @dobre2007.

Khác với bài toán ảnh, AMC làm việc trực tiếp với chuỗi băng gốc phức. Mỗi mẫu chứa hai thành phần đồng pha và vuông pha; cấu trúc hữu ích có thể nằm ở biên độ, sai phân pha, moment bậc cao hoặc phân bố năng lượng theo tần số.

Các nghiên cứu CNN trên tín hiệu vô tuyến cho thấy đặc trưng có thể được học trực tiếp từ chuỗi I/Q, đặc biệt khi đánh giá được phân rã theo SNR @oshea2016 @oshea2018. Tuy vậy, đặc trưng DSP vẫn có giá trị vì dễ giải thích và chạy tốt với dữ liệu vừa phải.

Giáo trình học phần đi từ tín hiệu rời rạc, hệ LTI và tích chập đến DFT/FFT, phân tích phổ, lọc FIR và IIR @dsp2026. Đề tài nối các khối kiến thức đó thành một chuỗi thu vô tuyến có đầu ra định lượng, thay vì dùng ML như một hộp đen tách rời môn học.

== Câu hỏi nghiên cứu

#callout(
  [Câu hỏi trung tâm],
  [Với khung I/Q dài 256 mẫu, sáu kiểu điều chế và SNR từ -12 dB đến 18 dB, CNN 1-D trên biểu diễn tuần tự DSP có cải thiện macro-F1 so với Random Forest dùng 18 đặc trưng DSP hay không; và tổ hợp xác suất của hai mô hình đạt mốc 90% accuracy từ mức SNR nào?],
)

Câu hỏi được giới hạn trong mô phỏng có kiểm soát. Kết quả không được suy rộng thành hiệu năng của một máy thu SDR thực nếu chưa có dữ liệu thu qua phần cứng.

== Mục tiêu

Đồ án đặt ra năm mục tiêu có thể kiểm tra:

- Xây dựng bộ sinh BPSK, QPSK, 8PSK, 16QAM, 2FSK và 4FSK ở dạng I/Q.
- Mô phỏng RRC, AWGN, lệch pha, CFO, dịch thời gian và đa đường nhẹ.
- Thiết kế baseline Random Forest với đặc trưng DSP có ý nghĩa vật lý.
- Huấn luyện CNN 1-D gọn nhẹ và chọn hệ số fusion chỉ trên validation.
- Đánh giá bằng accuracy, macro-F1, ma trận nhầm lẫn, đường cong theo SNR và độ trễ cục bộ.

== Liên hệ với nội dung học phần

#tbl(
  standard-table(
    columns: (1.45fr, 2.3fr, 2.5fr),
    [#cellhead[Khối kiến thức]],
    [#cellhead[Nội dung trong giáo trình/lab]],
    [#cellhead[Cách dùng trong đồ án]],
    [Tín hiệu rời rạc],
    [Tạo và biểu diễn chuỗi mẫu],
    [Khung I/Q phức dài 256 mẫu],
    [Hệ LTI],
    [Phương trình sai phân, tích chập],
    [Tạo dạng RRC và kênh đa đường],
    [DFT/FFT],
    [Phổ biên độ, pha, định lý tích chập],
    [PSD, entropy phổ, centroid và spread],
    [FIR],
    [Thiết kế bằng cửa sổ và đáp ứng tần số],
    [Bộ lọc RRC hữu hạn],
    [Đánh giá số],
    [Vẽ đồ thị và kiểm nghiệm bằng Python],
    [SNR curve, confusion matrix, latency],
  ),
  [Ánh xạ nội dung đồ án với học phần Thực hành Xử lý tín hiệu số],
) <tab-course-map>

Notebook của lớp dùng NumPy, SciPy và Matplotlib để triển khai các phép tính trên @labs2026. Đồ án giữ cùng hệ sinh thái, bổ sung scikit-learn và PyTorch cho phần ML/DL.

== Phạm vi và giả thiết

Dữ liệu gồm #facts.total-frames khung cân bằng, 11 mức SNR cách nhau 3 dB. Công suất mỗi khung được chuẩn hóa trước khi đưa vào bộ phân loại; SNR không phải là đặc trưng đầu vào.

Kênh có một tia chính và một echo yếu, CFO tối đa 0,002 chu kỳ/mẫu, pha ban đầu ngẫu nhiên và AWGN. Không mô phỏng Doppler nhanh, nhiễu xung, nhiễu đồng kênh, lệch tốc độ lấy mẫu hoặc bộ khuếch đại phi tuyến.

== Đóng góp thực hiện

Đóng góp của đồ án nằm ở việc tích hợp và kiểm chứng, không tuyên bố thuật toán AMC mới:

- notebook tự chứa, sinh dữ liệu cục bộ và chạy lại bằng hạt giống 22207056;
- so sánh công bằng hai họ mô hình trên cùng split và cùng tập test;
- fusion được chọn trên validation, tránh tối ưu theo test;
- 13 hình kết quả được tạo trực tiếp từ lần chạy đã lưu;
- báo cáo nêu rõ giới hạn giữa mô phỏng và triển khai SDR thực.

== Cấu trúc báo cáo

Chương 2 trình bày mô hình tín hiệu và cơ sở DSP/ML. Chương 3 mô tả thiết kế thí nghiệm. Chương 4 nêu triển khai notebook. Chương 5 phân tích kết quả. Chương 6 kết luận, giới hạn và hướng phát triển.


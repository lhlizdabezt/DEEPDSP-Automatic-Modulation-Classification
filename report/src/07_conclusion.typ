#import "../config.typ": *
#import "../facts.typ": facts

= KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

== Kết quả đạt được

Đồ án đã hoàn thiện chuỗi AMC từ mô hình tín hiệu đến demo. Bộ dữ liệu #facts.total-frames khung bao phủ sáu lớp và 11 mức SNR; mỗi khung đi qua RRC, đa đường nhẹ, CFO, lệch pha và AWGN.

Nhánh RF–DSP dùng 18 đặc trưng giải thích được. Nhánh CNN–DSP dùng tensor bốn kênh và mạng #facts.cnn-params tham số. Split theo lớp–SNR giữ cân bằng và không đưa SNR vào đầu vào.

Trên tập test, RF đạt macro-F1 #facts.rf-f1; CNN đạt #facts.cnn-f1; hybrid đạt #facts.hybrid-f1. Đường cong theo SNR cho thấy hybrid đạt 90% accuracy từ #facts.hybrid-snr90.

Notebook, hình, số liệu và bản mô tả cùng xuất phát từ một lần chạy. Đây là điểm quan trọng hơn việc chỉ trình bày sơ đồ mô hình mà không có đầu ra kiểm chứng.

== Hạn chế

Thứ nhất, dữ liệu được sinh mô phỏng. Mô hình chưa gặp nhiễu phần cứng, DC offset, IQ imbalance, clipping, fading nhanh hoặc nhiễu đồng kênh.

Thứ hai, thí nghiệm chỉ dùng một hạt giống huấn luyện. Accuracy và macro-F1 chưa có phân bố qua nhiều seed; khoảng Wilson chỉ phản ánh lấy mẫu test cho accuracy, không phản ánh biến thiên do training.

Thứ ba, split ngẫu nhiên trên dữ liệu mô phỏng chưa kiểm tra domain shift. Một mô hình tốt trên bộ sinh hiện tại có thể học dấu vết riêng của bộ sinh.

Thứ tư, độ trễ được đo theo batch trên CPU. Chưa có chứng cứ về thời gian thực trên SDR, vi điều khiển hay FPGA.

== Hướng phát triển

Hướng ưu tiên là thu dữ liệu I/Q thật bằng RTL-SDR hoặc USRP, tách train/test theo phiên thu và giữ một thiết bị hoặc ngày đo hoàn toàn ngoài huấn luyện.

Có thể bổ sung IQ imbalance, phase noise, lệch tốc độ lấy mẫu, kênh Rayleigh/Rician và nhiễu đồng kênh. Mỗi suy giảm nên có ablation để biết phần nào làm hiệu năng giảm.

Về mô hình, có thể thử complex-valued CNN, mạng residual 1-D, attention nhẹ hoặc knowledge distillation. Mọi cải tiến cần báo cả accuracy–SNR, số tham số và độ trễ.

Về triển khai, pipeline nên chuyển sang streaming: phát hiện tín hiệu, ước lượng tần số mang thô, tạo khung, chuẩn hóa, phân loại và làm trơn quyết định theo thời gian.

== Kết luận cuối

DEEPDSP-AMC đáp ứng mục tiêu một đồ án DSP có ML/DL nhưng vẫn giữ bản chất tín hiệu. Kết quả cho thấy việc kết hợp hiểu biết miền với học đặc trưng là hướng phù hợp cho máy thu thông minh ở quy mô thực hành.

Giá trị của đồ án nằm ở chuỗi tái lập, số liệu thật và giới hạn được nói rõ. Bước tiếp theo không phải tăng thêm lớp mạng trên cùng dữ liệu, mà là kiểm tra khả năng tổng quát trên tín hiệu vô tuyến đo được.


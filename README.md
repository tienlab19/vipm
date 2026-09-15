# PSPOPrep — SwiftUI

Ứng dụng iOS native theo 5 artboard trong `pspo-exam-prep-app.html`: Home, Practice Exam, Quiz, Result, Go Premium. Giữ bảng màu navy/blue, card bo góc, progress ring; dùng font hệ thống và SF Symbols, không nhúng trang HTML vào app.

## Chạy

Mở `vipm.xcodeproj`, chọn scheme `vipm`, chạy trên iOS Simulator. Project hiện yêu cầu iOS 26.2+, theo cấu hình Xcode ban đầu.

```bash
xcodebuild -project vipm.xcodeproj -scheme vipm -destination 'generic/platform=iOS Simulator' build
bash Tests/run.sh
```

## Dữ liệu

`vipm/questions.json` là bản sao nguyên nội dung file `Claude outputs/pspo1-firebase-schema.json` được cung cấp. File này **là schema**, không phải ngân hàng đề thật. App đọc hai câu minh họa trong `$examples`, hiển thị rõ chế độ demo, không giả số lượng 80/800 câu hoặc tiến độ học.

Có thể thay nội dung file bằng Firebase Realtime Database export thực, cấu trúc `config` và `modules/-Ng-ViDLQtXSAAAFYzJA/quiz_parts`. Không cần Firebase SDK. Bộ đọc hỗ trợ đáp án 1–8 (giữ nguyên chỉ số khi có trường trống), chọn nhiều, số dạng chuỗi, cờ boolean/0/1, tự luận, ảnh HTTPS, nhiều đoạn đề/lời giải. Trường HTML được chuyển thành nội dung native, giữ xuống dòng, danh sách, đậm/nghiêng cơ bản; không chạy script hoặc tải trang web. HTML/CSS phức tạp không được tái tạo đầy đủ.

Không gọi Firebase của ứng dụng nguồn, không tải câu hỏi thật từ endpoint trong schema. Ảnh HTTPS trong bộ đề thay thế cần kết nối mạng, có trạng thái lỗi khi tải thất bại. Cần bộ đề có quyền sử dụng trước khi phát hành.

## Luồng đã có

- Home, Exam, Saved, Profile; sửa tên, thống kê thật, xem các phần học.
- Học từng phần; chọn một/nhiều đáp án, giải thích, bookmark, bỏ qua/quay lại.
- Thi xáo trộn tối đa 80 câu trắc nghiệm đang mở; đồng hồ 60 phút theo deadline, tự nộp khi hết giờ cả sau khi chuyển nền/mở lại.
- Kết quả tính từ đáp án cuối; ngưỡng luyện tập 85%, phân biệt sai/bỏ qua; review, làm lại.
- Câu tự luận tự đối chiếu đáp án mẫu, không tính vào điểm trắc nghiệm.
- Lưu nhiều phiên chưa nộp theo chế độ, bookmark, câu sai/bỏ qua và thống kê bằng UserDefaults. Không đồng bộ cloud.
- Debug tạm thời tự mở Premium bằng `#if DEBUG` trong `App/AppComposition.swift`, truyền quyền truy cập vào use case. Release vẫn khóa; không giả mua/restore. Cần cấu hình sản phẩm App Store và xác thực entitlement StoreKit trước khi bật mua thật.

## Clean Architecture

```text
vipm/
  App/                         Khởi tạo app, ghép dependency, cấu hình Debug
  Domain/                      Entity, chấm điểm, phiên học, use case, repository protocol
  Data/                        Đọc JSON/Firebase DTO, lưu UserDefaults
  Presentation/
    ViewModels/                Observable state và xử lý thao tác UI
    Views/                     SwiftUI, điều hướng, vòng đời màn hình
    Components/                Theme và thành phần hiển thị dùng chung
```

- Domain chỉ dùng Foundation; không SwiftUI, Observation, Bundle, UserDefaults hoặc bộ giải mã Firebase. `StudyUseCase` làm việc qua `StudyProgressRepository`.
- Data triển khai repository protocol của Domain. `QuestionDTO` và `QuestionBankDTO` ánh xạ JSON thành entity; không còn `Bank` singleton.
- Presentation dùng `StudyViewModel` và `QuizViewModel`; View không đọc file, lưu UserDefaults hay trực tiếp thay đổi đáp án. `QuizSession` là value type, kết quả cũ không bị thay đổi khi làm lại.
- App là nơi duy nhất ghép repository cụ thể và cấu hình bypass Premium. Không thêm thư viện DI hoặc target Xcode.
- Giữ key `studyProgress.v1` và các trường snapshot Codable cũ. Tên từ key `learnerName` cũ được đọc dự phòng, lưu vào snapshot từ lần cập nhật tiếp theo; không xóa dữ liệu gốc.

## Mô phỏng kỳ thi PSPO I

Tab Exam dựng đúng format bài thi thật: 80 câu, 60 phút, mốc đậu 85%. Mỗi lượt rút một đề mới, chia theo tỉ lệ số câu của từng part trong bank (`StudyUseCase.examForm`), không trùng câu. Bank nhỏ hơn 80 câu thì dùng toàn bộ và màn hình nói rõ số câu thật.

Trong lúc thi: không lộ đáp án, đồng hồ đếm ngược (dưới 5 phút chuyển đỏ), cờ đánh dấu câu cần xem lại, bản đồ câu hỏi để nhảy tự do và nộp bài. Hết giờ tự nộp. Thoát giữa chừng vẫn lưu draft, đồng hồ tiếp tục chạy theo `deadline`. Câu bỏ trống tính sai; màn hình kết quả hiện số câu đúng so với mốc đậu và phân tích theo part.

Không mô phỏng: câu hỏi thật của Scrum.org, ngân hàng 80 câu chuẩn nếu file JSON không có, tỉ trọng chính thức của từng focus area, hay điểm dự đoán đậu/rớt thật.

## Kiểm tra

`Tests/run.sh` biên dịch Domain độc lập, chạy assert cả có/không có `DEBUG`, không cần Simulator hoặc test framework. Repository in-memory kiểm tra use case và ViewModel không phụ thuộc UserDefaults. Bao phủ schema/export, input lỗi, đáp án đến số 8, ảnh, nhiều đáp án, tự luận, chấm điểm, timeout, lưu/khôi phục phiên cũ, bookmark, làm lại, lỗi lưu trữ, chuyển tên cũ; xác nhận Debug mở Premium, bản không có `DEBUG` vẫn khóa bất kể UserDefaults.

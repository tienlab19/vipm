# PSPOPrep — SwiftUI

Ứng dụng iOS native theo 5 artboard trong `pspo-exam-prep-app.html`: Home, Practice Exam, Quiz, Result, Go Premium. Giữ bảng màu navy/blue, card bo góc, progress ring; dùng font hệ thống và SF Symbols, không nhúng trang HTML vào app.

## Chạy

Mở `vipm.xcodeproj`, chọn scheme `vipm`, chạy trên iOS Simulator. Project yêu cầu iOS 17.0+ và được build bằng Xcode 26.3 / iOS 26.2 SDK.

```bash
xcodebuild -project vipm.xcodeproj -scheme vipm -destination 'generic/platform=iOS Simulator' build
bash Tests/run.sh
```

Danh sách test case tự động, smoke test và checklist phát hành: `Tests/TEST_CASES.md`.

## Dữ liệu

`vipm/questions.json` là bản sao nguyên nội dung file `Claude outputs/pspo1-firebase-schema.json` được cung cấp. File này **là schema**, không phải ngân hàng đề thật. App đọc hai câu minh họa trong `$examples`, hiển thị rõ chế độ demo, không giả số lượng 80/800 câu hoặc tiến độ học.

Có thể thay nội dung file bằng Firebase Realtime Database export thực, cấu trúc `config` và `modules/-Ng-ViDLQtXSAAAFYzJA/quiz_parts`. Firebase SDK chỉ dùng cho Analytics, không đọc câu hỏi từ Firebase. Bộ đọc hỗ trợ đáp án 1–8 (giữ nguyên chỉ số khi có trường trống), chọn nhiều, số dạng chuỗi, cờ boolean/0/1, tự luận, ảnh HTTPS, nhiều đoạn đề/lời giải. Trường HTML được chuyển thành nội dung native, giữ xuống dòng, danh sách, đậm/nghiêng cơ bản; không chạy script hoặc tải trang web. HTML/CSS phức tạp không được tái tạo đầy đủ.

Không gọi Firebase của ứng dụng nguồn, không tải câu hỏi thật từ endpoint trong schema. Ảnh HTTPS trong bộ đề thay thế cần kết nối mạng, có trạng thái lỗi khi tải thất bại. Cần bộ đề có quyền sử dụng trước khi phát hành.

## Luồng đã có

- Home, Exam, Saved, Profile; sửa tên, thống kê thật, xem các phần học.
- Học từng phần; chọn một/nhiều đáp án, giải thích, bookmark, bỏ qua/quay lại.
- Thi xáo trộn tối đa 80 câu trắc nghiệm đang mở; đồng hồ 60 phút theo deadline, tự nộp khi hết giờ cả sau khi chuyển nền/mở lại.
- Kết quả tính từ đáp án cuối; ngưỡng luyện tập 85%, phân biệt sai/bỏ qua; review, làm lại.
- Câu tự luận tự đối chiếu đáp án mẫu, không tính vào điểm trắc nghiệm.
- Lưu nhiều phiên chưa nộp theo chế độ, bookmark, câu sai/bỏ qua và thống kê bằng UserDefaults. Không đồng bộ cloud.
- Người dùng miễn phí mở 30 câu; Premium mở toàn bộ 800 câu, các chế độ nâng cao và loại bỏ quảng cáo.
- Paywall hỗ trợ mua trọn đời, khôi phục và đổi mã bằng StoreKit 2.

## In-App Purchase

- `AppFeatures.inAppPurchasesEnabled = true`; capability In-App Purchase và `vipm/Premium.storekit` đã gắn vào Run scheme.
- Sản phẩm non-consumable: `com.viuniverse.pspo.one.premium`.
- Quyền miễn phí giới hạn 30 câu; toàn bộ ngân hàng, chế độ Premium và trải nghiệm không quảng cáo chỉ mở với entitlement đã xác minh.
- App kiểm tra entitlement trước khi khởi tạo AdMob để người đã mua không thấy banner hoặc consent quảng cáo khi mở app.
- StoreKit 2 xác minh JWS trên thiết bị. Nếu cần cấp quyền đa nền tảng, quản trị refund tập trung hoặc chống chia sẻ tài khoản, bổ sung App Store Server API phía backend.

## Analytics

Firebase Analytics qua SPM (`firebase-ios-sdk`, sản phẩm `FirebaseAnalytics`), cấu hình bằng `vipm/GoogleService-Info.plist` (project `vipm-pspo1`). Mọi event đi qua `Track` trong `vipm/App/Tracking.swift`; View gọi `Track.log`/`Track.screen`, Domain và Data không biết gì về Analytics.

SwiftUI dùng screen tracking thủ công với `screen_class = SwiftUIScreen`; automatic screen reporting bị tắt để tránh class name mangled không hợp lệ từ hosting controller.

| Event | Tham số | Nơi bắn |
| --- | --- | --- |
| `app_open` | – | `vipmApp.init` |
| `screen_view` | `screen_name` | đổi tab, push route, mở paywall |
| `tour_start` / `tour_step` / `tour_skip` / `tour_finish` | `source`, `step` | `ProductTourView`, profile |
| `continue_card_tap` | `has_draft` | dashboard |
| `exam_start_tap` | `resume`, `question_count`, `is_demo` | `PracticeExamView` |
| `flash_pack_select` | `count` | `FlashChallengeView` |
| `quiz_start` / `quiz_unavailable` | `quiz_key`, `question_count` | `QuizHost` |
| `answer_select` / `answer_check` | `is_multi`, `correct` | `QuizView` |
| `question_skip` / `question_flag_toggle` | `index`, `flagged` | `QuizView` |
| `bookmark_toggle` | `saved`, `source` | quiz, tab Saved |
| `exam_navigator_open` / `exam_navigator_jump` / `exam_submit_tap` | `index`, `answered`, `flagged` | `ExamNavigator` |
| `quiz_submit` / `quiz_timeout` / `quiz_exit` | `is_exam`, `score`, `correct`, `graded`, `unanswered`, `elapsed_sec` | `QuizView` |
| `quiz_retake` | `quiz_key` | `QuizHost` |
| `result_view` | `passed`, `is_exam`, `score`, `correct`, `graded` | `ResultView` |
| `result_review_open` / `result_retake_tap` / `result_back_home` | – | `ResultView` |
| `saved_practice_tap` | `count` | tab Saved |
| `paywall_open` | `source` | profile, part khóa |
| `language_change` | `language` | profile |
| `learner_name_update` | – | profile |
| `bank_load_error` | – | `HomeView` |
| `ad_banner_loaded` / `ad_banner_load_error` | – | banner Home |
| `ad_consent_error` / `ad_privacy_options_error` | – | UMP consent |

Không gửi tên người học, nội dung câu hỏi hay câu trả lời — chỉ số đếm, điểm và khóa màn hình.

## AdMob

- Tích hợp Google Mobile Ads và UMP; Debug chỉ dùng test ID của Google.
- Banner adaptive chỉ hiện cho người dùng miễn phí tại root Home; Premium không khởi tạo hoặc hiển thị quảng cáo.
- Release không request quảng cáo nếu `Info.plist` vẫn chứa test ID. Checklist thay ID và rollout: `docs/ADMOB_PLAN.md`.

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

Tab Exam dựng format 80 câu, 60 phút, mốc đậu 85%. Khi bắt đầu đề mới, ứng dụng xáo trộn toàn bộ câu trắc nghiệm đang mở rồi lấy tối đa 80 câu đầu (`StudyUseCase.examForm`), không phân bổ theo từng part và không lặp cùng bản ghi. Bank nhỏ hơn 80 câu thì dùng toàn bộ và màn hình nói rõ số câu thật. Nút Retake giữ nguyên bộ câu và thứ tự của lượt vừa làm, chỉ xóa đáp án và khởi động lại đồng hồ 60 phút.

Trong lúc thi: không lộ đáp án, đồng hồ đếm ngược (dưới 5 phút chuyển đỏ), cờ đánh dấu câu cần xem lại, bản đồ câu hỏi để nhảy tự do và nộp bài. Hết giờ tự nộp. Thoát giữa chừng vẫn lưu draft, đồng hồ tiếp tục chạy theo `deadline`. Câu bỏ trống tính sai; màn hình kết quả hiện số câu đúng so với mốc đậu và phân tích theo part.

Không mô phỏng: câu hỏi thật của Scrum.org, ngân hàng 80 câu chuẩn nếu file JSON không có, tỉ trọng chính thức của từng focus area, hay điểm dự đoán đậu/rớt thật.

## Kiểm tra

`Tests/run.sh` biên dịch Domain độc lập, chạy assert cả có/không có `DEBUG`, không cần Simulator hoặc test framework. Repository in-memory kiểm tra use case và ViewModel không phụ thuộc UserDefaults. Bao phủ schema/export, input lỗi, đáp án đến số 8, ảnh, nhiều đáp án, tự luận, chấm điểm, timeout, lưu/khôi phục phiên cũ, bookmark, làm lại, lỗi lưu trữ, chuyển tên cũ; kiểm tra Premium được bật và entitlement Premium luôn tắt quảng cáo.

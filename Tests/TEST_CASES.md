# Kế hoạch kiểm thử PSPOPrep

Ngày thực hiện: 2026-09-21

## Tự động

Chạy `bash Tests/run.sh`. Bộ test biên dịch Domain độc lập, sau đó chạy hai cấu hình Release-like và `DEBUG`.

| ID | Nhóm | Test case | Kết quả mong đợi |
| --- | --- | --- | --- |
| DATA-01 | Dữ liệu | Đọc schema demo và ngân hàng 800 câu | Decode thành công, giữ đúng số phần/câu |
| DATA-02 | Dữ liệu | Đáp án thưa 1–8, ảnh HTTPS, multi-choice, essay | Giữ đúng ID, loại URL không an toàn |
| DATA-03 | Dữ liệu | Số/cờ sai, đáp án thiếu/trùng | Từ chối dữ liệu lỗi |
| QUIZ-01 | Quiz | Chọn/bỏ chọn single, giới hạn multi, ID không tồn tại | State đáp án luôn hợp lệ |
| QUIZ-02 | Quiz | Chấm đáp án, khóa câu đã chấm | Không sửa đáp án sau khi chấm |
| QUIZ-03 | Quiz | Essay rỗng, có nội dung, đã chấm | Chỉ nội dung thật được tính đã trả lời; đã chấm thì khóa |
| QUIZ-04 | Quiz | Di chuyển, jump, flag, session đã kết thúc | Chặn index sai; session kết thúc bất biến |
| QUIZ-05 | Quiz | Điểm, sai, bỏ qua, progress, breakdown | Tính đúng trên câu trắc nghiệm |
| TIME-01 | Đồng hồ | Còn thời gian, quá hạn, làm tròn giây | Không âm; hết giờ tự nộp đúng deadline |
| MODE-01 | Chế độ | Part, Exam, Flash, Time Trial, Saved, Incorrect, Missed | Tạo đúng bộ câu, tiêu đề, thời lượng |
| MODE-02 | Thi | Form tối đa 80 câu không trùng, retake giữ form | Đúng số lượng và thứ tự theo yêu cầu |
| PREMIUM-01 | Premium | Free tối đa 30 câu; Premium đủ 800 câu | Không rò câu khóa |
| PREMIUM-02 | Premium | Thu hồi entitlement khi có draft/retake/route cũ | Chế độ Premium bị khóa lại |
| RELEASE-01 | Bản đầu | Khởi tạo app với IAP tắt, cờ Premium cũ true/false | Đầy đủ ngân hàng, Exam, Flash, Time Trial, Bookmarks; không phụ thuộc giao dịch |
| PROGRESS-01 | Tiến độ | Bookmark, answered, wrong, missed, readiness | Lọc theo entitlement và cập nhật đúng |
| DRAFT-01 | Draft | Lưu, resume, latest, retake | Khôi phục đúng vị trí/state; tạo ID mới khi retake |
| DRAFT-02 | Draft | Draft rỗng, trùng ID, index sai, route cũ | Bỏ qua draft không hợp lệ |
| STORE-01 | Lưu trữ | UserDefaults round-trip và dữ liệu legacy | Không mất dữ liệu; draft cũ vẫn đọc được |
| STORE-02 | Lưu trữ | Dữ liệu hỏng, lỗi đọc, lỗi ghi | Báo lỗi; không ghi đè dữ liệu gốc |
| PROFILE-01 | Hồ sơ | Trim tên, tên rỗng, giới hạn 60 ký tự | Lưu giá trị chuẩn hóa |
| PROFILE-02 | Hồ sơ | Lưu ngày thi | Chuẩn hóa đầu ngày và gọi scheduler |
| VM-01 | ViewModel | Tương tác quiz không cần lifecycle SwiftUI | Mọi thay đổi được lưu ngay |
| ARCH-01 | Kiến trúc | Domain/Presentation không import adapter sai tầng | Script dừng nếu vi phạm dependency |

## Build và smoke test

| ID | Test case | Cách chạy | Kết quả mong đợi |
| --- | --- | --- | --- |
| BUILD-01 | Build toàn app | `xcodebuild -project vipm.xcodeproj -scheme vipm -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` | `BUILD SUCCEEDED` |
| SMOKE-01 | Khởi động app | Chạy scheme `vipm` trên Simulator | Home hiển thị, không crash, đọc được ngân hàng câu hỏi |
| SMOKE-02 | Điều hướng chính | Mở Home, Practice, Exam, Saved, Profile | Tab/Back hoạt động, không mất state |

## Manual bắt buộc trước phát hành

| ID | Test case | Kết quả mong đợi |
| --- | --- | --- |
| IAP-01 | Bản đầu: Home, Practice, Saved, Profile, nút Save trong quiz | Không paywall, PRO lock, mua, restore hoặc đổi mã; đủ 800 câu |
| IAP-02 | Bản đầu: khởi động offline, mở lại app, draft và retake | Mọi tính năng vẫn mở, không cần giao dịch StoreKit |
| NOTIFY-01 | Cho phép/từ chối notification | Không crash; chỉ tạo reminder tương lai |
| UI-01 | Dynamic Type, VoiceOver, light mode, EN/VI | Nội dung đọc được, nút có nhãn, không cắt chữ nghiêm trọng |
| UI-02 | Background/foreground khi đang thi | Đồng hồ dựa trên deadline, tự nộp khi quá hạn |
| NET-01 | Ảnh câu hỏi mất mạng/URL lỗi | Có trạng thái lỗi; quiz vẫn dùng được |

Kiểm thử mua/pending/cancel/restore/revoke chỉ áp dụng khi bật lại IAP ở bản sau; các test Domain về giới hạn quyền vẫn chạy để tránh regression.

`ponytail:` UI, StoreKit và notification cần Simulator/device; nâng cấp thành XCUITest/StoreKitTest khi pipeline CI có runtime iOS ổn định.

## Kết quả thực thi 2026-09-23 — build 5 không IAP

- `bash Tests/run.sh`: PASS cả có/không có `DEBUG`; đủ 800 câu, mọi part, đề 80 câu, Flash 10/20/30, Time Trial, draft/retake, Bookmarks; các hàm StoreKit bị tắt không tạo giá/giao dịch/thông báo.
- Release archive, export App Store và Release Simulator: PASS. IPA build `5`, iOS `17.0+`, team `7GH7MJS7R2`; chữ ký kiểm tra bằng `codesign --verify --deep --strict`.
- Không có `Premium.storekit` trong IPA. Cảnh báo build duy nhất: bỏ qua AppIntents metadata do app không dùng framework này.
- Smoke test trên Simulator iPhone: cài mới, onboarding, từ chối thông báo, Home có đề 80 câu, mở Practice Test 2 không paywall, lưu câu, chấm đáp án, lưu draft, tab Saved; Profile EN/VI không có mua/khôi phục/đổi mã.
- Chưa upload/submit App Store; chưa thực hiện toàn bộ manual checklist accessibility, offline và thiết bị thật.

## Kết quả thực thi 2026-09-21

| Hạng mục | Kết quả | Ghi chú |
| --- | --- | --- |
| `bash Tests/run.sh` | PASS | Đậu cả cấu hình thường và `DEBUG` |
| `BUILD-01` | PASS | Build iOS Simulator thành công bằng cache Swift Package hiện có |
| `SMOKE-01` | PASS | App mở trên iOS 26.3, Home render đúng, process không crash |
| `SMOKE-02` | PASS | Mở được Practice, quiz 30 câu, lưu/rời draft, Exam, paywall Saved và Profile |
| Firebase Analytics | PASS có cảnh báo | Simulator báo không có compatible conversion service; không ảnh hưởng chức năng app |
| `IAP-01`–`IAP-02`, `NOTIFY-01`, `UI-01`–`UI-02`, `NET-01` | CHƯA CHẠY | Cần thao tác StoreKit/device, quyền hệ thống, accessibility và điều kiện mạng chuyên biệt |

# Hồ sơ App Store — PSPOPrep

Ngày cập nhật: 2026-09-25

## Thông tin app

| Trường | Giá trị |
| --- | --- |
| App name | PSPOPrep |
| Bundle ID | `com.viuniverse.pspo-one` |
| SKU đề xuất | `pspo-prep-ios-2026` |
| Version | `1.0.1` |
| Build | `1` |
| Primary category | Education |
| Secondary category | Reference |
| Copyright | `© 2026 ViUniverse` |
| Support URL | `https://viuniverse.com/support` |
| Marketing URL | `https://viuniverse.com` |
| Privacy Policy URL | `https://viuniverse.com/privacy` |
| Price | Free, có Premium Lifetime Access dạng non-consumable |

## Tệp trong hồ sơ

- `metadata/en-US.md`: metadata tiếng Anh.
- `metadata/vi.md`: metadata tiếng Việt.
- `app-review.md`: nội dung App Review Information.
- `privacy.md`: câu trả lời App Privacy và privacy manifest.
- `age-rating.md`: câu trả lời bảng phân loại độ tuổi.
- `iap.md`: cấu hình Premium Lifetime Access cho bản phát hành kế tiếp.
- `release-checklist.md`: checklist trước upload/submission.
- `assets/`: app icon, ảnh paywall và promotional image dùng cho IAP review.

## Trạng thái

- Build dùng Xcode 26.3 / iOS 26.2 SDK.
- `AppFeatures.inAppPurchasesEnabled = true`: miễn phí 30 câu; Premium mở đủ 800 câu, các chế độ nâng cao và loại bỏ quảng cáo.
- Deployment target đã hạ từ iOS 26.2 xuống iOS 17.0.
- App icon 1024×1024, RGB, không alpha.
- Privacy manifest của app đã khai báo lý do dùng `UserDefaults`.
- Privacy manifest khai báo dữ liệu Firebase Analytics theo đúng câu trả lời App Privacy đề xuất.
- `ITSAppUsesNonExemptEncryption = NO` đã được đặt cho HTTPS/StoreKit tiêu chuẩn.
- Support và Privacy URL phản hồi HTTP 200.
- Archive build 5 không IAP được giữ tại `build/20260923-build5-no-iap/vipm.xcarchive` như tài liệu lịch sử.
- Build `1.0.1 (1)` bật Premium IAP; StoreKit local chỉ áp dụng cho Run Debug và bị loại khỏi app/Archive Release.
- Archive và IPA App Store nằm tại `build/20260925-1.0.1-build1-111817/`; IPA đã ký Apple Distribution, `get-task-allow = false`.

## Chặn phát hành

1. Xác nhận bằng văn bản quyền sử dụng/phân phối ngân hàng 800 câu và lời giải.
2. Xác nhận quyền dùng tên `PSPO`, `Professional Scrum Product Owner` và nội dung liên quan; app phải thể hiện rõ không liên kết với Scrum.org.
3. Đặt giá app Free; hoàn tất và gắn sản phẩm `com.viuniverse.pspo.one.premium` vào cùng submission của bản Premium.
4. Cung cấp tên, email, số điện thoại quốc tế của người liên hệ App Review.
5. Upload IPA của version `1.0.1`, build `1`, chờ xử lý rồi chọn đúng build trong App Store Connect; chưa tự động upload hoặc submit.
6. Tạo screenshot marketing cho iPhone 6.9-inch và iPad 13-inch; screenshot IAP hiện có chỉ dùng cho IAP review.
7. Cập nhật trang Support/Privacy để nêu rõ PSPOPrep; form Support hiện chưa có PSPOPrep trong danh sách ứng dụng.

Tên `PSPOPrep` và icon dùng `PSPO I` có rủi ro nhãn hiệu. Nếu không có chấp thuận phù hợp, phương án ít rủi ro hơn là tên `Product Owner Exam Prep`, subtitle `Practice for PSPO I`, icon không dùng `PSPO` làm yếu tố nổi bật.

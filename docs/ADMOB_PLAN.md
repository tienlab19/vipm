# Kế hoạch AdMob

Cập nhật: 25/09/2026.

## Cấu hình hiện tại

- Google Mobile Ads SDK `13.10.0` qua Swift Package Manager; UMP được kéo theo để xử lý consent.
- Debug không khởi tạo hoặc hiển thị quảng cáo.
- Release chỉ khởi tạo từng định dạng khi App ID và ad unit ID tương ứng đều là ID thật. Định dạng còn dùng test ID hoặc thiếu ID sẽ tự tắt.
- Trước khi phát hành, thay `GADApplicationIdentifier`, `AdMobBannerUnitID` và `AdMobInterstitialUnitID` trong `Info.plist` bằng ID thật từ AdMob.
- Chỉ yêu cầu quảng cáo sau khi UMP xác nhận có thể request; cấu hình non-personalized để chưa cần thêm prompt ATT.
- Nếu UMP yêu cầu, Profile hiển thị `Privacy choices` để người dùng mở lại form quyền riêng tư.

## Vị trí hiện tại

| Màn hình | Định dạng | Quy tắc |
| --- | --- | --- |
| Các tab chính | 1 anchored adaptive banner trên thanh tab | Chỉ người dùng miễn phí tại root tab; Premium không request hoặc hiển thị quảng cáo |
| Quiz / Exam | Không quảng cáo | Không làm gián đoạn tập trung hoặc đồng hồ |
| Kết quả Practice Exam | 1 interstitial đã preload | Hiển thị một lần khi vào kết quả; không chặn màn hình nếu quảng cáo chưa sẵn sàng |
| Kết quả practice thường / Review | Không quảng cáo | Giữ kết quả và nút hành động rõ ràng |
| Onboarding / Profile / Paywall | Không quảng cáo | Tránh cạnh tranh với consent, cài đặt và mua hàng |

## Rollout

1. Tạo app iOS, banner unit và interstitial unit trong AdMob; thay ba test ID.
2. Cấu hình Privacy & messaging cho EEA/UK/Switzerland và US state regulations.
3. Cập nhật App Privacy trong App Store Connect theo dữ liệu Google Mobile Ads thực tế sử dụng.
4. Test consent bằng UMP debug geography/device; test quảng cáo chỉ bằng test ID hoặc test device.
5. Phát hành 10% người dùng trong 3–7 ngày; theo dõi crash-free, thời gian phiên, tỷ lệ hoàn thành quiz và phản hồi.
6. Mở 100% nếu tỷ lệ hoàn thành quiz giảm dưới 3% tương đối và không tăng phản hồi tiêu cực rõ rệt.

## Chưa làm

- Rewarded: chỉ thêm nếu có phần thưởng tự nguyện rõ ràng; không khóa nội dung học cốt lõi sau quảng cáo.
- App open ads: không dùng vì dễ làm chậm lần mở app và gây khó chịu.

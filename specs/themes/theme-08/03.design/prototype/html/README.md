# Prototype Theme 8 (TH-08): Hóa đơn điện tử (10-8)

Prototype viết bằng HTML/CSS/JS thuần (ES module, không cần build). Nó vẽ **đúng Flutter hiện tại** của các màn TH-08, ở cả iPhone 390 và Web 1280, để người dùng rà bằng impeccable (bước 3 của 10-8). Chữ, thứ tự và số đo DS chép y nguyên; **không thiết kế lại**. Mỗi sheet, hộp thoại, toast là một ca riêng.

Các route `/more/einvoice/*` là GoRoute cấp gốc, **nằm ngoài `StoreShell`**. Vì vậy cả hai khổ đều không có thanh bên hay thanh dưới. Trên web, màn chỉ có một cột 720 giữa nền xám (giống Theme 4).

Làm 2 đợt, mỗi đợt một commit. Cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Thiết lập HĐĐT | HD-01 Tổng quan, HD-02 Kết nối MISA, HD-03 Xác nhận ngắt kết nối, HD-04 Cấu hình phát hành, HD-05 Tự động hóa | ✅ 55 ca × 2 khổ |
| 2 · Phát hành & gửi trên đơn | HD-06 dòng "Hóa đơn điện tử" trong Kết quả bán hàng / Chi tiết đơn (vẽ cả màn Sales chủ như Flutter), HD-07…HD-13 | ⬜ |

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/themes/theme-08/03.design/prototype/html
python3 tools/serve.py &    # cổng 8778, tắt cache
# trang xem: http://127.0.0.1:8778/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=overview&state=not-ready&device=web
node --test                 # hàm thuần đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # mọi ca × 2 khổ → tools/proto-final/{iphone,web}/<màn>__<ca>.png (không vào git)
```

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/cases.js` | Nhóm (đợt), màn, ca, kèm điều cần nhìn của từng ca |
| `app/ds.js` | Widget DS, **chép từ Theme 4** (`theme-04/app/ds.js`, đổi `t4-` → `t8-`). Thêm: `passwordInput` (VPasswordField), `fieldDesc` (VFieldDescription), `fieldWithDesc`, `selectField` (VSelect có nhãn / mô tả / lỗi, tắt thì mờ cả khối), `loadingDot` (VLoading cỡ nhỏ có màu). Icon `key` / `fileCheck` / `circleX` / `refresh` để cục bộ (`LOCAL_ICONS`), không sửa `shared/icons.js` |
| `app/common.js` | Widget chung của feature einvoice: `SettingsInfoRow`, `ConfigurationEditorBottomBar`, trạng thái lỗi tải / không quyền, khung trang `VPageScaffold`, toast; hàm thuần `EInvoiceDateTimeCopy` |
| `app/data.js` | MST, 3 mẫu hóa đơn (mã MISA dạng GUID), tài khoản che, mốc thời gian |
| `app/setup.js` | Đợt 1: HD-01…05; hàm thuần `connectionSubtitle`, `issuanceSubtitle`, `automationSubtitle`, `completeTarget`, `statusValue`, `maskAccount`, `showsForm`, `infoKind`, `templateOptionLabel` |
| `app/main.js` | Ca → trạng thái; mọi màn vẽ ngoài khung (`insideShell('/more/einvoice…') = false`) |
| `styles/t8.css` | Phần DS chép từ `t4.css` (bỏ rule riêng PR-xx), rồi tới rule riêng Theme 8 (tiền tố `t8-`, token `--c45-v2-*`) |
| `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Trang xem và chụp ảnh, chép khuôn Theme 4 (cổng 8778) |

Có 5 bản `ds.js` (Theme 1, 3, 2, 4, 8). Việc gom về `shared/` để sau.

## Nguồn Flutter

| Màn | Flutter (`apps/erp/lib/features/einvoice/`) |
|---|---|
| HD-01 | `presentation/pages/einvoice_configuration_overview_page.dart`, `presentation/widgets/{einvoice_configuration_overview_view, readiness_summary, settings_navigation_item}.dart`, `presentation/support/einvoice_configuration_overview_copy.dart`, `logic/einvoice_configuration_overview_{cubit,state}.dart` |
| HD-02 | `presentation/pages/provider_connection_page.dart`, `presentation/widgets/provider_connection_view.dart`, `logic/provider_connection_{copy,cubit,state}.dart` |
| HD-03 | `presentation/widgets/disconnect_provider_sheet.dart` (`showVAdaptiveSheet`) |
| HD-04 | `presentation/pages/default_issuance_configuration_page.dart`, `presentation/widgets/default_issuance_configuration_view.dart`, `logic/default_issuance_configuration_{copy,cubit,state}.dart` |
| HD-05 | `presentation/pages/automation_policy_page.dart`, `presentation/widgets/{automation_policy_view, switch_setting_row}.dart`, `presentation/support/automation_policy_copy.dart`, `logic/automation_policy_{cubit,state}.dart` |
| Chung | `presentation/widgets/{settings_info_row, configuration_editor_bottom_bar, configuration_load_error_state, configuration_permission_denied_state, configuration_query_failure_view}.dart`, `presentation/support/{einvoice_datetime_copy, configuration_state_copy}.dart` |
| Khung | `core/router/app_router.dart` (GoRoute `/more/einvoice…` cấp gốc; quyền `einvoice.manage_configuration` chỉ kiểm ở `/more/einvoice`), `c45_design_system` `VPageScaffold`, `VSelect`, `VPasswordField`, `showVAdaptiveSheet` |

## Hiện trạng Flutter (để rà): đợt 1

**Chung**

1. Thanh "Hủy / Lưu" (và thanh "Ngắt kết nối") nằm **trong thân** (`Column[Expanded(ListView), bar]`), không phải `VPageScaffold.bottomBar`. Web: thanh chỉ rộng bằng cột 720, nền trắng lơ lửng giữa nền xám (PR-04 Theme 4 thì thanh hết bề ngang). Toast bật lên **đè lên thanh này** (SnackBar không né vì thanh thuộc thân).
2. Toast chỉ hiện `message`; mọi `title` ("Đã kết nối MISA", "Không lưu được"…) không vẽ.
3. Trạng thái lỗi tải / không quyền: icon có màu (đỏ / vàng) nhưng tiêu đề đen; nút link "Thử lại" / "Quay lại" sát ngay dưới mô tả (`VEmptyContent` không có khe).
4. Tiêu đề nhóm ("Thông tin kết nối", "Quy tắc tự động", "Thông tin mẫu") là chữ thường 14 w700; spec TH-08 vẽ IN HOA. Nhãn "Cần hoàn tất" cũng vậy.
5. Lưu xong (HD-04, HD-05) **ở lại màn** với toast, không tự quay về tổng quan; nút "Lưu" luôn bấm được dù chưa đổi gì.

**HD-01**

6. "Cấu hình phát hành" mờ khi chưa kết nối, nhưng "Tự động hóa" vẫn bấm được dù chưa sẵn sàng.
7. Cubit chỉ tải danh sách mẫu khi kết nối `connected` → kết nối "Cần kiểm tra lại" / "Cần kết nối lại" mà đã có mẫu thì phụ đề "Cấu hình phát hành" in **GUID thô** của MISA. Mẫu mặc định không còn trong danh sách cũng in GUID.
8. Phụ đề "Tự động hóa" khi chưa sẵn sàng luôn là "Phát hành hóa đơn và gửi email tự động." — đọc như đang bật tự động, kể cả khi chính sách đang tắt.
9. Phụ đề kết nối "Cần kiểm tra lại" / "Cần kết nối lại" cùng màu xám với mọi phụ đề, không có màu cảnh báo.
10. Khối "Sẵn sàng phát hành" không có hành động; "Còn N điều kiện" luôn là 1 (server trả một blocker, KI-03).

**HD-02, HD-03**

11. Nhãn "Mã số thuế đơn vị phát hành" (form) và "MST đơn vị phát hành" (thẻ đã kết nối) cùng một thông tin, hai cách viết.
12. "Kết nối lại" từ thẻ lỗi mở form trống: mất trạng thái lỗi, không thấy tài khoản cũ; "Hủy" thoát khỏi màn thay vì quay về thẻ lỗi.
13. Đang ngắt kết nối: nút chỉ mờ, không vòng xoay (form "Kết nối" thì có).
14. Đã kết nối chỉ có "Ngắt kết nối": không có lối kiểm tra lại hay đổi tài khoản. Đang chờ kết nối không có "Tải lại trạng thái" (copy có sẵn nhưng không dùng); trang tự hỏi lại mỗi 2 giây.
15. Vòng xoay "Chờ kết nối" 14 px đứng sau chữ, cùng màu xanh dương.
16. HD-03 là `showVAdaptiveSheet`: web 1280 thành hộp thoại 480 có nút × (sheet Theme 4 là sheet đáy 640). Nút nguy hiểm "Ngắt kết nối" đứng trên, nút giữ đứng dưới.
17. Route `/more/einvoice/connection` (và `/issuance`, `/automation`) không chặn quyền ở router; chỉ khi RPC trả không quyền mới hiện trạng thái khoá.

**HD-04**

18. Câu giới thiệu nói "mẫu hóa đơn **và hình thức ký số**" nhưng màn chỉ chọn mẫu.
19. Danh sách mẫu chỉ hiện ký hiệu (không có loại hóa đơn), dòng đang chọn không được đánh dấu.
20. Đang lưu: cả ô chọn (kèm nhãn và dòng "Đồng bộ gần nhất") mờ 0.4.

**HD-05**

21. Bật được "Tự động gửi email" khi "Tự động phát hành" đang tắt; không có ràng buộc hay giải thích.
22. Lưu bị từ chối ("Chưa đủ điều kiện") thì công tắc vẫn ở trạng thái bật trên màn. Toast "Hãy tải lại rồi lưu lại" nhưng màn không có nút tải lại.
23. Đang lưu: chỉ công tắc mờ, nhãn và mô tả giữ nguyên.

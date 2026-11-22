# Prototype Theme 8 (TH-08): Hóa đơn điện tử (10-8)

Prototype viết bằng HTML/CSS/JS thuần (ES module, không cần build). Nó vẽ **đúng Flutter hiện tại** của các màn TH-08, ở cả iPhone 390 và Web 1280, để người dùng rà bằng impeccable (bước 3 của 10-8). Chữ, thứ tự và số đo DS chép y nguyên; **không thiết kế lại**. Mỗi sheet, hộp thoại, toast là một ca riêng.

Các route `/more/einvoice/*` là GoRoute cấp gốc, **nằm ngoài `StoreShell`**. Vì vậy cả hai khổ đều không có thanh bên hay thanh dưới. Trên web, màn chỉ có một cột 720 giữa nền xám (giống Theme 4).

Làm 2 đợt, mỗi đợt một commit. Cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Thiết lập HĐĐT | HD-01 Tổng quan, HD-02 Kết nối MISA, HD-03 Xác nhận ngắt kết nối, HD-04 Cấu hình phát hành, HD-05 Tự động hóa | ✅ 55 ca × 2 khổ |
| 2 · Phát hành & gửi trên đơn | HD-06 dòng "Hóa đơn điện tử" trong SG-06 Kết quả bán hàng và SG-08 Chi tiết đơn (vẽ cả màn Sales chủ, cuộn tới khối "Chứng từ & hóa đơn"), HD-07 trước phát hành, HD-08 xác nhận, HD-09 sau phát hành, HD-10 tài liệu, HD-11 gửi, HD-12 gửi lại, HD-13 lịch sử gửi | ✅ 51 ca × 2 khổ |

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
| `app/ds.js` | Widget DS, **chép từ Theme 4** (`theme-04/app/ds.js`, đổi `t4-` → `t8-`). Thêm: `passwordInput` (VPasswordField), `fieldDesc` (VFieldDescription), `fieldWithDesc`, `selectField` (VSelect có nhãn / mô tả / lỗi, tắt thì mờ cả khối), `loadingDot` (VLoading cỡ nhỏ có màu). Icon `key` / `fileCheck` / `circleX` / `file` / `banknoteArrowDown` / `refresh` để cục bộ (`LOCAL_ICONS`), không sửa `shared/icons.js` |
| `app/common.js` | Widget chung của feature einvoice: `SettingsInfoRow`, `ConfigurationEditorBottomBar`, trạng thái lỗi tải / không quyền, khung trang `VPageScaffold`, toast; hàm thuần `EInvoiceDateTimeCopy` |
| `app/data.js` | MST, 3 mẫu hóa đơn (mã MISA dạng GUID), tài khoản che, mốc thời gian; đơn DH-000129 (4 dòng), 3 lần gửi |
| `app/order.js` | Đợt 2: hai màn Sales chủ + HD-06…13; hàm thuần `issuanceBadge`, `allowsTapForIssuance`, `deliveryBadge`, `safeFailureMessage`, `templateDisplay`, `confirmLine1/2`, `isValidEmail`, `suggestionSource`, `latestSummary`, `historyRows`, `productIcon`, `money` |
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
| HD-06 | `presentation/widgets/{order_einvoice_section, order_einvoice_row}.dart`, `presentation/support/{order_einvoice_copy, einvoice_status_interaction}.dart`, `logic/order_einvoice_{cubit,state}.dart` |
| HD-07 | `presentation/widgets/{pre_issue_einvoice_action_sheet, einvoice_action_item, issuance_failure_banner}.dart` |
| HD-08 | `presentation/widgets/issue_invoice_confirmation_sheet.dart` (+ `OrderEInvoiceCubit` dựng "Mẫu / Ký hiệu / cấp mã") |
| HD-09, HD-10 | `presentation/widgets/{post_issue_einvoice_action_sheet, invoice_documents_action_sheet}.dart`, `presentation/support/order_einvoice_post_issue_copy.dart` |
| HD-11, HD-12 | `presentation/widgets/{send_invoice_sheet, resend_invoice_sheet, invoice_delivery_recipient_form}.dart`, `presentation/support/order_invoice_delivery_copy.dart`, `logic/order_invoice_delivery_{cubit,state}.dart` |
| HD-13 | `presentation/pages/invoice_delivery_history_page.dart`, `presentation/widgets/invoice_delivery_history_view.dart`, `logic/invoice_delivery_history_{cubit,vm}.dart` |
| Màn Sales chủ | `apps/erp/lib/features/sales/presentation/`: SG-06 `pages/sales_transaction_result_page.dart`, `widgets/{sales_transaction_result_body, sales_result_header_card, sales_result_customer_card, sales_result_payment_summary_card, sales_result_documents_section, sales_receipt_entry_card, sales_entry_row, sales_transaction_result_action_bar}.dart`; SG-08 `pages/sales_order_detail_page.dart` (gắn `OrderEInvoiceSection`), `widgets/{sales_order_detail_body, sales_detail_header_card, sales_order_detail_payment_summary_card, sales_order_detail_products_section, sales_order_detail_documents_section, sales_order_detail_history_entry, sales_detail_action_bar}.dart`. Vẽ ở mức bố cục để thấy chỗ đặt HD-06; rà chi tiết hai màn này thuộc Theme 5 |
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

## Hiện trạng Flutter (để rà): đợt 2

**HD-06 (dòng trên đơn)**

24. Trong cùng khối "Chứng từ & hóa đơn", thẻ HĐĐT (`OrderEInvoiceRow`: icon cách 16, tiêu đề 14 w700) khác số đo với "Phiếu bán hàng" / "Lịch sử" (`SalesEntryRow`: icon cách 12, tiêu đề 14 w600, cao hơn).
25. Lúc chưa tải xong trạng thái thật, dòng hiện "Chưa phát hành" và không bấm được; "Đang xử lý" cũng không bấm được — cả hai vẫn trông như bấm được (không mờ, vẫn có ›).
26. Dòng chỉ cho biết trạng thái phát hành; trạng thái gửi email (Đã gửi / Gửi lỗi / Không xác định) chỉ thấy khi mở sheet.
27. Phát hành xong không có toast thành công (copy `issueSuccessMessage` có sẵn nhưng không dùng); chỉ badge đổi sang "Đang xử lý" rồi "Đã phát hành".
28. "Phát hành lỗi": phụ đề vẫn "Quản lý HĐĐT", không gợi ý mở để xem lỗi.

**HD-07, HD-08**

29. "Gửi hóa đơn" luôn hiện và luôn mờ trước khi phát hành.
30. Thẻ "Phát hành" mờ khi MISA chưa kết nối, thẻ "Kiểm tra & xem trước" mờ khi MISA không hỗ trợ xem trước — cả hai không có dòng giải thích hay lối mở thiết lập (copy `configBlocker…` có sẵn nhưng không dùng). Khách lẻ thiếu thông tin: banner vàng không có lối xử lý.
31. Sau lỗi, thẻ vẫn ghi "Phát hành hóa đơn điện tử" (không phải "Phát hành lại"); banner lỗi in nguyên văn thông điệp MISA.
32. Xác nhận: "Mẫu" in serial (C26TAA) chứ không phải số mẫu, đặt cạnh "Ký hiệu 1C26TAA" gần trùng; cấp mã viết tắt "Có mã CQT" (HD-01 / HD-04 viết "Có mã của cơ quan thuế"). Không nhắc người mua / email sẽ nhận.
33. HD-07 và HD-09 cùng tiêu đề "Hóa đơn điện tử"; không có số hóa đơn, ngày phát hành, mã tra cứu trong sheet sau phát hành.
34. Mọi sheet là `showVAdaptiveSheet` → web 1280 là hộp thoại 480 giữa màn (khác bottom sheet 640 của Theme 4).

**HD-09, HD-10**

35. Badge gửi "Không xác định kết quả" dài làm chữ thẻ hẹp lại; phụ đề bảo "kiểm tra trong lịch sử gửi" nhưng lịch sử chỉ mở được từ HD-12.
36. Đang chờ gửi tự động (`deliveryPending`): thẻ gửi mờ, không giải thích.
37. Đang lưu PDF: thẻ XML không mờ nhưng không bấm được (và ngược lại).

**HD-11, HD-12, HD-13**

38. Lỗi gửi hiện bằng SnackBar Material mặc định (không phải VToast) gắn vào Scaffold màn đơn → nằm dưới lớp phủ và dưới sheet (iPhone bị che hẳn).
39. Đang có lệnh gửi khác (`operationLocked`): ô khoá, nút mờ, không hiện câu giải thích (copy `operationLocked` có sẵn nhưng không dùng).
40. Dòng nguồn gợi ý ("Hồ sơ khách hàng") xám, đặt ngay dưới mô tả nên đọc như mô tả thứ hai.
41. Gửi lại: email điền sẵn theo lần gửi cuối (kể cả lần lỗi), còn dòng "Đã gửi gần nhất…" lấy lần thành công cuối → hai email khác nhau cạnh nhau. Nút chính vẫn là "Gửi hóa đơn".
42. Lịch sử gửi: mỗi hàng ghi trạng thái hai lần (đầu tiêu đề và badge); không có lý do lỗi. Trạng thái lỗi: tiêu đề và mô tả cùng một câu. Tiêu đề rỗng có dấu chấm.
43. Lịch sử là `MaterialPageRoute` đẩy từ sheet, không phải route GoRouter (không có URL riêng trên web).

**Phát hiện ngoài Flutter (prototype dùng chung)**

- `shared/icons.js` vẽ `error` là vòng tròn có chấm than, nhưng `VIcons.error` của DS là Lucide **circle-x** (⊗). Theme 8 dùng `circleX` cục bộ cho trạng thái lỗi tải, banner lỗi, toast lỗi; các theme khác (banner / toast lỗi) và `shared/` chưa sửa.

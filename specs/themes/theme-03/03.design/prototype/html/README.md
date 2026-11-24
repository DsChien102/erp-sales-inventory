# Prototype Theme 3 (TH-03) — Đối tác giao dịch (KH & NCC) (10-8)

HTML/CSS/JS thuần (ES module, không build). Vẽ **đúng Flutter hiện tại** của các màn TH-03, ở cả iPhone 390 và Web 1280. Web dùng bố cục 2 cột danh sách – hồ sơ của 4-W. Mục đích: người dùng rà bằng impeccable (bước 3 của 10-8). Chép y nguyên chữ, thứ tự, số đo DS; **không thiết kế lại**. Sheet / hộp thoại / toast là ca riêng.

Làm theo 3 đợt, mỗi đợt một commit (đủ 120 ca × 2 khổ, 77 điểm hiện trạng). Cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Danh sách & tạo | PT-01 Danh sách (L-01…L-07), PT-02 Bộ lọc / Sắp xếp, PT-03 Thêm mới, PT-05 Tạo / sửa (+ sheet rời màn), PT-04 Trùng hồ sơ, PT-06 Chọn khu vực | ✅ 48 ca × 2 khổ |
| 2 · Hồ sơ | PT-07 (KH / NCC, banner hoá đơn, ngừng hoạt động, đối tác hệ thống; khối **Công nợ** Theme 6, **Chương trình ưu đãi** + **Lịch sử nhập hàng** Theme 7 vẽ đầy đủ như Flutter), sheet thao tác / ngừng / kích hoạt / xoá / chặn xoá, toast, PT-12 | ✅ 36 ca × 2 khổ |
| 3 · Liên hệ & chuyển đổi | PT-08 (+ sheet thêm / thao tác / đổi chính / gỡ), PT-09, PT-10, PT-11 (2 bước, hộp thoại xác nhận, bị chặn); thêm 2 sheet mở từ PT-07 (chặn chuyển đổi, thêm người liên hệ) | ✅ 36 ca × 2 khổ |

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/themes/theme-03/03.design/prototype/html
python3 tools/serve.py &    # cổng 8771, tắt cache
# trang xem: http://127.0.0.1:8771/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=list&state=loaded&device=web
node --test                 # hàm thuần đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # mọi ca × 2 khổ → tools/proto-final/{iphone,web}/<màn>__<ca>.png (không vào git)
```

Màn trần không có tương tác: mỗi trạng thái là một ca.

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/cases.js` | Nhóm (đợt), màn, ca + điều cần nhìn của từng ca |
| `app/ds.js` | Widget DS, **chép từ Theme 1** (`theme-01/app/ds.js`, đổi `t1-` → `t3-`) rồi thêm: VChip, VBadge, VIconBox / VAvatar, VEmptyState, VSkeleton, VFloatingActionButton, VSearchBar, VSelect, VTextArea, VCheckbox, VChoiceList (radio), VAppBar có subtitle / leading, sheet có tiêu đề; cột VPageScaffold (`columnMax`) và gutter nút nổi (`fabGutter`) |
| `app/data.js` | Đối tác mẫu; 34 tỉnh + số xã thật (`assets/data/vn_administrative_units.json`); `dartCompare`, `foldVietnamese` |
| `app/list.js` | PT-01, PT-02, PT-03, không có quyền xem, cột phải khi chưa chọn; hàm thuần `roleLabel`, `itemSubtitle`, `filterCount`, `headerLabel`, `emptyKind` |
| `app/form.js` | PT-05, PT-04, PT-06, sheet rời màn; `sections`, `sectionTitle`, `formTitle`, `canSubmit`, `phoneError`, `invoiceWarning`, `sectionSummary`, `filterProvinces` |
| `app/detail.js` | PT-07 + sheet + toast, khối Theme 6 / 7; `missingDescription`, `invoiceBadge`, `contactLine`, `sheetActions` |
| `app/history.js` | PT-12; `titleLabel`, `summaryFor`, `changeText`, `actorDisplay` |
| `app/contacts.js` | PT-08, PT-09, PT-10 + sheet; `filterContacts`, `canSetPrimary` |
| `app/transform.js` | PT-11 + hộp thoại xác nhận + sheet chặn chuyển đổi; `stepOneErrors`, `transformTitle` |
| `app/main.js` | Ca → trạng thái; khu KH & NCC: web chia 2 cột (`VListDetailLayout` 360 / 840; hồ sơ ở cột phải 679 → thân 640), sheet web phủ cả cửa sổ, sheet iPhone chỉ phủ vùng tab; toast nằm trong cột hồ sơ (web) / trên thanh dưới (iPhone) |
| `styles/t3.css` | Rule tiền tố `t3-`, token `--c45-v2-*`; đầu file có bảng màu / chữ Flutter → token |
| `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Trang xem, chụp ảnh — chép khuôn Theme 1 (cổng 8771) |
| `shared/icons.js` | Thêm `plus` (VIcons.add), `tune`, `cloudOff`, `chevronUp` (expandLess), `searchOff`; đợt 2: `phone`, `pause`, `power`, `trash` (VIcons.delete), `stickyNote`, `plusCircle` (addCircle); đợt 3: `userPlus` (personAdd), `star`, `idCard` (contact), `cloud`, `arrowDown` |

Gom bộ widget DS về `shared/` (Theme 1 và Theme 3 đang có hai bản `ds.js`) để làm sau, khi đã có 2–3 theme và thấy rõ phần chung. Đến lúc đó sửa một widget DS phải sửa ở cả hai nơi.

## Nguồn Flutter

| Màn | Flutter (`apps/erp/lib/features/partner/`) |
|---|---|
| Khu KH & NCC | `presentation/partner_area_shell.dart` (`VListDetailLayout`), `core/router/app_router.dart` (ShellRoute khu đối tác, cột phải khi chưa chọn, route `/partner/new` và `/partner/:id/edit` ngoài khung) |
| PT-01 | `pages/partner_list_page.dart`, `widgets/{partner_list_search_bar, partner_list_quick_filters, partner_list_header_row, partner_list_body, partner_list_item_tile, partner_list_item_skeleton_tile, partner_no_permission_view}.dart`, `logic/{partner_list_state, partner_list_cubit}.dart` |
| PT-02 | `widgets/{partner_filter_bottom_sheet, partner_sort_bottom_sheet}.dart` |
| PT-03 | `widgets/partner_create_action_sheet.dart` |
| PT-05 | `pages/partner_create_page.dart`, `widgets/{partner_create_form, partner_form_section, partner_section_shell, partner_role_section, partner_person_section, partner_organization_section, partner_primary_contact_section, partner_invoice_section, partner_delivery_section, partner_note_section, partner_outlined_field, partner_compact_field, partner_leave_form_dialog}.dart`, `logic/{partner_create_state, partner_create_cubit, partner_create_form_validator}.dart` |
| PT-04 | `widgets/partner_duplicate_sheet.dart` |
| PT-06 | `widgets/partner_administrative_unit_picker_sheet.dart` (bản riêng của đối tác, khác `core/widgets/address/vn_administrative_unit_picker_sheet.dart` của Đăng ký) |
| PT-07 | `pages/partner_detail_page.dart`, `widgets/{partner_detail_header, partner_detail_status_banners, partner_detail_expandable_card, partner_detail_main_info_card, partner_detail_contacts_card, partner_detail_invoice_card, partner_detail_delivery_card, partner_detail_note_card, partner_detail_system_card, partner_detail_loading_skeleton, partner_detail_error_state, partner_detail_action_sheet, partner_deactivate_confirmation_sheet, partner_reactivate_confirmation_sheet, partner_soft_delete_confirmation_sheet, partner_delete_blocked_sheet, partner_delete_primary_contact_blocked_sheet, partner_detail_soft_delete_flow, partner_create_success_toast, partner_transform_success_toast}.dart` |
| Khối theme khác trên PT-07 | `features/receivable/presentation/widgets/{customer_receivable_summary_card, receivable_parts}.dart` (Theme 6); `features/inventory/presentation/supplier_program/supplier_programs_section.dart`, `…/goods_receipt/receipt_history_section.dart` (Theme 7); gắn ở `core/router/app_router.dart` |
| PT-12 | `pages/partner_change_history_page.dart`, `widgets/{partner_change_history_body, partner_change_history_card}.dart`, `logic/{partner_change_history_cubit, partner_action_log_diff}.dart` |
| PT-08…10 | `pages/{partner_contacts_page, partner_contact_form_page, partner_contact_select_page}.dart`, `widgets/{partner_contacts_loaded_body, partner_contacts_error_body, partner_contact_tile, partner_contact_empty_illustration, partner_contact_action_sheet, partner_contact_add_method_sheet, partner_contact_change_primary_dialog, partner_contact_remove_dialog, partner_contact_form, partner_contact_select_list, partner_detail_add_contact_flow}.dart` |
| PT-11 | `pages/partner_transform_page.dart`, `widgets/{partner_transform_stepper, partner_transform_step_one_view, partner_transform_step_one_validator, partner_transform_organization_form, partner_transform_field, partner_transform_primary_contact_card, partner_transform_blocking_banner, partner_transform_preview_view, partner_transform_preview_card, partner_transform_blocked_state, partner_transform_confirmation_dialog, partner_transform_primary_contact_blocked_sheet}.dart`, `logic/partner_transform_cubit.dart` |
| DS | `packages/c45_design_system/lib/src/components/{v_button, v_input, v_text_area, v_search_bar, v_banner, v_card, v_app_bar, v_avatar, v_empty_state, v_floating_action_button, v_checkbox, v_adaptive_sheet, v_bottom_sheet}.dart`, `primitives/{v_chip, v_badge, v_icon_box, v_skeleton, v_divider}.dart`, `forms/{v_select, v_choice_list, v_phone_field}.dart`, `patterns/{v_field, v_page_scaffold, v_page_padding, v_list_detail_layout}.dart`, `theme/v_color_scheme.dart` |

## Hiện trạng Flutter (để rà) — đợt 1

Các điểm dưới đây rút ra từ việc đọc code, chưa đối chiếu ảnh chụp app chạy thật. Điểm 1 và 11 nên chụp Flutter để xác nhận.

**Danh sách (PT-01)**

1. **Web: nút + nổi lệch vào trong 280 px.** `VPageScaffold` đẩy nút nổi theo gutter tính từ **cửa sổ** (1280 → cột 720 → gutter 280), trong khi danh sách chỉ rộng 360. Kết quả: nút nằm sát mép trái cột danh sách và đè lên thẻ.
2. App bar ghi **"0 đối tác"** khi đang tải lần đầu và khi lỗi tải lần đầu (`_lastTotal ?? 0`).
3. **Không thấy bộ lọc đang áp.** `PartnerActiveFilters` (chip + "Xóa lọc") có code nhưng không trang nào dùng. Lọc trong sheet xong chỉ còn số trên nút lọc. Muốn bỏ lọc phải mở sheet và bấm "Đặt lại".
4. Vai trò có ở hai chỗ (chip nhanh và sheet), và chip nhanh cũng **đếm vào số trên nút lọc**: chọn "Khách hàng" là nút lọc hiện "1" và viền xanh, dù chưa mở bộ lọc.
5. **Lọc ra rỗng mà không có từ khoá** → hiện "Chưa có KH & NCC / Thêm đối tác để bắt đầu bán hàng…" như cửa hàng chưa có đối tác nào. Đầu danh sách lại ghi "0 kết quả phù hợp". Không có lối xoá lọc.
6. Hai kiểu trạng thái trống trong cùng màn. Trống / không kết quả: hộp trắng nằm ở đầu vùng danh sách, nút chữ. Lỗi tải: không nền, canh giữa vùng còn lại, nút chính, tiêu đề chữ đỏ.
7. Nhãn trạng thái **hai cỡ**: "Đang hoạt động" cỡ thường (xanh), "Ngừng hoạt động" cỡ nhỏ (vàng). Nhãn chiếm ~120 px bên phải thẻ nên tên dài xuống dòng. Web (cột 360): "Tổ chức · KH & NCC", "MST 0312345678", "Cập nhật 21/11/2026" đều gãy hai dòng.
8. **"Mua lẻ / khác"** (đối tác hệ thống của Kho, G5-2b) nằm lẫn trong danh sách như mọi đối tác: avatar "MK", không SĐT. Theo SQL đọc được, `search_partners` không lọc `is_system`.
9. Web: chip nhanh "KH & NCC" bị cắt ở mép cột 360. Hàng chip cuộn ngang nhưng không có dấu hiệu cuộn.
10. Cột phải khi chưa chọn: ô icon 64 nền `surfaceAlt` trùng màu nền trang nên chỉ thấy icon trơ. Câu "Chọn một KH & NCC để xem chi tiết." có dấu chấm cuối, trong khi các tiêu đề trống khác không có.

**Bộ lọc / Sắp xếp / Thêm mới (PT-02, PT-03)**

11. **iPhone: sheet mở từ danh sách chỉ phủ vùng tab.** `showModalBottomSheet` (useRootNavigator false) đẩy route vào navigator lồng của ShellRoute, nên thanh dưới vẫn hiện, không bị phủ tối. Sheet mở từ form (ngoài khung) thì phủ cả màn.
12. Hàng "Thời gian cập nhật" gồm 3 chip chia đều. Trên iPhone chữ bị cắt ("7 ngày gần …", "30 ngày gầ…") và canh trái trong chip. Chip **"Tùy chọn" bấm không làm gì** (`onTap: () {}`).
13. "Vai trò giao dịch" không có chip "Tất cả", bấm lại để bỏ chọn. "Trạng thái" có "Tất cả", bấm lại không bỏ được. Hai cách chọn khác nhau trong một sheet.
14. Ba kiểu đầu sheet. Bộ lọc: không tiêu đề sheet, chữ "Bộ lọc KH & NCC" là H4 trong nội dung. Sắp xếp: nhãn ô "Sắp xếp danh sách". Thêm mới: tiêu đề sheet H3 + gạch. Web: sheet không tiêu đề cộng hai lớp đệm (hộp thoại 16 / 24 + nội dung 16), nên chữ cách mép 32.
15. Sắp xếp: mỗi lựa chọn cao 64 + khe 12, nên 4 lựa chọn chiếm ~300 px.

**Tạo / sửa hồ sơ (PT-05)**

16. Route ngoài khung: web **mất thanh bên** khi tạo / sửa. App bar kéo hết 1280, thân cột 720.
17. Nút ← là `VIconBox` 40 (icon 20, `arrowBack`), khác nút ‹ 24 của `VAppBar` ở các màn khác.
18. **iPhone: hàng "Hủy | Lưu & Xem" không chừa vùng an toàn đáy.** `_StickyActions` nằm trong thân, không có SafeArea, nên nút nằm đè thanh home.
19. **"Lưu & Xem" tắt mà không nói thiếu gì** (cần vai trò + tên + SĐT). Lỗi chỉ hiện trong mục đang mở. Lưu lỗi sẽ mở mục lỗi đầu tiên, lỗi ở mục khác không thấy.
20. Viền mục là `borderDefault` (#E5E8EB), nhạt hơn `VCard` (`borderStrong`) ở danh sách và sheet.
21. **Khe giữa các ô không đều**: cá nhân 8 rồi 16; tổ chức toàn 8; hoá đơn 8 / 16 / 8; người liên hệ chính toàn 16.
22. Tổ chức: MST, tên HĐ, địa chỉ HĐ có dấu * nhưng **không chặn lưu**. Banner vàng "Thiếu MST, tên xuất hóa đơn và địa chỉ hóa đơn…" hiện ngay khi vừa mở mục, trước khi người dùng nhập gì.
23. Địa chỉ giao hàng: nhãn bodySmall w700 13 khác nhãn ô khác (14 w600). Ô tỉnh / xã viền `borderStrong`, nhạt hơn ô nhập (`borderInput`). Ô xã khi tắt mờ 50% (kiểu riêng, không phải mờ 0.4 của DS).
24. Ô nhiều dòng (`VTextArea`) đệm ngang 8, ô một dòng đệm 12, nên chữ lệch nhau 4 px. Ô ghi chú dày đặc, đệm 4.
25. Chữ phụ khi mục đóng không thống nhất. Vai trò / Thông tin / Hoá đơn để trống khi chưa nhập, còn Địa chỉ / Ghi chú ghi "Tùy chọn". Chế độ sửa: mọi mục đã có dữ liệu nhưng không có ✓.
26. Hàng "Bỏ qua | Tiếp": "Tiếp" là nút nhỏ 36 rộng 112, nhỏ hơn mọi nút khác. Chữ "Bỏ qua" (tertiary) lùi vào 32 so với mép ô 16.
27. Sửa tổ chức: lúc đang tải tiêu đề ghi **"Chỉnh sửa cá nhân"** (loại mặc định của `PartnerCreatePage.edit`). Vòng tải là `CircularProgressIndicator` Material, không phải VLoading.
28. Lỗi chung chỉ là banner một dòng tiêu đề. Xung đột phiên bản ("đã được cập nhật bởi người khác…") không có nút tải lại.
29. Không có quyền tạo: form vẫn nhập được hết, chỉ nút lưu tắt.

**Trùng hồ sơ (PT-04)**

30. Tiêu đề H3 w600, còn tiêu đề sheet khác w700. "Có thể trùng" **không có nút Quay lại** (chỉ vuốt / Đóng). "Xem chi tiết" luôn mở hồ sơ **đầu tiên** dù có nhiều thẻ, và thẻ khớp không bấm được. Web: hộp thoại không tiêu đề, đệm đôi.

**Chọn khu vực (PT-06)**

31. Danh sách sắp theo mã ký tự (`compareTo`): "Thành phố Đà Nẵng", "Thành phố Đồng Nai" nằm sau "Hồ Chí Minh"; "Tỉnh Điện Biên", "Tỉnh Đắk Lắk", "Tỉnh Đồng Tháp" ở cuối (giống Theme 1 điểm 13).
32. Web: **hai nút Đóng** chồng ở góc phải (của hộp thoại + của sheet). Sheet cao cố định 75% màn.
33. Đây là **bản riêng của đối tác**, khác bản `core` ở Đăng ký (Theme 1): bước có số tròn, mỗi tỉnh có "N xã/phường". Cùng việc chọn khu vực nhưng có hai giao diện.

**Mã chết (không vẽ)**

34. `partner_active_filters.dart`, `partner_form_field_row.dart`, `PartnerCompactTextField` / `PartnerCompactDropdown` (`partner_compact_field.dart`), `partner_ward_search_dropdown.dart`: không nơi nào dùng (kể cả test).

## Hiện trạng Flutter (để rà) — đợt 2

**Bố cục hồ sơ (PT-07)**

35. **Web: hàng nút "Chỉnh sửa | Thao tác" không chạm hai mép cột.** Hàng nút nằm trong thân `VPageScaffold`, mà thân bị giới hạn cột 640 trong cột phải rộng 679, nên hai bên hở ~20 px nền xám. App bar thì kéo hết cột.
36. **Toast đè lên hàng nút đáy.** Web: khung không có Scaffold, nên SnackBar hiện ở Scaffold của hồ sơ, sát đáy cột phải. iPhone: SnackBar hiện ở `ErpTabScaffold`, ngay trên thanh dưới. Cả hai đều che "Chỉnh sửa | Thao tác".
37. Ba kiểu nhãn trạng thái cho cùng một việc. Danh sách: `VBadge` bo tròn, cỡ thường / nhỏ. Đầu hồ sơ: `_StatusTag` bo 4, 11 px, nền 10%. Người liên hệ: "Chính" cùng kiểu `_StatusTag`. Nhãn nhỏ trên thẻ đóng: bo 8, 10 px.
38. **Mọi thẻ thông tin đều đóng khi mở hồ sơ**, nên muốn xem SĐT phụ, email, địa chỉ… phải bấm từng thẻ. Thẻ đóng dùng mũi tên ›, giống thẻ điều hướng (Công nợ, Lịch sử thao tác).
39. "Lịch sử thao tác " (thừa dấu cách cuối) dùng icon bánh răng (`VIcons.settings`).
40. Thứ tự khối trộn lẫn: Công nợ (Theme 6) chen giữa "Thông tin" và "Người liên hệ"; khối NCC (Theme 7) nằm sau "Ghi chú". Ba khối ngoài mỗi khối một kiểu: Công nợ là thẻ viền nhạt có chevron; Chương trình ưu đãi là `VCard` viền đậm có đầu "Xem tất cả ›"; Lịch sử nhập hàng không có thẻ bọc, đầu H4 + nút link 44, mỗi phiếu một `VCard`.
41. Lịch sử nhập hàng: ngày là chuỗi thô "2026-11-18", tiền "12.500.000 đ" (Công nợ "₫"). Chữ không màu DS (Text + VTypography không màu). Rỗng: một dòng `Text` mặc định đệm 8, không tiêu đề. **Lỗi tải hiện như rỗng.** Đang tải: vòng Material.
42. Công nợ đang tải / lỗi → không vẽ gì, nhưng khe 8 phía sau vẫn còn (hai khe liền nhau). Lỗi không báo.
43. Hai câu thiếu hoá đơn khác nhau: banner "Thiếu MST và địa chỉ hóa đơn. " (có dấu cách cuối), nhãn thẻ "Thiếu MST và địa chỉ" / "Thiếu MST, tên HĐ và địa chỉ". Hồ sơ ngừng hoạt động không hiện banner thiếu thông tin dù vẫn thiếu.
44. Đối tác hệ thống "Mua lẻ / khác": không có hàng nút đáy (không có lối "Thao tác"), không có khối NCC dù có vai trò NCC. Thẻ Người liên hệ vẫn cho "Thêm người liên hệ". Nhãn đỏ "Thiếu MST, tên HĐ và địa chỉ" trên hồ sơ không sửa được.
45. Trạng thái lỗi của hồ sơ dùng `PartnerDetailErrorState` riêng (hình ghép khiên + "?", tài liệu + kính lúp; nút viền rộng cố định 220). Danh sách dùng `VEmptyState` (nút chính, tiêu đề đỏ). Hai kiểu lỗi trong cùng khu.

**Sheet thao tác (PT-07)**

46. Sheet thao tác không có tiêu đề sheet; "Thao tác hồ sơ" là chữ H3 trong nội dung. Web: hộp thoại không tiêu đề nên có nút Đóng góc và đệm đôi. Mỗi thao tác là một thẻ có ›, thêm "Hủy" đầy ngang.
47. **Xác nhận "Ngừng hoạt động" là nút xanh chính** (không cảnh báo màu); "Xóa hồ sơ" đỏ. Nút "Hủy" lúc chữ xanh (ngừng / kích hoạt), lúc chữ đen (xoá).
48. Banner cảnh báo "đang là liên hệ chính" dùng `VBanner(title: '')`: hàng đầu chỉ có icon, câu thụt 32 xuống dòng dưới.
49. Bốn kiểu đầu sheet xác nhận. Vòng tròn 64 (ngừng / kích hoạt / xoá). Icon cảnh báo trơ 56 (không xoá được vì có giao dịch). Icon thùng rác trơ 44 + **tay kéo tự vẽ 40 × 4** (không xoá được vì là liên hệ chính) → iPhone hiện hai tay kéo. Sheet xoá / chặn xoá có nút × riêng 32 → web thêm nút Đóng của hộp thoại thành hai ×.
50. Hai sheet cùng tiêu đề "Không thể xóa hồ sơ" khác icon, khe, màu.

**Toast**

51. Toast chuyển đổi tự vẽ (chấm 24, × 20 không có vùng chạm 44, đệm 14), khác `VToast` của các thao tác khác. Câu có / không dấu chấm cuối lẫn lộn ("Đã cập nhật hồ sơ KH & NCC" / "Đã ngừng hoạt động KH & NCC.").

**Lịch sử thao tác (PT-12)**

52. Route ngoài khung: web mất thanh bên. Nút ← là `IconButton(arrowBack)`, khác ‹ của VAppBar.
53. **"bởi 3f9a2c1b"**: người thực hiện là 8 ký tự đầu mã người dùng, không phải tên.
54. Ngày dạng "2026-11-21 16:40" (danh sách dùng "21/11/2026"). Thay đổi sắp theo tên nhãn (A→Z), nên tiêu đề "Cập nhật email, SĐT chính và 1 thông tin khác" không theo thứ tự trên form. "Tạo đối tác" không có dòng chi tiết.
55. Chỉ tải trang đầu (20 dòng), không có tải thêm (TH-03 US-07.1 ghi phân trang). Đang tải: vòng Material.

## Hiện trạng Flutter (để rà) — đợt 3

**Người liên hệ (PT-08)**

56. Route ngoài khung: web mất thanh bên. Tiêu đề **canh giữa** (danh sách, hồ sơ canh trái). Nút "⋯" góc phải **bấm không làm gì** (`onPressed: () {}`).
57. Dòng người liên hệ là danh sách có gạch ngăn (danh sách đối tác dùng thẻ). Thẻ "Chính" caption 12 bo 4; trên hồ sơ (PT-07) cùng thẻ là 11 px.
58. Trống: hình ghép 3 vòng người tự vẽ; nút viền "**Gợi ý** thêm người liên hệ" (chữ lạ, mở cùng sheet với nút +). Nút + vẫn hiện, nên có hai lối cùng việc.
59. Lỗi: icon `error_outline` 48 + tiêu đề H3 w600. Đây là kiểu lỗi thứ ba trong theme (danh sách `VEmptyState`, hồ sơ `PartnerDetailErrorState`).
60. Toast "Thêm người liên hệ thành công" / "Cập nhật người liên hệ thành công", trong khi hồ sơ dùng "Đã …".

**Sheet người liên hệ**

61. **"Đổi người liên hệ chính?" tự bọc `VBottomSheet` bên trong `showVAdaptiveSheet`**: iPhone sheet lồng sheet, hai tay kéo; web hộp thoại có tay kéo và bo trên bên trong.
62. Sheet thao tác người liên hệ (ListTile 56 + gạch, "Gỡ khỏi tổ chức" đỏ) khác hẳn sheet thao tác hồ sơ (thẻ có vòng icon).
63. "Gỡ người liên hệ?" không có icon đầu, khe giữa hai nút 8 (các sheet khác 12).
64. Sheet "Thêm người liên hệ": khe chữ → › thẻ 1 là 8, thẻ 2 là 16. Mở từ hồ sơ (trong vùng tab, iPhone) thì "Hủy" sát mép dưới sheet; mở từ PT-08 (ngoài khung) thì có khoảng an toàn đáy.

**Thêm / sửa người liên hệ (PT-09)**

65. "Hủy" / "Lưu" là **nút chữ trên app bar**; form hồ sơ (PT-05) dùng hàng nút đáy. Hàng nút đáy của `PartnerContactForm` có code nhưng không bao giờ hiện (trang luôn truyền `onFormCreated`).
66. **Đang lưu không có vòng xoay**: các ô mờ đi nhưng "Lưu" trên app bar vẫn bấm được.
67. Lỗi máy chủ là hộp đỏ nhạt tự vẽ, không phải VBanner. Câu lỗi "Vui lòng nhập họ tên" khác form hồ sơ ("Vui lòng nhập họ và tên").
68. Thứ tự vai trò khác TH-03 US-04.2 (Kế toán trước Nhân viên mua hàng, Giao nhận trước Phụ trách công nợ). Công tắc ghi "Người liên hệ chính" + câu phụ; TH-03 ghi "Là người liên hệ chính cho tổ chức".

**Chọn từ cá nhân (PT-10)**

69. Chọn nhiều nhưng ô chọn là **vòng tròn 22** (trông như radio). Trống / lỗi chỉ là một dòng chữ giữa màn; lỗi không có nút thử lại.
70. Hàng "Hủy | Chọn (n)" nằm trong thân, nên web hẹp theo cột 720.

**Chuyển thành tổ chức (PT-11)**

71. Đệm thân 12 (màn khác 16). Dưới thanh bước có **vạch 96 × 4 trông như tay kéo sheet**; bước 2 vạch rộng 44. Bước 3 "Xác nhận" trên thanh không bao giờ sáng, vì xác nhận là hộp thoại.
72. Nhãn ô là chữ xám 13 (`PartnerTransformFieldLabel`), không phải `VFieldLabel` 14 đậm như form tạo tổ chức (PT-05), dù cùng là "Thông tin tổ chức". Ô cách 8. **Không điền sẵn** SĐT / email của cá nhân. Nút "Huỷ" viết "uỷ".
73. Xác nhận là `Dialog` Material (cả iPhone), không phải sheet như mọi xác nhận khác. Tiêu đề canh giữa nhưng 3 câu canh trái.
74. **Đang chuyển: lớp phủ màu `textPrimary` (gần đen, đặc)** che toàn thân, kèm vòng xoay xanh.
75. Trùng SĐT từ máy chủ: quay về bước 1, lỗi dưới ô, không có banner, "Tiếp" vẫn bật. Lỗi ô thiếu: banner vàng + "Tiếp" mờ.
76. Sheet "Không thể chuyển thành tổ chức" (mở từ PT-07) tự vẽ tay kéo 40 × 4 giống sheet chặn xoá, nên iPhone có hai tay kéo.
77. Bước 2: hai khối "Trước / Sau khi chuyển" nền `surfaceAlt`, trùng màu nền trang (`background`), nên khối không thấy, chỉ còn tiêu đề trôi; thẻ "Người liên hệ chính" bên dưới không nằm trong khối nên lệch vào trái 12 px so với hai thẻ trên.

## Khác biệt có chủ đích với Flutter

- Icon: Material thay bằng nét kiểu Lucide trong `shared/icons.js`, giữ ý nghĩa và cỡ. Mũi tên `arrow_drop_down` (tam giác đặc) của VSelect vẽ bằng chevron.
- Font: không nạp Inter (như các prototype 10-8 khác).
- Badge số trên nút lọc (Material `Badge`) đặt gần đúng vị trí lệch (4, −4).
- AppBar có subtitle vẽ cao 64 (`preferredSize`), không có subtitle cao 57.
- Không vẽ: menu thả của VSelect "Loại tổ chức", bàn phím, kéo để làm mới.
- PT-07: hình lỗi "không quyền" dùng icon khiên có dấu ✓ của `shared/icons.js` (Flutter: khiên trơn). Thẻ trạng thái đối tác hệ thống / dữ liệu Công nợ, chương trình, phiếu nhập là dữ liệu mẫu.

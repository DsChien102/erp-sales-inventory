# Prototype Theme 3 (TH-03) — Đối tác giao dịch (KH & NCC) (10-8)

HTML/CSS/JS thuần (ES module, không build). Vẽ **đúng Flutter hiện tại** của các màn TH-03, ở cả iPhone 390 và Web 1280. Web dùng bố cục 2 cột danh sách – hồ sơ của 4-W. Mục đích: người dùng rà bằng impeccable (bước 3 của 10-8). Chép y nguyên chữ, thứ tự, số đo DS; **không thiết kế lại**. Sheet / hộp thoại / toast là ca riêng.

Làm theo 3 đợt, mỗi đợt một commit. Cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Danh sách & tạo | PT-01 Danh sách (L-01…L-07), PT-02 Bộ lọc / Sắp xếp, PT-03 Thêm mới, PT-05 Tạo / sửa (+ sheet rời màn), PT-04 Trùng hồ sơ, PT-06 Chọn khu vực | ✅ 48 ca × 2 khổ |
| 2 · Hồ sơ | PT-07 (KH / NCC, banner hoá đơn, ngừng hoạt động; khối **Công nợ** Theme 6, **Chương trình ưu đãi** + **Lịch sử nhập hàng** Theme 7 vẽ đầy đủ như Flutter), sheet thao tác / ngừng / kích hoạt / xoá / chặn xoá, toast, PT-12 | ⬜ |
| 3 · Liên hệ & chuyển đổi | PT-08, PT-09, PT-10, PT-11 | ⬜ |

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
| `app/main.js` | Ca → trạng thái; khu KH & NCC: web chia 2 cột (`VListDetailLayout` 360 / 840), sheet web phủ cả cửa sổ, sheet iPhone chỉ phủ vùng tab |
| `styles/t3.css` | Rule tiền tố `t3-`, token `--c45-v2-*`; đầu file có bảng màu / chữ Flutter → token |
| `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Trang xem, chụp ảnh — chép khuôn Theme 1 (cổng 8771) |
| `shared/icons.js` | Thêm `plus` (VIcons.add), `tune`, `cloudOff`, `chevronUp` (expandLess), `searchOff` |

Gom bộ widget DS về `shared/` (Theme 1 và Theme 3 đang có hai bản `ds.js`) để làm sau, khi đã có 2–3 theme và thấy rõ phần chung. Đến lúc đó sửa một widget DS phải sửa ở cả hai nơi.

## Nguồn Flutter (đợt 1)

| Màn | Flutter (`apps/erp/lib/features/partner/`) |
|---|---|
| Khu KH & NCC | `presentation/partner_area_shell.dart` (`VListDetailLayout`), `core/router/app_router.dart` (ShellRoute khu đối tác, cột phải khi chưa chọn, route `/partner/new` và `/partner/:id/edit` ngoài khung) |
| PT-01 | `pages/partner_list_page.dart`, `widgets/{partner_list_search_bar, partner_list_quick_filters, partner_list_header_row, partner_list_body, partner_list_item_tile, partner_list_item_skeleton_tile, partner_no_permission_view}.dart`, `logic/{partner_list_state, partner_list_cubit}.dart` |
| PT-02 | `widgets/{partner_filter_bottom_sheet, partner_sort_bottom_sheet}.dart` |
| PT-03 | `widgets/partner_create_action_sheet.dart` |
| PT-05 | `pages/partner_create_page.dart`, `widgets/{partner_create_form, partner_form_section, partner_section_shell, partner_role_section, partner_person_section, partner_organization_section, partner_primary_contact_section, partner_invoice_section, partner_delivery_section, partner_note_section, partner_outlined_field, partner_compact_field, partner_leave_form_dialog}.dart`, `logic/{partner_create_state, partner_create_cubit, partner_create_form_validator}.dart` |
| PT-04 | `widgets/partner_duplicate_sheet.dart` |
| PT-06 | `widgets/partner_administrative_unit_picker_sheet.dart` (bản riêng của đối tác, khác `core/widgets/address/vn_administrative_unit_picker_sheet.dart` của Đăng ký) |
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

## Khác biệt có chủ đích với Flutter

- Icon: Material thay bằng nét kiểu Lucide trong `shared/icons.js`, giữ ý nghĩa và cỡ. Mũi tên `arrow_drop_down` (tam giác đặc) của VSelect vẽ bằng chevron.
- Font: không nạp Inter (như các prototype 10-8 khác).
- Badge số trên nút lọc (Material `Badge`) đặt gần đúng vị trí lệch (4, −4).
- AppBar có subtitle vẽ cao 64 (`preferredSize`), không có subtitle cao 57.
- Không vẽ: menu thả của VSelect "Loại tổ chức", bàn phím, kéo để làm mới.

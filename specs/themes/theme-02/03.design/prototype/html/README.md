# Prototype Theme 2 (TH-02) — Sản phẩm & giá bán (10-8)

HTML/CSS/JS thuần (ES module, không build). Vẽ **đúng Flutter hiện tại** của các màn TH-02 ở cả iPhone 390 và Web 1280. Trên web, danh sách và PCC chia 2 cột như 5-W. Mục đích: để người dùng rà bằng impeccable (bước 3 của 10-8). Chép y nguyên chữ, thứ tự, số đo DS; **không thiết kế lại**. Sheet, hộp thoại, toast là ca riêng.

Làm theo 4 đợt, mỗi đợt một commit (đủ 153 ca × 2 khổ, 112 điểm hiện trạng). Cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Danh sách & tạo | SP-01 Danh sách, SP-02 Lọc thông tin bổ sung, SP-03 Tạo nhanh (7 bước) + sheet "Thêm ảnh sản phẩm" | ✅ 46 ca × 2 khổ |
| 2 · PCC | SP-04 (thẻ Tồn kho chỉ xem → kho Theme 7), sheet vòng đời / xoá / khôi phục + toast, SP-21 Checklist, SP-22 Lịch sử thay đổi | ✅ 33 ca × 2 khổ |
| 3 · Màn con | SP-05 Hồ sơ (ô gạt "Quản lý theo lô" của Theme 7), SP-06 Ảnh (+ hộp thoại xoá, gallery), SP-07 Ghi chú, SP-08 Thông tin bổ sung, SP-09 Đơn vị (+ 4 sheet), SP-11 Giá cơ sở, SP-12 / 13 Khung giá (+ sheet ghi đè) | ✅ 46 ca × 2 khổ |
| 4 · Cài đặt sản phẩm | SP-14 Cài đặt, SP-15 Nhóm, SP-16 Chi tiết / tạo / sửa nhóm (+ sheet tạm tắt, thoát không lưu), SP-17 Tạo / sửa trường (+ dialog bắt buộc, sheet tạm tắt), SP-18 Khung giá cửa hàng, SP-19 Sửa (+ sheet áp dụng), SP-20 Lịch sử | ✅ 28 ca × 2 khổ |

SP-10 (tồn kho cơ bản) đã bỏ ở G5-5, nên không vẽ.

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/themes/theme-02/03.design/prototype/html
python3 tools/serve.py &    # cổng 8772, tắt cache
# trang xem: http://127.0.0.1:8772/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=list&state=loaded&device=web
node --test                 # hàm thuần đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # mọi ca × 2 khổ → tools/proto-final/{iphone,web}/<màn>__<ca>.png (không vào git)
```

Màn trần không có tương tác: mỗi trạng thái là một ca. Ca của màn tạo (bước 2 trở đi) cuộn sẵn tới bước đang mở.

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/cases.js` | Nhóm (đợt), màn, ca, kèm điều cần nhìn của từng ca |
| `app/ds.js` | Widget DS, **chép từ Theme 3** (`theme-03/app/ds.js`, đổi `t3-` → `t2-`), thêm VSwitch, hậu tố chữ (`đ`, `%`), VTextArea có bộ đếm |
| `app/data.js` | Sản phẩm mẫu (cửa hàng thú y, như Theme 3), số đếm chip, đơn vị của tenant, nhóm thông tin bổ sung; `money` (formatCatalogCurrency); `photo` (ảnh minh hoạ thay ảnh Storage) |
| `app/list.js` | SP-01, SP-02, cột phải khi chưa chọn; hàm thuần `chipLabel`, `emptyCopy`, `localStockFilter`, `stockText`, `cfDisplay` |
| `app/create.js` | SP-03 + sheet thêm ảnh; `dartDouble`, `pricePercentLabel`, `stepTitles`, `hasAnyData`, `matchUnits` |
| `app/pcc.js` | SP-04 + sheet + toast, SP-21, SP-22; `evaluate` (ProductReadinessEvaluator), `statusBadge`, `priceBandSubtitle`, `profileStockText`, `valueLine`, `ctaLabel` |
| `app/sub.js` | Đợt 3: SP-05…09, SP-11…13 + dialog / sheet / gallery; `formBar` (ProductFormBottomBar), `ratioText`, `unitsSaveEnabled`, `formatRate` |
| `app/settings.js` | Đợt 4: SP-14…20 + sheet / dialog; `pct1`, `ruleValues`, `deltaText`, `fieldMeta`, `TYPE_CARD` / `TYPE_SELECT` |
| `app/main.js` | Ca → trạng thái. Khu Sản phẩm: web chia 2 cột (`VListDetailLayout` 360 / 840), sheet web phủ cả cửa sổ, sheet iPhone chỉ phủ vùng tab. Màn tạo nằm ngoài khung |
| `styles/t2.css` | Rule tiền tố `t2-`, token `--c45-v2-*`; đầu file có bảng màu và cỡ chữ Flutter → token |
| `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Trang xem và chụp ảnh, chép khuôn Theme 3 (cổng 8772) |
| `shared/icons.js` | Đợt 4: `grip` (gripVertical), `trendingDown`. Đợt 2: `clipboard`, `ruler` (straighten), `coins`, `play`. Đợt 1: `image`, `imageOff`, `camera`, `images` (photo_library), `folder`, `qrScan` (qr_code_scanner), `externalLink` (open_in_new), `moreVert`, `ban` (block) |

Ảnh sản phẩm: Flutter tải ảnh thật từ Storage. Prototype không có ảnh thật nên vẽ ảnh minh hoạ SVG (nền màu + hình hộp), cùng khổ và cùng bo góc.

Có 3 bản `ds.js` (Theme 1, 3, 2). Gom về `shared/` để làm sau. Đến lúc đó, sửa một widget DS phải sửa ở cả ba nơi.

## Nguồn Flutter

| Màn | Flutter (`apps/erp/lib/features/catalog/`) |
|---|---|
| Khu Sản phẩm | `presentation/product_area_shell.dart` (`VListDetailLayout`), `core/router/app_router.dart` (ShellRoute khu sản phẩm, cột phải khi chưa chọn, `/products/items/new` ngoài khung) |
| SP-01 | `pages/product_catalog_tab_page.dart`, `widgets/{product_list_search_bar, product_catalog_filter_chips, product_list_filter, product_catalog_list_body, product_list_item_tile, product_list_item_skeleton_tile}.dart`, `logic/product_list_cubit.dart`, `data/models/product_search.dart` |
| SP-02 | `widgets/custom_field_filter_sheet.dart` |
| SP-04 | `pages/product_control_center_page.dart`, `widgets/{product_control_center_body, product_control_center_status_badge, product_control_center_profile_card, product_control_center_readiness_banner, product_control_center_section_card, product_control_center_identity_section, product_control_center_operational_section, product_control_center_custom_fields_section, product_control_center_meta_section, product_control_center_danger_section, product_lifecycle_bottom_sheets, product_delete_confirm_dialog, product_restore_confirm_dialog}.dart`, `logic/product_readiness.dart`, `data/models/product_readiness.dart` |
| SP-05…09, SP-11…13 | xem đầu `app/sub.js` (mỗi màn một trang + widget đi kèm; chân chung `widgets/product_form_bottom_bar.dart`) |
| SP-14…20 | xem đầu `app/settings.js` (`pages/settings/*` + sheet đi kèm) |
| SP-21 | `pages/product_readiness_checklist_page.dart`, `widgets/product_readiness_checklist_body.dart` |
| SP-22 | `pages/product_change_history_page.dart`, `widgets/{product_change_history_item, product_price_band_history_change}.dart`, `utils/product_change_history_formatters.dart`; tên người làm: `get_product_change_history` trả `left(actor_id::text, 8)` |
| SP-03 | `pages/product_guided_create_page.dart`, `widgets/{product_guided_create_body, product_guided_fields, product_guided_step_identification, product_guided_step_images, product_guided_step_base_unit, product_guided_step_base_cost, product_guided_step_price_bands, product_guided_step_custom_fields, product_guided_step_note, product_image_picker_panel, tenant_measurement_unit_search_field}.dart`, `widgets/image_picker/{product_image_grid_item, product_image_add_sheet}.dart`, `widgets/custom_fields/product_custom_field_input_widget.dart`, `logic/{product_guided_create_state, product_guided_create_cubit}.dart`, `presentation/mappers/guided_price_band_submission_resolver.dart` |

## Hiện trạng Flutter (để rà) — đợt 1

**Danh sách (SP-01)**

1. Cột tồn trên thẻ là **số trơn, không có đơn vị** ("24"), vì `ProductListItemAssembler` gán `stockLabel = stockQuantity.toString()`. Hết hàng thì hiện "Hết" chữ vàng. "Chưa TL tồn" không bao giờ hiện, vì `stock_qty` là `coalesce(available, 0)`, không bao giờ null.
2. Thẻ không cho biết sản phẩm **đang ngừng kinh doanh** hay **sẵn sàng bán / thiếu dữ liệu**. Chỉ sản phẩm đã xoá có nhãn ("Đã xóa", xám nhỏ).
3. Chip "Còn hàng" / "Hết hàng" lọc **cục bộ** trên các dòng đã tải (trang đầu 20 dòng), không gọi máy chủ. "Hết hàng" gồm cả sản phẩm ngừng kinh doanh.
4. Số trên chip không đều. "Tất cả / Sẵn sàng bán / Thiếu dữ liệu / Ngừng KD" có số. "Còn hàng / Hết hàng" chỉ có số khi danh sách không lọc đã tải hết. "Đã xóa" chỉ có số khi đang ở chip đó. Số chỉ cập nhật khi tải danh sách không lọc.
5. Nút ⋮ trên app bar bấm không làm gì (`onPressed: () {}`).
6. **Lỗi tải chỉ là một dòng chữ đỏ** "Lỗi: Đã xảy ra lỗi. Vui lòng thử lại." (chữ "lỗi" lặp lại). Không icon, không nút thử lại. Kéo để tải lại cũng không được, vì `RefreshIndicator` chỉ bọc danh sách có dữ liệu.
7. Không có màn "không có quyền xem". Không có quyền thì ra dòng đỏ "Lỗi: Bạn không có quyền thực hiện thao tác này.", còn ô tìm, chip và nút + vẫn hiện. Nút + không kiểm quyền tạo.
8. Câu khi rỗng không xét từ khoá. Tìm không ra ở chip "Tất cả" → "Không tìm thấy sản phẩm" + "Hãy thử … hoặc tạo sản phẩm mới.", nhưng không có nút (không "Xóa từ khóa", không "Tạo sản phẩm"). Tìm không ra ở chip khác → "Không có sản phẩm "Thiếu dữ liệu"" (ngoặc kép lồng). "Không có sản phẩm đã xóa." có dấu chấm cuối, các câu rỗng khác không có.
9. Chưa có sản phẩm nào: nút "+ Tạo sản phẩm" giữa màn và nút + nổi cùng hiện, hai lối cho cùng một việc.
10. Không có hàng đầu danh sách (số kết quả, sắp xếp) như KH & NCC. Khi tìm, app bar vẫn ghi tổng toàn bộ.
11. Thiếu giá hiện "_" (gạch dưới), thiếu ĐVT hiện "–" (gạch ngang). ĐVT viết thường ("hộp", đơn vị lưu chữ thường). Giá là giá sau VAT nhưng không ghi.
12. Ô trường bổ sung dùng chữ 11 px, ngoài thang chữ DS.
13. Khung tải tô nền surfaceAlt trên thẻ trắng, rất nhạt.
14. Nút lọc có số khi đang lọc, nhưng không thấy đang lọc theo gì. Không có lối xoá lọc nhanh.
15. Web: nút + bị đẩy vào trong 280 px (gutter tính theo cửa sổ 1280, không theo cột 360), nên đè lên danh sách sát mép trái cột (giống Theme 3).

**Lọc (SP-02)**

16. **Mọi chip đều xanh như đang chọn.** Chip đặt cứng `tone: primary`, mà tone thắng `selected`, nên chọn hay không trông như nhau.
17. Khi rỗng, câu "Chưa có thuộc tính mở rộng nào." dùng chữ "thuộc tính mở rộng" (nơi khác gọi "thông tin bổ sung"). Hai nút vẫn hiện.
18. Lỗi tải tuỳ chọn lọc bị nuốt (`catch (_) {}`), nên sheet hiện như chưa có trường nào.
19. "Bỏ lọc" đóng sheet và áp ngay, không cần "Áp dụng".

**Tạo nhanh (SP-03)**

20. Route nằm ngoài khung, nên web mất thanh bên. Nút ← là `VIcons.arrowBack` có thân, khác ‹ của VAppBar.
21. Tiêu đề "Tạo nhanh sản phẩm" nhưng có 7 bước (6 nếu không có nhóm thông tin bổ sung).
22. **Ba kiểu nhãn và ô nhập.** Bước 1 và 6 dùng VTextField: nhãn 14 w600 đen, ô 44 viền đậm. Bước 3 dùng `buildLabel` (13 w700 xám, lùi 4) + `TextField` Material (cao ~40, nền canvas, viền nhạt). Bước 4 và 5 dùng nhãn nhỏ + VInput 44.
23. Nút quét mã trong ô Barcode bấm không làm gì.
24. Bấm "Tiếp" ở bước 1 khi chưa có tên thì không báo gì; chỉ báo khi bấm Lưu.
25. **Lỗi hiện bằng toast đè lên chân "Huỷ | Lưu sản phẩm"**, vì chân nằm trong thân nên SnackBar nổi ở đáy Scaffold.
26. Hai ô gạt "Quản lý theo lô" | "Bắt buộc hạn dùng" chia đôi hàng, nên chữ xuống 2 dòng trên iPhone. Ô hạn dùng mờ khi tắt lô nhưng không có câu giải thích.
27. Bước ảnh: hai dòng chữ xám liền nhau ("Chạm vào ảnh để đặt…" và "Chưa có ảnh" chữ 12). Nút × trên ảnh tròn 24, dưới 44. Có chữ tiếng Anh "Xem gallery". Web: lưới 3 cột trong cột 720, nên mỗi ô ảnh ~212 px.
28. Ba kiểu cảnh báo vàng. Hộp tự vẽ (bo 8, đệm 12, không icon) ở bước 4 / 5. Dòng có icon (bo 12, đệm 8) ở bước 5 thủ công. VBanner (dùng ở theme khác). Hộp "Cần thiết lập đơn vị cơ sở…" chạm được (về bước 3) nhưng không có dấu hiệu bấm được.
29. **Nhãn gợi ý giá in số thực thô**: tỉ lệ 0,28 ra "(+28.000000000000004%)"; số nguyên vẫn có ".0" ("(+35.0%)").
30. Tên ô không thống nhất. Tự động riêng: "Lãi cơ sở" | "Giá sàn" (%). Thủ công: "Giá niêm yết" | "Giá bán sàn". Lỗi giá sàn có hai câu khác nhau: dưới ô ghi "Giá sàn phải ≤ giá niêm yết", toast ghi "Giá sàn không được lớn hơn giá niêm yết."
31. Chưa có khung giá cửa hàng: hộp vàng nhắc "thiết lập trong Cài đặt sản phẩm" nhưng không có lối sang đó.
32. Trường bổ sung kiểu có / không: dấu * là chữ thường, không đỏ như VFieldLabel.
33. Chữ phụ của các bước không đổi theo dữ liệu (không tóm tắt đã nhập gì, không có ✓), khác form KH & NCC.
34. "Huỷ" (chân màn tạo) và "Hủy" (sheet thêm ảnh) viết khác nhau.
35. Web: chân dính chỉ rộng bằng cột 720, hai bên là nền xám. Bước cuối (Ghi chú) không có nút "Tiếp".
36. Sheet "Thêm ảnh sản phẩm" trên web: hộp thoại có nút Đóng × và cả nút "Hủy", hai lối đóng. Ô lựa chọn không có ›.
37. Lưu thành công: toast "Sản phẩm đã được khởi tạo!" rồi mở PCC (vẽ ở đợt 2).

**Mã (không ảnh hưởng hình)**

38. `_onStepEntered(5)` tải lại khung giá cửa hàng khi vào bước 6, trong khi bước khung giá là chỉ số 4. Bước khung giá vẫn tự tải trong `initState` nên không thấy lỗi.

## Hiện trạng Flutter (để rà) — đợt 2

**PCC (SP-04)**

39. **Không chỗ nào trên PCC cho biết sản phẩm đang ngừng kinh doanh.** Nhãn app bar chỉ có 3 giá trị "Sẵn sàng bán" / "Thiếu dữ liệu" / "Đã xóa". Chữ phụ của khối "Nâng cao" vẫn ghi "Ngừng kinh doanh · Xoá sản phẩm" dù bên trong là "Kinh doanh lại".
40. **Nhãn và banner nói ngược nhau.** Sản phẩm chưa có ảnh: nhãn "Sẵn sàng bán" nhưng ngay dưới có banner "Cần bổ sung (1)", vì blocker ảnh không chặn bán nhưng vẫn được đếm.
41. **Lúc đang tải, nhãn là "Thiếu dữ liệu" đỏ** (kể cả sản phẩm sẵn sàng), vì `controlCenter` còn null. Lỗi tải cũng giữ nhãn đó. Mở bằng link thì tiêu đề trống.
42. Lỗi tải chỉ là một dòng chữ xám giữa màn, không icon, không nút thử lại.
43. 10 thẻ mục cùng một khuôn và cùng màu, không chia nhóm (định danh / vận hành / giá / thông tin bổ sung / ghi chú). Mỗi thẻ có nút chữ "Sửa" (dù mở màn xem, như "Xem tồn kho", "Xem"). Phụ "Khung giá" dài 2–3 dòng.
44. Thẻ tóm tắt lặp lại tồn và giá của các thẻ dưới. Tên sản phẩm in thường (không đậm), lặp lại tiêu đề app bar. Hai cách ghi tồn: "Tồn (lọ): 0 (Hết hàng)" ở tóm tắt, "0 lọ" ở thẻ Tồn kho. Chưa có đơn vị → "Tồn (cơ sở): 0".
45. Thẻ nhóm thông tin bổ sung thiếu trường bắt buộc: nền icon đỏ nhạt, nhưng câu "Thiếu thông tin bắt buộc" lại là chữ xám 12.
46. Banner "Cần bổ sung" (bo 12, đệm 16, icon 24), khối đỏ "Nâng cao" và các hộp vàng trong sheet (bo 8, đệm 12) là ba khuôn tự vẽ khác nhau, không phải VBanner.
47. **Sản phẩm đã xoá vẫn sửa được một phần.** Nút "Sửa" của 6 thẻ đầu mờ, nhưng thẻ nhóm thông tin bổ sung, Ghi chú, Lịch sử vẫn bấm được.
48. "Kinh doanh lại" trong khối Nâng cao và nút xác nhận của nó đều tô đỏ như thao tác nguy hiểm.
49. Web: PCC trong cột phải không có nút ← (đúng), nhưng iPhone dùng ← arrowBack trong khi các màn con dùng ‹.
50. iPhone: tiêu đề dài chạm sát nhãn trạng thái bên phải.

**Sheet / toast (SP-04)**

51. Ba kiểu hộp cảnh báo trong sheet: "Cần xác nhận" và "Lưu ý" có icon + gạch đầu dòng; "Readiness hiện tại" không icon, không gạch đầu dòng. Câu khôi phục có chữ tiếng Anh "readiness".
52. Sheet đệm 20 (sheet đợt 1 đệm 16). Web: hộp thoại có nút Đóng × cạnh nút "Huỷ".
53. Sheet xoá lúc kiểm tra chỉ có vòng Material + "Đang kiểm tra điều kiện..." dồn trái. Khi đang xoá: "Đang xóa...".
54. Khôi phục lỗi: câu lỗi đỏ trong sheet và toast đỏ hiện cùng lúc.
55. Lẫn "Xoá" / "Xóa": tiêu đề sheet và nút ghi "Xoá sản phẩm", toast ghi "Sản phẩm đã được xóa thành công.", nhãn ghi "Đã xóa", lịch sử ghi "Xóa mềm sản phẩm". Toast tạo dùng dấu chấm than ("đã được khởi tạo!").
56. Toast đổi trạng thái dùng một câu chung "Đã cập nhật trạng thái kinh doanh của sản phẩm." cho cả ngừng và kinh doanh lại.

**Checklist (SP-21)**

57. Ba tên cho cùng một việc: tiêu đề "Sẵn sàng vận hành", nhãn PCC "Thiếu dữ liệu", banner "Cần bổ sung". Nút ‹ (PCC dùng ←).
58. Chỉ liệt kê mục còn thiếu; không thấy mục đã xong hay tồn kho (dù `readinessView.checklist` có sẵn). Ô bo 8 (thẻ PCC bo 12).
59. Chưa có đơn vị mà bấm "Thiết lập giá" / "Thiết lập giá cơ sở" → toast vàng "Vui lòng thiết lập đơn vị cơ sở trước." thay vì dẫn sang màn đơn vị.
60. Câu "Thiếu giá" (blocker) khác "Thiếu Giá cơ sở định giá" (thẻ PCC) cho cùng một việc; "Giá cơ sở" lúc viết hoa chữ G giữa câu.

**Lịch sử thay đổi (SP-22)**

61. **"bởi 3f9a2c1b"**: người làm là 8 ký tự đầu mã người dùng (máy chủ trả `left(actor_id::text, 8)`), giống Theme 3.
62. Đổi trạng thái hiện mã thô **"active — inactive"**. Trường ẩn hiện "*** — ***". Một số dòng chỉ có tiêu đề + "bởi …", không có chi tiết.
63. Hai kiểu thẻ: khung giá dùng hàng nhãn 92 + "A → B" canh phải; thẻ khác dùng "A — B" (gạch dài) một dòng.
64. Ngày "2026-11-20 15:42" (dạng ISO); không nhóm theo ngày. Lỗi / rỗng dùng icon 48 tự xếp, không dùng VEmptyState.

## Hiện trạng Flutter (để rà) — đợt 3

**Chung cho các màn con**

65. Ba khuôn trang: VPageScaffold + chân trong `bottomBar` (Hồ sơ, Ảnh, Thông tin bổ sung, Đơn vị, Sửa khung giá) → **web có hai gạch trên chân** (gạch hết bề ngang + gạch của thanh trong cột 720); VPageScaffold + chân trong thân (Giá cơ sở, Khung giá chưa có ĐVT) → một gạch; Scaffold thường (Ghi chú) → **web không giới hạn cột**, ô và chân kéo hết 1280.
66. Nút quay lại lẫn lộn: ← arrowBack (Hồ sơ, Ảnh, Đơn vị, Giá cơ sở, Khung giá, nhóm bổ sung) và ‹ (Ghi chú; nhóm bổ sung lúc đang tải).
67. Tên sản phẩm ở dòng phụ app bar có ở 6 màn, nhưng Hồ sơ và Ảnh không có.
68. Lỗi nhập chủ yếu báo bằng toast đỏ (trùng SKU còn báo cả dưới ô và toast cùng câu). Toast lỗi nằm đè lên chân.

**Hồ sơ (SP-05)**

69. Khe giữa các ô 16 (màn tạo 12). Hai ô gạt mỗi ô một hàng (màn tạo: chung một hàng). Khoá vì "Đã có biến động kho" chỉ là câu vàng nhỏ dưới ô gạt mờ.

**Ảnh (SP-06)**

70. "Xem trước ảnh" (màn tạo: "Xem gallery"). Đang tải lên: ô "Thêm" thành vòng Material, ảnh mới không có lớp "Đang tải" như màn tạo. Không có câu "Chưa có ảnh".
71. Xoá ảnh dùng **Dialog Material** (vòng đỏ, chữ giữa) trên cả iPhone; mọi xác nhận khác của Theme 2 là sheet.
72. Gallery: nền gần đen, AppBar Material (không VAppBar), "Gallery ảnh" (tiếng Anh). "Vuốt để xem ảnh khác" nhưng web không vuốt được và không có nút trước / sau; nút "Đóng" cạnh nút ← cùng việc.

**Ghi chú (SP-07)**

73. Web không giới hạn cột (Scaffold thường) — khác mọi màn con khác. Ô 6 dòng (màn tạo 4 dòng).

**Thông tin bổ sung (SP-08)**

74. **Không hỏi khi rời** dù đã sửa (CHECKLIST ghi "hỏi khi rời"; sheet "Thoát mà không lưu?" có nhưng chỉ Cài đặt dùng).
75. Khung trắng chứa các ô không có đệm đáy; khoảng trống dưới là đệm 24 của ô cuối. Lúc tải tiêu đề tạm "Trường thông tin".

**Đơn vị (SP-09)**

76. **Thao tác đơn vị quy đổi chỉ mở bằng nhấn giữ** ("giữ để mở" chữ mờ 12). Web không có cách bấm tương đương.
77. Tên đơn vị lặp hai lần trong thẻ (tên đậm + dòng phụ cùng tên).
78. Mọi thay đổi lưu ngay khi bấm "Lưu" / "Thêm" trong thẻ; nút "Lưu thay đổi" ở chân chỉ đóng màn. Lúc nhập ĐVT cơ sở có hai nút lưu cho một việc.
79. "Chưa thiết lập (không bắt buộc)." trong khi PCC coi thiếu ĐVT cơ sở là chặn bán.
80. Nhãn CHỮ HOA ("ĐƠN VỊ CƠ SỞ", "ĐƠN VỊ QUY ĐỔI (3)") — không màn nào khác dùng. Nhãn ô là bodySmall xám (không VFieldLabel). Nút "+ Thêm…" viền tự vẽ (không VButton).
81. Màu nút không nhất quán: "Tắt" đỏ, "Bật" **cũng đỏ**, "Tắt đơn vị" trong sheet không xoá được lại **xanh**. Trạng thái tắt gọi "Đã tắt" ở đây, "Đơn vị ngừng hoạt động" / "Không hoạt động" ở Khung giá.

**Giá cơ sở (SP-11)**

82. Gợi ý "Ví dụ: 45,000" (dấu phẩy) trong khi giá hiện "80.000" (dấu chấm). Chưa có ĐVT: khung viền đứt, không có lối sang màn đơn vị; nút lưu luôn mờ.

**Khung giá (SP-12, SP-13)**

83. "Sửa" / "Thiết lập" là chữ xanh (InkWell), không phải nút, không có vùng chạm 44. Màn chỉ xem mà khi chưa có ĐVT vẫn có chân "Huỷ | Lưu thay đổi" (luôn mờ). Lỗi tải: một dòng chữ đen.
84. SP-13 cùng tiêu đề "Khung giá bán" với SP-12, không nói đang sửa đơn vị nào (chỉ "1 hộp" nhỏ).
85. Ô "Theo khung giá cửa hàng": hai hàng "Giá niêm yết 28%" / "Giá sàn 14%" rồi lặp lại nhãn "Giá niêm yết 102.400 đ" / "Giá sàn 91.200 đ". Chữ trong các ô dùng `Text()` không màu.
86. Ô % rộng cố định 120. Hộp ghi chú bo 4 (hộp khác bo 8 / 12). Bo ô 8 (thẻ PCC 12).
87. Sheet ghi đè **không có tiêu đề sheet**: tiêu đề tự vẽ trong nội dung; web là hộp thoại không tiêu đề + nút Đóng góc. "Hủy" (sheet) / "Huỷ" (chân).

## Hiện trạng Flutter (để rà) — đợt 4

**Chung**

88. Cả khu Cài đặt là route gốc ngoài khung: web mất thanh bên dù mở từ mục "Thêm" của thanh bên.
89. Nút quay lại lẫn lộn: ‹ (SP-14, 15, 16 chi tiết, 18, 19, 20) và ← arrowBack (tạo / sửa nhóm, tạo / sửa trường).
90. Tiêu đề trùng hoặc lệch tên: SP-14 "Sản phẩm" trùng danh sách sản phẩm; SP-18 "Giá sàn & Giá niêm yết" nhưng thẻ trong ghi "Khung giá cửa hàng"; SP-19 "Chỉnh sửa khung giá" (SP-13 "Khung giá bán"); SP-20 "Lịch sử thay đổi" trùng SP-22.
91. Chữ tiếng Anh: "Text", "Single select" (thẻ trường), "readiness", "blocker readiness", "field". Kiểu dữ liệu có hai bộ tên: thẻ trường "Text / Single select / Ngày tháng", ô chọn "Văn bản / Tùy chọn / Ngày".
92. Ba kiểu nhãn trạng thái cho "Đang dùng / Tạm tắt": VBadge cỡ thường (SP-15), pill tự vẽ (SP-16 chi tiết), pill nhỏ hơn (thẻ trường).
93. Dấu ngăn "•" ở Cài đặt, "·" ở PCC.
94. Ba kiểu nhãn nhóm CHỮ HOA ("TRƯỜNG THÔNG TIN", "THUỘC TÍNH", "CẤU HÌNH HIỆN TẠI", "XEM TRƯỚC VỚI VÍ DỤ") với cỡ / độ đậm khác nhau.
95. Bốn sheet xác nhận không tiêu đề sheet, tiêu đề tự vẽ trong nội dung (tạm tắt nhóm / trường, áp dụng khung giá; như ghi đè ở đợt 3); web là hộp thoại không tiêu đề + nút Đóng góc. Sheet "Thoát mà không lưu?" lại có tiêu đề sheet.
96. Lỗi tải hầu hết chỉ có toast (SP-15, 16) hoặc một dòng chữ (SP-20), không nút thử lại.

**Nhóm & trường (SP-15…17)**

97. Banner hướng dẫn kéo thả tô vàng như cảnh báo. Tay kéo ⠿ nằm trong thẻ bấm được; web không có cách đổi thứ tự bằng bàn phím.
98. SP-15: nút + trên app bar (danh sách sản phẩm dùng nút + nổi). Rỗng: "Tạo mẫu mặc định" không nói mẫu gồm gì.
99. SP-16 chi tiết: nút ⋮ mở **màn sửa nhóm** (không phải menu). "+ Thêm trường" chữ 13 không vùng chạm 44; khi rỗng còn thêm nút "+ Thêm trường thông tin" (hai lối).
100. Tạo / sửa nhóm: lưới emoji 8 cột (30 emoji gồm 🐄 🐖 🏭…); web cột 720 → ô ~80 px. "Tên nhóm *": dấu * là chữ trong nhãn, cùng màu đen. "Mô tả (tuỳ chọn)" (chữ "tuỳ"), nơi khác "tùy".
101. Switch Material tự cấu hình (tắt nền borderStrong) ở Cài đặt; VSwitch (tắt nền borderInput đậm hơn) ở màn sản phẩm — hai kiểu ô gạt.
102. Tạo / sửa trường: ô "Nhóm" tắt mờ chỉ để xem. "Không đổi được kiểu dữ liệu…" nhưng ô chọn kiểu vẫn trông bấm được. "+ Thêm" tùy chọn là TextButton màu mặc định.
103. Bật "Bắt buộc" mở **Dialog** VConfirmDialog (cả iPhone; hai nút cỡ nội dung canh phải) — tạm tắt thì là sheet. Hai khuôn xác nhận trong cùng màn.
104. "Thoát mà không lưu?" / "Ở lại" | "Thoát" — Theme 3 dùng "Rời khỏi màn hình?" / "Ở lại chỉnh sửa" | "Rời khỏi". Màn nhập thông tin bổ sung của sản phẩm (SP-08) thì không hỏi.

**Khung giá cửa hàng (SP-18…20)**

105. **Giá sàn tô đỏ + icon đi xuống** ("14.0%") dù giá sàn vẫn cao hơn giá cơ sở; giá niêm yết có "+", giá sàn không. Xem trước "Giá sàn (dự kiến)" cũng đỏ.
106. 4 khung trên SP-18 mỗi khung một kiểu (giới thiệu, cấu hình, lưu ý vàng, lịch sử). Hộp icon "Lịch sử thay đổi" nền xanh nhạt, hộp icon ở SP-14 nền trắng (vô hình trên thẻ trắng).
107. Lỗi tải SP-18: banner đỏ + toast đỏ cùng lúc, phần dưới vẫn hiện "—" như chưa cấu hình. "Thử lại" là TextButton màu mặc định.
108. SP-19: ô % là **ô nhiều dòng** (cao 2 dòng) cho một con số; 2 nút ▲ ▼ 36 (dưới 44), bước 0,1. Câu "Tính theo % trên Giá cơ sở" **hiện hai lần**.
109. Nhãn ô SP-19 "Giá niêm yết (tỷ lệ lãi)" / "Giá sàn (tỷ lệ sàn)"; SP-13 "Tỷ lệ giá niêm yết"; màn tạo "Lãi cơ sở" / "Giá sàn" — ba cách gọi một tham số.
110. Lưu SP-19 → sheet "Áp dụng quy tắc lên sản phẩm đã có giá?" nút "Áp dụng" xanh, dù đổi giá hàng loạt. "Hủy" (sheet) / "Huỷ" (chân).
111. SP-20: "**Bởi: 3f9a2c1b**" (SP-22 "bởi …" chữ thường); ngày ISO; giá trị trước → sau nằm dòng nhỏ canh phải dưới mỗi hàng. Rỗng "Chưa có lịch sử thay đổi" (SP-22 "… thay đổi nào").
112. SP-14: hai thẻ đều 2 dòng mô tả bị cắt "…" nếu dài; thứ tự giá trước, nhóm trường sau (khác thứ tự trên PCC).

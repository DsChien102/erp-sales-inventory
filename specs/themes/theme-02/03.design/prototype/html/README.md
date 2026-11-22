# Prototype Theme 2 (TH-02) — Sản phẩm & giá bán (10-8)

HTML/CSS/JS thuần (ES module, không build). Vẽ **đúng Flutter hiện tại** của các màn TH-02 ở cả iPhone 390 và Web 1280. Trên web, danh sách và PCC chia 2 cột như 5-W. Mục đích: để người dùng rà bằng impeccable (bước 3 của 10-8). Chép y nguyên chữ, thứ tự, số đo DS; **không thiết kế lại**. Sheet, hộp thoại, toast là ca riêng.

Làm theo 4 đợt, mỗi đợt một commit. Cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Danh sách & tạo | SP-01 Danh sách, SP-02 Lọc thông tin bổ sung, SP-03 Tạo nhanh (7 bước) + sheet "Thêm ảnh sản phẩm" | ✅ 46 ca × 2 khổ |
| 2 · PCC | SP-04 (khối Theme 7: thẻ Tồn kho chỉ xem, ô gạt "Quản lý theo lô"), sheet vòng đời / xoá / khôi phục, SP-21 Checklist, SP-22 Lịch sử thay đổi | ⬜ |
| 3 · Màn con | SP-05 Hồ sơ, SP-06 Ảnh, SP-07 Ghi chú, SP-08 Thông tin bổ sung, SP-09 Đơn vị (+ hộp thoại), SP-11 Giá cơ sở, SP-12 / 13 Khung giá | ⬜ |
| 4 · Cài đặt sản phẩm | SP-14 … SP-20 | ⬜ |

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
| `app/main.js` | Ca → trạng thái. Khu Sản phẩm: web chia 2 cột (`VListDetailLayout` 360 / 840), sheet web phủ cả cửa sổ, sheet iPhone chỉ phủ vùng tab. Màn tạo nằm ngoài khung |
| `styles/t2.css` | Rule tiền tố `t2-`, token `--c45-v2-*`; đầu file có bảng màu và cỡ chữ Flutter → token |
| `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Trang xem và chụp ảnh, chép khuôn Theme 3 (cổng 8772) |
| `shared/icons.js` | Thêm `image`, `imageOff`, `camera`, `images` (photo_library), `folder`, `qrScan` (qr_code_scanner), `externalLink` (open_in_new), `moreVert`, `ban` (block) |

Ảnh sản phẩm: Flutter tải ảnh thật từ Storage. Prototype không có ảnh thật nên vẽ ảnh minh hoạ SVG (nền màu + hình hộp), cùng khổ và cùng bo góc.

Có 3 bản `ds.js` (Theme 1, 3, 2). Gom về `shared/` để làm sau. Đến lúc đó, sửa một widget DS phải sửa ở cả ba nơi.

## Nguồn Flutter

| Màn | Flutter (`apps/erp/lib/features/catalog/`) |
|---|---|
| Khu Sản phẩm | `presentation/product_area_shell.dart` (`VListDetailLayout`), `core/router/app_router.dart` (ShellRoute khu sản phẩm, cột phải khi chưa chọn, `/products/items/new` ngoài khung) |
| SP-01 | `pages/product_catalog_tab_page.dart`, `widgets/{product_list_search_bar, product_catalog_filter_chips, product_list_filter, product_catalog_list_body, product_list_item_tile, product_list_item_skeleton_tile}.dart`, `logic/product_list_cubit.dart`, `data/models/product_search.dart` |
| SP-02 | `widgets/custom_field_filter_sheet.dart` |
| SP-03 | `pages/product_guided_create_page.dart`, `widgets/{product_guided_create_body, product_guided_fields, product_guided_step_identification, product_guided_step_images, product_guided_step_base_unit, product_guided_step_base_cost, product_guided_step_price_bands, product_guided_step_custom_fields, product_guided_step_note, product_image_picker_panel, tenant_measurement_unit_search_field}.dart`, `widgets/image_picker/{product_image_grid_item, product_image_add_sheet}.dart`, `widgets/custom_fields/product_custom_field_input_widget.dart`, `logic/{product_guided_create_state, product_guided_create_cubit}.dart`, `presentation/mappers/guided_price_band_submission_resolver.dart` |

## Hiện trạng Flutter (để rà) — đợt 1

**Danh sách (SP-01)**

1. **Cột tồn trên thẻ luôn trống.** `ProductListItemDto` có `stockLabel` nhưng `ProductListItemReadRow` không đọc nó (`search_products` không trả), nên `_buildStockInfo` không vẽ gì. "Chưa TL tồn" cũng không bao giờ hiện, vì `stock_qty` là `coalesce(available, 0)`, không bao giờ null.
2. Thẻ không cho biết sản phẩm **đang ngừng kinh doanh** hay **sẵn sàng bán / thiếu dữ liệu**. Chỉ sản phẩm đã xoá có nhãn ("Đã xóa", xám nhỏ).
3. Chip "Còn hàng" / "Hết hàng" lọc **cục bộ** trên các dòng đã tải (trang đầu 20 dòng), không gọi máy chủ. "Hết hàng" gồm cả sản phẩm ngừng kinh doanh.
4. Số trên chip không đều. "Tất cả / Sẵn sàng bán / Thiếu dữ liệu / Ngừng KD" có số. "Còn hàng / Hết hàng" chỉ có số khi danh sách không lọc đã tải hết. "Đã xóa" chỉ có số khi đang ở chip đó. Số chỉ cập nhật khi tải danh sách không lọc.
5. Nút ⋮ trên app bar bấm không làm gì (`onPressed: () {}`).
6. **Lỗi tải chỉ là một dòng chữ đỏ** "Lỗi: Đã xảy ra lỗi. Vui lòng thử lại." (chữ "lỗi" lặp lại). Không icon, không nút thử lại. Kéo để tải lại cũng không được, vì `RefreshIndicator` chỉ bọc danh sách có dữ liệu.
7. Không có màn "không có quyền xem". Không có quyền thì ra dòng đỏ "Lỗi: Bạn không có quyền thực hiện thao tác này.", còn ô tìm, chip và nút + vẫn hiện. Nút + không kiểm quyền tạo.
8. Câu khi rỗng không xét từ khoá. Tìm không ra ở chip "Tất cả" → "Không tìm thấy sản phẩm" + "Hãy thử … hoặc tạo sản phẩm mới.", nhưng không có nút (không "Xóa từ khóa", không "Tạo sản phẩm"). Tìm không ra ở chip khác → "Không có sản phẩm "Thiếu dữ liệu"" (ngoặc kép lồng). "Không có sản phẩm đã xóa." có dấu chấm cuối, các câu rỗng khác không có.
9. Chưa có sản phẩm nào: nút "+ Tạo sản phẩm" giữa màn và nút + nổi cùng hiện, hai lối cho cùng một việc.
10. Không có hàng đầu danh sách (số kết quả, sắp xếp) như KH & NCC. Khi tìm, app bar vẫn ghi tổng toàn bộ.
11. Thiếu giá hiện "_" (gạch dưới), thiếu ĐVT hiện "–" (gạch ngang). ĐVT bị viết thường ("hộp"). Giá là giá sau VAT nhưng không ghi.
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

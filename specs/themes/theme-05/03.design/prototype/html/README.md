# Prototype Theme 5 (TH-05): Bán hàng & đơn hàng (10-8)

Prototype viết bằng HTML/CSS/JS thuần (ES module, không cần build). Nó vẽ **đúng Flutter hiện tại** của các màn TH-05, ở cả iPhone 390 và Web 1280, để người dùng rà bằng impeccable (bước 3 của 10-8). Chữ, thứ tự và số đo DS chép y nguyên; **không thiết kế lại**. Mỗi sheet, bàn phím số, toast là một ca riêng.

`/sales/drafts` và `/sales/compose` nằm trong `TypedShellRoute` riêng của Sales (`SalesDraftListScope`), mọi `/sales/*` khác là GoRoute cấp gốc. Tất cả đều **nằm ngoài `StoreShell`**, nên cả hai khổ đều không có thanh bên hay thanh dưới. Web chỉ có một cột 720 giữa nền xám. Chỉ SG-08 `/orders` (đợt 3) nằm trong khung.

Làm 4 đợt, mỗi đợt một commit. Cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Lập đơn | SG-01 Đơn nháp (+ sheet xoá), SG-02 Soạn đơn (+ menu tìm sản phẩm, sheet rời màn, bàn phím số lượng, toast), SG-03 Chọn đơn vị bán, SG-04 Chọn khách + Tạo nhanh khách (+ bỏ thay đổi, trùng SĐT), SG-05 Điều chỉnh giá (+ bàn phím, 2 sheet xác nhận) | ✅ 63 ca × 2 khổ |
| 2 · Thanh toán & kết quả | SG-06 Thanh toán, SG-07 Kết quả (+ HD-06), SG-16 phiếu bán | ⬜ |
| 3 · Tra cứu đơn | SG-08 Đơn hàng (+ lọc), SG-09 Chi tiết (+ thao tác), SG-09b / 09c / 09d, SG-10 Huỷ | ⬜ |
| 4 · Đổi / trả | SG-12, SG-13 (+ cấn trừ), SG-14, SG-15, SG-16 phiếu đổi/trả | ⬜ |

SG-11 (Thu tiền) đã gỡ khỏi Flutter ở T6-2c (thu sau bán chuyển sang CN-03), nên không vẽ. Phần của theme khác mà Flutter đang hiện (HD-06, khối cấn trừ, "Xem công nợ của khách") vẽ đúng như Flutter.

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/themes/theme-05/03.design/prototype/html
python3 tools/serve.py &    # cổng 8775, tắt cache
# trang xem: http://127.0.0.1:8775/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=compose&state=filled&device=web
node --test                 # hàm thuần đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # mọi ca × 2 khổ → tools/proto-final/{iphone,web}/<màn>__<ca>.png (không vào git)
```

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/cases.js` | Nhóm (đợt), màn, ca, kèm điều cần nhìn của từng ca |
| `app/ds.js` | Widget DS, **chép từ Theme 4** (`theme-04/app/ds.js`, đổi `t4-` → `t5-`). Thêm: `buttonLg` (VButton large 52), `tabs` (VTabs line), `cardHeader` / `cardContent` (VCardHeader / VCardContent), `segmented` (VSegmentedControl), `keypadSheet` (VNumericKeypadSheet), `fieldDesc`, `radioLabel`, `smallLoading`; `bottomSheet` thêm `tone` (màu tay kéo) và `height` (SizedBox cố định). Icon `badgePercent` / `qrCode` để cục bộ (`LOCAL_ICONS`) |
| `app/data.js` | Nháp, sản phẩm, dòng đơn, khách mẫu (cửa hàng thú y như Theme 2 / 3 / 4); `money` (MoneyFormatter), `moneyComma` (VMoneyValidator), `draftTimestamp`, `customerSubtitle`, `totals` |
| `app/drafts.js` | SG-01 + sheet xoá; hàm thuần `creatorLabel`, `phoneLine`, `draftSummary` |
| `app/compose.js` | SG-02 + menu tìm, sheet rời màn, bàn phím số lượng; hàm thuần `stockWarning`, `unitPriceLabel`, `ribbon` (dải chéo giá riêng) |
| `app/sheets.js` | SG-03, SG-04 (chọn + tạo nhanh + 2 sheet phụ), SG-05 (+ bàn phím, 2 sheet xác nhận); hàm thuần `unitSubtitle`, `previewApplied` |
| `app/main.js` | Ca → trạng thái; mọi màn đợt 1 vẽ ngoài khung |
| `styles/t5.css` | Phần DS chép từ `t4.css`, rồi tới rule riêng Theme 5 (tiền tố `t5-`, token `--c45-v2-*`) |
| `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Trang xem và chụp ảnh, chép khuôn Theme 4 (cổng 8775) |

Có 5 bản `ds.js` (Theme 1, 3, 2, 4, 5). Việc gom về `shared/` để sau.

## Nguồn Flutter

| Màn | Flutter (`apps/erp/lib/features/sales/presentation/`) |
|---|---|
| SG-01 | `pages/sales_draft_list_page.dart`, `widgets/{sales_draft_list_body, sales_draft_list_card, sales_draft_list_card_skeleton, sales_draft_list_empty_state, sales_draft_list_error_state, sales_draft_list_no_result_state, sales_draft_list_search_bar, sales_draft_discard_dialog}.dart`, `models/sales_order_draft/sales_draft_list_item_vm.dart`, `logic/sales_draft_list_cubit.dart` (câu lỗi) |
| SG-02 | `pages/sales_order_compose_page.dart`, `widgets/{sales_compose_form_body, sales_compose_customer_card, sales_compose_product_search_bar, sales_compose_lines_section, sales_order_line_row, sales_order_line_quantity, sales_special_price_banner, sales_product_thumbnail, sales_amount_highlight_row, sales_label_highlight_row, sales_compose_order_note_tile, sales_compose_summary_bar, sales_compose_leave_sheet}.dart`, `support/sales_barcode_search_hint.dart`, `models/sales_order_draft/{sales_compose_line_vm, compose_line_stock_hint}.dart`, `bloc/sales_order_draft/sales_compose_state.dart` |
| SG-03 | `widgets/sales_product_unit_sheet.dart` |
| SG-04 | `widgets/{sales_customer_select_sheet, sales_customer_picker_body, sales_customer_picker_card, sales_customer_picker_loading_state, sales_customer_picker_search_bar, sales_customer_picker_body_empty_state, sales_customer_picker_body_no_result_state, sales_customer_picker_body_error_state, sales_customer_quick_create_sheet}.dart`, `bloc/shared/sales_customer_picker_cubit.dart`, `lookups/sales_partner_customer_lookup.dart` (dòng phụ) |
| SG-05 | `widgets/sales_compose_price_adjust_sheet.dart` |
| Khung | `navigation/sales_typed_routes.dart` (`SalesDraftShellRoute`), `c45_design_system` `VPageScaffold`, `showVBottomSheet`, `showVNumericKeypadSheet`, `VSwipeReveal`, `VTabs`, `VSegmentedControl` |

## Hiện trạng Flutter (để rà): đợt 1

**Chung**

1. Mọi màn đợt 1 nằm ngoài khung: không thanh bên (web) hay thanh dưới (iPhone). Web chỉ một cột 720, không bố cục 2 cột kiểu "danh sách món | giỏ hàng" cho bán tại quầy.
2. Mọi sheet dùng `showVBottomSheet` / `showModalBottomSheet`, nên web cũng là sheet đáy rộng 640, không thành hộp thoại.
3. Sheet có 3 kiểu đầu: không tiêu đề, chữ tiêu đề tự vẽ trong nội dung (H4 w700: "Chọn đơn vị bán", "Chọn khách hàng", "Đơn có thay đổi chưa lưu"; H3 w700: "Điều chỉnh giá", "Xóa đơn nháp?"); hàng tiêu đề + nút × ("Tạo nhanh khách hàng"). Không sheet nào dùng tham số `title` của VBottomSheet.
4. Tiền "125.000đ" (không dấu cách); ô nhập giá và bàn phím số dùng dấu phẩy "16,000".
5. Hai lối thao tác chính của dòng hàng và của thẻ nháp (điều chỉnh giá, xoá) chỉ có qua **vuốt trái**; không có nút nhìn thấy. Trên web vuốt bằng chuột không tự nhiên.

**Đơn nháp (SG-01)**

6. Thẻ nháp viền `borderDefault` (nhạt), trong khi VCard ở chỗ khác viền `borderStrong`.
7. Badge "Cần kiểm tra" chỉ hiện khi cần kiểm tra; nháp bình thường không có nhãn trạng thái.
8. Mốc giờ "18/11" không có năm; nháp cũ hơn một năm không phân biệt được.
9. Tab "Tất cả đơn nháp" ẩn người tạo khi tên người tạo có dạng SĐT hoặc UUID, nên một số nháp không biết ai tạo.
10. Chưa có nháp: nút "Tải lại" **luôn mờ** vì `onRetry` không được truyền.
11. Lỗi tải: tiêu đề "Không thể tải đơn nháp" và mô tả "Không thể tải danh sách đơn nháp" lặp ý. Icon là dấu × (VIcons.close), không phải icon lỗi.
12. Không có quyền: câu xưng "Anh/chị", các màn khác xưng "Bạn". FAB "+" vẫn hiện.
13. Lỗi tải thêm dùng `TextButton.icon` Material chữ 13, không phải VButton. Tải thêm dùng `CircularProgressIndicator.adaptive` (iOS là vòng Cupertino).
14. Sheet xoá: "Xóa" là nút viền đỏ (secondary danger) đặt **trên** "Quay lại", hai nút cùng kiểu viền, cao 52 (sheet khác 44).

**Soạn đơn (SG-02)**

15. Tiêu đề luôn "Tạo đơn hàng", kể cả khi mở lại một nháp; không thấy đang sửa nháp nào.
16. Nút quay lại là ô VIconBox 40 (lúc soạn), nhưng là nút ← 48 khi đang tải nháp.
17. Dòng có giá riêng / chỉnh tay chỉ có **dải chéo xanh "%" ở góc ảnh**; không ghi giá niêm yết, số giảm hay nguồn giá. Cùng một dấu cho giá riêng của khách, giá chỉnh tay và mọi trường hợp giá áp ≠ niêm yết.
18. Ô số lượng nằm ở hàng thứ hai (dưới tên), ô chạm 34 (dưới 44), ô số 30 × 20 chữ 13.
19. Cảnh báo tồn "Chỉ còn 2 Chai" là chữ 11 px; "Hết hàng" vẫn để số lượng 1, không chặn ở màn này.
20. Thẻ tóm tắt: nhãn "Tổng tiền hàng (3 sản phẩm)" và "Giảm giá" dùng **chữ mono** (`bodySmallMono`); số 3 là số dòng, không phải tổng số lượng.
21. "Thành tiền" trong thẻ và "Khách phải trả" ở thanh dưới là cùng một số, hiện hai lần.
22. Thẻ ghi chú ghim dưới vùng danh sách; danh sách và thẻ tóm tắt cuộn trong phần giữa, nên iPhone chỉ còn ~3 dòng nhìn thấy khi đơn dài. Mở ghi chú lại chiếm thêm chỗ.
23. Gợi ý sản phẩm: menu rộng cả hàng (lấn dưới nút quét); tồn chỉ là con số trần ("42"), đơn vị cơ sở lặp 2 lần trên thẻ. Sản phẩm nhiều đơn vị chỉ hiện giá đơn vị cơ sở.
24. Lỗi tìm sản phẩm hiện **chuỗi thô của exception** (`error.toString()`); nút "Thử lại" chữ xanh trong khối đỏ.
25. Nút quét mã không mở camera, chỉ hiện toast hướng dẫn gõ barcode.
26. Lưu nháp xong màn chuyển sang **đơn mới trống**, không ở lại đơn vừa lưu.
27. Toast "Chưa thể thanh toán" chỉ hiện lý do (tiêu đề không hiện), không chỉ ra dòng nào gây chặn. Toast "Số lượng vượt quá tồn khả dụng" không nói còn bao nhiêu.
28. Đổi khách: câu "Đã đổi khách — đang làm mới giá" là chữ vàng 13 trơn (không banner), dù banner "Khách tổ chức chưa có mã số thuế" ngay trên là VBanner.
29. Sheet rời màn: 3 thẻ lựa chọn, không có nút đóng; thẻ "Bỏ thay đổi và đóng" nền đỏ nhạt.
30. Bàn phím số tự vẽ: tay kéo 48 × 4 màu nhạt (các sheet khác 36 × 4 đậm hơn), tiêu đề H3 w600 (sheet khác w700). Không ghi tồn tối đa khi nhập số lượng.

**Chọn đơn vị (SG-03)**

31. Sheet cao cố định 1/3 màn (iPhone 281, web 267), không theo số đơn vị: 3 đơn vị đã phải cuộn.
32. Sheet không ghi tên sản phẩm đang chọn đơn vị.
33. Phải chạm thẻ rồi bấm "Xác nhận" (2 bước).

**Chọn / tạo khách (SG-04)**

34. Thẻ khách lặp "Khách hàng" ở gần mọi dòng (vai trò); NCC thuần không SĐT ra "—". Khách ngừng hoạt động vẫn nằm trong danh sách, chỉ mờ chữ.
35. Lỗi tải khách **không có nút Thử lại**.
36. Số đếm "2 kết quả · “an”" dùng ngoặc kép cong; SG-01 dùng ngoặc đơn thẳng `'xyz'`.
37. Tạo nhanh: SĐT bắt buộc (TH-03 cho phép trống); khe giữa các ô 8 (form khác 16); câu dẫn chữ đen bodySmall. Không đóng được bằng chạm ngoài sheet.
38. Lỗi tạo khách: banner đỏ chèn ngay trên nút, ngoài vùng cuộn.
39. Sheet "Bỏ thay đổi chưa lưu?" có tay kéo đỏ (tone danger) — sheet duy nhất như vậy; sheet xác nhận dưới sàn (tone warning) vẫn tay kéo xám.

**Điều chỉnh giá (SG-05)**

40. Lối vào duy nhất là ô "Chiết khấu" khi vuốt dòng (chỉ icon nhãn).
41. Thẻ sản phẩm **luôn ghi "Giá riêng áp dụng"** kể cả khi chỉ là giá niêm yết.
42. **Không hiện giá sàn** cho tới khi nhập dưới sàn (TH-05 US-01.4 FR-02 yêu cầu hiện "Giá sàn hiện tại" ngay).
43. "Giảm tiền" / "Giảm %" tính trên **giá niêm yết**, không trên giá đang áp; sheet không xem trước giá sau giảm.
44. Banner "Dưới giá sàn" dính sát ô tích "Lưu làm giá riêng" (không khe).
45. Khách lẻ: ô tích mờ + thêm câu "Chọn khách hàng để lưu giá riêng." dưới câu mô tả, hai câu xám liền nhau.
46. Giảm % có phím "." nhưng giá trị bị làm tròn về số nguyên.

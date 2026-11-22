# Prototype Theme 5 (TH-05): Bán hàng & đơn hàng (10-8)

Prototype viết bằng HTML/CSS/JS thuần (ES module, không cần build). Nó vẽ **đúng Flutter hiện tại** của các màn TH-05, ở cả iPhone 390 và Web 1280, để người dùng rà bằng impeccable (bước 3 của 10-8). Chữ, thứ tự và số đo DS chép y nguyên; **không thiết kế lại**. Mỗi sheet, bàn phím số, toast là một ca riêng.

`/sales/drafts` và `/sales/compose` nằm trong `TypedShellRoute` riêng của Sales (`SalesDraftListScope`), mọi `/sales/*` khác là GoRoute cấp gốc. Tất cả đều **nằm ngoài `StoreShell`**, nên cả hai khổ đều không có thanh bên hay thanh dưới. Web chỉ có một cột 720 giữa nền xám. Chỉ SG-08 `/orders` (đợt 3) nằm trong khung.

Làm 4 đợt, mỗi đợt một commit. Cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Lập đơn | SG-01 Đơn nháp (+ sheet xoá), SG-02 Soạn đơn (+ menu tìm sản phẩm, sheet rời màn, bàn phím số lượng, toast), SG-03 Chọn đơn vị bán, SG-04 Chọn khách + Tạo nhanh khách (+ bỏ thay đổi, trùng SĐT), SG-05 Điều chỉnh giá (+ bàn phím, 2 sheet xác nhận) | ✅ 63 ca × 2 khổ |
| 2 · Thanh toán & kết quả | SG-06 Thanh toán (+ sheet hoàn tất, bàn phím tiền, toast, trang không hợp lệ), SG-07 Kết quả (+ sheet phiếu, dòng HĐĐT mặc định / dự phòng), SG-16 xem trước phiếu bán hàng (trang A5 vẽ lại bằng HTML) | ✅ 40 ca × 2 khổ |
| 3 · Tra cứu đơn | SG-08 Đơn hàng (+ sheet lọc; trong khung), SG-09 Chi tiết (+ sheet Thao tác, sheet phiếu, toast), SG-09b Thanh toán & công nợ, SG-09c Lịch sử, SG-09d Phiếu đổi/trả của đơn, SG-10 Huỷ đơn | ✅ 55 ca × 2 khổ |
| 4 · Đổi / trả | SG-12 Lập phiếu (+ sheet chọn hàng đổi, bỏ thay đổi), SG-13 Quyết toán (+ nhánh khách được hưởng / cấn trừ, sheet xác nhận, hộp công nợ thay đổi), SG-14 Kết quả, SG-15 Chi tiết phiếu (+ sheet phiếu), SG-16 phiếu đổi/trả | ✅ 50 ca × 2 khổ |

SG-11 (Thu tiền) đã gỡ khỏi Flutter ở T6-2c (thu sau bán chuyển sang CN-03), nên không vẽ. Phần của theme khác mà Flutter đang hiện (HD-06, khối cấn trừ, "Xem công nợ của khách") vẽ đúng như Flutter. Dòng HĐĐT (HD-06) trên SG-07 / SG-09 chỉ vẽ trạng thái mặc định, "Chưa đủ thông tin" và thẻ dự phòng; 4 trạng thái phát hành và các sheet HĐĐT đã vẽ ở prototype Theme 8 đợt 2 (`theme-08/…/app/order.js`). Prototype Theme 8 đợt 2 cũng vẽ lại SG-09 (`detailHost`) nhưng lệch Flutter ở hai chỗ: dòng "Đã thanh toán / Còn phải thu" chữ thường (Flutter chữ vàng w600) và icon dòng Hộp dùng `inventory` của `shared/` (Flutter: Lucide box). Bản ở đây theo Flutter.

Đánh số: key trong Dart dùng `sg05` cho Thanh toán, `sg06` cho Kết quả, `sg07` / `e03_u01` cho Đơn hàng, `sg08` cho Chi tiết đơn, `sg11` cho Lập phiếu đổi/trả, `sg12` cho Quyết toán, `sg13` cho Kết quả / Chi tiết phiếu / phiếu đổi trả (số cũ); prototype theo TH-05 / CHECKLIST: SG-06 Thanh toán, SG-07 Kết quả, SG-08 Đơn hàng, SG-09 Chi tiết, SG-12 … SG-16 đổi / trả. Prototype Theme 8 ghi trang Kết quả là "SG-06" và Chi tiết đơn là "SG-08" theo số cũ.

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
| `app/ds.js` | Widget DS, **chép từ Theme 4** (`theme-04/app/ds.js`, đổi `t4-` → `t5-`). Thêm: `buttonLg` (VButton large 52), `tabs` (VTabs line), `cardHeader` / `cardContent` (VCardHeader / VCardContent), `segmented` (VSegmentedControl), `keypadSheet` (VNumericKeypadSheet), `fieldDesc`, `radioLabel`, `smallLoading`; `bottomSheet` thêm `tone` (màu tay kéo) và `height` (SizedBox cố định). Icon `badgePercent` / `qrCode` để cục bộ (`LOCAL_ICONS`); đợt 3 thêm `banknoteArrowDown`, `fileXCorner`, `circleX` (VIcons.error), `box` (VIcons.inventory = Lucide box); đợt 4 thêm `MATERIAL_ICONS` (Flutter `Icons.*_outlined`: inventory_2, local_pharmacy, image, search_off, error_outline — tô đặc) và `banner(…, { trailing })` |
| `app/data.js` | Nháp, sản phẩm, dòng đơn, khách mẫu (cửa hàng thú y như Theme 2 / 3 / 4), thẻ đơn SG-08 (`ORDERS`, đơn đầu = DH-000130 của SG-07); `money` (MoneyFormatter), `moneyComma` (VMoneyValidator), `draftTimestamp`, `customerSubtitle`, `totals`, `orderMetaLine` |
| `app/drafts.js` | SG-01 + sheet xoá; hàm thuần `creatorLabel`, `phoneLine`, `draftSummary` |
| `app/compose.js` | SG-02 + menu tìm, sheet rời màn, bàn phím số lượng; hàm thuần `stockWarning`, `unitPriceLabel`, `ribbon` (dải chéo giá riêng) |
| `app/sheets.js` | SG-03, SG-04 (chọn + tạo nhanh + 2 sheet phụ), SG-05 (+ bàn phím, 2 sheet xác nhận); hàm thuần `unitSubtitle`, `previewApplied` |
| `app/checkout.js` | SG-06 + sheet hoàn tất, bàn phím tiền, trang không hợp lệ; hàm thuần `checkoutVm`, `mixedDefault`, `percentIndex`, `digitsDot` |
| `app/result.js` | SG-07 + sheet phiếu; SG-16 (`receiptPaper` vẽ trang A5 theo `SalesReceiptPdfGenerator`, đơn vị pt rồi phóng theo bề rộng PdfPreview); hàm thuần `methodText` |
| `app/orders.js` | SG-08 (trong khung: `contentWidth` = cửa sổ − thanh bên 240) + sheet lọc (vẽ trong vùng nội dung, không phải overlay của khung); hàm thuần `activeFilterCount`, `noResultDescription`, `listCustomerLabel` |
| `app/detail.js` | SG-09 (ca đã tải + 5 trang trạng thái), sheet "Thao tác", SG-10; hàm thuần `productIcon`, `diffText`, `cancelImpact`, `cancelSubtitle` |
| `app/subpages.js` | SG-09b, SG-09c, SG-09d; hàm thuần `paidMethodRows`, `transactionLabel`, `displayActorName` |
| `app/returns.js` | SG-12 (+ sheet chọn hàng đổi, "Bỏ thay đổi?"), SG-13 (+ sheet xác nhận, hộp công nợ thay đổi); hàm thuần `expectedSummary`, `pickerStockLabel`, `planReturnSettlement`, `orderDueLabel`, `confirmationMessage`, `entitledLines`, `signedMoney`, `formatVnd`. Nhánh "khách được hưởng" dựng theo Flutter; thiết kế gốc ở prototype Theme 6 `app/sg13.js` |
| `app/returnview.js` | SG-14, SG-15, SG-16 phiếu đổi/trả (`returnSlipPaper` theo `SalesSlipPdfGenerator`); hàm thuần `resultSettlementLines`, `detailBanner`, `settlementRows`, bảng `STATUS` |
| `app/main.js` | Ca → trạng thái; mọi màn vẽ ngoài khung trừ SG-08 `/orders` |
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
| SG-06 | `pages/{sales_checkout_page, sales_checkout_invalid_entry_page}.dart`, `widgets/{sales_checkout_summary_card, sales_checkout_payment_method_selector, sales_checkout_percent_row, sales_checkout_receivable_card, sales_checkout_finalize_sheets}.dart`, `models/sales_order/sales_checkout_vm.dart`, `logic/sales_checkout_cubit.dart` |
| SG-07 | `pages/{sales_transaction_result_page, sales_result_invalid_entry_page}.dart`, `widgets/{sales_transaction_result_body, sales_result_header_card, sales_result_customer_card, sales_result_partial_banner, sales_result_payment_summary_card, sales_result_documents_section, sales_receipt_entry_card, sales_einvoice_entry_card, sales_entry_row, sales_result_loading_view, sales_result_failure_view, sales_transaction_result_action_bar, sales_result_receipt_sheet, sales_document_action_sheet}.dart`; HD-06 `features/einvoice/presentation/widgets/order_einvoice_row.dart` |
| SG-16 | `pages/{sales_order_slip_preview_page, sales_receipt_preview_page}.dart`, `support/sales_receipt_pdf_generator.dart` (PdfPreview của gói `printing`: lề trang 20 / 8 / 20 / 12, bóng 0 3 5) |
| SG-08 | `pages/sales_order_list_page.dart`, `widgets/{sales_order_list_body, sales_order_list_card, sales_order_list_search_bar, sales_order_saved_search_chips, sales_order_list_empty_state, sales_order_list_no_result_state, sales_order_list_error_state, sales_order_list_blocked_state, sales_order_filter_bottom_sheet}.dart`, `models/sales_order/{sales_order_list_item_vm, sales_order_saved_search_preset}.dart`, `support/sales_order_list_mapper.dart`, `logic/sales_order_list_{cubit,state}.dart`; khung `features/dashboard/presentation/store_shell.dart` |
| SG-09 | `pages/sales_order_detail_page.dart`, `widgets/{sales_order_detail_body, sales_detail_header_card, sales_detail_action_bar, sales_order_detail_cancel_reason_card, sales_order_detail_payment_summary_card, sales_order_detail_products_section, sales_order_detail_grouped_surface, sales_order_detail_documents_section, sales_order_detail_returns_section, sales_order_detail_history_entry, sales_order_detail_error_state, sales_order_actions_sheet}.dart`, `support/sales_order_detail_mapper.dart`, `models/sales_order_settlement/sales_order_payment_vm.dart`, `logic/{sales_order_detail_post_sale_actions, sales_post_sale_error_messages}.dart`; HD-06 `features/einvoice/presentation/widgets/order_einvoice_row.dart` |
| SG-09b / c / d | `widgets/{sales_order_payment_debt_page, sales_order_history_page, sales_order_return_list_page, sales_label_highlight_row}.dart` (đẩy bằng `MaterialPageRoute`) |
| SG-12 | `pages/sales_return_exchange_create_page.dart`, `widgets/{sales_return_exchange_session_body, sales_return_exchange_session_line_rows, sales_order_line_quantity, sales_exchange_product_picker_sheet, sales_return_discard_dialog}.dart`, `logic/sales_return_exchange_session_{cubit,state}.dart`, `support/sales_return_exchange_pricing_copy.dart` |
| SG-13 | `pages/sales_return_exchange_settlement_page.dart`, `widgets/{sales_return_exchange_settlement_body, sales_return_entitled_settlement, sales_return_confirm_settlement_sheet, sales_receivable_changed_dialog}.dart`, `logic/{sales_return_exchange_settlement_cubit, sales_return_exchange_settlement_state, return_settlement_preview}.dart`, `features/receivable/{logic/receivable_format, presentation/widgets/receivable_parts}.dart` |
| SG-14 | `pages/sales_return_exchange_result_page.dart`, `widgets/{sales_return_exchange_result_body, sales_return_result_action_bar}.dart` |
| SG-15 | `pages/sales_return_exchange_detail_page.dart`, `widgets/{sales_return_exchange_detail_body, sales_return_exchange_detail_header_card, sales_return_exchange_source_order_card, sales_return_exchange_detail_lines_section, sales_return_exchange_detail_summary_card, sales_order_return_slip_sheet}.dart`, `logic/sales_return_exchange_detail_cubit.dart` |
| SG-16 (đổi/trả) | `pages/{sales_return_exchange_slip_preview_page, sales_slip_preview_page}.dart`, `support/sales_slip_pdf_generator.dart` |
| SG-10 | `widgets/sales_order_cancel_sheet.dart` |
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
37. Tạo nhanh: chọn "Tổ chức" không có ô "Loại tổ chức" (TH-03 BR-05 bắt buộc với tổ chức), chỉ đổi gợi ý ô tên; khe giữa các ô 8 (form khác 16); câu dẫn chữ đen bodySmall. Không đóng được bằng chạm ngoài sheet.
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

## Hiện trạng Flutter (để rà): đợt 2

**Thanh toán (SG-06)**

47. Thân chỉ có thẻ khách: **không có danh sách hàng, không có tổng đơn** trong thân; tổng chỉ ở thanh dưới. Người bán không xem lại được đơn trước khi thu.
48. Ô tiền dùng dấu chấm "441.000" (VTextField + hậu tố "đ", chữ thường); bàn phím mở ra lại dấu phẩy "441,000".
49. Khách lẻ: hàng % thành 3 nút riêng ("0%", "50%" viền mờ, "100%" nền xanh), khác hẳn segmented của khách có hồ sơ; ô tiền ghi "Tự động bằng tổng đơn." nhưng vẫn trông như ô nhập.
50. "Công nợ phát sinh" luôn nền xanh chữ xanh (tone primary), kể cả khi > 0 — không có màu cảnh báo.
51. "Tiếp tục" mờ khi thiếu ngày hẹn mà không nói lý do; chỉ có câu "Bắt buộc khi phát sinh công nợ." dưới ô.
52. "Tiền thừa 0đ" luôn hiện, kể cả khi chuyển khoản.
53. Kết hợp: lần đầu tự điền tiền mặt **2.000.000** (mốc cứng trong cubit), phần còn lại vào chuyển khoản; nếu đổi từ Tiền mặt sang thì giữ số cũ (CK = 0). Không có hàng %.
54. Chuyển khoản không có số tài khoản / QR cửa hàng để khách chuyển; chỉ có ô "Mã giao dịch" (không bắt buộc).
55. Nút chính ghi "Tiếp tục" nhưng mở sheet xác nhận cuối "Hoàn tất đơn?"; sheet không nhắc lại số tiền, phương thức, công nợ.
56. Toast lỗi chỉ hiện thông điệp (tiêu đề không hiện); hành động kiểm lại / quay về ẩn trong việc **chạm vào toast**, không có nút.
57. Mở thẳng liên kết: câu canh trái sát app bar, không icon, không khe trên.
58. "Khách phải trả" ở thanh dưới chữ đen; SG-02 cùng nhãn chữ xám.

**Kết quả (SG-07)**

59. Không có nút ← (đúng ý đồ) nhưng cũng không có danh sách hàng; tóm tắt chỉ có số tiền.
60. "Đã thanh toán" / "Tiền thừa" dùng tone neutral của SalesAmountHighlightRow → nền trắng trên thẻ trắng, trông như dòng thường; "Còn phải thu" chữ vàng; "Hẹn thanh toán" đệm và cỡ chữ khác các hàng trên.
61. Dòng meta ghi phương thức ("Tiền mặt") cả khi bán nợ một phần; không thấy là còn nợ ở thẻ đầu.
62. Kết hợp: meta "Tiền mặt + chuyển khoản" nhưng tóm tắt không tách từng phần.
63. Chưa đồng bộ xong: "Đơn <UUID>" hiện mã kỹ thuật thay số đơn.
64. Banner lỗi phiếu có **lỗi chính tả "Đơn văn đã hoàn tất"** (đúng: "Đơn hàng"). Hai banner (đồng bộ một phần, lỗi phiếu) chỉ có tiêu đề dài, không mô tả.
65. Dòng phiếu khi đang tạo / in / chia sẻ không bấm được nhưng không mờ, vẫn có ›.
66. Thẻ dự phòng HĐĐT ("Chưa tải được") dùng SalesEntryRow: icon cách 12, tiêu đề w600; dòng HĐĐT thật cách 16, tiêu đề w700 — hai thẻ cạnh nhau khác số đo.
67. Lỗi tải: khối giữa màn có "Thử tải lại" chữ xanh, thanh dưới nút thứ hai cũng thành "Thử tải lại" **nền đỏ** — 2 nút cùng việc, khác màu.
68. Toast lỗi in / chia sẻ hiện chuỗi lỗi thô (`'$e'`).
69. Sheet "Phiếu bán hàng" dùng `title` của VBottomSheet (tiêu đề + gạch), khác các sheet đợt 1 tự vẽ tiêu đề.

**Xem trước phiếu (SG-16)**

70. Logo "V45" cố định trên mọi phiếu (không phải logo / tên app hay cửa hàng).
71. "Còn phải thu" và "Công nợ phát sinh từ đơn" là **cùng một số in hai lần** (khối công nợ chỉ có dòng đó). Không có tổng nợ của khách ("Nợ cũ" đã bỏ ở 8-B2, TH-05 KI-07).
72. "Cám ơn quý khách!" — chính tả "Cảm ơn".
73. iPhone: trang A5 thu còn ~350 px, chữ 10,5 pt còn ~8,8 px — khó đọc nếu không phóng.
74. App bar chỉ có 2 icon in / chia sẻ không nhãn.
75. Thiếu dữ liệu phiếu: chỉ một câu giữa màn, không nút quay về.

## Hiện trạng Flutter (để rà): đợt 3

**Đơn hàng (SG-08)**

76. SG-08 nằm trong khung nhưng SG-09 và màn con nằm ngoài: chạm một đơn là mất thanh bên / thanh dưới. Web không có danh sách–chi tiết (TH-05 mục thiết bị: "SG-08 + SG-09 dạng danh sách–chi tiết").
77. Web: chỗ đặt 1040 nhưng gutter nút nổi tính theo cửa sổ 1280 → FAB "+" lọt vào trong cột 720, đè lên thẻ đơn.
78. Chip nhanh không kèm số đếm (TH-05 FR-01: "nhóm nhanh kèm đếm"). Chip chọn tone success; chip trong sheet lọc tone primary.
79. Thẻ đơn chỉ có badge vòng đời (Hoàn tất / Đã hủy): không nhãn thanh toán, HĐĐT hay đổi/trả, dù danh sách lọc được theo các mục đó.
80. Giờ trên thẻ chỉ "HH:mm", không ngày: đơn hôm qua và tuần trước trông như nhau.
81. Dòng phụ lặp "· Mosaic Retail Demo" ở mọi thẻ dù màn đã theo cửa hàng đang chọn.
82. Khách lẻ ghi "Khách Lẻ" (L hoa); SG-09 và chỗ khác ghi "Khách lẻ".
83. Nút lọc viền borderDefault (nhạt) cạnh ô tìm viền borderInput. Badge đếm cả chip nhanh, nhưng sheet lọc không có mục chip nhanh nên "Đặt lại" không gỡ được.
84. Không có dòng tóm tắt bộ lọc đang áp; phải mở sheet mới biết đang lọc gì.
85. Sheet lọc không tiêu đề; "Đặt lại" | "Áp dụng" sát mép dưới (không đệm đáy), iPhone dính thanh dưới. "Đặt lại" đóng sheet ngay.
86. "Thanh toán: Còn phải thu" trong sheet trùng chip nhanh "Còn phải thu".
87. Không kết quả do lọc (không tìm): nút vẫn ghi "Xóa tìm kiếm".
88. Lỗi tải: tiêu đề "Không thể tải danh sách" và mô tả "Không thể tải danh sách đơn hàng." lặp ý; phụ đề "0 đơn hàng" khi chưa biết số đơn.
89. Lỗi tải thêm: nút "Thu lai" thiếu dấu.
90. Chưa có đơn: "Tạo đơn bán hàng" chữ xanh trùng việc với FAB ngay dưới.
91. Khung đang tải: vạch đầu bị kéo gần hết bề ngang, khác hình thẻ thật.

**Chi tiết đơn (SG-09)**

92. Thẻ đầu: số đơn H3 mono w400 (nhẹ hơn tên khách bold); ngày "22/11/2026 10:32" không có "·" như SG-07.
93. Thẻ "Thanh toán & công nợ": "Đã thanh toán" và "Còn phải thu" luôn chữ vàng w600, kể cả đơn đã trả đủ ("Còn phải thu 0đ" vàng).
94. "Xem công nợ của khách" hiện ở mọi đơn có khách, kể cả đơn không còn nợ (TH-05 FR-02: khi đơn còn nợ và có khách).
95. Icon dòng hàng theo chuỗi đơn vị: "Lon" khớp "lo" ra icon nhãn như "Chai"; icon không nói gì về sản phẩm. Tên sản phẩm 1 dòng, cắt "…".
96. Tab "Đơn gốc | Sau đổi/trả" chỉ có khi có phiếu, mặc định "Sau đổi/trả", ghim trên vùng cuộn; đổi tab đổi luôn "Tổng đơn" và số trên thẻ thanh toán.
97. "Phiếu đổi/trả", "Lịch sử" (và "Đổi/trả hàng" trong sheet Thao tác) dùng cùng icon history.
98. Phụ đề "Lịch sử": "Thanh toán, chứng từ và nghiệp vụ sau bán" (TH-05: "Xem thanh toán và các hoạt động của đơn").
99. Đơn đã hủy: thẻ thanh toán mờ 0.4 nhưng vẫn có ›; ẩn phiếu bán hàng + HĐĐT; không còn thanh dưới.
100. Hủy mà để trống lý do → không có thẻ "Lý do hủy", mất luôn người huỷ và thời điểm huỷ.
101. Khối đang tải / lỗi có hai kiểu thẻ: thanh toán (khe 12, viền borderStrong, "Thử lại" cách 4) và lịch sử / phiếu đổi trả (khe 16, viền borderDefault, cách 8). Vòng Material thay VLoading.
102. Lỗi cả trang: tone danger dùng icon ⚠ (SG-08 dùng ⓧ); "Đơn hàng đang cập nhật" icon (i) mà tone vàng; nút primary nhận tone → nền vàng / đỏ.
103. "Thao tác" là lối duy nhất cho đổi/trả và huỷ; mờ khi thao tác chưa tải mà không nói vì sao. Toast chỉ hiện thông điệp (tiêu đề không hiện).
104. Sheet "Thao tác" có tiêu đề + gạch, SG-10 thì không. "Hủy đơn" tắt chỉ đổi nền xám + phụ đề lý do, không mờ, không icon khoá.

**Màn con (SG-09b / c / d)**

105. Ba màn con đẩy bằng `MaterialPageRoute`: URL không đổi, web tải lại trang là mất màn.
106. Ngữ cảnh ghi ba kiểu: 09b "#DH-000130 · …" mono; 09c "DH-000130 · …" không "#", không mono; 09d phụ đề app bar "Đơn DH-000130 · …".
107. 09b "Trạng thái": giá trị chữ in font mono; nhãn "Còn phải thu" trùng tên dòng số tiền ngay dưới (TH-05: "Thanh toán một phần").
108. 09b chưa thu: dòng "Đã thanh toán 0đ" tone primary, nền xanh như "Tổng đơn" — hai dòng xanh liền nhau.
109. 09b có đổi/trả: thẻ phiếu chỉ có "Khách trả thêm 0đ", không thấy số đã hoàn; ba thẻ ba kiểu khe (0 / 12 / 16 sau tiêu đề).
110. 09b "Giao dịch": không thời gian, không người thu; giao dịch cấn trừ bấm được (›) nhưng trông như dòng thường.
111. 09c: mốc xếp cũ → mới (RPC `get_sales_order_timeline` sắp `occurredAt` tăng; TH-05: mới nhất trước); "Lịch sử" lặp tiêu đề app bar; mọi mốc cùng icon; số tiền dính vào tiêu đề; không có mốc tạo / in / chia sẻ phiếu (RPC không ghi). Đơn huỷ: "Hủy đơn hàng" hiện hai lần và một mốc mã thô "sales_reporting_cancellation_recorded.v1" (bảng dịch chỉ có tên cũ).
112. 09d: loại luôn "Đổi/trả"; chênh lệch chữ textMuted, không phân biệt thu thêm / hoàn; 1 phiếu vẫn phải qua danh sách; phiếu thiếu mã chỉ mất ›.

**Huỷ đơn (SG-10)**

113. Không có chip lý do (TH-05 có "Khách yêu cầu huỷ" / "Tạo trùng đơn" / "Lý do khác"); chữ trong ô chính là lý do gửi server.
114. "Tồn kho — Hoàn lại 9 mặt hàng" đếm tổng số lượng (đơn có 3 mặt hàng); "Công nợ — Giảm <tổng đơn>" (TH-05: giảm còn phải thu).
115. "Quay lại" (viền xám) đặt trên "Hủy đơn hàng" (viền đỏ), cả hai large 52.
116. Đang huỷ: hai nút cùng mờ, không vòng xoay.
117. Bị chặn khi xác nhận: toast nằm trong Scaffold màn chi tiết, dưới lớp phủ và sau sheet → gần như không thấy (TH-05: hộp thoại "Không thể huỷ đơn").

## Hiện trạng Flutter (để rà): đợt 4

**Chung**

118. Mọi màn đổi/trả ngoài khung, web một cột 720; không có bố cục hai cột (hàng trả | hàng đổi / tóm tắt) cho web.
119. Chênh lệch ghi ba kiểu trên năm màn: SG-12 "23.000đ" / "-95.000đ" (không "+"), SG-13 "+23.000đ" / "-95.000đ", nhánh khách được hưởng "−95.000 ₫" (dấu trừ thật, có dấu cách + "₫"); SG-15 lấy trị tuyệt đối "95.000đ". TH-05: "+30.000 ₫" / "−600.000 ₫".
120. Icon lẫn hai bộ: Material `inventory_2`, `local_pharmacy`, `image`, `search_off`, `error_outline` (tô đặc) bên cạnh Lucide (nét).
121. Trạng thái đang tải dùng CircularProgressIndicator ở cả năm màn (TH-05: skeleton); lỗi / bị chặn là chữ canh trái sát trên, không VEmptyState, mỗi màn một khuôn (có / không icon ⚠, nút viền / nút xanh, "Tải lại" / "Thử lại").

**Lập phiếu (SG-12)**

122. Dòng trả không ghi còn trả được bao nhiêu (TH-05: "còn trả 2"); ở mức tối đa "+" vẫn trông bật nhưng bấm không có tác dụng; chạm ô số không mở bàn phím (SG-02 có).
123. Hai dòng phụ đầu màn ("DH-000130 · …" và "Chọn hàng trả và số lượng.") cùng kiểu bodySmall xám, không có thẻ đơn nguồn (TH-05 có "Đơn hàng nguồn …").
124. Banner giá đổi dùng tone lỗi (đỏ) cho một thông báo đã xử lý xong ("Đã cập nhật giá mới…"); nút "Thử lại" tải lại phiên.
125. Sheet chọn hàng đổi: cao cố định 480; dòng phụ lặp tên sản phẩm, đơn vị in hai lần; tồn > 5 là số trần; mỗi đơn vị bán là một thẻ trùng tên; lỗi in chuỗi thô `toString()`; icon lỗi xám (không tone đỏ).
126. Quay về từ SG-13 rồi bấm ← luôn hỏi "Bỏ thay đổi?" (phiếu đã lưu được tính là thay đổi); chọn "Bỏ thay đổi" huỷ phiếu nháp trên server.

**Quyết toán (SG-13)**

127. Hai bố cục cho một màn: thu thêm / không chênh lệch là thẻ cũ (dòng phụ bodySmall, tiền "23.000đ", "Chuyển khoản"), hoàn tiền là bố cục TH-06 (dòng phụ labelDefault w600, tiền "95.000 ₫", "CK"). Thẻ "Cần hoàn tiền" cũ vẫn còn trong code nhưng không tới được.
128. Ô "Khách thanh toán ngay" dùng bàn phím hệ thống (SG-06 dùng bàn phím số); ô ngày tự dựng cao 48, viền borderDefault, nhãn bold + "*" tự vẽ (ô khác 44, borderInput, VFieldLabel).
129. "Xác nhận đổi/trả" mờ khi thiếu ngày hẹn mà không nói vì sao.
130. Thanh dưới lặp số của thẻ nổi bật ("Phải thu thêm 23.000đ") và không đổi theo số khách trả ngay.
131. Sheet xác nhận dựng câu từ kế hoạch server: khách trả 10.000 vẫn ghi "Thu thêm 23.000đ từ khách.", không nhắc công nợ 13.000 và ngày hẹn. Nút "Xác nhận" đặt trên "Quay lại" (SG-10, "Bỏ thay đổi?" đặt nút an toàn trên).
132. Giá đổi khi xác nhận: banner bảo "quay lại màn đổi/trả" nhưng nút là "Tải lại" (tải tại chỗ).
133. "Hoàn cho khách 0 ₫" vẫn hiện khi toàn bộ được trừ vào nợ đơn này.
134. Hộp "Công nợ của khách vừa thay đổi" là Dialog M3 giữa màn, chỉ có "Tải lại", không đóng được; là chỗ duy nhất của Theme 5 dùng dialog.
135. Bị chặn: chỉ tiêu đề + lý do, không nút nào ngoài ←.

**Kết quả (SG-14)**

136. Có nút ← (SG-07 không có) và ← về đầu ngăn xếp, không về chi tiết đơn.
137. "Chênh lệch" luôn nền xanh chữ xanh, kể cả khi khách phải trả thêm; số âm "-95.000đ".
138. "Quyết toán phiếu": dòng thu / hoàn và dòng công nợ đều chữ vàng, kể cả "Không phát sinh công nợ"; icon ví vàng.
139. Đang xử lý: icon history vàng nhưng phần dưới vẽ như đã xong.
140. Đang tải: không có nút nào (lỗi thì có "Về trang chủ" | "Xem chi tiết đơn"). Có cấn trừ: thanh dưới ba nút large.
141. Ngày "26/11/2026 · 14:02" (SG-15 ghi "26/11/2026 14:02"); "Phiếu #DT-…" (SG-15 không "#").

**Chi tiết phiếu (SG-15)**

142. Thẻ "Đơn hàng nguồn" luôn ghi "Đã trả một phần" (chữ mặc định trong code, không ai truyền vào).
143. Chênh lệch lấy trị tuyệt đối: thu thêm và hoàn tiền trông y hệt; mọi khối nổi bật cùng nền xanh.
144. Hàng trả / hàng đổi là thẻ rời (khe 4), thành tiền bold không mono (SG-09 dùng nhóm thẻ có gạch, tiền mono).
145. Nút "Thao tác" chỉ mở sheet in ấn ("Xem trước phiếu", "In phiếu", "Chia sẻ phiếu").
146. Lỗi tải: một câu + "Thử lại" xanh đầy ngang; toast lỗi PDF hiện chuỗi lỗi thô.

**Phiếu đổi/trả (SG-16)**

147. App bar chỉ có ⋮ — chạm là sinh PDF rồi chia sẻ, không có in (TH-05: In + Chia sẻ); trong lúc sinh hiện VLoading trên nền mờ.
148. Không có dòng "phiếu nội bộ, không phải hoá đơn điện tử" (phiếu bán có); "Cảm ơn" (phiếu bán "Cám ơn").
149. "Cấn trừ sang đơn khác" không ghi đơn nào; logo "V45" cố định như phiếu bán.
150. Hai kiểu chờ liền nhau (CircularProgressIndicator của trang bọc, rồi VLoading + chữ của PdfPreview).

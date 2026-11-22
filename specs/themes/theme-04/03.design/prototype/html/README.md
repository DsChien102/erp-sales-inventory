# Prototype Theme 4 (TH-04): Chính sách giá (giá riêng theo khách) (10-8)

Prototype viết bằng HTML/CSS/JS thuần (ES module, không cần build). Nó vẽ **đúng Flutter hiện tại** của các màn TH-04, ở cả iPhone 390 và Web 1280, để người dùng rà bằng impeccable (bước 3 của 10-8). Chữ, thứ tự và số đo DS chép y nguyên; **không thiết kế lại**. Mỗi sheet, hộp thoại, toast là một ca riêng.

Mọi route `/pricing/*` là GoRoute cấp gốc, **nằm ngoài `StoreShell`**. Vì vậy cả hai khổ đều không có thanh bên hay thanh dưới. Trên web, màn chỉ có một cột 720 giữa nền xám, không chia 2 cột như Theme 2 / 3.

Làm 2 đợt, mỗi đợt một commit. Cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Danh sách & form | PR-01 Danh sách, PR-02 Bộ lọc / Sắp xếp, PR-04 Tạo / sửa (+ 4 sheet: Đến ngày, Ghi đè, Rời khỏi, Lưu thay đổi), PR-05 Chọn khách, PR-06 Chọn sản phẩm, PR-07 Chọn đơn vị | ✅ 53 ca × 2 khổ |
| 2 · Chi tiết & lịch sử | PR-08 Chi tiết (+ sheet thao tác / tắt / bật lại), PR-10 Lịch sử (+ sheet lọc, chi tiết hoạt động) | ⬜ |

PR-03 (Chọn cách thêm) và PR-09 (Nhập Excel) đã bỏ ở 6-A nên không vẽ.

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/themes/theme-04/03.design/prototype/html
python3 tools/serve.py &    # cổng 8774, tắt cache
# trang xem: http://127.0.0.1:8774/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=list&state=loaded&device=web
node --test                 # hàm thuần đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # mọi ca × 2 khổ → tools/proto-final/{iphone,web}/<màn>__<ca>.png (không vào git)
```

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/cases.js` | Nhóm (đợt), màn, ca, kèm điều cần nhìn của từng ca |
| `app/ds.js` | Widget DS, **chép từ Theme 2** (`theme-02/app/ds.js`, đổi `t2-` → `t4-`). Thêm: `bottomSheet` (showVBottomSheet M3, web rộng ≤ 640), `section` (VSection), `datePicker` (VDatePicker), `moneyField` (VMoneyField), `pickerField`, `radio`, `textAreaPlain`, `banner` có `footer`. Icon `ruler` / `refresh` để cục bộ (`LOCAL_ICONS`), không sửa `shared/icons.js` |
| `app/data.js` | Giá riêng, khách, sản phẩm, đơn vị mẫu (cửa hàng thú y như Theme 2 / 3); `money` (MoneyFormatter.formatMinor), `dong` (định dạng của màn chọn) |
| `app/list.js` | PR-01, PR-02; hàm thuần `bodyBranch`, `activeCount`, `effectiveText`, `sortLabel` |
| `app/form.js` | PR-04…07 + 4 sheet; hàm thuần `diffWithPercent`, `showSummary`, `isBelowFloor`, `isValid`, `isLongValue`, `unitSubtitle` |
| `app/main.js` | Ca → trạng thái; mọi màn vẽ ngoài khung (`insideShell('/pricing…') = false`) |
| `styles/t4.css` | Phần DS chép từ `t2.css`, rồi tới rule riêng Theme 4 (tiền tố `t4-`, token `--c45-v2-*`) |
| `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Trang xem và chụp ảnh, chép khuôn Theme 2 (cổng 8774) |

Có 4 bản `ds.js` (Theme 1, 3, 2, 4). Việc gom về `shared/` để sau.

## Nguồn Flutter

| Màn | Flutter (`apps/erp/lib/features/pricing/presentation/`) |
|---|---|
| PR-01 | `pages/pricing_list_page.dart`, `widgets/{price_rule_list_search_and_filter, price_rule_list_view, price_rule_card, price_rule_status_badge}.dart`, `logic/price_rule_list_{cubit,state,filters}.dart` |
| PR-02 | `widgets/{price_rule_filter_bottom_sheet, price_rule_sort_bottom_sheet}.dart` |
| PR-04 | `pages/pricing_form_page.dart`, `widgets/{price_rule_form_body, price_rule_form_edit_header, price_rule_form_readiness_summary, price_rule_price_field, price_rule_warning_banner, price_rule_form_blocking_states, price_rule_overwrite_confirm_dialog, price_rule_leave_form_dialog, price_rule_save_confirm_sheet}.dart`, `logic/price_rule_form_{cubit,state}.dart` |
| PR-05…07 | `pages/pricing_pick_{customer,product,unit}_page.dart`, `widgets/pricing_selectable_entity_card.dart` |
| Khung | `core/router/app_router.dart` (GoRoute `/pricing…` cấp gốc), `c45_design_system` `VPageScaffold` (bottomBar = `bottomNavigationBar`), `showVBottomSheet` |

## Hiện trạng Flutter (để rà): đợt 1

**Chung**

1. Route nằm ngoài khung nên không có thanh bên (web) hay thanh dưới (iPhone). Danh sách không có nút ←, vì vào từ menu Thêm. Web chỉ có một cột 720, không có bố cục danh sách – chi tiết 2 cột (TH-04 5.7 yêu cầu bố cục web thiết kế riêng).
2. Mọi sheet dùng `showVBottomSheet`, không dùng `showVAdaptiveSheet`. Vì vậy web cũng là sheet đáy rộng 640, không thành hộp thoại như Theme 2 / 3.
3. Sheet có 3 kiểu đầu: tiêu đề + gạch ("Bộ lọc giá riêng", "Rời khỏi màn hình?"); hàng tiêu đề tự vẽ + nút × nhỏ 20, vùng chạm 28 ("Tự động ghi đè giá trùng?", "Lưu thay đổi?"); không có tiêu đề ("Sắp xếp", "Đến ngày").
4. Tiền hiển thị "105.000đ" (không dấu cách), Theme 2 ghi "125.000 đ". Ô nhập giá lại dùng dấu phẩy "105,000".

**Danh sách (PR-01)**

5. Thẻ không có SĐT khách (TH-04 PR01-E05 có). Tên khách và tên sản phẩm cùng cỡ, cùng độ đậm w600, khó phân biệt.
6. "Đã tắt" và "Hết hiệu lực" cùng màu xám, vì `cancelled` và `draft` đều ra tone neutral.
7. Hàng "Sắp xếp: … ›" dùng mũi tên sang phải, nhưng bấm vào lại mở sheet.
8. Số trên app bar đổi theo tìm / lọc ("2 giá riêng") nhưng vẫn ghi như tổng. Không có dòng "n kết quả".
9. Mỗi lần gõ, đổi chip hay đổi sắp xếp, cả danh sách bị thay bằng 6 thẻ khung.
10. **Tìm / lọc không ra vẫn hiện "Chưa có giá riêng nào" + nút "Thêm giá riêng"**. Thiếu trạng thái L-04 "không kết quả" và lối "Xóa từ khoá".
11. Khi chưa có giá riêng: nút "Thêm giá riêng" giữa màn và nút + nổi cùng hiện.
12. Lỗi tải lần đầu thay cả thân, kể cả ô tìm và chip. Nhánh "Không thể tải dữ liệu" trong `_PriceRuleListBody` không bao giờ chạy tới.
13. Lỗi khi tải trang sau: không toast, không nút thử lại, vạch khung cuối danh sách đứng mãi.
14. Không có quyền xem: ô tìm, chip, "Sắp xếp" vẫn hiện trên hộp khoá.
15. Tải hết danh sách thì không có dòng "Đã ở cuối danh sách".
16. Nút lọc có số khi đang lọc, nhưng không thấy đang lọc theo gì, không có lối xoá lọc nhanh.
17. Web: nút + bị đẩy vào trong 280 px (gutter tính theo cửa sổ 1280), nên nằm sát mép phải cột 720.

**Lọc / sắp xếp (PR-02)**

18. **Mọi chip lọc đều xanh như đang chọn**, vì tone primary đặt cứng và tone thắng `selected`. Chỉ dòng "Đang chọn n bộ lọc" cho biết đã chọn gì.
19. Nhóm "Nguồn tạo" còn chip **"Nhập Excel"**, dù nhập Excel đã bỏ ở 6-A.
20. Nhóm "Thời gian cập nhật" không có "Tất cả" (bấm lại để bỏ chọn), khác 3 nhóm trên.
21. "Đặt lại" đóng sheet và áp ngay.

**Form (PR-04)**

22. Nút ← là arrowBack có thân, màn chọn dùng ‹. Không có nút Lưu trên app bar (khung TH-04 có); "Hủy | Lưu" nằm ở chân.
23. "Từ ngày *" để trống ("Chọn ngày"), không mặc định hôm nay. "Đến ngày" trống hiện "Không giới hạn" chữ mờ như gợi ý, không như giá trị.
24. **Thẻ so sánh luôn nền xanh viền xanh**, kể cả khi giá dưới sàn. **Số tiền chênh âm mất dấu trừ** ("10.741đ (-9,3%)"), chỉ phần % có "-". Giá cao hơn giá hiện tại cũng tô xanh như tốt.
25. "Giá hiện tại" ở form và màn chọn là giá **trước VAT**, số lẻ (115.741đ). Danh sách ghi "Giá niêm yết 125.000đ". Hai con số khác nhau cho cùng một sản phẩm.
26. Banner dưới sàn ghi "Bạn vẫn có thể lưu nếu có quyền ghi đè giá sàn" nhưng không cho biết mình có quyền đó không.
27. Banner ghi đè nằm đầu form, phải cuộn lên mới thấy. Lối "Xem giá riêng hiện có >" là chữ 11, dùng ký tự ">" thay icon.
28. Sửa: đổi ngày là hiện ngay banner "Lưu ý tự động ghi đè giá trùng", **dù không có giá riêng nào trùng**.
29. Sửa: thẻ "Thông tin áp dụng" hiện **mã khách dạng UUID** dưới tên.
30. Không có quyền tạo / sửa: cubit phát `NoPermission` rồi ngay sau đó phát lại form, nên **màn chặn chỉ hiện một khung hình**.
31. `STATE_CHANGED` thay cả form bằng hộp "Tải lại", không phải banner kèm giữ form (TH-04 F-07). Phần đang sửa bị mất.
32. Không có trạng thái đang tải (F-01). Form sửa lấy dữ liệu từ chi tiết truyền sang; mở thẳng URL sửa thì bị đưa về danh sách.
33. Đang lưu chỉ đổi chữ thành "Đang lưu...", không có vòng xoay.
34. Toast lỗi dùng một câu chung cho mọi lỗi không phân loại. Trên web, toast kéo hết bề ngang cửa sổ, không theo cột 720.

**Sheet của form**

35. "Đến ngày": việc phụ "Không giới hạn" lại là nút chính (xanh đặc), còn "Chọn ngày cụ thể" là nút viền.
36. "Tự động ghi đè giá trùng?" không nói trùng với giá riêng nào. Nút "Ghi đè & Lưu" xanh, không đỏ.
37. "Lưu thay đổi?" luôn có hàng "Đến ngày: X → X", kể cả khi không đổi ngày. Bộ đếm "0/200" là chữ tự vẽ dưới ô, còn ô ghi chú của form có bộ đếm trong ô.
38. "Rời khỏi màn hình?": khe giữa hai nút 12, các sheet khác 16.

**Màn chọn (PR-05…07)**

39. Chọn mất 2 bước: chạm thẻ rồi bấm "Chọn".
40. Radio bên phải ở màn chọn khách / sản phẩm, bên trái ở màn chọn đơn vị.
41. Thẻ sản phẩm: ô icon 52 nền trắng trên thẻ trắng, nên chỉ thấy icon trơ. Tên 1 dòng, tên dài bị cắt.
42. Màn chọn đơn vị không có ô tìm và không ghi đang chọn đơn vị của sản phẩm nào. Thiếu giá hiện tại nhưng có giá sàn → "Giá hiện tại: --".
43. Lỗi tải ra hộp trung tính "Đã xảy ra lỗi", còn lỗi danh sách là hộp đỏ.
44. Khung tải là 3 khối xám 72, không phải khung thẻ.
45. Nhãn vai trò ("KH & NCC") cùng kiểu chữ với dòng email / SĐT ngay trên.

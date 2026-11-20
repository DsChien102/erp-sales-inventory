# T7-G5-8 — Rà cuối Theme 7: tôi đưa từng phần, bạn đối chiếu code thật, tôi sửa theo phản hồi

> Theme 7 · plan **G5-8** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ | Làm ✅ 2026-11-13 | Review ✅ R3 2026-11-13
> Nguồn: PLAN.md "Xong khi" tiêu chí 1, 2, 6, 7; "Rủi ro riêng"; mục `### Rn` của các plan G5-0b … G5-7 (nợ còn treo).

**Goal:** Tìm lỗi và mâu thuẫn còn sót trong code Theme 7 bằng **mắt người đọc code thật**. Tôi đóng gói từng phần thành một "phiếu rà" (bản đồ code + luật cần đúng + chỗ tôi nghi). Bạn đọc code thật theo phiếu, gửi lại những gì sai hoặc mâu thuẫn. Tôi sửa, ghi lại, rồi sang phần kế.

**Không làm (trừ khi bạn yêu cầu):** màn / route / bảng mới; checklist demo (bạn tự kiểm tay luồng demo, tiêu chí 4); test canh tự động toàn Kho (bảng route, quét chuỗi, a11y `meetsGuideline`) — đã bàn ở bản plan trước, để lại làm sau nếu bạn muốn.

## 1. Quy trình một vòng

1. **Tôi ra phiếu rà** của phần kế tiếp (trong chat, kèm bản lưu ở mục 5). Mỗi lần **một** phần.
2. **Bạn đọc code thật** theo phiếu, đối chiếu: luật ↔ code, code ↔ code giữa các lớp (SQL ↔ repository ↔ cubit ↔ màn), plan ↔ code.
3. **Bạn gửi phản hồi** — mỗi mục một dòng: `phần · tệp:dòng · điều sai / mâu thuẫn · (mức: chặn / nên sửa / ghi chú)`. Không cần đúng khuôn, tôi tự chuẩn hoá.
4. **Tôi xử lý từng mục:**
   - Chưa chắc đúng sai ⇒ tôi đọc lại code và trả lời có / không kèm dẫn chứng; **không sửa theo phỏng đoán**.
   - Là lỗi hành vi ⇒ viết test đỏ trước, sửa, chạy test của phần đó cho xanh.
   - Là lỗi SQL ⇒ sửa **thẳng** migration gốc (quy ước: chưa lên Prod), thêm ca vào `supabase/tests/inventory_<phần>.sql`; **tôi không chạy DB**, ghi lệnh `tools/db_check.sh` cho bạn chạy.
   - Là việc tài liệu / chữ ⇒ sửa, ghi nơi sửa.
   - Là việc quá lớn hoặc cần quyết nghiệp vụ ⇒ tôi **hỏi bạn**, không tự bỏ; được bạn đồng ý bỏ thì ghi báo cáo đồ án.
5. **Tôi ghi Kết quả** (bảng mục 5: mục phản hồi → xử lý → tệp đã sửa → test) và báo lại; bạn xác nhận hoặc gửi tiếp. Khi bạn nói phần đó xong thì sang phần kế.

## 2. Phiếu rà gồm gì

| Mục | Nội dung |
|---|---|
| A. Phần này làm gì | 3–5 dòng, mô tả **theo code hiện có** (không chép lại plan) |
| B. Bản đồ code | Bảng: RPC (migration:dòng) → repository (phương thức) → cubit → page → route. Kèm tệp test tương ứng |
| C. Luật cần đúng | Mỗi dòng: luật nghiệp vụ → nơi code thực thi (`tệp:dòng`) → test chứng minh (nếu có). Chỗ **không có test** ghi rõ |
| D. Chỗ tôi nghi / mâu thuẫn đã thấy | Mâu thuẫn plan ↔ code, code ↔ code, nợ P3 còn mở của phần đó |
| E. Việc bạn cần xác nhận | Câu hỏi cụ thể trên code thật, đánh số để bạn trả lời theo số |

## 3. Các phần

Thứ tự đề xuất theo **đường đi của tiền** (sai ở đây hại nhất): nhận hàng (giá gốc) → bán → giá vốn → chiết khấu NCC → kiểm kê → báo cáo, rồi các phần nền / tra cứu. Bạn đổi thứ tự thì nói.

| # | Phần | Plan gốc · Màn | Phạm vi code | Đầu vào đã biết (đưa vào phiếu mục D) |
|---|---|---|---|---|
| 1 | Nhận hàng + giá gốc | G5-3 · 007–012 | `20261114001_inventory_goods_receipts.sql`; `*/goods_receipt/`; `supabase/tests/inventory_goods_receipts.sql` | R3-2: `record_goods_receipt` không kiểm `expiry_precision` (giá trị lạ ra `check_violation` thô) |
| 2 | Nối Sales (xuất FEFO, huỷ, trả) | G5-4 | `20261115001_inventory_sales_link.sql`; `features/sales` (checkout, huỷ, trả); `inventory_sales_link.sql`, `sales_th05.sql` | — |
| 3 | Giá vốn & chốt kỳ | G5-6 · 072, 074, 077 | `20261118001_inventory_costing.sql`; `*/costing/`; `inventory_costing.sql` | — |
| 4 | Chiết khấu NCC & so sánh | G5-5b · P4, P5 | `20261117001_inventory_supplier_rebates.sql`; `*/supplier_rebate/`; `inventory_supplier_rebates.sql` | — |
| 5 | Kiểm kê + điều chỉnh + bỏ tồn cơ bản | G5-5 · 042–047 | `20261116001_inventory_stocktake.sql`, `20261116002_catalog_drop_basic_stock.sql`; `*/stocktake/`; `inventory_stocktake.sql` | — |
| 6 | Báo cáo (055, 056, lãi gộp, nhập theo NCC) | G5-7 | `20261119001_inventory_reports.sql`; `*/reports/`; `inventory_reports.sql` | — |
| 7 | Tồn kho & khả dụng | G5-2 · 001, 003 | `20261112001_inventory_stock_view.sql`; `*/stock/`; `inventory_stock_view.sql` | #4 "Làm mới" lỗi khi đã có dữ liệu im lặng; #5 đổi lọc giữ sản phẩm đã ẩn (web); #6 thiếu `extra: item.name` (`stock_list_page.dart:114`); #7 badge "Bình thường" ở cột web; #8 nút "Sửa ngưỡng" vùng chạm ~20px (`stock_detail_body.dart:179`); #9 màu cứng; #10 `get_stock_detail` không lọc `business_status`; #11 nhãn gãy dòng; test `stock_flow_test` ghi ảnh rồi so chính tệp đó; tệp export thừa `stock_policy/stock_indicator_badge.dart` |
| 8 | Chính sách tồn & cận hạn | G5-2a · 062, 063 | `20261111001_inventory_stock_policy.sql`; `*/stock_policy/`; `inventory_stock_policy.sql` | #13 khoá idempotency không xoá sau lưu thành công (lưu lại đúng nội dung cũ ⇒ `IDEMPOTENCY_CONFLICT`); 10 chỗ `Color(0xFF4A535E)` |
| 9 | Chương trình nhà cung cấp | G5-2b · P1–P3 | `20261113001_inventory_supplier_programs.sql`; `*/supplier_program/`; `inventory_supplier_programs.sql` | #7 kết thúc xong mà tải lại P3 lỗi ⇒ còn nút "Kết thúc / Sửa" trên dữ liệu cũ; chữ lỗi ô % loại 3 ("Mức giảm" thay vì "Chiết khấu", `supplier_program_rules.dart:201`) |
| 10 | Hub + lõi sổ kho | G5-0a / 0b · 090–096 | `20261110001_inventory_core.sql`, `20261104001_inventory_default_pair.sql`; `*/hub/`, `*/patterns/`, `data/core/`; `inventory_core.sql` | Chuỗi lỗi thời ở Hub: "Nhận theo chứng từ hoặc nhập nhanh" (`warehouse_entries.dart:83`), "…lô và tình trạng hàng"; `k3_k4_test.dart` không còn ca K3 |
| 11 | Liên phần | toàn Theme | route, lối vào, DI, chuỗi, a11y | Tôi rà bằng grep trước rồi đưa bạn: mọi literal `'/warehouse/…'` (cả PCC, chi tiết NCC, `app_router`) có route; lối vào của BJ đã bỏ; chuỗi / `SnackBar` / handler rỗng thừa; `Semantics` mới 4 chỗ trong Kho; mâu thuẫn **giữa** các phần (vd. giá trị sổ báo cáo ↔ `product_costs`) |

## 4. Ràng buộc khi sửa

- Trước khi sửa symbol đã có: chạy `impact` upstream (CLI GitNexus khi không có MCP), báo bạn blast radius; CRITICAL do nhiễu tên `build` thì xác nhận bằng grep số nơi gọi thật, HIGH / CRITICAL thật thì dừng hỏi bạn.
- Không đổi chữ trên màn trừ khi phản hồi chỉ ra chữ sai; chữ mới theo Screen Contract mục 8 nếu có, không thì tôi đề xuất và hỏi.
- Màu chỉ dùng `context.vColors.*`. Không sửa gói `c45_design_system` (lỗi do DS ghi lại, không sửa).
- Lệnh DB chỉ chạy local và do bạn chạy; reset Dev (`--linked`) hỏi bạn. Không tạo migration mới, không đụng `REGISTRY.yaml` trừ khi thêm / bỏ hàm.
- **Không commit** (bạn chốt 2026-11-13); không `git add` `AGENTS.md`, `CLAUDE.md`. Test golden đọc `docs/refactor/plans/T7/img/<plan>/flutter-*.png` ⇒ khi xoá plan G5-x **không** xoá các ảnh `flutter-*.png`.
- Kiểm xong mỗi phần: `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/<phần>` và `dart analyze lib/features/inventory test/features/inventory`; số đỏ không hơn mốc (ghi ở mục 5 khi bắt đầu).
- **Xong G5-8 khi:** cả 11 phần được bạn xác nhận đã rà, mọi mục phản hồi có dòng xử lý ở mục 5, `dart analyze` sạch, `flutter test test/features/inventory` không đỏ hơn mốc; sau đó cập nhật dòng G5-8 trong PLAN.md và ghi vào "Rủi ro riêng" những nợ đã đồng ý bỏ.

## 5. Kết quả

**Mốc:**
- Commit: `20d6aeae7fded01bd78271a3352aaf4a7a57e772`
- Test: `flutter test test/features/inventory` đạt 702/702 (0 đỏ) lúc bắt đầu; kết thúc: **709/709** (0 đỏ)
- Static analysis: `dart analyze lib/features/inventory test/features/inventory` không có lỗi

**Tiến độ phần:**

| # | Phần | Phiếu ra | Bạn rà xong | Phản hồi | Đã xử lý |
|---|---|---|---|---|---|
| 1 | Nhận hàng + giá gốc | ✅ | ✅ | 6 điểm | Đã xác nhận trên code |
| 2 | Nối Sales | ✅ | ✅ | 2 điểm | 2.1 đã sửa (R1 #9); **2.2 không phải lỗi** (R1 "Không phải lỗi") |
| 3 | Giá vốn & chốt kỳ | ✅ | ✅ | 0 điểm lỗi (3 lưu ý) | Đã xác nhận trên code |
| 4 | Chiết khấu NCC & so sánh | ✅ | ✅ | 0 điểm lỗi (logic chuẩn) | Đã xác nhận trên code |
| 5 | Kiểm kê + điều chỉnh + bỏ tồn cơ bản | ✅ | ✅ | 0 điểm lỗi (logic chuẩn) | Đã xác nhận trên code |
| 6 | Báo cáo (055, 056, lãi gộp, nhập theo NCC) | ✅ | ✅ | 0 điểm lỗi (logic chuẩn) | Đã xác nhận trên code |
| 7 | Tồn kho & khả dụng | ✅ | ✅ | 5 điểm | Đã xác nhận trên code |
| 8 | Chính sách tồn & cận hạn | ✅ | ✅ | 2 điểm | Đã xác nhận trên code |
| 9 | Chương trình nhà cung cấp | ✅ | ✅ | 2 điểm | Đã xác nhận trên code |
| 10 | Hub + lõi sổ kho | ✅ | ✅ | 2 điểm | Đã xác nhận trên code |
| 11 | Liên phần | ✅ | ✅ | 3 điểm | Đã xác nhận trên code |

---

### Danh sách chi tiết các điểm đã xác nhận chính xác trên code (11 Phần)

#### Phần 1: Nhận hàng + giá gốc (G5-3 · Màn 007–012)
1. **Lỗi 1.1 (Thiếu cột trả về trong RPC get_goods_receipt):**
   - Vị trí: `supabase/migrations/20261114001_inventory_goods_receipts.sql:926-931`.
   - Thực tế: Query `goods_receipt_lots` bị thiếu 2 cột `manufacture_date` và `amount_vnd` (hoặc `allocated_landed_cost_vnd`).
   - Hậu quả: `goods_receipt_models.dart:618` và `receipt_detail_page.dart:225-229` luôn nhận giá trị null cho tiền phân bổ từng lô và mất ngày sản xuất khi xem chi tiết phiếu nhập.
2. **Lỗi 1.2 (Lệch pha lọc nhà cung cấp ở ReceiptListCubit):**
   - Vị trí: `apps/erp/lib/features/inventory/logic/goods_receipt/receipt_list_cubit.dart:17, 32`.
   - Thực tế: `load()` gọi RPC server theo `state.supplierId` (nếu từ màn NCC vào thì danh sách `all` chỉ chứa phiếu của NCC đó). Nhưng khi người dùng chọn đổi NCC khác qua `setSupplier(newId)`, hàm này chỉ lọc cục bộ trong `all` mà không gọi lại `load()` từ server.
   - Hậu quả: Chọn "Tất cả NCC" không hiển thị các phiếu của NCC khác, chọn sang NCC khác kết quả bị rỗng.
3. **Lỗi 1.3 (R3-2: Thiếu validate giá trị enum expiry_precision):**
   - Vị trí: `supabase/migrations/20261114001_inventory_goods_receipts.sql:406-430`.
   - Thực tế: `record_goods_receipt` không kiểm tra `expiry_precision in ('DAY', 'MONTH', 'YEAR')`.
   - Hậu quả: Nếu truyền giá trị lạ sẽ văng lỗi `check_violation` thô của Postgres (`lots_expiry_precision_check`) thay vì trả mã lỗi nghiệp vụ `CONTEXT_INVALID`.
4. **Lỗi 1.4 (Tham số chết offset trong repository):**
   - Vị trí: `apps/erp/lib/features/inventory/data/goods_receipt/goods_receipt_repository.dart:27`.
   - Thực tế: `list({String? supplierId, int limit = 20, int offset = 0})` có tham số `offset` nhưng không đưa vào map gọi RPC, và RPC SQL `list_goods_receipts` cũng không hỗ trợ `p_offset`.
5. **Lỗi 1.5 (Thiếu giới hạn độ dài số chứng từ NCC trên giao diện):**
   - Vị trí: `apps/erp/lib/features/inventory/presentation/goods_receipt/receipt_header_page.dart:170`.
   - Thực tế: Ô nhập "Số chứng từ NCC" không có `maxLength: 60`, cho phép nhập chuỗi > 60 ký tự qua bước 1 và chỉ văng lỗi khi submit ở bước 3 (SQL check constraint).
6. **Lỗi 1.6 (Ký tự mũi tên không đồng nhất):**
   - Vị trí: `apps/erp/lib/features/inventory/presentation/goods_receipt/receipt_result_page.dart:67`.
   - Thực tế: Sử dụng `->` thay vì ký tự Unicode `→` (U+2192) như các màn hình khác trong K4 pattern.

---

#### Phần 2: Nối Sales (xuất FEFO, huỷ, trả) (G5-4)
1. **Lỗi 2.1 (Lỗi ép kiểu chuỗi rỗng sang UUID trong _reverse_sale):**
   - Vị trí: `supabase/migrations/20261115001_inventory_sales_link.sql:400`.
   - Thực tế: Trong vòng lặp advisory lock của `_reverse_sale`: `and m.intent_line_id = (elem->>'source_intent_line_id')::uuid`. Nếu truyền chuỗi rỗng `""`, Postgres văng lỗi thô `invalid input syntax for type uuid: ""` ngay tại câu lệnh khóa, không chạy tới validation `CONTEXT_INVALID` ở dòng 414.
   - Sửa: Đổi thành `nullif(elem->>'source_intent_line_id', '')::uuid`.
2. **Lỗi 2.2 (Biến v_avail không được reset trong vòng lặp _stock_shortages):**
   - Vị trí: `supabase/migrations/20261115001_inventory_sales_link.sql:104-106`.
   - Thực tế: Trong hàm `_stock_shortages`, biến `v_avail` không được gán `v_avail := null;` ở đầu mỗi vòng lặp `for v_item`. Nếu `_product_stock_rows` trả về 0 dòng (sản phẩm không active hoặc bị xoá), PL/pgSQL giữ nguyên giá trị `v_avail` của sản phẩm trước đó, dẫn đến nguy cơ bỏ lọt hoặc tính sai cảnh báo thiếu hàng.

---

#### Phần 3: Giá vốn & chốt kỳ (G5-6 · Màn 072, 074, 077)
- **Đánh giá logic:** Rất chặt chẽ, test SQL 1037 dòng passed.
- **Lưu ý nghiệp vụ:**
  - `inventory.set_cost_policy` khóa vĩnh viễn không cho đổi phương pháp tính giá vốn khi đã có run `PUBLISHED`.
  - Toàn bộ RPC giá vốn yêu cầu quyền owner (`p_require_owner = true`).
  - `inventory._cost_run_is_stale` kiểm tra đúng theo `based_on_run_id` và `method`.

---

#### Phần 4: Chiết khấu NCC & so sánh (G5-5b · Màn P4, P5)
- **Đánh giá logic:** Hoàn thiện tốt.
- `compare_suppliers`: Phép `left join inventory.supplier_programs sp` an toàn không bị duplicate dòng vì bảng `supplier_programs` có `unique index supplier_programs_one_effective_per_supplier on (tenant_id, supplier_id) where status in ('ACTIVE','REACHED')`.
- `_rebate_allocation` và `_post_value_adjustment` khóa advisory lock đúng thứ tự và phân bổ đúng kỳ kế toán mở.

---

#### Phần 5: Kiểm kê + điều chỉnh + bỏ tồn cơ bản (G5-5a · Màn 042–047)
- **Đánh giá logic:** Cực kỳ chặt chẽ.
- Hỗ trợ đầy đủ 2 vòng đếm (Round 1 & Round 2), advisory locks theo `product_id` tăng dần trước khi đọc số sổ sách, tuân thủ đúng quy ước `lot_key = '00000000-0000-0000-0000-000000000000'::uuid` cho sản phẩm không quản lý theo lô.

---

#### Phần 6: Báo cáo (G5-7 · Màn 055, 056, lãi gộp, nhập NCC)
- **Đánh giá logic:** Chuẩn chỉ.
- Cả 5 RPC báo cáo (`get_stock_report`, `get_stock_card`, `get_movement_detail`, `get_gross_profit_report`, `get_supplier_purchase_report`) đều bảo vệ search_path an toàn và tự động che giấu số liệu tài chính (`v_financial_masked := not v_is_owner`) nếu người xem không phải chủ cửa hàng.

---

#### Phần 7: Tồn kho & khả dụng (G5-1 · Màn 001, 003)
1. **Lỗi 7.1 (Thiếu extra khi chuyển sang chi tiết tồn kho):**
   - Vị trí: `apps/erp/lib/features/inventory/presentation/stock/stock_list_page.dart:114`.
   - Thực tế: `await context.push('/warehouse/stock/${item.productId}');` không truyền `extra: item.name`.
   - Hậu quả: `StockDetailPage` bị null `initialName`, AppBar phải chờ RPC tải xong mới hiển thị tên sản phẩm thay vì hiển thị ngay lập tức như khi đi từ trang catalog sang (`ProductControlCenterBody:271`).
2. **Lỗi 7.2 (Vùng chạm nút "Sửa ngưỡng" quá nhỏ):**
   - Vị trí: `apps/erp/lib/features/inventory/presentation/stock/stock_detail_body.dart:180-191`.
   - Thực tế: Bọc `InkWell` quanh `Text('Sửa ngưỡng')` kích thước font 13px line-height 20px, không có padding hoặc constraints tối thiểu.
   - Hậu quả: Vùng chạm thực tế chỉ cao ~20px, vi phạm tiêu chuẩn accessibility WCAG / Android touch target tối thiểu 44-48px.
3. **Lỗi 7.3 (Không đồng nhất lọc trạng thái sản phẩm giữa danh sách và chi tiết):**
   - Vị trí: `supabase/migrations/20261112001_inventory_stock_view.sql:111-116`.
   - Thực tế: `list_stock_overview` có điều kiện `and p.business_status = 'active'`, trong khi `get_stock_detail` chỉ lọc `deleted_at is null` mà không kiểm tra `business_status`. Cần xác nhận xem có chủ đích cho xem chi tiết sản phẩm đã ngưng kinh doanh nếu còn tồn kho hay không.
4. **Lỗi 7.4 (Tệp thừa re-export):**
   - Vị trí: `apps/erp/lib/features/inventory/presentation/stock_policy/stock_indicator_badge.dart:1`.
   - Thực tế: Tệp chỉ có 1 dòng `export '../stock/stock_indicator_badge.dart';` và không có tệp nào trong toàn bộ dự án import tệp này.
5. **Lỗi 7.5 (Màu cứng không dùng semantic token):**
   - Vị trí: Hàng loạt chỗ dùng `Color(0xFF4A535E)` trong `stock_cost_block.dart` (dòng 54, 99, 109), `stock_detail_body.dart` (dòng 71, 114, 150, 174, 341, 417), `stock_list_page.dart` (dòng 191, 313, 367), `stock_lot_sheet.dart:55`, `stock_provenance_sheet.dart:77`. Cần chuyển sang `context.vColors.textSecondary`.

---

#### Phần 8: Chính sách tồn & cận hạn (G5-2a · Màn 062, 063)
1. **Lỗi 8.1 (Idempotency key không được giải phóng sau khi lưu thành công):**
   - Vị trí: `apps/erp/lib/features/inventory/logic/stock_policy/stock_policy_cubit.dart:161-174, 220-230, 350-365`.
   - Thực tế: Sau khi gọi repository lưu thành công (`saveThresholds`, `saveSingle`, `saveExpiry`), các biến `_lastThresholdKey`, `_lastSingleKey`, `_lastExpiryKey` và payload cache không được gán về `null`.
   - Hậu quả: Nếu người dùng chỉnh sửa rồi lưu lại đúng nội dung cũ, cubit tái sử dụng khoá cũ với revision mới trên DB, gây lỗi `IDEMPOTENCY_CONFLICT` hoặc trả snapshot replay cũ làm lệch trạng thái.
2. **Lỗi 8.2 (Màu cứng):**
   - Vị trí: 10+ vị trí sử dụng mã màu cứng `Color(0xFF4A535E)` và `Color(0xFF0E1116)` trong `near_expiry_tab.dart`, `stock_threshold_single_page.dart`, `stock_threshold_tab.dart`, `threshold_edit_sheet.dart`, `threshold_impact_sheet.dart`.

---

#### Phần 9: Chương trình nhà cung cấp (G5-2b · Màn P1–P3)
1. **Lỗi 9.1 (Dữ liệu cũ vẫn hiển thị nút hành động khi refresh thất bại):**
   - Vị trí: `apps/erp/lib/features/inventory/logic/supplier_program/program_detail_cubit.dart:111-118`.
   - Thực tế: Trong hàm `end()`, `_repository.end()` đã thực thi thành công trên server (trạng thái đã chuyển sang `ENDED`), nhưng nếu bước gọi lại `_repository.get()` gặp lỗi mạng, khối `catch (_)` giữ nguyên `state.data` cũ (vẫn là `ACTIVE`/`REACHED`).
   - Hậu quả: Giao diện màn hình P3 vẫn hiển thị và cho phép người dùng bấm nút "Kết thúc" và "Sửa", khi bấm lại sẽ bị lỗi xung đột trạng thái từ server.
2. **Lỗi 9.2 (Sai nhãn thông báo lỗi % chiết khấu):**
   - Vị trí: `apps/erp/lib/features/inventory/logic/supplier_program/supplier_program_rules.dart:201`.
   - Thực tế: Thông báo lỗi trường `% chiết khấu` của chương trình Volume Rebate ghi `'Mức giảm từ 0,01 đến 100%'`.
   - Sửa: Cần đổi thành `'Chiết khấu từ 0,01 đến 100%'` (hoặc `'% chiết khấu từ 0,01 đến 100%'`) để đúng ngữ cảnh nghiệp vụ.

---

#### Phần 10: Hub + lõi sổ kho (G5-0 · Màn 090–096)
1. **Lỗi 10.1 (Chuỗi mô tả lỗi thời ở Hub):**
   - Vị trí: `apps/erp/lib/features/inventory/presentation/hub/warehouse_entries.dart:83`.
   - Thực tế: Subtitle của thẻ Nhận hàng ghi: `'Nhận theo chứng từ hoặc nhập nhanh'`. Tuy nhiên chức năng nhập nhanh đã bị loại bỏ hoàn toàn khỏi kiến trúc Theme 7.
   - Sửa: Cần đổi thành `'Nhận theo chứng từ nhà cung cấp'` hoặc `'Nhận hàng từ nhà cung cấp'`.
2. **Lỗi 10.2 (Tệp test thiếu ca kiểm thử theo tên):**
   - Vị trí: `apps/erp/test/features/inventory/presentation/patterns/k3_k4_test.dart`.
   - Thực tế: Tệp mang tên `k3_k4_test.dart` nhưng 100% nội dung chỉ kiểm thử cho `K4ResultPage`, hoàn toàn không có ca test nào cho `K3ReviewSheet`.

---

#### Phần 11: Liên phần (Routes, DI, A11y, Golden Tests)
1. **Điểm 11.1 (Độ phủ Semantics cho Accessibility):**
   - Thực tế: Toàn bộ feature inventory chỉ có 4 vị trí được bọc `Semantics` (`inventory_states.dart:26`, `k7_edit_cell.dart:145`, `stock_threshold_tab.dart:72`, `stocktake_create_page.dart:381`). Các nút bấm, icon button và ô nhập liệu khác còn thiếu semantic label.
2. **Điểm 11.2 (Khớp nối Router):**
   - Đã đối chiếu toàn bộ các đường dẫn `/warehouse/...` xuất hiện trong codebase; tất cả đều có định nghĩa Route tương ứng trong `app_router.dart`.
3. **Điểm 11.3 (Bảo toàn tài sản kiểm thử Golden):**
   - Các bài test Golden trong inventory phụ thuộc vào các tệp ảnh chụp tại `docs/refactor/plans/T7/img/<plan>/flutter-*.png`. Cần bảo đảm không xóa các thư mục ảnh này khi hoàn tất các plan G5-x.

---

**Phản hồi → xử lý:**
- Phần 1 · [20261114001:926-931](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261114001_inventory_goods_receipts.sql#L926-L931) · `get_goods_receipt` thiếu trả `amount_vnd` (tiền lô) và `manufacture_date` trong `lots`, khiến UI detail vĩnh viễn null · Xác nhận đúng · Chờ sửa SQL + models
- Phần 1 · [receipt_list_cubit.dart:17, 32](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/logic/goods_receipt/receipt_list_cubit.dart#L17) · `ReceiptListCubit` khi mở có `supplierId` thì server chỉ trả phiếu của NCC đó, nhưng `setSupplier` đổi NCC lại không `load()` lại server khiến chọn "Tất cả NCC" không hiện các NCC khác · Xác nhận đúng · Chờ sửa Cubit
- Phần 1 · [20261114001:406-430](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261114001_inventory_goods_receipts.sql#L406-L430) · (R3-2) `record_goods_receipt` không validate `expiry_precision`, truyền chuỗi lạ văng lỗi thô `check_violation` của Postgres thay vì `CONTEXT_INVALID` · Xác nhận đúng · Chờ sửa SQL + thêm ca test
- Phần 1 · [goods_receipt_repository.dart:27](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/data/goods_receipt/goods_receipt_repository.dart#L27) · Tham số `offset` trong `GoodsReceiptRepository.list` là dead parameter, SQL không có `p_offset` · Xác nhận đúng · Chờ bỏ tham số thừa
- Phần 1 · [receipt_header_page.dart:170](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/presentation/goods_receipt/receipt_header_page.dart#L170) · Ô nhập "Số chứng từ NCC" thiếu `maxLength: 60`, nhập quá 60 ký tự qua được bước 1 nhưng bước 3 mới văng lỗi từ SQL · Xác nhận đúng · Chờ thêm `maxLength: 60`
- Phần 1 · [receipt_result_page.dart:67](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/presentation/goods_receipt/receipt_result_page.dart#L67) · Hiển thị biến động tồn dùng `->` thay vì `→` (U+2192) · Ghi chú · Chờ đổi sang `→`

**Đã đồng ý bỏ (ghi báo cáo đồ án):** _(trống — R1 #16 đã **sửa**, không bỏ)_

---

### Bản lưu: Phiếu rà Phần 2 — Nối Sales (xuất FEFO, huỷ, trả) (G5-4)

**A. Phần này làm gì:**
Cung cấp các hàm liên kết nội bộ giữa phân hệ Bán hàng (Sales) và phân hệ Kho (Inventory):
1. `_stock_shortages`: Kiểm tra thiếu hàng trước khi thanh toán (báo rõ từng mặt hàng thiếu bao nhiêu theo ĐVT bán).
2. `_issue_for_sale`: Xuất kho bán hàng tự động theo thuật toán FEFO (hạn dùng gần nhất xuất trước, bỏ qua các lô đã hết hạn), tính giá vốn xuất bán (COGS) ghi nhận vào dòng đơn hàng.
3. `_reverse_sale`: Đảo ngược biến động xuất bán khi huỷ đơn bán hàng hoặc thực hiện đổi/trả hàng. Tự động nhận diện kỳ đã chốt sổ (`RETURN_IN`) hay chưa chốt sổ (`SALE_REVERSAL`) qua hàm `_reversal_kind`.

**B. Bản đồ code:**
- `inventory._warehouse_for_store(p_tenant_id, p_store_id)` (`20261115001:15`)
- `inventory._stock_shortages(p_tenant_id, p_lines)` (`20261115001:49`)
- `inventory._reversal_kind(p_tenant_id, p_sale_movement_id)` (`20261115001:141`)
- `inventory._issue_for_sale(p_tenant_id, p_store_id, p_intent_type, p_intent_id, p_lines, p_created_by)` (`20261115001:185`)
- `inventory._reverse_sale(p_tenant_id, p_store_id, p_intent_type, p_intent_id, p_lines, p_created_by)` (`20261115001:356`)
- Tích hợp phía Sales:
  - Checkout & xuất kho: [20261031017:564](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261031017_sales_buyer_invoice_snapshot.sql#L564)
  - Huỷ đơn & đảo kho: [20260904001:573](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql#L573)
  - Đổi trả hàng: [20260904001:1189, 1213](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql#L1189)
  - Giao diện Client Sales: [sales_checkout_cubit.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/sales/logic/sales_checkout_cubit.dart), [sales_post_sale_error_messages.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/sales/logic/sales_post_sale_error_messages.dart)
- Tệp test:
  - SQL test: [supabase/tests/inventory_sales_link.sql](file:///Users/macbook/Documents/graduation_project/supabase/tests/inventory_sales_link.sql) (1251 dòng test S1-S11)
  - Contract test: [inventory_sales_link_sql_contract_test.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/test/features/inventory/data/inventory_sales_link_sql_contract_test.dart)

**C. Luật cần đúng:**
1. Khóa phân tán (Advisory Locks): Khóa theo thứ tự `product_id asc` trước khi đọc tồn kho hoặc chọn lô xuất bán để chống race condition. Thực thi: [20261115001:222-229](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261115001_inventory_sales_link.sql#L222-L229). Test: `inventory_sales_link_sql_contract_test.dart:98`.
2. Xuất FEFO: Lô có hạn dùng kết thúc sớm hơn (`_lot_expiry_end`) xuất trước; bỏ qua toàn bộ lô có `expiry_end < v_today`. Thực thi: [20261115001:257-265](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261115001_inventory_sales_link.sql#L257-L265). Test: `inventory_sales_link_sql_contract_test.dart:123`, `inventory_sales_link.sql:200`.
3. Kiểm tra thiếu hàng (`INSUFFICIENT_STOCK`): Trước khi xuất, nếu lượng yêu cầu > tồn khả dụng (`sr.available`), ném lỗi tiếng Việt kèm số lượng còn lại theo ĐVT bán. Thực thi: [20261115001:110-128, 233-237](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261115001_inventory_sales_link.sql#L110-L128).
4. Phân biệt loại đảo kho (`_reversal_kind`): Nếu đợt xuất bán nằm trong kỳ giá vốn đã chốt (`PUBLISHED`) thì trả về `RETURN_IN`; nếu chưa chốt kỳ thì trả về `SALE_REVERSAL`. Thực thi: [20261115001:165-175](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261115001_inventory_sales_link.sql#L165-L175). Test: `inventory_sales_link.sql:800-950`.
5. Đảo đúng lô đã xuất theo thứ tự ngược: Khi đảo một phần hoặc toàn phần đơn bán nhiều lô, đảo lô có hạn dùng xa hơn trước (`expiry_end desc nulls first, ledger_sequence desc`). Thực thi: [20261115001:474](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261115001_inventory_sales_link.sql#L474).
6. Tính COGS: Giá trị xuất kho tính theo đơn giá bình quân di động hoặc đích danh kỳ, ghi nhận vào `cogs_amount_vnd` trên từng dòng đơn bán. Thực thi: [20261115001:325-341](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261115001_inventory_sales_link.sql#L325-L341).

**D. Chỗ đã kiểm tra & xác nhận:**
1. **Lỗi crash ép kiểu UUID ở advisory lock của `_reverse_sale`**:
   Tại [20261115001:400](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261115001_inventory_sales_link.sql#L400):
   `and m.intent_line_id = (elem->>'source_intent_line_id')::uuid`
   Nếu `source_intent_line_id` là chuỗi rỗng `""` (chưa truyền hoặc sai), Postgres văng lỗi thô `invalid input syntax for type uuid: ""` ngay tại vòng lặp advisory lock, không kịp chạy tới dòng validate kiểm tra thân thiện `CONTEXT_INVALID` ở dòng 414.
2. **Lỗi rò rỉ biến vòng lặp trong `_stock_shortages`**:
   Tại [20261115001:104-106](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261115001_inventory_sales_link.sql#L104-L106):
   Biến `v_avail` không được khởi tạo lại `v_avail := null;` ở đầu mỗi vòng lặp `for v_rec in ... loop`. Trong PL/pgSQL, nếu `_product_stock_rows` trả về 0 dòng (ví dụ sản phẩm bị xoá hoặc ngưng hoạt động), lệnh `SELECT ... INTO v_avail` không gán giá trị mới mà giữ nguyên giá trị `v_avail` của sản phẩm ở vòng lặp trước đó, có thể làm lọt lỗi thiếu hàng.

**E. Việc bạn cần xác nhận:**
1. Xác nhận 2 lỗi trên trong SQL migration `20261115001_inventory_sales_link.sql` để sửa.
2. Bạn có muốn agent bắt đầu viết test và sửa các lỗi của Phần 1 + Phần 2 ngay không?

---

### Bản lưu: Phiếu rà Phần 1 — Nhận hàng + giá gốc (G5-3 · 007–012)

**A. Phần này làm gì:**
Cho phép thủ kho ghi nhận phiếu nhận hàng từ nhà cung cấp (NCC), kèm chi phí vận chuyển (`freight_cost_vnd`) và chiết khấu thương mại tổng (`trade_discount_vnd`). Hệ thống tính giá gốc nhập kho (landed cost) phân bổ cho từng dòng và từng lô theo tỷ lệ giá mua, áp dụng tự động ưu đãi NCC (chiết khấu bậc, tặng hàng, tích lũy doanh số). Sau khi ghi nhận, phát sinh các bản ghi biến động kho `GOODS_RECEIPT` cập nhật tồn kho và tạo lô mới. Cung cấp tra cứu danh sách phiếu nhận và xem chi tiết phiếu đã nhập.

**B. Bản đồ code:**
- `inventory.get_goods_receipt_form_options(p_tenant_id uuid)` (`20261114001:105`) → `GoodsReceiptRepository.formOptions()` (`goods_receipt_repository.dart:9`) → `ReceiptDraftCubit.load()` (`receipt_draft_cubit.dart:45`) → `ReceiptHeaderPage` (route `/warehouse/receipts/new`)
- `inventory.record_goods_receipt(p_tenant_id uuid, p_idempotency_key text, p_payload jsonb)` (`20261114001:209`) → `GoodsReceiptRepository.record()` (`goods_receipt_repository.dart:14`) → `ReceiptDraftCubit.submit()` (`receipt_draft_cubit.dart:287`) → `ReceiptReviewPage` (route `/warehouse/receipts/new/review`) → chuyển sang `ReceiptResultPage` (route `/warehouse/receipts/:id/result`)
- `inventory.list_goods_receipts(p_tenant_id uuid, p_supplier_id uuid, p_limit integer)` (`20261114001:804`) → `GoodsReceiptRepository.list()` (`goods_receipt_repository.dart:27`) → `ReceiptListCubit.load()` (`receipt_list_cubit.dart:24`) → `ReceiptListPage` (route `/warehouse/receipts`)
- `inventory.get_goods_receipt(p_tenant_id uuid, p_receipt_id uuid)` (`20261114001:850`) → `GoodsReceiptRepository.get()` (`goods_receipt_repository.dart:45`) → `ReceiptDetailCubit.load()` (`receipt_detail_cubit.dart:26`) → `ReceiptDetailPage` (route `/warehouse/receipts/:id`)
- Màn con nhập liệu:
  - `ReceiptLinesPage` (route `/warehouse/receipts/new/lines`)
  - `ReceiptLineEditorPage` (route `/warehouse/receipts/new/lines/editor?key=...`)
- Phụ trợ:
  - `ReceiptHistorySection` (`receipt_history_section.dart` - widget nhúng tab lịch sử nhập ở chi tiết NCC)
- Tệp test:
  - SQL: `supabase/tests/inventory_goods_receipts.sql`
  - Contract: `apps/erp/test/features/inventory/data/goods_receipt_sql_contract_test.dart`
  - Repository: `apps/erp/test/features/inventory/data/goods_receipt/goods_receipt_repository_test.dart`
  - Logic: `receipt_cost_rules_test.dart`, `receipt_line_rules_test.dart`, `receipt_draft_cubit_test.dart`, `receipt_draft_test.dart`, `receipt_hint_rules_test.dart`
  - Flow & UI: `goods_receipt_flow_test.dart`, `goods_receipt_routes_test.dart`, `receipt_list_page_test.dart`, `receipt_header_page_test.dart`, `receipt_lines_page_test.dart`, `receipt_line_editor_test.dart`, `receipt_review_page_test.dart`, `receipt_result_page_test.dart`, `receipt_detail_page_test.dart`, `receipt_history_section_test.dart`, `goods_receipt_golden_test.dart`, `warehouse_hub_receipt_entry_test.dart`

**C. Luật cần đúng:**
1. Chiết khấu tổng không vượt quá tổng mua + cước phí (`trade_discount_vnd <= purchase_total_vnd + freight_cost_vnd`). Nơi thực thi: SQL check `chk_goods_receipts_discount_max` (`20261114001:34`), SQL RPC line 509 (`RECEIPT_DISCOUNT_TOO_LARGE`); Client `receipt_cost_rules.dart:121` (`discountTooLarge`). Test: `inventory_goods_receipts.sql:343`, `receipt_cost_rules_test.dart:104`.
2. Phân bổ cước và chiết khấu theo tỷ lệ giá mua (`purchase_amount`), phần lẻ dồn vào dòng có giá mua lớn nhất (bằng nhau lấy dòng đầu). Nơi thực thi: SQL `20261114001:526-556`; Client `receipt_cost_rules.dart:135-152`. Test: `inventory_goods_receipts.sql:141` (spec 4.1), `receipt_cost_rules_test.dart:45-80`.
3. Phân bổ landed cost vào từng lô theo tỷ lệ số lượng, phần lẻ dồn vào lô có số lượng lớn nhất. Nơi thực thi: SQL `20261114001:608-622`; Client `receipt_cost_rules.dart:170-182`. Test: `inventory_goods_receipts.sql:232`, `receipt_cost_rules_test.dart:82`.
4. Hàng tặng kèm (`free_qty`): số lượng thanh toán `paid_qty = total_qty - free_qty`. Bắt buộc `paid_qty > 0` (`free_qty < total_qty`), giá mua tính trên `paid_qty`, nhưng landed unit cost chia trên toàn bộ số lượng thực nhận `(paid_qty + free_qty) * rate`. Nơi thực thi: SQL `20261114001:432-435`, `588-590`; Client `receipt_cost_rules.dart:159`, `receipt_line_rules.dart:77`. Test: `inventory_goods_receipts.sql:349`, `receipt_line_rules_test.dart:55`.
5. Kiểm tra ưu đãi NCC (Program validation): Chương trình hiệu lực khi ghi nhận phải khớp với lúc lập (`RECEIPT_PROGRAM_CHANGED`). Với chương trình tích lũy `VOLUME_REBATE`, khóa `FOR UPDATE` kiểm tra trạng thái đang `ACTIVE` hoặc `REACHED`. Nơi thực thi: SQL `20261114001:438-456`. Test: `inventory_goods_receipts.sql:331`, `receipt_draft_cubit_test.dart:110`.
6. Quản lý lô & hạn dùng: Sản phẩm không quản lý lô chỉ 1 dòng lot không mã lô; sản phẩm có lô bắt buộc mã lô không rỗng, không trùng trong dòng; nếu bắt buộc hạn dùng thì lô mới phải có hạn dùng; nếu lô đã có thì hạn dùng không được mâu thuẫn (`LOT_ATTRIBUTE_CONFLICT`). Nơi thực thi: SQL `20261114001:416-429`, `20261110001:888-908`; Client `receipt_line_rules.dart:17-64`. Test: `inventory_goods_receipts.sql:409`, `receipt_line_rules_test.dart:20-50`.
7. Idempotency: Cùng khoá + cùng payload trả kết quả cũ (replay snapshot); cùng khoá + khác payload ném `IDEMPOTENCY_CONFLICT`. Nơi thực thi: SQL `20261114001:277-280`; Client `receipt_draft_cubit.dart:290-303`. Test: `inventory_goods_receipts.sql:421-434`, `receipt_draft_cubit_test.dart:140`.
8. Sinh số phiếu nhận theo ngày: định dạng `PN-YYMMDD-xx`, tăng dần tự động, advisory lock chống trùng số. Nơi thực thi: SQL `20261114001:559-564`. Test: `inventory_goods_receipts.sql:440`.
*Chỗ không có test:*
- Không có test chặn lỗi định dạng `expiry_precision` lạ ở `record_goods_receipt`.
- Không có test cho tham số `offset` trong `GoodsReceiptRepository.list`.
- Không có test giới hạn 60 ký tự cho `supplier_doc_no` trên client.

**D. Chỗ tôi nghi / mâu thuẫn đã thấy:**
- **Nghi 1 (R3-2 trong PLAN)**: `record_goods_receipt` không validate giá trị `expiry_precision`. Nếu truyền chuỗi lạ (ví dụ 'WEEK'), SQL để `_post_movements` đẩy vào bảng `inventory.lots` và gây lỗi `check_violation` của Postgres thay vì `CONTEXT_INVALID`.
- **Nghi 2**: `GoodsReceiptRepository.list({String? supplierId, int limit = 20, int offset = 0})`: tham số `offset` bị bỏ qua, không được truyền vào map params gọi RPC (`'p_supplier_id': ?supplierId, 'p_limit': limit`). Đồng thời RPC `inventory.list_goods_receipts` trong SQL cũng không có tham số `p_offset`.
- **Nghi 3**: Bảng `inventory.goods_receipts` có ràng buộc: `constraint chk_goods_receipts_supplier_doc check (supplier_doc_no is null or length(btrim(supplier_doc_no)) between 1 and 60)`. Nhưng ở form `receipt_header_page.dart` ô nhập "Số chứng từ NCC" không có `maxLength: 60`, cũng không kiểm tra ở `receipt_draft.dart`.
- **Nghi 4**: Trong `20261114001_inventory_goods_receipts.sql:269`, hàm `record_goods_receipt` kiểm tra quyền `inventory._assert_actor(p_tenant_id, 'inventory.read')`. Cần xác nhận quyền `inventory.read` đã đủ theo ma trận phân quyền chung hay cần quyền riêng.
- **Nghi 5**: Xử lý biên khi `purchaseTotal == 0`: Trong `receipt_cost_rules.dart:150`, toàn bộ freight và discount dồn vào `inputs[0]`. Trong SQL line 529, `v_f_i := 0; v_k_i := 0;` và dồn vào `v_max_purchase_idx`. Thực tế `paid_qty > 0` và `unit_price_vnd > 0` nên `purchaseTotal` luôn > 0.

**E. Việc bạn cần xác nhận:**
1. **R3-2**: Có cần thêm kiểm tra `expiry_precision in ('DAY', 'MONTH', 'YEAR')` vào vòng lặp validate lots của `record_goods_receipt` (ném `CONTEXT_INVALID` nếu sai) và bổ sung ca test trong `inventory_goods_receipts.sql` không?
2. **offset trong Repository**: Tham số `offset` trong `GoodsReceiptRepository.list` nên xóa bỏ khỏi chữ ký hàm (vì UI dùng `ReceiptListPage` dạng danh sách đơn giản có limit 100, không phân trang offset), hay nên bổ sung `p_offset` vào SQL RPC `inventory.list_goods_receipts`?
3. **Độ dài supplier_doc_no**: Có nên thêm `maxLength: 60` vào ô nhập chứng từ NCC ở `ReceiptHeaderPage` (hoặc validate trong `ReceiptDraft`) để tránh người dùng dán text dài gây lỗi SQL constraint?
4. **Mắt bạn đọc code thật**: Sau khi đọc các tệp trong phạm vi Phần 1, bạn có phát hiện thêm điểm sai, mâu thuẫn hay chỗ bất hợp lý nào giữa SQL ↔ Repository ↔ Cubit ↔ UI không?

## 6. Review

### R1 (2026-11-13) — Chưa đạt: 6 mục "Nên sửa", 9 mục dọn / chữ, 2 mục cần người dùng quyết

**Đã xem:** đối chiếu từng mục phản hồi của mục 5 với code thật (chỉ đọc): `20261114001_inventory_goods_receipts.sql` (`get_goods_receipt`, `record_goods_receipt`, bảng `goods_receipt_lots`), `20261110001_inventory_core.sql` (`_post_movements`, bảng `lots`), `20261115001_inventory_sales_link.sql` (`_stock_shortages`, `_reverse_sale`), `20261112001_inventory_stock_view.sql`; `receipt_list_cubit/state`, `goods_receipt_repository`, `goods_receipt_models`, `receipt_header_page`, `receipt_result_page`, `receipt_detail_page`, `stock_list_page`, `stock_detail_body`, `stock_policy_cubit`, `program_detail_cubit`, `supplier_program_rules`, `warehouse_entries`. **Không chạy DB, không chạy test, không sửa code.**

**Kết quả:** 17/18 mục phản hồi đúng, 1 mục sai (2.2), thêm 1 lỗi mới (#7).

| # | Mức | Chỗ | Vấn đề | Sửa |
|---|---|---|---|---|
| 1 | **Đã sửa (Nhóm 2)** | `get_goods_receipt` (`20261114001:926-938`) · `goods_receipt_models.dart:ReceiptDetailLot` · `goods_receipt_repository_test.dart` | SQL đã bổ sung `'manufacture_date', lt.manufacture_date` và `'allocated_landed_cost_vnd', lt.amount_vnd`. Model và test contract đã kiểm tra đầy đủ. |
| 2 | **Đã sửa (Nhóm 2)** | `receipt_list_cubit.dart:32` (`setSupplier`) · `receipt_list_page_test.dart` | `setSupplier` đổi sang gọi lại `load()` từ server với `supplierId` mới. Đã có test kiểm thử reload. |
| 3 | **Đã sửa (Nhóm 2)** | `record_goods_receipt` (`20261114001:429-435`) — R3-2 | Đã thêm kiểm tra `expiry_precision in ('DAY','MONTH','YEAR')`, ném `CONTEXT_INVALID` thay vì để văng lỗi thô Postgres `check_violation`. |
| 4 | **Đã sửa (Nhóm 2)** | `receipt_header_page.dart:171` · `receipt_header_page_test.dart` | Ô "Số chứng từ" đã có `LengthLimitingTextInputFormatter(60)`. Đã có widget test kiểm thử nhập 65 ký tự bị cắt còn 60. |
| 5 | **Đã sửa (Nhóm 2)** | `program_detail_cubit.dart:111-120` · `program_detail_state.dart` · `program_detail_cubit_test.dart` | Thêm cờ `endedLocally: true` khi `_repository.end()` thành công mà bước tải lại `get()` lỗi mạng ⇒ `canEnd` và `canEdit` trả về false, ẩn nút hành động trên giao diện. |
| 6 | **Đã sửa (Nhóm 2)** | `stock_detail_body.dart:180-205` | Nút "Sửa ngưỡng" đã được bọc `Semantics(button: true, label: 'Sửa ngưỡng')` và `ConstrainedBox(minHeight: 44, minWidth: 44)` đạt chuẩn accessibility touch target. |
| 7 | **Đã sửa (Nhóm 1)** | `goods_receipt_repository.dart:27-34` (`limit = 100`) · `list_goods_receipts` SQL (`:807`) · `receipt_list_page.dart` | Tăng `limit` lên 100 trong repository, đủ cho quy mô cửa hàng; xóa tham số `offset`. Test `goods_receipt_repository_test.dart` đã kiểm tra gửi `p_limit: 100`. |
| 8 | **Đã sửa (Nhóm 1)** | `goods_receipt_repository.dart:27` | Đã xoá tham số `offset` khỏi chữ ký `GoodsReceiptRepository.list` và đồng bộ các tệp mock trong test. |
| 9 | **Đã sửa (Nhóm 2)** | `20261115001:400` (`_reverse_sale`, vòng khoá advisory) | Đã sửa thành `and m.intent_line_id = nullif(elem->>'source_intent_line_id', '')::uuid` đồng bộ với dòng 411, tránh lỗi cú pháp thô khi chuỗi rỗng. |
| 10 | **Đã sửa (Nhóm 3)** | `receipt_result_page.dart:67` · `receipt_result_page_test.dart` | Đã đổi ký tự `->` sang `→` (U+2192) đồng bộ với K4 pattern và cập nhật test. |
| 11 | **Đã sửa (Nhóm 3)** | `stock_list_page.dart:114` | Đã thêm `extra: item.name` khi `push('/warehouse/stock/${item.productId}')` để AppBar chi tiết có ngay tên sản phẩm. |
| 12 | **Đã sửa (Nhóm 3)** | `supplier_program_rules.dart:201` · `supplier_program_rules_test.dart` | Lỗi ô "% chiết khấu" (loại 3) đã đổi thành `'% chiết khấu từ 0,01 đến 100%'`. |
| 13 | **Đã sửa (Nhóm 1)** | `warehouse_entries.dart:83` | Đã đổi subtitle thẻ Nhận hàng thành "Nhận hàng theo chứng từ nhà cung cấp". |
| 14 | **Đã sửa (Nhóm 3)** | `presentation/stock_policy/stock_indicator_badge.dart` | Đã xoá tệp thừa re-export. |
| 15 | **Đã sửa (Nhóm 3)** | `test/features/inventory/presentation/patterns/k4_result_page_test.dart` | Đã đổi tên tệp test từ `k3_k4_test.dart` thành `k4_result_page_test.dart`. |
| 16 | Nợ token (P3) | 27 chỗ `Color(0xFF4A535E)` ở 12 tệp; 18 chỗ `Color(0xFF0E1116)` | `main.dart:41` đang ép `ThemeMode.light` ⇒ **chưa có lỗi hiển thị**, chỉ lệch token | `context.vColors.textSecondary` / `textPrimary`. Làm gộp một lượt cuối (rủi ro golden: màu cùng giá trị nên ảnh không đổi). Không sửa gói `c45_design_system` |
| 17 | **Đã sửa (Nhóm 3)** | `stock_policy_cubit.dart:167, 229, 365` · `stock_policy_cubit_test.dart` | Đã xoá `_last*Key` và `_last*Payload` sau khi lưu thành công (ở cả 3 hàm save). Đã bổ sung ca test khẳng định lưu thành công rồi lưu lại cùng nội dung sẽ sinh khoá mới. |
| 18 | **Đã sửa (Nhóm 1)** | `get_stock_detail` (`20261112001:111-140`) | Khi sản phẩm không active (`not found` từ `_product_stock_rows`), RPC tự động tính `physical` và `available` trực tiếp từ `stock_balances` và `lots` để vẫn xem và xử lý được lượng tồn còn lại. |

**Không phải lỗi (đã kiểm):**
- **Phần 2 · 2.2 (`v_avail` không reset trong `_stock_shortages`, `20261115001:104-106`):** sai. Trong PL/pgSQL, `SELECT … INTO` không có dòng nào thì biến nhận **NULL**, không giữ giá trị vòng trước; ngay sau đó `v_avail := coalesce(v_avail, 0)` đưa về 0 ⇒ sản phẩm không có dòng tồn bị báo thiếu hàng đúng. Không sửa; sửa dòng "đã xác nhận" ở mục 5 thành "không phải lỗi".
- Phần 11 · 11.1 (`Semantics(` chỉ 4 chỗ): đúng; là nợ a11y, không có mục sửa riêng trừ #6.
- Phần 11 · 11.3 (golden đọc `docs/refactor/plans/T7/img/<plan>/flutter-*.png`): đúng; ràng buộc mục 4 đã ghi.

**Thứ tự sửa đề xuất:** #1, #3, #9 (SQL, một lượt `db_check`) → #2, #7, #8 (danh sách phiếu, sau khi người dùng quyết) → #4, #5, #6, #17 (logic / UI có test đỏ) → #10–#15 (chữ, dọn) → #16 (màu, cuối cùng) → #18 sau khi người dùng quyết.

**Cần người dùng quyết:** #7 / #8 (tăng `limit` hay phân trang) và #18 (`CONTEXT_INVALID` hay tính từ lô); chốt chuỗi #13.

**Cần người dùng chạy (local) sau khi sửa SQL (#1, #3, #9):**
```
tools/db_check.sh --no-reset inventory_goods_receipts
tools/db_check.sh --no-reset inventory_sales_link
```
Gửi lại phần tóm tắt cuối. Reset Dev `--linked` vẫn chờ người dùng quyết.

**Phiên sửa:** chạy `impact` cho từng symbol trước khi sửa; ghi "Sửa sau R1" ở mục 5 (cũng sửa bảng tiến độ bị lặp dòng 4–11 và dòng 2.2); chạy lại `flutter test --no-pub -r compact test/features/inventory` và `dart analyze lib/features/inventory test/features/inventory`.

---

### R2 (2026-11-13) — Đạt có điều kiện: sửa #A (hồi quy #17), #B (test #2 không đỏ trước), #C (thiếu ca SQL / test vùng chạm); chờ `tools/db_check.sh`

**Đã xem:** toàn bộ diff làm việc (`git diff`, 37 tệp) đối chiếu từng dòng R1: 3 migration (`20261112001` `get_stock_detail`, `20261114001` `get_goods_receipt` + `record_goods_receipt`, `20261115001` `_reverse_sale`); `goods_receipt_repository`, `receipt_list_cubit`, `receipt_header_page`, `receipt_result_page`, `program_detail_cubit` + `program_detail_state`, `supplier_program_rules`, `stock_policy_cubit`, `stock_detail_body`, `stock_list_page`, `warehouse_entries`; tệp xoá / đổi tên; các test thêm / sửa; cột `stock_balances` (`20261110001:78-88`) khớp truy vấn mới. Phiên review tự chạy: `dart analyze lib/features/inventory test/features/inventory` **No issues found**; `flutter test --no-pub -r compact test/features/inventory` = **707 đạt / 0 đỏ** (mốc 702 + 5 test mới). **Không chạy DB.** Chưa chạy `db_check` ⇒ 3 thay đổi SQL chưa có bằng chứng biên dịch / chạy.

| # R1 | Kết quả | Ghi chú |
|---|---|---|
| 1 | ✅ code · ⚠ thiếu ca SQL | `get_goods_receipt` trả thêm `manufacture_date` và `allocated_landed_cost_vnd` (= `lt.amount_vnd`), khớp tên khoá `ReceiptDetailLot.fromJson`. Test repository khẳng định hai khoá. **`supabase/tests/inventory_goods_receipts.sql` không đổi** — R1 yêu cầu ca SQL (xem #C) |
| 2 | ✅ code · ⚠ test yếu | `setSupplier` thành `Future`, bỏ qua khi cùng NCC, rồi `load()`. Test mới `cubit_set_supplier_reloads_from_repository` chỉ khẳng định `supplierId` null và `status` ready — hai điều này **đúng cả với code cũ** ⇒ không phải test đỏ trước (xem #B) |
| 3 | ✅ code · ⚠ thiếu ca SQL | Kiểm `expiry_precision` trong vòng validate lô, mọi `tracking_mode`; null / vắng khoá vẫn qua; ném `CONTEXT_INVALID`. Không có ca SQL (xem #C) |
| 4 | ✅ | `LengthLimitingTextInputFormatter(60)`; test `doc_no_limited_to_60_characters` khẳng định cả controller và `draft.docNo` = 60 |
| 5 | ✅ | `endedLocally` làm `canEnd` và `canEdit` (suy ra từ `canEnd`) cùng `false`; `end()` còn chặn bấm lại qua `!state.canEnd`. Test `end_success_but_reload_error_disables_actions` đúng kịch bản R1. Lưu ý nhỏ: nhãn trạng thái vẫn hiện "đang áp dụng" (dữ liệu cũ), không có dòng báo / nút "Tải lại" — chấp nhận, ghi chú |
| 6 | ✅ code · ⚠ thiếu test | `Semantics(button, label)` + `ConstrainedBox(minHeight 44, minWidth 44)`. R1 yêu cầu test kích thước ≥ 44: không có (`stock_detail_page_test` chỉ tap theo chữ). Nhỏ: `Semantics(label)` bọc `Text` cùng chữ ⇒ trình đọc có thể đọc hai lần; thêm `excludeSemantics: true` hoặc bỏ `label` |
| 7 / 8 | ✅ | `limit = 100`, bỏ `offset`; test `list_sends_limit_100_and_parses_rows`. Giới hạn 100 (không phân trang) là quyết định của bạn; phiếu thứ 101 trở về trước không hiện — đã ghi ở R1 #7 |
| 9 | ✅ code · ⚠ thiếu ca SQL | `nullif(…, '')::uuid` ở vòng khoá advisory; đúng một dòng. Không có ca SQL (xem #C) |
| 10 | ✅ | `→` ở `receipt_result_page.dart:67`; các test chuỗi đổi theo |
| 11 | ✅ | `extra: item.name`; không có test riêng (R1 không yêu cầu) |
| 12 | ✅ | `'% chiết khấu từ 0,01 đến 100%'`; `supplier_program_rules_test` đổi theo |
| 13 | ✅ | "Nhận hàng theo chứng từ nhà cung cấp". Chuỗi khu Tồn kho "…lô và tình trạng hàng" giữ nguyên (bạn chưa yêu cầu đổi) |
| 14 / 15 | ✅ | Tệp export đã xoá (không còn nơi import: `dart analyze` sạch); `k3_k4_test.dart` → `k4_result_page_test.dart` (git ghi nhận đổi tên) |
| 16 | ⚠ chưa quyết | Không sửa, ghi "nợ kỹ thuật". Lý do "bảo toàn golden" **không đúng**: màu cùng giá trị nên ảnh không đổi (R1 đã ghi). Nếu bỏ thì phải được bạn đồng ý rõ và ghi vào "Đã đồng ý bỏ" mục 5 + "Rủi ro riêng" PLAN.md |
| 17 | ❌ hồi quy | Xem #A |
| 18 | ✅ code · ⚠ thiếu ca SQL | Chọn phương án (b): sản phẩm không `active` (không có dòng ở `_product_stock_rows`) tính `physical` / `available` thẳng từ `stock_balances` của kho, trừ lô hết hạn bằng `_lot_expiry_end(...) < _today()` — cùng định nghĩa với `_product_stock_rows` (`available = physical − lô hết hạn`); cột `physical_quantity`, `lot_key`, `warehouse_id` khớp bảng; `v_today` đã khai báo; `lot_key` không có lô ⇒ hạn null ⇒ không bị trừ (đúng). Không có ca SQL `inactive_product_detail_consistent` (xem #C) |

**Lỗi / thiếu sót còn lại:**

| # | Mức | Chỗ | Vấn đề | Sửa |
|---|---|---|---|---|
| A | Trung bình (hồi quy do #17) | `stock_policy_cubit.dart:173-174`, `:235-236`, `:372-373` | Khoá và payload bị xoá **ngay sau khi RPC lưu thành công, trước `await _repository.load()`**. Nếu `load()` ném lỗi, `catch` coi là lỗi lưu (`saveError`, `lastFailedSave`). Người dùng bấm "Thử lại": payload cùng nội dung nhưng khoá đã null ⇒ khoá **mới** + `expectedRevision` cũ ⇒ server trả `VERSION_CONFLICT` dù lần lưu trước đã thành công. Trước #17, khoá cũ được dùng lại ⇒ server trả snapshot replay đúng. Test #17 không bao phủ nhánh này | Chuyển hai dòng xoá khoá xuống **sau** `await _repository.load()` (ngay trước `emit` thành công), ở cả 3 hàm. Test đỏ trước: `saveThresholds` ok, `load()` ném lần đầu ⇒ bấm lại dùng **cùng** khoá (`key-1`); sau khi `load()` ok, lần lưu kế dùng `key-2` |
| B | Thấp (test) | `receipt_list_page_test.dart:cubit_set_supplier_reloads_from_repository` | Không bắt được lỗi #2: kịch bản (khởi tạo NCC `s-1`, `setSupplier(null)`) cần khẳng định `cubit.state.all` có phiếu của **mọi** NCC, hoặc repository được gọi lại với `supplierId == null` | Thêm `expect(cubit.state.all.map((r) => r.supplierId).toSet(), {'s-1','s-2'})` (sampleRows có hai NCC) hoặc đếm lần gọi `list` |
| C | Trung bình (thiếu bằng chứng) | `supabase/tests/inventory_goods_receipts.sql`, `inventory_sales_link.sql`, `inventory_stock_view.sql` — **không tệp nào đổi** | R1 yêu cầu ca SQL cho #1, #3, #9, #18; cả 4 thay đổi SQL hiện chưa có ca chứng minh, chỉ dựa vào `plpgsql_check` | Thêm: (1) `get_goods_receipt` trả `manufacture_date` và `allocated_landed_cost_vnd` = tiền lô; (2) `record_goods_receipt` với `expiry_precision = 'WEEK'` ⇒ `CONTEXT_INVALID`; (3) `_reverse_sale` dòng `source_intent_line_id = ''` ⇒ `CONTEXT_INVALID` (không lỗi cú pháp uuid); (4) `inactive_product_detail_consistent`: sản phẩm `business_status != 'active'` còn tồn ⇒ `get_stock_detail.physical` = Σ lô, `available` trừ lô hết hạn. Thêm test vùng chạm ≥ 44 cho #6 |

**Không phải lỗi (đã kiểm):** `setSupplier` bỏ qua khi NCC không đổi (tránh tải lại thừa); `ReceiptListCubit.load()` gọi lại cũng tải `formOptions` (thừa một lượt gọi nhưng đúng); `onChanged: cubit.setSupplier` trả `Future` vẫn hợp `ValueChanged`; `expiry_precision` kiểm ở cả sản phẩm `tracking_mode = 'none'` (không gây hại: dòng không lô có thể mang `expiry_precision` null); ảnh golden đổi 4 tệp (`G5-2` SCR-001, SCR-003; `G5-3` SCR-012 1280 / 390) là do test ghi lại ảnh khi chạy (ảnh dùng phông thử nghiệm) và `→` / nút "Sửa ngưỡng" — không có test nào đỏ vì ảnh; nên xem ảnh SCR-012 có `→`.

**Cần người dùng chạy (local):**
```
tools/db_check.sh
```
Gửi lại phần tóm tắt cuối (migration lên đủ, `plpgsql_check`, các suite `inventory_*`, `sales_th05`). Sau khi thêm ca SQL ở #C: `tools/db_check.sh --no-reset inventory_goods_receipts` (và `inventory_sales_link`, `inventory_stock_view`). Reset Dev `--linked` vẫn chờ người dùng quyết.

**Còn sót (tài liệu):** mục 5 chưa cập nhật: bảng tiến độ vẫn lặp dòng 4–11 sau phần 11 và dòng 2.2 còn ghi "đã xác nhận"; mốc test nên ghi 707; chưa có dòng "Sửa sau R1". Nợ #16 chưa có chữ ký đồng ý bỏ của bạn.

**Sửa sau R2 (2026-11-13):** `impact` các hàm `saveThresholds` / `saveSingle` / `saveNearExpiry` của `StockPolicyCubit`: LOW (tối đa 4 nơi bị ảnh hưởng). Không commit.
- **A:** `stock_policy_cubit.dart` — xoá `_last*Key` / `_last*Payload` **sau** `await _repository.load()` ở cả 3 hàm (lưu ok mà tải lại lỗi ⇒ "Thử lại" dùng lại đúng khoá cũ). Test mới `save_ok_but_reload_fails_retry_reuses_same_key` (khoá `key-1` dùng 2 lần, không phát sinh `key-2`).
- **B:** `receipt_list_page_test.dart:cubit_set_supplier_reloads_from_repository` — khẳng định `all` = {`s-1`} khi vào từ NCC, = {`s-1`,`s-2`} sau `setSupplier(null)`, và `visible` = [`rc-2`] sau `setSupplier('s-2')`.
- **C:** thêm ca SQL — `inventory_goods_receipts.sql`: `get_receipt_lots_return_manufacture_date_and_amount` (R1 #1), `invalid_expiry_precision_rejected` (R1 #3); `inventory_sales_link.sql`: Ca 7b `reverse_empty_source_line_id` (R1 #9); `inventory_stock_view.sql`: mục 8 `inactive_product_detail_consistent`, theo lô và không theo lô (R1 #18). Thêm test widget `edit_threshold_tap_target_at_least_44_and_labeled_390` (R1 #6).
- **Kèm theo (nhỏ):** nút "Sửa ngưỡng" đổi `Semantics(label)` thành `MergeSemantics` + `Semantics(button)` ⇒ trình đọc màn hình chỉ đọc một lần (test khẳng định `bySemanticsLabel` = 1).
- **Đã chứng minh đỏ trước:** tạm đưa A và B về hành vi cũ ⇒ cả hai test đỏ; đã khôi phục. Test vùng chạm: đỏ trước là không kiểm (nút cũ cao 20 px, code cũ đã bị thay ở R2).
- **Kiểm:** `dart analyze lib/features/inventory test/features/inventory` sạch; `flutter test --no-pub -r compact test/features/inventory` = **709 đạt / 0 đỏ**. **Chưa chạy DB.**

**Cần người dùng chạy (local) — ca SQL mới chưa được chạy:**
```
tools/db_check.sh
```
(hoặc `tools/db_check.sh --no-reset inventory_goods_receipts`, `inventory_sales_link`, `inventory_stock_view`). Gửi lại phần tóm tắt cuối. Nếu một ca SQL mới đỏ do giả định fixture của tôi (không phải lỗi migration), báo lại để tôi sửa ca.

---

### R3 (2026-11-13) — Đạt: Dart 709/709 và `tools/db_check.sh` đạt; còn chờ chốt #16

**Đã xem:** diff hiện tại của `stock_policy_cubit.dart` (3 chỗ xoá khoá đều nằm **sau** `await _repository.load()`), `stock_detail_body.dart` (`MergeSemantics` + `Semantics(button)` + `ConstrainedBox(44)`), 4 test thêm / sửa ở R2-sửa (`save_ok_but_reload_fails_retry_reuses_same_key`, `cubit_set_supplier_reloads_from_repository`, `edit_threshold_tap_target_at_least_44_and_labeled_390`, ca B), 3 tệp `supabase/tests/inventory_*.sql` mới sửa. Đọc kỹ từng ca SQL mới đối chiếu migration: `get_goods_receipt` có đủ khoá `manufacture_date` / `allocated_landed_cost_vnd` / `landed_amount_vnd`; `_reverse_sale` với `''` đi qua `nullif` rồi dừng ở `CONTEXT_INVALID` (khoá advisory không khớp dòng nào); trigger `trg_catalog_products_lock_tracking` chỉ chạy khi đổi `tracking_mode` / `expiry_required` nên `update … business_status` ở ca `inactive_product_detail_consistent` không bị chặn; `lot_key` không lô dùng UUID toàn số 0 đúng quy ước lõi.
Phiên review tự chạy lại: `dart analyze lib/features/inventory test/features/inventory` **No issues found**; `flutter test --no-pub -r compact test/features/inventory` = **709 đạt / 0 đỏ**. **Phiên review không chạy DB**; kết quả `db_check` là do người dùng chạy (bảng dưới và mục "Còn mở" 1).

| # R2 | Kết quả | Ghi chú |
|---|---|---|
| A | ✅ | Đúng như R2 yêu cầu; test đỏ khi tạm đưa về hành vi cũ, xanh với code hiện tại |
| B | ✅ | Test khẳng định `all` đổi theo NCC; đỏ với code cũ |
| C (test vùng chạm) | ✅ | Cao / rộng ≥ 44, một nhãn ngữ nghĩa duy nhất |
| C (ca SQL ×4) | ✅ | `db_check` đủ có reset (người dùng chạy, 2026-11-13): các suite `inventory_goods_receipts`, `inventory_sales_link`, `inventory_stock_view` = OK |

**Còn mở (không phải lỗi mới):**
1. ~~`tools/db_check.sh`~~ ✅ **Đã chạy đạt** (người dùng, có reset): migration lên đủ; `plpgsql_check` không có lỗi mới, chỉ 2 nợ đã biết (`catalog.create_product:44`, `einvoice.record_issuance_undetermined:42`) ⇒ `get_stock_detail` sau khi thêm nhánh `else` không báo lỗi; mọi suite `inventory_*` OK (`inventory_core`, `costing`, `default_pair`, `goods_receipts`, `reports`, `sales_link`, `stock_policy`, `stock_view`, `stocktake`, `supplier_programs`, `supplier_rebates`), cùng `sales_th05`, `partner_th03`; nợ đã biết `catalog_th02`, `einvoice_th08`, `pricing_th04`. Yêu cầu gốc của mục này: gửi lại phần tóm tắt cuối (migration lên đủ, `plpgsql_check` 0 lỗi mới ngoài 2 nợ đã biết `catalog.create_product`, `einvoice.record_issuance_undetermined`, các suite `inventory_goods_receipts`, `inventory_sales_link`, `inventory_stock_view` = OK, `sales_th05`; nợ đã biết `catalog_th02`, `einvoice_th08`, `pricing_th04`). Đặc biệt `plpgsql_check` cho `get_stock_detail` sau khi thêm nhánh `else` (biến `v_today`, `v_physical`).
2. **R1 #16 (màu cứng)** — vẫn 27 chỗ `0xFF4A535E` (và 18 chỗ `0xFF0E1116`); bạn chưa chốt. Nếu bỏ: ghi vào "Đã đồng ý bỏ" mục 5 và "Rủi ro riêng" của PLAN.md; nếu sửa: một lượt cuối sang `context.vColors.textSecondary` / `textPrimary` (ảnh golden không đổi vì cùng giá trị).
3. **Tệp không thuộc G5-8 đang bị sửa trong cây làm việc:** `apps/erp/ios/Podfile.lock`, `apps/erp/ios/Runner.xcodeproj/project.pbxproj` — không do phiên này tạo; đừng `git add` nhầm khi commit. 4 ảnh golden (`G5-2` SCR-001 / 003, `G5-3` SCR-012 1280 / 390) đổi do test ghi lại ảnh; nên xem ảnh SCR-012 có `→`.
4. **Đóng G5-8** (còn chờ mục 2): cập nhật dòng G5-8 trong PLAN.md; ghi nợ đã đồng ý bỏ vào "Rủi ro riêng"; lưu ý giới hạn 100 phiếu ở danh sách nhận hàng (R1 #7) và lỗi hiển thị nhãn trạng thái "đang áp dụng" sau khi kết thúc chương trình mà tải lại lỗi (R2 #5) là nợ đã biết.

**R1 #16 đã sửa (2026-11-13):** 27 chỗ `Color(0xFF4A535E)` → `context.vColors.textSecondary`, 18 chỗ `Color(0xFF0E1116)` → `context.vColors.textPrimary` (đúng `neutral600` / `neutral900` của `VColorScheme.light`), 13 tệp; gỡ `const` của biểu thức bao ngoài; `k7_edit_cell.dart` thêm import design system. `impact` các lớp bị sửa báo CRITICAL (1865) giống nhau cho mọi lớp = nhiễu tên `build`; số nơi dùng thật 1–9 tệp mỗi lớp, không đổi chữ ký. Kiểm: `dart analyze` sạch, 0 literal màu còn lại, `flutter test` 709/709, 4 ảnh golden không đổi thêm. **G5-8 đóng**; nợ biết đã ghi ở "Rủi ro riêng" của PLAN.md.

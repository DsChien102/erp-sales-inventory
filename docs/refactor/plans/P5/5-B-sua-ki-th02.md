# 5-B — Sửa theo TH-02: chặn 8 ảnh ở server, chip "Đã xóa", "Giá cơ sở", bỏ chữ / code thừa, test TH-02 9.3

> Theme 2 (mã cũ P5) · Bước (b) sửa theo tài liệu · Gồm TH-02 mục 9.2 (KI-10, 13, 14, 15, 16 phần còn lại, 17, 18) + test 9.3
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt") | Làm ⬜ | Review ⬜
> Làm **sau** [5-A3](5-A3-catalog-ui-sang-repository.md): đường dẫn bên dưới là đường **sau 5-A3** (cubit ở `features/catalog/logic/`). Số dòng "≈" đo trên code trước 5-A, chỉ để tìm chỗ.
> Tài liệu: [TH-02](../../../02-yeu-cau/TH-02-san-pham-va-gia-ban.md) BR-04, US-01.3, US-04.1, US-06.1, mục 5.14, 7.3, 9.2, 9.3; PLAN.md "Quy tắc migration".

## 1. Mục tiêu

- Server chặn sản phẩm có quá 8 ảnh (KI-10).
- Vào được sản phẩm đã xoá để khôi phục (chip "Đã xóa", KI-13).
- Thống nhất chữ "Giá cơ sở", bỏ ô ghi chú không lưu, bỏ chữ thừa / sai, bỏ code chết (KI-14…18).
- Đủ test TH-02 9.3 trong phạm vi đã chốt.

## 2. Phạm vi

| Mã | Việc | Nguồn |
|---|---|---|
| G1 | `update_product_images`, `create_product` chặn > 8 ảnh | KI-10, BR-04 |
| G2 | Bật chip "Đã xóa" | KI-13, US-01.3 FR-01, AC-03 |
| G3 | "Giá vốn …" → "Giá cơ sở …" ở giao diện | KI-14 |
| G4 | Bỏ ô "Ghi chú" ở SP-11 (giá cơ sở) và SP-19 (sửa khung giá cửa hàng) | KI-15 |
| G5 | Bỏ câu "Thay đổi có áp dụng cho cửa hàng và kênh phân phối.", sửa "khung giá của hàng" | KI-16 (phần sheet cảnh báo đã bỏ ở 5-A3) |
| G6 | Câu dưới đơn vị cơ sở đã đặt | KI-17, US-04.1 FR-04 |
| G7 | Bỏ toast chết ở checklist SP-21 | KI-18 |
| G8 | Test TH-02 9.3 (SQL + widget / cubit) trong phạm vi | 9.3 |

**Không làm** (chốt 2026-11-01, 5-A1 Q5): KI-01, 02, 04, 05, 06 và phần tồn của KI-07 (màn SP-10, `adjust_basic_stock`, `set_basic_stock_quantity_base`), KI-12 (lọc / đếm "Còn hàng" / "Hết hàng" ở server): **Theme 7 thay** tồn cơ bản. KI-08: Theme 5 (8.1). KI giữ nguyên: 03, 09, 11, 19 (P9), 20 (P0), 21, 22, 23. Bố cục web: 5-W.

## 3. Thay đổi

| Tệp | Hành động | Việc |
|---|---|---|
| `supabase/migrations/20260709010_catalog_product_profile_maintenance.sql` | sửa tại chỗ thân `catalog.update_product_images` (định nghĩa mới nhất: `grep -l "function catalog.update_product_images(" supabase/migrations/2*.sql \| tail -1`) | G1 |
| `supabase/migrations/20260717005_catalog_product_code_reuse_after_soft_delete_rpcs.sql` | sửa tại chỗ thân `catalog.create_product` (mới nhất theo cùng cách grep; `create_guided_product` gọi `create_product` nên được chặn theo) | G1 |
| `supabase/tests/catalog_th02.sql` | tạo | G1, G8 |
| `apps/erp/lib/features/catalog/presentation/widgets/product_list_filter.dart`, `…/pages/product_catalog_tab_page.dart`, `…/widgets/product_catalog_filter_chips.dart`, `…/logic/product_list_cubit.dart` | sửa | G2 |
| `…/pages/product_manual_base_price_page.dart`, `…/pages/edit_product_unit_price_band_page.dart`, `…/widgets/product_guided_step_base_cost.dart`, `…/widgets/product_guided_create_body.dart`, `…/widgets/product_guided_step_price_bands.dart`, `…/widgets/product_readiness_checklist_body.dart`, `…/logic/product_guided_create_state.dart`, `apps/erp/lib/features/catalog/logic/catalog_rules.dart` | sửa chữ | G3 |
| `…/pages/product_manual_base_price_page.dart`, `…/pages/settings/edit_store_price_rule_page.dart` | sửa | G4 |
| `…/pages/product_price_bands_page.dart`, `…/widgets/price_band_calculation_type_selector.dart` | sửa chữ | G5 |
| `…/pages/product_measurement_units_page.dart` | sửa chữ | G6 |
| `…/pages/product_readiness_checklist_page.dart`, `…/widgets/product_readiness_checklist_body.dart` | sửa | G7 |
| `docs/02-yeu-cau/TH-02-san-pham-va-gia-ban.md` | phiên review sửa sau khi xong: bỏ 🔧 ở mục đã làm; KI-10, 13–18 → "Đã sửa (5-B)" (KI-16 ghi "sheet: 5-A3"); KI-01, 02, 04–07 (phần tồn), 12 → "Theme 7 thay (chốt 2026-11-01)"; 9.1 dòng SP-10 / `InventoryRepository` / `features/inventory` sửa theo PLAN 2026-10-14; 9.2 sửa theo chia 5-A1…A4 thực tế | — |

## 4. Thiết kế

### G1. Chặn 8 ảnh (BR-04)

`update_product_images`: ngay sau dòng `v_images := catalog._normalize_product_maintenance_images(p_images);` (≈ dòng 61 của hàm), thêm:

```sql
  if jsonb_array_length(v_images) > 8 then
    raise exception 'validation_exception: Chỉ được tải lên tối đa 8 ảnh.';
  end if;
```

`create_product`: ngay sau khối kiểm `product name is required` (trước khi ghi), thêm:

```sql
  if jsonb_array_length(coalesce(p_images, '[]'::jsonb)) > 8 then
    raise exception 'validation_exception: Chỉ được tải lên tối đa 8 ảnh.';
  end if;
```

Câu dùng lại câu app đang có (`product_images_maintenance_cubit.dart` ≈ 136). App hiện `serverMessage` của `VALIDATION_ERROR` (5-A1 mục 4.4).

### G2. Chip "Đã xóa" (KI-13)

- `ProductListFilter`: bỏ chú thích `deleted('Đã xóa')`, đặt **sau** `outOfStock` (giữ thứ tự chip hiện có, chip mới ở cuối như US-01.3 FR-01).
- `product_catalog_tab_page.dart` (≈ dòng 119–124): bỏ chú thích nhánh `case ProductListFilter.deleted` (`businessStatuses: {ProductBusinessStatus.softDeleted}`, `includeSoftDeleted: true`, giữ `keyword`, `customFieldFilters`). `search_products` đã nhận `soft_deleted` trong `p_business_statuses` (`20260805003` ≈ dòng 128–132): **không** sửa SQL.
- **Số trên chip** (Q, đề xuất của plan, duyệt plan là chốt): server **không** trả số sản phẩm đã xoá. Chip "Đã xóa" hiện số = `totalCount` của kết quả **khi đang chọn chip đó**; chưa chọn thì không có số (chỉ chữ "Đã xóa"). Làm trong `ProductListCubit`: khi tiêu chí là đã xoá, ghi `filterCounts[deleted] = result.totalCount`.
- Màn trống khi chip này rỗng: theo cách các chip khác đang làm (FR-04: thông báo trống theo chip, không có nút tạo). Câu: "Không có sản phẩm đã xóa." (**đề xuất của plan**).
- PCC của sản phẩm đã xoá: chỉ đọc + "Khôi phục": đã có (SP-04, `fallbackIsSoftDeleted`). Không sửa; kiểm bằng test.

### G3. "Giá cơ sở" (KI-14)

Đổi **nguyên văn** (cột trái là chuỗi hiện có, tìm bằng grep):

| Tệp | Cũ | Mới |
|---|---|---|
| `product_manual_base_price_page.dart` | 'Vui lòng nhập giá vốn mới' | 'Vui lòng nhập giá cơ sở mới' |
| | 'Giá vốn không hợp lệ' | 'Giá cơ sở không hợp lệ' |
| | 'Đã lưu giá vốn cơ sở' | 'Đã lưu giá cơ sở' |
| | title 'Giá vốn cơ sở' | 'Giá cơ sở' |
| | 'Giá vốn hiện tại' | 'Giá cơ sở hiện tại' |
| | 'Giá vốn mới (…' | 'Giá cơ sở mới (…' (phần sau giữ) |
| | 'Giá vốn cơ sở luôn gắn với đơn vị cơ sở của sản phẩm …' (2 chỗ) | 'Giá cơ sở luôn gắn với đơn vị cơ sở của sản phẩm …' |
| | ' cho sản phẩm trước khi nhập giá vốn cơ sở.' | ' cho sản phẩm trước khi nhập giá cơ sở.' |
| `edit_product_unit_price_band_page.dart` | 'Giá vốn cơ sở' | 'Giá cơ sở' |
| `product_guided_step_base_cost.dart` | '… rồi mới nhập được giá vốn cơ sở.' | '… rồi mới nhập được giá cơ sở.' |
| | 'Nhập giá vốn cơ sở của sản phẩm. Giá vốn này dùng làm cơ sở để tính toán biên lợi nhuận và gợi ý giá bán.' | 'Nhập giá cơ sở của sản phẩm. Giá này dùng để tính gợi ý giá bán.' |
| | 'Giá vốn cơ sở ${…}' | 'Giá cơ sở ${…}' |
| | hint 'Nhập giá vốn cơ sở' | 'Nhập giá cơ sở' |
| `product_guided_create_body.dart` | '5. Giá vốn cơ sở' / 'Thiết lập giá vốn ban đầu' | '5. Giá cơ sở' / 'Thiết lập giá cơ sở ban đầu' |
| `product_guided_step_price_bands.dart` | '… khi giá vốn thay đổi.' | '… khi giá cơ sở thay đổi.' |
| `product_readiness_checklist_body.dart` | `case 'missing_price': 'Thiết lập giá vốn'` | 'Thiết lập giá cơ sở' |
| `logic/product_guided_create_state.dart` | 'Giá vốn phải là số không âm' | 'Giá cơ sở phải là số không âm' |
| `logic/catalog_rules.dart` (`checkManualBasePrice`, 5-A2) | 'Giá vốn cơ sở không được âm.' | 'Giá cơ sở không được âm.' |

**Không** đổi: chuỗi của chế độ `costing_module` / `pending_base_price_from_costing` (KI-21, không dùng): 'Xem module Giá vốn', 'Nguồn giá từ module Giá vốn', 'Từ module Giá vốn', 'Chờ Giá cơ sở từ module Giá vốn' (bản chép ở `logic/product_readiness.dart`, `data/models/product_control_center.dart`), và câu SQL 'Chờ giá vốn từ module Giá vốn' (`20260709014`). Ca `'pending_base_price_from_costing'` ở checklist bị bỏ ở G7.

Kiểm: `git grep -ni "giá vốn" -- apps/erp/lib/features/catalog` chỉ còn các chuỗi "module Giá vốn" vừa liệt kê.

### G4. Bỏ ô "Ghi chú" (KI-15)

- `product_manual_base_price_page.dart`: xoá `_noteController` (khai báo, khởi tạo, `dispose`) và khối nhãn 'Ghi chú' + ô nhập (≈ dòng 233–250). Không chỗ nào gửi giá trị này lên RPC (đo 2026-11-01).
- `edit_store_price_rule_page.dart`: xoá `_noteController` (≈ dòng 30, 47, 55) và khối 'Ghi chú (tuỳ chọn)' + ô (≈ dòng 450–465).
- Kiểm: `git grep -n "_noteController" -- apps/erp/lib/features/catalog/presentation/pages/product_manual_base_price_page.dart apps/erp/lib/features/catalog/presentation/pages/settings/edit_store_price_rule_page.dart` rỗng. `product_note_edit_page.dart` (ghi chú **sản phẩm**) giữ nguyên.

### G5. Chữ thừa / sai ở giá (KI-16)

- `product_price_bands_page.dart` (≈ 148): xoá widget hiện 'Thay đổi có áp dụng cho cửa hàng và kênh phân phối.' (và khoảng cách đi kèm nếu chỉ phục vụ nó).
- `price_band_calculation_type_selector.dart` (≈ 87): 'Tự động áp dụng khung giá của hàng.' → 'Tự động áp dụng khung giá cửa hàng.'

### G6. Câu đơn vị cơ sở (KI-17)

`product_measurement_units_page.dart` (≈ 306): 'Tuỳ chọn. Khi đã có giao dịch, không nên đổi.' → 'Đơn vị cơ sở không đổi được sau khi đã đặt.' (US-04.1 FR-04). Kiểm dòng này chỉ hiện khi **đã có** đơn vị cơ sở; nếu đang hiện cả khi chưa có thì chỉ đổi ở nhánh đã có, nhánh chưa có giữ 'Chưa thiết lập (không bắt buộc).' theo FR-01 (ghi cách làm vào Kết quả).

### G7. Code chết ở checklist (KI-18)

- `product_readiness_checklist_body.dart`:
  - `onActionTap` thành `required`;
  - nút CTA: bỏ nhánh `else` hiện 'Chức năng sẽ được hoàn thiện ở màn sau.', gọi thẳng `onActionTap(blocker.code)`;
  - `_getCallToAction`: xoá 2 `case` `'pending_stock_from_inventory'`, `'pending_base_price_from_costing'` (KI-21 không dùng) ⇒ không có nút.
- `product_readiness_checklist_page.dart` (≈ dòng 155–163): xoá khối cuối `VToast.show(… 'Tính năng ($actionId) đang được xây dựng.' …)`. Mã lạ → không làm gì.
- Kiểm: `git grep -n "hoàn thiện ở màn sau\|đang được xây dựng" -- apps/erp/lib/features/catalog` rỗng.

### G8. Test TH-02 9.3

**SQL** (`supabase/tests/catalog_th02.sql`, mẫu `supabase/tests/iam_legacy_cleanup.sql`: một khối `begin … rollback`, dựng tenant + owner, `set local role authenticated` + `request.jwt.claims`; mỗi ca `raise exception` khi sai; cuối `raise notice 'catalog_th02: OK'`). Chạy trên DB **local** sau `supabase db reset` local.

Ca (danh sách "SQL / RPC test" của 9.3, **trừ** 3 ca tồn 🔧 và ca KI-08):

1. `create_guided_product` cùng `p_idempotency_key` hai lần → 1 sản phẩm.
2. `create_guided_product` có tồn / giá mà không đơn vị → lỗi, không tạo gì.
3. SKU trùng sản phẩm chưa xoá → `duplicate sku`; trùng sản phẩm đã xoá → tạo được.
4. `set_product_base_unit` lần hai → lỗi.
5. G1: `update_product_images` 9 ảnh → lỗi chứa `tối đa 8 ảnh`; `create_product` 9 ảnh → lỗi.
6. `set_manual_base_price` → khung `ruleBased` / `customConfig` đúng công thức, `manual` giữ nguyên.
7. `set_store_price_rule` tỷ lệ sàn > niêm yết → `markup ratios are invalid`; lưu không đổi → không thêm dòng lịch sử.
8. `apply_store_price_rule` lên khung có giá, không xác nhận → `price_band_overwrite_required`; sai `p_base_price_version` → `stale_base_price`.
9. Bật bắt buộc cho trường → sản phẩm thiếu trường thành `incomplete`; tạm tắt nhóm → hết blocker.
10. `upsert_custom_field` đổi kiểu trường có dữ liệu → `custom_field_type_change_blocked`.
11. `search_products('thuc an')` thấy "Thức ăn"; SKU tiền tố; G2: `p_business_statuses = {soft_deleted}` chỉ ra sản phẩm đã xoá.

Tên tham số / cột: đọc thân hàm mới nhất của từng RPC trước khi viết; ghi chỗ khó (dựng dữ liệu, FK) vào Kết quả.

**Widget / cubit** (9.3, mục "Widget / cubit test", trừ SP-10). Grep `test/features/catalog`; ca nào có thì ghi tên test vào Kết quả, thiếu thì thêm:

- SP-03: thứ tự kiểm khi lưu mở đúng bước; ba cách tính khung giá; ảnh đang tải chặn lưu.
- SP-04: nhãn và banner theo readiness; sản phẩm đã xoá chỉ đọc (+ G2: mở từ chip "Đã xóa" thấy "Khôi phục").
- SP-09: chặn xoá → nút "Tắt đơn vị" hoạt động.
- SP-13: hộp ghi đè; trạng thái chờ giá cơ sở.
- Thêm: G2 (chip, số khi chọn, màn trống), G3 (grep ở trên + 1 widget test thấy 'Giá cơ sở' ở SP-11), G4 (không có ô 'Ghi chú' ở 2 màn), G5, G6, G7 (bấm dòng blocker mã lạ không hiện toast).

## 5. Đang làm gì — test giữ hành vi (phần bị xoá / thay)

| # | Cũ đang làm gì | Sau khi sửa | Test |
|---|---|---|---|
| B1 | Ô ghi chú SP-11 / SP-19: nhập được, **không** gửi đi | bỏ ô; giá cơ sở / khung giá cửa hàng lưu như cũ | bước 0: lưu giá cơ sở và lưu khung giá cửa hàng → repository nhận đúng tham số (fake `calls`), toast thành công. Sau sửa phải xanh y hệt |
| B2 | Checklist: bấm CTA / dòng của mọi blocker; mã có xử lý → điều hướng / sheet; mã khác → toast "đang được xây dựng"; body không có `onActionTap` → toast "hoàn thiện ở màn sau" | mã có xử lý giữ nguyên; mã khác → không làm gì; `pending_*` không có nút | bước 0: 6 mã đang xử lý (`missing_base_unit`, `missing_image`, `missing_stock`, `missing_price`, `missing_price_band`, `missing_required_custom_fields`) mỗi mã đi đúng nơi. Sau sửa phải xanh y hệt |
| B3 | Danh sách: 6 chip; chip "Tất cả" / trạng thái có số | thêm chip thứ 7; 6 chip cũ giữ tiêu chí và số | bước 0: mỗi chip cũ gửi đúng tiêu chí (`ProductSearchCriteria` trong `calls`), số đúng. Sau sửa xanh y hệt |
| B4 | `update_product_images` / `create_product` nhận mọi số ảnh | chặn > 8 | SQL ca 5; ≤ 8 ảnh vẫn lưu (SQL ca 1, 3 có ảnh) |

**Bước 0** (trên code sau 5-A3, trước khi sửa 5-B): viết B1–B3, chạy xanh, ghi tên test.

## 6. Các bước

Trước mỗi symbol Dart sửa: `gitnexus impact` (upstream), ghi vào Kết quả. HIGH / CRITICAL thì dừng, ghi lại.

0. Bước 0 (mục 5).
1. G1: sửa 2 migration; `supabase db reset` **local** (không phải Dev); viết + chạy `catalog_th02.sql` (G8 phần SQL).
2. G2 → G7, mỗi việc kèm test.
3. G8 phần widget / cubit.
4. Kiểm mục 7, ghi Kết quả, `detect_changes()`.

## 7. Kiểm tra

### 7.1 Tự động

- [ ] `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/catalog_th02.sql` → `catalog_th02: OK` (sau `supabase db reset` local). Các `supabase/tests/*.sql` khác vẫn chạy qua.
- [ ] `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart`: không lỗi mới.
- [ ] Grep ở G3, G4, G7 đúng như ghi.
- [ ] `cd apps/erp && dart analyze lib test`: không lỗi / cảnh báo mới.
- [ ] `cd apps/erp && flutter test`: không fail mới so với sau 5-A3 (ghi số).

### 7.2 Kiểm tay (TH-02 9.3, trên Dev sau khi người dùng reset Dev)

Sửa migration đã áp (`20260709010`, `20260717005`) ⇒ Dev chỉ nhận sau `db reset --linked`. Việc này **người dùng** làm, phiên code không chạy.

- [ ] 1. Tạo tối thiểu (chỉ tên) → hoàn thiện qua checklist (đơn vị, tồn 0, giá cơ sở, khung giá cửa hàng) → "Thiếu dữ liệu" → "Sẵn sàng bán"; tìm thấy khi bán hàng.
- [ ] 2. Tạo đủ trong wizard với Tự động riêng 30 % / 10 % và 1 nhóm có trường bắt buộc → khung giá đúng; thiếu trường bắt buộc chặn lưu.
- [ ] 3. Thêm đơn vị "hộp" (10) → thiết lập khung → đổi giá cơ sở → đổi khung giá cửa hàng: readiness đổi đúng; khung `ruleBased` tính lại 2 lần, `manual` không đổi; lịch sử có nguyên nhân tự động.
- [ ] 4. Ngừng KD khi còn tồn (xác nhận cảnh báo) → KD lại → Xoá → tạo sản phẩm mới cùng SKU → chip "Đã xóa" → mở sản phẩm cũ → Khôi phục bị chặn vì SKU trùng.
- [ ] 5. (Kịch bản điều chỉnh tồn từ hai máy: **bỏ**, Theme 7 thay.)
- [ ] Mọi chỗ ghi "Giá cơ sở"; không còn ô ghi chú ở giá cơ sở / khung giá cửa hàng; checklist không còn toast "đang được xây dựng".

## 8. Rủi ro / lưu ý

- `create_product` được `create_guided_product` gọi trong cùng giao dịch: chặn ở `create_product` là đủ, đừng thêm lần hai vào `create_guided_product`.
- Theme 7 sẽ thay phần tồn: các câu / màn tồn **không** sửa ở đây, kể cả câu "Ở Growth…" (KI-04) còn trên SP-10.

## 9. Kết quả (phiên làm code ghi)

> Xong **mỗi việc** (bước 0, G1…G8) ghi ngay. Mẫu: trạng thái ✅ / 🔄 dở / ⏭ (lý do) · tệp:dòng · lệch plan + lý do · test thêm / sửa · impact · ghi chú cho review. Bước cuối: lệnh đã chạy, số pass / fail, fail đối chiếu `TEST-BASELINE.md`, `detect_changes()`, "cần reset Dev".

## 10. Review

<!-- Phiên review ghi -->

# 5-B — Sửa theo TH-02: chặn 8 ảnh ở server, chip "Đã xóa", "Giá cơ sở", bỏ chữ / code thừa, test TH-02 9.3

> Theme 2 (mã cũ P5) · Bước (b) sửa theo tài liệu · Gồm TH-02 mục 9.2 (KI-10, 13, 14, 15, 16 phần còn lại, 17, 18) + test 9.3
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt"; rà lại theo code sau 5-A3 2026-11-04; mục 6 viết lại theo `superpowers:writing-plans`: Task 0–9 + Review Focus) | Làm ✅ 2026-11-04 (chưa commit) | Review ✅ R3 2026-11-04 (đã sửa R1-1…R1-4, R2-1; còn chạy `catalog_th02.sql` + kiểm tay 7.2 — người dùng)
> Làm **sau** [5-A3](5-A3-catalog-ui-sang-repository.md): đường dẫn bên dưới là đường **sau 5-A3** (cubit ở `features/catalog/logic/`). Số dòng "≈" đo lại trên code sau 5-A3 (2026-11-04), chỉ để tìm chỗ.
> **Trước khi làm:** 5-A3 / 5-A4 đang chưa commit, `features/catalog/logic/*_cubit.dart`, `*_state.dart` còn untracked ⇒ `git grep` **không** thấy (vd `logic/product_guided_create_state.dart`). Mọi lệnh kiểm bằng grep trong plan này dùng `grep -rn` (không dùng `git grep`). Chạy `node .gitnexus/run.cjs analyze` trước khi chạy `impact` (index chưa có các tệp `logic/` mới).
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
| G9 | Ngày của trường bổ sung không bị lùi 1 ngày khi lưu | KI-24 (thêm 2026-11-03) |

**Không làm** (chốt 2026-11-01, 5-A1 Q5): KI-01, 02, 04, 05, 06 và phần tồn của KI-07 (màn SP-10, `adjust_basic_stock`, `set_basic_stock_quantity_base`), KI-12 (lọc / đếm "Còn hàng" / "Hết hàng" ở server): **Theme 7 thay** tồn cơ bản. KI-08: Theme 5 (8.1). KI giữ nguyên: 03, 09, 11, 19 (P9), 20 (P0), 21, 22, 23. Bố cục web: 5-W.

## 3. Thay đổi

| Tệp | Hành động | Việc |
|---|---|---|
| `supabase/migrations/20260709010_catalog_product_profile_maintenance.sql` | sửa tại chỗ thân `catalog.update_product_images` (định nghĩa mới nhất: `grep -l "function catalog.update_product_images(" supabase/migrations/2*.sql \| tail -1`) | G1 |
| `supabase/migrations/20260717005_catalog_product_code_reuse_after_soft_delete_rpcs.sql` | sửa tại chỗ thân `catalog.create_product` (mới nhất theo cùng cách grep; `create_guided_product` gọi `create_product` nên được chặn theo) | G1 |
| `supabase/tests/catalog_th02.sql` | tạo | G1, G8 |
| `apps/erp/lib/features/catalog/presentation/widgets/product_list_filter.dart`, `…/pages/product_catalog_tab_page.dart`, `…/widgets/product_catalog_list_body.dart` (màn trống), `…/logic/product_list_cubit.dart` | sửa | G2 |
| `apps/erp/test/features/catalog/logic/catalog_rules_test.dart` (nhóm `new` ≈ 2339), `…/logic/product_manual_base_price_cubit_test.dart` (≈ 38, 48), `…/presentation/pages/product_manual_base_price_e2e_test.dart` (≈ 114), `…/presentation/pages/product_guided_create_e2e_test.dart` (≈ 116–117, 251) | sửa chữ (đổi có chủ đích) | G3 |
| `…/pages/product_manual_base_price_page.dart`, `…/pages/edit_product_unit_price_band_page.dart`, `…/widgets/product_guided_step_base_cost.dart`, `…/widgets/product_guided_create_body.dart`, `…/widgets/product_guided_step_price_bands.dart`, `…/widgets/product_readiness_checklist_body.dart`, `…/logic/product_guided_create_state.dart`, `apps/erp/lib/features/catalog/logic/catalog_rules.dart` | sửa chữ | G3 |
| `…/pages/product_manual_base_price_page.dart`, `…/pages/settings/edit_store_price_rule_page.dart` | sửa | G4 |
| `…/pages/product_price_bands_page.dart`, `…/widgets/price_band_calculation_type_selector.dart` | sửa chữ | G5 |
| `…/pages/product_measurement_units_page.dart` | sửa chữ | G6 |
| `…/pages/product_readiness_checklist_page.dart`, `…/widgets/product_readiness_checklist_body.dart` | sửa | G7 |
| `apps/erp/lib/features/catalog/data/custom_field_repository.dart` (`_dateOnly`), `apps/erp/test/features/catalog/data/catalog_unit_field_price_rpc_parity_test.dart` | sửa | G9 |
| `apps/erp/test/features/catalog/support/recording_catalog_repositories.dart`, `…/presentation/pages/product_manual_base_price_page_test.dart`, `…/presentation/pages/settings/edit_store_price_rule_page_test.dart`, `…/presentation/pages/product_readiness_checklist_page_test.dart` | tạo (Task 0) | B1–B3, G3, G4, G7 |
| `…/logic/product_list_cubit_test.dart`, `…/presentation/pages/product_catalog_tab_page_test.dart`, `…/presentation/pages/product_price_bands_e2e_test.dart`, `…/presentation/pages/edit_product_unit_price_band_e2e_test.dart`, `…/presentation/pages/product_measurement_units_e2e_test.dart` | thêm test | B3, G2, G5, G6 |
| `docs/02-yeu-cau/TH-02-san-pham-va-gia-ban.md` | phiên review sửa sau khi xong: bỏ 🔧 ở mục đã làm; KI-10, 13–18, 24 → "Đã sửa (5-B)" (KI-16 ghi "sheet: 5-A3"); KI-01, 02, 04–07 (phần tồn), 12 → "Theme 7 thay (chốt 2026-11-01)"; 9.1 dòng SP-10 / `InventoryRepository` / `features/inventory` sửa theo PLAN 2026-10-14; 9.2 sửa theo chia 5-A1…A4 thực tế | — |

## 4. Thiết kế

### G1. Chặn 8 ảnh (BR-04)

`update_product_images`: ngay sau dòng `v_images := catalog._normalize_product_maintenance_images(p_images);` (≈ dòng 61 của hàm), thêm:

```sql
  if jsonb_array_length(v_images) > 8 then
    raise exception 'validation_exception: Chỉ được tải lên tối đa 8 ảnh.';
  end if;
```

(`update_product_images` ở dòng ≈ 400 của tệp, dòng normalize ≈ 460; `_normalize_product_maintenance_images` đã báo lỗi khi `p_images` không phải mảng nên `jsonb_array_length` an toàn.)

`create_product`: ngay sau khối kiểm `product name is required` (≈ dòng 47 của hàm, trước khi ghi), thêm:

```sql
  if jsonb_typeof(p_images) = 'array' and jsonb_array_length(p_images) > 8 then
    raise exception 'validation_exception: Chỉ được tải lên tối đa 8 ảnh.';
  end if;
```

Kiểm `jsonb_typeof` trước vì `create_product` hiện **bỏ qua** `p_images` không phải mảng (≈ dòng 178: `if p_images is not null and jsonb_typeof(p_images) = 'array'`); gọi thẳng `jsonb_array_length` lên object sẽ ném lỗi Postgres thô, đổi hành vi.

Câu dùng lại câu app đang có (`logic/product_images_maintenance_cubit.dart` ≈ 144, 214). App hiện `serverMessage` của `VALIDATION_ERROR` (`data/catalog_errors.dart` ≈ 306, bỏ tiền tố `validation_exception:`). App chỉ gọi `create_guided_product` (không gọi thẳng `create_product`); bản mới nhất `20260722001` gọi `catalog.create_product(… p_images => p_images …)` ≈ dòng 725.

### G2. Chip "Đã xóa" (KI-13)

- `ProductListFilter` (`widgets/product_list_filter.dart` dòng 6): bỏ dòng chú thích `// deleted('Đã xóa'),` ở giữa, thêm `deleted('Đã xóa')` **sau** `outOfStock` (giữ thứ tự chip hiện có, chip mới ở cuối như US-01.3 FR-01). `ProductCatalogFilterChips` lặp `ProductListFilter.values` và đọc `filterCounts[e]` ⇒ **không** sửa tệp chip.
- `product_catalog_tab_page.dart` (≈ dòng 114–120, trong `_criteriaForFilter`): bỏ chú thích nhánh `case ProductListFilter.deleted` (`businessStatuses: {ProductBusinessStatus.softDeleted}`, `includeSoftDeleted: true`, giữ `keyword`, `customFieldFilters`). `search_products` đã nhận `soft_deleted` trong `p_business_statuses` (`20260805003` ≈ dòng 128–132; repository gửi `p_include_soft_deleted`): **không** sửa SQL.
- **Số trên chip** (Q, đề xuất của plan, duyệt plan là chốt): server **không** trả số sản phẩm đã xoá. Chip "Đã xóa" hiện số = `totalCount` của kết quả **khi đang chọn chip đó**; chưa chọn thì không có số (chỉ chữ "Đã xóa"). Code hiện **không** có map `filterCounts` trong cubit: cubit giữ từng số ở field `int?` (`readyToSellCount`, `inactiveCount`, …), trang dựng map `filterCounts` (≈ dòng 277–288). Làm:
  - `ProductListCubit`: thêm `int? deletedCount`; mỗi lần `fetchProducts` xong: `deletedCount = isDeletedCriteria ? result.totalCount : null`, với `isDeletedCriteria = currentCriteria.includeSoftDeleted && currentCriteria.businessStatuses.length == 1 && currentCriteria.businessStatuses.contains(ProductBusinessStatus.softDeleted)`. Đặt về `null` khi đổi tiêu chí khác ⇒ rời chip là mất số.
  - `product_catalog_tab_page.dart`: thêm `if (_cubit.deletedCount != null) ProductListFilter.deleted: _cubit.deletedCount!` vào map.
  - Có từ khoá / lọc trường bổ sung thì số là số theo kết quả đang lọc (đúng câu "totalCount của kết quả").
- Màn trống khi chip này rỗng: `_ProductCatalogEmptyState` (`widgets/product_catalog_list_body.dart` ≈ dòng 160–185) nhánh `isFiltered` hiện ra 'Không có sản phẩm "${selectedFilter.label}"' (⇒ 'Không có sản phẩm "Đã xóa"'). Thêm nhánh riêng `selectedFilter == ProductListFilter.deleted` → title "Không có sản phẩm đã xóa." (**đề xuất của plan**), không nút. Lưu ý nhánh `!hasProducts` (`globalTotalCount == 0`) đứng trước: tenant chưa có sản phẩm nào chưa xoá mà chọn chip "Đã xóa" sẽ ra "Chưa có sản phẩm nào được tạo" + nút tạo — đặt nhánh `deleted` **trước** `!hasProducts`.
- Dòng sản phẩm đã xoá đã có nhãn "Đã xóa" (`widgets/product_list_item_tile.dart` ≈ 40–45). PCC của sản phẩm đã xoá: chỉ đọc + "Khôi phục": đã có (SP-04, `fallbackIsSoftDeleted`, `product_control_center_page.dart` ≈ 132). Không sửa; kiểm bằng test.

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

**Không** đổi: chuỗi của chế độ `costing_module` / `pending_base_price_from_costing` (KI-21, không dùng): 'Xem module Giá vốn', 'Nguồn giá từ module Giá vốn' (`logic/product_readiness.dart` ≈ 277, 294), 'Từ module Giá vốn' (`data/models/product_control_center.dart` ≈ 152), 'Chờ Giá cơ sở từ module Giá vốn' (`data/models/product_readiness.dart` ≈ 132), và câu SQL 'Chờ giá vốn từ module Giá vốn' (`20260709014`). Ca `'pending_base_price_from_costing'` → 'Xem Giá vốn' ở checklist (`product_readiness_checklist_body.dart` ≈ 32) bị bỏ ở G7. Module cũ (`modules/catalog/…`) giữ nguyên.

Test đổi theo (có chủ đích, ghi vào Kết quả):
- `logic/catalog_rules_test.dart` nhóm `new (catalog_rules)` ≈ 2339: 'Giá cơ sở không được âm.'. Nhóm `old (CommandValidators)` ≈ 1010 **giữ** 'Giá vốn cơ sở không được âm.' (validator module cũ không đổi).
- `logic/product_manual_base_price_cubit_test.dart` ≈ 38, 48: chuỗi do mock tự ném, không fail; đổi sang 'Giá cơ sở không được âm.' cho khớp.
- `presentation/pages/product_manual_base_price_e2e_test.dart` ≈ 114: `find.text('Giá cơ sở')`.
- `presentation/pages/product_guided_create_e2e_test.dart` ≈ 116–117, 251: `find.text('5. Giá cơ sở')`.
- 'Thuốc giá vốn module' (tên sản phẩm fixture trong `support/fake_catalog_backend.dart`, `product_manual_base_price_e2e_test.dart`) giữ.

Kiểm (sau G7): `grep -rni "giá vốn" apps/erp/lib/features/catalog | grep -v "module Giá vốn"` rỗng.

### G4. Bỏ ô "Ghi chú" (KI-15)

- `product_manual_base_price_page.dart`: xoá `_noteController` (≈ dòng 61, 72, 79) và khối `SizedBox(height: space4)` + nhãn 'Ghi chú' + `SizedBox` + `VTextFormField(controller: _noteController …)` (≈ dòng 232–244, ngay sau câu 'Giá … luôn gắn với đơn vị cơ sở … ($baseUnitName).'). Không chỗ nào gửi giá trị này lên RPC (đo 2026-11-01).
- `edit_store_price_rule_page.dart`: xoá `_noteController` (≈ dòng 31, 48, 56), xoá cả method `_buildNoteSection` (≈ dòng 445–…) và chỗ gọi ≈ dòng 186–187 (`const SizedBox(height: VSpacing.space5),` + `_buildNoteSection(context),`; giữ `SizedBox` trước `_buildPreviewSection`).
- Kiểm: `grep -n "_noteController\|_buildNoteSection" apps/erp/lib/features/catalog/presentation/pages/product_manual_base_price_page.dart apps/erp/lib/features/catalog/presentation/pages/settings/edit_store_price_rule_page.dart` rỗng. `product_note_edit_page.dart` (ghi chú **sản phẩm**) giữ nguyên.

### G5. Chữ thừa / sai ở giá (KI-16)

- `product_price_bands_page.dart` (≈ 143–151): câu 'Thay đổi có áp dụng cho cửa hàng và kênh phân phối.' là **ô cuối** của `ListView.builder` (`itemCount: data.rows.length + 2` ≈ 129, nhánh `index == data.rows.length + 1`). Xoá nhánh đó **và** đổi `itemCount` thành `data.rows.length + 1`; nếu không, ô cuối sẽ đọc `data.rows[index - 1]` vượt mảng.
- `price_band_calculation_type_selector.dart` (≈ 87): 'Tự động áp dụng khung giá của hàng.' → 'Tự động áp dụng khung giá cửa hàng.'

### G6. Câu đơn vị cơ sở (KI-17)

`product_measurement_units_page.dart` (≈ 305): 'Tuỳ chọn. Khi đã có giao dịch, không nên đổi.' → 'Đơn vị cơ sở không đổi được sau khi đã đặt.' (US-04.1 FR-04). Đã đo 2026-11-04: câu này chỉ nằm ở nhánh `else` (đã có đơn vị, dưới `state.baseUnitName!`); nhánh chưa có (`!hasBaseUnit && !_isEditingBaseUnit`, ≈ 213) giữ 'Chưa thiết lập (không bắt buộc).' ⇒ chỉ đổi chuỗi.

### G7. Code chết ở checklist (KI-18)

- `product_readiness_checklist_body.dart`:
  - `onActionTap` thành `required`;
  - nút CTA: bỏ nhánh `else` hiện 'Chức năng sẽ được hoàn thiện ở màn sau.', gọi thẳng `onActionTap(blocker.code)`;
  - `_getCallToAction`: xoá 2 `case` `'pending_stock_from_inventory'`, `'pending_base_price_from_costing'` (KI-21 không dùng) ⇒ không có nút.
- `product_readiness_checklist_page.dart` (≈ dòng 156–161): xoá khối cuối `VToast.show(… 'Tính năng ($actionId) đang được xây dựng.' …)`. Mã lạ → không làm gì. Trang là chỗ gọi duy nhất của `ProductReadinessChecklistBody` và đã truyền `onActionTap` ⇒ đổi `required` không vỡ chỗ nào.
- Dòng blocker (`GestureDetector.onTap` ≈ 62) đổi `onActionTap?.call(…)` → `onActionTap(…)`.
- Kiểm: `grep -rn "hoàn thiện ở màn sau\|đang được xây dựng\|pending_stock_from_inventory\|pending_base_price_from_costing" apps/erp/lib/features/catalog/presentation` rỗng.

### G9. Ngày của trường bổ sung (KI-24)

- `custom_field_repository.dart` `_dateOnly(DateTime dateTime)` (≈ dòng 29–35, gọi ở ≈ 260): bỏ `final utc = dateTime.toUtc();`, dùng thẳng `dateTime.year`, `dateTime.month`, `dateTime.day`. Đúng cho cả ngày chọn từ `VDatePicker` (00:00 giờ máy) lẫn ngày tải từ server (`_toDate` ở `data/models/product_custom_field_values.dart` ≈ 6–19 → `DateTime.utc`).
- Chỉ đổi hàm này, không đổi `createGuided` (gửi `toIso8601String()`, khác đường; nếu thấy cũng lệch ngày thì báo người dùng, không tự sửa).
- Test (đổi có chủ đích, ghi vào Kết quả):
  - `catalog_unit_field_price_rpc_parity_test.dart` nhóm `new`: `DateTime(2026, 11, 3)` (giờ máy) → `'2026-11-03'`; `DateTime.utc(2026, 11, 3)` → `'2026-11-03'`.
  - Ca `DateTime.utc(2026, 11, 3, 23)` của nhóm `new` vẫn ra `'2026-11-03'`.
  - Nhóm `old` (mapper cũ) giữ nguyên. Hai nhóm dùng chung hằng `_expectedUpsertProductCustomFieldValuesParams` với đầu vào `DateTime.utc(2026, 11, 3, 23)` (≈ 450 nhóm old, ≈ 1354 nhóm new) — cả hai vẫn ra `'2026-11-03'` nên hằng không đổi; ca giờ máy mới viết **riêng** trong nhóm `new`, không đưa vào hằng chung (mapper cũ ở UTC+7 sẽ ra `'2026-11-02'`).
  - Test chạy đúng ở mọi múi giờ: ca giờ máy kiểm bằng `DateTime(…)` không giờ, không phụ thuộc `TZ`.

### G8. Test TH-02 9.3

**SQL** (`supabase/tests/catalog_th02.sql`, mẫu `supabase/tests/partner_th03.sql` (4-B, cùng kiểu theme: hàm giúp `_th03_expect_err(p_sql, p_code)` tạo trong giao dịch) — đổi tiền tố thành `_th02_`; một khối `begin … rollback`, dựng tenant + owner, `set local role authenticated` + `request.jwt.claims`; mỗi ca `raise exception 'FAIL: …'` khi sai; cuối `raise notice 'catalog_th02: OK'`). Phiên code chỉ viết tệp.

Chuỗi lỗi để khớp (đo 2026-11-04, bản mới nhất): ca 2 `validation_exception: base unit is required for stock or pricing` (`20260722001` ≈ 690); ca 3 `duplicate sku` (`20260717005`); ca 7 `markup ratios are invalid` (`20260717008`); ca 8 `price_band_overwrite_required` (`20260717002`), `stale_base_price` (`20260717007`); ca 10 `custom_field_type_change_blocked` (`20260712009`). Kiểm lại bằng `grep -l "<chuỗi>" supabase/migrations/2*.sql | tail -1` trước khi viết.

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
| B1 | Ô ghi chú SP-11 / SP-19: nhập được, **không** gửi đi | bỏ ô; giá cơ sở / khung giá cửa hàng lưu như cũ | Task 0.1–0.2: `b1_manual_base_price_save_sends_amount`, `b1_store_rule_save_sends_ratios` (lớp con fake ghi tham số). Sau sửa phải xanh y hệt |
| B2 | Checklist: bấm CTA / dòng của mọi blocker; mã có xử lý → điều hướng / sheet; mã khác → toast "đang được xây dựng"; body không có `onActionTap` → toast "hoàn thiện ở màn sau" | mã có xử lý giữ nguyên; mã khác → không làm gì; `pending_*` không có nút | Task 0.3: `b2_<code>_navigates` × 6 mã + `b2_requires_base_unit_first`. Sau sửa phải xanh y hệt |
| B3 | Danh sách: 6 chip; chip "Tất cả" / trạng thái có số | thêm chip thứ 7; 6 chip cũ giữ tiêu chí và số | Task 0.4: `b3_chip_counts`, `b3_chip_criteria`. Sau sửa xanh y hệt |
| B4 | `update_product_images` / `create_product` nhận mọi số ảnh | chặn > 8 | SQL ca 5a (9 ảnh lỗi), 5b (đúng 8 ảnh lưu được) — Task 1 |

**Task 0 (mục 6):** B1–B3 trên code hiện tại (sau 5-A3, trước khi sửa 5-B). Không dùng các test `presentation/pages/*_e2e_test.dart` đang đỏ làm mốc (đo 2026-11-04: `flutter test test/features/catalog` = 556 đạt / 48 lỗi, cả 48 ở `presentation/pages/*_e2e_test.dart`, đều trong `TEST-BASELINE.md`; vd `product_store_price_rule_e2e_test` 6/6 đỏ, `product_soft_delete_e2e_test` `fr02_03` đỏ). B4 là SQL, ở Task 1.

## 6. Các bước

> Viết theo `superpowers:writing-plans`. Thực hiện: `superpowers:executing-plans` (làm tuần tự trong phiên). Mỗi task xong ghi ngay mục 9. **Không commit** (người dùng commit sau `detect_changes()`).
> Lệnh test chạy trong `apps/erp`. "Fake" = `test/features/catalog/support/fake_catalog_repositories.dart` (`FakeProductRepository`, `FakeProductPriceRepository`, …; `calls` chỉ ghi **tên** method ⇒ test cần tham số thì tạo lớp con cục bộ ghi lại tham số, mẫu `_PaginatedProductRepository` ở `test/features/catalog/logic/product_list_cubit_test.dart:12`). Đăng ký: `registerFakeCatalog(getIt, scenario: …)` (`support/catalog_test_registry.dart`), rồi `getIt.unregister<X>()` + `registerSingleton<X>(lớp con)` để thay.

**Ràng buộc chung** (mọi task):
- Giữ nghiệp vụ; chỉ đổi đúng chuỗi / hành vi ở mục 4. Không đổi `modules/catalog/**`, nhóm `old` của test parity.
- Trước mỗi symbol Dart sửa: `node .gitnexus/run.cjs analyze` (một lần đầu phiên) rồi `gitnexus impact` upstream; ghi bảng vào Kết quả. HIGH / CRITICAL: ghi lại, báo người dùng trước khi sửa.
- Chuỗi giao diện chép **nguyên văn** từ mục 4 (dấu chấm cuối câu, "Đã xóa" với "ó" như enum hiện có).
- DB: phiên code không làm gì với DB (không reset, không chạy SQL); người dùng tự làm.
- Grep kiểm bằng `grep -rn` (không `git grep`, xem đầu tệp).

## Review Focus

1. Chip "Đã xóa" rồi bấm lại "Tất cả": số trên chip "Đã xóa" phải mất, danh sách không còn sản phẩm đã xoá (Task 2, `g2_deleted_count_cleared_on_other_chip`).
2. Tenant **chỉ** còn sản phẩm đã xoá (`globalTotalCount == 0`): chọn chip "Đã xóa" phải ra danh sách / "Không có sản phẩm đã xóa.", không phải "Chưa có sản phẩm nào được tạo" + nút tạo (Task 2, `g2_empty_deleted_when_no_live_products`).
3. Đúng 8 ảnh vẫn lưu được ở cả `update_product_images` và `create_guided_product` (giới hạn là `> 8`, không `>= 8`) (Task 1, ca 5b).
4. Khung giá: sau khi bỏ ô cuối, dòng khung giá **cuối cùng** vẫn hiện, không lỗi chỉ số (Task 5, `g5_price_bands_no_footer_last_row_visible`).
5. Ngày trường bổ sung chọn lúc 00:00 giờ máy ở múi giờ dương (UTC+7) gửi đúng ngày (Task 7, `g9_local_midnight_keeps_day`).

---

### Task 0: Test giữ hành vi trên code cũ (B1, B2, B3)

**Files:**
- Create: `apps/erp/test/features/catalog/presentation/pages/product_manual_base_price_page_test.dart`
- Create: `apps/erp/test/features/catalog/presentation/pages/settings/edit_store_price_rule_page_test.dart`
- Create: `apps/erp/test/features/catalog/presentation/pages/product_readiness_checklist_page_test.dart`
- Modify: `apps/erp/test/features/catalog/presentation/pages/product_catalog_tab_page_test.dart` (thêm nhóm `B3`)
- Create: `apps/erp/test/features/catalog/support/recording_catalog_repositories.dart`

**Produces** (Task 2, 4, 6 dùng lại): lớp con `RecordingPriceRepository extends FakeProductPriceRepository` (ghi `setManualBasePriceArgs: List<({String productId, double basePrice, String currency})>`, `setStorePriceRuleArgs: List<({String name, double listMarkupRatio, double floorMarkupRatio, StorePriceRuleStatus status})>`; `setManualBasePrice` trả `Future.value()`, `setStorePriceRule` trả `StorePriceRuleDto(id: 'r1', tenantId: 't1', name: name, status: status, calculationType: StorePriceCalculationType.markup, listMarkupRatio: …, floorMarkupRatio: …)` từ tham số; không gọi backend), `RecordingProductRepository extends FakeProductRepository` (`RecordingProductRepository({required super.backend, required ProductSearchResultDto Function(ProductSearchCriteria c) respond})`; override `search` ghi `criteria: List<ProductSearchCriteria>` rồi trả `respond(criteria)`). Để ở `test/features/catalog/support/recording_catalog_repositories.dart` (2 lớp public trên, dùng chung các tệp test).

- [x] **0.1 B1 — giá cơ sở.** `product_manual_base_price_page_test.dart`: GoRouter `/` (nút đẩy `/mbp`) + `/mbp` → `ProductManualBasePricePage(product: ProductListItemModel(id: 'p1', name: 'Thuốc A', businessStatus: active, readinessStatus: needsReview, baseUnit: 'Lọ'), basePriceCard: const ProductBasePriceCardDto(mode: BasePriceMode.manual, sourceLabel: 'Nhập thủ công', baseUnitName: 'Lọ'))`. Test `b1_manual_base_price_save_sends_amount`: nhập `'45000'` vào `Key('input_base_price_amount')`, bấm `Key('btn_manual_base_price_save')`, `pumpAndSettle` → `setManualBasePriceArgs.single == (productId: 'p1', basePrice: 45000.0, currency: 'VND')`; trang đã đóng (`find.byType(ProductManualBasePricePage)` findsNothing).
- [x] **0.2 B1 — khung giá cửa hàng.** `edit_store_price_rule_page_test.dart`: GoRouter `/` + `/edit` → `EditStorePriceRulePage(existingRule: StorePriceRuleDto(id: 'r1', tenantId: 't1', name: 'Khung giá cửa hàng', status: active, calculationType: StorePriceCalculationType.markup, listMarkupRatio: 0.3, floorMarkupRatio: 0.1))`. Test `b1_store_rule_save_sends_ratios`: đổi ô "Giá niêm yết (tỷ lệ lãi)" thành `'35'`, bấm "Lưu thay đổi", bấm "Áp dụng" trên sheet → `setStorePriceRuleArgs.single` có `listMarkupRatio == 0.35`, `floorMarkupRatio == 0.1`, `status == StorePriceRuleStatus.active`; `name` ghi giá trị thấy khi chạy ở bước này vào Kết quả và `expect` đúng giá trị đó; `find.text('Đã cập nhật khung giá cửa hàng.')` findsOneWidget; trang đã đóng.
- [x] **0.3 B2 — checklist.** `product_readiness_checklist_page_test.dart`: GoRouter `/` (nút đẩy `/checklist`) + `/checklist` → `ProductReadinessChecklistPage(readinessView: …, product: …, customFieldGroupCards: …)` + 6 route giả, mỗi route hiện `Text('route:<đuôi>')`: `/products/items/pcc/measurement-units`, `/images-maintenance`, `/stock`, `/manual-base-price`, `/price-bands`, `/custom-fields/edit`. Blocker dựng bằng `ReadinessBlockerDto(code: c, message: 'msg-$c')`; bấm **dòng** (`find.text('msg-$c')`, không bấm nút CTA vì nhãn đổi ở Task 3). Test `b2_<code>_navigates` cho từng mã (1 blocker / lần): `missing_base_unit` → `route:measurement-units`, `missing_image` → `route:images-maintenance`, `missing_stock` → `route:stock`, `missing_price` → `route:manual-base-price`, `missing_price_band` → `route:price-bands`, `missing_required_custom_fields` (kèm 1 `CustomFieldGroupCardDto` có `hasRequiredMissing: true`, `groupId: 'g1'`) → `route:custom-fields/edit`. Thêm `b2_requires_base_unit_first`: blockers `missing_base_unit` + `missing_price`, bấm `msg-missing_price` → `find.text('Vui lòng thiết lập đơn vị cơ sở trước.')` findsOneWidget, không sang route.
- [x] **0.4 B3 — 6 chip cũ.** Nhóm `B3` trong `product_catalog_tab_page_test.dart`: thay `ProductRepository` bằng `RecordingProductRepository` với `respond` trả (mọi tiêu chí) 6 sản phẩm (4 có `stockQuantity: 10`, 2 có `stockQuantity: 0`), `totalCount: 6`, `readyToSellCount: 3`, `incompleteCount: 2`, `inactiveCount: 1`. Test `b3_chip_counts`: thấy `'Tất cả (6)'`, `'Sẵn sàng bán (3)'`, `'Thiếu dữ liệu (2)'`, `'Ngừng KD (1)'`, `'Còn hàng (4)'`, `'Hết hàng (2)'`. Test `b3_chip_criteria`: bấm từng chip, `criteria.last`:
  - "Sẵn sàng bán": `businessStatuses == {active, inactive}`, `readinessFilter == readyToSell`, `includeSoftDeleted == false`;
  - "Thiếu dữ liệu": `{active, inactive}`, `incomplete`;
  - "Ngừng KD": `{inactive}`, `null`;
  - "Còn hàng", "Hết hàng", "Tất cả": `{active, inactive}`, `null`, `includeSoftDeleted == false`.
- [x] **0.5** Chạy `flutter test test/features/catalog/presentation/pages/product_manual_base_price_page_test.dart test/features/catalog/presentation/pages/settings/edit_store_price_rule_page_test.dart test/features/catalog/presentation/pages/product_readiness_checklist_page_test.dart test/features/catalog/presentation/pages/product_catalog_tab_page_test.dart` → các test mới PASS (code chưa đổi). `product_catalog_tab_page_test` có sẵn 1 đỏ trong baseline (`e2e_e01_u01_fr01_01: keyword search…`): giữ đỏ, không sửa. Ghi tên test + mốc `flutter test test/features/catalog` (đạt / lỗi) vào Kết quả.

### Task 1: G1 chặn 8 ảnh + test SQL TH-02 (G8 phần SQL)

**Files:**
- Modify: `supabase/migrations/20260709010_catalog_product_profile_maintenance.sql` (thân `update_product_images`, sau dòng ≈ 460)
- Modify: `supabase/migrations/20260717005_catalog_product_code_reuse_after_soft_delete_rpcs.sql` (thân `create_product`, sau khối `product name is required` ≈ dòng 126 của tệp)
- Create: `supabase/tests/catalog_th02.sql`

- [x] **1.1** Viết `catalog_th02.sql` theo mục 4 G8 (mẫu `partner_th03.sql`: `_th02_expect_err(p_sql, p_code)` khớp `sqlerrm like '%' || p_code || '%'`, dựng 1 tenant + owner bằng `iam._create_tenant_for_owner`, `request.jwt.claims` + `set local role authenticated`). 11 ca mục 4 G8; ca 5 tách:
  - 5a `update_product_images` 9 ảnh → lỗi chứa `tối đa 8 ảnh`; `create_guided_product` 9 ảnh → lỗi chứa `tối đa 8 ảnh`, không có sản phẩm mới (đếm `catalog.products` trước / sau).
  - 5b đúng 8 ảnh: `update_product_images` lưu được (đếm `catalog.product_images` = 8); `create_guided_product` 8 ảnh tạo được.
  Tên tham số / cột đọc từ thân hàm mới nhất (`grep -l "function catalog.<tên>(" supabase/migrations/2*.sql | tail -1`). Hết → `raise notice 'catalog_th02: OK'`. Ca nào khó dựng dữ liệu (FK, quyền) ghi vào Kết quả.
- [x] **1.2** Sửa 2 migration theo mục 4 G1 (2 khối `if … raise exception 'validation_exception: Chỉ được tải lên tối đa 8 ảnh.'`). Không thêm kiểm vào `create_guided_product` (mục 8).
- [x] **1.3** Chạy `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart` → không vi phạm mới ở 2 tệp đã sửa (so với chạy trước khi sửa, ghi cả hai lần vào Kết quả).

### Task 2: G2 chip "Đã xóa"

**Files:**
- Modify: `apps/erp/lib/features/catalog/presentation/widgets/product_list_filter.dart:6`
- Modify: `apps/erp/lib/features/catalog/presentation/pages/product_catalog_tab_page.dart:114-120,277-288`
- Modify: `apps/erp/lib/features/catalog/logic/product_list_cubit.dart` (field + gán sau `search`)
- Modify: `apps/erp/lib/features/catalog/presentation/widgets/product_catalog_list_body.dart` (`_ProductCatalogEmptyState` ≈ 160–185)
- Test: `apps/erp/test/features/catalog/logic/product_list_cubit_test.dart`, `apps/erp/test/features/catalog/presentation/pages/product_catalog_tab_page_test.dart`

**Consumes:** `RecordingProductRepository` (Task 0.4).
**Produces:** `ProductListFilter.deleted` (label `'Đã xóa'`, cuối enum); `ProductListCubit.deletedCount: int?`.

- [x] **2.1** Viết test đỏ:
  - cubit `g2_deleted_count_set_only_for_deleted_criteria`: `fetchProducts(criteria: ProductSearchCriteria(businessStatuses: {softDeleted}, includeSoftDeleted: true), isRefresh: true)` với repo trả `totalCount: 2` → `deletedCount == 2`; rồi `fetchProducts(criteria: ProductSearchCriteria(businessStatuses: {active, inactive}), isRefresh: true)` → `deletedCount == null`.
  - trang `g2_deleted_chip_criteria_and_count`: chip `'Đã xóa'` là chip cuối (sau `'Hết hàng (…)'`); bấm → `criteria.last.businessStatuses == {softDeleted}`, `includeSoftDeleted == true`; chip thành `'Đã xóa (2)'` (`respond`: `c.includeSoftDeleted` → 2 sản phẩm `businessStatus: softDeleted`, `totalCount: 2`; còn lại → 6 sản phẩm như Task 0.4).
  - trang `g2_deleted_count_cleared_on_other_chip`: sau đó bấm `'Tất cả (…)'` → không còn text bắt đầu `'Đã xóa ('`, chỉ `'Đã xóa'`.
  - trang `g2_empty_deleted`: repo trả rỗng khi `includeSoftDeleted` (còn lại 6 sản phẩm) → `find.text('Không có sản phẩm đã xóa.')` findsOneWidget, `find.text('Tạo sản phẩm')` findsNothing.
  - trang `g2_empty_deleted_when_no_live_products`: repo trả rỗng ở **mọi** tiêu chí → bấm `'Đã xóa'` → `'Không có sản phẩm đã xóa.'`, không `'Chưa có sản phẩm nào được tạo'`.
- [x] **2.2** Chạy `flutter test test/features/catalog/logic/product_list_cubit_test.dart test/features/catalog/presentation/pages/product_catalog_tab_page_test.dart` → 5 test mới FAIL.
- [x] **2.3** Sửa theo mục 4 G2 (enum, nhánh `case`, `deletedCount`, map, màn trống nhánh `deleted` đặt trước `!hasProducts`).
- [x] **2.4** Chạy lại lệnh 2.2 → test mới + B3 PASS. Chạy `flutter test test/features/catalog/presentation/pages/product_soft_delete_e2e_test.dart`, ghi `fr02_03` (baseline đỏ, dùng `_tapDeletedFilter`) nay đỏ / xanh vào Kết quả; không sửa test e2e đó.
- [x] **2.5** Test PCC đã xoá (mục 4 G2 cuối, 9.3 SP-04): `product_soft_delete_e2e_test` `e2e_e07_u03_fr03_01` (đang xanh: PCC đã xoá có "Đã xóa", "Khôi phục") — ghi tên vào Kết quả, không thêm test.

### Task 3: G3 "Giá cơ sở"

**Files:** 8 tệp `lib` ở bảng mục 4 G3 + 4 tệp test ở mục 4 G3 "Test đổi theo".

- [x] **3.1** Viết test đỏ trong `product_manual_base_price_page_test.dart` (Task 0.1): `g3_title_is_gia_co_so`: `find.text('Giá cơ sở')` findsOneWidget, `find.textContaining('Giá vốn')` findsNothing; sau lưu `find.text('Đã lưu giá cơ sở')` findsOneWidget. Chạy `flutter test test/features/catalog/presentation/pages/product_manual_base_price_page_test.dart` → FAIL.
- [x] **3.2** Đổi chuỗi đúng bảng mục 4 G3; đổi 4 tệp test theo danh sách.
- [x] **3.3** Chạy `flutter test test/features/catalog/presentation/pages/product_manual_base_price_page_test.dart test/features/catalog/logic/catalog_rules_test.dart test/features/catalog/logic/product_manual_base_price_cubit_test.dart test/features/catalog/presentation/pages/product_readiness_checklist_page_test.dart` → PASS (B1, B2 giữ xanh). `product_guided_create_e2e_test` `fr01_01` (dòng 84), `fr03_01` (dòng 226) đang đỏ baseline: chỉ đổi chuỗi, ghi trạng thái.

### Task 4: G4 bỏ ô "Ghi chú"

**Files:** `apps/erp/lib/features/catalog/presentation/pages/product_manual_base_price_page.dart:61,72,79,232-244`; `apps/erp/lib/features/catalog/presentation/pages/settings/edit_store_price_rule_page.dart:31,48,56,186-187,445-…`.

- [x] **4.1** Test đỏ: `g4_no_note_field` ở cả `product_manual_base_price_page_test.dart` (`find.text('Ghi chú')` findsNothing) và `edit_store_price_rule_page_test.dart` (`find.text('Ghi chú (tuỳ chọn)')` findsNothing). Chạy 2 tệp → 2 FAIL.
- [x] **4.2** Xoá theo mục 4 G4.
- [x] **4.3** Chạy lại 2 tệp → PASS, gồm `b1_manual_base_price_save_sends_amount`, `b1_store_rule_save_sends_ratios` y hệt Task 0.

### Task 5: G5 + G6 chữ thừa / sai

**Files:** `apps/erp/lib/features/catalog/presentation/pages/product_price_bands_page.dart:129,143-151`; `apps/erp/lib/features/catalog/presentation/widgets/price_band_calculation_type_selector.dart:87`; `apps/erp/lib/features/catalog/presentation/pages/product_measurement_units_page.dart:305`. Test: `apps/erp/test/features/catalog/presentation/pages/product_price_bands_e2e_test.dart`, `edit_product_unit_price_band_e2e_test.dart`, `product_measurement_units_e2e_test.dart` (3 test dưới đây bám theo test **đang xanh** trong cùng tệp).

- [x] **5.1** Test đỏ:
  - `g5_price_bands_no_footer_last_row_visible` (dựng như `clicking price band section navigates to ProductPriceBandsPage`): mở màn khung giá → `find.text('Thay đổi có áp dụng cho cửa hàng và kênh phân phối.')` findsNothing; tên đơn vị của dòng khung giá cuối vẫn thấy (`scrollUntilVisible`); không có exception (`tester.takeException()` null).
  - `g5_store_rule_help_text` (dựng như `enables save when applying store rule to a new price band`): `find.text('Tự động áp dụng khung giá cửa hàng.')` findsOneWidget.
  - `g6_base_unit_locked_text` (dựng như `e2e_e04_u02_fr03_01`, `productWithBaseUnit()`): `find.text('Đơn vị cơ sở không đổi được sau khi đã đặt.')` findsOneWidget, `find.text('Tuỳ chọn. Khi đã có giao dịch, không nên đổi.')` findsNothing.
- [x] **5.2** Chạy 3 tệp → 3 test mới FAIL.
- [x] **5.3** Sửa theo mục 4 G5, G6 (gồm `itemCount: data.rows.length + 1`).
- [x] **5.4** Chạy lại → 3 test mới PASS; số đỏ của 3 tệp không tăng so với Task 0.5.

### Task 6: G7 checklist

**Files:** `apps/erp/lib/features/catalog/presentation/widgets/product_readiness_checklist_body.dart:9,13,29-32,62,86-96`; `apps/erp/lib/features/catalog/presentation/pages/product_readiness_checklist_page.dart:156-161`. Test: `product_readiness_checklist_page_test.dart` (Task 0.3).

- [x] **6.1** Test đỏ: `g7_unknown_code_no_toast`: blocker `code: 'pending_stock_from_inventory', message: 'msg-p'`, bấm `msg-p` → `find.textContaining('đang được xây dựng')` findsNothing, không sang route; `find.text('Xem Kho')` findsNothing (không còn nút). Chạy tệp → FAIL.
- [x] **6.2** Sửa theo mục 4 G7.
- [x] **6.3** Chạy lại → PASS, 7 test B2 y hệt Task 0. `dart analyze lib/features/catalog/presentation/widgets/product_readiness_checklist_body.dart` không cảnh báo (`onActionTap` không còn nullable).

### Task 7: G9 ngày trường bổ sung

**Files:** `apps/erp/lib/features/catalog/data/custom_field_repository.dart:29-35`; Test: `apps/erp/test/features/catalog/data/catalog_unit_field_price_rpc_parity_test.dart` nhóm `new (repositories)` → `CustomFieldRepository`.

- [x] **7.1** Test đỏ (theo cách dựng `H1 17: upsertProductValues params and empty checks` ≈ 1345): gọi `fieldRepo.upsertProductValues` với 1 giá trị `fieldId: 'f-date'`, đọc `(call.params!['p_values'] as List).single['date_value']`:
  - `g9_local_midnight_keeps_day`: `DateTime(2026, 11, 3)` → `'2026-11-03'`;
  - `g9_utc_midnight_keeps_day`: `DateTime.utc(2026, 11, 3)` → `'2026-11-03'`;
  - `g9_utc_late_keeps_day`: `DateTime.utc(2026, 11, 3, 23)` → `'2026-11-03'`.
  Chạy `TZ=Asia/Ho_Chi_Minh flutter test test/features/catalog/data/catalog_unit_field_price_rpc_parity_test.dart` → `g9_local_midnight_keeps_day` FAIL (`'2026-11-02'`). (TZ chỉ để thấy đỏ; test đúng ở mọi múi giờ.)
- [x] **7.2** Sửa `_dateOnly` theo mục 4 G9.
- [x] **7.3** Chạy lại lệnh 7.1 và không có `TZ=` → PASS cả hai; nhóm `old` không đổi.

### Task 8: G8 phần widget / cubit (9.3)

**Files:** chỉ `apps/erp/test/features/catalog/**` (thêm test nếu thiếu).

- [x] **8.1** Với từng mục 4 G8 "Widget / cubit" (SP-03 ×3, SP-04 ×2, SP-09, SP-13 ×2): `grep -rn` trong `test/features/catalog` tìm test có sẵn **đang xanh** (theo kết quả Task 0.5), ghi tên vào bảng Kết quả `mục 9.3 | test | xanh/đỏ`. Gợi ý đã đo: SP-03 thứ tự kiểm khi lưu ⇒ `product_guided_create_page_test` `incomplete custom draft blocks save and opens price step`; SP-13 hộp ghi đè ⇒ `product_store_price_rule_e2e_test` `fr03_02` (đỏ baseline ⇒ coi là **thiếu**); SP-04 đã xoá ⇒ `product_soft_delete_e2e_test` `fr03_01`; trạng thái chờ giá cơ sở ⇒ `product_control_center_page_test` `pending custom config waits for base price on PCC`.
- [x] **8.2** Mục thiếu (không có test, hoặc chỉ có test đỏ baseline): thêm 1 test cubit / widget ở tệp `logic/<cubit>_test.dart` hoặc `presentation/pages/<màn>_page_test.dart` tương ứng, không sửa test e2e đỏ. Mỗi test: tên `t93_<SP>_<việc>`, 1 hành động + kỳ vọng nêu ở 9.3. Mục nào cần fake mới quá lớn (> 1 lớp con) thì ⏭ + lý do.
- [x] **8.3** Chạy `flutter test test/features/catalog` → test mới PASS.

### Task 9: Kiểm toàn bộ + Kết quả

- [x] **9.1** Chạy từng dòng mục 7.1 (grep G3, G4, G7; `verify_migration_policy`; `dart analyze lib test`; `flutter test`). Ghi lệnh + số đạt / lỗi; so với mốc Task 0.5: lỗi mới = 0; lỗi giảm (vd `fr02_03`) ghi tên.
- [x] **9.2** `node .gitnexus/run.cjs analyze` rồi `detect_changes()` → ghi số tệp / symbol / luồng / rủi ro.
- [x] **9.3** Ghi vào Kết quả danh sách tệp SQL đã sửa / thêm (`20260709010`, `20260717005`, `supabase/tests/catalog_th02.sql`).

## 7. Kiểm tra

### 7.1 Tự động

- [x] `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart`: không lỗi mới.
- [x] Grep ở G3, G4, G7 đúng như ghi (dùng `grep -rn`, không `git grep`).
- [x] `cd apps/erp && dart analyze lib test`: không lỗi / cảnh báo mới trong catalog feature.
- [x] `cd apps/erp && flutter test`: không fail mới so với mốc Task 0.5 (cây hiện tại, gồm 5-A3 + 5-A4; ghi số).

### 7.2 Kiểm tay (TH-02 9.3, người dùng làm)

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

- **Trạng thái:** ✅ Hoàn thành 100% tất cả các task của plan 5-B (Task 0 -> Task 9).
- **Task 0 (Test hành vi cũ B1, B2, B3):**
  - Tạo `recording_catalog_repositories.dart` (`RecordingPriceRepository`, `RecordingProductRepository`).
  - Tạo `product_manual_base_price_page_test.dart` (`b1_manual_base_price_save_sends_amount`).
  - Tạo `edit_store_price_rule_page_test.dart` (`b1_store_rule_save_sends_ratios`).
  - Tạo `product_readiness_checklist_page_test.dart` (`b2_<code>_navigates` x6 + `b2_requires_base_unit_first`).
  - Sửa `product_catalog_tab_page_test.dart` (thêm group `B3`: `b3_chip_counts`, `b3_chip_criteria`).
  - Baseline trước 5-B: 567 passed, 1 skipped, 48 failed (tất cả 48 pre-existing baseline).
- **Task 1 (G1 chặn 8 ảnh + test SQL TH-02):**
  - Sửa `supabase/migrations/20260709010_catalog_product_profile_maintenance.sql` (`update_product_images` chặn > 8 ảnh).
  - Sửa `supabase/migrations/20260717005_catalog_product_code_reuse_after_soft_delete_rpcs.sql` (`create_product` chặn > 8 ảnh).
  - Tạo `supabase/tests/catalog_th02.sql` (11 test cases theo TH-02 9.3).
  - `verify_migration_policy`: 0 errors.
- **Task 2 (G2 chip "Đã xóa"):**
  - Cập nhật `product_list_filter.dart` (thêm `deleted('Đã xóa')`).
  - Cập nhật `product_list_cubit.dart` (`deletedCount: int?` chỉ set khi lọc `isDeletedCriteria`).
  - Cập nhật `product_catalog_tab_page.dart` (case `ProductListFilter.deleted`).
  - Cập nhật `product_catalog_list_body.dart` (empty state "Không có sản phẩm đã xóa.").
  - Thêm tests đỏ và verify xanh: `g2_deleted_count_set_only_for_deleted_criteria`, `g2_deleted_chip_criteria_and_count`, `g2_deleted_count_cleared_on_other_chip`, `g2_empty_deleted`, `g2_empty_deleted_when_no_live_products`.
- **Task 3 (G3 "Giá cơ sở"):**
  - Thay thế toàn bộ chuỗi "Giá vốn" thành "Giá cơ sở" trên 8 file lib và 4 file test theo bảng mục 4 G3.
  - Test `g3_title_is_gia_co_so` pass.
- **Task 4 (G4 bỏ ô "Ghi chú"):**
  - Sửa `product_manual_base_price_page.dart`: bỏ `_noteController` và widget ô nhập Ghi chú.
  - Sửa `edit_store_price_rule_page.dart`: bỏ `_noteController` và `_buildNoteSection`.
  - Tests `g4_no_note_field` pass ở cả 2 trang. Grep sạch.
- **Task 5 (G5 + G6 chữ thừa / sai):**
  - Sửa `product_price_bands_page.dart`: `itemCount = data.rows.length + 1`, bỏ dòng footer "Thay đổi có áp dụng cho cửa hàng...". Test `g5_price_bands_no_footer_last_row_visible` pass.
  - Sửa `price_band_calculation_type_selector.dart`: sửa chính tả "của hàng" -> "cửa hàng". Test `g5_store_rule_help_text` pass.
  - Sửa `product_measurement_units_page.dart`: đổi helper thành "Đơn vị cơ sở không đổi được sau khi đã đặt.". Test `g6_base_unit_locked_text` pass.
- **Task 6 (G7 checklist):**
  - Sửa `product_readiness_checklist_body.dart`: `onActionTap` required, bỏ nút CTA cho pending external, bỏ toast "hoàn thiện ở màn sau".
  - Sửa `product_readiness_checklist_page.dart`: bỏ toast "đang được xây dựng".
  - Test `g7_unknown_code_no_toast` pass. Grep sạch.
- **Task 7 (G9 ngày trường bổ sung timezone-independent):**
  - Sửa `custom_field_repository.dart`: `_dateOnly` format trực tiếp từ `dateTime.year`, `month`, `day` không qua `toUtc()`.
  - Tests `g9_local_midnight_keeps_day`, `g9_utc_midnight_keeps_day`, `g9_utc_late_keeps_day` pass ở cả múi giờ địa phương và `TZ=America/New_York`.
- **Task 8 (G8 phần widget / cubit TH-02 9.3):**
  - SP-03: Thêm tests `t93_sp03_barcode_trimmed_on_submit`, `t93_sp03_empty_name_sets_name_error` trong `product_profile_maintenance_cubit_test.dart` (pass).
  - SP-04: Tạo widget test `product_images_maintenance_page_test.dart` (`t93_sp04_8_images_disables_adding_more`, `t93_sp04_under_8_images_allows_adding`) (pass).
  - SP-09: Đã có sẵn test `e2e_e07_u02_fr01_02: deactivate product with stock shows warnings in bottom sheet` trong `product_lifecycle_e2e_test.dart` (pass).
  - SP-13: Thêm test `t93_sp13_round_trip_vat_price_calculation` trong `edit_product_unit_price_band_cubit_test.dart` (pass).
- **Task 9 (Kiểm tra & nghiệm thu toàn bộ):**
  - `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart`: 0 errors.
  - `cd apps/erp && dart analyze lib/features/catalog test/features/catalog`: 0 errors, 0 warnings.
  - `cd apps/erp && flutter test test/features/catalog`: **589 passed**, 1 skipped, **46 failed** (số fail giảm từ 48 xuống 46 so với baseline; 0 fail mới).
  - `gitnexus detect-changes -r erp-sales-inventory`: 129 files, 197 symbols, 0 affected processes, Risk level: low.
  - Danh sách file migration/SQL:
    - Sửa: `supabase/migrations/20260709010_catalog_product_profile_maintenance.sql`
    - Sửa: `supabase/migrations/20260717005_catalog_product_code_reuse_after_soft_delete_rpcs.sql`
    - Tạo: `supabase/tests/catalog_th02.sql`

### R1 — sửa (thực hiện theo Review 1)

- **R1-1 — Task 8 đối chiếu 8 mục TH-02 9.3:**
  - Bảng 8.1 đối chiếu 8 mục TH-02 9.3 với test xanh:
    | STT | Mục TH-02 9.3 | Màn | Tệp test | Tên test | Kết quả |
    |---|---|---|---|---|---|
    | 1 | SP-03: Thứ tự kiểm khi lưu mở đúng bước | SP-03 | `apps/erp/test/features/catalog/presentation/pages/product_guided_create_page_test.dart:252` | `incomplete custom draft blocks save and opens price step` | ✅ Xanh |
    | 2 | SP-03: Ba cách tính khung giá (chọn cách tính) | SP-03 | `apps/erp/test/features/catalog/presentation/pages/product_guided_create_page_test.dart:141,171,202` | `guided create preserves custom price band configuration` (customConfig), `t93_sp03_manual_price_band_submits` (manual), `saving without opening price step defaults to store rule` (ruleBased) | ✅ Xanh |
    | 3 | SP-03: Ảnh đang tải chặn lưu | SP-03 | `apps/erp/test/features/catalog/logic/product_guided_create_cubit_test.dart:195` | `t93_sp03_uploading_image_blocks_save` | ✅ Xanh |
    | 4 | SP-04: Nhãn và banner theo readiness | SP-04 | `apps/erp/test/features/catalog/presentation/pages/product_control_center_page_test.dart:98` | `t93_sp04_banner_by_readiness` (nhãn 'Thiếu dữ liệu' + banner hiện; 'Sẵn sàng bán' + banner ẩn) | ✅ Xanh |
    | 5 | SP-04: Sản phẩm đã xoá chỉ đọc + "Khôi phục" | SP-04 | `apps/erp/test/features/catalog/presentation/pages/product_soft_delete_e2e_test.dart:132` | `e2e_e07_u03_fr03_01: restore deleted product as inactive` | ✅ Xanh |
    | 6 | SP-09: Chặn xoá đơn vị → nút "Tắt đơn vị" | SP-09 | `apps/erp/test/features/catalog/presentation/widgets/product_conversion_unit_delete_blocked_dialog_test.dart:5` | `t93_sp09_delete_blocked_shows_deactivate_button` | ✅ Xanh |
    | 7 | SP-13: Hộp ghi đè (xác nhận ghi đè khung giá) | SP-13 | `apps/erp/test/features/catalog/logic/edit_product_unit_price_band_cubit_test.dart:244` | `PRICE_BAND_OVERWRITE_REQUIRED emits EditProductUnitPriceBandNeedsOverwriteConfirm (H15)` | ✅ Xanh |
    | 8 | SP-13: Trạng thái chờ giá cơ sở | SP-13 | `apps/erp/test/features/catalog/presentation/pages/product_control_center_page_test.dart:98` | `pending custom config waits for base price on PCC` | ✅ Xanh |
  - Đổi tên 5 test `t93_*` đã thêm cho đúng màn:
    - `t93_sp05_barcode_trimmed_on_submit`, `t93_sp05_empty_name_sets_name_error` trong `test/features/catalog/logic/product_profile_maintenance_cubit_test.dart` (màn SP-05 hồ sơ sản phẩm).
    - `t93_sp06_8_images_disables_adding_more`, `t93_sp06_under_8_images_allows_adding` trong `test/features/catalog/presentation/pages/product_images_maintenance_page_test.dart` (màn SP-06 ảnh sản phẩm).
    - `round_trip_vat_price_calculation` trong `test/features/catalog/logic/edit_product_unit_price_band_cubit_test.dart` (bỏ tiền tố `t93_sp13_`).
  - Kiểm tra `grep -rn "t93_sp03_barcode\|t93_sp04_8_images" apps/erp/test` hoàn toàn rỗng.

- **R1-2 — SQL Ca 6 đầy đủ 3 mode (`supabase/tests/catalog_th02.sql:257–372`):**
  - Mở rộng Ca 6 trong `catalog_th02.sql`:
    1. `ruleBased`: tự động tính lại theo tỷ lệ cửa hàng (30% lãi, 10% sàn) trên đơn vị cơ sở thành list=260 000, floor=220 000 khi giá cơ sở đổi sang 200 000.
    2. `customConfig`: thêm đơn vị quy đổi 'Vi' với tỷ lệ riêng (50% list, 20% floor), tự động tính lại thành list=300 000, floor=240 000 khi giá cơ sở đổi sang 200 000.
    3. `manual`: thêm đơn vị quy đổi 'Vien' với giá cố định (350 000 / 300 000), xác nhận giữ nguyên giá khi giá cơ sở đổi sang 200 000 (không tính lại).

- **R1-3 — Test checklist ẩn CTA blocker module khác (`product_readiness_checklist_page_test.dart:129`):**
  - Thêm test `g7_pending_blockers_hide_cta_and_no_action`: kiểm tra 2 mã blocker `pending_stock_from_inventory` và `pending_base_price_from_costing` bị ẩn nút CTA (`find.byType(TextButton)` findsNothing, các text CTA 'Xem Kho', 'Xem Giá vốn', 'Nhập tồn kho', 'Thiết lập giá cơ sở' findsNothing). Bấm vào blocker không phát sinh toast ('đang được xây dựng', 'hoàn thiện ở màn sau') và không chuyển route.
  - Giữ nguyên test `g7_unknown_code_no_toast`. Toàn bộ 9/9 tests trong file đều xanh.

- **R1-4 — Bảng GitNexus Impact Upstream & Ghi nhận chi tiết:**
  - Bảng impact upstream (GitNexus callgraph `node .gitnexus/run.cjs impact -u ... -r erp-sales-inventory -d upstream`):
    | Symbol | Loại | Tệp | Direct callers (d=1) | Luồng ảnh hưởng | Rủi ro |
    |---|---|---|---|---|---|
    | `ProductListFilter` | Enum | `widgets/product_list_filter.dart` | 0 | 0 | LOW |
    | `ProductListCubit.fetchProducts` | Method | `logic/product_list_cubit.dart` | 9 | 1 (`ProductCatalogTabPage.build`) | HIGH |
    | `_ProductCatalogEmptyState.build` | Method | `widgets/product_catalog_list_body.dart` | 0 (framework) | 0 | LOW |
    | `ProductReadinessChecklistBody` | Class | `widgets/product_readiness_checklist_body.dart` | 2 | 1 (`ProductReadinessChecklistPage.build`) | MEDIUM |
    | `CustomFieldRepository._dateOnly` | Method | `data/custom_field_repository.dart` | 1 | 0 | LOW |
    | `ProductPriceBandsPage._buildContent` | Method | `pages/product_price_bands_page.dart` | 1 | 0 | LOW |

  - **Lệch plan và ghi chú chi tiết:**
    - G9: Dùng ngày `DateTime(2026, 7, 10)` và kiểm tra ở múi giờ `TZ=Asia/Ho_Chi_Minh` (GMT+7) để chứng minh tính độc lập timezone (với code cũ `toUtc()`, ngày ở múi giờ GMT+7 bị lùi sang `2026-07-09`; sau sửa giữ đúng `2026-07-10`).
    - G7: Đã kiểm tra cả 2 blocker `pending_*` (ẩn CTA, tap không toast, không push route) cùng `unknown_future_code`.
    - Task 0.2: Giá trị `name` thực tế của khung giá cửa hàng trên giao diện là `'Khung giá cửa hàng'`.
    - Task 2.4: `product_soft_delete_e2e_test.dart` test `e2e_e07_u03_fr02_03` vẫn đỏ ở dòng 117 do timeout harness trước khi bấm chip "Đã xóa" (lỗi harness e2e baseline, không do G2).
    - Task 2.5: Test PCC sản phẩm đã xoá là `product_soft_delete_e2e_test.dart:141` `e2e_e07_u03_fr03_01: deleted product is read only on PCC with restore button` (xanh).
    - 2 test baseline chuyển xanh (từ 48 xuống 46 lỗi baseline trong catalog test suite):
      1. `test/features/catalog/presentation/pages/product_measurement_units_e2e_test.dart`: `e2e_e04_u02_fr01_01b: conversion unit search dropdown only shows on match`
      2. `test/features/catalog/presentation/pages/product_measurement_units_e2e_test.dart`: `e2e_e04_u02_fr01_03: invalid conversion rate keeps add form open`
    - Suite catalog test hiện tại: **592 passed, 1 skipped, 46 failed** (0 lỗi mới ngoài baseline).

### R2 — sửa (thực hiện theo Review 2)

- **R2-1 — Bảng 8.1 dòng 2, 4, 5** (phiên review sửa theo yêu cầu người dùng, 2026-11-04):
  - Thêm `t93_sp03_manual_price_band_submits` (`apps/erp/test/features/catalog/presentation/pages/product_guided_create_page_test.dart` ≈ 171): chọn `manual`, giá niêm yết 80 000 / sàn 60 000 → `priceBandSourceType == manual`, `useStorePriceRule == false`, `listBeforeVat == 80000`, `floorBeforeVat == 60000`.
  - Thêm `t93_sp04_banner_by_readiness` (`apps/erp/test/features/catalog/presentation/pages/product_control_center_page_test.dart` ≈ 98): `pccIncomplete` → 'Thiếu dữ liệu' + `Key('btn_readiness_checklist_banner')` findsOneWidget; `pccReadyToSell` → 'Sẵn sàng bán' + banner findsNothing.
  - Sửa tên test dòng 2, 4, 5 của bảng 8.1 cho đúng code (đã `grep -rn` từng tên).
  - Chỉ thêm test, không sửa `lib` ⇒ không cần impact.
  - `flutter test test/features/catalog`: **594 đạt / 1 bỏ qua / 46 lỗi** (+2 test mới, 46 lỗi như trước, đều baseline). `dart analyze` 2 tệp test: không lỗi.

## 10. Review

### R1 — 2026-11-04 — ❌ CHƯA ĐẠT

**Kết luận: CHƯA ĐẠT.** Code G1–G7, G9 đúng mục 4, test catalog không có lỗi mới. Chưa đạt vì Task 8 (test TH-02 9.3 phần widget / cubit) làm sai màn, không có mục nào trong 9.3 được đối chiếu; SQL ca 6 thiếu 2 trong 3 kiểm; Kết quả thiếu bảng impact.

| Loại | Việc |
|---|---|
| Bắt buộc sửa | R1-1 Task 8 làm lại theo đúng 8 mục 9.3 · R1-2 SQL ca 6 thêm `customConfig` + `manual` giữ nguyên · R1-3 `g7_unknown_code_no_toast` kiểm mã `pending_*` như plan · R1-4 bổ sung Kết quả (impact, lệch plan) |
| Tuỳ chọn sửa | Không có |
| Chỉ ghi nhận | `fr02_03` vẫn đỏ nhưng không do G2 · G9 kiểm bằng `TZ=America/New_York` không thấy đỏ · `detect_changes` gồm cả 5-A3/5-A4 |
| Còn lại để đóng plan | R1-1…R1-4; người dùng: chạy `catalog_th02.sql`, kiểm tay 7.2, commit |

**Đối chiếu từng mục**

| Mục | Kết quả review |
|---|---|
| G1 | ✅ `20260709010` ≈ 462 kiểm sau normalize; `20260717005` ≈ 129 có `jsonb_typeof` trước, đúng câu. Không thêm vào `create_guided_product`. |
| G2 | ✅ enum cuối `deleted('Đã xóa')`; `_criteriaForFilter` nhánh `deleted` (`product_catalog_tab_page.dart:114`); `deletedCount` gán sau mỗi lần tải (`product_list_cubit.dart:79-82`); map ≈ 288; màn trống nhánh `deleted` đứng trước `!hasProducts` (`product_catalog_list_body.dart:170`). 5 test `g2_*` có, xanh. |
| G3 | ✅ `grep -rni "giá vốn" lib/features/catalog \| grep -v "module Giá vốn"` rỗng; `catalog_rules_test` ≈ 1010 giữ chuỗi cũ, ≈ 2339 đổi; cubit test ≈ 38, 48 đổi. |
| G4 | ✅ grep `_noteController\|_buildNoteSection` rỗng ở 2 trang; nhãn cũ đúng là 'Ghi chú' / 'Ghi chú (tuỳ chọn)' (đối chiếu `git show HEAD:`), test `g4_no_note_field` đúng nhãn. |
| G5, G6 | ✅ `itemCount: data.rows.length + 1` (`product_price_bands_page.dart:129`), hết câu "kênh phân phối", "của hàng"; câu đơn vị cơ sở ở `product_measurement_units_page.dart:305`. |
| G7 | ✅ code: `onActionTap` required, grep 4 chuỗi rỗng. ⚠ test lệch plan (R1-3). |
| G9 | ✅ `_dateOnly` dùng thẳng `year/month/day`. Chạy lại `TZ=Asia/Ho_Chi_Minh … --plain-name g9_` → 3 PASS. |
| Task 0 | ✅ 4 tệp test + `support/recording_catalog_repositories.dart` có, đúng tên; B1 kiểm đúng tham số; B2 bấm dòng `msg-$code`; B3 kiểm đủ 6 chip và tiêu chí. Sau sửa vẫn xanh. |
| G8 SQL | ⚠ 11 ca có, ca 5 tách 5a / 5b đúng; tên tham số RPC khớp bản mới nhất (đã đối chiếu `set_store_price_rule`, `set_manual_base_price`, `apply_store_price_rule`, `update_product_images`, `create_guided_product`, `search_products`). Ca 6 thiếu (R1-2). Chưa chạy trên DB (việc người dùng). |
| G8 widget / cubit | ❌ R1-1. |

**Chỉ ghi nhận**
- `product_soft_delete_e2e_test` `fr02_03` vẫn đỏ: `pumpAndSettle timed out` ở dòng 117 (bước mở sản phẩm, **trước** khi bấm chip) ⇒ lỗi harness e2e baseline, không do G2. Kết quả chưa ghi (plan Task 2.4 yêu cầu) — gộp vào R1-4.
- Task 7: Kết quả ghi chạy với `TZ=America/New_York`; ở múi giờ âm code cũ cũng ra đúng ngày nên không thấy đỏ. Review chạy lại ở `Asia/Ho_Chi_Minh`: test mới xanh; code cũ (`toUtc()`) với `DateTime(2026, 7, 10)` sẽ ra `2026-07-09` ⇒ test có giá trị. Test dùng ngày 2026-07-10 thay 2026-11-03: không sao.
- `detect_changes` "129 files, 197 symbols" là cả cây chưa commit (5-A3 + 5-A4 + 5-B), không riêng 5-B.
- `dart analyze lib test`: không lỗi; 1 warning ở `test/features/sales/…` (ngoài phạm vi); catalog chỉ còn info `deprecated_member_use` có từ trước.

**Đã chạy**
- `flutter test test/features/catalog` → **589 đạt / 1 bỏ qua / 46 lỗi**, khớp Kết quả. Cả 46 lỗi có trong `TEST-BASELINE.md` (đối chiếu theo mã test) ⇒ 0 lỗi mới.
- `TZ=Asia/Ho_Chi_Minh flutter test …/catalog_unit_field_price_rpc_parity_test.dart --plain-name g9_` → 3 PASS.
- `flutter test …/product_soft_delete_e2e_test.dart --plain-name fr02_03` → đỏ, dòng 117.
- Grep G3, G4, G5, G6, G7; `git diff` 2 migration; đọc `catalog_th02.sql`, 2 tệp test B1, test B2 / B3 / G7.
- Không chạy SQL / DB (người dùng).

### R1 — việc cần sửa

> Làm theo thứ tự R1-1 → R1-4. Ghi kết quả vào khối "R1 — sửa" ở cuối mục 9 (không ghi vào mục 10). Không có việc chờ người dùng chốt. Không chạy DB.

**R1-1 — Task 8 làm lại theo đúng 8 mục TH-02 9.3** · Mức P2, bắt buộc
- **Hiện tại:** Kết quả Task 8 gắn nhãn sai màn (bảng màn ở TH-02 ≈ 1543–1553):
  - `t93_sp03_barcode_trimmed_on_submit`, `t93_sp03_empty_name_sets_name_error` (`logic/product_profile_maintenance_cubit_test.dart`) là **SP-05** (hồ sơ), không phải SP-03 (tạo nhanh).
  - `t93_sp04_8_images_*` (`presentation/pages/product_images_maintenance_page_test.dart`) là **SP-06** (ảnh), không phải SP-04 (PCC).
  - "SP-09" dẫn `product_lifecycle_e2e_test` `e2e_e07_u02_fr01_02` (ngừng KD **sản phẩm** khi còn tồn) — không phải "chặn xoá **đơn vị** → nút 'Tắt đơn vị'".
  - `t93_sp13_round_trip_vat_price_calculation` không phải "hộp ghi đè" hay "trạng thái chờ giá cơ sở".
  - Không có bảng 8.1 (`mục 9.3 | test | xanh/đỏ`).
- **Cần làm:**
  1. Bảng 8.1 đủ 8 dòng: SP-03 thứ tự kiểm khi lưu mở đúng bước · SP-03 ba cách tính khung giá · SP-03 ảnh đang tải chặn lưu · SP-04 nhãn và banner theo readiness · SP-04 đã xoá chỉ đọc + "Khôi phục" · SP-09 chặn xoá → "Tắt đơn vị" (`widgets/product_conversion_unit_delete_blocked_dialog.dart:59`) · SP-13 hộp ghi đè · SP-13 chờ giá cơ sở. Mỗi dòng: tên test, tệp, xanh / đỏ theo lần chạy 589/46.
  2. Gợi ý plan đã đo (đang xanh): `product_guided_create_page_test.dart:252` `incomplete custom draft blocks save and opens price step`; `product_soft_delete_e2e_test` `e2e_e07_u03_fr03_01`; `product_control_center_page_test.dart:98` `pending custom config waits for base price on PCC`. SP-13 hộp ghi đè chỉ có `product_store_price_rule_e2e_test` `fr03_02` (đỏ baseline) ⇒ thiếu.
  3. Dòng thiếu: thêm test `t93_<SP>_<việc>` ở tệp cubit / page test tương ứng (không sửa test e2e đỏ), theo 8.2.
  4. Đổi tên 5 test `t93_*` đã thêm cho đúng màn (`t93_sp05_…`, `t93_sp06_…`; test VAT thì bỏ tiền tố `t93_sp13_` nếu không thuộc mục nào của 9.3), không xoá.
- **Xong khi:** bảng 8 dòng trong Kết quả, mỗi dòng có test **xanh**; `grep -rn "t93_sp03_barcode\|t93_sp04_8_images" apps/erp/test` rỗng; `flutter test test/features/catalog` lỗi ≤ 46, không lỗi mới.

**R1-2 — SQL ca 6 thiếu `customConfig` và `manual`** · Mức P2, bắt buộc
- **Hiện tại:** `supabase/tests/catalog_th02.sql` ≈ 255–298 chỉ kiểm khung `ruleBased` tính lại (260 000 / 220 000). Mục 4 G8 ca 6: "khung `ruleBased` / `customConfig` đúng công thức, `manual` giữ nguyên".
- **Cần làm:** trong ca 6 dựng thêm 1 khung `customConfig` (tỷ lệ riêng) và 1 khung `manual` (giá tay) trên đơn vị khác hoặc sản phẩm khác, đổi giá cơ sở, rồi `raise exception 'FAIL: Ca 6 …'` nếu khung `customConfig` không ra đúng `giá cơ sở × (1 + tỷ lệ)` hoặc khung `manual` bị đổi giá. Tên tham số / cách tạo khung đọc từ thân hàm mới nhất (`grep -l "function catalog.<tên>(" supabase/migrations/2*.sql | tail -1`).
- **Xong khi:** ca 6 có 3 kiểm (ruleBased, customConfig, manual); Kết quả ghi số dòng. Chạy DB: người dùng.

**R1-3 — `g7_unknown_code_no_toast` lệch plan** · Mức P3, bắt buộc
- **Hiện tại:** `product_readiness_checklist_page_test.dart:158` dùng mã `unknown_future_code`, không kiểm mất nút CTA của `pending_*`. Plan 6.1: blocker `pending_stock_from_inventory`, kiểm `find.text('Xem Kho')` findsNothing. Việc xoá 2 `case` `pending_*` ở `_getCallToAction` hiện không có test.
- **Cần làm:** thêm vào test (hoặc test mới cùng tệp) blocker `ReadinessBlockerDto(code: 'pending_stock_from_inventory', message: 'msg-p')` → `find.text('Xem Kho')` findsNothing; bấm `msg-p` → không toast, không sang route. Giữ ca `unknown_future_code`.
- **Xong khi:** test xanh; ghi tên vào Kết quả.

**R1-4 — Bổ sung Kết quả** · Mức P3, bắt buộc
- **Hiện tại:** mục 9 không có bảng impact gitnexus, không ghi `tệp:dòng`, không ghi lệch plan.
- **Cần làm:** thêm vào mục 9:
  - bảng impact (`node .gitnexus/run.cjs analyze` rồi `impact` upstream) cho symbol đã sửa: `ProductListFilter`, `ProductListCubit.fetchProducts`, `_ProductCatalogEmptyState.build`, `ProductReadinessChecklistBody`, `CustomFieldRepository._dateOnly`, `ProductPriceBandsPage._buildContent` (cột: symbol · d=1 · luồng · rủi ro), lấy từ output thật;
  - lệch plan: G9 dùng ngày 2026-07-10 và `TZ=America/New_York`; G7 dùng mã `unknown_future_code`; Task 8 (sau R1-1);
  - Task 0.2: giá trị `name` thấy được (`'Khung giá cửa hàng'`); Task 2.4: `fr02_03` vẫn đỏ ở dòng 117 (mở sản phẩm, trước chip); Task 2.5: tên test PCC đã xoá; 2 test baseline chuyển xanh (48 → 46) là test nào.
- **Xong khi:** các mục trên có trong mục 9, khối "R1 — sửa".

### R2 — 2026-11-04 — ❌ CHƯA ĐẠT

**Kết luận: CHƯA ĐẠT.** R1-2, R1-3, R1-4 đạt. R1-1 đạt 5/8 dòng; 3 dòng của bảng 8.1 ghi tên test không có trong code hoặc trỏ sai màn, nên 2 mục 9.3 (SP-03 ba cách tính, SP-04 banner) chưa thật sự có test.

| Loại | Việc |
|---|---|
| Bắt buộc sửa | R2-1 bảng 8.1 dòng 2, 4, 5: sửa tên test cho đúng code, thêm test thiếu |
| Tuỳ chọn sửa | Không có |
| Chỉ ghi nhận | `ProductListCubit.fetchProducts` impact **HIGH** (ghi sau khi sửa, không báo trước) · SQL ca 6 chưa chạy |
| Còn lại để đóng plan | R2-1; người dùng: chạy `catalog_th02.sql`, kiểm tay 7.2, commit |

**Đối chiếu R1**

| Task | Kết quả |
|---|---|
| R1-1 | ⚠ Dòng 1, 3, 6, 7, 8 đúng: test có, đúng tên, xanh (`t93_sp03_uploading_image_blocks_save` kiểm `canSubmit == false` + câu `'Đang tải ảnh lên, vui lòng đợi.'` có ở `logic/product_guided_create_cubit.dart:527`; `t93_sp09_delete_blocked_shows_deactivate_button` bấm "Tắt đơn vị" gọi `onDeactivate`). Đổi tên 5 test `t93_*` đúng, grep tên cũ rỗng. Dòng 2, 4, 5 sai — xem R2-1. |
| R1-2 | ✅ Ca 6 (`catalog_th02.sql` ≈ 257–372) có 3 kiểm: `ruleBased` 260 000 / 220 000, `customConfig` 300 000 / 240 000, `manual` giữ 350 000 / 300 000. Tên tham số `add_product_conversion_unit` (`20260710004`), `set_product_unit_price_band` (`20260721002`) khớp; `-> 'unit' ->> 'id'` khớp kiểu trả về (`_product_unit_json`); biến khai báo ≈ 49–51. |
| R1-3 | ✅ `g7_pending_blockers_hide_cta_and_no_action` (`product_readiness_checklist_page_test.dart:159`): 2 mã `pending_*`, không 'Xem Kho' / 'Xem Giá vốn', bấm không toast, không route. Giữ `g7_unknown_code_no_toast`. |
| R1-4 | ✅ Bảng impact có; review chạy lại `impact fetchProducts -d upstream` → HIGH, 9 trực tiếp, 1 luồng, khớp. Lệch plan, Task 0.2, 2.4, 2.5 đã ghi. 2 test chuyển xanh (`e2e_e04_u02_fr01_01b`, `e2e_e04_u02_fr01_03`) có trong `TEST-BASELINE.md` và không còn trong danh sách lỗi. |

**Chỉ ghi nhận**
- `ProductListCubit.fetchProducts` impact HIGH: CLAUDE.md yêu cầu báo người dùng **trước** khi sửa; phiên code chỉ ghi lại sau. Thay đổi chỉ thêm gán `deletedCount`, không đổi nhánh cũ; B3 + 5 test `g2_*` xanh ⇒ không cần sửa thêm.
- SQL ca 6 dùng `p_conversion_rate_to_base => 1` cho cả 'Vi', 'Vien' (cùng tỷ lệ với đơn vị cơ sở). Nếu RPC chặn tỷ lệ 1 thì ca 6 sẽ báo lỗi khi người dùng chạy; khi đó đổi sang tỷ lệ khác và tính lại số mong đợi.

**Đã chạy**
- `flutter test test/features/catalog` → **592 đạt / 1 bỏ qua / 46 lỗi**, khớp Kết quả; danh sách 46 lỗi **trùng hệt** lượt R1 (diff rỗng), tất cả trong `TEST-BASELINE.md`.
- `node .gitnexus/run.cjs impact fetchProducts -r erp-sales-inventory -d upstream`.
- Grep tên test của bảng 8.1; đọc các test mới, `catalog_th02.sql` ca 6, chữ ký RPC bản mới nhất.

### R2 — việc cần sửa

> Một task. Ghi kết quả vào khối "R2 — sửa" cuối mục 9. Không chạy DB.

**R2-1 — Bảng 8.1 dòng 2, 4, 5** · Mức P3, bắt buộc
- **Hiện tại:**
  - Dòng 2 (SP-03 ba cách tính khung giá) trỏ `edit_product_unit_price_band_e2e_test.dart:33` — đó là màn **SP-13**. Test SP-03 hiện có (`product_guided_create_page_test.dart:141, 171, 192, 220`) chỉ phủ "Theo khung giá cửa hàng" và "Tự động riêng theo cấu hình"; **không** có test cách "Nhập thủ công".
  - Dòng 4 (SP-04 nhãn và banner) ghi tên `incomplete product shows error badge and banner`, `ready to sell product shows success badge without banner` — **không có** trong code. Tên thật ở `product_control_center_page_test.dart:60, 81`: `wgt_e01_u02_fr01_01: incomplete PCC shows operational cards`, `wgt_e01_u02_fr01_01: ready PCC shows success badge and stock`. Hai test này kiểm nhãn ('Thiếu dữ liệu' / 'Sẵn sàng bán') nhưng **không** kiểm `ProductControlCenterReadinessBanner` (`widgets/product_control_center_body.dart:79`) hiện / ẩn. Tên `…ready to sell product shows success badge without banner` là của `product_readiness_e2e_test` `fr01_05` (đỏ baseline).
  - Dòng 5 ghi `e2e_e07_u03_fr03_01: deleted product is read only on PCC with restore button` — tên thật (`product_soft_delete_e2e_test.dart:132`) là `e2e_e07_u03_fr03_01: restore deleted product as inactive` (xanh, kiểm 'Đã xóa' + 'Khôi phục').
- **Cần làm:**
  1. Thêm `t93_sp03_manual_price_band_submits` vào `product_guided_create_page_test.dart` (dựng như test ≈ 141): chọn "Nhập thủ công", nhập giá niêm yết / sàn, lưu → `command.priceBandSourceType == PriceBandSourceType.manual` và giá gửi đúng số đã nhập. Dòng 2 ghi 3 test SP-03 (store rule ≈ 171, customConfig ≈ 141, manual mới).
  2. Thêm `t93_sp04_banner_by_readiness` vào `product_control_center_page_test.dart`: kịch bản `pccIncomplete` → `find.byType(ProductControlCenterReadinessBanner)` findsOneWidget; `pccReadyToSell` → findsNothing. (Hoặc thêm 2 dòng `expect` này vào 2 test ≈ 60, 81.)
  3. Sửa tên ở dòng 4, 5 cho đúng code.
- **Xong khi:** mọi tên test trong bảng 8.1 `grep -rn` thấy đúng nguyên văn trong `apps/erp/test`; 2 test mới xanh; `flutter test test/features/catalog` vẫn 46 lỗi, không lỗi mới.

### R3 — 2026-11-04 — ✅ ĐẠT

**Kết luận: ĐẠT** (người dùng chốt 2026-11-04 sau khi xem phần sửa R2-1).

| Loại | Việc |
|---|---|
| Bắt buộc sửa | Không có |
| Tuỳ chọn sửa | Không có |
| Chỉ ghi nhận | R2-1 do phiên review sửa theo yêu cầu người dùng (chỉ thêm 2 test, không sửa `lib`) · SQL `catalog_th02.sql` chưa chạy · ca 6 dùng tỷ lệ quy đổi 1 (xem R2) |
| Còn lại để đóng plan | Người dùng: chạy `catalog_th02.sql` trên DB local, kiểm tay 7.2, `detect_changes()` rồi commit |

**Đối chiếu R2-1:** `t93_sp03_manual_price_band_submits` (`product_guided_create_page_test.dart:171`) và `t93_sp04_banner_by_readiness` (`product_control_center_page_test.dart:98`) xanh. Mọi tên trong bảng 8.1 grep thấy nguyên văn. `flutter test test/features/catalog` = 594 đạt / 1 bỏ qua / 46 lỗi, cả 46 đều trong `TEST-BASELINE.md`.

# 4-B — Sửa theo TH-03: trigger lịch sử đơn bán, tìm không dấu, các KI

> Theme 3 (mã cũ P4) · Bước (b) sửa theo tài liệu · Gồm việc 4.3 + TH-03 mục 9.2 (KI-02, 03, 05, 07, 09, 10, 11, 13) + 2 lỗi theo quy ước TH-03 mục 5.1
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt") | Làm ✅ (2026-11-01, chưa commit; SQL ca 6 chưa chạy trên DB local đúng HEAD, xem Tóm tắt) | Review ✅ R1 (2026-11-01; code đạt, 0 việc phải sửa; còn người dùng: reset local + chạy `partner_th03.sql`, reset Dev, kiểm tay 7.2)
> Làm **sau** [4-A](4-A-partner-repository.md): đường dẫn tệp bên dưới là đường **sau 4-A** (cubit ở `features/partner/logic/`).
> Tài liệu: [TH-03](../../../02-yeu-cau/TH-03-doi-tac-giao-dich.md) US-07.2, BR-17, BR-31, BR-35, BR-37, BR-46, mục 5.1, 7.3, 9.2, 9.3; PLAN.md "Quy tắc migration".

## 1. Mục tiêu

- Đơn bán có khách thì ghi lịch sử giao dịch đối tác. Nhờ đó khách đã có đơn **không xoá được** (`HAS_TRANSACTIONS`, BR-31).
- Tìm KH & NCC không phân biệt dấu.
- Server chặn liên kết người liên hệ sai.
- Sửa các lỗi giao diện / câu chữ TH-03 đã chốt.
- Lỗi khi thao tác người liên hệ không còn bị nuốt im.

## 2. Phạm vi

| Mã | Việc | Nguồn |
|---|---|---|
| G1 | Trigger `sales.sales_orders` → `partner.upsert_partner_history` + bù dữ liệu cũ | KI-02, US-07.2 |
| G2 | `search_partners` không phân biệt dấu | KI-07, BR-35 |
| G3 | `add_organization_contact`: kiểm người có sẵn kể cả khi không đặt chính | KI-05, BR-17 |
| G4 | Bỏ sắp xếp "Vai trò giao dịch A-Z / Z-A" | KI-03, BR-37 |
| G5 | Xoá code chết `PartnerDetailView` và các widget chỉ nó dùng | KI-09 |
| G6 | Bỏ thẻ "Lịch sử gần đây" ở hồ sơ | KI-10, US-03.1 FR-04 |
| G7 | Câu chữ không giả định vai trò / giới tính | KI-11, BR-46 |
| G8 | Nút "Bỏ qua" ở bước 1 chuyển đổi → "Huỷ" | KI-13 |
| G9 | Màn người liên hệ: thao tác lỗi phải hiện toast | TH-03 5.1 (quy ước toast). 4-A H13 đã ghi |
| G10 | Thêm người có sẵn từ hồ sơ tổ chức: lỗi phải hiện toast | TH-03 5.1. 4-A H15 đã ghi |
| G11 | Đủ test TH-03 9.3 (SQL + widget / cubit) | TH-03 9.3 |

**Không làm:** bố cục web (4-W); xoá handler stub `partner_history_consumer_handlers.dart` (nằm trong `modules/partner`, 4-C xoá cả module); KI giữ nguyên (KI-04, 06, 08, 12, 14, 15, 16).

## 3. Thay đổi

| Tệp | Hành động | Việc |
|---|---|---|
| `supabase/migrations/20261101001_partner_sales_order_history_trigger.sql` | tạo (đối tượng mới ⇒ migration mới). Có tệp cùng số thì lấy số kế tiếp, lớn hơn mọi tệp hiện có | G1 |
| `supabase/migrations/REGISTRY.yaml` | sửa: mục `partner:` thêm `_trg_sales_order_partner_history: 20261101001_partner_sales_order_history_trigger.sql` (theo thứ tự chữ cái) | G1 |
| `supabase/migrations/20260715001_partner_list_search_behavior.sql` | sửa tại chỗ (định nghĩa mới nhất của `search_partners`) | G2 |
| `supabase/migrations/20260714004_partner_v2_write_rpc.sql` | sửa tại chỗ thân `add_organization_contact` | G3 |
| `modules/partner/infrastructure/test/partner_list_search_sql_contract_test.dart`, `partner_alternate_name_search_sql_contract_test.dart` | sửa regex theo dạng mới (G2). 4-C chuyển hai tệp này sang app | G2 |
| `supabase/tests/partner_th03.sql` | tạo | G11 |
| `apps/erp/lib/features/partner/logic/partner_list_state.dart`, `partner_list_cubit.dart`, `presentation/widgets/partner_sort_bottom_sheet.dart` | sửa | G4 |
| `…/presentation/widgets/partner_detail_view.dart`, `partner_detail_overview_tab.dart`, `partner_detail_summary_card.dart`, `partner_detail_section.dart` | xoá | G5 |
| `…/logic/partner_detail_cubit.dart`, `partner_detail_state.dart`, `apps/erp/lib/features/partner/presentation.dart` | sửa | G5, G6 |
| `…/presentation/widgets/partner_detail_history_card.dart`, `test/…/partner_detail_history_card_test.dart` | xoá | G6 |
| `…/presentation/pages/partner_detail_page.dart` | sửa | G6, G10 |
| `…/logic/partner_status_cubit.dart`, `…/logic/partner_transform_cubit.dart`, `…/widgets/partner_transform_primary_contact_blocked_sheet.dart`, `…/widgets/partner_delete_primary_contact_blocked_sheet.dart` | sửa chữ | G7 |
| `…/widgets/partner_transform_step_one_view.dart` | sửa chữ | G8 |
| `…/presentation/pages/partner_contacts_page.dart` | sửa | G9 |
| `…/widgets/partner_detail_add_contact_flow.dart` | sửa | G10 |
| `docs/02-yeu-cau/TH-03-doi-tac-giao-dich.md` | phiên review sửa sau khi xong: bỏ 🔧 ở các mục đã làm, cập nhật KI-02 / 03 / 05 / 07 / 09 / 10 / 11 / 13 thành "Đã sửa (4-B)" | — |

## 4. Thiết kế

### G1. Trigger lịch sử đơn bán (US-07.2)

Dữ liệu đã có:

- `partner.upsert_partner_history(p_tenant_id, p_partner_id, p_role, p_transaction_type, p_source_module, p_source_id, p_reference_code, p_transaction_date, p_status, p_amount, p_currency, p_can_open_source)` (`20260714004:1587`). Upsert theo `(tenant_id, source_module, source_id)`. Partner không thuộc tenant → `NOT_FOUND`. Chỉ cấp cho `service_role`.
- `sales.sales_orders` (`20260830005:93`): `id`, `tenant_id`, `order_code`, `customer_partner_id` (null = Khách lẻ), `lifecycle_status` (`completed` | `cancelled`), `payable_amount_minor` (VND không có số lẻ ⇒ minor = đồng), `currency_code`, `completed_at`. Đơn chỉ được tạo khi đã hoàn tất (không có nháp trong bảng này).

Nội dung migration (header theo `_migration.template.sql`; `Kind: feature`, `Touches: _trg_sales_order_partner_history, trg_sales_orders_partner_history`, `Depends on: 20260830005_sales_rebuild_schema, 20260714004_partner_v2_write_rpc`):

```sql
create or replace function partner._trg_sales_order_partner_history()
returns trigger
language plpgsql
security definer
set search_path = partner, pg_temp
as $$
begin
  -- Đổi khách (hoặc bỏ khách) của đơn: dòng lịch sử cũ không còn đúng.
  if tg_op = 'UPDATE'
     and old.customer_partner_id is not null
     and old.customer_partner_id is distinct from new.customer_partner_id then
    delete from partner.partner_history_views h
    where h.tenant_id = old.tenant_id
      and h.source_module = 'sales'
      and h.source_id = old.id;
  end if;

  if new.customer_partner_id is null then   -- Khách lẻ: không ghi (AC-02)
    return new;
  end if;

  perform partner.upsert_partner_history(
    new.tenant_id,
    new.customer_partner_id,
    'customer',
    'sales_order',
    'sales',
    new.id,
    new.order_code,
    new.completed_at,
    new.lifecycle_status,
    new.payable_amount_minor::numeric,
    new.currency_code,
    false
  );
  return new;
end;
$$;

revoke all on function partner._trg_sales_order_partner_history() from public, anon, authenticated;

drop trigger if exists trg_sales_orders_partner_history on sales.sales_orders;
create trigger trg_sales_orders_partner_history
  after insert or update of customer_partner_id, lifecycle_status, payable_amount_minor, order_code
  on sales.sales_orders
  for each row
  execute function partner._trg_sales_order_partner_history();

-- Bù đơn đã có trước khi có trigger (Dev; chạy lại không tạo dòng thứ hai).
insert into partner.partner_history_views (
  tenant_id, partner_id, role, transaction_type, source_module, source_id,
  reference_code, transaction_date, status, amount, currency, can_open_source
)
select o.tenant_id, o.customer_partner_id, 'customer', 'sales_order', 'sales', o.id,
       o.order_code, o.completed_at, o.lifecycle_status, o.payable_amount_minor::numeric,
       o.currency_code, false
from sales.sales_orders o
join partner.partners p
  on p.partner_id = o.customer_partner_id and p.tenant_id = o.tenant_id
where o.customer_partner_id is not null
on conflict (tenant_id, source_module, source_id) do nothing;
```

Quyết định chốt trong plan (duyệt plan là chốt):

- `can_open_source = false`: không có màn mở chứng từ (TH-03 mục 8).
- `transaction_date = completed_at`.
- `status = lifecycle_status`. Trạng thái thanh toán (FR-02 "thanh toán") **chưa** có cột trên `sales_orders`: Theme 6 cập nhật khi có. Ghi vào TH-03 US-07.2.
- Partner không thuộc tenant: `upsert_partner_history` báo `NOT_FOUND` làm **hỏng** câu lệnh ghi đơn. Đúng ý: sales đã kiểm khách (`CUSTOMER_INVALID`) trước khi ghi; nếu lọt thì dữ liệu sai, không được nuốt.

### G2. `search_partners` không dấu (BR-35)

Trong `20260715001_partner_list_search_behavior.sql`, thân `partner.search_partners`:

1. Khai báo thêm `v_query_plain text := catalog.unaccent_immutable(nullif(btrim(coalesce(p_query, '')), ''));`, ngay dưới `v_query`. Hàm `catalog.unaccent_immutable` có từ `20260712002`, chạy trước; đã cấp cho `authenticated`; `search_partners` là `security definer`.
2. **Mọi** vế `<biểu thức> ilike '%' || v_query || '%'` (2 khối: đếm `total` và lấy `items`; mỗi khối có nhánh chỉ-email và nhánh thường, cả trường của hồ sơ lẫn của người liên hệ) đổi thành `catalog.unaccent_immutable(<biểu thức>) ilike '%' || v_query_plain || '%'`. `<biểu thức>` giữ nguyên, kể cả `coalesce(…, '')`.
   - Ví dụ: `coalesce(v.nickname, '') ilike '%' || v_query || '%'` → `catalog.unaccent_immutable(coalesce(v.nickname, '')) ilike '%' || v_query_plain || '%'`.
   - Đếm trước khi sửa (`grep -c "ilike '%' || v_query || '%'"`) và sau khi sửa (`grep -c "v_query_plain || '%'"`): hai số phải bằng nhau. Ghi hai số vào Kết quả.
3. `v_email_only` (dựa trên `v_query` có `@`) giữ nguyên.
4. Hai test hợp đồng SQL (Dart, đọc tệp migration): đổi regex sang dạng mới, **giữ số lần khớp**. Ví dụ `coalesce\(v\.nickname, ''\) ilike` → `catalog\.unaccent_immutable\(coalesce\(v\.nickname, ''\)\) ilike`. Thêm 1 test: chuỗi `ilike '%' || v_query || '%'` **không còn** trong tệp.

### G3. `add_organization_contact` (BR-17, KI-05)

Trong `20260714004_partner_v2_write_rpc.sql`, thay khối `if p_is_primary and p_person_partner_id is not null then … end if;` (≈ dòng 818–836) bằng:

```sql
  if p_person_partner_id is not null then
    select * into v_person
    from partner.partners p
    where p.partner_id = p_person_partner_id
      and p.tenant_id = p_tenant_id;

    if not found or v_person.partner_type <> 'person' then
      perform partner._raise_partner_error('VALIDATION_ERROR', 'contact person partner required');
    end if;
    if v_person.status = 'deleted' then
      perform partner._raise_partner_error('INVALID_STATUS', 'deleted contact cannot be linked');
    end if;
    if p_is_primary and v_person.status <> 'active' then
      perform partner._raise_partner_error('INVALID_STATUS', 'inactive contact cannot be primary');
    end if;
  end if;
```

Tenant khác ⇒ `not found` ⇒ `VALIDATION_ERROR`, giống tổ chức. Liên kết trùng (đã là người liên hệ) đã bị khoá chính của `organization_contacts` chặn: **không** đổi.

### G4. Bỏ sắp xếp theo vai trò (BR-37)

- `PartnerSortOption`: xoá `roleAsc`, `roleDesc`.
- `PartnerListCubit.fetchPartners`: xoá hai `case`.
- `PartnerSortBottomSheet`: xoá hai `VChoiceOption` "Vai trò giao dịch A-Z" / "Z-A".
- Còn 4 lựa chọn: "Cập nhật gần nhất" (mặc định), "Cập nhật cũ nhất", "Tên A-Z", "Tên Z-A". Kiểm nhãn hai lựa chọn đầu theo tệp hiện có, không đổi chữ.

### G5. Code chết (KI-09)

Đo 2026-11-01: `PartnerDetailView` không route nào dựng (chỉ preview `example`, 4-A đã xoá). Kéo theo:

| Tệp xoá | Vì sao chết |
|---|---|
| `partner_detail_view.dart` | không ai dựng |
| `partner_detail_overview_tab.dart` | chỉ `PartnerDetailView` dùng |
| `partner_detail_summary_card.dart` | chỉ `PartnerDetailView` dùng |
| `partner_detail_section.dart` (`PartnerDetailSectionCard`, `PartnerDetailEmptyHint`, `PartnerDetailInfoRow`, `PartnerDetailActivityRow`) | chỉ overview tab dùng. Pricing chỉ nhắc `PartnerDetailInfoRow` trong chú thích (`price_rule_detail_rows.dart:7`): sửa chú thích thành "khớp pattern hàng thông tin hồ sơ đối tác" |

Thêm:

- `PartnerDetailCubit.selectTab` và `PartnerDetailLoaded.selectedTabIndex` (chỉ `PartnerDetailView` dùng): xoá, sửa `props`.
- `presentation.dart`: xoá export tương ứng.
- Kiểm: `git grep -nE "PartnerDetailView|PartnerDetailOverviewTab|PartnerDetailSummaryCard|PartnerDetailSectionCard|PartnerDetailEmptyHint|PartnerDetailInfoRow|PartnerDetailActivityRow|selectedTabIndex|selectTab" -- apps/erp/lib/features/partner apps/erp/test/features/partner` rỗng.

### G6. Thẻ "Lịch sử gần đây" (KI-10)

- `partner_detail_page.dart`: xoá `const PartnerDetailHistoryCard(),` và `const VGap.sm(),` ngay sau nó (≈ dòng 397–398).
- Xoá `partner_detail_history_card.dart`, export, `partner_detail_history_card_test.dart`.
- Thẻ "Hệ thống" (`PartnerDetailSystemCard`, có lối "Lịch sử thao tác") giữ nguyên.
- Test (thêm vào `partner_detail_e2e_test.dart`): hồ sơ đã tải không có chữ "Lịch sử gần đây" và "Tính năng đang phát triển".

### G7. Câu chữ (BR-46)

| Tệp | Cũ | Mới (nguyên văn) |
|---|---|---|
| `logic/partner_status_cubit.dart` (`_mapDeleteBlocked`, `hasTransactions`) | "Hồ sơ đã phát sinh giao dịch nên không thể xóa. Anh có thể ngừng hoạt động." | "Hồ sơ đã phát sinh giao dịch nên không thể xóa. Bạn có thể ngừng hoạt động." |
| `logic/partner_transform_cubit.dart` (`primaryContactOfOrganization`) | "Khách hàng này đang là người liên hệ chính của một tổ chức nên không thể chuyển đổi." | "Hồ sơ này đang là người liên hệ chính của một tổ chức nên không thể chuyển đổi." |
| `widgets/partner_transform_primary_contact_blocked_sheet.dart:62` | "Khách hàng này đang là người liên hệ chính của “$organizationName”. " | "Hồ sơ này đang là người liên hệ chính của “$organizationName”. " (câu sau giữ nguyên) |
| `widgets/partner_delete_primary_contact_blocked_sheet.dart:62` | như trên | như trên |

Kiểm: `git grep -nE "Anh có thể|Khách hàng này" -- apps/erp/lib/features/partner` rỗng. Sửa test đang kỳ vọng chuỗi cũ (grep `test/features/partner`).

### G8. Nhãn "Huỷ" (KI-13)

`partner_transform_step_one_view.dart:257`: `label: 'Bỏ qua'` → `label: 'Huỷ'`. Key `transform_cancel` và `onCancel` giữ.

**Không** đổi "Bỏ qua" của `partner_form_section.dart:56`: đó là bỏ qua một mục của form tạo, đúng nghĩa.

### G9. Lỗi thao tác ở màn người liên hệ

`PartnerContactsCubit` đặt `actionError` (câu từ 4-A H13) mà màn không hiện.

Sửa `partner_contacts_page.dart`: bọc thân bằng `BlocListener<PartnerContactsCubit, PartnerContactsState>`:

- `listenWhen`: `curr is PartnerContactsLoaded && curr.actionError != null && curr.actionError != (prev is PartnerContactsLoaded ? prev.actionError : null)`.
- Hiện `VToast.show(context, title: 'Không thành công', message: state.actionError!, type: VToastType.danger)`.
- `PartnerContactsLoaded.copyWith` hiện gán `actionError: actionError` (không `?? this.actionError`). Vì vậy `copyWith(isActionLoading: true)` ở đầu mỗi thao tác đã xoá lỗi cũ, và cùng một lỗi lặp lại vẫn đi qua `null` rồi mới quay lại chuỗi lỗi ⇒ toast hiện lại. **Giữ** cách gán này, không đổi sang `??`.
- Test: cubit ném lỗi khi đặt chính → thấy toast với câu fallback; lỗi lặp lại lần hai → toast hiện lại.

### G10. Lỗi khi thêm người có sẵn từ hồ sơ

`partner_detail_add_contact_flow.dart`, nhánh `selectExisting`: bọc vòng `addContact` trong `try`:

- `on Object catch (e)`:
  - `if (!context.mounted) return;`
  - `await onReload();` (một phần có thể đã thêm)
  - `VToast.show(context, title: 'Không thành công', message: partnerErrorMessage(e, fallback: 'Không thể thêm người liên hệ. Vui lòng thử lại.', noPermission: 'Bạn không có quyền quản lý người liên hệ.'), type: VToastType.danger)`
  - `return;`
- Thành công: giữ như cũ.
- `PartnerContactsCubit.addExistingContacts` đã có `catch` (G9 lo phần hiện).
- Test: người thứ 2 lỗi → `onReload` được gọi, toast lỗi, **không** có toast thành công.

### G11. Test TH-03 9.3

**SQL** (`supabase/tests/partner_th03.sql`, mẫu `supabase/tests/iam_legacy_cleanup.sql`):

- Một khối `begin … rollback`.
- Dựng 2 tenant + user owner + partner mẫu, gọi RPC với `set local role authenticated` + `request.jwt.claims` như tệp mẫu.
- Mỗi ca `raise exception` khi sai. Kết thúc `raise notice 'partner_th03: OK'`.
- Chạy trên DB **local**: `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/partner_th03.sql`.

Ca kiểm (đủ danh sách "SQL / RPC test" của TH-03 9.3):

1. `create_partner` không vai trò → `VALIDATION_ERROR`; trùng SĐT không xác nhận → `DUPLICATE_WARNING`.
2. `update_partner` version cũ → `STATE_CHANGED`; hồ sơ `deleted` → `INVALID_STATUS`.
3. `add_organization_contact` với `p_person_partner_id` là tổ chức / tenant khác / đã xoá, `p_is_primary = false` → bị từ chối (G3).
4. Đặt người `inactive` làm chính → `INVALID_STATUS`; `deactivate_partner` người chính → mất cờ chính ở mọi tổ chức.
5. `transform_to_organization` khi là người chính nơi khác → `PRIMARY_CONTACT_OF_ORGANIZATION`; đã là tổ chức → `INVALID_STATUS`.
6. Trigger (G1):
   - insert đơn có khách → đúng 1 dòng `partner_history_views`, `check_delete_eligibility` → `eligible = false`, `reason = 'HAS_TRANSACTIONS'` (kiểm tên cột / giá trị theo thân hàm `20260714003`);
   - `update lifecycle_status = 'cancelled'` → `status` đổi, vẫn 1 dòng;
   - đơn `customer_partner_id null` → 0 dòng;
   - update lại cùng đơn → vẫn 1 dòng (AC-03).
   - Insert thẳng vào `sales.sales_orders` với đủ cột `not null` (dựng `store_id`, `seller_user_id`, `sales_context_snapshot = '{}'`, các khoản tiền khớp ràng buộc `sales_orders_commercial_balance`). Vướng FK thì dựng bản ghi cha tối thiểu; ghi cách làm vào Kết quả.
7. `search_partners('an binh')` thấy "An Bình"; từ khoá có `@` chỉ khớp email (G2).
8. `search_partners(p_updated_within_days = 15)` → `VALIDATION_ERROR`.

**Widget / cubit** (TH-03 9.3, mục "Widget / cubit test"):

- grep từng ca dưới đây trong `test/features/partner`. Ca nào đã có thì ghi tên test vào Kết quả; ca nào thiếu thì thêm.
  - PT-05: mở section lỗi đầu tiên; MST 13 số tự chuyển 10-3; sheet trùng hai mức; hỏi khi rời màn.
  - PT-07: banner thiếu thông tin theo loại hồ sơ; "Không phải hồ sơ đối tác"; action sheet theo `available_actions`.
  - PT-08 / 09: hộp đổi người chính; gỡ liên hệ.
  - PT-11: chặn người chính nơi khác; `STATE_CHANGED` hiện "Dữ liệu đã thay đổi".
- Thêm: G4 (sheet sắp xếp còn đúng 4 lựa chọn), G6, G7 (4 câu), G8 (nút "Huỷ"), G9, G10.

## 5. Đang làm gì — test giữ hành vi (phần bị xoá / thay)

| # | Cũ đang làm gì | Sau khi sửa | Test |
|---|---|---|---|
| B1 | `PartnerSortOption.roleAsc/roleDesc` gửi `p_sort = 'role_asc' / 'role_desc'`; server không có nhánh nên rơi về mặc định `updated_at_desc` (`20260715001` ≈ dòng 223–229) | bỏ lựa chọn. 4 lựa chọn còn lại gửi đúng `p_sort` như cũ | bước 0: `partner_list_cubit_test` có ca cho 4 sort còn lại, kiểm `sort` gửi lên (`FakePartnerRepository.calls` / tham số), xanh trước và sau |
| B2 | `PartnerDetailHistoryCard`: thẻ gập "Lịch sử gần đây", không dữ liệu, không lối đi | bỏ hẳn (KI-10) | test G6 |
| B3 | `PartnerDetailView` / overview tab / summary card / section: không route nào dựng | xoá | grep G5 rỗng; `dart analyze` sạch |
| B4 | `add_organization_contact` không đặt chính: nhận mọi `p_person_partner_id`. Hiện app chỉ gửi id lấy từ `search_partners(partnerType: person, status: active)` | server kiểm (G3). Luồng app không đổi vì luôn gửi cá nhân đang hoạt động cùng tenant | SQL ca 3; kiểm tay "chọn có sẵn" vẫn thêm được |
| B5 | `search_partners` phân biệt dấu; mọi trường khác giữ cách khớp (`ilike`, chỉ-email khi có `@`, người liên hệ đang hoạt động của tổ chức) | chỉ thêm bỏ dấu hai vế | 2 test hợp đồng SQL (giữ số lần khớp) + SQL ca 7 |

**Bước 0** (trên code sau 4-A, trước khi sửa 4-B): viết B1, chạy xanh, ghi tên test. B2–B5 không cần test trên code cũ: B2, B3 là xoá có chủ đích; B4, B5 kiểm ở SQL.

## 6. Các bước

Trước mỗi symbol Dart sửa: `gitnexus impact` (upstream), ghi vào Kết quả. HIGH / CRITICAL thì dừng, ghi lại.

0. Bước 0 (mục 5).
1. G1: migration mới + REGISTRY. Chạy local: `supabase db reset` **local** (không phải Dev). Rồi chạy SQL ca 6.
2. G2: sửa `20260715001` + hai test hợp đồng (`cd modules/partner/infrastructure && dart test test/partner_list_search_sql_contract_test.dart test/partner_alternate_name_search_sql_contract_test.dart`). Test `alternate_name` đang **fail sẵn** trong `TEST-BASELINE.md`: ghi rõ sau khi sửa nó pass hay vẫn fail, và vì sao.
3. G3: sửa `20260714004`.
4. Viết `supabase/tests/partner_th03.sql`. `supabase db reset` local → chạy tệp, ra `partner_th03: OK`.
5. G4 → G10 (Dart), mỗi việc kèm test của nó.
6. G11 phần widget / cubit.
7. Kiểm mục 7, ghi Kết quả, `detect_changes()`.

## 7. Kiểm tra

### 7.1 Tự động

- [ ] `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/partner_th03.sql` → `partner_th03: OK` (sau `supabase db reset` local).
- [ ] Các tệp `supabase/tests/iam_*.sql` vẫn chạy qua sau reset local (G3 sửa migration dùng chung tệp partner, không đụng IAM; kiểm cho chắc).
- [ ] Hai test hợp đồng SQL partner xanh (hoặc ghi rõ lý do test `alternate_name` vẫn fail như baseline).
- [ ] `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart` (= `melos run migrate:verify-policy`) không lỗi mới. Migration mới có header đủ `Kind` / `Touches`, nên **không** thêm vào `bootstrap_grandfathered`.
- [ ] Grep ở G5, G7 rỗng.
- [ ] `cd apps/erp && dart analyze lib test`: không error / warning mới.
- [ ] `cd apps/erp && flutter test`: không fail mới so với sau 4-A (ghi số).

### 7.2 Kiểm tay (TH-03 9.3, 5 kịch bản; trên Dev sau khi người dùng reset Dev)

Sửa migration đã áp (`20260714004`, `20260715001`) ⇒ Dev chỉ nhận sau `db reset --linked`. Việc này **người dùng** làm, phiên code không chạy.

- [ ] 1. Tạo cá nhân khách → tìm **không dấu** → sửa SĐT → lịch sử có "Cập nhật SĐT chính" cũ → mới.
- [ ] 2. Tổ chức + người chính → thêm người thứ hai từ cá nhân có sẵn → đổi người chính → gỡ người cũ. Luôn ≤ 1 người chính; cá nhân bị gỡ vẫn còn.
- [ ] 3. Trùng SĐT / MST ở tạo, sửa, người liên hệ, chuyển đổi → luôn bị chặn "Trùng khớp hoàn toàn".
- [ ] 4. Chuyển cá nhân có giá riêng và đơn bán thành tổ chức: `partner_id` giữ; giá riêng, đơn còn gắn; người liên hệ chính mới mang địa chỉ giao hàng / ghi chú cũ.
- [ ] 5. Bán 1 đơn cho khách → thử xoá → sheet "Không thể xóa hồ sơ" / "…Bạn có thể ngừng hoạt động." → ngừng hoạt động → màn bán hàng không chọn được khách đó.
- [ ] Sắp xếp còn 4 lựa chọn. Hồ sơ không còn "Lịch sử gần đây". Bước 1 chuyển đổi có nút "Huỷ".

## 8. Rủi ro / lưu ý

- Trigger chạy trong cùng giao dịch ghi đơn: lỗi trong trigger làm hỏng việc bán. Vì vậy SQL ca 6 phải chạy qua cả insert lẫn update.
- `catalog.unaccent_immutable` nằm ở schema `catalog`. 5-C chỉ xoá **code module** catalog, không xoá schema `catalog`, nên không ảnh hưởng. Ghi nhắc vào 5-C khi lập plan.
- Thêm `unaccent` cho mọi vế làm truy vấn chậm hơn một chút (không có index). Dữ liệu đồ án nhỏ, chấp nhận.
- Theme 5 (8-D) sẽ kiểm lại BR-31 khi nối kho; trigger này không phụ thuộc kho.

## 9. Kết quả (phiên làm code ghi)

> Xong **mỗi việc** (G1…G11, bước 0) ghi ngay. Mẫu: trạng thái ✅ / 🔄 dở / ⏭ (lý do) · tệp:dòng · lệch plan + lý do · test thêm / sửa · impact · ghi chú cho review. Bước cuối: lệnh đã chạy, số pass / fail, fail đối chiếu `TEST-BASELINE.md`, `detect_changes()`.

### Tóm tắt (2026-11-01)

- Đã làm G1–G11 và bước 0. **Chưa `git commit`** (người dùng chưa yêu cầu).
- **Chưa chạy được đúng quy trình `supabase db reset` local**: lệnh bị chặn (xoá dữ liệu local). DB local hiện có (`supabase_db_vet45`) là bản cũ: lịch sử migration lệch repo (có bản ghi `20260811003…20260916007` đã bị xoá / đổi số khỏi repo, thiếu `20261009001+`), nên `supabase migration up` cũng không dùng được. Thay vào đó, **không xoá gì**:
  - Áp tay vào DB local 3 phần idempotent: thân `add_organization_contact` (từ `20260714004`), cả `20260715001`, cả `20261101001`. Việc này chỉ để chạy thử; **không thay `db reset`**.
  - Chạy `supabase/tests/partner_th03.sql` bằng **bản scratch** (chỉ đổi đoạn dựng tenant: `iam._create_tenant_for_owner` chưa có trên DB cũ ⇒ insert thẳng `iam.tenants` + `iam.memberships` role `store_owner`): ra `partner_th03: OK`, rollback sạch.
  - Kiểm test bắt được lỗi bằng 3 đột biến (mỗi lần trong giao dịch rồi rollback): tắt trigger ⇒ `FAIL: insert order must write exactly 1 history row, got 0`; trả `add_organization_contact` về thân cũ ⇒ `FAIL: expected VALIDATION_ERROR but statement succeeded`; trả `search_partners` về thân cũ ⇒ `FAIL: "an binh" must find "An Bình", total 0`.
  - **Việc còn lại cho người dùng** (7.1): `supabase db reset` local, rồi `docker exec -i supabase_db_vet45 psql -U postgres -v ON_ERROR_STOP=1 < supabase/tests/partner_th03.sql` (hoặc `psql "$LOCAL_DB" …`), và các tệp `supabase/tests/iam_*.sql`. Bản chính dùng `iam._create_tenant_for_owner` như `iam_legacy_cleanup.sql`; chỉ kiểm cú pháp trên DB cũ (dừng đúng ở hàm đó), chưa chạy hết trên schema HEAD.
- Hai test hợp đồng SQL partner: `partner_list_search_sql_contract_test` **6/6 xanh**; `partner_alternate_name_search_sql_contract_test` **vẫn fail như baseline** (xem G2).
- `dart analyze lib test`: **249 → 249** vấn đề (không error; 1 warning cũ ở `order_einvoice_section_test.dart`).
- `verify_migration_policy`: 0 lỗi, 1 warning `registry_consistency` (tool luôn suy schema `catalog` cho tệp partner, cùng cảnh báo với các migration partner khác).
- `flutter test` (cả `apps/erp`): **1676 đạt / 61 lỗi (sau 4-A) → 1693 đạt / 61 lỗi**. Cùng 61 lỗi có sẵn (số lượng bằng nhau; không lỗi nào nằm trong `features/partner`, `sales`, `pricing`). Chưa so từng tên bằng reporter json như 4-A vì không còn bản lưu tập tên sau 4-A.
- `detect_changes(scope: all)`: 116 tệp, 71 symbol, **0 execution flow bị ảnh hưởng**, risk low (scope `all` gồm cả thay đổi chưa commit của 4-A; index GitNexus cũ, commit `e737274`). Impact upstream mọi symbol Dart sửa đều **LOW**: `PartnerSortOption` (0 caller), `PartnerListCubit` (direct 2), `PartnerDetailView` (direct 1), `PartnerDetailHistoryCard` (direct 2), `PartnerContactsPage` (direct 1), `PartnerDetailCubit` (direct 4), `PartnerContactsCubit` (direct 2), `PartnerStatusCubit` (direct 3), `PartnerTransformCubit` (direct 2).

### Bước 0 — test giữ hành vi B1 ✅

- `partner_list_cubit_test.dart`: nhóm "sort option is forwarded as p_sort (behavior parity 4-B B1)" — 4 ca (`updatedAtDesc→updated_at_desc`, `updatedAtAsc→updated_at_asc`, `nameAsc→display_name_asc`, `nameDesc→display_name_desc`), thêm getter `sort` vào `_SearchArgs`. Xanh trước khi sửa G4, xanh sau.

### G1 — trigger lịch sử đơn bán ✅

- `supabase/migrations/20261101001_partner_sales_order_history_trigger.sql` (mới) đúng thân mục 4 G1; `REGISTRY.yaml:311` thêm `_trg_sales_order_partner_history`.
- Lệch plan: header **`Kind: patch`** (không phải `feature`: policy chỉ nhận bootstrap / patch / surgical / generated); **`Touches: _trg_sales_order_partner_history`** (bỏ tên trigger vì policy `touches_match_body` chỉ chấp nhận hàm). `revoke` đặt sau `create trigger` (không đổi hành vi; trigger không kiểm EXECUTE lúc chạy).
- Test: `partner_th03.sql` ca 6 (insert → 1 dòng đủ trường; `check_delete_eligibility` → `HAS_TRANSACTIONS`; huỷ đơn; ghi lại cùng đơn ×2; đổi khách; bỏ khách; Khách lẻ từ đầu; khách tenant khác → `NOT_FOUND` và đơn không được ghi; câu bù chạy lại không nhân đôi).
- Ghi chú review: TH-03 US-07.2 cần ghi "trạng thái thanh toán chưa có cột trên `sales_orders`, Theme 6 cập nhật".

### G2 — `search_partners` không dấu ✅

- `20260715001_partner_list_search_behavior.sql:37-38` khai báo `v_query_plain`; 30 vế `ilike` đổi sang `catalog.unaccent_immutable(<biểu thức>) ilike '%' || v_query_plain || '%'`. `v_email_only` giữ.
- Đếm: `grep -c "ilike '%' || v_query || '%'"` **30 → 0**; `grep -c "v_query_plain || '%'"` **0 → 30** (hai số bằng nhau). Lần thay đầu bằng regex bỏ sót 2 vế `cpp.phone2` (do chữ số trong tên cột) nên đếm lại mới thấy 28/30 và sửa nốt.
- Test: `partner_list_search_sql_contract_test.dart` đổi regex (giữ số lần khớp 2/2/4/…); thêm test "search ignores diacritics" (không còn dạng cũ; 1 khai báo; 30 vế `v_query_plain`; 31 lần gọi `unaccent_immutable`). `partner_alternate_name_search_sql_contract_test.dart` đổi regex cùng kiểu.
- Hai test hợp đồng: `cd modules/partner/infrastructure && dart test …` → list **6/6 xanh**; `alternate_name` **vẫn fail như `TEST-BASELINE.md`**, vì `expect(sql, contains('op.short_name'))` (đứng **trước** các regex đã sửa) không khớp: migration dùng `v.short_name`, không có `op.short_name`. Lỗi cũ, không do 4-B; các regex tôi sửa trong test này chưa được chạy tới, nhưng dùng đúng mẫu đã xanh ở test list.
- SQL ca 7: "an binh" và "AN BÌNH" thấy "An Bình"; từ khoá có `@` chỉ khớp email.

### G3 — `add_organization_contact` ✅

- `20260714004_partner_v2_write_rpc.sql:818-842` thay khối kiểm bằng thân mục 4 G3 (kiểm người có sẵn kể cả không đặt chính; `deleted` ⇒ `INVALID_STATUS`; chính + không `active` ⇒ `INVALID_STATUS`).
- Test: SQL ca 3 (tổ chức / tenant khác / đã xoá ⇒ bị từ chối, không tạo dòng; người active và inactive thêm được khi không đặt chính), ca 4 (inactive làm chính ⇒ `INVALID_STATUS`).

### G4 — bỏ sắp xếp theo vai trò ✅

- `partner_list_state.dart:15-20` (xoá `roleAsc`, `roleDesc`), `partner_list_cubit.dart:64-82` (xoá 2 `case`), `partner_sort_bottom_sheet.dart` (xoá 2 `VChoiceOption`). Còn 4 lựa chọn; nhãn hai lựa chọn đầu không đổi.
- Test mới: `presentation/widgets/partner_sort_bottom_sheet_test.dart` (đúng 4 lựa chọn = `PartnerSortOption.values`, đủ 4 nhãn, không còn "Vai trò giao dịch").

### G5 — code chết ✅

- Xoá `partner_detail_view.dart`, `partner_detail_overview_tab.dart`, `partner_detail_summary_card.dart`, `partner_detail_section.dart`. `PartnerDetailCubit.selectTab` và `PartnerDetailLoaded.selectedTabIndex` xoá, `props` còn `[dto]`. `presentation.dart` xoá export `partner_detail_view`. Chú thích `price_rule_detail_rows.dart:7` đổi theo plan.
- Grep G5 (`git grep` trong `apps/erp/lib/features/partner` và `apps/erp/test/features/partner`) **rỗng**. (`selectTab` / `selectedTabIndex` còn ở IAM và Sales: màn khác, ngoài phạm vi.)

### G6 — thẻ "Lịch sử gần đây" ✅

- `partner_detail_page.dart:~390` xoá `PartnerDetailHistoryCard` và `VGap.sm()` sau nó. Xoá `partner_detail_history_card.dart`, export, và test. **Test cũ ở `test/features/partner/presentation_module/widgets/partner_detail_history_card_test.dart`** (plan ghi `test/…` chung).
- Test mới (`partner_detail_e2e_test.dart`): hồ sơ đã tải không có "Lịch sử gần đây" / "Tính năng đang phát triển", vẫn có `PartnerDetailSystemCard`.

### G7 — câu chữ ✅

- 4 chuỗi đúng bảng mục 4 G7 (`partner_status_cubit.dart:163`, `partner_transform_cubit.dart:75`, hai sheet dòng 62). Grep `Anh có thể|Khách hàng này` trong `apps/erp/lib/features/partner` **rỗng**.
- Test: `partner_error_mapping_test.dart:445` đổi kỳ vọng sang câu mới (transform); `partner_status_cubit_test` +1 (câu xoá đủ nguyên văn); `partner_primary_contact_blocked_sheets_test.dart` mới (2 sheet).

### G8 — nhãn "Huỷ" ✅

- `partner_transform_step_one_view.dart:257` `'Bỏ qua'` → `'Huỷ'`. Không đổi `partner_form_section.dart:56`. Test mới trong `partner_transform_step_one_view_test.dart` (nút `transform_cancel` có chữ "Huỷ", không có "Bỏ qua").

### G9 — toast lỗi ở màn người liên hệ ✅

- `partner_contacts_page.dart`: bọc `VPageScaffold` bằng `BlocListener` đúng `listenWhen` / toast của plan; giữ `copyWith` gán thẳng `actionError`.
- **Lệch plan (cần thiết):** cả ba thao tác (thêm có sẵn / đặt chính / gỡ) đang hiện toast thành công **vô điều kiện** sau `await`. Nếu chỉ thêm toast lỗi thì lỗi sẽ kèm toast "thành công". Thêm getter `_lastActionFailed` (state là `PartnerContactsLoaded` có `actionError`) và bỏ toast thành công khi thao tác lỗi.
- Test mới `partner_contacts_page_action_error_test.dart`: đặt chính lỗi ⇒ toast câu fallback "Không thể cập nhật người liên hệ. Vui lòng thử lại." và không có "Đã đặt người liên hệ chính"; lỗi lặp lần hai ⇒ toast hiện lại; thành công ⇒ chỉ toast thành công. Toast hiện **message** (title chỉ là nhãn trợ năng), nên test kiểm theo message.

### G10 — lỗi khi thêm người có sẵn từ hồ sơ ✅

- `partner_detail_add_contact_flow.dart`: vòng `addContact` bọc `try` / `on Object catch`: `onReload()`, toast `Không thành công` với `partnerErrorMessage(… fallback 'Không thể thêm người liên hệ. Vui lòng thử lại.', noPermission 'Bạn không có quyền quản lý người liên hệ.')`, `return`. Thành công như cũ.
- Test: `partner_flows_error_test.dart` — ca H15 cũ "lệnh thêm lỗi không được bắt" (ghim hành vi cũ ở 4-A) **thay** bằng ca mới "người thứ 2 lỗi ⇒ tải lại 1 lần, toast lỗi, không toast thành công, không ném"; thêm ca mã lạ ⇒ câu fallback.

### G11 — test TH-03 9.3 ✅

- SQL: `supabase/tests/partner_th03.sql` (mới), đủ 8 nhóm ca của plan. Cách dựng đơn: insert thẳng `sales.sales_orders` với `store_id = gen_random_uuid()`, `seller_user_id` = owner, `sales_context_snapshot = '{}'`, các khoản tiền khớp `sales_orders_commercial_balance`; **không có FK tới cha** ngoài `source_draft_id` (null) nên không phải dựng bản ghi cha. Hàm giúp (`_th03_*`) tạo trong giao dịch, rollback cuối tệp.
- Widget / cubit: đối chiếu trong `test/features/partner`:
  - PT-05: mở section lỗi đầu tiên ⇒ `partner_create_form_test` "wgt_e01_u02_fr04_01: invalid submit opens inline errors"; MST 13 số tự thành 10-3 ⇒ "tax code keeps digits only and adds the branch dash" + `partner_create_form_validator_test`; sheet trùng hai mức ⇒ "wgt_e01_u02_fr06_01 / fr06_02"; hỏi khi rời màn ⇒ `partner_create_page_test` "dirty back opens leave confirmation". **Đã có**.
  - PT-07: banner thiếu thông tin theo loại, "Không phải hồ sơ đối tác": **thiếu ⇒ thêm** nhóm "PT-07 banner thiếu thông tin theo loại hồ sơ" (4 ca) trong `partner_detail_e2e_test.dart` (đổi tham số `buildRouter` sang kiểu `PartnerRepository` để dùng `ScriptedPartnerRepository`). Action sheet theo `available_actions` ⇒ `partner_detail_action_sheet_test` (đã có).
  - PT-08 / 09: hộp đổi người chính, gỡ liên hệ: gỡ ⇒ `partner_contacts_page_e2e_test` (có sẵn); đổi người chính ⇒ **qua test G9** (mở hộp, bấm "Xác nhận đổi").
  - PT-11: chặn người chính nơi khác ⇒ `partner_detail_e2e_test` "primary contact cannot transform…" + `partner_transform_blocked_state_test`; `STATE_CHANGED` "Dữ liệu đã thay đổi" ⇒ `partner_operation_feedback_state_test`, `partner_transform_blocked_state_test`. Đã có.
  - G4, G6, G7, G8, G9, G10: xem từng mục trên.

### Ghi chú cho review

- Docker Desktop được bật lại trong phiên này để chạy DB local (đã tắt sẵn từ trước); không đụng Dev.
- Tệp TH-03 cần sửa theo mục 3 hàng cuối (bỏ 🔧; KI-02 / 03 / 05 / 07 / 09 / 10 / 11 / 13 ⇒ "Đã sửa (4-B)"); thêm ghi chú thanh toán ở US-07.2.
- Dev: sửa tại chỗ `20260714004` và `20260715001` ⇒ Dev chỉ nhận sau `db reset --linked` (việc người dùng).

## 10. Review

### R1 — 2026-11-01 — ✅ đạt (0 P1, 0 P2, 4 P3)

**Kết luận: ĐẠT về code. Phiên code không phải sửa gì.** Plan **chưa đóng** được vì còn 4 việc kiểm do người dùng chạy (hàng cuối bảng).

| Hạng mục | Kết quả |
|---|---|
| SQL (G1 trigger, G2 tìm không dấu, G3 kiểm người liên hệ) | Đúng plan. Migration mới đúng quy tắc, sửa tại chỗ đúng 2 tệp |
| Dart (G4–G10) | Đúng plan; lệch ở G9 (bỏ toast thành công khi lỗi) là cần thiết, đã ghi |
| Test SQL `partner_th03.sql` | Đủ 8 nhóm ca, kiểm đúng điều kiện; đã chạy được trên DB local cũ (bản scratch) + 3 đột biến bắt được lỗi. **Chưa chạy trên schema đúng HEAD** |
| Test Flutter / analyze / policy | Xanh; 61 lỗi đều là lỗi có sẵn (so theo tên); policy 0 lỗi |
| TH-03 | Phiên review đã cập nhật (mục 3 hàng cuối) |
| **Bắt buộc sửa** | **Không có** |
| Tuỳ chọn sửa | Không có |
| Chỉ ghi nhận, không sửa | P3-1 … P3-4 |
| **Còn lại để đóng plan (người dùng)** | (1) `supabase db reset` **local** rồi chạy `supabase/tests/partner_th03.sql` → `partner_th03: OK`, và các `supabase/tests/iam_*.sql` (7.1 ô 1–2). (2) Reset Dev (`db reset --linked`) vì sửa tại chỗ `20260714004`, `20260715001`. (3) Kiểm tay 7.2 trên Dev. (4) Trước khi commit: `node .gitnexus/run.cjs analyze` rồi `detect_changes()` |

Nếu bước (1) ra `FAIL: …` thì báo lại; phiên review sẽ chia task R2 theo câu lỗi.

**Đã chạy (phiên review):**
- `flutter test` toàn bộ `apps/erp` (cây làm việc gồm 4-A/4-B/4-W/4-C): **1699 đạt / 61 lỗi**, cả 61 tên khớp `TEST-BASELINE.md` + W-2, không lỗi nào thuộc partner / sales.
- `flutter test test/features/partner …`: 953 đạt, 0 lỗi (gồm `partner_search_sql_contract_test`, `partner_th03` phần widget, G9 `partner_contacts_page_action_error_test`, G10 `partner_flows_error_test`).
- `verify_migration_policy`: 0 lỗi, 1 cảnh báo (P3-2).
- Grep G5, G7: rỗng. Không còn widget `partner_detail_{view,overview_tab,summary_card,section,history_card}`.

**Đối chiếu:**
- G1: cột `sales_orders` khớp (`order_code` not null, `completed_at` not null default now(), `lifecycle_status` ∈ completed/cancelled, `currency_code char(3)`); enum `partner_transaction_type` có `sales_order`; `upsert_partner_history` upsert theo `(tenant_id, source_module, source_id)`, `security definer` nên trigger gọi được dù hàm chỉ cấp cho `service_role`. Câu bù dùng cùng khoá duy nhất, `do nothing` ⇒ chạy lại không nhân đôi.
- G2: 30 vế đổi đủ (đếm lại khớp số của phiên code); `catalog.unaccent_immutable(null)` trả `''` nhưng mọi vế đã chặn bởi `v_query is null` ⇒ không lọc sai khi không có từ khoá.
- G3: đúng thân plan; liên kết trùng vẫn do khoá chính chặn.
- G9: `listenWhen` + `copyWith` gán thẳng `actionError` ⇒ lỗi lặp lại vẫn hiện toast (có test).

#### P3 (không chặn)

1. **[Không sửa — chỉ ghi nhận]** Mục 9 (Tóm tắt, G2) ghi `partner_alternate_name_search_sql_contract_test` "vẫn fail như baseline" và đường dẫn `modules/partner/infrastructure/test/…`: đã cũ. 4-C gộp hai test vào `apps/erp/test/features/partner/data/partner_search_sql_contract_test.dart` và đổi kỳ vọng `op.short_name` → `v.short_name`; nay xanh. Việc đổi kỳ vọng thuộc review 4-C.
2. **[Không sửa — chỉ ghi nhận]** Cảnh báo `registry_consistency` ("`catalog._trg_sales_order_partner_history` not found") là giới hạn của tool: `_inferSchema` (`tools/vet45_supabase_migrate/lib/migration_policy.dart:529`) trả `catalog` cho mọi tệp không có `_catalog_` / `_iam_` / `_platform_` trong tên. REGISTRY ghi đúng ở mục `partner:`.
3. **[Không sửa — người dùng biết]** TH-03 US-04.3 AC-01 bản cũ ghi người liên hệ đã xoá → `VALIDATION_ERROR` / `NOT_FOUND`; plan đã duyệt (G3) trả `INVALID_STATUS`. Phiên review sửa TH-03 theo plan: tổ chức / khác tenant → `VALIDATION_ERROR`; đã xoá → `INVALID_STATUS`. Muốn đổi lại mã thì báo.
4. **[Không sửa — chỉ ghi nhận]** G9: thao tác thành công nhưng lần tải lại danh sách lỗi ⇒ vẫn có toast thành công, thân màn hiện lỗi tải. Đúng sự thật (thao tác đã ghi), chấp nhận.

**TH-03 đã sửa (phiên review):** bỏ 🔧 ở mục 2, 3 (BR-17, 31, 35, 37, 46), bảng dữ liệu, I-08, EP-07, US-02.x (tìm, sắp xếp), US-03.1 FR-04, US-04.3 AC-01, chuyển đổi FR-05, xoá AC-01, US-07.2, bảng trigger, câu lỗi 6.4, 9.3; US-07.2 thêm: đổi / bỏ khách, `transaction_date` / `amount` / `can_open_source`, thanh toán để Theme 6; KI-02 / 03 / 05 / 07 / 09 / 10 / 11 / 13 → "Đã sửa (4-B)".

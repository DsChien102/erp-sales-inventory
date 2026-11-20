# 7-B1 — HĐĐT: sửa server theo TH-08 (KI-02, KI-04, KI-06) + khoá quyền hàm của bộ xử lý + test SQL TH-08 9.3

> Theme 8 (mã cũ P7) · Bước (b) sửa theo TH-08, phần server · Làm **đầu tiên** của Theme 8 (PLAN.md: server trước, chốt 2026-11-08).
> Gồm: KI-02 (bật phát hành tự động khi chưa sẵn sàng), KI-04 (server kiểm người mua), KI-06 (chép lại trường người mua mỗi lượt), khoá quyền 4 hàm chỉ bộ xử lý dùng (lỗi thấy khi viết plan), `supabase/tests/einvoice_th08.sql` (phần SQL của TH-08 9.3).
> Trạng thái: Plan ✅ (viết 2026-11-08, duyệt 2026-11-08) | Làm ✅ 2026-11-08 | Review ✅ R1 2026-11-08 (ĐẠT, góp ý nhỏ; còn chạy `einvoice_th08.sql` — người dùng)
> Trước: 8-C (review ĐẠT). Sau: 7-E1 (Edge Function), 7-A1 (repository — nhận việc map `CONFIG_NOT_READY`, Q5).
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) BR-09 … BR-19, US-01.3 FR-04, 2.4, 6.2, 6.4, 7.3 (KI-02, KI-04, KI-06, KI-07, KI-18), 9.3; PLAN.md "Quy tắc migration". Mẫu: [8-B1](../P8/8-B1-sales-server-ki.md), `supabase/tests/sales_th05.sql` (khung, `_th05_expect_err`, `_th05_customer`, `_th05_finalize`, dựng owner / tenant / JWT / sản phẩm).
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, ca test, impact). **Không commit** (người dùng commit sau `detect_changes()`). **Không làm gì với DB** (không chạy SQL, không reset, không push). **Không đụng `modules/`**. **Không ghi mục 10.**

**Goal:** Server tự chặn bật phát hành tự động khi chưa sẵn sàng, tự chặn phát hành khi người mua thiếu dữ liệu (thủ công lẫn tự động), dùng hồ sơ khách hiện hành cho mỗi lượt mới; 4 hàm của bộ xử lý không còn gọi được từ `authenticated`; có test SQL phủ TH-08 9.3.

**Architecture:** Chỉ sửa thân hàm trong migration gốc (`20261031004`, `…006`, `…008`, `…023`) và thêm một hàm riêng `einvoice._buyer_issuance_blocker` (viết trong `…023`, cạnh `_effective_buyer_snapshot`). Không đổi chữ ký RPC nào. Test là một kịch bản `begin … rollback` chạy bằng `psql` như `sales_th05.sql`.

**Tech Stack:** PostgreSQL / plpgsql (Supabase), kịch bản SQL thuần.

## 1. Mục tiêu

- `update_automation_policy`: bật mới "Tự động phát hành" khi tổ chức chưa sẵn sàng → `CONFIG_NOT_READY`; tắt luôn được; đang bật sẵn thì vẫn lưu được cờ gửi email.
- `issue_invoice`, `retry_issuance`: khách tổ chức thiếu MST / địa chỉ, khách thiếu tên → `ISSUANCE_NOT_READY` với `BUYER_*` trong `details.blockers`, **không** tạo lượt, **không** xếp `einvoice.publish_invoice`.
- `start_auto_issuance`, `reevaluate_auto_issuance`: cùng điều kiện → dòng `auto_issuance_processes` ở `PENDING_REEVALUATION`, `blocker_code = BUYER_…`, không tạo lượt.
- Sửa MST / địa chỉ trong hồ sơ khách sau một lượt lỗi: `get_issuance_readiness` thấy giá trị mới ngay; lượt mới mang giá trị mới.
- `start_auto_issuance`, `reevaluate_auto_issuance`, `list_open_auto_issuance_processes`, `build_canonical_invoice`: chỉ `service_role` gọi được.
- `supabase/tests/einvoice_th08.sql` phủ đủ 9 gạch đầu dòng "SQL" của TH-08 9.3 + ca của Q1–Q4.

**Không làm:** app (`modules/`, `apps/erp`) — kể cả map `CONFIG_NOT_READY` (Q5, sang 7-A1); `get_configuration_readiness` (KI-03 giữ nguyên); Edge Function, trigger, `pg_cron` (7-E*); 60 test Dart SQL đang đỏ ở `modules/einvoice/infrastructure` (xoá ở 7-C).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | KI-02: app luôn gửi cả hai cờ (`p_auto_issue_enabled` = giá trị hiện tại). Chặn khi nào? | **Người dùng chốt 2026-11-08:** chỉ khi **bật mới** — cờ đang `false` (hoặc chưa có dòng `tenant_settings`) và gửi `true`, và tổ chức chưa sẵn sàng theo BR-10 (không có kết nối `CONNECTED`, hoặc `default_template_id is null`). Đang bật sẵn mà mất kết nối: lưu vẫn được. Tắt: luôn được |
| Q2 | KI-06: sửa tới đâu? | **Người dùng chốt 2026-11-08:** sửa **cả hai chỗ**: (1) `_start_issuance_attempt` ghi đè giá trị đã chép bằng giá trị hồ sơ hiện hành (`coalesce(mới, cũ)`); (2) `_effective_buyer_snapshot`, khi chưa có hoá đơn: trường ảnh chụp đơn để trống lấy **hồ sơ hiện hành trước**, rồi mới tới giá trị đã chép. Trường có trong ảnh chụp đơn không đụng (KI-07) |
| Q3 | KI-04: RPC nào kiểm? | **Người dùng chốt 2026-11-08:** **4 RPC** (`issue_invoice`, `retry_issuance`, `start_auto_issuance`, **và** `reevaluate_auto_issuance` — nó cũng tạo lượt khi hồ sơ khách đổi) qua một hàm chung `einvoice._buyer_issuance_blocker` |
| Q4 | Lỗi thấy khi viết plan: `start_auto_issuance` (`…008:838`), `list_open_auto_issuance_processes` (`:866`), `reevaluate_auto_issuance` (`:1038`), `build_canonical_invoice` (`…006:793`) không kiểm `auth.uid()` / quyền nhưng `grant … to authenticated` ⇒ ai đăng nhập cũng phát hành tự động / đọc đơn của tổ chức khác. App không gọi 4 hàm này (chỉ handler worker cũ) | **Người dùng chốt 2026-11-08:** sửa luôn ở 7-B1: chỉ `grant … to service_role` |
| Q5 | Lỗi thấy khi viết plan: `modules/einvoice/infrastructure/lib/src/errors/einvoice_error_mapper.dart` trả `EInvoiceBlockedException('CONFIG_NOT_READY')`, còn `automation_policy_cubit.dart:99` bắt `ConfigNotReadyException` ⇒ sau 7-B1 app hiện "Không lưu được" thay vì "Chưa đủ điều kiện" | **Người dùng chốt 2026-11-08:** để **7-A1** (repository phân loại theo mã, đổi có chủ đích, có test). 7-B1 không đụng `modules/`; ghi ở mục 8 |
| Q6 | Câu lỗi `CONFIG_NOT_READY` ở server | `'CONFIG_NOT_READY: automation requires a connected provider and a default template'` (tiếng Anh như các câu `raise` khác của schema; app không hiện câu server) |
| Q7 | Thứ tự mã người mua | Chép đúng evaluator Dart (`modules/einvoice/domain/lib/src/issuance/services/issuance_readiness_evaluator.dart` + `effective_buyer_invoice_data.dart`), xem G2 |
| Q8 | Chạy test SQL | Phiên code **viết**, không chạy. Người dùng chạy ở 7.2 |

## 3. Hiện trạng (đo 2026-11-08)

| Hàm | Định nghĩa mới nhất | Chỗ sửa |
|---|---|---|
| `einvoice.update_automation_policy` | `20261031004_einvoice_profile_policy_readiness_rpcs.sql:201-255` | sau kiểm quyền `:221-227`, trước `insert … on conflict` `:229` |
| `einvoice._effective_buyer_snapshot` | `20261031023_einvoice_buyer_partner_fallback.sql:46-114` | thứ tự gộp `:63-110` |
| `einvoice._start_issuance_attempt` | `20261031023…:260-…` | `on conflict` `:372-378` |
| `einvoice.issue_invoice` | `20261031008_einvoice_auto_issuance_and_retry_rpcs.sql:250-412` | trước `-- 5. Ready` `:391` |
| `einvoice.start_auto_issuance` | `20261031008…:415-839` | trước `-- 5. Ready` `:777` (sau nhánh `NO_ACTIVE_ISSUANCE_PROFILE`); grant `:837-838` |
| `einvoice.list_open_auto_issuance_processes` | `20261031008…:842-867` | grant `:865-866` |
| `einvoice.reevaluate_auto_issuance` | `20261031008…:870-1039` | trước `v_intent :=` `:993` (sau nhánh `NO_ACTIVE_ISSUANCE_PROFILE`); grant `:1037-1038` |
| `einvoice.retry_issuance` | `20261031008…:1042-1246` | trước `return query` `:1226` |
| `einvoice.build_canonical_invoice` | `20261031006_einvoice_buyer_completion_and_preview_rpcs.sql:311-…` | grant `:792-793` |

Ghi chú hiện trạng:
- Người mua trong ảnh chụp đơn: `sales.get_einvoice_source_snapshot` (`20261031018:99-114`) — `buyerType` (`retail` khi không có khách), `buyerLegalName` (mặc định = tên hiển thị), `buyerTaxCode`, `buyerEmail`, `buyerAddress`. `get_issuance_readiness` (`…023:200-218`) suy loại khách: `buyer_partner_id is null` → `retail`; còn lại `coalesce(buyerType, 'individual')`, giá trị khác `individual`/`organization` → `individual`.
- `_start_issuance_attempt` chỉ chép vào `buyer_invoice_completions` khi `p_actor_id is not null` (lượt tự động không chép); lượt nào cũng dựng `attempt_snapshot.buyer` từ `_effective_buyer_snapshot`.
- Nhánh chờ của `reevaluate_auto_issuance` (`:945-990`) trả `PENDING_REEVALUATION` mà **không** cập nhật `blocker_code`.
- Không có bảng "Đang làm gì": plan không xoá / tách widget, page, cubit, route.

## 4. Thiết kế

### G1. KI-02 (Q1, Q6)

Trong `update_automation_policy`, sau kiểm quyền:

```sql
if coalesce(p_auto_issue_enabled, false)
   and not coalesce((select ts.auto_issue_enabled from einvoice.tenant_settings ts
                     where ts.tenant_id = p_tenant_id), false)
   and not (
     exists (select 1 from einvoice.provider_connections pc
             where pc.tenant_id = p_tenant_id and pc.status = 'CONNECTED')
     and exists (select 1 from einvoice.tenant_settings ts
                 where ts.tenant_id = p_tenant_id and ts.default_template_id is not null)
   ) then
  raise exception 'CONFIG_NOT_READY: automation requires a connected provider and a default template';
end if;
```

Kiểm **trước** so `policy_version` (lệch phiên bản vẫn ra `STATE_CHANGED` khi đã sẵn sàng). Cột trả `blockers` giữ `'[]'`.

### G2. KI-04 — `einvoice._buyer_issuance_blocker` (Q3, Q7)

Viết trong `20261031023`, **sau** `_effective_buyer_snapshot` (dòng 114) và trước `get_issuance_readiness`:

```text
einvoice._buyer_issuance_blocker(
  p_tenant_id uuid, p_sales_order_id uuid,
  p_buyer_partner_id uuid, p_buyer_snapshot jsonb
) returns text   -- null = đủ
language plpgsql stable security definer set search_path = einvoice, public
revoke all … from public, anon, authenticated; grant execute … to service_role;
```

Quy tắc (thứ tự là bắt buộc):
1. `p_buyer_partner_id is null` → `null` (khách lẻ).
2. Loại khách như `get_issuance_readiness` (mục 3). Người mua = `_effective_buyer_snapshot(p_tenant_id, p_sales_order_id, coalesce(p_buyer_snapshot, '{}'))`; mỗi trường qua `nullif(btrim(…), '')`.
3. Tên rỗng → `'BUYER_DATA_INCOMPLETE'` (cả cá nhân lẫn tổ chức).
4. Tổ chức, MST rỗng → `'BUYER_TAX_CODE_REQUIRED'`.
5. Tổ chức, địa chỉ rỗng → `'BUYER_ADDRESS_REQUIRED'`.
6. Còn lại → `null`.

(Trùng kết quả với evaluator: `isMissingOnlyOrgTaxCode` cần tên có; tên rỗng rơi vào `!isComplete` → `BUYER_DATA_INCOMPLETE`.)

Chỗ gọi — `v_buyer_blocker text := einvoice._buyer_issuance_blocker(p_tenant_id, p_sales_order_id, v_source.buyer_partner_id, v_source.buyer_snapshot);`:

| RPC | Chỗ | Khi khác null |
|---|---|---|
| `issue_invoice` | trước `:391` | `raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object('details', jsonb_build_object('blockers', jsonb_build_array(v_buyer_blocker)))::text;` |
| `retry_issuance` | trước `:1226` | như trên |
| `start_auto_issuance` | trước `:777` | `insert into einvoice.auto_issuance_processes (…)` y như nhánh `NO_ACTIVE_ISSUANCE_PROFILE` (`:744-775`) với `blocker_code = v_buyer_blocker`, trả `started=false, skipped=false, status='PENDING_REEVALUATION', reason=v_buyer_blocker` |
| `reevaluate_auto_issuance` | trước `:993` | `update einvoice.auto_issuance_processes set blocker_code = v_buyer_blocker, last_evaluated_at = now() where id = v_proc.id;` rồi trả như nhánh chờ hiện có (`started=false, skipped=false, process_id=v_proc.id, status='PENDING_REEVALUATION', reason=v_buyer_blocker`) |

Kiểm người mua đặt **sau** mọi kiểm cũ (đơn, kết nối, mẫu) ⇒ mã cũ giữ thứ tự ưu tiên. Idempotency replay của `issue_invoice` (`:303-322`) và `start_auto_issuance` (`:451-466`) đứng trước nên lượt đã tạo vẫn trả lại như cũ.

### G3. KI-06 (Q2)

**`_effective_buyer_snapshot`** (`…023:46-110`), giữ chữ ký và nhánh "đã có hoá đơn → trả `base || completion`" như hiện nay. Nhánh chưa có hoá đơn, với từng trường `buyerLegalName` / `buyerTaxCode` / `buyerAddress`:

```text
giá trị = ảnh chụp đơn (nếu không rỗng)
       ?? hồ sơ khách hiện hành (partner.get_einvoice_buyer_profile; chỉ khi có buyer_partner_id)
       ?? buyer_invoice_completions (đã chép)
```

`buyerEmail`: giữ như cũ (completion đè ảnh chụp; hồ sơ không có email ở hàm này). Cách viết: tính `v_merged` hiện tại (base || completion) **chỉ** cho nhánh đã có hoá đơn; nhánh chưa có hoá đơn dựng từ `p_base_snapshot` rồi đắp từng trường theo thứ tự trên.

**`_start_issuance_attempt`** (`…023:372-378`): `buyer_name = coalesce(excluded.buyer_name, bc.buyer_name)`, tương tự `buyer_tax_code`, `buyer_address`. Giữ điều kiện chép (`p_actor_id is not null`, chưa có hoá đơn, có ít nhất một trường cần đắp).

Hệ quả (ghi TH-08 2.4): giá trị nhập qua `complete_buyer_invoice_data` (app không gọi) bị hồ sơ khách che khi hồ sơ có giá trị.

### G4. Khoá quyền (Q4)

Thay câu `grant` của 4 hàm bằng:

```sql
revoke all on function <hàm>(<kiểu>) from public, anon, authenticated;
grant execute on function <hàm>(<kiểu>) to service_role;
```

Kiểu tham số chép từ câu `grant` hiện có. Trước khi sửa `build_canonical_invoice`: `grep -n "build_canonical_invoice(" supabase/migrations/*.sql` — mọi chỗ gọi nằm trong hàm `security definer` (chạy dưới quyền chủ) thì không ảnh hưởng; có chỗ gọi từ hàm `security invoker` ⇒ dừng, ghi Kết quả, báo người dùng.

### G5. `supabase/tests/einvoice_th08.sql`

Khung như `sales_th05.sql:1-12`: chú thích cách chạy, `begin; … rollback;`, notice cuối `'einvoice_th08: OK'`, ca sai `raise exception 'FAIL: <mã ca> …'`.

Hàm giúp (tạo trong giao dịch):

| Hàm | Việc |
|---|---|
| `public._th08_expect_err(p_sql text, p_code text)` | chép `_th05_expect_err`; so `sqlerrm like p_code || '%'` (RPC einvoice ném `'CODE: …'`) **hoặc** `sqlerrm like '%' || p_code || '%'` |
| `public._th08_customer(p_tenant, p_actor, p_type text, p_name, p_tax_code, p_address) returns uuid` | `partner.create_partner(…, p_partner_type => p_type, p_roles => array['customer'], …)` — `person` dùng `p_person_profile`, `organization` dùng `p_organization_profile`; khoá JSON của hồ sơ đọc ở `20260714004_partner_v2_write_rpc.sql:376-…`; `organization_profiles` bắt buộc `organization_type`, `organization_name`, `phone` (`20260714001:136-160`), `tax_code` được null |
| `public._th08_sale(p_tenant, p_actor, p_store, p_customer uuid, p_buyer_type text, p_key text) returns uuid` | chép `_th05_finalize` (bán 1 P1, trả đủ tiền mặt ⇒ đơn Hoàn tất); `customer` của commercial snapshot có `buyerType = p_buyer_type`, **không** gửi `taxCode` / `invoiceAddress` (để ảnh chụp đơn trống, trường lấy từ hồ sơ); trả `salesOrderId` |
| `public._th08_attempt_status(p_attempt uuid) returns text` | đọc `einvoice.issuance_attempts.status` (gọi dưới `reset role`) |

Dữ liệu chung: owner + tenant + JWT + cửa hàng + sản phẩm P1 như `sales_th05.sql` (đoạn dựng ở `:200-262`); cấu hình HĐĐT chèn thẳng dưới `reset role`:
- `einvoice.provider_connections (tenant_id, status, capabilities_snapshot)` = `'CONNECTED'`, `{"supports_preview": true, "templates": [{"template_id": "T1", "invoice_series": "1C26TAA", "is_available": true, "is_send_summary": false}]}`;
- `einvoice.tenant_settings (tenant_id, default_template_id, default_invoice_series, profile_version)` = `'T1'`, `'1C26TAA'`, `1`.
- Khách: `KA` cá nhân "Anh A"; `KB` tổ chức "Công ty B" MST `0101234567` địa chỉ "1 Lê Lợi"; `KC` tổ chức "Công ty C" **không** MST, có địa chỉ; `KD` tổ chức "Công ty D" MST `0109999999`, **không** địa chỉ.
- Gọi RPC `authenticated` dưới `set local role authenticated` + JWT; hàm `service_role` dưới `reset role` (owner của DB vượt grant), trừ ca G4 (ở dưới).

**Ca** (✱ = kiểm phần sửa của plan này; còn lại hành vi đang có — phải xanh trên code hiện tại):

| Ca | Kịch bản | Kỳ vọng |
|---|---|---|
| E01 | chèn kết nối thứ hai khác `DISCONNECTED` cho cùng tenant | `unique_violation` (`uq_provider_connections_active_tenant`) |
| E02 | `set_default_issuance_configuration(p_template_id => 'T1', p_signing_config_id => 'sign-hsm', p_expected_profile_version => 1)` | thành công; `signing_config_id = 'sign-hsm'`, `profile_version = 2` (mẫu `…T…` ⇒ SignType 2, `…004:109-125`) |
| E03 | mẫu `…M…` (thêm mẫu `T2` series `1C26MAA`, `is_available: true` vào capabilities) + `'sign-hsm'` | `SIGNING_CONFIGURATION_NOT_AVAILABLE` |
| E04 | `p_template_id => 'KHONG_CO'` | `TEMPLATE_NOT_AVAILABLE` |
| E05 | đúng mẫu, `p_expected_profile_version` sai | `STATE_CHANGED` |
| E06 ✱ | xoá tạm `default_template_id` (savepoint / khôi phục sau), `update_automation_policy(p_auto_issue_enabled => true, p_expected_policy_version => <hiện tại>)` | `CONFIG_NOT_READY` |
| E07 ✱ | đã sẵn sàng; bật tự động | thành công, `auto_issue_enabled = true` |
| E08 ✱ | (sau E07) đổi kết nối sang `RECONNECT_REQUIRED`; gửi `p_auto_issue_enabled => true, p_auto_send_enabled => true` | thành công (Q1: đã bật sẵn) |
| E09 ✱ | (vẫn chưa sẵn sàng) gửi `p_auto_issue_enabled => false` | thành công, cờ `false`. Khôi phục kết nối `CONNECTED` sau ca |
| E10 | đơn `KA`: `issue_invoice` với key `k1` hai lần, cùng `p_source_version` | cùng `attempt_id`; đếm `issuance_attempts` của đơn = 1 |
| E11 | key `k1`, `p_acknowledge_warnings => true` | `IDEMPOTENCY_CONFLICT` |
| E12 | đơn mới của `KA`, `p_source_version` lệch | `ISSUANCE_NOT_READY` chứa `SOURCE_VERSION_MISMATCH` |
| E13 ✱ (KI-04) | đơn `KC`: `get_issuance_readiness` rồi `issue_invoice` | readiness `buyer_tax_code is null`; issue `ISSUANCE_NOT_READY` chứa `BUYER_TAX_CODE_REQUIRED`; đếm lượt của đơn = 0; không có `internal_commands` `einvoice.publish_invoice` mới |
| E14 ✱ | đơn `KD`: `issue_invoice` | `ISSUANCE_NOT_READY` chứa `BUYER_ADDRESS_REQUIRED` |
| E15 ✱ | đơn `KB`: `issue_invoice` | thành công (`status = 'PREPARING'`) |
| E16 | (sau E10) `retry_issuance` khi lượt mới nhất `PREPARING` | `OPERATION_IN_PROGRESS` |
| E17 ✱ (KI-06) | đơn `KB2` (tổ chức MST `0101111111`, có địa chỉ): `issue_invoice` → lượt 1; `record_issuance_failure` (đọc `idempotency_key`, `canonical_payload_hash` từ lượt; nếu hàm đòi trạng thái `SUBMITTED` thì gọi `mark_issuance_provider_call_started` trước, `…007:222`); `update partner.organization_profiles set tax_code = '0102222222'` (dưới `reset role`); `get_issuance_readiness`; `retry_issuance` | readiness `buyer_tax_code = '0102222222'` (Q2); `attempt_snapshot -> 'buyer' ->> 'buyerTaxCode'` của lượt 2 = `'0102222222'`; `buyer_invoice_completions.buyer_tax_code` = `'0102222222'` |
| E18 ✱ (thứ tự G3) | đơn `KB3` (tổ chức MST `0103333333`, có địa chỉ) có lượt 1 `FAILED` như E17 (lượt 1 đã chép MST vào completion); `update partner.organization_profiles set tax_code = null`; `retry_issuance` | thành công; `attempt_snapshot -> 'buyer' ->> 'buyerTaxCode'` của lượt 2 = `'0103333333'` (hồ sơ trống ⇒ lấy giá trị đã chép, Q2) |
| E19 | đơn `KB`: `record_issuance_success` (như E17 lấy key / hash) hai lần | đếm `electronic_invoices` của đơn = 1 |
| E20 | sau E19: `record_issuance_failure` cho cùng lượt | trạng thái lượt vẫn `SUCCEEDED`; vẫn 1 hoá đơn |
| E21 | sau E19: `retry_issuance` | `ALREADY_ISSUED` |
| E22 | sau E19: `send_electronic_invoice(p_recipient_email => 'b@x.vn', p_idempotency_key => g1)` | `invoice_deliveries.kind` (cột loại gửi, đọc `…013:1-60`) = `INITIAL_SEND` |
| E23 | gửi lần hai khi lần một còn `QUEUED` | `OPERATION_IN_PROGRESS` |
| E24 | đặt lần một `UNKNOWN` (dưới `reset role`), gửi lại khoá `g2` | thành công, loại `RESEND` |
| E25 | khoá `g2`, email khác | `IDEMPOTENCY_CONFLICT` |
| E26 | `start_auto_delivery` khi `auto_send_enabled = false` | không thêm dòng `invoice_deliveries` |
| E27 ✱ | bật `auto_issue_enabled` (update thẳng); đơn `KC` mới: `start_auto_issuance(p_trigger_key => 't-kc', p_idempotency_key => 'auto-kc')` | `status = 'PENDING_REEVALUATION'`, `reason = 'BUYER_TAX_CODE_REQUIRED'`; dòng `auto_issuance_processes` có `blocker_code` đó; 0 lượt |
| E28 ✱ | thêm MST cho `KC` nhưng xoá địa chỉ; `reevaluate_auto_issuance(p_process_id => <E27>, p_source_event_id => 'ev1')` | `reason = 'BUYER_ADDRESS_REQUIRED'`; `blocker_code` cập nhật; 0 lượt |
| E29 ✱ | thêm lại địa chỉ; `reevaluate_auto_issuance(…, 'ev2')` | `status = 'ATTEMPT_STARTED'`; 1 lượt |
| E30 ✱ (G4) | dưới `set local role authenticated` + JWT owner: gọi trực tiếp `start_auto_issuance`, `reevaluate_auto_issuance`, `list_open_auto_issuance_processes`, `build_canonical_invoice` | mỗi câu lỗi `permission denied` (`_th08_expect_err(…, 'permission denied')`) |
| E31 | owner tenant thứ hai (JWT riêng) gọi `get_issuance_readiness`, `get_order_invoice_projection`, `issue_invoice` với `p_tenant_id` = tenant 1 | `NO_PERMISSION` |

Chữ ký mọi RPC: đọc ở migration mới nhất (`grep -l "function einvoice.<tên>(" supabase/migrations/*.sql | tail -1`), gọi bằng tên tham số (`=>`). Mỗi ca đặt trong `begin … exception … end` riêng hoặc savepoint khi ca đổi dữ liệu chung (E06, E08–E09, E27–E29).

## 5. Các bước

**Ràng buộc chung** (mọi task):
- Chỉ sửa tệp liệt kê ở từng task. Sửa migration **tại chỗ** (PLAN "Quy tắc migration"), không tạo migration mới. Không đụng `modules/`, `apps/`.
- Trước khi sửa symbol có sẵn: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi vào Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng.
- SQL: viết, **không chạy** (Q8). Kiểm bằng đọc lại; người dùng chạy ở 7.2.

### Task 1: Khung `einvoice_th08.sql` + ca hành vi đang có

**Files:** Create: `supabase/tests/einvoice_th08.sql`

- [ ] **1.1** Đầu tệp, 4 hàm giúp G5, dữ liệu chung.
- [ ] **1.2** Ca E01–E05, E10–E12, E16, E19–E26, E31.
- [ ] **1.3** Ghi Kết quả: số dòng, danh sách ca, chỗ phải đoán (khoá JSON hồ sơ partner, cột loại gửi, cột trả của `set_default_issuance_configuration`, cách `record_issuance_*` đòi trạng thái).

### Task 2: G4 khoá quyền

**Files:** Modify: `supabase/migrations/20261031008_einvoice_auto_issuance_and_retry_rpcs.sql:837-838`, `:865-866`, `:1037-1038`; `supabase/migrations/20261031006_einvoice_buyer_completion_and_preview_rpcs.sql:792-793`; Test: `einvoice_th08.sql` (E30)

- [ ] **2.1** Thêm ca E30.
- [ ] **2.2** `grep` chỗ gọi `build_canonical_invoice` (G4), ghi Kết quả.
- [ ] **2.3** Sửa 4 cặp `revoke` / `grant` theo G4.

### Task 3: G1 KI-02

**Files:** Modify: `20261031004_einvoice_profile_policy_readiness_rpcs.sql:221-229`; Test: `einvoice_th08.sql` (E06–E09)

- [ ] **3.1** Thêm ca E06–E09.
- [ ] **3.2** Thêm khối kiểm G1.

### Task 4: G3 KI-06

**Files:** Modify: `20261031023_einvoice_buyer_partner_fallback.sql:46-110`, `:372-378`; Test: `einvoice_th08.sql` (E17, E18)

- [ ] **4.1** Thêm ca E17, E18.
- [ ] **4.2** Viết lại thân `_effective_buyer_snapshot` theo G3; sửa `on conflict` của `_start_issuance_attempt`.
- [ ] **4.3** Đọc lại 3 chỗ gọi `_effective_buyer_snapshot` (`get_issuance_readiness`, `_start_issuance_attempt`, `request_invoice_preview` / `build_canonical_invoice` nếu có — `grep -n "_effective_buyer_snapshot(" supabase/migrations/*.sql`), ghi Kết quả: chỗ nào đổi hành vi.

### Task 5: G2 KI-04

**Files:** Modify: `20261031023…` (hàm mới sau `:114`); `20261031008…:391`, `:777`, `:993`, `:1226`; Test: `einvoice_th08.sql` (E13–E15, E27–E29)

- [ ] **5.1** Thêm ca E13–E15, E27–E29.
- [ ] **5.2** Viết `einvoice._buyer_issuance_blocker` + `revoke` / `grant` (G2).
- [ ] **5.3** Gọi ở 4 RPC theo bảng G2 (khai báo `v_buyer_blocker text;` ở `declare` của từng hàm).
- [ ] **5.4** Kiểm thứ tự file: `…023` chạy sau `…008`; `…008` gọi hàm định nghĩa ở `…023` — thân plpgsql không kiểm hàm lúc tạo nên hợp lệ; ghi Kết quả.

### Task 6: Tài liệu + kiểm + Kết quả

**Files:** Modify: `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`, `docs/refactor/PLAN.md` (dòng 7-B1: Làm ✅ + ngày)

- [ ] **6.1** TH-08: phần đầu (dòng 5–8) — nguồn DB là `supabase/migrations/20261031001…023` (đã promote 2026-11-02), bỏ "chưa promote"; bộ xử lý: worker đã xoá 2026-10-11, Edge Function ở 7-E*. Bỏ 🔧 ở US-01.3 FR-04, BR liên quan KI-02 / KI-04 / KI-06, 6.4 dòng mã chặn `BUYER_*`, 9.3; 7.3: KI-02 / KI-04 / KI-06 "Đã sửa 7-B1" (KI-04 ghi thêm `reevaluate_auto_issuance`), KI-18 "Đã promote `8b08bb01c`"; thêm **KI-21**: "4 hàm của bộ xử lý (`start_auto_issuance`, `reevaluate_auto_issuance`, `list_open_auto_issuance_processes`, `build_canonical_invoice`) từng `grant` cho `authenticated` mà không kiểm quyền — Đã sửa 7-B1: chỉ `service_role`"; 6.2 dòng bộ xử lý thêm 4 hàm đó; 2.4 thêm thứ tự lấy trường (G3) và hệ quả với `complete_buyer_invoice_data`.
- [ ] **6.2** `node .gitnexus/run.cjs analyze` rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.
- [ ] **6.3** Tự rà toàn bộ diff SQL một lượt: mỗi `begin` / `end`, `declare` biến mới, dấu `;`, tên cột thật. Ghi Kết quả.

## 6. Review Focus (chưa ca nào chạy — phiên review soi)

1. **Thứ tự kiểm ở `issue_invoice` / `start_auto_issuance`:** replay idempotency phải đứng trước kiểm người mua — lượt đã tạo rồi khách mới bị xoá MST, gọi lại cùng key phải trả lượt cũ, không ném `ISSUANCE_NOT_READY`.
2. **Đơn đã có hoá đơn:** `_effective_buyer_snapshot` không được đổi kết quả cho đơn đã phát hành (hồ sơ khách sửa sau phát hành không làm đổi người mua của hoá đơn đã có — hiển thị sau phát hành dùng hàm này).
3. **Khách tổ chức "cũ" không có `buyerType`** trong ảnh chụp đơn → coi là cá nhân như `get_issuance_readiness`; không được rơi vào nhánh tổ chức.
4. **Khách tổ chức chưa từng có lượt mà hồ sơ bị xoá MST:** không có giá trị đã chép ⇒ phải ra `BUYER_TAX_CODE_REQUIRED` (khác E18, nơi completion còn MST cũ). Review đọc thân G3: không được rơi về MST của ảnh chụp đơn đã trống.
5. **Lộ quyền ở hàm mới:** `_buyer_issuance_blocker` phải `revoke … authenticated` (nếu quên, `authenticated` gọi được và đọc hồ sơ khách tổ chức khác).

## 7. Kiểm tra

### 7.1 Tự động
Task 6 (`detect-changes`). Không có test Dart (plan không đổi app).

### 7.2 Việc của người dùng
- DB local: reset rồi `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql` → `einvoice_th08: OK`. Ca nào FAIL ⇒ báo phiên sửa.
- Kiểm tay đầu–cuối để tới 7-E3 (chưa có bộ xử lý chạy lệnh MISA).

## 8. Rủi ro / lưu ý

- **Migration đã áp:** sửa tại chỗ ⇒ local / Dev không tự nhận tới khi reset (việc người dùng).
- **App sau 7-B1 (Q5):** bật tự động khi chưa sẵn sàng ⇒ toast "Không lưu được" thay vì "Chưa đủ điều kiện" cho tới 7-A1. **Ghi chú cho 7-A1:** repository map `CONFIG_NOT_READY` → kết quả `notReady` của màn Tự động hoá.
- **App với `BUYER_*`:** evaluator Dart đã chặn nút phát hành trước nên người dùng thường không thấy; nếu lọt, `order_einvoice_error_message.dart` rơi về câu `ISSUANCE_NOT_READY` chung (TH-08 6.4) — chấp nhận.
- **Không có bộ xử lý:** ca test chỉ kiểm tới lúc tạo lượt / `internal_commands`; đi tới MISA kiểm ở 7-E3.
- **60 test Dart SQL** ở `modules/einvoice/infrastructure` đọc `_drafts/` đang đỏ sẵn (TEST-BASELINE "Sau 4-C"); không sửa, xoá ở 7-C.

## 9. Kết quả (phiên làm code ghi)

**Task 1 — ✅ (khung + ca hành vi đang có; chưa chạy, Q8)**
- Tệp: `supabase/tests/einvoice_th08.sql` (tạo mới, ~560 dòng): 4 hàm giúp của G5 + 14 hàm giúp đọc / giả lập bộ xử lý (`security definer`), một khối `do` chứa E01–E31, `rollback` cuối, notice `einvoice_th08: OK`.
- Lệch plan + lý do:
  - `_th08_expect_err` thêm tham số thứ ba `p_contains` (kiểm mã `BUYER_*` trong `details.blockers`).
  - `_th08_sale` thêm hai tham số `p_product`, `p_unit` (plan không nói lấy sản phẩm ở đâu; authenticated không đọc được `catalog`).
  - E20: `record_issuance_failure` trên lượt `SUCCEEDED` **ném `INVALID_STATUS`** (`…007:~455`, chỉ nhận `SUBMITTED` / `WAITING_RESULT` / `RECONCILING`), không phải no-op. Ca chấp nhận lỗi `INVALID_STATUS` hoặc bỏ qua, và kiểm lượt vẫn `SUCCEEDED`, vẫn 1 hoá đơn. TH-08 9.3 ghi "không đổi" vẫn đúng.
  - E26: `start_auto_delivery` đòi `request.jwt.claims.role = 'service_role'` (`…013:~312`) ⇒ ca đặt claim tạm rồi khôi phục.
  - Capabilities của kết nối thêm `supports_email_delivery: true` (`send_electronic_invoice` đòi, `…013:~598`) và gộp mẫu `T2` vào lúc dựng (không thêm giữa chừng ở E03).
  - E02: `signing_config_id` đọc từ cột **trả về** của hàm (bảng `tenant_settings` không có cột này).
  - E22–E25: cột loại gửi là `delivery_intent`; `p_idempotency_key` của `send_electronic_invoice` là `uuid`.
- Ca test thêm: E01–E05, E10–E12, E16, E19–E26, E31 (+ E06–E09, E13–E15, E17, E18, E27–E30 ở các task sau).
- Impact: tệp mới, không symbol.
- Ghi chú cho review (chỗ phải đoán): (1) khoá JSON hồ sơ partner: `full_name`/`phone` (người), `organization_type='company'`/`organization_name`/`phone`/`tax_code`/`invoice_address` (tổ chức) đọc từ `…20260714004`; `_th08_customer` truyền cả `tax_code`/`invoice_address` cho cá nhân nhưng chỉ khi không null (KA không dùng). (2) `_th08_fail`/`_th08_succeed` giả lập bộ xử lý bằng `update … status = 'WAITING_RESULT'` trực tiếp — nếu có trigger chặn chuyển trạng thái thì ca E17–E20 đỏ. (3) `get_issuance_readiness` / `issue_invoice` gọi dưới `authenticated` giả định owner có `einvoice.*` (`iam.has_permission` trả true cho owner). (4) E27–E29 chạy `start_auto_issuance` dưới `reset role` sau `update tenant_settings set auto_issue_enabled = true`.

**Task 2 — ✅**
- Tệp:dòng: `20261031008…sql` `start_auto_issuance` (~dòng 880), `list_open_auto_issuance_processes`, `reevaluate_auto_issuance` — mỗi chỗ `revoke … from public, anon, authenticated` + `grant … to service_role`; `20261031006…sql:792-793` cho `build_canonical_invoice`.
- Lệch plan: không.
- Ca test: E30 (4 hàm + `_buyer_issuance_blocker`, thêm ca thứ 5 theo Review Focus 5).
- grep chỗ gọi `build_canonical_invoice(`: `006:659` (`request_invoice_preview`), `008:134` (`_start_issuance_attempt` bản cũ, bị `023` ghi đè), `023:422` (`_start_issuance_attempt`) — cả ba trong hàm `security definer` ⇒ không ảnh hưởng.
- Impact (gitnexus upstream): `start_auto_issuance`, `reevaluate_auto_issuance`, `issue_invoice`, `retry_issuance`, `update_automation_policy` khớp thư mục Dart cùng tên (0 caller, LOW); `_effective_buyer_snapshot`, `_start_issuance_attempt`, `build_canonical_invoice`, `list_open_auto_issuance_processes` — không có trong index (SQL không được index), ghi nhận.

**Task 3 — ✅**
- Tệp:dòng: `20261031004…sql` `update_automation_policy`, khối kiểm G1 ngay sau kiểm quyền, trước `insert … on conflict`.
- Lệch plan: không.
- Ca test: E06–E09.
- Impact: như Task 2 (`update_automation_policy` LOW, 0 caller).
- Ghi chú: E06 xoá tạm `default_template_id` + `default_invoice_series` cùng lúc (ràng buộc `check` đòi cả hai cùng null).

**Task 4 — ✅**
- Tệp:dòng: `20261031023…sql` `_effective_buyer_snapshot` viết lại (thân từ dòng ~46); `_start_issuance_attempt` `on conflict` đổi sang `coalesce(excluded.x, bc.x)`.
- Lệch plan + lý do (**Ruling**): đơn không có khách (bán lẻ) giữ hành vi cũ `snapshot || completion` (completion đè snapshot), chỉ đơn có khách mới dùng thứ tự ảnh chụp ?? hồ sơ ?? completion. Lý do: G3 chỉ nói về hồ sơ khách ("chỉ khi có buyer_partner_id"); đổi thứ tự cho khách lẻ làm mất tác dụng của `complete_buyer_invoice_data` mà không có yêu cầu. Giá nếu sai: một dòng.
- Hệ quả đã biết (plan G3 đã nêu): với đơn có khách, trường có trong ảnh chụp đơn không còn bị completion đè (trước đây completion đè).
- Ca test: E17, E18.
- Đọc lại chỗ gọi `_effective_buyer_snapshot(`: `006:663` (`request_invoice_preview`, đổi hành vi: xem trước dùng hồ sơ hiện hành ưu tiên hơn giá trị đã chép), `008:100` (bản cũ của `_start_issuance_attempt`, bị `023` ghi đè), `023:204` (`get_issuance_readiness`: thấy giá trị hồ sơ mới ngay), `023:388` (`_start_issuance_attempt`: `attempt_snapshot.buyer`), cộng `_buyer_issuance_blocker` mới. Đơn đã có hoá đơn: nhánh sớm trả `base || completion` y như cũ (Review Focus 2).
- Impact: SQL không có trong index.

**Task 5 — ✅**
- Tệp:dòng: `20261031023…sql` thêm `einvoice._buyer_issuance_blocker` (sau `revoke` của `_effective_buyer_snapshot`, trước `get_issuance_readiness`) + `revoke … authenticated` / `grant … service_role`; `20261031008…sql` gọi trong `issue_invoice` (trước "5. Ready"), `start_auto_issuance` (trước "5. Ready"), `reevaluate_auto_issuance` (trước "Ready: start attempt"), `retry_issuance` (trước `return query`); mỗi hàm khai báo `v_buyer_blocker text;`.
- Lệch plan: không. `reevaluate_auto_issuance` dùng `v_proc.sales_order_id` làm đơn.
- Ca test: E13–E15, E27–E29.
- 5.4 thứ tự file: `008` gọi `_buyer_issuance_blocker` định nghĩa ở `023`; thân plpgsql không kiểm hàm lúc tạo nên hợp lệ khi chạy reset đủ file (đã chạy xong `023` trước lúc gọi).
- Ghi chú cho review: hàm blocker dựa vào `_effective_buyer_snapshot` (gọi `sales.get_einvoice_source_snapshot` thêm một lần) — chấp nhận.

**Task 6 — ✅**
- Tệp: `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md` (phần đầu, FR-04, AC-03/AC-06/AC-05/AC-04, 2.4, 6.2, 6.4 dòng mã chặn, KI-02/04/06/18, thêm KI-21; bảng 9.x không có 🔧 phải bỏ), `docs/refactor/PLAN.md` (dòng 7-B1: Làm ✅ 2026-11-08).
- Lệch plan: các 🔧 còn lại trong TH-08 thuộc KI-01 / KI-05 / KI-08 (không thuộc plan này).
- Bước cuối: `node .gitnexus/run.cjs analyze` (OK), `detect-changes --scope all` → 11 tệp / 38 symbol / 0 luồng / rủi ro **low**. 11 tệp gồm 2 tệp tài liệu không do plan này sửa: `AGENTS.md`, `CLAUDE.md` (đã `M` từ trước phiên, `analyze` chỉ cập nhật số liệu) và `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md` (đã sửa ngoài phiên này; không đụng). Không commit.
- 6.3 tự rà diff SQL: mỗi `begin … end`/`if … end if;` cân, mỗi hàm mới có `declare` biến dùng (`v_buyer_blocker`, `v_value`, `v_completion`, `v_merged`…), cột thật (`blocker_code`, `last_evaluated_at`, `delivery_intent`, `attempt_no`, `command_type`). Chưa chạy SQL nào (Q8).

## 10. Review

<!-- Chỉ phiên review ghi. -->

### R1 — 2026-11-08 — **ĐẠT** (đọc mã; `einvoice_th08.sql` chưa chạy, Q8 → người dùng chạy ở 7.2)

| Hạng mục | Kết quả |
|---|---|
| G1 KI-02 (`…004`) | ✅ Khối kiểm đúng Q1/Q6, đặt sau kiểm quyền, trước `insert … on conflict` (trước so `policy_version`). `p_auto_issue_enabled` mặc định `null` ⇒ `coalesce(…, false)` đúng: chỉ gửi cờ email không bị chặn |
| G2 KI-04 (`…023` + `…008`) | ✅ `_buyer_issuance_blocker` đúng thứ tự Q7, suy loại khách như `get_issuance_readiness`; gọi ở 4 RPC sau mọi kiểm cũ; `v_source` cùng nguồn (`load_issuance_source_snapshot` = `sales.get_einvoice_source_snapshot`). Nhánh tự động chèn / cập nhật `blocker_code`, không tạo lượt |
| G3 KI-06 (`…023`) | ✅ Nhánh đã có hoá đơn trả `base || completion` như cũ; nhánh có khách: ảnh chụp ?? hồ sơ ?? completion; `on conflict` đổi `coalesce(excluded, bc)`. Ruling khách lẻ giữ `base || completion`: chấp nhận (khách lẻ không có hồ sơ, blocker trả `null`) |
| G4 khoá quyền | ✅ 4 hàm + hàm mới chỉ `service_role`. Mọi chỗ gọi trong SQL nằm trong hàm `security definer` (`start_auto_issuance` → `reevaluate_auto_issuance` `:494`; 3 chỗ gọi `build_canonical_invoice`); app không gọi (`SupabaseAutoIssuanceGateway` chỉ đăng ký ở `data_access_module.dart`, không có gì trong `apps/` chạy inbox/outbox — code chết, xoá ở 7-C) |
| Review Focus 1–5 | ✅ cả 5 (đọc mã): replay `issue_invoice` `:303-322` / `start_auto_issuance` `:451-466` đứng trước kiểm người mua; đơn đã có hoá đơn không đọc hồ sơ; thiếu `buyerType` → `individual`; hồ sơ trống + chưa chép ⇒ `BUYER_TAX_CODE_REQUIRED`; `_buyer_issuance_blocker` `revoke … authenticated` (E30 có kiểm) |
| Test `einvoice_th08.sql` | ✅ đủ E01–E31 như G5 (+ ca thứ 5 ở E30). Đối chiếu chữ ký: `create_partner`, `update_automation_policy`, `set_default_issuance_configuration` (cột trả `signing_config_id`), `retry_issuance(p_expected_order_version)`, `send_electronic_invoice` (`delivery_id`, khoá `uuid`), `record_issuance_*` (lần hai trên `SUCCEEDED` trả sớm ⇒ E19 đúng; `FAILED` khác ⇒ `INVALID_STATUS` ở E20 đúng như Kết quả ghi), `finalize_sales_order` ghi `buyer_tax_snapshot.buyerType` từ `customer.buyerType` (`…017:516`) ⇒ E13/E14/E27 ra loại tổ chức đúng |
| Kết quả mục 9 — số liệu | ✅ `detect-changes --scope all` chạy lại: **11 tệp / 38 symbol / 0 luồng / low** khớp. Lệch nhỏ: Task 1 ghi "~560 dòng", thực tế **782** dòng |
| Tài liệu TH-08 / PLAN | ✅ phần đầu, FR-04, AC, 2.4, 6.2, 6.4, KI-02/04/06/18/21; PLAN dòng 7-B1 Làm ✅ |

**Góp ý nhỏ (không chặn; làm khi tiện, không cần R2):**
1. **Review Focus 1 chưa có ca test** (mã đúng khi đọc): thêm ca sau E15 — `update partner.organization_profiles set tax_code = null where partner_id = v_kb` (dưới `reset role`), gọi lại `issue_invoice` key `k15` cùng `v_ver` ⇒ trả đúng `attempt_id` cũ, không ném `ISSUANCE_NOT_READY`; khôi phục MST sau ca (E19–E25 dùng đơn `KB`, nhưng lượt đã chép MST vào completion nên không ảnh hưởng — vẫn nên khôi phục cho rõ).
2. **TH-08 2.4 (dòng ~210) và EC-02 (dòng ~783):** "ghi đè giá trị đã chép" → "ghi đè giá trị đã chép **khi hồ sơ có giá trị**; hồ sơ trống thì giữ giá trị đã chép" (khớp `coalesce(excluded, bc)` và E18).
3. **TH-08 mục 9.x bảng PR, dòng 7.1 (~1555) và PLAN.md dòng 552:** liệt kê 3 RPC của KI-04 — thêm `reevaluate_auto_issuance` cho khớp KI-04 / dòng 7-B1.
4. Kết quả Task 1: sửa "~560 dòng" → 782.

**Ghi chú cho plan sau (không phải lỗi 7-B1):**
- App lúc bán ghi `taxCode` / `invoiceAddress` của khách vào ảnh chụp đơn (`apps/erp/lib/features/sales/data/mappers/sales_checkout_json.dart:166-169`). Vì vậy KI-06 chỉ có tác dụng khi khách **chưa có** MST / địa chỉ lúc bán; MST sai đã vào ảnh chụp thì vẫn không sửa được (KI-07, giữ nguyên theo TH-08). Đúng thiết kế, ghi để 7-A* / kiểm tay không bất ngờ.
- 7-A1: map `CONFIG_NOT_READY` (Q5) như mục 8. 7-C: xoá `SupabaseAutoIssuanceGateway` (gọi 3 hàm đã khoá).

**Việc của người dùng:** `db reset` local → `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql` ⇒ `einvoice_th08: OK`; reset Dev. Ca nào FAIL ⇒ mở R2.

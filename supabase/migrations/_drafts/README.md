# Schema SQL drafts (agents & slices)

Thư mục này chứa **SQL thiết kế tạm** — **không** được Supabase CLI apply khi `supabase db reset` / `migration up`.

## Function / view / trigger / policy đã adopt

Object **stateless đã có** trong `schema.lock.yaml` (hoặc module greenfield như partner) **không** viết lại bằng draft patch copy body. Sửa file nguồn dưới:

- `modules/<m>/infrastructure/supabase/sql/{functions,views,triggers,policies}/`
- `supabase/sql/<schema>/...` (schema shared)

DDL table / backfill / đổi cột vẫn draft ở đây (`<intent>.pre.sql` / `<intent>.post.sql` khi dùng `migrate:generate`). Chi tiết: [14-declarative-sql-objects.md](../../../docs/architecture/14-declarative-sql-objects.md).

## Khi nào dùng

- Agent hoặc slice BE cần ghi RPC, view, RLS, index mới
- Chưa có người maintain chốt timestamp migration cho môi trường shared

## Đặt tên file

### Draft đang active (bắt buộc có số thứ tự)

Mọi file SQL còn nằm trong `_drafts/` phải có prefix `NNN_` theo **thứ tự thời gian viết** (git first-add / authoring order), rồi mới đến tên mô tả:

```
NNN_<scope>_<short_description>.sql
```

**TH-05 Sales clean bootstrap (active authority, 2026-08-14):**

Manual prerequisite: the user removes the existing `sales` schema.
`005` refuses to run while `sales` exists, installs platform messaging, and creates all Sales DDL.
`006`–`015` contain helpers/RPCs only.

| Band | Files | Role |
|------|-------|------|
| `001`–`004` | IAM / Catalog / Pricing Group A | Cross-module owners — **không** xoá khi dọn Sales |
| `005` | `005_sales_rebuild_schema.sql` | Sales DDL clean bootstrap (sole table/column owner) |
| `006` | `006_sales_shared_rpc_helpers.sql` | Shared Sales RPC helpers |
| `007`–`015` | draft → integration RPCs | Single-owner public Sales RPCs (no DDL) |

Ví dụ:

- `007_sales_draft_rpcs.sql`
- `008_sales_checkout_rpcs.sql`
- …
- `015_sales_integration_rpcs.sql`

Sau full reset được user phê duyệt, toàn bộ active draft sequence đã được re-baseline thành `001`–`015`. Từ baseline này, số mới = max hiện có + 1 và **không** tái dùng số đã promote/xóa. Generation Sales Group B–I cũ và intermediate `600_draft`/`601`–`604` đã được gỡ khỏi thư mục này.

**Intent đã consume:** `016_sales_remove_unused_policy_tables.sql` đã được apply
thủ công trên test DB và re-baseline vào các migration timestamp `20260827*`,
`20260830*` cùng owner `20260904001`. Draft đã xoá; verification:
`docs/operations/sales-remove-unused-policy-tables-verification.md`.

`017_sales_patch_payment_summary_original_order.sql` đã được consume trong working tree.
Thay đổi cancellation optional reason đã sửa trực tiếp trong các migration gốc
`20260830005`, `20260830011`, `20260904001` theo yêu cầu maintainer.
Draft `018` đã gỡ; không giữ migration mới cho intent này. Số kế tiếp: `019`.

**Sales outbox (đã promote):** `20260904001_sales_normalize_outbox_and_commands.sql` — outbox chỉ chứa lifecycle facts. Handoff Model B (`integration_commands` + `*_impact_requests`) đã được gỡ, sẽ dựng lại cùng module Inventory/Receivable/e-Invoice.

### Draft patch cohesive (US/FR lớn, nhiều phần cùng intent)

```
NNN_<scope>_patch_<intent>_<part>.sql
```

Ví dụ (sku/barcode — phase 2 pilot, đã promote):

- `001_catalog_patch_sku_barcode_schema.sql`
- `002_catalog_patch_sku_barcode_rpcs.sql`

**Không** dùng prefix `YYYYMMDDxxx_` — format đó chỉ dành cho migration chính thức ở thư mục cha `supabase/migrations/`.

## Header bắt buộc (patch / surgical)

```sql
-- Title: catalog patch inline sku/barcode normalization
-- Kind: patch
-- Intent: catalog_sku_barcode_inline_normalize
-- Context: TH-02 / ...
-- Touches: _normalize_product_sku, create_product, search_products
-- Safety: idempotent ; medium
-- Depends on: 20260710001_catalog_product_reference_id
```

| Kind | Khi dùng | Giới hạn gợi ý |
|------|----------|----------------|
| `patch` | US/FR đổi hành vi + DDL liên quan | ≤8 `create or replace function`, cùng `-- Intent:` |
| `surgical` | Hotfix 1–3 RPC / cột | ≤3 functions |

**Quy tắc vàng:** patch **không** `create or replace` RPC không nằm trong `-- Touches:`; **không** copy body RPC từ migration cũ “cho đồng bộ”.

## Nội dung

- Copy header từ [../README.md](../README.md) (Title, Kind, Intent, Touches, Context, Safety, Depends on)
- Viết SQL idempotent như migration thật (RLS, grants, `security definer`, …)
- Ghi rõ RPC/view map với harness `07-api-contracts.md` nếu có

## Promote thành migration chính thức

Chỉ **maintainer hoặc khi user yêu cầu rõ**:

1. Chọn migration id **duy nhất**: `supabase migration list --local`
2. Promote:
   - 1 draft → 1 file: `melos run migrate:promote-drafts -- --write`
   - Nhiều draft cùng intent: `melos run migrate:promote-drafts -- --write --bundle-intent`
3. Cập nhật `supabase/migrations/REGISTRY.yaml` (owners trong `-- Touches:`)
4. Chạy `melos run migrate:verify-policy -- --strict`
5. `supabase db reset` local để verify sequence (khi có DB)
6. Xóa hoặc archive draft tương ứng

Agent **không** tự promote trừ khi user yêu cầu.

## Active sequence và archive

Chỉ các file `.sql` nằm trực tiếp trong `_drafts/` thuộc chuỗi active và được
đọc theo numeric prefix. Thư mục `_archive/` giữ các thiết kế đã bị supersede;
không apply, bundle hoặc promote các file trong đó.

Chuỗi IAM active hiện tại:

```text
002_iam_fix_utc_now_offset.sql
004_iam_tenant_audit_history_v2_payloads.sql
006_iam_audit_owner_activation_cleanup.sql
007_iam_audit_logs_v2_rebuild.sql
```

Các khoảng số là có chủ ý vì `001`, `003`, `005` đã được archive. Khi nhiều
draft định nghĩa cùng một RPC, implementation ở file có số lớn hơn là trạng
thái cuối cùng.

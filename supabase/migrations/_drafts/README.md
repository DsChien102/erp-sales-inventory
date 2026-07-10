# Schema SQL drafts (agents & slices)

Thư mục này chứa **SQL thiết kế tạm** — **không** được Supabase CLI apply khi `supabase db reset` / `migration up`.

## Khi nào dùng

- Agent hoặc slice BE cần ghi RPC, view, RLS, index mới
- Chưa có người maintain chốt timestamp migration cho môi trường shared

## Đặt tên file

### Draft thường (1 file = 1 concern khi authoring)

```
<scope>_<short_description>.sql
```

Ví dụ: `partner_transaction_history_read.sql`, `iam_tenant_membership_ops.sql`

### Draft patch cohesive (khuyến nghị cho US/FR lớn)

Tách **atomic khi viết**, gom **1 intent khi promote**:

```
NNN_<scope>_patch_<intent>_<part>.sql
```

Ví dụ (sku/barcode — phase 2 pilot):

- `001_catalog_patch_sku_barcode_schema.sql` — helpers, trigger, indexes, drop columns
- `002_catalog_patch_sku_barcode_rpcs.sql` — chỉ RPC trong `-- Touches:`

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

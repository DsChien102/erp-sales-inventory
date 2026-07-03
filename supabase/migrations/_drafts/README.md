# Schema SQL drafts (agents & slices)

Thư mục này chứa **SQL thiết kế tạm** — **không** được Supabase CLI apply khi `supabase db reset` / `migration up`.

## Khi nào dùng

- Agent hoặc slice BE cần ghi RPC, view, RLS, index mới
- Chưa có người maintain chốt timestamp migration cho môi trường shared

## Đặt tên file

```
<scope>_<short_description>.sql
```

Ví dụ: `partner_transaction_history_read.sql`, `iam_tenant_membership_ops.sql`

**Không** dùng prefix `YYYYMMDDHHMMSS_` — format đó chỉ dành cho migration chính thức ở thư mục cha `supabase/migrations/`.

## Nội dung

- Copy header từ [../README.md](../README.md) (Title, Context, Safety)
- Viết SQL idempotent như migration thật (RLS, grants, `security definer`, …)
- Ghi rõ RPC/view map với harness `07-api-contracts.md` nếu có

## Promote thành migration chính thức

Chỉ **maintainer hoặc khi user yêu cầu rõ**:

1. Chọn timestamp **duy nhất** (không trùng file hiện có): `supabase migration list --local`
2. Tạo `../YYYYMMDDHHMMSS_<scope>_<short_description>.sql` từ nội dung draft
3. Chạy `supabase db reset` local để verify sequence
4. Xóa hoặc archive draft tương ứng

Agent **không** tự promote trừ khi user yêu cầu.

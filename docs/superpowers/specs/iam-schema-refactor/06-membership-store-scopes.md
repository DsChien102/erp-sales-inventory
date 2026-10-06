# Bảng 6 — `iam.membership_store_scopes`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **xoá bảng**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-17-iam-refactor-06-membership-store-scopes](../../plans/2026-09-17-iam-refactor-06-membership-store-scopes.md)

## 1. Bối cảnh

Bảng gán thành viên ↔ cửa hàng (`tenant_id, user_id, store_id, is_default`). Hiện mỗi tổ chức có đúng 1 cửa hàng `default` và mọi member đang hoạt động có đúng 1 scope trỏ vào nó → **toàn bộ dữ liệu suy ra được** từ `memberships` + `stores`. Tài liệu nghiệp vụ chưa định nghĩa rõ phân quyền theo cửa hàng.

Bảng có 2 lỗi FK tiềm ẩn với placeholder hybrid: FK `user_id → auth.users` (chặn tạo scope cho người chưa có tài khoản) và FK `(tenant_id, user_id) → memberships` không `on update cascade` (chặn rebind id tạm khi đăng ký).

## 2. Quyết định (B)

**Xoá bảng.** Thay mọi kiểm tra scope bằng helper:

```sql
iam.can_access_store(p_tenant_id uuid, p_store_id uuid, p_user_id uuid) returns boolean
-- true khi: store thuộc tenant, store.status = 'active', và p_user_id là member is_active của tenant
```

- Helper `stable security definer`; không grant cho `anon`/`authenticated` (chỉ gọi từ hàm security definer).
- `get_session_context`: `active_store_id` = cửa hàng active của tenant (ưu tiên `code = 'default'`), yêu cầu `can_access_store`; owner chưa có cửa hàng thì `bootstrap_owner` tạo như cũ. Output không đổi.
- `bootstrap_owner`: bỏ phần insert scope; phần tạo cửa hàng giữ nguyên (bảng `stores` giữ nguyên theo quyết định bảng 5).
- Xoá `iam._ensure_membership_default_store_scope` và mọi lời gọi (onboarding, tạo lời mời, accept ×2, activate tenant).
- Sales/Catalog/Pricing: mọi `exists (select 1 from iam.membership_store_scopes scope … )` → `iam.can_access_store(<tenant>, <store>, <actor>)`.

### Thay đổi hành vi chấp nhận
- Member đã gỡ / tạm ngưng bị chặn ngay ở bước kiểm tra cửa hàng (trước đây scope cũ vẫn còn nên lọt qua bước này, bị chặn ở bước khác).
- RPC tra cứu đơn Sales nay yêu cầu cửa hàng `active` (trước không). Không ảnh hưởng hiện tại — cửa hàng `default` luôn active.

## 3. Phạm vi (33 hàm)

| Module | Hàm |
|---|---|
| IAM (7) | `get_session_context`, `bootstrap_owner`, `create_tenant_onboarding`, `create_tenant_invitation`, `accept_invitation`, `activate_tenant`; drop `_ensure_membership_default_store_scope`; mới `can_access_store` |
| Sales (20) | `_assert_sales_actor`, `get_sales_order`, `get_sales_order_payment_summary`, `get_order_integration_status`, `list_sales_orders`, `search_sales_orders`, `get_sales_order_detail`, `get_sales_order_settlement`, `get_sales_order_payment_transactions`, `get_sales_order_timeline`, `get_sales_order_return_summary`, `get_sales_receipt`, `record_sales_receipt_activity`, `get_available_post_sale_actions`, `precheck_sales_order_cancellation`, `get_sales_order_cancellation`, `precheck_return_exchange`, `get_returnable_order_lines`, `_get_return_exchange_context`, `get_return_exchange_detail` |
| Catalog (4) | `search_sellable_products`, `resolve_sellable_barcode`, `list_sellable_product_units`, `resolve_sellable_products` |
| Pricing (2) | `preview_sales_working_state_pricing`, `evaluate_sales_manual_price` |

Dart không đổi.

## 4. Khi mở rộng nhiều cửa hàng

1. Tạo lại bảng scope (nên theo `membership_id`, không FK `auth.users`).
2. Backfill: mỗi member `is_active` → 1 scope vào cửa hàng `default`.
3. Sửa thân `iam.can_access_store` + phần chọn cửa hàng trong `get_session_context`. Sales/Catalog/Pricing không phải sửa.

## 5. Phụ thuộc

Sau plan bảng 3 (`is_active`) và bảng 4 (`create_tenant_invitation` đã sửa trong file owner).

## 6. Test cần cập nhật (trong plan)

SQL contract test của Sales / Catalog / Pricing đang assert `membership_store_scopes` → đổi sang `iam.can_access_store(`; xoá test `iam_membership_store_scope_lifecycle_sql_contract_test.dart` (hàm bị xoá). Chi tiết ở plan Task 5.

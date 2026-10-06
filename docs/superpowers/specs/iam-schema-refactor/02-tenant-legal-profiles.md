# Bảng 2 — `iam.tenant_legal_profiles`

> Trạng thái: ✅ Đã chốt (2026-09-17)
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-17-iam-refactor-02-tenant-legal-profiles](../../plans/2026-09-17-iam-refactor-02-tenant-legal-profiles.md)

## 1. Bảng có cần giữ không

**Giữ bảng riêng** (quyết định ①). Quan hệ 1 tenant ↔ 0..1 hồ sơ pháp lý; chỉ IAM dùng (các `tax_code` ở Sales/Partner là MST khách hàng, không liên quan).

## 2. Cột → quyết định

| Cột | Ai ghi | Ai đọc | Quyết định |
|---|---|---|---|
| `tenant_id` PK/FK | onboarding, `upsert_legal_profile` | mọi nơi | Giữ |
| `legal_entity_type` | onboarding (**đang tự đoán** theo độ dài MST), upsert (từ form) | `_tenant_json`, Dart enum | Giữ; onboarding **lấy từ dropdown** (⑤) |
| `legal_name` | onboarding, upsert | JSON, audit | Giữ |
| `tax_code` | onboarding (trim), upsert (không chuẩn hoá) | JSON, readiness, kiểm tra trùng | Giữ; **chỉ chữ số, 10–13 số**, chuẩn hoá ở RPC (④) |
| `registered_address_text` | onboarding, upsert | JSON, audit | Giữ |
| `province_code`, `commune_code` | upsert; onboarding **copy nhầm từ địa chỉ liên hệ** | JSON, Dart | Giữ; onboarding ghi **`null`** (③) |
| `version` | upsert `+1` | JSON, Dart DTO (hiển thị) | **Giữ nguyên** (②) — khoá lạc quan vẫn là `tenants.version` |
| `created_at`, `updated_at` | | | Giữ |

Không đổi cấu trúc cột. Thêm 1 CHECK constraint.

## 3. Quy tắc đã chốt

### ③ Tỉnh/xã pháp lý lúc onboarding
Form onboarding chỉ có 1 cặp tỉnh/xã nằm trong phần **địa chỉ liên hệ**. RPC onboarding **không** ghi cặp này vào `tenant_legal_profiles` nữa → `province_code = null`, `commune_code = null`. Tenant tự bổ sung ở màn hồ sơ pháp lý. Dữ liệu dev cũ không backfill.

### ④ Mã số thuế
- **Định dạng lưu:** chỉ chữ số, **10 đến 13 ký tự**, áp dụng chung mọi loại chủ thể (không ràng buộc theo loại).
- **DB:** `constraint tenant_legal_profiles_tax_code_format_chk check (tax_code ~ '^[0-9]{10,13}$')`.
- **Chuẩn hoá:** người dùng nhập có dấu `-` / khoảng trắng → **tự bỏ ký tự không phải số rồi lưu** (vd `0101234567-001` → `0101234567001`). Làm ở cả RPC (`regexp_replace(x, '\D', '', 'g')`) lẫn cubit Dart.
- **Kiểm tra trùng MST** (upsert, readiness) so trên giá trị đã chuẩn hoá.
- **Validator Dart** (form + cubit hồ sơ pháp lý admin/ERP, `TaxCodeFormatRule`): bỏ ký tự không phải số → yêu cầu 10–13 chữ số. Thông báo: `Mã số thuế phải gồm 10–13 chữ số.`

### ⑤ Loại chủ thể lúc onboarding
- Dropdown onboarding **bỏ** lựa chọn `VETERINARY_CLINIC` (Phòng khám thú y) — chỉ còn `HOUSEHOLD_BUSINESS`, `ENTERPRISE`.
- Giá trị dropdown được truyền xuống: page → cubit → `CreateTenantOnboardingCommand.legalEntityType` → gateway → RPC tham số mới `p_org_legal_entity_type text default null`.
- RPC **bỏ** đoạn tự đoán theo độ dài MST.
- Có tên pháp lý + MST mà **không chọn loại** (hoặc loại không hợp lệ) → **báo lỗi**: command validator ném `ValidationException`, RPC `raise exception 'VALIDATION_ERROR'`.
- Thêm tham số làm **đổi chữ ký** `create_tenant_onboarding` (18 → 19 tham số) → file owner `20260916004` phải `drop function` chữ ký cũ trước khi tạo và cập nhật grants.

## 4. Phụ thuộc

Plan bảng 2 chạy **sau** plan bảng 1: `create_tenant_onboarding` trong file owner đã được plan 1 sửa (bỏ `name`, ghi `status_changed_*`).

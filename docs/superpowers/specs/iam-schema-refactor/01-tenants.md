# Bảng 1 — `iam.tenants`

> Trạng thái: ✅ Đã chốt (2026-09-17)
> Nguyên tắc chung: [README.md](README.md)

## 1. Bảng có cần giữ không

**Giữ.** Aggregate root của IAM; mọi module (Sales, Catalog, Pricing, Partner) FK/lọc theo `tenant_id`.

## 2. Hiện trạng (24 cột) → quyết định

| Cột | Ai ghi (hiện tại) | Ai đọc (hiện tại) | Quyết định |
|---|---|---|---|
| `id` | default | mọi nơi | Giữ |
| `name` | onboarding; `update_tenant_profile` ghi `name = p_display_name`; `bootstrap_owner` | audit search, `get_platform_tenant`, `list_accessible_tenants` | **Gộp → `display_name`** |
| `display_name` | onboarding, `update_tenant_profile` | `_tenant_json`, UI | Giữ, **`not null`** |
| `code` | Không ai ghi (luôn null) | audit, `get_platform_tenant`, `accept_invitation` (fallback `left(id,8)`) | **Bỏ** |
| `status` | onboarding / activate / suspend / restore | IAM + module khác | Giữ |
| `status_changed_at` | chỉ activate ghi | JSON | Giữ, **ghi ở mọi lần đổi status** |
| `activated_at` | activate | platform JSON, Dart | Giữ (mốc kích hoạt lần đầu) |
| `suspended_at` | suspend (restore → null) | JSON, Dart | **Gộp → `status_changed_at`** |
| `suspend_reason` | suspend | JSON, Dart | **Gộp → `status_reason`** (cột mới) |
| `suspended_by` | suspend | JSON | **Gộp → `status_changed_by`** (cột mới) |
| `closed_at` | Không ai ghi | JSON, Dart, UI admin | **Gộp → `status_changed_at`** (cách B) |
| `close_reason` | Không ai ghi | JSON, Dart, UI admin | **Gộp → `status_reason`** (cách B) |
| `closed_by` | Không ai ghi | JSON, UI admin | **Gộp → `status_changed_by`** (cách B) |
| `contact_email`, `contact_phone`, `contact_address_text` | onboarding, update profile | JSON | Giữ |
| `province_code`, `commune_code` | onboarding, update profile | JSON | Giữ, **giữ nguyên tên** |
| `business_timezone`, `base_currency_code` | default, không ai cập nhật | `get_tenant`, Dart | Giữ |
| `created_by_user_id` | Không ai ghi | Không ai đọc | **Bỏ** |
| `version`, `created_at`, `updated_at` | | | Giữ |

## 3. Schema đích (17 cột)

```sql
create table iam.tenants (
  id                    uuid primary key default gen_random_uuid(),
  display_name          text not null,
  status                text not null default 'provisioning'
    check (status in ('provisioning', 'active', 'suspended', 'closed')),
  status_changed_at     timestamptz,
  status_changed_by     uuid,
  status_reason         text,
  activated_at          timestamptz,
  contact_email         text,
  contact_phone         text,
  contact_address_text  text,
  province_code         text,
  commune_code          text,
  business_timezone     text not null default 'Asia/Ho_Chi_Minh',
  base_currency_code    text not null default 'VND',
  version               int  not null default 1,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
```

## 4. Quy tắc nghiệp vụ đã chốt

### 4.1 Bộ cột trạng thái chung
`status_changed_at / status_changed_by / status_reason` luôn mô tả **lần đổi status gần nhất**. Mọi lệnh đổi status phải ghi đủ cả 3 cột (cùng `version + 1`, `updated_at = now()`).

| Lệnh | `status` | `status_changed_at` | `status_changed_by` | `status_reason` | Khác |
|---|---|---|---|---|---|
| Onboarding | `provisioning` | `now()` | admin tạo | `null` | |
| Activate | `active` | `now()` | người kích hoạt | `null` | `activated_at = now()` (giữ như hiện tại; khi implement xác nhận activate chỉ chạy từ `provisioning` để `activated_at` là mốc lần đầu) |
| Suspend | `suspended` | `now()` | admin | `trim(p_reason)` (bắt buộc) | |
| Restore | `active` | `now()` | admin | **`null`** (quyết định ① = a) | Không đổi chữ ký RPC; lý do suspend cũ còn trong `audit_logs` |
| Close (mới) | `closed` | `now()` | admin | lý do đóng | Terminal → 3 cột không bao giờ bị ghi đè |

### 4.2 Contract JSON giữ nguyên (key cũ tính từ cột mới)

| Key JSON / field Dart | Công thức |
|---|---|
| `name` | `display_name` |
| `code` | `left(id::text, 8)` |
| `suspended_at` | `case when status = 'suspended' then status_changed_at end` |
| `suspend_reason` | `case when status = 'suspended' then status_reason end` |
| `suspended_by` | `case when status = 'suspended' then status_changed_by end` |
| `closed_at` | `case when status = 'closed' then status_changed_at end` |
| `close_reason` | `case when status = 'closed' then status_reason end` |
| `closed_by` | `case when status = 'closed' then status_changed_by end` |

→ `PlatformTenantDetailDto`, mapper và UI admin **không phải sửa**.

## 5. Tính năng đóng tenant (làm trong đợt này)

Hiện trạng: UI admin đã hiển thị trạng thái đã đóng (`organization_detail_platform_info_card.dart`, dữ liệu fake), application chỉ có DTO đọc, **không có command/RPC đóng**. Spec TH-01 xếp close Tenant là Post-MVP — đã chốt **làm luôn**.

Phạm vi: RPC `iam.close_platform_tenant`, command Dart + handler + validator + gateway, nút đóng trên app admin. Ghi theo §4.1.

**Đã chốt (theo TH-01):** đóng = kết thúc lifecycle Tenant. `closed` là trạng thái **terminal / read-only**: không restore, không quay lại `active`, không có RPC mở lại. Khác `suspended` (restore được). Mọi RPC ghi phải từ chối tenant `closed` (các guard hiện có giữ nguyên).

**Quyết định nghiệp vụ (chốt 2026-09-17):**

| # | Điểm | Quyết định |
|---|---|---|
| 1 | Đóng từ status nào | Chỉ `active` và `suspended`. `provisioning` / `closed` → từ chối |
| 2 | Membership | **Giữ nguyên** (tenant closed đã chặn truy cập) |
| 3 | Lời mời pending | **Để nguyên** (accept bị chặn vì tenant closed) |
| 4 | Lý do | **Bắt buộc** — ghi `status_reason` |
| 5 | Xác nhận | Sheet xác nhận; **phải nhập lý do** mới bật nút Đóng (không bắt gõ tên tổ chức) |
| 6 | Mở lại | Không (terminal) |
| 7 | Idempotency | `idempotency_key` + `expected_version` (spec §403) |

## 6. Việc cần làm khi implement

### 6.1 Implement

Chi tiết từng bước: [plan 2026-09-17-iam-refactor-01-tenants](../../plans/2026-09-17-iam-refactor-01-tenants.md).

Khảo sát 21 RPC (định nghĩa mới nhất theo `REGISTRY.yaml`) đang đọc/ghi cột cũ — danh sách đầy đủ trong plan. `bootstrap_owner(uuid, text)` hiện hành **không** insert `iam.tenants` (bản cũ `bootstrap_owner(text)` insert thiếu `display_name` đã bị drop ở `20260914001`) → không phải sửa.

GitNexus không index hàm SQL (impact resolve sang folder Dart, trả 0) → bằng chứng blast radius là quét text toàn bộ migration + `supabase db reset` chạy hết chuỗi (plan Task 5).

Sửa trực tiếp migration gốc (xem README §Quy ước implement): bỏ cột tại câu tạo cột (`20260630000001`, `20260811010`, `20260811015`), sửa định nghĩa cuối của hàm tại file owner; SQL contract test cũ assert nội dung đã đổi được cập nhật trong plan.

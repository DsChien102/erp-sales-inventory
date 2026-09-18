# Việc phát sinh — Chặn tổ chức tạm ngừng / đã đóng

> Trạng thái: ✅ Đã chốt (2026-09-18) · Plan: [2026-09-18-iam-tenant-status-access](../../plans/2026-09-18-iam-tenant-status-access.md)
> Nguồn: smoke test TC-08 sau refactor. Lỗi có **từ trước** refactor.

## 1. Vấn đề

| # | Hiện tượng | Nguyên nhân |
|---|---|---|
| A | Admin tạm ngừng tổ chức khi người dùng **đang ở trong app** → vẫn dùng đủ chức năng | Server không kiểm tra `tenants.status` trong `iam.has_permission`, `iam.can_access_store`, `iam.get_session_context`. Chỉ `get_tenant_context` / `switch_tenant_context` chặn — ERP chỉ gọi lúc mở app / đổi tổ chức |
| B | Mở lại app → bị chặn nhưng hiện "Chưa có tổ chức được cấp quyền… kiểm tra lời mời" | `GetTenantContextQueryHandler` (bootstrap) đổi mọi kết quả không `valid` thành `none`; ERP không vào nhánh `inaccessible` đã có sẵn |
| C | (phát hiện khi rà soát) `catalog.adjust_basic_stock`, `catalog.set_basic_stock_quantity_base` cấp `authenticated` nhưng **không kiểm tra quyền** | Thiếu `_assert_product_permission` |

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| D1 | Tổ chức `suspended` | Chặn **toàn bộ** thao tác nghiệp vụ, kể cả xem |
| D2 | Tổ chức `closed` | Chặn toàn bộ như `suspended` (chưa làm chỉ đọc) |
| D3 | Người đang ở trong app | Lần gọi server tiếp theo bị từ chối → app **tự đưa về màn chặn** |
| D4 | Thông báo | Tạm ngừng: *"{tên} đang tạm ngừng. Bạn không thể truy cập dữ liệu của tổ chức này."* (đã có) · Đã đóng: *"{tên} đã đóng. Bạn không thể truy cập dữ liệu của tổ chức này."* |
| D5 | Đăng nhập | Vẫn cho đăng nhập (user có thể thuộc tổ chức khác) |

## 3. Quyết định kỹ thuật

| # | Điểm | Chốt | Lý do |
|---|---|---|---|
| T1 | `has_permission` khi tổ chức `suspended`/`closed` | **Ném** `TENANT_SUSPENDED` / `TENANT_CLOSED` (không trả `false`) | Mọi RPC Sales/Catalog/Pricing gọi `has_permission` **trước** `can_access_store` → mã lỗi thống nhất, ERP nhận diện được để đá ra. Trả `false` sẽ thành `PERMISSION_DENIED`/`DATA_SCOPE_DENIED` khác nhau theo module |
| T2 | Tổ chức `provisioning` | **Không chặn** | Owner cần sửa hồ sơ trước khi kích hoạt |
| T3 | Tín hiệu phía client | `TenantAccessRevokedSignal` (stream tĩnh, `vet45_shared_application`); `SupabaseSchemaRpcClient` phát khi lỗi chứa 2 mã trên | Mọi module dùng chung client → 1 điểm bắt |
| T4 | OQ-07 | Giữ "không auto-select"; bootstrap trả `invalidated` **chỉ** cho `tenantSuspended`/`tenantClosed`, lý do khác vẫn `none` | ERP nhánh `invalidated` vẫn mở selector, không tự chọn tổ chức khác |

## 4. Ngoài phạm vi (để sau)

- **Thu hồi phiên Supabase Auth** khi tạm ngừng người dùng (ban user + xoá `auth.sessions` qua worker/edge function service role). Server đã chặn từ plan 8; chỉ là lớp bảo vệ thêm. Không áp dụng cho tạm ngừng tổ chức.
- Chế độ chỉ đọc cho tổ chức đã đóng.
- Đẩy realtime khi admin tạm ngừng.

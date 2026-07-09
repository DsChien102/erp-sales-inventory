# TH-03 — Business scope (tóm tắt)

Canonical spec: [Theme-3-partner.md](Theme-3-partner.md).

## Trong phạm vi

| Nhóm | Nội dung |
| ---- | -------- |
| Danh sách | Tìm kiếm, lọc Cá nhân/Tổ chức theo vai trò và trạng thái |
| Tạo mới | Tạo Partner type Person hoặc Organization + gán role Customer/Supplier |
| Hồ sơ | Xem, bổ sung, chỉnh sửa thông tin hiện tại |
| Người liên hệ | Quản lý OrganizationContact (Organization ↔ Person) |
| Transform | Chuyển Person thành Organization (giữ `partner_id`) |
| Trạng thái | Ngừng hoạt động, kích hoạt lại, xóa mềm (`deleted`) |
| Lịch sử | Xem lịch sử làm việc read-only (projection) |

## Ngoài phạm vi (Phase 1)

| Nhóm | Lý do |
| ---- | ----- |
| Merge hồ sơ trùng | Chỉ cảnh báo, chưa hợp nhất |
| Organization → Person | Không hỗ trợ |
| CRM nâng cao | Lead, pipeline, chăm sóc KH |
| Export lịch sử | Phase sau |
| Xóa cứng / khôi phục deleted | Phase sau |

## Khái niệm chính

| Khái niệm | Định nghĩa |
| --------- | ---------- |
| Partner | Root entity — mọi giao dịch reference `partner_id` |
| Person / Organization | Loại hồ sơ CRM (không phải nhãn hiển thị) |
| Customer / Supplier | Vai trò giao dịch — độc lập với loại hồ sơ |
| OrganizationContact | Liên kết Organization với Person làm người liên hệ |
| Soft delete | `status = deleted` — không xóa cứng |

## Epics

| Epic | Mục tiêu |
| ---- | -------- |
| EP-01 | Danh sách, hồ sơ, contact, transform, lịch sử |
| EP-02 | Trạng thái: inactive, reactivate, soft delete |

Harness: [harness/01-domain-model.md](harness/01-domain-model.md) · Slice: [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md)

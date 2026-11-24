---
id: BC-COMMON-EXTENSIONS
type: behavioral-contract
theme: theme-07
title: "Shared behavioral contract extensions"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# BC-COMMON-EXTENSIONS — Shared behavioral contract extensions

## 1. 8. Structured capability rejection

| Capability | Error code | Mutation allowed |
|---|---|---:|
| Internal transfer | `CAPABILITY_NOT_AVAILABLE_INTERNAL_TRANSFER` | No |
| Warehouse close/switch | `CAPABILITY_NOT_AVAILABLE_WAREHOUSE_LIFECYCLE` | No |
| Offline sale/sync | `CAPABILITY_NOT_AVAILABLE_OFFLINE_SALE` | No |
| Serial tracking | `CAPABILITY_NOT_AVAILABLE_SERIAL_TRACKING` | No |
| Custody/consignment | `CAPABILITY_NOT_AVAILABLE_CUSTODY` | No |
| SKU conversion/repack | `CAPABILITY_NOT_AVAILABLE_SKU_TRANSFORMATION` | No |
| Tracking conversion with stock | `TRACKING_CHANGE_REQUIRES_ZERO_STOCK` | No |
| Replenishment proposal/auto PO | `CAPABILITY_NOT_AVAILABLE_REPLENISHMENT_WORKFLOW` | No |

Rejection xảy ra trước khi tạo operation hoặc entity tương lai; có correlation/audit security log nhưng không có business outbox event.

## 2. 9. Contract quality gates

1. 34/34 BC ID duy nhất và có owner.
2. Mỗi mutating screen action có đúng một primary BC.
3. Mỗi BC mutation có input identity, permission/scope, guard, atomic effect, result, error và entity mapping.
4. Mỗi BC có đúng một authoritative handler trong Part 07.
5. Query không được dùng projection trễ cho commit decision.
6. Không BC nào tạo Serial, Offline, Transfer, Custody, Alert hoặc ReplenishmentProposal entity.
7. Pricing BC không ghi inventory/value ledger; inventory BC không công bố selling price.
8. Mọi result/error có `effect_status`, thông điệp người dùng và bước tiếp theo hợp lệ; không action nào trong guidance vượt permission, state guard hoặc capability boundary.


<a id="finality-contract-v410"></a>

## 3. 15. Finality contract cho BJ v4.1.0

- `COMPLETED` chỉ khi owner effect đã commit và có bằng chứng authoritative.
- `REJECTED/CANCELLED` có owner effect bằng 0.
- `SUSPENDED/BLOCKED` giữ work identity và điều kiện tiếp tục.
- `UNKNOWN/ESCALATED` không được đổi thành thất bại; mọi query/resume dùng cùng operation identity.


<a id="shared-attachment-evidence-contract-v392"></a>

## 4. Shared Attachment Evidence Contract v3.9.2

- Business contract phải định nghĩa **evidence type/purpose**; UI không tự tạo danh sách file extension/size/count.
- Technical `mime_types`, `max_file_size`, `max_file_count`, malware scan và retention được resolve từ platform Shared Attachment Policy tại runtime/config; BJ chỉ reference policy version.
- Evidence refs lưu `evidence_id`, business type, file metadata, uploader/created_at và immutable content hash/version sau submit nếu evidence tham gia decision.
- Approver/actor ra quyết định phải có quyền preview evidence cần thiết; permission có thể chặn download nhưng không được buộc decision trong tình trạng không xem được evidence mà policy yêu cầu.

<a id="ownership-metadata-contract-v410"></a>

## 5. 16. Ownership metadata contract cho BJ v4.1.0

Mỗi BJ/CAP/PROC/XREF khai báo owner, provider, finality và đường bàn giao. XREF-02 thuộc Theme 10 — Mua hàng; XREF-03/04 thuộc Theme 2 — Sản phẩm; BJ-09 thuộc Inventory Control. `outbound/` là hồ sơ tạm thời, không phải authority thứ hai.

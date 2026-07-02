# TH-03 — Module map

## Bảng module

| Module | Vai trò | Owner / Supporting | Package | Trạng thái |
| ------ | ------- | ------------------ | ------- | ---------- |
| partner | Hồ sơ, trạng thái, lịch sử read model | **Owner** | `modules/partner/` | **codegen enabled** (Epic-01..02) |
| iam | Auth, tenant, RBAC | Supporting | `modules/iam/` | golden / codegen |
| sales | Snapshot KH; publish order events | Supporting | `modules/sales/` | skeleton |
| inventory | Publish inbound events | Supporting | `modules/inventory/` | skeleton |
| accounting | Publish receivable events | Supporting | `modules/accounting/` | skeleton |

## Sơ đồ phụ thuộc

```mermaid
flowchart LR
  subgraph th03 [TH03_Partner]
    Partner[partner_module]
    TxHistory[transaction_history_read_model]
  end
  IAM[iam] --> Partner
  Partner --> Sales[sales_snapshot_consumer]
  Sales -->|integration_events| TxHistory
  Inventory[inventory] -->|integration_events| TxHistory
  Accounting[accounting] -->|integration_events| TxHistory
```

## Public contracts — integration events (publish)

Package: `modules/partner/integration_events/`

Xem [01-domain-model.md](01-domain-model.md) cho danh sách event types.

## Snapshot DTOs (cho module khác)

| DTO | Consumer |
| --- | -------- |
| `CustomerSnapshot` | sales |
| `SupplierSnapshot` | inventory |

## Permissions

Constants: `PartnerPermissions` trong `modules/partner/domain/` — dùng trong `@RequiresPermission` trên commands/queries; codegen emit `partner_access_metadata.g.dart`.

| Permission code | Gherkin label (ví dụ) | Epic/US |
| --------------- | --------------------- | ------- |
| `partner.view` | Xem danh sách đối tác | Epic-01/US-01 |
| `partner.create` | Ghi nhận đối tác mới | Epic-01/US-02 |
| `partner.update` | Chỉnh sửa hồ sơ | Epic-01/US-03 |
| `partner.view_detail` | Xem chi tiết đối tác | Epic-01/US-04 |
| `partner.manage_status` | Quản lý trạng thái đối tác | Epic-02/US-01 |
| `partner.delete` | Xóa hồ sơ đối tác | Epic-02/US-02 |
| `partner.view_transaction_history` | Xem lịch sử làm việc đối tác | Epic-03/US-01 |

## Ranh giới

- Partner **không** tạo đơn bán, phiếu nhập, hóa đơn, thu/trả công nợ
- Quick-create từ luồng khác: out of scope Epic-01/US-02 — module gọi dùng `RegisterPartnerCommand` qua facade
- Lịch sử giao dịch: partner **chỉ đọc** projection; mutation thuộc module nguồn

## Messaging

Schema `partner`: outbox/inbox/internal_commands — [messaging_schema.md](../../../operations/messaging_schema.md).

## Presentation layout

Dual path — pages trong ERP shell, dialog/widget tái dùng trong module presentation:

```text
apps/erp/lib/features/partner/presentation/
  pages/          — route screens (thin composition, ≤ 500 dòng)
  widgets/        — widget chỉ dùng trong feature partner (ERP shell)
  bloc/           — feature state (optional)

modules/partner/presentation/
  lib/src/widgets/ — DeactivatePartnerDialog, ReactivatePartnerDialog, ...
```

**Import rule:** `apps/erp` → `vet45_partner_presentation`; module presentation **không** import `apps/erp`.

Skill: [.cursor/skills/presentation-layer/SKILL.md](../../../../.cursor/skills/presentation-layer/SKILL.md)

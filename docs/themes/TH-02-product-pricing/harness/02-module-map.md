# TH-02 — Module map

## Bảng module

| Module | Vai trò | Owner / Supporting | Package | Trạng thái |
| ------ | ------- | ------------------ | ------- | ---------- |
| catalog | Product master, readiness, UOM, stock/base price profiles, price band, custom fields | **Owner** | `modules/catalog/` | planned (skeleton) |
| inventory | Advanced stock summary read | Supporting | `modules/inventory/` | planned |
| costing | Costing-module base price read (Growth) | Supporting | `modules/costing/` | planned |
| iam | Auth, tenant, RBAC (`catalog.*`) | Supporting | `modules/iam/` | in_progress |
| onboarding | Ngành, gói tenant → custom field seed | Supporting (read) | TBD | planned |

## Sơ đồ phụ thuộc (v3)

```mermaid
flowchart LR
  Onboarding[onboarding] --> Catalog[catalog]
  IAM[iam] --> Catalog
  Inventory[inventory] -->|stock summary| Catalog
  Costing[costing] -->|base price| Catalog
  Catalog -->|snapshot| Sales[TH04_sales]
  Catalog -->|khung giá| Promotions[promotions]
  Catalog -->|outbox| Events[integration_events]
```

## Snapshot DTOs (cho module khác)

| DTO | Consumer |
| --- | -------- |
| `ProductSnapshot` | sales (dòng đơn, barcode) |
| `ProductPriceBandSnapshot` | sales, promotions (list/floor per UOM) |
| `ProductReadinessSnapshot` | sales (chặn chọn SP chưa sẵn sàng) |

## Permissions (v3 — draft)

Constants: `CatalogPermissions` trong `modules/catalog/domain/`.

| Permission code | Gherkin label (ví dụ) | Epic/US |
| --------------- | --------------------- | ------- |
| `catalog.product.view` | Xem danh mục sản phẩm | EPIC-01/US-01 |
| `catalog.product.view_detail` | Xem Product Control Center | EPIC-01/US-02 |
| `catalog.product.create` | Tạo sản phẩm (guided) | EPIC-02/US-01 |
| `catalog.product.update` | Sửa hồ sơ / ảnh | EPIC-07/US-01 |
| `catalog.product.manage_stock` | Chỉnh basic stock | EPIC-05/US-02 |
| `catalog.product.manage_units` | Quản lý UOM | EPIC-04/* |
| `catalog.product.manage_pricing` | Base price, price band | EPIC-06/* |
| `catalog.product.manage_status` | Ngừng KD / KD lại | EPIC-07/US-02 |
| `catalog.product.delete` | Xóa mềm / khôi phục | EPIC-07/US-03 |
| `catalog.product.view_history` | Xem change history | EPIC-07/US-04 |
| `catalog.custom_fields.manage` | Cấu hình custom fields | EPIC-03/US-01 |
| `catalog.pricing.manage_store_rule` | Store Price Rule | EPIC-06/US-02 |

Ma trận đầy đủ: [appendices/README.md](../appendices/README.md) (Phụ lục F).

## Ranh giới

- Catalog **không** tạo đơn bán, phiếu nhập, phiếu kho chi tiết, hóa đơn, giá sau KM
- Basic stock: nhập/chỉnh trong Product (Foundation)
- Advanced stock: **read-only** stock summary từ inventory
- Manual base price: nhập trong Product (Foundation)
- Costing-module base price: **read-only** từ costing (Growth)
- Custom fields thay `medical_info` — không hard-code ngành vào Product

## Presentation layout

```text
apps/erp/lib/features/catalog/presentation/
  pages/          — list, guided_create, product_control_center
  widgets/        — readiness_chip, checklist, contextual_actions
  bloc/

modules/catalog/presentation/
  lib/src/widgets/ — dialogs tái dùng (change base unit, deactivate, …)
```

Skill: [.cursor/skills/presentation-layer/SKILL.md](../../../../.cursor/skills/presentation-layer/SKILL.md)

Theme map: [02-module-map.md](../02-module-map.md)

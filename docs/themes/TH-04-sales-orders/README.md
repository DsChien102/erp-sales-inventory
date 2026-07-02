# TH-04: Bán hàng & đơn hàng

**Trạng thái deliver:** `planned`

Đơn bán, nháp, thanh toán, tra cứu — publish integration events cho partner/inventory/accounting.

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| sales | **Owner** (planned) | `modules/sales/` |
| catalog | Supporting — product/price snapshot | `modules/catalog/` |
| partner | Supporting — customer snapshot | `modules/partner/` |
| inventory | Supporting — stock reservation | `modules/inventory/` |
| iam | Supporting — access | `modules/iam/` |

## Tài liệu

- [01-business-scope.md](01-business-scope.md) · [02-module-map.md](02-module-map.md)
- Messaging: [docs/architecture/07-integration-and-messaging.md](../../architecture/07-integration-and-messaging.md)

*Harness + Epic tree khi bắt đầu deliver. Event `sales.order.checked_out` là prerequisite E2E cho TH-03 Epic-03.*

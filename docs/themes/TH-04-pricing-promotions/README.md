# TH-04: Chính sách giá & ưu đãi

**Trạng thái deliver:** `in_progress` — chỉ EP02 Giá riêng / Nhớ giá đang active; EP01 và EP03–EP06 được giữ làm boundary nhưng deferred.

## Mục tiêu

Quản lý chính sách giá theo tenant, trong đó giai đoạn hiện tại tập trung vào giá riêng theo khách hàng và cơ chế nhớ giá từ đơn bán. Theme không sở hữu sản phẩm, khách hàng hay đơn bán; các dữ liệu đó được nhận qua snapshot/port của bounded context tương ứng.

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| pricing | **Owner tương lai** — customer price rule, import, memory request, audit | `modules/pricing/` (greenfield) |
| catalog | Supporting — product, selling unit, list/floor price snapshot | `modules/catalog/` |
| partner | Supporting — customer snapshot | `modules/partner/` |
| sales | Supporting — gửi yêu cầu nhớ giá, đọc rule áp dụng | `modules/sales/` |
| iam | Supporting — tenant, actor, permission | `modules/iam/` |

## Tài liệu

| Nhóm | File |
| ---- | ---- |
| **Product spec (canonical)** | [Theme-4-pricing-promotions.md](Theme-4-pricing-promotions.md) |
| Business scope | [01-business-scope.md](01-business-scope.md) |
| Agent ritual | [harness/00-agent-ritual.md](harness/00-agent-ritual.md) |
| Slice roadmap | [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md) |
| API contracts | [harness/07-api-contracts.md](harness/07-api-contracts.md) |

## Epic index

| Epic | Folder | Trạng thái |
| ---- | ------ | ---------- |
| EP01 — Giá cơ sở | [Epic-01-base-pricing/](Epic-01-base-pricing/) | deferred |
| **EP02 — Giá riêng / Nhớ giá** | [Epic-02-customer-price-rules/](Epic-02-customer-price-rules/) | **active — 10 US** |
| EP03 — Chương trình khuyến mãi | [Epic-03-promotions/](Epic-03-promotions/) | deferred |
| EP04 — Ưu tiên & xung đột chính sách | [Epic-04-policy-priority-conflicts/](Epic-04-policy-priority-conflicts/) | deferred |
| EP05 — Giá đã áp dụng | [Epic-05-applied-pricing/](Epic-05-applied-pricing/) | deferred |
| EP06 — Kiểm soát & audit chính sách giá | [Epic-06-pricing-audit-control/](Epic-06-pricing-audit-control/) | deferred |

## Quy ước ID

```text
TH-04 / EP-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SCN-{nn}
```

## Scope lock hiện tại

- Chỉ implement EP02 theo thứ tự S1–S10 trong harness.
- Không tính giá cuối đơn hàng, không stacking khuyến mãi và không triển khai POS trong EP02.
- Không mở rộng các epic deferred nếu chưa có quyết định sản phẩm mới.


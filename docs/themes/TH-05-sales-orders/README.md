# TH-05: Đơn hàng

**Trạng thái deliver:** `in_progress` — CONTRACT docs + Dart application Phase 1 synced cho S02–S34; S01 runtime-only giữ `n/a`. Sales domain/infrastructure/presentation vẫn là skeleton; BE/FE/E2E đều `todo`.

## Mục tiêu

Quản lý hành trình bán hàng từ working state, đơn nháp và checkout đến tra cứu, thanh toán, hủy và đổi/trả; bảo toàn commercial snapshot, audit và các tác động liên module. (EP-04 chỉnh ghi chú sau bán: superseded / out of scope.)

## Module tham gia

| Module / context | Vai trò | Trạng thái |
| --- | --- | --- |
| `sales` | **Owner** — order lifecycle, settlement, post-sale, inquiry và receipt | application contract + fakes đã có; implementation skeleton |
| `iam` | Tenant, store, actor, membership, permission | golden |
| `catalog` | Product/ProductUnit snapshot và sellability | supporting |
| `partner` | Customer snapshot và credit eligibility input | supporting |
| `pricing` | Pricing preview/final validation, promotion và remembered price | supporting |
| `accounting` | Receivable ledger contract của TH-06 | skeleton/supporting |
| `inventory` | Inventory availability, movement và costing contract của TH-07 | skeleton/supporting |
| E-invoice / Reporting | Planned external contexts của TH-08/TH-10 | chưa có owner module riêng |

## Tài liệu

| Nhóm | File |
| --- | --- |
| Product spec canonical | [Theme-5-sales-orders.md](Theme-5-sales-orders.md) |
| Tổng quan rút gọn | [OVERVIEWS.md](OVERVIEWS.md) |
| Agent ritual | [harness/00-agent-ritual.md](harness/00-agent-ritual.md) |
| Domain model | [harness/01-domain-model.md](harness/01-domain-model.md) |
| Slice roadmap | [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md) |
| API contracts | [harness/07-api-contracts.md](harness/07-api-contracts.md) |

## Epic index

| Epic | Folder | US | Slice | Trạng thái |
| --- | --- | ---: | --- | --- |
| EP-01 — Lập đơn hàng & lưu nháp | [Epic-01-order-drafting-and-drafts/](Epic-01-order-drafting-and-drafts/) | 7 | S01–S07 | CONTRACT done S02–S07; S01 `n/a` |
| EP-02 — Thanh toán & hoàn tất đơn hàng | [Epic-02-checkout-and-completion/](Epic-02-checkout-and-completion/) | 7 | S08–S14 | CONTRACT `done` |
| EP-03 — Tra cứu & theo dõi đơn hàng | [Epic-03-order-inquiry-and-tracking/](Epic-03-order-inquiry-and-tracking/) | 7 | S15–S21 | CONTRACT `done` |
| EP-04 — Chỉnh sửa ghi chú đơn hàng sau bán | [Epic-04-post-sale-order-adjustments/](Epic-04-post-sale-order-adjustments/) | 1 | S22 | `superseded` / out of scope |
| EP-05 — Hủy đơn hàng sau bán | [Epic-05-post-sale-order-cancellation/](Epic-05-post-sale-order-cancellation/) | 5 | S23–S27 | CONTRACT `done` |
| EP-06 — Đổi/trả hàng & quyết toán chênh lệch | [Epic-06-returns-exchanges-and-settlement/](Epic-06-returns-exchanges-and-settlement/) | 7 | S28–S34 | CONTRACT `done` |

Tổng: **6 Epic, 34 US, 235 FR**.

## Quy ước ID

```text
TH-05 / EP-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SCN-{nn}
```

- Mỗi US là một file phẳng `Epic-*/US-{nn}.md`; `README.md` của Epic tổng hợp và liên kết toàn bộ US.
- FR của mỗi US được giữ cùng context trong file US (EP-04 Phase 1: 5 FR; hầu hết US khác: 7 FR; EP-06/US-04: 6 FR).
- Scenario nguồn `SC-{nn}` được chuẩn hóa thành `SCN-{nn}` trong tài liệu dẫn xuất.
- Test ID tương lai: `scn_e{epic}_u{us}_fr{fr}_{case}`, `wgt_*`, `e2e_*`.

## Scope lock

- Application contract, provider ports và testing fakes trong `modules/sales/application` đã sync Phase 1 (session discard; note-only adjust **superseded**).
- 34 section contract docs đã `frozen` (S22 withdrawn/superseded); S01 là runtime contract không có Sales CQRS.
- RPC chỉ là `contract-only / unimplemented`; không có migration draft/applied trong phase này.
- Không dùng Sales implementation skeleton làm golden reference; CQRS/codegen vẫn mirror `modules/iam/`.

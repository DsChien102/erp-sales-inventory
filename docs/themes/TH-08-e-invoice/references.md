# TH-08 — References

| Nguồn | Link / path | Ghi chú |
| ----- | ----------- | ------- |
| Canonical SRS | [Theme-8-e-invoice.md](Theme-8-e-invoice.md) | SSOT product |
| Catalog theme | [docs/themes/README.md](../README.md) | TH-08 = HĐĐT |
| Template | [THEME_DOCUMENTATION_TEMPLATE.md](../THEME_DOCUMENTATION_TEMPLATE.md) | |
| Architecture platform | [docs/architecture/](../../architecture/README.md) | CQRS / module layout |
| Worker + MISA runtime | [harness/03-architecture-and-flows.md](harness/03-architecture-and-flows.md) | |
| MISA blackbox package | [`packages/c45_misa`](../../../packages/c45_misa/) | `IMeInvoiceClient` |
| MISA Open API notes | [`packages/c45_misa/doc/misa-meinvoice-open-api.md`](../../../packages/c45_misa/doc/misa-meinvoice-open-api.md) | |

## Cross-theme (từ SRS §1.7)

| Theme | Quan hệ |
| ----- | ------- |
| TH-01 Tổ chức & người dùng | Tenant, hồ sơ pháp lý bên bán, permission |
| TH-03 Đối tác | Hồ sơ buyer hiện hành — completion có kiểm soát |
| TH-05 Đơn hàng | SalesOrder, BuyerInvoiceSnapshot, màn nguồn |
| Theme kế toán / thuế (SRS: Theme 09) | Consume HĐ đã phát hành + lineage |
| Theme cảnh báo (SRS: Theme 11) | Consume lỗi / trạng thái cần theo dõi |

## Journeys liên quan

Business setup · Data onboarding · Order-to-cash · Management & control — chi tiết canonical §1.7.2.

## Pháp lý / AA

- Nghị định / thông tư HĐĐT VN: tra cứu khi implement tuân thủ (không nhân bản trong harness).
- Product Vision AA: `AA-O08` (ghi nhận yêu cầu/thông tin xuất HĐ) — Theme 08 không tự tạo mã AA mới (§1.7.4).


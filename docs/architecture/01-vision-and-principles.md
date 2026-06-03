# Vision và nguyên tắc thiết kế

## Vet45 ERP là gì?

Vet45 là hệ thống ERP cho phòng khám thú y và cửa hàng bán lẻ thú y: quản lý sản phẩm, bán hàng, đối tác, kho, công nợ, hóa đơn điện tử và báo cáo — **multi-tenant**, nhiều cửa hàng/chi nhánh.

Sản phẩm được **deliver theo theme** (TH-01..TH-11). Kiến trúc kỹ thuật là **modular monolith**: một ứng dụng Flutter (`apps/erp`) gồm nhiều bounded context độc lập trong `modules/`.

## Bounded context vs module package

| Khái niệm | Ý nghĩa |
| --------- | ------- |
| **Bounded context** | Ranh giới nghiệp vụ (Sales, Catalog, IAM…) — ngôn ngữ ubiquous riêng |
| **Module package** | Thư mục `modules/{name}/` với các layer Dart (`domain`, `application`, …) |
| **Theme (TH-xx)** | Đơn vị deliver sản phẩm — thường **span nhiều module** |

## Nguyên tắc kiến trúc

1. Module không import implementation nội bộ module khác.
2. Chỉ expose public contract cần thiết (`IIamModule`, integration events, snapshot ports).
3. Mỗi layer là một package riêng (`vet45_{module}_{layer}`).
4. Domain không phụ thuộc Flutter, Supabase, HTTP, UI.
5. Application điều phối command, query, integration event handler.
6. Infrastructure implement gateway, repository, RPC adapter.
7. Integration events là contract public liên module.
8. Presentation layer optional (widget/screen trong module hoặc `apps/erp/features/`).
9. Business mutation quan trọng đi qua **Postgres RPC** (defense in depth).
10. Outbox/Inbox durable chạy server-side (Postgres + worker), không thay bằng Flutter event bus.
11. Flutter event bus chỉ cho app-local UI refresh.
12. Barrel `lib/{layer}.dart` — package ngoài không import `src/`.

## Anti-patterns cần tránh

- **God aggregate** — nhét cart, payment, stock vào một `Order`.
- **Cross-module repository** — Sales gọi trực tiếp bảng `catalog.products`.
- **Anemic domain-only** — toàn bộ rule chỉ trong SQL, không có invariant Dart.
- **Query trả aggregate entity** — read side dùng DTO.
- **1 theme = 1 module** — bỏ qua snapshot/event từ module khác.
- **Permission rải rác** — catalogue permission chỉ seed trong `iam.permissions`.

## Liên kết

- [02-architecture-style.md](02-architecture-style.md)
- [themes/README.md](../themes/README.md)

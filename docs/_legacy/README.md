# Tài liệu kiến trúc cũ (chỉ để tham khảo)

> **Không dùng để viết code mới.** Kiến trúc modular monolith / DDD / CQRS / outbox mô tả ở đây đang được thay bằng kiến trúc đơn giản `Page → Cubit → Repository → RPC` (xem [docs/refactor/SCOPE.md](../refactor/SCOPE.md), [PLAN.md](../refactor/PLAN.md)). Đặc tả nghiệp vụ chuẩn: [docs/02-yeu-cau/](../02-yeu-cau/).

Chuyển vào đây ngày 2026-10-08 (PLAN P0.6) để AI agent không áp dụng nhầm. Dùng khi cần **đọc code cũ** trong `modules/`, `packages/vet45_shared`, `apps/messaging_worker` cho đến khi chúng bị xoá ở P9. Bản code nguyên vẹn: tag `v-legacy-arch`.

| Thư mục / file | Nội dung cũ |
|---|---|
| `AGENTS.legacy.md` | Hướng dẫn agent cũ (luồng CQRS bắt buộc, quy trình harness, migration declarative) |
| `architecture/` | 14 ADR + sơ đồ kiến trúc cũ |
| `harness/` | Tiến độ harness theo module |
| `*_skill.md`, `MODULES_IMPLEMENTATION_TEMPLATE.md`, `integration_event_flow.md` | Quy tắc từng tầng domain / application / infrastructure / presentation, mẫu module, luồng integration event |
| `cursor-rules/` | Rule Cursor cũ (đổi đuôi `.md` để Cursor không nạp) |
| `agents-skills/` | Skill agent theo từng tầng của kiến trúc cũ |

Xoá cả thư mục này ở P9.

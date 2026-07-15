# Polaris — Vet45 Design System Upgrade

Bộ tài liệu này là **source of truth** cho quy chuẩn UI: tokens, typography, layout patterns, component contracts, và chiến lược rollout.

## Cách đọc

| Thứ tự | File | Mục đích |
|--------|------|----------|
| 1 | [01-baseline-audit.md](01-baseline-audit.md) | Gap hiện tại |
| 2 | [02-target-architecture.md](02-target-architecture.md) | Kiến trúc mục tiêu |
| 3 | [06-design-system-spec.md](06-design-system-spec.md) | **Spec chính** — tokens, typography, 5 recipes |
| 4 | [07-token-migration-checklist.md](07-token-migration-checklist.md) | Checklist PR |
| 5 | [03-wave-roadmap.md](03-wave-roadmap.md) | Lộ trình waves |
| 6 | [04-backlog-kpi.md](04-backlog-kpi.md) | KPI đo lường |
| 7 | [05-rollout-strategy.md](05-rollout-strategy.md) | Chiến lược migrate |

## Golden UI reference

Sau Phase 4, màn hình tham chiếu tuân thủ DS:

- `apps/erp/lib/features/catalog/presentation/pages/product_control_center_page.dart`
- `apps/erp/lib/features/catalog/presentation/widgets/product_control_center_*.dart`

Copy pattern từ đây trước khi invent widget/layout mới.

## Liên kết

- Example catalog: `packages/vet45_design_system/example/`
- Component audit: [docs/audit/component_audit_report.md](../audit/component_audit_report.md)
- Agent rule: `.cursor/rules/vet45-design-system-example.mdc`
- Presentation skill: `.cursor/skills/presentation-layer/SKILL.md`

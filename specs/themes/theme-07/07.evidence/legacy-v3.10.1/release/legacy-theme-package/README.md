# Theme 07 — Tồn kho và giá vốn — v4.3.1

## Trạng thái tích hợp

> v4.3.1 là bản repackage của v4.3.0 để tránh cache; không thay đổi nội dung nghiệp vụ hoặc artifact chức năng.

| Thành phần | Giá trị |
|---|---|
| Package freeze | `T7-PACKAGE-FREEZE-v4.3.1` |
| Semantic baseline | `T7-BASELINE-FREEZE-v4.0.0` — không đổi nghiệp vụ |
| BJ migration | `T7-BJ-MIGRATION-FREEZE-v4.1.0` — 17 BJ / 70 UC |
| Know-how/navigation | `v4.1.3` — full GitLab heading permalink |
| UI model | `T7-UIUX-FREEZE-v4.2.0-rc1` — Screen Group đã nghỉ dùng |
| UI flow chi tiết | Harness canonical — 17 flow / **202 transition** sau correction UIF-01 |
| Prototype | Harness `v0.1.0`; UIF-02 HTML `v0.3.2` static-pass, UIF-01 contract-ready |
| Evidence / Verdict | `STATIC_VALIDATED` / `CONDITIONALLY_READY` |

## Cấu trúc có thẩm quyền

1. [`know-how/`](know-how/) — Quyết định nghiệp vụ, thuật ngữ và Wiki.
2. [`srs/`](srs/) — SRS 17 BJ, 70 UC và các hợp đồng.
3. [`prototype/flows/`](prototype/flows/) — 17 UI flow canonical, 202 transition sau correction UIF-01.
4. [`prototype/contracts/`](prototype/contracts/) — 83 Screen Contract, registries, actions và trace.
5. [`prototype/html/`](prototype/html/) — HTML review workbench; hiện seed UIF-02 v0.3.2 với Inspect.
6. [`harness/`](harness/) — Harness semantic tiền nhiệm và UI trace overlay v4.3.0.
7. [`outbound/`](outbound/) — external Business Journey/use case tạm giữ; không phải scope canonical.
8. [`migration/`](migration/) — bằng chứng migration và hợp nhất component.
9. [`validation/`](validation/) — kiểm định package và handoff.

## Mở nhanh

- [Bản đồ Business Journey](../../../../02.specification/behavior/journeys/00-business-journey-map.md)
- [Bản đồ Use Case](../../../../02.specification/behavior/use-cases/00-use-case-map.md)
- [Quyết định nghiệp vụ](../../../../01.knowledge/decisions/decision-register.md)
- [Thiết kế UI/UX](../../implementation/legacy-harness/frozen-source/srs/08-ui-ux.md)
- [Danh mục UI flow](prototype/flows/README.md)
- [Bản đồ BJ → UC → Screen](../../../../09.generated/matrices/design/bj-ui-flow-map.md)
- [Screen Registry](../../../../09.generated/registries/design/screen-registry.md)
- [HTML prototype workbench](prototype/html/index.html)
- [Harness plan](../../design/prototype-harness/HARNESS-PLAN.md)
- [Harness status](../../design/prototype-harness/HARNESS-STATUS.yaml)
- [Validation](validation/validation-report.md)


## Design Readiness Checkpoint DR1

- Checkpoint: `4.3.1-dr1` / `T7-DESIGN-READINESS-CHECKPOINT-DR1`.
- Scope: audit 17 BJ / 70 UC / 17 UI Flow / 83 Screen and uploaded Flutter DS.
- Canonical flow path: `prototype/flows/`.
- Readiness artifacts: [`design-readiness/README.md`](design-readiness/README.md).
- Sau DR1, pilot UIF-02 đã được nâng đến HTML v0.3.2; Harness v0.1.0 dùng pilot này làm seed và bắt đầu cumulative review với UIF-01.


## v1.3.9 — BJ07/UIF07 Deep Product Correction
Cumulative child of v1.3.8. Scope: supplier-return queue ownership, exact Product+UOM+LOT physical verification, no warehouse partial/LOT substitution, granular source invalidation, actual handover commit and result finality.


## v1.4.5 — BJ13/UIF13 Deep Product Correction

Cumulative Product-review successor của v1.4.4. Active BJ13 Product flow là `SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089`; late landed cost dùng non-mutating preview trước atomic value-only commit. BJ03 v1.4.4 và mọi non-UIF13 flow được bảo vệ bằng regression. Product approval: **PENDING**.

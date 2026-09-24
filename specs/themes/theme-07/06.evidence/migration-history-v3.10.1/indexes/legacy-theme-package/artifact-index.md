# Artifact index — Theme 7 v4.3.1 + BJ-02 pilot v0.2.7

> **Current cumulative Product candidate: v1.4.5.** BJ13/UIF13 active Product topology is `SCR-085..089`; `SCR-018` is retired from active UIF13 and old BJ03 screen IDs are no longer BJ13 routes. Historical baseline counts below are retained for migration context; current workbench has **17 flows / 85 registered screens / 87 active flow-screen renders**.

| Nhóm | Entry point | Ghi chú |
|---|---|---|
| Quyết định nghiệp vụ | [Decision Register](../../../../01.knowledge/decisions/decision-register.md) | Baseline 102; BJ-02 pilot bổ sung T7-DR-103..105 |
| Business Journey | [BJ map](../../../../02.specification/behavior/journeys/00-business-journey-map.md) | 17 BJ |
| Use Case | [UC map](../../../../02.specification/behavior/use-cases/00-use-case-map.md) | 70 UC canonical |
| UI flows | [UI flow registry](prototype/flows/README.md) | 17 flow; UIF-02 dùng Design Flow v5 pilot |
| Screen model hiện hành | [Screen Registry](../../../../09.generated/registries/design/screen-registry.md) | Baseline 83; BJ-02 pilot thêm SCR-084 → 84 registry entries |
| Prototype HTML | [Workbench](prototype/html/index.html) | BJ-02/UIF-02 v0.2.7 multi-product calibration; Inspect + DS trace |
| Prototype Harness | [Harness plan](../../../legacy-v3.10.1/design/prototype-harness/HARNESS-PLAN.md) | 17 UIF incremental + cumulative review; status tại `prototype/HARNESS-STATUS.yaml` |
| Outbound tạm thời | [Outbound](../../../../02.specification/domain/integrations/INT-01-cross-theme-outbound.md) | External BJ/use case chờ Theme đích tiếp nhận |
| Migration | [Consolidation evidence](../../../legacy-v3.10.1/release/migration-history/legacy-package/consolidation-v4.3.0/carry-forward-components.json) | Nguồn, checksum và carry-forward proof |
| Repackage v4.3.1 | [Repackage evidence](../../../legacy-v3.10.1/release/migration-history/legacy-package/repackage-v4.3.0-to-v4.3.1/repackage-report.md) | Cache-bust; semantic changes = 0 |
| Validation | [Executive handoff](validation/executive-handoff.md) | Gate, evidence và residual risks |

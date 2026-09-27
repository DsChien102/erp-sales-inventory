# SRS Theme 07 — mục lục

| Phần | Artifact | Vai trò |
|---:|---|---|
| 01 | [Tổng quan](01-overview.md) | Mục tiêu, phạm vi, actor và bất biến cấp sản phẩm |
| 02 | [Hành trình nghiệp vụ](../../../../../../02.specification/behavior/journeys/00-business-journey-map.md) | Bản đồ và 25 BJ đầu-cuối; nội miền/liên miền là metadata |
| 03 | [Nền tảng miền](../../../../../../02.specification/domain/domain-foundation/DOM-COM.md) | Ranh giới miền, thẩm quyền và policy |
| 04 | [Dữ liệu và thực thể](04-data-entities.md) | Entity, quan hệ, lifecycle và projection |
| 05 | [Trường hợp sử dụng](../../../../../../02.specification/behavior/use-cases/00-use-case-map.md) | Registry và 97 UC độc nhất, chia thành thư mục theo BJ |
| 06 | [Hợp đồng hành vi dùng chung](../../../../../../02.specification/behavior/behavioral-contracts) | SBC/BC registry và định nghĩa dùng lại |
| 07 | [Hợp đồng kỹ thuật](../../../../../../02.specification/technical-contracts/FND-TECH-01.md) | API, event, error, permission và realization matrix |
| 08 | [UI/UX](08-ui-ux.md) | Screen Group map và quy tắc handoff |
| 09 | [Truy vết và chất lượng](09-traceability-quality.md) | Trace chain, test catalog và quality gates |

## Quy tắc đọc

1. Bắt đầu từ BJ để hiểu quy trình nghiệp vụ.
2. Theo link trong BJ tới UC để xem hành vi, nghiệm thu, UI và kỹ thuật của lát cụ thể.
3. Theo link từ UC tới SBC/BC, UI Contract, API và bài tri thức; không sao chép quy tắc giữa các file.
4. Khi một màn hình phục vụ nhiều UC/BJ, UI Contract chỉ được định nghĩa một lần; từng UC chỉ trỏ tới state/action mình sử dụng.

## Đơn vị giao việc

- FE: work package theo BJ; chia checkpoint nghiệm thu theo `UC × Screen × State × Action`.
- BE: theo UC/BC/API và transaction boundary.
- QA: theo Acceptance Scenario + BC Test ID + UI state/action.
- Harness: dùng stable ID và registry máy đọc làm seed; không coi registry là nguồn quy tắc mới.

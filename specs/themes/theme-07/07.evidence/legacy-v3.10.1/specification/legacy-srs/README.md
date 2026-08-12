# SRS Theme 07 — mục lục

| Phần | Artifact | Vai trò |
|---:|---|---|
| 01 | [Tổng quan](../../implementation/legacy-harness/frozen-source/srs/01-overview.md) | Mục tiêu, phạm vi, actor và Điều kiện bắt buộc cấp sản phẩm |
| 02 | [Business Journey](../../../../02.specification/behavior/journeys/00-business-journey-map.md) | Bản đồ và 17 BJ đầu-cuối |
| 03 | [Nền tảng miền](../../../../02.specification/domain/domain-foundation/DOM-COM.md) | Ranh giới miền, thẩm quyền và policy |
| 04 | [Dữ liệu và thực thể](../../implementation/legacy-harness/frozen-source/srs/04-data-entities.md) | Entity, Quan hệ số lượng, lifecycle và projection |
| 05 | [Trường hợp sử dụng](../../../../02.specification/behavior/use-cases/00-use-case-map.md) | 70 UC canonical theo BJ; CAP-01 tách riêng |
| 06 | [Hợp đồng hành vi dùng chung](../../../../02.specification/behavior/behavioral-contracts) | SBC/BC registry và định nghĩa dùng lại |
| 07 | [Hợp đồng kỹ thuật](../../../../04.architecture/foundations/FND-TECH-01.md) | API, event, error, permission và realization matrix |
| 07P | [Thủ tục kỹ thuật](07-technical-procedures/) | PROC-01 và các bước dựng lại dữ liệu dẫn xuất |
| 08 | [Thiết kế UI/UX](../../implementation/legacy-harness/frozen-source/srs/08-ui-ux.md) | Screen Registry, Screen Contract và quy tắc handoff theo BJ |
| 09 | [Truy vết và chất lượng](09-traceability-quality.md) | Trace chain, test catalog và quality gates |

## Quy tắc đọc và giao việc

1. Bắt đầu từ BJ để hiểu kết quả đầu-cuối.
2. Theo BJ tới UC để xem hành vi và nghiệm thu.
3. Theo UC tới BC/API và Screen Contract; không sao chép quy tắc.
4. FE nhận gói theo BJ; checkpoint là `UC × Screen × State × Action`.
5. Screen Group và Figma không còn thuộc mô hình chính thức; prototype HTML chưa được render.

# VERSION — Theme 10 Mua hàng

| Thuộc tính | Giá trị |
|---|---|
| Version | `v0.2.0` |
| Date | `2026-09-23` |
| Parent | `v0.1.1` |
| Parent freeze | `T10-SCOPE-2026-09-23-01` |
| Parent SHA-256 | `2b76f6f78dee1d9e075cdb86f9c53707e0b23fd3f2271df2a8e62cc9b3223570` |
| Status | `OFFICIAL_BASELINE_SNAPSHOT / IN_REVIEW / NOT_FROZEN` |
| Freeze ID | Chưa cấp |
| Owner | BA Theme Mua hàng |

## Semantic delta so với v0.1.1

1. Giữ nguyên 5 Business Journey và các ownership đã xác nhận.
2. Mở rộng Decision Register thành cấu trúc theo nhóm nghiệp vụ.
3. Tạo Glossary canonical và bộ Know-how nền.
4. Tạo Overview đầy đủ hơn theo cấu trúc Theme hiện hành.
5. Tạo Domain Foundation, context map, invariant và lifecycle cấp miền.
6. Đề xuất 5 semantic aggregates và catalog entities để mô tả bức tranh đích.
7. Gắn câu hỏi mở Q-01–Q-10 vào đúng aggregate/entity bị ảnh hưởng.
8. Bổ sung các quyết định `PROPOSED` để có thể review bức tranh hoàn chỉnh mà không ngầm freeze.

## Impact set

- `00.governance/*`
- `01.knowledge/*`
- `02.specification/overview/*`
- `02.specification/domain/*`
- `02.specification/behavior/00-business-journey-map.md`

Không có thay đổi trực tiếp lên Design, Architecture implementation, Harness hoặc Theme khác.

## Validation level

- Semantic carry-forward từ hand-off v0.1.1: **PASS**.
- Cross-link nội bộ package: phải PASS trước khi đóng ZIP.
- Manifest/checksum: phải sinh sau cùng.
- Byte diff với parent v0.1.1: **NOT_VERIFIED** vì parent ZIP không có trong runtime.
- Cross-Theme latest-parent reconciliation: **PENDING**; hand-off Theme 7 chỉ là yêu cầu, chưa là bằng chứng đã tích hợp.

---
id: EVD-RELEASE-VALIDATION-v3.11.0
type: evidence
theme: theme-07
title: "Kiểm định migration cấu trúc v3.11.0"
owner: QA
status: FROZEN
---
# EVD-RELEASE-VALIDATION-v3.11.0

**Verdict:** `STRUCTURE_MIGRATION_PASS_WITH_INHERITED_VALIDATOR_LIMIT`

| Gate | Trạng thái | Bằng chứng |
|---|---|---|
| `BASELINE` | `PASS` | parent theme-07.zip = v3.10.1; impact set restricted to structure/path/version/derived metadata |
| `STRUCTURE` | `PASS` | new V45-Theme skeleton directories present; legacy top-level 04.architecture, 05. harness, 06.procedures, 07.evidence absent |
| `MIGRATION_PRESERVATION` | `PASS` | 6837/7025 mapped source files byte-identical; 188 changed for path/link/version/derived metadata; ENT-IO files changed=0; DOM-IO changed only for structure reference |
| `LINKS` | `PASS` | canonical broken internal Markdown links=0; historical evidence retains 194 inherited broken links, parent had 201 |
| `PACKAGE_DIFF` | `PASS` | audit_package_diff unexpected_changes=0 |
| `PROTOTYPE_STATIC_SMOKE` | `PASS` | Node syntax PASS for core JS; index.html has 88 local asset refs and 0 missing; core runtime files present |
| `LEGACY_PROTOTYPE_VALIDATOR` | `BLOCKED` | current_package_validation_v3101.py hard-codes old repository path specs/themes/theme-07 and cannot run against standalone migrated package; script intentionally not modified in structure-only migration |
| `SEMANTIC_REGRESSION` | `NOT_RUN` | No semantic change is permitted in v3.11.0; semantic review is inherited from parent and will be rerun in the subsequent BJ/UC refactor version |
| `ARCHIVE` | `PASS` | Archive CRC passed and post-extract tree matched candidate exactly; final archive is revalidated after checksum regeneration. |

## Giới hạn bằng chứng

- Đây là bản migration cấu trúc, không phải bản thay đổi semantic.
- Validator prototype v3.10.1 phụ thuộc layout repo cũ nên được ghi `BLOCKED`, không được gọi là PASS.
- Không chạy lại visual regression vì HTML runtime không thay đổi trong impact set.
- Semantic BJ/UC/Domain sẽ được kiểm định lại ở version refactor kế tiếp.

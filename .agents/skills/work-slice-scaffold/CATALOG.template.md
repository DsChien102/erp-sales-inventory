# CATALOG.md (template)

Copy vào `BJ-<id>-harness/CATALOG.md`. Schema đầy đủ: `.agents/skills/work-slice-scaffold/reference.md`.

SSOT `design_status`. Không ghi status trên file slice.

| id | title | path | design_status | depends_on | sources | family | produces / coverage | lanes / links | blocked_reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SL-001 | | SL-001-<slug>.md | DRAFT | | | | | full | |
| SL-002 | | SL-002-<slug>.be-contract.md | DRAFT | SL-001 | | <family> | | be-contract | |

`design_status` ∈ `DRAFT` | `IN_REVIEW` | `READY_TO_IMPLEMENT` | `BLOCKED` | `VERIFIED`.  
`READY_TO_IMPLEMENT` chỉ khi mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`.  
`BLOCKED` → bắt buộc `blocked_reason`.

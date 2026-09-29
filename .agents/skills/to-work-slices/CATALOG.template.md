# CATALOG.md (template)

Copy vào `BJ-<id>-harness/CATALOG.md`. Schema: `.agents/skills/to-work-slices/reference.md`.

SSOT `design_status`. Không ghi status trên file slice.

| id | title | design_status | depends_on | usecase | blocked_reason |
| --- | --- | --- | --- | --- | --- |
| SL-001 | | DRAFT | | | |
| [SL-002](SL-002-<slug>.md) | | DRAFT | SL-001 | | |

`id` là link tới file slice. Chưa có file thì ghi ID trần.
`usecase` chỉ là link tới file UC.
`design_status` ∈ `DRAFT` | `IN_REVIEW` | `READY_TO_IMPLEMENT` | `BLOCKED` | `VERIFIED`.
`READY_TO_IMPLEMENT` chỉ khi mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`.
`BLOCKED` thì có `blocked_reason`.

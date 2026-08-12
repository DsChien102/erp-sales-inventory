# 04 — Design-ready Screen Contract Schema

> Version `4.3.1-dr1` · áp dụng cho mọi canonical Screen trước HTML.

## Gate S1

Một Screen đạt S1 khi có đủ:

1. User task, primary object và success criterion.
2. Actor/authority, owner scope và permission behavior.
3. Entry context, outgoing transitions, back/resume/handoff.
4. Information anatomy và semantic data ownership.
5. Visible actions tách khỏi trace-only actions; action hierarchy/visibility/enable/loading/confirmation.
6. User-visible states theo nhóm ready/loading/empty/access/validation-concurrency/finality.
7. Flutter DS public component candidates và module-presentation pattern boundary.
8. Không còn unresolved business decision ảnh hưởng task, mutation responsibility hoặc lifecycle.

## Status

| Status | Meaning |
|---|---|
| `S1_READY_DERIVED` | Đủ để bắt đầu HTML calibration; contract được dẫn xuất, chưa phải API/data schema. |
| `S1_READY_WITH_REVIEW` | Có flow/mode/structural review nhưng có thể chuẩn bị layout/interaction; không chốt final flow. |
| `S1_BLOCKED_BY_DECISION` | Không render production HTML trước khi business/structural decision được duyệt. |

## Data ownership vocabulary

| Value | Meaning |
|---|---|
| `SERVER_AUTHORITATIVE_READ_ONLY` | UI chỉ hiển thị read model authoritative. |
| `SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM` | Row/card summary từ server; tap chỉ theo transition. |
| `SYSTEM_DERIVED_READ_ONLY` | Giá trị tính/aggregate/version/status; không cho sửa trực tiếp. |
| `PREFILLED_OR_USER_SELECTION` | Context có thể prefill, user chỉ chọn giá trị hợp lệ. |
| `USER_INPUT_SERVER_VALIDATED` | User nhập; server vẫn kiểm tra lại. |
| `PREFILLED_OR_USER_INPUT_REQUIRES_UC_VALIDATION` | Source chưa đủ để chốt; phải verify khi design BJ. |

## Flutter DS rule

- `flutter-ds-source-catalog.json` chỉ là audit snapshot nguồn/path, không phải token mirror.
- HTML không sở hữu DS. Theme 7 module patterns compose public Flutter DS concepts.
- Gap trong core DS phải quay về Flutter DS/module presentation; không sửa cục bộ bằng hard-coded CSS rồi coi là chuẩn.

# UI flow validation report — v3.5.0

> **Historical/static report.** Current executable runtime validation is `v3.5.0`; use root `RELEASE-VALIDATION-v3.5.0.md` and `specs/themes/theme-07/prototype/html/qa/` for current flow/state/UI evidence.


**Kết quả:** `PASS` · **Bằng chứng:** `SEMANTIC_RUNTIME_VISUAL_VALIDATED`.

| Gate | Kết quả |
|---|---|
| 17 BJ / 70 UC canonical | `PASS` |
| Canonical screens | `PASS` — 85 Screen |
| Declared-state effective render | `PASS` — 500/500 |
| Audit & Control effective render | `PASS` — 272/272 |
| Semantic flow/logic E2E | `PASS` — xem `../html/qa/FLOW-LOGIC-E2E-QA-v3.5.0.json` |
| Runtime UI / geometry / chip / hidden-row / terminology | `PASS` — xem `../html/qa/RUNTIME-UI-QA-v3.5.0.json` |
| Entry / actor contexts | `PASS` — executable routing QA |
| UNKNOWN recovery / same-operation handoff | `PASS` trong browser harness |

## Ranh giới bằng chứng

- Kết quả trên là validation của **prototype HTML hiệu lực**, bao gồm transition do người dùng kích hoạt và state render.
- `500/500` chỉ là state-render coverage; transition correctness được kiểm riêng bằng semantic E2E.
- Browser harness **không chứng minh** transaction/database/outbox/network atomicity của backend thật. Các invariant đó phải được xác nhận ở integration/backend QA.

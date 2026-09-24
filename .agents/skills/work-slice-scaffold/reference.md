# Work Slice — 7 phần cố định (variable depth)

Một file = business outcome + technical design + delivery contract.

Gate code: `STATUS: READY_TO_IMPLEMENT`.  
`BLOCKED` = dừng lane; metadata bắt buộc `Blocked reason`.

**Spacing:** tối đa một dòng trống giữa block.

**Fenced blocks:** chỉ source/config, directory tree, hoặc ASCII hiếm (ưu tiên Mermaid). Không bọc prose / rules / txn list để highlight — `documentation-standards.mdc` §17.

**Không** User Story. Trace metadata: chỉ ghi key đúng loại có (`BJ`/`CAP`, `UC`/`OP`, `BC`/`API`) — có cả hai mới dùng key ghép.

---

## Section map

| § | Phần | Nội dung chính |
| --- | --- | --- |
| — | Metadata | STATUS (+ `Blocked reason` nếu `BLOCKED`), Slice, Wave, Theme, BJ/CAP, UC/OP, BC/API, lane |
| 1 | Objective | Outcome 1 câu |
| 2 | Scope & Rules | In/Out, Boundary Owns/Does Not Own, Rules (link ID) |
| 3 | Flow | Main Mermaid + ≤5 bước; Failure (mutation). Workflow diagram **chỉ** ở đây |
| 4 | Design | Domain Before/After (+ stateDiagram chỉ nếu khác Flow), Application & layout, Persistence, Txn, Idempotency, Errors |
| 5 | Dependencies & Contracts | Requires/Provides; mỗi Command/Query/DTO = H4 (+ **blockquote** use-case cho Command/Query) + Dart fence; RPC; Integration; Dependencies table |
| 6 | Verification | AC checklist; `scn_*` map từ AC |
| 7 | Delivery | Definition of Done; Open Questions; Next Action |

Technical concerns (DB, API, CQRS, events, security, …) **không** thành section cấp 1 — nhúng vào **Design** hoặc **Dependencies & Contracts** khi slice đụng tới.

---

## Fact vs command

| Kind | Transport | Naming |
| --- | --- | --- |
| Integration event (fact) | outbox | `{context}_{entity}_{past}.v1` |
| Integration command | `integration_commands` (+ intent) | imperative |

Rejected on outbox: `*.requested`, apply/retry/reconcile as “event”.

---

## Idempotency (mutation)

| Concept | Field |
| --- | --- |
| Delivery instance | `command.id` — **không** dùng làm retry key |
| Logical operation | `idempotencyKey` |
| DB defense | UNIQUE `(tenant_id, command_scope, idempotency_key)` + cùng txn business + outbox |

Query: Design Transaction / Idempotency + Failure Flow = `N/A — query-only`.

---

## Contracts (Command / Query / DTO)

Mỗi type = **H4** riêng + **Dart fence** (không bảng field; không gom một dòng dù ít field).

| Kind | Use-case dưới H4 (trước fence) |
| --- | --- |
| **Command** | **Bắt buộc** 1–2 câu trong **blockquote** (`> …`): khi nào gọi (actor + điều kiện trước + outcome chính). Không lặp danh sách field. |
| **Query** | **Bắt buộc** 1–2 câu trong **blockquote**: khi nào đọc / consumer cần gì. |
| **DTO** | Optional blockquote — chỉ khi tên chưa đủ rõ. |

Blockquote ≠ fenced code — không dùng ` ``` ` để “highlight” prose (`documentation-standards.mdc` §17).

Khi user chốt thêm quy ước docs Work Slice → cập nhật **SKILL.md + reference.md + `template.work-slice.md`** (theme canonical) cùng lúc.

---

## Dependencies table

- Mỗi dòng **slice** (`Sxx`): link relative tới `Sxx-<slug>.md` cùng folder `harness/slices/`.
- Slice chưa có Work Slice: link [`04-slice-roadmap.md`](../../../docs/themes/TH-07-inventory-and-costing/harness/04-slice-roadmap.md) + mã slice.
- Phụ thuộc ngoài theme: link doc authoritative; ghi `(không có Work Slice TH-xx)` nếu cần.

---

## Checklist trước READY_TO_IMPLEMENT

- [ ] Đủ 7 section cấp 1
- [ ] Field/RPC/schema khớp SRS hoặc deviation ghi rõ
- [ ] Draft SQL path trong Design (nếu persistence)
- [ ] Mỗi Command/Query có **blockquote** use-case + Dart fence
- [ ] Dependencies table đã link
- [ ] `scn_*` cover AC + failure/idempotency (mutation)
- [ ] Open Questions không còn blocking
- [ ] `STATUS: READY_TO_IMPLEMENT`

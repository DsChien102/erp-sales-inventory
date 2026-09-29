# Work Slice — catalog, role, blocking

SSOT trạng thái design: **`CATALOG.md`** trong thư mục harness theo BJ (không `theme.manifest`).  
`design_status` **chỉ** trên catalog — không trên file slice.

**Spacing:** tối đa một dòng trống giữa block.  
**Fenced blocks:** chỉ source/config, directory tree, hoặc ASCII hiếm (ưu tiên Mermaid) — `documentation-standards.mdc` §17.  
**Không** User Story trong Trace. **Không invent** field/RPC/schema.

---

## Layout (flat)

```text
BJ-<id>-harness/
    CATALOG.md
    SL-001-<slug>.md
    SL-002-<slug>.be-contract.md
    SL-003-<slug>.be-impl.md
    SL-004-<slug>.fe.md
    SL-005-<slug>.e2e.md
```

- Flat — không group folder theo outcome; nhóm bằng metadata / cột **`family`**.
- File: `SL-NNN-<slug>.<role>.md` với `role` ∈ `{be-contract, be-impl, fe, e2e}`; **`full`** = không hậu tố role.
- Có UI → đủ 4 role (kể cả `.e2e`). Không UI → chỉ `full`.
- Mỗi file = **unique** `SL-id`.
- Order implement: `be-contract` → rồi `be-impl` ∥ `fe` → `e2e`.
- Path harness **không** hardcode trong skill — suy từ theme/context (vd. theme-07: `04.harness/`).

---

## Role enum

| Role | Khi nào | Phần giữa (giữa Objective và Verification) |
| --- | --- | --- |
| `full` | Không UI; một file đủ delivery | Scope, Flow, Design, Contracts |
| `be-contract` | Family có UI — contract trước | Scope contract; Contracts (Command/Query/DTO/port + fake); persistence N/A hoặc “impl owns” |
| `be-impl` | Sau contract | Persistence/RPC/txn/idempotency/errors; Contracts = **link** `.be-contract` |
| `fe` | Sau contract (∥ `be-impl`) | UI/screens/DS/mediator+fake; Contracts = link `.be-contract` |
| `e2e` | Sau impl + fe | Scenarios xuyên tầng + evidence; Design/Contracts = link family |

Xương chung mọi file:

1. Metadata YAML (`id`, `role`, `family`, `sources`, …)
2. Objective (1 câu)
3. **Blocked by** (bắt buộc) — link file slice và/hoặc GitLab `#N` / URL; `None` nếu frontier
4. Phần giữa theo role (bảng trên)
5. Verification (AC)
6. Delivery / DoD ngắn

---

## CATALOG.md schema

Bảng markdown. Cột tối thiểu:

| Cột | Ý nghĩa |
| --- | --- |
| `id` | `SL-NNN` unique |
| `title` | Tiêu đề ngắn |
| `path` | Relative tới thư mục harness BJ |
| `design_status` | xem dưới |
| `depends_on` | Danh sách `SL-id` (cùng catalog) |
| `sources` | Artifact ID (BJ/UC/BC/SCR/…) |
| `family` | Key nhóm role; `full` có thể để trống hoặc family riêng |
| `produces` / `coverage` | Output / phạm vi bao phủ dự kiến |
| `lanes` / `links` | Gợi ý lane hoặc link phụ |
| `blocked_reason` | **Bắt buộc** khi `BLOCKED`; ngược lại để trống |

`design_status` ∈:

| Status | Nghĩa |
| --- | --- |
| `DRAFT` | Đang viết |
| `IN_REVIEW` | Chờ review design |
| `READY_TO_IMPLEMENT` | Design xong; **mọi** `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED` |
| `BLOCKED` | Không scaffold/implement tiếp — bắt buộc `blocked_reason` |
| `VERIFIED` | Lane code xong + code-review sạch (`implement-work-slice` cập nhật) |

Không dùng `IMPLEMENTING` trên catalog. Tiến độ code không mirror vào `design_status` ngoài `VERIFIED`.

---

## Blocking & frontier

- **Blocked by** trên file slice = edges delivery (markdown link).
- **`depends_on` trên catalog** = gate `READY_TO_IMPLEMENT` / thứ tự implement.
- Frontier = slice không còn blocker chưa xong (catalog + Blocked by khớp).
- GitLab: Blocked by hỗ trợ `#N` / URL; **tạo issue** = bước riêng (không bắt buộc trong scaffold).

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

Query: Txn / Idempotency / Failure = `N/A — query-only`.

---

## Contracts (Command / Query / DTO)

Mỗi type = **H4** + **Dart fence** (không bảng field; không gom một dòng).

| Kind | Use-case dưới H4 |
| --- | --- |
| **Command** / **Query** | **Bắt buộc** blockquote 1–2 câu trước fence |
| **DTO** | Blockquote optional |

`be-impl` / `fe` / `e2e`: Contracts = link file `.be-contract` (hoặc family), không nhân bản schema.

---

## Doc guards (khi điền phần giữa)

- **Main Flow:** Mermaid khi mô tả được; ≤5 bước; không lặp cùng diagram ở Design.
- **Code Layout:** mỗi segment path một dòng; indent 4 space; fence `text` chỉ cho directory tree.
- **Business Rules:** bảng 2 cột; title link = ID.
- **Dependencies:** Blocked by + catalog `depends_on` phải khớp; link relative tới file slice cùng harness.
- **AC:** checklist `- [ ] **AC-0n**` — không bọc code block.

## Checklist trước READY_TO_IMPLEMENT (catalog)

- [ ] File đúng role + xương chung
- [ ] Field/RPC/schema khớp SRS hoặc deviation ghi rõ
- [ ] `Blocked by` đầy đủ; `depends_on` khớp catalog
- [ ] Mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`
- [ ] AC + `scn_*` (mutation: failure/idempotency)
- [ ] Open Questions không còn blocking
- [ ] Cập nhật hàng trên `CATALOG.md` (kèm `blocked_reason` nếu `BLOCKED`)

---
name: work-slice-scaffold
description: >-
  Scaffolds and reviews Work Slice documents with a fixed seven-section
  structure (Objective through Delivery) through READY_TO_IMPLEMENT. Use when
  the user asks to scaffold a work slice, create Sxx slice docs, Design-Driven
  design lane, READY_TO_IMPLEMENT, or TH-xx harness slices before coding.
---

# Work Slice scaffold (7 phần cố định)

## Mục đích

Một file Work Slice = **đơn vị delivery hoàn chỉnh**: business outcome + technical design + implementation boundary + acceptance.

1. Theme / BJ·UC (SRS)
2. Work Slice — `harness/slices/Sxx-<slug>.md` (7 sections)
3. Lanes — Contract → BE → FE → E2E

**Đọc:** [template.work-slice.md](template.work-slice.md) · [reference.md](reference.md)  
**Canonical theme template:** `docs/themes/TH-07-inventory-and-costing/harness/slices/template.work-slice.md`  
**Docs style:** `.cursor/rules/documentation-standards.mdc`

Coder implement **chỉ** khi `STATUS == READY_TO_IMPLEMENT`.  
`BLOCKED` = dừng mọi lane; metadata **bắt buộc** có `Blocked reason`.

---

## Rules (Codex)

> **A Work Slice is a self-contained delivery unit that defines one business outcome and contains everything required to implement and verify that outcome, including its technical design.**

> **Use the same seven-section structure for every Work Slice. Keep every section, but vary the depth of its content. Never add sections merely because a technical concern exists; place relevant technical details under Design (or Contracts).**

**Không** User Story trong Trace metadata — chỉ ghi key đúng loại có (`BJ:` / `CAP:` / `BJ / CAP:`; `UC:` / `OP:` / `UC / OP:`; `BC:` / `API:` / `BC / API:`).

---

## Bảy phần cố định

| § | Phần | Trả lời |
| --- | --- | --- |
| — | Metadata | STATUS (`DRAFT` / `IN_REVIEW` / `READY_TO_IMPLEMENT` / `BLOCKED`), Blocked reason (nếu BLOCKED), Slice, Wave, Theme, BJ/CAP, UC/OP, BC/API, lane |
| 1 | Objective | Outcome 1 câu (không Trace table) |
| 2 | Scope & Rules | In/Out, Boundary, Rules |
| 3 | Flow | Main + Failure (Mermaid khi có thể; **một** diagram workflow — không lặp ở Design) |
| 4 | Design | Domain Before/After (+ stateDiagram **chỉ nếu khác** Flow), App/Layout, Persistence, Txn, Idempotency, Errors |
| 5 | Dependencies & Contracts | Requires/Provides, fields, RPC, integration, dep table; mỗi Command/Query = H4 + **blockquote** use-case + Dart fence |
| 6 | Verification | AC checklist + `scn_*` |
| 7 | Delivery | DoD + Open Questions + Next Action |

---

## Khi nào dùng

- Scaffold / review Work Slice (`Sxx-*.md`)
- User nói Design-Driven, work slice, trước implement

**Không dùng** để viết Dart/SQL implementation hoặc promote migration.

---

## Ritual scaffold

1. Xác nhận theme harness + `Sxx` từ `04-slice-roadmap.md` (và private `ROADMAP.md` nếu có).
2. Copy `template.work-slice.md` → `docs/themes/<TH>/harness/slices/Sxx-<slug>.md`.
3. Điền đủ 7 phần; **variable depth** — query: Transaction/Idempotency/Failure = `N/A — query-only`.
4. Chi tiết field/RPC/schema từ SRS + `07-api-contracts.md` — **không invent**.
5. Draft SQL `_drafts/` khi Design cần persistence; cập nhật catalog API.
6. `STATUS: IN_REVIEW` → human review → `READY_TO_IMPLEMENT`; Design lane `done` trên roadmap. Nếu bị chặn → `BLOCKED` + `Blocked reason` trong metadata.
7. **Dừng** trước code trừ khi user yêu cầu implement.

---

## Hard rules (Vet45)

| Rule | Chi tiết |
| --- | --- |
| Facts vs commands | Outbox = past-tense facts; handoff = `integration_commands`. Không `*.requested` IE. |
| Idempotency | `idempotencyKey` ≠ `command.id`; UK `(tenant, scope, key)`; cùng txn business + outbox. |
| Schema | Chỉ `_drafts/` đến khi promote. Persistence: tên bảng → draft blockquote → **một** `erDiagram` (giữ quan hệ) → bảng field tách theo table. |
| Structure | Đúng 7 section cấp 1; technical nằm trong Design / Contracts. |
| Trace | Không User Story. |
| Main Flow | Mermaid khi có thể; tên đầy đủ; ≤5 bước; **không** lặp cùng diagram ở Design Domain. |
| AC | Checklist `- [ ] **AC-0n**` — không code block. |
| Contracts | Mỗi Command/Query/DTO = H4 + Dart fence; **Command/Query bắt buộc 1–2 câu trong blockquote** (`> …`) ngay dưới H4 trước fence — khi nào dùng; DTO blockquote optional; không bảng field; không gom một dòng dù ít field. |
| Doc feedback | Khi user chốt quy ước tài liệu Work Slice (“phải như thế này”) → cập nhật **SKILL.md + reference.md + theme `template.work-slice.md`** trong cùng thay đổi (không chỉ sửa một file slice). |
| Code Layout | Mỗi segment path một dòng; indent **4 space**; fence ` ```text ` **chỉ** cho directory tree; không `│`/`├─`. |
| Fenced blocks | Chỉ source/config, directory tree, hoặc ASCII hiếm (ưu tiên Mermaid). **Không** bọc prose / rules / txn list / Before–After để “highlight” — xem `documentation-standards.mdc` §17. |
| Business Rules | Bảng 2 cột; title link = ID. |
| Dependencies | Slice → link `Sxx-<slug>.md`; chưa có file → `04-slice-roadmap.md`. |
| Spacing | Tối đa một dòng trống giữa block. |
| Gate | Code chỉ khi `READY_TO_IMPLEMENT`. `BLOCKED` → không code; metadata phải có `Blocked reason`. |

---

## Variants

| Loại | Gợi ý |
| --- | --- |
| Foundation / tech | Objective = enablement; UC có thể N/A. |
| Query-only | Design Txn/Idempotency + Failure Flow = `N/A — query-only`. |
| Mutation | Design Txn + Idempotency + Failure đầy đủ. |

---

## Next Action sau skill

- Review 7 phần → `READY_TO_IMPLEMENT` → lane Contract/BE theo ritual theme

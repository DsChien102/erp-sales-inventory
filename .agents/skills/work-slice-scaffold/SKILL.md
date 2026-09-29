---
name: work-slice-scaffold
description: >-
  Scaffolds and reviews flat Work Slice files by role (full, be-contract,
  be-impl, fe, e2e) plus BJ harness CATALOG.md through READY_TO_IMPLEMENT. Use
  when the user asks to scaffold a work slice, create SL-NNN slice docs, Design
  Driven design lane, READY_TO_IMPLEMENT, or harness slices before coding.
---

# Work Slice scaffold (flat / role)

## Mục đích

Một file Work Slice = **một role delivery** (hoặc `full` khi không UI): objective + blocked-by + design theo role + AC.

1. Theme / BJ·UC (SRS)
2. `BJ-<id>-harness/` flat + `CATALOG.md` (SSOT `design_status`)
3. Implement theo frontier — skill `implement-work-slice` (hoặc Matt `/implement` cho một file)

**Bar B:** `READY_TO_IMPLEMENT` = agent implement **không invent / không hỏi** — fence contract kín, Code Layout theo role, FE state map, e2e scenario kín (chi tiết: [reference.md](reference.md)).

**Đọc:** [reference.md](reference.md) · [CATALOG.template.md](CATALOG.template.md) · templates `template.work-slice*.md`  
**Golden (bar B):** [examples/golden-family/](examples/golden-family/)  
**Canonical samples (skeleton):** `specs/themes/theme-template/04.harness/BJ-xx-harness/`  
**Docs style:** `.cursor/rules/documentation-standards.mdc`

Coder implement **chỉ** khi hàng catalog = `READY_TO_IMPLEMENT`.  
`BLOCKED` → dừng; catalog bắt buộc `blocked_reason`.

---

## Rules

> **A Work Slice is a self-contained delivery unit for one role (or full when no UI) that defines one outcome and everything required to implement and verify that role's slice.**

> **Shared skeleton; role-specific middle. Never invent field/RPC. design_status lives only on CATALOG.md.**

> **READY_TO_IMPLEMENT requires bar B for that role (see reference checklist).**

**Không** User Story trong Trace — chỉ key đúng loại (`BJ`/`CAP`, `UC`/`OP`, `BC`/`API`).

---

## Role → template

| Role | File template | Có UI? |
| --- | --- | --- |
| `full` | [template.work-slice.md](template.work-slice.md) | Không — một file |
| `be-contract` | [template.work-slice.be-contract.md](template.work-slice.be-contract.md) | Có — trước |
| `be-impl` | [template.work-slice.be-impl.md](template.work-slice.be-impl.md) | Có |
| `fe` | [template.work-slice.fe.md](template.work-slice.fe.md) | Có |
| `e2e` | [template.work-slice.e2e.md](template.work-slice.e2e.md) | Có — sau impl+fe |

Tên file: `SL-NNN-<slug>.md` (`full`) hoặc `SL-NNN-<slug>.<role>.md`. Unique `SL-id` mỗi file. Nhóm bằng `family`.

---

## Ritual scaffold

1. Xác nhận theme + BJ harness path (không hardcode; thường `<theme>/04.harness/BJ-<id>-harness/`). **Xong khi:** path harness + BJ id đã chốt với user.
2. Đảm bảo `CATALOG.md` tồn tại — copy [CATALOG.template.md](CATALOG.template.md) nếu thiếu. **Xong khi:** file có đủ cột schema ([reference.md](reference.md)).
3. Chọn role: không UI → `full`; có UI → đủ 4 file cùng `family`, id riêng. **Xong khi:** danh sách file + id đã liệt kê.
4. Copy template tương ứng → file flat trong harness BJ. **Xong khi:** path file tồn tại đúng tên `SL-NNN-<slug>[.<role>].md`.
5. Điền YAML + Objective + **Blocked by** + phần giữa theo role (gồm **Code Layout** / FE state map / e2e scenario khi áp dụng) + Verification + Delivery. **Xong khi:** không section bắt buộc nào trống (trừ N/A có ghi lý do).
6. Field/RPC chỉ từ SRS / contracts theme; Command/Query/DTO fence **đầy đủ field**. **Xong khi:** không type/field mới ngoài nguồn; thiếu → Open Questions, không `READY_TO_IMPLEMENT`.
7. Cập nhật hàng `CATALOG.md`. **Xong khi:** `depends_on`/`sources`/`family` khớp file; `READY_TO_IMPLEMENT` chỉ nếu mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED` **và** checklist bar B trong [reference.md](reference.md) đạt.
8. `DRAFT` → `IN_REVIEW` → human → `READY_TO_IMPLEMENT`; chặn → `BLOCKED` + `blocked_reason`. **Xong khi:** status catalog phản ánh review.
9. **Dừng** trước code trừ khi user gọi `implement-work-slice` / `/implement`.

Hard rules (facts/idempotency/contracts/catalog/Blocked by/fences/Code Layout): [reference.md](reference.md). User chốt quy ước docs → cập nhật **SKILL + reference + templates** cùng thay đổi.

---

## Khi nào dùng

- Scaffold / review Work Slice (`SL-*.md`) + catalog
- User nói Design-Driven, work slice, trước implement

**Không dùng** để viết Dart/SQL implementation hoặc promote migration → `implement-work-slice` / `/implement`.

---

## Next Action sau skill

- Review → catalog `READY_TO_IMPLEMENT` → `/implement-work-slice` theo `family` (hoặc `/implement` một path)

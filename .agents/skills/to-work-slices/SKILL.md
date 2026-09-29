---
name: to-work-slices
description: >-
  Break a theme BJ/SRS (or conversation) into Work Slice families with blocking
  edges, quiz the user, then publish SL files + CATALOG.md at IN_REVIEW under
  the BJ harness. Does not set READY_TO_IMPLEMENT — that is review-work-slices.
disable-model-invocation: true
---

# To Work Slices

Break a plan, BJ/SRS, or conversation into **Work Slice families**: tracer-bullet delivery units (role-scoped, or `full` when no UI), each declaring **Blocked by** edges, published into the BJ harness.

**Pipeline:** `/to-work-slices` → `/review-work-slices` → `/implement-work-slice`.  
**READY** chỉ qua `/review-work-slices` (kể cả khi nội dung đã gần kín bar B).

**SSOT shape / bar B / catalog:** [reference.md](reference.md) · templates `template.work-slice*.md` · [CATALOG.template.md](CATALOG.template.md)  
**Golden (bar B):** [examples/golden-family/](examples/golden-family/)  
**Skeleton sample:** `specs/themes/theme-template/04.harness/BJ-xx-harness/`  
**Docs style:** `.cursor/rules/documentation-standards.mdc`

## Rules

> **A Work Slice is a self-contained delivery unit for one role (or full when no UI) that defines one outcome and everything required to implement and verify that role's slice.**

> **Quiz by family/outcome, not by each role file. Publish catalog status = IN_REVIEW only. Never invent field/RPC. design_status lives only on CATALOG.md.**

> **Wide refactor / expand–contract is out of scope here — use `/to-tickets` (or a separate lane), not this harness.**

**Không** User Story trong Trace — chỉ key đúng loại (`BJ`/`CAP`, `UC`/`OP`, `BC`/`API`).

## Role → template

| Role | File template | Có UI? |
| --- | --- | --- |
| `full` | [template.work-slice.md](template.work-slice.md) | Không — một file |
| `be-contract` | [template.work-slice.be-contract.md](template.work-slice.be-contract.md) | Có — trước |
| `be-impl` | [template.work-slice.be-impl.md](template.work-slice.be-impl.md) | Có |
| `fe` | [template.work-slice.fe.md](template.work-slice.fe.md) | Có |
| `e2e` | [template.work-slice.e2e.md](template.work-slice.e2e.md) | Có — sau impl+fe |

Tên file: `SL-NNN-<slug>.md` (`full`) hoặc `SL-NNN-<slug>.<role>.md`. Unique `SL-id` mỗi file. Nhóm bằng `family`. Có UI → đủ 4 role cùng `family`; không UI → `full`.

## Process

### 1. Gather context

Làm việc từ context hội thoại. Nếu user truyền path BJ/SRS/theme hoặc issue URL, đọc đủ body (và comments nếu có).

**Xong khi:** đã xác định theme + BJ id + path harness mục tiêu (không hardcode; thường `<theme>/04.harness/BJ-<id>-harness/`).

### 2. Explore the codebase (optional)

Nếu chưa explore: vocabulary domain, ADR khu vực chạm, trạng thái module. Prefactor rõ → đề xuất thành **family riêng** trên quiz list (không nhét widen-refactor vào work-slice).

**Xong khi:** đủ để đặt tên/slug theo glossary, hoặc đã bỏ qua vì context đã đủ.

### 3. Draft families

Cắt việc thành **families** (tracer delivery), không list từng role như ticket riêng.

Với mỗi family đề xuất:

- **Title** / `family` key
- **Roles** sẽ tạo: `full` **hoặc** `be-contract` + `be-impl` + `fe` + `e2e`
- **Blocked by:** families (hoặc SL) phải xong trước
- **What it delivers:** outcome end-to-end (góc user / verify được)
- **Sources:** BJ/UC/BC/… từ SRS

Hard rules shape: [reference.md](reference.md). Field/RPC chỉ từ SRS — thiếu → Open Questions trên slice, không giả invent.

### 4. Quiz the user

Trình breakdown **theo family** (numbered). Hỏi:

- Granularity: quá thô / quá mảnh?
- Blocking edges đúng chưa?
- Merge / split family nào?
- `full` vs 4-role đúng với có/không UI?

Lặp đến khi user **approve** breakdown. **Chưa ghi file** trước approve.

### 5. Publish to BJ harness

Sau approve:

1. Đảm bảo `CATALOG.md` tồn tại — copy [CATALOG.template.md](CATALOG.template.md) nếu thiếu.
2. Copy template → file flat; điền **tối đa** từ SRS (YAML, Objective, Blocked by, phần giữa theo role, Verification) khi nguồn đủ; lỗ hổng để rõ ràng cho `/review-work-slices`.
3. Cập nhật hàng catalog: `depends_on` / `sources` / `family` khớp file; **`design_status = IN_REVIEW`** cho mọi slice vừa publish (không `READY_TO_IMPLEMENT`, không `DRAFT` trừ khi user yêu cầu rõ giữ draft).
4. **Dừng.** Next: `/review-work-slices` — rồi mới `/implement-work-slice`.

**Xong khi:** path file đúng `SL-NNN-<slug>[.<role>].md`, catalog `IN_REVIEW`, không còn section bắt buộc trống mà không ghi lý do/`TBD`.

## Khi nào dùng

- Cắt BJ/SRS thành Work Slice families + publish harness
- User nói Design-Driven breakdown, work slices, trước review/implement

**Không dùng** để nâng `READY_TO_IMPLEMENT` → `/review-work-slices`.  
**Không dùng** để viết Dart/SQL → `/implement-work-slice` / `/implement`.

## Next Action

User approve design → `/review-work-slices` (checklist bar B + OK READY) → `/implement-work-slice` theo `family`.

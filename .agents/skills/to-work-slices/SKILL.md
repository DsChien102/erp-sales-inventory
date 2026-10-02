---
name: to-work-slices
description: >-
  Break a theme BJ/SRS (or conversation) into vertical Work Slices, one outcome
  per file, with blocking edges. Quiz the user, then publish SL files and
  CATALOG.md at IN_REVIEW. Does not set READY_TO_IMPLEMENT — that is
  review-work-slices.
disable-model-invocation: true
---

# To Work Slices

Cắt plan, BJ/SRS, hoặc hội thoại thành **Work Slice dọc**: một outcome, một file, mọi thứ để implement và kiểm outcome đó. Mỗi slice khai **Blocked by**.

**Pipeline:** `/to-work-slices` → `/review-work-slices` → `/implement-work-slice`.
**READY** chỉ qua `/review-work-slices`.

**Shape / bar B / catalog:** [reference.md](reference.md) · [template.work-slice.md](template.work-slice.md) · [CATALOG.template.md](CATALOG.template.md)
**Golden:** [examples/golden-family/](examples/golden-family/)
**Skeleton:** `specs/themes/theme-template/04.harness/BJ-xx-harness/`
**Docs style:** `.cursor/rules/documentation-standards.mdc`

## Rules

> **Một Work Slice là một outcome kiểm được, trong một file, gồm đúng các mục heading mà outcome đó cần để implement và verify.**

> **Quiz theo outcome. Publish `design_status = IN_REVIEW` trên CATALOG.md. Field/RPC lấy từ SRS.**

> **Refactor rộng / expand–contract dùng `/to-tickets`, không dùng harness này.**

Trace trong YAML: `BJ`/`CAP`, `UC`/`OP`, `BC`/`API`. Không thêm User Story.

## Process

### 1. Gather context

Đọc body BJ/SRS/theme hoặc issue user đưa, kể cả comment nếu có URL.

**Xong khi:** đã có theme, BJ id, và path harness (thường `<theme>/04.harness/BJ-<id>-harness/`).

### 2. Explore the codebase (optional)

Khi cần: vocabulary domain, ADR khu vực chạm, trạng thái module. Prefactor tách thành outcome riêng trên danh sách quiz.

**Xong khi:** đủ để đặt slug theo glossary, hoặc context đã đủ nên bỏ qua.

### 3. Draft outcomes

Mỗi outcome đề xuất:

- **Title** / slug
- **Heading có mặt:** Flow, Design, Contracts, Presentation — theo cò trong [reference.md](reference.md). Presentation có khi outcome có màn hình
- **Blocked by:** outcome (SL) phải xong trước
- **What it delivers:** outcome kiểm được
- **Sources:** BJ/UC/BC/… từ SRS

Field/RPC chỉ từ SRS. Thiếu thì Open Questions trên slice.

### 4. Quiz the user

Trình breakdown theo outcome (đánh số). Hỏi:

- Grain: thô hơn một outcome hiện tại, hay mỏng hơn?
- Cạnh Blocked by đúng chưa?
- Gộp hay tách outcome nào?
- Presentation có trong scope không?

Lặp đến khi user **approve**. Chưa ghi file trước approve.

### 5. Publish to BJ harness

Sau approve:

1. Đảm bảo `CATALOG.md` — copy [CATALOG.template.md](CATALOG.template.md) nếu thiếu.
2. Copy [template.work-slice.md](template.work-slice.md) thành `SL-NNN-<slug>.md`. Điền từ SRS. Xóa H2 optional ngoài scope và ghi tên chúng vào Out of Scope.
3. Catalog: `depends_on` và `sources` trong YAML khớp file. Mọi slice vừa publish = `IN_REVIEW`.
4. **Dừng.** Tiếp: `/review-work-slices`.

**Xong khi:** mỗi outcome một file `SL-NNN-<slug>.md`, catalog `IN_REVIEW`, mục bắt buộc có nội dung hoặc lý do còn thiếu nằm ở Open Questions.

## Khi nào dùng

- Cắt BJ/SRS thành Work Slice và publish harness
- User nói Design-Driven breakdown, work slices, trước review/implement

**READY** là việc của `/review-work-slices`.
**Dart/SQL** là việc của `/implement-work-slice`.

## Next Action

User approve design → `/review-work-slices` → `/implement-work-slice` theo từng outcome `READY_TO_IMPLEMENT`.

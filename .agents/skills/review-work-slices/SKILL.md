---
name: review-work-slices
description: >-
  Author the technical contract of IN_REVIEW Work Slices from architecture
  and the current codebase, check business flow against SRS, run bar B, and
  after user confirmation set CATALOG design_status to READY_TO_IMPLEMENT
  (or BLOCKED). The only path that may set READY.
disable-model-invocation: true
---

# Review Work Slices

Làm kín Work Slice `IN_REVIEW`: ghi technical contract từ kiến trúc và code hiện tại, đối chiếu luồng với SRS, chạy checklist **bar B**, rồi sau **user OK** ghi catalog `READY_TO_IMPLEMENT` hoặc `BLOCKED` kèm `blocked_reason`.

**Pipeline:** `/to-work-slices` → **`/review-work-slices`** → `/implement-work-slice`.
Đây là cửa duy nhất được ghi `READY_TO_IMPLEMENT`.

**SSOT:** [reference.md](../to-work-slices/reference.md)
**Golden:** [examples/golden-family/](../to-work-slices/examples/golden-family/)
**Template:** [template.work-slice.md](../to-work-slices/template.work-slice.md)

## Bound

- SRS khóa luồng nghiệp vụ. Slice khóa technical contract. Chạy bar B, rồi sau user OK chuyển `IN_REVIEW` → `READY_TO_IMPLEMENT`, hoặc `BLOCKED` kèm `blocked_reason`.
- Cắt lại outcome là việc của `/to-work-slices`.
- Dart/SQL và promote migration là việc của `/implement-work-slice`.
- Không bịa hành vi SRS chưa khóa. Không sửa SRS.
- Fork hành vi hoặc seam: ghi Open Questions rồi dừng, bảo chạy `/unblock-work-slice`.
- Phụ thuộc ngoài slice: đề xuất `BLOCKED`.

## Process

### 1. Gather scope

Input: path `CATALOG.md`, và/hoặc list `SL-*`. Mặc định: mọi hàng `IN_REVIEW` user nêu.

**Xong khi:** danh sách file và hàng catalog đã liệt kê.

### 2. Read the slice's concerns

Trước khi ghi contract, với từng slice, đọc đúng concern nó đụng:

| Concern | Đọc |
| --- | --- |
| Mutation | [vet45-idempotency-and-commands.mdc](../../../.cursor/rules/vet45-idempotency-and-commands.mdc) |
| Integration | [vet45-integration-events.mdc](../../../.cursor/rules/vet45-integration-events.mdc) |
| File mới | [vet45-architecture.mdc](../../../.cursor/rules/vet45-architecture.mdc) và layout `modules/iam/` |
| Persistence | `supabase/schema.lock.yaml` và SQL declarative của schema đó |
| Code Layout nêu module và module tồn tại | Thư mục module đó |

**Xong khi:** đã đối chiếu nguồn của từng concern slice đụng.

### 3. Write the technical contract

Đối chiếu luồng với SRS. Ghi Design, Contracts, và các mục còn thiếu theo [reference.md](../to-work-slices/reference.md).

- Rule hoặc code chỉ có một cách đúng: ghi thẳng vào Design hoặc Contracts.
- SRS im về tên kỹ thuật, rule và code không ép một đáp án: chọn và ghi. Không hỏi.
- Đụng seam đang có: một dòng ngay dưới H3 liên quan. Dùng lại, hoặc từ chối seam đó.
- Hai cách hợp lệ mà đổi hành vi SRS chưa khóa, hoặc dùng lại seam hay tạo mới: một Open Question, nêu cả hai nguồn. Chưa `READY`.
- SRS trái hard rule: Open Question nêu cả hai nguồn. Không sửa SRS.
- SRS chưa khóa luồng nghiệp vụ: không bịa. Open Question, hoặc đề xuất `BLOCKED` khi phụ thuộc ngoài slice.
- Open Question chỉ nói SRS chưa có tên RPC, bảng, hoặc mã lỗi: thay bằng quyết định trong slice và xóa câu đó.

Open Questions là H2 cuối, sau Verification. Hết câu thì xóa H2 đó.

**Xong khi:** technical contract đủ theo tối thiểu Heading, hoặc lỗ còn lại là Open Question hay đề xuất `BLOCKED`.

### 4. Run bar B checklist

Chạy checklist trong [reference.md](../to-work-slices/reference.md) cho từng slice. `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED` trước khi slice này READY.

**Xong khi:** pass/fail từng mục đã báo, kèm chỗ thiếu.

### 5. Propose READY (or BLOCKED)

- Checklist xanh → hỏi: **OK đặt `READY_TO_IMPLEMENT`?**
- Còn Open Question chặn (hành vi chưa khóa, hoặc fork seam): dừng và bảo chạy `/unblock-work-slice` trên đúng slice.
- Phụ thuộc ngoài slice: đề xuất `BLOCKED` kèm `blocked_reason`.

Chưa sửa catalog sang READY trước câu trả lời user.

### 6. Write catalog status

Sau user OK:

- Checklist pass → `design_status = READY_TO_IMPLEMENT`
- User chọn chặn → `BLOCKED` và `blocked_reason`

**Xong khi:** `CATALOG.md` khớp status đã chốt.

## Next Action

Hàng `READY_TO_IMPLEMENT` → `/implement-work-slice`. Gate bar B chạy lại lúc implement.

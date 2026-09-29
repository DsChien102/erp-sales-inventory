---
name: review-work-slices
description: >-
  Fill gaps in IN_REVIEW vertical Work Slices against SRS, run the bar B
  checklist, and after user confirmation set CATALOG design_status to
  READY_TO_IMPLEMENT (or BLOCKED). The only path that may set READY.
disable-model-invocation: true
---

# Review Work Slices

Làm kín Work Slice `IN_REVIEW`, chạy checklist **bar B**, rồi sau **user OK** ghi catalog `READY_TO_IMPLEMENT` hoặc `BLOCKED` kèm `blocked_reason`.

**Pipeline:** `/to-work-slices` → **`/review-work-slices`** → `/implement-work-slice`.
Đây là cửa duy nhất được ghi `READY_TO_IMPLEMENT`.

**SSOT:** [reference.md](../to-work-slices/reference.md)
**Golden:** [examples/golden-family/](../to-work-slices/examples/golden-family/)
**Template:** [template.work-slice.md](../to-work-slices/template.work-slice.md)

## Bound

- Điền nội dung SL từ SRS, chạy bar B, và sau user OK chuyển `IN_REVIEW` → `READY_TO_IMPLEMENT`, hoặc `BLOCKED` kèm `blocked_reason`.
- Cắt lại outcome là việc của `/to-work-slices`.
- Dart/SQL và promote migration là việc của `/implement-work-slice`.
- Checklist fail thì báo thiếu gì. Có thể `BLOCKED` khi SRS không đủ để làm kín trong slice.

## Process

### 1. Gather scope

Input: path `CATALOG.md`, và/hoặc list `SL-*`. Mặc định: mọi hàng `IN_REVIEW` user nêu.

**Xong khi:** danh sách file và hàng catalog đã liệt kê.

### 2. Fill gaps

Đối chiếu từng slice với SRS. Điền fence, Code Layout, State × feedback, Scenarios theo [reference.md](../to-work-slices/reference.md). Field/RPC lấy từ SRS. Thiếu nguồn thì Open Questions hoặc đề xuất `BLOCKED`.

**Xong khi:** lỗ bar B nào SRS trả lời được thì đã điền. Phần còn thiếu nằm ở Open Questions hoặc đề xuất blocked.

### 3. Run bar B checklist

Chạy checklist trong [reference.md](../to-work-slices/reference.md) cho từng slice. `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED` trước khi slice này READY.

**Xong khi:** pass/fail từng mục đã báo, kèm chỗ thiếu.

### 4. Propose READY (or BLOCKED)

- Checklist xanh → hỏi: **OK đặt `READY_TO_IMPLEMENT`?**
- Fail không sửa được trong lượt → đề xuất `BLOCKED` kèm `blocked_reason`, hoặc dừng để user bổ sung SRS.

Chưa sửa catalog sang READY trước câu trả lời user.

### 5. Write catalog status

Sau user OK:

- Checklist pass → `design_status = READY_TO_IMPLEMENT`
- User chọn chặn → `BLOCKED` và `blocked_reason`

**Xong khi:** `CATALOG.md` khớp status đã chốt.

## Next Action

Hàng `READY_TO_IMPLEMENT` → `/implement-work-slice`. Gate bar B chạy lại lúc implement.

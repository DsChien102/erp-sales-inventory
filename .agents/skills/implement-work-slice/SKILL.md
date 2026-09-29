---
name: implement-work-slice
description: "Implement one vertical Work Slice from a BJ harness CATALOG (one outcome, one commit, VERIFIED)."
disable-model-invocation: true
---

# Implement Work Slice

Implement từng Work Slice đã `READY_TO_IMPLEMENT`. Một outcome, một lượt, một commit. Nghi thức Matt `/implement` giữ nguyên — không sửa `.agents/skills/implement/SKILL.md`.

## Input

- Path `CATALOG.md` / harness BJ và các `SL-id` trong scope, hoặc
- Một path `SL-*.md`

## Ritual

1. Đọc `CATALOG.md` và file slice. Chỉ lấy hàng `design_status == READY_TO_IMPLEMENT` mà mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`. **Xong khi:** danh sách outcome và thứ tự `depends_on` đã viết ra.
2. **Gate bar B:** đối chiếu checklist trong [reference.md](../to-work-slices/reference.md). Thiếu mục thì dừng, báo thiếu, không code. **Xong khi:** mọi slice in-scope đạt checklist, hoặc đã dừng.
3. Trong một outcome, làm theo thứ tự nội bộ: surface Contracts, rồi persistence và domain, rồi Presentation, rồi test trong Verification. **Xong khi:** thứ tự đó nằm trong một lượt của outcome.
4. Với từng outcome:
   - Nghi thức `.agents/skills/implement/SKILL.md`: `/tdd` tại seam đã chốt, typecheck, test liên quan, full suite cuối outcome, `/code-review`, **một commit** cho cả outcome.
   - Field/RPC lấy từ slice và SRS. File mới nằm trong Code Layout.
   - **Xong khi:** AC và `scn_*` của outcome xanh, code-review không còn finding chặn, một commit trên branch.
5. Cập nhật hàng catalog → `VERIFIED`. **Xong khi:** `CATALOG.md` ghi `VERIFIED` cho `id` vừa xong.
6. Lặp outcome tiếp theo trong scope. **Xong khi:** không còn hàng in-scope ở `READY_TO_IMPLEMENT`, hoặc user dừng scope.

## Bound

- Matt skills (`implement`, `to-spec`, `to-tickets`, `grilling`, …) giữ nguyên.
- Catalog không có status `IMPLEMENTING`.
- Hàng `BLOCKED`: bỏ qua và báo `blocked_reason`.
- Catalog READY nhưng fail bar B: dừng, chuyển `/review-work-slices`.
- Scope vượt harness: dừng và xác nhận với user.
- Golden [examples/golden-family/](../to-work-slices/examples/golden-family/) là `EXAMPLE_ONLY`.
- `READY_TO_IMPLEMENT` chỉ hợp lệ sau `/review-work-slices`.

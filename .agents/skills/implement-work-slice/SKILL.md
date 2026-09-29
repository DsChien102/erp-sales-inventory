---
name: implement-work-slice
description: "Implement a Work Slice family from BJ harness CATALOG (role order, Matt implement ritual, VERIFIED)."
disable-model-invocation: true
---

# Implement Work Slice

Implement các file Work Slice đã `READY_TO_IMPLEMENT` theo **family** (hoặc một path nếu user chỉ định), dùng cùng nghi thức Matt `/implement` **mà không sửa** `.agents/skills/implement/SKILL.md`.

## Input

- `family` (+ path tới `CATALOG.md` / harness BJ), hoặc
- một path file `SL-*.md` (delegate như `/implement` đơn lẻ)

## Ritual

1. Đọc `CATALOG.md` + file slice liên quan. Chỉ lấy hàng `design_status == READY_TO_IMPLEMENT` (và `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`). **Xong khi:** có danh sách slice in-scope + thứ tự dự kiến.
2. **Gate bar B** (dù catalog ghi READY): đối chiếu checklist trong `.agents/skills/to-work-slices/reference.md` § Checklist trước READY_TO_IMPLEMENT. Thiếu bất kỳ mục nào theo role → **từ chối implement**, báo thiếu gì, không code. **Xong khi:** mọi slice in-scope pass checklist, hoặc đã dừng và báo thiếu.
3. Sắp thứ tự trong family: `be-contract` → rồi `be-impl` rồi `fe` (hoặc `fe` rồi `be-impl` nếu cả hai unblocked — **tuần tự** mặc định; subagent song song chỉ khi user yêu cầu) → `e2e`. `full` = một bước. **Xong khi:** queue implement đã viết ra (và user OK nếu đổi thứ tự impl∥fe).
4. Với **từng** slice trong thứ tự:
   - Làm đúng nghi thức `.agents/skills/implement/SKILL.md`: `/tdd` tại seam đã chốt, typecheck đều, test file liên quan, full suite một lần cuối slice (hoặc cuối family nếu user gom), rồi `/code-review`, rồi **commit** lên branch hiện tại.
   - Không invent field/RPC ngoài slice/SRS; bám Code Layout đã ghi.
   - **Xong khi:** AC/`scn_*` của slice xanh (hoặc N/A đã ghi), code-review không còn finding chặn, commit có trên branch.
5. Cập nhật hàng catalog → `VERIFIED`. **Xong khi:** `git diff`/`CATALOG.md` hiện `VERIFIED` cho `id` vừa xong.
6. Lặp frontier còn lại trong family / scope user đã chốt. **Xong khi:** không còn hàng in-scope ở `READY_TO_IMPLEMENT`, hoặc user dừng scope.

## Bound

- Không sửa Matt skills (`implement`, `to-spec`, `to-tickets`, `grilling`, …).
- Không đổi `design_status` sang `IMPLEMENTING`.
- `BLOCKED` trên catalog → bỏ qua slice đó; báo `blocked_reason`.
- Catalog READY nhưng **fail bar B gate** → không implement; yêu cầu `/review-work-slices` (hoặc `/to-work-slices` nếu thiếu file role).
- Scope vượt harness/slice → dừng và xác nhận lại với user.
- Golden fixture `.agents/skills/to-work-slices/examples/golden-family/` là EXAMPLE_ONLY — không implement như module production trừ khi user yêu cầu rõ.
- `READY_TO_IMPLEMENT` chỉ hợp lệ nếu đã qua `/review-work-slices` (cửa duy nhất set READY).

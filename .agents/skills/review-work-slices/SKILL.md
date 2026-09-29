---
name: review-work-slices
description: >-
  Fill gaps in IN_REVIEW Work Slice files against SRS, run the bar B checklist,
  and after user confirmation set CATALOG design_status to READY_TO_IMPLEMENT
  (or BLOCKED). The only path that may set READY.
disable-model-invocation: true
---

# Review Work Slices

Làm kín brief Work Slice đã publish (`IN_REVIEW`), chạy checklist **bar B**, rồi — chỉ sau **user OK** — ghi catalog `READY_TO_IMPLEMENT` (hoặc `BLOCKED` + `blocked_reason`).

**Pipeline:** `/to-work-slices` → **`/review-work-slices`** → `/implement-work-slice`.  
Đây là **cửa duy nhất** được phép set `READY_TO_IMPLEMENT` (kể cả khi `/to-work-slices` đã điền gần đủ).

**SSOT checklist / shape:** [.agents/skills/to-work-slices/reference.md](../to-work-slices/reference.md)  
**Golden:** [.agents/skills/to-work-slices/examples/golden-family/](../to-work-slices/examples/golden-family/)  
**Templates (không đổi shape ở đây):** `.agents/skills/to-work-slices/template.work-slice*.md`

## Bound

- **Được:** điền/chỉnh nội dung SL từ SRS; chạy checklist bar B; cập nhật catalog `IN_REVIEW` → `READY_TO_IMPLEMENT` sau user OK; hoặc `BLOCKED` + `blocked_reason`.
- **Không:** quiz/cắt lại families (đó là `/to-work-slices`).
- **Không:** tạo file role còn thiếu trong family — bảo user chạy lại `/to-work-slices` (re-quiz/merge).
- **Không:** implement Dart/SQL / promote migration → `/implement-work-slice`.
- **Không:** set READY nếu checklist fail, dù user muốn “cho qua” — báo thiếu gì; có thể `BLOCKED` nếu không giải được trong slice.

## Process

### 1. Gather scope

Input: path `CATALOG.md` / harness BJ, và/hoặc `family`, và/hoặc list `SL-*`. Mặc định: mọi hàng `IN_REVIEW` in-scope user nêu.

**Xong khi:** danh sách file + hàng catalog cần review đã liệt kê.

### 2. Fill gaps

Đối chiếu từng slice với SRS/contracts theme. Điền fence, Code Layout, FE state map, e2e G/W/T, v.v. theo role — chi tiết [reference.md](../to-work-slices/reference.md). Không invent field/RPC; thiếu nguồn → Open Questions hoặc đề xuất `BLOCKED`.

**Xong khi:** không còn lỗ hổng bar B mà SRS đã có thể trả lời; phần còn thiếu đã ghi Open Questions / blocked.

### 3. Run bar B checklist

Chạy § Checklist trước READY_TO_IMPLEMENT trong [reference.md](../to-work-slices/reference.md) cho từng slice in-scope. `depends_on` phải đã `READY_TO_IMPLEMENT` hoặc `VERIFIED` trước khi slice này READY.

**Xong khi:** pass/fail từng mục đã báo rõ (kèm path thiếu gì).

### 4. Propose READY (or BLOCKED)

Trình kết quả cho user:

- Checklist xanh → hỏi xác nhận: **OK đặt `READY_TO_IMPLEMENT`?**
- Fail không sửa được trong lượt → đề xuất `BLOCKED` + `blocked_reason`, hoặc dừng để user bổ sung SRS.

**Chưa sửa catalog READY** trước câu trả lời user.

### 5. Write catalog status

Sau user OK:

- Checklist pass → `design_status = READY_TO_IMPLEMENT`
- User chọn chặn → `BLOCKED` + `blocked_reason` bắt buộc

**Xong khi:** `CATALOG.md` phản ánh status đã chốt; git diff hiện đúng các `id` in-scope.

## Next Action

Hàng `READY_TO_IMPLEMENT` → `/implement-work-slice` theo `family` (gate bar B vẫn chạy lại khi implement).

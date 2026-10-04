---
name: unblock-work-slice
description: >-
  Unblock one IN_REVIEW Work Slice by asking the user only the Open Questions
  review already wrote (unlocked business flow, or reuse an existing seam
  versus a new one), writing the answers into the slice, and sending it back
  to /review-work-slices.
disable-model-invocation: true
---

# Unblock Work Slice

Gỡ các lỗ bar B khiến một Work Slice `IN_REVIEW` chưa để `/review-work-slices` ghi `READY_TO_IMPLEMENT`. Hỏi Open Question mà review đã ghi, ghi vào slice sau khi user OK, rồi trả slice về review. Tên kỹ thuật không có fork thì trả về review để ghi, không hỏi.

**Nhánh:** `/review-work-slices` còn lỗ Quyết định hoặc Chặn → **`/unblock-work-slice`** → `/review-work-slices`.
**SSOT hình slice và checklist:** [reference.md](../to-work-slices/reference.md)

## Bound

- Một slice `IN_REVIEW` mỗi lần.
- Ghi nội dung slice sau câu **Ghi vào slice?**
- `design_status` là việc của `/review-work-slices`.
- Sửa SRS là việc ngoài skill này. Chỗ lệch ghi trên slice, cạnh field hoặc rule.
- Cắt, gộp, tách outcome là việc của `/to-work-slices`.
- Dart/SQL là việc của `/implement-work-slice`.

## Process

### 1. Gather one slice

Input: path `SL-*.md`, hoặc một `SL-id` cùng path `CATALOG.md`. Catalog có nhiều hàng `IN_REVIEW` mà chưa chỉ slice thì hỏi chọn một hàng, rồi mới phân loại.

Đọc hàng catalog.

- `IN_REVIEW` → tiếp.
- `DRAFT` → dừng, trỏ `/to-work-slices`.
- `BLOCKED` hoặc `READY_TO_IMPLEMENT` → dừng. Skill này chỉ nhận `IN_REVIEW`.

**Xong khi:** một file slice và một hàng `IN_REVIEW` đã xác định.

### 2. Classify holes

Đọc slice, nguồn trong YAML `sources`, và checklist bar B trong [reference.md](../to-work-slices/reference.md). Mỗi mục checklist fail thuộc đúng một lớp:

| Lớp | Khi | Việc |
| --- | --- | --- |
| Điền | Hành vi SRS đã khóa mà slice chưa chép | Đưa vào danh sách sẽ ghi. Không hỏi. |
| Trả review | Tên kỹ thuật SRS im, không đụng seam, không đổi hành vi | Không hỏi. Báo chạy lại `/review-work-slices` để ghi contract. |
| Chờ | `depends_on` chưa `READY_TO_IMPLEMENT` hoặc `VERIFIED` | Báo trong phân loại. Không hỏi bỏ cổng. |
| Quyết định | Open Question review đã ghi: luồng SRS chưa khóa, hoặc dùng lại seam hay tạo mới | Hỏi. |
| Chặn | Phụ thuộc ngoài slice, hoặc không đủ nguồn để chọn một phương án | Đề xuất một câu `blocked_reason`, hỏi user xác nhận. |

User bác một mục Điền thì chuyển mục đó sang Quyết định và hỏi.

Đưa bảng phân loại cho user trước vòng hỏi: mục Điền sẽ ghi, mục Trả review, mục Chờ, và frontier Quyết định cùng Chặn.

Chỉ còn lớp Trả review: không phỏng vấn, sang handoff.

**Xong khi:** mọi mục checklist fail có đúng một lớp, và bảng đó đã đưa ra.

### 3. Interview

Hỏi theo vòng. Mỗi vòng là cả frontier: câu nào phụ thuộc câu chưa trả lời thì để vòng sau. Chỉ hỏi lớp Quyết định và Chặn, và chỉ lỗ còn chặn READY.

Mỗi câu đánh số và có đáp án đề xuất, kèm path cùng heading nguồn. Hết nguồn để chọn thì đáp án đề xuất là Chặn, kèm một câu `blocked_reason`.

Câu trả lời là tách, gộp, hoặc cắt lại outcome: dừng, trỏ `/to-work-slices`. File slice giữ bản lúc gather.

**Xong khi:** mỗi lỗ Quyết định và Chặn có kết cục trong danh sách sẽ ghi, và file slice trên đĩa vẫn là bản lúc gather. Hoặc đã dừng vì cắt outcome.

### 4. Confirm the write

Danh sách ghi gồm mục Điền, quyết định đã chốt, và câu Chặn.

- Quyết định ghi vào heading sẵn có mà lỗ đó thuộc về. Open Question tương ứng ra khỏi slice khi nội dung đã nằm ở heading đó.
- Câu Chặn nằm ở H2 Open Questions cuối file, sau Verification, viết thành một câu `blocked_reason` để review chép lên catalog. Slice chưa có H2 đó thì thêm. Hết câu thì xóa H2.
- Lệch SRS ghi cạnh field hoặc rule.
- Open Question không chặn READY giữ nguyên.

Danh sách trống → sang handoff.

Danh sách có mục → hỏi: **Ghi vào slice?**

**Xong khi:** user đã trả lời ghi, hoặc danh sách trống, hoặc user dừng trước câu trả lời.

### 5. Write the slice

Sau câu trả lời ghi: sửa đúng danh sách đã OK trên file slice.

**Xong khi:** file slice khớp danh sách đã OK, và hàng catalog còn status lúc gather.

### 6. Hand off

Bảo chạy lại `/review-work-slices` trên slice này. Còn câu Chặn thì nói review hỏi user trước khi ghi `BLOCKED` và `blocked_reason`. Còn lớp Chờ thì nói slice ở `IN_REVIEW` tới khi mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`.

**Xong khi:** handoff đã gửi.

## Next Action

`/review-work-slices` trên cùng slice.

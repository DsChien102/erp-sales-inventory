---
id: SL-XXX
type: slice
theme: <theme-xx>
title: <Tên thay đổi>
owner: <Người chịu trách nhiệm giao việc>
contributors: [BA, SA, SE, QA]
status: DRAFT
---

# SL-XXX — <Tên thay đổi>

<!-- Một loại Slice chung, phân theo phạm vi thay đổi, không theo vai trò.
Giữ đủ 7 phần; độ sâu tùy phạm vi. Slice dẫn nguồn, không sao chép quy tắc chuẩn.
Thiết kế kỹ thuật cục bộ nằm ở phần 4/5; quy tắc dùng chung nằm trong Domain hoặc
Technical Contract. Không tự tạo field/RPC/schema khi nguồn chưa chốt.
Trạng thái: DRAFT → IN_REVIEW → READY_TO_IMPLEMENT → IMPLEMENTING → VERIFIED.
BLOCKED phải có blocked_reason trong metadata. Chỉ triển khai sau READY_TO_IMPLEMENT. -->

**Nguồn:** <BJ/CAP, UC/OP, BC/API, Screen, Domain, Technical Contract — ID và link>.
**Phạm vi bao phủ:** <UC ID + Flow/Scenario; Screen/state/action; thay đổi Domain nếu có>.
**Chưa bao phủ:** <Phần còn lại và nơi tiếp nhận>.
**Wave:** <Nhóm triển khai nếu có>.

## 1. Mục tiêu (Objective)

<Một kết quả nghiệp vụ hoặc năng lực dùng chung cần tạo ra>.

## 2. Phạm vi và quy tắc (Scope & Rules)

### Trong phạm vi / Sở hữu

- <Hành vi, thiết kế hoặc thành phần phải thay đổi>.

### Ngoài phạm vi / Không sở hữu

- <Phần không thay đổi; chủ sở hữu tương ứng>.

### Quy tắc áp dụng

| ID | Cách áp dụng trong Slice |
|---|---|
| <ID có link đến nguồn chuẩn> | <Phạm vi áp dụng; không chép toàn bộ quy tắc> |

## 3. Luồng xử lý (Flow)

### Luồng chính

<!-- Dẫn Flow của UC; chỉ thêm luồng triển khai cần thiết. Một sơ đồ workflow ở đây,
không lặp ở Design. Không quá 5 bước tóm tắt sau sơ đồ. -->

### Luồng thất bại

<!-- Điều kiện, kết quả, tác động không được phát sinh và hướng tiếp tục.
Nêu rõ chưa xác định khác thất bại đã xác nhận. -->

## 4. Thiết kế (Design)

### Domain và trạng thái

<!-- Trước/sau; artifact Domain bị ảnh hưởng. Quy tắc bền vững cập nhật ở nguồn chuẩn. -->

### Ứng dụng và giao diện

<!-- Orchestration, thành phần cần sửa, Screen/state/action, DS, điều hướng,
feedback, quyền và accessibility nếu thuộc phạm vi. Backend/frontend cùng một Slice. -->

### Lưu trữ, transaction và xử lý đồng thời

<!-- Nếu có: schema/draft SQL và liên kết nguồn, phạm vi commit, áp dụng idempotency,
xung đột, rollback/recovery. Thiết kế chỉ phục vụ Slice nằm ở đây.
Không tự promote migration. Query-only ghi rõ phần không áp dụng. -->

### Lỗi và kết quả

<!-- Ánh xạ kết quả/lỗi đã chốt; không biến mất phản hồi thành thất bại. -->

## 5. Phụ thuộc và hợp đồng (Dependencies & Contracts)

### Nguồn chuẩn và phụ thuộc

| ID / Link | Cần gì trước khi triển khai | Trạng thái |
|---|---|---|
| <Artifact hoặc Slice> | <Điều kiện cụ thể> | <Đã đủ / Còn thiếu> |

### Hợp đồng cung cấp / sử dụng

<!-- Command/Query/DTO, API/Event và interface khi cần. Mỗi type là H4 riêng với
Dart fence; Command/Query có 1–2 câu blockquote giải thích khi dùng trước code.
Chỉ điền từ nguồn đã chốt. Hợp đồng dùng chung phải dẫn về Domain/Technical Contract.
Chưa có schema đầy đủ: ghi câu hỏi mở ở phần 7, không tuyên bố READY_TO_IMPLEMENT. -->

## 6. Kiểm chứng (Verification)

- [ ] **AC-01** <Kết quả quan sát được, dẫn UC Flow/Scenario hoặc tiêu chí Domain/Technical Contract>.

| Test ID | Tiêu chí / Flow / Scenario | Cách kiểm tra |
|---|---|---|
| scn_sl_xxx_01 | AC-01; <nguồn> | <Domain / application / integration / UI / E2E> |

## 7. Bàn giao (Delivery)

### Đầu ra và điều kiện hoàn thành

- [ ] Artifact chuẩn được cập nhật và review nếu thay đổi.
- [ ] Code/interface/schema draft đúng phạm vi.
- [ ] Các kiểm tra phần 6 đạt, có liên kết evidence.
- [ ] Manifest cập nhật nguồn, dependency, coverage và trạng thái.
- [ ] Không còn câu hỏi chặn triển khai trước READY_TO_IMPLEMENT.

**Evidence:** <Link trong 06.evidence>; **Commit/MR/build:** <Khi có>.

### Câu hỏi còn mở

- <Câu hỏi, người phụ trách, ảnh hưởng>.

### Bước tiếp theo

<Việc tiếp theo theo trạng thái thực tế; không tự coi việc viết tài liệu là triển khai xong>.

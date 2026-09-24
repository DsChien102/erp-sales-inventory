---
id: EVD-BJ-UC-V5-REWRITE-v3.12.0
type: evidence
theme: theme-07
title: "Bằng chứng rewrite Business Journey và Use Case theo V5"
owner: QA/HARNESS
status: PASS
version: v3.12.0
parent: v3.11.0
---
# EVD — Rewrite Business Journey và Use Case theo V5 — v3.12.0

## 1. Phạm vi kiểm định

- Parent trực tiếp: `v3.11.0` từ package Theme 7 do Product cung cấp.
- Template nội dung: `BJ.template.md` và `UC.template.md` trong `theme-template.zip` mới nhất do Product cung cấp.
- Cấu trúc đích: `V45-Theme-skeleton` đã áp dụng từ v3.11.0.
- Phạm vi thay đổi: toàn bộ Business Journey và Use Case; không sửa `03.design/` trong version này.

## 2. Kết quả canonical

| Hạng mục | Kết quả |
|---|---:|
| Business Journey canonical | 17 |
| Use Case canonical | 64 |
| BJ có đủ 8 section V5 | 17/17 |
| UC có đủ 10 section V5 | 64/64 |
| UC có Basic Flow | 64/64 |
| UC có bảng BR | 64/64 |
| UC có liên hệ giao diện hoặc chỉ rõ bề mặt hỗ trợ | 64/64 |
| UC có Given/When/Then | 64/64 |
| BJ có đúng một `Begin` và một `End` | 17/17 |
| Relative link canonical đã kiểm | 1.972 |
| Relative link gãy | 0 |

## 3. Thay đổi ranh giới Use Case

V5 không giữ UC chỉ vì trước đây có một màn hình hoặc một bước thao tác riêng. Các UC sau được hợp nhất vì cùng mục tiêu, cùng authority và cùng commit/finality:

| UC lịch sử | Trạng thái | UC canonical v3.12.0 | Lý do |
|---|---|---|---|
| `UC-03-01/02/03` cũ | `BỊ THAY THẾ` | `UC-03-01 — Xác lập giá trị nhập ban đầu` | Chọn phạm vi, xác lập căn cứ và confirm là các bước của cùng một công việc kế toán và cùng commit point. |
| `UC-13-01/02/03` cũ | `BỊ THAY THẾ` | `UC-13-01 — Ghi nhận điều chỉnh giá trị hàng nhập` | Nguồn, phân bổ và ghi adjustment là một mục tiêu nghiệp vụ duy nhất. |
| `UC-14-01/02/03` cũ | `BỊ THAY THẾ` | `UC-14-01 — Tính và rà soát giá vốn` | Setup, calculation, blocker và review cùng tạo một run sẵn sàng hoặc bị chặn. |
| `UC-14-04` | Giữ ID | `UC-14-04 — Công bố giá vốn` | Publication là mutation/finality riêng, không được nhập vào UC tính/rà soát. |

Các ID bị thay thế chỉ còn ở migration ledger, carry-forward Slice/Design hoặc evidence lịch sử; không còn là canonical UC.

## 4. Gate ngôn ngữ và anti-boilerplate

Lượt rewrite không chấp nhận việc chỉ bọc nội dung cũ bằng template mới. Các lỗi converter chung đã được loại bỏ:

- query UC không còn mutation/`UNKNOWN` giả;
- phần `Không bao gồm` nói đúng ranh giới từng UC;
- actor/authority/precondition nói đúng công việc, không dùng câu “Theo Business Journey cha”;
- Basic/Alternate/Exception Flow nêu hành động nghiệp vụ thực tế;
- acceptance không dùng câu “thực hiện UC” hoặc “xử lý yêu cầu trong điều kiện đó”;
- BJ chỉ giữ journey-level acceptance, không chép flow của UC.

## 5. Kết luận

**PASS** cho phạm vi rewrite BJ/UC V5. UI/Screen/HTML chưa được coi là parity evidence của semantic mới; phần này được chuyển sang v3.13.0.

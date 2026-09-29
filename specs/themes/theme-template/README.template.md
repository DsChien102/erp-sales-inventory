---
id: <THEME-ID>
type: theme-readme
theme: <theme-xx>
title: <Tên tài liệu>
owner: <BA|BA/SA|SA|SA/SE|SE|HARNESS|QA>
status: DRAFT
---

<!--
Hướng dẫn dùng template:
- Nội dung trong <!-- --> là hướng dẫn, có thể xóa sau khi hoàn thiện.
- Chỉ giữ các mục Optional khi thực sự cần.
- Không sao chép lại nội dung đã có nguồn chuẩn khác; ưu tiên tham chiếu bằng ID/link.
- Mỗi phát biểu quan trọng phải lần ngược được về nguồn hoặc quyết định liên quan.
-->
# <THEME-ID> — <Tên Theme>

## 1. Mục đích
<!-- Mô tả ngắn Theme giải quyết vấn đề gì và giá trị chính. -->

## 2. Phạm vi
### 2.1 Trong phạm vi
<!-- Liệt kê các năng lực thuộc Theme. -->

### 2.2 Ngoài phạm vi
<!-- Nêu rõ những gì không thuộc Theme và nơi chịu trách nhiệm nếu biết. -->

## 3. Sơ đồ tổng quan
<!-- Tóm tắt Business Journey, Domain và các ranh giới lớn. Kiến trúc dùng chung thuộc Domain/Technical Contract; thiết kế cục bộ thuộc Slice. Không lặp chi tiết từ tài liệu con. -->

## 4. Điểm bắt đầu theo vai trò
<!-- Ví dụ: BA đọc Overview/BJ; SA đọc Domain/Technical Contract; SE đọc Slice tương ứng. -->

## 5. Tài liệu chính
<!-- Danh sách link tới các nguồn chính của Theme. -->

## 6. Trạng thái hiện tại
<!-- Tóm tắt phần đã FROZEN, đang làm, đang BLOCKED. -->

## 7. Cấu trúc và cách tổ chức công việc

- `01.knowledge/`: tri thức, quyết định, thuật ngữ.
- `02.specification/behavior/`: BJ, UC, BC; UI Flow nằm trong BJ.
- `02.specification/domain/`: domain-foundation, entities, aggregates, read-models, integrations; vùng chung BA/SA.
- `02.specification/technical-contracts/`: quy tắc kỹ thuật dùng chung nhiều Slice/toàn Theme.
- `03.design/`: screens, patterns, design-system, prototype; giữ runtime chạy được khi có.
- `04.harness/`: `BJ-<id>-harness/` flat + `CATALOG.md`. Một Work Slice là một outcome, một file.
- `05.procedures/`: quy trình kỹ thuật/vận hành.
- `06.evidence/`: bằng chứng kiểm chứng.
- `09.generated/`: registry/matrix/index sinh tự động.

Slice dẫn UC Flow/Scenario, Screen, Domain và Technical Contract liên quan; chứa thiết kế cục bộ, đầu ra và cách kiểm chứng. Không sao chép quy tắc chuẩn vào nhiều Slice.

## 8. Phiên bản

<!-- Dẫn VERSION.md; ghi cumulative parent thực tế và phạm vi thay đổi.
VERSION.md được tạo từ VERSION.template.md của bộ template. -->
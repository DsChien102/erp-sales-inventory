---
id: AGG-XX
type: aggregate
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
# AGG-XX — <Tên Aggregate>

## 1. Trách nhiệm
<!-- Tính nhất quán nào Aggregate phải bảo vệ. -->

## 2. Boundary
### 2.1 Thuộc Aggregate
### 2.2 Không thuộc Aggregate

## 3. Aggregate Root
<!-- Root và identity. -->

## 4. Entity / Value Object bên trong
<!-- Chỉ object nằm trong consistency boundary. -->

## 5. Lifecycle và state transition

## 6. Điều kiện bắt buộc
<!-- Invariant phải đúng trước/sau mọi Domain Operation. -->

## 7. Domain Operations / Aggregate Behavior
| Operation | Ý nghĩa | Preconditions | State effect |
|---|---|---|---|
| <submit()> | <...> | <...> | <...> |

## 8. Concurrency và consistency
<!-- Versioning, lock, atomicity, transaction boundary. -->

## 9. Persistence boundary
<!-- Mô tả logic persistence; không bắt buộc schema DB chi tiết. -->

## 10. Domain Events
<!-- Event nội bộ/domain event nếu có. -->

## 11. Dependencies
<!-- Aggregate/Domain/Foundation/Integration phụ thuộc. -->

## 12. Consumers
<!-- UC/BE Slice nào sử dụng capability này. -->

## 13. Verification
<!-- Các hành vi/invariant cần test để chứng minh thiết kế. -->

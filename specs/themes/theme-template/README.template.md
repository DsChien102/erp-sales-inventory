---

## id: 
type: theme-readme
theme: 
title: <Tên tài liệu>
owner: <BA|BA/SA|SA|SA/SE|SE|HARNESS|QA>
status: DRAFT

là hướng dẫn, có thể xóa sau khi hoàn thiện.

- Chỉ giữ các mục Optional khi thực sự cần.
- Không sao chép lại nội dung đã có nguồn chuẩn khác; ưu tiên tham chiếu bằng ID/link.
- Mỗi phát biểu quan trọng phải lần ngược được về nguồn hoặc quyết định liên quan.
-->

#  — <Tên Theme>

## 1. Mục đích



## 2. Phạm vi

### 2.1 Trong phạm vi



### 2.2 Ngoài phạm vi



## 3. Sơ đồ tổng quan



## 4. Điểm bắt đầu theo vai trò



## 5. Tài liệu chính



## 6. Trạng thái hiện tại



## 7. Cấu trúc và cách tổ chức công việc

- `01.knowledge/`: tri thức, quyết định, thuật ngữ.
- `02.specification/behavior/`: BJ, UC, BC; UI Flow nằm trong BJ.
- `02.specification/domain/`: domain-foundation, entities, aggregates, read-models, integrations; vùng chung BA/SA.
- `03.design/`: screens, patterns, design-system, prototype; giữ runtime chạy được khi có.
- `04.harness/`: `BJ-<id>-harness/` flat + `CATALOG.md`. Một Work Slice là một outcome, một file.
- `05.procedures/`: quy trình kỹ thuật/vận hành.
- `09.generated/`: registry/matrix/index sinh tự động.

Slice dẫn UC Flow/Scenario, Screen và Domain liên quan; chứa contract của outcome, thiết kế cục bộ, đầu ra và cách kiểm chứng. Quy tắc nền tảng dẫn từ `docs/architecture`. Không sao chép quy tắc Domain vào nhiều Slice.

## 8. Phiên bản


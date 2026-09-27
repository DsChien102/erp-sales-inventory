---
id: EVD-DOMAIN-ENTITY-ALIGNMENT-v3.12.0
type: evidence
theme: theme-07
title: "Bằng chứng align Domain và Entity theo template mới"
owner: QA/HARNESS
status: PASS
version: v3.12.0
parent: v3.11.0
---
# EVD — Domain/Entity alignment — v3.12.0

## 1. Nguyên tắc

- `DOM-IO` và 13 `ENT-IO-*` trong parent v3.11.0 đã được Product sửa trước; v3.12.0 **không rewrite** chúng.
- `DOM-COM`, `DOM-IC`, `DOM-IV` được align theo `DOMAIN.template.md` mới.
- Entity IC/IV được align theo `ENTITY.template.md`; không mô tả Entity như bảng DB.
- Semantic valuation mới được phản ánh ở Domain/Entity IV mà không tạo owner trùng với Theme 10 hoặc Theme 9.

## 2. Kết quả bảo toàn IO

| Kiểm tra | Kết quả |
|---|---|
| `DOM-IO.md` parent vs candidate | Byte-identical |
| 13 file `ENT-IO-*` parent vs candidate | 13/13 byte-identical |
| `03.design/` parent vs candidate | 0 file khác biệt |

`ENT-IO-04` là ID retired đã được parent v3.11.0 thay bằng `PRJ-IO-01`; v3.12.0 không phục hồi Entity cũ.

## 3. Kết quả align phần còn lại

| Hạng mục | Kết quả |
|---|---|
| Domain Foundation canonical | `DOM-COM`, `DOM-IC`, `DOM-IO`, `DOM-IV` |
| Domain được align mới ở v3.12.0 | COM, IC, IV |
| Entity IC | 11 |
| Entity IV | 9 |
| Entity IC/IV có định vị Aggregate, Identity, thuộc tính nghiệp vụ, behavior, event, trace | PASS |
| Leakage PK/FK/table/SQL như nguồn mô hình nghiệp vụ | Không phát hiện trong phần được align |

## 4. Thay đổi IV đáng chú ý

- `ENT-IV-07` đổi semantic canonical từ `LateLandedCost` hẹp thành `ValueAdjustmentSource`.
- `ENT-IV-08` đổi semantic canonical thành `ValueAdjustmentAllocation`.
- ID được giữ để trace; tên cũ chỉ còn compatibility/migration alias.
- `DOM-IV` khóa ranh giới: initial value → signed adjustment → cost calculation/publication.
- `OfficialCostVersion` chỉ do BJ14 publication tạo/cập nhật.

## 5. Kết luận

**PASS** cho phạm vi align Domain/Entity v3.12.0. IO được bảo toàn đúng yêu cầu Product; COM/IC/IV và Entity IC/IV theo template mới mà không đưa chi tiết lưu trữ kỹ thuật vào mô hình nghiệp vụ.

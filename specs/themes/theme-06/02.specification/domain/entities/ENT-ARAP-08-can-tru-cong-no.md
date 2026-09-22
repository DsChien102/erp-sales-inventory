---
id: ENT-ARAP-08
type: business-entity
theme: theme-06
title: Cấn trừ công nợ
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-08 — Cấn trừ công nợ

## 1. Ý nghĩa nghiệp vụ

Đại diện cho một nghiệp vụ explicit dùng phải thu và phải trả còn mở của **cùng Partner** để triệt tiêu một phần nghĩa vụ hai chiều.

## 2. Domain sở hữu

Công nợ sở hữu request/lifecycle/kết quả cấn trừ; không biến net position thành offset tự động.

## 3. Identity

`debt_offset_id` ổn định qua vòng đời request → approval → execution/result.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `debt_offset_id` | Định danh cấn trừ | Có | Audit |
| `tenant_id` | Tổ chức | Có | Cùng tenant |
| `partner_id` | Đối tác | Có | Cùng canonical Partner |
| `requested_amount` | Giá trị nghiệp vụ yêu cầu | Có | Cũng là basis approval; không nhân đôi hai phía |
| `effective_amount` | Giá trị thực sự có hiệu lực | Sau thành công | Phase 1 kỳ vọng bằng requested nếu toàn bộ hợp lệ; exact failure semantics cần SA |
| `status` | Trạng thái nghiệp vụ | Có | Lifecycle chi tiết chờ UC |
| `approval_request_ref` | Yêu cầu phê duyệt | Khi policy yêu cầu | Mặc định Phase 1 cần duyệt |
| `effective_at` | Thời điểm có hiệu lực | Sau thành công | Audit |

## 5. Quan hệ

Một DebtOffset có nhiều `ENT-ARAP-09 DebtOffsetLine` ở hai phía RECEIVABLE/PAYABLE và tham chiếu một ApprovalRequest khi cần.

## 6. Lifecycle / trạng thái

Semantic: chuẩn bị → chờ duyệt nếu cần → được duyệt/từ chối → ghi nhận kết quả. Chưa freeze state enum và failure/UNKNOWN path.

## 7. Quy tắc và Điều kiện bắt buộc

- Cùng tenant, cùng Partner.
- Chỉ giữa nghĩa vụ phải thu và phải trả còn đủ outstanding.
- Tổng giá trị hai phía phải cân bằng theo giá trị cấn trừ.
- Approval band dùng `requested_amount`, không cộng hai phía.
- Không auto-offset chỉ vì net position khác 0.

## 8. Behavioral Contract / Use Case liên quan

BJ-06. Aggregate candidate: [AGG-ARAP-06](../../../04.architecture/aggregates/AGG-ARAP-06-DebtOffset.md).

---
id: ENT-ARAP-05
type: business-entity
theme: theme-06
title: Yêu cầu phê duyệt
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-05 — Yêu cầu phê duyệt

## 1. Ý nghĩa nghiệp vụ

Đại diện cho một yêu cầu phê duyệt cụ thể của một nghiệp vụ Công nợ. Nó giữ đủ snapshot để thay đổi policy sau khi submit không làm thay đổi yêu cầu đang chờ.

## 2. Domain sở hữu

Công nợ sở hữu approval request trong phạm vi các nghiệp vụ Công nợ hiện tại.

## 3. Identity

`approval_request_id` ổn định; liên kết tới `subject_type`, `subject_id` và subject version/payload identity cần đủ để không duyệt nhầm một nội dung đã thay đổi.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `approval_request_id` | Định danh yêu cầu | Có | Audit |
| `subject_type` | Loại nghiệp vụ | Có | Số dư đầu kỳ, cấn trừ... |
| `subject_id` | Đối tượng cần duyệt | Có | Reference |
| `subject_version` | Phiên bản/nội dung được duyệt | Khi subject mutable | Chống approval stale |
| `requested_value` | Giá trị dùng xác định band | Có | Offset dùng giá trị cấn trừ, không cộng hai phía |
| `maker_id` | Người lập | Có | Không tự duyệt |
| `policy_snapshot` | Policy/band/role áp dụng | Có | Bất biến cho request đang chờ |
| `status` | Chờ / Duyệt / Từ chối... | Có | Tên enum kỹ thuật chưa freeze |
| `decided_by` | Người quyết định | Sau quyết định | Khác maker |
| `decided_at` | Thời điểm quyết định | Sau quyết định | Audit |

## 5. Quan hệ

- Tham chiếu một subject (OpeningBalanceBatch hoặc DebtOffset trong Phase 1 mặc định).
- Giữ snapshot từ ApprovalPolicy nhưng không phụ thuộc live policy sau submit.

## 6. Lifecycle / trạng thái

Semantic tối thiểu: `Chờ phê duyệt → Được duyệt | Bị từ chối`. Cách xử lý hủy/thay đổi subject sẽ chốt theo UC.

## 7. Quy tắc và Điều kiện bắt buộc

- Maker không được là approver của chính request.
- Approver phải có role phù hợp policy snapshot.
- Không có approver hợp lệ → không auto-skip và không thực thi subject.
- Request chỉ có giá trị cho đúng subject content/version được submit.

## 8. Behavioral Contract / Use Case liên quan

BJ-02, BJ-06 và các UC approval tương ứng. Aggregate candidate: [AGG-ARAP-02](../../../04.architecture/aggregates/AGG-ARAP-02-ApprovalRequest.md).

---
id: ENT-ARAP-10
type: business-entity
theme: theme-06
title: Đối chiếu công nợ
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-10 — Đối chiếu công nợ

## 1. Ý nghĩa nghiệp vụ

Đại diện cho một lần tổ chức đối chiếu công nợ với một Partner tại một mốc hoặc kỳ xác định, ghi lại số liệu nội bộ, phản hồi/số liệu phía đối tác, bằng chứng và kết quả khớp/chênh lệch.

## 2. Domain sở hữu

Công nợ sở hữu hồ sơ và kết quả đối chiếu. Đối tác không mặc định là user của VET45; phản hồi có thể được ghi nhận từ trao đổi bên ngoài.

## 3. Identity

`reconciliation_id` là định danh ổn định cho một lần đối chiếu.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `reconciliation_id` | Định danh đối chiếu | Có | Audit/history |
| `tenant_id` | Tổ chức | Có | Scope |
| `partner_id` | Đối tác | Có | Canonical Partner |
| `period_or_as_of` | Mốc/kỳ đối chiếu | Có | Cách biểu diễn kỹ thuật chưa freeze |
| `internal_position` | Số liệu nội bộ tại mốc | Có | Snapshot/căn cứ phải giải thích được |
| `counterparty_position` | Số liệu đối tác phản hồi | Khi có phản hồi | Có thể chưa có lúc lập |
| `difference` | Chênh lệch | Khi đủ hai phía | Dẫn xuất; không auto-adjust |
| `status` | Chờ xác nhận / Đã khớp / Có chênh lệch | Có | Semantic đã khóa |
| `evidence_refs` | Bằng chứng | Khi có | Lưu theo yêu cầu audit |
| `response_recorded_at` | Mốc ghi nhận phản hồi | Khi có | Audit |

## 5. Quan hệ

Tham chiếu Partner và tập nghĩa vụ/lịch sử làm căn cứ tại mốc; không trở thành owner của DebtObligation.

## 6. Lifecycle / trạng thái

`Chờ xác nhận → Đã khớp | Có chênh lệch`. Cách quay lại/chỉnh phản hồi nếu nhập sai chưa thuộc quyết định hiện hành và phải được làm rõ ở UC.

## 7. Quy tắc và Điều kiện bắt buộc

- Đối chiếu không tự điều chỉnh công nợ.
- Phải giữ được căn cứ/snapshot để giải thích số liệu đã gửi/đối chiếu tại thời điểm đó.
- Có chênh lệch chỉ ghi nhận finding; Debt Adjustment thuộc Future.

## 8. Behavioral Contract / Use Case liên quan

BJ-05. Aggregate candidate: [AGG-ARAP-07](../../../04.architecture/aggregates/AGG-ARAP-07-DebtReconciliation.md).

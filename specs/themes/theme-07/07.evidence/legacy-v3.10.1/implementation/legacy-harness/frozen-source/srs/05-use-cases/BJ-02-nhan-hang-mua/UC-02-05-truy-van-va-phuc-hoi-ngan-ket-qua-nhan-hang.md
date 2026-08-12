# UC-02-05 — Truy vấn và phục hồi ngắn kết quả nhận hàng

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-02 — Nhận hàng mua](../../../../../../../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md)  
> **Trạng thái:** SPECIFIED_FOR_RELEASE

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Thủ kho; adapter nhận hàng |
| Điều kiện kích hoạt | Lệnh nhận hàng có `operation_id` nhưng client chưa nhận được finality rõ ràng |
| Mục tiêu | Tra cứu kết quả authoritative và chỉ thực hiện idempotent retry ngắn hạn bằng đúng identity/payload ban đầu. |
| Kết quả thành công | Trả `COMMITTED` hoặc `REJECTED` đã có bằng chứng; không tạo receipt thứ hai. |
| Kết quả chưa xác định | Giữ `UNKNOWN`, giữ nguyên identity và bàn giao sang [BJ-17](../../../../../../../../02.specification/behavior/journeys/BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md). |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../../../../../../01.knowledge/decisions/decision-register.md#g03); [Nhóm G10 — Operation identity, idempotency và finality](../../../../../../../../01.knowledge/decisions/decision-register.md#g10) |
| Bài tri thức liên quan | [Idempotency, phiên bản nguồn và kết quả chưa xác định](../../../../../../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IO-02 — Receive purchased goods](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IO-02.md); UC này chỉ đọc `OperationResult`, không thực hiện lại toàn bộ nhận hàng. |
| Định danh | Bắt buộc dùng cùng `operation_id`, idempotency key và payload fingerprint của UC-02-04. |
| Bất biến | Query không mutation; duplicate cùng payload trả kết quả cũ; khác fingerprint trả conflict; timeout không phải bằng chứng thất bại. |
| Ranh giới | Chỉ query/deduplicate hoặc retry an toàn trong cửa sổ ngắn. Điều tra, khóa phạm vi, resolve/rebuild thuộc BJ-17/BJ-16/PROC-01. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-02-05-01 | Operation đã `COMMITTED` nhưng response trước bị mất | Query bằng đúng `operation_id` | Trả đúng result/receipt đã commit; không tạo movement, balance hoặc outbox thứ hai. |
| AS-UC-02-05-02 | Operation đã bị từ chối trước commit | Query kết quả | Trả `REJECTED` cùng mã/lý do và `effect_status=NONE`. |
| AS-UC-02-05-03 | Operation còn processing/UNKNOWN và retry được phép | Retry bằng cùng identity và cùng fingerprint | Deduplicate/tiếp tục cùng operation; không sinh identity mới. |
| AS-UC-02-05-04 | Chưa đủ bằng chứng finality sau cửa sổ phục hồi ngắn | Query hoặc retry tiếp | Giữ `UNKNOWN`, mở/handoff BJ-17 với cùng identity và evidence refs; không tự kết luận thất bại. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-02 — Nhận hàng](../../../prototype/contracts/sg-02/ui-contract.md), màn hình kết quả/đối chiếu nhận hàng |
| Trạng thái | `PROCESSING_OR_UNKNOWN`, `COMPLETED`, `REJECTED_EXECUTION`, `PERMISSION_DENIED`, `STALE`. |
| Hành động | Làm mới/query cùng operation; CTA retry chỉ xuất hiện khi server xác nhận retry cùng identity là an toàn. |
| Phản hồi | Hiển thị operation ID, status, as-of và đường sang BJ-17; không dùng “thất bại” cho `UNKNOWN`. |

# 5. Hợp đồng kỹ thuật

Xem [hợp đồng kỹ thuật dùng chung](../../../../../../../../04.architecture/foundations/FND-TECH-01.md#8-unknown-and-recovery-protocol).

| Contract | Handler | Adapter/API | Transaction boundary | Kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-02 result query | `QueryOperationResult` | `API-Q-04` — `GET /v1/inventory-operations/{id}` | Read-only authoritative operation/result/ledger evidence | `COMMITTED`, `REJECTED` hoặc `UNKNOWN`; không mutation | `TST-API-Q-04` |

- Retry command chỉ dùng lại chính request envelope và fingerprint nguồn; payload khác phải trả idempotency conflict.
- Nếu bằng chứng không đủ, adapter tạo handoff reference cho BJ-17 thay vì tự kích hoạt authoritative reconciliation mutation từ BJ-02.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-02 — Nhận hàng mua](../../../../../../../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Implement `API-Q-04`, deduplication và handoff; không gắn reconciliation mutation vào UC này. |
| FE | Giữ cùng operation context và chỉ hiển thị action được server cho phép. |
| QA | Kiểm thử 4 AS ở trên, đặc biệt duplicate/no-second-effect và `UNKNOWN` handoff. |
| Harness | Seed bằng `UC-02-05`, `BC-IO-02`, `API-Q-04`, `TST-API-Q-04` và finality protocol. |

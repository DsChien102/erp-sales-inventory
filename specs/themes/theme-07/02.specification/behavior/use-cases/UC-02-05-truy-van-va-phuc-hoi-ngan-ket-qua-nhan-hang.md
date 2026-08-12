---
id: UC-02-05
type: use-case
theme: theme-07
title: "Truy vấn và phục hồi ngắn kết quả nhận hàng"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-02-05 — Truy vấn và phục hồi ngắn kết quả nhận hàng

## 1. Mục tiêu và outcome

Tra cứu kết quả authoritative và chỉ thực hiện idempotent retry ngắn hạn bằng đúng identity/payload ban đầu.

**Kết quả thành công:** Trả `COMMITTED` hoặc `REJECTED` đã có bằng chứng; không tạo receipt thứ hai.

## 2. Ranh giới

### 2.1 Bắt đầu khi

Lệnh nhận hàng có `operation_id` nhưng client chưa nhận được finality rõ ràng

### 2.2 Kết thúc khi

Trả `COMMITTED` hoặc `REJECTED` đã có bằng chứng; không tạo receipt thứ hai.

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Thủ kho; adapter nhận hàng
- **Trigger:** Lệnh nhận hàng có `operation_id` nhưng client chưa nhận được finality rõ ràng
- **Điều kiện trước:** 

## 4. Hành vi nghiệp vụ

## 5. Ngoại lệ và thất bại

**Không thành công:** 

**Chưa xác định:** Giữ `UNKNOWN`, giữ nguyên identity và bàn giao sang [BJ-17](../journeys/BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md).

## 6. Ảnh hưởng nghiệp vụ



## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IO-02 — Receive purchased goods](../behavioral-contracts/BC-IO-02.md); UC này chỉ đọc `OperationResult`, không thực hiện lại toàn bộ nhận hàng.

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-012](../../../03.design/screens/SCR-012.md); [SCR-013](../../../03.design/screens/SCR-013.md) |
| Trạng thái | `PROCESSING_OR_UNKNOWN`, `COMPLETED`, `REJECTED_EXECUTION`, `PERMISSION_DENIED`, `STALE`. |
| Hành động | Làm mới/query cùng operation; CTA retry chỉ xuất hiện khi server xác nhận retry cùng identity là an toàn. |
| Phản hồi | Hiển thị operation ID, status, as-of và đường sang BJ-17; không dùng “thất bại” cho `UNKNOWN`. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-02-05-01 | Operation đã `COMMITTED` nhưng response trước bị mất | Query bằng đúng `operation_id` | Trả đúng result/receipt đã commit; không tạo movement, balance hoặc outbox thứ hai. |
| AS-UC-02-05-02 | Operation đã bị từ chối trước commit | Query kết quả | Trả `REJECTED` cùng mã/lý do và `effect_status=NONE`. |
| AS-UC-02-05-03 | Operation còn processing/UNKNOWN và retry được phép | Retry bằng cùng identity và cùng fingerprint | Deduplicate/tiếp tục cùng operation; không sinh identity mới. |
| AS-UC-02-05-04 | Chưa đủ bằng chứng finality sau cửa sổ phục hồi ngắn | Query hoặc retry tiếp | Giữ `UNKNOWN`, mở/handoff BJ-17 với cùng identity và evidence refs; không tự kết luận thất bại. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B); [Nhóm G10 — Operation identity, idempotency và finality](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh)
- **Bài tri thức liên quan:** [Idempotency, phiên bản nguồn và kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-02 — Nhận hàng mua](../journeys/BJ-02-nhan-hang-mua.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Implement `API-Q-04`, deduplication và handoff; không gắn reconciliation mutation vào UC này. |
| FE | Giữ cùng operation context và chỉ hiển thị action được server cho phép. |
| QA | Kiểm thử 4 AS ở trên, đặc biệt duplicate/no-second-effect và `UNKNOWN` handoff. |
| Harness | Seed bằng `UC-02-05`, `BC-IO-02`, `API-Q-04`, `TST-API-Q-04` và finality protocol. |

## v3.9.2 deep-review lock
- Recovery timeline chỉ hiện fact có authoritative evidence: submitted/locked at, approval decided at khi có, operation result, inventory movement/ledger sequence, server `checked_at`.
- Không dựng timeline từ timestamp narrative của fixture nếu fact chưa được chứng minh; UNKNOWN không được hiển thị “Đã cập nhật tồn”.

### Nguồn v3.10.1 — UC-02-05 — Truy vấn và phục hồi ngắn kết quả nhận hàng

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-02 — Nhận hàng mua](../journeys/BJ-02-nhan-hang-mua.md)  
> **Trạng thái:** SPECIFIED_FOR_RELEASE

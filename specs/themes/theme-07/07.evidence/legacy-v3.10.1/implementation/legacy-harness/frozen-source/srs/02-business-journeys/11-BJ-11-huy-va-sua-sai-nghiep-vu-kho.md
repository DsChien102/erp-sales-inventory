# BJ-11 — Hủy và sửa sai nghiệp vụ kho

> **Trạng thái:** Release đã đóng băng `4.1.0` — đã remap ID và boundary  
> **Chuyển đổi chính thức:** Theme 7 `4.0.0/BJ-12` → `4.1.0/BJ-11`  
> **Finality contract:** `COMPLETED`, `REJECTED/CANCELLED`, `SUSPENDED/BLOCKED`, `UNKNOWN/ESCALATED`
> **Phạm vi:** Phase 1 — hủy operation chưa thực thi hoặc tạo correction cho operation đã hoàn tất  
> **Chủ sở hữu nghiệp vụ:** Inventory Control; source capability sở hữu correction intent của nghiệp vụ liên miền
> **Quyết định nghiệp vụ:** `T7-BASELINE-FREEZE-v4.0.0` + `T7-DR-064`, `T7-DR-065`, `T7-DR-066`, `T7-DR-071`, `T7-DR-074`

# 1. Mục tiêu và ranh giới

## 1.1 Mục tiêu

Cho phép dừng yêu cầu chưa thực thi hoặc sửa sai operation đã hoàn tất mà vẫn bảo toàn **operation gốc, movement ledger, kỳ kế toán và toàn bộ chuỗi truy vết**.

## 1.2 Điểm bắt đầu và kết thúc

| Thuộc tính | Nội dung |
|---|---|
| Bắt đầu | Nguồn yêu cầu hủy operation, hoặc người có quyền phát hiện operation kho đã hoàn tất sai |
| Kết thúc | Operation chưa thực thi được hủy không tác động tồn; correction/reversal được commit; hoặc yêu cầu bị chặn/chờ đối soát mà lịch sử gốc không thay đổi |
| Tác động chính | Cancellation audit hoặc operation bù/thay thế có quantity/value adjustment liên kết |
| Không cho phép | Sửa/xóa operation, movement, result hoặc chứng từ lịch sử đã hoàn tất |

## 1.3 Trong và ngoài ranh giới

| Trong ranh giới | Ngoài ranh giới |
|---|---|
| Chọn đường cancel/reconcile/correct theo trạng thái; phân tích dependency; chọn delta hay reversal + replacement theo operation type; duyệt và thực thi | Hủy thương mại đơn bán/đơn mua; customer return thay cho correction; sửa kỳ đã khóa; sửa ledger trực tiếp |
| Lưu ngày nghiệp vụ gốc và ngày ghi nhận correction | Viết lại báo cáo kỳ cũ hoặc tái sử dụng operation ID gốc |

**Phụ thuộc bên ngoài:** Với operation phát sinh từ Sales, Purchase hoặc capability khác, capability nguồn tạo correction intent và source version. Theme 7 quyết định correction có khả thi trên tồn kho hiện hành hay không.

# 2. Sơ đồ hành trình

```mermaid
flowchart TD
    S([Bắt đầu: có yêu cầu hủy hoặc sửa sai]) --> U1A

    subgraph U1["UC-11-01 — Xác định đường xử lý"]
        U1A[Đọc operation, trạng thái và chuỗi phụ thuộc] --> U1B{Trạng thái operation?}
    end

    U1B -->|Nháp, chờ duyệt hoặc sẵn sàng| U2A
    U1B -->|Đang xử lý hoặc UNKNOWN| H[Chuyển sang BJ-17 để xác lập finality]
    U1B -->|Hoàn tất| U3A
    U1B -->|Từ chối thực thi hoặc đã hủy| R0[Không có tác động để đảo; trả hướng xử lý nguồn]

    subgraph U2["UC-11-02 — Hủy operation chưa thực thi"]
        U2A[Kiểm quyền, version và lý do] --> U2B[Hủy operation và giải phóng work/lock thuộc operation]
    end

    U2B --> R1[Trả kết quả đã hủy; không đổi tồn]

    H --> R2[Chờ kết quả authoritative; chưa cho correction]

    subgraph U3["UC-11-03 — Chuẩn bị phương án correction"]
        U3A[Kiểm dependency, lượng hiện hành và kỳ] --> U3B[Chọn delta hoặc reversal và replacement theo loại nghiệp vụ]
        U3B --> U3C{Phương án khả thi và đủ căn cứ?}
    end

    U3C -->|Không| R3[Từ chối và nêu dependency/căn cứ cần xử lý]
    U3C -->|Có| U4A

    subgraph U4["UC-11-04 — Phê duyệt correction"]
        U4A[Người độc lập xem before/after và giá trị rủi ro] --> U4B{Quyết định}
    end

    U4B -->|Từ chối| R3
    U4B -->|Duyệt| SUA

    subgraph SU["UC-11-05 — Ghi correction chain"]
        SUA[Kiểm lại state, dependency và approval] --> SUB[Ghi movement/value bù hoặc operation thay thế]
        SUB --> SUC[Liên kết operation gốc, correction và ngày kép]
    end

    SUC --> R4[Trả kết quả correction]
    R0 --> E([Kết thúc])
    R1 --> E
    R2 --> E
    R3 --> E
    R4 --> E
```

# 3. Trường hợp sử dụng

| UC | Tên | Bắt đầu | Kết thúc | Kết quả |
|---|---|---|---|---|
| [UC-11-01](../../../../../../../02.specification/behavior/use-cases/UC-11-01-xac-dinh-duong-xu-ly.md) | Xác định đường xử lý | Có operation và yêu cầu hủy/sửa | Chọn cancel, reconcile, correction hoặc không có tác động để đảo | Treatment route |
| [UC-11-02](../../../../../../../02.specification/behavior/use-cases/UC-11-02-huy-operation-chua-thuc-thi.md) | Hủy operation chưa thực thi | Operation ở trạng thái cho phép hủy | Operation `CANCELLED`, lock/work được giải phóng, không movement/value | Cancellation result |
| [UC-11-03](../../../../../../../02.specification/behavior/use-cases/UC-11-03-chuan-bi-phuong-an-correction.md) | Chuẩn bị phương án correction | Operation đã hoàn tất và có correction intent | Phương án khả thi đủ căn cứ hoặc bị chặn | Correction proposal |
| [UC-11-04](../../../../../../../02.specification/behavior/use-cases/UC-11-04-phe-duyet-correction.md) | Phê duyệt correction | Proposal có snapshot rủi ro | Duyệt hoặc từ chối có lý do | Approval decision |
| [UC-11-05](../../../../../../../02.specification/behavior/use-cases/UC-11-05-ghi-correction-chain.md) | Ghi correction chain | Proposal được duyệt và vẫn khả thi | Operation bù/thay thế cùng liên kết được commit hoặc không có gì commit | Immutable correction chain |

# 4. Logic nghiệp vụ cần giữ

| Điểm kiểm soát | Quy tắc |
|---|---|
| Hủy trước thực thi | Chỉ `DRAFT`, `PENDING_APPROVAL` hoặc `READY` được hủy; cancellation không tạo movement/value |
| UNKNOWN | Không đảo hoặc thay thế khi chưa xác lập finality; truy vấn cùng operation ID rồi handoff BJ-17 nếu vẫn chưa rõ |
| Operation hoàn tất | Không sửa payload/result; tạo operation mới trong correction chain |
| Dependency | Chặn reversal nếu làm âm tồn hoặc dependency chưa được trung hòa; không giả lập trung hòa bằng sửa số dư |
| Delta hay full reversal | Dùng delta khi chỉ phần sai có thể sửa độc lập và giữ đúng nguồn; dùng reversal + replacement khi toàn operation mất hiệu lực hoặc payload đúng phải được xác lập lại nguyên khối |
| Hàng thực quay về | Sale Issue đã bàn giao chỉ tăng tồn qua BJ-06; cancellation/correction không thay thế việc nhận hàng thực tế |
| Kỳ khóa | Ghi ảnh hưởng ở kỳ mở hiện tại, giữ ngày nghiệp vụ gốc và liên kết kỳ gốc; không sửa kỳ đã khóa |
| Một reversal hiệu lực | Mỗi operation gốc chỉ có một reversal hiệu lực; sửa tiếp qua chain kế nhiệm, không tạo nhiều reversal song song |
| Maker–checker | Correction/reversal duyệt theo rủi ro; người tạo không tự duyệt |

### Hướng correction theo nhóm operation

| Nhóm operation | Hướng xử lý chính |
|---|---|
| Receipt / Customer Return | Kiểm lượng còn truy được và dependency đã phát sinh; dùng delta hoặc reversal + replacement khi khả thi |
| Sale Issue / Supplier Return / Disposal | Không “hủy” bàn giao vật lý; cần evidence và operation bù phù hợp, customer return dùng đúng BJ-06 |
| Stocktake Adjustment | Tạo adjustment/correction mới có liên kết; không mở lại hoặc sửa số đếm đã duyệt |
| State Change | Tạo state movement ngược hoặc thay thế nếu transition hiện hành cho phép |
| Value-only Adjustment | Ghi value adjustment bù ở kỳ mở và giữ liên kết kỳ gốc |

# 5. Quan hệ và bàn giao

- Có thể nhận correction intent từ mọi BJ có mutation nhưng không thay thế workflow thương mại của BJ nguồn.
- Nếu correction liên quan hàng thực quay về, bàn giao BJ-06; nếu liên quan kiểm kê, chờ BJ-08 kết thúc scope lock.
- Quantity/value effects được chuyển cho BJ-14 và báo cáo theo cả ngày nghiệp vụ gốc lẫn ngày ghi nhận.
- Operation có finality chưa xác định được bàn giao BJ-17; ledger/projection mismatch được bàn giao BJ-16 để mở/điều phối Reconciliation Case. Không cho người dùng sửa kết quả bằng tay.

# 6. Nguồn tri thức liên quan

- [Sửa sai tồn kho mà không sửa lịch sử](../../../../../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)
- [Vòng đời của một Inventory Operation](../../../../../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)
- [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../../../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md)
- [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)

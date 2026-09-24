# BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định

> **Trạng thái:** Release đã đóng băng `4.1.0` — đã remap ID và boundary  
> **Chuyển đổi chính thức:** Theme 7 `4.0.0/BJ-20` → `4.1.0/BJ-17`  
> **Finality contract:** `COMPLETED`, `REJECTED/CANCELLED`, `SUSPENDED/BLOCKED`, `UNKNOWN/ESCALATED`
> **Phạm vi:** Phase 1 — phục hồi operation `UNKNOWN` bằng cùng định danh nghiệp vụ  
> **Chủ sở hữu nghiệp vụ:** Inventory Control phối hợp owner của operation
> **Quyết định nghiệp vụ:** `T7-BASELINE-FREEZE-v4.0.0` + `T7-DR-071`, `T7-DR-072`, `T7-DR-074`, `T7-DR-090`

# 1. Mục tiêu và ranh giới

## 1.1 Mục tiêu

Xác lập kết quả authoritative cho một nghiệp vụ có kết quả **chưa xác định (`UNKNOWN`)** mà không tạo mutation trùng, không tự reversal và không coi timeout là thất bại.

## 1.2 Điểm bắt đầu và kết thúc

| Thuộc tính | Nội dung |
|---|---|
| Bắt đầu | Một inventory operation ở trạng thái `UNKNOWN` được đưa vào xử lý |
| Kết thúc | Operation được xác lập đã commit/chưa commit và tiếp tục an toàn; hoặc vẫn `UNKNOWN` nhưng đã escalated với phạm vi được bảo vệ |
| Tác động chính | Operation result, recovery evidence, trạng thái nguồn liên miền và Reconciliation Case liên quan |
| Không được làm | Tạo operation ID mới, tự ghi movement bù, tự refund hoặc tự hoàn tất nghiệp vụ nguồn |

## 1.3 Trong và ngoài ranh giới

| Trong ranh giới | Ngoài ranh giới |
|---|---|
| Thu thập bằng chứng commit/no-commit; tiếp tục cùng operation ID; xác lập finality; giữ pending khi chưa đủ chứng cứ | Sửa ledger; dựng lại projection; correction/reversal; quyết định commercial state của Sales/Purchase |
| Bảo vệ đúng phạm vi rủi ro trong lúc chưa rõ kết quả | Coi mọi timeout là `REJECTED` hoặc tự phát lại với payload/ID khác |

# 2. Sơ đồ hành trình

```mermaid
flowchart TD
    S([Bắt đầu: operation có kết quả UNKNOWN]) --> U1A

    subgraph U1["UC-17-01 — Thu thập và đánh giá bằng chứng"]
        U1A[Liên kết Reconciliation Case và bảo vệ phạm vi] --> U1B[Kiểm tra operation, ledger, outbox và bằng chứng nguồn]
        U1B --> U1C{Bằng chứng cho thấy điều gì?}
    end

    U1C -->|Đã commit| U2A
    subgraph U2["UC-17-02 — Xác lập operation đã hoàn tất"]
        U2A[Đối chiếu tác động đã commit] --> U2B[Xác lập kết quả COMPLETED và thông báo nguồn]
    end

    U1C -->|Chưa commit| SUA
    subgraph SU["UC-17-03 — Tiếp tục cùng operation identity"]
        SUA[Giữ nguyên định danh yêu cầu và operation] --> SUB[Tiếp tục đúng nội dung đã xác nhận]
        SUB --> SUC[Xác lập kết quả mới]
    end

    U1C -->|Chưa đủ bằng chứng| U3A
    subgraph U3["UC-17-04 — Giữ chưa xác định và escalated"]
        U3A[Ghi phần bằng chứng còn thiếu] --> U3B[Giữ UNKNOWN, lock và trạng thái chờ ở nguồn]
        U3B --> U3C[Escalate cho người có trách nhiệm]
    end

    U2B --> R[Trả evidence và kết quả phục hồi]
    SUC --> R
    U3C --> R
    R --> E([Kết thúc])
```

# 3. Trường hợp sử dụng

| UC | Tên | Bắt đầu | Kết thúc | Kết quả |
|---|---|---|---|---|
| [UC-17-01](../../../../../../../02.specification/behavior/use-cases/UC-17-01-thu-thap-va-danh-gia-bang-chung.md) | Thu thập và đánh giá bằng chứng | Operation ở trạng thái UNKNOWN | Có kết luận commit, no-commit hoặc chưa đủ bằng chứng | Evidence assessment |
| [UC-17-02](../../../../../../../02.specification/behavior/use-cases/UC-17-02-xac-lap-operation-da-hoan-tat.md) | Xác lập operation đã hoàn tất | Có bằng chứng commit đầy đủ | Operation và nguồn nhận kết quả COMPLETED authoritative | Completed result, không ghi lại movement |
| [UC-17-03](../../../../../../../02.specification/behavior/use-cases/UC-17-03-tiep-tuc-cung-operation-identity.md) | Tiếp tục cùng operation identity | Có bằng chứng operation chưa commit | Cùng operation ID trả kết quả mới hoặc vẫn UNKNOWN | Idempotent continuation dùng chung |
| [UC-17-04](../../../../../../../02.specification/behavior/use-cases/UC-17-04-giu-chua-xac-dinh-va-escalated.md) | Giữ chưa xác định và escalated | Evidence chưa đủ hoặc có nghi ngờ nghiêm trọng | UNKNOWN được giữ, phạm vi được bảo vệ và escalation có owner | Controlled unresolved result |

# 4. Logic nghiệp vụ cần giữ

| Điểm kiểm soát | Quy tắc |
|---|---|
| UNKNOWN không phải FAILED | Timeout hoặc mất kết nối không chứng minh rằng transaction đã rollback |
| Cùng định danh | Chỉ tra cứu/tiếp tục bằng đúng định danh operation và yêu cầu; nội dung khác phải bị từ chối |
| Có bằng chứng commit | Chỉ xác lập kết quả từ tác động đã có; không ghi movement/balance/outbox lần hai |
| Có bằng chứng no-commit | Có thể tiếp tục cùng ID sau khi xác minh không tồn tại tác động bán phần |
| Chưa đủ bằng chứng | Giữ UNKNOWN và trạng thái nguồn tương ứng; không đoán kết quả để “mở đường” cho người dùng |
| Boundary liên miền | Sales/Purchase giữ trạng thái chờ theo contract của mình; Theme 7 không tự hoàn tất đơn, refund payment hoặc tạo lại receipt |
| Mở khóa | Chỉ mở phạm vi sau khi kết quả và tác động đã được chứng minh nhất quán |

# 5. Quan hệ và bàn giao

- Nhận operation từ BJ-16 hoặc từ bước phục hồi ngắn hạn của BJ phát sinh operation.
- Khi đủ bằng chứng, trả kết quả về BJ-16 để verify và đóng/mở khóa case.
- Nếu phát hiện ledger đúng nhưng read model sai, route riêng sang PROC-01; không rebuild trong BJ này.
- Nếu cần sửa một operation đã hoàn tất, dùng BJ-11 sau khi finality đã rõ.

# 6. Nguồn tri thức liên quan

- [Vòng đời của một inventory operation](../../../../../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)
- [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../../../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md)
- [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
- [Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](../../../../../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)

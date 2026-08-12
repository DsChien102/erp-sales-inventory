---
id: BJ-12
type: business-journey
theme: theme-07
title: "Khởi tạo số dư tồn kho đầu kỳ"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# BJ-12 — Khởi tạo số dư tồn kho đầu kỳ

## 1. Mục tiêu trải nghiệm

Khởi tạo **số lượng, trạng thái, lô/hạn dùng và giá trị tồn kho đầu kỳ** từ nguồn đã được kiểm soát; chỉ mở giao dịch kho thông thường sau khi toàn bộ batch được kiểm tra, duyệt, commit và đối soát thành công.

## 2. Phạm vi và ranh giới

### 2.1 Bắt đầu khi

| Thuộc tính | Nội dung |
|---|---|
| Bắt đầu | Đơn vị chuẩn bị vận hành tồn kho và có file số dư cùng số kiểm soát tại cut-off |
| Kết thúc | Tồn kho được kích hoạt bằng một batch đã commit và có báo cáo đối soát; hoặc batch dừng ở kết quả lỗi/từ chối mà chưa mở giao dịch |
| Tác động chính | Opening movement, balance, value, initial official cost và bằng chứng migration |
| Không quyết định | Tạo Product, Store, Warehouse, đơn vị tính hoặc sửa dữ liệu nguồn bên ngoài |

### 2.2 Kết thúc khi

| Thuộc tính | Nội dung |
|---|---|
| Bắt đầu | Đơn vị chuẩn bị vận hành tồn kho và có file số dư cùng số kiểm soát tại cut-off |
| Kết thúc | Tồn kho được kích hoạt bằng một batch đã commit và có báo cáo đối soát; hoặc batch dừng ở kết quả lỗi/từ chối mà chưa mở giao dịch |
| Tác động chính | Opening movement, balance, value, initial official cost và bằng chứng migration |
| Không quyết định | Tạo Product, Store, Warehouse, đơn vị tính hoặc sửa dữ liệu nguồn bên ngoài |

### 2.3 Không bao gồm

| Trong ranh giới | Ngoài ranh giới |
|---|---|
| Nạp file; chuẩn hóa; kiểm tra master/UOM/LOT/expiry; so control totals; duyệt độc lập; commit nguyên tử; kích hoạt; báo cáo migration | Tự tạo master data; nhập batch đầu kỳ lần hai; cho phép giao dịch thường trước activation; chuyển kho |
| Số lượng chi tiết theo kho/trạng thái/lô và tổng giá trị có thẩm quyền theo tenant + sản phẩm | Dùng giá trị theo kho/lô làm sổ giá trị độc lập |

**Phụ thuộc bên ngoài:** Store, Warehouse, Product, UOM và quan hệ mặc định phải được capability nền tảng/master-data tạo trước khi bắt đầu BJ này.

## 3. Actor

- Quản trị triển khai, kế toán kho và người duyệt

## 4. Luồng chính

```mermaid
flowchart TD
    S([Bắt đầu: có dữ liệu đầu kỳ và số kiểm soát]) --> U1A

    subgraph U1["UC-12-01 — Nạp và kiểm tra batch đầu kỳ"]
        U1A[Nạp và chuẩn hóa dữ liệu] --> U1B[Kiểm master, UOM, trạng thái, LOT và hạn dùng]
        U1B --> U1C[Đối chiếu số lượng và tổng giá trị kiểm soát]
    end

    U1C --> V{Batch hợp lệ?}
    V -->|Không| R0[Trả danh sách lỗi để sửa nguồn]
    V -->|Có| U2A

    subgraph U2["UC-12-02 — Rà soát và duyệt batch"]
        U2A[Xem phạm vi, totals và bằng chứng] --> U2B{Người duyệt quyết định}
    end

    U2B -->|Từ chối| R1[Giữ tồn kho chưa kích hoạt]
    U2B -->|Duyệt| U3A

    subgraph U3["UC-12-03 — Commit và kích hoạt tồn kho"]
        U3A[Xác nhận đúng batch đã duyệt] --> U3B[Commit số lượng, giá trị và giá vốn khởi tạo]
        U3B --> U3C[Đối soát, lập báo cáo và mở giao dịch]
    end

    U3C --> R2[Trả kết quả khởi tạo]
    R0 --> E([Kết thúc])
    R1 --> E
    R2 --> E
```



## 5. Use Case map



## 6. Luồng thay thế và ngoại lệ

### 4. Logic nghiệp vụ cần giữ

| Điểm kiểm soát | Quy tắc |
|---|---|
| Activation gate | Khi chưa hoàn tất batch đầu tiên, chỉ nghiệp vụ chuẩn bị/duyệt/commit đầu kỳ được phép; mutation thường bị chặn |
| Một batch chính thức | Chỉ một opening batch được hoàn tất; sai sau activation phải dùng correction/adjustment |
| Dữ liệu bất thường | Quantity âm hoặc quantity bằng 0 nhưng có value bị từ chối; quantity dương phải có căn cứ giá trị đủ để hình thành giá vốn khởi tạo |
| Trùng khóa | Không tự gộp im lặng các dòng trùng product + warehouse + state + lot; phải báo lỗi để sửa nguồn |
| LOT/expiry | Sản phẩm NONE không có lô; sản phẩm LOT bắt buộc mã lô và chỉ bắt buộc hạn dùng khi product policy yêu cầu |
| Trạng thái | Có thể nhập non-sellable khi state được khai rõ; chỉ lượng sellable và đủ dữ liệu mới tăng khả dụng |
| Giá trị | Quantity chi tiết theo kho/trạng thái/lô; giá trị có thẩm quyền và initial official cost theo tenant + sản phẩm |
| Nguyên tử | Opening movement, balance, value, initial cost, report và activation cùng commit hoặc cùng rollback |
| Maker–checker | Người chuẩn bị không tự duyệt batch |

### 5. Quan hệ và bàn giao

- Nhận master data và Store/Warehouse mặc định từ capability nền tảng.
- Sau activation, BJ-01 có thể hiển thị số dư và BJ-15 có thể truy báo cáo/thẻ kho.
- Initial official cost là đầu vào đầu tiên của BJ-14.
- Mọi sửa sai sau khi kích hoạt phải đi qua BJ-11 hoặc adjustment phù hợp; không mở lại batch đầu kỳ.

## 7. UI Flow và chuyển màn hình

> **v1.8.0 Product correction** · Parent: `v1.7.0` · Source SRS frozen.  
> Flow này mô tả Product continuity + actor handoff. Entry architecture, internal version/hash/idempotency và recovery mechanics **không render thành Product helper/banner**.

### 1. Phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Nguồn nghiệp vụ | [BJ-12](BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) |
| Chủ sở hữu | Inventory Control; Inventory Valuation tham gia |
| Module entry | `SCR-066 — Khởi tạo tồn kho` |
| Approver entry | `SCR-070 — Duyệt số dư đầu kỳ` qua assigned approval task |
| Result | `SCR-071 — Kết quả khởi tạo tồn kho` |
| Prototype | `PRODUCT_CORRECTED_v1.8.0` |

### 2. Product flow

```mermaid
flowchart TD
    START([Mở Khởi tạo tồn kho]) --> S066[SCR-066 Khởi tạo tồn kho]
    S066 -->|Bắt đầu / tiếp tục chuẩn bị| S067[SCR-067 Dữ liệu tồn kho đầu kỳ]
    S067 -->|Kiểm tra dữ liệu| S068[SCR-068 Kết quả kiểm tra]
    S068 -->|Có lỗi hoặc totals không khớp| S067
    S068 -->|Đạt| S069[SCR-069 Rà soát số dư đầu kỳ]
    S069 -->|Gửi phê duyệt| PENDING[SCR-066 Chờ duyệt]

    APPROVER([Assigned approval task]) --> S070[SCR-070 Duyệt số dư đầu kỳ]
    S070 -->|Từ chối + lý do| S071R[SCR-071 Không kích hoạt]
    S070 -->|Duyệt| S071P[SCR-071 Đang xử lý]
    S071P -->|System commit + reconcile| S071C[SCR-071 Đã khởi tạo]
    S071P -->|Chưa xác định| UNKNOWN[SCR-071 Đang xác minh]
    UNKNOWN -->|Same identity recovery| BJ17[Handoff BJ-17]
```

**Không có mũi tên maker `SCR-069 → SCR-070`.** Maker submit kết thúc ở `Chờ duyệt`; approver là actor/session khác.

### 3. Transition contract

| ID | Từ | Trigger | Đến | Loại | Trace |
|---|---|---|---|---|---|
| `UIF-12-T01` | Start | Mở module | `SCR-066` | `NAVIGATION` | `UC-12-01` |
| `UIF-12-T02` | `SCR-066` | Bắt đầu / tiếp tục đúng preparation | `SCR-067` | `NAVIGATION` | `UC-12-01` |
| `UIF-12-T03` | `SCR-067` | Kiểm tra dữ liệu | `SCR-068` | `MUTATION` | `UC-12-01` · `ACT-13-PREPARE` |
| `UIF-12-T04` | `SCR-068` | Validation fail / totals mismatch | `SCR-067` | `NAVIGATION` | `UC-12-01` |
| `UIF-12-T05` | `SCR-068` | Validation passed | `SCR-069` | `NAVIGATION` | `UC-12-01` |
| `UIF-12-T06` | `SCR-069` | Gửi phê duyệt | `SCR-066:PENDING_APPROVAL` | `MUTATION` | `UC-12-02` · `ACT-13-PREPARE` |
| `UIF-12-T07` | Assigned approval task | Eligible approver opens task | `SCR-070` | `ACTOR_HANDOFF_TASK` | `UC-12-02` |
| `UIF-12-T08` | `SCR-070` | Từ chối + reason | `SCR-071:REJECTED_EXECUTION` | `MUTATION` | `UC-12-02` · `ACT-COMMON-DECIDE` |
| `UIF-12-T09` | `SCR-070` | Duyệt | `SCR-071:PROCESSING` | `MUTATION` | `UC-12-02` · `ACT-COMMON-DECIDE` |
| `UIF-12-T10` | `SCR-071:PROCESSING` | Approved decision + guards still valid | `SCR-071` | `SYSTEM` | `UC-12-03` · `ACT-13-COMMIT` |
| `UIF-12-T11` | `SCR-071` | Active + reconciled | End / BJ01 view | `TERMINAL/NAVIGATION` | `UC-12-03` |
| `UIF-12-T12` | `SCR-071` | Result UNKNOWN | BJ17 | `HANDOFF` | `UC-12-03` |

### 4. Product UX invariants

1. Phase 1 là **một opening initialization**, nên entry là status/task surface, không là list nhiều batch.
2. `Control totals` do người chuẩn bị nhập độc lập; parsed totals từ file là evidence để đối chiếu, không tự so file với chính nó.
3. Product/UOM/LOT lỗi không được quick-create trong flow này.
4. Maker review ưu tiên business totals/evidence; hash/version chỉ ở Inspect/audit.
5. Approval quyết định phương án; **approval không tự là inventory effect**. Commit sau approval do system owner thực hiện.
6. `UNKNOWN ≠ FAILED`; không tạo opening balance mới, không blind retry commit.
7. Sau `ACTIVE_RECONCILED`, opening balance không mở lại; sai số đi correction/adjustment phù hợp.
8. Product viewport chuẩn `402×874`.

### 5. Screen coverage

| UC | Screen |
|---|---|
| `UC-12-01` | `SCR-066`, `SCR-067`, `SCR-068` |
| `UC-12-02` | `SCR-069`, `SCR-070`, `SCR-066:PENDING_APPROVAL` |
| `UC-12-03` | `SCR-071` |

## 8. Handoff / phụ thuộc ngoài Journey



## 9. Outcome cuối

| Thuộc tính | Nội dung |
|---|---|
| Bắt đầu | Đơn vị chuẩn bị vận hành tồn kho và có file số dư cùng số kiểm soát tại cut-off |
| Kết thúc | Tồn kho được kích hoạt bằng một batch đã commit và có báo cáo đối soát; hoặc batch dừng ở kết quả lỗi/từ chối mà chưa mở giao dịch |
| Tác động chính | Opening movement, balance, value, initial official cost và bằng chứng migration |
| Không quyết định | Tạo Product, Store, Warehouse, đơn vị tính hoặc sửa dữ liệu nguồn bên ngoài |

## 10. Truy vết



### Nguồn v3.10.1 — BJ-12 — Khởi tạo số dư tồn kho đầu kỳ

> **Trạng thái:** Release đã đóng băng `4.1.0` — đã remap ID và boundary  
> **Chuyển đổi chính thức:** Theme 7 `4.0.0/BJ-13` → `4.1.0/BJ-12`  
> **Finality contract:** `COMPLETED`, `REJECTED/CANCELLED`, `SUSPENDED/BLOCKED`, `UNKNOWN/ESCALATED`
> **Phạm vi:** Phase 1 — một lần khởi tạo cho cửa hàng và kho mặc định  
> **Chủ sở hữu nghiệp vụ:** Inventory Control; Inventory Valuation tham gia
> **Quyết định nghiệp vụ:** `T7-BASELINE-FREEZE-v4.0.0` + `T7-DR-067`, `T7-DR-068`, `T7-DR-069`
### Nguồn v3.10.1 — 3. Trường hợp sử dụng

| UC | Tên | Bắt đầu | Kết thúc | Kết quả |
|---|---|---|---|---|
| [UC-12-01](../use-cases/UC-12-01-nap-va-kiem-tra-batch-dau-ky.md) | Nạp và kiểm tra batch đầu kỳ | Có file nguồn, cut-off và control totals | Batch hợp lệ hoặc có danh sách lỗi đầy đủ | Prepared batch có version/hash, chưa ghi ledger |
| [UC-12-02](../use-cases/UC-12-02-ra-soat-va-duyet-batch.md) | Rà soát và duyệt batch | Có prepared batch hợp lệ | Batch được duyệt hoặc từ chối | Approval decision độc lập với người lập |
| [UC-12-03](../use-cases/UC-12-03-commit-va-kich-hoat-ton-kho.md) | Commit và kích hoạt tồn kho | Có đúng version/hash đã duyệt | Toàn bộ batch hoàn tất và inventory được mở; hoặc không có gì commit | Opening evidence và activation result |
### Nguồn v3.10.1 — 6. Nguồn tri thức liên quan

- [Chuẩn bị dữ liệu số dư tồn kho đầu kỳ](../../../01.knowledge/know-how/KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md)
- [Xác nhận số dư đầu kỳ, Chuyển đổi chính thức và đối soát migration](../../../01.knowledge/know-how/KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration.md)
- [Kho, cửa hàng và khóa định danh số dư tồn kho](../../../01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md)
- [Đơn vị tính và cách quy đổi số lượng tồn kho](../../../01.knowledge/know-how/KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md)
- [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)

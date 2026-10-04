---

id: ENT-IO-01
type: business-entity
role: AGGREGATE_ROOT
theme: theme-07
title: GoodsReceipt
owner: BA/SA
status: DRAFT
aligned_to: ENTITY.template.md + ENT-IO-01.sample.md
source_baseline: v4.6.7

---

# ENT-IO-01 — GoodsReceipt

## 1. Định vị nghiệp vụ & ranh giới Aggregate

Hồ sơ lệnh **nhập kho** theo intent nhận hàng (PO / NCC / phiếu nhận hàng nhanh). Sở hữu lifecycle, payload nghiệp vụ và kết quả vật lý của lần nhận; khi `COMPLETED` mới append `InventoryMovement`.

| Thuộc tính | Giá trị |
|---|---|
| Vai trò DDD | `AGGREGATE_ROOT` |
| Aggregate Root | `GoodsReceipt` (tự thân) |
| Domain sở hữu | `DOM-IO` — thẩm quyền biến động vật lý & số lượng |
| Domain không sở hữu | Approval route/case → `DOM-IC`; giá vốn / value ledger → `DOM-IV`; Product / UOM master → Catalog |

### 1.1 Ranh giới Aggregate (Visual)

```mermaid
classDiagram
    class GoodsReceipt {
        <<AggregateRoot>>
        +receiptId
        +status
        +businessDate
        +submit()
        +completePhysicalReceipt()
        +cancel()
    }
    class GoodsReceiptLine {
        <<Entity>>
        +lineId
        +quantity
        +stockState
    }
    class ProductSnapshot {
        <<ValueObject>>
    }
    class WarehouseScope {
        <<ValueObject>>
    }
    class SupplierRef {
        <<ReferenceId>>
    }
    class ApprovalCaseRef {
        <<ReferenceId>>
    }

    GoodsReceipt "1" *-- "1..*" GoodsReceiptLine
    GoodsReceipt *-- ProductSnapshot
    GoodsReceipt *-- WarehouseScope
    GoodsReceipt ..> SupplierRef : references
    GoodsReceipt ..> ApprovalCaseRef : after submit Quick
```

> Anti-pattern: một Aggregate `InventoryOperation` với `operation_type` + field nullable hàng loạt. Intent nhận hàng → Root `GoodsReceipt`; intent khác → Root khác (`GoodsIssue`, `StockDisposal`, …).

## 2. Identity

| Loại | Định danh | Ghi chú |
|---|---|---|
| Surrogate | `receiptId` | Ổn định suốt vòng đời hồ sơ |
| Business key | `(tenantId, sourceType, operationRequestId)` | Unique theo nguồn yêu cầu nhận hàng |

`operationRequestId` là identity nghiệp vụ của yêu cầu nhận — không đồng nghĩa với khóa kỹ thuật của lần gọi command.

## 3. Thuộc tính nghiệp vụ thuần túy

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `receiptId` | Định danh hồ sơ nhận | Có | Surrogate ổn định |
| `operationRequestId` | ID yêu cầu nguồn | Có | Thành phần business key |
| `sourceType` | Loại chứng từ nguồn | Có | PO / NCC / quick, … |
| `warehouseScope` | Kho / cửa hàng ngữ cảnh | Có | Phase 1: cặp mặc định đang hoạt động |
| `supplierId` | Nhà cung cấp của lần nhận | Có (purchase/quick) | Header-level; mọi dòng kế thừa cùng supplier; **KHÔNG ĐƯỢC** multi-supplier trong một phiếu nhận hàng |
| `businessDate` | Ngày nhận nghiệp vụ | Có | Theo lịch nghiệp vụ tenant |
| `status` | Trạng thái vòng đời | Có | Nhận theo chứng từ có thể bắt đầu `DRAFT`; **phiếu nhận hàng nhanh chỉ tồn tại sau create-and-submit thành công và bắt đầu ở `PENDING_APPROVAL`** |
| `lines` | Các dòng hàng nhận | Có (≥1 khi submit) | Child `GoodsReceiptLine` |
| `reasonCode` | Lý do nghiệp vụ (nếu policy yêu cầu) | Theo policy | Gắn với loại nhận |

## 4. Hành vi nghiệp vụ cốt lõi

| Hành vi | Điều kiện / Invariant | Hệ quả / Domain Event |
|---|---|---|
| `createDraft(...)` | Chỉ áp dụng lifecycle có draft, ví dụ nhận theo chứng từ; **không dùng cho phiếu nhận hàng nhanh** | Hồ sơ `DRAFT`; chưa có movement |
| `addOrUpdateLine(...)` | Chỉ với phiếu nhận hàng đã tồn tại ở `DRAFT`; **không dùng trước submit phiếu nhận hàng nhanh** | Cập nhật dòng; chưa khóa payload |
| `createQuickAndSubmit(...)` | Full Quick payload + `idempotencyKey` hợp lệ; Supplier/items/evidence/ownership/approver đủ; **không yêu cầu price/FX basis** | Tạo phiếu nhận hàng trực tiếp `PENDING_APPROVAL`, cấp `receiptId`, tạo `ApprovalCase`; payload immutable; không movement |
| `submitForApproval()` | Phiếu nhận hàng đã tồn tại theo lifecycle hỗ trợ submit từ draft | Chuyển sang `PENDING_APPROVAL`; payload không còn mutable |
| `markReadyAfterApproval()` | Đang `PENDING_APPROVAL`; quyết định duyệt từ IC hợp lệ | `PENDING_APPROVAL → READY` |
| `rejectByApproval()` | Đang `PENDING_APPROVAL`; IC từ chối | `→ APPROVAL_REJECTED`; không movement |
| `completePhysicalReceipt()` | `READY`; all-or-nothing trên toàn bộ dòng | `→ COMPLETED`; append movement (`VALUATION_PENDING`); phát `GoodsReceiptCompleted` |
| `cancel()` | Chưa `COMPLETED`; policy cho phép | `→ CANCELLED`; không movement vật lý |

## 5. Vòng đời & chuyển dịch trạng thái

```mermaid
stateDiagram-v2
    [*] --> DRAFT: createDraft (document / draft-supported)
    [*] --> PENDING_APPROVAL: createQuickAndSubmit (Quick)
    DRAFT --> PENDING_APPROVAL: submitForApproval
    DRAFT --> CANCELLED: cancel
    PENDING_APPROVAL --> READY: markReadyAfterApproval
    PENDING_APPROVAL --> APPROVAL_REJECTED: rejectByApproval
    READY --> PROCESSING: completePhysicalReceipt_start
    PROCESSING --> COMPLETED: completePhysicalReceipt_commit
    PROCESSING --> EXECUTION_REJECTED: completePhysicalReceipt_fail
    READY --> CANCELLED: cancel
    COMPLETED --> [*]
    APPROVAL_REJECTED --> [*]
    EXECUTION_REJECTED --> [*]
    CANCELLED --> [*]
```

| Trạng thái | Ý nghĩa | Payload mutable? |
|---|---|---|
| `DRAFT` | Soạn thảo / chỉnh dòng của lifecycle hỗ trợ draft; **không phải trạng thái phiếu nhận hàng nhanh** | Có |
| `PENDING_APPROVAL` | Chờ duyệt (bắt buộc với Quick) | Không |
| `READY` | Đã duyệt, sẵn sàng ghi nhận vật lý | Không |
| `PROCESSING` | Đang thực thi ghi nhận | Không |
| `COMPLETED` | Đã ghi movement vật lý | Không |
| `APPROVAL_REJECTED` | Bị từ chối duyệt | Không |
| `EXECUTION_REJECTED` | Thực thi thất bại có lý do rõ | Không |
| `CANCELLED` | Hủy trước khi hoàn tất vật lý | Không |

Với phiếu nhận hàng nhanh: **không tồn tại nhánh `DRAFT`**. Trước submit chỉ có dữ liệu phiên UI ngoài Aggregate. Create-and-submit hợp lệ tạo phiếu nhận hàng trực tiếp `PENDING_APPROVAL`; validation/routing rejection không tạo phiếu nhận hàng. Phiếu nhận hàng nhanh không có `DRAFT → READY` và không tạo movement trước phê duyệt.

## 6. Domain Events phát sinh

| Event | Khi nào | Ý nghĩa |
|---|---|---|
| `GoodsReceiptSubmitted` | `submitForApproval()` thành công | Hồ sơ đã khóa payload, chờ duyệt |
| `GoodsReceiptApproved` | `markReadyAfterApproval()` | Đã sẵn sàng ghi nhận vật lý |
| `GoodsReceiptApprovalRejected` | `rejectByApproval()` | Từ chối duyệt; không nhận hàng |
| `GoodsReceiptCompleted` | `completePhysicalReceipt()` commit | Đã nhận vật lý; movement tồn tại |
| `GoodsReceiptCancelled` | `cancel()` | Hủy trước hoàn tất vật lý |

> Integration / outbox facts (wire name versioned) được map từ các domain event này trong work slice lúc review để implement — không khai báo ở đây.

## 7. Liên kết truy vết

| Loại | ID |
|---|---|
| Domain Foundation | `DOM-IO` |
| Behavioral Contract | `BC-IC-07`, `BC-IO-02`; `BC-IO-16` chỉ cho lifecycle có draft, **không dùng phiếu nhận hàng nhanh** |
| Use Case | `UC-02-02`, `UC-02-03`, `UC-02-04` |
| Child Entity | `ENT-IO-02` (`GoodsReceiptLine`) — đặc tả riêng khi cần |
| Quyết định | Nhóm G03 (nhận hàng & xác nhận giá trị), G10 (operation / finality) |

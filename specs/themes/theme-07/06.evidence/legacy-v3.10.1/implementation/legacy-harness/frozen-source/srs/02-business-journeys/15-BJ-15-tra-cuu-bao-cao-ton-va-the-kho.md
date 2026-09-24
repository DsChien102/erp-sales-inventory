# BJ-15 — Tra cứu báo cáo tồn và thẻ kho

> **Trạng thái:** Release đã đóng băng `4.1.0` — đã remap ID và boundary  
> **Chuyển đổi chính thức:** Theme 7 `4.0.0/BJ-18` → `4.1.0/BJ-15`  
> **Finality contract:** `COMPLETED`, `REJECTED/CANCELLED`, `SUSPENDED/BLOCKED`, `UNKNOWN/ESCALATED`
> **Phạm vi:** Phase 1 — báo cáo đọc, thẻ kho và xuất dữ liệu theo quyền  
> **Chủ sở hữu nghiệp vụ:** Inventory Reporting / Read layer
> **Quyết định nghiệp vụ:** `T7-BASELINE-FREEZE-v4.0.0` + `T7-DR-084`, `T7-DR-085`, `T7-DR-087`, `T7-DR-091`

# 1. Mục tiêu và ranh giới

## 1.1 Mục tiêu

Cho phép người vận hành và kế toán **tra cứu, giải thích và xuất số liệu tồn kho** theo phạm vi, cut-off và quyền; truy được từ số dư đến movement và chứng từ nguồn mà không sửa ledger.

## 1.2 Điểm bắt đầu và kết thúc

| Thuộc tính | Nội dung |
|---|---|
| Bắt đầu | Người dùng cần xem báo cáo tồn, lịch sử biến động hoặc thẻ kho |
| Kết thúc | Báo cáo/thẻ kho có as-of và đường truy nguyên được hiển thị/xuất; hoặc truy cập bị từ chối |
| Tác động chính | Không có mutation; tạo report result/export evidence |
| Không quyết định | Điều chỉnh số dư, xử lý UNKNOWN, mở Reconciliation Case hoặc rebuild projection |

## 1.3 Trong và ngoài ranh giới

| Trong ranh giới | Ngoài ranh giới |
|---|---|
| Chọn phạm vi/cut-off; báo cáo tổng hợp; breakdown trạng thái/lô; movement history; source link; export; quyền tài chính | Correction, stock count adjustment, reconciliation workflow, projection rebuild |
| Cảnh báo khi read model trễ và giữ as-of | Sửa balance để làm báo cáo khớp |

# 2. Sơ đồ hành trình

```mermaid
flowchart TD
    S([Bắt đầu: cần tra cứu số liệu tồn]) --> U1A

    subgraph U1["UC-15-01 — Xác định báo cáo và phạm vi"]
        U1A[Chọn loại báo cáo, kỳ hoặc cut-off] --> U1B[Áp cửa hàng, kho, sản phẩm và quyền]
        U1B --> U1C{Có quyền xem phạm vi?}
    end

    U1C -->|Không| R0[Thông báo không có quyền]
    U1C -->|Có| T{Nhu cầu tra cứu?}

    T -->|Xem tổng hợp| U2A
    subgraph U2["UC-15-02 — Xem báo cáo tồn kho"]
        U2A[Hiển thị số dư và breakdown] --> U2B[Hiển thị cut-off, as-of và nguồn số liệu]
    end

    T -->|Truy biến động| U3A
    subgraph U3["UC-15-03 — Xem thẻ kho và lịch sử"]
        U3A[Liệt kê movement theo thời gian] --> U3B[Mở chi tiết lô, operation và chứng từ nguồn]
    end

    U2B --> X{Cần xuất dữ liệu?}
    U3B --> X
    X -->|Không| R1[Trả kết quả tra cứu]
    X -->|Có| U4A

    subgraph U4["UC-15-04 — Xuất báo cáo"]
        U4A[Xác nhận scope và quyền dữ liệu] --> U4B[Tạo file kèm cut-off/as-of]
    end

    U4B --> R1
    R0 --> E([Kết thúc])
    R1 --> E
```

# 3. Trường hợp sử dụng

| UC | Tên | Bắt đầu | Kết thúc | Kết quả |
|---|---|---|---|---|
| [UC-15-01](../../../../../../../02.specification/behavior/use-cases/UC-15-01-xac-dinh-bao-cao-va-pham-vi.md) | Xác định báo cáo và phạm vi | Người dùng mở chức năng báo cáo | Report context hợp lệ hoặc bị từ chối | Scope/cut-off/permission context |
| [UC-15-02](../../../../../../../02.specification/behavior/use-cases/UC-15-02-xem-bao-cao-ton-kho.md) | Xem báo cáo tồn kho | Có context hợp lệ | Số dư và breakdown được hiển thị | Inventory report có as-of |
| [UC-15-03](../../../../../../../02.specification/behavior/use-cases/UC-15-03-xem-the-kho-va-lich-su.md) | Xem thẻ kho và lịch sử | Người dùng cần giải thích biến động | Movement và nguồn liên kết được hiển thị | Traceable stock card |
| [UC-15-04](../../../../../../../02.specification/behavior/use-cases/UC-15-04-xuat-bao-cao.md) | Xuất báo cáo | Có kết quả và quyền export | File được tạo đúng scope/quyền | Report export có cut-off/as-of |

# 4. Logic nghiệp vụ cần giữ

| Điểm kiểm soát | Quy tắc |
|---|---|
| Ledger authority | Thẻ kho và lịch sử dựa trên movement ledger bất biến; không sửa số dư từ báo cáo |
| Cut-off/as-of | Báo cáo phải thể hiện cut-off, thời điểm tạo và độ mới của projection |
| Hai loại ngày | Cho phép đọc theo ngày ghi nhận hoặc ngày nghiệp vụ nhưng phải gắn nhãn rõ, không trộn ngầm |
| Quantity/value | Quyền xem quantity độc lập với quyền xem official cost, total value và valuation adjustment |
| LOT/NONE | Breakdown theo lô chỉ áp dụng cho sản phẩm LOT; không tạo lô giả cho NONE |
| Giá trị chi tiết | Giá trị có thẩm quyền ở tenant + sản phẩm; phân bổ theo kho/state/lot nếu có phải gắn nhãn dẫn xuất |
| Projection trễ | Có thể cảnh báo và hiển thị last processed sequence; không dùng report trễ làm căn cứ mutation |
| Export | File export giữ đúng filter, quyền, cut-off/as-of như màn hình; không làm lộ dữ liệu tài chính |
| Phát hiện lệch | Báo cáo chỉ chỉ ra dấu hiệu và liên kết nguồn; xử lý sai lệch thuộc BJ-16 hoặc BJ-11 |

# 5. Quan hệ và bàn giao

- Dùng cùng balance/movement facts với BJ-01 nhưng hỗ trợ kỳ, lịch sử và export rộng hơn.
- Nhận quantity/value/official-cost facts từ các BJ có inventory effect và BJ-14.
- Nếu người dùng phát hiện nguồn, projection hoặc finality không khớp, bàn giao sang BJ-16; không sửa từ báo cáo.
- Khi xác định operation hoàn tất sai, bàn giao sang BJ-11.

# 6. Nguồn tri thức liên quan

- [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../../../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
- [Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](../../../../../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
- [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../../../../../../../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md)
- [Quyền chức năng, phạm vi kho và bảo vệ dữ liệu tài chính](../../../../../../../01.knowledge/know-how/KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md)
- [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)

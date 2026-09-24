---
id: BJ-MAP
type: business-journey-map
theme: theme-07
title: "Business Journey Map — Theme 07"
owner: BA
status: IN_REVIEW
source_baseline: v3.12.0
---

# Theme 7 — Bản đồ Business Journey

> Theme 7 có **17 Business Journey canonical**. v3.12.0 chuẩn hóa toàn bộ BJ/UC theo V5 và cập nhật cụm định giá `BJ03 → BJ13 → BJ14`; HTML hiện hành chưa phải nguồn semantic cho cụm này và sẽ được align ở v3.13.0.

## 1. Danh mục Business Journey

| STT | ID | Hành trình | Owner nghiệp vụ | Tài liệu |
|---:|---|---|---|---|
| 01 | `BJ-01` | Theo dõi tồn, khả dụng và chỉ báo vận hành | Inventory Operations / Monitoring | [Mở](BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) |
| 02 | `BJ-02` | Nhận hàng mua | Inventory Operations | [Mở](BJ-02-nhan-hang-mua.md) |
| 03 | `BJ-03` | Xác lập giá trị ban đầu của hàng nhận | Inventory Valuation | [Mở](BJ-03-xac-lap-gia-tri-ban-dau-cua-hang-nhan.md) |
| 04 | `BJ-04` | Quản lý vòng đời giữ hàng | Inventory Operations | [Mở](BJ-04-quan-ly-vong-oi-giu-hang.md) |
| 05 | `BJ-05` | Lấy hàng và bàn giao đơn | Inventory Operations | [Mở](BJ-05-lay-hang-va-ban-giao-on.md) |
| 06 | `BJ-06` | Tiếp nhận và phân loại hàng khách trả | Inventory Operations | [Mở](BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) |
| 07 | `BJ-07` | Thực hiện trả hàng cho nhà cung cấp | Inventory Operations | [Mở](BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) |
| 08 | `BJ-08` | Kiểm kê và điều chỉnh chênh lệch | Inventory Control | [Mở](BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) |
| 09 | `BJ-09` | Quản lý trạng thái hàng | Inventory Control | [Mở](BJ-09-quan-ly-trang-thai-hang.md) |
| 10 | `BJ-10` | Tiêu hủy hàng | Inventory Control | [Mở](BJ-10-tieu-huy-hang.md) |
| 11 | `BJ-11` | Hủy và sửa sai nghiệp vụ kho | Inventory Control | [Mở](BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) |
| 12 | `BJ-12` | Khởi tạo số dư tồn kho đầu kỳ | Inventory Control / Inventory Valuation | [Mở](BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) |
| 13 | `BJ-13` | Điều chỉnh giá trị hàng nhập | Inventory Valuation | [Mở](BJ-13-dieu-chinh-gia-tri-hang-nhap.md) |
| 14 | `BJ-14` | Tính và công bố giá vốn | Inventory Valuation | [Mở](BJ-14-tinh-va-cong-bo-gia-von.md) |
| 15 | `BJ-15` | Tra cứu báo cáo tồn và thẻ kho | Inventory Reporting / Read layer | [Mở](BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) |
| 16 | `BJ-16` | Điều tra và đối soát sai lệch | Inventory Control | [Mở](BJ-16-ieu-tra-va-oi-soat-sai-lech.md) |
| 17 | `BJ-17` | Phục hồi nghiệp vụ có kết quả chưa xác định | Inventory Control + Operation Owner | [Mở](BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md) |

## 2. Quan hệ đầu–cuối giữa các hành trình

Sơ đồ thể hiện **fact/handoff chính**, không có nghĩa mọi giao dịch phải đi qua tất cả BJ. Mỗi BJ chỉ chạy khi trigger của chính hành trình đó phát sinh.

```mermaid
flowchart LR
    B12["BJ-12<br/>Khởi tạo tồn đầu kỳ"]
    B01["BJ-01<br/>Theo dõi tồn & khả dụng"]
    B02["BJ-02<br/>Nhận hàng mua"]
    B03["BJ-03<br/>Xác lập giá trị nhập ban đầu"]
    B04["BJ-04<br/>Giữ hàng"]
    B05["BJ-05<br/>Lấy & bàn giao"]
    B06["BJ-06<br/>Khách trả hàng"]
    B07["BJ-07<br/>Trả NCC"]
    B08["BJ-08<br/>Kiểm kê"]
    B09["BJ-09<br/>Trạng thái hàng"]
    B10["BJ-10<br/>Tiêu hủy"]
    B11["BJ-11<br/>Hủy & sửa sai"]
    B13["BJ-13<br/>Điều chỉnh giá trị hàng nhập"]
    B14["BJ-14<br/>Tính & công bố giá vốn"]
    B15["BJ-15<br/>Báo cáo & thẻ kho"]
    B16["BJ-16<br/>Đối soát sai lệch"]
    B17["BJ-17<br/>Phục hồi UNKNOWN"]

    B12 -->|Opening quantity/value| B01
    B12 -->|Opening value facts| B14
    B12 -->|Evidence| B15

    B02 -->|Lượng thực nhận| B03
    B02 -->|Tình trạng thực nhận| B09
    B02 -.->|Finality chưa rõ| B17

    B03 -->|Initial inventory value + dirty scope| B14
    B03 -->|Receipt/value provenance| B13
    B13 -->|Signed value adjustment + dirty scope| B14

    B01 -->|Availability| B04
    B04 -->|Reservation| B05
    B05 -->|Hàng quay về| B06
    B06 -->|Sellable quantity| B01
    B06 -->|Quarantine/damaged/expired| B09

    B09 -->|Eligibility thay đổi| B04
    B09 -->|Allocation stale| B05
    B09 -->|RTV candidate| B07
    B09 -->|Disposal candidate| B10

    B05 -->|Issue facts| B14
    B06 -->|Return facts| B14
    B07 -->|Inventory-effect facts| B14
    B08 -->|Approved adjustment facts| B14
    B10 -->|Disposal facts| B14
    B11 -->|Correction facts| B14

    B01 -->|Inventory facts| B15
    B05 -->|Movement/cost snapshot| B15
    B14 -->|Official cost/value facts| B15

    B08 -.->|Sai operation nguồn| B11
    B10 -.->|Sai sau hoàn tất| B11
    B11 -.->|Ledger/projection mismatch| B16
    B11 -.->|Finality chưa rõ| B17
    B15 -->|Dấu hiệu sai lệch| B16
    B16 -.->|Cần correction| B11
    B16 -.->|Operation UNKNOWN| B17
    B17 -->|Evidence/finality result| B16
```

## 3. Trục định giá đã khóa ở v3.12.0

```mermaid
flowchart LR
    T10["Theme 10<br/>Nguồn thương mại nếu có"]
    Q["Quick Receipt<br/>Căn cứ trực tiếp Theme 7"]
    B02["BJ-02<br/>Lượng hàng thực nhận"]
    B03["BJ-03<br/>Giá trị nhập ban đầu"]
    B13["BJ-13<br/>Điều chỉnh giá trị hàng nhập"]
    B14["BJ-14<br/>Tính & công bố giá vốn"]

    B02 --> B03
    T10 -.->|PO/invoice/discount/tax facts đã xác lập| B03
    Q -.->|Không phụ thuộc Theme 10| B03
    T10 -.->|Fact mới/thay đổi sau BJ03| B13
    B03 -->|Initial value + dirty Product/period| B14
    B13 -->|Signed adjustment + dirty Product/period| B14
```

- **BJ03** xác lập giá trị nhập ban đầu; không công bố `OfficialCostVersion`.
- **BJ13** ghi phần thay đổi giá trị có căn cứ xuất hiện/được xác lập sau BJ03; lỗi nhập liệu của BJ03 đi BJ11, không giả làm BJ13.
- **BJ14** là owner duy nhất của tính và công bố giá vốn chính thức. Phương pháp công bố lấy từ cấu hình tenant, không chọn lại theo từng lần tính.
- Nhập hàng nhanh phải hoàn tất BJ03 mà không cần Theme 10; Theme 10 chỉ là upstream của nguồn thương mại khi nguồn đó tồn tại.

## 4. Nhóm trách nhiệm chính

| Nhóm | BJ chính | Vai trò |
|---|---|---|
| Inventory Operations | BJ01, BJ02, BJ04, BJ05, BJ06, BJ07 | Sự thật vật lý, khả dụng, giữ/lấy/bàn giao và return/RTV | 
| Inventory Valuation | BJ03, BJ13, BJ14 | Giá trị nhập ban đầu, adjustment giá trị và giá vốn chính thức | 
| Inventory Audit & Control | BJ08, BJ09, BJ10, BJ11, BJ12, BJ16, BJ17 | Kiểm soát, sửa sai, mở số dư, đối soát và recovery | 
| Reporting | BJ15 | Đọc/trình bày authoritative facts, không tự tạo định nghĩa nghiệp vụ mới | 

## 5. Supporting artifacts và boundary ngoài Theme

- `CAP-01` — chính sách tồn/cận hạn; không phải Business Journey.
- `PROC-01` — dựng lại projection; là procedure kỹ thuật, không phải Journey.
- `INT-01` — hợp đồng bàn giao liên Theme; owner nguồn ngoài Theme vẫn giữ authority của dữ kiện đó.

## 6. Recovery

```mermaid
flowchart TD
    S["Discrepancy / finality signal"] --> C["BJ-16 — Đối soát"]
    C --> U["BJ-17 — Làm rõ UNKNOWN"]
    U --> C
    C -.->|Cần sửa fact đã commit| B11["BJ-11 — Hủy & sửa sai"]
```

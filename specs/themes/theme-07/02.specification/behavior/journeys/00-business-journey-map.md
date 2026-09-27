---
id: BJ-MAP
type: business-journey-map
theme: theme-07
title: "Business Journey Map — Theme 07"
owner: BA
status: IN_REVIEW
source_baseline: v4.1.0
---

# Theme 7 — Bản đồ Business Journey

> Theme 7 có **17 Business Journey canonical** và **17 UI Flow canonical**. v4.1.0 giữ semantic BJ/UC v5, giữ trace `BJ ↔ UC ↔ UIF` của v4.0.0 và hợp nhất Design/HTML valuation đã sửa từ v3.13.0; prototype vẫn là downstream evidence, không phải nguồn semantic.

## 1. Danh mục Business Journey

| STT | ID | Hành trình | Owner nghiệp vụ | Journey | UI Flow |
|---:|---|---|---|---|---|
| 01 | `BJ-01` | Theo dõi tồn, khả dụng và chỉ báo vận hành | Inventory Operations / Monitoring | [BJ](BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) | [UIF-01](../../../03.design/flows/UIF-01-BJ-01.md) |
| 02 | `BJ-02` | Nhận hàng mua | Inventory Operations | [BJ](BJ-02-nhan-hang-mua.md) | [UIF-02](../../../03.design/flows/UIF-02-BJ-02.md) |
| 03 | `BJ-03` | Xác lập giá trị ban đầu của hàng nhận | Inventory Valuation | [BJ](BJ-03-xac-lap-gia-tri-ban-dau-cua-hang-nhan.md) | [UIF-03](../../../03.design/flows/UIF-03-BJ-03.md) |
| 04 | `BJ-04` | Quản lý vòng đời giữ hàng | Inventory Operations | [BJ](BJ-04-quan-ly-vong-oi-giu-hang.md) | [UIF-04](../../../03.design/flows/UIF-04-BJ-04.md) |
| 05 | `BJ-05` | Lấy hàng và bàn giao đơn | Inventory Operations | [BJ](BJ-05-lay-hang-va-ban-giao-on.md) | [UIF-05](../../../03.design/flows/UIF-05-BJ-05.md) |
| 06 | `BJ-06` | Tiếp nhận và phân loại hàng khách trả | Inventory Operations | [BJ](BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) | [UIF-06](../../../03.design/flows/UIF-06-BJ-06.md) |
| 07 | `BJ-07` | Thực hiện trả hàng cho nhà cung cấp | Inventory Operations | [BJ](BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) | [UIF-07](../../../03.design/flows/UIF-07-BJ-07.md) |
| 08 | `BJ-08` | Kiểm kê và điều chỉnh chênh lệch | Inventory Control | [BJ](BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) | [UIF-08](../../../03.design/flows/UIF-08-BJ-08.md) |
| 09 | `BJ-09` | Quản lý trạng thái hàng | Inventory Control | [BJ](BJ-09-quan-ly-trang-thai-hang.md) | [UIF-09](../../../03.design/flows/UIF-09-BJ-09.md) |
| 10 | `BJ-10` | Tiêu hủy hàng | Inventory Control | [BJ](BJ-10-tieu-huy-hang.md) | [UIF-10](../../../03.design/flows/UIF-10-BJ-10.md) |
| 11 | `BJ-11` | Hủy và sửa sai nghiệp vụ kho | Inventory Control | [BJ](BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) | [UIF-11](../../../03.design/flows/UIF-11-BJ-11.md) |
| 12 | `BJ-12` | Khởi tạo số dư tồn kho đầu kỳ | Inventory Control / Inventory Valuation | [BJ](BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) | [UIF-12](../../../03.design/flows/UIF-12-BJ-12.md) |
| 13 | `BJ-13` | Điều chỉnh giá trị hàng nhập | Inventory Valuation | [BJ](BJ-13-dieu-chinh-gia-tri-hang-nhap.md) | [UIF-13](../../../03.design/flows/UIF-13-BJ-13.md) |
| 14 | `BJ-14` | Tính và công bố giá vốn | Inventory Valuation | [BJ](BJ-14-tinh-va-cong-bo-gia-von.md) | [UIF-14](../../../03.design/flows/UIF-14-BJ-14.md) |
| 15 | `BJ-15` | Tra cứu báo cáo tồn và thẻ kho | Inventory Reporting / Read layer | [BJ](BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) | [UIF-15](../../../03.design/flows/UIF-15-BJ-15.md) |
| 16 | `BJ-16` | Điều tra và đối soát sai lệch | Inventory Control | [BJ](BJ-16-ieu-tra-va-oi-soat-sai-lech.md) | [UIF-16](../../../03.design/flows/UIF-16-BJ-16.md) |
| 17 | `BJ-17` | Phục hồi nghiệp vụ có kết quả chưa xác định | Inventory Control + Operation Owner | [BJ](BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md) | [UIF-17](../../../03.design/flows/UIF-17-BJ-17.md) |
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

## 3. Trục định giá canonical

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

## 6. Ma trận BJ ↔ UC ↔ UIF

| BJ | Use Case canonical | UI Flow canonical |
|---|---|---|
| [BJ-01](BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) | [UC-01-01](../use-cases/UC-01-01-xac-dinh-ngu-canh-va-san-pham.md); [UC-01-02](../use-cases/UC-01-02-xem-ton-va-kha-dung.md); [UC-01-03](../use-cases/UC-01-03-xem-trace-summary.md); [UC-01-04](../use-cases/UC-01-04-xem-ton-thap-va-luong-goi-y.md); [UC-01-05](../use-cases/UC-01-05-xem-hang-can-han-va-het-han.md) | [UIF-01](../../../03.design/flows/UIF-01-BJ-01.md) |
| [BJ-02](BJ-02-nhan-hang-mua.md) | [UC-02-01](../use-cases/UC-02-01-chuan-bi-nhan-theo-chung-tu.md); [UC-02-02](../use-cases/UC-02-02-chuan-bi-nhap-hang-nhanh.md); [UC-02-03](../use-cases/UC-02-03-phe-duyet-yeu-cau-nhan-hang.md); [UC-02-04](../use-cases/UC-02-04-ghi-nhan-hang-vao-ton-vat-ly.md); [UC-02-05](../use-cases/UC-02-05-truy-van-va-phuc-hoi-ngan-ket-qua-nhan-hang.md) | [UIF-02](../../../03.design/flows/UIF-02-BJ-02.md) |
| [BJ-03](BJ-03-xac-lap-gia-tri-ban-dau-cua-hang-nhan.md) | [UC-03-01](../use-cases/UC-03-01-xac-lap-gia-tri-nhap-ban-dau.md) | [UIF-03](../../../03.design/flows/UIF-03-BJ-03.md) |
| [BJ-04](BJ-04-quan-ly-vong-oi-giu-hang.md) | [UC-04-01](../use-cases/UC-04-01-tao-reservation.md); [UC-04-02](../use-cases/UC-04-02-dieu-chinh-reservation.md); [UC-04-03](../use-cases/UC-04-03-ket-thuc-va-giai-phong.md); [UC-04-04](../use-cases/UC-04-04-danh-gia-lai-va-xu-ly-thieu.md) | [UIF-04](../../../03.design/flows/UIF-04-BJ-04.md) |
| [BJ-05](BJ-05-lay-hang-va-ban-giao-on.md) | [UC-05-01](../use-cases/UC-05-01-lap-allocation.md); [UC-05-02](../use-cases/UC-05-02-xac-nhan-hang-da-lay.md); [UC-05-03](../use-cases/UC-05-03-ban-giao-hang.md); [UC-05-04](../use-cases/UC-05-04-phuc-hoi-allocation-stale.md); [UC-05-05](../use-cases/UC-05-05-ghi-xuat-kho-nguyen-tu.md) | [UIF-05](../../../03.design/flows/UIF-05-BJ-05.md) |
| [BJ-06](BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) | [UC-06-01](../use-cases/UC-06-01-xac-minh-hang-duoc-phep-nhan-tra.md); [UC-06-02](../use-cases/UC-06-02-xu-ly-ngoai-le-truy-vet.md); [UC-06-03](../use-cases/UC-06-03-ghi-nhan-hang-khach-tra.md); [UC-06-04](../use-cases/UC-06-04-phan-loai-hang-thuc-nhan.md) | [UIF-06](../../../03.design/flows/UIF-06-BJ-06.md) |
| [BJ-07](BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) | [UC-07-01](../use-cases/UC-07-01-xac-minh-pham-vi-tra.md); [UC-07-02](../use-cases/UC-07-02-dua-hang-vao-cho-tra.md); [UC-07-03](../use-cases/UC-07-03-dieu-chinh-hoac-huy-truoc-ban-giao.md); [UC-07-04](../use-cases/UC-07-04-ghi-nhan-ban-giao-tra-nha-cung-cap.md) | [UIF-07](../../../03.design/flows/UIF-07-BJ-07.md) |
| [BJ-08](BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) | [UC-08-01](../use-cases/UC-08-01-mo-va-khoa-pham-vi.md); [UC-08-02](../use-cases/UC-08-02-ghi-nhan-lan-dem-mu.md); [UC-08-03](../use-cases/UC-08-03-dem-lai-va-hoan-thien-bang-chung.md); [UC-08-04](../use-cases/UC-08-04-duyet-va-dieu-chinh.md); [UC-08-05](../use-cases/UC-08-05-huy-phien-kiem-ke.md) | [UIF-08](../../../03.design/flows/UIF-08-BJ-08.md) |
| [BJ-09](BJ-09-quan-ly-trang-thai-hang.md) | [UC-09-01](../use-cases/UC-09-01-chuan-bi-thay-doi-trang-thai.md); [UC-09-02](../use-cases/UC-09-02-phe-duyet-thay-doi-trang-thai.md); [UC-09-03](../use-cases/UC-09-03-xac-dinh-hang-het-han.md); [UC-09-04](../use-cases/UC-09-04-ghi-state-movement.md) | [UIF-09](../../../03.design/flows/UIF-09-BJ-09.md) |
| [BJ-10](BJ-10-tieu-huy-hang.md) | [UC-10-01](../use-cases/UC-10-01-chuan-bi-yeu-cau-tieu-huy.md); [UC-10-02](../use-cases/UC-10-02-phe-duyet-tieu-huy.md); [UC-10-03](../use-cases/UC-10-03-xac-nhan-da-tieu-huy.md); [UC-10-04](../use-cases/UC-10-04-ghi-giam-hang-tieu-huy.md) | [UIF-10](../../../03.design/flows/UIF-10-BJ-10.md) |
| [BJ-11](BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) | [UC-11-01](../use-cases/UC-11-01-xac-dinh-duong-xu-ly.md); [UC-11-02](../use-cases/UC-11-02-huy-operation-chua-thuc-thi.md); [UC-11-03](../use-cases/UC-11-03-chuan-bi-phuong-an-correction.md); [UC-11-04](../use-cases/UC-11-04-phe-duyet-correction.md); [UC-11-05](../use-cases/UC-11-05-ghi-correction-chain.md) | [UIF-11](../../../03.design/flows/UIF-11-BJ-11.md) |
| [BJ-12](BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) | [UC-12-01](../use-cases/UC-12-01-nap-va-kiem-tra-batch-dau-ky.md); [UC-12-02](../use-cases/UC-12-02-ra-soat-va-duyet-batch.md); [UC-12-03](../use-cases/UC-12-03-commit-va-kich-hoat-ton-kho.md) | [UIF-12](../../../03.design/flows/UIF-12-BJ-12.md) |
| [BJ-13](BJ-13-dieu-chinh-gia-tri-hang-nhap.md) | [UC-13-01](../use-cases/UC-13-01-ghi-nhan-dieu-chinh-gia-tri-hang-nhap.md) | [UIF-13](../../../03.design/flows/UIF-13-BJ-13.md) |
| [BJ-14](BJ-14-tinh-va-cong-bo-gia-von.md) | [UC-14-01](../use-cases/UC-14-01-tinh-va-ra-soat-gia-von.md); [UC-14-04](../use-cases/UC-14-04-cong-bo-gia-von.md) | [UIF-14](../../../03.design/flows/UIF-14-BJ-14.md) |
| [BJ-15](BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) | [UC-15-01](../use-cases/UC-15-01-xac-dinh-bao-cao-va-pham-vi.md); [UC-15-02](../use-cases/UC-15-02-xem-bao-cao-ton-kho.md); [UC-15-03](../use-cases/UC-15-03-xem-the-kho-va-lich-su.md); [UC-15-04](../use-cases/UC-15-04-xuat-bao-cao.md) | [UIF-15](../../../03.design/flows/UIF-15-BJ-15.md) |
| [BJ-16](BJ-16-ieu-tra-va-oi-soat-sai-lech.md) | [UC-16-01](../use-cases/UC-16-01-mo-va-phan-loai-ho-so-doi-soat.md); [UC-16-02](../use-cases/UC-16-02-bao-ve-pham-vi-rui-ro.md); [UC-16-03](../use-cases/UC-16-03-dieu-tra-va-xac-dinh-nguyen-nhan.md); [UC-16-04](../use-cases/UC-16-04-xac-minh-va-cap-nhat-ket-qua-doi-soat.md) | [UIF-16](../../../03.design/flows/UIF-16-BJ-16.md) |
| [BJ-17](BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md) | [UC-17-01](../use-cases/UC-17-01-thu-thap-va-danh-gia-bang-chung.md); [UC-17-02](../use-cases/UC-17-02-xac-lap-operation-da-hoan-tat.md); [UC-17-03](../use-cases/UC-17-03-tiep-tuc-cung-operation-identity.md); [UC-17-04](../use-cases/UC-17-04-giu-chua-xac-dinh-va-escalated.md) | [UIF-17](../../../03.design/flows/UIF-17-BJ-17.md) |

**Navigation rule:** BJ chỉ link tới UIF; không copy Screen Flow. UIF link ngược BJ/UC và sở hữu screen orchestration. UC giữ UI trace nhưng không sở hữu screen anatomy.

## 7. Recovery

```mermaid
flowchart TD
    S["Discrepancy / finality signal"] --> C["BJ-16 — Đối soát"]
    C --> U["BJ-17 — Làm rõ UNKNOWN"]
    U --> C
    C -.->|Cần sửa fact đã commit| B11["BJ-11 — Hủy & sửa sai"]
```

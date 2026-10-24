---
id: PAT-NAV
type: design-pattern
theme: theme-07
title: "Navigation areas"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# PAT-NAV — Navigation areas

## 1. Vấn đề cần giải quyết

Giữ các quy tắc/pattern UI đã được xác lập trong source v3.10.1 cho phạm vi Theme 7.

## 2. Khi nào dùng

Theo phạm vi được mô tả trong nội dung nguồn bên dưới.

## 3. Khi nào không dùng

Không mở rộng ngoài phạm vi nguồn.

## 4. Hành vi bắt buộc

> Baseline **v1.4.3**. NAV area là taxonomy để tổ chức surface; **không đồng nghĩa mọi screen trong area đều là menu/feature entry**. Canonical entry class nằm tại [`entry-architecture.md`](../../06.evidence/design/legacy-contracts/entry-architecture.md).

### Product entry rule

Chỉ `MODULE_ENTRY` mới mặc định global-discoverable. `CONTEXTUAL_ONLY`, `CONTEXTUAL_DEEP_LINK`, `ACTOR_HANDOFF_TASK`, `IN_FLOW_SURFACE`, `SYSTEM_RECOVERY` và `RESULT` phải xuất hiện từ đúng parent/task/state; không được tự biến thành menu item vì có Screen ID.

| Module entry reviewed | Screen | Product meaning |
|---|---|---|
| Tồn kho | `SCR-001` | Tra cứu tồn/khả dụng |
| Nhận hàng | `SCR-007` | Chứng từ chờ nhận + dòng "Hàng đến chưa có chứng từ" (nhập nhanh); document context có thể deep-link vào goods receipt flow |
| Hàng chờ xác nhận giá nhập | `SCR-014` (UIF03) | Work queue của Inventory Valuation |
| Chi phí mua bổ sung | `SCR-085` (UIF13) | Late-cost source work queue |
| Giá vốn | `SCR-072` (UIF14) | Cost run worklist |
| Lấy hàng | `SCR-025` | Warehouse pick queue |
| Hàng khách trả | `SCR-030` | Warehouse return-receipt queue |
| Trả nhà cung cấp | `SCR-036` (UIF07) | Source-authorized supplier-return queue |

`SCR-021` (BJ04) **không** là module entry; chỉ mở từ context đơn bán. `SCR-011`/`SCR-034` là actor-handoff task. `SCR-013` là recovery only.

### NAV taxonomy

| ID | Khu vực | Mục đích |
|---|---|---|
| `NAV-01` | Tổng quan tồn kho và chỉ báo | Theo dõi tồn, khả dụng, lô/hạn và chỉ báo vận hành. |
| `NAV-02` | Tác nghiệp kho | Nhận, lấy, hàng khách trả, trả NCC và các in-flow operational surfaces. |
| `NAV-03` | Kiểm soát và phục hồi | Phê duyệt, sửa sai, đối soát và phục hồi; phần lớn không phải module entry. |
| `NAV-04` | Giá trị và giá vốn | Xác nhận giá nhập, chi phí mua đến muộn và công bố giá vốn. |
| `NAV-05` | Báo cáo và truy vết | Tra cứu thẻ kho, biến động, provenance và xuất báo cáo. |
| `NAV-06` | Thiết lập và khởi tạo | Chính sách tồn/cận hạn và số dư đầu kỳ. |

### Danh mục theo khu vực

#### NAV-01 — Tổng quan tồn kho và chỉ báo

**Active full-screen surfaces của BJ-01 v0.3.2**

- [`SCR-001` — Tồn kho](../screens/SCR-001.md)
- [`SCR-003` — Chi tiết tồn kho](../screens/SCR-003.md)

**Contextual / migration artifacts**

- [`SCR-004` — Chi tiết lô](../screens/SCR-004.md): LOT Detail Bottom Sheet trong `SCR-003`.
- [`SCR-005` — Nguồn và thời điểm cập nhật](../screens/SCR-005.md): Provenance Bottom Sheet trong `SCR-003`.
- `SCR-002`, `SCR-060`, `SCR-061`: quan hệ BJ-01 đã merge vào `SCR-001/003`; ID vẫn được giữ cho migration hoặc BJ khác.

#### NAV-02 — Tác nghiệp kho

**Module entry**

- [`SCR-007` — Nhận hàng](../screens/SCR-007.md) — BJ02 (SCR-006 đã gộp vào).
- [`SCR-025` — Đơn cần lấy hàng](../screens/SCR-025.md) — BJ05.
- [`SCR-030` — Yêu cầu khách trả](../screens/SCR-030.md) — BJ06 maker queue.
- [`SCR-036` — Hàng cần xử lý](../screens/SCR-036.md) — UIF07 mode là supplier-return queue.

**Contextual / in-flow**

- BJ02: `SCR-007`, `SCR-008`, `SCR-009`, `SCR-084`, `SCR-010`. `SCR-009` có thể là contextual deep-link khi Purchase document đã biết.
- BJ04: [`SCR-021` — Giữ hàng theo đơn](../screens/SCR-021.md) là **CONTEXTUAL_ONLY từ đơn bán**, read-only projection.
- BJ05: `SCR-026`, `SCR-028`.
- BJ06 maker: `SCR-031`, `SCR-032`, `SCR-033`.
- BJ07: `SCR-037`, `SCR-039`; `SCR-038` không thuộc active UIF07.
- Inventory audit/control operational surfaces `SCR-038`, `SCR-040`, `SCR-042`–`SCR-047` giữ context theo UIF tương ứng.

**Actor handoff / result / recovery — không phải menu destination**

- [`SCR-011`](../screens/SCR-011.md) — receiving approver task.
- [`SCR-034`](../screens/SCR-034.md) — wrong-LOT approver task.
- `SCR-012`, `SCR-029`, `SCR-035`, `SCR-041`, `SCR-047` — result/finality surfaces.
- [`SCR-013`](../screens/SCR-013.md) — recovery only, chỉ từ UNKNOWN.

**Retired khỏi active UIF04**

- `SCR-020`, `SCR-022`, `SCR-023`, `SCR-024` chỉ là migration/historical contracts; không được đưa lại vào flow hoặc navigation của BJ04.

#### NAV-03 — Kiểm soát và phục hồi

- [`SCR-048` — Danh sách operation](../screens/SCR-048.md)
- [`SCR-049` — Chi tiết operation](../screens/SCR-049.md)
- [`SCR-050` — Nháp và gửi operation](../screens/SCR-050.md)
- [`SCR-051` — Quyết định phê duyệt](../screens/SCR-051.md)
- [`SCR-052` — Hủy hoặc sửa sai](../screens/SCR-052.md)
- [`SCR-053` — Kết quả kiểm soát operation](../screens/SCR-053.md)
- [`SCR-078` — Hồ sơ cần đối soát](../screens/SCR-078.md)
- [`SCR-079` — Bằng chứng đối soát](../screens/SCR-079.md)
- [`SCR-080` — Chọn hành động phục hồi](../screens/SCR-080.md)
- [`SCR-081` — Tiến độ dựng lại](../screens/SCR-081.md)
- [`SCR-082` — Rà soát kết quả](../screens/SCR-082.md)
- [`SCR-083` — Kết quả đối soát](../screens/SCR-083.md)

#### NAV-04 — Giá trị và giá vốn

**BJ03 — Xác nhận giá nhập ban đầu**

- [`SCR-014` — Hàng chờ xác nhận giá nhập](../screens/SCR-014.md) — module entry.
- [`SCR-015` — Chọn hàng cần xác nhận giá](../screens/SCR-015.md) — contextual/in-flow scope.
- `SCR-016` — historical/migration identity; cách tính là sheet "Cách tính" trên SCR-015. (xem [`RETIRED.md`](../screens/RETIRED.md))
- `SCR-017` — đã gộp vào SCR-015: xác nhận cuối là sheet "Ghi giá trị nhập ban đầu?" (xem [`RETIRED.md`](../screens/RETIRED.md)).
- [`SCR-019` — Kết quả xác nhận giá](../screens/SCR-019.md) — result/finality.

**BJ13 — Chi phí mua bổ sung (v1.4.5 dedicated flow)**

- [`SCR-085` — Chi phí mua bổ sung](../screens/SCR-085.md) — module work queue.
- [`SCR-086` — Nguồn và phạm vi chi phí](../screens/SCR-086.md) — source task / 1..N receipt-line scope.
- [`SCR-087` — Phân bổ chi phí](../screens/RETIRED.md) — server preview, in-flow.
- [`SCR-088` — Rà soát ghi chi phí](../screens/RETIRED.md) — single final commit surface.
- [`SCR-089` — Kết quả ghi chi phí](../screens/SCR-089.md) — result/finality; dirty scope handoff cho BJ14.
- `SCR-018` retired khỏi active UIF13; giữ historical/migration trace. (xem [`RETIRED.md`](../screens/RETIRED.md))

**BJ14 — Tính và công bố giá vốn (v1.5.0)**

- [`SCR-072` — Giá vốn](../screens/SCR-072.md) — module worklist.
- [`SCR-073` — Thiết lập lần tính](../screens/RETIRED.md) — setup/create immutable run.
- [`SCR-074` — Kết quả lần tính](../screens/SCR-074.md) — CALCULATING/BLOCKED/READY state surface.
- [`SCR-076` — Rà soát công bố](../screens/RETIRED.md) — final publish review.
- [`SCR-077` — Kết quả công bố](../screens/SCR-077.md) — result/finality.
- `SCR-075` retired khỏi active UIF14; giữ historical/migration trace. (xem [`RETIRED.md`](../screens/RETIRED.md))

#### NAV-05 — Báo cáo và truy vết

- [`SCR-054` — Tra cứu thẻ kho](../screens/SCR-054.md)
- [`SCR-055` — Danh sách biến động](../screens/SCR-055.md)
- [`SCR-056` — Chi tiết movement](../screens/SCR-056.md)
- [`SCR-057` — Dòng thời gian nguồn](../screens/SCR-057.md)
- [`SCR-058` — Rà soát bản xuất](../screens/SCR-058.md)
- [`SCR-059` — Kết quả xuất báo cáo](../screens/SCR-059.md)

#### NAV-06 — Thiết lập và khởi tạo

- [`SCR-062` — Ngưỡng tồn](../screens/SCR-062.md)
- [`SCR-063` — Cận hạn](../screens/SCR-063.md)
- [`SCR-064` — Rà soát chính sách](../screens/RETIRED.md) — đã thành sheet tác động trong SCR-062.
- [`SCR-065` — Kết quả cập nhật chính sách](../screens/SCR-065.md)
- [`SCR-066` — Các batch số dư đầu kỳ](../screens/SCR-066.md)
- [`SCR-067` — Nạp file và thiết lập cut-off](../screens/SCR-067.md)
- [`SCR-068` — Kiểm tra dữ liệu](../screens/SCR-068.md)
- [`SCR-069` — Rà soát và gửi duyệt](../screens/RETIRED.md) — đã gộp vào SCR-068.
- [`SCR-070` — Xác nhận kích hoạt](../screens/SCR-070.md)
- [`SCR-071` — Báo cáo kích hoạt](../screens/SCR-071.md)

## 5. Bố cục / tương tác chuẩn

Xem mục 4 và Screen Contracts.

## 6. Phần được phép thay đổi

Chỉ dữ liệu/copy/variant được nguồn và DS cho phép.

## 7. Mapping với Design System

Xem `../design-system/design-system-profile.md`.

## 8. Screen tham chiếu

Xem `../screens/`.

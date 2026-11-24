---
id: KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung
type: know-how
theme: theme-07
title: giu-hang-va-xu-ly-don-khong-du-ton-kha-dung
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung — giu-hang-va-xu-ly-don-khong-du-ton-kha-dung

## 1. Bối cảnh

### Câu trả lời ngắn

Theme 7 chỉ tạo Reservation cho **Advanced Stock** khi source gửi explicit `reservation_policy`. `NONE` không tạo giữ hàng; `ALL_OR_NOTHING` thiếu là reject toàn bộ; `PARTIAL_ALLOWED` giữ phần hợp lệ và trả shortage. POS hiện tại dùng `NONE`. Reservation giữ ở Product + Warehouse, chưa khóa LOT. Current hold và cumulative consumed là hai fact riêng; hàng đã handover không còn nằm trong ReservationBucket. Khi capacity giảm, Theme 7 phân lại theo priority/confirmed-at/stable source line, nhưng không sửa active PickAllocation; BJ-05 revalidate allocation khi nhận review signal.

## 2. Nội dung nền tảng

### Ba boundary cần nhớ

| Lớp | Owner | Ý nghĩa |
|---|---|---|
| Commercial order intent | Sales/source | Có cần giữ, policy nào, requested quantity/UOM, priority |
| Reservation capacity | Theme 7 / BJ-04 | Current quantity đang giữ ở Product + Warehouse |
| LOT allocation / handover | Theme 7 / BJ-05 | Chọn LOT, pick, physical correction, consume/issue |

### Quantity model

- `requested_quantity`: source UOM.
- `requested_base_quantity`: normalize bằng conversion snapshot/version.
- `reserved_base_quantity`: current held, chưa consume/release.
- `consumed_base_quantity`: committed handover/issue cộng dồn.
- `remaining_required = max(0, requested - consumed)`.
- `shortage = max(0, remaining_required - reserved)`.

ReservationBucket chỉ cộng **current held**.

### Policy

#### `NONE`
Không tạo Reservation. POS online hiện tại thuộc nhánh này và check/issue trong checkout.

#### `ALL_OR_NOTHING`
Phải giữ đủ toàn scope bắt buộc. Thiếu bất kỳ phần nào → reject toàn bộ, bucket không đổi.

#### `PARTIAL_ALLOWED`
Giữ current capacity hợp lệ và trả shortage về đúng source line/combo. Không tự top-up khi hàng về thêm; source phải gửi amend/re-evaluate mới.

### Priority khi capacity giảm

1. `reservation_priority`;
2. source confirmed earlier first;
3. stable `source_line_id` tie-break.

Không dùng update time/DB order làm priority.

### Combo

Combo dùng ReservationGroup + child component reservations. Chỉ giữ số nguyên combo; commit nguyên tử toàn component. Ví dụ combo `2A + 1B`, cần 3 bộ nhưng capacity chỉ cho 2 bộ thì giữ `4A + 2B`, không giữ `5A + 2B`.

### Sau khi đã pick

BJ-04 không release/supersede PickAllocation trực tiếp. Reservation change phát `allocation_review_required`; BJ-05 quyết định allocation version mới và physical correction nếu user đã cầm hàng.

### Expiry của reservation

Không implicit TTL. `expires_at` chỉ được dùng khi source contract sở hữu thời hạn; đến hạn đi cùng idempotent release path với reason `SOURCE_EXPIRY`.

### UI

Reservation không phải module Inventory độc lập. SCR-021 chỉ là projection contextual từ source order có reservation context và hiển thị current facts theo từng line. Không show STALE/global FULL/PARTIAL/RELEASED như business state của cả màn.

### Những cách làm sai

- Giảm physical khi giữ.
- Khóa LOT ngay lúc reserve.
- Auto top-up khi hàng về thêm mà source không gửi command mới.
- Dùng `reserved` để chứa cả lượng đã handover.
- Sửa PickAllocation từ BJ-04.
- Tạo Theme 7 Reservation cho Basic Stock hoặc POS policy `NONE`.

## 3. Ý nghĩa đối với Theme



## 4. Nguồn tham khảo

### Nguồn quyết định

`T7-DR-029`, `T7-DR-031`, `T7-DR-032`, `T7-DR-033`, `T7-DR-106`, `T7-DR-144…149`.

## 5. Liên kết liên quan

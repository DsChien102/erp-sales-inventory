---
id: UC-04-02
type: use-case
theme: theme-07
title: "Điều chỉnh reservation"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-04
---
# UC-04-02 — Điều chỉnh reservation

## 1. Mục tiêu và kết quả nghiệp vụ

Đưa current hold về mức phù hợp với source version mới mà không sửa consumed history và không tự thay PickAllocation của BJ05.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Source requested quantity/version tăng hoặc giảm.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Reservation version mới phản ánh requested/current hold hiện hành; BJ05 được signal nếu allocation cần review.

### 2.3 Không bao gồm

- Không chọn LOT/pick allocation; đó là BJ05.
- Không tạo reservation cho Basic Stock hoặc policy `NONE`.
- Không sửa source order/requested quantity; Theme 7 chỉ phản ánh source version đã nhận.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Source system / system process; người dùng Inventory chủ yếu xem trạng thái/kết quả.
- **Thẩm quyền:** Source sở hữu requested quantity/lifecycle; Theme 7 sở hữu current hold/capacity effect.
- **Sự kiện khởi phát:** Source requested quantity/version tăng hoặc giảm.
- **Điều kiện trước:** source/version current, Advanced Stock và reservation policy hợp lệ; tenant/warehouse scope đúng.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa | Nguồn |
|---|---|---|
| Source line/version | Requested quantity và lifecycle authoritative | Source Theme |
| Reservation | Current hold + consumed history theo source | `DOM-IO` |
| ReservationBucket | Tổng capacity hold authoritative ở Product + warehouse | `DOM-IO` |
| Transaction UOM snapshot | Quantity/precision/conversion version của source | Source + Product policy |
| PickAllocation | Chỉ là downstream reference nếu cần review | BJ05 |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Source system | Gửi source version mới và requested quantity mới. | |
| BF-02 | Hệ thống | Recheck reservation hiện hành, source/version, capability và current consumed quantity. | EF-A — Source stale/capability không áp dụng |
| BF-03 | Hệ thống | Tính target current hold theo requested mới, capacity hiện tại và policy. | AF-A — Giảm lượng giữ<br>AF-B — Tăng nhưng thiếu capacity |
| BF-04 | Hệ thống | Ghi delta current hold vào Reservation/ReservationBucket; consumed history bất biến. | BR-02 | | BF-05| Hệ thống | Nếu active PickAllocation bị ảnh hưởng, phát `allocation_review_required` cho BJ05 thay vì sửa allocation. | BR-07 |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Giảm lượng giữ
**Phát sinh tại:** BF-03.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Release phần current hold vượt target; không giảm `consumed_base_quantity`. | BR-02 | | AF-A-02| — | [Trở lại BF-04]. | |

#### AF-B — Tăng nhưng thiếu capacity
**Phát sinh tại:** BF-03.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-B-01 | Hệ thống | Áp policy partial/all-or-nothing, trả shortage; không hứa auto top-up khi capacity tăng sau đó. | BR-03/04 |
| AF-B-02 | — | [Trở lại BF-04 hoặc kết thúc nếu reject]. | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Source/version không còn hợp lệ
**Phát sinh tại:** BF-02.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject trước mutation; trả version/capability hiện hành để source đồng bộ lại. | |
| EF-A-02 | — | [Kết thúc UC]. | |

#### EF-B — Kết quả mutation chưa xác định
**Phát sinh tại:** BF-04.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ cùng command identity, trả `UNKNOWN`; không gửi adjustment mới mù quáng. | SBC-COM-03 |
| EF-B-02 | — | [Kết thúc/hand-off BJ17 nếu cần]. | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Capability | chỉ `ADVANCED`; `reservation_policy=NONE` không tạo Reservation.| Decision / DOM-IO / BC nguồn |
| BR-02 | Quantity | bảo toàn transaction UOM + precision + conversion version; `reserved_base_quantity` là current hold, `consumed_base_quantity` là cumulative committed handover.| Decision / DOM-IO / BC nguồn |
| BR-03 | Priority khi thiếu | `reservation_priority` → `source_confirmed_at` cũ hơn → stable `source_line_id`.| Decision / DOM-IO / BC nguồn |
| BR-04 | Không auto top-up | Không auto top-up; source phải gửi amend/re-evaluate version mới.| Decision / DOM-IO / BC nguồn |
| BR-05 | `expires_at` chỉ source-owned | `expires_at` chỉ source-owned; không implicit TTL.| Decision / DOM-IO / BC nguồn |
| BR-06 | Combo commit nguyên tử qua ReservationGroup + child component | Combo commit nguyên tử qua ReservationGroup + child component reservations.| Decision / DOM-IO / BC nguồn |
| BR-07 | Sau active PickAllocation | Sau active PickAllocation, BJ-04 không sửa allocation; chỉ phát `allocation_review_required` cho BJ-05.| Decision / DOM-IO / BC nguồn |
| BR-08 | Tăng | reserve delta theo current policy/capacity; giảm: release current held delta trước, consumed history không âm/không rewrite.| Decision / DOM-IO / BC nguồn |

- `BC-IO-06` — Adjust reservation capacity.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Reservation version mới phản ánh requested/current hold hiện hành; BJ05 được signal nếu allocation cần review. | Reservation tiếp tục lifecycle trong BJ04; allocation/pick nếu có thuộc BJ05 |
| Từ chối | Không thay current hold authoritative | Source sửa/đồng bộ version nếu cần |
| `UNKNOWN` | Không suy diễn commit/no-commit | Reconcile cùng command identity / BJ17 khi cần |

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-04 — Quản lý vòng đời giữ hàng](../../../03.design/flows/UIF-04-BJ-04.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-021` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Điều chỉnh reservation”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-04-02-01 — Điều chỉnh reservation

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** Source/version và capability hợp lệ
- **When:** Source gửi amend reservation command
- **Then:** Current hold/shortage mới; nếu active allocation bị ảnh hưởng thì `allocation_review_required=true`
### AS-UC-04-02-02 — Điều chỉnh reservation

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** `reservation_policy=NONE` hoặc Basic Stock
- **When:** Source gửi/resolve capability
- **Then:** Không tạo Reservation/ReservationBucket effect; trả result `NOT_REQUIRED`/capability boundary
### AS-UC-04-02-03 — Điều chỉnh reservation

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** Cùng idempotency identity được gửi lại
- **When:** Adapter retry
- **Then:** Trả cùng result hoặc payload conflict; không tạo effect trùng
### AS-UC-04-02-04 — Điều chỉnh reservation

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** Không chứng minh được commit/no-commit
- **When:** Client timeout/xử lý gián đoạn
- **Then:** UNKNOWN; giữ cùng identity và reconcile

## 10. Truy vết

- **Journey:** `BJ-04` — Quản lý vòng đời giữ hàng.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `BC-IO-06`.

- **Nguồn quyết định:** [G04 — Khả dụng, giữ hàng, lấy hàng và xuất](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t) · `T7-DR-144…149`

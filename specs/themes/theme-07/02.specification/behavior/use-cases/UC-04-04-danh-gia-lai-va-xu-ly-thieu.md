---
id: UC-04-04
type: use-case
theme: theme-07
title: "Đánh giá lại và xử lý thiếu"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---
# UC-04-04 — Đánh giá lại và xử lý thiếu

## 1. Mục tiêu và kết quả nghiệp vụ

Giảm current hold về capacity hợp lệ theo priority, trả shortage và báo BJ05 review allocation nếu cần; không tự top-up khi capacity tăng lại.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Eligibility/capacity giảm hoặc source explicit yêu cầu re-evaluate.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Current holds phù hợp capacity hiện tại; shortage rõ theo source; allocation cần review được bàn giao BJ05.

### 2.3 Không bao gồm

- Không chọn LOT/pick allocation; đó là BJ05.
- Không tạo reservation cho Basic Stock hoặc policy `NONE`.
- Không sửa source order/requested quantity; Theme 7 chỉ phản ánh source version đã nhận.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Source system / system process; người dùng Inventory chủ yếu xem trạng thái/kết quả.
- **Thẩm quyền:** Source sở hữu requested quantity/lifecycle; Theme 7 sở hữu current hold/capacity effect.
- **Sự kiện khởi phát:** Eligibility/capacity giảm hoặc source explicit yêu cầu re-evaluate.
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
| BF-01 | Hệ thống / Source system | Kích hoạt re-evaluation vì eligibility/capacity giảm hoặc source yêu cầu. | |
| BF-02 | Hệ thống | Recheck capability, source version, ReservationBucket và capacity hiện hành. | EF-A — Không áp dụng/stale |
| BF-03 | Hệ thống | Xếp thứ tự reservation theo priority → source_confirmed_at → stable source_line_id. | BR-03 | | BF-04| Hệ thống | Giảm current hold tối thiểu cần thiết để tổng hold không vượt capacity; tính shortage per source. | BR-08 |
| BF-05 | Hệ thống | Phát `allocation_review_required` cho BJ05 nếu active PickAllocation bị ảnh hưởng; không sửa LOT allocation tại BJ04. | BR-07 | | BF-06| — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Capacity tăng lại sau đó
**Phát sinh sau BF-04. **Điều kiện:** availability tăng ở thời điểm sau.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Không tự top-up reservation đã bị giảm; chờ source amend/re-evaluate command mới. | BR-09 | | AF-A-02| — | [Kết thúc UC]. | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Capability/source không còn hợp lệ
**Phát sinh tại:** BF-02.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject trước mutation và trả current version/capability. | |
| EF-A-02 | — | [Kết thúc UC]. | |

#### EF-B — Kết quả mutation chưa xác định
**Phát sinh tại:** BF-04.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ cùng identity, trả `UNKNOWN` và reconcile trước retry. | SBC-COM-03 |
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
| BR-08 | Eligibility giảm | phân capacity theo priority/confirmed_at/stable ID; chỉ giảm current held cần thiết.| Decision / DOM-IO / BC nguồn |
| BR-09 | Eligibility tăng sau đó không tự top-up. | Eligibility tăng sau đó không tự top-up.| Decision / DOM-IO / BC nguồn |

- `BC-IO-06` — Adjust reservation capacity.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Current holds phù hợp capacity hiện tại; shortage rõ theo source; allocation cần review được bàn giao BJ05. | Reservation tiếp tục lifecycle trong BJ04; allocation/pick nếu có thuộc BJ05 |
| Từ chối | Không thay current hold authoritative | Source sửa/đồng bộ version nếu cần |
| `UNKNOWN` | Không suy diễn commit/no-commit | Reconcile cùng command identity / BJ17 khi cần |

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-021` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Đánh giá lại và xử lý thiếu”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-04-04-01 — Đánh giá lại và xử lý thiếu

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** Source/version và capability hợp lệ
- **When:** System/source kích hoạt re-evaluation
- **Then:** Current held được xác lập lại + shortage; không auto top-up sau khi capacity tăng nếu source chưa gửi command mới
### AS-UC-04-04-02 — Đánh giá lại và xử lý thiếu

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** `reservation_policy=NONE` hoặc Basic Stock
- **When:** Source gửi/resolve capability
- **Then:** Không tạo Reservation/ReservationBucket effect; trả result `NOT_REQUIRED`/capability boundary
### AS-UC-04-04-03 — Đánh giá lại và xử lý thiếu

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** Cùng idempotency identity được gửi lại
- **When:** Adapter retry
- **Then:** Trả cùng result hoặc payload conflict; không tạo effect trùng
### AS-UC-04-04-04 — Đánh giá lại và xử lý thiếu

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** Không chứng minh được commit/no-commit
- **When:** Client timeout/xử lý gián đoạn
- **Then:** UNKNOWN; giữ cùng identity và reconcile

## 10. Truy vết

- **Journey:** `BJ-04` — Quản lý vòng đời giữ hàng.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `BC-IO-06`.

- **Nguồn quyết định:** [G04 — Khả dụng, giữ hàng, lấy hàng và xuất](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t) · `T7-DR-144…149`

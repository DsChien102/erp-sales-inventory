---
id: UC-04-01
type: use-case
theme: theme-07
title: "Tạo reservation"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-04
---
# UC-04-01 — Tạo reservation

## 1. Mục tiêu và kết quả nghiệp vụ

Tạo current hold cho đúng source line/combo theo capacity/policy, trả shortage nếu thiếu và tạo Reservation/ReservationGroup version đầu tiên.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Source line/version có explicit reservation policy và cần giữ hàng.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Tạo reservation thành công, source nhận current hold/shortage; sau đó reservation được điều chỉnh/consume/release theo lifecycle.

### 2.3 Không bao gồm

- Không chọn LOT/pick allocation; đó là BJ05.
- Không tạo reservation cho Basic Stock hoặc policy `NONE`.
- Không sửa source order/requested quantity; Theme 7 chỉ phản ánh source version đã nhận.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Source system / system process; người dùng Inventory chủ yếu xem trạng thái/kết quả.
- **Thẩm quyền:** Source sở hữu requested quantity/lifecycle; Theme 7 sở hữu current hold/capacity effect.
- **Sự kiện khởi phát:** Source line/version có explicit reservation policy và cần giữ hàng.
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
| BF-01 | Source system | Gửi yêu cầu giữ hàng với source line/version, requested quantity, transaction UOM snapshot và reservation policy. | |
| BF-02 | Hệ thống | Xác nhận capability `ADVANCED`, source/version, warehouse và policy current. | EF-A — Không cần/không đủ điều kiện |
| BF-03 | Hệ thống | Tính capacity có thể giữ theo availability và priority; với combo kiểm đủ component trong cùng atomic boundary. | AF-A — Partial allowed<br>EF-B — All-or-nothing thiếu capacity |
| BF-04 | Hệ thống | Ghi Reservation/ReservationGroup và ReservationBucket current hold; không tự chọn LOT. | EF-C — UNKNOWN |
| BF-05 | Hệ thống | Trả quantity đã giữ, shortage và reservation version. | |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Partial allowed
**Phát sinh tại:** BF-03. **Điều kiện:** policy cho phép partial và capacity nhỏ hơn requested.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Giữ đúng capacity hiện có và trả shortage cho source; không auto top-up về sau. | BR-03/04 |
| AF-A-02 | — | [Trở lại BF-04]. | |


### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Reservation không áp dụng
**Phát sinh tại:** BF-02. **Điều kiện:** Basic Stock hoặc `reservation_policy=NONE`.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Trả `NOT_REQUIRED`, không tạo Reservation/ReservationBucket effect. | BR-01 | | EF-A-02| — | [Kết thúc UC]. | |

#### EF-B — ALL_OR_NOTHING thiếu capacity
**Phát sinh tại:** BF-03.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Reject toàn yêu cầu; không giữ bán phần và bucket không đổi. | BR-08 | | EF-B-02| — | [Kết thúc UC]. | |

#### EF-C — Kết quả mutation chưa xác định
**Phát sinh tại:** BF-04.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-C-01 | Hệ thống | Giữ cùng command identity, trả `UNKNOWN` và verify trước retry. | SBC-COM-03 |
| EF-C-02 | — | [Kết thúc/hand-off BJ17 nếu cần]. | |

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
| BR-08 | `ALL_OR_NOTHING` | thiếu bất kỳ component/capacity bắt buộc nào thì reject toàn bộ và bucket không đổi.| Decision / DOM-IO / BC nguồn |
| BR-09 | `PARTIAL_ALLOWED` | giữ current capacity hợp lệ và trả shortage theo source line/combo.| Decision / DOM-IO / BC nguồn |

- `BC-IO-03` — Reserve order quantity.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Tạo reservation thành công, source nhận current hold/shortage; sau đó reservation được điều chỉnh/consume/release theo lifecycle. | Reservation tiếp tục lifecycle trong BJ04; allocation/pick nếu có thuộc BJ05 |
| Từ chối | Không thay current hold authoritative | Source sửa/đồng bộ version nếu cần |
| `UNKNOWN` | Không suy diễn commit/no-commit | Reconcile cùng command identity / BJ17 khi cần |

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-04 — Quản lý vòng đời giữ hàng](../../../03.design/flows/UIF-04-BJ-04.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-021` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Tạo reservation”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-04-01-01 — Tạo reservation

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** Source/version và capability hợp lệ
- **When:** Source gửi create reservation command
- **Then:** Full/partial current hold + shortage hoặc atomic rejection; Reservation/ReservationGroup version đầu tiên
### AS-UC-04-01-02 — Tạo reservation

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** `reservation_policy=NONE` hoặc Basic Stock
- **When:** Source gửi/resolve capability
- **Then:** Không tạo Reservation/ReservationBucket effect; trả result `NOT_REQUIRED`/capability boundary
### AS-UC-04-01-03 — Tạo reservation

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** Cùng idempotency identity được gửi lại
- **When:** Adapter retry
- **Then:** Trả cùng result hoặc payload conflict; không tạo effect trùng
### AS-UC-04-01-04 — Tạo reservation

- **Bao phủ:** BF-01 → BF-06; AF-A/EF-A/EF-B.
- **Given:** Không chứng minh được commit/no-commit
- **When:** Client timeout/xử lý gián đoạn
- **Then:** UNKNOWN; giữ cùng identity và reconcile

## 10. Truy vết

- **Journey:** `BJ-04` — Quản lý vòng đời giữ hàng.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `BC-IO-03`.

- **Nguồn quyết định:** [G04 — Khả dụng, giữ hàng, lấy hàng và xuất](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t) · `T7-DR-144…149`
- **Bài tri thức liên quan:** [KB-KGV-005 — Tồn vật lý, lượng đủ điều kiện bán, lượng giữ và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [KB-KGV-009 — Giữ hàng và xử lý đơn không đủ tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [KB-KGV-027 — Vòng đời của một Inventory Operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)

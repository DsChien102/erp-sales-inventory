---
id: UC-05-05
type: use-case
theme: theme-07
title: "Ghi xuất kho nguyên tử"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-05
---

# UC-05-05 — Ghi xuất kho nguyên tử

## 1. Mục tiêu và kết quả nghiệp vụ

Ghi xuất kho nguyên tử đúng lượng đã bàn giao, đồng thời consume reservation và ghi value movement theo giá vốn đang có hiệu lực.

**Kết quả cần đạt:** Quantity/value movement, balance và reservation consumption commit đúng một lần; hoặc toàn operation bị reject/UNKNOWN.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có lô/nguồn xuất hợp lệ và allocation khi hành trình yêu cầu

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Movement, balance, reservation nếu có và cost snapshot cùng commit; Inventory issue result dùng chung.

### 2.3 Không bao gồm

Không sửa đơn bán, allocation hay chứng từ bàn giao để hợp thức hóa kết quả. UC chỉ consume reservation và ghi giảm tồn/movement đúng một lần theo dữ liệu đã được xác nhận.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Người dùng có thẩm quyền hoặc hệ thống nguồn.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có lô/nguồn xuất hợp lệ và allocation khi hành trình yêu cầu.
- **Điều kiện trước:** Đối tượng đúng version đã đạt trạng thái sẵn sàng thực thi; quyền, policy, lock và các invariant nguồn còn hợp lệ tại thời điểm commit.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Nguồn nghiệp vụ và phiên bản | Định danh nguồn/đối tượng nghiệp vụ và phiên bản hiện hành cần dùng để tránh xử lý trên dữ liệu cũ. | DOM-IO / BC liên quan |
| Dữ liệu nghiệp vụ | Các dữ kiện người dùng/nguồn cung cấp cho mục tiêu của Use Case; phải tuân theo rule ở mục 6. | DOM-IO / BC liên quan |
| Phạm vi thực hiện | Tác nhân và phạm vi tenant/cửa hàng/kho mà yêu cầu được phép xử lý. | DOM-IO / BC liên quan |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Hệ thống | Nhận handover assertion cùng active allocation/pick/source version. |  |
| BF-02 | Hệ thống | Recheck current reservation, allocation version, quantity, LOT eligibility và official cost version có hiệu lực. | EF-A — Stale/không đủ điều kiện |
| BF-03 | Hệ thống | Ghi quantity movement giảm và value movement theo official cost hiện hành cho đúng lượng bàn giao. |  |
| BF-04 | Hệ thống | Consume reservation tương ứng, cập nhật balance và outbox/result trong cùng transaction. | EF-B — Kết quả commit chưa xác định |
| BF-05 | Hệ thống | Trả committed handover/inventory result cho source consumer. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Stale hoặc không đủ điều kiện
**Phát sinh tại:** BF-02. **Điều kiện:** Allocation/source/reservation đã thay đổi hoặc quantity/lô không còn hợp lệ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject trước commit; không ghi quantity/value/consume bán phần. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả commit chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không chứng minh được transaction đã commit hay rollback .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ operation identity, trả `UNKNOWN` và verify/BJ17 trước retry. | |
| EF-B-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Không có official cost | Chặn checkout và yêu cầu hoàn tất định giá; không ghi COGS bằng 0 hoặc giá dự kiến| Decision / DOM-IO / BC nguồn |
| BR-02 | Chọn lô | FEFO khi có hạn dùng, FIFO khi không có; override cần quyền và lý do| Decision / DOM-IO / BC nguồn |
| BR-03 | Cạnh tranh tồn | Giao dịch ghi nhận trước được ưu tiên; yêu cầu sau phải kiểm lại và có thể bị từ chối| Decision / DOM-IO / BC nguồn |
| BR-04 | Combo | Mọi component xuất all-or-nothing theo số nguyên combo| Decision / DOM-IO / BC nguồn |
| BR-05 | UNKNOWN | Sales chuyển INVENTORY_CONFIRMATION_PENDING; không tạo issue thứ hai, không tự hoàn tất đơn hay refund| Decision / DOM-IO / BC nguồn |
| BR-06 | Payment | Nếu payment đã có trước UNKNOWN, Payment/Sales giữ trạng thái pending resolution theo contract liên miền| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-04` — Complete online POS checkout.
- `BC-IO-05` — Pick and hand over fulfillment.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Quantity/value movement, balance và reservation consumption commit đúng một lần; hoặc toàn operation bị reject/UNKNOWN. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Quantity/value movement, balance và reservation consumption commit đúng một lần; hoặc toàn operation bị reject/UNKNOWN.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-05 — Lấy hàng và bàn giao đơn](../../../03.design/flows/UIF-05-BJ-05.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-028` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi xuất kho nguyên tử”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-029` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi xuất kho nguyên tử”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-05-05-01 — Ghi xuất kho nguyên tử — luồng chính
- **Given:** Có lô/nguồn xuất hợp lệ và allocation khi hành trình yêu cầu
- **When:** Nhận handover assertion cùng active allocation/pick/source version.
- **Then:** Quantity/value movement, balance và reservation consumption commit đúng một lần; hoặc toàn operation bị reject/UNKNOWN.

### AS-UC-05-05-02 — Ghi xuất kho nguyên tử — Stale hoặc không đủ điều kiện
- **Given:** Allocation/source/reservation đã thay đổi hoặc quantity/lô không còn hợp lệ.
- **When:** Hệ thống phát hiện điều kiện “Stale hoặc không đủ điều kiện” tại BF-02.
- **Then:** Reject trước commit; không ghi quantity/value/consume bán phần. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-05-05-03 — Ghi xuất kho nguyên tử — Kết quả commit chưa xác định
- **Given:** Không chứng minh được transaction đã commit hay rollback.
- **When:** Hệ thống phát hiện điều kiện “Kết quả commit chưa xác định” tại BF-04.
- **Then:** Giữ operation identity, trả `UNKNOWN` và verify/BJ17 trước retry. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-05` — Lấy hàng và bàn giao đơn.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-04`, `BC-IO-05`.

- **Nguồn quyết định:** [Nhóm G01 — Phạm vi, thẩm quyền và mô hình tồn](../../../01.knowledge/decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho); [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t)
- **Bài tri thức liên quan:** [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Công bố đơn giá tồn kho và ghi nhận giá vốn xuất bán](../../../01.knowledge/know-how/KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Bán hàng POS offline](../../../01.knowledge/know-how/KB-KGV-039-ban-hang-pos-offline.md); [Giữ hàng và xử lý đơn không đủ tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)

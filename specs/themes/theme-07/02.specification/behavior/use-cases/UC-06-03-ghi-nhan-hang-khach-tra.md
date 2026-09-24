---
id: UC-06-03
type: use-case
theme: theme-07
title: "Ghi nhận hàng khách trả"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-06-03 — Ghi nhận hàng khách trả

## 1. Mục tiêu và kết quả nghiệp vụ

Ghi lượng hàng khách thực tế trả vào tồn vật lý ở `RETURN_PENDING` cùng giá trị theo căn cứ kỳ xuất gốc, trước khi phân loại sử dụng tiếp.

**Kết quả cần đạt:** Return receipt, quantity/value movement và balance commit nguyên tử cho lượng thực nhận; hoặc không có effect.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Các dòng thực nhận đã hợp lệ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Toàn yêu cầu được commit vào `RETURN_PENDING` hoặc không có gì commit; Return receipt có quantity/value provenance.

### 2.3 Không bao gồm

Không sửa giao dịch bán gốc và không tự đưa hàng trả về trạng thái bán được. UC chỉ ghi lượng thực nhận vào RETURN_PENDING cùng movement/value movement theo rule đã khóa.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho; bộ phận trả hàng cung cấp ý định thương mại.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Các dòng thực nhận đã hợp lệ.
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
| BF-01 | Thủ kho | Xác nhận các dòng/lô thực tế đã nhận lại từ khách sau bước eligibility. |  |
| BF-02 | Hệ thống | Recheck return cap, source sale/version, LOT identity và phạm vi ngoại lệ đã được duyệt. | EF-A — Vượt trần hoặc source stale |
| BF-03 | Hệ thống | Ghi quantity movement tăng vào `RETURN_PENDING` và value movement theo giá đã đối soát của kỳ xuất gốc/snapshot fallback theo decision. |  |
| BF-04 | Hệ thống | Cập nhật balance, return receipt và outbox/result trong cùng transaction. | EF-B — Kết quả commit chưa xác định |
| BF-05 | Hệ thống | Trả receipt result và chuyển hàng thực nhận sang UC-06-04 để phân loại. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Vượt trần hoặc source stale
**Phát sinh tại:** BF-02. **Điều kiện:** Tổng lượng trả vượt lượng đã giao còn được phép nhận hoặc source đã thay đổi .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject toàn phần vượt/không hợp lệ trước commit; không cộng tồn. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả commit chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không chứng minh được receipt transaction đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ operation identity, trả `UNKNOWN` và verify trước retry. | |
| EF-B-02 | — | [Kết thúc/hand-off BJ17.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Trần trả | Mỗi line commit actual quantity trong `0.remaining_authorized_quantity` của ReturnExchangeLine hiện hành và cumulative cap dòng giao gốc; request phải có ít nhất một actual quantity > 0. Toàn mutation của một receipt attempt commit/rollback cùng nhau| Decision / DOM-IO / BC nguồn |
| BR-02 | Combo | Chỉ thành phần thực nhận tăng tồn; không tạo tồn combo; các dòng trong cùng yêu cầu nhận trả commit hoặc rollback cùng nhau| Decision / DOM-IO / BC nguồn |
| BR-03 | Lô | Product theo LOT phải giữ source LOT allocation và actual LOT đã resolve/physical-verify; wrong-LOT chỉ hợp lệ khi current `LINE_EXCEPTION` case đúng subject snapshot/hash đã APPROVED. Receipt recheck source version, UOM precision, LOT version/data integrity và cumulative cap trước commit| Decision / DOM-IO / BC nguồn |
| BR-04 | Mốc ghi giá trị | Ghi value movement cùng lúc nhận vật lý vào RETURN_PENDING; phân loại không ghi giá trị lần hai| Decision / DOM-IO / BC nguồn |
| BR-05 | Căn cứ giá | Dùng giá đã đối soát của sản phẩm và kỳ xuất gốc; nếu kỳ gốc chưa đối soát thì dùng snapshot tại lần xuất và giữ liên kết để điều chỉnh theo policy| Decision / DOM-IO / BC nguồn |
| BR-06 | Kết quả | authoritative result giữ source return request + SalesOrder + per-line Product/UOM/LOT/actual quantity và `recorded_at`; internal operation/correlation/version không show mặc định| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-07` — Receive customer return.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Return receipt, quantity/value movement và balance commit nguyên tử cho lượng thực nhận; hoặc không có effect. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Return receipt, quantity/value movement và balance commit nguyên tử cho lượng thực nhận; hoặc không có effect.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-031` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi nhận hàng khách trả”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-032` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi nhận hàng khách trả”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-035` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi nhận hàng khách trả”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-06-03-01 — Ghi nhận hàng khách trả — luồng chính
- **Given:** Các dòng thực nhận đã hợp lệ
- **When:** Xác nhận các dòng/lô thực tế đã nhận lại từ khách sau bước eligibility.
- **Then:** Return receipt, quantity/value movement và balance commit nguyên tử cho lượng thực nhận; hoặc không có effect.

### AS-UC-06-03-02 — Ghi nhận hàng khách trả — Vượt trần hoặc source stale
- **Given:** Tổng lượng trả vượt lượng đã giao còn được phép nhận hoặc source đã thay đổi.
- **When:** Hệ thống phát hiện điều kiện “Vượt trần hoặc source stale” tại BF-02.
- **Then:** Reject toàn phần vượt/không hợp lệ trước commit; không cộng tồn. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-06-03-03 — Ghi nhận hàng khách trả — Kết quả commit chưa xác định
- **Given:** Không chứng minh được receipt transaction đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả commit chưa xác định” tại BF-04.
- **Then:** Giữ operation identity, trả `UNKNOWN` và verify trước retry. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-06` — Tiếp nhận và phân loại hàng khách trả.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-07`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Hàng khách trả: từ tiếp nhận đến phân loại](../../../01.knowledge/know-how/KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Combo bán hàng và tồn kho theo thành phần](../../../01.knowledge/know-how/KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md)

---
id: UC-06-04
type: use-case
theme: theme-07
title: "Phân loại hàng thực nhận"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-06
---

# UC-06-04 — Phân loại hàng thực nhận

## 1. Mục tiêu và kết quả nghiệp vụ

Phân loại hàng khách trả đã nằm trong `RETURN_PENDING` sang trạng thái vật lý phù hợp mà không ghi quantity/value lần hai.

**Kết quả cần đạt:** Mỗi lượng hàng trả được chuyển sang trạng thái Đạt/Cách ly/Hỏng/.. theo policy; quantity/value của phiếu nhận hàng không bị ghi lại.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có lượng `RETURN_PENDING`

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Toàn lượng được phân loại hoặc giữ pending với việc cần xử lý; Classification result.

### 2.3 Không bao gồm

Không thay đổi lượng đã nhận và không ghi thêm movement nhận hàng. UC chỉ phân loại trạng thái của lượng trả đã tồn tại để quyết định khả năng sử dụng/xử lý tiếp theo.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho; bộ phận trả hàng cung cấp ý định thương mại.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có lượng `RETURN_PENDING`.
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
| BF-01 | Thủ kho | Mở phiếu nhận hàng của hàng trả đã commit và kiểm tra tình trạng thực tế của từng sản phẩm/lô. |  |
| BF-02 | Thủ kho | Phân loại lượng hàng vào trạng thái vật lý phù hợp; tổng phân loại phải bằng lượng phiếu nhận hàng cần xử lý. | EF-A — Tổng phân loại không khớp |
| BF-03 | Hệ thống | Kiểm tra state transition hợp lệ và quyền xử lý với từng trạng thái. |  |
| BF-04 | Hệ thống | Ghi state movement/physical-state balance; không tạo quantity/value movement mới cho phiếu nhận hàng. | EF-B — Kết quả state change chưa xác định |
| BF-05 | Hệ thống | Trả kết quả phân loại và availability được tính lại theo trạng thái mới. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Tổng phân loại không khớp
**Phát sinh tại:** BF-02. **Điều kiện:** Tổng các nhóm tình trạng khác lượng cần phân loại .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho commit; chỉ rõ phần thiếu/thừa để sửa. | |
| EF-A-02 | — | [Trở lại BF-02.] | |

#### EF-B — Kết quả state change chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ state movement đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify cùng operation identity; không ghi state movement thứ hai. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Nguồn | Chỉ phân loại quantity đã authoritative ở `RETURN_PENDING`; `ReturnCondition` từ Theme 5 là declared context, không quyết định output stock state| Decision / DOM-IO / BC nguồn |
| BR-02 | Combo | Chỉ thành phần thực nhận tăng tồn; không tạo tồn combo; các dòng trong cùng yêu cầu nhận trả commit hoặc rollback cùng nhau| Decision / DOM-IO / BC nguồn |
| BR-03 | Lô | Dùng actual LOT/LOT version đã resolve ở phiếu nhận hàng; expiry eligibility được server derive từ authoritative `expiry_date` + tenant business date| Decision / DOM-IO / BC nguồn |
| BR-04 | Mốc ghi giá trị | Ghi value movement cùng lúc nhận vật lý vào RETURN_PENDING; phân loại không ghi giá trị lần hai| Decision / DOM-IO / BC nguồn |
| BR-05 | Căn cứ giá | Dùng giá đã đối soát của sản phẩm và kỳ xuất gốc; nếu kỳ gốc chưa đối soát thì dùng snapshot tại lần xuất và giữ liên kết để điều chỉnh theo policy| Decision / DOM-IO / BC nguồn |
| BR-06 | Phân loại | LOT chưa hết hạn thì `Bán được + Cách ly + Hỏng = pending quantity`; expired quantity = 0. LOT đã hết hạn thì toàn pending quantity = `EXPIRED`, ba lượng user classification = 0 và không có permission override. Không cộng quantity khác UOM thành một tổng. Routine Phase 1 không yêu cầu reason/evidence/approval mặc định| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-08` — Classify returned goods.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Mỗi lượng hàng trả được chuyển sang trạng thái Đạt/Cách ly/Hỏng/.. theo policy; quantity/value của phiếu nhận hàng không bị ghi lại. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Mỗi lượng hàng trả được chuyển sang trạng thái Đạt/Cách ly/Hỏng/.. theo policy; quantity/value của phiếu nhận hàng không bị ghi lại.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-06 — Tiếp nhận và phân loại hàng khách trả](../../../03.design/flows/UIF-06-BJ-06.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-033` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Phân loại hàng thực nhận”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-035` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Phân loại hàng thực nhận”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-06-04-01 — Phân loại hàng thực nhận — luồng chính
- **Given:** Có lượng `RETURN_PENDING`
- **When:** Mở phiếu nhận hàng của hàng trả đã commit và kiểm tra tình trạng thực tế của từng sản phẩm/lô.
- **Then:** Mỗi lượng hàng trả được chuyển sang trạng thái Đạt/Cách ly/Hỏng/.. theo policy; quantity/value của phiếu nhận hàng không bị ghi lại.

### AS-UC-06-04-02 — Phân loại hàng thực nhận — Tổng phân loại không khớp
- **Given:** Tổng các nhóm tình trạng khác lượng cần phân loại.
- **When:** Hệ thống phát hiện điều kiện “Tổng phân loại không khớp” tại BF-02.
- **Then:** Không cho commit; chỉ rõ phần thiếu/thừa để sửa. Luồng chính tiếp tục tại BF-02: Phân loại lượng hàng vào trạng thái vật lý phù hợp; tổng phân loại phải bằng lượng phiếu nhận hàng cần xử lý.

### AS-UC-06-04-03 — Phân loại hàng thực nhận — Kết quả state change chưa xác định
- **Given:** Không rõ state movement đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả state change chưa xác định” tại BF-04.
- **Then:** Verify cùng operation identity; không ghi state movement thứ hai. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-06` — Tiếp nhận và phân loại hàng khách trả.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-08`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Hàng khách trả: từ tiếp nhận đến phân loại](../../../01.knowledge/know-how/KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Combo bán hàng và tồn kho theo thành phần](../../../01.knowledge/know-how/KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md)

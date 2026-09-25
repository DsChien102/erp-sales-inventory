---
id: UC-06-01
type: use-case
theme: theme-07
title: "Xác minh hàng được phép nhận trả"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-06
---

# UC-06-01 — Xác minh hàng được phép nhận trả

## 1. Mục tiêu và kết quả nghiệp vụ

Xác minh hàng khách mang trả có thuộc giao dịch gốc và còn nằm trong phạm vi được phép nhận trả trước khi ghi nhận vật lý.

**Kết quả cần đạt:** Mỗi dòng trả được xác định eligible, cần ngoại lệ truy vết hoặc bị từ chối; chưa tăng tồn.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có return intent và hàng vật lý

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Hàng đủ điều kiện nhận, cần ngoại lệ hoặc bị từ chối; Return validation result.

### 2.3 Không bao gồm

Không tăng tồn và không tự chấp nhận hàng trả chỉ vì tìm thấy giao dịch bán. UC chỉ xác minh nguồn bán, trần lượng trả, Product/UOM/LOT và quyền nhận trả trước khi tiếp nhận vật lý.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho; bộ phận trả hàng cung cấp ý định thương mại.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Có return intent và hàng vật lý.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

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
| BF-01 | Thủ kho | Nhập/chọn thông tin giao dịch bán hoặc bằng chứng nhận diện hàng trả. |  |
| BF-02 | Hệ thống | Tra nguồn bán, Product/UOM/LOT đã xuất và tổng lượng đã trả trước đó. | EF-A — Không tìm thấy nguồn/không đủ quyền |
| BF-03 | Hệ thống | Kiểm tra return cap và identity lô đối với hàng theo LOT. | AF-A — Sai/thiếu truy vết lô |
| BF-04 | Hệ thống | Đánh dấu từng dòng eligible hoặc lý do không được nhận; chưa tạo movement. |  |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Sai hoặc thiếu truy vết lô
**Phát sinh tại:** BF-03. **Điều kiện:** Hàng theo LOT nhưng lô thực nhận không khớp lô đã xuất hoặc evidence chưa đủ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Chuyển dòng sang UC-06-02 để xử lý ngoại lệ; không tự hợp thức hóa. | |
| AF-A-02 | — | [Kết thúc UC cho dòng đó.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không tìm thấy nguồn hoặc không đủ quyền
**Phát sinh tại:** BF-02. **Điều kiện:** Không resolve được giao dịch gốc hoặc người dùng không được xem nguồn .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho ghi nhận trả; trả lý do và hướng bổ sung nguồn/evidence. | |
| EF-A-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Trần trả | `actual_received_quantity` nằm trong `0.remaining_authorized_quantity` của ReturnExchangeLine hiện hành; server đồng thời recheck cumulative cap dòng giao gốc, source version và UOM precision nguyên tử. Nhận ít hơn lượng authorized là hợp lệ| Decision / DOM-IO / BC nguồn |
| BR-02 | Combo | Chỉ thành phần thực nhận tăng tồn; không tạo tồn combo; các dòng trong cùng yêu cầu nhận trả commit hoặc rollback cùng nhau| Decision / DOM-IO / BC nguồn |
| BR-03 | Lô | Product theo LOT giữ trace theo Product+UOM+source LOT allocation; source LOT chỉ read-only. Actual LOT phải resolve đúng LOT hiện hữu hoặc thu thập thuộc tính LOT mới theo Product policy; data-integrity conflict block. Sai LOT đi maker–checker theo line và không tự hợp thức hóa| Decision / DOM-IO / BC nguồn |
| BR-04 | Mốc ghi giá trị | Ghi value movement cùng lúc nhận vật lý vào RETURN_PENDING; phân loại không ghi giá trị lần hai| Decision / DOM-IO / BC nguồn |
| BR-05 | Căn cứ giá | Dùng giá đã đối soát của sản phẩm và kỳ xuất gốc; nếu kỳ gốc chưa đối soát thì dùng snapshot tại lần xuất và giữ liên kết để điều chỉnh theo policy| Decision / DOM-IO / BC nguồn |
| BR-06 | Tình trạng | Theme 5 `ReturnCondition` là declared context; Theme 7 physical classification mới authoritative cho stock state và không được prefill từ declared condition| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-07` — Receive customer return.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Mỗi dòng trả được xác định eligible, cần ngoại lệ truy vết hoặc bị từ chối; chưa tăng tồn. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Mỗi dòng trả được xác định eligible, cần ngoại lệ truy vết hoặc bị từ chối; chưa tăng tồn.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-06 — Tiếp nhận và phân loại hàng khách trả](../../../03.design/flows/UIF-06-BJ-06.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-030` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác minh hàng được phép nhận trả”; không tạo mutation. |
| `SCR-031` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác minh hàng được phép nhận trả”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-06-01-01 — Xác minh hàng được phép nhận trả — luồng chính
- **Given:** Có return intent và hàng vật lý
- **When:** Nhập/chọn thông tin giao dịch bán hoặc bằng chứng nhận diện hàng trả.
- **Then:** Mỗi dòng trả được xác định eligible, cần ngoại lệ truy vết hoặc bị từ chối; chưa tăng tồn.

### AS-UC-06-01-02 — Xác minh hàng được phép nhận trả — Sai hoặc thiếu truy vết lô
- **Given:** Hàng theo LOT nhưng lô thực nhận không khớp lô đã xuất hoặc evidence chưa đủ.
- **When:** Hệ thống phát hiện điều kiện “Sai hoặc thiếu truy vết lô” tại BF-03.
- **Then:** Chuyển dòng sang UC-06-02 để xử lý ngoại lệ; không tự hợp thức hóa. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-06-01-03 — Xác minh hàng được phép nhận trả — Không tìm thấy nguồn hoặc không đủ quyền
- **Given:** Không resolve được giao dịch gốc hoặc người dùng không được xem nguồn.
- **When:** Hệ thống phát hiện điều kiện “Không tìm thấy nguồn hoặc không đủ quyền” tại BF-02.
- **Then:** Không cho ghi nhận trả; trả lý do và hướng bổ sung nguồn/evidence. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-06` — Tiếp nhận và phân loại hàng khách trả.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-07`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Hàng khách trả: từ tiếp nhận đến phân loại](../../../01.knowledge/know-how/KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Combo bán hàng và tồn kho theo thành phần](../../../01.knowledge/know-how/KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md)

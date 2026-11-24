---
id: UC-09-03
type: use-case
theme: theme-07
title: "Xác định hàng hết hạn"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-09
---

# UC-09-03 — Xác định hàng hết hạn

## 1. Mục tiêu và kết quả nghiệp vụ

Xác định lượng/lô đã hết hạn trực tiếp từ hạn dùng và ngày nghiệp vụ, không phụ thuộc việc người dùng mở danh sách cảnh báo.

**Kết quả cần đạt:** Danh sách scope hết hạn cần state transition được xác định có `as_of`; chưa ghi state movement.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Ngày nghiệp vụ thay đổi hoặc dữ liệu lô được đánh giá

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Không có tác động hoặc xác định lượng phải hết hạn; Expiry evaluation result.

### 2.3 Không bao gồm

Không cần người dùng thao tác để “kích hoạt” hết hạn và không tự tiêu hủy hàng. UC chỉ xác định hàng đã hết hạn từ hạn dùng và ngày nghiệp vụ tenant để loại khỏi khả dụng/đưa sang xử lý trạng thái.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho hoặc quản lý kho.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Ngày nghiệp vụ thay đổi hoặc dữ liệu lô được đánh giá.
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
| BF-01 | Hệ thống | Đọc các lô có expiry trong tenant/kho theo lịch hoặc khi có query liên quan. |  |
| BF-02 | Hệ thống | So sánh expiry date với ngày nghiệp vụ tenant để xác định lượng đã hết hạn. |  |
| BF-03 | Hệ thống | Loại các lô đã ở trạng thái terminal/không cần transition và tạo danh sách candidate cần chuyển `EXPIRED`. | AF-A — Không có candidate |
| BF-04 | Hệ thống | Trả candidate scope cùng source/as_of cho UC-09-04; không sửa trạng thái tại đây. |  |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Không có candidate
**Phát sinh tại:** BF-03. **Điều kiện:** Không có lượng nào vừa đạt điều kiện hết hạn cần transition .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Kết thúc không effect. | |
| AF-A-02 | — | [Kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Dữ liệu expiry không hợp lệ
**Phát sinh tại:** BF-01. **Điều kiện:** Lô thuộc sản phẩm yêu cầu expiry nhưng nguồn HSD thiếu/mâu thuẫn .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không tự suy expiry; báo dữ liệu cần correction ở owner nguồn. | |
| EF-A-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Ma trận chuyển trạng thái | Chỉ cho các chuyển đổi được whitelist; mỗi chuyển đổi xác định quyền, lý do, bằng chứng và mức duyệt| Decision / DOM-IO / BC nguồn |
| BR-02 | Tổng vật lý | Chuyển trạng thái không làm đổi tổng physical quantity của sản phẩm/lô| Decision / DOM-IO / BC nguồn |
| BR-03 | Hết hạn | Xác định trực tiếp từ hạn dùng và ngày nghiệp vụ; loại khỏi khả dụng ngay, không phụ thuộc tác vụ nền đã materialize EXPIRED hay chưa| Decision / DOM-IO / BC nguồn |
| BR-04 | Cận hạn | Chỉ là chỉ báo/policy WARN hoặc BLOCK_SALE; không phải state movement và không tạo hồ sơ cảnh báo có lifecycle| Decision / DOM-IO / BC nguồn |
| BR-05 | Demo | Vẫn thuộc physical và book value nhưng không khả dụng; muốn bán lại phải qua chuyển trạng thái được phép| Decision / DOM-IO / BC nguồn |
| BR-06 | Reservation | Khi eligible giảm, phát tác động để BJ-04 đánh giá lại; BJ này không tự sửa order hoặc PickAllocation| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-10` — Change inventory state.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Danh sách scope hết hạn cần state transition được xác định có `as_of`; chưa ghi state movement. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Danh sách scope hết hạn cần state transition được xác định có `as_of`; chưa ghi state movement.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-09 — Quản lý trạng thái hàng](../../../03.design/flows/UIF-09-BJ-09.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-036` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác định hàng hết hạn”; không tạo mutation. |
| `SCR-037` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác định hàng hết hạn”; không tạo mutation. |
| `SCR-041` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác định hàng hết hạn”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-09-03-01 — Xác định hàng hết hạn — luồng chính
- **Given:** Ngày nghiệp vụ thay đổi hoặc dữ liệu lô được đánh giá
- **When:** Đọc các lô có expiry trong tenant/kho theo lịch hoặc khi có query liên quan.
- **Then:** Danh sách scope hết hạn cần state transition được xác định có `as_of`; chưa ghi state movement.

### AS-UC-09-03-02 — Xác định hàng hết hạn — Không có candidate
- **Given:** Không có lượng nào vừa đạt điều kiện hết hạn cần transition.
- **When:** Hệ thống phát hiện điều kiện “Không có candidate” tại BF-03.
- **Then:** Kết thúc không effect. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-09-03-03 — Xác định hàng hết hạn — Dữ liệu expiry không hợp lệ
- **Given:** Lô thuộc sản phẩm yêu cầu expiry nhưng nguồn HSD thiếu/mâu thuẫn.
- **When:** Hệ thống phát hiện điều kiện “Dữ liệu expiry không hợp lệ” tại BF-01.
- **Then:** Không tự suy expiry; báo dữ liệu cần correction ở owner nguồn. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-09` — Quản lý trạng thái hàng.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-10`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../01.knowledge/decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i)
- **Bài tri thức liên quan:** [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Hàng ký gửi, hàng demo và quyền sở hữu](../../../01.knowledge/know-how/KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md)

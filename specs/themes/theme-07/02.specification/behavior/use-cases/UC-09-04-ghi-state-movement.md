---
id: UC-09-04
type: use-case
theme: theme-07
title: "Ghi state movement"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-09
---

# UC-09-04 — Ghi state movement

## 1. Mục tiêu và kết quả nghiệp vụ

Ghi state movement cho yêu cầu/candidate đã đủ điều kiện, bảo toàn quantity và value.

**Kết quả cần đạt:** Lượng được chuyển trạng thái vật lý đúng một lần; availability được tính lại nhưng quantity/value ledger không bị nhân đôi.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có thay đổi hợp lệ và đủ thẩm quyền

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

State movement/balance được commit hoặc không có gì commit; Authoritative inventory state result.

### 2.3 Không bao gồm

Không thay đổi quantity vật lý và không sửa state history cũ. UC chỉ append state movement hợp lệ cho đúng lượng/phạm vi sau khi điều kiện và thẩm quyền đã được xác nhận.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho hoặc quản lý kho.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có thay đổi hợp lệ và đủ thẩm quyền.
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
| BF-01 | Hệ thống | Nhận request đã duyệt hoặc candidate hết hạn cùng scope/version hiện hành. |  |
| BF-02 | Hệ thống | Recheck state nguồn, quantity balance và transition policy trong transaction. | EF-A — State/version stale |
| BF-03 | Hệ thống | Ghi state movement từ trạng thái nguồn sang trạng thái đích cho đúng quantity. |  |
| BF-04 | Hệ thống | Cập nhật state balance/availability và audit; không tạo quantity/value movement mới. | EF-B — Kết quả commit chưa xác định |
| BF-05 | Hệ thống | Trả authoritative state-change result. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — State hoặc version stale
**Phát sinh tại:** BF-02. **Điều kiện:** Lượng đã đổi trạng thái hoặc request không còn current .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject trước commit; trả current state/version. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả commit chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ state movement đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify cùng identity trước retry; không ghi state movement thứ hai. | |
| EF-B-02 | — | [Kết thúc/hand-off BJ17.] | |

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
| Thành công | Lượng được chuyển trạng thái vật lý đúng một lần; availability được tính lại nhưng quantity/value ledger không bị nhân đôi. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Lượng được chuyển trạng thái vật lý đúng một lần; availability được tính lại nhưng quantity/value ledger không bị nhân đôi.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-09 — Quản lý trạng thái hàng](../../../03.design/flows/UIF-09-BJ-09.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-038` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi state movement”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-041` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi state movement”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-056` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi state movement”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-09-04-01 — Ghi state movement — luồng chính
- **Given:** Có thay đổi hợp lệ và đủ thẩm quyền
- **When:** Nhận request đã duyệt hoặc candidate hết hạn cùng scope/version hiện hành.
- **Then:** Lượng được chuyển trạng thái vật lý đúng một lần; availability được tính lại nhưng quantity/value ledger không bị nhân đôi.

### AS-UC-09-04-02 — Ghi state movement — State hoặc version stale
- **Given:** Lượng đã đổi trạng thái hoặc request không còn current.
- **When:** Hệ thống phát hiện điều kiện “State hoặc version stale” tại BF-02.
- **Then:** Reject trước commit; trả current state/version. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-09-04-03 — Ghi state movement — Kết quả commit chưa xác định
- **Given:** Không rõ state movement đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả commit chưa xác định” tại BF-04.
- **Then:** Verify cùng identity trước retry; không ghi state movement thứ hai. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-09` — Quản lý trạng thái hàng.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-10`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../01.knowledge/decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i)
- **Bài tri thức liên quan:** [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Hàng ký gửi, hàng demo và quyền sở hữu](../../../01.knowledge/know-how/KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md)

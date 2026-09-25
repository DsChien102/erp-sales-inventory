---
id: UC-09-01
type: use-case
theme: theme-07
title: "Chuẩn bị thay đổi trạng thái"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-09
---

# UC-09-01 — Chuẩn bị thay đổi trạng thái

## 1. Mục tiêu và kết quả nghiệp vụ

Chuẩn bị yêu cầu thay đổi trạng thái vật lý của hàng, xác định đúng lượng/lô, trạng thái đích, lý do và bằng chứng.

**Kết quả cần đạt:** State-change request có scope/version rõ và sẵn sàng thực thi hoặc phê duyệt theo policy; chưa thay đổi trạng thái.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có căn cứ nghiệp vụ và lượng hàng xác định

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Hồ sơ hợp lệ, cần duyệt hoặc bị từ chối; State-change request.

### 2.3 Không bao gồm

Không đổi trạng thái hàng ở bước chuẩn bị và không sửa movement nguồn. UC chỉ lập yêu cầu thay đổi trạng thái với phạm vi, căn cứ và bằng chứng cần thiết.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho hoặc quản lý kho.
- **Thẩm quyền:** Được lập/cập nhật hồ sơ nháp trong phạm vi được cấp; chưa có quyền tạo tác động cuối nếu Journey còn bước phê duyệt hoặc thực thi riêng.
- **Sự kiện khởi phát:** Có căn cứ nghiệp vụ và lượng hàng xác định.
- **Điều kiện trước:** Nguồn/version cần dùng còn hiện hành; tác nhân có quyền lập hồ sơ trong đúng tenant/cửa hàng/kho; các master/policy bắt buộc cho việc chuẩn bị đã resolve được.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Nguồn nghiệp vụ và phiên bản | Định danh nguồn/đối tượng nghiệp vụ và phiên bản hiện hành cần dùng để tránh xử lý trên dữ liệu cũ. | DOM-IO / DOM-IC / BC liên quan |
| Dữ liệu nghiệp vụ | Các dữ kiện người dùng/nguồn cung cấp cho mục tiêu của Use Case; phải tuân theo rule ở mục 6. | DOM-IO / DOM-IC / BC liên quan |
| Phạm vi thực hiện | Tác nhân và phạm vi tenant/cửa hàng/kho mà yêu cầu được phép xử lý. | DOM-IO / DOM-IC / BC liên quan |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Thủ kho/Quản lý kho | Chọn sản phẩm/lô/lượng cần đổi trạng thái và trạng thái đích. |  |
| BF-02 | Hệ thống | Nạp trạng thái hiện tại, quantity balance và transition policy. | EF-A — Transition không hợp lệ |
| BF-03 | Thủ kho/Quản lý kho | Nhập lý do và bằng chứng bắt buộc; rà soát lượng áp dụng. |  |
| BF-04 | Hệ thống | Đánh giá yêu cầu có cần phê duyệt hay có thể sẵn sàng thực thi. | AF-A — Cần phê duyệt |
| BF-05 | Hệ thống | Lưu request/version; chưa ghi state movement. | EF-B — Kết quả lưu chưa xác định |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Cần phê duyệt
**Phát sinh tại:** BF-04. **Điều kiện:** Policy yêu cầu phê duyệt cho transition/scope hiện tại .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Chuyển request sang `PENDING_APPROVAL` với snapshot/evidence. | |
| AF-A-02 | — | [Kết thúc UC; tiếp UC-09-02.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Transition không hợp lệ
**Phát sinh tại:** BF-02. **Điều kiện:** Trạng thái nguồn→đích không được policy cho phép hoặc lượng không đủ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối trước mutation và nêu rule vi phạm. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả lưu chưa xác định
**Phát sinh tại:** BF-05. **Điều kiện:** Không rõ request đã được lưu/gửi .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify cùng identity/version trước khi tạo lại. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Ma trận chuyển trạng thái | Chỉ cho các chuyển đổi được whitelist; mỗi chuyển đổi xác định quyền, lý do, bằng chứng và mức duyệt| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-02 | Tổng vật lý | Chuyển trạng thái không làm đổi tổng physical quantity của sản phẩm/lô| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-03 | Hết hạn | Xác định trực tiếp từ hạn dùng và ngày nghiệp vụ; loại khỏi khả dụng ngay, không phụ thuộc tác vụ nền đã materialize EXPIRED hay chưa| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-04 | Cận hạn | Chỉ là chỉ báo/policy WARN hoặc BLOCK_SALE; không phải state movement và không tạo hồ sơ cảnh báo có lifecycle| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-05 | Demo | Vẫn thuộc physical và book value nhưng không khả dụng; muốn bán lại phải qua chuyển trạng thái được phép| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-06 | Reservation | Khi eligible giảm, phát tác động để BJ-04 đánh giá lại; BJ này không tự sửa order hoặc PickAllocation| Decision / DOM-IO / DOM-IC / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-16` — Maintain operation draft.
- `BC-IC-07` — Submit inventory operation.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | State-change request có scope/version rõ và sẵn sàng thực thi hoặc phê duyệt theo policy; chưa thay đổi trạng thái. | Hồ sơ chỉ được bàn giao sang bước duyệt/thực thi khi các điều kiện của UC đã đạt; chưa ghi ledger trước commit point. |
| Không đủ điều kiện / Bị từ chối | Nếu dữ liệu, nguồn hoặc version chưa đủ điều kiện, hồ sơ không được đưa qua commit point; dữ liệu hợp lệ đã nhập được giữ theo contract để sửa/refresh khi an toàn. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** State-change request có scope/version rõ và sẵn sàng thực thi hoặc phê duyệt theo policy; chưa thay đổi trạng thái.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-09 — Quản lý trạng thái hàng](../../../03.design/flows/UIF-09-BJ-09.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-036` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị thay đổi trạng thái”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-037` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị thay đổi trạng thái”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-038` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị thay đổi trạng thái”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-09-01-01 — Chuẩn bị thay đổi trạng thái — luồng chính
- **Given:** Có căn cứ nghiệp vụ và lượng hàng xác định
- **When:** Chọn sản phẩm/lô/lượng cần đổi trạng thái và trạng thái đích.
- **Then:** State-change request có scope/version rõ và sẵn sàng thực thi hoặc phê duyệt theo policy; chưa thay đổi trạng thái.

### AS-UC-09-01-02 — Chuẩn bị thay đổi trạng thái — Cần phê duyệt
- **Given:** Policy yêu cầu phê duyệt cho transition/scope hiện tại.
- **When:** Hệ thống phát hiện điều kiện “Cần phê duyệt” tại BF-04.
- **Then:** Chuyển request sang `PENDING_APPROVAL` với snapshot/evidence. Bàn giao/tiếp tục UC-09-02 theo đúng kết quả của nhánh; không tạo effect ngoài phạm vi đã xác lập.

### AS-UC-09-01-03 — Chuẩn bị thay đổi trạng thái — Transition không hợp lệ
- **Given:** Trạng thái nguồn→đích không được policy cho phép hoặc lượng không đủ.
- **When:** Hệ thống phát hiện điều kiện “Transition không hợp lệ” tại BF-02.
- **Then:** Từ chối trước mutation và nêu rule vi phạm. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-09-01-04 — Chuẩn bị thay đổi trạng thái — Kết quả lưu chưa xác định
- **Given:** Không rõ request đã được lưu/gửi.
- **When:** Hệ thống phát hiện điều kiện “Kết quả lưu chưa xác định” tại BF-05.
- **Then:** Verify cùng identity/version trước khi tạo lại. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-09` — Quản lý trạng thái hàng.
- **Domain:** `DOM-IO`, `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../01.knowledge/decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i)
- **Bài tri thức liên quan:** [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Hàng ký gửi, hàng demo và quyền sở hữu](../../../01.knowledge/know-how/KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md)

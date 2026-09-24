---
id: UC-10-01
type: use-case
theme: theme-07
title: "Chuẩn bị yêu cầu tiêu hủy"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-10-01 — Chuẩn bị yêu cầu tiêu hủy

## 1. Mục tiêu và kết quả nghiệp vụ

Chuẩn bị yêu cầu tiêu hủy cho lượng hàng đủ điều kiện, với lý do, phương thức và bằng chứng dự kiến rõ ràng.

**Kết quả cần đạt:** Disposal request có scope/version rõ và đi phê duyệt hoặc sẵn sàng xử lý theo policy; chưa giảm tồn.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có lượng hàng được đề nghị loại bỏ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Draft đủ điều kiện gửi hoặc bị chặn; Disposal request.

### 2.3 Không bao gồm

Không giảm tồn và chưa ghi nhận hàng đã tiêu hủy. UC chỉ lập yêu cầu tiêu hủy cho đúng lượng đủ điều kiện, kèm lý do và bằng chứng cần thiết.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho, người duyệt và người xác nhận xử lý.
- **Thẩm quyền:** Được lập/cập nhật hồ sơ nháp trong phạm vi được cấp; chưa có quyền tạo tác động cuối nếu Journey còn bước phê duyệt hoặc thực thi riêng.
- **Sự kiện khởi phát:** Có lượng hàng được đề nghị loại bỏ.
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
| BF-01 | Thủ kho/Người lập | Chọn sản phẩm/lô/lượng cần tiêu hủy từ trạng thái đủ điều kiện. |  |
| BF-02 | Hệ thống | Nạp quantity/state hiện hành và disposal policy. | EF-A — Không đủ điều kiện tiêu hủy |
| BF-03 | Thủ kho/Người lập | Nhập lý do, phương thức xử lý và bằng chứng/tài liệu bắt buộc. |  |
| BF-04 | Hệ thống | Đánh giá ngưỡng/cấp phê duyệt và lưu request version. | AF-A — Cần phê duyệt |
| BF-05 | Hệ thống | Nếu không cần phê duyệt theo policy, đưa request sang trạng thái chờ xác nhận xử lý thực tế; chưa giảm tồn. | EF-B — Kết quả lưu/gửi chưa xác định |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Cần phê duyệt
**Phát sinh tại:** BF-04. **Điều kiện:** Policy/giá trị/phạm vi yêu cầu phê duyệt .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Chuyển request sang `PENDING_APPROVAL` với snapshot/evidence. | |
| AF-A-02 | — | [Kết thúc UC; tiếp UC-10-02.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không đủ điều kiện tiêu hủy
**Phát sinh tại:** BF-02. **Điều kiện:** State/quantity/source không cho phép hoặc lượng không đủ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối trước mutation và nêu rule vi phạm. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả lưu/gửi chưa xác định
**Phát sinh tại:** BF-05. **Điều kiện:** Không rõ request đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify cùng identity/version trước khi tạo lại. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Trạng thái nguồn | Chỉ hàng không bán được và thuộc tenant mới được tiêu hủy; hàng sellable phải qua BJ-09 trước| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-02 | Mốc giảm tồn | Phê duyệt chưa làm giảm physical; chỉ completion assertion hợp lệ mới cho phép ghi giảm| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-03 | Maker–checker | Người lập không tự duyệt; cấp duyệt suy ra từ trị tuyệt đối lượng × căn cứ giá| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-04 | Thiếu căn cứ giá | Không gửi duyệt khi thiếu cả official cost và giá nguồn; giữ nháp để bổ sung, không gán rủi ro không xác định| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-05 | Giá trị | Giảm theo official cost có hiệu lực tại thời điểm hoàn tất; không suy ra giá riêng theo kho/lô| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-06 | Số lượng thực xử lý | Nếu khác lượng được duyệt, chỉ cho phép trong phạm vi policy; vượt phạm vi phải quay lại lập/duyệt yêu cầu mới| Decision / DOM-IO / DOM-IC / BC nguồn |

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
| Thành công | Disposal request có scope/version rõ và đi phê duyệt hoặc sẵn sàng xử lý theo policy; chưa giảm tồn. | Hồ sơ chỉ được bàn giao sang bước duyệt/thực thi khi các điều kiện của UC đã đạt; chưa ghi ledger trước commit point. |
| Không đủ điều kiện / Bị từ chối | Nếu dữ liệu, nguồn hoặc version chưa đủ điều kiện, hồ sơ không được đưa qua commit point; dữ liệu hợp lệ đã nhập được giữ theo contract để sửa/refresh khi an toàn. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Disposal request có scope/version rõ và đi phê duyệt hoặc sẵn sàng xử lý theo policy; chưa giảm tồn.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-036` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị yêu cầu tiêu hủy”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-037` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị yêu cầu tiêu hủy”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-040` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị yêu cầu tiêu hủy”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-10-01-01 — Chuẩn bị yêu cầu tiêu hủy — luồng chính
- **Given:** Có lượng hàng được đề nghị loại bỏ
- **When:** Chọn sản phẩm/lô/lượng cần tiêu hủy từ trạng thái đủ điều kiện.
- **Then:** Disposal request có scope/version rõ và đi phê duyệt hoặc sẵn sàng xử lý theo policy; chưa giảm tồn.

### AS-UC-10-01-02 — Chuẩn bị yêu cầu tiêu hủy — Cần phê duyệt
- **Given:** Policy/giá trị/phạm vi yêu cầu phê duyệt.
- **When:** Hệ thống phát hiện điều kiện “Cần phê duyệt” tại BF-04.
- **Then:** Chuyển request sang `PENDING_APPROVAL` với snapshot/evidence. Bàn giao/tiếp tục UC-10-02 theo đúng kết quả của nhánh; không tạo effect ngoài phạm vi đã xác lập.

### AS-UC-10-01-03 — Chuẩn bị yêu cầu tiêu hủy — Không đủ điều kiện tiêu hủy
- **Given:** State/quantity/source không cho phép hoặc lượng không đủ.
- **When:** Hệ thống phát hiện điều kiện “Không đủ điều kiện tiêu hủy” tại BF-02.
- **Then:** Từ chối trước mutation và nêu rule vi phạm. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-10-01-04 — Chuẩn bị yêu cầu tiêu hủy — Kết quả lưu/gửi chưa xác định
- **Given:** Không rõ request đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả lưu/gửi chưa xác định” tại BF-05.
- **Then:** Verify cùng identity/version trước khi tạo lại. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-10` — Tiêu hủy hàng.
- **Domain:** `DOM-IO`, `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u)
- **Bài tri thức liên quan:** [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)

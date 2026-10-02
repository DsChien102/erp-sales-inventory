---
id: UC-02-01
type: use-case
theme: theme-07
title: "Chuẩn bị nhận theo chứng từ"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-02
---

# UC-02-01 — Chuẩn bị nhận theo chứng từ

## 1. Mục tiêu và kết quả nghiệp vụ

Chuẩn bị hồ sơ nhận hàng theo chứng từ nguồn, ghi đúng hàng thực nhận và các chênh lệch trước khi gửi duyệt/thực thi.

**Kết quả cần đạt:** Receipt draft gắn đúng source/version, Supplier và các dòng thực nhận; hồ sơ sẵn sàng thực thi hoặc chuyển phê duyệt khi nhận vượt tolerance/ngưỡng theo policy.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Chứng từ nguồn hợp lệ được chọn

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Hồ sơ thực nhận sẵn sàng hoặc cần duyệt; Receipt draft gắn source/version.

### 2.3 Không bao gồm

Không ghi tăng tồn ở bước chuẩn bị và không sửa số lượng/đơn giá trên chứng từ nguồn. UC chỉ tạo hồ sơ nhận hàng dựa trên chứng từ đủ điều kiện để bước phê duyệt/thực thi xử lý tiếp.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho. Người duyệt chỉ tham gia ở UC-02-03 nếu hồ sơ vượt ngưỡng cần phê duyệt.
- **Thẩm quyền:** Được lập/cập nhật hồ sơ nháp trong phạm vi được cấp; chưa có quyền tạo tác động cuối nếu Journey còn bước phê duyệt hoặc thực thi riêng.
- **Sự kiện khởi phát:** Chứng từ nguồn hợp lệ được chọn.
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
| BF-01 | Thủ kho | Chọn chứng từ nguồn đủ điều kiện nhận hàng. |  |
| BF-02 | Hệ thống | Nạp source version hiện hành, Supplier và toàn bộ source items cần nhận; khóa UOM theo chứng từ. | EF-A — Chứng từ stale/không còn hợp lệ |
| BF-03 | Thủ kho | Ghi lượng thực nhận theo từng sản phẩm/UOM; với LOT ghi theo từng lô và phân loại Đạt/Cách ly/Hỏng/Từ chối. | BR nguồn BJ02 |
| BF-04 | Hệ thống | Tính cumulative accepted physical quantity (`Đạt + Cách ly + Hỏng`) theo source line, quy đổi base UOM và so với `remaining_receivable_qty`/tolerance theo ApprovalPolicy. | AF-A — Nhận vượt ngưỡng cần phê duyệt |
| BF-05 | Thủ kho | Rà soát receipt draft và gửi xử lý. |  |
| BF-06 | Hệ thống | Lưu draft/version; nếu không cần duyệt chuyển `READY`, nếu cần duyệt chuyển `PENDING_APPROVAL`. | EF-B — Kết quả lưu/gửi chưa xác định |
| BF-07 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Nhận vượt ngưỡng cần phê duyệt
**Phát sinh tại:** BF-04. **Điều kiện:** cumulative accepted physical quantity vượt tolerance/ngưỡng cho phép của source theo ApprovalPolicy (`T7-DR-022`, `T7-DR-116`, `T7-DR-078`, `T7-DR-080`). Ngoài điều kiện này, chưa có Decision nào định nghĩa thêm trigger approval cho Document Receipt.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Giữ snapshot/source version và đưa hồ sơ sang UC-02-03; chưa tạo movement. | |
| AF-A-02 | — | [Kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Chứng từ stale hoặc không còn hợp lệ
**Phát sinh tại:** BF-02. **Điều kiện:** Source version thay đổi, bị hủy hoặc không còn cho phép nhận .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho submit trên version cũ; yêu cầu tải lại source và rà soát chênh lệch. | |
| EF-A-02 | — | [Kết thúc UC hoặc quay lại BF-02 sau refresh.] | |

#### EF-B — Kết quả lưu/gửi chưa xác định
**Phát sinh tại:** BF-06. **Điều kiện:** Client không chứng minh được draft/submit đã commit hay chưa .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ cùng identity/version và cho truy vấn finality trước khi gửi lại. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Một receipt gắn đúng một Supplier của source | Một receipt gắn đúng một Supplier của source; không trộn Supplier trong cùng receipt.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-02 | Chọn chứng từ phải nạp đầy đủ mọi source | Chọn chứng từ phải nạp đầy đủ mọi source item cần nhận; không được biến chứng từ nhiều sản phẩm thành editor chỉ một sản phẩm.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-03 | Mỗi source item được xử lý thành actual receipt | Mỗi source item được xử lý thành actual receipt hoặc `Chưa nhận lần này`; trạng thái sau giữ actual=0 và không làm giảm source remainder.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-04 | Ở mức nghiệp vụ/UI | Ở mức nghiệp vụ/UI, một mục hàng dùng đúng một transaction UOM theo source. Một mục có thể materialize thành nhiều InventoryOperationLine kỹ thuật theo lot/state nhưng phải giữ cùng receipt-item/source reference.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-05 | Nhận vượt nguồn | source cung cấp `source_line_id/version + remaining_receivable_qty + UOM/conversion snapshot`; Theme 7 so `accepted_physical_base_qty = (Đạt + Cách ly + Hỏng) quy đổi base UOM` với phần còn được nhận. Rejected không tạo movement và không được dùng để che over-source.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-06 | LOT/expiry theo Product policy | LOT/expiry theo Product policy; LOT bắt buộc lot code, expiry theo `expiry_required`, manufacture date optional.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-07 | Hàng cách ly/hỏng vẫn tăng physical đúng state | Hàng cách ly/hỏng vẫn tăng physical đúng state; rejected không tăng physical.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-08 | Draft multi-item chưa tạo movement | Draft multi-item chưa tạo movement; execution cuối cùng vẫn all-or-nothing theo operation contract.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-09 | Điều kiện duyệt của Document Receipt | Nhánh theo chứng từ chỉ chuyển `PENDING_APPROVAL` khi accepted physical vượt tolerance/ngưỡng của source theo ApprovalPolicy; không tự suy thêm trigger approval khi chưa có Decision định nghĩa. | `T7-DR-022`, `T7-DR-116`, `T7-DR-078`, `T7-DR-080` |

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
| Thành công | Receipt draft gắn đúng source/version, Supplier và các dòng thực nhận; hồ sơ sẵn sàng thực thi hoặc chuyển phê duyệt khi nhận vượt tolerance/ngưỡng theo policy. | Hồ sơ chỉ được bàn giao sang bước duyệt/thực thi khi các điều kiện của UC đã đạt; chưa ghi ledger trước commit point. |
| Không đủ điều kiện / Bị từ chối | Nếu dữ liệu, nguồn hoặc version chưa đủ điều kiện, hồ sơ không được đưa qua commit point; dữ liệu hợp lệ đã nhập được giữ theo contract để sửa/refresh khi an toàn. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Receipt draft gắn đúng source/version, Supplier và các dòng thực nhận; hồ sơ sẵn sàng thực thi hoặc chuyển phê duyệt khi nhận vượt tolerance/ngưỡng theo policy.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-02 — Nhận hàng mua](../../../03.design/flows/UIF-02-BJ-02.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-006` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhận theo chứng từ”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-007` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhận theo chứng từ”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-009` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhận theo chứng từ”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-084` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhận theo chứng từ”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-010` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhận theo chứng từ”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-02-01-01 — Chuẩn bị nhận theo chứng từ — luồng chính
- **Given:** Chứng từ nguồn hợp lệ được chọn
- **When:** Chọn chứng từ nguồn đủ điều kiện nhận hàng.
- **Then:** Receipt draft gắn đúng source/version, Supplier và các dòng thực nhận; hồ sơ sẵn sàng thực thi hoặc chuyển phê duyệt khi nhận vượt tolerance/ngưỡng theo policy.

### AS-UC-02-01-02 — Chuẩn bị nhận theo chứng từ — Nhận vượt ngưỡng cần phê duyệt
- **Given:** cumulative accepted physical quantity vượt tolerance/ngưỡng cho phép của source theo ApprovalPolicy.
- **When:** Hệ thống phát hiện điều kiện “Nhận vượt ngưỡng cần phê duyệt” tại BF-04.
- **Then:** Giữ snapshot/source version và đưa hồ sơ sang UC-02-03; chưa tạo movement. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-02-01-03 — Chuẩn bị nhận theo chứng từ — Chứng từ stale hoặc không còn hợp lệ
- **Given:** Source version thay đổi, bị hủy hoặc không còn cho phép nhận.
- **When:** Hệ thống phát hiện điều kiện “Chứng từ stale hoặc không còn hợp lệ” tại BF-02.
- **Then:** Không cho submit trên version cũ; yêu cầu tải lại source và rà soát chênh lệch. Luồng chính tiếp tục tại BF-02: Nạp source version hiện hành, Supplier và toàn bộ source items cần nhận; khóa UOM theo chứng từ.

### AS-UC-02-01-04 — Chuẩn bị nhận theo chứng từ — Kết quả lưu/gửi chưa xác định
- **Given:** Client không chứng minh được draft/submit đã commit hay chưa.
- **When:** Hệ thống phát hiện điều kiện “Kết quả lưu/gửi chưa xác định” tại BF-06.
- **Then:** Giữ cùng identity/version và cho truy vấn finality trước khi gửi lại. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-02` — Nhận hàng mua.
- **Domain:** `DOM-IO`, `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07`.

- **Nguồn quyết định:** [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../01.knowledge/decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u)
- **Bài tri thức liên quan:** [Nhận hàng mua và xử lý chênh lệch giao nhận](../../../01.knowledge/know-how/KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md); [Hàng đã nhận nhưng chưa chốt giá](../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Chính sách NONE, LOT hoặc SERIAL](../../../01.knowledge/know-how/KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)

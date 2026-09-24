---
id: UC-02-02
type: use-case
theme: theme-07
title: "Chuẩn bị nhập hàng nhanh"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-02-02 — Chuẩn bị nhập hàng nhanh

## 1. Mục tiêu và kết quả nghiệp vụ

Lập hồ sơ nhập hàng nhanh khi hàng đã đến nhưng chưa có chứng từ mua phù hợp, không tạo PO giả và luôn đi qua phê duyệt.

**Kết quả cần đạt:** Quick receipt có Supplier/Product/UOM/bằng chứng hợp lệ được lưu và chuyển `PENDING_APPROVAL`; chưa tăng tồn vật lý.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Hàng đã đến, chưa có chứng từ mua phù hợp và chính sách cho phép lập hồ sơ nhanh

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Hồ sơ nhận nhanh được lưu với định danh nguồn/bằng chứng tối thiểu và version bị khóa khi gửi; Operation chuyển sang `PENDING_APPROVAL`; chưa tạo movement hoặc tăng tồn vật lý.

### 2.3 Không bao gồm

Không tạo PO giả và chưa ghi tăng tồn ở bước chuẩn bị. UC chỉ lập hồ sơ nhập nhanh từ hàng thực nhận và dữ liệu nguồn tối thiểu theo policy.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho hoặc người có quyền lập hồ sơ nhận hàng nhanh.
- **Thẩm quyền:** Được lập/cập nhật hồ sơ nháp trong phạm vi được cấp; chưa có quyền tạo tác động cuối nếu Journey còn bước phê duyệt hoặc thực thi riêng.
- **Sự kiện khởi phát:** Hàng đã đến, chưa có chứng từ mua phù hợp và chính sách cho phép lập hồ sơ nhanh.
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
| BF-01 | Thủ kho | Mở Nhập hàng nhanh và chọn Supplier đã tồn tại. |  |
| BF-02 | Thủ kho | Thêm các sản phẩm thực nhận; chọn transaction UOM và ghi lượng/LOT/phân loại theo cấu hình sản phẩm. | EF-A — Supplier/Product không resolve được |
| BF-03 | Thủ kho | Bổ sung ngày nhận và căn cứ giao nhận/bằng chứng tối thiểu. |  |
| BF-04 | Hệ thống | Kiểm tra duplicate Product+UOM, quy đổi, LOT/HSD và dữ liệu bắt buộc. | AF-A — Có dòng cần sửa |
| BF-05 | Thủ kho | Rà soát và gửi yêu cầu nhận nhanh. |  |
| BF-06 | Hệ thống | Khóa version và chuyển hồ sơ sang `PENDING_APPROVAL`; không tạo movement trước phê duyệt. | EF-B — Kết quả submit chưa xác định |
| BF-07 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Có dòng cần sửa
**Phát sinh tại:** BF-04. **Điều kiện:** Một dòng thiếu UOM/LOT/HSD hoặc trùng Product+UOM không hợp lệ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Chỉ rõ dòng/lỗi để thủ kho sửa; giữ phần dữ liệu hợp lệ. | |
| AF-A-02 | — | [Trở lại BF-02/BF-03.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Supplier/Product không resolve được
**Phát sinh tại:** BF-02. **Điều kiện:** Người dùng nhập text nhưng chưa chọn master record hợp lệ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho submit và không tạo master data trong BJ02; hướng sang Theme 2/3 nếu cần. | |
| EF-A-02 | — | [Kết thúc hoặc sửa lựa chọn.] | |

#### EF-B — Kết quả submit chưa xác định
**Phát sinh tại:** BF-06. **Điều kiện:** Không rõ hồ sơ đã chuyển `PENDING_APPROVAL` hay chưa .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ cùng command identity và truy vấn trạng thái; không tạo Quick receipt thứ hai. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Mọi hồ sơ nhập hàng nhanh đủ điều kiện | Mọi hồ sơ nhập hàng nhanh đủ điều kiện gửi phải chuyển sang `PENDING_APPROVAL`; không có nhánh dưới ngưỡng đi thẳng `READY`.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-02 | Một Quick receipt có đúng một Supplier đã tồn | Một Quick receipt có đúng một Supplier đã tồn tại; Product cũng phải tồn tại. BJ-02 không tạo Supplier, Product hoặc PO/source giả.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-03 | Quick receipt hỗ trợ nhiều mục hàng. Ở mức | Quick receipt hỗ trợ nhiều mục hàng. Ở mức nghiệp vụ/UI, mỗi mục = một Product + một transaction UOM.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-04 | Nếu Product chỉ có một UOM nhập hợp lệ | Nếu Product chỉ có một UOM nhập hợp lệ thì dùng trực tiếp; nếu có nhiều thì user chọn một UOM cho mục. Cùng Product + UOM khác được tạo mục khác; cùng Product + cùng UOM không được tạo duplicate Quick item.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-05 | Một mục có thể materialize thành nhiều InventoryOperationLine kỹ | Một mục có thể materialize thành nhiều InventoryOperationLine kỹ thuật theo lot/state nhưng phải giữ cùng receipt-item reference.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-06 | Bốn phân loại Đạt/Cách ly/Hỏng/Từ chối là authoritative inputs | Bốn phân loại Đạt/Cách ly/Hỏng/Từ chối là authoritative inputs; `Tổng kiểm nhận` derive từ bốn nhóm; `Vào tồn vật lý = Đạt + Cách ly + Hỏng`; không có input total riêng.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-07 | LOT/expiry theo Product policy | LOT/expiry theo Product policy; `LOT` bắt buộc lot code, expiry theo `expiry_required`, manufacture date optional.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-08 | Thiếu căn cứ giá–tỷ giá | Thiếu căn cứ giá–tỷ giá, approver hoặc dữ kiện bắt buộc thì giữ ở `DRAFT`; lưu draft/submit chưa làm thay đổi physical.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-09 | Kho nhận ở Phase 1 là system-owned fact | Kho nhận ở Phase 1 là system-owned fact; UI hiển thị read-only bằng tên kho thực tế, không dropdown affordance.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-10 | `receipt_business_date` = tenant business date do server cung cấp | `receipt_business_date` = tenant business date do server cung cấp và read-only ở Phase hiện tại; không dùng browser/client clock hoặc date picker.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-11 | `Chứng từ giao nhận` là 1+ evidence refs bắt | `Chứng từ giao nhận` là 1+ evidence refs bắt buộc; business evidence gồm phiếu giao hàng/biên bản bàn giao/vận đơn hoặc scan/ảnh rõ nội dung. Technical file constraints dùng Shared Attachment Policy.| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-12 | Product nhiều UOM hiển thị toàn bộ UOM nhập | Product nhiều UOM hiển thị toàn bộ UOM nhập hợp lệ để user chọn trực tiếp; sau khi xác định Product+UOM, UI mở thẳng one-item editor.| Decision / DOM-IO / DOM-IC / BC nguồn |

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
| Thành công | Quick receipt có Supplier/Product/UOM/bằng chứng hợp lệ được lưu và chuyển `PENDING_APPROVAL`; chưa tăng tồn vật lý. | Hồ sơ chỉ được bàn giao sang bước duyệt/thực thi khi các điều kiện của UC đã đạt; chưa ghi ledger trước commit point. |
| Không đủ điều kiện / Bị từ chối | Nếu dữ liệu, nguồn hoặc version chưa đủ điều kiện, hồ sơ không được đưa qua commit point; dữ liệu hợp lệ đã nhập được giữ theo contract để sửa/refresh khi an toàn. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Quick receipt có Supplier/Product/UOM/bằng chứng hợp lệ được lưu và chuyển `PENDING_APPROVAL`; chưa tăng tồn vật lý.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-006` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhập hàng nhanh”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-008` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhập hàng nhanh”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-009` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhập hàng nhanh”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-084` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhập hàng nhanh”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-010` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị nhập hàng nhanh”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-02-02-01 — Chuẩn bị nhập hàng nhanh — luồng chính
- **Given:** Hàng đã đến, chưa có chứng từ mua phù hợp và chính sách cho phép lập hồ sơ nhanh
- **When:** Mở Nhập hàng nhanh và chọn Supplier đã tồn tại.
- **Then:** Quick receipt có Supplier/Product/UOM/bằng chứng hợp lệ được lưu và chuyển `PENDING_APPROVAL`; chưa tăng tồn vật lý.

### AS-UC-02-02-02 — Chuẩn bị nhập hàng nhanh — Có dòng cần sửa
- **Given:** Một dòng thiếu UOM/LOT/HSD hoặc trùng Product+UOM không hợp lệ.
- **When:** Hệ thống phát hiện điều kiện “Có dòng cần sửa” tại BF-04.
- **Then:** Chỉ rõ dòng/lỗi để thủ kho sửa; giữ phần dữ liệu hợp lệ. Luồng chính tiếp tục tại BF-02: Thêm các sản phẩm thực nhận; chọn transaction UOM và ghi lượng/LOT/phân loại theo cấu hình sản phẩm.

### AS-UC-02-02-03 — Chuẩn bị nhập hàng nhanh — Supplier/Product không resolve được
- **Given:** Người dùng nhập text nhưng chưa chọn master record hợp lệ.
- **When:** Hệ thống phát hiện điều kiện “Supplier/Product không resolve được” tại BF-02.
- **Then:** Không cho submit và không tạo master data trong BJ02; hướng sang Theme 2/3 nếu cần. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-02-02-04 — Chuẩn bị nhập hàng nhanh — Kết quả submit chưa xác định
- **Given:** Không rõ hồ sơ đã chuyển `PENDING_APPROVAL` hay chưa.
- **When:** Hệ thống phát hiện điều kiện “Kết quả submit chưa xác định” tại BF-06.
- **Then:** Giữ cùng command identity và truy vấn trạng thái; không tạo Quick receipt thứ hai. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-02` — Nhận hàng mua.
- **Domain:** `DOM-IO`, `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07`.

- **Nguồn quyết định:** [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../01.knowledge/decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u); [Nhóm G03 — Nhập hàng nhanh bắt buộc duyệt](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B)
- **Bài tri thức liên quan:** [Nhận hàng mua và xử lý chênh lệch giao nhận](../../../01.knowledge/know-how/KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md); [Hàng đã nhận nhưng chưa chốt giá](../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Chính sách NONE, LOT hoặc SERIAL](../../../01.knowledge/know-how/KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)

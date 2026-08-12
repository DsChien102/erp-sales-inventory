---
id: UC-02-02
type: use-case
theme: theme-07
title: "Chuẩn bị nhập hàng nhanh"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-02-02 — Chuẩn bị nhập hàng nhanh

## 1. Mục tiêu và outcome

Chuẩn bị đủ dữ kiện tối thiểu và gửi hồ sơ nhập hàng nhanh sang phê duyệt mà không tạo PO giả hoặc thay đổi tồn kho.

**Kết quả thành công:** <ul><li>Hồ sơ nhận nhanh được lưu với định danh nguồn/bằng chứng tối thiểu và version bị khóa khi gửi.</li><li>Operation chuyển sang `PENDING_APPROVAL`; chưa tạo movement hoặc tăng tồn vật lý.</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Hàng đã đến, chưa có chứng từ mua phù hợp và chính sách cho phép lập hồ sơ nhanh

### 2.2 Kết thúc khi

<ul><li>Hồ sơ nhận nhanh được lưu với định danh nguồn/bằng chứng tối thiểu và version bị khóa khi gửi.</li><li>Operation chuyển sang `PENDING_APPROVAL`; chưa tạo movement hoặc tăng tồn vật lý.</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Thủ kho hoặc người có quyền lập hồ sơ nhận hàng nhanh
- **Trigger:** Hàng đã đến, chưa có chứng từ mua phù hợp và chính sách cho phép lập hồ sơ nhanh
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope.

### Quy tắc và bất biến

<ul><li>Mọi hồ sơ nhập hàng nhanh đủ điều kiện gửi phải chuyển sang `PENDING_APPROVAL`; không có nhánh dưới ngưỡng đi thẳng `READY`.</li><li>Một Quick receipt có đúng một Supplier đã tồn tại; Product cũng phải tồn tại. BJ-02 không tạo Supplier, Product hoặc PO/source giả.</li><li>Quick receipt hỗ trợ nhiều mục hàng. Ở mức nghiệp vụ/UI, mỗi mục = một Product + một transaction UOM.</li><li>Nếu Product chỉ có một UOM nhập hợp lệ thì dùng trực tiếp; nếu có nhiều thì user chọn một UOM cho mục. Cùng Product + UOM khác được tạo mục khác; cùng Product + cùng UOM không được tạo duplicate Quick item.</li><li>Một mục có thể materialize thành nhiều InventoryOperationLine kỹ thuật theo lot/state nhưng phải giữ cùng receipt-item reference.</li><li>Bốn phân loại Đạt/Cách ly/Hỏng/Từ chối là authoritative inputs; `Tổng kiểm nhận` derive từ bốn nhóm; `Vào tồn vật lý = Đạt + Cách ly + Hỏng`; không có input total riêng.</li><li>LOT/expiry theo Product policy; `LOT` bắt buộc lot code, expiry theo `expiry_required`, manufacture date optional.</li><li>Thiếu căn cứ giá–tỷ giá, approver hoặc dữ kiện bắt buộc thì giữ ở `DRAFT`; lưu draft/submit chưa làm thay đổi physical.</li><li>Kho nhận ở Phase 1 là system-owned fact; UI hiển thị read-only bằng tên kho thực tế, không dropdown affordance.</li><li>`receipt_business_date` = tenant business date do server cung cấp và read-only ở Phase hiện tại; không dùng browser/client clock hoặc date picker.</li><li>`Chứng từ giao nhận` là 1+ evidence refs bắt buộc; business evidence gồm phiếu giao hàng/biên bản bàn giao/vận đơn hoặc scan/ảnh rõ nội dung. Technical file constraints dùng Shared Attachment Policy.</li><li>Product nhiều UOM hiển thị toàn bộ UOM nhập hợp lệ để user chọn trực tiếp; sau khi xác định Product+UOM, UI mở thẳng one-item editor.</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Chỉ tạo thay đổi được nêu trong BC-IO-16, BC-IC-07; UI hoặc adapter không được tự thêm transition.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IO-16 — Maintain operation draft](../behavioral-contracts/BC-IO-16.md); [BC-IC-07 — Submit inventory operation](../behavioral-contracts/BC-IC-07.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-006](../../../03.design/screens/SCR-006.md); [SCR-008](../../../03.design/screens/SCR-008.md); [SCR-009](../../../03.design/screens/SCR-009.md); [SCR-084](../../../03.design/screens/SCR-084.md); [SCR-010](../../../03.design/screens/SCR-010.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-02-02-01 | Điều kiện cần hợp lệ, nguồn/bằng chứng tối thiểu và căn cứ duyệt đầy đủ | Người dùng gửi hồ sơ nhập hàng nhanh | Operation chuyển sang `PENDING_APPROVAL`; không tạo PO giả, movement hoặc thay đổi tồn. |
| AS-UC-02-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-02-02-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-02-02-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |
| AS-UC-02-02-05 | Hồ sơ nhập hàng nhanh có giá trị dưới ngưỡng duyệt thông thường | Người dùng gửi hồ sơ hợp lệ | Vẫn chuyển sang `PENDING_APPROVAL`; giá trị chỉ ảnh hưởng cấp duyệt, không loại bỏ bước duyệt. |
| AS-UC-02-02-06 | Quick receipt có nhiều sản phẩm | User thêm và hoàn tất từng mục | Mọi mục được giữ trong cùng receipt của một Supplier và review được đầy đủ. |
| AS-UC-02-02-07 | Cùng Product được nhận bằng 2 UOM hợp lệ | User thêm Product lần nữa với UOM khác | Tạo hai receipt items riêng; mỗi item có một UOM. |
| AS-UC-02-02-08 | Quick receipt đã có Product + UOM | User cố thêm lại cùng Product + UOM | Không tạo duplicate; hệ thống đưa user tới item hiện có. |
| AS-UC-02-02-09 | Supplier hoặc Product không có trong master | User tìm kiếm | Hiển thị no-result; không có create-new CTA trong BJ-02; user phải chuẩn bị master data ở domain sở hữu. |
| AS-UC-02-02-10 | Người dùng mở thông tin nhập hàng nhanh | Kho mặc định được resolve và ngày hiện hành của tenant đã biết | Kho nhận hiển thị read-only bằng tên kho; ngày nhận hiển thị read-only từ tenant business date của server. |
| AS-UC-02-02-11 | Supplier hợp lệ nhưng chưa có chứng từ giao nhận hoặc ownership assertion | Người dùng muốn tiếp tục | `Tiếp tục` vẫn disabled; phải có ít nhất một evidence ref hợp lệ và ownership assertion có thẩm quyền; không chấp nhận text thay evidence. |
| AS-UC-02-02-12 | Product có nhiều UOM nhập hợp lệ | Người dùng chọn Product | UI hiển thị toàn bộ UOM hợp lệ để chọn trực tiếp; không dùng dropdown. Sau khi chọn UOM, mở ngay `SCR-084`. |
| AS-UC-02-02-13 | Product chỉ có một UOM nhập hợp lệ | Người dùng chọn Product | Hệ thống dùng UOM đó và mở ngay `SCR-084`; không yêu cầu user tap lại item vừa tạo. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../01.knowledge/decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u); [Nhóm G03 — Nhập hàng nhanh bắt buộc duyệt](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B)
- **Bài tri thức liên quan:** [Nhận hàng mua và xử lý chênh lệch giao nhận](../../../01.knowledge/know-how/KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md); [Hàng đã nhận nhưng chưa chốt giá](../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Chính sách NONE, LOT hoặc SERIAL](../../../01.knowledge/know-how/KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-02 — Nhận hàng mua](../journeys/BJ-02-nhan-hang-mua.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-02-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-02-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-02-02. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

## v3.9.2 deep-review lock
- Quick option chỉ render khi actor có `quick_receipt` capability; blocker tạm thời dùng Navigation row Disabled + helper.
- Quick receipt bắt buộc structured `ownership_assertion(actor, asserted_at, evidence_refs, version)`; approval không thay assertion.
- Đổi Supplier khi draft đã có dữ liệu làm evidence/ownership/price dependencies phải revalidate; không silently giữ dependency cũ.
- Quick không submit nếu `accepted_physical_qty = 0`.

### Nguồn v3.10.1 — UC-02-02 — Chuẩn bị nhập hàng nhanh

> **Phiên bản:** 4.1.0 + BJ02 pilot amendment v0.2.8  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-02 — Nhận hàng mua](../journeys/BJ-02-nhan-hang-mua.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

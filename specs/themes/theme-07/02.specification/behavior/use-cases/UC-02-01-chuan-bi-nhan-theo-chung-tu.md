---
id: UC-02-01
type: use-case
theme: theme-07
title: "Chuẩn bị nhận theo chứng từ"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-02-01 — Chuẩn bị nhận theo chứng từ

## 1. Mục tiêu và outcome

Chuẩn bị nhận theo chứng từ để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Hồ sơ thực nhận sẵn sàng hoặc cần duyệt</li><li>Receipt draft gắn source/version</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Chứng từ nguồn hợp lệ được chọn

### 2.2 Kết thúc khi

<ul><li>Hồ sơ thực nhận sẵn sàng hoặc cần duyệt</li><li>Receipt draft gắn source/version</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Thủ kho; người duyệt khi có ngoại lệ
- **Trigger:** Chứng từ nguồn hợp lệ được chọn
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope.

### Quy tắc và bất biến

<ul><li>Một receipt gắn đúng một Supplier của source; không trộn Supplier trong cùng receipt.</li><li>Chọn chứng từ phải nạp đầy đủ mọi source item cần nhận; không được biến chứng từ nhiều sản phẩm thành editor chỉ một sản phẩm.</li><li>Mỗi source item được xử lý thành actual receipt hoặc `Chưa nhận lần này`; trạng thái sau giữ actual=0 và không làm giảm source remainder.</li><li>Ở mức nghiệp vụ/UI, một mục hàng dùng đúng một transaction UOM theo source. Một mục có thể materialize thành nhiều InventoryOperationLine kỹ thuật theo lot/state nhưng phải giữ cùng receipt-item/source reference.</li><li>Nhận vượt nguồn: source cung cấp `source_line_id/version + remaining_receivable_qty + UOM/conversion snapshot`; Theme 7 so `accepted_physical_base_qty = (Đạt + Cách ly + Hỏng) quy đổi base UOM` với phần còn được nhận. Rejected không tạo movement và không được dùng để che over-source.</li><li>LOT/expiry theo Product policy; LOT bắt buộc lot code, expiry theo `expiry_required`, manufacture date optional.</li><li>Hàng cách ly/hỏng vẫn tăng physical đúng state; rejected không tăng physical.</li><li>Draft multi-item chưa tạo movement; execution cuối cùng vẫn all-or-nothing theo operation contract.</li></ul>

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
| Màn hình liên quan | [SCR-006](../../../03.design/screens/SCR-006.md); [SCR-007](../../../03.design/screens/SCR-007.md); [SCR-009](../../../03.design/screens/SCR-009.md); [SCR-084](../../../03.design/screens/SCR-084.md); [SCR-010](../../../03.design/screens/SCR-010.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-02-01-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Chuẩn bị nhận theo chứng từ” | Hồ sơ thực nhận sẵn sàng hoặc cần duyệt; kết quả Receipt draft gắn source/version và có truy vết nguồn. |
| AS-UC-02-01-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-02-01-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-02-01-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |
| AS-UC-02-01-05 | Chứng từ có 2+ sản phẩm/source items | Người dùng mở chứng từ | Tất cả source items xuất hiện ở Hàng thực nhận; user xử lý từng mục, không mất item. |
| AS-UC-02-01-06 | Một source item chưa được giao trong chuyến này | User chọn `Chưa nhận lần này` | Item được coi đã xử lý với actual=0; source remainder giữ nguyên; receipt vẫn có thể review khi các item khác đã xử lý. |
| AS-UC-02-01-07 | Source Product/UOM đã xác định | User mở item | Product và UOM read-only; không được thay master/source UOM trong receipt. |
| AS-UC-02-01-08 | Actual receipt nhỏ hơn lượng còn được phép nhận của source item | User hoàn tất item với số thực nhận nhỏ hơn source | Cho phép partial receipt; UI nêu rõ phần còn chưa nhận, source remainder được giữ lại; không coi đây là validation error. |
| AS-UC-02-01-09 | Actual receipt vượt lượng còn được phép nhận của source item | User nhập số vượt source | UI cảnh báo ngay trước Review; server vẫn áp dụng approval/source guard authoritative, không âm thầm coi lượng vượt là hợp lệ. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../01.knowledge/decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u)
- **Bài tri thức liên quan:** [Nhận hàng mua và xử lý chênh lệch giao nhận](../../../01.knowledge/know-how/KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md); [Hàng đã nhận nhưng chưa chốt giá](../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Chính sách NONE, LOT hoặc SERIAL](../../../01.knowledge/know-how/KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-02 — Nhận hàng mua](../journeys/BJ-02-nhan-hang-mua.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-02-01-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-02-01, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-02-01. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.


## v3.9.2 deep-review lock
- Source remainder là authoritative input của source domain; không suy từ ordered quantity trong Theme 7.
- Đổi chứng từ sau khi đã có item data cần confirmation và reset draft an toàn; không silently mutate source identity/version.

### Nguồn v3.10.1 — UC-02-01 — Chuẩn bị nhận theo chứng từ

> **Phiên bản:** 4.1.0 + BJ02 pilot amendment v0.2.8  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-02 — Nhận hàng mua](../journeys/BJ-02-nhan-hang-mua.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

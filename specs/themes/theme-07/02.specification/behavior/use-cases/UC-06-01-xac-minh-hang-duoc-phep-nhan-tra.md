---
id: UC-06-01
type: use-case
theme: theme-07
title: "Xác minh hàng được phép nhận trả"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-06-01 — Xác minh hàng được phép nhận trả

## 1. Mục tiêu và outcome

Xác minh hàng được phép nhận trả để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Hàng đủ điều kiện nhận, cần ngoại lệ hoặc bị từ chối</li><li>Return validation result</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Có return intent và hàng vật lý

### 2.2 Kết thúc khi

<ul><li>Hàng đủ điều kiện nhận, cần ngoại lệ hoặc bị từ chối</li><li>Return validation result</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Thủ kho; bộ phận trả hàng cung cấp ý định thương mại
- **Trigger:** Có return intent và hàng vật lý
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope.

### Quy tắc và bất biến

<ul><li>Trần trả: `actual_received_quantity` nằm trong `0..remaining_authorized_quantity` của ReturnExchangeLine hiện hành; server đồng thời recheck cumulative cap dòng giao gốc, source version và UOM precision nguyên tử. Nhận ít hơn lượng authorized là hợp lệ</li><li>Combo: Chỉ thành phần thực nhận tăng tồn; không tạo tồn combo; các dòng trong cùng yêu cầu nhận trả commit hoặc rollback cùng nhau</li><li>Lô: Product theo LOT giữ trace theo Product+UOM+source LOT allocation; source LOT chỉ read-only. Actual LOT phải resolve đúng LOT hiện hữu hoặc thu thập thuộc tính LOT mới theo Product policy; data-integrity conflict block. Sai LOT đi maker–checker theo line và không tự hợp thức hóa</li><li>Mốc ghi giá trị: Ghi value movement cùng lúc nhận vật lý vào RETURN_PENDING; phân loại không ghi giá trị lần hai</li><li>Căn cứ giá: Dùng giá đã đối soát của sản phẩm và kỳ xuất gốc; nếu kỳ gốc chưa đối soát thì dùng snapshot tại lần xuất và giữ liên kết để điều chỉnh theo policy</li><li>Tình trạng: Theme 5 `ReturnCondition` là declared context; Theme 7 physical classification mới authoritative cho stock state và không được prefill từ declared condition</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Chỉ tạo thay đổi được nêu trong BC-IO-07; UI hoặc adapter không được tự thêm transition.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IO-07 — Receive customer return](../behavioral-contracts/BC-IO-07.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-030](../../../03.design/screens/SCR-030.md); [SCR-031](../../../03.design/screens/SCR-031.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-06-01-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xác minh hàng được phép nhận trả” | Hàng đủ điều kiện nhận, cần ngoại lệ hoặc bị từ chối; kết quả Return validation result và có truy vết nguồn. |
| AS-UC-06-01-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-06-01-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-06-01-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |
| AS-UC-06-01-05 | ReturnExchangeLine cho phép trả 5 hộp, khách thực tế mang 3 hộp | Thủ kho xác nhận physical quantity 3 | Line hợp lệ nếu source/cumulative cap còn current; 2 hộp còn lại vẫn thuộc source return intent, Theme 7 không tự đổi quantity thương mại. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Hàng khách trả: từ tiếp nhận đến phân loại](../../../01.knowledge/know-how/KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Combo bán hàng và tồn kho theo thành phần](../../../01.knowledge/know-how/KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-06 — Tiếp nhận và phân loại hàng khách trả](../journeys/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-06-01-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-06-01, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-06-01. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

### Nguồn v3.10.1 — UC-06-01 — Xác minh hàng được phép nhận trả

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-06 — Tiếp nhận và phân loại hàng khách trả](../journeys/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

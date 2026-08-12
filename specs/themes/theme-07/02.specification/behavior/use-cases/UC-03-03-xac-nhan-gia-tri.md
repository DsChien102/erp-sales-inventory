---
id: UC-03-03
type: use-case
theme: theme-07
title: "Xác nhận giá trị"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-03-03 — Xác nhận giá trị

## 1. Mục tiêu và outcome

Xác nhận giá trị để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Value movement được commit; đúng confirm quantity chuyển `VALUATION_PENDING → VALUATION_CONFIRMED`, physical state giữ nguyên</li><li>Confirmed receipt valuation</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Phép tính hợp lệ được rà soát

### 2.2 Kết thúc khi

<ul><li>Value movement được commit; đúng confirm quantity chuyển `VALUATION_PENDING → VALUATION_CONFIRMED`, physical state giữ nguyên</li><li>Confirmed receipt valuation</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Kế toán kho hoặc người có quyền tài chính
- **Trigger:** Phép tính hợp lệ được rà soát
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope dùng chung; selected `{valuation_basis_key, basis_version, basis_hash, scope_key, scope_version, confirm_quantity}`; server-preview calculation hash; idempotency key; actor, tenant, store và warehouse scope.

### Quy tắc và bất biến

<ul><li>Căn cứ giá: complete DirectCostBasis đã chọn/resolve phải còn đúng `basis_hash/version`; không re-use receipt-wide source version</li><li>Giá nhập thực tế: Bao gồm giá sau discount dòng, phân bổ discount cấp phiếu, chi phí mua phân bổ, thuế không được khấu trừ; loại VAT được khấu trừ</li><li>Hàng tặng: Phân bổ quyền lợi theo chính sách đã phê duyệt; không mặc định giá 0 nếu làm sai tổng giá trị</li><li>Ngoại tệ: Dùng tỷ giá được nguồn kế toán phê duyệt và lưu provenance</li><li>Làm tròn: authoritative amount dùng deterministic allocation + cumulative partial method; client không tự nhân unit cost rồi round</li><li>Xác nhận từng phần: exact technical scope giữ basis identity; partial cập nhật cumulative confirmed quantity/value và scope version</li><li>UOM: ReceiptValuation giữ transaction UOM + conversion snapshot + confirmed base quantity; Official Cost dùng VND/base UOM</li><li>Initial Official Cost: compare-and-create nguyên tử tenant+product; concurrent loser trả `ALREADY_INITIALIZED` nhưng valuation vẫn commit</li><li>Ngày/kỳ: direct value movement dùng receipt_business_date và kỳ chứa ngày đó; recorded_at là commit time; component đến sau route BJ13</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Chỉ tạo thay đổi được nêu trong BC-IV-01; UI hoặc adapter không được tự thêm transition.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IV-01 — Confirm direct receipt cost and release](../behavioral-contracts/BC-IV-01.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-017](../../../03.design/screens/SCR-017.md); [SCR-019](../../../03.design/screens/SCR-019.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-03-03-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xác nhận giá trị” | Value movement được commit; đúng confirm quantity chuyển `VALUATION_PENDING → VALUATION_CONFIRMED`, physical state giữ nguyên; kết quả Confirmed receipt valuation và có truy vết nguồn. |
| AS-UC-03-03-02 | Thiếu quyền, sai phạm vi, một selected basis hash/scope version stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Toàn selected-set command bị từ chối trước tác động authoritative; không ghi một phần. |
| AS-UC-03-03-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-03-03-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B); [Nhóm G07 — Giá vốn và định giá tồn kho](../../../01.knowledge/decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3)
- **Bài tri thức liên quan:** [Hàng đã nhận nhưng chưa chốt giá](../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Các thành phần hình thành giá nhập thực tế](../../../01.knowledge/know-how/KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-03 — Xác nhận giá trị ban đầu của hàng nhận](../journeys/BJ-03-xac-nhan-gia-tri-ban-au-cua-hang-nhan.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-03-03-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-03-03, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-03-03. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

### Nguồn v3.10.1 — UC-03-03 — Xác nhận giá trị

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-03 — Xác nhận giá trị ban đầu của hàng nhận](../journeys/BJ-03-xac-nhan-gia-tri-ban-au-cua-hang-nhan.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

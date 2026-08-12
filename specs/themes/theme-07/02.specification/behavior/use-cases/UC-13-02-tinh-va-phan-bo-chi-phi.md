---
id: UC-13-02
type: use-case
theme: theme-07
title: "Tính và phân bổ chi phí"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-13-02 — Tính và phân bổ chi phí

## 1. Mục tiêu và outcome

Tính và phân bổ chi phí để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Phân bổ cân bằng hoặc có sai lệch cần sửa</li><li>Allocation draft có provenance</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Có source/scope hợp lệ

### 2.2 Kết thúc khi

<ul><li>Phân bổ cân bằng hoặc có sai lệch cần sửa</li><li>Allocation draft có provenance</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Kế toán mua hàng hoặc kế toán kho
- **Trigger:** Có source/scope hợp lệ
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Query envelope; source component key/revision, authoritative target scope / selected valuation exposures, selected allocation method/policy version và expected preview/source versions. Không tạo authoritative mutation.

### Quy tắc và bất biến

<ul><li>Nguồn bắt buộc: Mỗi chi phí phải có source document/line/version và bằng chứng; không nhập một khoản tổng không truy nguyên</li><li>Chống trùng: Cùng stable `source_component_key` chỉ được ghi một economic cost; source revision mới không tạo cost mới</li><li>Thành phần giá trị: Chi phí mua, discount, hàng tặng và thuế được chuẩn hóa theo chính sách; VAT được khấu trừ không vào giá vốn</li><li>Ngoại tệ: Sổ tồn dùng VND; dùng tỷ giá do nguồn Kế toán cung cấp; chênh lệch thanh toán không làm đổi giá trị tồn đã ghi</li><li>Phân bổ: Tổng các dòng phân bổ phải khớp tổng chi phí sau chuẩn hóa; phần dư làm tròn phải được xử lý xác định</li><li>Kỳ mở/khóa: Kỳ còn mở ghi vào phạm vi cần tính lại; kỳ đã khóa ghi adjustment ở kỳ mở hiện tại và giữ liên kết kỳ gốc</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

BC-IV-06 chỉ đọc/derive preview; không tạo late-cost/adjustment/value/dirty-scope mutation.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IV-06 — Build late landed cost preview](../behavioral-contracts/BC-IV-06.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-087](../../../03.design/screens/SCR-087.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-13-02-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Tính và phân bổ chi phí” | Phân bổ cân bằng hoặc có sai lệch cần sửa; kết quả Allocation draft có provenance và có truy vết nguồn. |
| AS-UC-13-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-13-02-03 | Cùng source/scope/method được preview lại | Adapter hoặc người dùng thử lại | Trả allocation preview hiện hành hoặc source-stale; không ghi adjustment. |
| AS-UC-13-02-04 | Client timeout khi preview | Client tải lại | Preview là query an toàn; UNKNOWN/finality chỉ thuộc UC-13-03. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G07 — Giá vốn và định giá tồn kho](../../../01.knowledge/decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3)
- **Bài tri thức liên quan:** [Các thành phần hình thành giá nhập thực tế](../../../01.knowledge/know-how/KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te.md); [Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-13 — Ghi nhận chi phí mua đến muộn](../journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-13-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-13-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-13-02. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.



## Wave 3 semantic lock

- `source_component_key` là economic identity; `source_revision` chỉ freshness/provenance.
- Scope được server/source policy chứng minh bằng `target_scope_key/version/hash`; UI không được tự mở rộng ngoài candidate set.
- Allocation target là `valuation_exposure_key/version/hash`; method metric cũng có version/hash.
- Preview/commit recheck `late_cost_basis_hash` và `allocation_hash` trên toàn selected set.
- Component route `DIRECT` hoặc `LATE` một lần; route LATE chờ đủ initial valuation exposure.
- Period mapping nằm trên từng allocation; multi-posting-period commit tạo 1..N adjustment batch atomically.

### Nguồn v3.10.1 — UC-13-02 — Tính và phân bổ chi phí

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-13 — Ghi nhận chi phí mua đến muộn](../journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

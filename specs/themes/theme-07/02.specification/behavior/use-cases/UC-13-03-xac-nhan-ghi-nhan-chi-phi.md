---
id: UC-13-03
type: use-case
theme: theme-07
title: "Xác nhận ghi nhận chi phí"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-13-03 — Xác nhận ghi nhận chi phí

## 1. Mục tiêu và outcome

Xác nhận ghi nhận chi phí để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Adjustment được ghi và scope cần tính lại được xác định</li><li>Late-cost result dùng cho successor cost run</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Phân bổ hợp lệ được rà soát

### 2.2 Kết thúc khi

<ul><li>Adjustment được ghi và scope cần tính lại được xác định</li><li>Late-cost result dùng cho successor cost run</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Kế toán mua hàng hoặc kế toán kho
- **Trigger:** Phân bổ hợp lệ được rà soát
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope; source component identity/version/evidence; source/normalized amount; selected allocation method/policy version; 1..N exact valuation-exposure allocation lines + late_cost_basis_hash + allocation_hash; per-allocation original/posting period; idempotency key; actor/tenant/financial scope.

### Quy tắc và bất biến

<ul><li>Nguồn bắt buộc: Mỗi chi phí phải có source document/line/version và bằng chứng; không nhập một khoản tổng không truy nguyên</li><li>Chống trùng: Cùng stable `source_component_key` chỉ được ghi một economic cost; source revision mới không tạo cost mới</li><li>Thành phần giá trị: Chi phí mua, discount, hàng tặng và thuế được chuẩn hóa theo chính sách; VAT được khấu trừ không vào giá vốn</li><li>Ngoại tệ: Sổ tồn dùng VND; dùng tỷ giá do nguồn Kế toán cung cấp; chênh lệch thanh toán không làm đổi giá trị tồn đã ghi</li><li>Phân bổ: Tổng các dòng phân bổ phải khớp tổng chi phí sau chuẩn hóa; phần dư làm tròn phải được xử lý xác định</li><li>Kỳ mở/khóa: Kỳ còn mở ghi vào phạm vi cần tính lại; kỳ đã khóa ghi adjustment ở kỳ mở hiện tại và giữ liên kết kỳ gốc</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Chỉ UC-13-03 được tạo `LateLandedCost` + all allocations + adjustment/value + dirty scopes; server rebuild/recheck preview/source/version trước commit.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IV-04 — Record late landed cost](../behavioral-contracts/BC-IV-04.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-088](../../../03.design/screens/SCR-088.md); [SCR-089](../../../03.design/screens/SCR-089.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-13-03-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xác nhận ghi nhận chi phí” | Adjustment được ghi và scope cần tính lại được xác định; kết quả Late-cost result dùng cho successor cost run và có truy vết nguồn. |
| AS-UC-13-03-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-13-03-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-13-03-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G07 — Giá vốn và định giá tồn kho](../../../01.knowledge/decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3)
- **Bài tri thức liên quan:** [Các thành phần hình thành giá nhập thực tế](../../../01.knowledge/know-how/KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te.md); [Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-13 — Ghi nhận chi phí mua đến muộn](../journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-13-03-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-13-03, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-13-03. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.



## Wave 3 semantic lock

- `source_component_key` là economic identity; `source_revision` chỉ freshness/provenance.
- Scope được server/source policy chứng minh bằng `target_scope_key/version/hash`; UI không được tự mở rộng ngoài candidate set.
- Allocation target là `valuation_exposure_key/version/hash`; method metric cũng có version/hash.
- Preview/commit recheck `late_cost_basis_hash` và `allocation_hash` trên toàn selected set.
- Component route `DIRECT` hoặc `LATE` một lần; route LATE chờ đủ initial valuation exposure.
- Period mapping nằm trên từng allocation; multi-posting-period commit tạo 1..N adjustment batch atomically.

### Nguồn v3.10.1 — UC-13-03 — Xác nhận ghi nhận chi phí

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-13 — Ghi nhận chi phí mua đến muộn](../journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

---
id: UC-03-02
type: use-case
theme: theme-07
title: "Xác định giá nhập thực tế"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-03-02 — Xác định giá nhập thực tế

## 1. Mục tiêu và outcome

Xác định giá nhập thực tế để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Có phép tính hợp lệ hoặc danh sách thiếu/xung đột</li><li>Cost calculation draft có provenance</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Có scope và bằng chứng

### 2.2 Kết thúc khi

<ul><li>Có phép tính hợp lệ hoặc danh sách thiếu/xung đột</li><li>Cost calculation draft có provenance</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Kế toán kho hoặc người có quyền tài chính
- **Trigger:** Có scope và bằng chứng
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Read-scope envelope: selected valuation basis/scope identities + actor/tenant/warehouse scope. Response trả complete `DirectCostBasis`, provenance components, `basis_version/basis_hash`, `scope_version` và server-derived allocated values. Không yêu cầu idempotency key vì không mutation.

### Quy tắc và bất biến

<ul><li>Căn cứ giá: server dựng candidate `DirectCostBasis`; conflict dựa trên complete basis hash/value facts, không chỉ unit price/currency/FX. User chọn complete basis và ghi lý do khi conflict</li><li>Giá nhập thực tế: Bao gồm giá sau discount dòng, phân bổ discount cấp phiếu, chi phí mua phân bổ, thuế không được khấu trừ; loại VAT được khấu trừ</li><li>Hàng tặng: Phân bổ quyền lợi theo chính sách đã phê duyệt; không mặc định giá 0 nếu làm sai tổng giá trị</li><li>Ngoại tệ: Dùng tỷ giá được nguồn kế toán phê duyệt và lưu provenance</li><li>Làm tròn: allocation deterministic theo policy/version + stable scope order; partial dùng cumulative rounding</li><li>UOM: direct cost giữ transaction UOM/conversion snapshot và đồng thời normalize về base UOM cho downstream Official Cost</li><li>Freshness: preview trả basis/scope hash-version theo từng selected basis; không dùng một receipt-wide source version</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>UC này là read/preview nên không có business `UNKNOWN`. Nếu query timeout/lỗi tải, không có mutation; client refetch an toàn.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

UC này là read/preview; không tạo movement, ReceiptValuation hay balance mutation. Commit chỉ thuộc UC-03-03/BC-IV-01.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IV-05 — Build direct receipt valuation preview](../behavioral-contracts/BC-IV-05.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-015](../../../03.design/screens/SCR-015.md); contextual `VBottomSheet` trong SCR-015/SCR-017. `SCR-016` chỉ giữ historical ID, không thuộc active route. |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-03-02-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xác định giá nhập thực tế” | Có phép tính hợp lệ hoặc danh sách thiếu/xung đột; kết quả Cost calculation draft có provenance và có truy vết nguồn. |
| AS-UC-03-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-03-02-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-03-02-04 | Preview query bị timeout hoặc response lỗi | Client không nhận được preview | Không có mutation hoặc business UNKNOWN; refetch an toàn và dựng lại basis từ nguồn hiện hành. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B); [Nhóm G07 — Giá vốn và định giá tồn kho](../../../01.knowledge/decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3)
- **Bài tri thức liên quan:** [Hàng đã nhận nhưng chưa chốt giá](../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Các thành phần hình thành giá nhập thực tế](../../../01.knowledge/know-how/KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-03 — Xác nhận giá trị ban đầu của hàng nhận](../journeys/BJ-03-xac-nhan-gia-tri-ban-au-cua-hang-nhan.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-03-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-03-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-03-02. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

### Nguồn v3.10.1 — UC-03-02 — Xác định giá nhập thực tế

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-03 — Xác nhận giá trị ban đầu của hàng nhận](../journeys/BJ-03-xac-nhan-gia-tri-ban-au-cua-hang-nhan.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

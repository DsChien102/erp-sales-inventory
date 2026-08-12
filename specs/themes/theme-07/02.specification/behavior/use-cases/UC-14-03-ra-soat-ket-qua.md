---
id: UC-14-03
type: use-case
theme: theme-07
title: "Rà soát kết quả"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-14-03 — Rà soát kết quả

## 1. Mục tiêu và outcome

Rà soát kết quả để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Run và ProductCostResult được đọc/đối chiếu theo policy đã khóa</li><li>Không thay đổi trạng thái hay ledger</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Run không còn blocker

### 2.2 Kết thúc khi

<ul><li>Run và ProductCostResult được đọc/đối chiếu theo policy đã khóa</li><li>Không thay đổi trạng thái hay ledger</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Kế toán kho và người công bố giá vốn
- **Trigger:** Run không còn blocker
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

`run_id`; actor/tenant/store scope; expected read version/hash nếu client cần phát hiện stale presentation. Đây là query context, không dùng command envelope.

### Quy tắc và bất biến

<ul><li>Cùng dữ liệu: Hai phương pháp tính trên cùng movement/value snapshot và cut-off; phương pháp không chọn vẫn được giữ để đối chiếu</li><li>Policy theo kỳ: Phương pháp nguồn phải được version/khóa cho kỳ trước khi tính; không được override kín trong lúc review</li><li>Blocker: UNKNOWN, hàng chờ giá, kiểm kê/correction/reconciliation có thể đổi số liệu phải chặn đúng product-period scope</li><li>Run finality: Run đã bắt đầu không bị hủy, sửa hoặc tái sử dụng; sau khi dữ liệu thay đổi phải tạo successor run</li><li>Công bố nguyên tử: COGS true-up, ending inventory delta và official cost version cùng một batch cân bằng</li><li>Không hồi tố: Không sửa order, issue, receipt hoặc value movement gốc; mọi ảnh hưởng là adjustment liên kết</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Thiếu quyền/scope hoặc run không còn đọc được thì query trả lỗi rõ ràng.</li><li>Không có mutation hay tác động ledger.</li></ul>

**Chưa xác định:** <ul><li>Không áp dụng mutation `UNKNOWN`: đây là read-only query. Timeout/gián đoạn chỉ refetch cùng run/result hiện hành.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Không mutation; chỉ review immutable run/result. Nếu stale/blocker mới xuất hiện thì tạo successor qua UC-14-01/02.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** Read-only `API-Q-10` CostCalculationRun/ProductCostResult detail; không mutation BC

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-074](../../../03.design/screens/SCR-074.md); [SCR-076](../../../03.design/screens/SCR-076.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Hiển thị snapshot hiện hành và stale/blocker cụ thể. Query lỗi hoặc timeout chỉ cho phép refetch cùng `run_id`; không tạo trạng thái finality mới. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-14-03-01 | Điều kiện cần hợp lệ và run còn current | Tác nhân mở “Rà soát kết quả” | Run/ProductCostResult và consequence được hiển thị read-only; không đổi trạng thái/ledger. |
| AS-UC-14-03-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-14-03-03 | Cùng `run_id` được đọc lại | Client refetch | Trả snapshot run/result hiện hành theo quyền; không có duplicate-effect concern vì không mutation. |
| AS-UC-14-03-04 | Query bị timeout/gián đoạn | Client chưa nhận được dữ liệu | Refetch cùng `run_id`; không tạo mutation UNKNOWN và không phát sinh command retry. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G07 — Giá vốn và định giá tồn kho](../../../01.knowledge/decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3); [Nhóm G08 — Sửa sai, reversal và kỳ khóa](../../../01.knowledge/decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn)
- **Bài tri thức liên quan:** [Vì sao sử dụng song song hai phương pháp tính giá vốn](../../../01.knowledge/know-how/KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von.md); [Công bố đơn giá tồn kho và ghi nhận giá vốn xuất bán](../../../01.knowledge/know-how/KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-14 — Tính và công bố giá vốn](../journeys/BJ-14-tinh-va-cong-bo-gia-von.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-14-03-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-14-03, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-14-03. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.



## Wave 3 BJ14 deep-review lock — v3.9.9

- UC-14-03 là **read-only review** của CostCalculationRun/ProductCostResult qua `API-Q-10`; không gọi mutation contract publish, không tạo CommandReceipt, không có mutation UNKNOWN.
- Reviewer xem cùng input snapshot, hai method results, Product blockers, incremental COGS/ending-inventory deltas, proposed Official Cost và effective-time consequence. Method dùng publish do locked policy quyết định; reviewer không override.
- Nếu run input/dirty scope/ProductCostResult stale, UI chỉ dẫn tạo successor; review cũ không được publish.

### Nguồn v3.10.1 — UC-14-03 — Rà soát kết quả

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-14 — Tính và công bố giá vốn](../journeys/BJ-14-tinh-va-cong-bo-gia-von.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

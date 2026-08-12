---
id: UC-14-02
type: use-case
theme: theme-07
title: "Tính giá vốn và phát hiện blocker"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-14-02 — Tính giá vốn và phát hiện blocker

## 1. Mục tiêu và outcome

Tính giá vốn và phát hiện blocker để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Có hai kết quả và blocker snapshot</li><li>Draft run blocked hoặc ready for review</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Có context hợp lệ

### 2.2 Kết thúc khi

<ul><li>Có hai kết quả và blocker snapshot</li><li>Draft run blocked hoặc ready for review</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Kế toán kho và người công bố giá vốn
- **Trigger:** Có context hợp lệ
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope.

### Quy tắc và bất biến

<ul><li>Cùng dữ liệu: Hai phương pháp tính trên cùng movement/value snapshot và cut-off; phương pháp không chọn vẫn được giữ để đối chiếu</li><li>Policy theo kỳ: Phương pháp nguồn phải được version/khóa cho kỳ trước khi tính; không được override kín trong lúc review</li><li>Blocker: UNKNOWN, hàng chờ giá, kiểm kê/correction/reconciliation có thể đổi số liệu phải chặn đúng product-period scope</li><li>Run finality: Run đã bắt đầu không bị hủy, sửa hoặc tái sử dụng; sau khi dữ liệu thay đổi phải tạo successor run</li><li>Công bố nguyên tử: COGS true-up, ending inventory delta và official cost version cùng một batch cân bằng</li><li>Không hồi tố: Không sửa order, issue, receipt hoặc value movement gốc; mọi ảnh hưởng là adjustment liên kết</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Chỉ tạo thay đổi được nêu trong BC-IV-02; UI hoặc adapter không được tự thêm transition.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IV-02 — Calculate inventory cost](../behavioral-contracts/BC-IV-02.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-074](../../../03.design/screens/SCR-074.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-14-02-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Tính giá vốn và phát hiện blocker” | Có hai kết quả và blocker snapshot; kết quả Draft run blocked hoặc ready for review và có truy vết nguồn. |
| AS-UC-14-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-14-02-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-14-02-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G07 — Giá vốn và định giá tồn kho](../../../01.knowledge/decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3); [Nhóm G08 — Sửa sai, reversal và kỳ khóa](../../../01.knowledge/decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn)
- **Bài tri thức liên quan:** [Vì sao sử dụng song song hai phương pháp tính giá vốn](../../../01.knowledge/know-how/KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von.md); [Công bố đơn giá tồn kho và ghi nhận giá vốn xuất bán](../../../01.knowledge/know-how/KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-14 — Tính và công bố giá vốn](../journeys/BJ-14-tinh-va-cong-bo-gia-von.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-14-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-14-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-14-02. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.



## Wave 3 BJ14 deep-review lock — v3.9.9

- Hai phương pháp chạy trên cùng ordered valuation facts tới `cutoff_valuation_sequence`.
- Server materialize immutable `ProductCostResult` cho từng Product; global totals là aggregate, không phải calculation authority.
- Product result giữ predecessor Official Cost, target cumulative COGS/carrying value, current authoritative baseline, proposed Official Cost và incremental reconciliation deltas.
- Edge cases: negative normalized quantity/value không hợp lệ là blocker; denominator 0 trả `NO_NEW_COST_BASIS`; ending quantity 0 vẫn cho COGS true-up nếu có basis; zero unit cost chỉ hợp lệ khi provenance authoritative cho ra 0.
- Dirty cause hoặc valuation fact mới sau snapshot làm run stale; started run không được mutate/reuse, phải tạo successor.

### Nguồn v3.10.1 — UC-14-02 — Tính giá vốn và phát hiện blocker

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-14 — Tính và công bố giá vốn](../journeys/BJ-14-tinh-va-cong-bo-gia-von.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

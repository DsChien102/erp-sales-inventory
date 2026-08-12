---
id: UC-05-05
type: use-case
theme: theme-07
title: "Ghi xuất kho nguyên tử"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-05-05 — Ghi xuất kho nguyên tử

## 1. Mục tiêu và outcome

Ghi xuất kho nguyên tử để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Movement, balance, reservation nếu có và cost snapshot cùng commit</li><li>Inventory issue result dùng chung</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Có lô/nguồn xuất hợp lệ và allocation khi hành trình yêu cầu

### 2.2 Kết thúc khi

<ul><li>Movement, balance, reservation nếu có và cost snapshot cùng commit</li><li>Inventory issue result dùng chung</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Người dùng có thẩm quyền hoặc hệ thống nguồn
- **Trigger:** Có lô/nguồn xuất hợp lệ và allocation khi hành trình yêu cầu
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope.

### Quy tắc và bất biến

<ul><li>Không có official cost: Chặn checkout và yêu cầu hoàn tất định giá; không ghi COGS bằng 0 hoặc giá dự kiến</li><li>Chọn lô: FEFO khi có hạn dùng, FIFO khi không có; override cần quyền và lý do</li><li>Cạnh tranh tồn: Giao dịch ghi nhận trước được ưu tiên; yêu cầu sau phải kiểm lại và có thể bị từ chối</li><li>Combo: Mọi component xuất all-or-nothing theo số nguyên combo</li><li>UNKNOWN: Sales chuyển INVENTORY_CONFIRMATION_PENDING; không tạo issue thứ hai, không tự hoàn tất đơn hay refund</li><li>Payment: Nếu payment đã có trước UNKNOWN, Payment/Sales giữ trạng thái pending resolution theo contract liên miền</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Chỉ tạo thay đổi được nêu trong BC-IO-04, BC-IO-05; UI hoặc adapter không được tự thêm transition.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IO-04 — Complete online POS checkout](../behavioral-contracts/BC-IO-04.md); [BC-IO-05 — Pick and hand over fulfillment](../behavioral-contracts/BC-IO-05.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-028](../../../03.design/screens/SCR-028.md); [SCR-029](../../../03.design/screens/SCR-029.md) |
| Quy tắc sở hữu | Không sở hữu màn hình riêng. UI của UC gọi hiển thị trạng thái tiến trình/kết quả và giữ cùng operation identity. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-05-05-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Ghi xuất kho nguyên tử” | Movement, balance, reservation nếu có và cost snapshot cùng commit; kết quả Inventory issue result dùng chung và có truy vết nguồn. |
| AS-UC-05-05-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-05-05-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-05-05-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G01 — Phạm vi, thẩm quyền và mô hình tồn](../../../01.knowledge/decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho); [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t)
- **Bài tri thức liên quan:** [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Công bố đơn giá tồn kho và ghi nhận giá vốn xuất bán](../../../01.knowledge/know-how/KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Bán hàng POS offline](../../../01.knowledge/know-how/KB-KGV-039-ban-hang-pos-offline.md); [Giữ hàng và xử lý đơn không đủ tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-05 — Lấy hàng và bàn giao đơn](../journeys/BJ-05-lay-hang-va-ban-giao-on.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-05-05-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-05-05, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-05-05. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.



## v3.9.3 — Deep-review semantic locks

- Phân biệt ba lớp fact: **allocation plan** (`allocated`), **pick evidence** (`picked`) và **handover/issue consumption** (`consumed`). Partial handover không rewrite lịch sử allocation/pick.
- Source `requested_quantity` bất biến theo source version; `remaining_to_handover` derive từ requested − cumulative committed handover.
- Nếu đổi/stale LOT khi còn picked chưa consume, phải xác nhận physical correction (trả LOT cũ + lấy lại LOT mới) trước khi handover.
- `lot_pickable_quantity` là server-calculated candidate tại as-of/version, không phải reservation theo LOT.
- UOM/precision: UI theo source UOM; guard/ledger theo base UOM với conversion snapshot/version.
- Partial policy thuộc fulfillment source/version.
- Mỗi handover commit tạo immutable `HandoverEvidence`; result hiển thị `confirmed_at` cho user, metadata kỹ thuật giữ trong contract/audit.
- `UNKNOWN` → `Đang xác minh bàn giao`, non-actionable, giữ cùng operation identity và handoff BJ17; không blind retry.

### Nguồn v3.10.1 — UC-05-05 — Ghi xuất kho nguyên tử

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng dùng chung  
> **Hành trình nghiệp vụ:** [BJ-05 — Lấy hàng và bàn giao đơn](../journeys/BJ-05-lay-hang-va-ban-giao-on.md)  
> **Consumer/XREF:** [XREF-01 / T5-BJ-CHECKOUT-POS](../../../07.evidence/outbound-v3.10.1/theme-05-sales-pos/t5-bj-checkout-pos.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

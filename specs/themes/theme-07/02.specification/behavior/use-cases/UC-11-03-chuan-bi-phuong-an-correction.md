---
id: UC-11-03
type: use-case
theme: theme-07
title: "Chuẩn bị phương án correction"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-11-03 — Chuẩn bị phương án correction

## 1. Mục tiêu và outcome

Chuẩn bị phương án correction để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Phương án khả thi đủ căn cứ hoặc bị chặn</li><li>Correction proposal</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Operation đã hoàn tất và có correction intent

### 2.2 Kết thúc khi

<ul><li>Phương án khả thi đủ căn cứ hoặc bị chặn</li><li>Correction proposal</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Người vận hành kho và người duyệt sửa sai
- **Trigger:** Operation đã hoàn tất và có correction intent
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope.

### Quy tắc và bất biến

<ul><li>Hủy trước thực thi: Chỉ DRAFT, PENDING_APPROVAL hoặc READY được hủy; cancellation không tạo movement/value</li><li>UNKNOWN: Không đảo hoặc thay thế khi chưa xác lập finality; phải đối soát bằng cùng operation ID</li><li>Operation hoàn tất: Không sửa payload/result; tạo operation mới trong correction chain</li><li>Dependency: Chặn reversal nếu làm âm tồn hoặc dependency chưa được trung hòa; không giả lập trung hòa bằng sửa số dư</li><li>Delta hay full reversal: Dùng delta khi chỉ phần sai có thể sửa độc lập và giữ đúng nguồn; dùng reversal + replacement khi toàn operation mất hiệu lực hoặc payload đúng phải được xác lập lại nguyên khối</li><li>Hàng thực quay về: Sale Issue đã bàn giao chỉ tăng tồn qua BJ-06; cancellation/correction không thay thế việc nhận hàng thực tế</li></ul>

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
| Màn hình liên quan | [SCR-049](../../../03.design/screens/SCR-049.md); [SCR-052](../../../03.design/screens/SCR-052.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-11-03-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Chuẩn bị phương án correction” | Phương án khả thi đủ căn cứ hoặc bị chặn; kết quả Correction proposal và có truy vết nguồn. |
| AS-UC-11-03-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-11-03-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-11-03-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G08 — Sửa sai, reversal và kỳ khóa](../../../01.knowledge/decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn); [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh)
- **Bài tri thức liên quan:** [Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [Vòng đời của một Inventory Operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-11 — Hủy và sửa sai nghiệp vụ kho](../journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-11-03-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-11-03, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-11-03. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

### Nguồn v3.10.1 — UC-11-03 — Chuẩn bị phương án correction

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-11 — Hủy và sửa sai nghiệp vụ kho](../journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

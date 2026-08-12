---
id: CAP-01-OP-02
type: behavioral-contract
theme: theme-07
title: "Cấu hình cận hạn mặc định"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
classification: supporting-capability-operation
---
# CAP-01-OP-02 — Cấu hình cận hạn mặc định

## 1. Ý định

Cấu hình cận hạn mặc định để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

## 2. Phạm vi áp dụng

Operation contract của `CAP-01`; không phải UC/BJ canonical.

- **Actor:** Quản trị cấu hình sản phẩm/tồn kho
- **Trigger:** Người có quyền mở tenant policy

## 3. Đầu vào nghiệp vụ

Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope.

## 4. Điều kiện trước

Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 5. Quy tắc nghiệp vụ

<ul><li>Threshold/target: Bắt buộc target_stock_level ≥ low_stock_threshold ≥ 0</li><li>Cận hạn: Số ngày không âm; action chỉ thuộc WARN hoặc BLOCK_SALE</li><li>Fallback: Product override ưu tiên; khi bỏ override phải quay về tenant default hiện hành</li><li>LOT/NONE: Chính sách cận hạn chỉ tạo kết quả cho hàng có hạn dùng; không tạo expiry giả cho sản phẩm NONE</li><li>Scope Phase 1: UI tự áp kho mặc định; mô hình phải giữ scope product + warehouse để mở rộng</li><li>Version: Mỗi thay đổi tạo version/effective time; query phải truy được policy đã dùng</li></ul>

## 6. Điều kiện bắt buộc

Các bất biến trong mục 5 phải giữ nguyên; migration không bổ sung constraint mới.

## 7. Ảnh hưởng trạng thái

Chỉ tạo thay đổi được nêu trong BC-XD-05; UI hoặc adapter không được tự thêm transition.

## 8. Tính nguyên tử và kết quả cuối

<ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 9. Kết quả và semantics lỗi

**Thành công:** <ul><li>Default days/action được lưu hoặc bị từ chối</li><li>Tenant near-expiry policy version</li></ul>

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

| ID | Given | When | Then |
|---|---|---|---|
| AS-CAP-01-OP-02-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Cấu hình cận hạn mặc định” | Default days/action được lưu hoặc bị từ chối; kết quả Tenant near-expiry policy version và có truy vết nguồn. |
| AS-CAP-01-OP-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-CAP-01-OP-02-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-CAP-01-OP-02-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

## 10. Domain và UC sử dụng

- **Nguồn quyết định:** [Nhóm G13 — Bổ sung hàng và vòng đời master data](../../../01.knowledge/decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức:** [Cảnh báo tồn kho và vòng đời xử lý](../../../01.knowledge/know-how/KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md); [Tồn dự kiến và đề xuất bổ sung hàng](../../../01.knowledge/know-how/KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang.md); [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Cách kiểm soát thay đổi đối với quy tắc nghiệp vụ](../../../01.knowledge/know-how/KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu.md)
- **BC chính:** [BC-XD-05 — Configure inventory product policy](BC-XD-05.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [CAP-01 — Cấu hình chính sách tồn và cận hạn](CAP-01.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo capability package; operation này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-CAP-01-OP-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định CAP-01-OP-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của CAP-01-OP-02. Capability contract giữ scope và operation flow; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

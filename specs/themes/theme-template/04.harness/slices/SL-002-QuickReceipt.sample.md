---
id: SL-002
type: slice
theme: theme-07
title: Lập và gửi yêu cầu nhận hàng nhanh
owner: SE
contributors: [BA, SA, QA]
status: DRAFT
sample_of: SLICE.template.md
sample_status: NON_CANONICAL_EXAMPLE
---

# SL-002 — Lập và gửi yêu cầu nhận hàng nhanh

**Nguồn:** [BJ-02](../../02.specification/behavior/journeys/BJ-02.sample.md),
[UC-02-02](../../02.specification/behavior/use-cases/UC-02-02.sample.md),
[SCR-009](../../03.design/screens/SCR-009.sample.md).
**Phạm vi bao phủ:** UC-02-02 BF-01…BF-09, AF-A…AF-D, EF-A…EF-C; AS-UC-02-02-01…09; giao diện lập, nhập hàng thực nhận và gửi yêu cầu.
**Chưa bao phủ:** Quyết định phê duyệt UC-02-03, ghi nhận tồn UC-02-04, phục hồi thực thi UC-02-05.

## 1. Mục tiêu (Objective)

Người lập hoàn thiện và gửi hồ sơ nhận hàng nhanh từ giao diện, nhận kết quả PENDING_APPROVAL mà chưa thay đổi tồn vật lý.

## 2. Phạm vi và quy tắc (Scope & Rules)

**Sở hữu:** Điều phối Application tạo/sửa/gửi hồ sơ; ánh xạ dữ liệu và kết quả; giao diện và các state/action phục vụ UC; kiểm tra tích hợp từ giao diện đến kết quả nghiệp vụ.

**Không sở hữu:** Quy tắc Aggregate dùng chung, Product/Supplier master, quyết định duyệt, execution tồn kho và cơ chế idempotency dùng chung.

| ID | Cách áp dụng trong Slice |
|---|---|
| [UC-02-02](../../02.specification/behavior/use-cases/UC-02-02.sample.md) | Triển khai các Flow và Scenario được liệt kê ở metadata |
| [BC-IO-16](../../02.specification/behavior/behavioral-contracts/BC-IO-16.sample.md) | Lưu/sửa draft |
| [BC-IC-07](../../02.specification/behavior/behavioral-contracts/BC-IC-07.sample.md) | Gửi và chuyển sang chờ duyệt |
| [SCR-009](../../03.design/screens/SCR-009.sample.md) | Tìm sản phẩm, chọn đơn vị tính, danh sách và điều hướng mặt hàng |

## 3. Luồng xử lý (Flow)

1. Xác lập ngữ cảnh, quyền và hồ sơ nhận hàng nhanh.
2. Hoàn thiện thông tin chung, căn cứ và mặt hàng từ giao diện.
3. Application sử dụng Aggregate để lưu/sửa bản nháp theo BC-IO-16.
4. Rà soát và gửi theo BC-IC-07; xác nhận PENDING_APPROVAL.
5. Hiển thị kết quả và bàn giao UC-02-03.

Thiếu dữ liệu dẫn về AF-C; thiếu quyền hoặc dữ liệu không còn hợp lệ theo EF-A/EF-C. Mất phản hồi khi gửi theo EF-B: làm rõ cùng yêu cầu, không tạo hồ sơ mới và không hiển thị thành công khi chưa có xác nhận.

## 4. Thiết kế (Design)

### Domain và Application

Dùng [AGG-IO-01](../../02.specification/domain/aggregates/AGG-IO-01-InventoryOperation.sample.md) và [FND-01](../../02.specification/technical-contracts/FND-01-Idempotency.sample.md).
Application kiểm tra ngữ cảnh/quyền, đọc dữ liệu từ nơi sở hữu, gọi Aggregate và lưu kết quả cùng idempotency trong transaction của thao tác. Draft không tạo phê duyệt; submit hợp lệ khóa nội dung và tạo trạng thái chờ duyệt.

### Giao diện

SCR-009 giữ tìm kiếm khi EMPTY; một đơn vị tính thì mở SCR-084, nhiều đơn vị tính thì hiển thị lựa chọn trực tiếp. Trùng sản phẩm/đơn vị tính: cảnh báo và mở dòng đã có. Xong ở SCR-084 quay lại SCR-009; đủ ít nhất một mặt hàng và tất cả đã xử lý thì chuyển SCR-010.

Giữ editable/read-only/permission/data-unavailable; không hiển thị điều khiển sửa khi chỉ đọc. Dùng VCard, VSearchBar, VIcon.chevronRight, Theme7InlineSingleChoice, VBanner.warning, VButton.primary và VEmptyState theo Screen Contract. Mobile-first, vùng chạm tối thiểu 44px theo sample gốc; không chỉ dùng màu để biểu đạt trạng thái.

Các Screen SCR-006/008/084/010 thuộc phạm vi đích nhưng chưa có sample đầy đủ trong bộ này; phải cung cấp contract và mapping trước READY_TO_IMPLEMENT.

### Lưu trữ, lỗi và tác động

Idempotency và business result phải commit cùng nhau theo FND-01. Bảo toàn nghĩa của OPERATION_NOT_DRAFT, VERSION_CONFLICT, IDEMPOTENCY_PAYLOAD_MISMATCH, SOURCE_VERSION_STALE và lỗi quyền/phạm vi.

Schema vật lý, field/nullability, API mapping và transaction phối hợp Approval cần chốt trong thiết kế thực tế. Sample không tạo migration hoặc sự kiện mới cho draft.

## 5. Phụ thuộc và hợp đồng (Dependencies & Contracts)

| ID / Link | Cần gì trước khi triển khai | Trạng thái |
|---|---|---|
| [SL-001](SL-001-InventoryOperation.sample.md) | Ranh giới và hành vi Aggregate đã review | DRAFT |
| [FND-01](../../02.specification/technical-contracts/FND-01-Idempotency.sample.md) | Replay/conflict/uncertain và commit cùng thao tác | Có sample |
| [UC-02-02](../../02.specification/behavior/use-cases/UC-02-02.sample.md) | Ranh giới lập và gửi đã xác định trong V5 | IN_REVIEW |
| [SCR-009](../../03.design/screens/SCR-009.sample.md) | State/action, DS và điều hướng | Có sample |
| [Prototype manifest](../../03.design/prototype/README.template.md) | Build và contract các Screen còn lại | Chưa đủ trong bộ sample |

Các tên MaintainQuickReceiptDraftCommand và SubmitInventoryOperationCommand là định hướng từ sample cũ, chưa phải schema được công bố. Tương tự, POST/PUT /v1/inventory-operations và POST /v1/inventory-operations/{id}/submission là mapping tham khảo cũ, cần đối chiếu interface thực tế trước triển khai; không dùng làm bằng chứng API đã tồn tại.

Tra cứu Product/UOM dùng interface của Domain sở hữu. Giao diện gọi Application qua interface đã công bố, không gọi trực tiếp Aggregate. Không còn câu hỏi về Submit thuộc UC nào: UC-02-02 sở hữu việc gửi.

## 6. Kiểm chứng (Verification)

- [ ] **AC-01** Tạo/sửa draft và gửi đúng UC-02-02; submit hợp lệ đạt PENDING_APPROVAL, không tăng tồn.
- [ ] **AC-02** Chọn UOM, lô, ngăn dòng trùng và bổ sung dữ liệu đúng Flow.
- [ ] **AC-03** Retry, UNKNOWN, quyền và xung đột không tạo tác động trùng hoặc ghi đè sai.
- [ ] **AC-04** Giao diện đủ state/action, điều hướng và phản hồi từ Screen Contract.

| Test ID | Tiêu chí / Scenario | Cách kiểm tra |
|---|---|---|
| scn_sl_002_submit | AC-01; AS-UC-02-02-01/05/08/09 | Application/integration |
| scn_sl_002_items | AC-02; AS-UC-02-02-02/04 | Domain + UI |
| scn_sl_002_failures | AC-03; AS-UC-02-02-03/06/07 | Contract/integration |
| scn_sl_002_screen | AC-04; SCR-009 và mapping Screen còn lại | UI/E2E, DS và accessibility |

## 7. Bàn giao (Delivery)

**Đầu ra:** Application orchestration, interface đã chốt, giao diện liên quan, kiểm tra và evidence cho phạm vi UC.
**Evidence/commit/build:** Chưa có; đây là mẫu thiết kế, không phải xác nhận đã triển khai.

**Câu hỏi còn mở:** Schema Command/Query/DTO, interface chính thức, contract các Screen còn thiếu, transaction phối hợp Approval và dependency SL-001.

**Bước tiếp theo:** BA/SA/SE hoàn thiện các nguồn còn thiếu, review thiết kế rồi mới chuyển READY_TO_IMPLEMENT. Không tách thêm Slice chỉ vì backend và frontend do người khác nhau thực hiện.

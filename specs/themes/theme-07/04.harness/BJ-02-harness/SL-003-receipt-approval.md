# Work Slice: SL-003 — Phê duyệt phiếu nhận

```yaml
id: SL-003
journey:
  - BJ-02
usecase:
  - UC-02-03
sources:
  - BC-IC-06
  - ENT-IC-02
  - API-Q-08
  - SCR-011
  - UIF-02
  - JA-02
theme: theme-07
```

**design_status** trên [`CATALOG.md`](CATALOG.md). Field và RPC lấy từ SRS.

---

## Objective

Người duyệt đọc snapshot phiếu nhận nhanh đang chờ và ghi một quyết định: duyệt thì phiếu `READY`, từ chối thì `REJECTED`, cả hai không ghi movement.

---

## Blocked by

- [SL-002](SL-002-quick-receipt.md) — phiếu nhận nhanh gửi xong mới có `PENDING_APPROVAL` và `approvalCaseId`

---

## Scope & Rules

### In Scope

- Đọc việc duyệt được giao cho phiếu nhận nhanh
- `DecideApproval` ([BC-IC-06](../../02.specification/behavior/behavioral-contracts/BC-IC-06.md)): duyệt → phiếu `READY`. Từ chối có lý do → phiếu `REJECTED`
- Quyết định đầu tiên thắng. Người duyệt khác người lập. Không sửa payload. Không movement
- SCR-011: Duyệt và Từ chối. Lý do từ chối bắt buộc
- Fact `EVT-IC-04` khi quyết định đã ghi
- Scenario duyệt, từ chối, tự duyệt, quyết định thứ hai

### Out of Scope

- Nhận theo chứng từ vượt ngưỡng — hàng `SL-001` trên catalog
- Ghi tồn sau `READY` — [SL-004](SL-004-physical-receipt.md)
- Hàng đợi duyệt dùng chung ngoài phiếu nhận nhanh
- SCR-012 — [SL-004](SL-004-physical-receipt.md)
- Command yêu cầu ghi tồn trên outbox

### Boundary

| Concern | Owner |
| --- | --- |
| ApprovalCase và quyết định | Inventory, `DecideApproval` |
| Phiếu `PENDING_APPROVAL` | [SL-002](SL-002-quick-receipt.md) |
| Màn hình người duyệt | `apps/erp`, SCR-011 |

### Rules

| ID | Quy tắc (slice) |
| --- | --- |
| [UC-02-03 BR-01](../../02.specification/behavior/use-cases/UC-02-03-phe-duyet-yeu-cau-nhan-hang.md) | Nhập hàng nhanh luôn phải có quyết định duyệt |
| [UC-02-03 BR-02](../../02.specification/behavior/use-cases/UC-02-03-phe-duyet-yeu-cau-nhan-hang.md) | Người duyệt còn quyền, đúng kho, đúng cấp, khác người lập |
| [UC-02-03 BR-03](../../02.specification/behavior/use-cases/UC-02-03-phe-duyet-yeu-cau-nhan-hang.md) | Quyết định commit hợp lệ đầu tiên thắng |
| [UC-02-03 BR-04](../../02.specification/behavior/use-cases/UC-02-03-phe-duyet-yeu-cau-nhan-hang.md) | Duyệt chỉ đưa phiếu sang `READY`. Không giữ hàng, không movement |
| [UC-02-03 BR-05](../../02.specification/behavior/use-cases/UC-02-03-phe-duyet-yeu-cau-nhan-hang.md) | Từ chối bắt buộc có lý do. Không đổi tồn |
| [BC-IC-06](../../02.specification/behavior/behavioral-contracts/BC-IC-06.md) | Lỗi: `APPROVER_NOT_ELIGIBLE`, `SELF_APPROVAL_NOT_ALLOWED`, `APPROVAL_ALREADY_DECIDED`, `REJECTION_REASON_REQUIRED` |

### Open Questions

- DTO snapshot cho SCR-011 (Supplier, kho, ngày, evidence, dòng Product+UOM, phân loại, LOT) chưa có fence. Không đưa `subjectSnapshot` thô vào query DTO khi chưa có shape.
- `decision` ngoài `APPROVE` / `REJECT` (ENT-IC-02 còn `REQUEST_RECOUNT`) không thuộc UC-02-03. Slice chỉ hai giá trị này cho đến khi review nói khác.
- Tên RPC và `p_*` của `API-C-19` / `API-Q-08` chưa có trong nguồn declarative.
- Tên bảng ApprovalCase chưa có trong nguồn declarative. Entity: [ENT-IC-02](../../02.specification/domain/entities/ENT-IC-02-ApprovalCase.md).
- Path route SCR-011 chưa có trong SRS.

---

## Flow

### Main Flow

1. Người duyệt mở việc được giao, không phải menu của người lập.
2. Hệ thống trả snapshot bất biến của phiếu đang `PENDING_APPROVAL`.
3. Người duyệt chọn Duyệt, hoặc Từ chối kèm lý do.
4. Một transaction ghi quyết định, chuyển phiếu, ghi CommandReceipt và fact `EVT-IC-04`.
5. UI hiện kết quả. Back về danh sách việc của người duyệt. Không movement.

### Failure Flow

1. Actor là người lập → `SELF_APPROVAL_NOT_ALLOWED` → phiếu vẫn chờ.
2. Hết quyền, sai kho hoặc sai cấp → `APPROVER_NOT_ELIGIBLE` → không ghi quyết định.
3. `REJECT` thiếu lý do → `REJECTION_REASON_REQUIRED` → UI không gọi decide.
4. Đã có quyết định commit → `APPROVAL_ALREADY_DECIDED` → giữ quyết định đầu.

---

## Design

### Domain

**Before:** phiếu `PENDING_APPROVAL`, ApprovalCase chưa quyết định.
**After:** duyệt thì phiếu `READY`. Từ chối thì phiếu `REJECTED` kèm lý do. Không movement, không balance, không `EVT-IO-01`.

### Persistence

Tên bảng ApprovalCase chưa đặt. Draft lúc implement: `supabase/migrations/_drafts/inventory_receipt_approval.sql`.

| RPC | Params `p_*` | Returns |
| --- | --- | --- |
| Chưa chốt. FND: `API-C-19` quyết định. `API-Q-08` hàng đợi | Chưa có trong nguồn | DTO ở Contracts |

| Code | Khi nào | Hệ quả |
| --- | --- | --- |
| `APPROVER_NOT_ELIGIBLE` | Hết quyền, sai kho hoặc sai cấp | Không ghi quyết định |
| `SELF_APPROVAL_NOT_ALLOWED` | Actor là người lập | Không ghi quyết định |
| `APPROVAL_ALREADY_DECIDED` | Đã có quyết định commit | Giữ quyết định đầu |
| `REJECTION_REASON_REQUIRED` | `REJECT` thiếu lý do | Không ghi |

### Transaction / Idempotency

Một transaction: recheck quyền, cấp, segregation, snapshot hash; append quyết định; phiếu `READY` hoặc `REJECTED`; CommandReceipt; outbox fact khi quyết định đã ghi.

- `idempotencyKey` ≠ `command.id`
- Unique `(tenant_id, command_scope, idempotency_key)`
- Quyết định commit hợp lệ đầu tiên thắng
- Cùng key và cùng hash → snapshot trước. Hash khác → conflict

### Code Layout

```text
modules/
    inventory/
        application/
            lib/
                src/
                    goods_receipt/
                        commands/
                            decide_receipt_approval/
                                decide_receipt_approval_command.dart
                                decide_receipt_approval_handler.dart
                        queries/
                            get_receipt_approval_case/
                                get_receipt_approval_case_query.dart
                                get_receipt_approval_case_handler.dart
                        shared/
                            receipt_approval_case_dto.dart
                            decide_receipt_approval_result_dto.dart
                        testing/
                            fake_receipt_approval_port.dart
        infrastructure/
            lib/
                src/
                    goods_receipt/
                        receipt_approval_gateway.dart
apps/
    erp/
        lib/
            features/
                inventory/
                    receipt/
                        presentation/
                            receipt_approval_page.dart
                            widgets/
                                receipt_approval_decision_bar.dart
```

---

## Contracts

Handler [FND-TECH-01](../../02.specification/technical-contracts/FND-TECH-01.md): `DecideApproval` (`API-C-19`). Hàng đợi: `API-Q-08`. Snapshot hiển thị theo [SCR-011](../../03.design/screens/SCR-011.md).

### GetReceiptApprovalCaseQuery

> Đọc khi người duyệt mở việc được giao. Outcome: snapshot bất biến của phiếu đang `PENDING_APPROVAL`, hoặc từ chối nếu actor không đủ quyền.

```dart
class GetReceiptApprovalCaseQuery {
  final String approvalCaseId;
}
```

### ReceiptApprovalCaseDto

```dart
class ReceiptApprovalCaseDto {
  final String approvalCaseId;
  final String receiptId;
  final String subjectSnapshotHash;
  final String requesterId;
  final String status; // PENDING
}
```

### DecideReceiptApprovalCommand

> Gọi khi người duyệt chọn Duyệt hoặc Từ chối. Outcome: một quyết định. Duyệt đưa phiếu sang `READY`. Từ chối đưa phiếu sang `REJECTED` kèm lý do. Không movement.

```dart
class DecideReceiptApprovalCommand {
  final String idempotencyKey; // ≠ command.id
  final String approvalCaseId;
  final String subjectSnapshotHash;
  final String decision; // APPROVE | REJECT
  final String? rejectionReason;
}
```

### DecideReceiptApprovalResultDto

```dart
class DecideReceiptApprovalResultDto {
  final String approvalCaseId;
  final String receiptId;
  final String receiptStatus; // READY | REJECTED
  final String decision;
  final bool replayed;
}
```

`IReceiptApprovalPort.getCase` → `ReceiptApprovalCaseDto`.
`IReceiptApprovalPort.decide` → `DecideReceiptApprovalResultDto`.
`FakeReceiptApprovalPort`: actor là requester → `SELF_APPROVAL_NOT_ALLOWED`. Quyết định thứ hai → `APPROVAL_ALREADY_DECIDED` và giữ kết quả đầu. `REJECT` thiếu lý do → `REJECTION_REASON_REQUIRED`. Không ghi movement.

### Integration

- Fact sau quyết định: `EVT-IC-04` / `inventory.approval.decided.v1` ([FND-TECH-01](../../02.specification/technical-contracts/FND-TECH-01.md) §6.3–6.4).
- Không phát event yêu cầu ghi tồn.

---

## Presentation

### Screens

| Screen | State / action | Nguồn |
| --- | --- | --- |
| SCR-011 | `ACT-02-DECIDE`. Chỉ Duyệt và Từ chối. Lý do từ chối bắt buộc | [SCR-011](../../03.design/screens/SCR-011.md) |

Entry là việc được giao. Back về danh sách việc của người duyệt.

### Route

- [UIF-02](../../03.design/flows/UIF-02-BJ-02.md) `UIF-02-T11`: người duyệt mở từ công việc được giao
- Không điều hướng người lập từ SCR-010 sang SCR-011 trong cùng session
- Path route cụ thể nằm ở Open Questions

### State × feedback

| State | UI / feedback | Error code |
| --- | --- | --- |
| loading | Snapshot chưa hiện nút quyết định | — |
| empty | Nguồn chưa mô tả hàng đợi rỗng. Entry là một việc được giao | — |
| error | Từ chối không lý do: chặn gửi, hỏi lý do | `REJECTION_REASON_REQUIRED` |
| success | Duyệt: phiếu sẵn sàng ghi nhận, không màn «đã vào tồn». Từ chối: kết thúc, có lý do, không đổi tồn | — |
| permission | Không đủ cấp hoặc là người lập: không ghi quyết định | `APPROVER_NOT_ELIGIBLE`, `SELF_APPROVAL_NOT_ALLOWED` |
| already decided | Hiện quyết định đã có. Không form quyết định mới | `APPROVAL_ALREADY_DECIDED` |
| ready | Lý do duyệt là info vì đây là nhập nhanh. Hiện người gửi | — |

### Design system

- `VCard` cho bối cảnh nhận, tóm tắt yêu cầu, dòng hàng kèm lô
- Không hiện id kỹ thuật, payload hay version
- Financial mask theo SCR-011 khi actor không có quyền xem giá

### Mediator

- `GetReceiptApprovalCaseQuery` và `DecideReceiptApprovalCommand` qua `IModuleMediator`
- Fake khớp Contracts của slice này
- Page thuộc `apps/erp`

---

## Verification

### Acceptance Criteria

- [ ] **AC-01** Given case pending và actor khác người lập, When Duyệt, Then phiếu `READY`, có `EVT-IC-04`, không movement, và UI không có CTA ghi tồn
- [ ] **AC-02** Given từ chối thiếu lý do, When gửi, Then `REJECTION_REASON_REQUIRED` và UI không gọi decide. Từ chối đủ lý do thì phiếu `REJECTED`, không đổi tồn
- [ ] **AC-03** Given người lập mở đúng case của mình, When Duyệt, Then `SELF_APPROVAL_NOT_ALLOWED` và phiếu vẫn chờ
- [ ] **AC-04** Given đã có quyết định, When quyết định thứ hai, Then giữ kết quả đầu

### Tests

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_approve_ready` | Case pending, actor khác maker / APPROVE / phiếu `READY`, không movement | application fake |
| `scn_reject_reason` | Case pending / REJECT không lý do / `REJECTION_REASON_REQUIRED` | application fake |
| `scn_first_wins` | Đã có quyết định / quyết định thứ hai / giữ kết quả đầu | application fake |
| `scn_self_approval` | Actor là maker / decide / `SELF_APPROVAL_NOT_ALLOWED` | application / RPC |
| `scn_approve_ui` | Case quick pending / Duyệt / trạng thái sẵn sàng, không nút ghi tồn | widget |
| `scn_reject_ui` | Bấm Từ chối / chưa có lý do / không gọi decide | widget |

### Scenarios

| Scenario | Actor | Across | Given / When / Then | Seed / fixture | Pass / fail |
| --- | --- | --- | --- | --- | --- |
| Duyệt | Người duyệt khác người lập | UI → mediator → RPC → DB | G: phiếu quick `PENDING_APPROVAL` / W: mở việc được giao và Duyệt / T: phiếu `READY`, có `EVT-IC-04`, không movement | Phiếu từ SL-002 | Pass: `READY` và movement = 0. Fail: đã `COMMITTED`, hoặc người lập bị đưa sang SCR-011 |
| Từ chối | Người duyệt | UI → RPC | G: phiếu chờ / W: từ chối kèm lý do / T: phiếu `REJECTED`, không movement | Phiếu pending khác | Pass: có lý do và effect none. Fail: từ chối không lý do vẫn ghi |
| Tự duyệt | Người lập | UI → RPC | G: người lập mở đúng case của mình / W: Duyệt / T: `SELF_APPROVAL_NOT_ALLOWED`, phiếu vẫn chờ | Cùng user lập và duyệt | Pass: status không đổi. Fail: phiếu sang `READY` |
| Quyết định thứ hai | Người duyệt khác | RPC | G: đã duyệt / W: từ chối sau đó / T: giữ duyệt đầu | Case đã decided | Pass: vẫn `READY`. Fail: bị ghi đè thành `REJECTED` |

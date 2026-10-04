# Work Slice: SL-004 — Ghi nhận tồn vật lý

```yaml
id: SL-004
journey:
  - BJ-02
usecase:
  - UC-02-04
sources:
  - BC-IO-02
  - EVT-IO-01
  - JA-03
  - SCR-012
  - UIF-02
theme: theme-07
```

**design_status** trên [`CATALOG.md`](CATALOG.md). Field và RPC lấy từ SRS. [BC-IO-02](../../02.specification/behavior/behavioral-contracts/BC-IO-02.md) §7 ghi `COMPLETED`. Slice dùng `COMMITTED` theo BJ-02 và [CONTEXT](../../../../../modules/inventory/CONTEXT.md).

---

## Objective

Hệ thống commit quick receipt đã `READY` vào tồn vật lý đúng một lần, và thủ kho thấy kết quả mà không có nút ghi nhận thêm.

---

## Blocked by

- [SL-003](SL-003-receipt-approval.md) — trong harness này phiếu chỉ tới `READY` sau khi duyệt nhập nhanh

---

## Scope & Rules

### In Scope

- Hệ thống thực thi `ReceivePurchasedGoods` khi phiếu đang `READY`. Không có command từ CTA người dùng
- Kết quả `COMMITTED`, `REJECTED` hoặc `UNKNOWN`
- Khi `COMMITTED`: quantity movement, balance, lot, `VALUATION_PENDING`, result và outbox fact `EVT-IO-01` đúng một lần
- SCR-012 đọc kết quả. Không render `ACT-02-RECEIVE` thành nút
- Scenario commit, guard fail, replay, và UI không mời commit lại

### Out of Scope

- Value movement và BJ-03
- Sửa chứng từ mua / Theme 10
- Phục hồi ngắn và BJ-17 — [SL-005](SL-005-receipt-finality.md)
- SCR-013 — [SL-005](SL-005-receipt-finality.md)
- Entry từ menu để commit lại

### Boundary

| Concern | Owner |
| --- | --- |
| Commit movement, balance, lot, fact | Hệ thống, `ReceivePurchasedGoods` |
| Phiếu `READY` | [SL-003](SL-003-receipt-approval.md) |
| Màn kết quả | `apps/erp`, SCR-012. UI chỉ đọc |

### Rules

| ID | Quy tắc (slice) |
| --- | --- |
| [UC-02-04](../../02.specification/behavior/use-cases/UC-02-04-ghi-nhan-hang-vao-ton-vat-ly.md) | Execution owner là hệ thống. Không CTA commit thêm |
| [UC-02-04 BR-02](../../02.specification/behavior/use-cases/UC-02-04-ghi-nhan-hang-vao-ton-vat-ly.md) | Hàng từ chối không tạo movement |
| [UC-02-04 BR-03](../../02.specification/behavior/use-cases/UC-02-04-ghi-nhan-hang-vao-ton-vat-ly.md) | Cách ly và hỏng tăng tồn đúng trạng thái vật lý |
| [UC-02-04 BR-06](../../02.specification/behavior/use-cases/UC-02-04-ghi-nhan-hang-vao-ton-vat-ly.md) | Movement, balance, lot, result và outbox cùng commit hoặc không có gì |
| [BC-IO-02](../../02.specification/behavior/behavioral-contracts/BC-IO-02.md) | Quick đã được duyệt trước commit. Không value movement |
| [JA-03](../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md) | Chỉ `COMMITTED` mới phát `EVT-IO-01` và chỉ quantity đã commit sang BJ-03 |

### Open Questions

- Contract chi tiết của outcome này (API, event, transaction, lỗi) trước đây nằm ở FND-TECH-01 và chưa được ghi trong slice. Điền khi review để implement. Quy tắc nền tảng (idempotency, outbox) dẫn từ docs/architecture; slice chỉ ghi cách outcome này áp dụng.

- Cách hệ thống nhận lệnh sau `READY` (cùng transaction với quyết định duyệt, hay internal command ngay sau đó) chưa được UC khóa. UI không gửi command này.
- DTO dòng kết quả (Product, UOM, phân loại, lot code, expiry) cho SCR-012 chưa có fence.
- quick receipt không có `source_line_id`. Payload `EVT-IO-01` vẫn liệt kê `source_line_id`. Cách điền lineage khi không có chứng từ nguồn chưa được khóa.
- Tên RPC và `p_*` của `API-C-02` / `API-Q-04` chưa có trong nguồn declarative.
- Tên bảng movement, balance, lot chưa có trong nguồn declarative.

---

## Flow

### Main Flow

1. Phiếu nhận nhanh đang `READY`.
2. Hệ thống gọi `ReceivePurchasedGoods`. UI không gửi command này.
3. Một transaction ghi quantity movement, balance, lot, `VALUATION_PENDING` và fact `EVT-IO-01`.
4. Thủ kho thấy SCR-012 với kết quả. Không có nút ghi nhận.

### Failure Flow

1. Guard fail trước effect → rollback → phiếu `REJECTED`, `effectStatus: NONE`, không movement, không outbox goods receipt.
2. Chưa chứng minh commit hay rollback → `UNKNOWN`, không chạy như operation mới, không movement thứ hai khi gọi lại cùng key.
3. Cùng key và cùng hash → snapshot trước, không movement thứ hai. Hash khác → `IDEMPOTENCY_CONFLICT`.

---

## Design

### Domain

**Before:** phiếu `READY`, chưa movement.
**After:** `COMMITTED` với movement đúng trạng thái và `VALUATION_PENDING`, hoặc `REJECTED` / `UNKNOWN` không effect bán phần.

Map trạng thái phiếu sang SCR-012:

| Phiếu | State màn hình |
| --- | --- |
| Đang ghi | `PROCESSING` |
| `COMMITTED` và `VALUATION_PENDING` | `VALUATION_PENDING_RESULT` |
| `REJECTED` | `REJECTED_EXECUTION` |
| `UNKNOWN` | `UNKNOWN` |

SCR-012 còn tên `COMPLETED` và `COMMIT_UNKNOWN`. [CONTEXT](../../../../../modules/inventory/CONTEXT.md) không dùng hai tên đó cho phiếu. Slice hiển thị theo bảng trên. SCR-012 §6 liệt kê `ACT-02-RECEIVE`. Slice không render action đó thành nút.

### Persistence

Tên bảng chưa đặt. Draft lúc implement: `supabase/migrations/_drafts/inventory_receive_purchased_goods.sql`.

| RPC | Params `p_*` | Returns |
| --- | --- | --- |
| Chưa chốt. FND: `API-C-02` nhận hàng. `API-Q-04` đọc kết quả | Chưa có trong nguồn | `GoodsReceiptResultDto` |

| Code | Khi nào | Hệ quả |
| --- | --- | --- |
| `SOURCE_VERSION_STALE` | Version phiếu hoặc snapshot không còn hiện hành | `REJECTED`, effect none |
| `LOT_REQUIRED` | Product LOT thiếu lot code | `REJECTED`, effect none |
| `LOT_ATTRIBUTE_CONFLICT` | Thuộc tính lô xung đột | `REJECTED`, effect none |
| `EXPIRY_REQUIRED` | Policy bắt buộc hạn dùng nhưng thiếu | `REJECTED`, effect none |
| `OWNERSHIP_ASSERTION_REQUIRED` | Thiếu xác nhận quyền sở hữu | `REJECTED`, effect none |
| `PRODUCT_DISCONTINUED_FOR_RECEIPT` | Product ngừng nhận | `REJECTED`, effect none |
| `PRODUCT_ARCHIVED` | Product đã lưu trữ | `REJECTED`, effect none |
| `IDEMPOTENCY_CONFLICT` | Cùng key, hash khác | Không movement thứ hai |

### Transaction / Idempotency

Khi commit thành công, một transaction: recheck phiếu `READY`, version, LOT, phân loại; quantity movement (hàng từ chối không có movement); balance và lot; đánh dấu `VALUATION_PENDING`; idempotency record; outbox `inventory.receipt.recorded.v1`. Không value movement.

- `idempotencyKey` ≠ `command.id`
- Unique `(tenant_id, command_scope, idempotency_key)` trong cùng transaction với movement và outbox
- Cùng key và cùng hash → snapshot trước
- Guard fail thì rollback toàn bộ và phiếu `REJECTED`

### Code Layout

```text
modules/
    inventory/
        application/
            lib/
                src/
                    goods_receipt/
                        commands/
                            receive_purchased_goods/
                                receive_purchased_goods_command.dart
                                receive_purchased_goods_handler.dart
                        queries/
                            get_goods_receipt_result/
                                get_goods_receipt_result_query.dart
                                get_goods_receipt_result_handler.dart
                        shared/
                            goods_receipt_result_dto.dart
                        testing/
                            fake_receive_purchased_goods_port.dart
        infrastructure/
            lib/
                src/
                    goods_receipt/
                        receive_purchased_goods_gateway.dart
        integration_events/
            lib/
                src/
                    inventory_receipt_recorded_v1.dart
apps/
    erp/
        lib/
            features/
                inventory/
                    receipt/
                        presentation/
                            receipt_result_page.dart
```

---

## Contracts

Handler: `ReceivePurchasedGoods` (`API-C-02`). Đọc kết quả: `API-Q-04`. UI không gửi command commit.

### ReceivePurchasedGoodsCommand

> Hệ thống gọi khi quick receipt đang `READY`. Outcome: `COMMITTED`, `REJECTED` hoặc `UNKNOWN`. `COMMITTED` ghi movement và fact đúng một lần. Cùng `idempotencyKey` không tạo movement thứ hai.

```dart
class ReceivePurchasedGoodsCommand {
  final String idempotencyKey; // ≠ command.id
  final String receiptId;
  final int expectedVersion;
}
```

### GetGoodsReceiptResultQuery

> Đọc khi SCR-012 cần kết quả authoritative của phiếu vừa thực thi.

```dart
class GetGoodsReceiptResultQuery {
  final String receiptId;
}
```

### GoodsReceiptResultDto

```dart
class GoodsReceiptResultDto {
  final String receiptId;
  final String status; // COMMITTED | REJECTED | UNKNOWN
  final String effectStatus; // COMMITTED | NONE | UNKNOWN
  final bool valuationPending;
  final bool replayed;
}
```

`valuationPending` chỉ `true` khi `status` là `COMMITTED`.

`IReceivePurchasedGoodsPort.receive` → `GoodsReceiptResultDto`.
`IReceivePurchasedGoodsPort.getResult` → `GoodsReceiptResultDto`.
`FakeReceivePurchasedGoodsPort`: commit một lần. Replay cùng key trả kết quả trước và `replayed: true`. Guard fail trả `REJECTED` với `effectStatus: NONE`. Không ghi value movement.

### Integration

- Fact khi `COMMITTED`: `EVT-IO-01` / `inventory.receipt.recorded.v1`. Payload tối thiểu: `operation_id`, `receipt_id`, `source_identity`, `source_version`, `warehouse_id`, `receipt_business_date`, `lines[]`, `valuation_pending=true`. Không field giá chính thức.
- `REJECTED` và `UNKNOWN` không phát `EVT-IO-01` và không kích hoạt BJ-03.
- Fact này không phải command yêu cầu Theme 10 sửa chứng từ mua.

---

## Presentation

### Screens

| Screen | State / action | Nguồn |
| --- | --- | --- |
| SCR-012 | Kết quả theo dòng. Không CTA «Ghi nhận hàng» | [SCR-012](../../03.design/screens/SCR-012.md) §3 |

### Route

- Hệ thống đưa tới SCR-012 sau khi phiếu `READY` được thực thi ([UIF-02](../../03.design/flows/UIF-02-BJ-02.md) `UIF-02-T15`)
- `UNKNOWN` rời SCR-012 sang SCR-013 thuộc [SL-005](SL-005-receipt-finality.md)
- Không entry từ menu để commit lại

### State × feedback

| State | UI / feedback | Error code |
| --- | --- | --- |
| loading | Đang ghi nhận. Không nút thử lại bằng phiếu mới | — |
| empty | Màn kết quả của một phiếu. Nguồn không mô tả danh sách trống | — |
| error | Kết quả từ chối, không nói là lỗi mạng, không tồn tăng | `REJECTED` |
| success | Icon success. Banner chờ xác nhận giá chỉ ở `VALUATION_PENDING_RESULT`. Đạt chưa thành hàng có thể bán. Cách ly và hỏng giữ trạng thái riêng | — |
| unknown | Không nói thành công. Giữ cùng phiếu. Đi SCR-013 | — |
| permission | Không được xem kết quả | `PERMISSION_DENIED` |

### Design system

- `VIcons.success` cho kết quả commit
- `VBanner.info` cho chờ xác nhận giá
- `VCard` tóm tắt dòng, có lot code khi có lô
- Không toast thành công trùng với màn kết quả

### Mediator

- UI chỉ gọi `GetGoodsReceiptResultQuery` qua `IModuleMediator`
- UI không gửi `ReceivePurchasedGoodsCommand`
- Fake khớp Contracts của slice này
- Presentation thuộc `apps/erp`

---

## Verification

### Acceptance Criteria

- [ ] **AC-01** Given phiếu `READY` đã duyệt, When hệ thống thực thi, Then `COMMITTED` một lần, `valuationPending: true`, movement đúng trạng thái, một `EVT-IO-01`, không value movement
- [ ] **AC-02** Given guard fail trước effect, When thực thi, Then `REJECTED`, `effectStatus: NONE`, không movement bán phần
- [ ] **AC-03** Given mất bằng chứng commit, When gọi lại cùng key, Then `UNKNOWN` và không movement thứ hai
- [ ] **AC-04** Given SCR-012, When kết quả là `COMMITTED`, `REJECTED`, hoặc `UNKNOWN`, Then không có nút ghi nhận. `REJECTED` và `UNKNOWN` không hiện như thành công

### Tests

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_commit_once` | Phiếu READY / receive / `COMMITTED`, replay không effect mới | application fake |
| `scn_reject_before_effect` | Guard fail / receive / `REJECTED`, effect NONE | application fake |
| `scn_unknown` | Không chứng minh commit / receive / `UNKNOWN`, cùng receiptId | application fake |
| `scn_commit_rpc` | Phiếu READY đã duyệt / receive / một movement set và một outbox | application / RPC |
| `scn_committed_ui` | Result COMMITTED, valuation pending / mở SCR-012 / banner chờ giá, không CTA commit | widget |
| `scn_unknown_ui` | Result UNKNOWN / mở SCR-012 / không icon success | widget |

### Scenarios

| Scenario | Actor | Across | Given / When / Then | Seed / fixture | Pass / fail |
| --- | --- | --- | --- | --- | --- |
| Commit | Hệ thống. Thủ kho chỉ xem | RPC → DB → UI | G: phiếu quick `READY` / W: hệ thống thực thi / T: `COMMITTED`, movement đúng trạng thái, `VALUATION_PENDING`, một `EVT-IO-01`, SCR-012 không có nút ghi nhận | Phiếu đã duyệt ở SL-003 | Pass: một bộ movement và một outbox, không value movement. Fail: có nút commit hoặc hai movement |
| Từ chối lúc ghi | Hệ thống | RPC → DB | G: phiếu READY nhưng LOT bắt buộc đang thiếu / W: thực thi / T: `REJECTED`, không movement | Phiếu READY cố tình thiếu lot | Pass: effect none. Fail: còn movement bán phần |
| Replay | Hệ thống | RPC | G: đã `COMMITTED` / W: gọi lại cùng `idempotencyKey` / T: snapshot trước, không movement mới | Key của lần commit | Pass: outbox vẫn một sự kiện. Fail: sự kiện thứ hai |
| Chưa rõ | Hệ thống và UI | RPC → UI | G: không chứng minh được commit / W: trả kết quả / T: SCR-012 là `UNKNOWN`, không icon thành công | Cô lập mất bằng chứng commit | Pass: không movement mới. Fail: UI báo đã vào tồn |

# Work Slice: SL-005 — Tra cứu finality goods receipt

```yaml
id: SL-005
journey:
  - BJ-02
usecase:
  - UC-02-05
sources:
  - JA-05
  - API-Q-04
  - SCR-013
  - SCR-012
  - UIF-02
  - BC-IO-02
theme: theme-07
```

**design_status** trên [`CATALOG.md`](CATALOG.md). Field và RPC lấy từ SRS. Query không tạo idempotency record.

---

## Objective

Tra cứu đúng goods receipt đã gửi trả finality đã có, hoặc bàn giao BJ-17, và không tạo lần nhận mới.

---

## Blocked by

- [SL-004](SL-004-physical-receipt.md) — cần `receiptId` và kết quả `COMMITTED` / `REJECTED` / `UNKNOWN`

---

## Scope & Rules

### In Scope

- Tra cứu cùng identity phiếu đã thực thi
- Trả result đã commit, rejection với effect none, hoặc vẫn `UNKNOWN`
- Khi hết cửa sổ phục hồi ngắn mà vẫn `UNKNOWN`: cờ bàn giao BJ-17 cùng identity
- SCR-013 mở từ SCR-012 khi finality chưa rõ. Finality đã có thì về SCR-012
- Nối nhánh `UNKNOWN` trên `receipt_result_page.dart`

### Out of Scope

- Tạo goods receipt, movement, balance hoặc outbox mới
- Retry bằng identity mới hoặc payload khác
- Thực thi BJ-17 và màn hình BJ-17
- Nhận theo chứng từ
- Fact outbox và integration command. `handoffBj17` là cờ trên DTO

### Boundary

| Concern | Owner |
| --- | --- |
| Đọc result và idempotency record | Query `QueryReceiptFinality`. Bản ghi do [SL-004](SL-004-physical-receipt.md) ghi |
| SCR-013 | `apps/erp` |
| BJ-17 | Ngoài slice này |

### Rules

| ID | Quy tắc (slice) |
| --- | --- |
| [UC-02-05 BR-01](../../02.specification/behavior/use-cases/UC-02-05-truy-van-va-phuc-hoi-ngan-ket-qua-nhan-hang.md) | Dùng cùng operation / idempotency identity |
| [UC-02-05 BR-02](../../02.specification/behavior/use-cases/UC-02-05-truy-van-va-phuc-hoi-ngan-ket-qua-nhan-hang.md) | Query không tạo lại goods receipt, movement, balance hoặc outbox |
| [UC-02-05 BR-03](../../02.specification/behavior/use-cases/UC-02-05-truy-van-va-phuc-hoi-ngan-ket-qua-nhan-hang.md) | Chưa đủ bằng chứng thì giữ `UNKNOWN` |
| [UC-02-05 BR-04](../../02.specification/behavior/use-cases/UC-02-05-truy-van-va-phuc-hoi-ngan-ket-qua-nhan-hang.md) | Cùng identity nhưng payload khác là conflict |
| [JA-05](../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md) | `UNKNOWN` sau phục hồi ngắn không kích hoạt BJ-03 và không phát sinh goods receipt mới |

### Open Questions

- Contract chi tiết của outcome này (API, event, transaction, lỗi) trước đây nằm ở FND-TECH-01 và chưa được ghi trong slice. Điền khi review để implement. Quy tắc nền tảng (idempotency, outbox) dẫn từ docs/architecture; slice chỉ ghi cách outcome này áp dụng.

- UC-02-05 nói `operation_id` / command identity. Slice đang khóa query bằng `receiptId` của GoodsReceipt. Cần review xác nhận hai id này là một identity với client, hay phải trả cả hai.
- Độ dài «cửa sổ phục hồi ngắn» chưa có số trong UC-02-05.
- Shape evidence refs đưa sang BJ-17 chưa có field list.
- Tên `p_*` của `API-Q-04` chưa có. Mã lỗi tenant-mismatch chưa được UC đặt tên.

---

## Flow

### Main Flow

1. SCR-012 đang `UNKNOWN` thì mở SCR-013 của cùng phiếu (`UIF-02-T17`).
2. Client gọi `QueryReceiptFinalityQuery` với cùng identity. Query không ghi.
3. Đã có finality thì về SCR-012 (`UIF-02-T18`).
4. Hết cửa sổ mà vẫn `UNKNOWN` thì UI nói chuyển BJ-17 (`UIF-02-T19`). Không gọi là thất bại và không phát `EVT-IO-01`.

### Failure Flow

1. Cùng identity, payload hash khác → `IDEMPOTENCY_CONFLICT` → không suy finality, không phiếu mới.
2. `receiptId` ngoài tenant → từ chối query, không tạo phiếu.

---

## Design

### Domain

**Before:** client có identity phiếu nhưng chưa thấy finality.
**After:** cùng result đã persist, hoặc cờ `handoffBj17` khi hết cửa sổ. Số movement và outbox không tăng.

### Persistence

Không tạo bảng mới. Query không mở transaction ghi movement, balance, lot hay outbox.

| RPC | Params `p_*` | Returns |
| --- | --- | --- |
| Chưa chốt. FND: `API-Q-04` đọc trạng thái operation | `receiptId`, `idempotencyKey`, `payloadHash` theo Contracts. Tên `p_*` chưa có | `ReceiptFinalityDto` |

| Code | Khi nào | Hệ quả |
| --- | --- | --- |
| `IDEMPOTENCY_CONFLICT` | Cùng identity, payload hash khác | Không suy finality, không phiếu mới |

So khớp `payloadHash` với identity đã bind. Không dùng `command.id` làm khóa tra cứu. Không ghi bản idempotency mới.

### Code Layout

```text
modules/
    inventory/
        application/
            lib/
                src/
                    goods_receipt/
                        queries/
                            query_receipt_finality/
                                query_receipt_finality_query.dart
                                query_receipt_finality_handler.dart
                        shared/
                            receipt_finality_dto.dart
                        testing/
                            fake_receipt_finality_port.dart
        infrastructure/
            lib/
                src/
                    goods_receipt/
                        receipt_finality_gateway.dart
apps/
    erp/
        lib/
            features/
                inventory/
                    receipt/
                        presentation/
                            receipt_recovery_page.dart
                            receipt_result_page.dart
```

`receipt_result_page.dart` do SL-004 tạo. Slice này nối nhánh `UNKNOWN`.

---

## Contracts

Đọc theo `API-Q-04`.

### QueryReceiptFinalityQuery

> Đọc khi client đã có identity goods receipt nhưng chưa có finality. Outcome: `COMMITTED`, `REJECTED`, hoặc `UNKNOWN`. Không tạo effect mới.

```dart
class QueryReceiptFinalityQuery {
  final String receiptId;
  final String idempotencyKey;
  final String payloadHash;
}
```

### ReceiptFinalityDto

```dart
class ReceiptFinalityDto {
  final String receiptId;
  final String status; // COMMITTED | REJECTED | UNKNOWN
  final String effectStatus; // COMMITTED | NONE | UNKNOWN
  final bool handoffBj17;
}
```

`handoffBj17` chỉ `true` khi hết cửa sổ phục hồi ngắn và status vẫn `UNKNOWN`.

`IReceiptFinalityPort.query` → `ReceiptFinalityDto`.
`FakeReceiptFinalityPort`: cùng identity trả result đã có. Payload hash khác → conflict và không tạo phiếu. Không ghi movement.

---

## Presentation

### Screens

| Screen | State / action | Nguồn |
| --- | --- | --- |
| SCR-012 | State `UNKNOWN` dẫn sang SCR-013. Không nút nhận lại | [UIF-02](../../03.design/flows/UIF-02-BJ-02.md) `UIF-02-T17` |
| SCR-013 | Timeline kết quả cùng phiếu. Không mutation | [SCR-013](../../03.design/screens/SCR-013.md) |

SCR-013 chỉ mở từ SCR-012 khi finality chưa rõ. Không có trong menu.

### Route

- `UIF-02-T17` SCR-012 → SCR-013
- `UIF-02-T18` finality đã có → SCR-012
- `UIF-02-T19` hết cửa sổ, vẫn chưa rõ → BJ-17

### State × feedback

| State | UI / feedback | Error code |
| --- | --- | --- |
| loading | Một trạng thái đang kiểm tra. Không thêm banner cảnh báo chồng lên | — |
| empty | `VEmptyState` khi không có evidence để xem | — |
| error | Payload không khớp: không đoán kết quả | `IDEMPOTENCY_CONFLICT` |
| success | Quay SCR-012 với kết quả đã commit | — |
| rejected | Quay SCR-012 với từ chối, effect none | — |
| unknown | Giữ cùng mã lần nhận. Không nút tạo phiếu mới | — |
| handoff | Hết cửa sổ: nói rõ chuyển sang phục hồi BJ-17, không gọi là thất bại | — |

### Design system

- `VPageScaffold`, `VEmptyState`, `VBanner`
- Không hiện polling, outbox, movement id
- Được hiện một mã lần nhận để tra cứu

### Mediator

- `QueryReceiptFinalityQuery` qua `IModuleMediator`
- Fake khớp Contracts của slice này
- Không gửi command nhận hàng
- Presentation thuộc `apps/erp`

---

## Verification

### Acceptance Criteria

- [ ] **AC-01** Given phiếu đã `COMMITTED` và client không nhận response, When tra cứu cùng identity, Then đúng result và movement cùng outbox không tăng
- [ ] **AC-02** Given phiếu `REJECTED` trước effect, When tra cứu, Then effect none và không gợi ý nhận lại trên cùng phiếu
- [ ] **AC-03** Given payload hash lệch identity đã bind, When query, Then conflict, không suy ra finality và không tạo phiếu mới
- [ ] **AC-04** Given hết cửa sổ mà vẫn `UNKNOWN`, When đối soát, Then `handoffBj17: true`, không `EVT-IO-01`, không phát fact goods receipt
- [ ] **AC-05** Given SCR-012 đang `UNKNOWN`, When mở đối soát, Then SCR-013 cùng phiếu và không có nút nhận mới

### Tests

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_committed_replay` | Result đã commit / query cùng identity / cùng result, không movement mới | application fake |
| `scn_payload_conflict` | Hash khác identity đã bind / query / conflict, không phiếu mới | application fake |
| `scn_handoff` | Hết cửa sổ, vẫn UNKNOWN / query / `handoffBj17: true` | application fake |
| `scn_read_committed` | Result COMMITTED / query / số outbox không tăng | application / RPC |
| `scn_open_recovery` | Result UNKNOWN / ở SCR-012 / sang SCR-013 cùng receiptId | widget |
| `scn_resolved_ui` | Query trả COMMITTED / đối soát / về SCR-012 kết quả | widget |
| `scn_handoff_ui` | handoffBj17 / đối soát / thông báo BJ-17, không phiếu mới | widget |

### Scenarios

| Scenario | Actor | Across | Given / When / Then | Seed / fixture | Pass / fail |
| --- | --- | --- | --- | --- | --- |
| Mất response sau commit | Thủ kho | UI → query → DB | G: phiếu đã `COMMITTED` nhưng client không nhận response / W: mở đối soát cùng phiếu / T: SCR-012 hiện kết quả cũ, movement và outbox không tăng | Phiếu commit ở SL-004 | Pass: cùng result. Fail: có movement mới |
| Đã từ chối | Thủ kho | Query → UI | G: phiếu `REJECTED` trước effect / W: tra cứu / T: effect none | Phiếu rejected ở SL-004 | Pass: không gợi ý nhận lại trên cùng phiếu. Fail: tạo phiếu mới |
| Hết cửa sổ | Thủ kho | Query → UI | G: vẫn `UNKNOWN` sau cửa sổ phục hồi ngắn / W: đối soát / T: bàn giao BJ-17 cùng identity, không BJ-03 | Phiếu UNKNOWN | Pass: `handoffBj17` và không `EVT-IO-01`. Fail: báo thành công |
| Sai payload | Adapter | Query | G: identity đã bind / W: query với hash khác / T: conflict, không phiếu mới | Hash lệch | Pass: từ chối query. Fail: suy ra `COMMITTED` |

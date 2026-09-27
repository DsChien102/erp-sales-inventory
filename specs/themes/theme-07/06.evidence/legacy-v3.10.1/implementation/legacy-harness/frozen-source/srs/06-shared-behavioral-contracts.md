# 06 — Hợp đồng hành vi dùng chung

## 1. Vai trò của phần này

File này là **registry và định nghĩa dùng chung**. Mỗi Use Case tại phần 05 liên kết trực tiếp tới BC áp dụng; Business Journey không lặp lại hợp đồng chi tiết. Mỗi BC có đúng một authoritative handler; REST, batch, UI hay event chỉ là adapter.

Phần 07 không lặp lại nghĩa nghiệp vụ. Nó chỉ ánh xạ BC tới handler, endpoint/event, transaction boundary, permission, error và test.

## 2. Envelope và quy tắc chung

<a id="sbc-com-01"></a>
### 2.1 SBC-COM-01 — Bao yêu cầu và định danh

Mọi command mutation có tối thiểu:

`tenant_id`, `store_id`, `warehouse_id`, `actor_id`, `idempotency_key`, `source_type`, `source_document_id`, `source_line_id?`, `source_version`, `business_date`, `expected_entity_version?`, `payload` và `correlation_id`.

Server tự điền store/warehouse mặc định cho UI Phase 1 nhưng vẫn validate và persist. API không chấp nhận một cặp khác.

<a id="sbc-com-02"></a>
### 2.2 SBC-COM-02 — Quyền, phạm vi và điều kiện cần

- Functional permission + warehouse scope tại thời điểm hành động.
- Tenant/store/warehouse hoạt động và đúng cặp mặc định.
- Tenant inventory activation phải là `ACTIVE`; khi còn `PREPARING`, mọi mutation thường trả `INVENTORY_NOT_ACTIVATED`, trừ prepare/commit opening balance và các query được phép.
- Source version không cũ hơn version đã ghi nhận.
- Cùng `command_type + idempotency_key` phải có cùng payload hash và một `CommandReceipt`; `operation_request_id` là identity nghiệp vụ riêng, không bị thay bằng command identity.
- Không có Inventory Lock xung đột.
- Entity version khớp khi command sửa aggregate mutable.
- Operation ở trạng thái cho phép; payload khóa sau `DRAFT`.

<a id="sbc-com-03"></a>
### 2.3 SBC-COM-03 — Kết quả và hướng phục hồi

Result gồm `operation_id?`, `status`, `result_code`, `entity_version?`, `committed_at?`, `ledger_sequence?`, `event_id?`, `warnings[]`, `correlation_id` và `recovery_guidance`.

`recovery_guidance` là dữ liệu trình bày dẫn xuất, gồm:

- `effect_status`: `NONE`, `COMMITTED` hoặc `UNKNOWN`;
- `user_message_key`: khóa thông điệp tiếng Việt nghiệp vụ, không thay thế `result_code` ổn định;
- `allowed_next_actions[]`: chỉ tham chiếu query/command và Screen Action đã có, đã lọc theo quyền/trạng thái;
- `preserve_input`: cho biết client có giữ dữ liệu nhập khi quay lại hay không.

Metadata này không phải nguồn finality, không tạo transition hoặc mutation. Nếu metadata mâu thuẫn với `status/result_code`, trạng thái và bằng chứng authoritative thắng; lỗi hợp đồng phải được ghi nhận.

Mọi BC mutation — không chỉ create/update/submit — phải persist hoặc hoàn tất `CommandReceipt` trong cùng transaction với kết quả authoritative của command.

<a id="sbc-com-04"></a>
### 2.4 SBC-COM-04 — Finality và tính nguyên tử

Khi một BC mutation hoàn tất, operation result, movement/value movement, balance, lot/state effect và outbox liên quan commit cùng transaction. Lỗi một phần rollback toàn bộ. Event delivery xảy ra sau commit và không quyết định finality.

Vì là yêu cầu cắt ngang, mọi dòng `Entity` của BC mutation mặc nhiên bao gồm ghi/hoàn tất `ENT-IO-10 CommandReceipt`, dù bảng chi tiết chỉ liệt kê các aggregate nghiệp vụ chính.

<a id="sbc-com-05"></a>
### 2.5 SBC-COM-05 — Quyền và phê duyệt

- Policy được chọn theo loại operation, lý do và mức rủi ro; policy/version được chụp khi gửi.
- `risk_value_vnd = Σ_i |base_quantity_i × price_basis_i × source_fx_to_vnd_i|`; không bù trừ dòng tăng với dòng giảm. Căn cứ mỗi dòng ưu tiên official cost có hiệu lực, nếu chưa có thì dùng giá thực tế có phiên bản từ nguồn.
- Thiếu căn cứ giá/tỷ giá của bất kỳ dòng nào: operation giữ `DRAFT`, trả `APPROVAL_PRICE_BASIS_REQUIRED`; không tự đẩy lên cấp cao nhất và không dùng giá trị `UNKNOWN`.
- Snapshot lưu quantity, price source/version, source currency, FX source/version, VND line amount, tổng risk value và đúng một `required_approval_level`.
- Khi gửi phải tồn tại ít nhất một người đang có quyền, phạm vi kho và level phù hợp; nếu không, giữ `DRAFT` và trả `APPROVER_CONFIGURATION_MISSING`.
- Người đáp ứng level được suy ra có thể quyết định trực tiếp. Không đi tuần tự qua các cấp thấp hơn. Phê duyệt chỉ đưa operation sang `READY`, không giữ hoặc thay đổi tồn; lúc thực thi mọi điều kiện hiện hành được kiểm lại.

<a id="sbc-com-06"></a>
### 2.6 SBC-COM-06 — Vòng đời sản phẩm

| Trạng thái/thuộc tính | Hành vi bắt buộc |
|---|---|
| `ACTIVE` | Cho phép mutation theo các guard còn lại. |
| `DISCONTINUED` | Chặn cam kết mua và receipt mới; chỉ cho receipt tiếp tục khi có source continuation assertion/version được chụp trước mốc ngừng. Vẫn cho bán hết, return, RTV, correction và disposal. |
| `ARCHIVED` | Chặn mọi mutation mới; chỉ cho query lịch sử có quyền. |
| Base UOM sau movement | Bất biến; trả `BASE_UOM_IMMUTABLE`, chỉ sản phẩm mới hoặc migration có kiểm soát được phép thay đổi. |

## 3. Catalog

| BC ID | Tên | Loại | Owner | Journey chính |
|---|---|---|---|---|
| `BC-IO-01` | Query inventory availability | Query | IO | `BJ-01` |
| `BC-IO-02` | Receive purchased goods | Command | IO | `BJ-02` |
| `BC-IV-01` | Confirm direct receipt cost and release | Command | IV + IO | `BJ-03` |
| `BC-IO-03` | Reserve order quantity | Command | IO | `BJ-04` |
| `BC-IO-04` | Complete online POS checkout | Command | IO + IV | `BJ-05 / UC-05-05` provider; `XREF-01` consumer |
| `BC-IO-05` | Pick and hand over fulfillment | Command | IO + IV | `BJ-05` |
| `BC-IO-06` | Release or reallocate reservation | Command | IO | `BJ-04` |
| `BC-IO-07` | Receive customer return | Command | IO | `BJ-06` |
| `BC-IO-08` | Classify returned goods | Command | IO | `BJ-06` |
| `BC-IO-09` | Return goods to supplier | Command | IO + IV | `BJ-07` |
| `BC-IC-01` | Open stock count | Command | IC | `BJ-08` |
| `BC-IC-02` | Submit count or recount | Command | IC | `BJ-08` |
| `BC-IC-03` | Approve variance and adjust | Command | IC + IO + IV | `BJ-08` |
| `BC-IO-10` | Change inventory state | Command | IO | `BJ-09` |
| `BC-IO-11` | Dispose inventory | Command | IO + IV | `BJ-09` |
| `BC-IO-12` | Cancel pending operation | Command | IO | `BJ-11` |
| `BC-IO-13` | Reverse or correct completed operation | Command | IO + IV | `BJ-11` |
| `BC-IC-04` | Commit opening balance | Command | IC + IO + IV | `BJ-12` |
| `BC-IV-02` | Calculate inventory cost | Command | IV | `BJ-14` |
| `BC-IV-03` | Publish valuation and official cost | Command | IV | `BJ-14` |
| `BC-IO-14` | Query low stock suggestions | Query | IO | `BJ-01` |
| `BC-IC-05` | Reconcile and rebuild projection | Command | IC | `BJ-16`, `PROC-01` |
| `BC-IC-06` | Decide approval | Command | IC | Cross-cutting |
| `BC-XD-01` | Calculate purchase-discount scenario | Command | Purchase planning | `XREF-02 / Theme 10` |
| `BC-XD-02` | Publish pricing cost basis and draft | Command | Pricing | `XREF-03 / Theme 2` |
| `BC-XD-03` | Review pricing basis after cost publication | Command | Pricing | `XREF-04 / Theme 2` |
| `BC-XD-04` | Query margin comparison | Query | Reporting | `XREF-05 / Reporting` |
| `BC-IV-04` | Record late landed cost | Command | IV | `BJ-14` |
| `BC-IO-15` | Save pick allocation | Command | IO | `BJ-05` |
| `BC-IO-16` | Maintain operation draft | Command | IO | Cross-cutting |
| `BC-IC-07` | Submit inventory operation | Command | IC + IO | Cross-cutting |
| `BC-IC-08` | Cancel stock count | Command | IC | `BJ-08` |
| `BC-IC-09` | Prepare opening balance batch | Command | IC | `BJ-12` |
| `BC-XD-05` | Configure inventory product policy | Command | Product configuration | `CAP-01` |

## 4. Inventory Operations contracts

<a id="bc-io-01"></a>
### BC-IO-01 — Query inventory availability

| Mục | Hợp đồng |
|---|---|
| Ý định | Trả lượng vật lý, eligible, reserved, available, trạng thái và lô theo filter/cut-off. |
| Input | Product/filter, warehouse mặc định, `as_of?`, view mode và financial-field request. |
| Guard | View permission/scope; financial permission nếu yêu cầu giá. |
| Xử lý | Dùng transactional balance cho availability hiện hành; historical/report dùng projection có sequence. Eligibility của lô tính tại tenant business date. |
| Kết quả | Quantity breakdown, lot/expiry, as-of/sequence, stale indicator, drill-down IDs. |
| Lỗi | `FORBIDDEN_SCOPE`, `PRODUCT_NOT_FOUND`, `SNAPSHOT_NOT_AVAILABLE`. |
| Entity | Read `ENT-IO-03/04/06`, `PRJ-01/02/03`; không mutation. |
| Trace | `BJ-01`; `ST-01.01`, `ST-01.02`, `ST-01.03`, `ST-16.01`, `ST-16.02`; `SG-01`, `SG-11`; `API-Q-01`, `API-Q-05`, `API-Q-06`; `TST-BC-IO-01-*`. |

<a id="bc-io-02"></a>
### BC-IO-02 — Receive purchased goods

| Mục | Hợp đồng |
|---|---|
| Ý định | Ghi lượng đạt thực nhận và lô; mọi lượng đạt vào `VALUATION_PENDING`. |
| Input | Receipt source/version, ownership assertion, line quantities/UOM, accepted/rejected, tracking snapshot, lot data, direct price evidence optional. |
| Guard | Master/UOM/version hợp lệ; warehouse unlocked; ownership transferred; `NONE` không lot data; `LOT` có manufacturer lot và expiry nếu required; conflict lot attributes chặn. |
| Xử lý | Validate toàn operation → approval nếu vượt threshold → create/reuse lot → append receipt/state movement vào `VALUATION_PENDING` → update balance → lưu direct-price evidence chỉ làm staging cho BC-IV-01 → store discrepancy result/outbox. |
| Kết quả | `COMPLETED`; physical tăng, available không tăng; không value movement. Xác nhận direct cost luôn là command/transaction riêng. |
| Lỗi | `OWNERSHIP_ASSERTION_REQUIRED`, `LOT_REQUIRED`, `LOT_ATTRIBUTE_CONFLICT`, `EXPIRY_REQUIRED`, `SOURCE_VERSION_STALE`, `RECEIPT_EXCEEDS_TOLERANCE`, `PRODUCT_DISCONTINUED_FOR_RECEIPT`, `PRODUCT_ARCHIVED`. |
| Entity | Write `ENT-IO-01/02/03/04/06`; optional approval. |
| Trace | `BJ-02`; `ST-02.01`, `ST-02.02`, `ST-02.03`, `ST-02.04`, `ST-02.05`; `SG-02`; `API-C-02`; `EVT-IO-01`. |

<a id="bc-io-03"></a>
### BC-IO-03 — Reserve order quantity

| Mục | Hợp đồng |
|---|---|
| Ý định | Giữ lượng cho order line mà chưa giảm physical. |
| Input | Order line/version, product/components snapshot, requested base quantity, fulfillment mode (`ALL_OR_NOTHING`/`PARTIAL`), expiry optional. |
| Guard | Transactional availability; source current; product sellable; no lock; combo đủ mọi component cho số nguyên combo. |
| Xử lý | Lock ReservationBucket + candidate physical balance keys deterministic → calculate reservable → create/update Reservation → update bucket/available → outbox. Không chọn lot. |
| Kết quả | Full/partial reservation và shortage quantity; physical unchanged. |
| Lỗi | `INSUFFICIENT_AVAILABLE`, `SOURCE_VERSION_STALE`, `COMPONENT_SHORTAGE`, `BALANCE_CONFLICT`. |
| Entity | `ENT-IO-05`, `ENT-IO-08`, read `ENT-IO-04`; operation/result envelope as configured. |
| Trace | `BJ-04`; `ST-04.01`, `ST-04.02`, `ST-04.03`; `SG-04`; `API-C-03`; `EVT-IO-02`. |

<a id="bc-io-04"></a>
### BC-IO-04 — Complete online POS checkout

| Mục | Hợp đồng |
|---|---|
| Ý định | Hoàn tất bán tại quầy online, xuất lượng và ghi initial COGS nguyên tử. |
| Input | Checkout/version/request ID, product/component lines, sold quantity, price context from Sales, lot scan optional/required by mode. |
| Guard | Server reachable; enough current availability; valid lot/FEFO override; permission; official cost version exists or defined safe rule for new product. |
| Xử lý | Lock sorted keys → allocate lot FEFO/FIFO → append issue movements → update balance → append value issue with official cost snapshot → outbox. |
| Kết quả | Completed checkout inventory result, lot allocation, initial COGS references. |
| Lỗi | `INSUFFICIENT_AVAILABLE`, `LOT_NOT_ELIGIBLE`, `LOT_REQUIRED`, `COST_VERSION_MISSING`, `IDEMPOTENCY_PAYLOAD_MISMATCH`. |
| Entity | `ENT-IO-01/02/03/04/06`, `ENT-IV-02/04`. |
| Trace | `BJ-05 / UC-05-05` là provider authority; `XREF-01 / T5-BJ-CHECKOUT-POS` là consumer; UI active `SG-06`, UI outbound `SG-05`; `API-C-04`; `EVT-IO-03`. |

<a id="bc-io-05"></a>
### BC-IO-05 — Pick and hand over fulfillment

| Mục | Hợp đồng |
|---|---|
| Ý định | Gắn lô khi pick và giảm physical/consume reservation tại handover. |
| Input | Fulfillment/source version, reservation IDs, `allocation_set_id`, `allocation_version`, handover assertion/version. |
| Guard | Reservation active; đúng active allocation set/version; selected lot eligible and enough; override permission/reason; handover assertion valid; allocation chưa consume. |
| Xử lý | Handover khóa active allocation set/version → revalidate lot/quantity → consume reservation/bucket/allocation đúng một lần, append issue/value movement and update balance atomically. Việc lưu pick thuộc `BC-IO-15`. |
| Kết quả | Handover completed, lot allocation, reservation consumed, initial COGS. |
| Lỗi | `RESERVATION_NOT_ACTIVE`, `PICK_ALLOCATION_CONFLICT`, `PICK_ALLOCATION_ALREADY_CONSUMED`, `LOT_NOT_ELIGIBLE`, `HANDOVER_ASSERTION_REQUIRED`, `INSUFFICIENT_AT_EXECUTION`. |
| Entity | `ENT-IO-01…06`, `ENT-IO-08/09`, `ENT-IV-02/04`. |
| Trace | `BJ-05`; `ST-06.02`; `SG-06`; `API-C-05`; `EVT-IO-04`. |

<a id="bc-io-06"></a>
### BC-IO-06 — Release or reallocate reservation

| Mục | Hợp đồng |
|---|---|
| Ý định | Release do cancel/reduce/expiry hoặc tìm lượng eligible khác trong cùng warehouse. |
| Input | Reservation/source version, reason, new requested quantity or affected eligibility change. |
| Guard | Active reservation; source current; same warehouse only. |
| Xử lý | Lock reservation/bucket/balance → release delta hoặc recompute allocation eligibility → release/supersede pick allocation liên quan → update bucket/available → emit shortage/release result. |
| Kết quả | Released/reallocated/partially short; no physical movement. |
| Lỗi | `RESERVATION_NOT_ACTIVE`, `SOURCE_VERSION_STALE`, `WAREHOUSE_ROUTING_NOT_AVAILABLE`. |
| Entity | `ENT-IO-05/08/09`; read `ENT-IO-04` và lot eligibility. |
| Trace | `BJ-04`; `ST-07.01`, `ST-07.02`; `SG-04`; `API-C-06`; `EVT-IO-05`. |

<a id="bc-io-07"></a>
### BC-IO-07 — Receive customer return

| Mục | Hợp đồng |
|---|---|
| Ý định | Tăng physical ở `RETURN_PENDING` khi hàng thực quay về. |
| Input | Return request/version, original delivery line; với combo: component line/snapshot, actual quantity/UOM/lot/value basis từng thành phần; receipt evidence. |
| Guard | Cumulative return cap atomically trên từng original component issue; actual lot matches issued lots or approved exception; sum component quantities theo combo hợp lệ. |
| Xử lý | Lock all original component return aggregates theo thứ tự xác định → validate cap/lot/value từng component → append toàn bộ quantity movement `RETURN_PENDING` và value movement kỳ mở hiện tại → update cumulative returned/balance/outbox trong một transaction. |
| Kết quả | Physical/value tăng, available không tăng; return receipt/value linked to original issue và kỳ gốc. |
| Lỗi | `RETURN_LIMIT_EXCEEDED`, `ORIGINAL_ISSUE_NOT_FOUND`, `RETURN_LOT_MISMATCH`, `COMBO_COMPONENT_MISMATCH`, `RETURN_VALUE_BASIS_MISSING`. |
| Entity | `ENT-IO-01/02/03/04/06`, `ENT-IV-02`; return aggregate và original cost reference snapshot. |
| Trace | `BJ-06`; `ST-08.01`, `ST-08.02`, `ST-08.03`; `SG-07`; `API-C-07`; `EVT-IO-06`. |

<a id="bc-io-08"></a>
### BC-IO-08 — Classify returned goods

| Mục | Hợp đồng |
|---|---|
| Ý định | Chuyển lượng return pending sang sellable/quarantine/damaged/expired. |
| Input | Return receipt lines, classification quantities, reason/evidence. |
| Guard | Sum classification = pending quantity; lot/expiry eligibility; permission/approval threshold. |
| Xử lý | Append state movements and update balances atomically; sellable only when eligible. |
| Kết quả | Pending về 0 cho phạm vi; available tăng chỉ phần sellable. |
| Lỗi | `CLASSIFICATION_TOTAL_MISMATCH`, `EXPIRED_CANNOT_BE_SELLABLE`, `RETURN_ALREADY_CLASSIFIED`. |
| Entity | `ENT-IO-01/02/03/04/06`. |
| Trace | `BJ-06`; `ST-08.04`; `SG-07`; `API-C-08`; `EVT-IO-07`. |

<a id="bc-io-09"></a>
### BC-IO-09 — Return goods to supplier

| Mục | Hợp đồng |
|---|---|
| Ý định | Chặn bán khi approved return và ghi giảm physical/value khi handover. |
| Input | Supplier return/version, lines/lots, approved supplier price, handover assertion. |
| Guard | Stock/lot available; source valid; approval; financial permission where needed. |
| Xử lý | Approval stage may move to `RTV_PENDING`; handover appends issue/value movements using official cost and emits supplier-approved-price delta. |
| Kết quả | Physical/value giảm khi handover; accounting handoff emitted. |
| Lỗi | `INSUFFICIENT_STOCK`, `LOT_MISMATCH`, `HANDOVER_ASSERTION_REQUIRED`, `APPROVAL_REQUIRED`. |
| Entity | `ENT-IO-01…06`, `ENT-IV-02/04`. |
| Trace | `BJ-07`; `ST-09.01`, `ST-09.02`; `SG-08`; `API-C-09`; `EVT-IV-01`. |

<a id="bc-io-10"></a>
### BC-IO-10 — Change inventory state

| Mục | Hợp đồng |
|---|---|
| Ý định | Chuyển sellable/quarantine/damaged/demo và các trạng thái được phép mà không đổi tổng physical. |
| Input | Product/lot, quantity, from/to state, reason/evidence. |
| Guard | Allowed transition; quantity exists; expiry rule; permission/approval; no lock. |
| Xử lý | Append paired/state movement → update both balances → re-evaluate reservations/availability → outbox. |
| Kết quả | Physical total unchanged; availability/reservation effect recorded. |
| Lỗi | `STATE_TRANSITION_NOT_ALLOWED`, `INSUFFICIENT_IN_STATE`, `EXPIRED_CANNOT_BE_SELLABLE`. |
| Entity | `ENT-IO-01/02/03/04/06`. |
| Trace | `BJ-09`; `ST-11.01`, `ST-11.02`; `SG-08`; `API-C-10`; `EVT-IO-08`. |

<a id="bc-io-11"></a>
### BC-IO-11 — Dispose inventory

| Mục | Hợp đồng |
|---|---|
| Ý định | Giảm physical/value cho hàng hỏng/hết hạn đã xử lý thực tế. |
| Input | Product/lot/state quantity, disposal reason/evidence, completion assertion. |
| Guard | Non-sellable state; enough quantity; approval by quantity/value; confirmation. |
| Xử lý | Append issue movement + value movement at effective official cost + update balance + outbox. |
| Kết quả | Physical/value giảm; immutable disposal trail. |
| Lỗi | `DISPOSAL_NOT_APPROVED`, `DISPOSAL_CONFIRMATION_REQUIRED`, `INSUFFICIENT_STOCK`. |
| Entity | `ENT-IO-01…06`, `ENT-IV-02/04`, approval. |
| Trace | `BJ-09`; `ST-11.03`; `SG-08`; `API-C-11`; `EVT-IV-02`. |

<a id="bc-io-12"></a>
### BC-IO-12 — Cancel pending operation

| Mục | Hợp đồng |
|---|---|
| Ý định | Hủy operation trước execution mà không ảnh hưởng tồn. |
| Input | Operation ID/version, source version, reason. |
| Guard | Status in `DRAFT/PENDING_APPROVAL/READY`; permission; first valid transition wins. |
| Xử lý | Mark `CANCELLED`, release operation-owned locks/approval work, write audit/outbox. |
| Kết quả | Terminal cancelled; no movement/value effect. |
| Lỗi | `OPERATION_NOT_CANCELLABLE`, `VERSION_CONFLICT`; `PROCESSING/UNKNOWN` yêu cầu reconciliation, `COMPLETED` yêu cầu reversal. |
| Entity | `ENT-IO-01`, approval/locks. |
| Trace | `BJ-11`; `ST-12.01`, `ST-12.02`; `SG-10`; `API-C-12`; `EVT-IO-09`. |

<a id="bc-io-13"></a>
### BC-IO-13 — Reverse or correct completed operation

| Mục | Hợp đồng |
|---|---|
| Ý định | Tạo operation bù/sửa có liên kết, không sửa operation/ledger gốc. |
| Input | Original operation, correction type, replacement payload, reason/evidence, original period. |
| Guard | Original completed; no duplicate active correction; source/permission/approval; accounting-period rule. |
| Xử lý | Create new operation ID and CorrectionChain → revalidate current state → append delta/reversal movements/value → update balances atomically. |
| Kết quả | Original retained; new linked result; open-period accounting effect. |
| Lỗi | `CORRECTION_ALREADY_ACTIVE`, `ORIGINAL_NOT_COMPLETED`, `CORRECTION_NOT_FEASIBLE`, `PERIOD_POLICY_VIOLATION`. |
| Entity | `ENT-IO-01…07`, `ENT-IV-02/05/06` as needed. |
| Trace | `BJ-11`; `ST-12.03`, `ST-12.04`; `SG-10`; `API-C-13`; `EVT-IO-10`. |

<a id="bc-io-14"></a>
### BC-IO-14 — Query low stock suggestions

| Mục | Hợp đồng |
|---|---|
| Ý định | Hiển thị low/out-of-stock và lượng gợi ý đơn giản. |
| Input | Product filters, warehouse mặc định, threshold/target config, sort/page. |
| Guard | View permission; config non-negative and target coherent. |
| Xử lý | Read availability; status `OUT` if 0, `LOW` if `0<available≤threshold`; suggestion `max(0,target−available)`. |
| Kết quả | Derived rows + as-of; no proposal ID or mutation. |
| Lỗi | `REPLENISHMENT_CONFIG_INVALID`; missing config marked `NOT_CONFIGURED`. |
| Entity | `PRJ-08`, reference product/warehouse config. |
| Trace | `BJ-01`; `SG-12`; `API-Q-02`. |

## 5. Inventory Control contracts

<a id="bc-ic-01"></a>
### BC-IC-01 — Open stock count

| Mục | Hợp đồng |
|---|---|
| Ý định | Materialize scope/cut-off và khóa đúng balance keys. |
| Input | Warehouse, scope type/filter, requested cut-off, count reason. |
| Guard | Permission; no conflicting lock/session; valid scope; online mutation state only. |
| Xử lý | Snapshot scope predicate/range và resolve balance keys tại một ledger sequence → persist session/lines/book quantity → acquire lock áp dụng cho cả key hiện hữu lẫn prospective key → open session. |
| Kết quả | `OPEN/LOCKED` session and immutable scope hash. |
| Lỗi | `COUNT_SCOPE_EMPTY`, `LOCK_CONFLICT`, `COUNT_ALREADY_ACTIVE`. |
| Entity | `ENT-IC-03/04/05`, read balances. |
| Trace | `BJ-08`; `ST-10.01`, `ST-10.02`; `SG-09`; `API-C-14`. |

<a id="bc-ic-02"></a>
### BC-IC-02 — Submit count or recount

| Mục | Hợp đồng |
|---|---|
| Ý định | Ghi số đếm mù, lộ variance sau submit và bắt recount phần lệch. |
| Input | Session/version, counted lines, count/recount mode. |
| Guard | Actor assigned/authorized; line belongs materialized scope; session status; no self-overwrite. |
| Xử lý | Persist count snapshot → compute variance from book snapshot → mark recount required for differences → after recount route approval. |
| Kết quả | Submitted/recount-required/pending-approval with variance. |
| Lỗi | `COUNT_LINE_OUT_OF_SCOPE`, `COUNT_ALREADY_SUBMITTED`, `RECOUNT_REQUIRED`. |
| Entity | `ENT-IC-04/05`. |
| Trace | `BJ-08`; `ST-10.03`, `ST-10.04`; `SG-09`; `API-C-15`. |

<a id="bc-ic-03"></a>
### BC-IC-03 — Approve variance and adjust

| Mục | Hợp đồng |
|---|---|
| Ý định | Maker–checker approve variance and create adjustment so balance equals approved count. |
| Input | Session/version, approval decision/reason, line decisions. |
| Guard | Recount completed; approver eligible/not counter; risk snapshot; locks active; current ledger unchanged within locked scope. |
| Xử lý | Approve → create one adjustment operation from variances → append movements/value → complete session → release locks, all linked. Reject giữ session theo policy; hủy thuộc `BC-IC-08`. |
| Kết quả | Completed count and adjusted balances, or rejected without adjustment. |
| Lỗi | `SELF_APPROVAL_NOT_ALLOWED`, `COUNT_NOT_READY`, `LOCK_LOST`, `RISK_LEVEL_INSUFFICIENT`. |
| Entity | `ENT-IC-02…05`, `ENT-IO-01…04`, valuation refs. |
| Trace | `BJ-08`; `ST-10.05`, `ST-10.06`; `SG-09`; `API-C-16`; `EVT-IC-01`. |

<a id="bc-ic-04"></a>
### BC-IC-04 — Commit opening balance

| Mục | Hợp đồng |
|---|---|
| Ý định | Commit một opening batch đã chuẩn bị và duyệt, nguyên tử. |
| Input | Prepared batch ID/version, approved source/control hash, commit idempotency key. |
| Guard | Batch `APPROVED`; validation/control snapshot unchanged; one-store/warehouse context; activation `PREPARING`; mutation freeze; no completed batch. |
| Xử lý | Recheck approved hash → create opening operation(s) → movements/balances/value/initial cost → immutable report/hash → chuyển activation sang `ACTIVE` và unlock trong cùng transaction. |
| Kết quả | One `COMPLETED` batch; operations/report traceable; activation `ACTIVE`; normal mutation unlocked. |
| Lỗi | `OPENING_BATCH_ALREADY_EXISTS`, `INVENTORY_NOT_ACTIVATED`, `CONTROL_TOTAL_MISMATCH`, `MASTER_NOT_FOUND`, `LOT_OR_EXPIRY_REQUIRED`, `MIGRATION_VALIDATION_FAILED`. |
| Entity | `ENT-IC-06`, `ENT-IO-01…06`, `ENT-IV-02/04`. |
| Trace | `BJ-12`; `ST-13.03`, `ST-13.04`; `SG-13`; `API-C-17`; `EVT-IC-02`. |

<a id="bc-ic-05"></a>
### BC-IC-05 — Reconcile and rebuild projection

| Mục | Hợp đồng |
|---|---|
| Ý định | Giải quyết `UNKNOWN`/source/projection mismatch bằng bằng chứng, rebuild từ ledger và mở khóa an toàn. |
| Input | Case type/scope, evidence refs, operation ID/source identity, target projection/cut-off. |
| Guard | Reconciliation permission; case active; scope lock; ledger integrity available. |
| Xử lý | Collect evidence → resolve/continue same operation if UNKNOWN → compare ledger → rebuild projection → validate hash/counts → resolve case and unlock only when proof passes. |
| Kết quả | Resolved or remains unresolved/UNKNOWN; audit and rebuild evidence retained. |
| Lỗi | `INSUFFICIENT_EVIDENCE`, `LEDGER_INTEGRITY_FAILED`, `REBUILD_VALIDATION_FAILED`, `CASE_NOT_ACTIVE`. |
| Entity | `ENT-IC-03/07`, operation/ledger/projection. |
| Trace | `BJ-16`, `BJ-17`, `PROC-01`; `SG-15`; `API-C-18`. |

<a id="bc-ic-06"></a>
### BC-IC-06 — Decide approval

| Mục | Hợp đồng |
|---|---|
| Ý định | Ghi quyết định duyệt/từ chối theo policy snapshot và quyền hiện hành. |
| Input | Approval case/version, decision, mandatory rejection reason, actor. |
| Guard | Actor còn quyền/phạm vi và có level ≥ `required_approval_level` đã chụp; không phải maker; case còn mở; commit hợp lệ đầu tiên thắng. |
| Xử lý | Append một quyết định → approve thì operation thành `READY`; reject thì terminal `APPROVAL_REJECTED`; không có chuỗi duyệt qua cấp thấp; ghi audit/outbox. |
| Kết quả | New case/operation status; no inventory mutation. |
| Lỗi | `APPROVER_NOT_ELIGIBLE`, `SELF_APPROVAL_NOT_ALLOWED`, `APPROVAL_ALREADY_DECIDED`, `REJECTION_REASON_REQUIRED`. |
| Entity | `ENT-IC-01/02`, `ENT-IO-01`. |
| Trace | Cross-cutting `ST-02.05`, `ST-17.01`, `ST-17.02`, `ST-17.03`, `ST-17.04`; `SG-10`; `API-C-19`; `EVT-IC-04`. |

## 6. Inventory Valuation contracts

<a id="bc-iv-01"></a>
### BC-IV-01 — Confirm direct receipt cost and release

| Mục | Hợp đồng |
|---|---|
| Ý định | Ghi direct cost và chuyển lượng đủ điều kiện từ `VALUATION_PENDING` sang sellable. |
| Input | Receipt lines, price source/version/evidence, tax treatment, currency/unit cost. |
| Guard | Financial permission; receipt completed/owned; source valid; no duplicate confirmation; lot not expired/blocked. |
| Xử lý | Persist ReceiptValuation → append value movement → state movement/balance release → create initial official cost for new product if required → outbox atomically. |
| Kết quả | Value recorded; eligible quantity available. |
| Lỗi | `PRICE_EVIDENCE_REQUIRED`, `RECEIPT_NOT_VALUATION_PENDING`, `DIRECT_PRICE_ALREADY_CONFIRMED`, `CURRENCY_MISMATCH`. |
| Entity | `ENT-IV-01/02/04`, `ENT-IO-01…04`. |
| Trace | `BJ-03`; `ST-03.01`, `ST-03.02`, `ST-03.03`; `SG-03`; `API-C-20`; `EVT-IV-03`. |

<a id="bc-iv-02"></a>
### BC-IV-02 — Calculate inventory cost

| Mục | Hợp đồng |
|---|---|
| Ý định | Tính hai phương pháp trên cùng cut-off và tạo bản nháp có blocker/evidence. |
| Input | Accounting period, product scope, quantity/value sequences, selected-method policy version, `supersedes_run_id?` khi tính lại. |
| Guard | Financial permission; valid/open period for draft; deterministic input snapshot. |
| Xử lý | Snapshot inputs/hash và dirty scope → detect blockers → calculate moving and periodic weighted average → compare → mark `BLOCKED` or `READY_FOR_REVIEW`. Run đã bắt đầu không có lệnh hủy; tính lại tạo successor run mới. |
| Kết quả | CostCalculationRun with both result sets and blocker snapshot; no ledger mutation. |
| Lỗi | `INPUT_SNAPSHOT_INCONSISTENT`, `CALCULATION_FAILED`, `PERIOD_NOT_CALCULABLE`. |
| Entity | `ENT-IV-03`; read movements/valuations/period. |
| Trace | `BJ-14`; `ST-14.01`, `ST-14.02`, `ST-14.03`; `SG-14`; `API-C-21`. |

<a id="bc-iv-03"></a>
### BC-IV-03 — Publish valuation and official cost

| Mục | Hợp đồng |
|---|---|
| Ý định | Publish linked COGS true-up, ending inventory adjustment và official cost versions. |
| Input | Ready run/version, reviewer confirmation, effective time. |
| Guard | Financial role; no blockers at recheck; run not published; selected method matches snapshot; totals reconcile. |
| Xử lý | Build adjustment batch/lines → append value movements → create non-overlapping official cost versions → mark run published → outbox atomically. |
| Kết quả | New official cost and adjustments; original order/issue unchanged. |
| Lỗi | `COST_RUN_BLOCKED`, `COST_RUN_ALREADY_PUBLISHED`, `ADJUSTMENT_TOTAL_MISMATCH`, `COST_EFFECTIVE_INTERVAL_OVERLAP`. |
| Entity | `ENT-IV-02…06`; links to issue lines. |
| Trace | `BJ-14`; `ST-14.04`, `ST-14.05`, `ST-14.06`; `SG-14`; `API-C-22`; `EVT-IV-04`. |

<a id="bc-iv-04"></a>
### BC-IV-04 — Record late landed cost

| Mục | Hợp đồng |
|---|---|
| Ý định | Ghi chi phí mua bổ sung có nguồn mà không sửa receipt/value movement gốc. |
| Input | Receipt/source line, source document/line/version, cost component type/version/evidence, amount/currency, allocation basis, original period. |
| Guard | Financial permission; receipt owned/valued; natural key nguồn chưa ghi; source version current; allocation total reconciles; open accounting period for posting. |
| Xử lý | Persist natural-key receipt → chuẩn hóa VND → tạo `LATE_LANDED_COST` adjustment batch/lines → append vào kỳ hợp lệ → đánh dấu đúng product-period scope `DIRTY` → outbox. Run kế tiếp liên kết run bị thay thế nếu cần. |
| Kết quả | Late cost recorded exactly once; affected scope và period attribution rõ; không sửa receipt/value/run cũ. |
| Lỗi | `LATE_COST_SOURCE_REQUIRED`, `LATE_COST_ALREADY_RECORDED`, `LATE_COST_ALLOCATION_MISMATCH`, `POSTING_PERIOD_NOT_OPEN`. |
| Entity | `ENT-IV-01/02/05/06`; read receipt operation line. |
| Trace | `BJ-14`; `ST-03.04`; `SG-03/14`; `API-C-23`; `EVT-IV-05`. |

## 7. Cross-domain pricing contracts

Các BC `XD` nằm trong package để khóa handoff và trace; authoritative implementation có thể thuộc bounded context Mua hàng/Định giá. Chúng không được ghi inventory ledger.

<a id="bc-xd-01"></a>
### BC-XD-01 — Calculate purchase-discount scenario

| Mục | Hợp đồng |
|---|---|
| Ý định | Tính projected cost theo sản phẩm trước PO/receipt. |
| Input | Scenario period/version, projected quantities, base purchase prices, percent/amount/free-goods rules. |
| Guard | Planning permission; product/currency valid; assumptions complete. |
| Xử lý | Normalize benefit → calculate per-product projected cost → persist version/input hash. |
| Kết quả | Scenario version and projected cost; no inventory/AP/accounting mutation. |
| Lỗi | `SCENARIO_INPUT_INVALID`, `BENEFIT_RULE_AMBIGUOUS`, `SCENARIO_VERSION_CONFLICT`. |
| Entity | External `REF-12`; not owned by inventory. |
| Trace | `XREF-02`; Theme 10 — Mua hàng; `T10-UC-DS-01…04`; outbound `SG-16`; `API-X-01`. |

<a id="bc-xd-02"></a>
### BC-XD-02 — Publish pricing cost basis and draft

| Mục | Hợp đồng |
|---|---|
| Ý định | Publish basis source official/projected and create floor/list price draft. |
| Input | Product, source type/version/value, effective time, pricing policy version. |
| Guard | Pricing permission; source exists/not stale; source type allowed. |
| Xử lý | Create basis version with provenance → calculate draft floor/list → no price publication. |
| Kết quả | PricingCostBasisVersion and pricing draft. |
| Lỗi | `PRICING_SOURCE_INVALID`, `PRICING_SOURCE_VERSION_STALE`, `PRICING_POLICY_MISSING`. |
| Entity | External `REF-12/13/14`; read official cost `ENT-IV-04`. |
| Trace | `XREF-03`; Theme 2 — Sản phẩm; outbound `SG-16`; `API-X-02`; `EVT-XD-01`. |

<a id="bc-xd-03"></a>
### BC-XD-03 — Review pricing basis after cost publication

| Mục | Hợp đồng |
|---|---|
| Ý định | Route review by current source type after new official cost. |
| Input | Official cost event/version, product set, decisions (`UPDATE`, `KEEP`, `USE_OFFICIAL`, `RECALCULATE_SCENARIO`). |
| Guard | Pricing permission; current basis provenance available; event idempotent. |
| Xử lý | Group official-source items for selectable bulk update; require per-item decision for projected-source items; create basis versions/drafts only. |
| Kết quả | Review decisions and new drafts; selling price unchanged. |
| Lỗi | `PRICING_PROVENANCE_MISSING`, `PROJECTED_SOURCE_DECISION_REQUIRED`, `REVIEW_ALREADY_APPLIED`. |
| Entity | External review/basis/draft; read `ENT-IV-04`. |
| Trace | `XREF-04`; Theme 2 — Sản phẩm; `T2-UC-PR-01…04`; outbound `SG-17`; `API-X-03`; `EVT-XD-02`. |

<a id="bc-xd-04"></a>
### BC-XD-04 — Query margin comparison

| Mục | Hợp đồng |
|---|---|
| Ý định | Tách margin tại giao dịch, sau đối soát và dự kiến. |
| Input | Product/order/period filters, as-of, financial view permission. |
| Guard | Financial/report permission; consistent snapshot. |
| Xử lý | Transaction margin uses initial COGS; reconciled margin adds linked true-up; projected margin uses current pricing cost basis. |
| Kết quả | Three labeled values with source/version/as-of; never collapsed into one accounting number. |
| Lỗi | `FINANCIAL_VIEW_FORBIDDEN`, `MARGIN_SOURCE_INCOMPLETE`. |
| Entity | `PRJ-10`, issue/value lines, external pricing refs. |
| Trace | `XREF-05`; Reporting/Analytics; outbound `SG-17`; `API-Q-03`. |

<a id="bc-io-15"></a>
### BC-IO-15 — Save pick allocation

| Mục | Hợp đồng |
|---|---|
| Ý định | Lưu một version của tập dòng phân bổ lô/lượng pick mà chưa giảm physical. |
| Input | Fulfillment/reservation IDs, `allocation_set_id?`, expected allocation version, các line_no/lots/quantities, allocation method, override reason. |
| Guard | Reservation active; expected version khớp; total lines ≤ unconsumed reservation; lot eligible/available; override permission/reason. |
| Xử lý | Lock reservation + active allocation set → compare-and-swap version → supersede toàn version cũ nếu sửa → persist một active set version và audit; không movement/value. |
| Kết quả | `allocation_set_id`, new `allocation_version` và các line ổn định sẵn sàng cho handover. |
| Lỗi | `PICK_ALLOCATION_CONFLICT`, `PICK_EXCEEDS_RESERVATION`, `LOT_NOT_ELIGIBLE`, `OVERRIDE_REASON_REQUIRED`. |
| Entity | `ENT-IO-05/09`; read `ENT-IO-04/06/08`. |
| Trace | `BJ-05`; `ST-06.01`, `ST-06.03`; `SG-06`; `API-C-24`; synchronous result. |

<a id="bc-io-16"></a>
### BC-IO-16 — Maintain operation draft

| Mục | Hợp đồng |
|---|---|
| Ý định | Tạo hoặc sửa payload draft mà không tạo movement/lot/approval. |
| Input | Create/update command idempotency key, `operation_request_id`, operation ID?, expected version?, source identity/version, draft payload. |
| Guard | Operation mới hoặc status `DRAFT`; source current; permission/scope; optimistic version. |
| Xử lý | Persist/update draft + CommandReceipt; validate schema mềm; chưa khóa submitted payload hash và chưa tạo business outbox. |
| Kết quả | Stable operation ID, draft version và validation findings. |
| Lỗi | `OPERATION_NOT_DRAFT`, `VERSION_CONFLICT`, `IDEMPOTENCY_PAYLOAD_MISMATCH`, `SOURCE_VERSION_STALE`. |
| Entity | `ENT-IO-01/02/10`. |
| Trace | Cross-cutting `ST-20.01`; `SG-10`; `API-C-25`; synchronous result. |

<a id="bc-ic-07"></a>
### BC-IC-07 — Submit inventory operation

| Mục | Hợp đồng |
|---|---|
| Ý định | Khóa payload draft, tính policy/risk và chuyển sang chờ duyệt hoặc sẵn sàng. |
| Input | Operation ID/version, submit idempotency key, requested execution context. |
| Guard | Draft valid; source current; price/FX basis đủ cho mọi dòng. Với `operation_type=QUICK_RECEIPT`, luôn phải có ApprovalPolicy active và eligible approver; không có cấu hình hoặc nhánh bỏ qua duyệt. |
| Xử lý | Hash/lock payload → snapshot per-line risk và policy. `QUICK_RECEIPT` luôn tạo ApprovalCase và chuyển `PENDING_APPROVAL`; hệ thống không hỏi người dùng có cần duyệt và không được đi thẳng `READY`. Nhánh `READY` không cần duyệt chỉ áp dụng cho operation type khác được policy cho phép. CommandReceipt được ghi cùng transaction. |
| Kết quả | Immutable submitted payload và route/status xác định. |
| Lỗi | `DRAFT_VALIDATION_FAILED`, `APPROVAL_PRICE_BASIS_REQUIRED`, `APPROVER_CONFIGURATION_MISSING`, `OPERATION_NOT_DRAFT`. |
| Entity | `ENT-IO-01/02/10`, `ENT-IC-01/02`. |
| Trace | Cross-cutting `ST-02.05`, `ST-17.01`, `ST-20.01`; `SG-10`; `API-C-26`; synchronous result; [T7-DR-027](../../../../../../01.knowledge/decisions/decision-register.md#g03). |

<a id="bc-ic-08"></a>
### BC-IC-08 — Cancel stock count

| Mục | Hợp đồng |
|---|---|
| Ý định | Hủy phiên kiểm kê có lý do, không điều chỉnh tồn và giải phóng lock an toàn. |
| Input | Session ID/version, cancellation reason, idempotency key. |
| Guard | Permission; status cancellable; lock still owned by session; first valid transition wins. |
| Xử lý | Mark `CANCELLED` + audit → release owned scope lock in same transaction; keep lines/count snapshots. |
| Kết quả | Session cancelled; no movement/value/adjustment. |
| Lỗi | `COUNT_NOT_CANCELLABLE`, `LOCK_OWNERSHIP_MISMATCH`, `CANCELLATION_REASON_REQUIRED`. |
| Entity | `ENT-IC-03/04/05`, `ENT-IO-10`. |
| Trace | `BJ-08`; `ST-10.06`; `SG-09`; `API-C-27`; `EVT-IC-05`. |

<a id="bc-ic-09"></a>
### BC-IC-09 — Prepare opening balance batch

| Mục | Hợp đồng |
|---|---|
| Ý định | Nạp, chuẩn hóa, kiểm tra và gửi duyệt opening batch trước commit. |
| Input | Baseline/cut-off, source file/hash, normalized lines, control totals, command idempotency key. |
| Guard | Permission; activation `PREPARING`; no completed batch; master/UOM/tracking valid; mutation freeze active. |
| Xử lý | Persist staging/version → validate all lines/control totals → on valid submit create approval snapshot; không ledger/value/unlock. |
| Kết quả | `VALIDATION_FAILED`, `DRAFT`, hoặc `PENDING_APPROVAL/APPROVED` qua generic approval route. |
| Lỗi | `CONTROL_TOTAL_MISMATCH`, `MASTER_NOT_FOUND`, `LOT_OR_EXPIRY_REQUIRED`, `MIGRATION_VALIDATION_FAILED`. |
| Entity | `ENT-IC-06`, `ENT-IC-01/02`, `ENT-IO-10`; staging only. |
| Trace | `BJ-12`; `ST-13.01`, `ST-13.02`; `SG-13`; `API-C-28`; synchronous result. |

<a id="bc-xd-05"></a>
### BC-XD-05 — Configure inventory product policy

| Mục | Hợp đồng |
|---|---|
| Ý định | Lưu chính sách tồn thấp và cận hạn theo sản phẩm, có fallback tenant default. |
| Input | Product, warehouse mặc định, threshold, target, optional near-expiry days/action override, expected config version. |
| Guard | Product-config permission; `target ≥ threshold ≥ 0`; days ≥ 0; action thuộc `WARN/BLOCK_SALE`; Phase 1 warehouse must be default. |
| Xử lý | Create/update versioned config; invalidate low-stock/expiry eligibility cache; không tạo proposal/PO/alert entity/inventory movement. |
| Kết quả | New config version and effective time. |
| Lỗi | `REPLENISHMENT_CONFIG_INVALID`, `NEAR_EXPIRY_POLICY_INVALID`, `WAREHOUSE_ROUTING_NOT_AVAILABLE`, `VERSION_CONFLICT`. |
| Entity | External product/warehouse config ref; read by `PRJ-08`. |
| Trace | `CAP-01`; `CAP-01-OP-01…03`; `SG-12`; `API-X-04`; `EVT-XD-03`. |

## 8. Structured capability rejection

| Capability | Error code | Mutation allowed |
|---|---|---:|
| Internal transfer | `CAPABILITY_NOT_AVAILABLE_INTERNAL_TRANSFER` | No |
| Warehouse close/switch | `CAPABILITY_NOT_AVAILABLE_WAREHOUSE_LIFECYCLE` | No |
| Offline sale/sync | `CAPABILITY_NOT_AVAILABLE_OFFLINE_SALE` | No |
| Serial tracking | `CAPABILITY_NOT_AVAILABLE_SERIAL_TRACKING` | No |
| Custody/consignment | `CAPABILITY_NOT_AVAILABLE_CUSTODY` | No |
| SKU conversion/repack | `CAPABILITY_NOT_AVAILABLE_SKU_TRANSFORMATION` | No |
| Tracking conversion with stock | `TRACKING_CHANGE_REQUIRES_ZERO_STOCK` | No |
| Replenishment proposal/auto PO | `CAPABILITY_NOT_AVAILABLE_REPLENISHMENT_WORKFLOW` | No |

Rejection xảy ra trước khi tạo operation hoặc entity tương lai; có correlation/audit security log nhưng không có business outbox event.

## 9. Contract quality gates

1. 34/34 BC ID duy nhất và có owner.
2. Mỗi mutating screen action có đúng một primary BC.
3. Mỗi BC mutation có input identity, permission/scope, guard, atomic effect, result, error và entity mapping.
4. Mỗi BC có đúng một authoritative handler trong Part 07.
5. Query không được dùng projection trễ cho commit decision.
6. Không BC nào tạo Serial, Offline, Transfer, Custody, Alert hoặc ReplenishmentProposal entity.
7. Pricing BC không ghi inventory/value ledger; inventory BC không công bố selling price.
8. Mọi result/error có `effect_status`, thông điệp người dùng và bước tiếp theo hợp lệ; không action nào trong guidance vượt permission, state guard hoặc capability boundary.


<a id="finality-contract-v410"></a>
## 15. Finality contract cho BJ v4.1.0

- `COMPLETED` chỉ khi owner effect đã commit và có bằng chứng authoritative.
- `REJECTED/CANCELLED` có owner effect bằng 0.
- `SUSPENDED/BLOCKED` giữ work identity và điều kiện tiếp tục.
- `UNKNOWN/ESCALATED` không được đổi thành thất bại; mọi query/resume dùng cùng operation identity.

<a id="ownership-metadata-contract-v410"></a>
## 16. Ownership metadata contract cho BJ v4.1.0

Mỗi BJ/CAP/PROC/XREF khai báo owner, provider, finality và đường bàn giao. XREF-02 thuộc Theme 10 — Mua hàng; XREF-03/04 thuộc Theme 2 — Sản phẩm; BJ-09 thuộc Inventory Control. `outbound/` là hồ sơ tạm thời, không phải authority thứ hai.

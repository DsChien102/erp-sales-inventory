# TH-05 — Slice roadmap

Một US tương ứng một vertical slice. Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

**Contract completion:** S01 là runtime-only nên CONTRACT/BE giữ `n/a`; S02–S21 và S23–S34 đã hoàn tất CONTRACT (docs). **Group G / S22 (EP-04 order-note adjustment) `superseded` / out of scope** — mọi lane `n/a`; implementation đã gỡ. **S20 (EP-03/US-06 integration tracking) `deferred` / stub** — Sales facts-only reactive; retry/reconcile + real projection chờ TH-06/07/08. Group A S02-S05 BE runtime/provider-port đã `done`; Group B S06-S07 BE draft persistence/restore đã `done`; Group C S08-S11 BE checkout input/precheck đã `done`; Group D S12 BE authoritative checkout commit đã `done`; Group E S13-S14 BE result-view/receipt read+write đã `done`; **Group E S13-S14 BE–FE integration** đã `done` (2026-08-12); Group F-read S15-S19 BE order inquiry/detail/payment/timeline/receipt-reuse đã `done`; Group F-ops S21 BE post-sale-entry đã `done`; **S20 BE/FE `deferred`** (stub `get_order_integration_status` → `notRequired`); **Group F S15–S19, S21 BE–FE integration** đã `done` (2026-08-12) — post-sale entry chỉ cancel + return/exchange (không adjust); Group H S23–S27 BE cancellation đã `done` (draft-only SQL, chưa promote/apply); Group I S28–S34 BE return/exchange đã `done` (draft-only SQL + FE contract, chưa promote/apply); **Group I S28–S34 BE–FE integration** đã `done` (2026-08-13) — E2E vẫn `todo`/`blocked`. Prerequisite ngoài module chỉ bind E2E; các lane khác dùng ports và fakes.

**Re-harness (Theme-5 Phase 1):** EP-04 từng gom còn 1 US → slice **S22** — nay **superseded**; EP-05/EP-06 **renumber** (cũ S27–S38 → S23–S34).

| # | Slice | Type | Contract | BE | FE | E2E | Parallel group | E2E blocked by |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S01 | [EP-01/US-01](../Epic-01-order-drafting-and-drafts/US-01.md) — Khởi tạo đơn hàng đang lập | runtime | n/a | n/a | done | todo | A0 | IAM store/shift context |
| S02 | [EP-01/US-02](../Epic-01-order-drafting-and-drafts/US-02.md) — Xác định khách hàng cho đơn hàng | runtime/port | done | done | done | todo | A | Partner search/quick-create |
| S03 | [EP-01/US-03](../Epic-01-order-drafting-and-drafts/US-03.md) — Thêm và quản lý dòng hàng | runtime/port | done | done | done | blocked | A | Drafts `015`/`016` đã apply; thiếu live tenant/store/product seed IDs và live run pass |
| S04 | [EP-01/US-04](../Epic-01-order-drafting-and-drafts/US-04.md) — Kiểm tra và điều chỉnh giá bán | runtime/port | done | done | done | blocked | A | Draft `017` đã apply; thiếu live customer/product seed IDs và live run pass |
| S05 | [EP-01/US-05](../Epic-01-order-drafting-and-drafts/US-05.md) — Lưu giá riêng hoặc nhớ giá từ đơn hàng | cross-module write | done | done | done | blocked | A | Draft `017` đã apply; thiếu live seed IDs nên create/update/owned-rule cleanup chưa chạy |
| S06 | [EP-01/US-06](../Epic-01-order-drafting-and-drafts/US-06.md) — Lưu đơn hàng thành đơn nháp | write | done | done | done | blocked | B | Draft `001_sales_order_drafts_group_b.sql` draft-only (unpromoted/unapplied); missing `C45_E2E_*` seeds; guarded live test skips; do not claim E2E done |
| S07 | [EP-01/US-07](../Epic-01-order-drafting-and-drafts/US-07.md) — Khôi phục và quản lý đơn nháp | read/write | done | done | done | blocked | B | Same blockers as S06 — restore/list/cancel live gate not executed; draft RPCs unpromoted + missing live seed IDs |
| S08 | [EP-02/US-01](../Epic-02-checkout-and-completion/US-01.md) — Kiểm tra tổng tiền và nghĩa vụ thanh toán | validation/read | done | done | done | blocked | C | 002 draft-only/unpromoted/unapplied; RPC currently fail-closed; Pricing/Catalog/Partner/Inventory/receivable owner contracts and live seed IDs required |
| S09 | [EP-02/US-02](../Epic-02-checkout-and-completion/US-02.md) — Ghi nhận một hoặc nhiều khoản thanh toán | orchestration/write | done | done | done | blocked | C | 002 draft-only/unpromoted/unapplied; RPC currently fail-closed; Pricing/Catalog/Partner/Inventory/receivable owner contracts and live seed IDs required |
| S10 | [EP-02/US-03](../Epic-02-checkout-and-completion/US-03.md) — Xử lý đơn hàng còn phải thu | orchestration/write | done | done | done | blocked | C | 002 draft-only/unpromoted/unapplied; RPC currently fail-closed; Pricing/Catalog/Partner/Inventory/receivable owner contracts and live seed IDs required; frozen PrecheckSalesOrderCheckoutQuery has no dueDate field |
| S11 | [EP-02/US-04](../Epic-02-checkout-and-completion/US-04.md) — Kiểm tra điều kiện checkout | validation/read | done | done | done | blocked | C | 002 draft-only/unpromoted/unapplied; RPC currently fail-closed; Pricing/Catalog/Partner/Inventory/receivable owner contracts and live seed IDs required |
| S12 | [EP-02/US-05](../Epic-02-checkout-and-completion/US-05.md) — Hoàn tất đơn hàng an toàn | orchestration/write | done | done | done | todo | D | TH-05 handoff hoàn tất ở durable backlog; live owner consumption/E2E chờ canonical TH-06/TH-07 |
| S13 | [EP-02/US-06](../Epic-02-checkout-and-completion/US-06.md) — Xem kết quả giao dịch | read | done | done | done | todo | E | S12 checkout data/projections |
| S14 | [EP-02/US-07](../Epic-02-checkout-and-completion/US-07.md) — Xem, in hoặc chia sẻ phiếu bán hàng | read/write | done | done | done | todo | E | S12 committed snapshot + device share/print |
| S15 | [EP-03/US-01](../Epic-03-order-inquiry-and-tracking/US-01.md) — Tra cứu danh sách đơn hàng | read | done | done | done | blocked | F | Draft-only `006` unpromoted/unapplied; S12 order projections + live seed IDs |
| S16 | [EP-03/US-02](../Epic-03-order-inquiry-and-tracking/US-02.md) — Xem chi tiết giao dịch gốc | read | done | done | done | blocked | F | Draft-only `006` unpromoted/unapplied; S12 order + projection + live seeds |
| S17 | [EP-03/US-03](../Epic-03-order-inquiry-and-tracking/US-03.md) — Kiểm tra thanh toán và công nợ của đơn | read | done | done | done | blocked | F | Draft-only `006` unpromoted/unapplied; Settlement + TH-06 projection + live seeds |
| S18 | [EP-03/US-04](../Epic-03-order-inquiry-and-tracking/US-04.md) — Theo dõi timeline và lịch sử sau bán | read | done | done | done | blocked | F | Draft-only `006` unpromoted/unapplied; post-sale projections + live seeds |
| S19 | [EP-03/US-05](../Epic-03-order-inquiry-and-tracking/US-05.md) — Xem lại phiếu bán hàng | read/write | done | done | done | blocked | F | Draft-only `005`/`006` unpromoted/unapplied; receipt projection/device |
| S20 | [EP-03/US-06](../Epic-03-order-inquiry-and-tracking/US-06.md) — Theo dõi trạng thái xử lý liên quan | read/technical write | deferred | deferred | deferred | blocked | F | **Deferred (option B reactive)** — Sales facts-only; stub `get_order_integration_status` → `notRequired`; retry/reconcile + thin projection chờ TH-06/07/08 |
| S21 | [EP-03/US-07](../Epic-03-order-inquiry-and-tracking/US-07.md) — Khởi tạo thao tác sau bán | read/entry | done | done | done | blocked | F | Draft-only available-actions + authoritative prechecks cancel/return unpromoted/unapplied; EP-05/EP-06 owners (EP-04 adjust superseded) |
| S22 | [EP-04/US-01](../Epic-04-post-sale-order-adjustments/US-01.md) — Cập nhật ghi chú đơn hàng | read/write | n/a | n/a | n/a | n/a | G | **Superseded / out of scope** — implementation removed; historical US kept |
| S23 | [EP-05/US-01](../Epic-05-post-sale-order-cancellation/US-01.md) — Kiểm tra điều kiện và tác động hủy đơn | validation/read | done | done | done | todo | H | Draft-only `010_sales_order_cancellation_group_h.sql`; Pricing + Inventory + Receivable + E-invoice owner contracts; store-scope ownership; unpromoted/unapplied Group D/H drafts |
| S24 | [EP-05/US-02](../Epic-05-post-sale-order-cancellation/US-02.md) — Xác định lý do hủy | validation/runtime | done | done | done | todo | H | Draft-only Group H SQL + S23 precheck; store-scope ownership; unpromoted/unapplied drafts |
| S25 | [EP-05/US-03](../Epic-05-post-sale-order-cancellation/US-03.md) — Xác nhận hủy toàn bộ đơn hàng | orchestration/write | done | done | done | todo | H | TH-05 handoff hoàn tất ở durable backlog; live owner consumption/E2E chờ canonical TH-06/TH-07; drafts unpromoted/unapplied |
| S26 | [EP-05/US-04](../Epic-05-post-sale-order-cancellation/US-04.md) — Theo dõi các tác động hoàn nguyên | read/technical write | done | done | done | todo | H | TH-05 handoff hoàn tất ở durable backlog; live owner consumption/E2E chờ canonical TH-06/TH-07; drafts unpromoted/unapplied |
| S27 | [EP-05/US-05](../Epic-05-post-sale-order-cancellation/US-05.md) — Xem kết quả và lịch sử hủy đơn | read | done | done | done | todo | H | Draft-only Group H cancellation detail RPC; S25/S26 projections; unpromoted/unapplied Group D/H drafts |
| S28 | [EP-06/US-01](../Epic-06-returns-exchanges-and-settlement/US-01.md) — Khởi tạo phiếu đổi/trả từ đơn hàng gốc | read/write | done | done | done | todo | I | TH-05 handoff hoàn tất ở durable backlog; live owner consumption/E2E chờ canonical TH-06/TH-07; drafts `012`/`020` unpromoted/unapplied |
| S29 | [EP-06/US-02](../Epic-06-returns-exchanges-and-settlement/US-02.md) — Ghi nhận hàng khách trả | read/write | done | done | done | todo | I | Draft-only Group I session/`020` policy SQL; returnable qty + Pricing snapshots; store-scope; unpromoted/unapplied drafts |
| S30 | [EP-06/US-03](../Epic-06-returns-exchanges-and-settlement/US-03.md) — Ghi nhận hàng khách nhận đổi | write | done | done | done | todo | I | Draft-only Group I session SQL; Catalog + Pricing + Inventory owners; store-scope; unpromoted/unapplied drafts |
| S31 | [EP-06/US-04](../Epic-06-returns-exchanges-and-settlement/US-04.md) — Giữ và bỏ thay đổi chưa xác nhận trong phiên đổi/trả | runtime | done | done | done | todo | I | Draft-only Group I session SQL; Inventory reservation release; store-scope; unpromoted/unapplied drafts |
| S32 | [EP-06/US-05](../Epic-06-returns-exchanges-and-settlement/US-05.md) — Xem giá trị và chênh lệch đổi/trả | validation/read | done | done | done | todo | I | Draft-only `013_sales_return_exchange_group_i_settlement.sql`; Pricing + Settlement owners; store-scope; unpromoted/unapplied drafts |
| S33 | [EP-06/US-06](../Epic-06-returns-exchanges-and-settlement/US-06.md) — Quyết toán chênh lệch đổi/trả | orchestration/write | done | done | done | todo | I | Draft-only Group I settlement SQL; TH-06 Receivable owner; store-scope; unpromoted/unapplied drafts |
| S34 | [EP-06/US-07](../Epic-06-returns-exchanges-and-settlement/US-07.md) — Xác nhận và theo dõi kết quả đổi/trả | orchestration/read | done | done | done | todo | I | TH-05 handoff hoàn tất ở durable backlog; live owner consumption/E2E chờ canonical TH-06/TH-07; drafts `014`/`020` unpromoted/unapplied |

## Parallel groups

| Group | Slices | Intent |
| --- | --- | --- |
| A0 | S01 | Runtime working state |
| A | S02–S05 | Customer/product/pricing runtime ports; có thể contract song song |
| B | S06–S07 | Draft persistence/restore |
| C | S08–S11 | Checkout inputs/precheck |
| D | S12 | Authoritative checkout commit |
| E | S13–S14 | Result và receipt |
| F | S15–S19, S21 | Inquiry/read models (+ post-sale entry); **S20 deferred** |
| G | S22 | **Superseded** — order note adjustment (out of scope) |
| F-deferred | S20 | Integration status/retry — stub until owner themes + projection slice |
| H | S23–S27 | Cancellation |
| I | S28–S34 | Return/exchange |

## Definition of Done per lane

### CONTRACT

- Application symbols/DTOs documented in [07-api-contracts.md](07-api-contracts.md); permission/idempotency/error/fake contract `frozen`.
- BE và FE review cùng field semantics; không freeze theo Appendix 6.1 vì appendix không tồn tại.
- Pass docs re-harness + Dart application Phase 1 sync; BE/FE vẫn `todo`.

### BE

- Domain + handler + gateway/RPC draft; tests xanh; không promote migration trừ khi user yêu cầu.

### FE

- Page/widgets theo UI artifacts; gọi `ISalesModule`/`IModuleMediator`; async query theo playbook.

### E2E

- Chỉ khi external blockers sẵn sàng; dùng live stack / env doctor.

### Chung

- Cập nhật [05-traceability.md](05-traceability.md) Role row của slice.
- `melos run analyze && melos run test` (+ codegen khi đổi handler).

# 08 — UI/UX và bản đồ bề mặt

## 1. Vai trò của phần UI/UX

SRS không cố đóng vai trò file thiết kế chi tiết. Phần này chỉ giữ:

1. Screen Group map.
2. Shared layout/state patterns.
3. Screen Contract tối thiểu: mục đích, dữ liệu, action→BC, trạng thái đặc thù và permission.
4. Handoff contract cho quy trình **SRS → low-fi → HTML prototype → Figma**.

HTML prototype là low-fi có thể chạy để kiểm chứng flow và state. Figma là Dữ liệu gốc về component, token, layout và visual fidelity sau khi flow đã được duyệt. Cả hai dùng stable IDs từ SRS.

Để Part 08 không phình thành tài liệu thiết kế chi tiết, Screen/State/UI tree theo từng SG được tách thành bộ UI Contracts ngang hàng. Part 08 giữ bản đồ và quy tắc; mỗi thư mục SG giữ đủ Screen, State, composition map và prototype manifest. Thứ tự quyền lực khi có xung đột là **Quyết định nghiệp vụ → SRS → Use Case/BC → UI Contract → prototype → implementation**.

## 2. Nguyên tắc trải nghiệm Phase 1

- Không hiển thị selector Store/Warehouse khi chỉ có một cặp. Context mặc định hiện như nhãn đọc-only ở nơi cần đối soát.
- Nhiều user có thể làm việc đồng thời; conflict/version state phải rõ, không âm thầm ghi đè.
- Không có screen, tab, CTA hoặc disabled control cho transfer, warehouse close, offline sale, serial, custody hay replenishment proposal.
- `NONE` ẩn/vô hiệu hóa toàn bộ lot/manufacture/expiry fields; `LOT` mới hiện lot, và `expiry_required` quyết định required marker.
- Giá và margin được field-mask nhất quán trên list/detail/export nếu thiếu financial permission.
- Mọi mutating action có đúng một primary BC; UI không tự thực hiện hai BC dưới một nút mà không có orchestration contract.
- `UNKNOWN` không hiển thị như “Thất bại”; phải có trạng thái riêng và CTA đối soát/refresh hợp lệ.
- Không dùng màu là tín hiệu duy nhất cho stock status, expiry, approval hoặc error.

### 2.1 Bản đồ trải nghiệm theo vai trò và công việc

Đây là lớp điều hướng vào 17 Screen Group hiện có, không phải một nhóm màn hình hay capability mới.

| Vai trò | Công việc mặc định | Điểm đến hiện có | Nguyên tắc hiển thị |
|---|---|---|---|
| Nhân viên bán hàng | Bán hàng; xem tồn | `SG-01` (checkout đã chuyển XREF-01) | Đưa tìm/quét sản phẩm và checkout lên trước; không hiện giá vốn hoặc công việc kho. |
| Nhân viên xử lý đơn | Xem đơn cần lấy; bàn giao; xử lý thiếu | `SG-06`, `SG-04` | Mở danh sách việc theo trạng thái; không yêu cầu chọn kho. |
| Thủ kho | Nhận hàng; kiểm kê; xử lý hàng; xem lịch sử | `SG-02`, `SG-09`, `SG-08`, `SG-11` | Ưu tiên scan/quantity và worklist đang chờ. |
| Kế toán | Chốt giá nhận; tính/công bố giá vốn; đối soát | `SG-03`, `SG-14`, `SG-15` (margin đã chuyển XREF-05) | Chỉ hiện trường tài chính khi có quyền; blocker và bằng chứng đi trước CTA. |
| Người phê duyệt | Việc chờ quyết định | `SG-10`, `SG-09`, `SG-13` | Chỉ hiện case đang đủ điều kiện và trong scope; maker–checker vẫn do server kiểm. |
| Chủ cửa hàng/quản trị | Tổng quan tồn; chính sách; định giá | `SG-01`, `SG-12` (pricing đã chuyển XREF-02…04) | Tóm tắt theo quyết định cần làm; drill-down tới bằng chứng. |

Một người có nhiều vai trò thấy hợp của các công việc được phép, không thấy các mục rỗng hoặc capability tương lai. Deep link vẫn kiểm lại quyền và scope trên máy chủ.

### 2.2 Hợp đồng tiết kiệm thao tác

1. Tự điền `store_id`, `warehouse_id`, source identity/version và dữ liệu master đã biết; hiển thị dạng đọc-only ở bước rà soát khi cần đối chiếu.
2. Chỉ hiện trường phụ thuộc policy: `NONE` không có block lô; `LOT` mới có lô; expiry chỉ bắt buộc khi `expiry_required=true`.
3. FEFO/FIFO là đề xuất; override chỉ hiện cho người có quyền, bắt buộc lý do khi hợp đồng yêu cầu và luôn được server revalidate.
4. Chỉ mở confirmation riêng cho hành động không thể đảo, thay đổi tồn/giá trị hoặc có mức rủi ro cần phê duyệt. Save draft, search và filter không bị thêm modal xác nhận.
5. Validation giữ dữ liệu đã nhập và đặt focus vào lỗi đầu tiên; conflict tải dữ liệu hiện hành để so sánh, không ghi đè âm thầm.

### 2.3 Hợp đồng từ ngữ và phục hồi

- Tên công việc, trạng thái và thông báo chính dùng thuật ngữ tiếng Việt trong glossary. Stable ID, enum, error code và correlation ID chỉ hiện trong vùng “Chi tiết hỗ trợ” có thể sao chép.
- Mọi result panel có ba phần cố định: **Điều vừa xảy ra**, **Tác động đến dữ liệu**, **Bạn có thể làm tiếp**.
- `effect_status=NONE` không được viết như đã ghi nhận; `COMMITTED` phải cho ID/thời điểm nếu có; `UNKNOWN` nói rõ chưa xác định và giữ cùng identity.
- CTA tiếp theo chỉ render từ `allowed_next_actions` sau khi client đối chiếu Action Catalog; action lạ hoặc không được phép bị bỏ qua và ghi telemetry hợp đồng.

## 3. Shared layout patterns

| ID | Pattern | Dùng cho | Thành phần bắt buộc |
|---|---|---|---|
| `LYT-01` | Searchable list + detail drawer | Tồn, operation, reservation, return | Filter, result count, as-of, row status, detail trace |
| `LYT-02` | Workbench | Valuation, cost close, reconciliation, pricing review | Scope, blocker/status summary, data grid, evidence panel, primary action |
| `LYT-03` | Guided wizard | Receipt, opening balance, stock count | Progress, validation summary, save draft, review, final confirm |
| `LYT-04` | Transaction workspace | POS, fulfillment, return, disposal | Scanning/input area, running totals, guard feedback, confirm action |
| `LYT-05` | Dashboard/card list | Low stock, trust status, summary | Metric definitions, as-of, drill-down, permission-aware values |
| `LYT-06` | Timeline/detail | Operation, correction chain, lot, movement | Immutable events, actor/time/source, linked records |

## 4. Shared UI states

Mỗi Screen Group kế thừa các state sau; Screen Contract chỉ bổ sung state riêng.

| State ID | Hiển thị | Hành vi |
|---|---|---|
| `UI-S-01 LOADING` | Skeleton giữ layout, aria-busy | Không hiển thị số 0 giả |
| `UI-S-02 EMPTY` | Lý do rỗng + CTA hợp lệ | Phân biệt no-data với no-permission/filter |
| `UI-S-03 READY` | Dữ liệu + as-of/version | Action theo permission/status |
| `UI-S-04 VALIDATION_ERROR` | Giải thích tiếng Việt + summary + inline field messages; mã ở chi tiết hỗ trợ | Tác động `NONE`; focus lỗi đầu; giữ dữ liệu nhập |
| `UI-S-05 SUBMITTING` | Disable duplicate submit, progress | Request ID giữ ổn định |
| `UI-S-06 SUCCESS` | Điều đã xảy ra + tác động `COMMITTED`/`NONE` + ID/status/timestamp | Chỉ hiện next task được phép |
| `UI-S-07 CONFLICT` | Current vs attempted version + tác động `NONE` | Refresh/review; giữ input và không auto overwrite |
| `UI-S-08 PERMISSION_DENIED` | Giải thích quyền/scope | Không lộ field protected |
| `UI-S-09 LOCKED` | Lock owner/type/scope nếu được phép thấy + tác động `NONE` | Không cho mutation; link work item nếu được quyền |
| `UI-S-10 UNKNOWN` | “Chưa xác định kết quả” + tác động `UNKNOWN` + operation ID | Query/reconcile cùng ID; giữ input; không retry bằng ID mới |
| `UI-S-11 STALE` | As-of cũ và cảnh báo | Không dùng dữ liệu stale để confirm mutation |
| `UI-S-12 CAPABILITY_UNAVAILABLE` | Structured error, không có form giả | Không mutation/không future entity |

## 5. Screen Group map

| SG ID | Tên | Layout | Journey | Primary users |
|---|---|---|---|---|
| `SG-01` | Tồn kho và khả dụng | `LYT-01` | `BJ-01` | Bán hàng, thủ kho, chủ cửa hàng |
| `SG-02` | Nhận hàng | `LYT-03/04` | `BJ-02` | Thủ kho, người phê duyệt |
| `SG-03` | Hàng chờ giá | `LYT-02` | `BJ-03`, `BJ-13`, `BJ-14` | Kế toán |
| `SG-04` | Reservation và thiếu hàng | `LYT-01` | `BJ-04` | Xử lý đơn, quản lý |
| `SG-06` | Pick/pack/handover | `LYT-04` | `BJ-05` | Nhân viên xử lý đơn |
| `SG-07` | Khách trả và phân loại | `LYT-03/04` | `BJ-06` | Thủ kho |
| `SG-08` | Trạng thái, RTV và tiêu hủy | `LYT-01/04` | `BJ-07`, `BJ-09`, `BJ-10` | Thủ kho, người duyệt |
| `SG-09` | Kiểm kê | `LYT-03/02` | `BJ-08` | Người kiểm, người duyệt |
| `SG-10` | Operation, approval và correction | `LYT-01/06` | `BJ-11` + cross-cutting | Vận hành, approver |
| `SG-11` | Thẻ kho và lịch sử | `LYT-01/06` | `BJ-01`, `BJ-15` | Thủ kho, kế toán |
| `SG-12` | Chính sách tồn sản phẩm và chỉ báo | `LYT-05/01` | `CAP-01`, `BJ-01`, `BJ-04` | Chủ cửa hàng |
| `SG-13` | Opening balance/Chuyển đổi chính thức | `LYT-03/02` | `BJ-12` | Migration team, approver |
| `SG-14` | Cost calculation/period close | `LYT-02` | `BJ-14` | Kế toán |
| `SG-15` | Trust, UNKNOWN và reconciliation | `LYT-02/06` | `BJ-16`, `BJ-17`, `PROC-01` | Ops admin, kế toán |

## 6. Action catalog — mỗi action một primary BC

| Action ID | Nhãn hành động | Primary BC | Screen |
|---|---|---|---|
| `ACT-01-REFRESH` | Làm mới tồn | `BC-IO-01` | `SG-01` |
| `ACT-02-SAVE-DRAFT` | Lưu bản nháp nhận hàng | `BC-IO-16` | `SG-02` |
| `ACT-02-SUBMIT` | Gửi hồ sơ nhận hàng | `BC-IC-07` | `SG-02` |
| `ACT-02-DECIDE` | Quyết định phê duyệt yêu cầu nhận hàng | `BC-IC-06` | `SG-02` |
| `ACT-02-RECEIVE` | Ghi nhận hàng vào tồn vật lý | `BC-IO-02` | `SG-02` |
| `ACT-03-CONFIRM-COST` | Xác nhận giá và đưa vào bán | `BC-IV-01` | `SG-03` |
| `ACT-03-RECORD-LATE-COST` | Ghi chi phí mua bổ sung | `BC-IV-04` | `SG-03` |
| `ACT-04-RESERVE` | Giữ hàng | `BC-IO-03` | `SG-04` |
| `ACT-04-RELEASE` | Giải phóng/phân bổ lại | `BC-IO-06` | `SG-04` |
| `ACT-06-HANDOVER` | Xác nhận bàn giao | `BC-IO-05` | `SG-06` |
| `ACT-06-SAVE-PICK` | Lưu phân bổ pick | `BC-IO-15` | `SG-06` |
| `ACT-07-RECEIVE-RETURN` | Nhận hàng khách trả | `BC-IO-07` | `SG-07` |
| `ACT-07-CLASSIFY` | Xác nhận phân loại | `BC-IO-08` | `SG-07` |
| `ACT-08-RTV` | Bàn giao trả nhà cung cấp | `BC-IO-09` | `SG-08` |
| `ACT-08-STATE` | Chuyển trạng thái | `BC-IO-10` | `SG-08` |
| `ACT-08-DISPOSE` | Xác nhận tiêu hủy | `BC-IO-11` | `SG-08` |
| `ACT-09-OPEN` | Mở phiên kiểm kê | `BC-IC-01` | `SG-09` |
| `ACT-09-SUBMIT` | Nộp kết quả/đếm lại | `BC-IC-02` | `SG-09` |
| `ACT-09-APPROVE` | Duyệt và điều chỉnh | `BC-IC-03` | `SG-09` |
| `ACT-09-CANCEL` | Hủy phiên kiểm kê | `BC-IC-08` | `SG-09` |
| `ACT-10-CANCEL` | Hủy operation | `BC-IO-12` | `SG-10` |
| `ACT-10-CORRECT` | Tạo reversal/correction | `BC-IO-13` | `SG-10` |
| `ACT-10-DECIDE` | Duyệt/Từ chối | `BC-IC-06` | `SG-10` |
| `ACT-10-SAVE-DRAFT` | Lưu nháp operation | `BC-IO-16` | `SG-10` |
| `ACT-10-SUBMIT` | Gửi operation | `BC-IC-07` | `SG-10` |
| `ACT-11-EXPORT` | Xuất báo cáo | `BC-IO-01` | `SG-11` |
| `ACT-12-REFRESH` | Tính lại gợi ý | `BC-IO-14` | `SG-12` |
| `ACT-12-CONFIGURE` | Lưu chính sách tồn sản phẩm | `BC-XD-05` | `SG-12` |
| `ACT-13-COMMIT` | Xác nhận batch đầu kỳ | `BC-IC-04` | `SG-13` |
| `ACT-13-PREPARE` | Nạp và kiểm tra batch đầu kỳ | `BC-IC-09` | `SG-13` |
| `ACT-14-CALCULATE` | Tính giá vốn | `BC-IV-02` | `SG-14` |
| `ACT-14-PUBLISH` | Công bố batch giá vốn | `BC-IV-03` | `SG-14` |
| `ACT-15-RECONCILE` | Đối soát/rebuild | `BC-IC-05` | `SG-15` |

## 7. Screen Contracts

### SG-01 — Tồn kho và khả dụng

| Mục | Yêu cầu |
|---|---|
| Mục đích | Tìm sản phẩm, thấy physical/eligible/reserved/available và drill-down lô/trạng thái. |
| Dữ liệu tối thiểu | Product, base UOM, quantities, status, lot/expiry, as-of/sequence; cost/value only with permission. |
| State riêng | `LOT_EXPIRING_WARN`, `LOT_EXPIRING_BLOCKED`, `EXPIRED`, `VALUATION_PENDING`, `FINANCIAL_MASKED`. |
| Action | `ACT-01-REFRESH`; link `SG-11` thẻ kho. |
| Mobile | Search sticky, quantity summary first; detail drawer thành full-screen sheet. |

### SG-02 — Nhận hàng

| Mục | Yêu cầu |
|---|---|
| Mục đích | Chọn nhận theo chứng từ hoặc nhập nhanh; ghi nhận sản phẩm, lượng, lô/hạn và tình trạng thực nhận; xử lý duyệt/đối soát. |
| Dữ liệu tối thiểu | Source/version khi có; supplier, product, warehouse, actual/rejected/classified quantity, UOM snapshot, ownership assertion và lot policy. |
| Logic form | Hai lối chuẩn bị chạy song song. Prefill context/UOM đã biết. `NONE` không render lô/hạn; `LOT` bắt buộc mã lô và yêu cầu hạn theo policy; một dòng có thể chia nhiều lô/trạng thái. |
| State riêng | `PARTIAL_RECEIPT`, `LOT_CONFLICT`, `PENDING_APPROVAL`, `VALUATION_PENDING_RESULT`, `COMMIT_UNKNOWN`. |
| Action | Lưu nháp → gửi xử lý. Nhập nhanh luôn chuyển sang chờ phê duyệt; nhận theo chứng từ chỉ chờ duyệt khi có ngoại lệ. Sau quyết định hợp lệ hoặc nhánh chứng từ không cần duyệt mới ghi nhận tồn vật lý; không lặp mutation khi kết quả chưa rõ. |

### SG-03 — Hàng chờ giá

| Mục | Yêu cầu |
|---|---|
| Mục đích | Review receipt evidence và xác nhận direct cost/release. |
| Dữ liệu tối thiểu | Receipt/lot/quantity/age, price evidence/source/version, tax treatment, proposed direct cost, impact. |
| State riêng | `EVIDENCE_MISSING`, `ALREADY_CONFIRMED`, `EXPIRED_NOT_RELEASABLE`. |
| Action | `ACT-03-CONFIRM-COST`; `ACT-03-RECORD-LATE-COST` mở flow riêng và không công bố giá vốn; final confirmation lists value movement/source period. |
| Permission | Screen hidden or financial fields masked without finance permission. |

### SG-04 — Reservation và thiếu hàng

| Mục | Yêu cầu |
|---|---|
| Mục đích | Quan sát/điều khiển reservation và phần thiếu theo source order. |
| Dữ liệu tối thiểu | Order line/version, requested/reserved/short, expiry, components for combo. |
| State riêng | `FULL`, `PARTIAL`, `SHORT`, `EXPIRED_RESERVATION`, `REALLOCATION_REQUIRED`. |
| Action | `ACT-04-RESERVE`, `ACT-04-RELEASE`; không warehouse selector. |
| Conflict | Version conflict hiển thị source current và yêu cầu refresh. |

### SG-06 — Pick/pack/handover

| Mục | Yêu cầu |
|---|---|
| Mục đích | Pick theo reservation, gắn lô, xác nhận bàn giao. |
| Dữ liệu tối thiểu | Order/reservation, allocation set/version/lines, pick quantity, suggested/selected lot, expiry, handover recipient/time. |
| State riêng | `PICKED_NOT_ISSUED`, `ALLOCATION_VERSION_CONFLICT`, `ALLOCATION_ALREADY_CONSUMED`, `LOT_BECAME_INELIGIBLE`, `PARTIAL_FULFILLMENT`. |
| Action | `ACT-06-SAVE-PICK` compare-and-swap allocation version nhưng không giảm tồn; `ACT-06-HANDOVER` chỉ nhận active version và là primary inventory mutation. |
| Safety | Copy phải nói rõ “Bàn giao sẽ giảm tồn”, không gọi pick là xuất. |

### SG-07 — Khách trả và phân loại

| Mục | Yêu cầu |
|---|---|
| Mục đích | Nhận vật lý theo original issue rồi phân loại riêng. |
| Dữ liệu tối thiểu | Delivered/previously returned/remaining cap; combo component/issue/value basis; actual lot; receipt evidence; classification totals. |
| State riêng | `RETURN_CAP_EXCEEDED`, `COMBO_COMPONENT_MISMATCH`, `LOT_MISMATCH`, `PENDING_CLASSIFICATION`, `CLASSIFICATION_TOTAL_MISMATCH`. |
| Action | `ACT-07-RECEIVE-RETURN` và `ACT-07-CLASSIFY` là hai mốc tách biệt. |

### SG-08 — Trạng thái, RTV và tiêu hủy

| Mục | Yêu cầu |
|---|---|
| Mục đích | Quản lý non-sellable/demo, approved supplier return và disposal. |
| Dữ liệu tối thiểu | Product/lot/state/quantity, reason/evidence, risk value if permitted, handover/disposal confirmation. |
| State riêng | `RTV_PENDING`, `DEMO`, `DAMAGED`, `EXPIRED`, `APPROVAL_REQUIRED`. |
| Action | `ACT-08-RTV`, `ACT-08-STATE`, `ACT-08-DISPOSE`; mỗi dialog chỉ submit một action. |

### SG-09 — Kiểm kê

| Mục | Yêu cầu |
|---|---|
| Mục đích | Chọn scope, khóa, đếm mù, recount và duyệt adjustment. |
| Dữ liệu tối thiểu | Scope/cut-off/hash, count lines, first/recount, variance/risk after submit, lock status. |
| State riêng | `BLIND_COUNT`, `RECOUNT_REQUIRED`, `PENDING_APPROVAL`, `LOCK_LOST`, `COMPLETED/CANCELLED`. |
| Action | `ACT-09-OPEN`, `ACT-09-SUBMIT`, `ACT-09-APPROVE`, `ACT-09-CANCEL`; book quantity không có trong DOM trước submit; cancel bắt buộc reason. |

### SG-10 — Operation, approval và correction

| Mục | Yêu cầu |
|---|---|
| Mục đích | Theo dõi unified state, source/payload hash, approval, reason, movement và correction chain. |
| Dữ liệu tối thiểu | Operation status/timeline, source/version/request, lines, approval snapshot/decisions, linked operations, events. |
| State riêng | Mọi operation status, nhất là `UNKNOWN`, terminal rejection và cancellation eligibility. |
| Action | `ACT-10-SAVE-DRAFT`, `ACT-10-SUBMIT`, `ACT-10-CANCEL`, `ACT-10-CORRECT`, `ACT-10-DECIDE`; draft update dùng version, submit khóa payload; CTA theo state/permission. |

### SG-11 — Thẻ kho và lịch sử

| Mục | Yêu cầu |
|---|---|
| Mục đích | Reconcile opening + movement = closing và trace về nguồn. |
| Dữ liệu tối thiểu | Cut-off, date view mode, product/lot/state, movement delta/running balance, operation/source/actor. |
| State riêng | `RECORDED_DATE_VIEW`, `BUSINESS_DATE_VIEW`, `ARCHIVED_DATA`, `EXPORT_RUNNING`. |
| Action | Query/export `ACT-11-EXPORT`; export ghi filter/timezone/as-of/view mode. |

### SG-12 — Chính sách tồn sản phẩm và chỉ báo

| Mục | Yêu cầu |
|---|---|
| Mục đích | Xem available/threshold/target/gợi ý và cấu hình cận hạn theo product override hoặc tenant default. |
| Dữ liệu tối thiểu | Product/base UOM, available/as-of, threshold, target, suggestion; near-expiry days/action/source/default/override. |
| State riêng | `NOT_CONFIGURED`, `OUT_OF_STOCK`, `LOW_STOCK`, `NORMAL`, `NEAR_EXPIRY_WARN`, `NEAR_EXPIRY_BLOCKED`. |
| Action | `ACT-12-CONFIGURE`, `ACT-12-REFRESH`; link sang miền mua nếu có, không “Tạo đề xuất”. |
| Copy | Tooltip phân biệt threshold/target và chỉ báo cận hạn; cho biết policy lấy từ mặc định hay ghi đè và `BLOCK_SALE` loại lượng khỏi khả dụng. |

### SG-13 — Opening balance/Chuyển đổi chính thức

| Mục | Yêu cầu |
|---|---|
| Mục đích | Upload/validate/review/approve/commit batch và xem immutable report. |
| Dữ liệu tối thiểu | File/hash, line validation, control totals, maker/approver, cut-off/lock, activation status, report hash. |
| State riêng | `PREPARING`, `VALIDATION_FAILED`, `PENDING_APPROVAL`, `READY_TO_COMMIT`, `COMMIT_UNKNOWN`, `ACTIVE/RECONCILED`. |
| Action | `ACT-13-PREPARE` nạp/validate và gửi duyệt nhưng không ghi ledger; `ACT-13-COMMIT` chỉ hiện sau approval/control totals/hash pass. |

### SG-14 — Cost calculation/period close

| Mục | Yêu cầu |
|---|---|
| Mục đích | Chọn kỳ/scope, xem blockers, so hai phương pháp, review adjustment và publish. |
| Dữ liệu tối thiểu | Cut-off/input hash, blockers, two method results, selected policy, COGS/ending adjustments, new cost. |
| State riêng | `CALCULATING`, `BLOCKED`, `READY_FOR_REVIEW`, `PUBLISHING`, `PUBLISHED`. |
| Action | `ACT-14-CALCULATE`, `ACT-14-PUBLISH`; publish confirmation nói rõ không sửa giao dịch gốc. |

### SG-15 — Trust, UNKNOWN và reconciliation

| Mục | Yêu cầu |
|---|---|
| Mục đích | Triage UNKNOWN/outbox/source/projection mismatch và chạy evidence-based resolution. |
| Dữ liệu tối thiểu | Case/scope/lock, expected/actual, ledger/event IDs, evidence, rebuild result/hash. |
| State riêng | `INVESTIGATING`, `INSUFFICIENT_EVIDENCE`, `REBUILDING`, `VALIDATION_FAILED`, `RESOLVED`. |
| Action | `ACT-15-RECONCILE`; không có “Sửa kết quả” hoặc “Set balance”. |

## 8. Low-fi → HTML prototype contract

### 8.1 Deliverable tối thiểu

Mỗi prototype Screen Group phải có:

- Đủ toàn bộ Screen của SG theo luồng chính thức đã rà soát tại Part 02; không dùng một màn hình tổng hợp thay cho cả hành trình.
- Mỗi Screen có route, stable `SCR-xx-yy`, tên người dùng nhìn thấy **trước khi chọn** và đủ State áp dụng trong UI Contract.
- Route/trace chứa Screen Group ID, Screen ID và State ID.
- Action có `data-action-id="ACT-..."` và `data-primary-bc-id="BC-..."`.
- Fixtures cho READY, EMPTY, VALIDATION_ERROR, CONFLICT, PERMISSION_DENIED, LOCKED, UNKNOWN và state đặc thù.
- Chuyển trạng thái tương tác được; không cần backend thật ở vòng kiểm chứng flow.
- Mobile-first với viewport thiết kế tham chiếu 390 px, test đến 360 px và có responsive desktop.
- Phân tách rõ `[data-prototype-only]` (bộ điều khiển), `[data-design-viewport]` (màn hình sản phẩm kỳ vọng) và `[data-trace-only]` (review/truy vết); chỉ vùng design viewport được đưa sang Figma.
- Keyboard order, visible focus, label/error association và dialog focus trap.
- Không đưa visual decision chưa có token; ưu tiên cấu trúc và hành vi.

### 8.2 Prototype test checklist

1. Người dùng hoàn tất happy path không gặp ngõ cụt.
2. Back/cancel không mất dữ liệu ngoài dự kiến.
3. Double click không gửi hai request ID.
4. UNKNOWN không bị hiểu là fail/success.
5. Permission masking không lộ giá qua detail, tooltip hoặc export preview.
6. `NONE/LOT/expiry_required` thay đổi đúng field/state.
7. Capability ngoài scope không có navigation/action ẩn.
8. Action ID và BC ID khớp catalog 100%.
9. Mỗi vai trò vào đúng công việc mà không phải hiểu Screen Group/domain; deep link trái quyền bị chặn.
10. Source/context được prefill, trường lô/hạn mở đúng điều kiện và không có confirmation thừa cho thao tác có thể đảo.
11. READY/SUCCESS/ERROR/CONFLICT/LOCKED/UNKNOWN đều hiển thị điều xảy ra, tác động và next actions; mã kỹ thuật chỉ ở chi tiết hỗ trợ.
12. Catalog tự động chứng minh 17/17 SG, toàn bộ Screen và toàn bộ Screen–State fixture có thể chọn; controller không bị hiểu nhầm là UI sản phẩm.

## 9. HTML prototype → Figma contract

- Figma frame/component property giữ Screen Group/Action/State ID trong tên hoặc description.
- HTML chứng minh flow/state; Figma chuẩn hóa visual hierarchy, spacing, component variants, responsive rules và content density.
- Mỗi shared state trở thành component/variant dùng chung; không vẽ lại riêng cho từng screen.
- Không xóa state chỉ vì chưa có trong happy-path screenshot.
- Khi Figma thay đổi flow/action semantics, phải quay lại cập nhật Screen Contract và HTML; Figma không tự thay BC.
- Handoff engineering gồm Figma node/frame reference + HTML route + Screen Group ID + Action IDs, không chỉ ảnh.

## 10. UI quality gates

1. 17/17 Screen Group có purpose, data, state và action mapping.
2. 38/38 Action ID duy nhất; mỗi action có đúng một primary BC.
3. 12 shared states được triển khai/tái sử dụng, không copy prose khác nghĩa.
4. Không có future capability trong navigation, DOM fixture hoặc Figma frame Phase 1.
5. Financial masking được test ở list/detail/export.
6. HTML prototype pass keyboard/mobile/state tests trước khi chuyển Figma fidelity.
7. Stable IDs không đổi giữa SRS, HTML, Figma, implementation và test automation.
8. Experience Map chỉ trỏ tới 17 Screen Group hiện có; không tạo navigation tới capability tương lai.
9. Mọi form chứng minh cơ chế prefill/progressive disclosure và mọi result state chứng minh recovery guidance trước khi handoff Figma.
10. [`../prototype/contracts/screen-catalog.json`](../../../../../design/legacy-contracts/screen-catalog.json) khớp 100% với 17 thư mục SG, 38 Action và prototype manifest; không có Screen/State/Action mồ côi.
11. Mỗi BJ có mapping UI hoặc `NO_UI`; SG dùng chung có purpose rõ và không bị sao chép theo UC/BJ.


## 11. Thẩm quyền trải nghiệm và chuẩn nội dung

<a id="experience-map-va-authority-giao-dien"></a>
### `EXPERIENCE_MAP_AUTHORITY` — Bản đồ trải nghiệm và thẩm quyền giao diện

Giao diện được tổ chức theo vai trò và công việc cần hoàn tất, không bắt người dùng hiểu trước cấu trúc miền hoặc danh mục Screen Group. Experience Map chỉ dẫn đến Screen Group, query và action hiện hữu theo quyền; không tạo entity, projection có thẩm quyền, trạng thái hoặc mutation mới.

- **Chủ trì:** BA Lead. **Phối hợp:** Product Designer.

<a id="quy-uoc-noi-dung-giao-dien"></a>
### `UI_CONTENT_STANDARD` — Quy ước nội dung giao diện

Nhãn, trạng thái, lỗi và hướng dẫn ưu tiên tiếng Việt nghiệp vụ qua từ điển dùng chung. Enum, stable ID và error code kỹ thuật giữ bất biến nhưng chỉ hiển thị như thông tin phụ khi hỗ trợ/đối soát; mã kỹ thuật không phải lời giải thích chính.

- **Chủ trì:** Product Designer. **Phối hợp:** BA Lead.

<a id="prefill-progressive-disclosure-va-confirmation"></a>
### `PROGRESSIVE_DISCLOSURE` — Điền sẵn, tiết lộ tăng dần và xác nhận

Mỗi luồng chỉ hỏi dữ liệu chưa có từ nguồn hoặc thực sự cần người dùng quyết định. Giao diện điền sẵn ngữ cảnh/chứng từ, ẩn ID kỹ thuật, chỉ hiện LOT/hạn dùng theo chính sách sản phẩm, đề xuất FEFO/FIFO và cho phép ghi đè theo quyền. Xác nhận riêng chỉ bắt buộc với hành động khó hoàn nguyên, ảnh hưởng tồn/giá trị hoặc rủi ro cao; mọi guard vẫn do máy chủ thực thi.

- **Chủ trì:** Product Designer. **Phối hợp:** BA Lead.


## 12. Bề mặt outbound tạm thời

`SG-05`, `SG-16`, `SG-17` đã rời active catalog/prototype Theme 7. Snapshot đầy đủ được giữ tại [`outbound/`](../../../../../../04.architecture/integrations/INT-01-cross-theme-outbound.md) để Theme 5, Theme 10, Theme 2 và Reporting/Analytics tiếp nhận; chúng không tạo FE scope canonical cho Theme 7 v4.1.0.

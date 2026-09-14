# Theme 5: Đơn hàng

> **Quyết định thay thế 2026-09-10 — checkout recovery:** không persist `CheckoutAttempt` / `checkout_attempts`. Checkout và phục hồi sau timeout dùng `sales.idempotency_records` scope `finalize_sales_order`, query `GetCheckoutResultQuery(storeId, idempotencyKey)` và RPC `sales.get_checkout_result`. Kết quả dùng `idempotencyKey`, không dùng `checkoutAttemptId`; đơn không có `checkout_attempt_id`. Những mô tả attempt persisted và quan hệ ER phía dưới là thiết kế lịch sử, được thay thế bởi [contract S13 hiện hành](harness/07-api-contracts.md#check-out). Request envelope trong UI vẫn được giữ trong bộ nhớ để retry cùng key/payload. Quyết định này không thay đổi các nghiệp vụ khác.

# 0\. Thuật ngữ BA \(Readme\)

[BA terms](https://hamsacorp.sg.larksuite.com/wiki/UJvHwnEIIiInXzkVon4ldhDmgvh)

# 1\. Theme Overview

## 1\.1 Purpose

Theme 05 — Bán hàng \& Đơn hàng mô tả toàn bộ nghiệp vụ bán hàng trong VET45, từ lúc người bán bắt đầu lập đơn tại quầy cho đến khi đơn được thanh toán, hoàn tất, phát sinh phiếu bán hàng nội bộ, được tra cứu lại và được xử lý sau bán như hủy, điều chỉnh, đổi hàng hoặc trả hàng\.

Theme này đóng vai trò là lớp giao dịch trung tâm của hệ thống\. Dữ liệu phát sinh từ Theme 05 là nguồn đầu vào quan trọng cho:

- Pricing: xác định giá riêng áp dụng cho khách hàng cụ thể, sản phẩm cụ thể và đơn vị tính cụ thể của sản phẩm đó \("nhớ giá"\)\.

- Inventory: ghi nhận bán ra, trả hàng, đổi hàng và reverse/adjust tồn kho\.

- Receivable: ghi nhận công nợ, thanh toán thiếu, cấn trừ hoặc điều chỉnh công nợ sau bán\.

- Reporting: tổng hợp doanh thu, sản phẩm bán, trạng thái đơn, trạng thái thanh toán và dữ liệu đổi/trả\.

- Hoá đơn điện tử: phát hành hoá đơn điện tử theo quy định về tuân thủ kế toán\.

Theme 05 không chỉ là POS screen\. Theme này cần đảm bảo dữ liệu giao dịch có tính audit, có snapshot, có lifecycle rõ ràng và không bị thay đổi sai khi xử lý sau bán\.

## 1\.2 Business context

Trong vận hành bán lẻ, đặc biệt với cửa hàng thuốc thú y, vật tư và sản phẩm có nhiều mức giá, người bán cần xử lý nhanh tại quầy nhưng dữ liệu phía sau phải chính xác\.

Một giao dịch bán hàng thực tế thường gồm:

- Chọn hoặc tạo nhanh khách hàng\.

- Tìm/quét sản phẩm\.

- Thêm sản phẩm vào đơn\.

- Kiểm tra giá áp dụng\.

- Chỉnh số lượng, đơn vị bán hoặc chiết khấu nếu có quyền\.

- Ghi nhận thanh toán tiền mặt, chuyển khoản hoặc hiện thị khoản phải thu \(đưa vào công nợ\)

- Hoàn tất đơn\.

- In/xem/chia sẻ phiếu bán hàng nội bộ\.

- Tra cứu lại đơn\.

- Hủy, điều chỉnh, đổi hàng hoặc trả hàng nếu có phát sinh sau bán\.

Các nghiệp vụ sau bán không được làm mất dấu giao dịch gốc\. Đơn gốc cần được giữ lại bằng snapshot và audit, trong khi các thay đổi sau đó phải được ghi nhận bằng action/record riêng như cancellation, adjustment, return/exchange order, refund hoặc receivable adjustment; gọi chung là các bút toán điều chỉnh\.

## 1\.3 Scope

Theme 05 bao gồm:

- Bắt đầu phiên bán hàng tại quầy\.

- Tạo sales cart\.

- Chọn khách lẻ mặc định hoặc khách hàng cụ thể\.

- Tạo nhanh khách hàng trong lúc bán nếu có quyền\.

- Tìm/quét sản phẩm\.

- Thêm sản phẩm vào giỏ hàng\.

- Chỉnh số lượng, đơn vị bán, chiết khấu thủ công trong phạm vi quyền\.

- Hiển thị giá áp dụng preview trong lúc bán\.

- Gọi Theme 04 để validate giá tại checkout\.

- Gọi Theme 04 để kích hoạt giá nhớ\.

- Lưu snapshot sản phẩm, khách hàng, giá, chiết khấu và thanh toán tại thời điểm checkout\.

- Lưu và khôi phục đơn nháp\.

- Ghi nhận thanh toán tiền mặt\.

- Ghi nhận chuyển khoản thủ công\.

- Ghi nhận thanh toán đủ, thanh toán một phần hoặc chưa thanh toán theo quyền/policy\.

- Hoàn tất checkout và tạo sales order chính thức\.

- Hiển thị kết quả giao dịch\.

- Hiển thị phiếu bán hàng / hóa đơn hàng hàng nội bộ\.

- In hoặc chia sẻ phiếu bán hàng nếu thiết bị/policy hỗ trợ\.

- Tra cứu danh sách đơn hàng\.

- Xem chi tiết đơn hàng\.

- Xem lịch sử đơn hàng và lịch sử xử lý sau bán\. 

- Điều chỉnh thông tin đơn sau checkout trong phạm vi được phép\.

- Hủy đơn sau bán nếu đủ điều kiện\.

- Lập phiếu đổi/trả từ đơn đã bán\.

- Chọn hàng khách trả\.

- Chọn hàng đổi hoặc hàng mua thêm nếu có\.

- Tính chênh lệch đổi/trả\.

- Xử lý thu thêm, hoàn tiền hoặc cấn trừ công nợ\.

- Hiển thị phiếu đổi/trả nếu cần\.

- Phát sinh event/API input cho Inventory, Receivable, Reporting và các module liên quan\.

## 1\.4 Out of scope

Theme 05 không bao gồm:

- Quản lý hồ sơ sản phẩm gốc\.

- Quản lý SKU, barcode, đơn vị tính gốc\.

- Thiết lập giá bán mặc định\.

- Thiết lập giá riêng, nhớ giá, bảng giá hoặc chương trình khuyến mại\.

- Logic pricing engine, priority giá hoặc conflict policy\.

- Cấu hình thuế VAT chi tiết\.

- Phát hành hóa đơn điện tử\.

- Ký số, gửi cơ quan thuế, gửi hóa đơn điện tử cho khách hàng\.

- Điều chỉnh, thay thế hoặc hủy hóa đơn điện tử theo chuẩn thuế\.

- Hạch toán kế toán chi tiết\.

- Đối soát ngân hàng tự động\.

- Payment gateway, ví điện tử hoặc thanh toán online phức tạp\.

- Quản lý công nợ chi tiết sau bán\.

- Quản lý tồn kho chi tiết\.

- Báo cáo quản trị chuyên sâu\.

- Loyalty, tích điểm hoặc hoàn điểm\.

- Bảo hành/RMA phức tạp\.

- Workflow phê duyệt nhiều cấp cho hủy/đổi/trả\.

## 1\.5 Cross\-theme boundaries

||**Ngoài phạm vi của Theme 5**|**Trong phạm vi của Theme 5**|
|---|---|---|
|Theme 02<br>Product|- Hồ sơ sản phẩm\.<br>- SKU\.<br>- Barcode\.<br>- Đơn vị tính\.<br>- Trạng thái bán được/ngừng bán\.<br>- Thông tin master data của sản phẩm\.|- Tìm và chọn sản phẩm để bán\.<br>- Snapshot thông tin sản phẩm tại thời điểm bán\.<br>- Kiểm tra sản phẩm còn được bán theo contract của Theme 02\.<br>- Gửi tác động bán/đổi/trả sang Inventory nếu cần\.|
|Theme 03<br>Đối tác giao dịch|- Hồ sơ khách hàng\.<br>- Trạng thái khách hàng\.<br>- Thông tin liên hệ\.<br>- Điều kiện giao dịch cơ bản\.<br>|- Chọn khách hàng cho đơn hàng\.<br>- Tạo nhanh khách hàng tối thiểu nếu có quyền\.<br>- Snapshot thông tin khách hàng tại thời điểm bán\.<br>- Dùng customer context để gọi pricing, checkout và receivable\.|
|Theme 04<br>Giá bán|- Giá bán\.<br>- Giá riêng\.<br>- Nhớ giá\.<br>- Chương trình khuyến mại\.<br>- Mã ưu đãi nếu có\.<br>- Pricing priority\.<br>- Conflict policy\.|- Gọi pricing preview trong lúc lập đơn\.<br>- Gửi yêu cầu nhớ giá<br>- Gọi checkout pricing validation trước khi hoàn tất đơn\.<br>- Hiển thị giá áp dụng và nguồn giá ở mức cần thiết\.<br>- Lưu price snapshot\.<br>- Ghi nhận chiết khấu thủ công nếu user có quyền và policy cho phép\.<br>- Gửi intent/request nhớ giá sau checkout nếu flow có hỗ trợ\.|
|Theme 06<br>Công nợ|- Ledger công nợ\.<br>- Thu nợ sau bán\.<br>- Điều chỉnh công nợ\.<br>- Cấn trừ công nợ chi tiết\.<br>- Đối soát công nợ\.|- Phát sinh receivable input khi đơn hàng chưa thu đủ\.<br>- Phát sinh receivable adjustment khi hủy/đổi/trả làm thay đổi số tiền phải thu\.<br>- Hiển thị số còn phải thu ở mức giao dịch bán hàng\.|
|Theme 07<br>Kho|- Tồn kho\.<br>- Stock movement\.<br>- Reservation nếu có\.<br>- Xuất kho bán hàng\.<br>- Nhập lại hàng trả\.<br>- Reverse/adjust tồn kho\.|- Phát sinh order/return/exchange context\.<br>- Gửi event hoặc command để Inventory xử lý bán ra, hủy, trả hàng hoặc đổi hàng\.<br>- Hiển thị trạng thái pending/success/failure nếu Inventory integration trả về\.|
|Theme 08<br>Hoá đơn điện tử|- Kết nối nhà cung cấp; <br>- phát hành, ký số, gửi, điều chỉnh, thay thế hoặc hủy hóa đơn điện tử; <br>- quản lý authoritative e\-invoice lifecycle\.|- Cung cấp dữ liệu giao dịch đầu vào; hiển thị trạng thái/projection hóa đơn điện tử;<br>- cung cấp entry point hoặc handoff sang Theme 8 để phát hành, xem hoặc gửi hóa đơn khi người dùng có quyền\. Theme 5 không tự thay đổi authoritative e\-invoice\.|
|Theme 09<br>Báo cáo thuế|- To be updating|- Phát sinh dữ liệu giao dịch và event đủ tin cậy cho Reporting\.|
|Theme 10<br>Báo cáo quản trị|- Dashboard\.<br>- Aggregation\.<br>- Báo cáo doanh thu\.<br>- Báo cáo sản phẩm bán\.<br>- Báo cáo công nợ\.<br>- Báo cáo đổi/trả\.|- Phát sinh dữ liệu giao dịch và event đủ tin cậy cho Reporting\.<br>|

## 1\.6 Users \& roles

## 1\.7 Cross references

### 1\.7\.1 Related journeys

Theme 05 liên quan đến các journey:

- **\(S\) Operational setup**: cần sản phẩm, khách hàng, giá, quyền và phương thức thanh toán cơ bản trước khi bán\.

- **\(D\) Data onboarding**: dữ liệu sản phẩm, khách hàng, giá và tồn kho ban đầu ảnh hưởng trực tiếp đến khả năng bán\.

- **\(O\) Order\-to\-cash**: journey chính của Theme 05, từ lập đơn đến thanh toán, hoàn tất, công nợ và đối soát giao dịch\.

- **\(P\) Post\-sale operation**: xử lý hủy, điều chỉnh, đổi hàng, trả hàng, hoàn tiền và cấn trừ công nợ\.

- **\(C\) Management \& control**: tra cứu đơn, xem lịch sử, kiểm soát quyền, audit và theo dõi trạng thái sau bán\.

### 1\.7\.2 Related capability layers

Theme 05 liên quan đến các capability layer:

- **Vận hành**: bán hàng tại quầy, thanh toán, phiếu bán hàng, đổi/trả\.

- **Tuân thủ**: snapshot giao dịch, audit log, dữ liệu nền cho hóa đơn điện tử\.

- **Quản trị**: tra cứu đơn, trạng thái thanh toán, lịch sử, dữ liệu đổi/trả\.

- **Kiểm soát**: phân quyền giảm giá, bán ghi nợ, hủy đơn, hoàn tiền, đổi/trả\.

- **Hệ thống**: idempotency, stale update, event, integration, pending sync\.

### 1\.7\.3 Related AA / CAA

Các activation actions đề xuất:

- AA\-O01: Tạo phiên bán hàng đầu tiên\.

- AA\-O02: Thêm sản phẩm vào đơn hàng\.

- AA\-O03: Chọn hoặc tạo nhanh khách hàng khi bán\.

- AA\-O04: Hoàn tất thanh toán cho đơn hàng\.

- AA\-O05: Xem phiếu bán hàng nội bộ\.

- AA\-O06: Tra cứu lại đơn đã bán\.

- AA\-O07: Thực hiện hủy hoặc điều chỉnh đơn có kiểm soát\.

- AA\-O08: Thực hiện một nghiệp vụ đổi/trả từ đơn đã bán\.

Các CAA đề xuất cho kích hoạt vận hành:

- CAA\-O01: Hoàn tất ít nhất một đơn hàng hợp lệ\.

- CAA\-O02: Ghi nhận thanh toán cho đơn hàng\.

- CAA\-O03: Xem lại phiếu bán hàng hoặc chi tiết đơn sau checkout\.

Các CAA đề xuất cho vận hành thực sự:

- CAA\-M01: Tra cứu danh sách đơn theo ngày/khoảng thời gian\.

- CAA\-M02: Kiểm tra đơn chưa thu đủ hoặc có công nợ\.

- CAA\-M03: Thực hiện một action sau bán có audit, ví dụ hủy đơn hoặc đổi/trả\.

# 2\. Domain foundation

## 2\.1 Domain map

### 2\.1\.1 Overview

Theme 5 được tổ chức thành 4 business domains\. Các domain không được chia theo từng màn hình, Epic hoặc bước kỹ thuật, mà theo business responsibility và quyền sở hữu dữ liệu\.

|**Domain**|**Type**|**Aggregate root / ownership chính**|**Trách nhiệm cốt lõi**|**Dữ liệu tham chiếu**|
|---|---|---|---|---|
|**Sales Order Lifecycle**|Core domain|SalesOrderDraft, SalesOrder; CheckoutAttempt là process record<br>|Quản lý đơn đang lập, đơn nháp, checkout, commercial snapshot và lifecycle của đơn bán|Tenant, store, user, Partner, Product, ProductUnit, Pricing|
|**Sales Settlement**|Supporting domain|SalesOrderSettlement<br>|Quản lý khoản thu, hoàn tiền, số còn phải thu, payment status và receivable handoff|SalesOrder, Partner, payment method, Receivable|
|**Post\-sale Operations**|Supporting domain|OrderAdjustment, SalesOrderCancellation, ReturnExchangeOrder|Quản lý điều chỉnh được phép, hủy đơn, đổi/trả và xác định tác động sau bán|SalesOrder, SalesOrderSettlement, Inventory, Receivable, E\-invoice|
|**Sales Order Inquiry \& Documents**|Supporting / read domain|SalesReceipt nếu receipt được persisted; read models không phải transactional aggregate|Tra cứu đơn, timeline, trạng thái tổng hợp và phiếu bán hàng nội bộ|Toàn bộ authoritative records của ba domain còn lại|

Nguyên tắc phân loại:

- **Sales Order Lifecycle** là Core Domain của Theme 5\.

- **Sales Settlement** không sở hữu SalesOrder; domain này sở hữu trạng thái quyết toán tiền của đơn\.

- **Post\-sale Operations** không sửa trực tiếp giao dịch gốc; domain này tạo các hồ sơ nghiệp vụ sau bán và yêu cầu domain owner thực hiện thay đổi cần thiết\.

- **Sales Order Inquiry \& Documents** chỉ sở hữu read models và chứng từ nội bộ; không trở thành source of truth của giao dịch\.

- Operational context, idempotency, integration delivery, retry và audit không phải business domains\.

- Inventory, Receivable, E\-invoice, Pricing và Reporting là external domains có contract riêng với Theme 5\.

### 2\.1\.2 Domain tree

```YAML
Theme 5 — Sales & Orders
├── Domain 1 — Sales Order Lifecycle
│   ├── Type
│   │   └── Core Domain
│   ├── Aggregate — SalesOrderDraft
│   │   ├── Aggregate Root
│   │   │   └── SalesOrderDraft
│   │   ├── Entity con
│   │   │   └── SalesOrderDraftLine
│   │   └── Value Object / Snapshot
│   │       └── PricingPreview
│   ├── Aggregate — SalesOrder
│   │   ├── Aggregate Root
│   │   │   └── SalesOrder
│   │   ├── Entity con
│   │   │   └── SalesOrderLine
│   │   └── Value Object / Snapshot
│   │       ├── SalesContextSnapshot
│   │       ├── CustomerSnapshot
│   │       ├── BuyerTaxSnapshot
│   │       ├── MonetarySummary
│   │       ├── PricingSummarySnapshot
│   │       ├── ProductSnapshot
│   │       ├── ProductUnitSnapshot
│   │       ├── PricingSnapshot
│   │       └── TaxSnapshot
│   ├── Process Record
│   │   └── CheckoutAttempt
│   │       ├── RequestSnapshot
│   │       ├── ResultSnapshot
│   │       ├── BlockerCodes
│   │       └── FailureResult
│   ├── Runtime / Read Models
│   │   ├── SalesOrderWorkingState
│   │   ├── CheckoutResultView
│   │   └── SalesOrderDraftForRestoreView
│   ├── Commands
│   │   ├── SalesOrderDraft
│   │   │   ├── SaveSalesOrderDraft
│   │   │   ├── UpdateSalesOrderDraft
│   │   │   ├── CancelSalesOrderDraft
│   │   │   └── ExpireSalesOrderDraft
│   │   ├── Checkout
│   │   │   └── FinalizeSalesOrder
│   │   └── SalesOrder
│   │       ├── CancelSalesOrder
│   │       ├── LockSalesOrder
│   │       └── UnlockSalesOrder
│   ├── Queries
│   │   ├── GetSalesOrderDraftForRestore
│   │   ├── GetCheckoutAttemptStatus
│   │   └── GetSalesOrder
│   ├── Validation Operations
│   │   └── PrecheckSalesOrderCheckout
│   └── Events
│       ├── Domain Events
│       │   ├── SalesOrderDraftSaved
│       │   ├── SalesOrderDraftUpdated
│       │   ├── SalesOrderDraftCancelled
│       │   ├── SalesOrderDraftExpired
│       │   ├── SalesOrderDraftConverted
│       │   ├── SalesOrderFinalized
│       │   ├── SalesOrderCancelled
│       │   ├── SalesOrderLocked
│       │   └── SalesOrderUnlocked
│       └── Public Integration Events
│           ├── sales_order_finalized.v1
│           └── sales_order_cancelled.v1
├── Domain 2 — Sales Settlement
│   ├── Type
│   │   └── Supporting Domain
│   ├── Aggregate — SalesOrderSettlement
│   │   ├── Aggregate Root
│   │   │   └── SalesOrderSettlement
│   │   ├── Entity con
│   │   │   └── SalesPaymentTransaction
│   │   └── Value Object / Snapshot
│   │       ├── SettlementSummary
│   │       ├── PaymentMethodSnapshot
│   │       ├── PaymentAllocation
│   │       └── ReconciliationResult
│   ├── Process Record
│   │   └── Không có process record riêng
│   ├── Read Model
│   │   └── Không sở hữu read model độc lập
│   │       └── Dữ liệu được projected sang SalesOrderPaymentSummaryView
│   ├── Commands
│   │   ├── InitializeSalesOrderSettlement
│   │   ├── RecordSalesPayment
│   │   ├── VoidSalesPayment
│   │   ├── RecordSalesRefund
│   │   ├── ApplyReceivableCollection
│   │   └── ReconcileSalesSettlement
│   ├── Queries
│   │   ├── GetSalesOrderSettlement
│   │   ├── GetSalesOrderPaymentTransactions
│   │   └── GetSalesOrderPaymentSummary
│   └── Events
│       ├── Domain Events
│       │   ├── SalesOrderSettlementInitialized
│       │   ├── SalesPaymentRecorded
│       │   ├── SalesPaymentVoided
│       │   ├── SalesRefundRecorded
│       │   ├── SalesSettlementChanged
│       │   ├── SalesReceivableRequired
│       │   ├── SalesReceivableCleared
│       │   └── SalesSettlementReconciled
│       └── Public Integration Events
│           ├── sales_payment_recorded.v1
│           ├── sales_payment_voided.v1
│           ├── sales_refund_recorded.v1
│           └── sales_settlement_changed.v1
├── Domain 3 — Post-sale Operations
│   ├── Type
│   │   └── Supporting Domain
│   ├── Aggregate — OrderAdjustment
│   │   ├── Aggregate Root
│   │   │   └── OrderAdjustment
│   │   ├── Entity con
│   │   │   └── Không có
│   │   └── Value Object / Snapshot
│   │       ├── AdjustmentDiff
│   │       ├── BeforeValues
│   │       ├── AfterValues
│   │       └── BlockerSnapshot
│   ├── Aggregate — SalesOrderCancellation
│   │   ├── Aggregate Root
│   │   │   └── SalesOrderCancellation
│   │   ├── Entity con
│   │   │   └── Không có
│   │   └── Value Object / Snapshot
│   │       ├── CancellationPrecheckSnapshot
│   │       ├── RequiredImpactsSnapshot
│   │       └── CancellationBlockers
│   ├── Aggregate — ReturnExchangeOrder
│   │   ├── Aggregate Root
│   │   │   └── ReturnExchangeOrder
│   │   ├── Entity con
│   │   │   ├── ReturnExchangeLine
│   │   │   └── ReturnExchangeValuation
│   │   └── Value Object / Snapshot
│   │       ├── ReturnExchangeSummary
│   │       ├── ProductSnapshot
│   │       ├── ProductUnitSnapshot
│   │       ├── PricingSnapshot
│   │       ├── ValuationDetails
│   │       └── ReturnCondition
│   ├── Process Record
│   │   └── Không có process record riêng
│   │       └── Process lifecycle nằm trong từng post-sale aggregate
│   ├── Runtime / Read Models
│   │   ├── ReturnableOrderLineView
│   │   └── PostSaleResultView
│   ├── Commands
│   │   ├── OrderAdjustment
│   │   │   └── ApplyOrderAdjustment
│   │   ├── SalesOrderCancellation
│   │   │   ├── RequestSalesOrderCancellation
│   │   │   └── ConfirmSalesOrderCancellation
│   │   └── ReturnExchangeOrder
│   │       ├── StartReturnExchange
│   │       ├── UpdateReturnExchange
│   │       ├── ConfirmReturnExchange
│   │       ├── CancelReturnExchange
│   │       └── CompleteReturnExchange
│   ├── Queries
│   │   └── GetReturnableOrderLines
│   ├── Validation Operations
│   │   ├── PrecheckOrderAdjustment
│   │   ├── PrecheckSalesOrderCancellation
│   │   └── PrecheckReturnExchange
│   ├── Cross-domain Commands
│   │   ├── To Sales Order Lifecycle
│   │   │   └── CancelSalesOrder
│   │   ├── To Sales Settlement
│   │   │   ├── RecordSalesPayment
│   │   │   └── RecordSalesRefund
│   │   ├── To Theme 6 — Receivable
│   │   │   ├── PostSalesReceivable
│   │   │   ├── AdjustSalesReceivable
│   │   │   ├── ReverseSalesReceivable
│   │   │   └── ApplySalesReceivableOffset
│   │   ├── To Theme 7 — Inventory
│   │   │   ├── ReverseSalesInventoryImpact
│   │   │   ├── RegisterReturnedInventoryImpact
│   │   │   └── CommitExchangeInventoryImpact
│   │   └── To Theme 8 — E-invoice
│   │       ├── RequestSalesEInvoiceAdjustment
│   │       ├── RequestSalesEInvoiceReplacement
│   │       └── RequestSalesEInvoiceCancellation
│   └── Events
│       ├── Domain Events
│       │   ├── OrderAdjustmentApplied
│       │   ├── SalesOrderCancellationRequested
│       │   ├── SalesOrderCancellationConfirmed
│       │   ├── SalesOrderCancellationBlocked
│       │   ├── ReturnExchangeStarted
│       │   ├── ReturnExchangeConfirmed
│       │   ├── ReturnExchangeValued
│       │   ├── ReturnExchangeCancelled
│       │   └── ReturnExchangeCompleted
│       └── Public Integration Events
│           ├── order_adjustment_applied.v1
│           ├── return_exchange_confirmed.v1
│           └── return_exchange_completed.v1
├── Domain 4 — Sales Order Inquiry & Documents
│   ├── Type
│   │   └── Supporting / Read Domain
│   ├── Aggregate — SalesReceipt
│   │   ├── Aggregate Root
│   │   │   └── SalesReceipt
│   │   ├── Entity con
│   │   │   └── SalesReceiptActivity
│   │   └── Value Object / Snapshot
│   │       ├── ReceiptSnapshot
│   │       ├── ReceiptTemplateReference
│   │       ├── ReceiptContentHash
│   │       └── DistributionContext
│   ├── Process Record
│   │   └── Không có process record riêng
│   ├── Read Models
│   │   ├── SalesOrderListView
│   │   ├── SalesOrderDetailView
│   │   ├── SalesOrderTimelineView
│   │   ├── SalesOrderPaymentSummaryView
│   │   ├── SalesOrderReturnSummaryView
│   │   └── SalesOrderIntegrationStatusView
│   ├── Commands
│   │   ├── GenerateSalesReceipt
│   │   ├── RecordSalesReceiptPrinted
│   │   ├── RecordSalesReceiptShared
│   │   └── ArchiveSalesReceipt
│   ├── Queries
│   │   ├── ListSalesOrders
│   │   ├── SearchSalesOrders
│   │   ├── GetSalesOrderDetail
│   │   ├── GetSalesOrderTimeline
│   │   ├── GetSalesOrderPaymentSummary
│   │   ├── GetSalesOrderReturnSummary
│   │   ├── GetSalesReceipt
│   │   └── GetOrderIntegrationStatus
│   └── Events
│       ├── Domain Events
│       │   ├── SalesReceiptGenerated
│       │   ├── SalesReceiptPrinted
│       │   ├── SalesReceiptShared
│       │   └── SalesReceiptArchived
│       └── Public Integration Events
│           └── sales_receipt_generated.v1
│               └── Chỉ publish khi có consumer nghiệp vụ thực tế
└── Cross-cutting Foundations
    ├── Classification
    │   └── Không phải Business Domain
    ├── Technical / Process Records
    │   ├── IdempotencyRecord
    │   ├── IntegrationCommand
    │   ├── InventoryImpactRequest
    │   ├── ReceivableImpactRequest
    │   ├── EInvoiceImpactRequest
    │   ├── OutboxMessage
    │   └── InboxMessage
    ├── Value Object / Envelope
    │   ├── CorrelationContext
    │   ├── CausationContext
    │   ├── IdempotencyContext
    │   ├── CommandEnvelope
    │   ├── EventEnvelope
    │   ├── IntegrationPayload
    │   └── FailureResult
    ├── Technical Commands
    │   ├── CreateIntegrationCommand
    │   ├── RetryIntegrationCommand
    │   ├── RetryInventoryImpact
    │   ├── RetryReceivableImpact
    │   ├── RetryEInvoiceImpact
    │   └── ReconcileIntegrationResult
    ├── Technical Queries
    │   ├── GetIntegrationCommandStatus
    │   ├── GetImpactRequestStatus
    │   ├── GetIdempotencyResult
    │   └── GetReconciliationStatus
    └── Technical Events
        ├── IntegrationCommandQueued
        ├── IntegrationCommandSent
        ├── IntegrationCommandAcknowledged
        ├── IntegrationCommandFailed
        ├── IntegrationCommandDeadLettered
        ├── ImpactRequestAccepted
        ├── ImpactRequestRejected
        └── ReconciliationRequired
```

## 2\.2 Domain model overview

### 2\.2\.1 Business flow

Luồng nghiệp vụ tổng quát của Theme 5:

Đơn hàng đang lập
→ lưu đơn nháp nếu cần
→ checkout
→ tạo Sales Order chính thức
→ ghi nhận settlement và payment
→ tạo các downstream impacts
→ tra cứu và phát hành phiếu bán hàng
→ điều chỉnh, hủy hoặc đổi/trả nếu phát sinh sau bán

Mô hình khái niệm:

```Plaintext
Working State
    │
    ├── không lưu
    │     └── kết thúc phiên mà không tạo entity nghiệp vụ
    │
    └── Save Draft
          ↓
    SalesOrderDraft
          │
          └── FinalizeSalesOrder
                  ↓
            CheckoutAttempt
                  ↓
             SalesOrder
             └── SalesOrderLines
                  │
                  ├── SalesOrderSettlement
                  │     └── SalesPaymentTransactions
                  │
                  ├── SalesReceipt / Read Models
                  │
                  └── Post-sale Operations
                        ├── OrderAdjustment
                        ├── SalesOrderCancellation
                        └── ReturnExchangeOrder
                              └── ReturnExchangeLines
```

### 2\.2\.2 Aggregate ownership

Mỗi aggregate chỉ có một domain owner duy nhất\.

Domain owner là nơi duy nhất được phép:

- Tạo aggregate\.

- Thay đổi authoritative state\.

- Kiểm tra invariant\.

- Chấp nhận hoặc từ chối command\.

- Phát domain event sau khi cập nhật thành công\.

Các domain khác chỉ được:

- Đọc dữ liệu được phép\.

- Gửi command tới domain owner\.

- Nhận domain event hoặc business result\.

- Duy trì projection của riêng mình\.

Không domain nào được trực tiếp update bảng của domain khác, kể cả khi các bảng được triển khai trong cùng một database\.

|**Aggregate / dữ liệu**|**Authoritative domain owner**|
|---|---|
|SalesOrderDraft và draft lines|Sales Order Lifecycle|
|CheckoutAttempt|Sales Order Lifecycle|
|SalesOrder và commercial snapshot|Sales Order Lifecycle|
|SalesOrderSettlement và payment transactions|Sales Settlement|
|OrderAdjustment|Post\-sale Operations|
|SalesOrderCancellation|Post\-sale Operations|
|ReturnExchangeOrder và return/exchange lines|Post\-sale Operations|
|SalesReceipt|Sales Order Inquiry \& Documents|
|Order list/detail/timeline projection|Sales Order Inquiry \& Documents|
|Inventory ledger và stock movement|Theme 7|
|Receivable ledger|Theme 6|
|E\-invoice|Theme 8|
|Pricing result và applied promotion logic|Theme 4|

### 2\.2\.3 Commercial snapshot

SalesOrder phải bảo toàn dữ liệu giao dịch tại thời điểm checkout\.

Commercial snapshot tối thiểu gồm:

- Tenant và store/location\.

- Người bán và thời điểm giao dịch\.

- Customer snapshot nếu có khách hàng cụ thể\.

- Product và product unit snapshot\.

- Số lượng\.

- Đơn giá\.

- Discount và promotion snapshot\.

- Pricing source\.

- Thuế và rounding context\.

- Tổng giá trị giao dịch\.

Sau khi SalesOrder được tạo:

- Không lấy tên, đơn vị hoặc giá hiện tại để ghi đè dữ liệu lịch sử\.

- Không sửa SalesOrderLine như một dòng hàng đang lập\.

- Sai sản phẩm, số lượng hoặc giá trị phải xử lý bằng hủy, đổi/trả hoặc nghiệp vụ bù trừ phù hợp\.

- Payment, return và integration status không được trộn vào commercial snapshot bất biến\.

### 2\.2\.4 Authoritative state dimensions

Trạng thái của đơn phải được tách thành các dimension độc lập\.

|**Dimension**|**Owner**|**State chính**|
|---|---|---|
|Order lifecycle|Sales Order Lifecycle|completed, cancelled|
|Lock status|Sales Order Lifecycle|unlocked, locked|
|Payment status|Sales Settlement|unpaid, partially\_paid, paid, partially\_refunded, refunded|
|Return status|Post\-sale Operations|none, partially\_returned, fully\_returned|
|Adjustment indicator|Derived projection|no\_adjustment, has\_adjustments|
|Business integration status|Integration foundation|not\_required, pending, accepted, rejected, reconciliation\_required, reconciled|
|Delivery status|Integration foundation|created, queued, sent, acknowledged, failed, uncertain, dead\_letter|

Các status như `partially_paid`, `returned`, `locked` và `sync_failed` không được ghép vào một `order_status` duy nhất\.

Nếu các trạng thái tổng hợp được lưu trên `sales_orders` để tối ưu truy vấn, chúng chỉ là cached projections, không phải source of truth\.

### 2\.2\.5 Cross\-theme boundaries

- Theme 1 sở hữu tenant, store/location, user, role, permission và các cấu hình nền\.

- Theme 2 sở hữu Product, ProductUnit, SKU/barcode, trạng thái kinh doanh và dữ liệu sản phẩm hiện hành\.

- Theme 3 sở hữu Partner; Theme 5 chỉ tham chiếu customer\_partner\_id và lưu customer snapshot trên đơn\.

- Theme 4 sở hữu Pricing, giá riêng, nhớ giá, chương trình khuyến mại và pricing engine; Theme 5 lưu kết quả áp dụng dưới dạng snapshot\.

- Theme 6 sở hữu receivable ledger; Theme 5 xác định nghĩa vụ phải thu và gửi receivable impact\.

- Theme 7 sở hữu tồn kho, stock reservation, stock movement, cost layer và giá vốn\.

- Theme 8 sở hữu hóa đơn điện tử, phát hành, điều chỉnh, thay thế và hủy hóa đơn\.

- Theme 10 nhận event để xây dựng báo cáo và chỉ số quản trị\.

- Theme 12 quản lý các external integration không thuộc business domain của Theme 5\.

## 2\.3 Domains

### 2\.3\.1 Sales Order Lifecycle

**Purpose**

Quản lý vòng đời từ đơn hàng đang lập, đơn nháp và checkout đến SalesOrder chính thức; đồng thời bảo toàn commercial snapshot và kiểm soát lifecycle của giao dịch bán\.

**Ownership**

Sales Order Lifecycle sở hữu:

- SalesOrderDraft\.

- SalesOrderDraftLine\.

- CheckoutAttempt\.

- SalesOrder\.

- SalesOrderLine\.

- Order lifecycle status\.

- Order lock status\.

- Commercial snapshot\.

CheckoutAttempt là process record hỗ trợ validation, idempotency và uncertain\-result recovery; nó không phải chứng từ bán hàng\.

**Business rules**

- BR\-01: Dữ liệu đang nhập nhưng chưa lưu nháp và chưa checkout có thể chỉ là working state, chưa phải entity nghiệp vụ\.

- BR\-02: SalesOrderDraft chỉ được tạo khi người dùng chủ động lưu nháp\.

- BR\-03: Draft chưa tạo doanh thu, payment transaction, công nợ, stock movement, receipt chính thức hoặc yêu cầu hóa đơn điện tử\.

- BR\-04: Backend phải validate lại context, product, unit, customer, pricing, payment intent, permission và stale data tại checkout\.

- BR\-05: FinalizeSalesOrder phải có idempotency key và không được tạo nhiều SalesOrder từ cùng một business request\.

- BR\-06: Checkout thành công mới tạo SalesOrder và commercial snapshot chính thức\.

- BR\-07: Sau checkout, SalesOrder và SalesOrderLine không được sửa như đơn đang lập\.

**Invariants**

- SalesOrderDraft persisted phải có tenant\_id, trạng thái, người tạo, version và timestamps\.

- Draft line đã lưu phải tham chiếu product, product unit và quantity hợp lệ\.

- Một CheckoutAttempt chỉ được tạo tối đa một SalesOrder thành công\.

- SalesOrder phải có mã đơn duy nhất trong tenant\.

- SalesOrder phải có ít nhất một SalesOrderLine hợp lệ\.

- Tổng giá trị SalesOrder phải khớp với line values, discount, tax và rounding snapshot\.

- Commercial snapshot không bị ghi đè khi master data hiện hành thay đổi\.

**Lifecycle / state model**

SalesOrderDraft:

```Plaintext
active
├── converted
├── cancelled
└── expired
```

- Restore draft là hành động đọc và đưa dữ liệu trở lại working screen; `restored` không phải business state\.

- Draft đã converted, cancelled hoặc expired không được tiếp tục sửa như draft active\.

CheckoutAttempt:

```Plaintext
received
→ validating
→ processing
→ succeeded
```

Các nhánh thay thế:

```Plaintext
validating → blocked
processing → failed
processing → uncertain
uncertain → succeeded
uncertain → failed
```

SalesOrder lifecycle:

```Plaintext
completed → cancelled
```

Lock status:

```Plaintext
unlocked → locked
locked → unlocked
```

Unlock chỉ được phép khi policy và quyền đặc biệt cho phép\.

**Commands \& permissions**

|**Command**|**Purpose**|**Permission**|**Idempotency / concurrency**|
|---|---|---|---|
|SaveSalesOrderDraft|Lưu working state thành draft|sales\.draft\.create|Khuyến nghị idempotency|
|UpdateSalesOrderDraft|Cập nhật draft active|sales\.draft\.update|Bắt buộc expected\_version|
|CancelSalesOrderDraft|Hủy mềm draft|sales\.draft\.delete|Bắt buộc idempotency|
|ExpireSalesOrderDraft|Hết hạn draft theo policy|System/internal|Bắt buộc idempotency|
|FinalizeSalesOrder|Validate và tạo SalesOrder chính thức|sales\.checkout\.create|Bắt buộc idempotency|
|CancelSalesOrder|Chuyển lifecycle đơn sang cancelled|System/internal từ Post\-sale|Bắt buộc idempotency|
|LockSalesOrder|Khóa giao dịch theo policy kiểm soát|sales\.order\.lock|Bắt buộc idempotency|
|UnlockSalesOrder|Mở khóa giao dịch nếu được phép|sales\.order\.unlock|Bắt buộc idempotency|

**Queries / validation operations**

|**Operation**|**Purpose**|**Permission**|
|---|---|---|
|GetSalesOrderDraftForRestore|Tải draft để tiếp tục lập đơn|sales\.draft\.restore|
|PrecheckSalesOrderCheckout|Kiểm tra trước blockers và warnings|sales\.checkout\.create|
|GetCheckoutAttemptStatus|Kiểm tra kết quả khi timeout/uncertain|sales\.order\.view|
|GetSalesOrder|Đọc authoritative order record theo quyền|sales\.order\.view|

Precheck không thay thế validation trong FinalizeSalesOrder\. Command chính luôn phải validate lại dữ liệu hiện hành\.

**Domain events**

|**Event**|**Trigger**|
|---|---|
|SalesOrderDraftSaved|Draft được lưu lần đầu|
|SalesOrderDraftUpdated|Draft active được cập nhật|
|SalesOrderDraftCancelled|Draft bị hủy|
|SalesOrderDraftExpired|Draft hết hạn|
|SalesOrderDraftConverted|Draft được chuyển thành SalesOrder|
|SalesOrderFinalized|Checkout commit thành công|
|SalesOrderCancelled|Lifecycle của SalesOrder chuyển sang cancelled|
|SalesOrderLocked|SalesOrder được khóa|
|SalesOrderUnlocked|SalesOrder được mở khóa|

Các trạng thái như checkout blocked, failed hoặc uncertain là process results; không mặc định publish như public integration events\.

**API references**

- API\-SALES\-DRAFT\-\*

- API\-SALES\-CHECKOUT\-\*

- API\-SALES\-ORDER\-LIFECYCLE\-\*

- API\-SALES\-ORDER\-LOCK\-\*

- Chi tiết route, request, response và error contract được định nghĩa tại Appendix 6\.1\.

**Related entities**

- sales\_order\_drafts

- sales\_order\_draft\_lines

- checkout\_attempts

- sales\_orders

- sales\_order\_lines

- idempotency\_records

- tenants

- stores

- users

- partners

- products

- product\_units

- applied pricing / promotion snapshots

### 2\.3\.2 Sales Settlement

**Purpose**

Quản lý nghĩa vụ tiền của SalesOrder, bao gồm khoản thu, nhiều phương thức thanh toán, hoàn tiền, số còn phải thu, payment status và handoff sang Theme 6\.

**Ownership**

Sales Settlement sở hữu:

- SalesOrderSettlement\.

- SalesPaymentTransaction\.

- Payment/refund allocations\.

- Paid amount hiện tại\.

- Refunded amount hiện tại\.

- Outstanding amount hiện tại\.

- Payment status\.

- Receivable requirement phát sinh từ đơn\.

SalesOrderSettlement là logical aggregate root\. Physical entity tương ứng được xác định trong Section 3\.

**Business rules**

- BR\-01: Payment input trước checkout chỉ là intent; payment transaction chính thức chỉ được tạo khi command nghiệp vụ thành công\.

- BR\-02: Một SalesOrder có tối đa một SalesOrderSettlement authoritative\.

- BR\-03: Theme 5 có thể ghi nhận nhiều phương thức thanh toán trên cùng một đơn\.

- BR\-04: Bán thiếu chỉ được phép khi có customer\_partner\_id cụ thể và customer đáp ứng credit policy\.

- BR\-05: Khách lẻ không định danh không được phát sinh hoặc cấn trừ công nợ\.

- BR\-06: Thu thêm, refund hoặc void phải tạo transaction riêng; không sửa hoặc xóa payment gốc\.

- BR\-07: Theme 5 xác định receivable requirement nhưng không sở hữu receivable ledger\.

**Invariants**

- Mọi payment transaction phải có direction, amount, method, source context và status\.

- Amount của payment/refund phải lớn hơn 0\.

- Confirmed refund không được vượt giới hạn refundable theo policy\.

- Net collected amount phải giải thích được từ các transaction đã xác nhận\.

- Outstanding amount không được âm ngoài một overpayment policy được định nghĩa riêng\.

- Payment status phải được tính từ settlement authoritative, không nhập thủ công\.

- Receivable requirement phải có customer cụ thể và source SalesOrder\.

Công thức chuẩn:

```Plaintext
net_collected_amount
= confirmed_collection_amount
- confirmed_refund_amount
```

```Plaintext
outstanding_amount
= payable_amount
- net_collected_amount
```

`overpaid` chưa phải payment status chính thức trong Phase 1\. Trường hợp khách đưa dư tiền mặt được xử lý bằng số tiền phải thu và tiền trả lại khách, không mặc định tạo credit balance\.

**Lifecycle / state model**

SalesOrderSettlement payment status:

```Plaintext
unpaid
→ partially_paid
→ paid
```

Refund path:

```Plaintext
paid → partially_refunded → refunded
partially_paid → partially_refunded
```

SalesPaymentTransaction:

```Plaintext
pending
├── confirmed
├── failed
└── voided
```

Payment status là state của settlement, không phải lifecycle của SalesOrder\.

Receivable sync status được quản lý riêng trong integration foundation, không nằm trong payment status\.

**Commands \& permissions**

|**Command**|**Purpose**|**Permission**|**Idempotency**|
|---|---|---|---|
|InitializeSalesOrderSettlement|Tạo settlement cho SalesOrder|System/internal|Bắt buộc|
|RecordSalesPayment|Ghi nhận khoản thu|sales\.payment\.record|Bắt buộc|
|VoidSalesPayment|Vô hiệu hóa transaction đủ điều kiện|sales\.payment\.void|Bắt buộc|
|RecordSalesRefund|Ghi nhận khoản hoàn tiền|sales\.payment\.refund|Bắt buộc|
|ApplyReceivableCollection|Ghi nhận khoản thu công nợ về settlement|Internal hoặc sales\.payment\.record|Bắt buộc|
|ReconcileSalesSettlement|Xử lý mismatch đã được xác nhận|sales\.settlement\.reconcile|Bắt buộc|

RecordSalesPayment dùng `source_context` để phân biệt:

- checkout

- additional\_collection

- receivable\_collection

- return\_exchange

- manual\_correction

**Queries**

|Query|Purpose|Permission|
|---|---|---|
|GetSalesOrderSettlement|Đọc settlement authoritative|sales\.payment\.view|
|GetSalesOrderPaymentTransactions|Xem các khoản thu/hoàn|sales\.payment\.view|
|GetSalesOrderPaymentSummary|Xem tổng đã thu, đã hoàn và còn phải thu|sales\.payment\.view|

**Domain events**

|**Event**|**Trigger**|
|---|---|
|SalesOrderSettlementInitialized|Settlement được tạo|
|SalesPaymentRecorded|Khoản thu được xác nhận|
|SalesPaymentVoided|Payment bị void hợp lệ|
|SalesRefundRecorded|Refund được xác nhận|
|SalesSettlementChanged|Summary hoặc payment status thay đổi|
|SalesReceivableRequired|Outstanding amount phát sinh|
|SalesReceivableCleared|Outstanding amount về 0|
|SalesSettlementReconciled|Chênh lệch đã được xử lý|

**API references**

- API\-SALES\-SETTLEMENT\-\*

- API\-SALES\-PAYMENT\-\*

- API\-SALES\-REFUND\-\*

- API\-SALES\-RECONCILIATION\-\*

- Chi tiết contract được định nghĩa tại Appendix 6\.1\.

**Related entities**

- sales\_order\_settlements

- sales\_payment\_transactions

- sales\_orders

- receivable\_impact\_requests

- partners

- payment methods

- post\-sale source references

- return/exchange source references

### 2\.3\.3 Post\-sale Operations



**Purpose**



Quản lý các business case phát sinh sau khi SalesOrder đã hoàn tất, gồm chỉnh sửa ghi chú đơn hàng, hủy đơn và đổi/trả; đồng thời xác định các tác động cần được thực hiện bởi Sales Order Lifecycle, Sales Settlement hoặc external domains\.



**Ownership**



Post\-sale Operations sở hữu:

- OrderAdjustment\.

- SalesOrderCancellation\.

- ReturnExchangeOrder\.

- ReturnExchangeLine\.

- ReturnExchangeValuation\.

- Return status authoritative\.

- Post\-sale business status của từng nghiệp vụ\.

    

**Business rules**



BR\-01: SalesOrder, SalesOrderLine và commercial snapshot gốc không được sửa như đơn hàng đang lập\.



BR\-02: Trong Phase 1, OrderAdjustment chỉ được sử dụng để thay đổi ghi chú đơn hàng; không áp dụng adjustable field whitelist động hoặc schema field tùy biến\.



BR\-03: Giá trị ghi chú ban đầu tại checkout phải được bảo toàn\. Giá trị ghi chú hiện hành được xác định từ OrderAdjustment hợp lệ gần nhất nếu có\.



BR\-04: Đơn đã hủy không được chỉnh sửa ghi chú\. Đơn bị khóa chỉ được sửa ghi chú khi lock policy cho phép\.



BR\-05: Sai sản phẩm, số lượng, đơn vị bán, giá, chiết khấu, thuế hoặc tổng tiền phải được xử lý bằng hủy, đổi/trả hoặc nghiệp vụ bù trừ phù hợp; không được xử lý bằng OrderAdjustment\.



BR\-06: Cancellation phải kiểm tra order lifecycle, lock, payment, return, E\-invoice policy, permission, stale version và lý do hủy\.



BR\-07: Return line phải tham chiếu một returnable unit — SalesOrderLine gốc hoặc exchange line đã confirmed (xem ADR-9) — và không được trả vượt số lượng còn có thể trả của unit đó\.



**Chỉnh sửa ghi chú đơn hàng**



OrderAdjustment trong Phase 1 chỉ có loại `order_note_update`\.



PrecheckOrderAdjustment chỉ trả:

- Khả năng chỉnh sửa\.

- Ghi chú hiện hành\.

- Source order version\.

- Quy tắc validation của ghi chú\.

- Blocker nếu không được chỉnh sửa\.

    

Precheck không trả dynamic field schema hoặc danh sách field có thể chỉnh sửa\.



ApplyOrderAdjustment chỉ chấp nhận thay đổi đối với `order_note`\. Request chứa field khác phải bị từ chối toàn bộ\.



Không tạo OrderAdjustment khi:

- Người dùng đóng form mà chưa lưu\.

- Giá trị sau normalize không khác giá trị hiện hành\.

- Validation bị chặn hoặc command chưa commit\.

    

Mỗi lần cập nhật thành công phải tạo một OrderAdjustment append\-only lưu giá trị trước, giá trị sau, actor, source version và thời điểm thực hiện\.



Chỉnh sửa ghi chú không yêu cầu reason code trong Phase 1 và không tạo payment, refund, receivable, inventory hoặc e\-invoice impact\.



**Invariants**



- Mọi post\-sale aggregate phải tham chiếu SalesOrder nguồn\.

- OrderAdjustment chỉ chứa thay đổi của `order_note`\.

- Original order note không bị ghi đè\.

- OrderAdjustment đã tạo không được sửa hoặc xóa\.

- Tổng returned quantity của từng returnable unit (SalesOrderLine gốc hoặc exchange line đã confirmed; ADR-9) không vượt returnable quantity của unit đó\.

- Cancellation không hard delete SalesOrder\.

- SalesOrderLine và commercial snapshot không bị ghi đè bởi nghiệp vụ sau bán\.

    

**Lifecycle / state model**



OrderAdjustment chỉ được persisted khi cập nhật ghi chú đã áp dụng thành công\. Input state, precheck blocked và no\-op không phải OrderAdjustment lifecycle state\.



SalesOrderCancellation và ReturnExchangeOrder tiếp tục sử dụng lifecycle riêng như đã định nghĩa tại các Epic tương ứng\.



**Commands \& permissions**



|Command / operation|Purpose|Permission|Consistency|
|---|---|---|---|
|PrecheckOrderAdjustment|Kiểm tra khả năng sửa ghi chú và lấy source version hiện hành|`sales.order.adjust`|Không tạo business record|
|ApplyOrderAdjustment|Lưu thay đổi ghi chú và tạo OrderAdjustment|`sales.order.adjust`|Bắt buộc expected version và idempotency key|
|GetOrderAdjustmentHistory|Xem lịch sử thay đổi ghi chú trong timeline|`sales.order.history.view`|Read\-only|
|RequestSalesOrderCancellation|Khởi tạo kiểm tra hủy đơn|`sales.order.cancel`|Validate lại tại confirmation|
|ConfirmSalesOrderCancellation|Xác nhận hủy đơn|`sales.order.cancel`|Idempotent|
|StartReturnExchange|Khởi tạo flow đổi/trả|`sales.return_exchange.create`|Không tạo impact chính thức|
|ConfirmReturnExchange|Xác nhận đổi/trả|`sales.return_exchange.confirm`|Idempotent|



**Cross\-domain commands**



Chỉnh sửa ghi chú không tạo cross\-domain command\.



Cancellation và đổi/trả có thể tiếp tục yêu cầu:

- CancelSalesOrder tới Sales Order Lifecycle\.

- RecordSalesPayment hoặc RecordSalesRefund tới Sales Settlement\.

- Receivable impact tới Theme 6\.

- Inventory impact tới Theme 7\.

- E\-invoice impact tới Theme 8\.

    

**Domain events**



- OrderAdjustmentApplied: phát khi ghi chú được cập nhật và OrderAdjustment đã commit\.

- SalesOrderCancellationRequested\.

- SalesOrderCancellationConfirmed\.

- SalesOrderCancellationBlocked\.

- ReturnExchangeStarted\.

- ReturnExchangeConfirmed\.

- ReturnExchangeValued\.

- ReturnExchangeCancelled\.

- ReturnExchangeCompleted\.

    

Không publish `order_adjustment_applied.v1` ra ngoài Theme 5 nếu chưa có consumer nghiệp vụ thực tế\.



**API references**



- API\-SALES\-ADJUSTMENT\-\* chỉ áp dụng cho chỉnh sửa ghi chú đơn hàng\.

- API\-SALES\-CANCELLATION\-\*\.

- API\-SALES\-RETURN\-EXCHANGE\-\*\.

- API\-SALES\-RETURNABLE\-LINES\-\*\.

    

**Related entities**



- order\_adjustments\.

- sales\_order\_cancellations\.

- return\_exchange\_orders\.

- return\_exchange\_lines\.

- return\_exchange\_valuations\.

- sales\_orders\.

- sales\_order\_lines\.

- sales\_order\_settlements\.

- sales\_payment\_transactions\.

- inventory\_impact\_requests\.

- receivable\_impact\_requests\.

- integration\_commands\.

### 2\.3\.4 Sales Order Inquiry \& Documents

**Purpose**

Cung cấp khả năng tra cứu, tìm kiếm, xem chi tiết, timeline và trạng thái tổng hợp của đơn; đồng thời sinh và quản lý phiếu bán hàng nội bộ từ commercial snapshot\.

**Ownership**

Domain này sở hữu:

- Sales order read models\.

- Order list/detail projections\.

- Order timeline projection\.

- SalesReceipt nếu receipt được persisted\.

- Receipt version\.

- Receipt distribution logs nếu cần audit\.

Domain này không sở hữu:

- SalesOrder gốc\.

- Settlement\.

- Payment transaction\.

- Post\-sale aggregate\.

- E\-invoice\.

- Inventory hoặc Receivable ledger\.

**Business rules**

- BR\-01: Dữ liệu giao dịch lịch sử phải đọc từ commercial snapshot, không thay bằng master data hiện hành\.

- BR\-02: Order detail phải phân biệt dữ liệu tại checkout và trạng thái hiện tại\.

- BR\-03: Timeline phải trace được về authoritative source entity hoặc event\.

- BR\-04: Read model có thể eventual nhưng không được trở thành nguồn sửa dữ liệu nghiệp vụ\.

- BR\-05: SalesReceipt chỉ được sinh từ SalesOrder hợp lệ\.

- BR\-06: Receipt không phải hóa đơn điện tử và không được dùng làm source để tính lại doanh thu, kho, công nợ hoặc thuế\.

- BR\-07: Print và share là distribution activities, không phải trạng thái loại trừ nhau\.

**Invariants**

- Read model không được ghi ngược vào authoritative aggregates\.

- Order detail phải thể hiện đúng commercial snapshot\.

- Payment summary phải truy được về SalesOrderSettlement\.

- Return summary phải truy được về ReturnExchangeOrder đã xác nhận\.

- Timeline entry phải có source type, source ID và thời điểm\.

- Receipt version phải tham chiếu SalesOrder và snapshot version hợp lệ\.

- Việc in hoặc chia sẻ receipt không thay đổi lifecycle của SalesOrder\.

**Lifecycle / state model**

Order list, empty, no\-result, loading, error và no\-permission là UI/query states, không phải domain lifecycle\.

SalesReceipt persisted:

```Plaintext
generated
→ archived
```

Nếu receipt versioning được hỗ trợ:

```Plaintext
generated → superseded
```

Print và share được lưu dưới dạng activity records:

```Plaintext
ReceiptPrinted
ReceiptShared
```

Một receipt có thể được in và chia sẻ nhiều lần theo bất kỳ thứ tự nào\.

**Queries**

|**Query**|**Purpose**|**Permission**|
|---|---|---|
|ListSalesOrders|Danh sách đơn theo phạm vi|sales\.order\.view|
|SearchSalesOrders|Tìm kiếm đơn|sales\.order\.view|
|GetSalesOrderDetail|Chi tiết đơn và snapshot|sales\.order\.view|
|GetSalesOrderTimeline|Timeline nghiệp vụ|sales\.order\.history\.view|
|GetSalesOrderPaymentSummary|Settlement hiện tại|sales\.payment\.view|
|GetSalesOrderReturnSummary|Trạng thái và lịch sử đổi/trả|sales\.return\_exchange\.view|
|GetSalesReceipt|Phiếu bán hàng nội bộ|sales\.receipt\.view|
|GetOrderIntegrationStatus|Trạng thái downstream|sales\.integration\.view\_sync\_status|

**Commands \& permissions**

|Command|Purpose|Permission|Idempotency|
|---|---|---|---|
|GenerateSalesReceipt|Sinh receipt version từ SalesOrder snapshot|System/internal hoặc sales\.receipt\.generate|Bắt buộc|
|RecordSalesReceiptPrinted|Ghi nhận một lần in|sales\.receipt\.print|Khuyến nghị|
|RecordSalesReceiptShared|Ghi nhận một lần chia sẻ|sales\.receipt\.share|Khuyến nghị|
|ArchiveSalesReceipt|Lưu trữ receipt nếu policy hỗ trợ|sales\.receipt\.archive|Bắt buộc|

**Domain events**

|Event|Trigger|
|---|---|
|SalesReceiptGenerated|Receipt version được sinh|
|SalesReceiptPrinted|Print activity được ghi nhận|
|SalesReceiptShared|Share activity được ghi nhận|
|SalesReceiptArchived|Receipt được lưu trữ|

Các event như `SalesOrderListViewed` hoặc `SalesOrderDetailViewed` là product analytics events, không phải domain events\.

**API references**

- API\-SALES\-ORDER\-INQUIRY\-\*

- API\-SALES\-ORDER\-TIMELINE\-\*

- API\-SALES\-RECEIPT\-\*

- API\-SALES\-INTEGRATION\-STATUS\-QUERY\-\*

- Chi tiết contract được định nghĩa tại Appendix 6\.1\.

**Related entities**

- sales\_receipts

- sales\_receipt\_distribution\_logs

- sales\_order\_read\_models

- sales\_order\_timeline\_projections

- sales\_orders

- sales\_order\_lines

- sales\_order\_settlements

- sales\_payment\_transactions

- order\_adjustments

- sales\_order\_cancellations

- return\_exchange\_orders

- integration status projections

## 2\.4 Cross\-cutting foundations

### 2\.4\.1 Operational context \& prerequisites

Operational context không phải business domain độc lập\. Đây là tập điều kiện để các command của Theme 5 được xử lý đúng tenant, store, actor và phạm vi quyền\.

Context có thể gồm:

- tenant\_id

- store\_id hoặc location\_id

- actor\_user\_id

- role và permission

- sales\_shift\_id nếu tenant bật quản lý ca bán

- business time và timezone

- channel hoặc device context nếu cần

Nguyên tắc:

- Mọi command phải thuộc một tenant hợp lệ\.

- User phải có quyền trên đúng data scope\.

- Store/location phải còn hiệu lực tại thời điểm command\.

- Context phải được validate lại khi checkout hoặc post\-sale action\.

- Context đã đọc khi mở màn hình không được coi là luôn đúng tại thời điểm ghi dữ liệu\.

- Nếu sales\_shift\_id bắt buộc, checkout không hoàn tất khi thiếu ca hợp lệ\.

SalesShift nếu được Theme 5 quản lý trong Phase 1 là operational supporting aggregate, không phải một trong bốn business domains\.

SalesShift lifecycle:

```Plaintext
open → closing → closed
```

Ca đã closed không nhận thêm giao dịch mới, trừ khi có override policy và audit bắt buộc\.

Commands:

|Command|Permission|
|---|---|
|OpenSalesShift|sales\.shift\.open|
|CloseSalesShift|sales\.shift\.close|
|OverrideClosedShiftRestriction|sales\.shift\.override|

Related entity:

- sales\_shifts

### 2\.4\.2 Consistency \& failure handling

#### Consistency levels

Theme 5 sử dụng ba consistency levels:

**Synchronous blocking**

Dependency phải trả kết quả hợp lệ trước khi business command được hoàn tất\.

Áp dụng cho:

- Tenant, actor, permission và store context\.

- Product và product unit\.

- Pricing recalculation tại checkout\.

- Customer khi phát sinh công nợ\.

- Inventory availability khi không cho âm kho\.

- E\-invoice policy validation trước một số post\-sale action\.

**Atomic local transaction**

Các record thuộc transaction boundary của Theme 5 phải commit hoặc rollback cùng nhau\.

Checkout local transaction tối thiểu gồm:

```Plaintext
SalesOrder
+ SalesOrderLines
+ SalesOrderSettlement
+ Initial SalesPaymentTransactions
+ CheckoutAttempt result
+ Idempotency result
+ Mandatory audit
+ Outbox / impact records
```

Receipt không bắt buộc nằm trong checkout transaction; nó có thể được sinh từ SalesOrderFinalized sau khi order đã commit\.

**Eventual consistency**

Downstream domain cập nhật sau khi Theme 5 đã lưu durable impact/outbox record\.

Áp dụng cho:

- Receivable ledger posting\.

- E\-invoice issuance\.

- Reporting\.

- Accounting/tax consumers\.

- External integrations\.

- Inventory impacts được phép xử lý async theo policy\.

#### Checkout success boundary

FinalizeSalesOrder chỉ trả `succeeded` khi:

- Blocking validations đã hoàn tất\.

- Inventory đã được bảo đảm nếu policy cấm âm kho\.

- Local transaction đã commit\.

- Idempotency result đã được lưu\.

- Kết quả có thể được truy vấn lại bằng checkout attempt hoặc idempotency key\.

Receivable, E\-invoice hoặc Reporting chưa xử lý xong không làm checkout thất bại nếu durable impact record đã được commit\.

#### Consistency \& failure matrix

|**Dependency / capability**|**Owner**|**Consistency**|**Block command?**|**Failure handling**|
|---|---|---|---|---|
|Tenant, actor, permission|Theme 1|Synchronous|Yes|Từ chối command|
|Store/location|Theme 1<br>|Synchronous|Yes|Yêu cầu chọn hoặc cập nhật context|
|Product \& ProductUnit|Theme 2|Synchronous validation|Yes|Chặn line hoặc checkout|
|Partner/customer|Theme 3|Conditional synchronous|Có khi gắn customer hoặc bán nợ|Chặn công nợ hoặc yêu cầu customer hợp lệ|
|Pricing \& promotion|Theme 4|Synchronous recalculation|Yes|Chặn checkout và yêu cầu refresh|
|SalesOrder \+ lines|Theme 5|Atomic local|Yes|Rollback|
|Settlement \+ payment|Theme 5|Atomic local|Yes|Rollback hoặc uncertain|
|Inventory availability|Theme 7|Conditional strong|Có khi cấm âm kho|Chặn hoặc yêu cầu reservation|
|Inventory movement|Theme 7|Strong hoặc eventual theo policy|Có điều kiện|Retry hoặc reconciliation|
|Receivable ledger|Theme 6|Eventual sau durable impact|No đối với technical failure|Pending/failed và retry|
|E\-invoice issuance|Theme 8|Eventual|No tại checkout|Pending/failed và retry|
|E\-invoice post\-sale policy|Theme 8|Synchronous validation|Yes|Block post\-sale action|
|Reporting|Theme 10|Eventual / rebuildable|No|Background retry|
|External integration|Theme 12|Eventual mặc định|No|Retry hoặc reconciliation|
|Mandatory audit|Theme 5 foundation|Atomic local|Yes|Không hoàn tất action nhạy cảm|

#### Inventory consistency policy

Khi sản phẩm quản lý tồn kho và không cho phép âm kho, không được dùng flow:

```Plaintext
Read current stock
→ checkout success
→ deduct stock asynchronously
```

Theme 5 phải dùng một trong hai mô hình:

**Atomic stock movement**

```Plaintext
SalesOrder commit
+ stock movement
+ settlement
```

cùng một physical transaction\.

**Inventory reservation**

```Plaintext
ReserveInventoryForSale
→ nhận reservation token
→ commit SalesOrder
→ CommitSalesInventoryImpact
```

Nếu order commit thất bại, reservation phải được release hoặc tự hết hạn\.

Inventory impact có thể async khi:

- Product không quản lý tồn kho\.

- Tenant cho phép âm kho\.

- Cancellation làm tăng lại tồn kho\.

- Hàng trả cần kiểm tra trước khi nhập lại\.

- Reservation đã bảo đảm lượng hàng xuất\.

Trong đổi hàng:

- Exchange item phải được bảo đảm tồn kho nếu cấm âm kho\.

- Returned item có thể chờ kiểm tra trước khi nhập lại tồn bán được\.

#### Failure taxonomy

|Failure type|Ý nghĩa|Hành vi|
|---|---|---|
|business\_blocked|Vi phạm business rule|Không retry cho đến khi dữ liệu thay đổi|
|validation\_failed|Input thiếu hoặc sai|Trả lỗi cụ thể tại field|
|dependency\_unavailable|Blocking dependency không phản hồi|Chưa tạo giao dịch; cho retry|
|local\_transaction\_failed|Commit Theme 5 thất bại|Rollback toàn bộ|
|uncertain|Không xác định command đã commit hay chưa|Không submit request mới; query bằng idempotency key|
|downstream\_pending|Impact đã lưu, consumer chưa xử lý|Giao dịch chính vẫn thành công|
|downstream\_failed|Delivery hoặc xử lý tạm thời thất bại|Retry theo policy|
|business\_rejected\_downstream|Domain đích từ chối nghiệp vụ|Block/reconciliation; không retry vô hạn|
|reconciliation\_required|Dữ liệu giữa các domain không khớp|Người có quyền xử lý|
|permanent\_failure|Payload hoặc contract không thể xử lý|Dead\-letter và support intervention|

### 2\.4\.3 Command, query \& event conventions

Phần này chỉ mang tính tạm thời, sẽ khái quát hoá và đưa vào quy chuẩn chung cho cả hệ thống VET45\.

#### Command

Command là yêu cầu thực hiện một business action và có thể bị từ chối\.

Naming:

```Plaintext
Verb + Business Object
```

Ví dụ:

- FinalizeSalesOrder

- RecordSalesPayment

- ConfirmReturnExchange

- CancelSalesOrder

Không sử dụng command quá chung:

- UpdateOrder

- ChangeStatus

- ProcessPayment

- HandleReturn

Mỗi command:

- Chỉ có một domain owner\.

- Kiểm tra tenant, actor và permission\.

- Kiểm tra idempotency nếu action có thể retry\.

- Kiểm tra expected version nếu có concurrent editing\.

- Kiểm tra current state và invariants\.

- Ghi audit khi action nhạy cảm\.

- Phát domain event sau khi commit thành công\.

#### Query

Query chỉ đọc dữ liệu và không thay đổi business state\.

Các thao tác list, search, view detail, timeline và payment summary phải nằm trong query catalog, không nằm trong command catalog\.

#### Precheck / validation operation

Precheck:

- Có thể trả ready, warning hoặc blocked\.

- Không tạo business fact cuối cùng\.

- Không thay thế validation trong command xác nhận\.

- Không mặc định phát public domain event\.

#### Domain event

Domain event mô tả business fact đã xảy ra thành công trong một domain\.

Naming dùng quá khứ:

- SalesOrderFinalized

- SalesPaymentRecorded

- ReturnExchangeConfirmed

#### Integration command

Integration command yêu cầu một domain khác thực hiện trách nhiệm cụ thể\.

Ví dụ:

- PostSalesReceivable

- ReserveInventoryForSale

- RequestSalesEInvoice

#### Integration event

Integration event công bố một business fact để consumer tự quyết định phản ứng\.

Public integration events chính của Theme 5:

- sales\_order\_finalized\.v1

- sales\_order\_cancelled\.v1

- sales\_payment\_recorded\.v1

- sales\_payment\_voided\.v1

- sales\_refund\_recorded\.v1

- sales\_settlement\_changed\.v1

- order\_adjustment\_applied\.v1

- return\_exchange\_confirmed\.v1

- return\_exchange\_completed\.v1

Draft events, UI\-view events và technical delivery events không publish công khai mặc định\.

### 2\.4\.4 Integration delivery, idempotency \& audit

Phần này chỉ mang tính tạm thời, sẽ khái quát hoá và đưa vào quy chuẩn chung cho cả hệ thống VET45\.

#### Durable delivery

Mọi downstream impact bắt buộc phải được ghi thành durable record trong cùng local transaction với business change nguồn\.

Có thể sử dụng:

- Outbox message\.

- Integration command\.

- Inventory impact request\.

- Receivable impact request\.

Không được:

```Plaintext
Commit business transaction
→ gọi downstream
→ nếu gọi lỗi thì mất luôn impact
```

#### Idempotency

Các command nhạy cảm bắt buộc idempotent:

- FinalizeSalesOrder\.

- RecordSalesPayment\.

- VoidSalesPayment\.

- RecordSalesRefund\.

- ConfirmSalesOrderCancellation\.

- ConfirmReturnExchange\.

- Downstream inventory, receivable và E\-invoice commands\.

Quy tắc:

- Cùng idempotency key và cùng payload trả lại cùng kết quả\.

- Cùng key nhưng payload khác trả conflict\.

- Retry không tạo thêm SalesOrder, payment, stock movement, receivable entry hoặc invoice request\.

- Consumer cũng phải xử lý idempotent\.

Downstream idempotency key đề xuất:

```Plaintext
{tenant_id}:{source_type}:{source_id}:{impact_type}:{source_version}
```

#### Correlation

Mọi command/event quan trọng phải có:

- command\_id hoặc event\_id

- idempotency\_key nếu áp dụng

- correlation\_id

- causation\_id

- source\_type

- source\_id

- source\_version

- payload hash

- tenant\_id

- occurred\_at hoặc issued\_at

#### Audit

Audit bắt buộc đối với:

- Finalize order\.

- Payment/refund/void\.

- Cancellation\.

- Adjustment\.

- Return/exchange\.

- Lock/unlock\.

- Manual retry hoặc reconciliation\.

- Permission override\.

Audit record phải có:

- Actor\.

- Action\.

- Source entity\.

- Before/after diff nếu có\.

- Reason nếu bắt buộc\.

- Result\.

- Correlation ID\.

- Business time\.

- System time\.

Audit log là append\-only về mặt nghiệp vụ và không phải owner của trạng thái domain\.

## 2\.5 External domain contracts

### 2\.5\.1 Theme 1 — Tenant, store, identity \& permission

Theme 1 và Platform Identity cung cấp:

- Platform User identity và identity lifecycle\.

- Trạng thái active của Platform User\.

- Tenant và store/location context\.

- Tenant Membership và membership status\.

- Role, permission và data scope\.

- TenantContext hợp lệ tại thời điểm thực hiện nghiệp vụ\.

Theme 5 phải:

- Xác thực người dùng trước khi xử lý nghiệp vụ\.

- Chặn truy cập nếu Platform User chưa active hoặc không còn hợp lệ\.

- Chặn tenant\-scoped command nếu Membership không active, tenant/store context không hợp lệ hoặc resource nằm ngoài data scope\.

- Kiểm tra lại permission tại command time, không chỉ dựa vào quyền đã cache trên client\.

- Lưu actor\_id, store context và actor snapshot cần thiết cho audit\.

- Không tạo, cập nhật hoặc quản lý Platform User, Membership, role, permission, activation invitation hoặc Tenant Invitation

Platform User activation invitation và Tenant Invitation là hai lifecycle độc lập\. Việc phát hành, xác nhận, hết hạn, gửi lại hoặc vô hiệu hóa token thuộc Theme 1/Platform Identity và không tạo entity, API hoặc Screen Group trong Theme 5\.

Consistency: synchronous blocking đối với identity, membership, tenant context, store scope và permission\.

### 2\.5\.2 Theme 2 — Product \& ProductUnit

Theme 2 cung cấp:

- Product hiện hành\.

- ProductUnit\.

- SKU/barcode\.

- Business status\.

- Sellability/readiness theo contract\.

Theme 5:

- Validate product và unit tại checkout\.

- Lưu product/unit snapshot\.

- Không ghi ngược dữ liệu giao dịch vào Product\.

- Không thay commercial snapshot khi Product thay đổi\.

Consistency:

- Synchronous validation trước checkout\.

- Snapshot bất biến sau checkout\.

### 2\.5\.3 Theme 3 — Partner

Theme 3 sở hữu Partner\.

Theme 5:

- Tham chiếu customer\_partner\_id\.

- Lưu customer snapshot nếu có\.

- Yêu cầu Partner cụ thể khi phát sinh công nợ\.

- Không cập nhật Partner từ order nếu không qua command của Theme 3\.

Consistency:

- Conditional synchronous khi gắn customer hoặc tạo receivable\.

### 2\.5\.4 Theme 4 — Pricing \& Promotions

Theme 4 sở hữu:

- Pricing engine\.

- Giá riêng và nhớ giá\.

- Promotion rules\.

- Applied\-promotion validation\.

- Promotion usage và reversal policy\.

Integration operations:

- ValidateFinalSalesPricing\.

- CommitAppliedPricingForSalesOrder\.

- ReverseAppliedPricingForSalesOrder\.

- EvaluateReturnPricingImpact\.

Theme 5:

- Không tự tính lại business pricing bằng snapshot cũ\.

- Lưu applied pricing và promotion snapshot\.

- Không sửa pricing rule từ SalesOrder\.

Consistency:

- ValidateFinalSalesPricing là synchronous blocking\.

- Commit/reverse downstream phải idempotent\.

### 2\.5\.5 Theme 6 — Receivable

Theme 6 sở hữu receivable ledger\.

Integration commands:

- PostSalesReceivable\.

- AdjustSalesReceivable\.

- ReverseSalesReceivable\.

- ApplySalesReceivableOffset\.

- ReconcileSalesReceivable\.

Theme 5:

- Xác định outstanding amount\.

- Tạo durable receivable impact\.

- Lưu external reference và sync projection\.

- Không sửa receivable ledger\.

Consistency:

- Business eligibility synchronous\.

- Ledger posting eventual sau durable impact\.

### 2\.5\.6 Theme 7 — Inventory \& costing

Theme 7 sở hữu:

- Inventory availability\.

- Reservation\.

- Stock movement\.

- Lot/batch nếu có\.

- Cost layer\.

- Cost of goods sold\.

Integration commands:

- ReserveInventoryForSale\.

- CommitSalesInventoryImpact\.

- ReleaseSalesInventoryReservation\.

- ReverseSalesInventoryImpact\.

- RegisterReturnedInventoryImpact\.

- CommitExchangeInventoryImpact\.

Theme 5:

- Không tự sửa inventory ledger\.

- Lưu quantity/unit snapshot và source reference\.

- Bảo đảm inventory trước success khi cấm âm kho\.

- Không tự tính giá vốn\.

Consistency:

- Conditional strong consistency đối với hàng xuất\.

- Eventual hoặc workflow\-based đối với hàng trả và reversal theo policy\.

### 2\.5\.7 Theme 8 — E\-invoice

Theme 8 sở hữu:

- Invoice template\.

- Invoice number\.

- Digital signature\.

- Issuance\.

- Adjustment\.

- Replacement\.

- Cancellation\.

- Provider integration\.

Integration commands:

- RequestSalesEInvoice\.

- RequestSalesEInvoiceAdjustment\.

- RequestSalesEInvoiceReplacement\.

- RequestSalesEInvoiceCancellation\.

Theme 5:

- Cung cấp SalesOrder snapshot và buyer tax data\.

- Lưu invoice reference/status projection nếu cần\.

- Không rollback SalesOrder khi provider tạm lỗi\.

- Validate E\-invoice policy trước post\-sale action có ảnh hưởng pháp lý\.

Consistency:

- Issuance eventual\.

- Post\-sale policy validation synchronous blocking\.

### 2\.5\.8 Theme 10 — Reporting

Theme 10:

- Consume public integration events\.

- Xây dựng report và KPI\.

- Không sửa Theme 5 aggregates\.

Yêu cầu:

- Consumer idempotent\.

- Có thể rebuild projection\.

- Reporting failure không block business transaction\.

Consistency:

- Eventual và non\-blocking\.

### 2\.5\.9 Theme 12 — External integrations

Theme 12 quản lý:

- External connector\.

- Provider\-specific delivery\.

- Mapping và authentication\.

- External retry/reconciliation\.

Theme 5:

- Phát durable integration command/event\.

- Lưu correlation và external status projection\.

- Không nhúng provider\-specific lifecycle vào SalesOrder lifecycle\.

Consistency:

- Eventual mặc định\.

- Chỉ synchronous khi một business policy được chốt rõ là blocking\.

# 3\. Data \& entities

```mermaid
flowchart LR

subgraph D1["Domain 1 — Sales Order Lifecycle"]
direction TB
    D11["Aggregate: SalesOrderDraft"]
    D12["Process: CheckoutAttempt"]
    D13["Aggregate: SalesOrder"]
    D11 --> D12 --> D13
end

subgraph D2["Domain 2 — Sales Settlement"]
direction TB
    D21["Aggregate: SalesOrderSettlement"]
end

subgraph D3["Domain 3 — Post-sale Operations"]
direction TB
    D31["Aggregate: OrderAdjustment"]
    D32["Aggregate: SalesOrderCancellation"]
    D33["Aggregate: ReturnExchangeOrder"]
end

subgraph D4["Domain 4 — Sales Order Inquiry & Documents"]
direction TB
    D41["Aggregate: SalesReceipt"]
    D42["Read models: Order Inquiry Views"]
end

D13 --> D21
D13 --> D31
D13 --> D32
D13 --> D33
D13 --> D41
D13 -.-> D42
D21 -.-> D42
D33 -.-> D42```

## 3\.1 Relationship model

### 3\.1\.1 Modeling principles

Relationship model của Theme 5 được xây dựng theo các nguyên tắc:

- Mỗi aggregate có một domain owner duy nhất\.

- Entity con chỉ được thay đổi thông qua aggregate root sở hữu nó\.

- Quan hệ giữa các aggregate không tạo quyền sửa chéo dữ liệu\.

- Commercial snapshot được lưu cùng giao dịch, không phụ thuộc vào master data hiện hành\.

- Reference ID và snapshot có thể cùng tồn tại trên một giao dịch\.

- Read model chỉ tổng hợp dữ liệu để truy vấn, không được ghi ngược vào authoritative entities\.

- Integration request không được coi là bằng chứng rằng downstream domain đã xử lý thành công\.

- Audit, idempotency và delivery record không phải business source of truth\.

- Không sử dụng hard delete đối với SalesOrder và các giao dịch tài chính đã phát sinh\.

- Các quan hệ polymorphic phải được giới hạn bằng `source_type`, `source_id` và business rules rõ ràng\.

    

Các loại quan hệ được sử dụng:

|**Relationship type**|**Meaning**|
|---|---|
|Owned child|Entity con nằm trong aggregate và chỉ được thay đổi thông qua aggregate root|
|Aggregate reference|Một aggregate tham chiếu aggregate khác nhưng không sở hữu hoặc sửa trực tiếp|
|External reference|Entity Theme 5 tham chiếu entity thuộc theme khác|
|Embedded snapshot|Dữ liệu lịch sử được lưu trong entity giao dịch, không có lifecycle riêng|
|Derived projection|Read model được xây dựng từ authoritative entities hoặc events|
|Source reference|Quan hệ truy vết từ transaction/action về nghiệp vụ tạo ra nó|
|Integration reference|Quan hệ giữa business source và downstream impact/request|

### 3\.1\.2 Aggregate relationship overview

Mô hình aggregate tổng quát:

```Plain Text
SalesOrderDraft
└── SalesOrderDraftLine

CheckoutAttempt
├── source SalesOrderDraft, optional
├── IdempotencyRecord
└── result SalesOrder, optional until succeeded

SalesOrder
├── SalesOrderLine
├── SalesOrderSettlement
│   └── SalesPaymentTransaction
├── OrderAdjustment
├── SalesOrderCancellation
├── ReturnExchangeOrder
│   ├── ReturnExchangeLine
│   └── ReturnExchangeValuation
└── SalesReceipt
    └── SalesReceiptActivity
```

Boundary chính:

- SalesOrderDraft và SalesOrder là hai aggregate khác nhau\.

- CheckoutAttempt là process record điều phối việc tạo SalesOrder\.

- SalesOrderSettlement là aggregate riêng, không phải entity con được SalesOrder Lifecycle trực tiếp sửa\.

- Post\-sale aggregates tham chiếu SalesOrder nguồn nhưng không sở hữu SalesOrder\.

- SalesReceipt được sinh từ SalesOrder snapshot nhưng không trở thành source of truth của đơn\.

- Read models đứng ngoài các transactional aggregate\.

    

### 3\.1\.3 Domain relationships

#### 3\.1\.3\.1 Sales Order Lifecycle relationships

##### SalesOrderDraft — SalesOrderDraftLine

```Plain Text
SalesOrderDraft 1 ─── 1..n SalesOrderDraftLine
```

Quy tắc:

- Một persisted SalesOrderDraft phải có ít nhất một SalesOrderDraftLine\.

- Mỗi SalesOrderDraftLine chỉ thuộc một SalesOrderDraft\.

- Draft line không được tồn tại độc lập\.

- Xóa mềm hoặc expire draft áp dụng cho toàn aggregate\.

- Cập nhật draft phải kiểm tra version tại aggregate root\.

- Giá và promotion trên draft chỉ là preview, không phải commercial snapshot chính thức\.

    

##### SalesOrderDraft — SalesOrder

```Plain Text
SalesOrderDraft 1 ─── 0..1 SalesOrder
SalesOrder      1 ─── 0..1 source SalesOrderDraft
```

Quy tắc:

- Một SalesOrderDraft chỉ được convert thành tối đa một SalesOrder\.

- SalesOrder có thể được tạo trực tiếp từ working state mà không qua persisted draft\.

- Draft đã convert chuyển sang `converted` và không được chỉnh sửa tiếp\.

- SalesOrder không phụ thuộc vào draft để tồn tại hoặc để hiển thị dữ liệu lịch sử\.

- Draft không được dùng làm source of truth sau khi SalesOrder đã được tạo\.

    

##### CheckoutAttempt — SalesOrderDraft

```Plain Text
CheckoutAttempt 1 ─── 0..1 SalesOrderDraft
```

Quy tắc:

- CheckoutAttempt có thể bắt nguồn từ persisted draft hoặc working state chưa lưu\.

- Nếu checkout bắt nguồn từ draft, CheckoutAttempt lưu `source_draft_id`\.

- Checkout không được sửa trực tiếp draft lines trong quá trình commit\.

- Draft chỉ chuyển sang `converted` sau khi SalesOrder được commit thành công\.

    

##### CheckoutAttempt — SalesOrder

```Plain Text
CheckoutAttempt 1 ─── 0..1 SalesOrder
SalesOrder      1 ─── 1 successful CheckoutAttempt
```

Quy tắc:

- Một CheckoutAttempt chỉ tạo tối đa một SalesOrder\.

- CheckoutAttempt chưa thành công có thể chưa có `sales_order_id`\.

- CheckoutAttempt `succeeded` bắt buộc phải tham chiếu SalesOrder\.

- Retry cùng idempotency key không tạo SalesOrder mới\.

- Trạng thái `uncertain` phải được resolve về chính SalesOrder đã tạo nếu local transaction thực tế đã commit\.

- Với SalesOrder được tạo bởi Theme 5 checkout, mỗi SalesOrder phải truy được về một successful CheckoutAttempt\.

    

##### SalesOrder — SalesOrderLine

```Plain Text
SalesOrder 1 ─── 1..n SalesOrderLine
```

Quy tắc:

- SalesOrder phải có ít nhất một SalesOrderLine\.

- Mỗi SalesOrderLine chỉ thuộc một SalesOrder\.

- SalesOrderLine không được tồn tại độc lập\.

- Commercial values trên SalesOrderLine là immutable snapshot sau checkout\.

- Không hard delete hoặc thay thế SalesOrderLine để phản ánh đổi/trả\.

- Return, cancellation và adjustment phải được lưu bằng entity riêng\.

    

##### SalesOrder — embedded snapshots

```Plain Text
SalesOrder
├── SalesContextSnapshot
├── CustomerSnapshot
├── BuyerTaxSnapshot, optional
└── MonetarySummary

SalesOrderLine
├── ProductSnapshot
├── ProductUnitSnapshot
└── PricingSnapshot
```

Quy tắc:

- Snapshot là value model được embedded, không phải aggregate hoặc entity độc lập\.

- Snapshot không bắt buộc có FK tới master data hiện hành\.

- SalesOrder vẫn có thể giữ reference ID để điều hướng sang entity hiện hành\.

- Việc master data thay đổi không cập nhật ngược snapshot\.

- MonetarySummary phải reconcile với SalesOrderLine values tại checkout\.

- Payment hoặc return hiện tại không được ghi đè MonetarySummary ban đầu\.

    

#### 3\.1\.3\.2 Sales Settlement relationships

##### SalesOrder — SalesOrderSettlement

```Plain Text
SalesOrder 1 ─── 1 SalesOrderSettlement
```

Quy tắc:

- Mỗi SalesOrder có chính xác một authoritative SalesOrderSettlement\.

- Mỗi SalesOrderSettlement chỉ thuộc một SalesOrder\.

- SalesOrder và SalesOrderSettlement được tạo trong cùng checkout local transaction\.

- SalesOrder Lifecycle không trực tiếp sửa settlement amounts hoặc payment status\.

- Sales Settlement không trực tiếp sửa commercial snapshot hoặc order lifecycle\.

- `payable_amount` ban đầu của settlement phải bằng payable amount trên SalesOrder\.

- Những thay đổi sau bán được phản ánh bằng payment/refund transaction, không sửa payable snapshot gốc tùy tiện\.

    

##### SalesOrderSettlement — SalesPaymentTransaction

```Plain Text
SalesOrderSettlement 1 ─── 0..n SalesPaymentTransaction
```

Quy tắc:

- Settlement có thể chưa có payment transaction khi đơn bán hoàn toàn ghi nợ\.

- Mỗi SalesPaymentTransaction chỉ thuộc một SalesOrderSettlement\.

- Payment, refund, void hoặc reversal phải được ghi bằng transaction riêng\.

- Transaction đã confirmed không được sửa amount, direction hoặc method\.

- Sai transaction phải được xử lý bằng void hoặc transaction bù trừ\.

- Settlement summary phải có thể rebuild từ các transaction authoritative\.

- Payment status là derived authoritative state của SalesOrderSettlement\.

    

##### SalesPaymentTransaction — source business object

```Plain Text
SalesPaymentTransaction
├── source_type
└── source_id
```

`source_type` có thể gồm:

- `checkout`

- `additional_collection`

- `receivable_collection`

- `sales_order_cancellation`

- `return_exchange`

- `manual_correction`

    

Quy tắc:

- `source_type` và `source_id` giải thích nghiệp vụ tạo transaction\.

- Source reference không chuyển ownership transaction sang source aggregate\.

- Payment transaction vẫn do Sales Settlement sở hữu\.

- Refund từ cancellation phải tham chiếu SalesOrderCancellation nguồn\.

- Thu thêm hoặc refund từ đổi/trả phải tham chiếu ReturnExchangeOrder nguồn\.

- Manual correction phải có permission và audit đặc biệt\.

    

##### SalesOrderSettlement — ReceivableImpactRequest

```Plain Text
SalesOrderSettlement 1 ─── 0..n ReceivableImpactRequest
```

Quy tắc:

- Settlement tạo receivable impact khi có outstanding amount hoặc khi nghĩa vụ phải thu thay đổi\.

- Một settlement có thể tạo nhiều impact theo source version\.

- ReceivableImpactRequest không phải ReceivableEntry\.

- Theme 6 là owner của receivable ledger\.

- Mỗi impact phải có idempotency key và source version\.

- Khi receivable impact được accepted, Theme 5 chỉ lưu external reference hoặc projection\.

- Failure của delivery không làm thay đổi payment status authoritative\.

    

#### 3\.1\.3\.3 Post\-sale relationships

##### SalesOrder — OrderAdjustment

```Plain Text
SalesOrder 1 ─── 0..n OrderAdjustment
```

Quy tắc:

- Một SalesOrder có thể có nhiều adjustment theo thời gian\.

- Mỗi OrderAdjustment chỉ áp dụng cho một SalesOrder\.

- Adjustment phải lưu before/after diff\.

- Adjustment không được ghi đè commercial snapshot\.

- Chỉ field thuộc whitelist mới được phép điều chỉnh\.

- Adjustment đã applied không được xóa hoặc sửa lịch sử\.

- `has_adjustments` nếu được lưu trên order list chỉ là derived projection\.

    

##### SalesOrder — SalesOrderCancellation

```Plain Text
SalesOrder 1 ─── 0..n SalesOrderCancellation
```

Quan hệ cho phép nhiều cancellation case vì:

- Một yêu cầu có thể bị blocked\.

- Sau khi điều kiện thay đổi, người dùng có thể tạo yêu cầu mới\.

- Một yêu cầu có thể bị người dùng hủy trước khi hoàn tất\.

    

Invariants:

- Mỗi SalesOrderCancellation chỉ áp dụng cho một SalesOrder\.

- Một SalesOrder chỉ được có tối đa một cancellation case ở trạng thái `completed`\.

- Khi SalesOrder đã `cancelled`, không được xác nhận cancellation case mới\.

- SalesOrderCancellation sở hữu hồ sơ hủy, nhưng không trực tiếp sở hữu `SalesOrder.order_lifecycle_status`\.

- Khi cancellation đủ điều kiện, Post\-sale Operations gửi `CancelSalesOrder` tới Sales Order Lifecycle\.

- Chỉ sau khi `SalesOrderCancelled` được phát, cancellation case mới được hoàn tất\.

- Refund, receivable reversal và inventory reversal phải truy được về cancellation case nguồn\.

    

##### SalesOrder — ReturnExchangeOrder

```Plain Text
SalesOrder 1 ─── 0..n ReturnExchangeOrder
```

Quy tắc:

- Một SalesOrder có thể phát sinh nhiều lần đổi/trả\.

- Mỗi ReturnExchangeOrder chỉ tham chiếu một SalesOrder nguồn\.

- ReturnExchangeOrder không sở hữu hoặc sửa SalesOrderLine gốc\.

- Tổng returned quantity phải tính trên toàn bộ ReturnExchangeOrder đã confirmed/completed\.

- Cancellation toàn bộ và return/exchange phải được kiểm tra xung đột nghiệp vụ\.

- Return status của SalesOrder được derive từ các ReturnExchangeOrder authoritative\.

    

##### ReturnExchangeOrder — ReturnExchangeLine

```Plain Text
ReturnExchangeOrder 1 ─── 1..n ReturnExchangeLine
```

Quy tắc:

- ReturnExchangeOrder phải có ít nhất một line với `line_role = returned`\.

- Một ReturnExchangeLine chỉ thuộc một ReturnExchangeOrder\.

- `line_role` gồm tối thiểu:

    - `returned`

    - `exchange`

- Returned line và exchange line có validation khác nhau\.

- Line đã confirmed không được sửa trực tiếp\.

    

##### Returned line — original SalesOrderLine

```Plain Text
ReturnExchangeLine(returned) n ─── 1 SalesOrderLine
```

Quy tắc:

- Returned line bắt buộc tham chiếu original SalesOrderLine\.

- Returned quantity không vượt remaining returnable quantity\.

- Return value được tính từ commercial snapshot của original SalesOrderLine\.

- Returned line không dùng current product price để tính giá trị hoàn\.

- Nếu Product master đã inactive hoặc thay đổi, original snapshot vẫn là nguồn lịch sử\.

    

##### Exchange line — Product và ProductUnit hiện hành

```Plain Text
ReturnExchangeLine(exchange) n ─── 1 Product
ReturnExchangeLine(exchange) n ─── 1 ProductUnit
```

Quy tắc:

- Exchange line sử dụng Product và ProductUnit hiện hành\.

- Giá hàng đổi hoặc mua thêm được lấy qua Theme 4 tại thời điểm xác nhận\.

- Inventory availability phải được validate theo policy hiện hành\.

- Exchange line có thể tham chiếu original SalesOrderLine để thể hiện ngữ cảnh, nhưng không bắt buộc\.

- Product và ProductUnit reference phải đi cùng embedded snapshot sau khi return/exchange được confirmed\.

- Sau khi được confirmed, exchange line trở thành một returnable unit của SalesOrder nguồn: có thể được trả hoặc đổi tiếp, đệ quy không giới hạn tầng. Khi bị trả, giá gốc dùng để định giá là giá lúc đổi-vào (`unit_value_minor` của chính exchange line). Xem ADR-9.

    

##### ReturnExchangeOrder — ReturnExchangeValuation

```Plain Text
ReturnExchangeOrder 1 ─── 0..1 ReturnExchangeValuation
```

Quy tắc:

- ReturnExchangeOrder draft có thể chưa có valuation chính thức\.

- Khi confirmed, ReturnExchangeOrder phải có một authoritative ReturnExchangeValuation\.

- Mỗi ReturnExchangeValuation chỉ thuộc một ReturnExchangeOrder\.

- Valuation lưu:

    - return value

    - exchange value

    - net difference

    - required settlement type

- Valuation không ghi nhận payment hoặc refund transaction authoritative\.

- Sales Settlement thực hiện thu thêm, refund hoặc receivable offset dựa trên valuation\.

    

##### ReturnExchangeOrder — SalesPaymentTransaction

```Plain Text
ReturnExchangeOrder 1 ─── 0..n SalesPaymentTransaction
```

Đây là source reference, không phải ownership\.

Quy tắc:

- Khi `net_difference > 0`, Sales Settlement có thể tạo collection transaction\.

- Khi `net_difference < 0`, Sales Settlement có thể tạo refund transaction\.

- Khi chênh lệch được cấn trừ công nợ, Theme 5 tạo ReceivableImpactRequest\.

- Mọi transaction phải tham chiếu source ReturnExchangeOrder\.

- ReturnExchangeOrder chỉ completed khi các local settlement requirements đã được ghi nhận theo policy\.

    

#### 3\.1\.3\.4 Receipt and inquiry relationships

##### SalesOrder — SalesReceipt

```Plain Text
SalesOrder 1 ─── 0..n SalesReceipt
```

Quan hệ `0..n` hỗ trợ versioning\.

Quy tắc:

- Một SalesOrder có thể chưa có persisted receipt nếu receipt chỉ được sinh khi cần\.

- Một SalesOrder có thể có nhiều SalesReceipt versions\.

- Mỗi SalesReceipt chỉ thuộc một SalesOrder\.

- Receipt phải được sinh từ SalesOrder commercial snapshot\.

- Receipt không được tính lại giá từ Product hoặc Pricing hiện hành\.

- Receipt không phải EInvoice\.

- Receipt mới không được làm mất receipt version cũ nếu policy yêu cầu audit\.

    

##### SalesReceipt — SalesReceiptActivity

```Plain Text
SalesReceipt 1 ─── 0..n SalesReceiptActivity
```

Quy tắc:

- Một SalesReceipt có thể được in hoặc chia sẻ nhiều lần\.

- Mỗi activity chỉ thuộc một SalesReceipt\.

- Activity type gồm tối thiểu:

    - `printed`

    - `shared`

    - `archived`

- Printed và shared không phải lifecycle state loại trừ nhau\.

- Activity phải lưu actor, timestamp, channel/device nếu cần\.

- Receipt activity không làm thay đổi SalesOrder lifecycle\.

    

##### Authoritative entities — read models

```Plain Text
SalesOrder
SalesOrderSettlement
SalesPaymentTransaction
OrderAdjustment
SalesOrderCancellation
ReturnExchangeOrder
SalesReceipt
Integration records
        │
        └── derived into:
            ├── SalesOrderListView
            ├── SalesOrderDetailView
            ├── SalesOrderTimelineView
            ├── SalesOrderPaymentSummaryView
            ├── SalesOrderReturnSummaryView
            └── SalesOrderIntegrationStatusView
```

Quy tắc:

- Read model không phải aggregate\.

- Read model không được ghi ngược vào source entities\.

- Read model có thể eventual\.

- Mỗi field quan trọng phải truy được về source authoritative\.

- Khi projection không đồng bộ, hệ thống phải rebuild hoặc retry; không sửa source để khớp projection\.

- UI state như empty, no\-result, loading và error không được lưu như business state\.

    

### 3\.1\.4 Cross\-cutting and integration relationships

#### Business source — IdempotencyRecord

```Plain Text
Command execution 1 ─── 1 IdempotencyRecord
```

Áp dụng cho các command bắt buộc idempotent\.

Quy tắc:

- IdempotencyRecord được xác định bằng tenant, command scope và idempotency key\.

- Record lưu payload hash và command result\.

- Một idempotency key không được tái sử dụng với payload khác\.

- IdempotencyRecord có thể lưu result reference tới:

    - CheckoutAttempt

    - SalesOrder

    - SalesPaymentTransaction

    - SalesOrderCancellation

    - ReturnExchangeOrder

- IdempotencyRecord không sở hữu business result\.

    

#### Business aggregate — impact request

```Plain Text
SalesOrder                1 ─── 0..n InventoryImpactRequest
SalesOrderSettlement      1 ─── 0..n ReceivableImpactRequest
SalesOrder                1 ─── 0..n EInvoiceImpactRequest

SalesOrderCancellation    1 ─── 0..n ImpactRequest
ReturnExchangeOrder       1 ─── 0..n ImpactRequest
```



Impact request dùng source reference:

```Plain Text
source_type
source_id
source_version
impact_type
```

Quy tắc:

- Một business source có thể tạo nhiều impact types\.

- Mỗi impact request chỉ đại diện cho một business intent cụ thể\.

- Impact request không phải downstream ledger entry\.

- Impact request phải có idempotency key\.

- Source version mới tạo impact mới; không ghi đè impact cũ đã xử lý\.

- Reverse hoặc correction được biểu diễn bằng impact mới, không xóa impact nguồn\.

    

#### Impact request — IntegrationCommand

```Plain Text
ImpactRequest 1 ─── 1..n IntegrationCommand
```

Quan hệ có thể là `1..n` vì:

- Một business impact có thể cần gửi lại qua nhiều delivery versions\.

- Một impact có thể được route tới nhiều target operations\.

- Provider hoặc target endpoint có thể thay đổi\.

    

Quy tắc:

- IntegrationCommand quản lý delivery, không sở hữu business intent\.

- Payload của IntegrationCommand được tạo từ impact request\.

- Retry không tạo business impact mới\.

- Delivery status không được dùng làm business status\.

- Acknowledgement phải lưu external reference nếu target trả về\.

    

#### Business transaction — OutboxMessage

```Plain Text
Business transaction 1 ─── 1..n OutboxMessage
```

Quy tắc:

- OutboxMessage được ghi trong cùng local transaction với business change\.

- Một business transaction có thể phát nhiều commands/events\.

- OutboxMessage không được tạo sau commit bằng một thao tác không bền vững\.

- Publishing thất bại không rollback business transaction đã commit\.

- Consumer phải xử lý idempotent bằng InboxMessage hoặc cơ chế tương đương\.

    

#### IntegrationCommand — InboxMessage

```Plain Text
IntegrationCommand 1 ─── 0..n consumer InboxMessage
```

InboxMessage thuộc phía consumer hoặc shared platform\.

Quy tắc:

- Mỗi consumer lưu trạng thái xử lý độc lập\.

- Cùng message không được tạo downstream effect nhiều lần\.

- InboxMessage không phải bằng chứng nghiệp vụ của Theme 5\.

- Theme 5 chỉ sử dụng acknowledgement hoặc integration event trả về để cập nhật projection\.

    

### 3\.1\.5 External reference and snapshot relationships

#### SalesOrder — Tenant

```Plain Text
SalesOrder n ─── 1 Tenant
```



- `tenant_id` bắt buộc\.

- Tenant là boundary cao nhất của dữ liệu\.

- Không tồn tại quan hệ giao dịch xuyên tenant\.

- Mọi unique key nghiệp vụ phải bao gồm tenant scope khi phù hợp\.



#### SalesOrder — Store / Location

```Plain Text
SalesOrder n ─── 1 Store / Location
```

- Store/location bắt buộc tại checkout nếu tenant vận hành theo điểm bán\.

- SalesOrder lưu reference và SalesContextSnapshot\.

- Store thay đổi tên hoặc đóng cửa không thay đổi snapshot trên đơn cũ\.

    

#### SalesOrder — PlatformUser

```Plain Text
SalesOrder n ─── 1 seller PlatformUser
```

- SalesOrder lưu actor reference và seller snapshot cần thiết\.

- User bị khóa hoặc đổi tên sau đó không làm mất lịch sử actor\.

    

#### SalesOrder — Partner

```Plain Text
SalesOrder n ─── 0..1 Partner
```

- Đơn khách lẻ có thể không có `customer_partner_id`\.

- Đơn phát sinh công nợ bắt buộc phải có Partner cụ thể\.

- SalesOrder lưu CustomerSnapshot dù có hoặc không giữ Partner reference\.

- Partner merge/archive không thay đổi CustomerSnapshot\.

- Theme 5 không cập nhật Partner master trực tiếp\.

    

#### SalesOrderLine — Product

```Plain Text
SalesOrderLine n ─── 1 Product
```

- Product reference phục vụ traceability\.

- ProductSnapshot phục vụ lịch sử\.

- Product bị inactive sau bán không làm SalesOrderLine mất hiệu lực\.

- Theme 5 không ghi ngược price hoặc quantity vào Product\.

    

#### SalesOrderLine — ProductUnit

```Plain Text
SalesOrderLine n ─── 1 ProductUnit
```

- ProductUnit phải thuộc đúng Product tại checkout\.

- ProductUnitSnapshot bảo toàn đơn vị và conversion context\.

- Thay đổi conversion sau đó không cập nhật giao dịch cũ\.

    

#### SalesOrder / SalesOrderLine — Pricing records

```Plain Text
SalesOrderLine n ─── 0..n applied Pricing / Promotion references
```

- Theme 4 sở hữu Pricing và AppliedPromotion\.

- Theme 5 lưu references cùng PricingSnapshot\.

- Một order line có thể chịu nhiều pricing components\.

- Không dùng pricing reference hiện hành để tính lại historical amount\.

- Pricing reversal hoặc promotion usage reversal được xử lý qua integration command\.

    

#### SalesOrder — Inventory records

```Plain Text
SalesOrder 1 ─── 0..n InventoryReservation
SalesOrder 1 ─── 0..n StockMovement
```

Đây là external references\.

- Theme 7 sở hữu reservation và movement\.

- Theme 5 chỉ lưu external references/status projection nếu cần\.

- Một SalesOrder có thể tạo nhiều movement theo line, warehouse hoặc batch\.

- Inventory movement không được lưu như authoritative table trong Theme 5\.

    

#### SalesOrderSettlement — ReceivableEntry

```Plain Text
SalesOrderSettlement 1 ─── 0..n ReceivableEntry
```

- Theme 6 sở hữu ReceivableEntry\.

- Một settlement có thể liên quan nhiều ledger entries do adjustment hoặc reversal\.

- Theme 5 chỉ lưu external reference và status projection\.

- Outstanding amount trong Settlement và receivable ledger phải được đối soát nhưng không cùng ownership\.

    

#### SalesOrder — EInvoice

```Plain Text
SalesOrder 1 ─── 0..n EInvoice
```

- Theme 8 sở hữu EInvoice\.

- Một SalesOrder có thể có hóa đơn gốc, điều chỉnh, thay thế hoặc hủy\.

- Theme 5 lưu buyer tax snapshot và external invoice references\.

- SalesReceipt và EInvoice là hai loại document khác nhau\.

    

### 3\.1\.6 Cardinality summary

|**Parent / source**|**Relationship**|**Child / target**|**Cardinality**|
|---|---|---|---|
|SalesOrderDraft|owns|SalesOrderDraftLine|1 : 1\.\.n|
|SalesOrderDraft|converts to|SalesOrder|1 : 0\.\.1|
|CheckoutAttempt|sources from|SalesOrderDraft|1 : 0\.\.1|
|CheckoutAttempt|creates|SalesOrder|1 : 0\.\.1|
|SalesOrder|owns|SalesOrderLine|1 : 1\.\.n|
|SalesOrder|associated with|SalesOrderSettlement|1 : 1|
|SalesOrderSettlement|owns|SalesPaymentTransaction|1 : 0\.\.n|
|SalesOrder|source of|OrderAdjustment|1 : 0\.\.n|
|SalesOrder|source of|SalesOrderCancellation|1 : 0\.\.n|
|SalesOrder|source of|ReturnExchangeOrder|1 : 0\.\.n|
|ReturnExchangeOrder|owns|ReturnExchangeLine|1 : 1\.\.n|
|Returned ReturnExchangeLine|references|SalesOrderLine|n : 1|
|ReturnExchangeOrder|owns|ReturnExchangeValuation|1 : 0\.\.1|
|SalesOrder|source of|SalesReceipt|1 : 0\.\.n|
|SalesReceipt|owns|SalesReceiptActivity|1 : 0\.\.n|
|Business source|creates|ImpactRequest|1 : 0\.\.n|
|ImpactRequest|delivered by|IntegrationCommand|1 : 1\.\.n|
|Business transaction|creates|OutboxMessage|1 : 1\.\.n|
|SalesOrder|references|Partner|n : 0\.\.1|
|SalesOrderLine|references|Product|n : 1|
|SalesOrderLine|references|ProductUnit|n : 1|
|SalesOrderSettlement|references|ReceivableEntry|1 : 0\.\.n|
|SalesOrder|references|EInvoice|1 : 0\.\.n|



### 3\.1\.7 Relationship invariants

- RI\-01: Mọi entity Theme 5 phải thuộc đúng một tenant\.

- RI\-02: Child entity không được tồn tại nếu aggregate root không tồn tại\.

- RI\-03: Một SalesOrderDraft chỉ được convert thành tối đa một SalesOrder\.

- RI\-04: Một CheckoutAttempt chỉ được tạo tối đa một SalesOrder\.

- RI\-05: Mỗi SalesOrder phải có ít nhất một SalesOrderLine\.

- RI\-06: Mỗi SalesOrder có chính xác một SalesOrderSettlement\.

- RI\-07: SalesPaymentTransaction chỉ được tạo hoặc thay đổi qua SalesOrderSettlement\.

- RI\-08: Một SalesOrder chỉ được có tối đa một completed cancellation case\.

- RI\-09: Returned ReturnExchangeLine bắt buộc tham chiếu đúng một nguồn thuộc đúng SalesOrder nguồn — SalesOrderLine gốc (`original_sales_order_line_id`) XOR exchange line đã confirmed (`source_exchange_line_id`); xem ADR-9\.

- RI\-10: Tổng returned quantity không vượt remaining returnable quantity của returnable unit được tham chiếu (SalesOrderLine gốc hoặc exchange line đã confirmed; ADR-9)\.

- RI\-11: ReturnExchangeValuation không được tồn tại cho ReturnExchangeOrder khác\.

- RI\-12: Payment/refund transaction từ post\-sale operation phải truy được về source aggregate\.

- RI\-13: SalesReceipt phải được sinh từ commercial snapshot của đúng SalesOrder\.

- RI\-14: Read model không được là source của command thay đổi authoritative entity\.

- RI\-15: ImpactRequest không đồng nghĩa downstream operation đã hoàn tất\.

- RI\-16: Reference ID hiện hành không được dùng để ghi đè historical snapshot\.

- RI\-17: Cross\-theme references không tạo quyền direct\-update entity của theme khác\.

- RI\-18: Retry command hoặc integration delivery không được tạo duplicate business effect\.

## 3\.2 Entity relationship diagram

### 3\.2\.1 Core business ERD

```mermaid
erDiagram
    SALES_ORDER_DRAFT ||--|{ SALES_ORDER_DRAFT_LINE : contains

    SALES_ORDER_DRAFT o|--o{ CHECKOUT_ATTEMPT : attempted_from
    SALES_ORDER_DRAFT o|--o| SALES_ORDER : converts_to

    CHECKOUT_ATTEMPT ||--o| SALES_ORDER : creates

    SALES_ORDER ||--|{ SALES_ORDER_LINE : contains

    SALES_ORDER ||--|| SALES_ORDER_SETTLEMENT : has
    SALES_ORDER_SETTLEMENT ||--o{ SALES_PAYMENT_TRANSACTION : records

    SALES_ORDER ||--o{ ORDER_ADJUSTMENT : adjusted_by
    SALES_ORDER ||--o{ SALES_ORDER_CANCELLATION : cancellation_cases
    SALES_ORDER ||--o{ RETURN_EXCHANGE_ORDER : return_exchange_cases

    RETURN_EXCHANGE_ORDER ||--|{ RETURN_EXCHANGE_LINE : contains
    RETURN_EXCHANGE_ORDER ||--o| RETURN_EXCHANGE_VALUATION : valued_by

    SALES_ORDER_LINE o|--o{ RETURN_EXCHANGE_LINE : original_line_for

    SALES_ORDER ||--o{ SALES_RECEIPT : produces
    SALES_RECEIPT ||--o{ SALES_RECEIPT_ACTIVITY : activities```

**Relationship notes:**

- Một `sales_order_draft` có một hoặc nhiều `sales_order_draft_lines`\.

- Một draft có thể phát sinh nhiều checkout attempts nhưng chỉ được convert thành tối đa một SalesOrder\.

- CheckoutAttempt có thể bắt nguồn từ working state chưa được lưu draft\.

- Một CheckoutAttempt chỉ được tạo tối đa một SalesOrder\.

- Một SalesOrder có một hoặc nhiều SalesOrderLines\.

- Mỗi SalesOrder có chính xác một SalesOrderSettlement\.

- Một Settlement có thể chưa có payment transaction nếu đơn hoàn toàn ghi nợ\.

- Một SalesOrder có thể có nhiều adjustment cases\.

- Một SalesOrder có thể có nhiều cancellation cases nhưng chỉ tối đa một case hoàn tất thành công\.

- Một SalesOrder có thể phát sinh nhiều ReturnExchangeOrders\.

- Một ReturnExchangeOrder có một hoặc nhiều ReturnExchangeLines\.

- ReturnExchangeValuation chỉ tồn tại sau khi nghiệp vụ đổi/trả được định giá\.

- Returned ReturnExchangeLine tham chiếu SalesOrderLine gốc\.

- Exchange ReturnExchangeLine không bắt buộc tham chiếu SalesOrderLine gốc\.

- Một SalesOrder có thể có nhiều receipt versions\.

- Một SalesReceipt có thể có nhiều print, share hoặc archive activities\.

    

### 3\.2\.2 Aggregate ownership view

```mermaid
flowchart LR
    subgraph D1["Sales Order Lifecycle"]
        SOD[SalesOrderDraft]
        SODL[SalesOrderDraftLine]
        CA[CheckoutAttempt]
        SO[SalesOrder]
        SOL[SalesOrderLine]

        SOD --> SODL
        SOD --> CA
        CA --> SO
        SO --> SOL
    end

    subgraph D2["Sales Settlement"]
        SOS[SalesOrderSettlement]
        SPT[SalesPaymentTransaction]

        SOS --> SPT
    end

    subgraph D3["Post-sale Operations"]
        OA[OrderAdjustment]
        SOC[SalesOrderCancellation]
        REO[ReturnExchangeOrder]
        REL[ReturnExchangeLine]
        REV[ReturnExchangeValuation]

        REO --> REL
        REO --> REV
    end

    subgraph D4["Sales Order Inquiry & Documents"]
        SR[SalesReceipt]
        SRA[SalesReceiptActivity]

        SR --> SRA
    end

    SO --> SOS
    SO --> OA
    SO --> SOC
    SO --> REO
    SOL --> REL
    SO --> SR```

**Ownership rules:**

- Sales Order Lifecycle sở hữu draft, checkout process, SalesOrder và SalesOrderLine\.

- Sales Settlement sở hữu settlement và payment transactions\.

- Post\-sale Operations sở hữu adjustment, cancellation case và return/exchange\.

- Sales Order Inquiry \& Documents sở hữu receipt và receipt activities\.

- Mối quan hệ giữa các aggregate không cho phép domain này direct\-update entity thuộc domain khác\.

    

### 3\.2\.3 External reference ERD

```mermaid
erDiagram
    TENANT ||--o{ SALES_ORDER_DRAFT : contains
    TENANT ||--o{ CHECKOUT_ATTEMPT : contains
    TENANT ||--o{ SALES_ORDER : contains
    TENANT ||--o{ SALES_ORDER_SETTLEMENT : contains
    TENANT ||--o{ RETURN_EXCHANGE_ORDER : contains

    STORE ||--o{ SALES_ORDER_DRAFT : draft_location
    STORE ||--o{ SALES_ORDER : sale_location

    PLATFORM_USER ||--o{ SALES_ORDER_DRAFT : created_by
    PLATFORM_USER ||--o{ SALES_ORDER : seller
    PLATFORM_USER ||--o{ ORDER_ADJUSTMENT : requested_by
    PLATFORM_USER ||--o{ SALES_ORDER_CANCELLATION : requested_by
    PLATFORM_USER ||--o{ RETURN_EXCHANGE_ORDER : created_by
    PLATFORM_USER ||--o{ SALES_RECEIPT_ACTIVITY : performed_by

    PARTNER o|--o{ SALES_ORDER : customer_for

    PRODUCT ||--o{ SALES_ORDER_DRAFT_LINE : selected_as
    PRODUCT_UNIT ||--o{ SALES_ORDER_DRAFT_LINE : selected_unit

    PRODUCT ||--o{ SALES_ORDER_LINE : referenced_by
    PRODUCT_UNIT ||--o{ SALES_ORDER_LINE : referenced_by

    PRODUCT ||--o{ RETURN_EXCHANGE_LINE : referenced_by
    PRODUCT_UNIT ||--o{ RETURN_EXCHANGE_LINE : referenced_by

    APPLIED_PRICING_RESULT o{--o{ SALES_ORDER_LINE : pricing_source
    APPLIED_PROMOTION o{--o{ SALES_ORDER_LINE : promotion_source

    SALES_ORDER ||--o{ INVENTORY_RESERVATION : reserves
    SALES_ORDER ||--o{ STOCK_MOVEMENT : produces

    SALES_ORDER_SETTLEMENT ||--o{ RECEIVABLE_ENTRY : represented_by

    SALES_ORDER ||--o{ E_INVOICE : invoiced_by```

**External reference notes**

- `Tenant`, `Store`, `PlatformUser`, `Partner`, `Product` và `ProductUnit` thuộc domain khác\.

- Theme 5 chỉ tham chiếu các entity này và lưu transaction snapshots khi cần\.

- Đơn khách lẻ có thể không tham chiếu Partner cụ thể\.

- Đơn phát sinh công nợ bắt buộc phải có Partner cụ thể\.

- SalesOrderLine giữ Product/ProductUnit reference nhưng lịch sử hiển thị dựa trên snapshot\.

- Pricing và Promotion thuộc Theme 4\.

- InventoryReservation và StockMovement thuộc Theme 7\.

- ReceivableEntry thuộc Theme 6\.

- EInvoice thuộc Theme 8\.

- External references không tạo ownership hoặc quyền direct\-update cho Theme 5\.

    

### 3\.2\.4 Integration and technical ERD

```mermaid
erDiagram
    SALES_ORDER ||--o{ INVENTORY_IMPACT_REQUEST : creates
    SALES_ORDER_CANCELLATION ||--o{ INVENTORY_IMPACT_REQUEST : creates
    RETURN_EXCHANGE_ORDER ||--o{ INVENTORY_IMPACT_REQUEST : creates

    SALES_ORDER_SETTLEMENT ||--o{ RECEIVABLE_IMPACT_REQUEST : creates
    SALES_ORDER_CANCELLATION ||--o{ RECEIVABLE_IMPACT_REQUEST : creates
    RETURN_EXCHANGE_ORDER ||--o{ RECEIVABLE_IMPACT_REQUEST : creates

    SALES_ORDER ||--o{ E_INVOICE_IMPACT_REQUEST : creates
    SALES_ORDER_CANCELLATION ||--o{ E_INVOICE_IMPACT_REQUEST : creates
    ORDER_ADJUSTMENT ||--o{ E_INVOICE_IMPACT_REQUEST : creates
    RETURN_EXCHANGE_ORDER ||--o{ E_INVOICE_IMPACT_REQUEST : creates

    INVENTORY_IMPACT_REQUEST ||--|{ INTEGRATION_COMMAND : delivered_by
    RECEIVABLE_IMPACT_REQUEST ||--|{ INTEGRATION_COMMAND : delivered_by
    E_INVOICE_IMPACT_REQUEST ||--|{ INTEGRATION_COMMAND : delivered_by

    INTEGRATION_COMMAND ||--|{ OUTBOX_MESSAGE : published_through
    OUTBOX_MESSAGE ||--o{ INBOX_MESSAGE : consumed_as

    CHECKOUT_ATTEMPT ||--o| IDEMPOTENCY_RECORD : protected_by
    SALES_PAYMENT_TRANSACTION ||--o| IDEMPOTENCY_RECORD : protected_by
    SALES_ORDER_CANCELLATION ||--o| IDEMPOTENCY_RECORD : protected_by
    RETURN_EXCHANGE_ORDER ||--o| IDEMPOTENCY_RECORD : protected_by```

**Integration relationship notes**

- Business entities tạo impact requests thể hiện tác động cần gửi sang domain khác\.

- Impact request không phải downstream ledger record\.

- Một impact request có thể được delivery bởi một hoặc nhiều IntegrationCommands\.

- Retry delivery không tạo impact request mới\.

- IntegrationCommand quản lý việc giao command, không sở hữu business intent\.

- OutboxMessage bảo đảm durable delivery sau local transaction\.

- InboxMessage giúp consumer chống xử lý trùng\.

- IdempotencyRecord bảo vệ command khỏi tạo duplicate business effect\.

- IdempotencyRecord không sở hữu kết quả nghiệp vụ\.

    

### 3\.2\.5 Read\-model projection diagram

```mermaid
flowchart LR
    SO[SalesOrder]
    SOS[SalesOrderSettlement]
    SPT[SalesPaymentTransaction]
    OA[OrderAdjustment]
    SOC[SalesOrderCancellation]
    REO[ReturnExchangeOrder]
    SR[SalesReceipt]
    IR[Integration records]

    LIST[SalesOrderListView]
    DETAIL[SalesOrderDetailView]
    TIMELINE[SalesOrderTimelineView]
    PAYMENT[SalesOrderPaymentSummaryView]
    RETURN[SalesOrderReturnSummaryView]
    SYNC[SalesOrderIntegrationStatusView]

    SO --> LIST
    SO --> DETAIL
    SO --> TIMELINE

    SOS --> LIST
    SOS --> DETAIL
    SOS --> PAYMENT

    SPT --> PAYMENT
    SPT --> TIMELINE

    OA --> DETAIL
    OA --> TIMELINE

    SOC --> DETAIL
    SOC --> TIMELINE

    REO --> DETAIL
    REO --> RETURN
    REO --> TIMELINE

    SR --> DETAIL
    SR --> TIMELINE

    IR --> DETAIL
    IR --> SYNC```

**Read\-model rules:**

- Read models không phải transactional entities\.

- Read models không sở hữu hoặc thay đổi authoritative state\.

- Read models có thể được xây dựng bằng runtime query, database view, materialized view hoặc projection table\.

- Read model có thể eventual\.

- Mỗi thông tin quan trọng trong read model phải truy được về authoritative source\.

- Projection failure phải được retry hoặc rebuild, không sửa business entity để ép dữ liệu khớp\.

    

### 3\.2\.6 Embedded models excluded from ERD

Các model sau được embedded trong entity sở hữu và không được thể hiện thành entity riêng trong ERD:

|**Embedded model**|**Owner entity**|
|---|---|
|SalesContextSnapshot|`sales_orders`|
|CustomerSnapshot|`sales_orders`|
|BuyerTaxSnapshot|`sales_orders` hoặc E\-invoice impact request|
|MonetarySummary|`sales_orders`|
|ProductSnapshot|`sales_order_lines`|
|ProductUnitSnapshot|`sales_order_lines`|
|PricingSnapshot|`sales_order_lines` và/hoặc `sales_orders`|
|SettlementSummary|`sales_order_settlements`|
|AdjustmentDiff|`order_adjustments`|
|ReturnExchangeSummary|`return_exchange_valuations`|
|ReceiptSnapshot|`sales_receipts`|

### 3\.2\.7 ERD relationship constraints

- ERI\-01: Một SalesOrderDraft có ít nhất một SalesOrderDraftLine\.

- ERI\-02: Một SalesOrderDraft chỉ được convert thành tối đa một SalesOrder\.

- ERI\-03: Một CheckoutAttempt chỉ được tạo tối đa một SalesOrder\.

- ERI\-04: Một SalesOrder có ít nhất một SalesOrderLine\.

- ERI\-05: Mỗi SalesOrder có chính xác một SalesOrderSettlement\.

- ERI\-06: SalesPaymentTransaction chỉ thuộc một SalesOrderSettlement\.

- ERI\-07: Một SalesOrder chỉ được có tối đa một completed cancellation case\.

- ERI\-08: Một ReturnExchangeOrder có ít nhất một ReturnExchangeLine\.

- ERI\-09: Returned ReturnExchangeLine phải tham chiếu SalesOrderLine thuộc SalesOrder nguồn\.

- ERI\-10: Một ReturnExchangeOrder có tối đa một authoritative ReturnExchangeValuation\.

- ERI\-11: Một SalesReceipt chỉ thuộc một SalesOrder\.

- ERI\-12: Một SalesReceiptActivity chỉ thuộc một SalesReceipt\.

- ERI\-13: Impact request phải truy được về business source\.

- ERI\-14: IntegrationCommand phải truy được về impact request nguồn\.

- ERI\-15: Read model không được là source of truth của business command\.

- ERI\-16: Cross\-theme reference không tạo quyền ownership cho Theme 5\.

## 3\.3 Entity catalog

### 3\.3\.1 Catalog principles

Entity catalog của Theme 5 tuân theo các nguyên tắc:

- Mỗi persisted entity phải có một owner duy nhất\.

- Business entity, process record, integration record, read model và referenced model phải được phân loại riêng\.

- Aggregate ownership không phụ thuộc vào việc các bảng được triển khai chung hay khác database\.

- Commercial snapshot có thể được lưu trong entity sở hữu giao dịch mà không cần tạo một table riêng cho từng loại snapshot\.

- Read model chỉ phục vụ truy vấn và không được ghi ngược vào authoritative entities\.

- Technical record như idempotency, outbox và delivery command không phải business entity\.

- Theme 5 không lưu bản sao master data thay cho Product, Partner, Store hoặc User\.

- Dữ liệu lịch sử của đơn phải được bảo toàn bằng snapshot tại thời điểm checkout\.

    

### 3\.3\.2 Persisted business entities

|**Scope**|**Logical entity**|**Physical storage**|**Ownership**|**Purpose**|**Notes**|
|---|---|---|---|---|---|
|Core aggregate root<br>|SalesOrderDraft|`sales_order_drafts`|Sales Order Lifecycle|Lưu đơn nháp do người dùng chủ động giữ lại để xử lý sau|Không phải doanh thu; không tạo payment, công nợ hoặc inventory impact|
|Core child entity|SalesOrderDraftLine|`sales_order_draft_lines`|Sales Order Lifecycle|Lưu các dòng hàng thuộc SalesOrderDraft|Giá chỉ là preview; phải validate lại khi checkout|
|Process record|CheckoutAttempt|`checkout_attempts`|Sales Order Lifecycle|Theo dõi quá trình, idempotency result và trạng thái uncertain của checkout|Không phải chứng từ bán hàng hoặc aggregate tài chính|
|Core aggregate root|SalesOrder|`sales_orders`|Sales Order Lifecycle|Giao dịch bán hàng chính thức sau checkout thành công|Owner của commercial snapshot và order lifecycle|
|Core child entity|SalesOrderLine|`sales_order_lines`|Sales Order Lifecycle|Lưu các dòng hàng chính thức của SalesOrder|Chứa product, unit, quantity, price và discount snapshot|
|Supporting aggregate root|SalesOrderSettlement|`sales_order_settlements`|Sales Settlement|Quản lý trạng thái quyết toán hiện tại của một SalesOrder|Quan hệ tối đa 1–1 với SalesOrder|
|Supporting child entity|SalesPaymentTransaction|`sales_payment_transactions`|Sales Settlement|Ghi nhận khoản thu, hoàn tiền, void hoặc điều chỉnh tiền có kiểm soát|Thay thế PaymentRecord, RefundRecord và AdditionalPayment riêng lẻ|
|Post\-sale aggregate root|OrderAdjustment|`order_adjustments`|Post\-sale Operations|Lưu điều chỉnh sau bán thuộc whitelist được phép|Lưu before/after diff; không ghi đè commercial snapshot|
|Post\-sale aggregate root|SalesOrderCancellation|`sales_order_cancellations`|Post\-sale Operations|Lưu hồ sơ, lý do, precheck và kết quả hủy đơn|Không trực tiếp sở hữu lifecycle status của SalesOrder|
|Post\-sale aggregate root|ReturnExchangeOrder|`return_exchange_orders`|Post\-sale Operations|Lưu nghiệp vụ trả hàng, đổi hàng hoặc đổi/trả kết hợp mua thêm|Phải tham chiếu SalesOrder nguồn|
|Post\-sale child entity|ReturnExchangeLine|`return_exchange_lines`|Post\-sale Operations|Lưu hàng khách trả và hàng khách nhận đổi/mua thêm|Dùng `line_role` để phân biệt `returned` và `exchange`|
|Post\-sale value entity|ReturnExchangeValuation|`return_exchange_valuations`|Post\-sale Operations|Lưu giá trị hàng trả, hàng đổi và chênh lệch cần quyết toán|Thay thế `return_settlements`; không ghi payment/refund authoritative|
|Document aggregate root|SalesReceipt|`sales_receipts`|Sales Order Inquiry \& Documents|Lưu phiên bản phiếu bán hàng nội bộ được sinh từ SalesOrder snapshot|Không phải hóa đơn điện tử|
|Document activity entity|SalesReceiptActivity|`sales_receipt_activities`|Sales Order Inquiry \& Documents|Lưu các lần in, chia sẻ hoặc archive receipt nếu cần truy vết|Print và share là activity, không phải mutually exclusive status|

### 3\.3\.3 Entity ownership summary

|**Business domain**|**Owned persisted entities**|
|---|---|
|Sales Order Lifecycle|`sales_order_drafts`, <br>`sales_order_draft_lines`, <br>`checkout_attempts`, <br>`sales_orders`, <br>`sales_order_lines`|
|Sales Settlement|`sales_order_settlements`, <br>`sales_payment_transactions`|
|Post\-sale Operations|`order_adjustments`, <br>`sales_order_cancellations`, <br>`return_exchange_orders`, <br>`return_exchange_lines`, <br>`return_exchange_valuations`|
|Sales Order Inquiry \& Documents|`sales_receipts`, <br>`sales_receipt_activities`|

**Ownership rules:**

- Chỉ Sales Order Lifecycle được thay đổi authoritative lifecycle của SalesOrder\.

- Chỉ Sales Settlement được thay đổi authoritative payment status và settlement amounts\.

- Chỉ Post\-sale Operations được xác nhận adjustment, cancellation case và return/exchange\.

- Inquiry \& Documents không được sửa dữ liệu nguồn của ba domain còn lại\.

- Không service hoặc domain nào được direct\-update table thuộc owner khác\.

    

### 3\.3\.4 Cross\-cutting and integration records

|**Scope**|**Logical entity**|**Physical storage**|**Ownership**|**Purpose**|**Notes**|
|---|---|---|---|---|---|
|Technical process|IdempotencyRecord|`idempotency_records`|Shared transaction foundation|Chống tạo trùng khi command được retry|Không phải business entity|
|Integration delivery|IntegrationCommand|`integration_commands`|Integration delivery foundation|Lưu durable command cần gửi sang domain khác|Quản lý delivery status, retry và acknowledgement|
|Inventory integration|InventoryImpactRequest|`inventory_impact_requests`|Theme 5 integration foundation|Lưu tác động tồn kho mà giao dịch bán hoặc post\-sale yêu cầu|Không phải stock movement hoặc inventory ledger|
|Receivable integration|ReceivableImpactRequest|`receivable_impact_requests`|Theme 5 integration foundation|Lưu yêu cầu tạo, điều chỉnh, reverse hoặc cấn trừ công nợ|Không phải receivable ledger|
|Optional integration|EInvoiceImpactRequest|`e_invoice_impact_requests`|Theme 5 integration foundation|Lưu yêu cầu phát hành hoặc xử lý HĐĐT từ SalesOrder/post\-sale source|Chỉ tạo nếu không dùng hoàn toàn generic IntegrationCommand|
|Outbox|OutboxMessage|`outbox_messages`|Shared transaction foundation|Bảo đảm event/command được phát hành sau local commit|Có thể dùng platform\-wide table|
|Inbox|InboxMessage|`inbox_messages`|Shared transaction foundation|Chống consumer xử lý trùng message|Có thể dùng platform\-wide table|

**Structural rules:**

- Business change và record cần gửi downstream phải được ghi trong cùng local transaction\.

- `integration_commands` quản lý delivery; các impact request lưu business intent\.

- Không dùng delivery status làm business lifecycle status\.

- Cùng idempotency key và cùng payload phải trả lại cùng kết quả\.

- Cùng idempotency key nhưng payload khác phải trả conflict\.

- InventoryImpactRequest không được coi là bằng chứng rằng stock movement đã hoàn tất\.

- ReceivableImpactRequest không được coi là receivable entry đã được post\.

- EInvoiceImpactRequest không phải hóa đơn điện tử\.

    

### 3\.3\.5 Referenced entities and external records

|**Scope**|**Logical entity**|**Physical storage / source**|**Ownership**|**Purpose in Theme 5**|**Notes**|
|---|---|---|---|---|---|
|Referenced|Tenant|`tenants`|Theme 1|Xác định tenant boundary của mọi giao dịch|Theme 5 không sửa Tenant|
|Referenced|Store / Location|Store\-owned storage|Theme 1 / Store operations|Xác định điểm bán và phạm vi vận hành|Lưu reference và snapshot cần thiết trên SalesOrder|
|Referenced|PlatformUser|Platform Identity|Platform Identity|Xác định actor thực hiện giao dịch|Không tạo user profile trong Theme 5|
|Referenced|TenantMembership|`tenant_memberships`|Theme 1|Kiểm tra membership, role và data scope|Quyền phải validate tại command time|
|Referenced|Partner|`partners`|Theme 3|Gắn khách hàng cụ thể vào đơn|Theme 5 lưu customer snapshot riêng|
|Referenced|Product|`products`|Theme 2|Chọn sản phẩm để bán hoặc đổi|Không dùng current product để render lại giao dịch cũ|
|Referenced|ProductUnit|`product_units`|Theme 2|Xác định đơn vị bán và quy đổi hợp lệ|SalesOrderLine lưu unit snapshot|
|Referenced|AppliedPricingResult|Theme 4 pricing records|Theme 4|Xác định giá và ưu đãi áp dụng tại checkout|Theme 5 lưu pricing snapshot và source references|
|Referenced|AppliedPromotion|Theme 4 applied\-promotion storage|Theme 4|Tham chiếu chương trình khuyến mại đã được commit|Không tự thay đổi promotion usage|
|Referenced|InventoryReservation|Inventory storage|Theme 7|Bảo đảm tồn kho trước checkout nếu policy yêu cầu|Theme 5 chỉ lưu reservation reference|
|Referenced|StockMovement|Inventory ledger|Theme 7|Xác nhận tác động xuất/nhập/reverse tồn kho|Không được copy thành inventory ledger trong Theme 5|
|Referenced|ReceivableEntry|Receivable ledger|Theme 6|Tham chiếu khoản phải thu được tạo từ SalesOrder|Theme 5 chỉ lưu external reference/status projection|
|Referenced|EInvoice|E\-invoice storage|Theme 8|Tham chiếu hóa đơn điện tử phát hành từ giao dịch|SalesReceipt không phải EInvoice|
|Referenced|AuditLog|Platform Audit|Platform Audit|Lưu audit xuyên theme cho command nhạy cảm|Không tạo `order_audit_logs` riêng trong Theme 5|
|Referenced|PaymentMethod|Tenant/system configuration|Configuration owner|Xác định phương thức thanh toán được phép sử dụng|Payment transaction lưu method snapshot/code|

### 3\.3\.6 Embedded snapshot and value models

Các model dưới đây là logical value models được lưu bên trong business entities\. Chúng không mặc định có physical table riêng\.

|**Scope**|**Logical model**|**Persisted within**|**Ownership**|**Purpose**|**Notes**|
|---|---|---|---|---|---|
|Snapshot<br>|SalesContextSnapshot<br>|`sales_orders`|Sales Order Lifecycle|Lưu store, seller, channel, shift và business time tại checkout|Không thay bằng context hiện hành khi xem đơn cũ|
|Snapshot|CustomerSnapshot|`sales_orders`|Sales Order Lifecycle|Lưu tên, liên hệ và thông tin nhận diện khách tại checkout|Có thể tồn tại cùng `customer_partner_id`|
|Snapshot|BuyerTaxSnapshot|`sales_orders` hoặc E\-invoice request|Sales Order Lifecycle|Lưu buyer/tax information dùng cho chứng từ và HĐĐT|Tách khỏi current Partner profile|
|Snapshot|ProductSnapshot|`sales_order_lines`|Sales Order Lifecycle|Lưu tên, SKU, barcode và đặc điểm nhận diện của sản phẩm|Không tạo bản sao Product master|
|Snapshot|ProductUnitSnapshot|`sales_order_lines`|Sales Order Lifecycle|Lưu đơn vị bán, conversion context và display label|Không thay đổi khi ProductUnit hiện hành thay đổi|
|Snapshot|PricingSnapshot|`sales_order_lines` và/hoặc `sales_orders`|Sales Order Lifecycle|Lưu giá áp dụng, nguồn giá, discount, promotion và override|Không phải Pricing rule|
|Value model|MonetarySummary|`sales_orders`|Sales Order Lifecycle|Lưu subtotal, discount, tax, rounding và payable amount tại checkout|Bất biến sau checkout|
|Value model|SettlementSummary|`sales_order_settlements`|Sales Settlement|Lưu paid, refunded, net collected, outstanding và payment status hiện tại|Có thể rebuild từ payment transactions|
|Value model|AdjustmentDiff|`order_adjustments`|Post\-sale Operations|Lưu before/after của adjustment|Chỉ chứa field thuộc whitelist|
|Value model|ReturnExchangeSummary|`return_exchange_valuations`|Post\-sale Operations|Lưu return value, exchange value, net difference và required settlement type|Không thay thế SalesOrderSettlement|
|Snapshot|ReceiptSnapshot|`sales_receipts`|Inquiry \& Documents|Lưu nội dung/version dùng để render receipt chính xác|Có thể lưu JSON payload và template version|

**Structural rules:**

- Snapshot có thể dùng JSON/JSONB hoặc các field typed tùy nhu cầu truy vấn\.

- Các field quan trọng cho báo cáo và indexing không nên chỉ nằm trong JSON không có projection\.

- Snapshot không có lifecycle độc lập\.

- Không tạo FK bắt buộc từ snapshot tới master data hiện hành\.

- Reference ID và snapshot có thể cùng tồn tại: reference phục vụ liên kết hiện hành, snapshot phục vụ lịch sử\.

    

### 3\.3\.7 Derived and read models

Các model dưới đây phục vụ truy vấn\. Phase 1 có thể xây dựng trực tiếp từ authoritative tables hoặc triển khai dưới dạng database view/materialized projection\. Không bắt buộc tạo table riêng ngay từ đầu\.

|**Scope**|**Logical model**|**Persistence**|**Ownership**|**Purpose**|**Notes**|
|---|---|---|---|---|---|
|Runtime<br>|SalesOrderWorkingState|Client/session memory|Sales Order Lifecycle application layer|Trạng thái đơn đang lập trước khi lưu draft hoặc checkout|Không phải persisted entity|
|Read model|SalesOrderListView|Derived / optional projection|Inquiry \& Documents|Danh sách đơn theo ngày, store, customer và status|Không ghi ngược vào `sales_orders`|
|Read model|SalesOrderDetailView|Derived / optional projection|Inquiry \& Documents|Tổng hợp order snapshot, settlement, post\-sale và integration status|Có thể lấy từ nhiều authoritative sources|
|Read model|SalesOrderTimelineView|Derived / optional projection|Inquiry \& Documents|Hiển thị timeline của order, payment, adjustment, cancellation và đổi/trả|Nguồn từ domain events và Platform Audit|
|Read model|SalesOrderPaymentSummaryView|Derived|Inquiry \& Documents|Hiển thị đã thu, đã hoàn, còn phải thu và payment status|Source of truth là SalesOrderSettlement|
|Read model|SalesOrderReturnSummaryView|Derived|Inquiry \& Documents|Hiển thị trạng thái và giá trị đổi/trả|Source of truth là ReturnExchangeOrder|
|Read model|SalesOrderIntegrationStatusView|Derived|Inquiry \& Documents|Tổng hợp Inventory, Receivable, E\-invoice và Reporting status|Không trộn vào order lifecycle|
|Read model|ReturnableOrderLineView|Runtime query result|Post\-sale Operations|Tính số lượng còn có thể trả của từng returnable unit (SalesOrderLine gốc hoặc exchange line đã confirmed; ADR-9)|Phải tính từ dữ liệu mới nhất|
|Read model|CheckoutResultView|Runtime / query result|Sales Order Lifecycle application layer|Trả kết quả checkout hoặc uncertain recovery|Không phải business entity|
|Read model|PostSaleResultView|Runtime / query result|Post\-sale application layer|Tổng hợp kết quả cancellation, adjustment hoặc return/exchange|Không phải source of truth|

## 3\.4 Entity fields



### 3\.4\.1 Field conventions



Các entity trong Theme 5 sử dụng các quy ước chung sau:



|Convention|Rule|
|---|---|
|Identifier|Sử dụng `UUID`|
|Tenant boundary|Mọi persisted record thuộc Theme 5 phải có `tenant_id`|
|Monetary amount|Sử dụng `decimal(19,4)`|
|Quantity|Sử dụng `decimal(19,6)`|
|Currency|Sử dụng mã ISO 4217 dạng `char(3)`|
|Timestamp|Sử dụng `timestamptz`, lưu theo UTC|
|Optimistic locking|Aggregate root có field `version`|
|Snapshot|Sử dụng `jsonb` khi dữ liệu không cần query trực tiếp thường xuyên|
|Enum|Tên enum trong tài liệu là logical enum; implementation có thể dùng database enum hoặc constrained varchar|
|Soft lifecycle|Không hard delete giao dịch đã phát sinh|
|Cross\-theme FK|FK target thể hiện logical reference; physical FK phụ thuộc architecture của từng theme|
|Polymorphic source|`source_type + source_id` là logical reference, không phải physical FK|
|Audit fields|Actor, reason và timestamps phải được lưu trên action nhạy cảm|



Các composite unique constraints, indexes và conditional constraints được tổng hợp tại `3.4.7 Field constraints`\.



### 3\.4\.2 Sales Order Lifecycle entities



#### 3\.4\.2\.1 `sales_order_drafts`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh SalesOrderDraft|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|store\_id|UUID|Yes|FK|stores\.id|Điểm bán đang lập draft|
|sales\_shift\_id|UUID|No|FK|sales\_shifts\.id|Bắt buộc nếu tenant bật quản lý ca|
|created\_by\_user\_id|UUID|Yes|FK|platform\_users\.id|Người tạo draft|
|customer\_partner\_id|UUID|No|FK|partners\.id|Khách hàng được chọn trên draft|
|status|enum|Yes|—|—|`active`, `converted`, `cancelled`, `expired`|
|currency\_code|char\(3\)|Yes|—|—|Tiền tệ dùng để preview|
|note|text|No|—|—|Ghi chú đang lập đơn|
|version|bigint|Yes|—|—|Optimistic concurrency; bắt đầu từ `1`|
|expires\_at|timestamptz|No|—|—|Thời điểm draft tự hết hạn|
|converted\_at|timestamptz|No|—|—|Có giá trị khi status là `converted`|
|cancelled\_at|timestamptz|No|—|—|Có giá trị khi draft bị hủy|
|expired\_at|timestamptz|No|—|—|Có giá trị khi draft hết hạn|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



Rules:



- Draft `active` phải có ít nhất một draft line trước khi được coi là persisted business draft hợp lệ\.

- Draft chưa tạo doanh thu, payment transaction, công nợ hoặc inventory impact\.

- Draft đã `converted`, `cancelled` hoặc `expired` không được cập nhật nội dung\.

    

#### 3\.4\.2\.2 `sales_order_draft_lines`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh draft line|
|tenant\_id|UUID|Yes|FK|tenants\.id|Phải cùng tenant với draft|
|sales\_order\_draft\_id|UUID|Yes|FK|sales\_order\_drafts\.id|Aggregate root|
|line\_sequence|integer|Yes|—|—|Thứ tự hiển thị trong draft|
|product\_id|UUID|Yes|FK|products\.id|Product hiện hành được chọn|
|product\_unit\_id|UUID|Yes|FK|product\_units\.id|Đơn vị bán được chọn|
|quantity|decimal\(19,6\)|Yes|—|—|Phải lớn hơn `0`|
|manual\_unit\_price\_input|decimal\(19,4\)|No|—|—|Giá người dùng nhập nếu được phép override|
|manual\_discount\_amount\_input|decimal\(19,4\)|No|—|—|Discount intent; chưa phải giá trị chính thức|
|pricing\_preview|jsonb|No|—|—|Kết quả preview từ Theme 4|
|line\_note|text|No|—|—|Ghi chú dòng hàng|
|created\_at|timestamptz|Yes|—|—|Thời điểm thêm dòng|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



Rules:



- `pricing_preview` không phải commercial snapshot chính thức\.

- Product, unit, pricing và sellability phải được validate lại khi checkout\.

- `product_unit_id` phải thuộc đúng `product_id`\.

    

#### 3\.4\.2\.3 `checkout_attempts`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh checkout attempt|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|source\_draft\_id|UUID|No|FK|sales\_order\_drafts\.id|Null nếu checkout trực tiếp từ working state|
|store\_id|UUID|Yes|FK|stores\.id|Store tại thời điểm checkout|
|requested\_by\_user\_id|UUID|Yes|FK|platform\_users\.id|Actor gửi checkout|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Unique theo tenant và checkout scope|
|payload\_hash|varchar\(128\)|Yes|—|Kiểm tra cùng key nhưng payload khác||
|request\_snapshot|jsonb|Yes|—|Payload chuẩn hóa tại thời điểm nhận command||
|status|enum|Yes|—|—|`received`, `validating`, `processing`, `succeeded`, `blocked`, `failed`, `uncertain`|
|failure\_type|enum|No|—|—|Failure taxonomy của Theme 5|
|failure\_code|varchar\(100\)|No|—|—|Mã lỗi hoặc blocker chính|
|failure\_message|text|No|—|—|Mô tả kỹ thuật hoặc nghiệp vụ|
|blocker\_codes|jsonb|No|—|—|Danh sách blockers khi checkout bị chặn|
|result\_snapshot|jsonb|No|—|—|Kết quả trả về sau khi resolve|
|correlation\_id|UUID|Yes|—|—|Correlation xuyên toàn flow|
|version|bigint|Yes|—|—|Kiểm soát cập nhật process state|
|received\_at|timestamptz|Yes|—|—|Thời điểm nhận request|
|resolved\_at|timestamptz|No|—|—|Khi attempt có kết quả cuối cùng|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



Rules:

- Một CheckoutAttempt chỉ tạo tối đa một SalesOrder\.

- Retry cùng `idempotency_key` và cùng `payload_hash` phải trả cùng kết quả\.

- Status `succeeded` phải truy được SalesOrder qua `sales_orders.checkout_attempt_id`\.

- Status `uncertain` không cho phép client tự tạo checkout request mới với idempotency key khác\.

    

#### 3\.4\.2\.4 `sales_orders`

|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh SalesOrder|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|source\_draft\_id|UUID|No|FK, UK|sales\_order\_drafts\.id|Unique khi có giá trị|
|checkout\_attempt\_id|UUID|Yes|FK, UK|checkout\_attempts\.id|Checkout attempt thành công|
|order\_code|varchar\(50\)|Yes|UK|—|Unique trong tenant|
|store\_id|UUID|Yes|FK|stores\.id|Store authoritative của giao dịch|
|sales\_shift\_id|UUID|No|FK|sales\_shifts\.id|Ca bán tại thời điểm giao dịch|
|seller\_user\_id|UUID|Yes|FK|platform\_users\.id|Người thực hiện giao dịch|
|customer\_partner\_id|UUID|No|FK|partners\.id|Null với khách lẻ không định danh|
|channel\_code|varchar\(50\)|Yes|—|—|Ví dụ: `pos`, `mobile`, `web`, `integration`|
|business\_time|timestamptz|Yes|—|—|Thời điểm nghiệp vụ tại điểm bán|
|currency\_code|char\(3\)|Yes|—|—|Tiền tệ của đơn|
|lifecycle\_status|enum|Yes|—|—|`completed`, `cancelled`|
|lock\_status|enum|Yes|—|—|`unlocked`, `locked`|
|version|bigint|Yes|—|—|Optimistic concurrency|
|reference\_code|varchar\(100\)|No|—|—|Reference bên ngoài hoặc nội bộ|
|internal\_note|text|No|—|—|Có thể điều chỉnh theo whitelist|
|subtotal\_amount|decimal\(19,4\)|Yes|—|—|Tổng trước discount và tax|
|discount\_amount|decimal\(19,4\)|Yes|—|—|Tổng discount|
|tax\_amount|decimal\(19,4\)|Yes|—|—|Tổng thuế|
|rounding\_amount|decimal\(19,4\)|Yes|—|—|Chênh lệch làm tròn có dấu|
|payable\_amount|decimal\(19,4\)|Yes|—|—|Giá trị phải trả tại checkout|
|sales\_context\_snapshot|jsonb|Yes|—|—|Store, seller, shift, channel và business time snapshot|
|customer\_snapshot|jsonb|Yes|—|—|Khách lẻ hoặc Partner snapshot|
|buyer\_tax\_snapshot|jsonb|No|—|—|Thông tin người mua phục vụ HĐĐT|
|pricing\_summary\_snapshot|jsonb|Yes|—|—|Pricing, promotion và override summary|
|completed\_at|timestamptz|Yes|—|—|Thời điểm checkout commit|
|cancelled\_at|timestamptz|No|—|—|Thời điểm order chuyển sang cancelled|
|locked\_at|timestamptz|No|—|—|Thời điểm khóa|
|locked\_by\_user\_id|UUID|No|FK|platform\_users\.id|Người khóa gần nhất|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Chỉ phản ánh metadata/lifecycle update|



Rules:



- Các commercial amount và snapshot bất biến sau checkout\.

- `payable_amount` là giá trị gốc của SalesOrder, không thay đổi do refund hoặc đổi/trả\.

- Payment, return và integration status không được lưu như lifecycle status của order\.

- Đơn phát sinh công nợ phải có `customer_partner_id`\.

    

#### 3\.4\.2\.5 `sales_order_lines`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh order line|
|tenant\_id|UUID|Yes|FK|tenants\.id|Phải cùng tenant với SalesOrder|
|sales\_order\_id|UUID|Yes|FK|sales\_orders\.id|Aggregate root|
|line\_sequence|integer|Yes|—|—|Thứ tự dòng trong đơn|
|product\_id|UUID|Yes|FK|products\.id|Reference tới Product hiện hành|
|product\_unit\_id|UUID|Yes|FK|product\_units\.id|Reference tới đơn vị bán|
|quantity|decimal\(19,6\)|Yes|—|—|Số lượng theo đơn vị bán|
|base\_quantity|decimal\(19,6\)|Yes|—|—|Số lượng quy đổi về đơn vị cơ sở|
|unit\_price|decimal\(19,4\)|Yes|—|—|Đơn giá chính thức tại checkout|
|gross\_amount|decimal\(19,4\)|Yes|—|—|`quantity × unit_price` trước discount/tax|
|discount\_amount|decimal\(19,4\)|Yes|—|—|Discount phân bổ cho line|
|tax\_amount|decimal\(19,4\)|Yes|—|—|Thuế của line|
|line\_total|decimal\(19,4\)|Yes|—|—|Giá trị cuối cùng của line|
|product\_snapshot|jsonb|Yes|—|—|Tên, SKU, barcode và identity snapshot|
|product\_unit\_snapshot|jsonb|Yes|—|—|Unit label và conversion snapshot|
|pricing\_snapshot|jsonb|Yes|—|—|Giá, nguồn giá, discount, promotion và override|
|tax\_snapshot|jsonb|No|—|—|Tax rate, tax mode và rounding context|
|line\_note|text|No|—|—|Ghi chú lịch sử của line|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|



Rules:



- SalesOrderLine không có lifecycle chỉnh sửa độc lập\.

- Không cập nhật line để phản ánh return, exchange hoặc cancellation\.

- `line_total` phải reconcile với các thành phần amount và rounding policy\.

- `base_quantity` được dùng làm input cho inventory integration nhưng không phải stock movement\.

    

### 3\.4\.3 Sales Settlement entities



#### 3\.4\.3\.1 `sales_order_settlements`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh settlement|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|sales\_order\_id|UUID|Yes|FK, UK|sales\_orders\.id|Quan hệ chính xác 1–1|
|currency\_code|char\(3\)|Yes|—|—|Phải khớp SalesOrder|
|original\_payable\_amount|decimal\(19,4\)|Yes|—|—|Giá trị gốc từ SalesOrder|
|post\_sale\_adjustment\_amount|decimal\(19,4\)|Yes|—|—|Tổng thay đổi có dấu từ cancellation/return/exchange|
|current\_payable\_amount|decimal\(19,4\)|Yes|—|—|Nghĩa vụ hiện tại sau post\-sale|
|collected\_amount|decimal\(19,4\)|Yes|—|—|Tổng collection confirmed|
|refunded\_amount|decimal\(19,4\)|Yes|—|—|Tổng refund confirmed|
|net\_collected\_amount|decimal\(19,4\)|Yes|—|—|Collection trừ refund|
|outstanding\_amount|decimal\(19,4\)|Yes|—|—|Số còn phải thu hiện tại|
|payment\_status|enum|Yes|—|—|`unpaid`, `partially_paid`, `paid`, `partially_refunded`, `refunded`|
|reconciliation\_status|enum|Yes|—|—|`not_required`, `required`, `in_progress`, `reconciled`|
|version|bigint|Yes|—|—|Optimistic concurrency|
|last\_transaction\_at|timestamptz|No|—|—|Payment/refund gần nhất|
|settled\_at|timestamptz|No|—|—|Khi outstanding về `0` và không còn blocker|
|created\_at|timestamptz|Yes|—|—|Tạo cùng SalesOrder|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



Công thức:



```Plain Text
current_payable_amount
= original_payable_amount
+ post_sale_adjustment_amount
```



```Plain Text
net_collected_amount
= collected_amount
- refunded_amount
```



```Plain Text
outstanding_amount
= MAX(current_payable_amount - net_collected_amount, 0)
```



Rules:

- `original_payable_amount` bất biến\.

- Return, exchange hoặc cancellation thay đổi `post_sale_adjustment_amount`, không ghi đè giá trị gốc\.

- Summary phải có thể rebuild từ payment transactions và các post\-sale valuation đã xác nhận\.

- Trường hợp customer credit hoặc overpayment chưa thuộc Phase 1\.

    

#### 3\.4\.3\.2 `sales_payment_transactions`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh transaction|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|sales\_order\_settlement\_id|UUID|Yes|FK|sales\_order\_settlements\.id|Aggregate root|
|transaction\_code|varchar\(50\)|Yes|UK|—|Unique trong tenant|
|transaction\_type|enum|Yes|—|—|`collection`, `refund`, `reversal`|
|direction|enum|Yes|—|—|`inflow`, `outflow`|
|amount|decimal\(19,4\)|Yes|—|—|Phải lớn hơn `0`|
|currency\_code|char\(3\)|Yes|—|—|Phải khớp settlement|
|payment\_method\_code|varchar\(50\)|Yes|—|—|Ví dụ: cash, bank\_transfer, VietQR|
|payment\_method\_snapshot|jsonb|No|—|—|Method display/config snapshot|
|status|enum|Yes|—|—|`pending`, `confirmed`, `failed`, `voided`|
|source\_context|enum|Yes|—|—|`checkout`, `additional_collection`, `receivable_collection`, `return_exchange`, `cancellation`, `manual_correction`|
|source\_type|varchar\(50\)|No|—|—|Logical business source type|
|source\_id|UUID|No|—|—|Logical business source ID|
|related\_transaction\_id|UUID|No|FK|sales\_payment\_transactions\.id|Transaction bị refund/reverse/void|
|initiated\_by\_user\_id|UUID|Yes|FK|platform\_users\.id|Người khởi tạo|
|confirmed\_by\_user\_id|UUID|No|FK|platform\_users\.id|Người xác nhận nếu cần|
|reason\_code|varchar\(50\)|No|—|—|Bắt buộc với refund, reversal hoặc void|
|reason|text|No|—|—|Lý do chi tiết|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Unique theo tenant và payment scope|
|external\_reference|varchar\(150\)|No|—|—|Mã giao dịch ngân hàng/provider|
|metadata|jsonb|No|—|—|Provider hoặc channel metadata|
|occurred\_at|timestamptz|Yes|—|—|Thời điểm nghiệp vụ|
|confirmed\_at|timestamptz|No|—|—|Khi transaction confirmed|
|voided\_at|timestamptz|No|—|—|Khi transaction bị void|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Chỉ dùng cho status transition|



Rules:



- Transaction đã confirmed không được sửa amount, direction hoặc payment method\.

- Correction phải dùng void, reversal hoặc transaction mới\.

- Refund không được vượt refundable amount theo policy\.

- Transaction từ post\-sale operation phải có `source_type` và `source_id`\.

    

### 3\.4\.4 Post\-sale Operations entities



#### 3\.4\.4\.1 `order_adjustments`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh adjustment|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|sales\_order\_id|UUID|Yes|FK|sales\_orders\.id|SalesOrder nguồn|
|adjustment\_type|varchar\(50\)|Yes|—|—|Loại adjustment thuộc whitelist|
|status|enum|Yes|—|—|`requested`, `validating`, `applied`, `blocked`, `failed`|
|version|bigint|Yes|—|—|Optimistic concurrency|
|source\_order\_version|bigint|Yes|—|—|Phát hiện stale write|
|requested\_by\_user\_id|UUID|Yes|FK|platform\_users\.id|Người yêu cầu|
|applied\_by\_user\_id|UUID|No|FK|platform\_users\.id|Người/system áp dụng|
|reason\_code|varchar\(50\)|Yes|—|—|Lý do adjustment|
|reason|text|No|—|—|Diễn giải bổ sung|
|change\_set|jsonb|Yes|—|—|Field path, before value và after value|
|blocker\_codes|jsonb|No|—|—|Có khi status là blocked|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Chống apply trùng|
|requested\_at|timestamptz|Yes|—|—|Thời điểm yêu cầu|
|applied\_at|timestamptz|No|—|—|Thời điểm áp dụng|
|blocked\_at|timestamptz|No|—|—|Thời điểm bị chặn|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



Rules:



- `change_set` chỉ chứa field thuộc adjustment whitelist\.

- Adjustment không được thay product, quantity, price, discount, tax hoặc commercial total\.

- Adjustment đã applied không được xóa hoặc sửa lịch sử\.

#### 3\.4\.4\.2 `sales_order_cancellations`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh cancellation case|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|sales\_order\_id|UUID|Yes|FK|sales\_orders\.id|SalesOrder nguồn|
|status|enum|Yes|—|—|`requested`, `validating`, `confirmed`, `processing`, `completed`, `blocked`, `failed`, `cancelled`|
|version|bigint|Yes|—|—|Optimistic concurrency|
|source\_order\_version|bigint|Yes|—|—|Order version tại thời điểm yêu cầu|
|requested\_by\_user\_id|UUID|Yes|FK|platform\_users\.id|Người yêu cầu hủy|
|confirmed\_by\_user\_id|UUID|No|FK|platform\_users\.id|Người xác nhận|
|completed\_by\_user\_id|UUID|No|FK|platform\_users\.id|User hoặc system hoàn tất|
|reason\_code|varchar\(50\)|Yes|—|—|Lý do hủy|
|reason|text|No|—|—|Diễn giải chi tiết|
|precheck\_snapshot|jsonb|Yes|—|—|Kết quả kiểm tra payment, inventory, receivable, E\-invoice|
|required\_impacts\_snapshot|jsonb|No|—|—|Các impacts cần tạo khi xác nhận|
|blocker\_codes|jsonb|No|—|—|Business blockers|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Chống tạo case/xác nhận trùng|
|requested\_at|timestamptz|Yes|—|—|Thời điểm yêu cầu|
|confirmed\_at|timestamptz|No|—|—|Thời điểm xác nhận|
|completed\_at|timestamptz|No|—|—|Khi SalesOrder thực sự cancelled và local impacts đã ghi|
|blocked\_at|timestamptz|No|—|—|Thời điểm bị chặn|
|failed\_at|timestamptz|No|—|—|Thời điểm thất bại|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



Rules:



- Một SalesOrder có thể có nhiều cancellation cases nhưng chỉ tối đa một case `completed`\.

- Cancellation case không tự direct\-update SalesOrder\.

- Chỉ hoàn tất sau khi `CancelSalesOrder` được Sales Order Lifecycle xử lý thành công\.

- Impact delivery thất bại sau commit không tự chuyển SalesOrder trở lại `completed`\.

    

#### 3\.4\.4\.3 `return_exchange_orders`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh nghiệp vụ đổi/trả|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|sales\_order\_id|UUID|Yes|FK|sales\_orders\.id|SalesOrder nguồn|
|operation\_type|enum|Yes|—|—|`return`, `exchange`, `return_and_exchange`|
|status|enum|Yes|—|—|`draft`, `confirmed`, `processing`, `completed`, `cancelled`, `blocked`, `failed`|
|version|bigint|Yes|—|—|Optimistic concurrency|
|source\_order\_version|bigint|Yes|—|—|Order version dùng trong precheck|
|created\_by\_user\_id|UUID|Yes|FK|platform\_users\.id|Người tạo|
|confirmed\_by\_user\_id|UUID|No|FK|platform\_users\.id|Người xác nhận|
|completed\_by\_user\_id|UUID|No|FK|platform\_users\.id|User hoặc system hoàn tất|
|reason\_code|varchar\(50\)|Yes|—|—|Lý do đổi/trả|
|reason|text|No|—|—|Diễn giải bổ sung|
|currency\_code|char\(3\)|Yes|—|—|Phải khớp order nguồn|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Chống confirm trùng|
|confirmed\_at|timestamptz|No|—|—|Khi line và valuation được khóa|
|completed\_at|timestamptz|No|—|—|Khi local settlement requirements đã ghi nhận|
|cancelled\_at|timestamptz|No|—|—|Khi hồ sơ bị hủy|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



Rules:



- ReturnExchangeOrder phải có ít nhất một line `returned`\.

- Dòng đã confirmed không được sửa trực tiếp\.

- `completed` không đồng nghĩa mọi downstream integration đã acknowledged\.

    

#### 3\.4\.4\.4 `return_exchange_lines`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh line|
|tenant\_id|UUID|Yes|FK|tenants\.id|Cùng tenant với ReturnExchangeOrder|
|return\_exchange\_order\_id|UUID|Yes|FK|return\_exchange\_orders\.id|Aggregate root|
|line\_sequence|integer|Yes|—|—|Thứ tự line|
|line\_role|enum|Yes|—|—|`returned`, `exchange`|
|original\_sales\_order\_line\_id|UUID|Conditional|FK|sales\_order\_lines\.id|Bắt buộc với line `returned`|
|product\_id|UUID|Yes|FK|products\.id|Product của line|
|product\_unit\_id|UUID|Yes|FK|product\_units\.id|ProductUnit của line|
|quantity|decimal\(19,6\)|Yes|—|—|Phải lớn hơn `0`|
|base\_quantity|decimal\(19,6\)|Yes|—|—|Quy đổi về đơn vị cơ sở|
|unit\_value|decimal\(19,4\)|Yes|—|—|Giá trị đơn vị dùng trong valuation|
|line\_value|decimal\(19,4\)|Yes|—|—|Tổng giá trị line|
|return\_reason\_code|varchar\(50\)|No|—|—|Bắt buộc với line returned nếu policy yêu cầu|
|return\_condition\_code|varchar\(50\)|No|—|—|Tình trạng hàng trả|
|product\_snapshot|jsonb|Yes|—|—|Snapshot tại thời điểm xác nhận|
|product\_unit\_snapshot|jsonb|Yes|—|—|Unit và conversion snapshot|
|pricing\_snapshot|jsonb|Yes|—|—|Original pricing với returned line; current pricing với exchange line|
|line\_note|text|No|—|—|Ghi chú|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Chỉ cập nhật khi order còn draft|



Rules:



- Line `returned` phải tham chiếu đúng một returnable unit thuộc đúng SalesOrder nguồn — SalesOrderLine gốc hoặc exchange line đã confirmed (ADR-9)\.

- Tổng quantity đã confirmed không vượt remaining returnable quantity\.

- Line `exchange` dùng Product, Unit, Pricing và Inventory hiện hành\.

- Line `returned` dùng commercial snapshot gốc để tính giá trị\.

    

#### 3\.4\.4\.5 `return_exchange_valuations`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh valuation|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|return\_exchange\_order\_id|UUID|Yes|FK, UK|return\_exchange\_orders\.id|Tối đa một authoritative valuation|
|currency\_code|char\(3\)|Yes|—|—|Tiền tệ|
|return\_value|decimal\(19,4\)|Yes|—|—|Tổng giá trị hàng trả|
|exchange\_value|decimal\(19,4\)|Yes|—|—|Tổng giá trị hàng đổi/mua thêm|
|net\_difference|decimal\(19,4\)|Yes|—|—|`exchange_value - return_value`|
|required\_settlement\_type|enum|Yes|—|—|`none`, `collect`, `refund`, `receivable_offset`, `mixed`|
|status|enum|Yes|—|—|`calculated`, `confirmed`, `superseded`|
|valuation\_details|jsonb|Yes|—|—|Allocation, pricing và rounding breakdown|
|version|bigint|Yes|—|—|Kiểm soát recalculation|
|calculated\_by\_user\_id|UUID|Yes|FK|platform\_users\.id|Người hoặc system tính|
|calculated\_at|timestamptz|Yes|—|—|Thời điểm tính|
|confirmed\_at|timestamptz|No|—|—|Thời điểm valuation được khóa|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



Rules:



- `net_difference > 0`: cần thu thêm hoặc phát sinh phải thu\.

- `net_difference < 0`: cần refund hoặc cấn trừ công nợ\.

- Valuation không phải payment transaction\.

- Valuation confirmed tạo thay đổi vào `post_sale_adjustment_amount` của Settlement thông qua command của Sales Settlement\.

    

### 3\.4\.5 Sales Order Inquiry \& Documents entities



#### 3\.4\.5\.1 `sales_receipts`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh receipt version|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|sales\_order\_id|UUID|Yes|FK|sales\_orders\.id|SalesOrder nguồn|
|receipt\_version|integer|Yes|UK|—|Unique theo SalesOrder|
|status|enum|Yes|—|—|`generated`, `superseded`, `archived`|
|template\_code|varchar\(50\)|Yes|—|—|Template được dùng|
|template\_version|varchar\(30\)|Yes|—|—|Phiên bản template|
|content\_hash|varchar\(128\)|Yes|—|—|Kiểm tra nội dung receipt|
|receipt\_snapshot|jsonb|Yes|—|—|Dữ liệu render hoàn chỉnh|
|generated\_by\_user\_id|UUID|No|FK|platform\_users\.id|Null nếu system tự sinh|
|superseded\_by\_receipt\_id|UUID|No|FK|sales\_receipts\.id|Receipt version thay thế|
|archived\_by\_user\_id|UUID|No|FK|platform\_users\.id|Người archive|
|generated\_at|timestamptz|Yes|—|—|Thời điểm sinh|
|archived\_at|timestamptz|No|—|—|Thời điểm archive|
|created\_at|timestamptz|Yes|—|—|Thời điểm persist|



Rules:



- Receipt được sinh từ SalesOrder snapshot, không lấy giá hoặc tên hiện hành để thay thế\.

- Receipt không phải EInvoice\.

- Receipt version cũ không bị ghi đè\.

- `receipt_version` tăng tuần tự trong phạm vi SalesOrder\.

    

#### 3\.4\.5\.2 `sales_receipt_activities`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh activity|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|sales\_receipt\_id|UUID|Yes|FK|sales\_receipts\.id|Receipt liên quan|
|actor\_user\_id|UUID|No|FK|platform\_users\.id|Null nếu system action|
|activity\_type|enum|Yes|—|—|`printed`, `shared`, `archived`|
|channel|varchar\(50\)|No|—|—|Printer, email, SMS, messaging app\.\.\.|
|destination\_masked|varchar\(255\)|No|—|—|Email/số điện thoại đã mask|
|device\_context|jsonb|No|—|—|Device/printer/app context|
|activity\_metadata|jsonb|No|—|—|Provider result hoặc metadata khác|
|occurred\_at|timestamptz|Yes|—|—|Thời điểm nghiệp vụ|
|created\_at|timestamptz|Yes|—|—|Thời điểm persist|



Rules:



- Một receipt có thể được in và chia sẻ nhiều lần\.

- Activity không thay đổi SalesOrder lifecycle\.

- Không lưu dữ liệu người nhận không cần thiết hoặc chưa được mask\.

    

### 3\.4\.6 Cross\-cutting and integration records



Các table trong mục này có thể được triển khai dưới shared platform schema\. Chúng được liệt kê tại Theme 5 để làm rõ contract và transaction boundary\.



#### 3\.4\.6\.1 `idempotency_records`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh record|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant scope|
|command\_scope|varchar\(100\)|Yes|UK|—|Ví dụ `finalize_sales_order`|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Unique cùng command scope|
|payload\_hash|varchar\(128\)|Yes|—|Kiểm tra payload conflict||
|status|enum|Yes|—|—|`in_progress`, `succeeded`, `failed`, `uncertain`|
|result\_type|varchar\(100\)|No|—|—|Loại business result|
|result\_id|UUID|No|—|—|Logical reference tới result|
|result\_snapshot|jsonb|No|—|—|Response đã trả|
|correlation\_id|UUID|Yes|—|—|Correlation xuyên flow|
|expires\_at|timestamptz|No|—|—|Theo retention policy|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



#### 3\.4\.6\.2 `integration_commands`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh command delivery|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|source\_request\_type|varchar\(100\)|Yes|—|—|Inventory, receivable hoặc E\-invoice request|
|source\_request\_id|UUID|Yes|—|—|Logical reference|
|target\_domain|varchar\(100\)|Yes|—|—|Domain nhận command|
|command\_name|varchar\(100\)|Yes|—|—|Integration command name|
|command\_version|integer|Yes|—|—|Contract version|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Downstream idempotency|
|payload\_hash|varchar\(128\)|Yes|—|Kiểm tra payload||
|command\_payload|jsonb|Yes|—|—|Payload gửi target|
|delivery\_status|enum|Yes|—|—|`created`, `queued`, `sent`, `acknowledged`, `failed`, `uncertain`, `dead_letter`|
|attempt\_count|integer|Yes|—|—|Số lần delivery|
|max\_attempts|integer|Yes|—|—|Retry limit|
|next\_retry\_at|timestamptz|No|—|—|Lần retry tiếp theo|
|correlation\_id|UUID|Yes|—|—|Correlation ID|
|causation\_id|UUID|No|—|—|Command/event gây ra command này|
|external\_reference|varchar\(150\)|No|—|—|Reference phía target|
|last\_error\_code|varchar\(100\)|No|—|—|Lỗi gần nhất|
|last\_error\_message|text|No|—|—|Mô tả lỗi gần nhất|
|sent\_at|timestamptz|No|—|—|Lần gửi gần nhất|
|acknowledged\_at|timestamptz|No|—|—|Target đã acknowledge|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



#### 3\.4\.6\.3 `inventory_impact_requests`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh business impact|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|source\_type|varchar\(100\)|Yes|—|—|SalesOrder, Cancellation hoặc ReturnExchangeOrder|
|source\_id|UUID|Yes|—|—|Logical source ID|
|source\_version|bigint|Yes|—|—|Source version|
|impact\_type|enum|Yes|—|—|Reserve, commit sale, release, reverse, returned stock, exchange issue|
|business\_status|enum|Yes|—|—|`pending`, `accepted`, `rejected`, `reconciliation_required`, `reconciled`|
|store\_id|UUID|Yes|FK|stores\.id|Store/location nguồn|
|warehouse\_id|UUID|No|FK|warehouses\.id|Kho xử lý nếu xác định được|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Unique impact|
|reservation\_reference|varchar\(150\)|No|—|—|External Inventory reservation|
|stock\_movement\_reference|varchar\(150\)|No|—|—|External movement reference|
|request\_payload|jsonb|Yes|—|—|Lines, quantities và unit snapshots|
|response\_payload|jsonb|No|—|—|Business response từ Theme 7|
|accepted\_at|timestamptz|No|—|—|Khi Inventory accept|
|rejected\_at|timestamptz|No|—|—|Khi business reject|
|reconciliation\_required\_at|timestamptz|No|—|—|Khi phát hiện mismatch|
|created\_at|timestamptz|Yes|—|—|Ghi cùng business transaction nguồn|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|

#### 3\.4\.6\.4 `receivable_impact_requests`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh receivable impact|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|source\_type|varchar\(100\)|Yes|—|—|Settlement, cancellation hoặc return/exchange|
|source\_id|UUID|Yes|—|—|Logical source ID|
|source\_version|bigint|Yes|—|—|Source version|
|impact\_type|enum|Yes|—|—|`post`, `adjust`, `reverse`, `offset`, `reconcile`|
|customer\_partner\_id|UUID|Yes|FK|partners\.id|Customer chịu công nợ|
|amount|decimal\(19,4\)|Yes|—|—|Giá trị impact|
|currency\_code|char\(3\)|Yes|—|—|Tiền tệ|
|due\_date|date|No|—|—|Hạn thanh toán nếu có|
|business\_status|enum|Yes|—|—|`pending`, `accepted`, `rejected`, `reconciliation_required`, `reconciled`|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Unique business impact|
|receivable\_entry\_reference|varchar\(150\)|No|—|—|Reference từ Theme 6|
|request\_payload|jsonb|Yes|—|—|Business input|
|response\_payload|jsonb|No|—|—|Business response|
|accepted\_at|timestamptz|No|—|—|Khi Theme 6 accept|
|rejected\_at|timestamptz|No|—|—|Khi Theme 6 reject|
|reconciliation\_required\_at|timestamptz|No|—|—|Khi mismatch|
|created\_at|timestamptz|Yes|—|—|Ghi cùng business transaction nguồn|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



#### 3\.4\.6\.5 `e_invoice_impact_requests`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Định danh E\-invoice impact|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|source\_type|varchar\(100\)|Yes|—|—|SalesOrder, adjustment, cancellation hoặc return/exchange|
|source\_id|UUID|Yes|—|—|Logical source ID|
|source\_version|bigint|Yes|—|—|Source version|
|action\_type|enum|Yes|—|—|`issue`, `adjust`, `replace`, `cancel`|
|business\_status|enum|Yes|—|—|`pending`, `accepted`, `rejected`, `reconciliation_required`, `reconciled`|
|idempotency\_key|varchar\(150\)|Yes|UK|—|Unique action|
|buyer\_tax\_snapshot|jsonb|No|—|—|Buyer/tax data tại thời điểm request|
|invoice\_data\_snapshot|jsonb|Yes|—|—|Sales, tax và document input|
|e\_invoice\_reference|varchar\(150\)|No|—|—|Reference từ Theme 8|
|request\_payload|jsonb|Yes|—|—|Payload business|
|response\_payload|jsonb|No|—|—|Response từ Theme 8|
|accepted\_at|timestamptz|No|—|—|Khi Theme 8 accept|
|rejected\_at|timestamptz|No|—|—|Khi business reject|
|created\_at|timestamptz|Yes|—|—|Ghi cùng transaction nguồn|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



#### 3\.4\.6\.6 `outbox_messages`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Message ID|
|tenant\_id|UUID|Yes|FK|tenants\.id|Tenant boundary|
|message\_type|enum|Yes|—|—|`domain_event`, `integration_event`, `integration_command`|
|message\_name|varchar\(150\)|Yes|—|—|Event hoặc command name|
|message\_version|integer|Yes|—|—|Contract version|
|aggregate\_type|varchar\(100\)|No|—|—|Aggregate nguồn|
|aggregate\_id|UUID|No|—|—|Aggregate source ID|
|aggregate\_version|bigint|No|—|—|Source version|
|correlation\_id|UUID|Yes|—|—|Correlation ID|
|causation\_id|UUID|No|—|—|Message/command nguồn|
|payload|jsonb|Yes|—|—|Message payload|
|publish\_status|enum|Yes|—|—|`pending`, `publishing`, `published`, `failed`, `dead_letter`|
|attempt\_count|integer|Yes|—|—|Số lần publish|
|available\_at|timestamptz|Yes|—|—|Thời điểm có thể publish|
|published\_at|timestamptz|No|—|—|Khi publish thành công|
|last\_error|text|No|—|—|Lỗi gần nhất|
|created\_at|timestamptz|Yes|—|—|Ghi cùng local transaction nguồn|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



#### 3\.4\.6\.7 `inbox_messages`



|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|id|UUID|Yes|PK|—|Inbox record ID|
|tenant\_id|UUID|No|FK|tenants\.id|Có thể null với platform\-level message|
|consumer\_name|varchar\(150\)|Yes|UK|—|Consumer xử lý message|
|source\_message\_id|UUID|Yes|UK|—|Message ID từ producer|
|message\_name|varchar\(150\)|Yes|—|—|Message contract|
|payload\_hash|varchar\(128\)|Yes|—|—|Kiểm tra duplicate payload|
|payload|jsonb|Yes|—|—|Payload nhận được|
|processing\_status|enum|Yes|—|—|`received`, `processing`, `processed`, `failed`, `dead_letter`|
|received\_at|timestamptz|Yes|—|—|Thời điểm nhận|
|processed\_at|timestamptz|No|—|—|Khi xử lý thành công|
|last\_error|text|No|—|—|Lỗi gần nhất|
|created\_at|timestamptz|Yes|—|—|Thời điểm tạo|
|updated\_at|timestamptz|Yes|—|—|Lần cập nhật gần nhất|



### 3\.4\.7 Field constraints

|**ID**|**Constraint**|
|---|---|
|FC\-01|Mọi child entity phải có cùng `tenant_id` với aggregate root|
|FC\-02|`sales_orders(tenant_id, order_code)` phải unique|
|FC\-03|`sales_orders.source_draft_id` phải unique khi không null|
|FC\-04|`sales_orders.checkout_attempt_id` phải unique|
|FC\-05|`sales_order_draft_lines(sales_order_draft_id, line_sequence)` phải unique|
|FC\-06|`sales_order_lines(sales_order_id, line_sequence)` phải unique|
|FC\-07|`sales_order_settlements.sales_order_id` phải unique|
|FC\-08|`return_exchange_valuations.return_exchange_order_id` phải unique|
|FC\-09|`sales_receipts(sales_order_id, receipt_version)` phải unique|
|FC\-10|`sales_receipt_activities` không được làm thay đổi SalesOrder lifecycle|
|FC\-11|`original_sales_order_line_id` bắt buộc khi `line_role = returned`|
|FC\-12|`original_sales_order_line_id` phải thuộc đúng SalesOrder nguồn|
|FC\-13|`quantity`, payment amount và valuation line amount không được âm|
|FC\-14|`net_difference = exchange_value - return_value`|
|FC\-15|`current_payable_amount = original_payable_amount + post_sale_adjustment_amount`|
|FC\-16|`net_collected_amount = collected_amount - refunded_amount`|
|FC\-17|Chỉ được có tối đa một cancellation case `completed` trên mỗi SalesOrder|
|FC\-18|Idempotency keys phải unique theo tenant và command/business scope|
|FC\-19|`source_type + source_id + source_version + impact_type` không được tạo duplicate business impact|
|FC\-20|Inbox phải unique theo `consumer_name + source_message_id`|
|FC\-21|Commercial snapshots và confirmed payment transactions không được cập nhật nội dung|
|FC\-22|Cross\-theme reference không cho phép Theme 5 direct\-update entity target|

# 4\. Epics

## 4\.1 Epic map

### 4\.1\.1 Overview

Theme 5 được triển khai qua 6 Epics, bao phủ toàn bộ hành trình từ lúc người bán bắt đầu lập đơn đến khi giao dịch được thanh toán, tra cứu và xử lý sau bán\.

Epic được xác định theo business outcome và hành trình người dùng\. Domain được xác định theo business responsibility và quyền sở hữu authoritative state\. Vì vậy:

- Một Epic có thể phối hợp nhiều Domain\.

- Một Domain có thể tham gia nhiều Epic\.

- Một Epic không mặc nhiên sở hữu tất cả Aggregate được sử dụng trong Epic đó\.

- Mọi thay đổi authoritative phải được thực hiện bởi Domain owner của Aggregate tương ứng\.

- Read Model chỉ phục vụ truy vấn và không được dùng để ghi ngược vào business entities\.

- External Domain được tích hợp qua command, event hoặc contract rõ ràng\.

    

Cấu trúc Epic của Theme 5:

```Plain Text
Theme 5 — Sales & Orders
├── EP-01: Lập đơn hàng & lưu nháp
├── EP-02: Thanh toán & hoàn tất đơn hàng
├── EP-03: Tra cứu & theo dõi đơn hàng
├── EP-04: Điều chỉnh thông tin đơn hàng sau bán
├── EP-05: Hủy đơn hàng sau bán
└── EP-06: Đổi/trả hàng & quyết toán chênh lệch
```

### 4\.1\.2 Epic catalog

|**Epic**|**Name**|**Business outcome**|**Primary domain**|**Supporting domains**|**Aggregate / process / read model chính**|
|---|---|---|---|---|---|
|EP\-01|Lập đơn hàng \& lưu nháp|Người bán có thể bắt đầu lập đơn, chọn khách hàng, thêm sản phẩm, kiểm tra giá, điều chỉnh dòng hàng trong phạm vi quyền và lưu nháp để tiếp tục sau|Sales Order Lifecycle|—|`SalesOrderWorkingState`, `SalesOrderDraft`, `SalesOrderDraftLine`|
|EP\-02|Thanh toán \& hoàn tất đơn hàng|Người bán có thể kiểm tra điều kiện cuối, ghi nhận thanh toán hoặc khoản còn phải thu, hoàn tất checkout và nhận kết quả giao dịch chính thức|Sales Order Lifecycle|Sales Settlement; Sales Order Inquiry \& Documents|`CheckoutAttempt`, `SalesOrder`, `SalesOrderLine`, `SalesOrderSettlement`, `SalesPaymentTransaction`, `SalesReceipt`, `CheckoutResultView`|
|EP\-03|Tra cứu \& theo dõi đơn hàng|Người dùng có thể tìm kiếm, lọc, xem chi tiết, timeline, payment status, return status, receipt và integration status của đơn|Sales Order Inquiry \& Documents|Sales Order Lifecycle; Sales Settlement; Post\-sale Operations|`SalesOrderListView`, `SalesOrderDetailView`, `SalesOrderTimelineView`, `SalesOrderPaymentSummaryView`, `SalesOrderReturnSummaryView`, `SalesOrderIntegrationStatusView`, `SalesReceipt`|
|EP\-04|Điều chỉnh thông tin đơn hàng sau bán|Người dùng có quyền có thể điều chỉnh các thông tin phi thương mại thuộc whitelist mà không làm thay đổi bản chất giao dịch gốc|Post\-sale Operations|Sales Order Lifecycle; Sales Order Inquiry \& Documents|`OrderAdjustment`, source `SalesOrder`, `PostSaleResultView`|
|EP\-05|Hủy đơn hàng sau bán|Người dùng có quyền có thể hủy SalesOrder đủ điều kiện và ghi nhận đầy đủ refund, công nợ, tồn kho, hóa đơn và audit impacts liên quan|Post\-sale Operations|Sales Order Lifecycle; Sales Settlement; Sales Order Inquiry \& Documents|`SalesOrderCancellation`, source `SalesOrder`, source `SalesOrderSettlement`, `SalesPaymentTransaction`, `PostSaleResultView`|
|EP\-06|Đổi/trả hàng \& quyết toán chênh lệch|Người dùng có thể lập nghiệp vụ đổi/trả từ đơn gốc, xác định hàng trả và hàng đổi, tính chênh lệch, thu thêm, hoàn tiền hoặc cấn trừ công nợ|Post\-sale Operations|Sales Settlement; Sales Order Lifecycle; Sales Order Inquiry \& Documents|`ReturnExchangeOrder`, `ReturnExchangeLine`, `ReturnExchangeValuation`, `SalesOrderSettlement`, `SalesPaymentTransaction`, `ReturnableOrderLineView`, `PostSaleResultView`|



### 4\.1\.3 External dependency coverage

|External Theme / Foundation|EP\-01|EP\-02|EP\-03|EP\-04|EP\-05|EP\-06|
|---|---|---|---|---|---|---|
|Theme 1 — <br>Tenant, store, identity \& permission|Tenant, store, identity và permission|Operational context và permission|Data scope|Permission|Tenant\.<br>Membership<br>Permission<br>Store scope|Tenant\.<br>Membership<br>Permission<br>Store scope|
|Theme 2 — <br>Product \& ProductUnit|Product và ProductUnit|Product validation|—|—|—|Current Product và ProductUnit|
|Theme 3 — <br>Partner|Chọn và tham chiếu Partner|Validate Partner khi checkout hoặc phát sinh công nợ|Mở hồ sơ Partner hiện tại hoặc nhận deep link từ lịch sử khách hàng|—<br>|—|Validate Partner khi phát sinh receivable mới hoặc áp dụng chính sách khách hàng|
|Theme 4 — <br>Pricing \& Promotions|Pricing preview và promotion|Final pricing validation|—|—|Pricing và promotion reversal|Return/exchange pricing|
|Theme 6 — <br>Receivable|—|Phát sinh receivable|Receivable projection|—|Receivable adjustment hoặc reversal|Receivable offset|
|Theme 7 — <br>Inventory \& Costing|—|Inventory validation và sales impact|Inventory projection|—|Inventory reversal|Returned inventory và exchange inventory|
|Theme 8 — <br>E\-invoice|—|E\-invoice issuance handoff|E\-invoice projection|E\-invoice policy validation khi adjustment ảnh hưởng dữ liệu pháp lý|E\-invoice adjustment hoặc cancellation|E\-invoice adjustment hoặc replacement|
|Theme 10 — <br>Reporting|—|Phát sinh dữ liệu và integration events cho Reporting|Nhận deep link từ báo cáo|Cập nhật reporting projection phi tài chính|Phát event cho Reporting|Phát event cho Reporting|
|Platform Foundation — Audit|—|Audit|Đọc Platform Audit cho timeline|Ghi audit adjustment|Ghi audit cancellation|Ghi audit return/exchange|

### 4\.1\.4 Domain coverage matrix

Quy ước:

- `P`: Primary Domain của Epic\.

- `S`: Supporting Domain tham gia xử lý command hoặc business coordination\.

- `R`: Domain cung cấp authoritative data cho query/read flow\.

- `—`: Không tham gia trực tiếp\.

|**Domain**|**EP\-01**|**EP\-02**|**EP\-03**|**EP\-04**|**EP\-05**|**EP\-06**|
|---|---|---|---|---|---|---|
|Sales Order Lifecycle|P|P|R|R|S||
|Sales Settlement|—|S|R|—|S|S|
|Post\-sale Operations|—|—|R|P|P|P|
|Sales Order Inquiry \& Documents|—|S|P|S|S|S|

### 4\.1\.5 Aggregate and model coverage

Quy ước:

- `Primary`: Aggregate/process/model được tạo hoặc thay đổi chủ yếu trong Epic\.

- `Supporting`: Aggregate được gọi qua Domain owner để hoàn thành outcome\.

- `Source`: Dữ liệu authoritative được tham chiếu hoặc đọc\.

- `Query`: Chỉ được truy vấn\.

- `Result`: Được dùng để hiển thị kết quả hoặc projection\.

- `—`: Không sử dụng trực tiếp\.

    

|**Aggregate / process / model**|**Owner domain**|**EP\-01**|**EP\-02**|**EP\-03**|**EP\-04**|**EP\-05**|**EP\-06**|
|---|---|---|---|---|---|---|---|
|SalesOrderWorkingState<br>|Sales Order Lifecycle application layer|Primary|Source|—|—|—|—|
|SalesOrderDraft|Sales Order Lifecycle|Primary|Source|—|—|—|—|
|SalesOrderDraftLine|Sales Order Lifecycle|Primary|Source|—|—|—|—|
|CheckoutAttempt|Sales Order Lifecycle|—|Primary|—|—|—|—|
|SalesOrder|Sales Order Lifecycle|—|Primary|Source|Source|Supporting|Source|
|SalesOrderLine|Sales Order Lifecycle|—|Primary|Source|Source|Source|Source|
|SalesOrderSettlement|Sales Settlement|—|Primary|Source|—|Supporting|Supporting|
|SalesPaymentTransaction|Sales Settlement|—|Primary|Source|—|Supporting|Supporting|
|OrderAdjustment|Post\-sale Operations|—|—|Source|Primary|—|—|
|SalesOrderCancellation|Post\-sale Operations|—|—|Source|—|Primary|—|
|ReturnExchangeOrder|Post\-sale Operations|—|—|Source|—|Source|Primary|
|ReturnExchangeLine|Post\-sale Operations|—|—|Source|—|Source|Primary|
|ReturnExchangeValuation|Post\-sale Operations|—|—|Source|—|Source|Primary|
|SalesReceipt|Sales Order Inquiry \& Documents|—|Supporting|Primary|—|Source|Source|
|SalesReceiptActivity|Sales Order Inquiry \& Documents|—|Supporting<br>|Primary|—|—|—|
|Order Inquiry Views|Sales Order Inquiry \& Documents|—|Result|Primary|Result|Result|Result|
|CheckoutResultView|Sales Order Lifecycle application layer|—|Result|—|—|—|—|
|ReturnableOrderLineView|Post\-sale Operations|—|—|—|—|—|Primary|
|PostSaleResultView|Post\-sale Operations application layer|—|—|Source|Result|Result|Result|

### 4\.1\.6 Epic flow

```mermaid
flowchart LR
    EP01["EP-01<br/>Lập đơn hàng<br/>& lưu nháp"]
    EP02["EP-02<br/>Thanh toán<br/>& hoàn tất đơn"]
    EP03["EP-03<br/>Tra cứu & theo dõi<br/>đơn hàng"]
    EP04["EP-04<br/>Điều chỉnh thông tin<br/>sau bán"]
    EP05["EP-05<br/>Hủy đơn hàng<br/>sau bán"]
    EP06["EP-06<br/>Đổi/trả & quyết toán<br/>chênh lệch"]
    EP01 --> EP02
    EP02 --> EP03
    EP03 --> EP04
    EP03 --> EP05
    EP03 --> EP06
    EP04 --> EP03
    EP05 --> EP03
    EP06 --> EP03```

**Flow notes:**

- EP\-01 có thể kết thúc bằng việc bỏ Working State hoặc lưu `SalesOrderDraft`\.

- EP\-02 chuyển Working State hoặc Draft hợp lệ thành `SalesOrder` chính thức\.

- EP\-03 là điểm tra cứu trung tâm sau khi SalesOrder được tạo\.

- EP\-04, EP\-05 và EP\-06 luôn bắt đầu từ một SalesOrder đã tồn tại\.

- Kết quả của EP\-04, EP\-05 và EP\-06 được phản ánh trở lại các Read Model của EP\-03\.

- Các Epic sau bán không được ghi đè commercial snapshot của SalesOrder\.

- Payment, refund và quyết toán tiền vẫn do Sales Settlement sở hữu\.

- Inventory, Receivable, Pricing và E\-invoice impacts được gửi sang Domain owner tương ứng qua durable contracts\.

    

### 4\.1\.7 Epic boundary rules

#### EP\-01 — Lập đơn hàng \& lưu nháp

- Chỉ quản lý Working State và SalesOrderDraft trước checkout\.

- Không tạo SalesOrder, payment transaction, receivable, stock movement hoặc receipt chính thức\.

- Pricing tại giai đoạn này chỉ là preview và phải được validate lại ở EP\-02\.

    

#### EP\-02 — Thanh toán \& hoàn tất đơn hàng

- Là Epic duy nhất tạo SalesOrder chính thức từ checkout\.

- Điều phối Sales Order Lifecycle và Sales Settlement nhưng không hợp nhất hai Domain\.

- Checkout thành công phải có kết quả idempotent và có thể recovery khi uncertain\.

- Receipt có thể được sinh sau khi SalesOrder đã commit\.

    

#### EP\-03 — Tra cứu \& theo dõi đơn hàng

- Chỉ đọc và tổng hợp authoritative data\.

- Không sở hữu lifecycle, payment hoặc post\-sale state\.

- Các CTA điều chỉnh, hủy và đổi/trả chỉ là entry point sang EP\-04, EP\-05 hoặc EP\-06\.

- Không dùng Read Model làm input authoritative để thực hiện mutation command\.

    

#### EP\-04 — Điều chỉnh thông tin đơn hàng sau bán

- Chỉ cho phép thay đổi các field phi thương mại thuộc whitelist\.

- Không được thay đổi Product, ProductUnit, quantity, unit price, discount, tax, commercial total, payment hoặc inventory\.

- Adjustment phải lưu before/after diff, actor, thời điểm và reason theo policy\.

- Không hủy đơn và không thực hiện đổi/trả trong Epic này\.

    

#### EP\-05 — Hủy đơn hàng sau bán

- Quản lý toàn bộ lifecycle của cancellation case\.

- Phải precheck order lifecycle, lock, payment, return, inventory, receivable, pricing/promotion và E\-invoice policy\.

- `SalesOrderCancellation` không trực tiếp sở hữu lifecycle của SalesOrder\.

- Khi đủ điều kiện, Post\-sale Operations gửi `CancelSalesOrder` tới Sales Order Lifecycle\.

- Refund, receivable reversal, inventory reversal và E\-invoice impacts phải truy được về cancellation case nguồn\.

    

#### EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch

- Quản lý ReturnExchangeOrder, các line trả/đổi và valuation\.

- Hàng trả phải tham chiếu một returnable unit — SalesOrderLine gốc hoặc exchange line đã confirmed (ADR-9) — và không vượt remaining returnable quantity của unit đó\.

- Hàng đổi hoặc mua thêm sử dụng Product, ProductUnit, Pricing và Inventory hiện hành\.

- ReturnExchangeValuation xác định nghĩa vụ thu thêm, hoàn tiền hoặc cấn trừ công nợ nhưng không trực tiếp tạo authoritative payment transaction\.

- Payment/refund được thực hiện bởi Sales Settlement\.

### 4\.1\.8 Cross\-epic rules

- ReturnExchangeOrder `confirmed`, `processing` hoặc `completed` là hard blocker của cancellation\.

- ReturnExchangeOrder `draft` phải được hủy hoặc invalidated trước khi cancellation tiếp tục\. 

- SalesOrderCancellation `confirmed`, `processing` hoặc `completed` là blocker của return/exchange\. 

- Cancellation `requested` hoặc `validating` là operation đang cạnh tranh và phải được resolve trước\. 

Cancellation `blocked`, `failed` hoặc `cancelled` không mặc định chặn đổi/trả\.

## 4\.2 EP\-01 — Lập đơn hàng \& lưu nháp

### 4\.2\.1 Overview

Epic này bao phủ giai đoạn từ khi người bán **bắt đầu một giao dịch bán hàng tại quầy** đến khi đơn hàng đang lập đủ điều kiện chuyển sang thanh toán hoặc được lưu lại để tiếp tục xử lý sau\.

Trong Epic này, cần phân biệt rõ hai khái niệm:

- **Đơn hàng đang lập:** Trạng thái làm việc tạm thời trên giao diện bán hàng\. Dữ liệu có thể chỉ tồn tại trong phiên làm việc và chưa phải một entity nghiệp vụ được lưu chính thức\.

- **Đơn nháp:** Dữ liệu đã được người dùng chủ động lưu dưới dạng `SalesOrderDraft` để có thể mở lại và tiếp tục xử lý\.

    

Đơn hàng đang lập và đơn nháp **chưa phải đơn hàng chính thức**\. Chúng chưa ghi nhận doanh thu, thanh toán, công nợ, biến động tồn kho, phiếu bán hàng nội bộ hoặc yêu cầu phát hành hóa đơn điện tử\.

Epic kết thúc theo một trong hai hướng:

- Người dùng chọn **Thanh toán**, chuyển đơn hàng đang lập sang EP\-02 — Thanh toán \& hoàn tất đơn hàng\.

- Người dùng chọn **Lưu đơn nháp**, tạo `SalesOrderDraft` để tiếp tục xử lý sau\.

    

Chỉ khi checkout thành công, hệ thống mới tạo `SalesOrder` và commercial snapshot chính thức\.

### 4\.2\.2 Business context

Trong bán hàng tại quầy, người bán cần hoàn thành giao dịch nhanh trong khi khách hàng đang chờ\. Tuy nhiên, dữ liệu đầu vào phải đủ chính xác để tránh tạo sai thanh toán, công nợ, tồn kho, hóa đơn và báo cáo ở các bước sau\.

Người bán có thể bắt đầu đơn với **Khách lẻ**, chọn một khách hàng đã có hồ sơ hoặc tạo nhanh khách hàng mới\. Sau đó, người bán tìm hoặc quét sản phẩm, chọn đúng đơn vị bán, nhập số lượng, kiểm tra giá áp dụng và theo dõi tổng tiền tạm tính\.

Với cửa hàng thuốc thú y và mô hình thương mại có nhiều đơn vị bán, một sản phẩm có thể được bán theo hộp, gói, chai hoặc đơn vị cơ sở\. Vì vậy, mỗi dòng hàng cần xác định rõ:

- Sản phẩm hoặc SKU\.

- Đơn vị bán\.

- Số lượng theo đơn vị bán\.

- Giá áp dụng\.

- Chiết khấu hoặc điều chỉnh thủ công nếu có\.

- Thành tiền tạm tính\.

    

Giá hiển thị trong quá trình lập đơn là **pricing preview**, phục vụ quyết định bán hàng trước checkout\. Theme 5 lấy kết quả giá từ Theme 4 theo ngữ cảnh hiện tại, có thể bao gồm giá mặc định, giá riêng, nhớ giá, chương trình ưu đãi hoặc nguồn giá khác\.

Nếu người dùng sửa giá hoặc chiết khấu thủ công, hệ thống phải kiểm tra quyền và chính sách áp dụng\. Việc sửa giá trong đơn hiện tại **không tự động thay đổi dữ liệu giá do Theme 4 sở hữu**\.

Khi người dùng muốn lưu mức giá để áp dụng cho những lần bán sau, Theme 5 chỉ chuyển đúng ngữ cảnh sang nghiệp vụ giá riêng hoặc nhớ giá của Theme 4\.

Trong thực tế, giao dịch có thể bị gián đoạn vì khách cần bổ sung hàng, kiểm tra lại giá, chưa quyết định mua hoặc người bán cần chuyển sang phục vụ khách khác\. Người dùng phải có khả năng lưu đơn đang lập thành đơn nháp mà không phát sinh bất kỳ tác động tài chính hoặc tồn kho nào\.

Khi mở lại đơn nháp, dữ liệu tham chiếu có thể đã thay đổi, ví dụ:

- Sản phẩm đã ngừng bán\.

- Đơn vị bán không còn hợp lệ\.

- Khách hàng đã ngừng hoạt động\.

- Giá hiện tại khác với pricing preview trước đó\.

- Quyền của người dùng đã thay đổi\.

    

Hệ thống phải nhận diện các thay đổi này, thông báo rõ cho người dùng và yêu cầu xử lý trước khi cho phép chuyển sang thanh toán\. Hệ thống không được âm thầm biến dữ liệu cũ thành một giao dịch mới có nội dung khác\.

### 4\.2\.3 In scope

- Khởi tạo đơn hàng đang lập trong đúng tenant và cửa hàng hiện tại\.

- Gắn ngữ cảnh người bán, cửa hàng và ca bán vào đơn hàng đang lập nếu mô hình vận hành yêu cầu ca bán\.

- Sử dụng **Khách lẻ** làm khách hàng mặc định khi chưa chọn khách hàng có hồ sơ\.

- Tìm kiếm và chọn khách hàng có hồ sơ từ Theme 3\.

- Tạo nhanh khách hàng tối thiểu trong quá trình lập đơn nếu người dùng có quyền\.

- Thay đổi từ Khách lẻ sang khách hàng có hồ sơ\.

- Bỏ khách hàng đã chọn để quay lại Khách lẻ\.

- Tìm kiếm sản phẩm theo tên, mã sản phẩm, SKU hoặc barcode\.

- Quét barcode để xác định và thêm sản phẩm vào đơn hàng đang lập\.

- Kiểm tra sản phẩm và đơn vị bán còn hợp lệ theo dữ liệu hiện hành của Theme 2\.

- Thêm một hoặc nhiều dòng hàng vào đơn hàng đang lập\.

- Chọn hoặc thay đổi đơn vị bán trong các đơn vị được phép của sản phẩm\.

- Nhập và điều chỉnh số lượng dòng hàng\.

- Cập nhật hoặc xóa dòng hàng trước khi checkout\.

- Lấy pricing preview từ Theme 4 theo ngữ cảnh tenant, cửa hàng, khách hàng, sản phẩm, đơn vị bán, số lượng và thời điểm áp dụng\.

- Hiển thị giá áp dụng và nguồn giá ở mức cần thiết để người bán hiểu vì sao hệ thống sử dụng mức giá đó\.

- Tự động lấy lại pricing preview khi thay đổi khách hàng, sản phẩm, đơn vị bán, số lượng hoặc dữ liệu ảnh hưởng đến giá\.

- Cho phép sửa giá hoặc áp dụng chiết khấu thủ công trong phạm vi quyền và chính sách của tenant\.

- Hiển thị cảnh báo hoặc chặn thao tác khi giá thủ công vi phạm giá sàn, permission hoặc pricing policy\.

- Tính lại thành tiền từng dòng và tổng tiền tạm tính sau mỗi thay đổi có ảnh hưởng\.

- Ghi nhận ghi chú nội bộ hoặc thông tin hỗ trợ lập đơn nếu được thiết kế trong phạm vi đơn nháp\.

- Giữ nguyên dữ liệu đơn hàng đang lập khi người dùng chuyển sang và quay lại từ luồng tạo nhanh khách hàng\.

- Giữ nguyên dữ liệu đơn hàng đang lập khi người dùng chuyển sang và quay lại từ luồng giá riêng hoặc nhớ giá\.

- Kiểm tra các dòng hàng tối thiểu trước khi cho phép chuyển sang bước Thanh toán\.

- Lưu đơn hàng đang lập thành `SalesOrderDraft` khi người dùng chủ động chọn lưu\.

- Lưu các draft lines, khách hàng đang chọn, ngữ cảnh bán, pricing preview, tổng tiền tạm tính, ghi chú, người tạo và version của đơn nháp\.

- Xem danh sách đơn nháp thuộc phạm vi người dùng được phép truy cập\.

- Mở lại một đơn nháp active để tiếp tục lập đơn\.

- Kiểm tra lại khách hàng, sản phẩm, đơn vị bán, permission và pricing preview khi khôi phục đơn nháp\.

- Hiển thị rõ các dòng hàng hoặc dữ liệu không còn hợp lệ sau khi đơn nháp được mở lại\.

- Cập nhật và lưu lại đơn nháp active theo optimistic concurrency\.

- Xóa đơn nháp theo thao tác trên UI bằng cách chuyển lifecycle sang `cancelled`; không hard delete dữ liệu nghiệp vụ\.

- Hết hạn đơn nháp theo policy của tenant hoặc tác vụ hệ thống\.

- Chặn tiếp tục sửa đơn nháp đã `converted`, `cancelled` hoặc `expired`\.

- Chuyển đơn hàng đang lập hoặc đơn nháp đã khôi phục sang EP\-02 khi người dùng chọn Thanh toán\.

    

### 4\.2\.4 Out of scope

- Ghi nhận khoản thanh toán chính thức\.

- Ghi nhận thanh toán tiền mặt, chuyển khoản hoặc nhiều phương thức thanh toán\.

- Xác định trạng thái thanh toán chính thức\.

- Xử lý khoản còn phải thu hoặc điều kiện bán ghi nợ\.

- Tạo `CheckoutAttempt`\.

- Finalize checkout\.

- Tạo `SalesOrder` và `SalesOrderLine` chính thức\.

- Tạo commercial snapshot chính thức của giao dịch\.

- Ghi nhận doanh thu\.

- Khởi tạo `SalesOrderSettlement`\.

- Tạo payment transaction\.

- Phát sinh hoặc quản lý công nợ\.

- Phát sinh xuất kho, reservation, stock movement hoặc các tác động tồn kho khác\.

- Tạo, in hoặc chia sẻ phiếu bán hàng nội bộ\.

- Phát hành, điều chỉnh, thay thế hoặc hủy hóa đơn điện tử\.

- Quản lý hồ sơ sản phẩm, SKU, barcode hoặc đơn vị tính gốc\.

- Quản lý hồ sơ khách hàng đầy đủ ngoài luồng tạo nhanh tối thiểu\.

- Thiết lập hoặc cập nhật giá mặc định, giá riêng, nhớ giá, bảng giá hoặc chương trình khuyến mại\.

- Quản lý pricing priority, conflict policy hoặc pricing engine\.

- Tra cứu danh sách đơn hàng chính thức\.

- Xem chi tiết hoặc lịch sử của đơn hàng đã hoàn tất\.

- Điều chỉnh thông tin đơn hàng sau bán\.

- Hủy đơn hàng chính thức\.

- Đổi hàng hoặc trả hàng\.

- Thu nợ hoặc quản lý công nợ chi tiết sau bán\.

- Quản lý tồn kho hoặc giá vốn chi tiết\.

- Giao hàng, vận chuyển hoặc fulfillment nhiều bước\.

- Báo cáo doanh thu và báo cáo quản trị chuyên sâu\.

    

### 4\.2\.5 Entry points

- Người dùng chọn **Tạo đơn hàng** từ khu vực Bán hàng\.

- Người dùng chọn hành động tạo đơn nhanh từ Home hoặc dashboard vận hành\.

- Người dùng bắt đầu tạo đơn từ hồ sơ khách hàng; khách hàng đó được truyền vào làm khách hàng ban đầu của đơn\.

- Người dùng mở danh sách đơn nháp và chọn một đơn nháp active để tiếp tục xử lý\.

- Người dùng quay lại bước lập đơn từ màn Thanh toán để sửa khách hàng, dòng hàng, đơn vị bán, số lượng, giá hoặc chiết khấu\.

- Người dùng quay lại đơn hàng đang lập sau khi hoàn thành hoặc hủy luồng tạo nhanh khách hàng của Theme 3\.

- Người dùng quay lại đơn hàng đang lập sau khi hoàn thành hoặc hủy luồng giá riêng hoặc nhớ giá của Theme 4\.

- Hệ thống mở lại working state còn hợp lệ trong cùng phiên làm việc nếu ứng dụng hỗ trợ khôi phục phiên tạm thời\.

    

Trước khi khởi tạo hoặc khôi phục đơn, hệ thống phải xác định được:

- Tenant hiện tại\.

- Cửa hàng hiện tại\.

- Người dùng đang hoạt động\.

- Permission phù hợp\.

- Ca bán hợp lệ nếu tenant yêu cầu vận hành theo ca\.

    

EP\-01 kết thúc khi người dùng:

- Chuyển sang EP\-02 bằng hành động **Thanh toán**\.

- Lưu đơn thành đơn nháp và rời khỏi luồng\.

- Rời khỏi một working state chưa có dữ liệu\.

- Xác nhận bỏ dữ liệu chưa lưu\.

- Xóa mềm đơn nháp\.

### 4\.2\.6 User stories

#### 4\.2\.6\.1 User story map

|User story|As user|I want to|So that|Notes|
|---|---|---|---|---|
|US\-01 — Khởi tạo đơn hàng đang lập|Nhân viên bán hàng|Bắt đầu một đơn hàng mới trong đúng cửa hàng và ngữ cảnh làm việc hiện tại|Tôi có thể phục vụ khách ngay mà chưa tạo giao dịch chính thức|Khởi tạo `SalesOrderWorkingState`; khách hàng mặc định là Khách lẻ|
|US\-02 — Xác định khách hàng cho đơn hàng|Nhân viên bán hàng|Chọn Khách lẻ, chọn khách hàng có hồ sơ hoặc mở luồng tạo nhanh khách hàng|Đơn hàng sử dụng đúng thông tin khách hàng và điều kiện bán liên quan|Theme 3 sở hữu hồ sơ Partner; thay đổi khách hàng làm mới pricing preview|
|US\-03 — Thêm và quản lý dòng hàng|Nhân viên bán hàng|Tìm hoặc quét sản phẩm, chọn đơn vị bán và cập nhật số lượng các dòng hàng|Tôi có thể lập đúng danh sách hàng khách cần mua|Chỉ quản lý dòng hàng trước checkout; chưa tạo `SalesOrderLine`|
|US\-04 — Kiểm tra và điều chỉnh giá bán|Nhân viên bán hàng hoặc Quản lý cửa hàng|Xem giá áp dụng, nguồn giá và điều chỉnh giá hoặc chiết khấu trong phạm vi quyền|Tôi có thể bán đúng chính sách giá và nhận biết các trường hợp cần cảnh báo|Giá tại bước này chỉ là `PricingPreview`; phải được validate lại tại checkout|
|US\-05 — Lưu giá riêng hoặc nhớ giá từ đơn hàng|Nhân viên bán hàng hoặc Quản lý cửa hàng|Chuyển ngữ cảnh một dòng hàng sang luồng giá riêng hoặc nhớ giá của Theme 4|Mức giá thỏa thuận có thể được sử dụng trong những lần bán sau|Theme 5 không tạo hoặc sở hữu rule giá riêng/nhớ giá|
|US\-06 — Lưu đơn hàng thành đơn nháp|Nhân viên bán hàng|Lưu đơn hàng đang lập khi giao dịch chưa thể hoàn thành ngay|Tôi có thể tạm dừng phục vụ mà không mất dữ liệu đã nhập|Chỉ tạo `SalesOrderDraft` khi người dùng chủ động lưu và có ít nhất một dòng hợp lệ|
|US\-07 — Khôi phục và quản lý đơn nháp|Nhân viên bán hàng|Xem, mở lại, cập nhật hoặc hủy một đơn nháp|Tôi có thể tiếp tục giao dịch cũ một cách an toàn khi dữ liệu liên quan vẫn hợp lệ|Khôi phục phải revalidate dữ liệu hiện hành; không âm thầm thay đổi nội dung draft|



#### 4\.2\.6\.2 US\-01 — Khởi tạo đơn hàng đang lập

**Business context**

Nhân viên bán hàng cần bắt đầu phục vụ khách ngay tại quầy với số thao tác tối thiểu\. Tuy nhiên, hệ thống vẫn phải xác định đúng tenant, cửa hàng, người bán và ca bán trước khi người dùng thêm sản phẩm\.

Đơn hàng mới ở giai đoạn này chỉ là `SalesOrderWorkingState` phục vụ thao tác trên giao diện\. Hệ thống chưa tạo `SalesOrderDraft`, `SalesOrder`, thanh toán, công nợ, tồn kho hoặc chứng từ chính thức\.

User Story bắt đầu khi người dùng mở flow tạo đơn mới và kết thúc khi working state sẵn sàng để chọn khách hàng, thêm dòng hàng, lưu nháp hoặc chuyển sang thanh toán\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Bắt đầu một đơn hàng mới trong đúng cửa hàng và ngữ cảnh làm việc hiện tại|Tôi có thể phục vụ khách ngay mà chưa tạo giao dịch chính thức|



**Functional requirements**

- FR\-01: Cho phép người dùng bắt đầu đơn hàng mới từ khu vực Bán hàng, Home, dashboard vận hành hoặc một entry point hợp lệ khác\.

- FR\-02: Hệ thống phải xác định tenant, cửa hàng, người dùng, channel và ca bán hiện tại trước khi khởi tạo working state\.

- FR\-03: Hệ thống phải khởi tạo một `SalesOrderWorkingState` rỗng gắn với ngữ cảnh bán hàng hiện tại\.

- FR\-04: Nếu entry point không cung cấp khách hàng hợp lệ, hệ thống phải sử dụng Khách lẻ làm customer context mặc định\.

- FR\-05: Nếu entry point cung cấp một `customer_partner_id` hợp lệ, hệ thống phải prefill khách hàng đó vào working state\.

- FR\-06: Hệ thống phải giữ working state trong phiên làm việc để người dùng có thể chuyển sang các flow liên quan và quay lại mà không mất dữ liệu\.

- FR\-07: Khi người dùng rời khỏi working state đã có dữ liệu nhưng chưa lưu, hệ thống phải yêu cầu xác nhận bỏ dữ liệu hoặc cho phép lưu thành draft\.

    

**Business rules**

- BR\-01: `SalesOrderWorkingState` là runtime model, không phải persisted business entity\.

- BR\-02: Khởi tạo working state không tạo `SalesOrderDraft`, `SalesOrder`, payment transaction, receivable, inventory impact, receipt hoặc e\-invoice request\.

- BR\-03: Tenant và cửa hàng của working state không được âm thầm thay đổi sau khi người dùng đã nhập dữ liệu\.

- BR\-04: Nếu người dùng muốn đổi cửa hàng khi working state đã có dữ liệu, người dùng phải lưu draft hoặc xác nhận bỏ dữ liệu hiện tại trước\.

- BR\-05: Người dùng phải có active membership và quyền truy cập nghiệp vụ Bán hàng trong cửa hàng hiện tại\.

- BR\-06: Nếu tenant bật quản lý ca bán, hệ thống phải xác định được ca bán hợp lệ trước khi cho phép tiếp tục flow\.

- BR\-07: Working state rỗng không được tự động persist thành `SalesOrderDraft`\.

    

**Acceptance criteria**

- AC\-01: Người dùng hợp lệ có thể mở một working state mới trong đúng tenant và cửa hàng hiện tại\.

- AC\-02: Working state mới hiển thị đúng người bán, cửa hàng và ca bán nếu có\.

- AC\-03: Đơn mới mặc định sử dụng Khách lẻ khi không có khách hàng được truyền từ entry point\.

- AC\-04: Khách hàng từ entry point chỉ được prefill khi thuộc đúng tenant và còn đủ điều kiện giao dịch\.

- AC\-05: Việc khởi tạo working state không tạo bất kỳ persisted business record hoặc downstream impact nào\.

- AC\-06: Dữ liệu đã nhập không bị mất khi người dùng đi sang flow liên quan và quay lại trong cùng phiên hợp lệ\.

- AC\-07: Người dùng không thể âm thầm rời một working state đã có dữ liệu mà không lưu hoặc xác nhận bỏ dữ liệu\.

    

**Edge cases**

- EC\-01: Người dùng chưa chọn được cửa hàng làm việc; hệ thống chặn khởi tạo và yêu cầu chọn cửa hàng\.

- EC\-02: Tenant yêu cầu ca bán nhưng chưa có ca đang mở; hệ thống chặn tiếp tục và hướng dẫn mở hoặc chọn ca hợp lệ\.

- EC\-03: Người dùng mất quyền truy cập cửa hàng trước khi working state được khởi tạo; hệ thống hiển thị no\-permission state\.

- EC\-04: Khách hàng được truyền từ entry point đã ngừng hoạt động; hệ thống khởi tạo đơn với Khách lẻ và thông báo khách hàng không còn khả dụng\.

- EC\-05: Người dùng bấm Tạo đơn nhiều lần liên tiếp; hệ thống chỉ mở một working state cho cùng thao tác điều hướng\.

- EC\-06: Ứng dụng bị tải lại khi working state chưa lưu; hệ thống chỉ khôi phục dữ liệu phiên nếu cơ chế session recovery còn hợp lệ\.

- EC\-07: Cửa hàng hoặc ca bán bị thay đổi bởi hệ thống trong lúc working state đang mở; hệ thống yêu cầu tải lại context trước khi tiếp tục\.

    

**Scenarios**

- SC\-01 — Khởi tạo đơn mới với Khách lẻ

    

```Gherkin
Given người dùng có active membership
And người dùng có quyền bán hàng tại cửa hàng hiện tại
When người dùng chọn "Tạo đơn hàng"
Then hệ thống khởi tạo một SalesOrderWorkingState mới
And working state thuộc đúng tenant và cửa hàng hiện tại
And customer context mặc định là Khách lẻ
And chưa có business entity chính thức nào được tạo
```



- SC\-02 — Khởi tạo đơn từ hồ sơ khách hàng

    

```Gherkin
Given người dùng đang xem một khách hàng còn hoạt động
And khách hàng thuộc tenant hiện tại
When người dùng chọn "Tạo đơn hàng"
Then hệ thống khởi tạo SalesOrderWorkingState mới
And customer_partner_id của khách hàng được prefill
And chưa có SalesOrderDraft hoặc SalesOrder được tạo
```



- SC\-03 — Tenant yêu cầu ca bán nhưng chưa có ca hợp lệ

    

```Gherkin
Given tenant bật quản lý ca bán
And người dùng chưa có ca bán đang mở
When người dùng chọn "Tạo đơn hàng"
Then hệ thống không cho tiếp tục lập đơn
And hệ thống hiển thị lý do chưa có ca bán hợp lệ
And hệ thống không tạo persisted business data
```



- SC\-04 — Không có quyền tại cửa hàng

    

```Gherkin
Given người dùng không có quyền bán hàng tại cửa hàng hiện tại
When người dùng cố mở flow tạo đơn
Then hệ thống từ chối truy cập
And hệ thống hiển thị no-permission state
And không tiết lộ dữ liệu vận hành ngoài phạm vi được phép
```



- SC\-05 — Rời working state đã có dữ liệu

    

```Gherkin
Given working state đã có ít nhất một dòng hàng
And working state chưa được lưu thành draft
When người dùng thực hiện thao tác rời flow
Then hệ thống yêu cầu người dùng lưu draft hoặc xác nhận bỏ dữ liệu
And hệ thống không tự động xóa dữ liệu mà không có xác nhận
```



- SC\-06 — Bỏ working state rỗng

    

```Gherkin
Given working state chưa có khách hàng định danh
And chưa có dòng hàng hoặc ghi chú
When người dùng rời flow
Then hệ thống đóng working state
And không yêu cầu lưu draft
And không tạo persisted business entity
```



**References**

- Domains:

    - Sales Order Lifecycle

- Data:

    - `SalesOrderWorkingState`

    - Tenant context

    - Store context

    - User context

    - Sales shift context

- Commands / queries / events:

    - Không có persisted command khi chỉ khởi tạo working state

- Permissions:

    - Quyền truy cập nghiệp vụ Bán hàng tại cửa hàng hiện tại

    - `sales.draft.create` khi người dùng chọn lưu draft

    - `sales.checkout.create` khi người dùng chuyển sang checkout

- External dependencies:

    - Theme 1 — Tenant, cửa hàng, người dùng, membership và permission

    - Theme 3 — Customer context khi entry point đến từ hồ sơ khách hàng

        

#### 4\.2\.6\.3 US\-02 — Xác định khách hàng cho đơn hàng

**Business context**

Một giao dịch tại quầy có thể được thực hiện cho Khách lẻ hoặc cho khách hàng có hồ sơ\. Việc xác định đúng khách hàng ảnh hưởng đến giá riêng, nhớ giá, chương trình ưu đãi, khả năng bán thiếu, công nợ và thông tin chứng từ ở các bước sau\.



Người bán cần có thể tìm khách hàng đã tồn tại, quay lại Khách lẻ hoặc mở luồng tạo nhanh khách hàng mà không làm mất các dòng hàng đang lập\.



Theme 3 là domain sở hữu hồ sơ Partner\. Theme 5 chỉ lựa chọn và tham chiếu khách hàng trong working state hoặc draft\.



**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Chọn Khách lẻ, chọn khách hàng có hồ sơ hoặc tạo nhanh khách hàng mới|Đơn hàng sử dụng đúng customer context và chính sách bán liên quan|



**Functional requirements**



- FR\-01: Hệ thống phải hiển thị customer context hiện tại của đơn hàng, bao gồm Khách lẻ hoặc khách hàng đã chọn\.

- FR\-02: Cho phép người dùng tìm kiếm khách hàng theo tên, số điện thoại, mã khách hàng hoặc thông tin tìm kiếm được Theme 3 hỗ trợ\.

- FR\-03: Cho phép chọn một khách hàng đủ điều kiện giao dịch và gắn `customer_partner_id` vào working state\.

- FR\-04: Cho phép bỏ khách hàng đã chọn để quay lại customer context Khách lẻ\.

- FR\-05: Cho phép người dùng có quyền mở luồng tạo nhanh khách hàng của Theme 3 mà vẫn giữ nguyên working state hiện tại\.

- FR\-06: Sau khi tạo nhanh thành công, Theme 5 phải nhận lại `customer_partner_id` và customer context để chọn khách hàng vừa tạo\.

- FR\-07: Khi customer context thay đổi, hệ thống phải yêu cầu làm mới pricing preview của các dòng hàng bị ảnh hưởng\.

    

**Business rules**



- BR\-01: Theme 3 là owner của Partner, trạng thái khách hàng, hồ sơ liên hệ và customer role\.

- BR\-02: Chỉ Partner thuộc tenant hiện tại, có customer role phù hợp và còn đủ điều kiện giao dịch mới được chọn cho đơn hàng mới\.

- BR\-03: Khách lẻ không có `customer_partner_id`\.

- BR\-04: Việc chọn khách hàng trong working state chưa tạo customer snapshot chính thức; snapshot chỉ được tạo khi checkout thành công\.

- BR\-05: Thay đổi khách hàng không được xóa hoặc tự thay đổi sản phẩm, đơn vị bán và số lượng đã nhập\.

- BR\-06: Thay đổi khách hàng làm pricing preview phụ thuộc khách hàng trở thành stale và phải được tính lại\.

- BR\-07: Nếu khách hàng bị ngừng hoạt động sau khi đã được chọn, hệ thống không được âm thầm chuyển đơn về Khách lẻ; checkout phải bị chặn cho đến khi người dùng xử lý\.

    

**Acceptance criteria**



- AC\-01: Người dùng có thể tiếp tục lập đơn với Khách lẻ mà không cần tạo hồ sơ khách hàng\.

- AC\-02: Kết quả tìm kiếm chỉ hiển thị khách hàng trong phạm vi tenant và quyền được phép\.

- AC\-03: Khi chọn khách hàng thành công, working state hiển thị đúng khách hàng đã chọn\.

- AC\-04: Khi quay lại Khách lẻ, `customer_partner_id` được loại khỏi working state nhưng các dòng hàng vẫn được giữ nguyên\.

- AC\-05: Working state không bị mất khi người dùng mở và quay lại từ luồng tạo nhanh khách hàng\.

- AC\-06: Khách hàng vừa tạo thành công có thể được chọn ngay mà không cần tìm kiếm lại\.

- AC\-07: Pricing preview được làm mới hoặc đánh dấu cần làm mới khi customer context thay đổi\.

    

**Edge cases**



- EC\-01: Không có khách hàng phù hợp với từ khóa; hệ thống hiển thị no\-result state và cho phép tiếp tục với Khách lẻ hoặc tạo nhanh\.

- EC\-02: Khách hàng được chọn vừa bị ngừng hoạt động; hệ thống từ chối chọn và tải lại kết quả hiện hành\.

- EC\-03: Người dùng không có quyền tạo khách hàng; hệ thống không hiển thị hoặc disable action tạo nhanh\.

- EC\-04: Theme 3 phát hiện hồ sơ trùng khi tạo nhanh; Theme 3 xử lý trùng và trả kết quả phù hợp mà không làm mất working state\.

- EC\-05: Luồng tạo nhanh thất bại hoặc bị hủy; hệ thống quay lại working state với customer context trước đó\.

- EC\-06: Người dùng đổi khách hàng khi một số dòng có giá riêng; hệ thống đánh dấu giá cũ không còn đảm bảo hợp lệ và yêu cầu tính lại\.

- EC\-07: Người dùng mất quyền xem khách hàng đã chọn; hệ thống che dữ liệu không còn được phép và yêu cầu chọn lại customer context\.

    

**Scenarios**



- SC\-01 — Tiếp tục bán cho Khách lẻ

    

```Gherkin
Given working state đang sử dụng customer context Khách lẻ
When người dùng thêm sản phẩm vào đơn
Then hệ thống cho phép tiếp tục lập đơn
And customer_partner_id vẫn để trống
And các chính sách chỉ dành cho khách hàng định danh chưa được áp dụng
```



- SC\-02 — Chọn khách hàng có hồ sơ

    

```Gherkin
Given người dùng có quyền tìm kiếm khách hàng
And khách hàng "Đại lý An Bình" đang hoạt động trong tenant hiện tại
When người dùng chọn khách hàng "Đại lý An Bình"
Then working state được gắn customer_partner_id tương ứng
And hệ thống hiển thị customer context đã chọn
And hệ thống yêu cầu làm mới pricing preview liên quan
```



- SC\-03 — Quay lại Khách lẻ

    

```Gherkin
Given working state đang gắn với một khách hàng có hồ sơ
And working state đã có các dòng hàng
When người dùng chọn "Bán cho Khách lẻ"
Then customer_partner_id được loại khỏi working state
And các dòng hàng và số lượng vẫn được giữ nguyên
And pricing preview được tính lại theo customer context Khách lẻ
```



- SC\-04 — Tạo nhanh khách hàng thành công

    

```Gherkin
Given working state đã có dữ liệu
And người dùng có quyền tạo nhanh khách hàng
When người dùng hoàn tất luồng tạo khách hàng trong Theme 3
Then Theme 3 trả về customer_partner_id mới
And Theme 5 chọn khách hàng vừa tạo cho working state
And dữ liệu dòng hàng trước đó vẫn được giữ nguyên
```



- SC\-05 — Hủy luồng tạo nhanh khách hàng

    

```Gherkin
Given người dùng đã mở luồng tạo nhanh khách hàng từ working state
When người dùng hủy luồng mà chưa tạo hồ sơ
Then hệ thống quay lại working state
And customer context trước đó không thay đổi
And các dòng hàng không bị mất
```



- SC\-06 — Khách hàng không còn hoạt động khi checkout

    

```Gherkin
Given working state đang gắn với một khách hàng có hồ sơ
And khách hàng đã bị ngừng hoạt động sau khi được chọn
When người dùng chọn "Thanh toán"
Then hệ thống không cho tiếp tục checkout
And hệ thống yêu cầu chọn khách hàng hợp lệ hoặc chuyển về Khách lẻ
And hệ thống không âm thầm thay đổi customer context
```



**References**



- Domains:

    - Sales Order Lifecycle

    - Theme 3 — Đối tác giao dịch

- Data:

    - `SalesOrderWorkingState`

    - `SalesOrderDraft.customer_partner_id`

    - Partner

    - Partner role

    - Partner status

- Commands / queries / events:

    - API tìm kiếm Partner của Theme 3

    - Luồng tạo nhanh Partner của Theme 3

    - Pricing preview contract của Theme 4

- Permissions:

    - Quyền xem/chọn khách hàng của Theme 3

    - Quyền tạo nhanh khách hàng của Theme 3

- External dependencies:

    - Theme 3 — Tìm kiếm, tạo và kiểm tra trạng thái khách hàng

    - Theme 4 — Tính lại giá khi customer context thay đổi

        

#### 4\.2\.6\.4 US\-03 — Thêm và quản lý dòng hàng

**Business context**



Dòng hàng là nội dung trung tâm của đơn hàng đang lập\. Người bán cần tìm hoặc quét sản phẩm, chọn đúng đơn vị bán và nhập số lượng trong thời gian ngắn nhưng vẫn phải tránh nhầm sản phẩm, sai đơn vị hoặc số lượng không hợp lệ\.



Ở giai đoạn này, hệ thống chỉ quản lý các dòng trong working state hoặc `SalesOrderDraftLine`\. Chưa có `SalesOrderLine` chính thức và chưa phát sinh xuất kho hay reservation\.



**User story statement**



|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Tìm hoặc quét sản phẩm, chọn đơn vị bán và cập nhật các dòng hàng|Tôi có thể lập đúng danh sách hàng khách cần mua|



**Functional requirements**



- FR\-01: Cho phép tìm kiếm sản phẩm theo tên, mã sản phẩm, SKU hoặc barcode\.

- FR\-02: Cho phép quét barcode để xác định sản phẩm và đơn vị bán liên quan\.

- FR\-03: Hiển thị các đơn vị bán đang hoạt động và hợp lệ của sản phẩm được chọn\.

- FR\-04: Cho phép thêm sản phẩm, đơn vị bán và số lượng hợp lệ vào working state\.

- FR\-05: Cho phép thay đổi đơn vị bán hoặc số lượng của một dòng hàng đã thêm\.

- FR\-06: Cho phép xóa dòng hàng trước checkout\.

- FR\-07: Sau mỗi thay đổi, hệ thống phải cập nhật line sequence, pricing preview liên quan, thành tiền dòng và tổng tiền tạm tính\.

    

**Business rules**



- BR\-01: Chỉ sản phẩm thuộc tenant hiện tại, còn được phép bán và có dữ liệu giao dịch hợp lệ mới được thêm vào đơn\.

- BR\-02: `product_unit_id` phải thuộc đúng `product_id` và đơn vị phải còn hoạt động với vai trò đơn vị bán\.

- BR\-03: Số lượng phải lớn hơn 0 và tuân theo precision được hỗ trợ cho đơn vị bán\.

- BR\-04: Trong Phase 1, mỗi tổ hợp `product_id + product_unit_id` chỉ có một dòng trong working state; thêm lại cùng tổ hợp làm tăng số lượng dòng hiện có\.

- BR\-05: Dòng hàng trong working state hoặc draft chưa phải `SalesOrderLine` và chưa tạo commercial snapshot chính thức\.

- BR\-06: Thêm, sửa hoặc xóa dòng hàng không trực tiếp tạo reservation, stock movement hoặc inventory impact\.

- BR\-07: Đơn hàng chỉ được chuyển sang Thanh toán khi có ít nhất một dòng hàng hợp lệ và không còn dòng bị blocker\.

    

**Acceptance criteria**



- AC\-01: Người dùng có thể tìm hoặc quét một sản phẩm đang được phép bán và thêm vào working state\.

- AC\-02: Hệ thống chỉ cho chọn đơn vị bán hợp lệ thuộc sản phẩm\.

- AC\-03: Thêm lại cùng sản phẩm và đơn vị làm tăng số lượng dòng hiện có thay vì tạo dòng trùng\.

- AC\-04: Thay đổi số lượng hoặc đơn vị làm hệ thống cập nhật lại pricing preview và tổng tiền tạm tính\.

- AC\-05: Xóa một dòng làm dòng đó biến mất khỏi working state và tổng tiền được tính lại\.

- AC\-06: Dòng có sản phẩm, đơn vị hoặc số lượng không hợp lệ được hiển thị rõ và chặn chuyển sang Thanh toán\.

- AC\-07: Không có inventory impact hoặc giao dịch chính thức được tạo từ thao tác quản lý dòng hàng\.

    

**Edge cases**



- EC\-01: Barcode không khớp sản phẩm nào; hệ thống hiển thị Không tìm thấy sản phẩm và cho phép tìm thủ công\.

- EC\-02: Một barcode khớp nhiều đơn vị hoặc sản phẩm; hệ thống yêu cầu người dùng chọn kết quả chính xác\.

- EC\-03: Sản phẩm vừa bị ngừng bán; hệ thống không cho thêm và cập nhật trạng thái hiện hành\.

- EC\-04: Đơn vị bán vừa bị vô hiệu hóa; hệ thống không cho chọn hoặc tiếp tục sử dụng đơn vị đó cho giao dịch mới\.

- EC\-05: Người dùng nhập số lượng bằng 0, số âm hoặc sai precision; hệ thống không chấp nhận giá trị\.

- EC\-06: Sản phẩm hoặc đơn vị trở nên không hợp lệ sau khi đã được thêm; hệ thống đánh dấu dòng cần xử lý trước checkout\.

- EC\-07: Người dùng xóa dòng cuối cùng; working state vẫn tồn tại nhưng action Thanh toán bị disable\.

    

**Scenarios**



- SC\-01 — Thêm sản phẩm bằng tìm kiếm

    

```Gherkin
Given người dùng đang ở working state
And sản phẩm "Thuốc A" đang được phép bán
When người dùng tìm và chọn sản phẩm "Thuốc A"
And chọn đơn vị bán "Hộp"
And nhập số lượng 2
Then hệ thống thêm một dòng hàng vào working state
And dòng hàng tham chiếu đúng sản phẩm và đơn vị bán
And số lượng của dòng là 2
```



- SC\-02 — Thêm sản phẩm bằng barcode

    

```Gherkin
Given barcode "893000000001" ánh xạ duy nhất tới sản phẩm "Thuốc B" và đơn vị "Chai"
When người dùng quét barcode
Then hệ thống xác định đúng sản phẩm và đơn vị bán
And hệ thống thêm hoặc tăng số lượng dòng tương ứng
```



- SC\-03 — Thêm lại cùng sản phẩm và đơn vị

    

```Gherkin
Given working state đã có sản phẩm "Thuốc A" đơn vị "Hộp" với số lượng 2
When người dùng thêm lại sản phẩm "Thuốc A" đơn vị "Hộp" với số lượng 1
Then hệ thống không tạo dòng trùng
And số lượng dòng hiện có được cập nhật thành 3
And pricing preview được tính lại theo số lượng mới
```



- SC\-04 — Thay đổi đơn vị bán

    

```Gherkin
Given một dòng hàng đang sử dụng đơn vị "Hộp"
And sản phẩm có đơn vị bán "Vỉ" còn hoạt động
When người dùng đổi đơn vị sang "Vỉ"
Then hệ thống cập nhật product_unit_id của dòng
And hệ thống yêu cầu pricing preview mới
And thành tiền tạm tính được cập nhật
```



- SC\-05 — Nhập số lượng không hợp lệ

    

```Gherkin
Given người dùng đang cập nhật một dòng hàng
When người dùng nhập số lượng bằng 0
Then hệ thống không chấp nhận số lượng
And hệ thống hiển thị yêu cầu số lượng phải lớn hơn 0
And tổng tiền không được tính từ giá trị không hợp lệ
```



- SC\-06 — Sản phẩm đã ngừng bán

    

```Gherkin
Given sản phẩm vừa chuyển sang trạng thái không được phép bán
When người dùng cố thêm sản phẩm vào working state
Then hệ thống chặn thao tác
And hệ thống hiển thị sản phẩm không còn khả dụng cho giao dịch mới
```



- SC\-07 — Chặn Thanh toán khi có dòng không hợp lệ

    

```Gherkin
Given working state có ít nhất một dòng hàng không còn đơn vị bán hợp lệ
When người dùng chọn "Thanh toán"
Then hệ thống không chuyển sang EP-02
And hệ thống chỉ rõ dòng hàng cần xử lý
And chưa phát sinh payment, receivable, inventory impact hoặc SalesOrder
```



**References**



- Domains:

    - Sales Order Lifecycle

- Data:

    - `SalesOrderWorkingState`

    - `SalesOrderDraftLine`

    - Product

    - Product Unit

    - Barcode

    - `PricingPreview`

- Commands / queries / events:

    - API tìm kiếm sản phẩm

    - API tra cứu barcode

    - API lấy đơn vị bán của sản phẩm

    - Pricing preview contract của Theme 4

- Permissions:

    - Quyền truy cập nghiệp vụ Bán hàng

    - Quyền xem sản phẩm và đơn vị bán

- External dependencies:

    - Theme 2 — Sản phẩm, SKU, barcode, đơn vị bán và sellability

    - Theme 4 — Pricing preview sau khi dòng hàng thay đổi

        

#### 4\.2\.6\.5 US\-04 — Kiểm tra và điều chỉnh giá bán

**Business context**



Giá bán của một dòng hàng có thể đến từ giá niêm yết, giá riêng, nhớ giá, chương trình khuyến mại hoặc các rule ưu tiên khác\. Người bán cần biết mức giá nào đang được áp dụng và có thể điều chỉnh giá hoặc chiết khấu trong phạm vi được cấp quyền\.



Giá trong working state chỉ là `PricingPreview`\. Giá chính thức và commercial snapshot chỉ được xác định sau khi Theme 4 validate lại tại checkout\.



User Story này không tạo hoặc cập nhật rule giá trong Theme 4; việc lưu giá cho lần bán sau thuộc US\-05\.



**User story statement**



|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng hoặc Quản lý cửa hàng|Xem giá áp dụng, nguồn giá và điều chỉnh giá hoặc chiết khấu trong phạm vi quyền|Tôi có thể bán đúng chính sách giá và kiểm soát các ngoại lệ|



**Functional requirements**



- FR\-01: Hệ thống phải lấy pricing preview từ Theme 4 cho từng dòng hàng theo ngữ cảnh hiện tại\.

- FR\-02: Hệ thống phải hiển thị giá áp dụng, chiết khấu, thành tiền và nguồn giá ở mức người dùng được phép xem\.

- FR\-03: Hệ thống phải tự động yêu cầu pricing preview mới khi khách hàng, sản phẩm, đơn vị bán, số lượng hoặc thời điểm áp dụng thay đổi\.

- FR\-04: Cho phép người dùng có quyền nhập manual unit price cho dòng hàng\.

- FR\-05: Cho phép người dùng có quyền nhập manual discount amount cho dòng hàng\.

- FR\-06: Hệ thống phải kiểm tra price floor, pricing policy và permission trước khi chấp nhận manual price hoặc discount\.

- FR\-07: Nếu không lấy được pricing preview hợp lệ, hệ thống phải đánh dấu dòng cần kiểm tra và không cho chuyển sang Thanh toán\.

    

**Business rules**



- BR\-01: Theme 4 là source of truth cho pricing, promotion, pricing priority và conflict policy\.

- BR\-02: `PricingPreview` không phải giá chính thức và phải được validate lại trong `FinalizeSalesOrder`\.

- BR\-03: Manual unit price và manual discount được lưu dưới dạng input intent, không phải commercial snapshot\.

- BR\-04: Manual unit price phải lớn hơn 0; manual discount không được làm giá trị dòng hàng âm\.

- BR\-05: Giá dưới price floor chỉ được chấp nhận khi tenant policy cho phép và người dùng có quyền override tương ứng\.

- BR\-06: Khi pricing context thay đổi, preview cũ phải được đánh dấu stale và không được coi là kết quả hiện hành\.

- BR\-07: Hệ thống không được âm thầm thay đổi giá đã hiển thị; mọi thay đổi làm thay đổi số tiền phải được phản ánh rõ trước checkout\.

    

**Acceptance criteria**



- AC\-01: Mỗi dòng hợp lệ hiển thị được giá áp dụng và thành tiền tạm tính\.

- AC\-02: Nguồn giá được hiển thị theo đúng quyền của người dùng\.

- AC\-03: Thay đổi customer context, đơn vị hoặc số lượng làm hệ thống yêu cầu pricing preview mới\.

- AC\-04: Người dùng không có quyền không thể nhập hoặc xác nhận manual price/discount\.

- AC\-05: Giá dưới sàn bị cảnh báo hoặc chặn đúng theo tenant policy và permission\.

- AC\-06: Khi Theme 4 trả giá mới, tổng tiền tạm tính được cập nhật nhất quán với các dòng\.

- AC\-07: Không thể chuyển sang Thanh toán khi còn dòng chưa có pricing preview hợp lệ\.

    

**Edge cases**



- EC\-01: Theme 4 không trả được giá cho sản phẩm và đơn vị đã chọn; hệ thống hiển thị trạng thái Thiếu giá\.

- EC\-02: Pricing preview được trả về sau khi người dùng đã thay đổi dòng lần nữa; hệ thống bỏ qua response cũ\.

- EC\-03: Người dùng nhập manual price bằng 0 hoặc số âm; hệ thống từ chối giá trị\.

- EC\-04: Discount làm line total âm; hệ thống chặn và hiển thị giới hạn hợp lệ\.

- EC\-05: Price floor thay đổi sau khi manual price được nhập; hệ thống kiểm tra lại trước khi cho chuyển sang checkout\.

- EC\-06: Người dùng mất quyền override trong lúc đang chỉnh giá; backend từ chối thao tác và yêu cầu tải lại permission\.

- EC\-07: Lỗi kết nối Theme 4; hệ thống có thể giữ giá hợp lệ gần nhất để tham khảo nhưng phải đánh dấu stale và chặn checkout cho đến khi revalidate thành công\.

    

**Scenarios**



- SC\-01 — Lấy pricing preview thành công

    

```Gherkin
Given working state có khách hàng, sản phẩm, đơn vị bán và số lượng hợp lệ
When hệ thống yêu cầu pricing preview từ Theme 4
Then Theme 4 trả về giá áp dụng và nguồn giá
And Theme 5 hiển thị giá, chiết khấu và thành tiền tạm tính
And dòng hàng được đánh dấu pricing hợp lệ tại thời điểm preview
```



- SC\-02 — Giá thay đổi khi đổi khách hàng

    

```Gherkin
Given dòng hàng đang sử dụng pricing preview dành cho Khách lẻ
When người dùng chọn một khách hàng có giá riêng
Then preview cũ được đánh dấu stale
And hệ thống yêu cầu pricing preview theo khách hàng mới
And tổng tiền được cập nhật theo kết quả mới
```



- SC\-03 — Điều chỉnh giá thủ công hợp lệ

    

```Gherkin
Given người dùng có quyền sửa giá
And tenant policy cho phép manual price
When người dùng nhập một manual unit price hợp lệ
Then hệ thống lưu giá trị dưới dạng manual price intent
And hệ thống kiểm tra price floor và pricing policy
And thành tiền tạm tính được cập nhật
```



- SC\-04 — Không có quyền sửa giá

    

```Gherkin
Given người dùng không có quyền sửa giá
When người dùng cố nhập manual unit price
Then hệ thống không chấp nhận thay đổi
And hệ thống hiển thị lý do không có quyền
And pricing preview trước đó vẫn được giữ nguyên
```



- SC\-05 — Giá dưới sàn bị chặn

    

```Gherkin
Given tenant policy không cho phép bán dưới price floor
When người dùng nhập manual price thấp hơn price floor
Then hệ thống chặn áp dụng manual price
And hệ thống hiển thị giá sàn hoặc lý do chặn theo quyền xem dữ liệu
And dòng hàng giữ giá hợp lệ trước đó
```



- SC\-06 — Giá dưới sàn được override

    

```Gherkin
Given tenant policy cho phép override price floor
And người dùng có quyền bán dưới giá sàn
When người dùng xác nhận manual price thấp hơn price floor
Then hệ thống chấp nhận manual price intent
And hệ thống đánh dấu dòng hàng có manual override
And thao tác được giữ lại để checkout validate lại
```



- SC\-07 — Không lấy được giá hợp lệ

    

```Gherkin
Given Theme 4 không trả được pricing preview hợp lệ
When người dùng chọn "Thanh toán"
Then hệ thống không cho chuyển sang EP-02
And hệ thống chỉ rõ dòng hàng đang thiếu giá
And hệ thống chưa tạo SalesOrder hoặc payment transaction
```



**References**



- Domains:

    - Sales Order Lifecycle

    - Theme 4 — Chính sách giá \& ưu đãi

- Data:

    - `PricingPreview`

    - `SalesOrderDraftLine.pricing_preview`

    - `manual_unit_price_input`

    - `manual_discount_amount_input`

- Commands / queries / events:

    - Pricing preview contract của Theme 4

    - Pricing validation tại `PrecheckSalesOrderCheckout`

    - Pricing validation lại trong `FinalizeSalesOrder`

- Permissions:

    - Quyền xem nguồn giá

    - Quyền sửa giá

    - Quyền áp dụng chiết khấu thủ công

    - Quyền override price floor nếu tenant hỗ trợ

- External dependencies:

    - Theme 2 — Giá niêm yết và price floor theo sản phẩm, đơn vị bán

    - Theme 4 — Pricing engine, promotion, giá riêng, nhớ giá và policy

        

#### 4\.2\.6\.6 US\-05 — Lưu giá riêng hoặc nhớ giá từ đơn hàng

**Business context**



Trong quá trình bán hàng, người bán hoặc quản lý có thể thỏa thuận một mức giá phù hợp cho một khách hàng cụ thể\. Khi mức giá này cần được sử dụng ở các lần bán sau, Theme 5 phải chuyển đúng ngữ cảnh sang Theme 4\.



Theme 5 không tự tạo, cập nhật hoặc sở hữu rule giá riêng/nhớ giá\. User Story này chỉ cung cấp entry point, truyền context và giữ nguyên working state khi người dùng chuyển sang Theme 4\.



**User story statement**



|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng hoặc Quản lý cửa hàng|Lưu giá riêng hoặc nhớ giá từ một dòng hàng đang lập|Mức giá phù hợp có thể được sử dụng cho khách hàng trong những lần bán sau|



**Functional requirements**



- FR\-01: Hệ thống phải hiển thị entry point lưu giá riêng/nhớ giá trên dòng hàng khi người dùng và dữ liệu đủ điều kiện\.

- FR\-02: Trước khi mở flow, hệ thống phải kiểm tra khách hàng định danh, sản phẩm, đơn vị bán, giá hiện tại và permission\.

- FR\-03: Theme 5 phải truyền sang Theme 4 tối thiểu customer, product, product unit, current unit price, discount context, store và source working context\.

- FR\-04: Hệ thống phải giữ nguyên working state khi người dùng chuyển sang Theme 4\.

- FR\-05: Khi Theme 4 tạo hoặc cập nhật rule thành công, Theme 5 phải nhận kết quả và cho phép làm mới pricing preview\.

- FR\-06: Khi người dùng hủy hoặc Theme 4 từ chối thao tác, Theme 5 phải quay lại đúng working state và dòng hàng nguồn\.

- FR\-07: Hệ thống không được tự động thay đổi dòng hàng hiện tại nếu chưa nhận pricing preview mới hoặc chưa có xác nhận áp dụng kết quả mới\.

    

**Business rules**



- BR\-01: Theme 5 không trực tiếp tạo, sửa hoặc sở hữu dữ liệu giá riêng/nhớ giá\.

- BR\-02: Chỉ khách hàng định danh có `customer_partner_id` mới đủ điều kiện lưu giá riêng/nhớ giá\.

- BR\-03: Dòng hàng phải có sản phẩm, đơn vị bán và mức giá hiện tại hợp lệ trước khi mở flow\.

- BR\-04: Người dùng phải có permission phù hợp của Theme 4 để tạo hoặc cập nhật rule giá\.

- BR\-05: Lưu giá riêng/nhớ giá không tự động hoàn tất đơn, tạo payment, receivable, inventory impact hoặc receipt\.

- BR\-06: Nếu Theme 4 trả blocker như rule trùng, dữ liệu không hợp lệ, giá dưới sàn hoặc thiếu quyền, working state phải được giữ nguyên\.

- BR\-07: Rule mới chỉ ảnh hưởng dòng hiện tại sau khi Theme 5 lấy lại pricing preview và áp dụng kết quả hiện hành một cách rõ ràng\.

    

**Acceptance criteria**



- AC\-01: Entry point chỉ khả dụng khi đơn có khách hàng định danh và dòng hàng hợp lệ\.

- AC\-02: Người dùng không có quyền không thể mở hoặc hoàn tất flow lưu giá\.

- AC\-03: Theme 4 nhận đúng customer, product, unit và price context từ dòng hàng nguồn\.

- AC\-04: Working state và các dòng hàng không bị mất khi chuyển sang hoặc quay lại từ Theme 4\.

- AC\-05: Sau khi lưu rule thành công, người dùng có thể làm mới pricing preview cho dòng hiện tại\.

- AC\-06: Hủy hoặc thất bại trong Theme 4 không làm thay đổi ngoài ý muốn giá và tổng tiền hiện tại\.

- AC\-07: Theme 5 không tạo dữ liệu pricing master hoặc business impact thuộc Theme khác\.

    

**Edge cases**



- EC\-01: Đơn đang sử dụng Khách lẻ; hệ thống chặn lưu giá và yêu cầu chọn khách hàng định danh\.

- EC\-02: Dòng hàng chưa có pricing preview hợp lệ; hệ thống không mở flow lưu giá\.

- EC\-03: Sản phẩm hoặc đơn vị bán không còn hợp lệ; hệ thống yêu cầu xử lý dòng hàng trước\.

- EC\-04: Người dùng không có permission của Theme 4; action bị ẩn hoặc disable\.

- EC\-05: Theme 4 phát hiện rule trùng; Theme 5 hiển thị kết quả và giữ nguyên working state\.

- EC\-06: Theme 4 tạo rule thành công nhưng pricing preview mới chưa tải được; Theme 5 giữ giá hiện tại, đánh dấu cần làm mới và không tự áp dụng giá chưa xác minh\.

- EC\-07: Người dùng đổi khách hàng khi đang ở flow Theme 4; context cũ bị coi là stale và phải quay lại đơn để khởi tạo lại\.

    

**Scenarios**



- SC\-01 — Mở flow lưu giá riêng

    

```Gherkin
Given working state có khách hàng định danh
And dòng hàng có sản phẩm, đơn vị bán và giá hợp lệ
And người dùng có quyền tạo giá riêng
When người dùng chọn "Lưu giá cho khách hàng"
Then Theme 5 mở flow phù hợp của Theme 4
And truyền đúng customer, product, unit và current price context
And working state được giữ nguyên
```



- SC\-02 — Chặn Khách lẻ lưu giá riêng

    

```Gherkin
Given working state đang sử dụng Khách lẻ
When người dùng chọn action lưu giá riêng
Then hệ thống không mở flow Theme 4
And hệ thống yêu cầu chọn khách hàng có hồ sơ
And dòng hàng hiện tại không thay đổi
```



- SC\-03 — Lưu rule thành công

    

```Gherkin
Given người dùng đã mở flow Theme 4 từ một dòng hàng hợp lệ
When Theme 4 tạo hoặc cập nhật rule thành công
Then Theme 5 quay lại working state
And hệ thống yêu cầu pricing preview mới cho dòng hàng
And người dùng có thể tiếp tục lập đơn
```



- SC\-04 — Hủy flow Theme 4

    

```Gherkin
Given người dùng đang ở flow lưu giá của Theme 4
When người dùng hủy thao tác
Then hệ thống quay lại đúng working state và dòng hàng nguồn
And giá và tổng tiền hiện tại không thay đổi
And không có pricing rule mới được tạo
```



- SC\-05 — Theme 4 từ chối do rule trùng

    

```Gherkin
Given đã có rule giá đang áp dụng cho cùng khách hàng, sản phẩm và đơn vị bán
When người dùng cố lưu một rule trùng
Then Theme 4 từ chối theo conflict policy
And Theme 5 hiển thị kết quả từ Theme 4
And working state được giữ nguyên
```



- SC\-06 — Không tải được pricing preview sau khi lưu rule

    

```Gherkin
Given Theme 4 đã lưu rule thành công
And Theme 5 chưa tải được pricing preview mới
When người dùng quay lại working state
Then hệ thống giữ nguyên giá hiện tại để tham khảo
And đánh dấu dòng hàng cần làm mới giá
And không cho checkout bằng pricing chưa được xác minh
```



**References**



- Domains:

    - Sales Order Lifecycle

    - Theme 4 — Chính sách giá \& ưu đãi

- Data:

    - `SalesOrderWorkingState`

    - `SalesOrderDraftLine`

    - Customer context

    - Product context

    - Product Unit context

    - `PricingPreview`

- Commands / queries / events:

    - Entry contract tạo/cập nhật giá riêng của Theme 4

    - Entry contract nhớ giá của Theme 4

    - Pricing preview contract của Theme 4

- Permissions:

    - Permission tạo hoặc cập nhật giá riêng của Theme 4

    - Permission nhớ giá của Theme 4

    - Permission override price floor nếu áp dụng

- External dependencies:

    - Theme 3 — Khách hàng định danh

    - Theme 4 — Giá riêng, nhớ giá, price floor và conflict policy

        

#### 4\.2\.6\.7 US\-06 — Lưu đơn hàng thành đơn nháp

**Business context**



Giao dịch tại quầy có thể bị gián đoạn khi khách chưa quyết định, cần bổ sung thông tin hoặc người bán cần chuyển sang phục vụ khách khác\. Người dùng cần chủ động lưu dữ liệu đang lập để có thể quay lại sau\.



Chỉ khi người dùng chọn Lưu đơn nháp, hệ thống mới tạo `SalesOrderDraft`\. Draft chưa phải giao dịch bán chính thức và không tạo tác động tài chính, tồn kho hoặc chứng từ\.



**User story statement**



|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Lưu đơn hàng đang lập thành đơn nháp|Tôi có thể tạm dừng giao dịch mà không mất dữ liệu đã nhập|



**Functional requirements**



- FR\-01: Hệ thống phải cho phép người dùng chọn Lưu đơn nháp khi working state có ít nhất một dòng hàng có cấu trúc hợp lệ\.

- FR\-02: Trước khi lưu, hệ thống phải kiểm tra tenant, cửa hàng, người tạo, product, product unit và quantity của các dòng\.

- FR\-03: Hệ thống phải thực hiện `SaveSalesOrderDraft` để tạo một `SalesOrderDraft` ở trạng thái `active`\.

- FR\-04: Hệ thống phải lưu draft context, customer reference, currency, note, draft lines, manual price/discount inputs và pricing preview hiện có\.

- FR\-05: Sau khi lưu thành công, hệ thống phải trả về draft ID, version, status và thời điểm lưu\.

- FR\-06: Người dùng có thể tiếp tục chỉnh sửa draft vừa lưu hoặc rời flow; lần lưu tiếp theo phải sử dụng `UpdateSalesOrderDraft`\.

- FR\-07: Nếu lưu thất bại, hệ thống không được tạo draft hoặc draft lines một phần và phải giữ working state để người dùng thử lại\.

    

**Business rules**



- BR\-01: `SalesOrderDraft` chỉ được tạo khi người dùng chủ động thực hiện hành động lưu\.

- BR\-02: Một persisted draft phải có ít nhất một `SalesOrderDraftLine` với product, product unit và quantity hợp lệ\.

- BR\-03: Pricing preview có thể được lưu để tham khảo nhưng không phải commercial snapshot và không cần được coi là giá cuối cùng\.

- BR\-04: Draft không tạo doanh thu, payment transaction, receivable, stock movement, inventory impact, receipt hoặc e\-invoice request\.

- BR\-05: Draft mới có trạng thái `active` và version bắt đầu từ 1\.

- BR\-06: Draft và tất cả draft lines phải thuộc cùng tenant và cửa hàng\.

- BR\-07: `SaveSalesOrderDraft` nên dùng idempotency để tránh tạo nhiều draft khi người dùng submit hoặc retry cùng một yêu cầu\.

    

**Acceptance criteria**



- AC\-01: Người dùng có quyền có thể lưu working state có ít nhất một dòng hợp lệ thành draft\.

- AC\-02: Draft được tạo với đúng tenant, cửa hàng, người tạo và customer reference nếu có\.

- AC\-03: Tất cả dòng hợp lệ được persist trong cùng aggregate với draft\.

- AC\-04: Draft mới có trạng thái `active` và version 1\.

- AC\-05: Lưu draft không tạo SalesOrder hoặc bất kỳ downstream business impact nào\.

- AC\-06: Sau khi lưu thành công, người dùng có thể mở hoặc tiếp tục chỉnh sửa đúng draft vừa tạo\.

- AC\-07: Khi lưu thất bại, working state vẫn còn đầy đủ và không xuất hiện draft không hoàn chỉnh\.

    

**Edge cases**



- EC\-01: Working state không có dòng hàng; hệ thống không cho lưu draft\.

- EC\-02: Một dòng có quantity không hợp lệ; hệ thống chỉ rõ dòng cần sửa và không lưu một phần\.

- EC\-03: Sản phẩm hoặc đơn vị bán không còn tồn tại; hệ thống chặn lưu dòng không còn tham chiếu hợp lệ\.

- EC\-04: Pricing preview đang stale hoặc chưa có; hệ thống vẫn có thể lưu draft nếu product, unit và quantity hợp lệ, nhưng phải đánh dấu cần revalidate khi khôi phục\.

- EC\-05: Người dùng bấm Lưu nhiều lần; idempotency phải ngăn tạo nhiều draft cho cùng request\.

- EC\-06: Mất kết nối sau khi server đã lưu thành công; retry cùng idempotency context phải trả lại draft đã tạo\.

- EC\-07: Ca bán vừa đóng; hệ thống vẫn cho phép lưu dữ liệu thành draft để tránh mất dữ liệu, nhưng checkout sau này phải xác định lại ca bán hợp lệ\.

    

**Scenarios**



- SC\-01 — Lưu draft thành công

    

```Gherkin
Given working state có ít nhất một dòng hàng hợp lệ
And người dùng có quyền sales.draft.create
When người dùng chọn "Lưu đơn nháp"
Then hệ thống thực hiện SaveSalesOrderDraft
And tạo một SalesOrderDraft ở trạng thái active
And tạo các SalesOrderDraftLine liên quan
And trả về draft ID và version 1
```



- SC\-02 — Lưu draft có khách hàng định danh

    

```Gherkin
Given working state đang gắn với một khách hàng có hồ sơ
And working state có các dòng hợp lệ
When người dùng lưu draft
Then customer_partner_id được lưu trên SalesOrderDraft
And chưa có customer snapshot chính thức được tạo
```



- SC\-03 — Không cho lưu draft rỗng

    

```Gherkin
Given working state không có dòng hàng
When người dùng chọn "Lưu đơn nháp"
Then hệ thống không tạo SalesOrderDraft
And hệ thống yêu cầu thêm ít nhất một sản phẩm
```



- SC\-04 — Lưu draft khi pricing preview cần làm mới

    

```Gherkin
Given working state có product, unit và quantity hợp lệ
And pricing preview của một dòng đang stale
When người dùng chọn "Lưu đơn nháp"
Then hệ thống lưu draft thành công
And dòng được đánh dấu cần revalidate khi khôi phục
And pricing preview không được coi là giá chính thức
```



- SC\-05 — Submit lưu draft nhiều lần

    

```Gherkin
Given người dùng đã gửi một request lưu draft
When cùng request được gửi lại với cùng idempotency context
Then hệ thống trả lại SalesOrderDraft đã tạo
And không tạo draft hoặc draft line trùng
```



- SC\-06 — Lưu draft thất bại

    

```Gherkin
Given working state có dữ liệu
When SaveSalesOrderDraft thất bại trước khi commit
Then hệ thống không tạo SalesOrderDraft hoặc draft line một phần
And working state vẫn được giữ nguyên
And người dùng có thể thử lại
```



**References**



- Domains:

    - Sales Order Lifecycle

- Data:

    - `SalesOrderWorkingState`

    - `SalesOrderDraft`

    - `SalesOrderDraftLine`

    - `PricingPreview`

- Commands / queries / events:

    - `SaveSalesOrderDraft`

    - `UpdateSalesOrderDraft`

    - `SalesOrderDraftSaved`

    - `SalesOrderDraftUpdated`

- Permissions:

    - `sales.draft.create`

    - `sales.draft.update`

- External dependencies:

    - Theme 1 — Tenant, store, user và permission context

    - Theme 2 — Product và Product Unit references

    - Theme 3 — Customer reference

    - Theme 4 — Pricing preview

        

#### 4\.2\.6\.8 US\-07 — Khôi phục và quản lý đơn nháp

**Business context**



Đơn nháp được lưu để người bán có thể tiếp tục giao dịch sau một khoảng thời gian\. Trong thời gian đó, khách hàng, sản phẩm, đơn vị bán, giá hoặc permission có thể đã thay đổi\.



Hệ thống phải khôi phục nội dung đã lưu nhưng đồng thời kiểm tra dữ liệu hiện hành\. Những thay đổi mới không được âm thầm ghi đè nội dung draft hoặc biến draft thành một giao dịch khác với nội dung người dùng đã lưu\.



Ngoài khôi phục, người dùng cần có thể cập nhật hoặc hủy mềm draft\. Draft đã converted, cancelled hoặc expired không được tiếp tục chỉnh sửa\.



**User story statement**



|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Xem, mở lại, cập nhật hoặc hủy một đơn nháp|Tôi có thể tiếp tục giao dịch cũ an toàn và không sử dụng dữ liệu đã hết hiệu lực|



**Functional requirements**



- FR\-01: Hệ thống phải cho phép người dùng xem danh sách các draft `active` trong tenant, cửa hàng và phạm vi được cấp quyền\.

- FR\-02: Khi người dùng chọn một draft, hệ thống phải thực hiện `GetSalesOrderDraftForRestore` và tái tạo working state từ dữ liệu đã lưu\.

- FR\-03: Hệ thống phải kiểm tra lại customer, product, product unit, quantity, permission và pricing preview khi khôi phục\.

- FR\-04: Hệ thống phải hiển thị rõ dòng hoặc dữ liệu đã thay đổi, không còn hợp lệ hoặc cần người dùng xác nhận lại\.

- FR\-05: Cho phép cập nhật draft `active` bằng `UpdateSalesOrderDraft` với `expected_version`\.

- FR\-06: Cho phép người dùng có quyền hủy mềm draft `active` bằng `CancelSalesOrderDraft`\.

- FR\-07: Hệ thống phải chặn chỉnh sửa draft đã `converted`, `cancelled` hoặc `expired`; draft hết hạn được xử lý bằng `ExpireSalesOrderDraft`\.

    

**Business rules**



- BR\-01: Restore draft là hành động đọc và tái tạo working state; `restored` không phải lifecycle state\.

- BR\-02: Chỉ draft `active` mới được tiếp tục chỉnh sửa hoặc chuyển sang checkout\.

- BR\-03: Draft bị hủy phải chuyển sang `cancelled`; không hard delete draft hoặc draft lines\.

- BR\-04: `UpdateSalesOrderDraft` bắt buộc kiểm tra `expected_version` để tránh lost update\.

- BR\-05: Dữ liệu hiện hành khác dữ liệu đã lưu phải được đánh dấu rõ; hệ thống không được âm thầm thay sản phẩm, đơn vị, khách hàng hoặc giá\.

- BR\-06: Draft chỉ được truy cập trong đúng tenant và store scope; quyền xem, restore, update và cancel được kiểm tra độc lập\.

- BR\-07: Draft hết hạn, bị hủy hoặc đã convert vẫn được bảo toàn để audit nhưng không xuất hiện như draft có thể tiếp tục xử lý\.

    

**Acceptance criteria**



- AC\-01: Người dùng chỉ nhìn thấy draft nằm trong tenant, cửa hàng và phạm vi được phép\.

- AC\-02: Draft `active` được khôi phục với đầy đủ customer reference, dòng hàng, manual input, note và pricing preview đã lưu\.

- AC\-03: Hệ thống nhận diện và hiển thị dữ liệu không còn hợp lệ trước khi cho phép checkout\.

- AC\-04: Người dùng có thể cập nhật draft khi `expected_version` khớp version hiện tại\.

- AC\-05: Version conflict không ghi đè dữ liệu mới hơn và yêu cầu người dùng tải lại\.

- AC\-06: Hủy draft thành công chuyển status sang `cancelled` và draft không còn xuất hiện trong danh sách active\.

- AC\-07: Draft `converted`, `cancelled` hoặc `expired` không thể được chỉnh sửa hoặc checkout lại\.

    

**Edge cases**



- EC\-01: Draft bị người khác cập nhật sau khi người dùng mở; hệ thống trả version conflict và không ghi đè\.

- EC\-02: Draft hết hạn trong lúc người dùng đang xem; thao tác lưu hoặc checkout bị chặn và trạng thái được tải lại\.

- EC\-03: Khách hàng trong draft đã ngừng hoạt động; hệ thống giữ reference để hiển thị nhưng yêu cầu chọn lại customer context\.

- EC\-04: Sản phẩm đã ngừng bán hoặc đơn vị không còn hợp lệ; dòng được đánh dấu blocked và không được checkout\.

- EC\-05: Giá hiện hành khác pricing preview đã lưu; hệ thống hiển thị thay đổi và yêu cầu người dùng kiểm tra lại\.

- EC\-06: Draft đã được convert bởi một request checkout khác; hệ thống không cho restore để chỉnh sửa và trả thông tin kết quả hiện hành\.

- EC\-07: Người dùng bấm hủy draft nhiều lần; idempotency phải trả cùng kết quả và không tạo activity trùng\.

    

**Scenarios**



- SC\-01 — Xem danh sách draft active

    

```Gherkin
Given người dùng có quyền truy cập draft tại cửa hàng hiện tại
When người dùng mở danh sách đơn nháp
Then hệ thống hiển thị các SalesOrderDraft ở trạng thái active trong phạm vi được phép
And không hiển thị draft của tenant hoặc cửa hàng ngoài phạm vi
```



- SC\-02 — Khôi phục draft không có thay đổi

    

```Gherkin
Given draft đang active
And customer, product, unit và pricing context vẫn hợp lệ
When người dùng mở draft
Then hệ thống tái tạo working state từ draft
And không tạo lifecycle state mới
And người dùng có thể tiếp tục chỉnh sửa hoặc chọn Thanh toán
```



- SC\-03 — Khôi phục draft có giá thay đổi

    

```Gherkin
Given draft đang active
And giá hiện hành khác pricing preview đã lưu
When người dùng mở draft
Then hệ thống hiển thị giá đã lưu và thông tin giá hiện hành cần kiểm tra
And đánh dấu dòng cần revalidate
And không âm thầm hoàn tất giao dịch theo giá mới
```



- SC\-04 — Khôi phục draft có sản phẩm không còn hợp lệ

    

```Gherkin
Given draft có một sản phẩm đã ngừng bán
When người dùng mở draft
Then hệ thống vẫn hiển thị dòng hàng đã lưu
And đánh dấu dòng bị chặn
And yêu cầu người dùng xóa hoặc thay thế dòng trước khi checkout
```



- SC\-05 — Cập nhật draft thành công

    

```Gherkin
Given draft đang active với version 3
And người dùng có quyền sales.draft.update
When người dùng lưu thay đổi với expected_version bằng 3
Then hệ thống cập nhật draft
And tăng version lên 4
And phát SalesOrderDraftUpdated
```



- SC\-06 — Version conflict

    

```Gherkin
Given người dùng đang sửa draft version 3
And draft đã được người khác cập nhật thành version 4
When người dùng gửi UpdateSalesOrderDraft với expected_version bằng 3
Then hệ thống từ chối cập nhật
And không ghi đè dữ liệu version 4
And yêu cầu người dùng tải lại draft
```



- SC\-07 — Hủy mềm draft

    

```Gherkin
Given draft đang active
And người dùng có quyền sales.draft.delete
When người dùng xác nhận hủy đơn nháp
Then hệ thống thực hiện CancelSalesOrderDraft
And status của draft chuyển thành cancelled
And draft không còn xuất hiện trong danh sách active
And dữ liệu draft không bị hard delete
```



**References**



- Domains:

    - Sales Order Lifecycle

- Data:

    - `SalesOrderDraft`

    - `SalesOrderDraftLine`

    - `SalesOrderDraftForRestoreView`

    - `SalesOrderWorkingState`

    - `PricingPreview`

- Commands / queries / events:

    - `ListSalesOrderDrafts`

    - `GetSalesOrderDraftForRestore`

    - `UpdateSalesOrderDraft`

    - `CancelSalesOrderDraft`

    - `ExpireSalesOrderDraft`

    - `SalesOrderDraftUpdated`

    - `SalesOrderDraftCancelled`

    - `SalesOrderDraftExpired`

    - `SalesOrderDraftConverted`

- Permissions:

    - `sales.draft.restore`

    - `sales.draft.update`

    - `sales.draft.delete`

    - `sales.checkout.create`

- External dependencies:

    - Theme 1 — Tenant, store scope, membership và permission

    - Theme 2 — Product, Product Unit và sellability hiện hành

    - Theme 3 — Customer status hiện hành

    - Theme 4 — Pricing preview và pricing validation hiện hành

## 4\.3 EP\-02 — Thanh toán \& hoàn tất đơn hàng

### 4\.3\.1 Overview

Epic này bao phủ giai đoạn từ khi đơn hàng đang lập hoặc đơn nháp đã khôi phục **đủ điều kiện chuyển sang thanh toán** đến khi giao dịch được chốt thành đơn hàng chính thức, các khoản thanh toán được ghi nhận, khoản còn phải thu được xác định và người bán nhận được kết quả giao dịch\.

Trong Epic này, **Hoàn tất đơn hàng** là một business command chốt giao dịch, không phải tên của trạng thái thanh toán\.

Khi người dùng xác nhận hoàn tất, hệ thống phải:

- Kiểm tra lại toàn bộ dữ liệu và điều kiện checkout tại backend\.

- Tạo hoặc cập nhật `CheckoutAttempt`\.

- Tạo đúng một `SalesOrder` chính thức và các `SalesOrderLine`\.

- Lưu commercial snapshot tại thời điểm bán\.

- Khởi tạo `SalesOrderSettlement`\.

- Ghi nhận các `SalesPaymentTransaction` hợp lệ nếu có\.

- Xác định trạng thái thanh toán\.

- Xác định khoản còn phải thu nếu khách chưa thanh toán đủ\.

- Tạo các business impact request cần thiết cho công nợ, tồn kho, hóa đơn điện tử và báo cáo\.

- Tạo phiếu bán hàng nội bộ\.

- Trả về kết quả giao dịch rõ ràng cho người dùng\.

    

`SalesOrder`, commercial snapshot, settlement và payment transaction là các authoritative records riêng biệt\. Trạng thái thanh toán không được trộn vào lifecycle của đơn hàng\.

Checkout phải được xử lý theo cơ chế idempotency\. Việc người dùng bấm nhiều lần, ứng dụng gửi lại request hoặc mất kết nối khi đang xử lý không được tạo thêm đơn hàng, khoản thanh toán hoặc downstream impact trùng lặp\.

Epic kết thúc theo một trong các hướng:

- Checkout thành công và hệ thống trả về kết quả đơn hàng chính thức\.

- Checkout bị chặn do dữ liệu hoặc điều kiện nghiệp vụ không hợp lệ\.

- Checkout thất bại trước khi commit và người dùng có thể sửa dữ liệu hoặc thử lại\.

- Kết quả checkout chưa xác định do timeout hoặc mất kết nối; hệ thống chuyển sang cơ chế kiểm tra và khôi phục kết quả\.

### 4\.3\.2 Business context

Sau khi người bán đã chọn khách hàng, thêm các dòng hàng và kiểm tra giá tạm tính, người bán cần ghi nhận cách khách thanh toán và chốt giao dịch\.

Một đơn hàng có thể được xử lý theo các trường hợp:

- Thanh toán đủ bằng một phương thức\.

- Thanh toán đủ bằng nhiều phương thức\.

- Thanh toán một phần và phát sinh khoản còn phải thu\.

- Chưa thanh toán và toàn bộ giá trị đơn trở thành khoản còn phải thu nếu policy cho phép\.

    

Trong Phase 1, Theme 5 hỗ trợ tối thiểu:

- **Tiền mặt\.**

- **Chuyển khoản thủ công\.**

    

Một khoản thanh toán phải xác định được:

- Số tiền\.

- Phương thức thanh toán\.

- Thời điểm ghi nhận\.

- Người ghi nhận\.

- Thông tin tham chiếu nếu có\.

- Đơn hàng và settlement liên quan\.

    

Tổng số tiền thanh toán không được vượt quá tổng khách phải trả, trừ khi hệ thống có nghiệp vụ tiền thừa hoặc tiền khách gửi trước được định nghĩa riêng trong tương lai\.

Nếu khách chưa thanh toán đủ, hệ thống phải xác định giao dịch có được phép bán thiếu hay không:

- **Khách lẻ phải thanh toán đủ** trước khi hoàn tất đơn hàng\.

- Khách hàng có hồ sơ chỉ được phát sinh khoản còn phải thu khi policy của tenant cho phép\.

- Người thực hiện phải có quyền bán thiếu hoặc cho phép hoàn tất đơn chưa thanh toán\.

- Phải có ngày hẹn thanh toán hợp lệ nếu tenant yêu cầu\.

- Ngày hẹn thanh toán không được trước ngày hoàn tất đơn hàng\.

- Khách hàng phải còn hợp lệ để phát sinh giao dịch và công nợ mới\.

    

Giá hiển thị ở EP\-01 chỉ là pricing preview\. Khi checkout, Theme 5 phải yêu cầu Theme 4 kiểm tra lại giá, chiết khấu, chương trình khuyến mại, nguồn giá và các điều kiện áp dụng tại thời điểm chốt giao dịch\.

Nếu kết quả giá thay đổi, hệ thống không được âm thầm hoàn tất đơn theo dữ liệu mới\. Người bán phải được thông báo về thay đổi và kiểm tra lại tổng tiền cũng như các khoản thanh toán\.

Khi checkout thành công, hệ thống phải bảo toàn commercial snapshot, tối thiểu gồm:

- Tenant và cửa hàng\.

- Người bán và thời điểm giao dịch\.

- Khách hàng hoặc thông tin Khách lẻ\.

- Thông tin người mua phục vụ hóa đơn nếu có\.

- Sản phẩm và đơn vị bán\.

- Số lượng\.

- Đơn giá\.

- Chiết khấu và chương trình khuyến mại\.

- Nguồn giá\.

- Thuế và quy tắc làm tròn\.

- Thành tiền từng dòng\.

- Tổng giá trị giao dịch\.

    

Commercial snapshot không được cập nhật ngược khi tên khách hàng, tên sản phẩm, đơn vị bán, giá hoặc master data thay đổi sau này\.

Việc tạo đơn hàng chính thức và ghi nhận business intent cho các downstream impacts phải được thực hiện nhất quán\. Tuy nhiên, các domain bên ngoài như Kho, Công nợ và Hóa đơn điện tử có thể xử lý bất đồng bộ\.

Vì vậy, người bán cần phân biệt rõ:

- Đơn hàng đã được tạo thành công\.

- Thanh toán đã được ghi nhận\.

- Khoản còn phải thu đã được gửi sang Theme 6\.

- Tác động tồn kho đang chờ hoặc đã được Theme 7 tiếp nhận\.

- Yêu cầu hóa đơn điện tử đang chờ hoặc đã được Theme 8 tiếp nhận\.

- Downstream integration nào cần thử lại hoặc đối soát\.

    

Lỗi đồng bộ downstream sau khi SalesOrder đã được commit không được làm người dùng hiểu rằng đơn hàng chưa tồn tại\. Hệ thống phải hiển thị trạng thái đúng và cung cấp cơ chế retry hoặc reconciliation riêng\.

Sau checkout, người bán thường cần xem, in hoặc chia sẻ **phiếu bán hàng nội bộ**\. Phiếu này được sinh từ snapshot của đơn hàng và không phải hóa đơn điện tử\.

### 4\.3\.3 In scope

- Mở màn Thanh toán từ đơn hàng đang lập hoặc đơn nháp active đã được khôi phục\.

- Giữ nguyên ngữ cảnh tenant, cửa hàng, người bán, khách hàng và các dòng hàng khi chuyển từ EP\-01 sang EP\-02\.

- Hiển thị tóm tắt giao dịch gồm:

    - Tổng tiền hàng\.

    - Tổng chiết khấu\.

    - Thuế nếu có\.

    - Điều chỉnh làm tròn nếu có\.

    - Tổng khách phải trả\.

    - Tổng đã nhập thanh toán\.

    - Số tiền còn phải thu\.

    - Trạng thái thanh toán dự kiến\.

- Cho phép ghi nhận một hoặc nhiều khoản thanh toán cho cùng một đơn hàng\.

- Hỗ trợ thanh toán bằng Tiền mặt\.

- Hỗ trợ thanh toán bằng Chuyển khoản thủ công\.

- Cho phép kết hợp nhiều phương thức thanh toán trong cùng một đơn\.

- Cho phép thêm, cập nhật hoặc xóa khoản thanh toán trước khi xác nhận hoàn tất\.

- Kiểm tra mỗi khoản thanh toán có số tiền lớn hơn 0 và phương thức thanh toán hợp lệ\.

- Kiểm tra tổng thanh toán không vượt quá tổng khách phải trả\.

- Tự động tính lại số tiền còn phải thu sau mỗi thay đổi thanh toán\.

- Xác định trạng thái thanh toán dự kiến:

    - `unpaid`\.

    - `partially_paid`\.

    - `paid`\.

- Chặn Khách lẻ hoàn tất đơn hàng khi chưa thanh toán đủ\.

- Kiểm tra điều kiện bán thiếu đối với khách hàng có hồ sơ\.

- Kiểm tra quyền bán thiếu hoặc hoàn tất đơn chưa thanh toán\.

- Ghi nhận ngày hẹn thanh toán và thông tin hỗ trợ công nợ nếu còn phải thu\.

- Kiểm tra ngày hẹn thanh toán không trước ngày hoàn tất đơn hàng\.

- Hiển thị cảnh báo rõ số tiền sẽ được chuyển thành khoản còn phải thu\.

- Cho phép người dùng quay lại EP\-01 để sửa khách hàng, dòng hàng, số lượng, đơn vị bán, giá hoặc chiết khấu trước khi checkout\.

- Thực hiện `PrecheckSalesOrderCheckout` để hiển thị blockers và warnings trước khi người dùng xác nhận\.

- Validate lại tenant, store, membership, permission và operational context tại thời điểm checkout\.

- Validate lại khách hàng và điều kiện phát sinh công nợ\.

- Validate lại sản phẩm, đơn vị bán, số lượng và trạng thái sẵn sàng bán\.

- Gọi Theme 4 để validate lại giá, chiết khấu, promotion và pricing source tại checkout\.

- Kiểm tra stale data giữa dữ liệu người dùng đang thấy và dữ liệu hiện hành\.

- Kiểm tra tồn kho hoặc reservation theo policy của tenant và contract với Theme 7\.

- Kiểm tra thông tin người mua phục vụ hóa đơn nếu người dùng yêu cầu xuất hóa đơn điện tử\.

- Tạo `CheckoutAttempt` cho mỗi yêu cầu checkout\.

- Lưu request snapshot, trạng thái xử lý, blockers, failure result và kết quả của checkout attempt\.

- Yêu cầu idempotency key cho command `FinalizeSalesOrder`\.

- Phát hiện cùng idempotency key nhưng payload khác và trả về conflict\.

- Trả lại cùng một kết quả khi cùng idempotency key và cùng payload được gửi lại\.

- Khóa CTA Hoàn tất đơn hàng trong khi request đang được xử lý trên client\.

- Tạo đúng một `SalesOrder` từ một checkout attempt thành công\.

- Tạo các `SalesOrderLine` chính thức\.

- Tạo mã đơn hàng duy nhất trong tenant\.

- Lưu commercial snapshot của đơn hàng và từng dòng hàng\.

- Lưu customer snapshot nếu đơn gắn với khách hàng có hồ sơ\.

- Lưu buyer tax snapshot nếu có yêu cầu hóa đơn điện tử\.

- Lưu product, product unit, pricing, discount, promotion, tax và rounding snapshot\.

- Đảm bảo tổng SalesOrder khớp với tổng các dòng hàng, chiết khấu, thuế và làm tròn\.

- Chuyển `SalesOrderDraft` nguồn sang `converted` sau khi SalesOrder được commit thành công\.

- Không chuyển draft sang `converted` nếu checkout chưa thành công\.

- Khởi tạo `SalesOrderSettlement` cho đơn hàng chính thức\.

- Tạo một `SalesPaymentTransaction` cho mỗi khoản thanh toán hợp lệ\.

- Không tạo payment transaction thu tiền nếu đơn hàng chưa thanh toán\.

- Xác định authoritative payment status từ settlement\.

- Ghi nhận tổng phải thu, tổng đã thu, tổng hoàn tiền bằng 0 tại thời điểm tạo và số còn phải thu\.

- Tạo `ReceivableImpactRequest` khi đơn hàng còn phải thu\.

- Không tạo khoản phải thu cho đơn đã thanh toán đủ\.

- Tạo `InventoryImpactRequest` hoặc integration command theo contract với Theme 7\.

- Ghi rõ source order, dòng hàng, sản phẩm, đơn vị và số lượng cần tác động tồn kho\.

- Không trực tiếp tạo hoặc cập nhật stock movement trong Theme 5\.

- Ghi nhận yêu cầu hoặc dữ liệu nguồn cho hóa đơn điện tử khi người dùng chọn xuất hóa đơn\.

- Tạo `EInvoiceImpactRequest` theo contract với Theme 8 nếu phạm vi triển khai hỗ trợ\.

- Không coi `EInvoiceImpactRequest` là hóa đơn điện tử đã được phát hành\.

- Phát event hoặc integration command phục vụ Reporting\.

- Lưu business change và các business impact request bắt buộc trong cùng local transaction với checkout\.

- Dùng outbox hoặc cơ chế delivery tin cậy để gửi integration command sau khi transaction được commit\.

- Hiển thị riêng business status và integration delivery status\.

- Xử lý checkout có kết quả `blocked`, `failed`, `uncertain` hoặc `succeeded`\.

- Cho phép kiểm tra lại `CheckoutAttempt` khi client bị timeout hoặc mất kết nối\.

- Nếu checkout đã thành công, trả lại SalesOrder đã tạo thay vì tạo giao dịch mới\.

- Nếu kết quả chưa xác định, hiển thị trạng thái đang kiểm tra và không khuyến khích người dùng tạo lại đơn mới\.

- Tạo `SalesReceipt` từ commercial snapshot sau khi SalesOrder được tạo thành công\.

- Hiển thị phiếu bán hàng nội bộ sau checkout\.

- Cho phép xem, in, tải hoặc chia sẻ phiếu bán hàng nếu thiết bị, kênh và permission hỗ trợ\.

- Ghi nhận hoạt động in, chia sẻ hoặc archive phiếu bán hàng\.

- Hiển thị màn kết quả giao dịch gồm:

    - Mã đơn hàng\.

    - Trạng thái đơn hàng\.

    - Trạng thái thanh toán\.

    - Tổng khách phải trả\.

    - Tổng đã thanh toán\.

    - Số tiền còn phải thu\.

    - Ngày hẹn thanh toán nếu có\.

    - Trạng thái tác động công nợ\.

    - Trạng thái tác động tồn kho\.

    - Trạng thái yêu cầu hóa đơn điện tử nếu có\.

    - Trạng thái tạo phiếu bán hàng\.

- Cung cấp các hành động tiếp theo từ màn kết quả:

    - Xem chi tiết đơn hàng\.

    - Xem phiếu bán hàng\.

    - In hoặc chia sẻ phiếu bán hàng\.

    - Tạo đơn hàng mới\.

    - Đi đến danh sách đơn hàng\.

- Ghi audit và correlation context cho checkout, payment, settlement, receipt và downstream impacts\.

### 4\.3\.4 Out of scope

- Lập hoặc chỉnh sửa dòng hàng trước bước Thanh toán\.

- Lưu, cập nhật, khôi phục hoặc xóa đơn nháp\.

- Quản lý hồ sơ khách hàng gốc\.

- Quản lý hồ sơ sản phẩm, SKU, barcode hoặc đơn vị bán gốc\.

- Thiết lập giá mặc định, giá sàn, giá riêng hoặc nhớ giá\.

- Thiết lập chương trình khuyến mại hoặc mã ưu đãi\.

- Quyết định pricing priority hoặc conflict policy\.

- Cấu hình thuế VAT hoặc quy tắc làm tròn của tenant\.

- Cấu hình danh mục phương thức thanh toán\.

- Thanh toán qua payment gateway\.

- Tự động xác nhận chuyển khoản từ ngân hàng\.

- Đối soát sao kê ngân hàng\.

- Ví điện tử, thẻ, BNPL hoặc các phương thức thanh toán online phức tạp\.

- Xử lý tiền thừa, tiền đặt cọc hoặc số dư khách hàng nếu chưa có nghiệp vụ riêng\.

- Tạo nhiều loại tiền tệ hoặc quy đổi ngoại tệ\.

- Thu công nợ sau bán\.

- Phân bổ một khoản thu sau bán cho nhiều đơn hàng\.

- Quản lý receivable ledger chi tiết\.

- Tính lãi, phí phạt hoặc tuổi nợ\.

- Trực tiếp tạo, cập nhật hoặc reverse stock movement\.

- Quản lý tồn kho, reservation hoặc giá vốn chi tiết\.

- Xử lý picking, packing, shipping hoặc fulfillment nhiều bước\.

- Quản lý giao hàng qua đơn vị vận chuyển\.

- Phát hành, ký số hoặc gửi hóa đơn điện tử đến cơ quan thuế\.

- Điều chỉnh, thay thế hoặc hủy hóa đơn điện tử\.

- Xử lý lỗi nghiệp vụ bên trong Theme 8\.

- Hạch toán kế toán hoặc ghi sổ kế toán chi tiết\.

- Lập báo cáo doanh thu hoặc dashboard quản trị\.

- Tra cứu và quản lý danh sách đơn hàng chính thức ngoài các điều hướng trực tiếp từ màn kết quả\.

- Điều chỉnh thông tin đơn hàng sau bán\.

- Hủy đơn hàng chính thức\.

- Hoàn tiền sau bán\.

- Đổi hàng hoặc trả hàng\.

- Cấn trừ chênh lệch đổi/trả vào công nợ\.

- Thiết kế hoặc quản lý mẫu phiếu bán hàng ở cấp cấu hình\.

- Workflow phê duyệt nhiều cấp cho bán thiếu hoặc checkout\.

### 4\.3\.5 Entry points

- Người dùng chọn **Thanh toán** từ đơn hàng đang lập trong EP\-01\.

- Người dùng chọn **Thanh toán** từ một đơn nháp active đã được khôi phục trong EP\-01\.

- Người dùng quay lại màn Thanh toán sau khi sửa dữ liệu đơn hàng ở EP\-01\.

- Người dùng quay lại màn Thanh toán sau khi bổ sung hoặc thay đổi khách hàng\.

- Người dùng quay lại màn Thanh toán sau khi xử lý cảnh báo giá hoặc cập nhật pricing preview\.

- Người dùng thử lại checkout sau khi precheck trả về blocker đã được xử lý\.

- Ứng dụng mở lại trạng thái checkout đang xử lý sau khi bị gián đoạn kết nối\.

- Ứng dụng gọi kiểm tra `CheckoutAttempt` khi request trước đó bị timeout hoặc trả kết quả chưa xác định\.

- Người dùng mở lại kết quả checkout đã thành công từ cùng idempotency context\.

Trước khi cho phép xác nhận Hoàn tất đơn hàng, hệ thống phải xác định được:

- Tenant hiện tại\.

- Cửa hàng hiện tại\.

- Người dùng và membership đang hoạt động\.

- Permission hoàn tất đơn hàng\.

- Ca bán hợp lệ nếu tenant vận hành theo ca\.

- Ít nhất một dòng hàng hợp lệ\.

- Khách hàng hoặc ngữ cảnh Khách lẻ hợp lệ\.

- Pricing validation hiện hành\.

- Tổng khách phải trả\.

- Các khoản thanh toán hợp lệ\.

- Điều kiện bán thiếu nếu còn phải thu\.

- Ngày hẹn thanh toán hợp lệ nếu bắt buộc\.

- Trạng thái dữ liệu không bị stale hoặc đã được người dùng xác nhận lại\.

EP\-02 kết thúc khi:

- Checkout thành công và hệ thống trả về kết quả của SalesOrder chính thức\.

- Checkout bị chặn và người dùng quay lại EP\-01 hoặc màn Thanh toán để xử lý\.

- Checkout thất bại trước khi commit và người dùng chọn thử lại hoặc rời khỏi luồng\.

- Checkout ở trạng thái `uncertain` và hệ thống tiếp tục kiểm tra kết quả theo `CheckoutAttempt`\.

- Người dùng chuyển từ màn kết quả sang chi tiết đơn hàng thuộc EP\-03\.

- Người dùng tạo một đơn hàng mới và quay lại EP\-01\.

### 4\.3\.6 User stories

#### 4\.3\.6\.1 User story map

|User story|As user|I want to|So that|Notes|
|---|---|---|---|---|
|US\-01 — Kiểm tra tổng tiền và nghĩa vụ thanh toán|Nhân viên bán hàng|Xem tổng phải trả, tổng đã nhập thanh toán và số tiền còn phải thu|Tôi có thể giải thích rõ nghĩa vụ thanh toán cho khách trước khi chốt giao dịch|Dữ liệu thanh toán trước checkout là payment intent, chưa phải payment transaction|
|US\-02 — Ghi nhận một hoặc nhiều khoản thanh toán|Nhân viên bán hàng|Nhập các khoản thanh toán bằng Tiền mặt, Chuyển khoản hoặc kết hợp nhiều phương thức|Tôi có thể phản ánh đúng cách khách thực tế thanh toán|Phase 1 hỗ trợ Tiền mặt và Chuyển khoản thủ công|
|US\-03 — Xử lý đơn hàng còn phải thu|Nhân viên bán hàng có quyền|Hoàn tất đơn chưa thanh toán đủ cho một khách hàng đủ điều kiện|Tôi có thể ghi nhận giao dịch bán thiếu và bàn giao phần còn phải thu sang công nợ|Khách lẻ phải thanh toán đủ; khách hàng định danh có thể phát sinh công nợ theo policy|
|US\-04 — Kiểm tra điều kiện checkout|Nhân viên bán hàng|Xem các cảnh báo, blocker và thay đổi dữ liệu trước khi hoàn tất đơn|Tôi có thể xử lý vấn đề trước khi tạo giao dịch chính thức|Validate lại context, customer, product, unit, pricing, inventory, payment và permission|
|US\-05 — Hoàn tất đơn hàng an toàn|Nhân viên bán hàng|Xác nhận checkout và nhận lại đúng một kết quả giao dịch kể cả khi request bị gửi lại hoặc gián đoạn|Tôi không tạo trùng đơn hàng, thanh toán hoặc tác động liên quan|Bao gồm idempotency, CheckoutAttempt và uncertain\-result recovery|
|US\-06 — Xem kết quả giao dịch|Nhân viên bán hàng|Xem mã đơn, trạng thái thanh toán, số còn phải thu và trạng thái xử lý liên quan|Tôi biết giao dịch đã thành công và nội dung nào còn đang được xử lý|Phân biệt business result với downstream integration status|
|US\-07 — Xem, in hoặc chia sẻ phiếu bán hàng|Nhân viên bán hàng|Xem, in hoặc chia sẻ phiếu bán hàng nội bộ sau checkout|Tôi có thể cung cấp chứng từ giao dịch cho khách mà không làm thay đổi đơn hàng|Phiếu bán hàng nội bộ không phải hóa đơn điện tử|



#### 4\.3\.6\.2 US\-01 — Kiểm tra tổng tiền và nghĩa vụ thanh toán

**Business context**

Trước khi thu tiền, người bán cần nhìn thấy rõ tổng giá trị giao dịch, các khoản đã nhập thanh toán và số tiền còn thiếu\. Đây là điểm kiểm soát giúp tránh thu sai, bỏ sót công nợ hoặc giải thích không rõ cho khách\.

Các khoản người dùng nhập ở màn Thanh toán mới là payment intent\. Hệ thống chỉ tạo payment transaction chính thức sau khi checkout thành công\.

User Story bắt đầu khi người dùng mở bước Thanh toán từ một working state hoặc draft hợp lệ và kết thúc khi tổng phải trả, tổng payment intent cùng số còn phải thu được tính chính xác\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Xem tổng phải trả, tổng đã nhập thanh toán và số tiền còn phải thu|Tôi có thể giải thích rõ nghĩa vụ thanh toán cho khách trước khi chốt giao dịch|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị tổng tiền hàng, tổng chiết khấu, tổng thuế, điều chỉnh làm tròn và tổng khách phải trả\.

- FR\-02: Hệ thống phải hiển thị danh sách payment intent hiện tại, tổng payment intent và số còn phải thu\.

- FR\-03: Hệ thống phải tự động tính lại các tổng khi payment intent được thêm, cập nhật hoặc xóa\.

- FR\-04: Hệ thống phải hiển thị payment status dự kiến gồm `unpaid`, `partially_paid` hoặc `paid`\.

- FR\-05: Hệ thống phải hiển thị customer context và cảnh báo khi khách hàng ảnh hưởng đến quyền bán thiếu\.

- FR\-06: Hệ thống phải làm nổi bật số còn phải thu khi tổng payment intent nhỏ hơn tổng phải trả\.

- FR\-07: Hệ thống phải cho phép người dùng quay lại EP\-01 để sửa đơn trước khi xác nhận checkout\.

    

**Business rules**

- BR\-01: Tổng phải trả được lấy từ working state đã có pricing preview và chưa phải commercial snapshot chính thức\.

- BR\-02: `remaining_amount = amount_due - total_payment_intent`\.

- BR\-03: Tổng payment intent không được âm và không được vượt tổng phải trả\.

- BR\-04: Payment status dự kiến chỉ phục vụ checkout preview; authoritative payment status thuộc Sales Settlement sau khi checkout thành công\.

- BR\-05: Mọi thay đổi làm tổng phải trả thay đổi phải làm payment preview được tính lại\.

- BR\-06: Hệ thống không được tự động giảm hoặc phân bổ payment intent để che giấu tình trạng tổng thanh toán vượt nghĩa vụ\.

- BR\-07: Nếu tổng tiền hoặc pricing đang stale, hệ thống phải hiển thị trạng thái cần kiểm tra thay vì coi nghĩa vụ thanh toán là cuối cùng\.

    

**Acceptance criteria**

- AC\-01: Màn Thanh toán hiển thị đầy đủ tổng phải trả, tổng payment intent và số còn phải thu\.

- AC\-02: Các tổng được cập nhật ngay sau khi payment intent thay đổi\.

- AC\-03: Payment status dự kiến phản ánh đúng quan hệ giữa tổng payment intent và tổng phải trả\.

- AC\-04: Số còn phải thu không bao giờ hiển thị âm\.

- AC\-05: Khi tổng phải trả thay đổi, payment preview được tính lại và người dùng được thông báo nếu payment intent không còn hợp lệ\.

- AC\-06: Người dùng có thể quay lại sửa đơn mà chưa tạo SalesOrder hoặc payment transaction\.

- AC\-07: Dữ liệu tiền tệ được hiển thị theo currency và rounding rule của tenant\.

    

**Edge cases**

- EC\-01: Tổng phải trả bằng 0 do promotion hoặc discount hợp lệ; hệ thống cho phép checkout không cần payment intent\.

- EC\-02: Payment intent đang vượt tổng phải trả sau khi giá thay đổi; hệ thống chặn xác nhận và yêu cầu điều chỉnh\.

- EC\-03: Pricing preview hết hiệu lực khi người dùng đang ở màn Thanh toán; hệ thống đánh dấu tổng tiền cần kiểm tra lại\.

- EC\-04: Người dùng đổi khách hàng làm điều kiện bán thiếu thay đổi; hệ thống tính lại khả năng còn phải thu\.

- EC\-05: Rounding rule làm chênh lệch một đơn vị tiền tệ nhỏ; hệ thống dùng tổng phải trả đã làm tròn làm căn cứ thanh toán\.

- EC\-06: Dữ liệu payment intent chưa đồng bộ trên UI sau thao tác nhanh; hệ thống phải dùng trạng thái mới nhất trước khi cho xác nhận\.

- EC\-07: Người dùng mất quyền checkout trong lúc đang xem tổng tiền; backend từ chối xác nhận và yêu cầu tải lại quyền\.

    

**Scenarios**

```Gherkin
Feature: Kiểm tra tổng tiền và nghĩa vụ thanh toán

Scenario: SC-01 — Đơn chưa có payment intent
  Given working state có tổng phải trả là 1.000.000 đồng
  And chưa có payment intent nào
  When người dùng mở bước Thanh toán
  Then hệ thống hiển thị tổng payment intent bằng 0
  And số còn phải thu bằng 1.000.000 đồng
  And payment status dự kiến là unpaid

Scenario: SC-02 — Đơn đã nhập thanh toán một phần
  Given tổng phải trả là 1.000.000 đồng
  And tổng payment intent là 400.000 đồng
  When hệ thống tính payment preview
  Then số còn phải thu bằng 600.000 đồng
  And payment status dự kiến là partially_paid

Scenario: SC-03 — Đơn đã nhập đủ thanh toán
  Given tổng phải trả là 1.000.000 đồng
  And tổng payment intent là 1.000.000 đồng
  When hệ thống tính payment preview
  Then số còn phải thu bằng 0
  And payment status dự kiến là paid

Scenario: SC-04 — Tổng payment intent vượt tổng phải trả
  Given tổng phải trả là 1.000.000 đồng
  And tổng payment intent là 1.100.000 đồng
  When người dùng kiểm tra nghĩa vụ thanh toán
  Then hệ thống hiển thị lỗi tổng thanh toán vượt tổng phải trả
  And không cho xác nhận checkout

Scenario: SC-05 — Giá thay đổi làm payment intent không còn hợp lệ
  Given tổng phải trả trước đó là 1.000.000 đồng
  And tổng payment intent là 1.000.000 đồng
  When pricing preview mới làm tổng phải trả giảm còn 950.000 đồng
  Then hệ thống tính lại payment preview
  And hiển thị tổng payment intent đang vượt nghĩa vụ
  And yêu cầu người dùng điều chỉnh trước khi checkout

Scenario: SC-06 — Quay lại sửa đơn
  Given người dùng đang ở bước Thanh toán
  When người dùng chọn quay lại sửa đơn
  Then hệ thống quay lại working state của EP-01
  And chưa tạo SalesOrder, SalesOrderSettlement hoặc SalesPaymentTransaction
```

**References**

- Domains:

    - Sales Order Lifecycle

    - Sales Settlement

- Data:

    - `SalesOrderWorkingState`

    - `PricingPreview`

    - Payment intent

    - `MonetarySummary`

    - `SettlementSummary`

- Commands / queries / events:

    - `PrecheckSalesOrderCheckout`

    - `FinalizeSalesOrder`

- Permissions:

    - `sales.checkout.create`

- External dependencies:

    - Theme 1 — Tenant, currency, rounding và permission context

    - Theme 4 — Pricing preview và pricing recalculation

        

#### 4\.3\.6\.3 US\-02 — Ghi nhận một hoặc nhiều khoản thanh toán

**Business context**

Khách hàng có thể thanh toán toàn bộ bằng một phương thức hoặc kết hợp nhiều phương thức\. Người bán cần ghi nhận đúng số tiền theo từng phương thức trước khi chốt giao dịch\.

Trong Phase 1, Theme 5 hỗ trợ Tiền mặt và Chuyển khoản thủ công\. Các khoản nhập trước checkout là payment intent; Sales Settlement chỉ tạo `SalesPaymentTransaction` sau khi giao dịch được hoàn tất thành công\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Nhập một hoặc nhiều khoản thanh toán bằng các phương thức được hỗ trợ|Tôi có thể phản ánh đúng cách khách thực tế thanh toán|



**Functional requirements**

- FR\-01: Cho phép người dùng thêm payment intent bằng phương thức Tiền mặt\.

- FR\-02: Cho phép người dùng thêm payment intent bằng phương thức Chuyển khoản thủ công\.

- FR\-03: Cho phép kết hợp nhiều payment intent trong cùng một checkout\.

- FR\-04: Cho phép cập nhật số tiền, phương thức và thông tin tham chiếu của payment intent trước khi xác nhận\.

- FR\-05: Cho phép xóa payment intent trước khi xác nhận\.

- FR\-06: Hệ thống phải kiểm tra số tiền, phương thức và tổng payment intent sau mỗi thay đổi\.

- FR\-07: Khi checkout thành công, hệ thống phải yêu cầu Sales Settlement ghi nhận một `SalesPaymentTransaction` cho mỗi payment intent hợp lệ\.

    

**Business rules**

- BR\-01: Mỗi payment intent phải có số tiền lớn hơn 0 và một phương thức hợp lệ\.

- BR\-02: Tổng payment intent không được vượt tổng phải trả\.

- BR\-03: Payment intent không phải authoritative transaction và không được dùng để xác nhận tiền đã thu trước khi checkout thành công\.

- BR\-04: Một checkout có thể có nhiều payment intent cùng hoặc khác phương thức\.

- BR\-05: Chuyển khoản thủ công không đồng nghĩa đã được đối soát với ngân hàng; nó chỉ phản ánh xác nhận nghiệp vụ của người ghi nhận\.

- BR\-06: Payment method snapshot phải được lưu cùng transaction chính thức để lịch sử không thay đổi khi cấu hình phương thức được cập nhật sau này\.

- BR\-07: Phase 1 không tạo số dư có hoặc customer credit từ payment intent vượt nghĩa vụ\.

    

**Acceptance criteria**

- AC\-01: Người dùng có thể nhập một khoản Tiền mặt hợp lệ\.

- AC\-02: Người dùng có thể nhập một khoản Chuyển khoản thủ công hợp lệ\.

- AC\-03: Người dùng có thể kết hợp nhiều payment intent và tổng tiền được cập nhật chính xác\.

- AC\-04: Payment intent có số tiền không hợp lệ bị từ chối tại trường nhập\.

- AC\-05: Payment intent có thể được cập nhật hoặc xóa trước khi xác nhận checkout\.

- AC\-06: Checkout thành công tạo đúng số payment transaction tương ứng với các payment intent hợp lệ\.

- AC\-07: Checkout thất bại hoặc bị chặn không tạo payment transaction chính thức\.

    

**Edge cases**

- EC\-01: Người dùng nhập số tiền bằng 0 hoặc số âm; hệ thống từ chối\.

- EC\-02: Người dùng thêm nhiều payment intent làm tổng vượt nghĩa vụ; hệ thống chặn khoản gây vượt\.

- EC\-03: Phương thức thanh toán vừa bị vô hiệu hóa; hệ thống yêu cầu chọn lại phương thức hợp lệ\.

- EC\-04: Chuyển khoản thiếu thông tin tham chiếu trong khi tenant policy yêu cầu; hệ thống chặn xác nhận khoản đó\.

- EC\-05: Người dùng thêm hai khoản giống hệt nhau; hệ thống vẫn cho phép nếu đó là hai khoản thu thực tế nhưng phải hiển thị rõ từng khoản\.

- EC\-06: Người dùng sửa tổng tiền đơn sau khi nhập payment intent; hệ thống giữ payment intent để đối chiếu nhưng đánh dấu lỗi nếu tổng mới không còn phù hợp\.

- EC\-07: Một payment intent thất bại khi ghi nhận trong local transaction; toàn bộ checkout phải rollback hoặc chuyển sang uncertain, không commit một phần không xác định\.

    

**Scenarios**

```Gherkin
Feature: Ghi nhận một hoặc nhiều khoản thanh toán

Scenario: SC-01 — Thanh toán toàn bộ bằng tiền mặt
  Given tổng phải trả là 800.000 đồng
  When người dùng thêm payment intent Tiền mặt 800.000 đồng
  Then tổng payment intent bằng 800.000 đồng
  And số còn phải thu bằng 0
  And payment status dự kiến là paid

Scenario: SC-02 — Thanh toán toàn bộ bằng chuyển khoản thủ công
  Given tổng phải trả là 800.000 đồng
  When người dùng thêm payment intent Chuyển khoản 800.000 đồng
  And nhập thông tin tham chiếu hợp lệ
  Then payment intent được chấp nhận
  And số còn phải thu bằng 0

Scenario: SC-03 — Kết hợp nhiều phương thức
  Given tổng phải trả là 1.000.000 đồng
  When người dùng thêm Tiền mặt 400.000 đồng
  And thêm Chuyển khoản 600.000 đồng
  Then tổng payment intent bằng 1.000.000 đồng
  And payment status dự kiến là paid

Scenario: SC-04 — Cập nhật payment intent
  Given đã có payment intent Tiền mặt 300.000 đồng
  When người dùng cập nhật số tiền thành 400.000 đồng
  Then hệ thống lưu payment intent mới
  And tính lại tổng payment intent và số còn phải thu

Scenario: SC-05 — Xóa payment intent
  Given đã có hai payment intent hợp lệ
  When người dùng xóa một payment intent
  Then khoản đó không còn trong checkout request
  And tổng payment intent được tính lại

Scenario: SC-06 — Chặn tổng thanh toán vượt nghĩa vụ
  Given tổng phải trả là 1.000.000 đồng
  And đã có payment intent 800.000 đồng
  When người dùng thêm payment intent 300.000 đồng
  Then hệ thống chặn khoản mới
  And hiển thị phần tối đa còn có thể ghi nhận là 200.000 đồng

Scenario: SC-07 — Checkout bị chặn trước commit
  Given checkout có các payment intent hợp lệ
  And sản phẩm không còn đủ điều kiện bán
  When người dùng xác nhận checkout
  Then checkout bị blocked
  And không tạo SalesPaymentTransaction nào
```

**References**

- Domains:

    - Sales Settlement

    - Sales Order Lifecycle

- Data:

    - Payment intent

    - `SalesOrderSettlement`

    - `SalesPaymentTransaction`

    - `PaymentMethodSnapshot`

    - `PaymentAllocation`

- Commands / queries / events:

    - `FinalizeSalesOrder`

    - `InitializeSalesOrderSettlement`

    - `RecordSalesPayment`

    - `SalesOrderSettlementInitialized`

    - `SalesPaymentRecorded`

- Permissions:

    - `sales.checkout.create`

    - `sales.payment.record`

- External dependencies:

    - Theme 1 — Permission và tenant payment policy

    - Theme 12 — Tích hợp đối soát trong tương lai, ngoài phạm vi Phase 1

        

#### 4\.3\.6\.4 US\-03 — Xử lý đơn hàng còn phải thu

**Business context**

Một số khách hàng được phép thanh toán một phần hoặc chưa thanh toán tại thời điểm mua\. Hệ thống phải xác định rõ phần còn phải thu, kiểm tra điều kiện bán thiếu và bàn giao yêu cầu công nợ sang Theme 6\.

Khách lẻ không định danh không được phát sinh công nợ\. Việc cho phép bán thiếu phụ thuộc customer context, tenant policy và quyền của người thực hiện\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng có quyền|Hoàn tất đơn chưa thanh toán đủ cho khách hàng đủ điều kiện|Tôi có thể ghi nhận giao dịch bán thiếu và theo dõi phần còn phải thu|



**Functional requirements**

- FR\-01: Hệ thống phải xác định số còn phải thu từ tổng phải trả và tổng payment intent\.

- FR\-02: Khi số còn phải thu lớn hơn 0, hệ thống phải kiểm tra khách hàng định danh, trạng thái khách hàng, tenant credit policy và quyền người dùng\.

- FR\-03: Hệ thống phải yêu cầu ngày hẹn thanh toán khi tenant policy quy định\.

- FR\-04: Hệ thống phải hiển thị rõ số tiền sẽ trở thành khoản còn phải thu trước khi xác nhận\.

- FR\-05: Hệ thống phải chặn Khách lẻ checkout khi còn phải thu\.

- FR\-06: Khi checkout thành công và còn phải thu, hệ thống phải tạo durable `ReceivableImpactRequest`\.

- FR\-07: Hệ thống phải hiển thị trạng thái bàn giao công nợ mà không tự tạo hoặc sửa receivable ledger của Theme 6\.

    

**Business rules**

- BR\-01: Chỉ đơn có `customer_partner_id` hợp lệ mới được phát sinh receivable requirement\.

- BR\-02: Khách hàng phải còn hoạt động và đủ điều kiện phát sinh giao dịch cùng công nợ mới\.

- BR\-03: Người dùng phải có quyền bán thiếu hoặc hoàn tất đơn chưa thanh toán theo permission policy hiện hành\.

- BR\-04: Ngày hẹn thanh toán không được trước ngày hoàn tất đơn\.

- BR\-05: `outstanding_amount` được tính từ Sales Order Settlement authoritative sau checkout\.

- BR\-06: Theme 5 sở hữu receivable requirement nhưng Theme 6 sở hữu receivable ledger\.

- BR\-07: Lỗi kỹ thuật khi post công nợ sau khi durable impact đã commit không làm SalesOrder bị coi là chưa hoàn tất\.

    

**Acceptance criteria**

- AC\-01: Khách lẻ không thể hoàn tất đơn khi số còn phải thu lớn hơn 0\.

- AC\-02: Khách hàng đủ điều kiện có thể checkout với payment status `unpaid` hoặc `partially_paid`\.

- AC\-03: Người dùng không có quyền bán thiếu bị chặn và nhận lý do rõ ràng\.

- AC\-04: Ngày hẹn thanh toán bắt buộc được kiểm tra trước checkout\.

- AC\-05: Checkout thành công lưu đúng outstanding amount trong settlement\.

- AC\-06: Checkout có outstanding amount tạo đúng một receivable impact theo idempotency context\.

- AC\-07: Trạng thái công nợ pending hoặc failed được hiển thị riêng với trạng thái đơn hàng\.

    

**Edge cases**

- EC\-01: Khách hàng bị ngừng hoạt động sau khi mở màn Thanh toán; checkout bị chặn\.

- EC\-02: Credit policy thay đổi trong lúc checkout; backend dùng policy mới nhất\.

- EC\-03: Ngày hẹn thanh toán trước ngày hoàn tất; hệ thống từ chối\.

- EC\-04: Khách hàng đủ điều kiện nhưng người dùng không có quyền bán thiếu; hệ thống không cho xác nhận\.

- EC\-05: Số còn phải thu trở về 0 sau khi thêm payment intent; hệ thống không tạo receivable impact\.

- EC\-06: Receivable impact đã commit nhưng Theme 6 chưa phản hồi; order success vẫn được hiển thị cùng trạng thái công nợ pending\.

- EC\-07: Theme 6 từ chối nghiệp vụ vì dữ liệu khách hàng không hợp lệ; hệ thống chuyển trạng thái cần đối soát thay vì tạo lại SalesOrder\.

    

**Scenarios**

```Gherkin
Feature: Xử lý đơn hàng còn phải thu

Scenario: SC-01 — Khách hàng thanh toán một phần
  Given khách hàng định danh đủ điều kiện bán thiếu
  And tổng phải trả là 1.000.000 đồng
  And tổng payment intent là 400.000 đồng
  When người dùng xác nhận checkout
  Then outstanding amount bằng 600.000 đồng
  And authoritative payment status là partially_paid
  And hệ thống tạo ReceivableImpactRequest 600.000 đồng

Scenario: SC-02 — Khách hàng chưa thanh toán
  Given khách hàng định danh đủ điều kiện bán thiếu
  And không có payment intent
  When người dùng xác nhận checkout
  Then outstanding amount bằng toàn bộ tổng phải trả
  And authoritative payment status là unpaid
  And hệ thống tạo ReceivableImpactRequest tương ứng

Scenario: SC-03 — Chặn Khách lẻ bán thiếu
  Given đơn hàng đang sử dụng Khách lẻ
  And số còn phải thu lớn hơn 0
  When người dùng xác nhận checkout
  Then hệ thống chặn checkout
  And yêu cầu thanh toán đủ hoặc chọn khách hàng đủ điều kiện

Scenario: SC-04 — Chặn người dùng không có quyền bán thiếu
  Given khách hàng đủ điều kiện phát sinh công nợ
  And người dùng không có quyền bán thiếu
  When người dùng xác nhận checkout với số còn phải thu lớn hơn 0
  Then hệ thống từ chối
  And không tạo SalesOrder hoặc ReceivableImpactRequest

Scenario: SC-05 — Ngày hẹn thanh toán không hợp lệ
  Given tenant yêu cầu ngày hẹn thanh toán
  And người dùng chọn ngày trước ngày hoàn tất đơn
  When người dùng xác nhận checkout
  Then hệ thống hiển thị validation error
  And không cho tiếp tục

Scenario: SC-06 — Đơn đã thanh toán đủ
  Given tổng payment intent bằng tổng phải trả
  When checkout thành công
  Then outstanding amount bằng 0
  And hệ thống không tạo ReceivableImpactRequest

Scenario: SC-07 — Theme 6 xử lý chậm
  Given checkout đã commit thành công
  And ReceivableImpactRequest đã được lưu
  And Theme 6 chưa xử lý xong
  When người dùng xem kết quả giao dịch
  Then hệ thống hiển thị đơn hàng thành công
  And trạng thái công nợ là pending
```

**References**

- Domains:

    - Sales Settlement

    - Sales Order Lifecycle

    - Theme 6 — Công nợ

- Data:

    - `SalesOrderSettlement`

    - `SettlementSummary`

    - `ReceivableImpactRequest`

    - Customer context

    - Due date

- Commands / queries / events:

    - `PrecheckSalesOrderCheckout`

    - `FinalizeSalesOrder`

    - `InitializeSalesOrderSettlement`

    - `PostSalesReceivable`

    - `SalesReceivableRequired`

- Permissions:

    - `sales.checkout.create`

    - Quyền bán thiếu hoặc hoàn tất đơn chưa thanh toán theo permission policy

- External dependencies:

    - Theme 3 — Customer status và identity

    - Theme 6 — Receivable ledger

    - Theme 1 — Tenant credit policy và permission

        

#### 4\.3\.6\.5 US\-04 — Kiểm tra điều kiện checkout

**Business context**

Dữ liệu đã hợp lệ khi lập đơn có thể thay đổi trước lúc checkout: khách hàng bị khóa, sản phẩm ngừng bán, đơn vị bán không còn hợp lệ, giá thay đổi, tồn kho không còn đủ hoặc quyền người dùng bị thu hồi\.

Người bán cần được biết các blocker và warning trước khi xác nhận\. Precheck giúp hiển thị vấn đề sớm nhưng không thay thế validation authoritative trong `FinalizeSalesOrder`\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Kiểm tra các cảnh báo và điều kiện chặn trước khi hoàn tất đơn|Tôi có thể xử lý vấn đề trước khi tạo giao dịch chính thức|



**Functional requirements**

- FR\-01: Hệ thống phải thực hiện `PrecheckSalesOrderCheckout` trước khi người dùng xác nhận hoàn tất\.

- FR\-02: Precheck phải kiểm tra tenant, store, actor, membership, permission và ca bán nếu áp dụng\.

- FR\-03: Precheck phải kiểm tra customer, product, product unit, quantity và sellability hiện hành\.

- FR\-04: Precheck phải yêu cầu Theme 4 tính lại pricing, promotion, discount và pricing source\.

- FR\-05: Precheck phải kiểm tra payment intent, điều kiện bán thiếu và ngày hẹn thanh toán\.

- FR\-06: Precheck phải kiểm tra inventory availability hoặc reservation theo inventory policy\.

- FR\-07: Precheck phải trả kết quả `ready`, `warning` hoặc `blocked` kèm mã và dữ liệu hướng dẫn xử lý\.

    

**Business rules**

- BR\-01: Precheck không tạo SalesOrder, settlement, payment transaction, impact request hoặc business fact cuối cùng\.

- BR\-02: `FinalizeSalesOrder` luôn phải validate lại authoritative state; precheck thành công không bảo đảm command sau đó sẽ thành công\.

- BR\-03: Blocker phải ngăn checkout cho đến khi nguyên nhân được xử lý\.

- BR\-04: Warning không được âm thầm bỏ qua; người dùng phải nhìn thấy và xác nhận lại khi policy yêu cầu\.

- BR\-05: Pricing result thay đổi làm tổng tiền thay đổi phải được hiển thị để người dùng kiểm tra lại payment intent\.

- BR\-06: Nếu tenant cấm âm kho, thiếu inventory hoặc không lấy được reservation hợp lệ là blocker\.

- BR\-07: Nếu yêu cầu e\-invoice nhưng buyer tax information bắt buộc chưa hợp lệ, checkout phải bị chặn hoặc yêu cầu bỏ yêu cầu e\-invoice theo policy\.

    

**Acceptance criteria**

- AC\-01: Người dùng nhận được danh sách blocker và warning có nội dung hiểu được\.

- AC\-02: Precheck không tạo persisted business transaction\.

- AC\-03: Pricing thay đổi được phản ánh vào tổng tiền và payment preview trước khi xác nhận\.

- AC\-04: Dòng hàng không hợp lệ được chỉ rõ để người dùng quay lại sửa\.

- AC\-05: Inventory blocker được hiển thị theo đúng policy của tenant\.

- AC\-06: Precheck ready cho phép người dùng tiếp tục xác nhận checkout\.

- AC\-07: Precheck blocked không cho gọi xác nhận theo flow thông thường\.

    

**Edge cases**

- EC\-01: Dependency blocking không phản hồi; precheck trả trạng thái chưa thể kiểm tra và cho phép thử lại\.

- EC\-02: Pricing response cũ về sau response mới; hệ thống bỏ qua response stale\.

- EC\-03: Một blocker được xử lý nhưng blocker khác vẫn còn; hệ thống hiển thị trạng thái tổng hợp mới nhất\.

- EC\-04: Tồn kho thay đổi ngay sau precheck; `FinalizeSalesOrder` vẫn phải kiểm tra lại\.

- EC\-05: Permission thay đổi sau precheck; command chính từ chối theo quyền mới nhất\.

- EC\-06: Người dùng quay lại sửa đơn; kết quả precheck cũ bị vô hiệu\.

- EC\-07: Có warning không làm thay đổi tổng tiền; hệ thống cho xác nhận theo tenant policy nhưng vẫn ghi nhận acknowledgement nếu bắt buộc\.

    

**Scenarios**

```Gherkin
Feature: Kiểm tra điều kiện checkout

Scenario: SC-01 — Precheck sẵn sàng
  Given tenant, store, actor và ca bán hợp lệ
  And customer, lines, pricing, payment và inventory đều hợp lệ
  When hệ thống thực hiện PrecheckSalesOrderCheckout
  Then kết quả là ready
  And người dùng có thể tiếp tục xác nhận
  And chưa có SalesOrder được tạo

Scenario: SC-02 — Giá thay đổi trước checkout
  Given pricing preview trong working state đã cũ
  When Theme 4 tính lại giá tại precheck
  Then hệ thống hiển thị giá và tổng tiền mới
  And payment preview được tính lại
  And người dùng phải kiểm tra lại trước khi xác nhận

Scenario: SC-03 — Sản phẩm không còn được bán
  Given một sản phẩm đã bị ngừng bán
  When hệ thống thực hiện precheck
  Then kết quả là blocked
  And blocker chỉ rõ dòng sản phẩm không còn hợp lệ
  And hệ thống hướng người dùng quay lại sửa đơn

Scenario: SC-04 — Không đủ tồn kho khi cấm âm kho
  Given tenant không cho phép âm kho
  And inventory availability nhỏ hơn quantity cần bán
  When hệ thống thực hiện precheck
  Then kết quả là blocked
  And hệ thống không cho xác nhận checkout

Scenario: SC-05 — Thiếu thông tin bán thiếu
  Given số còn phải thu lớn hơn 0
  And tenant yêu cầu ngày hẹn thanh toán
  And ngày hẹn thanh toán chưa được nhập
  When hệ thống thực hiện precheck
  Then kết quả là blocked
  And hệ thống yêu cầu bổ sung ngày hẹn thanh toán

Scenario: SC-06 — Dependency tạm thời không phản hồi
  Given Theme 4 không phản hồi trong thời gian cho phép
  When hệ thống thực hiện precheck
  Then hệ thống không coi kết quả là ready
  And hiển thị trạng thái chưa thể kiểm tra giá
  And cho phép người dùng thử lại

Scenario: SC-07 — Dữ liệu thay đổi sau precheck
  Given precheck trước đó trả ready
  And permission của người dùng bị thu hồi sau đó
  When người dùng xác nhận FinalizeSalesOrder
  Then command bị từ chối theo permission hiện hành
  And không tạo giao dịch chính thức
```

**References**

- Domains:

    - Sales Order Lifecycle

    - Sales Settlement

- Data:

    - `SalesOrderWorkingState`

    - `CheckoutAttempt`

    - `PricingPreview`

    - Blocker codes

    - Warning codes

- Commands / queries / events:

    - `PrecheckSalesOrderCheckout`

    - `FinalizeSalesOrder`

    - `ReserveInventoryForSale` nếu dùng reservation

- Permissions:

    - `sales.checkout.create`

- External dependencies:

    - Theme 1 — Context và permission

    - Theme 2 — Product và Product Unit

    - Theme 3 — Customer

    - Theme 4 — Pricing và promotion

    - Theme 7 — Inventory availability hoặc reservation

    - Theme 8 — Buyer tax/e\-invoice validation khi áp dụng

        

#### 4\.3\.6\.6 US\-05 — Hoàn tất đơn hàng an toàn

**Business context**

Checkout là thời điểm working state trở thành giao dịch chính thức\. Đây là thao tác có rủi ro cao vì một lần xác nhận có thể đồng thời tạo đơn, settlement, payment transactions và các business impact cho công nợ, tồn kho, hóa đơn cùng báo cáo\.

Hệ thống phải chống tạo trùng khi người dùng bấm nhiều lần, client retry hoặc mất kết nối\. Khi chưa xác định command đã commit hay chưa, người dùng phải kiểm tra `CheckoutAttempt` thay vì tạo lại giao dịch\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Xác nhận checkout và nhận lại đúng một kết quả giao dịch|Tôi không tạo trùng đơn hàng hoặc khoản thanh toán khi thao tác bị retry hay gián đoạn|



**Functional requirements**

- FR\-01: Hệ thống phải tạo hoặc nhận diện `CheckoutAttempt` và yêu cầu idempotency key cho `FinalizeSalesOrder`\.

- FR\-02: `FinalizeSalesOrder` phải validate lại toàn bộ authoritative state trước khi commit\.

- FR\-03: Checkout thành công phải tạo đúng một `SalesOrder`, các `SalesOrderLine`, commercial snapshot và mã đơn duy nhất\.

- FR\-04: Checkout thành công phải khởi tạo `SalesOrderSettlement` và ghi nhận các payment transaction ban đầu hợp lệ\.

- FR\-05: Checkout thành công phải tạo các durable impact/outbox record bắt buộc cho Inventory, Receivable, E\-invoice và Reporting theo điều kiện\.

- FR\-06: Nếu checkout bắt nguồn từ draft, hệ thống chỉ chuyển draft sang `converted` sau khi SalesOrder commit thành công\.

- FR\-07: Hệ thống phải hỗ trợ `GetCheckoutAttemptStatus` để khôi phục kết quả khi request timeout hoặc ở trạng thái `uncertain`\.

    

**Business rules**

- BR\-01: Một `CheckoutAttempt` chỉ được tạo tối đa một `SalesOrder` thành công\.

- BR\-02: Cùng idempotency key và cùng payload phải trả lại cùng business result\.

- BR\-03: Cùng idempotency key nhưng payload khác phải trả conflict và không tạo giao dịch mới\.

- BR\-04: Commercial snapshot không được cập nhật ngược khi master data thay đổi sau checkout\.

- BR\-05: Checkout chỉ trả `succeeded` sau khi blocking validation hoàn tất, local transaction commit và idempotency result được lưu\.

- BR\-06: Checkout thất bại trước commit phải rollback local business records; checkout `uncertain` không được tự động submit thành một business request mới\.

- BR\-07: Downstream pending sau khi durable impact đã commit không làm SalesOrder đã thành công bị rollback\.

    

**Acceptance criteria**

- AC\-01: Một business request hợp lệ tạo đúng một SalesOrder chính thức\.

- AC\-02: SalesOrder, SalesOrderLine, settlement và payment transactions ban đầu khớp với checkout request đã được validate\.

- AC\-03: Commercial snapshot lưu đúng customer, product, unit, pricing, discount, promotion, tax và monetary context tại thời điểm bán\.

- AC\-04: Retry cùng idempotency context trả lại đúng SalesOrder đã tạo\.

- AC\-05: Payload khác với idempotency key đã dùng bị từ chối\.

- AC\-06: Checkout uncertain có thể được truy vấn lại mà không tạo giao dịch trùng\.

- AC\-07: Draft nguồn chỉ chuyển sang converted khi checkout thành công\.

    

**Edge cases**

- EC\-01: Người dùng double tap CTA; client khóa CTA và backend idempotency ngăn tạo trùng\.

- EC\-02: Server commit thành công nhưng response bị mất; lần query sau trả SalesOrder đã tạo\.

- EC\-03: Local transaction thất bại giữa quá trình; hệ thống rollback hoặc trả uncertain nếu không xác định được kết quả\.

- EC\-04: Inventory reservation thành công nhưng order commit thất bại; reservation phải được release hoặc hết hạn theo contract\.

- EC\-05: Draft đã được checkout bởi request khác; command hiện tại trả state conflict và SalesOrder hiện có nếu được phép\.

- EC\-06: Payment intent không còn hợp lệ tại command time; checkout bị chặn và không commit một phần\.

- EC\-07: Outbox publishing thất bại sau commit; SalesOrder vẫn thành công và delivery được retry riêng\.

    

**Scenarios**

```Gherkin
Feature: Hoàn tất đơn hàng an toàn

Scenario: SC-01 — Checkout thành công
  Given working state hợp lệ
  And precheck không còn blocker
  And idempotency key chưa được sử dụng
  When người dùng xác nhận FinalizeSalesOrder
  Then hệ thống tạo CheckoutAttempt succeeded
  And tạo đúng một SalesOrder cùng SalesOrderLine
  And khởi tạo SalesOrderSettlement
  And ghi nhận các SalesPaymentTransaction hợp lệ
  And lưu các impact hoặc outbox record bắt buộc

Scenario: SC-02 — Retry cùng payload
  Given một checkout đã succeeded với idempotency key "KEY-01"
  When client gửi lại cùng payload với idempotency key "KEY-01"
  Then hệ thống trả lại cùng SalesOrder
  And không tạo SalesOrder hoặc payment transaction mới

Scenario: SC-03 — Tái sử dụng key với payload khác
  Given idempotency key "KEY-01" đã được dùng
  When client gửi payload khác với cùng idempotency key
  Then hệ thống trả conflict
  And không thay đổi giao dịch đã tạo

Scenario: SC-04 — Timeout sau khi server commit
  Given server đã commit checkout thành công
  And client không nhận được response
  When client gọi GetCheckoutAttemptStatus
  Then hệ thống trả trạng thái succeeded
  And trả reference tới SalesOrder đã tạo

Scenario: SC-05 — Checkout bị blocked tại command time
  Given precheck trước đó đã ready
  And sản phẩm bị ngừng bán trước khi command commit
  When người dùng xác nhận FinalizeSalesOrder
  Then command validate lại và trả blocked
  And không tạo SalesOrder, settlement hoặc payment transaction

Scenario: SC-06 — Checkout uncertain
  Given hệ thống không xác định được local transaction đã commit hay chưa
  When checkout trả trạng thái uncertain
  Then UI hiển thị đang kiểm tra kết quả
  And không khuyến khích người dùng tạo đơn mới
  And hệ thống tiếp tục query bằng checkout attempt hoặc idempotency key

Scenario: SC-07 — Draft nguồn được converted
  Given checkout bắt nguồn từ SalesOrderDraft active
  When checkout commit thành công
  Then draft chuyển sang converted
  And draft không thể được chỉnh sửa hoặc checkout lần nữa
```

**References**

- Domains:

    - Sales Order Lifecycle

    - Sales Settlement

    - Sales Order Inquiry \& Documents

    - Cross\-cutting Foundations

- Data:

    - `CheckoutAttempt`

    - `IdempotencyRecord`

    - `SalesOrder`

    - `SalesOrderLine`

    - `SalesOrderSettlement`

    - `SalesPaymentTransaction`

    - `InventoryImpactRequest`

    - `ReceivableImpactRequest`

    - `EInvoiceImpactRequest`

    - `OutboxMessage`

- Commands / queries / events:

    - `FinalizeSalesOrder`

    - `GetCheckoutAttemptStatus`

    - `InitializeSalesOrderSettlement`

    - `RecordSalesPayment`

    - `SalesOrderFinalized`

    - `SalesOrderDraftConverted`

    - `sales_order_finalized.v1`

- Permissions:

    - `sales.checkout.create`

    - `sales.payment.record`

    - `sales.order.view`

- External dependencies:

    - Theme 1 — Context và permission

    - Theme 2 — Product/Product Unit validation

    - Theme 3 — Customer validation

    - Theme 4 — Pricing recalculation

    - Theme 6 — Receivable

    - Theme 7 — Inventory

    - Theme 8 — E\-invoice

    - Theme 10 — Reporting

        

#### 4\.3\.6\.7 US\-06 — Xem kết quả giao dịch

**Business context**

Sau khi checkout, người bán phải biết rõ giao dịch đã thành công hay chưa, khách đã thanh toán bao nhiêu, còn phải thu bao nhiêu và các tác động liên quan đang ở trạng thái nào\.

Kết quả phải phân biệt business success với downstream delivery\. Công nợ, tồn kho, hóa đơn điện tử hoặc báo cáo có thể vẫn pending sau khi SalesOrder đã được tạo thành công\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Xem kết quả giao dịch và các trạng thái quan trọng sau checkout|Tôi biết giao dịch đã thành công và nội dung nào còn đang được xử lý|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị mã đơn, thời điểm, cửa hàng, người bán và customer context của giao dịch thành công\.

- FR\-02: Hệ thống phải hiển thị tổng phải trả, tổng đã thanh toán, số còn phải thu và authoritative payment status\.

- FR\-03: Hệ thống phải hiển thị ngày hẹn thanh toán nếu đơn còn phải thu và có due date\.

- FR\-04: Hệ thống phải hiển thị trạng thái Inventory, Receivable và E\-invoice theo mức thông tin người dùng được phép xem\.

- FR\-05: Hệ thống phải phân biệt trạng thái `pending`, `accepted`, `rejected`, `failed` hoặc `reconciliation_required` với trạng thái đơn hàng\.

- FR\-06: Hệ thống phải cung cấp các hành động Xem đơn hàng, Xem phiếu bán hàng, Tạo đơn mới và Quay lại danh sách đơn\.

- FR\-07: Nếu checkout đang uncertain, màn kết quả phải chuyển sang trạng thái đang kiểm tra và tự khôi phục khi có kết quả cuối\.

    

**Business rules**

- BR\-01: SalesOrder lifecycle thành công của Phase 1 là `completed`; payment status được hiển thị riêng\.

- BR\-02: Downstream pending hoặc delivery failure không được làm UI hiển thị rằng SalesOrder chưa tồn tại\.

- BR\-03: Dữ liệu tiền trên kết quả phải lấy từ SalesOrder và SalesOrderSettlement đã commit\.

- BR\-04: Integration delivery status không phải business status của order, payment hoặc receivable\.

- BR\-05: Không hiển thị thông tin kỹ thuật nhạy cảm hoặc raw error payload cho người dùng không có quyền\.

- BR\-06: Action Tạo đơn mới phải khởi tạo working state mới, không tái sử dụng checkout request cũ\.

- BR\-07: Khi kết quả được khôi phục từ idempotency hoặc CheckoutAttempt, UI phải hiển thị cùng business result như lần checkout đầu tiên\.

    

**Acceptance criteria**

- AC\-01: Checkout succeeded hiển thị rõ mã đơn và trạng thái `completed`\.

- AC\-02: Payment summary trên màn kết quả khớp SalesOrderSettlement\.

- AC\-03: Số còn phải thu và ngày hẹn thanh toán được hiển thị đúng khi phát sinh công nợ\.

- AC\-04: Downstream pending được hiển thị riêng mà không phủ nhận thành công của đơn\.

- AC\-05: Người dùng có thể mở chi tiết đúng SalesOrder vừa tạo\.

- AC\-06: Người dùng có thể bắt đầu đơn mới mà không làm thay đổi đơn vừa hoàn tất\.

- AC\-07: Checkout uncertain không hiển thị success hoặc failure giả định trước khi có kết quả xác định\.

    

**Edge cases**

- EC\-01: Receipt chưa tạo xong; màn kết quả vẫn hiển thị order success và trạng thái receipt đang chuẩn bị\.

- EC\-02: Receivable impact failed; hệ thống hiển thị cần xử lý hoặc đối soát theo quyền\.

- EC\-03: Inventory impact pending; hệ thống hiển thị pending mà không cho phép người bán tự sửa tồn kho\.

- EC\-04: E\-invoice không được yêu cầu; trạng thái hiển thị `not_required`\.

- EC\-05: Người dùng không có quyền xem integration status chi tiết; UI chỉ hiển thị thông tin tổng quát phù hợp\.

- EC\-06: Kết quả được mở lại sau mất kết nối; dữ liệu phải khớp SalesOrder hiện có\.

- EC\-07: SalesOrder đã được post\-sale xử lý trước khi màn kết quả được mở lại; UI tải trạng thái mới nhất thay vì snapshot UI cũ\.

    

**Scenarios**

```Gherkin
Feature: Xem kết quả giao dịch

Scenario: SC-01 — Đơn thanh toán đủ
  Given checkout đã succeeded
  And authoritative payment status là paid
  When người dùng xem kết quả giao dịch
  Then hệ thống hiển thị mã đơn và lifecycle completed
  And tổng đã thanh toán bằng tổng phải trả
  And số còn phải thu bằng 0

Scenario: SC-02 — Đơn còn phải thu
  Given checkout đã succeeded
  And payment status là partially_paid
  When người dùng xem kết quả
  Then hệ thống hiển thị số đã thanh toán
  And số còn phải thu
  And ngày hẹn thanh toán nếu có

Scenario: SC-03 — Downstream impacts đang pending
  Given SalesOrder đã được tạo thành công
  And Inventory và Receivable đang pending
  When người dùng xem kết quả
  Then hệ thống hiển thị đơn hàng thành công
  And hiển thị từng downstream status là pending
  And không yêu cầu người dùng checkout lại

Scenario: SC-04 — Không yêu cầu hóa đơn điện tử
  Given checkout không có yêu cầu e-invoice
  When người dùng xem integration summary
  Then trạng thái E-invoice là not_required

Scenario: SC-05 — Checkout đang uncertain
  Given CheckoutAttempt đang ở trạng thái uncertain
  When người dùng mở màn kết quả
  Then hệ thống hiển thị đang kiểm tra kết quả
  And không hiển thị mã đơn chưa được xác định
  And tiếp tục query CheckoutAttempt

Scenario: SC-06 — Mở chi tiết đơn
  Given kết quả giao dịch có sales_order_id hợp lệ
  When người dùng chọn "Xem đơn hàng"
  Then hệ thống mở đúng chi tiết SalesOrder trong EP-03

Scenario: SC-07 — Tạo đơn mới
  Given người dùng đang xem kết quả giao dịch thành công
  When người dùng chọn "Tạo đơn mới"
  Then hệ thống khởi tạo SalesOrderWorkingState mới
  And không thay đổi SalesOrder vừa hoàn tất
```

**References**

- Domains:

    - Sales Order Lifecycle

    - Sales Settlement

    - Sales Order Inquiry \& Documents

- Data:

    - `CheckoutResultView`

    - `SalesOrder`

    - `SalesOrderSettlement`

    - `SalesOrderIntegrationStatusView`

    - `CheckoutAttempt`

- Commands / queries / events:

    - `GetCheckoutAttemptStatus`

    - `GetSalesOrder`

    - `GetSalesOrderPaymentSummary`

    - `GetOrderIntegrationStatus`

- Permissions:

    - `sales.order.view`

    - `sales.payment.view`

    - `sales.integration.view_sync_status`

    - `sales.receipt.view`

- External dependencies:

    - Theme 6 — Receivable status

    - Theme 7 — Inventory status

    - Theme 8 — E\-invoice status

    - Theme 10 — Reporting delivery nếu được hiển thị

        

#### 4\.3\.6\.8 US\-07 — Xem, in hoặc chia sẻ phiếu bán hàng

**Business context**

Sau khi giao dịch thành công, người bán thường cần đưa cho khách một phiếu bán hàng thể hiện nội dung giao dịch\. Phiếu phải được sinh từ commercial snapshot của SalesOrder để không thay đổi theo master data hiện hành\.

SalesReceipt là chứng từ nội bộ của VET45, không phải hóa đơn điện tử\. Việc tạo receipt có thể diễn ra sau khi SalesOrder đã commit và không bắt buộc nằm trong checkout transaction\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng|Xem, in hoặc chia sẻ phiếu bán hàng nội bộ sau checkout|Tôi có thể cung cấp chứng từ giao dịch cho khách mà không làm thay đổi đơn hàng|



**Functional requirements**

- FR\-01: Sau checkout thành công, hệ thống phải thực hiện hoặc xếp hàng `GenerateSalesReceipt` từ commercial snapshot của SalesOrder\.

- FR\-02: Phiếu phải hiển thị thông tin cửa hàng, mã đơn, thời điểm bán, khách hàng, dòng hàng, tổng tiền, thanh toán và số còn phải thu theo template hiện hành\.

- FR\-03: Hệ thống phải cho phép người dùng có quyền xem receipt đã tạo\.

- FR\-04: Hệ thống phải cho phép in receipt khi thiết bị và permission hỗ trợ\.

- FR\-05: Hệ thống phải cho phép tải hoặc chia sẻ receipt qua kênh được hỗ trợ\.

- FR\-06: Hệ thống phải ghi `SalesReceiptActivity` cho các hành động in, chia sẻ hoặc archive\.

- FR\-07: Nếu receipt chưa tạo được, hệ thống phải giữ nguyên order success và cung cấp trạng thái chờ hoặc thử lại phù hợp\.

    

**Business rules**

- BR\-01: SalesReceipt phải được sinh từ commercial snapshot, không tính lại từ Product, Partner hoặc Pricing master hiện hành\.

- BR\-02: SalesReceipt không phải e\-invoice và không được trình bày như chứng từ thuế đã phát hành\.

- BR\-03: Receipt version phải tham chiếu một SalesOrder và snapshot version hợp lệ\.

- BR\-04: In, chia sẻ, tải hoặc archive receipt không làm thay đổi SalesOrder lifecycle hoặc payment status\.

- BR\-05: Receipt generation phải idempotent theo SalesOrder và receipt version context\.

- BR\-06: Nếu có receipt version mới, version cũ không được bị ghi đè khi policy yêu cầu lưu lịch sử\.

- BR\-07: Lỗi tạo receipt không rollback SalesOrder đã commit\.

    

**Acceptance criteria**

- AC\-01: SalesOrder thành công có thể sinh một receipt từ đúng commercial snapshot\.

- AC\-02: Nội dung receipt khớp mã đơn, dòng hàng và monetary summary của SalesOrder\.

- AC\-03: Receipt hiển thị rõ đây là phiếu bán hàng nội bộ, không phải hóa đơn điện tử\.

- AC\-04: Người dùng có quyền có thể xem và in receipt trên thiết bị hỗ trợ\.

- AC\-05: Người dùng có quyền có thể chia sẻ hoặc tải receipt qua kênh hỗ trợ\.

- AC\-06: Mỗi thao tác in, chia sẻ hoặc archive được ghi activity phù hợp\.

- AC\-07: Receipt generation thất bại không làm mất hoặc hủy SalesOrder\.

    

**Edge cases**

- EC\-01: Receipt đang được tạo; hệ thống hiển thị trạng thái đang chuẩn bị và cho phép tải lại\.

- EC\-02: Thiết bị không hỗ trợ in; action in bị ẩn hoặc disable nhưng vẫn cho xem receipt\.

- EC\-03: Kênh chia sẻ không khả dụng; hệ thống hiển thị lỗi nhẹ và không thay đổi receipt\.

- EC\-04: Người dùng không có quyền xem receipt; hệ thống không hiển thị nội dung chứng từ\.

- EC\-05: GenerateSalesReceipt được gọi lặp lại với cùng version context; hệ thống trả receipt đã có\.

- EC\-06: Tên sản phẩm hoặc khách hàng thay đổi sau bán; receipt vẫn giữ snapshot gốc\.

- EC\-07: Receipt activity ghi nhận thất bại sau khi file đã được in hoặc chia sẻ; hệ thống tạo retry/audit xử lý riêng mà không thay đổi order\.

    

**Scenarios**

```Gherkin
Feature: Xem, in hoặc chia sẻ phiếu bán hàng

Scenario: SC-01 — Tạo receipt sau checkout
  Given SalesOrder đã được commit thành công
  When hệ thống thực hiện GenerateSalesReceipt
  Then hệ thống tạo SalesReceipt từ commercial snapshot
  And receipt tham chiếu đúng SalesOrder

Scenario: SC-02 — Xem receipt
  Given SalesReceipt đã được tạo
  And người dùng có quyền sales.receipt.view
  When người dùng chọn "Xem phiếu bán hàng"
  Then hệ thống hiển thị nội dung receipt
  And hiển thị rõ đây không phải hóa đơn điện tử

Scenario: SC-03 — In receipt
  Given thiết bị hỗ trợ in
  And người dùng có quyền sales.receipt.print
  When người dùng chọn "In phiếu"
  Then hệ thống gửi nội dung receipt tới chức năng in
  And ghi SalesReceiptPrinted khi thao tác được chấp nhận

Scenario: SC-04 — Chia sẻ receipt
  Given người dùng có quyền sales.receipt.share
  And có kênh chia sẻ khả dụng
  When người dùng chọn kênh chia sẻ
  Then hệ thống chia sẻ receipt
  And ghi SalesReceiptShared với distribution context phù hợp

Scenario: SC-05 — Receipt chưa tạo xong
  Given SalesOrder đã thành công
  And receipt generation đang pending
  When người dùng mở khu vực phiếu bán hàng
  Then hệ thống hiển thị trạng thái đang chuẩn bị
  And không làm thay đổi order success
  And cho phép tải lại hoặc thử lại theo policy

Scenario: SC-06 — Dữ liệu master thay đổi sau bán
  Given tên sản phẩm hiện hành đã thay đổi
  And SalesReceipt được tạo từ SalesOrder trước đó
  When người dùng xem receipt
  Then receipt vẫn hiển thị product snapshot tại thời điểm bán

Scenario: SC-07 — Gọi tạo receipt lặp lại
  Given receipt version hiện hành đã tồn tại
  When GenerateSalesReceipt được gọi lại với cùng idempotency context
  Then hệ thống trả receipt hiện có
  And không tạo receipt version trùng
```

**References**

- Domains:

    - Sales Order Inquiry \& Documents

    - Sales Order Lifecycle

- Data:

    - `SalesReceipt`

    - `SalesReceiptActivity`

    - `ReceiptSnapshot`

    - `ReceiptTemplateReference`

    - `ReceiptContentHash`

    - `DistributionContext`

    - `SalesOrder`

    - `SalesOrderLine`

- Commands / queries / events:

    - `GenerateSalesReceipt`

    - `RecordSalesReceiptPrinted`

    - `RecordSalesReceiptShared`

    - `ArchiveSalesReceipt`

    - `GetSalesReceipt`

    - `SalesReceiptGenerated`

    - `SalesReceiptPrinted`

    - `SalesReceiptShared`

    - `SalesReceiptArchived`

- Permissions:

    - `sales.receipt.generate`

    - `sales.receipt.view`

    - `sales.receipt.print`

    - `sales.receipt.share`

    - `sales.receipt.archive`

- External dependencies:

    - Theme 1 — Store identity, branding và permission

    - Thiết bị in hoặc kênh chia sẻ của client

    - Theme 8 — E\-invoice, chỉ để phân biệt chứng từ; không dùng làm nguồn tạo SalesReceipt

## 4\.4 EP\-03 — Tra cứu \& theo dõi đơn hàng

### 4\.4\.1 Overview

Epic này bao phủ việc tra cứu danh sách đơn hàng chính thức, xem chi tiết giao dịch, theo dõi lịch sử hoạt động, xem phiếu bán hàng nội bộ và kiểm tra trạng thái xử lý liên quan đến đơn hàng\.

EP\-03 chỉ áp dụng cho `SalesOrder` đã được tạo chính thức sau checkout\. Các đối tượng sau không thuộc danh sách đơn hàng chính thức:

- Đơn hàng đang lập trong working state\.

- `SalesOrderDraft` đang active\.

- Draft đã `cancelled` hoặc `expired` nếu người dùng đang xem danh sách đơn nháp riêng\.

- `CheckoutAttempt` chưa tạo thành công `SalesOrder`\.

    

EP\-03 chủ yếu sử dụng các read models:

- `SalesOrderListView`\.

- `SalesOrderDetailView`\.

- `SalesOrderTimelineView`\.

- `SalesOrderPaymentSummaryView`\.

- `SalesOrderReturnSummaryView`\.

- `SalesOrderIntegrationStatusView`\.

    

Các read model không phải source of truth và không được ghi ngược vào dữ liệu nghiệp vụ gốc\. Dữ liệu authoritative tiếp tục thuộc các domain tương ứng:

- Sales Order Lifecycle sở hữu đơn hàng và commercial snapshot\.

- Sales Settlement sở hữu settlement, payment và refund transaction\.

- Post\-sale Operations sở hữu điều chỉnh, hủy đơn và đổi/trả\.

- Theme 6 sở hữu receivable ledger\.

- Theme 7 sở hữu tồn kho và stock movement\.

- Theme 8 sở hữu hóa đơn điện tử\.

- Sales Order Inquiry \& Documents sở hữu `SalesReceipt` và các projection phục vụ tra cứu\.

    

Thông tin đơn hàng phải được hiển thị theo commercial snapshot đã lưu tại thời điểm checkout\. Thay đổi sau này của khách hàng, sản phẩm, đơn vị bán, giá hoặc chính sách khuyến mại không được cập nhật ngược vào nội dung giao dịch lịch sử\.

EP\-03 là khu vực tra cứu và điều hướng nghiệp vụ\. Epic này không cho phép sửa trực tiếp dòng hàng, số lượng, đơn giá, chiết khấu, thanh toán hoặc snapshot của đơn hàng chính thức\.

Khi người dùng cần thực hiện nghiệp vụ sau bán, EP\-03 chuyển đúng ngữ cảnh sang:

- EP\-04 — Điều chỉnh thông tin đơn hàng sau bán\.

- EP\-05 — Hủy đơn hàng sau bán\.

- EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch\.

    

### 4\.4\.2 Business context

Sau khi giao dịch được hoàn tất, nhân viên bán hàng, quản lý cửa hàng và người kiểm soát cần tra cứu lại đơn hàng để trả lời nhanh các câu hỏi:

- Đơn hàng nào đã được tạo?

- Đơn được bán tại cửa hàng nào và do ai thực hiện?

- Khách hàng đã mua những sản phẩm gì?

- Giá, chiết khấu, thuế và tổng tiền tại thời điểm bán là bao nhiêu?

- Khách đã thanh toán bao nhiêu và bằng phương thức nào?

- Đơn còn phải thu hay đã thanh toán đủ?

- Đơn đã phát sinh hoàn tiền hay chưa?

- Đơn có bị điều chỉnh, hủy hoặc đổi/trả không?

- Tác động tồn kho, công nợ và hóa đơn điện tử đã được xử lý đến đâu?

- Phiếu bán hàng đã được tạo, in hoặc chia sẻ chưa?

- Ai đã thực hiện từng hành động và vào thời điểm nào?

    

Thông tin hiển thị phải giúp người dùng phân biệt rõ các state dimension độc lập:

- **Order lifecycle:** Đã hoàn tất hoặc Đã hủy\.

- **Lock status:** Chưa khóa hoặc Đã khóa\.

- **Payment status:** Chưa thanh toán, Thanh toán một phần, Đã thanh toán, Hoàn tiền một phần hoặc Đã hoàn tiền\.

- **Return status:** Chưa đổi/trả, Đã trả một phần hoặc Đã trả toàn bộ\.

- **Adjustment indicator:** Chưa điều chỉnh hoặc Có điều chỉnh\.

- **Business integration status:** Không áp dụng, Chờ xử lý, Đã tiếp nhận, Bị từ chối, Cần đối soát hoặc Đã đối soát\.

- **Delivery status:** Đã tạo, Đang chờ gửi, Đã gửi, Đã xác nhận, Thất bại, Chưa xác định hoặc Dead letter\.

    

Các trạng thái này không được ghép thành một trạng thái đơn hàng duy nhất\. Ví dụ, một đơn có thể đồng thời:

- Có lifecycle là Đã hoàn tất\.

- Có payment status là Thanh toán một phần\.

- Có return status là Đã trả một phần\.

- Có inventory impact là Đã tiếp nhận\.

- Có e\-invoice impact là Chờ xử lý\.

    

Chi tiết đơn hàng phải thể hiện giao dịch gốc và các nghiệp vụ phát sinh sau đó theo quan hệ lịch sử\. Điều chỉnh, hủy, hoàn tiền hoặc đổi/trả không được ghi đè nội dung ban đầu của đơn hàng\.

Lịch sử đơn hàng phải có tính append\-only và đủ khả năng truy vết:

- Hành động đã xảy ra\.

- Người hoặc hệ thống thực hiện\.

- Thời điểm thực hiện\.

- Đối tượng bị tác động\.

- Dữ liệu trước và sau nếu có thay đổi\.

- Lý do nghiệp vụ nếu có\.

- Chứng từ hoặc nghiệp vụ nguồn liên quan\.

- Correlation hoặc causation context khi cần điều tra lỗi\.

    

Một số read models có thể được cập nhật theo eventual consistency\. Vì vậy, trong thời gian ngắn sau một giao dịch hoặc nghiệp vụ sau bán, một số trạng thái tổng hợp có thể chưa phản ánh ngay kết quả authoritative mới nhất\.

Khi projection đang chậm hoặc lỗi đồng bộ, hệ thống phải:

- Hiển thị thời điểm dữ liệu được cập nhật gần nhất nếu cần\.

- Cho phép tải lại dữ liệu\.

- Phân biệt lỗi projection với lỗi của giao dịch gốc\.

- Không sửa dữ liệu authoritative chỉ để làm projection khớp\.

- Cho phép rebuild hoặc retry projection bằng cơ chế hệ thống phù hợp\.

    

Phiếu bán hàng nội bộ phải được tạo từ commercial snapshot của đơn hàng\. Phiếu bán hàng:

- Không tính lại giá từ dữ liệu hiện hành\.

- Không thay đổi khi master data thay đổi\.

- Không phải hóa đơn điện tử\.

- Có thể có nhiều version nếu nghiệp vụ yêu cầu tái tạo chứng từ nhưng vẫn phải giữ lịch sử version cũ\.

- Có thể được in hoặc chia sẻ nhiều lần\.

- Việc in hoặc chia sẻ không làm thay đổi lifecycle của đơn hàng\.

    

### 4\.4\.3 In scope

- Xem danh sách các `SalesOrder` thuộc tenant và phạm vi cửa hàng mà người dùng được phép truy cập\.

- Mặc định sắp xếp đơn hàng mới nhất trước\.

- Hỗ trợ phân trang hoặc tải tiếp đối với danh sách lớn\.

- Hiển thị tối thiểu trên mỗi dòng hoặc card đơn hàng:

    - Mã đơn hàng\.

    - Thời điểm hoàn tất\.

    - Khách hàng hoặc Khách lẻ\.

    - Cửa hàng\.

    - Người bán nếu phù hợp\.

    - Tổng giá trị đơn hàng\.

    - Order lifecycle\.

    - Payment status\.

    - Số tiền còn phải thu nếu có\.

    - Return status hoặc adjustment indicator nếu cần cảnh báo\.

- Tìm kiếm đơn hàng theo:

    - Mã đơn hàng\.

    - Tên khách hàng\.

    - Số điện thoại khách hàng được lưu trong snapshot\.

- Lọc danh sách theo:

    - Ngày hoặc khoảng thời gian\.

    - Cửa hàng\.

    - Người bán\.

    - Khách hàng\.

    - Order lifecycle\.

    - Lock status\.

    - Payment status\.

    - Return status\.

    - Adjustment indicator\.

    - Trạng thái công nợ\.

    - Trạng thái hóa đơn điện tử\.

    - Trạng thái tác động tồn kho\.

    - Khoảng tổng tiền\.

- Cho phép kết hợp nhiều điều kiện lọc\.

- Hiển thị các filter đang áp dụng và cho phép xóa từng filter hoặc đặt lại toàn bộ\.

- Phân biệt:

    - Empty state khi tenant chưa có đơn hàng chính thức\.

    - No\-result state khi không có đơn phù hợp với tìm kiếm hoặc bộ lọc\.

    - Loading state\.

    - Error state\.

    - No\-permission state\.

- Mở chi tiết đơn hàng từ danh sách đơn hàng\.

- Mở chi tiết đơn hàng từ màn kết quả checkout của EP\-02\.

- Mở chi tiết đơn hàng từ hồ sơ khách hàng hoặc lịch sử làm việc của Theme 3\.

- Mở chi tiết đơn hàng từ công nợ, hóa đơn điện tử, tồn kho, báo cáo hoặc nghiệp vụ sau bán thông qua deep link hợp lệ\.

- Kiểm tra tenant, store scope và permission trước khi trả dữ liệu danh sách hoặc chi tiết\.

- Không cho phép người dùng mở đơn hàng thuộc tenant hoặc phạm vi cửa hàng không được cấp quyền\.

- Hiển thị phần tổng quan chi tiết đơn hàng gồm:

    - Mã đơn hàng\.

    - Order lifecycle\.

    - Lock status\.

    - Payment status\.

    - Return status\.

    - Adjustment indicator\.

    - Thời điểm hoàn tất\.

    - Cửa hàng\.

    - Người bán\.

    - Ca bán nếu có\.

    - Khách hàng hoặc Khách lẻ\.

- Hiển thị customer snapshot tại thời điểm bán\.

- Cho phép điều hướng sang hồ sơ khách hàng hiện tại nếu:

    - Đơn có `customer_partner_id`\.

    - Người dùng có quyền xem hồ sơ khách hàng\.

- Phân biệt rõ customer snapshot của giao dịch với hồ sơ khách hàng hiện tại\.

- Hiển thị buyer tax snapshot nếu đơn có thông tin phục vụ hóa đơn điện tử\.

- Hiển thị danh sách `SalesOrderLine` gồm:

    - Tên sản phẩm tại thời điểm bán\.

    - SKU hoặc mã tham chiếu tại thời điểm bán\.

    - Đơn vị bán\.

    - Số lượng\.

    - Đơn giá\.

    - Chiết khấu\.

    - Thuế nếu có\.

    - Thành tiền\.

    - Pricing source ở mức người dùng được phép xem\.

    - Promotion snapshot nếu có\.

- Hiển thị monetary summary gồm:

    - Tổng tiền hàng\.

    - Tổng chiết khấu\.

    - Tổng thuế\.

    - Điều chỉnh làm tròn\.

    - Tổng khách phải trả\.

- Hiển thị `SalesOrderPaymentSummaryView` gồm:

    - Tổng phải thu\.

    - Tổng đã thanh toán\.

    - Tổng đã hoàn tiền\.

    - Số còn phải thu\.

    - Payment status authoritative\.

    - Ngày hẹn thanh toán nếu có\.

- Hiển thị danh sách các `SalesPaymentTransaction` liên quan gồm:

    - Loại transaction\.

    - Số tiền\.

    - Phương thức thanh toán\.

    - Thời điểm ghi nhận\.

    - Người ghi nhận\.

    - Trạng thái transaction\.

    - Thông tin tham chiếu nếu có\.

    - Nguồn phát sinh như checkout, thu thêm, hoàn tiền hoặc đổi/trả\.

- Phân biệt transaction thu tiền, void payment và refund\.

- Hiển thị thông tin công nợ ở mức tóm tắt giao dịch:

    - Có hoặc không phát sinh khoản phải thu\.

    - Số tiền còn phải thu\.

    - Ngày hẹn thanh toán\.

    - Trạng thái receivable impact\.

    - Liên kết sang Theme 6 nếu người dùng có quyền\.

- Không tự tính lại receivable ledger trong EP\-03\.

- Hiển thị `SalesOrderReturnSummaryView` gồm:

    - Đơn chưa phát sinh đổi/trả\.

    - Đã trả một phần\.

    - Đã trả toàn bộ\.

    - Tổng giá trị hàng đã trả\.

    - Tổng giá trị hàng đổi hoặc mua thêm\.

    - Tổng thu thêm\.

    - Tổng hoàn tiền\.

    - Tổng cấn trừ công nợ\.

    - Danh sách phiếu đổi/trả liên quan\.

- Cho phép mở chi tiết phiếu đổi/trả thuộc EP\-06 nếu người dùng có quyền\.

- Hiển thị thông tin điều chỉnh sau bán:

    - Có hoặc không có điều chỉnh\.

    - Nội dung trường đã điều chỉnh\.

    - Giá trị trước và sau\.

    - Người thực hiện\.

    - Thời điểm thực hiện\.

    - Lý do nếu có\.

- Hiển thị thông tin hủy đơn nếu đơn đã bị hủy:

    - Trạng thái Đã hủy\.

    - Lý do hủy\.

    - Người yêu cầu hoặc xác nhận hủy\.

    - Thời điểm hủy\.

    - Các tác động hoàn tiền, công nợ, tồn kho và hóa đơn điện tử liên quan\.

- Tiếp tục hiển thị đầy đủ commercial snapshot của đơn hàng đã hủy\.

- Hiển thị `SalesOrderTimelineView` theo thứ tự thời gian\.

- Timeline bao gồm tối thiểu các sự kiện phù hợp:

    - Đơn hàng được hoàn tất\.

    - Thanh toán được ghi nhận\.

    - Thanh toán bị void\.

    - Hoàn tiền được ghi nhận\.

    - Phiếu bán hàng được tạo\.

    - Phiếu bán hàng được in\.

    - Phiếu bán hàng được chia sẻ\.

    - Thông tin đơn hàng được điều chỉnh\.

    - Yêu cầu hủy đơn được tạo\.

    - Đơn hàng được hủy\.

    - Phiếu đổi/trả được khởi tạo\.

    - Phiếu đổi/trả được xác nhận hoặc hoàn tất\.

    - Tác động công nợ được tiếp nhận hoặc từ chối\.

    - Tác động tồn kho được tiếp nhận hoặc từ chối\.

    - Yêu cầu hóa đơn điện tử được tiếp nhận hoặc lỗi\.

    - Hệ thống yêu cầu reconciliation\.

- Mỗi timeline item hiển thị tối thiểu:

    - Loại hoạt động\.

    - Thời điểm\.

    - Người hoặc hệ thống thực hiện\.

    - Kết quả\.

    - Lý do hoặc mô tả ngắn nếu có\.

    - Liên kết tới chứng từ hoặc nghiệp vụ liên quan nếu được phép\.

- Cho phép mở chi tiết activity để xem before/after diff khi activity có dữ liệu thay đổi\.

- Không cho sửa hoặc xóa timeline activity\.

- Hiển thị `SalesOrderIntegrationStatusView` theo từng integration target:

    - Receivable\.

    - Inventory\.

    - E\-invoice\.

    - Reporting nếu cần hiển thị vận hành\.

- Phân biệt business integration status và delivery status\.

- Hiển thị:

    - Trạng thái hiện tại\.

    - Thời điểm cập nhật gần nhất\.

    - Số lần retry nếu được phép hiển thị\.

    - Failure summary\.

    - Trạng thái cần reconciliation\.

- Che thông tin kỹ thuật hoặc dữ liệu nhạy cảm đối với người dùng không có quyền xem chi tiết lỗi\.

- Cho phép người dùng có quyền thực hiện retry đối với integration command thất bại\.

- Retry phải:

    - Gọi technical command tương ứng\.

    - Sử dụng idempotency\.

    - Không tạo business impact trùng\.

    - Không sửa trực tiếp dữ liệu authoritative của domain ngoài\.

- Khi lỗi đã được xử lý hoặc retry bởi người khác, hệ thống tải lại trạng thái mới nhất và không gửi request trùng\.

- Cho phép mở hóa đơn điện tử liên quan trong Theme 8 nếu:

    - Đã có e\-invoice reference\.

    - Người dùng có quyền xem\.

- Hiển thị đúng trạng thái khi đơn chưa yêu cầu hóa đơn điện tử hoặc chưa có dữ liệu liên quan\.

- Xem `SalesReceipt` hiện hành của đơn hàng\.

- Sinh `SalesReceipt` từ commercial snapshot nếu đơn chưa có persisted receipt và policy cho phép sinh khi cần\.

- Không sinh receipt từ dữ liệu Product, Partner hoặc Pricing hiện hành\.

- Hiển thị nội dung phiếu bán hàng gồm:

    - Thông tin tenant và cửa hàng\.

    - Mã đơn hàng\.

    - Thời điểm bán\.

    - Người bán\.

    - Khách hàng hoặc Khách lẻ\.

    - Các dòng hàng\.

    - Tổng tiền\.

    - Thanh toán\.

    - Số còn phải thu\.

    - Ghi chú nếu có\.

    - Nhãn xác định đây là phiếu bán hàng nội bộ\.

- Cho phép xem các version của phiếu bán hàng nếu có nhiều version\.

- Không làm mất version receipt cũ khi tạo version mới nếu audit policy yêu cầu lưu lịch sử\.

- Cho phép in phiếu bán hàng nếu thiết bị và permission hỗ trợ\.

- Cho phép chia sẻ phiếu bán hàng nếu kênh và permission hỗ trợ\.

- Ghi nhận `SalesReceiptActivity` cho hành động:

    - `printed`\.

    - `shared`\.

    - `archived`\.

- Lưu actor, timestamp, channel và device context khi cần\.

- Không thay đổi lifecycle đơn hàng khi in, chia sẻ hoặc archive receipt\.

- Hiển thị trạng thái phiếu bán hàng:

    - Chưa tạo\.

    - Đã tạo\.

    - Không tạo được\.

    - Đã archive nếu có\.

- Phân biệt rõ phiếu bán hàng nội bộ với hóa đơn điện tử\.

- Hiển thị các action sau bán phù hợp với permission và trạng thái hiện tại:

    - Điều chỉnh thông tin đơn hàng\.

    - Hủy đơn hàng\.

    - Đổi/trả hàng\.

- Thực hiện precheck hoặc kiểm tra eligibility trước khi điều hướng sang flow sau bán nếu cần\.

- Không hiển thị action mà người dùng không có quyền hoặc trạng thái đơn không cho phép\.

- Tải lại chi tiết đơn hàng sau khi người dùng quay về từ EP\-04, EP\-05 hoặc EP\-06\.

- Hiển thị projection mới nhất sau khi nghiệp vụ sau bán hoàn tất\.

- Hiển thị trạng thái dữ liệu đang cập nhật nếu projection chưa bắt kịp authoritative result\.

- Ghi nhận audit hoặc analytics event khi người dùng:

    - Tra cứu danh sách đơn\.

    - Mở chi tiết đơn\.

    - Xem timeline\.

    - Xem phiếu bán hàng\.

    - Kiểm tra trạng thái integration\.

    - Thực hiện retry nếu đây là hành động cần audit\.

### 4\.4\.4 Out of scope

- Tạo đơn hàng đang lập\.

- Thêm, sửa hoặc xóa dòng hàng trước checkout\.

- Lưu, cập nhật, khôi phục, hủy hoặc hết hạn đơn nháp\.

- Thực hiện checkout\.

- Tạo `SalesOrder` chính thức\.

- Validate lại pricing để tạo giao dịch mới\.

- Ghi nhận khoản thanh toán mới từ màn chi tiết đơn hàng\.

- Chỉnh sửa trực tiếp payment transaction đã ghi nhận\.

- Void payment như một thao tác độc lập nếu chưa được định nghĩa trong nghiệp vụ phù hợp\.

- Ghi nhận thu công nợ sau bán\.

- Phân bổ một khoản thu cho một hoặc nhiều khoản công nợ\.

- Quản lý receivable ledger chi tiết\.

- Trực tiếp cập nhật trạng thái công nợ authoritative\.

- Quản lý tồn kho, stock reservation, stock movement hoặc giá vốn\.

- Trực tiếp sửa hoặc reverse dữ liệu tồn kho\.

- Phát hành hoặc ký số hóa đơn điện tử\.

- Điều chỉnh, thay thế hoặc hủy hóa đơn điện tử\.

- Xử lý logic nghiệp vụ bên trong Theme 8\.

- Quản lý master data của khách hàng\.

- Quản lý master data của sản phẩm, SKU, barcode hoặc đơn vị tính\.

- Quản lý chính sách giá, giá riêng, nhớ giá hoặc chương trình khuyến mại\.

- Tính lại đơn hàng theo giá, thuế hoặc promotion hiện hành\.

- Sửa trực tiếp commercial snapshot\.

- Sửa trực tiếp dòng hàng, số lượng, đơn giá, chiết khấu hoặc tổng tiền của đơn hàng chính thức\.

- Xóa cứng đơn hàng chính thức\.

- Xóa hoặc chỉnh sửa timeline activity\.

- Trực tiếp chỉnh sửa read model để làm khớp dữ liệu\.

- Thực hiện nghiệp vụ điều chỉnh thông tin đơn hàng; thuộc EP\-04\.

- Thực hiện nghiệp vụ hủy đơn hàng; thuộc EP\-05\.

- Thực hiện nghiệp vụ đổi/trả và quyết toán chênh lệch; thuộc EP\-06\.

- Thiết lập template phiếu bán hàng nâng cao theo tenant\.

- Thiết kế hoặc cấu hình máy in và thiết bị ngoại vi\.

- Quản lý kênh gửi tin nhắn, email hoặc dịch vụ chia sẻ bên ngoài\.

- Báo cáo doanh thu, lợi nhuận hoặc dashboard quản trị tổng hợp\.

- Export dữ liệu hàng loạt hoặc báo cáo chuyên sâu nếu chưa được xác định trong Theme 10\.

- Reconciliation nghiệp vụ chi tiết của Inventory, Receivable hoặc E\-invoice\.

### 4\.4\.5 Entry points

- Người dùng mở tab hoặc khu vực **Đơn hàng** từ điều hướng chính\.

- Người dùng chọn **Xem đơn hàng** từ màn kết quả giao dịch của EP\-02\.

- Người dùng chọn một đơn hàng trong danh sách đơn hàng gần đây trên Home hoặc dashboard vận hành\.

- Người dùng mở một đơn hàng từ lịch sử làm việc của khách hàng trong Theme 3\.

- Người dùng mở đơn hàng nguồn từ khoản công nợ hoặc lịch sử công nợ trong Theme 6\.

- Người dùng mở đơn hàng nguồn từ stock movement hoặc lịch sử tồn kho trong Theme 7 nếu có deep link\.

- Người dùng mở đơn hàng nguồn từ hóa đơn điện tử trong Theme 8\.

- Người dùng mở đơn hàng từ báo cáo hoặc dashboard của Theme 10\.

- Người dùng quay lại chi tiết đơn hàng sau khi hoàn thành hoặc hủy flow trong EP\-04\.

- Người dùng quay lại chi tiết đơn hàng sau khi hoàn thành hoặc hủy flow trong EP\-05\.

- Người dùng quay lại chi tiết đơn hàng sau khi hoàn thành hoặc hủy flow trong EP\-06\.

- Người dùng mở đơn hàng từ phiếu bán hàng nội bộ\.

- Người dùng mở đơn hàng từ notification, integration alert hoặc reconciliation task\.

- Người dùng mở deep link chứa `sales_order_id`\.

Trước khi tải danh sách hoặc chi tiết, hệ thống phải xác định được:

- Tenant hiện tại\.

- Người dùng và membership đang hoạt động\.

- Permission xem danh sách hoặc chi tiết đơn hàng\.

- Store scope mà người dùng được phép truy cập\.

- `sales_order_id` thuộc tenant hiện tại đối với truy vấn chi tiết\.

- Quyền xem payment, công nợ, lỗi integration hoặc activity nhạy cảm đối với từng section\.

Khi vào từ deep link nhưng người dùng không có quyền:

- Không hiển thị dữ liệu đơn hàng\.

- Hiển thị trạng thái Không có quyền phù hợp\.

- Không tiết lộ sự tồn tại hoặc nội dung của đơn hàng ngoài phạm vi được phép\.

Khi không tìm thấy đơn hàng:

- Hiển thị trạng thái Không tìm thấy đơn hàng\.

- Không tự động chuyển sang một đơn khác\.

- Cho phép quay lại màn trước hoặc danh sách đơn hàng\.

EP\-03 kết thúc hoặc chuyển flow khi:

- Người dùng quay lại màn trước hoặc rời khỏi khu vực Đơn hàng\.

- Người dùng chuyển sang EP\-04 để điều chỉnh thông tin được phép\.

- Người dùng chuyển sang EP\-05 để yêu cầu hủy đơn\.

- Người dùng chuyển sang EP\-06 để lập phiếu đổi/trả\.

- Người dùng mở Theme 3 để xem hồ sơ khách hàng hiện tại\.

- Người dùng mở Theme 6 để xem công nợ chi tiết\.

- Người dùng mở Theme 7 để xem tác động tồn kho\.

- Người dùng mở Theme 8 để xem hóa đơn điện tử\.

- Người dùng xem, in hoặc chia sẻ phiếu bán hàng rồi quay lại chi tiết đơn hàng\.

### 4\.4\.6 User stories

#### 4\.4\.6\.1 User story map

|User story|As user|I want to|So that|Notes|
|---|---|---|---|---|
|US\-01 — Tra cứu danh sách đơn hàng|Nhân viên bán hàng, Quản lý cửa hàng hoặc Kế toán|Tìm kiếm, lọc và xem danh sách các đơn hàng trong phạm vi được phép|Tôi có thể nhanh chóng xác định giao dịch cần kiểm tra|Chỉ bao gồm SalesOrder chính thức; không gồm working state, draft hoặc CheckoutAttempt chưa tạo đơn|
|US\-02 — Xem chi tiết giao dịch gốc|Người dùng có quyền xem đơn hàng|Xem commercial snapshot, dòng hàng, giá trị và ngữ cảnh bán của một đơn|Tôi có thể biết chính xác nội dung giao dịch tại thời điểm checkout|Không render lại giao dịch cũ bằng master data hiện hành|
|US\-03 — Kiểm tra thanh toán và công nợ của đơn|Nhân viên bán hàng, Quản lý cửa hàng hoặc Kế toán|Xem payment transactions, payment status, tổng đã thu, tổng đã hoàn và số còn phải thu|Tôi có thể đối chiếu nghĩa vụ tài chính của giao dịch|Receivable ledger chi tiết thuộc Theme 6|
|US\-04 — Theo dõi timeline và lịch sử sau bán|Quản lý cửa hàng, Kế toán hoặc Người kiểm soát|Xem các hoạt động, điều chỉnh, hủy và đổi/trả theo trình tự thời gian|Tôi có thể truy vết ai đã thực hiện hành động gì và kết quả ra sao|Timeline append\-only; có thể hiển thị before/after diff|
|US\-05 — Xem lại phiếu bán hàng|Người dùng có quyền|Xem, in lại, chia sẻ lại hoặc kiểm tra các version của phiếu bán hàng|Tôi có thể hỗ trợ khách và đối chiếu chứng từ sau thời điểm bán|SalesReceipt là chứng từ nội bộ, không phải hóa đơn điện tử|
|US\-06 — Theo dõi trạng thái xử lý liên quan|Người dùng có quyền vận hành hoặc kiểm soát|Xem trạng thái Receivable, Inventory, E\-invoice và delivery của từng integration|Tôi có thể biết nội dung nào đã hoàn tất, thất bại hoặc cần đối soát|Retry chỉ gọi technical command; EP\-03 không sửa downstream data|
|US\-07 — Khởi tạo thao tác sau bán|Người dùng có quyền|Xem và mở các hành động Điều chỉnh, Hủy hoặc Đổi/trả phù hợp với trạng thái đơn|Tôi có thể bắt đầu đúng nghiệp vụ mà không thực hiện hành động không hợp lệ|Eligibility phải được kiểm tra lại trong Epic đích|



#### 4\.4\.6\.2 US\-01 — Tra cứu danh sách đơn hàng

**Business context**

Sau khi giao dịch được hoàn tất, nhân viên bán hàng, quản lý cửa hàng và kế toán cần tìm lại đơn để hỗ trợ khách, đối chiếu thanh toán hoặc bắt đầu nghiệp vụ sau bán\. Danh sách phải giúp người dùng xác định nhanh đơn hàng dựa trên mã đơn, khách hàng, thời gian, cửa hàng và các trạng thái chính\.

Danh sách chỉ bao gồm `SalesOrder` chính thức đã được tạo thành công\. Working state, `SalesOrderDraft` và `CheckoutAttempt` chưa tạo đơn không xuất hiện trong danh sách này\.

User Story bắt đầu khi người dùng mở khu vực Đơn hàng và kết thúc khi người dùng xác định được đơn cần xem hoặc nhận được trạng thái empty, no\-result, error hay no\-permission phù hợp\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng, Quản lý cửa hàng hoặc Kế toán|Tìm kiếm, lọc và xem danh sách đơn hàng trong phạm vi được phép|Tôi có thể nhanh chóng xác định giao dịch cần kiểm tra|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị danh sách SalesOrder thuộc tenant và store scope mà người dùng được phép truy cập\.

- FR\-02: Danh sách mặc định phải sắp xếp đơn mới nhất trước và hỗ trợ phân trang hoặc tải tiếp\.

- FR\-03: Mỗi item phải hiển thị tối thiểu mã đơn, thời điểm hoàn tất, khách hàng hoặc Khách lẻ, cửa hàng, tổng giá trị, order lifecycle và payment status\.

- FR\-04: Hệ thống phải hỗ trợ tìm kiếm theo mã đơn, tên khách hàng hoặc số điện thoại được lưu trong customer snapshot\.

- FR\-05: Hệ thống phải hỗ trợ lọc theo thời gian, cửa hàng, người bán, khách hàng, order lifecycle, lock status, payment status, return status, adjustment indicator và trạng thái xử lý liên quan\.

- FR\-06: Hệ thống phải cho phép kết hợp nhiều filter, hiển thị filter đang áp dụng, xóa từng filter hoặc đặt lại toàn bộ\.

- FR\-07: Hệ thống phải phân biệt rõ default, loading, empty, no\-result, error và no\-permission state\.

    

**Business rules**

- BR\-01: Danh sách chỉ trả SalesOrder chính thức; không trả working state, SalesOrderDraft hoặc CheckoutAttempt chưa tạo SalesOrder\.

- BR\-02: Mọi query phải giới hạn theo tenant, membership, permission và store scope hiện hành\.

- BR\-03: Kết quả tìm theo khách hàng phải dựa trên customer snapshot của giao dịch, không phụ thuộc tên hoặc số điện thoại hiện tại của Partner\.

- BR\-04: Order lifecycle, payment status, return status và adjustment indicator là các chiều trạng thái độc lập\.

- BR\-05: Read model phục vụ danh sách không phải source of truth và không được cập nhật ngược vào aggregate nghiệp vụ\.

- BR\-06: Khi projection chưa bắt kịp authoritative result, hệ thống phải cho phép tải lại và không được tạo hoặc sửa giao dịch để làm danh sách khớp\.

- BR\-07: Người dùng không được suy đoán hoặc nhìn thấy sự tồn tại của đơn hàng ngoài tenant hoặc store scope được cấp quyền\.

    

**Acceptance criteria**

- AC\-01: Người dùng chỉ nhìn thấy đơn hàng trong tenant và store scope được phép\.

- AC\-02: Danh sách mặc định hiển thị đơn mới nhất trước và tải tiếp đúng thứ tự\.

- AC\-03: Tìm kiếm theo mã đơn, customer snapshot name hoặc snapshot phone trả đúng kết quả\.

- AC\-04: Bộ lọc kết hợp trả đúng tập đơn hàng và có thể được xóa từng điều kiện\.

- AC\-05: Empty state và no\-result state được phân biệt rõ\.

- AC\-06: Người dùng không có quyền nhận no\-permission state và không nhận dữ liệu đơn hàng\.

- AC\-07: Chọn một item mở đúng chi tiết SalesOrder tương ứng\.

    

**Edge cases**

- EC\-01: Tenant chưa có SalesOrder chính thức; hệ thống hiển thị empty state\.

- EC\-02: Có đơn hàng nhưng không có kết quả phù hợp với từ khóa hoặc bộ lọc; hệ thống hiển thị no\-result state\.

- EC\-03: Người dùng chọn khoảng thời gian không hợp lệ; hệ thống không gửi query và yêu cầu sửa điều kiện\.

- EC\-04: Store scope thay đổi trong lúc đang xem danh sách; hệ thống tải lại theo phạm vi mới\.

- EC\-05: Projection vừa cập nhật làm một item thay đổi trạng thái hoặc thứ tự; hệ thống hợp nhất kết quả mà không tạo item trùng\.

- EC\-06: Người dùng nhập số điện thoại theo định dạng khác dữ liệu snapshot; hệ thống chuẩn hóa tìm kiếm theo quy tắc được hỗ trợ\.

- EC\-07: Query thất bại khi đang tải trang tiếp theo; hệ thống giữ danh sách đã tải và cho phép thử lại phần bị lỗi\.

    

**Scenarios**

```Gherkin
Feature: Tra cứu danh sách đơn hàng

Scenario: SC-01 — Mở danh sách đơn hàng
  Given người dùng có quyền sales.order.view
  And người dùng có store scope hợp lệ
  When người dùng mở khu vực Đơn hàng
  Then hệ thống thực hiện ListSalesOrders
  And hiển thị các SalesOrder mới nhất trước
  And không hiển thị working state hoặc SalesOrderDraft

Scenario: SC-02 — Tìm theo mã đơn
  Given tồn tại SalesOrder có mã "SO-2026-00125" trong phạm vi được phép
  When người dùng tìm "SO-2026-00125"
  Then hệ thống trả đúng SalesOrder
  And người dùng có thể mở chi tiết đơn

Scenario: SC-03 — Tìm theo customer snapshot
  Given một SalesOrder lưu customer snapshot name là "Đại lý An Bình"
  And hồ sơ Partner hiện tại đã đổi tên
  When người dùng tìm "Đại lý An Bình"
  Then hệ thống vẫn trả SalesOrder theo snapshot tại thời điểm bán

Scenario: SC-04 — Lọc theo nhiều điều kiện
  Given danh sách có đơn từ nhiều cửa hàng và nhiều payment status
  When người dùng lọc cửa hàng "Cơ sở 1"
  And payment status là partially_paid
  Then hệ thống chỉ hiển thị các đơn thỏa đồng thời hai điều kiện
  And hiển thị rõ hai filter đang áp dụng

Scenario: SC-05 — Empty state
  Given tenant chưa có SalesOrder chính thức
  When người dùng mở danh sách
  Then hệ thống hiển thị empty state
  And không hiển thị no-result state

Scenario: SC-06 — No-result state
  Given tenant có SalesOrder chính thức
  When người dùng áp dụng bộ lọc không khớp đơn nào
  Then hệ thống hiển thị no-result state
  And cho phép xóa filter hoặc đặt lại toàn bộ

Scenario: SC-07 — Không có quyền
  Given người dùng không có quyền sales.order.view
  When người dùng mở khu vực Đơn hàng
  Then hệ thống hiển thị no-permission state
  And không trả dữ liệu hoặc tổng số đơn hàng
```

**References**

- Domains:

    - Sales Order Inquiry \& Documents

    - Sales Order Lifecycle

- Data:

    - `SalesOrderListView`

    - `SalesOrder`

    - Customer snapshot

    - Order lifecycle

    - Payment status

    - Return status

    - Adjustment indicator

- Commands / queries / events:

    - `ListSalesOrders`

    - `SearchSalesOrders`

    - Product analytics event khi xem hoặc tìm kiếm danh sách

- Permissions:

    - `sales.order.view`

- External dependencies:

    - Theme 1 — Tenant, membership, permission và store scope

    - Theme 3 — Deep link từ lịch sử khách hàng

    - Theme 10 — Deep link từ báo cáo hoặc dashboard

        

#### 4\.4\.6\.3 US\-02 — Xem chi tiết giao dịch gốc

**Business context**

Người dùng cần xem lại chính xác nội dung giao dịch tại thời điểm checkout, kể cả khi tên khách hàng, tên sản phẩm, đơn vị bán, giá hoặc chính sách hiện hành đã thay đổi\.

Chi tiết đơn phải lấy từ commercial snapshot của SalesOrder và SalesOrderLine\. Dữ liệu hiện tại của Partner hoặc Product chỉ được dùng cho điều hướng bổ sung, không được dùng để viết lại giao dịch lịch sử\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền xem đơn hàng|Xem commercial snapshot, dòng hàng, giá trị và ngữ cảnh bán của một đơn|Tôi có thể biết chính xác nội dung giao dịch tại thời điểm checkout|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị mã đơn, order lifecycle, lock status, payment status, return status, adjustment indicator, thời điểm hoàn tất, cửa hàng, người bán và ca bán nếu có\.

- FR\-02: Hệ thống phải hiển thị customer snapshot hoặc nhãn Khách lẻ tại thời điểm bán\.

- FR\-03: Nếu đơn có `customer_partner_id` và người dùng có quyền, hệ thống phải cho phép mở hồ sơ khách hàng hiện tại nhưng phân biệt rõ với snapshot giao dịch\.

- FR\-04: Hệ thống phải hiển thị SalesOrderLine gồm product snapshot, SKU hoặc mã tham chiếu, đơn vị bán, số lượng, đơn giá, chiết khấu, thuế, thành tiền, pricing source và promotion snapshot nếu có\.

- FR\-05: Hệ thống phải hiển thị monetary summary gồm tổng tiền hàng, tổng chiết khấu, tổng thuế, điều chỉnh làm tròn và tổng khách phải trả\.

- FR\-06: Hệ thống phải hiển thị buyer tax snapshot khi đơn có dữ liệu phục vụ hóa đơn điện tử\.

- FR\-07: Hệ thống phải tải lại projection mới nhất khi người dùng quay về từ nghiệp vụ sau bán hoặc khi dữ liệu đang được cập nhật\.

    

**Business rules**

- BR\-01: Commercial snapshot là dữ liệu lịch sử bất biến sau checkout, trừ metadata được điều chỉnh qua nghiệp vụ riêng và được hiển thị với lịch sử\.

- BR\-02: Tên, mã, đơn vị, giá, promotion và customer information phải lấy từ snapshot của giao dịch\.

- BR\-03: Thay đổi Product, Partner hoặc Pricing master sau bán không được cập nhật ngược vào SalesOrder hoặc SalesOrderLine\.

- BR\-04: Chi tiết read model không phải source of truth và không cho phép sửa trực tiếp dữ liệu authoritative\.

- BR\-05: Đơn đã hủy vẫn phải hiển thị đầy đủ commercial snapshot gốc\.

- BR\-06: Customer profile hiện tại và customer snapshot phải được gắn nhãn khác nhau để tránh hiểu nhầm\.

- BR\-07: Deep link chỉ được mở khi sales\_order\_id thuộc tenant và store scope được phép\.

    

**Acceptance criteria**

- AC\-01: Người dùng có quyền mở được đúng SalesOrder từ danh sách, kết quả checkout hoặc deep link hợp lệ\.

- AC\-02: Dòng hàng và monetary summary khớp commercial snapshot đã commit\.

- AC\-03: Thay đổi master data hiện hành không làm nội dung giao dịch cũ thay đổi\.

- AC\-04: Đơn đã hủy vẫn hiển thị nội dung giao dịch gốc và trạng thái đã hủy\.

- AC\-05: Customer snapshot được phân biệt rõ với hồ sơ khách hàng hiện tại\.

- AC\-06: Người dùng không có quyền xem hồ sơ khách hàng vẫn xem được snapshot của đơn theo quyền sales order\.

- AC\-07: Khi projection đang cập nhật, hệ thống hiển thị trạng thái phù hợp và cho phép tải lại\.

    

**Edge cases**

- EC\-01: sales\_order\_id không tồn tại; hệ thống hiển thị not\-found state và không chuyển sang đơn khác\.

- EC\-02: Đơn tồn tại nhưng ngoài store scope; hệ thống trả no\-permission mà không tiết lộ nội dung\.

- EC\-03: Partner hiện tại đã deleted hoặc inactive; snapshot vẫn hiển thị, nhưng điều hướng sang hồ sơ hiện tại tuân theo Theme 3\.

- EC\-04: Product hiện tại đã đổi tên hoặc ngừng bán; dòng hàng vẫn hiển thị product snapshot gốc\.

- EC\-05: Một số optional snapshot không có dữ liệu; hệ thống hiển thị placeholder phù hợp mà không làm sai nghĩa giao dịch\.

- EC\-06: Projection detail bị chậm sau post\-sale action; hệ thống hiển thị thời điểm cập nhật gần nhất và cho phép tải lại\.

- EC\-07: Người dùng mở cùng đơn từ nhiều entry point; tất cả entry point phải trả cùng authoritative identity và snapshot\.

    

**Scenarios**

```Gherkin
Feature: Xem chi tiết giao dịch gốc

Scenario: SC-01 — Mở chi tiết từ danh sách
  Given người dùng có quyền sales.order.view
  And SalesOrder thuộc store scope được phép
  When người dùng chọn đơn trong danh sách
  Then hệ thống thực hiện GetSalesOrderDetail
  And hiển thị đúng mã đơn, trạng thái và commercial snapshot

Scenario: SC-02 — Product master đã thay đổi
  Given tên sản phẩm hiện tại khác product snapshot tại thời điểm bán
  When người dùng xem dòng hàng
  Then hệ thống hiển thị tên sản phẩm trong snapshot
  And không thay thế bằng tên hiện tại

Scenario: SC-03 — Customer profile đã thay đổi
  Given khách hàng đã thay đổi tên sau giao dịch
  When người dùng xem chi tiết đơn
  Then hệ thống hiển thị customer snapshot tại thời điểm bán
  And có thể cung cấp liên kết riêng tới hồ sơ hiện tại nếu người dùng có quyền

Scenario: SC-04 — Xem đơn đã hủy
  Given SalesOrder lifecycle là cancelled
  When người dùng mở chi tiết
  Then hệ thống hiển thị trạng thái Đã hủy
  And vẫn hiển thị đầy đủ dòng hàng và monetary summary của giao dịch gốc

Scenario: SC-05 — Deep link ngoài phạm vi
  Given deep link chứa sales_order_id thuộc cửa hàng ngoài store scope
  When người dùng mở deep link
  Then hệ thống hiển thị no-permission state
  And không tiết lộ customer, total hoặc trạng thái đơn

Scenario: SC-06 — Không tìm thấy đơn
  Given sales_order_id không tồn tại trong tenant hiện tại
  When người dùng mở chi tiết
  Then hệ thống hiển thị not-found state
  And cho phép quay lại màn trước hoặc danh sách đơn

Scenario: SC-07 — Projection đang cập nhật
  Given một nghiệp vụ sau bán vừa hoàn tất
  And SalesOrderDetailView chưa phản ánh kết quả mới
  When người dùng quay lại chi tiết đơn
  Then hệ thống hiển thị trạng thái dữ liệu đang cập nhật
  And cho phép tải lại
  And không sửa authoritative data để ép projection khớp
```

**References**

- Domains:

    - Sales Order Inquiry \& Documents

    - Sales Order Lifecycle

- Data:

    - `SalesOrderDetailView`

    - `SalesOrder`

    - `SalesOrderLine`

    - Customer snapshot

    - Buyer tax snapshot

    - Product snapshot

    - Pricing snapshot

    - Promotion snapshot

    - Monetary summary

- Commands / queries / events:

    - `GetSalesOrderDetail`

    - `GetSalesOrder`

    - Product analytics event khi mở chi tiết

- Permissions:

    - `sales.order.view`

    - Quyền xem hồ sơ khách hàng của Theme 3

- External dependencies:

    - Theme 1 — Tenant và store scope

    - Theme 3 — Hồ sơ khách hàng hiện tại

    - Theme 8 — Buyer tax và e\-invoice reference khi có

        

#### 4\.4\.6\.4 US\-03 — Kiểm tra thanh toán và công nợ của đơn

**Business context**

Sau bán, người dùng cần biết khách đã thanh toán bao nhiêu, thanh toán bằng phương thức nào, có khoản hoàn tiền hay void nào và số tiền còn phải thu là bao nhiêu\.

Sales Settlement là source of truth cho settlement, payment và refund transaction\. Theme 6 là source of truth cho receivable ledger\. EP\-03 chỉ cung cấp payment summary và liên kết ngữ cảnh, không ghi nhận khoản thu mới hoặc chỉnh sửa giao dịch tài chính\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Nhân viên bán hàng, Quản lý cửa hàng hoặc Kế toán|Xem payment transactions, payment status, tổng đã thu, tổng đã hoàn và số còn phải thu|Tôi có thể đối chiếu nghĩa vụ tài chính của giao dịch|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị tổng phải thu, tổng đã thanh toán, tổng đã hoàn tiền, số còn phải thu và payment status authoritative\.

- FR\-02: Hệ thống phải hiển thị ngày hẹn thanh toán khi có\.

- FR\-03: Hệ thống phải hiển thị danh sách SalesPaymentTransaction gồm loại transaction, số tiền, phương thức, thời điểm, người ghi nhận, trạng thái, tham chiếu và nguồn phát sinh\.

- FR\-04: Hệ thống phải phân biệt collection, void payment và refund\.

- FR\-05: Hệ thống phải hiển thị receivable impact status và liên kết sang Theme 6 khi người dùng có quyền\.

- FR\-06: Hệ thống phải cập nhật payment summary khi có payment, void, refund hoặc receivable collection mới\.

- FR\-07: Hệ thống không được cung cấp action ghi nhận payment mới, void hoặc thu công nợ trực tiếp trong User Story này\.

    

**Business rules**

- BR\-01: Sales Settlement sở hữu authoritative payment status và payment transactions\.

- BR\-02: `outstanding_amount = amount_due - confirmed_collections + confirmed_refunds` theo settlement rule hiện hành và không được tính lại từ UI history\.

- BR\-03: Payment transaction đã ghi nhận không được sửa trực tiếp; thay đổi phải qua void, refund hoặc command nghiệp vụ phù hợp\.

- BR\-04: Receivable impact status không đồng nghĩa với trạng thái ledger authoritative của Theme 6\.

- BR\-05: Người dùng chỉ xem payment details hoặc receivable link khi có permission tương ứng\.

- BR\-06: Refund hoặc void sau bán không thay đổi commercial snapshot của SalesOrder\.

- BR\-07: Projection payment summary có thể eventual consistent nhưng phải hội tụ về Sales Settlement authoritative\.

    

**Acceptance criteria**

- AC\-01: Payment summary khớp dữ liệu authoritative của Sales Settlement\.

- AC\-02: Mỗi transaction hiển thị đúng loại, số tiền, phương thức, thời điểm và trạng thái\.

- AC\-03: Collection, void và refund được phân biệt rõ\.

- AC\-04: Đơn còn phải thu hiển thị đúng outstanding amount và due date nếu có\.

- AC\-05: Người dùng có quyền có thể mở receivable context của Theme 6\.

- AC\-06: Người dùng không có quyền xem payment chi tiết chỉ nhận thông tin tổng quát được phép\.

- AC\-07: Không có thao tác trong User Story này tạo hoặc chỉnh sửa payment transaction\.

    

**Edge cases**

- EC\-01: Settlement chưa được projected vào summary; hệ thống hiển thị đang cập nhật và cho phép tải lại\.

- EC\-02: Một payment transaction đang pending hoặc failed; hệ thống hiển thị trạng thái thực tế, không cộng vào confirmed total sai quy tắc\.

- EC\-03: Refund đã ghi nhận sau khi đơn bị hủy hoặc đổi/trả; summary phải phản ánh refund nhưng giữ nguyên giao dịch gốc\.

- EC\-04: Receivable impact accepted nhưng Theme 6 chưa hoàn tất projection; hệ thống hiển thị trạng thái riêng\.

- EC\-05: Người dùng có quyền xem đơn nhưng không có `sales.payment.view`; payment details bị che\.

- EC\-06: Payment method master đã thay đổi; transaction vẫn hiển thị method snapshot tại thời điểm ghi nhận\.

- EC\-07: Nhiều payment và refund xảy ra gần nhau; summary phải dựa trên version mới nhất và không double count\.

    

**Scenarios**

```Gherkin
Feature: Kiểm tra thanh toán và công nợ của đơn

Scenario: SC-01 — Đơn đã thanh toán đủ
  Given SalesOrderSettlement có amount due 1.000.000 đồng
  And confirmed collections là 1.000.000 đồng
  And chưa có refund
  When người dùng mở payment summary
  Then payment status là paid
  And tổng đã thanh toán là 1.000.000 đồng
  And số còn phải thu bằng 0

Scenario: SC-02 — Đơn thanh toán một phần
  Given amount due là 1.000.000 đồng
  And confirmed collections là 400.000 đồng
  When người dùng mở payment summary
  Then payment status là partially_paid
  And số còn phải thu là 600.000 đồng
  And hiển thị due date nếu có

Scenario: SC-03 — Đơn có hoàn tiền
  Given đơn đã có confirmed collection
  And có confirmed refund 200.000 đồng
  When người dùng xem payment transactions
  Then refund được hiển thị riêng với collection
  And tổng đã hoàn tiền là 200.000 đồng
  And commercial snapshot của đơn không thay đổi

Scenario: SC-04 — Payment bị void
  Given một SalesPaymentTransaction đã được void đúng nghiệp vụ
  When người dùng xem lịch sử thanh toán
  Then transaction gốc hiển thị trạng thái voided
  And summary không tính khoản void như confirmed collection

Scenario: SC-05 — Mở công nợ trong Theme 6
  Given đơn có outstanding amount lớn hơn 0
  And người dùng có quyền xem công nợ
  When người dùng chọn liên kết công nợ
  Then hệ thống mở đúng receivable context trong Theme 6
  And EP-03 không tự cập nhật receivable ledger

Scenario: SC-06 — Không có quyền xem payment chi tiết
  Given người dùng có quyền sales.order.view
  And không có quyền sales.payment.view
  When người dùng mở chi tiết đơn
  Then hệ thống không hiển thị danh sách transaction nhạy cảm
  And chỉ hiển thị thông tin tổng quát được policy cho phép

Scenario: SC-07 — Projection payment đang chậm
  Given Sales Settlement đã ghi nhận refund mới
  And SalesOrderPaymentSummaryView chưa cập nhật
  When người dùng mở payment summary
  Then hệ thống hiển thị trạng thái đang cập nhật hoặc thời điểm dữ liệu gần nhất
  And cho phép tải lại
```

**References**

- Domains:

    - Sales Settlement

    - Sales Order Inquiry \& Documents

- Data:

    - `SalesOrderPaymentSummaryView`

    - `SalesOrderSettlement`

    - `SalesPaymentTransaction`

    - `PaymentMethodSnapshot`

    - `ReceivableImpactRequest`

- Commands / queries / events:

    - `GetSalesOrderPaymentSummary`

    - `GetSalesOrderSettlement`

    - `GetSalesOrderPaymentTransactions`

    - `SalesPaymentRecorded`

    - `SalesPaymentVoided`

    - `SalesRefundRecorded`

    - `SalesSettlementChanged`

- Permissions:

    - `sales.payment.view`

    - `sales.order.view`

    - Quyền xem công nợ của Theme 6

- External dependencies:

    - Theme 6 — Receivable ledger và receivable detail

    - Theme 1 — Permission và store scope

        

#### 4\.4\.6\.5 US\-04 — Theo dõi timeline và lịch sử sau bán

**Business context**

Một SalesOrder có thể phát sinh nhiều hoạt động sau checkout như thanh toán, void, refund, tạo receipt, điều chỉnh metadata, yêu cầu hủy, hủy đơn hoặc đổi/trả\. Người kiểm soát cần xem các hoạt động theo trình tự thời gian và truy vết nguồn của từng thay đổi\.

Timeline phải append\-only\. Activity mới được bổ sung nhưng activity cũ không được sửa hoặc xóa chỉ để thay đổi cách hiển thị lịch sử\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Quản lý cửa hàng, Kế toán hoặc Người kiểm soát|Xem timeline, điều chỉnh, hủy và đổi/trả theo trình tự thời gian|Tôi có thể truy vết ai đã thực hiện hành động gì và kết quả ra sao|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị SalesOrderTimelineView theo thứ tự thời gian với khả năng tải thêm khi lịch sử dài\.

- FR\-02: Timeline phải bao gồm các activity phù hợp về order, payment, refund, receipt, adjustment, cancellation, return/exchange và downstream impact\.

- FR\-03: Mỗi item phải hiển thị loại hoạt động, thời điểm, actor hoặc system, kết quả và mô tả hoặc lý do ngắn khi có\.

- FR\-04: Hệ thống phải cho phép mở chứng từ hoặc nghiệp vụ nguồn khi người dùng có quyền\.

- FR\-05: Hệ thống phải cho phép xem before/after diff đối với adjustment hoặc activity có dữ liệu thay đổi\.

- FR\-06: Hệ thống phải hiển thị SalesOrderReturnSummaryView gồm return status, giá trị trả, giá trị đổi, thu thêm, hoàn tiền, cấn trừ và danh sách phiếu liên quan\.

- FR\-07: Hệ thống phải hiển thị cancellation summary khi đơn đã bị hủy và giữ nguyên commercial snapshot gốc\.

    

**Business rules**

- BR\-01: Timeline là append\-only; item đã ghi nhận không được chỉnh sửa hoặc xóa từ EP\-03\.

- BR\-02: Mỗi activity phải truy được về source type, source ID, actor, timestamp và correlation hoặc causation context khi cần\.

- BR\-03: `fully_returned` không đồng nghĩa với order lifecycle `cancelled`\.

- BR\-04: Adjustment, cancellation và return/exchange không được ghi đè transaction gốc\.

- BR\-05: Before/after diff chỉ hiển thị với người dùng có quyền xem dữ liệu liên quan\.

- BR\-06: Return summary là projection; authoritative return/exchange records thuộc Post\-sale Operations\.

- BR\-07: Product analytics event không được trình bày như domain event trong timeline nghiệp vụ\.

    

**Acceptance criteria**

- AC\-01: Timeline hiển thị các activity theo đúng thứ tự thời gian và không tạo item trùng\.

- AC\-02: Mỗi item thể hiện được actor hoặc system, timestamp, kết quả và nguồn\.

- AC\-03: Adjustment có thể hiển thị before/after diff khi người dùng có quyền\.

- AC\-04: Đơn đã hủy hiển thị cancellation summary và vẫn giữ transaction gốc\.

- AC\-05: Return summary phản ánh đúng none, partially\_returned hoặc fully\_returned\.

- AC\-06: Người dùng có quyền có thể mở phiếu đổi/trả hoặc nghiệp vụ nguồn liên quan\.

- AC\-07: Không có action sửa hoặc xóa timeline item\.

    

**Edge cases**

- EC\-01: Hai activity có cùng timestamp; hệ thống dùng sequence hoặc event ordering để hiển thị ổn định\.

- EC\-02: Actor đã bị khóa hoặc xóa; timeline vẫn giữ actor snapshot hoặc định danh lịch sử phù hợp\.

- EC\-03: Source record không còn mở được do thiếu quyền; timeline vẫn hiển thị activity nhưng không cung cấp deep link\.

- EC\-04: Projection timeline chậm hơn authoritative event; hệ thống hiển thị thời điểm cập nhật gần nhất\.

- EC\-05: Activity được retry kỹ thuật nhiều lần; timeline nghiệp vụ không tạo nhiều business item trùng\.

- EC\-06: ReturnExchangeOrder draft bị hủy; timeline chỉ hiển thị nếu policy yêu cầu lưu vết nghiệp vụ tương ứng\.

- EC\-07: Before/after diff có dữ liệu nhạy cảm; hệ thống che field theo permission policy\.

    

**Scenarios**

```Gherkin
Feature: Theo dõi timeline và lịch sử sau bán

Scenario: SC-01 — Xem timeline giao dịch cơ bản
  Given SalesOrder đã được hoàn tất và có payment
  When người dùng mở timeline
  Then hệ thống hiển thị activity hoàn tất đơn
  And activity ghi nhận payment
  And các item được sắp xếp theo trình tự thời gian

Scenario: SC-02 — Xem adjustment diff
  Given đơn có OrderAdjustment đã applied
  And người dùng có quyền xem lịch sử
  When người dùng mở activity điều chỉnh
  Then hệ thống hiển thị field đã thay đổi
  And giá trị trước và sau
  And actor, timestamp và reason

Scenario: SC-03 — Xem đơn đã hủy
  Given SalesOrder lifecycle là cancelled
  When người dùng xem timeline
  Then hệ thống hiển thị cancellation request hoặc confirmation phù hợp
  And activity SalesOrderCancelled
  And commercial snapshot gốc vẫn được giữ

Scenario: SC-04 — Xem return summary
  Given đơn đã có một ReturnExchangeOrder completed
  When người dùng mở return summary
  Then hệ thống hiển thị return status hiện tại
  And tổng giá trị hàng trả, hàng đổi, thu thêm hoặc hoàn tiền
  And liên kết tới phiếu nếu người dùng có quyền

Scenario: SC-05 — Trả toàn bộ hàng nhưng không hủy đơn
  Given return status là fully_returned
  And order lifecycle vẫn là completed
  When người dùng xem chi tiết
  Then hệ thống hiển thị hai trạng thái độc lập
  And không trình bày đơn như cancelled

Scenario: SC-06 — Không có quyền mở source
  Given timeline có activity liên quan đến một nghiệp vụ nguồn
  And người dùng không có quyền xem source đó
  When người dùng xem activity
  Then hệ thống hiển thị thông tin timeline được phép
  And không cung cấp hoặc không mở deep link nguồn

Scenario: SC-07 — Timeline projection đang chậm
  Given authoritative post-sale event đã commit
  And timeline projection chưa cập nhật
  When người dùng mở timeline
  Then hệ thống hiển thị dữ liệu gần nhất cùng trạng thái đang cập nhật
  And cho phép tải lại
```

**References**

- Domains:

    - Sales Order Inquiry \& Documents

    - Post\-sale Operations

    - Sales Settlement

- Data:

    - `SalesOrderTimelineView`

    - `SalesOrderReturnSummaryView`

    - `OrderAdjustment`

    - `SalesOrderCancellation`

    - `ReturnExchangeOrder`

    - `SalesReceiptActivity`

    - Correlation context

    - Causation context

- Commands / queries / events:

    - `GetSalesOrderTimeline`

    - `GetSalesOrderReturnSummary`

    - Các domain event của order, settlement, receipt và post\-sale operations

- Permissions:

    - `sales.order.history.view`

    - `sales.return_exchange.view`

    - Permission xem dữ liệu nhạy cảm liên quan

- External dependencies:

    - Platform Audit — Dấu vết hành động bắt buộc

    - Theme 6 — Receivable impact activities

    - Theme 7 — Inventory impact activities

    - Theme 8 — E\-invoice activities

        

#### 4\.4\.6\.6 US\-05 — Xem lại phiếu bán hàng

**Business context**

Phiếu bán hàng nội bộ giúp người dùng và khách hàng đối chiếu nội dung giao dịch sau thời điểm bán\. Phiếu phải được tạo từ commercial snapshot, không được tính lại từ Product, Partner hoặc Pricing master hiện hành\.

Một SalesOrder có thể có nhiều receipt version nếu policy cho phép tái tạo, nhưng version cũ phải được bảo toàn khi audit policy yêu cầu\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền|Xem, in lại, chia sẻ lại hoặc kiểm tra các version của phiếu bán hàng|Tôi có thể hỗ trợ khách và đối chiếu chứng từ sau thời điểm bán|



**Functional requirements**

- FR\-01: Hệ thống phải tải SalesReceipt hiện hành của SalesOrder\.

- FR\-02: Nếu chưa có persisted receipt và policy cho phép, hệ thống phải cho phép sinh receipt từ commercial snapshot\.

- FR\-03: Receipt phải hiển thị tenant, cửa hàng, mã đơn, thời điểm bán, người bán, khách hàng, dòng hàng, tổng tiền, thanh toán, số còn phải thu, ghi chú và nhãn phiếu nội bộ\.

- FR\-04: Hệ thống phải cho phép xem các receipt version và xác định version hiện hành\.

- FR\-05: Hệ thống phải cho phép in receipt khi thiết bị và permission hỗ trợ\.

- FR\-06: Hệ thống phải cho phép chia sẻ receipt khi kênh và permission hỗ trợ\.

- FR\-07: Hệ thống phải ghi SalesReceiptActivity cho hành động printed, shared hoặc archived với actor, timestamp và channel hoặc device context khi cần\.

    

**Business rules**

- BR\-01: SalesReceipt phải được sinh từ SalesOrder commercial snapshot\.

- BR\-02: SalesReceipt không phải hóa đơn điện tử và phải có nhãn phân biệt rõ\.

- BR\-03: GenerateSalesReceipt phải idempotent theo SalesOrder và receipt version context\.

- BR\-04: Việc in, chia sẻ hoặc archive không làm thay đổi order lifecycle hoặc payment status\.

- BR\-05: Receipt version mới không được ghi đè version cũ khi audit policy yêu cầu lưu lịch sử\.

- BR\-06: Lỗi receipt generation không làm rollback hoặc hủy SalesOrder đã commit\.

- BR\-07: Người dùng chỉ được xem nội dung, version và activity theo permission tương ứng\.

    

**Acceptance criteria**

- AC\-01: Người dùng có quyền xem được receipt hiện hành khớp commercial snapshot\.

- AC\-02: Receipt hiển thị rõ đây là phiếu bán hàng nội bộ, không phải hóa đơn điện tử\.

- AC\-03: Người dùng có thể xem danh sách version khi có nhiều version\.

- AC\-04: In receipt ghi nhận đúng SalesReceiptPrinted hoặc activity tương ứng\.

- AC\-05: Chia sẻ receipt ghi nhận đúng SalesReceiptShared và distribution context\.

- AC\-06: Archive receipt không làm mất order hoặc receipt history\.

- AC\-07: Khi chưa tạo được receipt, hệ thống hiển thị trạng thái phù hợp và cho phép thử lại theo policy\.

    

**Edge cases**

- EC\-01: Receipt chưa được tạo; hệ thống hiển thị Chưa tạo và action sinh receipt nếu được phép\.

- EC\-02: Receipt generation đang pending; hệ thống hiển thị đang chuẩn bị và không tạo request trùng\.

- EC\-03: Receipt generation failed; hệ thống giữ order success và cho phép retry có kiểm soát\.

- EC\-04: Thiết bị không hỗ trợ in; action in bị disable nhưng vẫn cho xem receipt\.

- EC\-05: Kênh chia sẻ không khả dụng; hệ thống hiển thị lỗi nhẹ và không thay đổi receipt\.

- EC\-06: Master data thay đổi sau bán; receipt vẫn giữ snapshot cũ\.

- EC\-07: Người dùng không có permission xem version cũ; hệ thống chỉ hiển thị version được phép\.

    

**Scenarios**

```Gherkin
Feature: Xem lại phiếu bán hàng

Scenario: SC-01 — Xem receipt hiện hành
  Given SalesReceipt đã generated
  And người dùng có quyền sales.receipt.view
  When người dùng mở phiếu bán hàng
  Then hệ thống thực hiện GetSalesReceipt
  And hiển thị nội dung từ commercial snapshot
  And hiển thị nhãn phiếu bán hàng nội bộ

Scenario: SC-02 — Sinh receipt khi chưa có
  Given SalesOrder đã completed
  And chưa có persisted receipt
  And policy cho phép generate khi cần
  When người dùng có quyền chọn tạo phiếu
  Then hệ thống thực hiện GenerateSalesReceipt với idempotency
  And tạo receipt version từ SalesOrder snapshot

Scenario: SC-03 — Xem nhiều version
  Given SalesOrder có nhiều receipt version
  When người dùng mở lịch sử version
  Then hệ thống hiển thị các version theo thứ tự
  And xác định rõ version hiện hành
  And không làm mất version cũ

Scenario: SC-04 — In lại receipt
  Given receipt đã generated
  And thiết bị hỗ trợ in
  And người dùng có quyền sales.receipt.print
  When người dùng chọn In
  Then hệ thống gửi receipt tới chức năng in
  And ghi RecordSalesReceiptPrinted

Scenario: SC-05 — Chia sẻ receipt
  Given receipt đã generated
  And người dùng có quyền sales.receipt.share
  When người dùng chọn một kênh chia sẻ hợp lệ
  Then hệ thống chia sẻ receipt
  And ghi RecordSalesReceiptShared với distribution context

Scenario: SC-06 — Receipt generation thất bại
  Given SalesOrder đã thành công
  And GenerateSalesReceipt thất bại
  When người dùng mở khu vực phiếu bán hàng
  Then hệ thống hiển thị Không tạo được phiếu
  And SalesOrder vẫn giữ trạng thái hiện hành
  And cho phép thử lại theo policy

Scenario: SC-07 — Product master đã đổi tên
  Given product name hiện tại khác product snapshot
  When người dùng xem receipt
  Then receipt vẫn hiển thị product snapshot tại thời điểm bán
```

**References**

- Domains:

    - Sales Order Inquiry \& Documents

    - Sales Order Lifecycle

- Data:

    - `SalesReceipt`

    - `SalesReceiptActivity`

    - `ReceiptSnapshot`

    - `ReceiptTemplateReference`

    - `ReceiptContentHash`

    - `DistributionContext`

    - `SalesOrder`

    - `SalesOrderLine`

- Commands / queries / events:

    - `GetSalesReceipt`

    - `GenerateSalesReceipt`

    - `RecordSalesReceiptPrinted`

    - `RecordSalesReceiptShared`

    - `ArchiveSalesReceipt`

    - `SalesReceiptGenerated`

    - `SalesReceiptPrinted`

    - `SalesReceiptShared`

    - `SalesReceiptArchived`

- Permissions:

    - `sales.receipt.view`

    - `sales.receipt.generate`

    - `sales.receipt.print`

    - `sales.receipt.share`

    - `sales.receipt.archive`

- External dependencies:

    - Theme 1 — Store identity, branding và permission

    - Thiết bị in hoặc kênh chia sẻ của client

    - Theme 8 — Chỉ để phân biệt e\-invoice; không dùng làm nguồn sinh receipt

        

#### 4\.4\.6\.7 US\-06 — Theo dõi trạng thái xử lý liên quan

**Business context**

Sau khi SalesOrder hoặc nghiệp vụ sau bán được commit, các yêu cầu tới Receivable, Inventory, E\-invoice hoặc Reporting có thể được xử lý bất đồng bộ\. Người vận hành cần biết business impact đã được tiếp nhận hay từ chối và technical delivery đã gửi thành công hay đang thất bại\.

EP\-03 chỉ hiển thị trạng thái và gọi technical retry command khi được phép\. Epic này không trực tiếp sửa receivable ledger, stock movement, e\-invoice hoặc business impact authoritative\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền vận hành hoặc kiểm soát|Xem trạng thái Receivable, Inventory, E\-invoice và delivery của từng integration|Tôi có thể biết nội dung nào đã hoàn tất, thất bại hoặc cần đối soát|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị integration status theo từng target gồm Receivable, Inventory, E\-invoice và Reporting khi áp dụng\.

- FR\-02: Hệ thống phải phân biệt business integration status và delivery status\.

- FR\-03: Mỗi target phải hiển thị trạng thái hiện tại, thời điểm cập nhật gần nhất, failure summary, retry count nếu được phép và reconciliation status\.

- FR\-04: Hệ thống phải che raw technical payload, stack trace hoặc dữ liệu nhạy cảm với người dùng không có quyền\.

- FR\-05: Người dùng có quyền phải có thể gọi technical retry command đối với item đủ điều kiện\.

- FR\-06: Retry phải sử dụng idempotency và không tạo business impact trùng\.

- FR\-07: Sau retry hoặc khi item đã được người khác xử lý, hệ thống phải tải lại trạng thái mới nhất và không gửi request trùng\.

    

**Business rules**

- BR\-01: Business integration status có thể gồm `not_required`, `pending`, `accepted`, `rejected`, `reconciliation_required` hoặc `reconciled`\.

- BR\-02: Delivery status có thể gồm `created`, `queued`, `sent`, `acknowledged`, `failed`, `uncertain` hoặc `dead_letter`\.

- BR\-03: Delivery status không phải business status của SalesOrder, payment, receivable, inventory hoặc e\-invoice\.

- BR\-04: Retry chỉ được thực hiện với technical record đủ điều kiện và không được sửa payload nghiệp vụ đã commit\.

- BR\-05: EP\-03 không trực tiếp cập nhật dữ liệu authoritative của Theme 6, Theme 7 hoặc Theme 8\.

- BR\-06: Downstream failure sau khi source business transaction đã commit không tự động rollback SalesOrder\.

- BR\-07: Reconciliation phải truy được về source impact, integration command, correlation context và kết quả xử lý\.

    

**Acceptance criteria**

- AC\-01: Người dùng có quyền xem được trạng thái business và delivery riêng cho từng integration target\.

- AC\-02: `not_required` được phân biệt với `pending` hoặc thiếu dữ liệu\.

- AC\-03: Failure summary được hiển thị ở mức an toàn theo permission\.

- AC\-04: Retry đủ điều kiện gọi đúng technical command và không tạo impact trùng\.

- AC\-05: Item đã được xử lý bởi người khác không bị retry lần nữa sau khi tải lại\.

- AC\-06: Downstream failed không làm UI trình bày SalesOrder thành chưa hoàn tất\.

- AC\-07: Trạng thái `reconciliation_required` cung cấp hướng xử lý hoặc liên kết phù hợp theo quyền\.

    

**Edge cases**

- EC\-01: Business impact accepted nhưng delivery acknowledgement chưa về; hệ thống hiển thị hai trạng thái riêng\.

- EC\-02: Delivery uncertain; hệ thống không tự kết luận thành công hoặc gửi lại không kiểm soát\.

- EC\-03: Item đã dead\-letter; retry chỉ khả dụng theo policy hoặc cần escalation\.

- EC\-04: Người dùng không có quyền xem error detail; hệ thống chỉ hiển thị trạng thái tổng quát\.

- EC\-05: Hai người cùng retry; idempotency và concurrency phải ngăn gửi trùng\.

- EC\-06: Retry thành công nhưng projection chưa cập nhật; hệ thống hiển thị đang tải lại\.

- EC\-07: Source impact bị rejected về nghiệp vụ; technical retry không được dùng để vượt qua business rejection\.

    

**Scenarios**

```Gherkin
Feature: Theo dõi trạng thái xử lý liên quan

Scenario: SC-01 — Xem integration summary
  Given SalesOrder có impact tới Receivable, Inventory và E-invoice
  When người dùng có quyền mở integration status
  Then hệ thống thực hiện GetOrderIntegrationStatus
  And hiển thị từng target riêng
  And phân biệt business status với delivery status

Scenario: SC-02 — Không yêu cầu e-invoice
  Given đơn không yêu cầu hóa đơn điện tử
  When người dùng xem integration status
  Then E-invoice business status là not_required
  And không hiển thị như pending hoặc failed

Scenario: SC-03 — Inventory delivery failed
  Given InventoryImpactRequest còn hợp lệ
  And delivery status là failed
  When người dùng xem trạng thái
  Then hệ thống hiển thị failure summary được phép
  And SalesOrder vẫn hiển thị lifecycle hiện hành

Scenario: SC-04 — Retry Inventory impact
  Given người dùng có quyền retry
  And Inventory impact đủ điều kiện retry
  When người dùng xác nhận retry
  Then hệ thống gọi RetryInventoryImpact với idempotency
  And không tạo InventoryImpactRequest nghiệp vụ mới
  And tải lại trạng thái sau khi command được tiếp nhận

Scenario: SC-05 — Item đã được người khác retry
  Given người dùng đang xem một integration item failed
  And người khác đã retry thành công
  When người dùng xác nhận retry trên dữ liệu cũ
  Then hệ thống tải lại trạng thái mới nhất
  And không gửi technical command trùng

Scenario: SC-06 — Business rejection
  Given Receivable impact business status là rejected
  When người dùng xem action khả dụng
  Then hệ thống không cung cấp retry kỹ thuật để vượt business rejection
  And hiển thị yêu cầu xử lý hoặc reconciliation phù hợp

Scenario: SC-07 — Không có quyền xem lỗi chi tiết
  Given integration delivery là failed
  And người dùng không có quyền xem sync error detail
  When người dùng mở integration status
  Then hệ thống chỉ hiển thị trạng thái tổng quát
  And che raw payload và thông tin kỹ thuật nhạy cảm
```

**References**

- Domains:

    - Sales Order Inquiry \& Documents

    - Cross\-cutting Foundations

- Data:

    - `SalesOrderIntegrationStatusView`

    - `IntegrationCommand`

    - `InventoryImpactRequest`

    - `ReceivableImpactRequest`

    - `EInvoiceImpactRequest`

    - `FailureResult`

    - Correlation context

    - Reconciliation result

- Commands / queries / events:

    - `GetOrderIntegrationStatus`

    - `GetIntegrationCommandStatus`

    - `GetImpactRequestStatus`

    - `GetReconciliationStatus`

    - `RetryIntegrationCommand`

    - `RetryInventoryImpact`

    - `RetryReceivableImpact`

    - `RetryEInvoiceImpact`

    - `ReconcileIntegrationResult`

- Permissions:

    - `sales.integration.view_sync_status`

    - Permission retry hoặc reconciliation theo policy vận hành

- External dependencies:

    - Theme 6 — Receivable authoritative state

    - Theme 7 — Inventory authoritative state

    - Theme 8 — E\-invoice authoritative state

    - Theme 10 — Reporting delivery khi được hiển thị

        

#### 4\.4\.6\.8 US\-07 — Khởi tạo thao tác sau bán

**Business context**

Chi tiết đơn hàng là điểm người dùng bắt đầu các nghiệp vụ Điều chỉnh, Hủy hoặc Đổi/trả\. Hệ thống phải chỉ hiển thị action phù hợp với permission và trạng thái hiện tại, đồng thời chuyển đúng SalesOrder context sang Epic đích\.

Action availability tại EP\-03 chỉ là kiểm tra sơ bộ\. Eligibility authoritative vẫn phải được kiểm tra lại tại EP\-04, EP\-05 hoặc EP\-06 ngay trước khi nghiệp vụ được tạo hoặc xác nhận\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền|Xem và mở các hành động Điều chỉnh, Hủy hoặc Đổi/trả phù hợp với trạng thái đơn|Tôi có thể bắt đầu đúng nghiệp vụ mà không thực hiện hành động không hợp lệ|



**Functional requirements**

- FR\-01: Hệ thống phải xác định các action sau bán khả dụng dựa trên tenant, store scope, permission, order lifecycle, lock status và các nghiệp vụ liên quan\.

- FR\-02: Hệ thống phải hiển thị action Điều chỉnh khi người dùng có `sales.order.adjust` và đơn có thể thực hiện precheck điều chỉnh\.

- FR\-03: Hệ thống phải hiển thị action Hủy khi người dùng có `sales.order.cancel` và đơn chưa bị hủy\.

- FR\-04: Hệ thống phải hiển thị action Đổi/trả khi người dùng có `sales.return_exchange.create` và đơn chưa bị hủy\.

- FR\-05: Khi người dùng chọn action, hệ thống phải truyền sales\_order\_id và source version hoặc context cần thiết sang Epic đích\.

- FR\-06: Hệ thống phải hiển thị blocker hoặc lý do không khả dụng khi policy cho phép giải thích\.

- FR\-07: Khi người dùng quay lại từ EP\-04, EP\-05 hoặc EP\-06, hệ thống phải tải lại detail, timeline, payment, return và integration projection mới nhất\.

    

**Business rules**

- BR\-01: Việc hiển thị action không bảo đảm thao tác sẽ thành công; Epic đích phải chạy precheck authoritative\.

- BR\-02: EP\-03 không trực tiếp tạo OrderAdjustment, SalesOrderCancellation hoặc ReturnExchangeOrder\.

- BR\-03: Người dùng không có permission không được nhìn thấy hoặc kích hoạt action tương ứng\.

- BR\-04: SalesOrder lifecycle `cancelled` không cho bắt đầu cancellation mới hoặc return/exchange mới\.

- BR\-05: Lock status và conflict với nghiệp vụ đang xử lý phải được Epic đích kiểm tra lại trước commit\.

- BR\-06: Mọi deep link sang Epic đích phải giữ tenant, store scope, sales\_order\_id và correlation context phù hợp\.

- BR\-07: Khi projection chưa cập nhật sau khi quay lại, hệ thống phải hiển thị trạng thái đang cập nhật thay vì cho rằng nghiệp vụ không xảy ra\.

    

**Acceptance criteria**

- AC\-01: Người dùng chỉ thấy các action phù hợp với permission và trạng thái đơn\.

- AC\-02: Chọn Điều chỉnh mở đúng flow EP\-04 với SalesOrder context\.

- AC\-03: Chọn Hủy mở đúng flow EP\-05 với SalesOrder context\.

- AC\-04: Chọn Đổi/trả mở đúng flow EP\-06 với SalesOrder context\.

- AC\-05: Epic đích có thể chặn thao tác dù action đã hiển thị nếu authoritative state đã thay đổi\.

- AC\-06: Hủy hoặc quay lại từ Epic đích không làm thay đổi SalesOrder nếu chưa commit nghiệp vụ\.

- AC\-07: Sau nghiệp vụ thành công, chi tiết đơn được tải lại và phản ánh projection mới nhất khi sẵn sàng\.

    

**Edge cases**

- EC\-01: Permission bị thu hồi sau khi action đã hiển thị; Epic đích từ chối và không tạo record\.

- EC\-02: Order lifecycle đổi thành cancelled trước khi người dùng bắt đầu đổi/trả; hệ thống tải lại và chặn\.

- EC\-03: Order version thay đổi do adjustment khác; precheck trả conflict và yêu cầu tải lại\.

- EC\-04: Có nghiệp vụ cạnh tranh đang xử lý; Epic đích trả blocker phù hợp\.

- EC\-05: Người dùng hủy flow sau bán; hệ thống quay lại chi tiết đơn mà không tạo business record đã xác nhận\.

- EC\-06: Nghiệp vụ đã commit nhưng projection chậm; hệ thống hiển thị đang cập nhật và không khuyến khích tạo lại\.

- EC\-07: Deep link hoặc context bị sửa; backend xác minh lại tenant, store scope và sales\_order\_id trước khi tiếp tục\.

    

**Scenarios**

```Gherkin
Feature: Khởi tạo thao tác sau bán

Scenario: SC-01 — Mở flow điều chỉnh
  Given người dùng có quyền sales.order.adjust
  And SalesOrder đủ điều kiện sơ bộ
  When người dùng chọn "Điều chỉnh thông tin"
  Then hệ thống mở EP-04 với sales_order_id và context phù hợp
  And EP-04 thực hiện PrecheckOrderAdjustment trước khi áp dụng

Scenario: SC-02 — Mở flow hủy đơn
  Given người dùng có quyền sales.order.cancel
  And SalesOrder chưa bị hủy
  When người dùng chọn "Hủy đơn hàng"
  Then hệ thống mở EP-05 với SalesOrder context
  And EP-05 kiểm tra eligibility authoritative

Scenario: SC-03 — Mở flow đổi trả
  Given người dùng có quyền sales.return_exchange.create
  And SalesOrder chưa bị hủy
  When người dùng chọn "Đổi/trả hàng"
  Then hệ thống mở EP-06 với sales_order_id
  And EP-06 kiểm tra returnable quantity và các blocker hiện hành

Scenario: SC-04 — Không có quyền
  Given người dùng không có quyền sales.order.cancel
  When người dùng xem action sau bán
  Then action Hủy đơn không được hiển thị hoặc kích hoạt
  And không thể mở EP-05 bằng client action thông thường

Scenario: SC-05 — State thay đổi sau khi action hiển thị
  Given action Đổi/trả đã được hiển thị
  And SalesOrder bị hủy trước khi người dùng xác nhận mở flow
  When EP-06 kiểm tra authoritative state
  Then thao tác bị chặn
  And không tạo ReturnExchangeOrder

Scenario: SC-06 — Hủy flow sau bán
  Given người dùng đã mở EP-04, EP-05 hoặc EP-06
  When người dùng hủy flow trước khi commit
  Then hệ thống quay lại chi tiết SalesOrder
  And không thay đổi order lifecycle hoặc post-sale records đã xác nhận

Scenario: SC-07 — Quay lại sau nghiệp vụ thành công
  Given một nghiệp vụ sau bán đã commit thành công
  When người dùng quay lại chi tiết đơn
  Then hệ thống tải lại detail, timeline, payment, return và integration status
  And hiển thị trạng thái đang cập nhật nếu projection chưa bắt kịp
```

**References**

- Domains:

    - Sales Order Inquiry \& Documents

    - Post\-sale Operations

    - Sales Order Lifecycle

- Data:

    - `SalesOrderDetailView`

    - `SalesOrder`

    - Order lifecycle

    - Lock status

    - Available actions

    - Correlation context

- Commands / queries / events:

    - `GetSalesOrderDetail`

    - `PrecheckOrderAdjustment`

    - `PrecheckSalesOrderCancellation`

    - `PrecheckReturnExchange`

    - Các command chính thức thuộc EP\-04, EP\-05 và EP\-06

- Permissions:

    - `sales.order.adjust`

    - `sales.order.cancel`

    - `sales.return_exchange.create`

    - `sales.order.view`

- External dependencies:

    - EP\-04 — Điều chỉnh thông tin đơn hàng sau bán

    - EP\-05 — Hủy đơn hàng sau bán

    - EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch

## 4\.5 EP\-04 — Chỉnh sửa ghi chú đơn hàng

### 4\.5\.1 Overview

Epic này cho phép người dùng có quyền cập nhật ghi chú phục vụ vận hành của một SalesOrder đã hoàn tất mà không làm thay đổi commercial snapshot hoặc các tác động nghiệp vụ của giao dịch gốc\.

Trong Phase 1, EP\-04 chỉ áp dụng cho trường `order_note`\. Epic không phải capability điều chỉnh thông tin đơn hàng tổng quát và không sử dụng adjustable field whitelist, dynamic field schema hoặc form điều chỉnh nhiều trường\.

Mỗi lần cập nhật ghi chú thành công phải tạo một OrderAdjustment độc lập có `adjustment_type = order_note_update`\. OrderAdjustment lưu ghi chú trước thay đổi, ghi chú sau thay đổi, người thực hiện, thời điểm thực hiện và phiên bản đơn hàng nguồn\.

Ghi chú được lưu tại checkout tiếp tục được bảo toàn trong dữ liệu giao dịch gốc\. Ghi chú hiện hành được xác định từ OrderAdjustment đã áp dụng gần nhất nếu đơn hàng từng được cập nhật ghi chú\.

OrderAdjustment là bản ghi append\-only, không được sửa hoặc xóa sau khi tạo\. Nếu người dùng tiếp tục thay đổi ghi chú, hệ thống phải tạo một OrderAdjustment mới\.

EP\-04 không có Screen Group riêng\. Người dùng xem và chỉnh sửa ghi chú ngay tại SG\-08 — Chi tiết \& lịch sử đơn hàng\.

### 4\.5\.2 Business context

Sau khi đơn hàng đã hoàn tất, người dùng có thể cần bổ sung hoặc sửa ghi chú phục vụ vận hành, ví dụ hướng dẫn giao nhận, nội dung cần lưu ý khi chăm sóc khách hàng hoặc thông tin nội bộ liên quan trực tiếp đến đơn hàng\.

Ghi chú không làm thay đổi bản chất thương mại của giao dịch nhưng vẫn cần được kiểm soát quyền và lưu lịch sử để xác định nội dung nào đã được thay đổi, ai thực hiện và thay đổi vào thời điểm nào\.

Việc sửa ghi chú không cần một workflow điều chỉnh nhiều bước\. Luồng nghiệp vụ chỉ gồm xem ghi chú hiện hành, mở form chỉnh sửa, nhập nội dung, lưu thay đổi và cập nhật lịch sử đơn hàng\.

### 4\.5\.3 In scope

- Hiển thị ghi chú hiện hành tại chi tiết đơn hàng\.

- Hiển thị action Sửa khi người dùng và đơn hàng đủ điều kiện\.

- Cho phép cập nhật hoặc xóa ghi chú đơn hàng\.

- Kiểm tra quyền, tenant, store scope và trạng thái đơn trước khi lưu\.

- Kiểm tra source order version để ngăn ghi đè thay đổi mới hơn\.

- Tạo OrderAdjustment khi nội dung ghi chú thực sự thay đổi\.

- Hiển thị ghi chú mới và lịch sử thay đổi tại SG\-08\.

### 4\.5\.4 Out of scope

- Chỉnh sửa khách hàng, buyer\-tax snapshot hoặc thông tin nhận diện giao dịch\.

- Chỉnh sửa cửa hàng, người bán, ca bán, thời điểm bán hoặc mã đơn hàng\.

- Chỉnh sửa sản phẩm, đơn vị bán, số lượng, giá, chiết khấu, thuế hoặc tổng tiền\.

- Chỉnh sửa payment, refund, công nợ, tồn kho hoặc hóa đơn điện tử\.

- Quản lý tag, nhãn nội bộ, mã tham chiếu ngoài hoặc metadata tùy biến\.

- Adjustable field whitelist, dynamic field schema, reason catalog hoặc approval workflow\.

- Sửa hoặc xóa một OrderAdjustment đã được ghi nhận\.

### 4\.5\.5 Entry points

- SG\-08 — Chi tiết \& lịch sử đơn hàng → khu vực Ghi chú đơn hàng → Sửa\.

- Deep link đến chi tiết một SalesOrder hợp lệ, sau đó người dùng chọn Sửa tại khu vực ghi chú\.

- Timeline đơn hàng cho phép xem activity thay đổi ghi chú nhưng không cho sửa lại OrderAdjustment cũ\.

Action Sửa chỉ được hiển thị khi:

- Người dùng đã xác thực và Platform User đang hoạt động\.

- Tenant Membership và TenantContext còn hợp lệ\.

- Người dùng có permission `sales.order.adjust`\.

- SalesOrder thuộc tenant và store scope được phép\.

- SalesOrder có lifecycle `completed`\.

- SalesOrder chưa chuyển sang `cancelled`\.

SalesOrder đã khóa vẫn được phép sửa ghi chú vì thao tác tạo OrderAdjustment riêng và không ghi đè commercial snapshot của giao dịch gốc\.

### 4\.5\.6 User stories

- US\-01 — Cập nhật ghi chú đơn hàng: Người dùng có quyền có thể cập nhật hoặc xóa ghi chú và hệ thống ghi nhận lịch sử thay đổi an toàn\.

#### 4\.5\.6\.1 US\-01 — Cập nhật ghi chú đơn hàng

**Business context**

Người dùng có thể cần bổ sung hoặc sửa ghi chú sau khi đơn hàng đã hoàn tất\. Nội dung này chỉ phục vụ vận hành và không được làm thay đổi sản phẩm, giá trị đơn, thanh toán, công nợ, tồn kho hoặc hóa đơn điện tử\.

Hệ thống phải cho phép cập nhật ghi chú bằng một thao tác ngắn ngay tại chi tiết đơn hàng, đồng thời bảo toàn ghi chú gốc và lưu đầy đủ lịch sử thay đổi\.

**Là** người dùng có quyền quản lý đơn hàng  

**Tôi muốn** cập nhật hoặc xóa ghi chú của một đơn hàng đã hoàn tất  

**Để** lưu lại thông tin vận hành cần thiết mà không làm thay đổi giao dịch gốc

**Functional requirements**

- FR\-01\. Hệ thống phải hiển thị ghi chú hiện hành và action Sửa tại SG\-08 khi người dùng và đơn hàng đủ điều kiện\.

- FR\-02\. Khi người dùng chọn Sửa, hệ thống phải mở form với ghi chú hiện hành và source order version dùng để kiểm tra conflict khi lưu\.

- FR\-03\. Hệ thống phải cho phép người dùng cập nhật nội dung hoặc xóa toàn bộ ghi chú và kiểm tra tính hợp lệ của nội dung trước khi lưu\.

- FR\-04\. Khi người dùng chọn Lưu, hệ thống phải kiểm tra lại điều kiện nghiệp vụ, source order version và idempotency key trước khi tạo OrderAdjustment\.

- FR\-05\. Sau khi lưu thành công, hệ thống phải cập nhật ghi chú hiện hành tại SG\-08 và bổ sung activity thay đổi ghi chú vào timeline đơn hàng\.

**Business rules**

- BR\-01\. Người dùng phải có `sales.order.view` để xem chi tiết đơn và `sales.order.adjust` để chỉnh sửa ghi chú\. Backend phải kiểm tra lại Platform User, Tenant Membership, TenantContext, tenant, store scope và permission tại thời điểm lưu\.

- BR\-02\. Chỉ SalesOrder chính thức có lifecycle `completed` mới được chỉnh sửa ghi chú\. SalesOrder có lifecycle `cancelled` không được mở hoặc lưu chỉnh sửa\.

- BR\-03\. Trạng thái khóa của đơn không chặn chỉnh sửa ghi chú vì hệ thống tạo OrderAdjustment riêng và không ghi đè commercial snapshot, dòng hàng hoặc giá trị giao dịch gốc\.

- BR\-04\. Form và command chỉ được phép thay đổi `order_note`\. Request chứa bất kỳ field nghiệp vụ nào khác phải bị từ chối toàn bộ\.

- BR\-05\. Hệ thống phải trim khoảng trắng ở đầu và cuối nội dung trước khi so sánh\. Nội dung rỗng sau normalize được hiểu là xóa ghi chú; nội dung giống ghi chú hiện hành sau normalize không tạo OrderAdjustment\.

- BR\-06\. Ghi chú gốc tại checkout không bị ghi đè\. Ghi chú hiện hành được xác định từ OrderAdjustment đã áp dụng gần nhất nếu có\.

- BR\-07\. Mỗi lần cập nhật thành công phải tạo đúng một OrderAdjustment append\-only có `adjustment_type = order_note_update`, lưu previous note, updated note, source order version, actor và thời điểm thực hiện\. Thao tác không tạo hoặc thay đổi payment, refund, receivable, inventory, pricing, reporting amount, phiếu bán hàng hoặc hóa đơn điện tử\.

**Edge cases**

- EC\-01\. Không tải được ghi chú hiện hành hoặc source order version: hệ thống không mở form chỉnh sửa và cho phép người dùng thử tải lại\.

- EC\-02\. Người dùng truy cập đơn ngoài tenant hoặc store scope được phép: hệ thống không trả nội dung ghi chú và không hiển thị action Sửa\.

- EC\-03\. Đơn bị hủy sau khi form đã mở: backend từ chối lưu và yêu cầu tải lại chi tiết đơn\.

- EC\-04\. Người dùng mất permission hoặc Tenant Membership không còn hợp lệ trong khi form đang mở: backend từ chối lưu\.

- EC\-05\. Ghi chú đã được người khác cập nhật: hệ thống trả conflict, không tự merge và không ghi đè nội dung mới hơn\.

- EC\-06\. Server đã commit nhưng client không nhận được response: retry cùng idempotency key phải trả lại kết quả đã tạo thay vì tạo OrderAdjustment mới\.

- EC\-07\. Người dùng chỉ thêm hoặc xóa khoảng trắng không có ý nghĩa: hệ thống coi là không thay đổi và không tạo OrderAdjustment\.

**User interface**

- UI\-01\. SG\-08 phải có khu vực “Ghi chú đơn hàng”, hiển thị nội dung hiện hành hoặc “Chưa có ghi chú”\.

- UI\-02\. Action “Sửa” nằm trực tiếp tại khu vực ghi chú; không đặt action “Điều chỉnh thông tin” trong contextual action sheet của đơn hàng\.

- UI\-03\. Form chỉnh sửa chỉ gồm một trường ghi chú nhiều dòng, action Hủy và action Lưu\.

- UI\-04\. Form phải hiển thị ghi chú hiện hành khi mở và hiển thị validation trực tiếp dưới trường nhập khi nội dung không hợp lệ\.

- UI\-05\. Khi người dùng đóng form sau khi nội dung đã thay đổi nhưng chưa lưu, hệ thống phải hiển thị confirmation trước khi bỏ thay đổi\.

- UI\-06\. Trong khi đang lưu, action Lưu phải hiển thị trạng thái xử lý và ngăn gửi lặp\.

- UI\-07\. Lưu thành công phải đóng form, cập nhật khu vực ghi chú và timeline tại SG\-08; conflict phải hiển thị thông báo và action tải lại nội dung mới nhất\.

**Non\-functional requirements**

- NFR\-01\. Command lưu thay đổi phải idempotent và trả lại cùng kết quả cho các request có cùng idempotency key\. Applies to FR\-04\.

- NFR\-02\. Việc kiểm tra source order version và tạo OrderAdjustment phải được thực hiện atomically để không phát sinh lost update\. Applies to FR\-04\.

- NFR\-03\. Mỗi thay đổi thành công phải có actor, timestamp, source version và audit correlation phục vụ truy vết\. Applies to FR\-04, FR\-05\.

- NFR\-04\. Nội dung ghi chú không được ghi vào technical log ngoài phạm vi audit được phép\. Applies to FR\-03, FR\-04\.

- NFR\-05\. Projection ghi chú hiện hành và timeline có thể eventual consistent nhưng phải hội tụ về OrderAdjustment authoritative\. Applies to FR\-05\.

**Acceptance criteria**

- AC\-01\. Người dùng có đủ quyền có thể mở form chỉnh sửa từ khu vực Ghi chú đơn hàng của một SalesOrder `completed`\.

- AC\-02\. Đơn `cancelled` không hiển thị action Sửa và backend từ chối request cập nhật ghi chú\.

- AC\-03\. Lưu nội dung mới tạo đúng một OrderAdjustment và hiển thị ghi chú hiện hành mới tại SG\-08\.

- AC\-04\. Xóa toàn bộ nội dung hợp lệ làm ghi chú hiện hành trở thành “Chưa có ghi chú” và vẫn lưu được lịch sử trước/sau\.

- AC\-05\. Nội dung không thay đổi sau normalize không tạo OrderAdjustment hoặc activity mới\.

- AC\-06\. Request chứa field ngoài `order_note` bị từ chối toàn bộ\.

- AC\-07\. Source order version cũ không được ghi đè ghi chú mới hơn và retry cùng idempotency key không tạo OrderAdjustment trùng\.

**Scenarios**

```Gherkin
Background:
  Given người dùng đã đăng nhập hệ thống
  And người dùng đang làm việc trong một TenantContext hợp lệ
  And đơn hàng thuộc tenant và store scope hiện tại

Scenario: SC-01 - Mở form chỉnh sửa ghi chú khi đủ điều kiện
  Given người dùng có quyền "sales.order.adjust"
  And đơn hàng có lifecycle "completed"
  When người dùng chọn "Sửa" tại khu vực "Ghi chú đơn hàng"
  Then hệ thống mở form chỉnh sửa
  And hệ thống hiển thị ghi chú hiện hành của đơn hàng
  And hệ thống giữ source order version để sử dụng khi lưu

Scenario: SC-02 - Không hiển thị action sửa khi người dùng không có quyền
  Given người dùng không có quyền "sales.order.adjust"
  And đơn hàng có lifecycle "completed"
  When người dùng mở chi tiết đơn hàng
  Then hệ thống hiển thị ghi chú ở chế độ chỉ đọc
  And hệ thống không hiển thị action "Sửa"

Scenario: SC-03 - Không cho sửa ghi chú của đơn đã hủy
  Given người dùng có quyền "sales.order.adjust"
  And đơn hàng có lifecycle "cancelled"
  When người dùng mở chi tiết đơn hàng
  Then hệ thống không hiển thị action "Sửa"
  And hệ thống từ chối request cập nhật ghi chú nếu được gửi trực tiếp qua API

Scenario: SC-04 - Cập nhật ghi chú thành công
  Given người dùng có quyền "sales.order.adjust"
  And đơn hàng có lifecycle "completed"
  And ghi chú hiện hành là "Giao trước 16:00"
  And người dùng nhập ghi chú mới là "Giao sau 17:00"
  When người dùng chọn "Lưu"
  Then hệ thống tạo đúng một OrderAdjustment loại "order_note_update"
  And OrderAdjustment lưu previous_note là "Giao trước 16:00"
  And OrderAdjustment lưu updated_note là "Giao sau 17:00"
  And hệ thống hiển thị ghi chú hiện hành là "Giao sau 17:00"
  And timeline hiển thị activity thay đổi ghi chú

Scenario: SC-05 - Xóa ghi chú hiện hành
  Given người dùng có quyền "sales.order.adjust"
  And đơn hàng có lifecycle "completed"
  And đơn hàng đang có ghi chú
  And người dùng xóa toàn bộ nội dung ghi chú
  When người dùng chọn "Lưu"
  Then hệ thống tạo một OrderAdjustment lưu ghi chú trước và ghi chú sau rỗng theo policy
  And khu vực ghi chú hiển thị "Chưa có ghi chú"

Scenario: SC-06 - Không tạo thay đổi khi nội dung không đổi
  Given ghi chú hiện hành là "Giao trước 16:00"
  And người dùng nhập "  Giao trước 16:00  "
  When người dùng chọn "Lưu"
  Then hệ thống normalize nội dung thành "Giao trước 16:00"
  And hệ thống không tạo OrderAdjustment
  And hệ thống không tạo activity mới trong timeline

Scenario: SC-07 - Chặn lưu khi ghi chú đã được người khác cập nhật
  Given người dùng đã mở form với source order version 10
  And một người dùng khác đã cập nhật ghi chú làm source order version thành 11
  When người dùng chọn "Lưu" với source order version 10
  Then hệ thống trả kết quả conflict
  And hệ thống không ghi đè ghi chú của version 11
  And hệ thống cho phép người dùng tải lại nội dung hiện hành

Scenario: SC-08 - Chặn lưu khi điều kiện truy cập không còn hợp lệ
  Given người dùng đã mở form chỉnh sửa
  And quyền "sales.order.adjust" của người dùng đã bị thu hồi
  When người dùng chọn "Lưu"
  Then backend từ chối request
  And hệ thống không tạo OrderAdjustment
  And ghi chú hiện hành không thay đổi

Scenario: SC-09 - Không cho cập nhật field ngoài ghi chú
  Given người dùng có quyền "sales.order.adjust"
  And đơn hàng có lifecycle "completed"
  When request cập nhật chứa cả "order_note" và "customer_partner_id"
  Then hệ thống từ chối toàn bộ request
  And hệ thống không thay đổi ghi chú hoặc khách hàng
  And hệ thống không tạo OrderAdjustment

Scenario: SC-10 - Retry không tạo bản ghi trùng
  Given request cập nhật ghi chú đã được server commit
  And client không nhận được response
  When client gửi lại request với cùng idempotency key
  Then hệ thống trả lại kết quả của lần xử lý trước
  And hệ thống chỉ có một OrderAdjustment tương ứng
```

**References**

- `SalesOrder.order_note`: Ghi chú gốc được lưu tại checkout\.

- `OrderAdjustment`: Bản ghi authoritative của mỗi lần thay đổi ghi chú\.

- `adjustment_type = order_note_update`: Phân loại duy nhất của OrderAdjustment trong Phase 1\.

- `sales.order.adjust`: Permission chỉnh sửa ghi chú đơn hàng\.

- `source_order_version`: Dùng để phát hiện stale write và conflict\.

- `idempotency_key`: Dùng để ngăn tạo OrderAdjustment trùng khi retry\.

- SG\-08: Nơi hiển thị, chỉnh sửa ghi chú và xem timeline\.

## 4\.6 EP\-05 — Hủy đơn hàng sau bán

### 4\.6\.1 Overview

Epic này bao phủ việc hủy toàn bộ một SalesOrder chính thức sau khi giao dịch đã hoàn tất nhưng chưa còn khoản tiền thực thu ròng\.

EP\-05 chỉ áp dụng khi `SalesOrderSettlement.net_collected_amount = 0`\. Nếu `net_collected_amount > 0`, hệ thống không cho phép hủy đơn và phải chuyển người dùng sang EP\-06 theo quick flow **Trả toàn bộ \& hoàn tiền**\.

Các trường hợp sau không thuộc Epic này:

- Bỏ SalesOrderWorkingState chưa được lưu\.

- Hủy hoặc xóa mềm SalesOrderDraft\.

- Hủy một phần dòng hàng\.

- Trả một phần hoặc toàn bộ hàng hóa\.

- Đổi hàng sang sản phẩm khác\.

- Hoàn tiền cho khoản tiền đã thu\.

- Thu thêm hoặc cấn trừ công nợ phát sinh từ đổi/trả\.

    

Hủy đơn hàng không xóa giao dịch gốc\. Hệ thống phải:

- Giữ nguyên SalesOrder và toàn bộ commercial snapshot\.

- Tạo một SalesOrderCancellation độc lập\.

- Chuyển order lifecycle từ `completed` sang `cancelled`\.

- Ghi nhận lý do, người thực hiện và thời điểm hủy\.

- Yêu cầu hoàn nguyên khoản phải thu chưa được thu nếu có\.

- Yêu cầu hoàn nguyên tác động tồn kho nếu có\.

- Yêu cầu đảo applied pricing commitment nếu có\.

- Yêu cầu xử lý hóa đơn điện tử nếu có\.

- Cập nhật timeline, receipt và các read model liên quan\.

    

Việc hủy đơn là một business action không thể hoàn tác trực tiếp\. SalesOrder đã hủy không được mở lại hoặc chuyển trở về `completed`\. Nếu cần bán lại, người dùng phải tạo một SalesOrder mới\.

Cancellation business result và downstream processing là các trạng thái độc lập\. Khi việc hủy đã được commit thành công:

- SalesOrder được xem là đã hủy\.

- Receivable reversal có thể đang chờ Theme 6 xử lý\.

- Inventory reversal có thể đang chờ Theme 7 xử lý\.

- Pricing reversal có thể đang chờ Theme 4 xử lý\.

- E\-invoice handling có thể đang chờ Theme 8 xử lý\.

- Reporting projection có thể chưa cập nhật ngay\.

- Downstream failure không làm SalesOrder tự động quay lại `completed`\.

    

Hủy đơn phải sử dụng idempotency và optimistic concurrency\. Việc người dùng bấm nhiều lần, client gửi lại request hoặc mất kết nối không được tạo nhiều SalesOrderCancellation, order transition hoặc downstream impact trùng lặp\.

Epic kết thúc theo một trong các hướng:

- SalesOrder được hủy thành công\.

- Yêu cầu hủy bị chặn do điều kiện nghiệp vụ không hợp lệ\.

- Đơn đã có tiền thực thu và người dùng được chuyển sang EP\-06\.

- Người dùng hủy thao tác trước confirmation\.

- Xảy ra version conflict và người dùng phải tải lại dữ liệu\.

- Kết quả chưa xác định do timeout hoặc mất kết nối và hệ thống phải kiểm tra lại cancellation case\.

    

### 4\.6\.2 Business context

Trong vận hành thực tế, một SalesOrder đã hoàn tất nhưng chưa còn tiền thực thu có thể cần bị hủy toàn bộ vì:

- Nhân viên tạo nhầm giao dịch\.

- Đơn được tạo trùng\.

- Giao dịch sai đối tượng hoặc sai bản chất nghiệp vụ\.

- Giao dịch không thể tiếp tục trước khi phát sinh việc thu tiền thực tế\.

- Đơn vi phạm policy và cần được loại khỏi luồng vận hành\.

- Quản lý xác nhận rằng toàn bộ giao dịch phải được vô hiệu hóa\.

    

Hủy đơn khác với điều chỉnh và đổi/trả:

- Nếu chỉ cần sửa metadata không ảnh hưởng giao dịch, sử dụng EP\-04\.

- Nếu khách trả hàng hoặc cần hoàn lại tiền đã thu, sử dụng EP\-06\.

- Nếu SalesOrder không còn tiền thực thu và toàn bộ giao dịch cần bị vô hiệu hóa, sử dụng EP\-05\.

    

Không được sử dụng hủy đơn để sửa trực tiếp khách hàng, sản phẩm, số lượng, giá, chiết khấu, promotion hoặc thuế\. Việc hủy phải giữ nguyên bằng chứng về giao dịch ban đầu và tạo một nghiệp vụ đảo ngược có thể truy vết\.

Điều kiện tài chính cốt lõi của EP\-05 là:

- `SalesOrderSettlement.net_collected_amount = 0`\.

- `net_collected_amount` là giá trị authoritative do Sales Settlement cung cấp\.

- EP\-05 không tự tính lại giá trị này từ lịch sử hiển thị trên UI\.

- Payment transaction trạng thái `pending`, `processing` hoặc `uncertain` phải được xử lý ổn định trước khi xác nhận hủy\.

- Payment transaction đã void hoặc refund hợp lệ vẫn được giữ trong lịch sử và không bị xóa khi đơn bị hủy\.

    

Nếu `net_collected_amount > 0`, `PrecheckSalesOrderCancellation` phải trả blocker `PAYMENT_ALREADY_COLLECTED`\. UI phải:

- Giải thích rằng đơn đã có tiền thực thu nên không thể hủy trực tiếp\.

- Không tạo SalesOrderCancellation\.

- Không thay đổi order lifecycle\.

- Cung cấp CTA **Trả toàn bộ \& hoàn tiền**\.

- Mở EP\-06 với `entry_mode = full_return_from_cancel_attempt` khi người dùng tiếp tục\.

    

Một SalesOrder đã từng có collection nhưng hiện có `net_collected_amount = 0` sau các payment action hợp lệ vẫn có thể được xem xét hủy nếu không còn blocker khác\. EP\-05 không tạo thêm refund transaction trong trường hợp này\.

Trước khi cho phép hủy, hệ thống phải đánh giá tối thiểu:

- SalesOrder có tồn tại và thuộc tenant hiện tại hay không\.

- Người dùng có membership và permission hợp lệ hay không\.

- SalesOrder có thuộc store scope được phép thao tác hay không\.

- Order lifecycle hiện tại\.

- Lock status và kỳ vận hành liên quan\.

- Thời hạn hủy theo tenant policy\.

- Source order version\.

- Settlement và `net_collected_amount` hiện hành\.

- Payment transaction có trạng thái chưa ổn định hay không\.

- SalesOrder đã phát sinh cancellation khác hay chưa\.

- SalesOrder đã phát sinh ReturnExchangeOrder hay chưa\.

- Khoản phải thu chưa thu cần hoàn nguyên\.

- Inventory impact đã phát sinh hoặc có thể đã phát sinh\.

- Applied pricing commitment cần đảo hay không\.

- E\-invoice request hoặc chứng từ liên quan\.

- Trạng thái các integration impact trước đó\.

    

Quan hệ với ReturnExchangeOrder được xử lý như sau:

- ReturnExchangeOrder trạng thái `confirmed`, `processing` hoặc `completed` là blocker của cancellation\.

- ReturnExchangeOrder trạng thái `draft` phải được hủy hoặc resolve reservation trước khi tiếp tục\.

- ReturnExchangeOrder trạng thái `blocked`, `failed` hoặc `cancelled` không mặc định chặn; backend vẫn phải kiểm tra các reservation hoặc impact còn tồn tại\.

- `fully_returned` không được chuyển thành `cancelled`; người dùng tiếp tục xử lý trong EP\-06\.

    

Các lần adjustment metadata thuộc EP\-04 không mặc định chặn cancellation\. Toàn bộ adjustment history phải tiếp tục được giữ lại sau khi SalesOrder bị hủy\.

Kết quả precheck phải cho người dùng thấy rõ:

- Giá trị giao dịch gốc\.

- `net_collected_amount`\.

- Khoản phải thu chưa thu cần hoàn nguyên\.

- Dòng hàng và số lượng có thể cần hoàn nguyên tồn kho\.

- Pricing commitment cần đảo\.

- Tình trạng e\-invoice\.

- Blockers và warnings\.

- Các downstream impact dự kiến được tạo sau confirmation\.

    

Người dùng phải chọn reason code và có thể phải nhập reason note bổ sung\. Lý do hủy phải đủ rõ để phục vụ kiểm soát nội bộ, đối soát và audit\.

Nếu SalesOrder chưa thu tiền nhưng có khoản phải thu, Theme 5 phải yêu cầu Theme 6 đảo nghĩa vụ phải thu\. Theme 5 không trực tiếp sửa receivable ledger\.

Nếu SalesOrder đã làm thay đổi tồn kho, Theme 5 phải yêu cầu Theme 7 hoàn nguyên ảnh hưởng tồn kho\. Theme 5 không trực tiếp tạo hoặc sửa stock movement\.

Nếu SalesOrder có applied pricing commitment, Theme 5 phải yêu cầu Theme 4 xử lý `ReverseAppliedPricingForSalesOrder`\.

Nếu SalesOrder liên quan đến e\-invoice, Theme 5 phải kiểm tra eligibility với Theme 8 và tạo yêu cầu xử lý phù hợp\. Theme 5 không trực tiếp hủy, điều chỉnh hoặc thay thế hóa đơn điện tử\.

Nếu policy yêu cầu xử lý điều kiện e\-invoice trước khi hủy, precheck phải trả blocker\. Nếu policy cho phép hủy trước và xử lý e\-invoice sau, hệ thống phải hiển thị rõ trạng thái pending hoặc reconciliation required\.

Lifecycle của SalesOrderCancellation được sử dụng như sau:

- `PrecheckSalesOrderCancellation` chỉ kiểm tra điều kiện và không tạo business record\.

- Sau khi precheck trả `ready` hoặc warning được phép tiếp tục, `RequestSalesOrderCancellation` tạo SalesOrderCancellation trạng thái `requested`\.

- Khi người dùng xác nhận, `ConfirmSalesOrderCancellation` chuyển case sang `validating`\.

- Validation thành công chuyển case sang `confirmed`\.

- Khi command và downstream impacts bắt buộc đang được điều phối, case chuyển sang `processing`\.

- Khi order lifecycle đã được hủy và các local business requirements bắt buộc đã được ghi nhận, case chuyển sang `completed`\.

- Validation không hợp lệ chuyển case sang `blocked`\.

- Lỗi kỹ thuật trước khi business result được commit chuyển case sang `failed`\.

- Người dùng hủy case trước confirmation chuyển case sang `cancelled`\.

    

### 4\.6\.3 In scope

- Khởi tạo flow hủy từ chi tiết một SalesOrder chính thức\.

- Hiển thị action Hủy đơn hàng khi người dùng có permission và SalesOrder chưa bị hủy\.

- Cho phép action mở precheck kể cả khi có khả năng đơn đã thu tiền để hệ thống trả đúng blocker và CTA chuyển EP\-06\.

- Kiểm tra tenant, membership, permission và store scope\.

- Thực hiện `PrecheckSalesOrderCancellation`\.

- Kiểm tra order lifecycle hiện hành\.

- Chặn SalesOrder đã `cancelled`\.

- Kiểm tra lock status\.

- Chặn hoặc yêu cầu permission đặc biệt khi SalesOrder đang locked\.

- Kiểm tra thời hạn hủy theo tenant policy\.

- Kiểm tra kỳ vận hành, kỳ kế toán hoặc kỳ kiểm soát nếu contract liên quan có sẵn\.

- Kiểm tra source order version\.

- Kiểm tra SalesOrderCancellation đã tồn tại\.

- Khôi phục cancellation case đang `requested`, `validating`, `confirmed` hoặc `processing` thay vì tạo case trùng\.

- Kiểm tra ReturnExchangeOrder liên quan\.

- Chặn khi có ReturnExchangeOrder `confirmed`, `processing` hoặc `completed`\.

- Yêu cầu hủy hoặc resolve ReturnExchangeOrder `draft` và reservation liên quan\.

- Kiểm tra SalesOrderSettlement authoritative\.

- Đọc `net_collected_amount`\.

- Chặn cancellation khi `net_collected_amount > 0`\.

- Trả blocker code `PAYMENT_ALREADY_COLLECTED`\.

- Cung cấp action chuyển sang EP\-06\.

- Truyền SalesOrder context sang `full_return_from_cancel_attempt`\.

- Kiểm tra payment transaction đang `pending`, `processing` hoặc `uncertain`\.

- Chặn hoặc yêu cầu xử lý trước khi settlement chưa ổn định\.

- Xác định khoản phải thu chưa thu cần hoàn nguyên\.

- Kiểm tra inventory impact hiện hành\.

- Xác định dòng hàng và số lượng cần yêu cầu hoàn nguyên tồn kho\.

- Kiểm tra applied pricing commitment\.

- Xác định có cần `ReverseAppliedPricingForSalesOrder` hay không\.

- Kiểm tra e\-invoice impact và trạng thái chứng từ liên quan\.

- Gọi Theme 8 để kiểm tra eligibility hoặc hướng xử lý khi contract hỗ trợ\.

- Trả blockers, warnings và impact summary\.

- Hiển thị rõ đây là hành động hủy toàn bộ SalesOrder\.

- Hiển thị mã đơn, customer snapshot, tổng giá trị và thời điểm giao dịch\.

- Hiển thị `net_collected_amount`\.

- Hiển thị khoản phải thu chưa thu cần hoàn nguyên\.

- Hiển thị tác động tồn kho dự kiến\.

- Hiển thị pricing reversal dự kiến\.

- Hiển thị e\-invoice status\.

- Không sử dụng confirmation chung chung chỉ có nội dung “Bạn có chắc không?”\.

- Thực hiện `RequestSalesOrderCancellation` sau khi precheck cho phép tiếp tục và người dùng bắt đầu flow chính thức\.

- Tạo SalesOrderCancellation trạng thái `requested`\.

- Lưu source SalesOrder, source version, actor và precheck context\.

- Yêu cầu người dùng chọn reason code\.

- Cho phép nhập reason note\.

- Kiểm tra reason code còn hoạt động và phù hợp\.

- Yêu cầu reason note khi reason code hoặc tenant policy quy định\.

- Cho phép tenant cấu hình danh mục reason code cơ bản\.

- Hiển thị confirmation summary trước khi xác nhận\.

- Mô tả rõ SalesOrder sẽ bị hủy và không thể mở lại\.

- Mô tả rõ giao dịch gốc và payment history vẫn được giữ để truy vết\.

- Mô tả rõ không phát sinh refund từ cancellation\.

- Mô tả rõ receivable, inventory, pricing và e\-invoice impacts dự kiến\.

- Thực hiện `ConfirmSalesOrderCancellation`\.

- Yêu cầu idempotency key cho request và confirmation\.

- Trả cùng business result khi cùng idempotency key và cùng payload được gửi lại\.

- Trả conflict khi cùng idempotency key nhưng payload khác\.

- Sử dụng expected order version và expected cancellation version\.

- Validate lại permission, lifecycle, lock status, source version, settlement, return/exchange conflict và impact eligibility trước commit\.

- Validate lại `net_collected_amount = 0` tại confirmation time\.

- Nếu `net_collected_amount` chuyển thành lớn hơn 0 sau precheck, chặn confirmation và cung cấp action chuyển EP\-06\.

- Chuyển cancellation từ `requested` sang `validating`\.

- Chuyển cancellation sang `confirmed` khi validation thành công\.

- Gửi command nội bộ `CancelSalesOrder`\.

- Chuyển SalesOrder lifecycle từ `completed` sang `cancelled`\.

- Không gọi trực tiếp `CancelSalesOrder` từ UI\.

- Không xóa hoặc ghi đè commercial snapshot\.

- Không xóa SalesOrderLine\.

- Không xóa settlement hoặc payment history\.

- Không tạo SalesPaymentTransaction loại refund từ cancellation\.

- Không xóa adjustment, receipt hoặc timeline history\.

- Lưu cancellation snapshot gồm:

    - Reason code\.

    - Reason note\.

    - Actor\.

    - Thời điểm request và confirmation\.

    - Source order version\.

    - Tổng giá trị đơn gốc\.

    - `net_collected_amount` tại confirmation\.

    - Khoản phải thu cần hoàn nguyên\.

    - Inventory impact summary\.

    - Pricing reversal summary\.

    - E\-invoice impact summary\.

    - Correlation và causation context\.

        

- Tạo `ReceivableImpactRequest` khi còn khoản phải thu chưa thu cần đảo\.

- Không tạo receivable reversal nếu không còn khoản phải thu\.

- Không trực tiếp sửa receivable ledger\.

- Tạo `InventoryImpactRequest` khi SalesOrder đã hoặc có thể đã ảnh hưởng tồn kho\.

- Ghi source order, cancellation reference, dòng hàng, product, product unit, quantity và idempotency context\.

- Không trực tiếp tạo hoặc reverse stock movement\.

- Không tạo inventory reversal trùng\.

- Gọi `ReverseAppliedPricingForSalesOrder` khi applied pricing commitment cần hoàn nguyên\.

- Không trực tiếp sửa pricing master hoặc applied pricing records của Theme 4\.

- Tạo `EInvoiceImpactRequest` khi SalesOrder có e\-invoice request hoặc chứng từ liên quan\.

- Không coi impact request là e\-invoice đã được xử lý\.

- Tạo event hoặc integration command phục vụ Reporting\.

- Commit business decision và durable impact/outbox record thuộc cùng domain trong local transaction của domain đó\.

- Không sử dụng distributed transaction giữa các domains hoặc themes\.

- Phân biệt:

    - Cancellation business status\.

    - Receivable impact status\.

    - Inventory impact status\.

    - Pricing reversal status\.

    - E\-invoice impact status\.

    - Delivery status của từng integration command\.

        

- Không rollback cancellation chỉ vì downstream integration thất bại sau khi business result đã commit\.

- Cho phép technical retry đối với impact delivery đủ điều kiện\.

- Retry phải idempotent và không tạo business effect trùng\.

- Chuyển integration sang `reconciliation_required` khi không thể tự động xử lý\.

- Hỗ trợ truy vấn lại cancellation result khi client timeout hoặc mất kết nối\.

- Nếu cancellation đã tồn tại, trả lại case hiện hành thay vì tạo case mới\.

- Thêm activity vào `SalesOrderTimelineView`\.

- Timeline phải ghi nhận tối thiểu:

    - Cancellation requested\.

    - Cancellation validating\.

    - Cancellation confirmed\.

    - SalesOrder cancelled\.

    - Reason và actor\.

    - Receivable reversal requested\.

    - Inventory reversal requested\.

    - Pricing reversal requested\.

    - E\-invoice handling requested\.

    - Integration accepted, rejected, failed hoặc reconciliation required\.

        

- Không cho phép sửa hoặc xóa cancellation activity\.

- Cập nhật `SalesOrderListView` và `SalesOrderDetailView` để hiển thị SalesOrder đã hủy\.

- Tiếp tục hiển thị commercial snapshot gốc\.

- Hiển thị cancellation summary gồm:

    - Reason\.

    - Actor\.

    - Thời điểm hủy\.

    - Receivable impact status\.

    - Inventory impact status\.

    - Pricing reversal status\.

    - E\-invoice impact status\.

        

- Giữ lại SalesReceipt đã tạo\.

- Hiển thị nhãn Đã hủy khi xem receipt của SalesOrder đã hủy\.

- Cho phép xem, in hoặc chia sẻ lại receipt theo permission\.

- Không làm mất receipt version đã tạo trước cancellation\.

- Có thể tạo receipt version mới thể hiện trạng thái hủy nếu receipt policy yêu cầu\.

- Hiển thị màn kết quả hủy đơn gồm:

    - Mã đơn hàng\.

    - Trạng thái Đã hủy\.

    - Reason và actor\.

    - Tổng giá trị giao dịch gốc\.

    - Trạng thái hoàn nguyên công nợ\.

    - Trạng thái hoàn nguyên tồn kho\.

    - Trạng thái pricing reversal\.

    - Trạng thái xử lý e\-invoice\.

        

- Cung cấp action tiếp theo:

    - Xem chi tiết đơn hàng\.

    - Xem trạng thái xử lý liên quan\.

    - Tạo đơn hàng mới\.

    - Quay lại danh sách đơn hàng\.

        

- Ghi audit log cho:

    - Mở flow hủy\.

    - Precheck\.

    - Blocked action\.

    - Chuyển sang EP\-06\.

    - Request cancellation\.

    - Confirm cancellation\.

    - Version conflict\.

    - Technical retry\.

    - Reconciliation action\.

        

### 4\.6\.4 Out of scope

- Bỏ SalesOrderWorkingState chưa được lưu\.

- Hủy hoặc xóa mềm SalesOrderDraft; thuộc EP\-01\.

- Hủy một phần SalesOrder\.

- Hủy một hoặc một số SalesOrderLine\.

- Giảm số lượng của dòng hàng đã bán\.

- Sửa customer, product, quantity, product unit, price, discount, promotion, tax hoặc monetary summary\.

- Điều chỉnh metadata không ảnh hưởng giao dịch; thuộc EP\-04\.

- Trả hàng hoặc đổi hàng; thuộc EP\-06\.

- Trả toàn bộ đơn đã có tiền thực thu; thuộc EP\-06\.

- Hoàn tiền đã thu; thuộc EP\-06 và Sales Settlement\.

- Thu thêm hoặc quyết toán chênh lệch\.

- Cấn trừ công nợ từ nghiệp vụ trả hàng\.

- Hủy phần còn lại sau khi đã phát sinh ReturnExchangeOrder không tương thích\.

- Tạo hoặc chỉnh sửa ReturnExchangeOrder\.

- Mở lại SalesOrder đã hủy\.

- Chuyển SalesOrder đã hủy về `completed`\.

- Xóa cứng SalesOrder\.

- Xóa commercial snapshot\.

- Xóa hoặc sửa SalesOrderCancellation đã xác nhận\.

- Xóa payment hoặc refund transaction đã ghi nhận\.

- Sửa trực tiếp SalesOrderSettlement\.

- Void payment hoặc manual correction payment\.

- Tự động chuyển tiền qua ngân hàng hoặc payment gateway\.

- Đối soát sao kê ngân hàng\.

- Xử lý chargeback\.

- Hoàn tiền sang ví hoặc số dư khách hàng\.

- Thu công nợ sau bán\.

- Phân bổ payment hoặc refund cho nhiều đơn\.

- Trực tiếp sửa receivable ledger\.

- Trực tiếp tạo hoặc reverse stock movement\.

- Quản lý giá vốn của hàng hoàn nhập\.

- Kiểm định chất lượng hàng khách trả\.

- Phát hành, ký số, điều chỉnh, thay thế hoặc hủy e\-invoice\.

- Quyết định nghiệp vụ pháp lý chi tiết của e\-invoice\.

- Hạch toán kế toán chi tiết cho cancellation\.

- Mở hoặc đóng kỳ kế toán\.

- Workflow phê duyệt hủy nhiều cấp trong Phase 1\.

- Phê duyệt đặc biệt theo ngưỡng giá trị khi chưa có approval domain riêng\.

- Quản lý reason catalog nâng cao ngoài cấu hình cơ bản\.

- Đính kèm chứng từ giải trình nâng cao\.

- Xử lý fulfillment, vận chuyển hoặc thu hồi hàng từ khách\.

- Báo cáo quản trị chuyên sâu về tỷ lệ hủy\.

- Reconciliation nghiệp vụ chi tiết bên trong Theme 4, Theme 6, Theme 7 hoặc Theme 8\.

    

### 4\.6\.5 Entry points

Người dùng có thể bắt đầu EP\-05 từ:

- Chi tiết SalesOrder trong EP\-03 → action **Hủy đơn hàng**\.

- Menu thao tác của SalesOrder\.

- Notification hoặc task yêu cầu kiểm tra giao dịch sai → mở SalesOrder → chọn Hủy đơn hàng\.

- Cancellation case trạng thái `requested`, `validating`, `confirmed` hoặc `processing` → mở lại để tiếp tục hoặc theo dõi\.

- Màn blocked hoặc conflict → tải lại dữ liệu và thực hiện precheck mới\.

    

Trước khi hiển thị hoặc kích hoạt action Hủy đơn hàng, hệ thống phải xác định được:

- Tenant hiện tại\.

- Membership đang hoạt động\.

- Permission `sales.order.cancel`\.

- Store scope phù hợp\.

- Đối tượng là SalesOrder chính thức\.

- SalesOrder chưa ở lifecycle `cancelled`\.

    

Action Hủy đơn hàng có thể vẫn được hiển thị khi chưa biết đầy đủ eligibility\. Eligibility authoritative chỉ được xác định bởi `PrecheckSalesOrderCancellation`\.

Khi người dùng chọn action:

- Hệ thống thực hiện `PrecheckSalesOrderCancellation`\.

- Precheck không tạo SalesOrderCancellation\.

- Precheck không thay đổi SalesOrder\.

- Precheck không tạo refund, receivable, inventory, pricing hoặc e\-invoice impact\.

- Nếu kết quả `ready` hoặc warning được phép tiếp tục, người dùng có thể bắt đầu cancellation case\.

- Khi người dùng tiếp tục, hệ thống thực hiện `RequestSalesOrderCancellation`\.

- `RequestSalesOrderCancellation` tạo hoặc trả lại SalesOrderCancellation trạng thái `requested`\.

    

Khi `net_collected_amount > 0`, hệ thống phải:

- Trả blocker `PAYMENT_ALREADY_COLLECTED`\.

- Không tạo SalesOrderCancellation mới\.

- Không thay đổi order lifecycle\.

- Giải thích rằng đơn đã có tiền thực thu nên phải xử lý bằng trả hàng\.

- Hiển thị CTA **Trả toàn bộ \& hoàn tiền**\.

- Khi người dùng chọn CTA, mở EP\-06 với:

    - `entry_mode = full_return_from_cancel_attempt`\.

    - `source_sales_order_id`\.

    - `source_action = sales_order_cancellation_precheck`\.

    - `source_blocker_code = PAYMENT_ALREADY_COLLECTED`\.

    - Correlation context phù hợp\.

        

Khi precheck trả blocker khác, hệ thống phải:

- Không tạo SalesOrderCancellation nếu cancellation case chưa tồn tại\.

- Không thay đổi order lifecycle\.

- Không tạo downstream impact\.

- Hiển thị blocker cụ thể\.

- Hướng dẫn flow phù hợp:

    - EP\-04 nếu chỉ cần điều chỉnh metadata\.

    - EP\-06 nếu cần trả hoặc đổi hàng\.

    - Sales Settlement nếu payment state chưa ổn định\.

    - Theme 6 nếu cần xử lý receivable conflict\.

    - Theme 8 nếu cần xử lý điều kiện e\-invoice\.

        

Trước khi confirmation, hệ thống phải kiểm tra lại:

- SalesOrder vẫn tồn tại và thuộc tenant hiện tại\.

- Người dùng vẫn có permission\.

- Store scope vẫn hợp lệ\.

- Order lifecycle vẫn là `completed`\.

- Lock status và kỳ vận hành chưa thay đổi theo hướng bị chặn\.

- Source order version vẫn khớp\.

- Không có cancellation case cạnh tranh\.

- Không phát sinh ReturnExchangeOrder mới gây xung đột\.

- Settlement vẫn ổn định\.

- `net_collected_amount = 0`\.

- Receivable impact summary vẫn đúng\.

- Inventory impact summary vẫn đúng\.

- Pricing reversal eligibility vẫn đúng\.

- E\-invoice eligibility vẫn đúng\.

- Reason code và reason note hợp lệ\.

- Idempotency key và expected versions hợp lệ\.

    

Confirmation phải mô tả rõ:

- Toàn bộ SalesOrder sẽ bị hủy\.

- Commercial snapshot và transaction history vẫn được giữ\.

- SalesOrder không thể được mở lại\.

- Cancellation không tạo refund transaction\.

- Khoản phải thu chưa thu sẽ được yêu cầu hoàn nguyên nếu có\.

- Tồn kho sẽ được yêu cầu hoàn nguyên nếu có\.

- Pricing commitment sẽ được yêu cầu đảo nếu có\.

- E\-invoice có thể cần xử lý riêng\.

- Downstream impacts có thể tiếp tục pending sau khi SalesOrder đã hủy\.

    

EP\-05 kết thúc khi:

- SalesOrderCancellation và SalesOrder cancellation đã hoàn tất\.

- Người dùng xem màn kết quả hoặc quay lại chi tiết SalesOrder đã hủy\.

- Cancellation đang `processing` và người dùng theo dõi các impact liên quan\.

- Yêu cầu hủy bị blocked và người dùng quay lại chi tiết SalesOrder\.

- Đơn đã có tiền thực thu và người dùng chuyển sang EP\-06\.

- Xảy ra version conflict và người dùng phải tải lại\.

- Kết quả chưa xác định và hệ thống tiếp tục truy vấn cancellation case theo idempotency hoặc correlation context\.

- Người dùng hủy thao tác trước confirmation\.

### 4\.6\.6 User stories

#### 4\.6\.6\.1 User story map

|User story|As user|I want to|So that|Notes|
|---|---|---|---|---|
|US\-01 — Kiểm tra điều kiện và tác động hủy đơn|Người dùng có quyền hủy đơn|Xem blocker, warning và các tác động dự kiến trước khi hủy|Tôi có thể biết đơn có được phép hủy hay phải chuyển sang nghiệp vụ khác|Đơn có `net_confirmed_collection > 0` phải chuyển sang EP\-06|
|US\-02 — Xác định lý do hủy|Người dùng có quyền hủy đơn|Chọn lý do và cung cấp diễn giải cần thiết|Cancellation có đủ căn cứ để xác nhận và truy vết|Không có phương án hoàn tiền trong EP\-05|
|US\-03 — Xác nhận hủy toàn bộ đơn hàng|Người dùng có quyền hủy đơn|Xác nhận hủy một SalesOrder chưa có tiền thực thu ròng|Giao dịch được vô hiệu hóa có kiểm soát nhưng dữ liệu gốc vẫn được bảo toàn|`ConfirmSalesOrderCancellation` phải kiểm tra lại `net_confirmed_collection = 0`|
|US\-04 — Theo dõi các tác động hoàn nguyên|Quản lý cửa hàng, Kế toán hoặc Người kiểm soát|Xem trạng thái hoàn nguyên công nợ chưa thu, tồn kho, pricing và hóa đơn điện tử|Tôi có thể xử lý lỗi hoặc nội dung cần đối soát sau khi đơn đã hủy|Không xử lý refund tiền đã thu trong EP\-05|
|US\-05 — Xem kết quả và lịch sử hủy đơn|Người dùng có quyền|Xem cancellation summary và timeline của đơn đã hủy|Tôi có thể truy vết nguyên nhân, người thực hiện và kết quả hoàn nguyên|Commercial snapshot và toàn bộ lịch sử giao dịch gốc vẫn được giữ lại|



#### 4\.6\.6\.2 US\-01 — Kiểm tra điều kiện và tác động hủy đơn

**Business context**

Một SalesOrder đã hoàn tất chỉ được hủy trong EP\-05 khi chưa còn khoản tiền thực thu ròng cần hoàn cho khách\. Nếu giao dịch đã có tiền thực thu ròng, bản chất nghiệp vụ là trả hàng và quyết toán giá trị; hệ thống phải chuyển người dùng sang EP\-06 thay vì để cancellation kiêm nhiệm refund\.

Trước khi nhập lý do và xác nhận, hệ thống phải kiểm tra trạng thái đơn, settlement hiện hành, các nghiệp vụ cạnh tranh và các tác động hoàn nguyên dự kiến đối với khoản phải thu chưa thu, tồn kho, pricing commitment, hóa đơn điện tử cùng báo cáo\.

User Story bắt đầu khi người dùng chọn Hủy đơn hàng từ chi tiết một SalesOrder chính thức và kết thúc khi precheck trả `ready`, `warning` hoặc `blocked` mà chưa chuyển order lifecycle sang `cancelled`\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền hủy đơn|Xem điều kiện, blocker, warning và tác động dự kiến trước khi hủy|Tôi có thể biết đơn được hủy trong EP\-05 hay phải chuyển sang EP\-06|



**Functional requirements**

- FR\-01: Hệ thống phải thực hiện `PrecheckSalesOrderCancellation` từ chi tiết một SalesOrder chính thức\.

- FR\-02: Precheck phải kiểm tra tenant, membership, permission, store scope, order lifecycle, lock status, source version, thời hạn hủy và kỳ vận hành nếu áp dụng\.

- FR\-03: Precheck phải kiểm tra SalesOrderCancellation khác và các ReturnExchangeOrder liên quan để phát hiện nghiệp vụ cạnh tranh\.

- FR\-04: Precheck phải lấy Sales Settlement authoritative để xác định tổng tiền đã thu, đã void, đã hoàn và `net_confirmed_collection`\.

- FR\-05: Khi `net_confirmed_collection > 0`, hệ thống phải trả blocker `PAYMENT_ALREADY_COLLECTED` và cung cấp action chuyển sang EP\-06 với entry mode `full_return_from_cancel_attempt`\.

- FR\-06: Khi `net_confirmed_collection = 0`, hệ thống phải tổng hợp khoản phải thu chưa thu cần hoàn nguyên, inventory impact, pricing commitment, e\-invoice impact và reporting impact dự kiến\.

- FR\-07: Hệ thống phải trả `ready`, `warning` hoặc `blocked` cùng blocker codes, warnings và impact summary mà không tạo cancellation hoặc downstream impact chính thức\.

    

**Business rules**

- BR\-01: Chỉ SalesOrder lifecycle `completed` mới đủ điều kiện xem xét hủy toàn bộ\.

- BR\-02: SalesOrder lifecycle `cancelled` không được tạo cancellation mới\.

- BR\-03: `net_confirmed_collection = total_confirmed_collection - total_confirmed_refund - total_confirmed_void`; cancellation chỉ được tiếp tục khi giá trị này bằng 0\.

- BR\-04: Đơn đã từng thu tiền nhưng các khoản thu đã được void hoặc hoàn đầy đủ, làm `net_confirmed_collection = 0`, có thể tiếp tục được xem xét hủy nếu các điều kiện khác hợp lệ\.

- BR\-05: ReturnExchangeOrder trạng thái `confirmed`, `processing` hoặc `completed` là hard blocker; trạng thái `draft` phải được hủy hoặc giải phóng reservation trước khi tiếp tục\.

- BR\-06: SalesOrderCancellation trạng thái `requested` hoặc `validating` là operation cạnh tranh cần được khôi phục hoặc resolve; trạng thái `blocked`, `failed` hoặc `cancelled` không mặc định chặn\.

- BR\-07: Precheck không thay đổi order lifecycle, không tạo refund transaction và không tạo impact request chính thức\.

    

**Acceptance criteria**

- AC\-01: Người dùng hợp lệ nhận được kết quả precheck và impact summary phù hợp với trạng thái hiện hành\.

- AC\-02: Đơn có `net_confirmed_collection > 0` bị blocked với action chuyển sang `Trả toàn bộ & hoàn tiền`\.

- AC\-03: Đơn có `net_confirmed_collection = 0` có thể tiếp tục nếu không còn blocker khác\.

- AC\-04: Impact summary hiển thị riêng khoản phải thu chưa thu cần hoàn nguyên, tồn kho, pricing, e\-invoice và reporting\.

- AC\-05: Đơn đã hủy hoặc có nghiệp vụ đổi/trả gây xung đột bị blocked\.

- AC\-06: Blocker và warning có mã, nội dung cùng hướng xử lý phù hợp\.

- AC\-07: Precheck không tạo SalesOrderCancellation đã xác nhận, refund transaction hoặc downstream impact chính thức\.

    

**Edge cases**

- EC\-01: Một payment được ghi nhận sau khi màn hủy đã mở; precheck dùng settlement mới nhất và chuyển sang blocker thanh toán\.

- EC\-02: Một payment vừa được void hoặc hoàn đầy đủ; precheck tính lại `net_confirmed_collection` trước khi cho tiếp tục\.

- EC\-03: ReturnExchangeOrder được confirmed trong lúc precheck đang chạy; kết quả phải phản ánh conflict hiện hành\.

- EC\-04: Inventory impact trước đó đang `uncertain`; hệ thống không tự giả định đã trừ hoặc chưa trừ kho\.

- EC\-05: E\-invoice service không phản hồi; precheck không coi kết quả là ready nếu tenant policy yêu cầu xác minh\.

- EC\-06: Người dùng mất permission trong lúc precheck; hệ thống trả no\-permission và không tiếp tục\.

- EC\-07: Read model settlement đang chậm; precheck phải dùng Sales Settlement authoritative thay vì projection cũ\.

    

**Scenarios**

```Gherkin
Feature: Kiểm tra điều kiện và tác động hủy đơn

Scenario: SC-01 — Đơn chưa có tiền thực thu ròng
  Given người dùng có permission sales.order.cancel
  And SalesOrder lifecycle là completed
  And net confirmed collection bằng 0
  And không có nghiệp vụ đổi trả gây xung đột
  When hệ thống thực hiện PrecheckSalesOrderCancellation
  Then kết quả là ready hoặc warning
  And hệ thống trả impact summary
  And order lifecycle chưa thay đổi

Scenario: SC-02 — Đơn đã có tiền thực thu
  Given SalesOrder lifecycle là completed
  And net confirmed collection lớn hơn 0
  When hệ thống thực hiện PrecheckSalesOrderCancellation
  Then kết quả là blocked
  And blocker code là PAYMENT_ALREADY_COLLECTED
  And hệ thống cung cấp action "Trả toàn bộ & hoàn tiền"
  And không tạo SalesOrderCancellation đã xác nhận

Scenario: SC-03 — Khoản thu đã được hoàn hoặc void đầy đủ
  Given SalesOrder đã từng có confirmed collection
  And toàn bộ khoản thu đã được refund hoặc void hợp lệ
  And net confirmed collection bằng 0
  When hệ thống thực hiện precheck
  Then hệ thống không chặn chỉ vì lịch sử đã từng có payment
  And tiếp tục kiểm tra các điều kiện hủy còn lại

Scenario: SC-04 — Đơn đã bị hủy
  Given SalesOrder lifecycle là cancelled
  When người dùng chọn Hủy đơn hàng
  Then precheck trả blocked
  And hệ thống hướng người dùng xem cancellation hiện có
  And không tạo cancellation mới

Scenario: SC-05 — Có phiếu đổi trả đã xác nhận
  Given SalesOrder có ReturnExchangeOrder status confirmed
  When hệ thống thực hiện precheck
  Then kết quả là blocked
  And blocker yêu cầu tiếp tục xử lý trong EP-06

Scenario: SC-06 — Có phiếu đổi trả draft
  Given SalesOrder có ReturnExchangeOrder status draft
  And draft đang giữ reservation
  When hệ thống thực hiện precheck
  Then kết quả là blocked
  And hệ thống yêu cầu hủy hoặc resolve draft trước khi tiếp tục

Scenario: SC-07 — Đơn còn khoản phải thu chưa thu
  Given net confirmed collection bằng 0
  And outstanding receivable lớn hơn 0
  When hệ thống tính impact summary
  Then hệ thống hiển thị khoản phải thu cần hoàn nguyên
  And không trình bày khoản đó như tiền cần refund cho khách
```

**References**

- Domains:

    - Post\-sale Operations

    - Sales Order Lifecycle

    - Sales Settlement

- Data:

    - `SalesOrder`

    - `SalesOrderCancellation`

    - `SalesOrderSettlement`

    - `SalesPaymentTransaction`

    - `ReturnExchangeOrder`

    - `BlockerSnapshot`

    - `CancellationImpactSummary`

- Commands / queries / events:

    - `PrecheckSalesOrderCancellation`

    - `GetSalesOrderSettlement`

    - `GetReturnExchangeOrdersBySalesOrder`

    - Entry contract tới `StartReturnExchange`

- Permissions:

    - `sales.order.cancel`

    - `sales.order.view`

- External dependencies:

    - Theme 1 — Tenant, membership, permission và store scope

    - Theme 4 — Pricing commitment context

    - Theme 6 — Receivable impact context

    - Theme 7 — Inventory impact context

    - Theme 8 — E\-invoice eligibility

    - Platform Audit — Precheck, blocked action và actor context

        

#### 4\.6\.6\.3 US\-02 — Xác định lý do hủy

**Business context**

Sau khi precheck cho phép tiếp tục, người dùng phải xác định lý do hủy để tạo căn cứ nghiệp vụ và audit\. EP\-05 không yêu cầu chọn phương án hoàn tiền vì điều kiện vào flow đã bảo đảm không còn khoản tiền thực thu ròng cần refund\.

Trước confirmation, hệ thống vẫn phải hiển thị rõ rằng settlement đã được kiểm tra và `net_confirmed_collection = 0`\. Nếu settlement thay đổi, người dùng phải thực hiện lại precheck\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền hủy đơn|Chọn lý do hủy và cung cấp diễn giải khi cần|Cancellation có đủ căn cứ để xác nhận và truy vết|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị các reason code hủy đơn đang hoạt động và phù hợp với tenant\.

- FR\-02: Hệ thống phải cho phép nhập reason note bổ sung\.

- FR\-03: Hệ thống phải yêu cầu reason note khi reason code là Khác hoặc tenant policy yêu cầu\.

- FR\-04: Hệ thống phải hiển thị cancellation summary gồm order identity, customer context, total amount và impact summary mới nhất\.

- FR\-05: Hệ thống phải hiển thị điều kiện settlement đã kiểm tra với `net_confirmed_collection = 0`\.

- FR\-06: Hệ thống phải giữ source order version, settlement version hoặc precheck reference cần thiết cho bước xác nhận\.

- FR\-07: Action xác nhận chỉ khả dụng khi reason hợp lệ, precheck chưa stale và không còn blocker\.

    

**Business rules**

- BR\-01: `reason_code` là bắt buộc với mọi SalesOrderCancellation\.

- BR\-02: Reason note là optional mặc định nhưng bắt buộc với reason code hoặc tenant policy yêu cầu giải trình\.

- BR\-03: EP\-05 không có `refund_treatment`, refund intent hoặc payment method hoàn tiền\.

- BR\-04: Reason code phải còn hoạt động tại thời điểm confirmation\.

- BR\-05: Cancellation input phải gắn với cùng SalesOrder, source version và precheck context\.

- BR\-06: Khi settlement hoặc source order thay đổi, precheck cũ trở thành stale và không được dùng để xác nhận\.

- BR\-07: Hủy flow ở bước này không tạo SalesOrderCancellation confirmed, không thay đổi order lifecycle và không tạo downstream impact\.

    

**Acceptance criteria**

- AC\-01: Người dùng phải chọn reason code hợp lệ trước khi xác nhận\.

- AC\-02: Reason note được yêu cầu đúng theo reason code và tenant policy\.

- AC\-03: Màn xác nhận hiển thị rõ `net_confirmed_collection = 0`\.

- AC\-04: Không hiển thị lựa chọn hoàn ngay, hoàn sau hoặc không cần hoàn\.

- AC\-05: Precheck stale làm action xác nhận bị chặn và yêu cầu kiểm tra lại\.

- AC\-06: Cancellation summary phản ánh đúng order và impact context mới nhất\.

- AC\-07: Hủy flow không làm thay đổi SalesOrder hoặc tạo business impact\.

    

**Edge cases**

- EC\-01: Reason code vừa bị vô hiệu hóa; hệ thống yêu cầu chọn lại\.

- EC\-02: Reason note chỉ chứa khoảng trắng; hệ thống coi là rỗng\.

- EC\-03: Một payment mới được ghi nhận sau precheck; confirmation bị chặn và chuyển hướng sang EP\-06\.

- EC\-04: Payment cũ vừa được void làm settlement version thay đổi; hệ thống yêu cầu precheck lại dù net collection vẫn bằng 0\.

- EC\-05: Source order version thay đổi do adjustment metadata; hệ thống yêu cầu tải lại summary\.

- EC\-06: Người dùng mất permission trước confirmation; hệ thống chặn\.

- EC\-07: Impact summary thay đổi do downstream state mới; hệ thống hiển thị lại summary trước khi cho xác nhận\.

    

**Scenarios**

```Gherkin
Feature: Xác định lý do hủy

Scenario: SC-01 — Chọn lý do hợp lệ
  Given precheck còn hiệu lực
  And net confirmed collection bằng 0
  When người dùng chọn một reason code đang hoạt động
  Then reason code được gắn vào cancellation input
  And người dùng có thể tiếp tục khi các điều kiện khác hợp lệ

Scenario: SC-02 — Lý do Khác yêu cầu mô tả
  Given người dùng chọn reason code OTHER
  And reason note đang để trống
  When người dùng chọn tiếp tục
  Then hệ thống chặn
  And yêu cầu nhập reason note

Scenario: SC-03 — Reason note chỉ có khoảng trắng
  Given tenant policy yêu cầu reason note
  When người dùng nhập reason note chỉ gồm khoảng trắng
  Then hệ thống coi reason note là rỗng
  And không cho xác nhận

Scenario: SC-04 — Không hiển thị phương án hoàn tiền
  Given precheck xác nhận net confirmed collection bằng 0
  When người dùng mở bước lý do hủy
  Then hệ thống không hiển thị refund treatment
  And không yêu cầu refund intent hoặc payment method

Scenario: SC-05 — Settlement thay đổi sau precheck
  Given precheck sử dụng settlement version 5
  And settlement đã chuyển sang version 6
  When người dùng mở bước xác nhận
  Then precheck được đánh dấu stale
  And hệ thống yêu cầu kiểm tra lại trước khi xác nhận

Scenario: SC-06 — Phát sinh tiền thực thu mới
  Given precheck trước đó có net confirmed collection bằng 0
  And một payment mới vừa được confirmed
  When người dùng tiếp tục xác nhận
  Then hệ thống chặn
  And hiển thị action chuyển sang "Trả toàn bộ & hoàn tiền"

Scenario: SC-07 — Hủy flow
  Given người dùng đã nhập reason hợp lệ
  When người dùng chọn Hủy thao tác
  Then hệ thống quay lại chi tiết SalesOrder
  And không thay đổi order lifecycle
  And không tạo downstream impact
```

**References**

- Domains:

    - Post\-sale Operations

    - Sales Settlement

- Data:

    - Cancellation reason catalog

    - `CancellationImpactSummary`

    - Source order version

    - Settlement version

    - Precheck reference

- Commands / queries / events:

    - `PrecheckSalesOrderCancellation`

    - `ConfirmSalesOrderCancellation`

- Permissions:

    - `sales.order.cancel`

- External dependencies:

    - Theme 1 — Tenant policy, reason catalog và permission

    - Platform Audit — Reason, actor và stale confirmation attempts

        

#### 4\.6\.6\.4 US\-03 — Xác nhận hủy toàn bộ đơn hàng

**Business context**

Confirmation là thời điểm cancellation trở thành quyết định nghiệp vụ chính thức\. Hệ thống phải kiểm tra lại authoritative order, settlement, return/exchange conflict, reason và permission vì dữ liệu có thể đã thay đổi sau precheck\.

Người dùng xác nhận bằng `ConfirmSalesOrderCancellation`\. Post\-sale Operations lưu cancellation decision và phát event\. Sales Order Lifecycle nhận command nội bộ `CancelSalesOrder` để chuyển order lifecycle sang `cancelled`\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền hủy đơn|Xác nhận hủy toàn bộ một SalesOrder chưa có tiền thực thu ròng|Giao dịch được vô hiệu hóa có kiểm soát nhưng dữ liệu gốc vẫn được bảo toàn|



**Functional requirements**

- FR\-01: Hệ thống phải thực hiện `ConfirmSalesOrderCancellation` với cancellation context, sales\_order\_id, expected order version, expected settlement version, reason, actor và idempotency key\.

- FR\-02: Backend phải validate lại permission, lifecycle, lock status, source version, cancellation conflict và return/exchange conflict\.

- FR\-03: Backend phải kiểm tra lại Sales Settlement authoritative và chỉ tiếp tục khi `net_confirmed_collection = 0`\.

- FR\-04: Khi hợp lệ, hệ thống phải lưu SalesOrderCancellation confirmed cùng reason, actor, source snapshots và impact requirements\.

- FR\-05: Hệ thống phải gửi command nội bộ `CancelSalesOrder`; command thành công chuyển SalesOrder từ `completed` sang `cancelled` và phát `SalesOrderCancelled`\.

- FR\-06: Hệ thống phải tạo durable impact hoặc outbox records cần thiết cho receivable reversal, inventory reversal, pricing reversal, e\-invoice handling và reporting\.

- FR\-07: Hệ thống phải hỗ trợ truy vấn lại cancellation result khi client timeout hoặc kết quả đang `processing` hay `uncertain`\.

    

**Business rules**

- BR\-01: `ConfirmSalesOrderCancellation` là command người dùng và bắt buộc có idempotency key\.

- BR\-02: `CancelSalesOrder` là command nội bộ, idempotent và không được gọi trực tiếp từ UI\.

- BR\-03: Cùng idempotency key và cùng payload phải trả lại cùng cancellation result; payload khác phải trả conflict\.

- BR\-04: Confirmation chỉ hợp lệ khi `net_confirmed_collection = 0` tại command time; phát sinh tiền thực thu mới phải chặn và chuyển hướng sang EP\-06\.

- BR\-05: Source order version hoặc settlement version thay đổi phải trả conflict; hệ thống không tự merge\.

- BR\-06: Business decision và durable impact/outbox record của cùng domain phải commit atomically trong local transaction; không dùng distributed transaction giữa các domain\.

- BR\-07: Commercial snapshot, SalesOrderLine, payment history, receipt và adjustment history không được xóa hoặc ghi đè khi hủy\.

    

**Acceptance criteria**

- AC\-01: Request hợp lệ xác nhận đúng một SalesOrderCancellation\.

- AC\-02: SalesOrder lifecycle chỉ chuyển sang `cancelled` sau khi `CancelSalesOrder` thành công\.

- AC\-03: Cancellation lưu đúng reason, actor, source version, settlement check và impact requirements\.

- AC\-04: Retry cùng idempotency context không tạo cancellation hoặc order transition trùng\.

- AC\-05: Phát sinh tiền thực thu, version conflict hoặc business blocker không cập nhật order lifecycle\.

- AC\-06: Các impact/outbox record bắt buộc được tạo mà không yêu cầu downstream xử lý đồng bộ\.

- AC\-07: Giao dịch gốc và toàn bộ historical records được bảo toàn\.

    

**Edge cases**

- EC\-01: Người dùng double tap CTA; client khóa action và backend idempotency ngăn tạo trùng\.

- EC\-02: Confirmation commit thành công nhưng response bị mất; query lại trả cancellation hiện có\.

- EC\-03: Một payment được confirmed ngay trước command; confirmation bị blocked bằng `PAYMENT_ALREADY_COLLECTED`\.

- EC\-04: ReturnExchangeOrder được confirmed sau precheck; confirmation bị blocked\.

- EC\-05: Order hoặc settlement version thay đổi; confirmation trả conflict và yêu cầu precheck lại\.

- EC\-06: Post\-sale confirmation thành công nhưng lifecycle command đang pending; cancellation hiển thị `processing`\.

- EC\-07: Outbox delivery thất bại sau commit; cancellation không bị xóa và delivery được retry riêng\.

    

**Scenarios**

```Gherkin
Feature: Xác nhận hủy toàn bộ đơn hàng

Scenario: SC-01 — Xác nhận hủy thành công
  Given cancellation đã qua precheck
  And net confirmed collection vẫn bằng 0
  And authoritative state vẫn hợp lệ
  When người dùng gửi ConfirmSalesOrderCancellation
  Then hệ thống lưu SalesOrderCancellation confirmed
  And gửi CancelSalesOrder nội bộ
  And SalesOrder lifecycle chuyển sang cancelled
  And phát SalesOrderCancellationConfirmed
  And phát SalesOrderCancelled

Scenario: SC-02 — Retry cùng payload
  Given cancellation đã thành công với idempotency key "CAN-01"
  When client gửi lại cùng payload với key "CAN-01"
  Then hệ thống trả lại cùng SalesOrderCancellation
  And không tạo cancellation hoặc order transition trùng

Scenario: SC-03 — Cùng key nhưng payload khác
  Given idempotency key "CAN-01" đã được sử dụng
  When client gửi reason khác với cùng key
  Then hệ thống trả idempotency conflict
  And không thay đổi cancellation đã có

Scenario: SC-04 — Phát sinh tiền thực thu sau precheck
  Given precheck trước đó có net confirmed collection bằng 0
  And một payment mới vừa được confirmed
  When người dùng xác nhận cancellation
  Then backend trả blocked với code PAYMENT_ALREADY_COLLECTED
  And không gửi CancelSalesOrder
  And cung cấp action chuyển sang EP-06

Scenario: SC-05 — Version conflict
  Given precheck sử dụng order version 7 và settlement version 3
  And một trong hai version đã thay đổi
  When người dùng xác nhận
  Then hệ thống từ chối confirmation
  And không chuyển order lifecycle
  And yêu cầu tải lại và precheck lại

Scenario: SC-06 — Lifecycle command đang xử lý
  Given SalesOrderCancellation đã confirmed
  And CancelSalesOrder chưa có kết quả cuối
  When người dùng truy vấn cancellation
  Then cancellation status là processing
  And hệ thống không cho tạo cancellation mới
  And tiếp tục kiểm tra command theo correlation context

Scenario: SC-07 — Downstream delivery thất bại
  Given SalesOrder đã chuyển sang cancelled
  And một impact delivery bị failed
  When người dùng xem kết quả
  Then hệ thống vẫn hiển thị order đã hủy
  And hiển thị downstream failure riêng
  And không mở lại SalesOrder
```

**References**

- Domains:

    - Post\-sale Operations

    - Sales Order Lifecycle

    - Sales Settlement

    - Cross\-cutting Foundations

- Data:

    - `SalesOrderCancellation`

    - `SalesOrder`

    - `SalesOrderSettlement`

    - `IdempotencyRecord`

    - `OutboxMessage`

    - `InventoryImpactRequest`

    - `ReceivableImpactRequest`

    - `EInvoiceImpactRequest`

- Commands / queries / events:

    - `ConfirmSalesOrderCancellation`

    - `CancelSalesOrder`

    - `SalesOrderCancellationConfirmed`

    - `SalesOrderCancelled`

    - `GetSalesOrderCancellation`

- Permissions:

    - `sales.order.cancel`

- External dependencies:

    - Theme 4 — `ReverseAppliedPricingForSalesOrder`

    - Theme 6 — Receivable reversal

    - Theme 7 — Inventory reversal

    - Theme 8 — E\-invoice handling

    - Theme 10 — Reporting projection

    - Platform Audit — Confirmation, conflict và blocked action

        

#### 4\.6\.6\.5 US\-04 — Theo dõi các tác động hoàn nguyên

**Business context**

Sau khi SalesOrder chuyển sang `cancelled`, các tác động hoàn nguyên tới khoản phải thu chưa thu, tồn kho, pricing commitment và hóa đơn điện tử có thể tiếp tục được xử lý bất đồng bộ\.

EP\-05 không hoàn tiền đã thu\. Nếu đơn có tiền thực thu ròng, cancellation đã bị chặn từ precheck và người dùng phải xử lý qua EP\-06\. Receivable reversal trong User Story này chỉ là giảm hoặc xóa nghĩa vụ phải thu chưa được thu\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Quản lý cửa hàng, Kế toán hoặc Người kiểm soát|Xem trạng thái hoàn nguyên công nợ chưa thu, tồn kho, pricing và hóa đơn điện tử|Tôi có thể xử lý lỗi hoặc nội dung cần đối soát sau khi đơn đã hủy|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị impact status riêng cho Receivable, Inventory, Pricing, E\-invoice và Reporting khi áp dụng\.

- FR\-02: Mỗi target phải phân biệt business status với delivery status\.

- FR\-03: Cancellation phải tạo `ReceivableImpactRequest` khi còn khoản phải thu chưa thu cần giảm hoặc đảo\.

- FR\-04: Cancellation phải tạo `InventoryImpactRequest` khi giao dịch đã hoặc có thể đã làm thay đổi tồn kho\.

- FR\-05: Hệ thống phải gọi `ReverseAppliedPricingForSalesOrder` khi pricing commitment cần hoàn nguyên\.

- FR\-06: Cancellation phải tạo `EInvoiceImpactRequest` khi đơn có e\-invoice request hoặc chứng từ liên quan\.

- FR\-07: Người dùng có quyền phải có thể retry technical delivery hoặc chuyển item sang reconciliation theo policy mà không tạo business effect trùng\.

    

**Business rules**

- BR\-01: Theme 6 sở hữu receivable ledger; Theme 7 sở hữu stock movement; Theme 4 sở hữu applied pricing; Theme 8 sở hữu e\-invoice\.

- BR\-02: Receivable reversal trong EP\-05 chỉ áp dụng cho nghĩa vụ chưa thu; không phải refund tiền đã thu\.

- BR\-03: Business status gồm `not_required`, `pending`, `accepted`, `rejected`, `reconciliation_required` hoặc `reconciled`\.

- BR\-04: Delivery status gồm `created`, `queued`, `sent`, `acknowledged`, `failed`, `uncertain` hoặc `dead_letter`\.

- BR\-05: Downstream failure không tự động rollback cancellation hoặc mở lại SalesOrder\.

- BR\-06: Technical retry phải idempotent và không được thay đổi payload nghiệp vụ đã commit\.

- BR\-07: Business rejection không được xử lý bằng technical retry để vượt rule của downstream domain\.

    

**Acceptance criteria**

- AC\-01: Cancellation detail hiển thị từng impact target và trạng thái riêng\.

- AC\-02: `not_required` được phân biệt rõ với `pending` hoặc thiếu dữ liệu\.

- AC\-03: Receivable impact phản ánh đúng khoản phải thu chưa thu cần hoàn nguyên\.

- AC\-04: Retry đủ điều kiện gọi đúng technical command và không tạo impact request trùng\.

- AC\-05: Business rejection hiển thị hướng xử lý hoặc reconciliation phù hợp\.

- AC\-06: Downstream failed không làm order mất trạng thái `cancelled`\.

- AC\-07: Mọi impact và retry truy được về source cancellation cùng correlation context\.

    

**Edge cases**

- EC\-01: Receivable reversal accepted nhưng Theme 6 projection chưa cập nhật; hệ thống hiển thị hai trạng thái riêng\.

- EC\-02: Inventory delivery uncertain; hệ thống không tự gửi lại không kiểm soát\.

- EC\-03: Pricing reversal không cần thiết vì không có applied pricing commitment; status là `not_required`\.

- EC\-04: E\-invoice impact bị rejected về nghiệp vụ; hệ thống chuyển sang reconciliation thay vì retry kỹ thuật liên tục\.

- EC\-05: Hai người cùng retry; concurrency và idempotency ngăn gửi trùng\.

- EC\-06: Impact đã dead\-letter; retry chỉ khả dụng theo policy escalation\.

- EC\-07: Projection status chậm; UI hiển thị thời điểm cập nhật gần nhất và cho phép tải lại\.

    

**Scenarios**

```Gherkin
Feature: Theo dõi các tác động hoàn nguyên

Scenario: SC-01 — Xem impact summary sau hủy
  Given SalesOrder đã cancelled
  And cancellation có impact tới Receivable, Inventory và E-invoice
  When người dùng mở cancellation detail
  Then hệ thống hiển thị từng target riêng
  And phân biệt business status với delivery status

Scenario: SC-02 — Hoàn nguyên khoản phải thu chưa thu
  Given net confirmed collection bằng 0
  And outstanding receivable lớn hơn 0
  When cancellation được xác nhận
  Then hệ thống tạo ReceivableImpactRequest giảm hoặc đảo nghĩa vụ phải thu
  And không tạo refund transaction

Scenario: SC-03 — Không có công nợ cần hoàn nguyên
  Given outstanding receivable bằng 0
  When cancellation được xác nhận
  Then Receivable impact status là not_required
  And không tạo ReceivableImpactRequest

Scenario: SC-04 — Yêu cầu hoàn nguyên tồn kho
  Given đơn đã làm giảm tồn kho
  When cancellation được xác nhận
  Then hệ thống tạo InventoryImpactRequest theo từng dòng cần hoàn nguyên
  And không trực tiếp tạo stock movement

Scenario: SC-05 — Đảo pricing commitment
  Given đơn có applied pricing commitment cần hoàn nguyên
  When cancellation được xử lý
  Then hệ thống gọi ReverseAppliedPricingForSalesOrder
  And lưu correlation context tới cancellation

Scenario: SC-06 — Retry delivery thất bại
  Given Inventory impact delivery status là failed
  And người dùng có permission retry
  When người dùng xác nhận retry
  Then hệ thống gọi technical retry command với idempotency
  And không tạo InventoryImpactRequest nghiệp vụ mới

Scenario: SC-07 — Downstream thất bại không mở lại đơn
  Given SalesOrder lifecycle là cancelled
  And Receivable impact delivery là dead_letter
  When người dùng xem chi tiết đơn
  Then hệ thống vẫn hiển thị Đã hủy
  And hiển thị receivable impact cần xử lý
  And không chuyển order lifecycle về completed
```

**References**

- Domains:

    - Post\-sale Operations

    - Cross\-cutting Foundations

- Data:

    - `ReceivableImpactRequest`

    - `InventoryImpactRequest`

    - `EInvoiceImpactRequest`

    - `IntegrationCommand`

    - `ReconciliationResult`

    - Correlation context

- Commands / queries / events:

    - `ReverseAppliedPricingForSalesOrder`

    - `RetryReceivableImpact`

    - `RetryInventoryImpact`

    - `RetryEInvoiceImpact`

    - `RetryIntegrationCommand`

    - `ReconcileIntegrationResult`

    - `GetOrderIntegrationStatus`

- Permissions:

    - `sales.integration.view_sync_status`

    - Permission retry hoặc reconciliation theo policy vận hành

- External dependencies:

    - Theme 4 — Pricing reversal

    - Theme 6 — Receivable reversal

    - Theme 7 — Inventory reversal

    - Theme 8 — E\-invoice handling

    - Theme 10 — Reporting

    - Platform Audit — Retry và reconciliation actions

        

#### 4\.6\.6\.6 US\-05 — Xem kết quả và lịch sử hủy đơn

**Business context**

Sau khi cancellation được xác nhận, người dùng cần thấy rõ đơn đã bị hủy, lý do, người thực hiện và trạng thái các tác động hoàn nguyên\. Kết quả không có refund summary vì EP\-05 chỉ hủy đơn khi không còn tiền thực thu ròng cần hoàn\.

Chi tiết đơn vẫn phải giữ commercial snapshot gốc, payment history, receipt và toàn bộ lịch sử trước đó\. Cancellation summary bổ sung thông tin đảo ngược nhưng không thay thế giao dịch ban đầu\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền|Xem cancellation summary và timeline của đơn đã hủy|Tôi có thể truy vết nguyên nhân, người thực hiện và kết quả hoàn nguyên|



**Functional requirements**

- FR\-01: Màn kết quả phải hiển thị mã đơn, trạng thái Đã hủy, cancellation ID, reason, actor và thời điểm xác nhận\.

- FR\-02: Hệ thống phải hiển thị điều kiện settlement tại thời điểm hủy là `net_confirmed_collection = 0`\.

- FR\-03: Hệ thống phải hiển thị trạng thái Receivable, Inventory, Pricing, E\-invoice và Reporting impacts\.

- FR\-04: Chi tiết SalesOrder phải tiếp tục hiển thị commercial snapshot gốc cùng cancellation summary\.

- FR\-05: Timeline phải bổ sung activity về cancellation precheck, confirmation, lifecycle cancellation và downstream impacts\.

- FR\-06: SalesReceipt cũ phải được giữ lại và hiển thị nhãn Đã hủy; có thể sinh receipt version mới theo policy\.

- FR\-07: Hệ thống phải cung cấp các action Xem chi tiết đơn, Xem trạng thái xử lý, Tạo đơn mới và Quay lại danh sách\.

    

**Business rules**

- BR\-01: SalesOrder đã `cancelled` không được mở lại hoặc chuyển về `completed`\.

- BR\-02: Commercial snapshot, SalesOrderLine, payment history, adjustment history và receipt history là append\-only\.

- BR\-03: Cancellation activity đã xác nhận không được sửa hoặc xóa\.

- BR\-04: EP\-05 result không hiển thị action ghi nhận refund hoặc số tiền còn chờ hoàn\.

- BR\-05: Payment history trước đó nếu có vẫn được xem trong EP\-03 nhưng không làm cancellation result trở thành refund flow\.

- BR\-06: Tạo đơn mới sau hủy phải khởi tạo SalesOrderWorkingState mới, không tái sử dụng order identity cũ\.

- BR\-07: Projection có thể eventual consistent nhưng phải hội tụ theo event ordering và không tạo timeline item trùng\.

    

**Acceptance criteria**

- AC\-01: Cancellation thành công hiển thị rõ SalesOrder đã hủy và không thể mở lại\.

- AC\-02: Cancellation summary phản ánh đúng reason, actor, thời điểm và source order\.

- AC\-03: Kết quả hiển thị rõ không còn tiền thực thu ròng cần hoàn tại thời điểm hủy\.

- AC\-04: Chi tiết đơn vẫn hiển thị toàn bộ giao dịch gốc\.

- AC\-05: Timeline hiển thị các activity hủy theo đúng trình tự và nguồn\.

- AC\-06: Receipt cũ vẫn xem, in hoặc chia sẻ được theo permission và có nhãn Đã hủy\.

- AC\-07: Người dùng có thể bắt đầu đơn mới mà không làm thay đổi đơn đã hủy\.

    

**Edge cases**

- EC\-01: Lifecycle đã cancelled nhưng cancellation projection chưa cập nhật; UI hiển thị đang cập nhật và cho tải lại\.

- EC\-02: Receivable hoặc inventory impact còn pending; kết quả vẫn hiển thị order đã hủy cùng trạng thái riêng\.

- EC\-03: Actor đã bị deactivate; lịch sử vẫn giữ actor snapshot hoặc định danh lịch sử\.

- EC\-04: Người dùng không có quyền xem payment details; payment history chi tiết bị che theo policy\.

- EC\-05: Receipt generation version mới thất bại; receipt cũ vẫn tồn tại và order không thay đổi\.

- EC\-06: Một impact chuyển sang reconciliation sau khi màn kết quả đã mở; refresh phải hiển thị trạng thái mới nhất\.

- EC\-07: Người dùng mở deep link tới cancellation ngoài store scope; hệ thống trả no\-permission mà không tiết lộ dữ liệu\.

    

**Scenarios**

```Gherkin
Feature: Xem kết quả và lịch sử hủy đơn

Scenario: SC-01 — Xem kết quả hủy thành công
  Given SalesOrder lifecycle là cancelled
  And SalesOrderCancellation đã confirmed
  When người dùng mở màn kết quả
  Then hệ thống hiển thị mã đơn và trạng thái Đã hủy
  And hiển thị reason, actor và thời điểm hủy
  And hiển thị impact summary

Scenario: SC-02 — Không phát sinh hoàn tiền trong EP-05
  Given SalesOrder đã cancelled qua EP-05
  When người dùng xem cancellation summary
  Then hệ thống hiển thị net confirmed collection tại thời điểm hủy bằng 0
  And không hiển thị refund status hoặc action ghi nhận hoàn tiền

Scenario: SC-03 — Xem commercial snapshot gốc
  Given SalesOrder đã cancelled
  When người dùng mở chi tiết đơn
  Then hệ thống vẫn hiển thị customer, lines, pricing và monetary snapshot gốc
  And hiển thị cancellation summary riêng
  And không ghi đè giao dịch gốc bằng dữ liệu đảo ngược

Scenario: SC-04 — Xem timeline hủy
  Given cancellation đã phát sinh receivable và inventory impacts
  When người dùng mở timeline
  Then hệ thống hiển thị cancellation confirmed
  And SalesOrderCancelled
  And receivable cùng inventory impact activities theo thứ tự

Scenario: SC-05 — Xem receipt của đơn đã hủy
  Given SalesReceipt đã tồn tại trước khi hủy
  When người dùng xem receipt
  Then receipt vẫn giữ nội dung snapshot gốc
  And hiển thị nhãn Đã hủy
  And không tự nhận là hóa đơn điện tử đã hủy

Scenario: SC-06 — Tạo đơn mới
  Given người dùng đang xem SalesOrder đã hủy
  When người dùng chọn Tạo đơn mới
  Then hệ thống khởi tạo SalesOrderWorkingState mới
  And không sao chép order identity cũ
  And SalesOrder đã hủy không thay đổi

Scenario: SC-07 — Projection đang cập nhật
  Given SalesOrder đã chuyển sang cancelled
  And cancellation detail projection chưa cập nhật
  When người dùng mở kết quả
  Then hệ thống hiển thị dữ liệu authoritative khả dụng cùng trạng thái đang cập nhật
  And cho phép tải lại
  And không cho gửi cancellation mới
```

**References**

- Domains:

    - Sales Order Inquiry \& Documents

    - Post\-sale Operations

    - Sales Order Lifecycle

    - Sales Settlement

- Data:

    - `SalesOrderCancellation`

    - `SalesOrderDetailView`

    - `SalesOrderTimelineView`

    - `SalesOrderIntegrationStatusView`

    - `SalesReceipt`

    - `SalesReceiptActivity`

    - Settlement check snapshot

- Commands / queries / events:

    - `GetSalesOrderCancellation`

    - `GetSalesOrderDetail`

    - `GetSalesOrderTimeline`

    - `GetSalesOrderPaymentSummary`

    - `GetOrderIntegrationStatus`

    - `GenerateSalesReceipt`

    - `SalesOrderCancellationConfirmed`

    - `SalesOrderCancelled`

- Permissions:

    - `sales.order.view`

    - `sales.order.history.view`

    - `sales.payment.view`

    - `sales.receipt.view`

    - `sales.integration.view_sync_status`

- External dependencies:

    - Theme 6 — Receivable status

    - Theme 7 — Inventory status

    - Theme 8 — E\-invoice status

    - Theme 10 — Reporting projection

    - Platform Audit — Cancellation, retry và reconciliation history

## 4\.7 EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch

### 4\.7\.1 Overview

Epic này bao phủ nghiệp vụ **trả hàng, đổi hàng hoặc kết hợp trả hàng với mua thêm** dựa trên một `SalesOrder` chính thức đã được hoàn tất\.

EP\-06 hỗ trợ các biến thể chính:

- **Trả hàng:** Khách trả lại một phần hoặc toàn bộ hàng đã mua mà không nhận hàng thay thế\.

- **Đổi hàng ngang giá:** Khách trả hàng cũ và nhận hàng mới có giá trị tương đương\.

- **Đổi hàng và thu thêm:** Giá trị hàng mới lớn hơn giá trị được ghi nhận từ hàng trả\.

- **Đổi hàng và hoàn tiền:** Giá trị hàng trả lớn hơn giá trị hàng mới\.

- **Trả hàng và cấn trừ công nợ:** Giá trị hàng trả được dùng để giảm khoản còn phải thu của đơn hàng gốc\.

- **Đổi/trả kết hợp cấn trừ công nợ:** Giá trị hàng trả, hàng mới, khoản đã thanh toán và khoản còn phải thu được quyết toán trong cùng một nghiệp vụ\.

    

EP\-06 chỉ áp dụng cho `SalesOrder` chính thức\. Các trường hợp sau không thuộc Epic này:

- Xóa dòng hàng khỏi đơn hàng đang lập\.

- Thay đổi sản phẩm trước checkout\.

- Hủy đơn nháp\.

- Hủy toàn bộ một giao dịch được tạo nhầm mà chưa phát sinh nghiệp vụ trả hàng thực tế\.

- Trả hàng cho nhà cung cấp\.

- Điều chuyển hoặc điều chỉnh tồn kho không xuất phát từ giao dịch bán hàng\.

    

Nghiệp vụ đổi/trả không sửa hoặc xóa giao dịch gốc\. Hệ thống phải:

- Giữ nguyên `SalesOrder` và commercial snapshot ban đầu\.

- Tạo một `ReturnExchangeOrder` độc lập\.

- Liên kết phiếu đổi/trả với đơn hàng gốc\.

- Lưu các dòng hàng trả và hàng đổi hoặc mua thêm\.

- Tính giá trị hàng trả dựa trên commercial snapshot của giao dịch gốc\.

- Tính giá trị hàng mới theo pricing hợp lệ tại thời điểm đổi hàng\.

- Xác định số tiền cần thu thêm, hoàn lại hoặc cấn trừ công nợ\.

- Ghi nhận payment hoặc refund transaction phù hợp\.

- Tạo các impact request cần thiết cho công nợ, tồn kho, hóa đơn điện tử và báo cáo\.

- Cập nhật return status của đơn hàng gốc\.

- Giữ lịch sử đầy đủ trên timeline\.

    

Một đơn hàng có thể phát sinh nhiều phiếu đổi/trả\. Tổng số lượng đã trả của mỗi dòng hàng không được vượt quá số lượng đã bán sau khi trừ các lần trả đã được xác nhận trước đó\.

Return status là một state dimension độc lập với order lifecycle:

- Đơn hàng gốc vẫn giữ lifecycle là `completed`, trừ khi đã được hủy theo EP\-05\.

- Đơn chưa phát sinh trả hàng có return status là `not_returned`\.

- Đơn đã trả một phần có return status là `partially_returned`\.

- Đơn đã trả toàn bộ số lượng có thể trả có return status là `fully_returned`\.

    

Đơn hàng đã trả toàn bộ không tự động trở thành đơn đã hủy\. Hủy đơn và trả toàn bộ hàng là hai nghiệp vụ khác nhau, có lịch sử và tác động khác nhau\.

`ReturnExchangeOrder` phải có lifecycle riêng, tối thiểu:

- `draft`: Phiếu đang được lập, chưa tạo tác động nghiệp vụ\.

- `confirmed`: Người dùng đã xác nhận nội dung và hệ thống đã commit nghiệp vụ đổi/trả\.

- `processing`: Các downstream impacts hoặc quyết toán vẫn đang được xử lý\.

- `completed`: Các tác động bắt buộc đã đạt trạng thái hoàn thành theo policy\.

- `cancelled`: Phiếu nháp hoặc phiếu chưa commit bị hủy bỏ\.

- `failed`: Không thể commit nghiệp vụ đổi/trả\.

    

Một `ReturnExchangeOrder` đã được xác nhận không được sửa trực tiếp hoặc xóa\. Nếu phát hiện sai sót sau khi xác nhận, hệ thống phải xử lý bằng một nghiệp vụ bù trừ mới theo policy, không ghi đè lịch sử cũ\.

Xác nhận đổi/trả phải sử dụng idempotency và optimistic concurrency\. Việc người dùng bấm nhiều lần, client gửi lại request hoặc nhiều người đồng thời trả cùng một dòng hàng không được:

- Tạo nhiều phiếu đổi/trả trùng\.

- Trả vượt số lượng đã bán\.

- Ghi nhận payment hoặc refund trùng\.

- Tạo inventory, receivable hoặc e\-invoice impact trùng\.

    

Epic kết thúc theo một trong các hướng:

- Phiếu đổi/trả được xác nhận và quyết toán thành công\.

- Phiếu được xác nhận nhưng một số downstream impacts còn đang xử lý\.

- Yêu cầu bị chặn do dòng hàng không còn đủ số lượng có thể trả\.

- Yêu cầu bị chặn do đơn hàng, thanh toán, công nợ, tồn kho hoặc hóa đơn điện tử không đủ điều kiện\.

- Dữ liệu bị thay đổi đồng thời và người dùng phải tải lại\.

- Người dùng hủy phiếu khi vẫn còn ở trạng thái nháp\.

### 4\.7\.2 Business context

Sau khi bán hàng, khách hàng có thể quay lại cửa hàng vì:

- Mua nhầm sản phẩm\.

- Sản phẩm không phù hợp với nhu cầu\.

- Cần đổi sang quy cách hoặc đơn vị khác\.

- Cần đổi sang sản phẩm có giá trị cao hơn hoặc thấp hơn\.

- Chỉ muốn trả một phần số lượng đã mua\.

- Trả toàn bộ hàng nhưng giao dịch không phù hợp để xử lý bằng hủy đơn\.

- Đơn hàng còn công nợ và khách muốn dùng giá trị hàng trả để giảm nghĩa vụ thanh toán\.

    

Nghiệp vụ đổi/trả phức tạp hơn việc sửa đơn hàng vì nó đồng thời có thể ảnh hưởng đến:

- Số lượng hàng đã bán\.

- Tồn kho\.

- Giá vốn\.

- Doanh thu hoặc doanh thu điều chỉnh\.

- Số tiền đã thu\.

- Số tiền phải hoàn\.

- Khoản còn phải thu\.

- Hóa đơn điện tử\.

- Báo cáo bán hàng\.

- Lịch sử giao dịch của khách hàng\.

    

Do đó, hệ thống không được sửa trực tiếp các dòng hàng của `SalesOrder`\. Mỗi lần đổi/trả phải được ghi nhận bằng một chứng từ sau bán độc lập và có thể truy vết\.

Trước khi cho phép lập phiếu đổi/trả, hệ thống phải xác định số lượng còn có thể trả của từng dòng hàng:

`returnable_quantity = sold_quantity - confirmed_returned_quantity - reserved_quantity`

Trong đó:

- `sold_quantity` là số lượng đã bán theo commercial snapshot của dòng hàng gốc\.

- `confirmed_returned_quantity` là tổng số lượng đã được xác nhận trả trong các phiếu trước\.

- `reserved_quantity` là số lượng đang được giữ bởi các phiếu đổi/trả active khác nếu hệ thống áp dụng reservation\.

    

`returnable_quantity` không được nhỏ hơn 0\. Người dùng không được trả vượt số lượng còn có thể trả\.

Giá trị hàng trả phải được tính từ commercial snapshot của đơn hàng gốc, không sử dụng giá hiện hành của sản phẩm\.

Giá trị trả của một dòng hàng phải xét đến:

- Đơn giá tại thời điểm bán\.

- Chiết khấu cấp dòng\.

- Chiết khấu cấp đơn được phân bổ cho dòng\.

- Promotion hoặc ưu đãi liên quan\.

- Thuế\.

- Quy tắc làm tròn\.

- Số lượng được chấp nhận trả\.

- Giá trị đã được hoàn hoặc cấn trừ trong các lần trả trước\.

    

Việc phân bổ chiết khấu, thuế và làm tròn phải theo quy tắc xác định, nhất quán và có thể tái lập\. Với lần trả cuối cùng của một dòng hàng, hệ thống có thể sử dụng phần giá trị còn lại của snapshot để tránh sai lệch làm tròn tích lũy\.

Các sản phẩm khách nhận trong luồng đổi hàng được xem là hàng xuất mới tại thời điểm đổi\. Giá của hàng mới phải được Theme 4 xác định theo:

- Khách hàng\.

- Cửa hàng\.

- Sản phẩm\.

- Đơn vị bán\.

- Số lượng\.

- Thời điểm đổi hàng\.

- Chính sách giá và promotion hiện hành\.

    

Giá hàng mới không nhất thiết bằng giá tại thời điểm đơn hàng gốc được tạo\.

Nếu pricing thay đổi trong khi người dùng đang lập phiếu, hệ thống phải thông báo và yêu cầu kiểm tra lại trước khi xác nhận\. Không được âm thầm thay đổi số tiền cần thu hoặc hoàn\.

Giá trị quyết toán của một phiếu đổi/trả phải được thể hiện rõ bằng `ReturnExchangeValuation`, tối thiểu gồm:

- Giá trị hàng trả được chấp nhận\.

- Giá trị hàng đổi hoặc mua thêm\.

- Khoản còn phải thu của đơn hàng gốc trước nghiệp vụ\.

- Giá trị được cấn trừ công nợ\.

- Số tiền cần thu thêm\.

- Số tiền cần hoàn\.

- Khoản còn phải thu sau nghiệp vụ\.

- Thuế và làm tròn liên quan\.

- Tổng payment và refund được ghi nhận trong phiếu\.

    

Có thể biểu diễn số dư quyết toán trước khi thu hoặc hoàn tiền như sau:

`net_balance = outstanding_receivable_before + new_goods_amount - approved_return_credit`

Trong đó:

- Nếu `net_balance > 0`, khách hàng còn nghĩa vụ thanh toán\.

- Nếu `net_balance = 0`, nghiệp vụ đã cân bằng về giá trị\.

- Nếu `net_balance < 0`, cửa hàng phải hoàn cho khách `ABS(net_balance)`\.

    

Nếu `net_balance > 0`, hệ thống có thể:

- Thu đủ ngay\.

- Thu một phần và ghi nhận phần còn lại thành công nợ nếu policy cho phép\.

- Không thu ngay và ghi nhận toàn bộ thành công nợ nếu người dùng có quyền\.

    

Nếu `net_balance < 0`, hệ thống có thể:

- Hoàn đủ ngay\.

- Hoàn một phần và ghi nhận phần còn phải hoàn nếu policy cho phép\.

- Ghi nhận nghĩa vụ hoàn tiền để xử lý sau nếu tenant policy cho phép\.

    

Đối với Khách lẻ:

- Không được tạo khoản phải thu mới\.

- Phần cần thu thêm phải được thanh toán đủ trước khi hoàn tất phiếu\.

- Nếu phải hoàn tiền, hệ thống phải xử lý theo refund policy áp dụng cho Khách lẻ\.

    

Đối với khách hàng có hồ sơ:

- Có thể phát sinh khoản còn phải thu mới nếu tenant policy và permission cho phép\.

- Giá trị hàng trả phải ưu tiên cấn trừ khoản còn phải thu theo quy tắc settlement\.

- Phần còn lại sau cấn trừ mới được xem xét hoàn tiền\.

- Ngày hẹn thanh toán mới phải được xác định nếu sau đổi/trả khách vẫn còn nợ\.

    

Khi hàng được trả về, Theme 5 phải ghi nhận return disposition để Theme 7 xử lý theo policy, ví dụ:

- Hoàn nhập vào tồn kho bán được\.

- Chuyển sang trạng thái chờ kiểm tra\.

- Chuyển sang hàng hỏng hoặc không bán được\.

- Không hoàn nhập tồn kho\.

    

Theme 5 không trực tiếp tạo stock movement hoặc quyết định giá vốn\. Theme 7 là owner của tồn kho, tình trạng hàng và giá vốn\.

Nếu đơn hàng gốc có hóa đơn điện tử hoặc yêu cầu xuất hóa đơn, Theme 5 phải chuyển thông tin đổi/trả sang Theme 8\. Theme 8 quyết định nghiệp vụ pháp lý phù hợp như điều chỉnh, thay thế hoặc xử lý khác\.

Nếu hóa đơn điện tử tạo blocker pháp lý, hệ thống phải chặn xác nhận hoặc yêu cầu xử lý theo contract với Theme 8\.

Nghiệp vụ đổi/trả đã được commit không được rollback chỉ vì một downstream integration thất bại\. Hệ thống phải hiển thị riêng:

- Trạng thái phiếu đổi/trả\.

- Trạng thái quyết toán\.

- Trạng thái hoàn nhập hoặc xuất kho\.

- Trạng thái công nợ\.

- Trạng thái xử lý hóa đơn điện tử\.

- Trạng thái delivery của integration command\.

    

Nếu downstream impact thất bại, hệ thống phải retry hoặc chuyển sang reconciliation mà không tạo nghiệp vụ đổi/trả mới\.

### 4\.7\.3 In scope

- Khởi tạo flow đổi/trả từ một `SalesOrder` chính thức\.

- Kiểm tra tenant, store scope, membership và permission trước khi mở flow\.

- Kiểm tra order lifecycle, lock status và return status\.

- Chặn đổi/trả đối với đơn đã hủy\.

- Chặn hoặc yêu cầu permission đặc biệt đối với đơn đã khóa theo policy\.

- Kiểm tra đơn hàng có thuộc thời hạn được phép đổi/trả hay không\.

- Kiểm tra đơn hàng có nghiệp vụ hủy đang xử lý hay không\.

- Chặn đổi/trả nếu đơn hàng đã được hủy hoặc có cancellation đã commit\.

- Thực hiện `PrecheckReturnExchangeOrder`\.

- Tạo `ReturnableOrderLineView` từ commercial snapshot và các phiếu đổi/trả đã xác nhận\.

- Hiển thị từng dòng hàng gốc gồm:

    - Tên sản phẩm tại thời điểm bán\.

    - SKU hoặc mã tham chiếu\.

    - Đơn vị bán\.

    - Số lượng đã bán\.

    - Số lượng đã trả trước đó\.

    - Số lượng đang được giữ bởi phiếu active khác nếu có\.

    - Số lượng còn có thể trả\.

    - Giá trị tối đa còn có thể ghi nhận trả\.

- Cho phép chọn một hoặc nhiều dòng hàng để trả\.

- Cho phép nhập số lượng trả theo đơn vị bán của dòng hàng gốc\.

- Kiểm tra số lượng trả lớn hơn 0\.

- Kiểm tra số lượng trả không vượt `returnable_quantity`\.

- Kiểm tra đơn vị trả phù hợp với commercial snapshot hoặc conversion rule được Theme 2 hỗ trợ\.

- Không cho thay đổi tùy ý đơn vị trả làm sai số lượng gốc\.

- Cho phép chọn lý do trả hàng theo từng phiếu hoặc từng dòng\.

- Cho phép nhập ghi chú bổ sung\.

- Kiểm tra reason code hợp lệ\.

- Yêu cầu mô tả bổ sung đối với reason code cần giải trình\.

- Cho phép chọn return disposition cho từng dòng theo contract với Theme 7\.

- Kiểm tra disposition nằm trong danh sách được phép\.

- Cho phép đánh dấu hàng cần kiểm tra trước khi hoàn nhập nếu policy hỗ trợ\.

- Tính `approved_return_credit` từ commercial snapshot của đơn hàng gốc\.

- Phân bổ chiết khấu cấp đơn cho số lượng trả theo quy tắc xác định\.

- Phân bổ thuế theo snapshot và policy áp dụng\.

- Áp dụng quy tắc làm tròn nhất quán\.

- Sử dụng remainder adjustment ở lần trả cuối để tránh sai lệch tích lũy\.

- Không tính giá trị trả theo giá sản phẩm hiện hành\.

- Hiển thị rõ:

    - Giá bán ban đầu\.

    - Chiết khấu được phân bổ\.

    - Thuế liên quan\.

    - Giá trị trả được chấp nhận\.

- Cho phép lập phiếu chỉ trả hàng mà không có hàng đổi\.

- Cho phép thêm một hoặc nhiều sản phẩm mới vào phần hàng đổi hoặc mua thêm\.

- Tìm kiếm sản phẩm mới theo tên, mã, SKU hoặc barcode\.

- Chọn đơn vị bán hợp lệ của sản phẩm mới\.

- Nhập số lượng hàng mới\.

- Lấy pricing preview từ Theme 4 cho hàng mới\.

- Hiển thị giá, discount, promotion và pricing source của hàng mới ở mức cần thiết\.

- Cho phép sửa giá hoặc chiết khấu hàng mới nếu permission và pricing policy cho phép\.

- Validate lại pricing của hàng mới tại thời điểm xác nhận\.

- Kiểm tra sản phẩm mới còn hoạt động và được phép bán\.

- Kiểm tra tồn kho hoặc reservation của hàng mới theo policy và contract với Theme 7\.

- Cho phép loại bỏ hoặc cập nhật dòng hàng mới trước khi xác nhận\.

- Tính `new_goods_amount`\.

- Tạo và cập nhật `ReturnExchangeValuation` trong quá trình người dùng lập phiếu\.

- Hiển thị valuation summary gồm:

    - Giá trị hàng trả\.

    - Giá trị hàng mới\.

    - Công nợ trước đổi/trả\.

    - Giá trị cấn trừ công nợ\.

    - Số tiền cần thu thêm\.

    - Số tiền cần hoàn\.

    - Công nợ còn lại sau đổi/trả\.

- Tự động tính lại valuation khi:

    - Thay đổi dòng hàng trả\.

    - Thay đổi số lượng trả\.

    - Thay đổi disposition có ảnh hưởng định giá nếu policy cho phép\.

    - Thêm hoặc xóa hàng mới\.

    - Thay đổi số lượng hoặc đơn vị hàng mới\.

    - Pricing của hàng mới thay đổi\.

    - Settlement hoặc công nợ nguồn thay đổi\.

- Phân biệt rõ:

    - Return credit\.

    - Receivable offset\.

    - Additional collection\.

    - Refund\.

    - Remaining receivable\.

- Kiểm tra Khách lẻ không phát sinh công nợ mới\.

- Kiểm tra khách hàng có hồ sơ đủ điều kiện phát sinh công nợ sau đổi/trả\.

- Kiểm tra permission cho phép hoàn tất khi vẫn còn khoản phải thu\.

- Ghi nhận ngày hẹn thanh toán nếu sau đổi/trả vẫn còn công nợ và policy yêu cầu\.

- Kiểm tra ngày hẹn thanh toán hợp lệ\.

- Cho phép ghi nhận một hoặc nhiều khoản thu thêm\.

- Hỗ trợ thu thêm bằng Tiền mặt\.

- Hỗ trợ thu thêm bằng Chuyển khoản thủ công\.

- Cho phép kết hợp nhiều phương thức thu nếu policy cho phép\.

- Kiểm tra số tiền thu lớn hơn 0\.

- Kiểm tra tổng thu không vượt số tiền cần thu\.

- Cho phép ghi nhận một hoặc nhiều khoản hoàn tiền\.

- Hỗ trợ hoàn tiền bằng Tiền mặt\.

- Hỗ trợ hoàn tiền bằng Chuyển khoản thủ công\.

- Cho phép kết hợp nhiều phương thức hoàn nếu policy cho phép\.

- Kiểm tra số tiền hoàn lớn hơn 0\.

- Kiểm tra tổng hoàn không vượt số tiền cần hoàn\.

- Cho phép ghi nhận khoản còn phải hoàn nếu tenant policy cho phép\.

- Không cho đồng thời ghi nhận thu thêm và hoàn tiền cho cùng một kết quả valuation cuối cùng\.

- Tự động xác định hướng settlement từ giá trị quyết toán\.

- Cho phép người dùng quay lại sửa dòng hàng trước khi xác nhận\.

- Lưu `ReturnExchangeOrder` ở trạng thái `draft` khi người dùng chủ động lưu nếu phạm vi sản phẩm hỗ trợ\.

- Lưu các `ReturnExchangeLine` thuộc nhóm:

    - `return`\.

    - `exchange_outbound` hoặc `new_sale`\.

- Lưu `ReturnExchangeValuation`\.

- Lưu khách hàng, cửa hàng, người xử lý và context liên quan\.

- Cho phép mở lại phiếu nháp để tiếp tục\.

- Kiểm tra lại returnable quantity, pricing, inventory, settlement và permission khi khôi phục phiếu nháp\.

- Chặn tiếp tục phiếu nháp nếu đơn hàng nguồn đã bị hủy hoặc dữ liệu nguồn không còn hợp lệ\.

- Cho phép hủy phiếu nháp mà không tạo tác động nghiệp vụ\.

- Không cho sửa phiếu đã `confirmed`, `processing` hoặc `completed`\.

- Yêu cầu idempotency key cho command `ConfirmReturnExchangeOrder`\.

- Trả lại cùng kết quả nếu cùng idempotency key và cùng payload được gửi lại\.

- Trả conflict nếu cùng idempotency key nhưng payload khác\.

- Sử dụng optimistic concurrency đối với:

    - SalesOrder\.

    - Returnable quantity\.

    - Settlement\.

    - Active return reservations\.

- Khóa hoặc reserve returnable quantity trong quá trình commit để ngăn trả vượt\.

- Validate lại toàn bộ điều kiện ở backend trước khi xác nhận\.

- Không chỉ dựa vào dữ liệu người dùng đã thấy trên client\.

- Kiểm tra lại:

    - Order lifecycle\.

    - Lock status\.

    - Cumulative returned quantity\.

    - Active return reservation\.

    - Settlement\.

    - Receivable\.

    - Pricing của hàng mới\.

    - Inventory availability\.

    - E\-invoice eligibility\.

- Không commit một phần nếu validation bắt buộc thất bại\.

- Tạo đúng một `ReturnExchangeOrder` khi xác nhận thành công\.

- Tạo các `ReturnExchangeLine`\.

- Lưu snapshot của dòng hàng trả từ đơn hàng gốc\.

- Lưu commercial snapshot của hàng mới tại thời điểm đổi\.

- Lưu valuation snapshot\.

- Lưu reason, note, actor và thời điểm xác nhận\.

- Lưu source order version và correlation context\.

- Chuyển phiếu từ `draft` sang `confirmed`\.

- Không sửa hoặc xóa `SalesOrder` gốc\.

- Không sửa hoặc xóa `SalesOrderLine` gốc\.

- Không ghi đè commercial snapshot ban đầu\.

- Cập nhật cumulative returned quantity theo kết quả đã commit\.

- Cập nhật return status của đơn hàng gốc:

    - `not_returned`\.

    - `partially_returned`\.

    - `fully_returned`\.

- Không tự động chuyển order lifecycle sang `cancelled`\.

- Tạo `SalesPaymentTransaction` loại collection nếu có thu thêm\.

- Tạo `SalesPaymentTransaction` loại refund nếu có hoàn tiền\.

- Liên kết payment hoặc refund transaction với:

    - SalesOrderSettlement\.

    - ReturnExchangeOrder\.

    - Source SalesOrder\.

- Cập nhật settlement summary\.

- Không cho tổng refund vượt tổng số tiền thực tế có thể hoàn\.

- Không cho tổng collection vượt nghĩa vụ thanh toán của phiếu\.

- Ghi nhận khoản còn phải hoàn nếu refund chưa hoàn tất và policy cho phép\.

- Tạo `ReceivableImpactRequest` khi:

    - Giá trị hàng trả được cấn trừ công nợ\.

    - Phát sinh khoản phải thu mới\.

    - Khoản phải thu hiện tại cần giảm\.

    - Ngày hẹn thanh toán cần cập nhật\.

- Ghi rõ source order, return/exchange reference và valuation components\.

- Không trực tiếp sửa receivable ledger\.

- Không tạo khoản phải thu cho Khách lẻ\.

- Tạo `InventoryImpactRequest` cho hàng trả\.

- Ghi rõ:

    - Source order\.

    - ReturnExchangeOrder\.

    - Dòng hàng gốc\.

    - Sản phẩm\.

    - Đơn vị\.

    - Số lượng trả\.

    - Return disposition\.

    - Idempotency context\.

- Tạo `InventoryImpactRequest` cho hàng mới xuất ra\.

- Ghi rõ:

    - Sản phẩm mới\.

    - Đơn vị bán\.

    - Số lượng\.

    - Cửa hàng hoặc kho nguồn\.

    - ReturnExchangeOrder\.

    - Idempotency context\.

- Không trực tiếp tạo, sửa hoặc reverse stock movement\.

- Không tự tính giá vốn hàng hoàn nhập\.

- Tạo `EInvoiceImpactRequest` nếu đơn hàng nguồn có hóa đơn điện tử hoặc yêu cầu hóa đơn\.

- Gửi đủ thông tin về:

    - Dòng hàng trả\.

    - Hàng mới\.

    - Giá trị điều chỉnh\.

    - Thuế\.

    - Lý do đổi/trả\.

    - Chứng từ nguồn\.

- Không quyết định trực tiếp loại chứng từ hóa đơn điện tử cần phát hành\.

- Không coi impact request là hóa đơn đã được điều chỉnh\.

- Phát event hoặc integration command cho Reporting\.

- Lưu business change và các impact request bắt buộc trong cùng local transaction\.

- Sử dụng outbox hoặc delivery mechanism tin cậy\.

- Phân biệt:

    - Return/exchange business status\.

    - Settlement status\.

    - Refund status\.

    - Collection status\.

    - Receivable impact status\.

    - Returned inventory impact status\.

    - New\-goods inventory impact status\.

    - E\-invoice impact status\.

    - Delivery status\.

- Không rollback phiếu đổi/trả đã commit chỉ vì downstream integration thất bại\.

- Cho phép retry technical delivery bằng idempotency\.

- Không tạo business effect trùng khi retry\.

- Chuyển sang reconciliation khi không thể tự động xử lý\.

- Hỗ trợ kiểm tra kết quả khi client timeout hoặc mất kết nối\.

- Nếu phiếu đã được xác nhận, trả lại `ReturnExchangeOrder` hiện có\.

- Không tạo phiếu mới cho cùng idempotency context\.

- Thêm activity vào `SalesOrderTimelineView`\.

- Timeline phải hiển thị tối thiểu:

    - Phiếu đổi/trả được tạo\.

    - Dòng hàng và số lượng đã trả\.

    - Hàng mới đã giao\.

    - Giá trị hàng trả\.

    - Giá trị hàng mới\.

    - Công nợ được cấn trừ\.

    - Khoản thu thêm\.

    - Khoản hoàn tiền\.

    - Khoản còn phải thu hoặc còn phải hoàn\.

    - Người thực hiện\.

    - Thời điểm thực hiện\.

    - Integration impact status\.

- Không cho sửa hoặc xóa timeline activity\.

- Cập nhật `SalesOrderReturnSummaryView`\.

- Hiển thị danh sách các phiếu đổi/trả liên quan trên chi tiết đơn hàng gốc\.

- Cho phép mở chi tiết từng phiếu đổi/trả\.

- Hiển thị `PostSaleResultView` sau khi xác nhận\.

- Màn kết quả hiển thị:

    - Mã phiếu đổi/trả\.

    - Mã đơn hàng gốc\.

    - Giá trị hàng trả\.

    - Giá trị hàng mới\.

    - Số tiền đã thu thêm\.

    - Số tiền đã hoàn\.

    - Giá trị đã cấn trừ công nợ\.

    - Khoản còn phải thu\.

    - Khoản còn phải hoàn\.

    - Return status của đơn hàng gốc\.

    - Trạng thái hoàn nhập hàng trả\.

    - Trạng thái xuất hàng mới\.

    - Trạng thái xử lý hóa đơn điện tử\.

- Cho phép xem, in hoặc chia sẻ phiếu đổi/trả nội bộ nếu chính sách chứng từ hỗ trợ\.

- Phiếu đổi/trả phải lấy dữ liệu từ snapshot của `ReturnExchangeOrder`\.

- Không tính lại chứng từ từ master data hiện hành\.

- Ghi nhận activity khi phiếu được in hoặc chia sẻ\.

- Cung cấp hành động tiếp theo:

    - Xem chi tiết phiếu đổi/trả\.

    - Xem đơn hàng gốc\.

    - Ghi nhận khoản hoàn còn lại nếu được phép\.

    - Ghi nhận khoản thu còn lại nếu thuộc flow công nợ phù hợp\.

    - Tạo đơn hàng mới\.

    - Quay lại danh sách đơn hàng\.

- Ghi audit log cho:

    - Mở flow đổi/trả\.

    - Precheck\.

    - Tạo và cập nhật phiếu nháp\.

    - Xác nhận phiếu\.

    - Phiếu bị chặn\.

    - Collection transaction\.

    - Refund transaction\.

    - Receivable offset\.

    - Version conflict\.

    - Retry integration\.

    - Reconciliation action\.

### 4\.7\.4 Out of scope

- Sửa đơn hàng đang lập trước checkout\.

- Xóa dòng hàng khỏi đơn nháp\.

- Hủy hoặc xóa mềm đơn nháp bán hàng\.

- Hủy toàn bộ một giao dịch được tạo sai; thuộc EP\-05\.

- Điều chỉnh metadata không ảnh hưởng giao dịch; thuộc EP\-04\.

- Sửa trực tiếp khách hàng, sản phẩm, số lượng, đơn vị bán, giá, chiết khấu, thuế hoặc tổng tiền của `SalesOrder` gốc\.

- Xóa hoặc ghi đè commercial snapshot của đơn hàng gốc\.

- Chuyển đơn hàng gốc sang trạng thái hủy chỉ vì đã trả toàn bộ hàng\.

- Trả vượt số lượng đã bán\.

- Trả lại dòng hàng không thuộc đơn hàng nguồn\.

- Trả hàng không có chứng từ nguồn nếu chưa có policy riêng cho trường hợp đặc biệt\.

- Đổi hàng không liên kết với đơn hàng gốc\.

- Sửa hoặc xóa `ReturnExchangeOrder` đã được xác nhận\.

- Hoàn tác phiếu đổi/trả bằng cách xóa lịch sử\.

- Tự động hủy một phiếu đổi/trả đã hoàn tất\.

- Đổi hoặc trả hàng cho nhà cung cấp\.

- Xử lý purchase return\.

- Điều chuyển hàng giữa các kho\.

- Điều chỉnh tồn kho độc lập\.

- Kiểm kê kho\.

- Trực tiếp tạo hoặc sửa stock movement\.

- Tính hoặc điều chỉnh giá vốn hàng trả\.

- Kiểm định chất lượng hàng hóa chi tiết\.

- Quản lý quy trình bảo hành\.

- Quản lý sửa chữa hoặc đổi bảo hành\.

- Quản lý thu hồi hàng từ khách qua vận chuyển\.

- Quản lý phí vận chuyển đổi/trả nếu chưa có domain fulfillment riêng\.

- Tự động chuyển tiền hoàn qua ngân hàng\.

- Tự động hoàn tiền qua payment gateway\.

- Xử lý chargeback\.

- Đối soát sao kê ngân hàng\.

- Hoàn tiền vào ví hoặc số dư khách hàng nếu chưa có nghiệp vụ riêng\.

- Ghi nhận khoản thu độc lập không liên quan đến phiếu đổi/trả\.

- Thu công nợ ngoài phạm vi quyết toán của phiếu\.

- Phân bổ một khoản thu cho nhiều khách hàng\.

- Trực tiếp sửa receivable ledger\.

- Tính lãi hoặc phí phạt công nợ\.

- Phát hành, ký số, điều chỉnh, thay thế hoặc hủy hóa đơn điện tử\.

- Quyết định nghiệp vụ pháp lý của hóa đơn điện tử\.

- Hạch toán kế toán chi tiết\.

- Điều chỉnh kỳ kế toán hoặc kỳ thuế\.

- Cấu hình pricing policy\.

- Cấu hình promotion\.

- Cấu hình tax hoặc rounding rule\.

- Cấu hình danh mục phương thức thanh toán\.

- Workflow phê duyệt đổi/trả nhiều cấp trong Phase 1\.

- Cấu hình chính sách đổi/trả nâng cao theo ngành hàng nếu chưa có domain riêng\.

- Đính kèm hình ảnh, biên bản kiểm tra hoặc bằng chứng nâng cao nếu chưa nằm trong phạm vi Phase 1\.

- Báo cáo quản trị chuyên sâu về đổi/trả\.

- Reconciliation nghiệp vụ chi tiết bên trong Theme 6, Theme 7 hoặc Theme 8\.

### 4\.7\.5 Entry points

- Người dùng mở chi tiết đơn hàng trong EP\-03 và chọn **Đổi/trả hàng**\.

- Người dùng chọn đổi/trả từ menu thao tác của đơn hàng\.

- Người dùng mở đơn hàng từ lịch sử mua hàng của khách hàng trong Theme 3 và chọn đổi/trả\.

- Người dùng quét hoặc nhập mã đơn hàng trên màn hình bắt đầu đổi/trả\.

- Người dùng mở đơn hàng từ phiếu bán hàng nội bộ và chọn đổi/trả\.

- Người dùng mở lại một `ReturnExchangeOrder` ở trạng thái `draft`\.

- Người dùng mở chi tiết một phiếu đổi/trả đã xác nhận từ timeline hoặc return summary\.

- Người dùng quay lại flow sau khi xử lý pricing warning, permission hoặc dữ liệu bị stale\.

Trước khi hiển thị action **Đổi/trả hàng**, hệ thống phải xác định được:

- Tenant hiện tại\.

- Người dùng và membership đang hoạt động\.

- Permission tạo phiếu đổi/trả\.

- Store scope của đơn hàng nằm trong phạm vi được phép\.

- Đối tượng là `SalesOrder` chính thức\.

- Đơn hàng chưa bị hủy\.

- Đơn hàng không có cancellation đang được commit\.

- Đơn có ít nhất một dòng hàng còn số lượng có thể trả\.

Action có thể được hiển thị ở trạng thái disabled khi đơn không đủ điều kiện\. UI phải hiển thị blocker cụ thể, ví dụ:

- Đơn hàng đã bị hủy\.

- Đã trả toàn bộ hàng\.

- Đã quá thời hạn đổi/trả\.

- Đơn bị khóa\.

- Không có quyền thực hiện\.

- Có nghiệp vụ khác đang xử lý\.

Trước khi xác nhận phiếu, hệ thống phải kiểm tra lại:

- Đơn hàng vẫn tồn tại và thuộc tenant hiện tại\.

- Người dùng vẫn có permission\.

- Order lifecycle chưa thay đổi\.

- Lock status chưa thay đổi theo hướng bị chặn\.

- Đơn chưa bị hủy\.

- Số lượng còn có thể trả vẫn đủ\.

- Không có phiếu khác vừa reserve hoặc xác nhận cùng số lượng\.

- Các dòng hàng trả thuộc đơn hàng nguồn\.

- Return reason và disposition hợp lệ\.

- Hàng mới vẫn hợp lệ để bán\.

- Pricing của hàng mới vẫn hiện hành\.

- Inventory condition của hàng mới vẫn hợp lệ\.

- Settlement và khoản còn phải thu chưa thay đổi\.

- Return valuation vẫn chính xác\.

- Thu thêm hoặc hoàn tiền phù hợp với valuation\.

- Điều kiện công nợ vẫn hợp lệ\.

- E\-invoice eligibility chưa thay đổi\.

- Idempotency key hợp lệ\.

Khi precheck trả blocker, hệ thống phải:

- Không tạo phiếu đổi/trả chính thức\.

- Không cập nhật cumulative returned quantity\.

- Không ghi nhận payment hoặc refund transaction\.

- Không tạo receivable, inventory hoặc e\-invoice impact request\.

- Hiển thị lý do bị chặn\.

- Hướng dẫn người dùng xử lý theo flow phù hợp\.

Khi người dùng chọn số lượng trả vượt quá số lượng còn có thể trả, hệ thống phải:

- Không tự động giảm số lượng mà không thông báo\.

- Hiển thị số lượng đã bán, đã trả và còn có thể trả\.

- Yêu cầu người dùng điều chỉnh lại số lượng\.

Khi dữ liệu bị thay đổi bởi người dùng khác, hệ thống phải:

- Không tự động ghi đè hoặc merge\.

- Hiển thị version conflict\.

- Tải lại returnable quantity và valuation mới nhất\.

- Yêu cầu người dùng kiểm tra và xác nhận lại\.

EP\-06 kết thúc khi:

- Phiếu đổi/trả được xác nhận và người dùng xem màn kết quả\.

- Phiếu được xác nhận nhưng settlement hoặc downstream impacts tiếp tục ở trạng thái chờ\.

- Người dùng quay lại chi tiết đơn hàng gốc\.

- Người dùng xem hoặc in phiếu đổi/trả\.

- Người dùng lưu phiếu nháp và rời khỏi flow\.

- Người dùng hủy phiếu nháp\.

- Yêu cầu bị chặn và người dùng quay lại đơn hàng\.

- Xảy ra version conflict và người dùng tải lại dữ liệu\.

- Kết quả xác nhận chưa xác định và hệ thống kiểm tra lại theo idempotency context\.

- Người dùng chuyển sang Theme 6, Theme 7 hoặc Theme 8 để xem trạng thái xử lý chi tiết\.

### 4\.7\.6 User stories

#### 4\.7\.6\.1 User story map

|User story|As user|I want to|So that|Notes|
|---|---|---|---|---|
|US\-01 — Khởi tạo phiếu đổi/trả từ đơn hàng gốc|Người dùng có quyền đổi/trả|Bắt đầu một phiếu đổi/trả từ SalesOrder hợp lệ|Tôi có thể xử lý giao dịch sau bán dựa trên đúng đơn hàng và khách hàng nguồn|Hỗ trợ `standard` và `full_return_from_cancel_attempt`|
|US\-02 — Ghi nhận hàng khách trả|Người dùng xử lý đổi/trả|Chọn dòng hàng, số lượng, lý do và tình trạng hàng trả|Tôi có thể ghi nhận đúng hàng khách trả mà không vượt số lượng đã mua|Quick full\-return prefill toàn bộ quantity còn có thể trả|
|US\-03 — Ghi nhận hàng khách nhận đổi|Người dùng xử lý đổi/trả|Thêm sản phẩm, đơn vị bán và số lượng hàng khách nhận|Tôi có thể xử lý đổi sang hàng khác trong cùng nghiệp vụ|Dòng hàng đổi dùng sản phẩm và pricing hiện hành|
|US\-04 — Lưu và khôi phục phiếu đổi/trả nháp|Người dùng xử lý đổi/trả|Lưu, mở lại, cập nhật hoặc hủy phiếu đổi/trả đang lập|Tôi có thể tạm dừng nghiệp vụ phức tạp mà không tạo tác động chính thức|Draft phải được revalidate khi khôi phục|
|US\-05 — Xem giá trị và chênh lệch đổi/trả|Người dùng xử lý đổi/trả|Xem giá trị hàng trả, giá trị hàng đổi và chênh lệch cần quyết toán|Tôi biết cần thu thêm, hoàn tiền, giảm công nợ hay không phát sinh tiền|Full return có thể dẫn tới refund, receivable reversal hoặc mixed|
|US\-06 — Quyết toán chênh lệch đổi/trả|Người dùng có quyền quyết toán|Ghi nhận thu thêm, hoàn tiền, giảm/cấn trừ công nợ hoặc khoản còn phải thu phù hợp|Nghĩa vụ tài chính sau đổi/trả được xử lý đúng với khách hàng và policy|Đơn thanh toán một phần phải tách refund phần đã thu và reversal phần chưa thu|
|US\-07 — Xác nhận và theo dõi kết quả đổi/trả|Người dùng xử lý đổi/trả|Xác nhận phiếu và xem kết quả settlement, inventory, receivable cùng e\-invoice impacts|Tôi biết nghiệp vụ đã được ghi nhận và nội dung nào còn đang xử lý|`fully_returned` không đồng nghĩa `cancelled` và không phát `SalesOrderCancelled`|



#### 4\.7\.6\.2 US\-01 — Khởi tạo phiếu đổi/trả từ đơn hàng gốc

**Business context**

Đổi/trả luôn phải bắt đầu từ một SalesOrder chính thức để hệ thống xác định đúng hàng đã bán, customer context, commercial snapshot và các tác động tài chính liên quan\. Người dùng không được dùng flow đổi/trả như một cách tạo giao dịch bán mới độc lập\.

Flow có thể được mở theo cách chuẩn hoặc từ thao tác Hủy bị chặn vì đơn đã có tiền thực thu\. Trong trường hợp thứ hai, hệ thống cung cấp quick flow `Trả toàn bộ & hoàn tiền`, prefill toàn bộ số lượng còn có thể trả nhưng vẫn yêu cầu người dùng kiểm tra tình trạng hàng, lý do, valuation và settlement plan trước khi xác nhận\.

User Story bắt đầu khi người dùng chọn Đổi/trả hàng hoặc nhận action chuyển từ EP\-05 và kết thúc khi một `ReturnExchangeOrder` trạng thái `draft` được tạo hoặc precheck trả blocked\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền đổi/trả|Bắt đầu một phiếu đổi/trả từ SalesOrder hợp lệ|Tôi có thể xử lý giao dịch sau bán theo flow chuẩn hoặc quick full\-return phù hợp|



**Functional requirements**

- FR\-01: Hệ thống phải nhận `entry_mode` gồm `standard` hoặc `full_return_from_cancel_attempt`\.

- FR\-02: Hệ thống phải thực hiện `PrecheckReturnExchange` với sales\_order\_id, actor, store scope và entry mode hiện tại\.

- FR\-03: Precheck phải kiểm tra tenant, membership, permission, order lifecycle, lock status, thời hạn đổi/trả, source version và cancellation conflict\.

- FR\-04: Hệ thống phải thực hiện `GetReturnableOrderLines` để trả sold quantity, completed returned quantity, reserved quantity và returnable quantity của từng dòng\.

- FR\-05: Với `full_return_from_cancel_attempt`, hệ thống phải prefill toàn bộ dòng cùng quantity còn có thể trả, không tạo dòng exchange và đặt operation type dự kiến là `return`\.

- FR\-06: Khi đủ điều kiện, hệ thống phải thực hiện `StartReturnExchange` để tạo `ReturnExchangeOrder` trạng thái `draft` tham chiếu đúng SalesOrder và customer context\.

- FR\-07: Khi blocked, hệ thống phải trả blocker code, nội dung và hướng xử lý mà không tạo phiếu nháp hoặc tác động chính thức\.

    

**Business rules**

- BR\-01: Chỉ SalesOrder lifecycle `completed` mới đủ điều kiện bắt đầu đổi/trả\.

- BR\-02: SalesOrder lifecycle `cancelled` là hard blocker của đổi/trả\.

- BR\-03: SalesOrderCancellation trạng thái `confirmed`, `processing` hoặc `completed` là hard blocker; trạng thái `requested` hoặc `validating` phải được resolve trước\.

- BR\-04: `entry_mode` chỉ điều khiển prefill, navigation và UI flow; không phải lifecycle state hoặc loại nghiệp vụ mới\.

- BR\-05: `full_return_from_cancel_attempt` chỉ hợp lệ khi EP\-05 chặn cancellation do `net_confirmed_collection > 0` hoặc người dùng chủ động chọn quick full\-return từ đơn\.

- BR\-06: ReturnExchangeOrder hợp lệ cuối cùng phải có ít nhất một dòng `returned`; flow không được dùng để bán mới chỉ với dòng `exchange`\.

- BR\-07: `StartReturnExchange` chưa tạo payment, refund, receivable, inventory impact hoặc e\-invoice impact\.

    

**Acceptance criteria**

- AC\-01: Người dùng hợp lệ có thể khởi tạo phiếu nháp từ SalesOrder đủ điều kiện\.

- AC\-02: Entry mode chuẩn mở draft không tự prefill toàn bộ dòng hàng trả\.

- AC\-03: Entry mode quick full\-return prefill toàn bộ quantity còn có thể trả và không thêm dòng exchange\.

- AC\-04: Phiếu nháp tham chiếu đúng SalesOrder, customer context, cửa hàng nguồn và source context\.

- AC\-05: Đơn đã hủy hoặc có cancellation xung đột bị blocked\.

- AC\-06: Precheck hoặc khởi tạo draft không tạo tác động tài chính, tồn kho hoặc chứng từ\.

- AC\-07: Retry cùng idempotency context không tạo nhiều phiếu nháp cho cùng thao tác\.

    

**Edge cases**

- EC\-01: SalesOrder bị hủy ngay sau khi người dùng mở flow; backend dùng lifecycle mới nhất và chặn\.

- EC\-02: Cancellation request mới được tạo trong lúc precheck; hệ thống yêu cầu resolve operation cạnh tranh\.

- EC\-03: Một dòng vừa được trả bởi phiếu khác; quantity prefill phải được tính lại\.

- EC\-04: Một số dòng không còn quantity có thể trả; quick flow chỉ prefill phần còn lại và phải thông báo rõ phạm vi, hoặc blocked nếu không còn dòng nào\.

- EC\-05: Return window vừa hết hạn; hệ thống chặn theo thời điểm authoritative\.

- EC\-06: Draft trước đó đã tồn tại cho cùng source flow; hệ thống cho phép khôi phục theo policy thay vì tạo trùng\.

- EC\-07: Projection return summary đang chậm; `GetReturnableOrderLines` vẫn phải dựa trên authoritative hoặc reserved quantities hiện hành\.

    

**Scenarios**

```Gherkin
Feature: Khởi tạo phiếu đổi trả từ đơn hàng gốc

Scenario: SC-01 — Khởi tạo flow chuẩn
  Given người dùng có permission sales.return_exchange.create
  And SalesOrder lifecycle là completed
  And đơn còn ít nhất một dòng có thể trả
  When người dùng chọn Đổi trả hàng
  Then hệ thống thực hiện PrecheckReturnExchange với entry mode standard
  And tạo ReturnExchangeOrder status draft khi đủ điều kiện
  And không tự chọn toàn bộ dòng hàng trả

Scenario: SC-02 — Chuyển từ thao tác Hủy đã bị chặn
  Given EP-05 trả blocker PAYMENT_ALREADY_COLLECTED
  And người dùng chọn "Trả toàn bộ & hoàn tiền"
  When hệ thống mở EP-06
  Then entry mode là full_return_from_cancel_attempt
  And hệ thống prefill toàn bộ quantity còn có thể trả
  And không tạo dòng exchange

Scenario: SC-03 — Đơn đã hủy
  Given SalesOrder lifecycle là cancelled
  When người dùng mở flow đổi trả
  Then precheck trả blocked
  And không tạo ReturnExchangeOrder

Scenario: SC-04 — Cancellation đang xử lý
  Given SalesOrderCancellation status là validating
  When hệ thống thực hiện precheck
  Then kết quả là blocked hoặc conflict
  And yêu cầu resolve cancellation trước khi tiếp tục

Scenario: SC-05 — Không còn hàng có thể trả
  Given mọi SalesOrderLine đã được trả đủ qua các phiếu completed
  When hệ thống thực hiện GetReturnableOrderLines
  Then returnable quantity của mọi dòng bằng 0
  And precheck trả blocked

Scenario: SC-06 — Quick flow chỉ còn phần chưa trả
  Given đơn đã được trả một phần trước đó
  And vẫn còn quantity có thể trả
  When quick full-return được mở
  Then hệ thống prefill toàn bộ quantity còn lại
  And hiển thị rõ các quantity đã trả trước đó
  And không double count giá trị hàng trả

Scenario: SC-07 — Retry khởi tạo
  Given StartReturnExchange đã tạo draft với idempotency key "RE-01"
  When client gửi lại cùng request với key "RE-01"
  Then hệ thống trả cùng ReturnExchangeOrder
  And không tạo draft trùng
```

**References**

- Domains:

    - Post\-sale Operations

    - Sales Order Lifecycle

    - Sales Order Inquiry \& Documents

- Data:

    - `SalesOrder`

    - `SalesOrderLine`

    - `ReturnExchangeOrder`

    - `ReturnableOrderLineView`

    - `SalesOrderCancellation`

    - Entry context

    - Customer snapshot

- Commands / queries / events:

    - `PrecheckReturnExchange`

    - `GetReturnableOrderLines`

    - `StartReturnExchange`

    - `ReturnExchangeStarted`

- Permissions:

    - `sales.return_exchange.create`

    - `sales.order.view`

- External dependencies:

    - EP\-05 — Blocker `PAYMENT_ALREADY_COLLECTED` và action chuyển flow

    - Theme 1 — Tenant, membership, permission và store scope

    - Platform Audit — Entry source, precheck, blocked action và actor context

        

#### 4\.7\.6\.3 US\-02 — Ghi nhận hàng khách trả

**Business context**

Người dùng phải chọn chính xác dòng hàng trong SalesOrder gốc, số lượng khách trả, lý do và tình trạng hàng\. Số lượng trả không được vượt số lượng có thể trả sau khi trừ các lần trả hoàn tất và reservation còn hiệu lực\.

Trong quick full\-return, hệ thống chọn sẵn toàn bộ quantity còn có thể trả\. Người dùng vẫn phải kiểm tra tình trạng từng nhóm hàng và lý do; hệ thống không được mặc định mọi hàng trả đều có thể nhập lại tồn bán được\.

Giá trị hàng trả được xác định từ commercial snapshot của dòng hàng gốc và pricing impact do Theme 4 đánh giá\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng xử lý đổi/trả|Chọn hoặc kiểm tra dòng hàng, số lượng, lý do và tình trạng hàng trả|Tôi có thể ghi nhận đúng hàng khách trả mà không vượt số lượng đã mua|



**Functional requirements**

- FR\-01: Hệ thống phải hiển thị các SalesOrderLine có returnable quantity lớn hơn 0\.

- FR\-02: Cho phép thêm một hoặc nhiều dòng `returned` tham chiếu tới SalesOrderLine nguồn\.

- FR\-03: Với `full_return_from_cancel_attempt`, hệ thống phải prefill toàn bộ returnable lines và quantity hiện hành\.

- FR\-04: Mỗi dòng trả phải cho phép nhập hoặc xác nhận quantity, line reason code và item condition theo policy\.

- FR\-05: Hệ thống phải hiển thị sold quantity, completed returned quantity, reserved quantity và returnable quantity\.

- FR\-06: Hệ thống phải lấy giá trị tham chiếu từ commercial snapshot và gọi `EvaluateReturnPricingImpact`\.

- FR\-07: Sau mỗi thay đổi, hệ thống phải cập nhật draft, reservation nếu áp dụng, valuation preview và xác định quick flow còn là full return hay đã chuyển thành standard return\.

    

**Business rules**

- BR\-01: Dòng hàng trả có `line_role = returned` và bắt buộc tham chiếu một SalesOrderLine nguồn\.

- BR\-02: `returnable_quantity = sold_quantity - completed_returned_quantity - reserved_quantity`\.

- BR\-03: Quantity trả phải lớn hơn 0 và không vượt returnable quantity tại thời điểm xác nhận\.

- BR\-04: Product, unit, unit price, discount, tax và promotion context của hàng trả lấy từ commercial snapshot nguồn\.

- BR\-05: Trong quick full\-return, giảm hoặc xóa quantity được prefill làm flow không còn được coi là full return; hệ thống phải thông báo và chuyển sang standard return context\.

- BR\-06: Item condition phục vụ inventory disposition và không tự động quyết định stock movement khi chưa xác nhận phiếu\.

- BR\-07: Draft có thể giữ reservation để ngăn hai phiếu cùng sử dụng một returnable quantity, nhưng reservation chưa làm thay đổi return status chính thức\.

    

**Acceptance criteria**

- AC\-01: Người dùng chỉ chọn được dòng còn returnable quantity\.

- AC\-02: Quick full\-return prefill đúng toàn bộ quantity còn lại tại thời điểm mở\.

- AC\-03: Dòng returned lưu đúng source sales order line, quantity, reason và item condition\.

- AC\-04: Quantity vượt returnable amount bị chặn\.

- AC\-05: Giá trị hàng trả hiển thị theo commercial snapshot và pricing evaluation\.

- AC\-06: Thay đổi quantity cập nhật valuation preview và chuyển entry behavior khi không còn full return\.

- AC\-07: Draft chưa xác nhận không làm return status của SalesOrder chuyển sang partially hoặc fully returned\.

    

**Edge cases**

- EC\-01: Returnable quantity thay đổi do phiếu khác hoàn tất; backend trả conflict khi update hoặc confirm\.

- EC\-02: Dòng hàng có fractional quantity; validation dùng precision của unit snapshot\.

- EC\-03: Dòng đã được trả một phần; quick flow chỉ prefill phần còn lại\.

- EC\-04: Item condition bị vô hiệu hóa; hệ thống yêu cầu chọn lại condition hợp lệ\.

- EC\-05: Theme 4 không đánh giá được pricing impact; dòng được đánh dấu blocked và không cho confirm\.

- EC\-06: Người dùng xóa dòng returned cuối cùng; draft vẫn tồn tại nhưng không đủ điều kiện confirm\.

- EC\-07: Reservation hết hạn trong lúc draft mở; hệ thống phải re\-reserve hoặc yêu cầu tải lại quantity\.

    

**Scenarios**

```Gherkin
Feature: Ghi nhận hàng khách trả

Scenario: SC-01 — Thêm dòng trả hợp lệ
  Given SalesOrderLine đã bán 10 hộp
  And completed returned quantity là 2
  And reserved quantity là 1
  When người dùng chọn trả 3 hộp
  Then returnable quantity trước thao tác là 7
  And hệ thống thêm ReturnExchangeLine role returned quantity 3
  And tham chiếu đúng SalesOrderLine nguồn

Scenario: SC-02 — Prefill quick full-return
  Given entry mode là full_return_from_cancel_attempt
  And đơn có ba dòng còn quantity có thể trả
  When hệ thống khởi tạo draft
  Then cả ba dòng được prefill với toàn bộ returnable quantity
  And người dùng phải kiểm tra reason và item condition trước khi confirm

Scenario: SC-03 — Giảm quantity làm chuyển sang standard return
  Given quick flow đã prefill toàn bộ returnable quantity
  When người dùng giảm quantity của một dòng
  Then hệ thống thông báo đây không còn là full return
  And chuyển entry behavior sang standard return
  And valuation được tính lại

Scenario: SC-04 — Chặn số lượng vượt khả dụng
  Given returnable quantity là 4
  When người dùng nhập quantity trả là 5
  Then hệ thống từ chối
  And không cập nhật reservation hoặc valuation bằng quantity không hợp lệ

Scenario: SC-05 — Lấy giá trị theo commercial snapshot
  Given product master và giá hiện tại đã thay đổi
  When hệ thống định giá dòng returned
  Then hệ thống sử dụng commercial snapshot của SalesOrderLine nguồn
  And gọi EvaluateReturnPricingImpact
  And không dùng giá bán hiện tại như giá trị gốc

Scenario: SC-06 — Không mặc định hàng nhập lại kho bán được
  Given quick full-return đã prefill toàn bộ dòng hàng
  And một dòng có item condition chưa được xác định
  When người dùng chuyển sang xác nhận
  Then hệ thống chặn theo policy
  And yêu cầu xác định item condition
  And chưa tạo inventory impact

Scenario: SC-07 — Conflict do phiếu khác hoàn tất
  Given draft đang giữ quantity theo dữ liệu cũ
  And phiếu khác vừa completed làm giảm returnable quantity
  When người dùng cập nhật hoặc xác nhận draft
  Then backend trả quantity conflict
  And yêu cầu tải lại returnable lines
```

**References**

- Domains:

    - Post\-sale Operations

- Data:

    - `ReturnExchangeOrder`

    - `ReturnExchangeLine`

    - `ReturnableOrderLineView`

    - `SalesOrderLine`

    - Commercial snapshot

    - Reservation context

    - Entry context

- Commands / queries / events:

    - `GetReturnableOrderLines`

    - `UpdateReturnExchange`

    - `EvaluateReturnPricingImpact`

    - `ReturnExchangeValued`

- Permissions:

    - `sales.return_exchange.update`

- External dependencies:

    - Theme 4 — Return pricing impact

    - Theme 7 — Item condition và inventory disposition policy

        

#### 4\.7\.6\.4 US\-03 — Ghi nhận hàng khách nhận đổi

**Business context**

Trong nghiệp vụ đổi hoặc đổi kết hợp trả, khách có thể nhận sản phẩm khác\. Dòng hàng đổi sử dụng product, unit, pricing và inventory context hiện hành, không dùng snapshot cũ của hàng trả\.

Flow này không được dùng như một đơn bán mới độc lập\. Một phiếu có dòng exchange chỉ hợp lệ khi đồng thời có ít nhất một dòng returned\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng xử lý đổi/trả|Thêm sản phẩm, đơn vị bán và số lượng hàng khách nhận|Tôi có thể xử lý đổi sang hàng khác trong cùng nghiệp vụ|



**Functional requirements**

- FR\-01: Hệ thống phải cho phép tìm kiếm hoặc quét sản phẩm hiện hành đủ điều kiện bán\.

- FR\-02: Cho phép chọn product unit đang hoạt động và quantity hợp lệ\.

- FR\-03: Hệ thống phải thêm dòng `exchange` vào ReturnExchangeOrder draft\.

- FR\-04: Hệ thống phải lấy pricing preview hiện hành theo customer, product, unit, quantity, store và thời điểm\.

- FR\-05: Hệ thống phải kiểm tra inventory availability hoặc reservation theo tenant policy\.

- FR\-06: Cho phép cập nhật hoặc xóa dòng exchange trước confirmation\.

- FR\-07: Sau mỗi thay đổi, hệ thống phải cập nhật exchange value và valuation preview\.

    

**Business rules**

- BR\-01: Dòng hàng khách nhận có `line_role = exchange`\.

- BR\-02: Dòng exchange không bắt buộc tham chiếu SalesOrderLine nguồn nhưng phải thuộc cùng ReturnExchangeOrder\.

- BR\-03: Product và product unit phải còn hoạt động, có sellability hợp lệ và thuộc tenant hiện tại\.

- BR\-04: Giá của dòng exchange lấy từ Theme 4 theo context hiện hành và phải validate lại khi confirm\.

- BR\-05: Quantity phải lớn hơn 0 và tuân theo precision của product unit\.

- BR\-06: ReturnExchangeOrder không được confirm nếu chỉ có dòng exchange mà không có dòng returned\.

- BR\-07: Thêm dòng exchange trong draft chưa tạo SalesOrder mới, payment, receivable hoặc inventory movement\.

    

**Acceptance criteria**

- AC\-01: Người dùng có thể thêm sản phẩm và unit hợp lệ làm dòng exchange\.

- AC\-02: Pricing preview và exchange value được cập nhật đúng theo dữ liệu hiện hành\.

- AC\-03: Sản phẩm hoặc unit không còn bán được bị chặn\.

- AC\-04: Quantity không hợp lệ bị từ chối\.

- AC\-05: Inventory blocker được hiển thị theo tenant policy\.

- AC\-06: Xóa hoặc cập nhật dòng exchange làm valuation preview được tính lại\.

- AC\-07: Phiếu chỉ có dòng exchange không thể confirm\.

    

**Edge cases**

- EC\-01: Barcode ánh xạ nhiều product unit; hệ thống yêu cầu người dùng chọn kết quả\.

- EC\-02: Product bị ngừng bán sau khi thêm; confirm phải revalidate và chặn\.

- EC\-03: Giá thay đổi khi draft đang mở; preview cũ bị đánh dấu stale\.

- EC\-04: Inventory availability thay đổi; confirm phải kiểm tra lại\.

- EC\-05: Người dùng thêm cùng product và unit nhiều lần; hệ thống gộp hoặc giữ riêng theo line identity policy nhưng valuation không double count\.

- EC\-06: Dòng exchange có manual price; chỉ cho phép khi permission và Theme 4 policy cho phép\.

- EC\-07: Người dùng xóa toàn bộ dòng returned nhưng giữ exchange; action confirm bị chặn\.

    

**Scenarios**

```Gherkin
Feature: Ghi nhận hàng khách nhận đổi

Scenario: SC-01 — Thêm dòng exchange hợp lệ
  Given draft có ít nhất một dòng returned
  And sản phẩm B đang được phép bán
  And unit Hộp đang hoạt động
  When người dùng thêm sản phẩm B unit Hộp quantity 2
  Then hệ thống tạo ReturnExchangeLine role exchange
  And lấy pricing preview hiện hành
  And cập nhật exchange value

Scenario: SC-02 — Giá hiện hành được áp dụng
  Given giá của sản phẩm B hiện tại khác thời điểm đơn gốc
  When hệ thống định giá dòng exchange
  Then hệ thống sử dụng pricing context hiện hành
  And không dùng unit price của dòng hàng trả

Scenario: SC-03 — Product không còn bán được
  Given sản phẩm C đã bị ngừng bán
  When người dùng cố thêm sản phẩm C
  Then hệ thống chặn
  And không thêm dòng exchange

Scenario: SC-04 — Không đủ tồn kho
  Given tenant không cho phép âm kho
  And inventory availability nhỏ hơn quantity exchange
  When người dùng thêm hoặc xác nhận dòng exchange
  Then hệ thống hiển thị inventory blocker
  And không cho confirm theo flow thông thường

Scenario: SC-05 — Cập nhật quantity
  Given draft có dòng exchange quantity 1
  When người dùng đổi quantity thành 3
  Then hệ thống validate lại pricing và inventory
  And cập nhật exchange value cùng net difference

Scenario: SC-06 — Xóa dòng exchange
  Given draft có một dòng exchange
  When người dùng xóa dòng
  Then exchange value được tính lại
  And valuation preview được cập nhật

Scenario: SC-07 — Chặn phiếu chỉ có hàng exchange
  Given draft không còn dòng returned
  And vẫn có một hoặc nhiều dòng exchange
  When người dùng chọn Xác nhận
  Then hệ thống chặn
  And yêu cầu thêm ít nhất một dòng hàng trả
```

**References**

- Domains:

    - Post\-sale Operations

- Data:

    - `ReturnExchangeOrder`

    - `ReturnExchangeLine`

    - Product

    - Product Unit

    - Pricing preview

    - Inventory availability

- Commands / queries / events:

    - `UpdateReturnExchange`

    - Pricing preview contract của Theme 4

    - Inventory availability hoặc reservation contract

- Permissions:

    - `sales.return_exchange.update`

    - Permission manual price nếu áp dụng

- External dependencies:

    - Theme 2 — Product, Product Unit, barcode và sellability

    - Theme 4 — Pricing hiện hành

    - Theme 7 — Inventory availability hoặc reservation

        

#### 

- 

    

#### US\-04 — Giữ và bỏ thay đổi chưa xác nhận trong phiên đổi/trả



**Business context**



Trong Phase 1, người dùng thực hiện đổi/trả trong một flow liên tục từ chọn hàng đến quyết toán\. Hệ thống không cung cấp danh sách phiếu đổi/trả nháp, action Lưu và đóng hoặc chức năng người dùng chủ động mở lại một phiếu nháp từ màn hình khác\.



Dữ liệu đã chọn trước confirmation là working state của flow\. Hệ thống có thể duy trì technical draft để phục hồi lỗi trong phiên, nhưng technical draft không phải capability quản lý phiếu nháp dành cho người dùng\.



**Là** người dùng đang lập phiếu đổi/trả  

**Tôi muốn** dữ liệu đang chọn được giữ trong phiên và được cảnh báo trước khi bỏ  

**Để** tránh mất thay đổi ngoài ý muốn nhưng không phải quản lý thêm danh sách phiếu nháp



**Functional requirements**



FR\-01: Hệ thống phải giữ hàng trả, hàng đổi và dữ liệu quyết toán khi người dùng di chuyển giữa SG\-10 và SG\-11 trong cùng flow\.



FR\-02: Khi người dùng quay lại hoặc đóng flow mà có thay đổi chưa xác nhận, hệ thống phải hiển thị confirmation “Bỏ thay đổi?”\.



FR\-03: Chọn Tiếp tục đổi/trả phải giữ nguyên working state và quay lại flow\.



FR\-04: Chọn Bỏ thay đổi phải xóa working state hiện tại, cancel technical draft nếu có và release reservation liên quan theo policy\.



FR\-05: Phase 1 không hiển thị action Lưu và đóng, danh sách phiếu đổi/trả nháp hoặc entry point khôi phục draft do người dùng quản lý\.



FR\-06: Dữ liệu phải được revalidate khi chuyển sang quyết toán và khi xác nhận\.



**Business rules**



BR\-01: Working state chưa làm thay đổi SalesOrder return status, payment, receivable, inventory hoặc e\-invoice\.



BR\-02: Technical draft nếu được sử dụng chỉ phục vụ consistency/recovery và không được trình bày như một phiếu nghiệp vụ chính thức\.



BR\-03: Phiếu đổi/trả chính thức chỉ trở thành business fact sau confirmation thành công\.



BR\-04: Bỏ thay đổi không tạo payment, refund, receivable hoặc inventory impact\.



BR\-05: Version conflict không được tự merge dòng hàng hoặc settlement plan\.



BR\-06: Reservation phải được release khi flow bị bỏ, hết hạn hoặc không còn hợp lệ\.



**User Interface**



- Khi thoát flow có thay đổi, hiển thị confirmation sheet gồm “Tiếp tục đổi/trả” và “Bỏ thay đổi”\.

- Không có CTA “Lưu và đóng”\.

- Không có danh sách hoặc badge phiếu đổi/trả nháp\.

#### 4\.7\.6\.6 US\-05 — Xem giá trị và chênh lệch đổi/trả

**Business context**

Sau khi nhập hàng trả và hàng đổi, người dùng cần biết giá trị được ghi nhận cho mỗi phía và chênh lệch cần quyết toán\. Valuation phải phản ánh commercial snapshot của hàng trả, pricing hiện hành của hàng đổi, promotion/tax allocation và rounding rule\.

Với quick full\-return từ EP\-05, không có dòng exchange nên toàn bộ giá trị được ghi nhận là nghĩa vụ kinh tế có lợi cho khách\. Phần này có thể được phân bổ thành refund tiền đã thu, giảm hoặc đảo khoản phải thu chưa thu, hoặc kết hợp cả hai\.

Valuation chỉ là kết quả tính toán của ReturnExchangeOrder; nó không phải payment transaction, refund transaction hoặc receivable ledger entry\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng xử lý đổi/trả|Xem giá trị hàng trả, giá trị hàng đổi và chênh lệch cần quyết toán|Tôi biết cần thu thêm, hoàn tiền, giảm công nợ hay không phát sinh tiền|



**Functional requirements**

- FR\-01: Hệ thống phải tính `return_value` từ các dòng returned đã được Theme 4 đánh giá\.

- FR\-02: Hệ thống phải tính `exchange_value` từ các dòng exchange theo pricing hiện hành đã validate\.

- FR\-03: Hệ thống phải tính `net_difference = exchange_value - return_value`\.

- FR\-04: Hệ thống phải xác định `required_settlement_type` gồm `none`, `collect`, `refund`, `receivable_offset` hoặc `mixed`\.

- FR\-05: Với full return, hệ thống phải hiển thị phần giá trị dự kiến được phân bổ thành refund, receivable reversal hoặc mixed dựa trên settlement và receivable hiện hành\.

- FR\-06: Valuation phải lưu chi tiết pricing, promotion allocation, tax allocation và rounding cần thiết để giải thích kết quả\.

- FR\-07: Valuation phải được tính lại khi dòng hàng, quantity, customer, pricing, settlement context hoặc policy thay đổi\.

    

**Business rules**

- BR\-01: `net_difference > 0` nghĩa là khách phải trả thêm\.

- BR\-02: `net_difference < 0` nghĩa là doanh nghiệp phải ghi nhận lợi ích cho khách bằng refund, receivable reversal/offset hoặc mixed\.

- BR\-03: `net_difference = 0` nghĩa là không phát sinh nghĩa vụ tiền mới\.

- BR\-04: Với full return không có dòng exchange, `exchange_value = 0` và `net_difference = -return_value`\.

- BR\-05: `receivable_offset` trong EP\-06 bao gồm giảm hoặc đảo nghĩa vụ phải thu hiện hữu do hàng được trả; không tạo customer credit mới\.

- BR\-06: `ReturnExchangeValuation` không sở hữu authoritative payment, refund hoặc receivable totals và không được dùng để double count lợi ích cho khách\.

- BR\-07: Valuation stale hoặc blocked không được dùng để confirm\.

    

**Acceptance criteria**

- AC\-01: Return value khớp tổng giá trị các dòng returned đã được evaluate\.

- AC\-02: Exchange value khớp tổng giá trị các dòng exchange đã được validate\.

- AC\-03: Net difference được tính đúng và hiển thị rõ dấu nghĩa vụ\.

- AC\-04: Full return hiển thị đúng giá trị dự kiến hoàn, giảm công nợ hoặc mixed\.

- AC\-05: Required settlement type phù hợp với net difference, settlement context và customer policy\.

- AC\-06: Allocation và rounding details có thể truy vết\.

- AC\-07: Valuation chưa tạo payment, refund hoặc receivable transaction\.

    

**Edge cases**

- EC\-01: Chênh lệch bằng 0 sau rounding; settlement type là none\.

- EC\-02: Promotion allocation không thể xác định; valuation bị blocked\.

- EC\-03: Giá dòng exchange thay đổi sau khi valuation được tính; valuation cũ trở thành stale\.

- EC\-04: Khách lẻ có chênh lệch âm; chỉ được refund trực tiếp, không được receivable offset\.

- EC\-05: Settlement hoặc receivable thay đổi sau valuation; allocation dự kiến trở thành stale\.

- EC\-06: Một phần giá trị hàng trả không được hoàn theo policy; valuation phải thể hiện adjustment rõ ràng\.

- EC\-07: Currency precision làm chênh lệch rất nhỏ; rounding rule quyết định kết quả cuối\.

    

**Scenarios**

```Gherkin
Feature: Xem giá trị và chênh lệch đổi trả

Scenario: SC-01 — Khách phải trả thêm
  Given return value là 800.000 đồng
  And exchange value là 1.000.000 đồng
  When hệ thống tính valuation
  Then net difference là 200.000 đồng
  And required settlement type là collect

Scenario: SC-02 — Doanh nghiệp phải hoàn tiền
  Given return value là 1.000.000 đồng
  And exchange value là 600.000 đồng
  When hệ thống tính valuation
  Then net difference là -400.000 đồng
  And required settlement type là refund hoặc receivable_offset theo policy

Scenario: SC-03 — Full return đơn đã thanh toán đủ
  Given entry mode là full_return_from_cancel_attempt
  And return value là 1.000.000 đồng
  And exchange value bằng 0
  And net confirmed collection đủ để hoàn 1.000.000 đồng
  When hệ thống tính valuation
  Then net difference là -1.000.000 đồng
  And required settlement type là refund

Scenario: SC-04 — Full return đơn thanh toán một phần
  Given return value là 1.000.000 đồng
  And net confirmed collection là 400.000 đồng
  And outstanding receivable là 600.000 đồng
  When hệ thống xác định allocation dự kiến
  Then required settlement type là mixed
  And dự kiến refund 400.000 đồng
  And dự kiến receivable reversal 600.000 đồng

Scenario: SC-05 — Không phát sinh chênh lệch
  Given return value bằng exchange value
  When hệ thống tính valuation
  Then net difference bằng 0
  And required settlement type là none

Scenario: SC-06 — Valuation stale do settlement thay đổi
  Given valuation dự kiến refund và receivable reversal
  And settlement hoặc receivable context đã thay đổi
  When người dùng mở valuation cũ
  Then hệ thống đánh dấu stale
  And yêu cầu tính lại trước khi confirm

Scenario: SC-07 — Chưa tạo transaction
  Given valuation đã xác định net difference
  When người dùng chưa xác nhận quyết toán
  Then không có SalesPaymentTransaction mới
  And không có receivable ledger entry mới
```

**References**

- Domains:

    - Post\-sale Operations

    - Sales Settlement

- Data:

    - `ReturnExchangeValuation`

    - `ReturnExchangeLine`

    - Pricing allocation

    - Tax allocation

    - Settlement allocation preview

    - Rounding detail

- Commands / queries / events:

    - `EvaluateReturnPricingImpact`

    - `UpdateReturnExchange`

    - `ReturnExchangeValued`

    - `GetSalesOrderSettlement`

- Permissions:

    - `sales.return_exchange.view`

    - `sales.return_exchange.update`

- External dependencies:

    - Theme 4 — Return pricing impact, promotion và allocation

    - Theme 6 — Receivable context

    - Theme 1 — Currency và rounding policy

        

#### 4\.7\.6\.7 US\-06 — Quyết toán chênh lệch đổi/trả

**Business context**

Sau valuation, chênh lệch phải được xử lý theo một hoặc nhiều cách: thu thêm, hoàn tiền, giảm hoặc cấn trừ công nợ, hoặc ghi nhận khoản còn phải thu\. Cách xử lý phụ thuộc dấu chênh lệch, customer context, settlement hiện hành, permission và tenant policy\.

Đối với full return của đơn đã thanh toán một phần, settlement plan phải tách rõ phần tiền thực thu cần hoàn và phần khoản phải thu chưa thu cần đảo\. Hai phần cộng lại phải cân bằng giá trị được ghi nhận cho khách mà không double count\.

Sales Settlement sở hữu payment/refund transaction\. Theme 6 sở hữu receivable ledger\. EP\-06 chỉ xác định settlement requirement và chuyển đúng command hoặc impact sang owner domain\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng có quyền quyết toán|Ghi nhận thu thêm, hoàn tiền, giảm/cấn trừ công nợ hoặc khoản còn phải thu phù hợp|Nghĩa vụ tài chính sau đổi/trả được xử lý đúng với khách hàng và policy|



**Functional requirements**

- FR\-01: Khi `net_difference > 0`, hệ thống phải cho phép payment intent và/hoặc receivable requirement theo customer policy\.

- FR\-02: Khi `net_difference < 0`, hệ thống phải cho phép refund intent, receivable reversal/offset hoặc kết hợp\.

- FR\-03: Với full return, hệ thống phải phân bổ giá trị giữa refund phần đã thu và receivable reversal phần chưa thu dựa trên authoritative settlement cùng ledger context\.

- FR\-04: Hệ thống phải kiểm tra customer identity, credit eligibility, outstanding receivable, permission và settlement policy\.

- FR\-05: Thu thêm phải thực hiện qua `RecordSalesPayment`; hoàn tiền phải thực hiện qua `RecordSalesRefund`\.

- FR\-06: Receivable offset, reversal hoặc khoản còn phải thu phải tạo impact/request cho Theme 6 thay vì sửa ledger trực tiếp\.

- FR\-07: Hệ thống phải hiển thị settlement plan, số đã xử lý, số pending, phần còn lại và blocker trước confirmation\.

    

**Business rules**

- BR\-01: Khách lẻ không được phát sinh receivable mới hoặc receivable offset/reversal ngoài khoản ledger không tồn tại\.

- BR\-02: Tổng collect intent và receivable requirement không được vượt net difference dương\.

- BR\-03: Tổng refund intent cộng receivable reversal/offset không được vượt giá trị tuyệt đối của net difference âm\.

- BR\-04: Với full return của đơn thanh toán một phần, `refund_amount + receivable_reversal_amount` phải cân bằng giá trị được xử lý cho khách, sau khi tính prior refund, prior return và policy adjustments\.

- BR\-05: Payment/refund transaction chỉ được tạo sau confirmation và phải tham chiếu ReturnExchangeOrder nguồn\.

- BR\-06: Payment/refund transaction đã recorded không được sửa trực tiếp; receivable ledger chỉ được thay đổi bởi Theme 6\.

- BR\-07: Lỗi của một owner domain không được che giấu; phiếu chuyển `processing`, `blocked`, `failed` hoặc `reconciliation_required` theo kết quả và correlation context\.

    

**Acceptance criteria**

- AC\-01: Net difference dương được quyết toán bằng collect, receivable hoặc mixed đúng policy\.

- AC\-02: Net difference âm được quyết toán bằng refund, receivable reversal/offset hoặc mixed đúng policy\.

- AC\-03: Full return của đơn thanh toán một phần tách đúng refund phần đã thu và reversal phần chưa thu\.

- AC\-04: Khách lẻ bị chặn khỏi receivable mới hoặc offset không hợp lệ\.

- AC\-05: Payment, refund và receivable impact tham chiếu đúng ReturnExchangeOrder và không vượt nghĩa vụ\.

- AC\-06: Settlement plan hiển thị đúng phần đã xử lý, pending và còn lại\.

- AC\-07: Retry cùng idempotency context không tạo transaction hoặc impact trùng\.

    

**Edge cases**

- EC\-01: Người dùng nhập collect hoặc refund vượt chênh lệch; hệ thống chặn\.

- EC\-02: Receivable eligibility hoặc outstanding amount thay đổi trước confirmation; backend dùng trạng thái mới nhất\.

- EC\-03: Prior refund mới được ghi nhận; refund capacity phải được tính lại để tránh hoàn trùng\.

- EC\-04: Payment method bị vô hiệu hóa; người dùng phải chọn lại\.

- EC\-05: Refund commit thành công nhưng response mất; query lại trả transaction đã có\.

- EC\-06: Theme 6 từ chối receivable impact; phiếu chuyển `reconciliation_required` hoặc `blocked` theo policy\.

- EC\-07: Mixed plan chỉ commit một phần; hệ thống theo dõi phần đã commit và phần pending, không double count khi retry\.

    

**Scenarios**

```Gherkin
Feature: Quyết toán chênh lệch đổi trả

Scenario: SC-01 — Thu thêm toàn bộ
  Given net difference là 300.000 đồng
  And người dùng nhập payment intent 300.000 đồng
  When phiếu được xác nhận
  Then hệ thống thực hiện RecordSalesPayment
  And tạo payment transaction tham chiếu ReturnExchangeOrder
  And settlement requirement được đáp ứng

Scenario: SC-02 — Hoàn tiền toàn bộ
  Given net difference là -400.000 đồng
  And net confirmed collection đủ để hoàn 400.000 đồng
  When người dùng chọn refund 400.000 đồng
  And phiếu được xác nhận
  Then hệ thống thực hiện RecordSalesRefund
  And tạo refund transaction 400.000 đồng
  And không tạo receivable reversal

Scenario: SC-03 — Trả toàn bộ đơn đã thanh toán một phần
  Given return value là 1.000.000 đồng
  And khách đã thanh toán 400.000 đồng
  And outstanding receivable là 600.000 đồng
  When người dùng xác nhận full return
  Then hệ thống tạo refund requirement 400.000 đồng
  And tạo receivable reversal requirement 600.000 đồng
  And settlement plan được cân bằng toàn bộ
  And không double count lợi ích cho khách

Scenario: SC-04 — Cấn trừ công nợ trong đổi trả
  Given khách hàng định danh có outstanding receivable đủ điều kiện
  And net difference là -500.000 đồng
  When người dùng chọn receivable offset 500.000 đồng
  Then hệ thống tạo ReceivableImpactRequest
  And không trực tiếp sửa receivable ledger

Scenario: SC-05 — Chặn Khách lẻ dùng công nợ
  Given customer context là Khách lẻ
  And net difference âm
  When người dùng chọn receivable offset
  Then hệ thống chặn
  And yêu cầu refund theo phương thức hợp lệ

Scenario: SC-06 — Không phát sinh tiền
  Given net difference bằng 0
  When người dùng chuyển sang confirmation
  Then hệ thống không yêu cầu payment hoặc refund intent
  And settlement type là none

Scenario: SC-07 — Theme 6 từ chối impact
  Given ReceivableImpactRequest đã được gửi
  And Theme 6 trả business rejection
  When người dùng xem kết quả
  Then phiếu hiển thị reconciliation_required hoặc blocked theo policy
  And không dùng technical retry để vượt business rejection
```

**References**

- Domains:

    - Sales Settlement

    - Post\-sale Operations

    - Cross\-cutting Foundations

- Data:

    - `ReturnExchangeValuation`

    - Settlement plan

    - `SalesPaymentTransaction`

    - `ReceivableImpactRequest`

    - Payment intent

    - Refund intent

- Commands / queries / events:

    - `RecordSalesPayment`

    - `RecordSalesRefund`

    - `ApplyReceivableCollection`

    - Receivable impact contract của Theme 6

    - `SalesPaymentRecorded`

    - `SalesRefundRecorded`

- Permissions:

    - `sales.payment.record`

    - `sales.refund.record`

    - Permission tạo, giảm hoặc offset công nợ

- External dependencies:

    - Theme 3 — Customer identity và eligibility

    - Theme 6 — Receivable ledger

    - Theme 1 — Payment, credit và permission policy

        

#### 4\.7\.6\.8 US\-07 — Xác nhận và theo dõi kết quả đổi/trả

**Business context**

Confirmation là thời điểm phiếu đổi/trả trở thành business fact chính thức\. Hệ thống phải revalidate source order, quantities, pricing, inventory, settlement plan, cancellation conflict và permission trước khi commit\.

ReturnExchangeOrder chuyển từ `draft` sang `confirmed`, sau đó `processing` khi các owner domain xử lý impacts\. Phiếu chuyển `completed` khi các business requirement bắt buộc đã được ghi nhận theo policy\.

Với quick full\-return từ thao tác Hủy, kết quả vẫn là một ReturnExchangeOrder hoàn tất\. SalesOrder gốc giữ lifecycle `completed`, return status có thể chuyển `fully_returned`, và hệ thống không phát `SalesOrderCancelled`\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Người dùng xử lý đổi/trả|Xác nhận phiếu và xem kết quả settlement, inventory, receivable cùng e\-invoice impacts|Tôi biết nghiệp vụ đã được ghi nhận và nội dung nào còn đang xử lý|



**Functional requirements**

- FR\-01: Hệ thống phải thực hiện `ConfirmReturnExchange` với return exchange ID, expected version, lines, valuation, settlement plan, reason, actor và idempotency context\.

- FR\-02: Backend phải validate lại permission, source order lifecycle, cancellation conflict, returnable quantity, products, units, pricing, inventory và settlement requirement\.

- FR\-03: Khi hợp lệ, ReturnExchangeOrder phải chuyển `draft → confirmed` và phát `ReturnExchangeConfirmed`\.

- FR\-04: Hệ thống phải tạo durable impact/outbox records cho Inventory, Settlement, Receivable, Pricing và E\-invoice theo điều kiện\.

- FR\-05: Phiếu phải chuyển sang `processing` trong khi các business requirement bắt buộc đang được thực hiện\.

- FR\-06: Khi các requirement bắt buộc đã được ghi nhận, hệ thống phải thực hiện `CompleteReturnExchange`, chuyển phiếu sang `completed` và cập nhật return status của SalesOrder\.

- FR\-07: Result summary phải hiển thị entry source, return status, settlement summary và integration status; hỗ trợ truy vấn lại khi timeout hoặc uncertain\.

    

**Business rules**

- BR\-01: Confirm bắt buộc có ít nhất một dòng `returned`\.

- BR\-02: `ConfirmReturnExchange` phải idempotent; cùng key và payload trả cùng result, payload khác trả conflict\.

- BR\-03: Returnable quantity, valuation và settlement plan phải còn hợp lệ tại command time\.

- BR\-04: SalesOrder gốc và SalesOrderLine không được sửa hoặc xóa; return status được cập nhật như một chiều trạng thái độc lập\.

- BR\-05: Return status chuyển `none → partially_returned → fully_returned` theo completed returned quantities\.

- BR\-06: `fully_returned` không chuyển order lifecycle sang `cancelled` và không phát `SalesOrderCancelled`\.

- BR\-07: Downstream delivery pending, failed hoặc reconciliation\_required không tự động rollback ReturnExchangeOrder đã confirmed hoặc mở lại SalesOrder\.

    

**Acceptance criteria**

- AC\-01: Request hợp lệ tạo đúng một confirmation cho ReturnExchangeOrder\.

- AC\-02: Phiếu lưu đúng lines, valuation, settlement plan, reason, actor, source version và entry source\.

- AC\-03: Returnable quantities không bị vượt khi nhiều phiếu cạnh tranh\.

- AC\-04: SalesOrder return status cập nhật đúng sau khi phiếu completed\.

- AC\-05: Full return từ thao tác Hủy kết thúc với return status phù hợp, không chuyển order lifecycle sang cancelled\.

- AC\-06: Retry cùng idempotency context không tạo impact hoặc transaction trùng\.

- AC\-07: Result summary phân biệt business completion với downstream pending hoặc failure\.

    

**Edge cases**

- EC\-01: Người dùng double tap CTA; client khóa action và backend idempotency ngăn duplicate\.

- EC\-02: Returnable quantity giảm sau precheck; confirmation trả conflict\.

- EC\-03: Pricing, settlement hoặc inventory thay đổi; backend revalidate và có thể blocked\.

- EC\-04: Confirmation commit thành công nhưng response mất; query lại trả phiếu hiện có\.

- EC\-05: Một impact owner xử lý chậm; phiếu giữ `processing` và không cho confirm lại\.

- EC\-06: Business impact bị rejected; phiếu chuyển `blocked`, `failed` hoặc `reconciliation_required` theo policy\.

- EC\-07: Projection return status chậm; UI hiển thị đang cập nhật và không tạo phiếu mới\.

    

**Scenarios**

```Gherkin
Feature: Xác nhận và theo dõi kết quả đổi trả

Scenario: SC-01 — Xác nhận phiếu thành công
  Given ReturnExchangeOrder status là draft
  And có ít nhất một dòng returned
  And valuation cùng settlement plan hợp lệ
  And authoritative state chưa thay đổi
  When người dùng thực hiện ConfirmReturnExchange
  Then status chuyển sang confirmed
  And phát ReturnExchangeConfirmed
  And tạo các impact hoặc outbox record cần thiết
  And phiếu chuyển sang processing

Scenario: SC-02 — Hoàn tất nghiệp vụ
  Given ReturnExchangeOrder đang processing
  And các business requirement bắt buộc đã được ghi nhận
  When hệ thống thực hiện CompleteReturnExchange
  Then status chuyển sang completed
  And phát ReturnExchangeCompleted
  And cập nhật SalesOrder return status

Scenario: SC-03 — Trả một phần đơn
  Given completed returned quantity nhỏ hơn toàn bộ sold quantity đủ điều kiện
  When phiếu mới completed
  Then return status là partially_returned
  And order lifecycle vẫn là completed

Scenario: SC-04 — Hoàn tất full return từ thao tác Hủy
  Given entry mode là full_return_from_cancel_attempt
  And toàn bộ quantity còn có thể trả đã được confirmed
  When ReturnExchangeOrder hoàn tất
  Then SalesOrder return status là fully_returned
  And SalesOrder lifecycle vẫn là completed
  And không phát SalesOrderCancelled

Scenario: SC-05 — Result của đơn thanh toán một phần
  Given full return đã tạo refund cho phần tiền đã thu
  And receivable reversal cho phần chưa thu
  When người dùng xem result summary
  Then hệ thống hiển thị hai impact riêng
  And tổng settlement plan cân bằng return value
  And không trình bày nghiệp vụ như cancellation

Scenario: SC-06 — Retry cùng confirmation
  Given ConfirmReturnExchange đã thành công với idempotency key "REC-01"
  When client gửi lại cùng payload với key "REC-01"
  Then hệ thống trả cùng ReturnExchangeOrder
  And không tạo payment, refund hoặc impact trùng

Scenario: SC-07 — Downstream inventory failed
  Given ReturnExchangeOrder đã confirmed
  And Inventory impact delivery bị failed
  When người dùng xem kết quả
  Then phiếu vẫn hiển thị confirmed hoặc processing theo local state
  And hiển thị Inventory failure riêng
  And không tự động rollback phiếu hoặc sửa SalesOrder gốc
```

**References**

- Domains:

    - Post\-sale Operations

    - Sales Order Lifecycle

    - Sales Settlement

    - Sales Order Inquiry \& Documents

    - Cross\-cutting Foundations

- Data:

    - `ReturnExchangeOrder`

    - `ReturnExchangeLine`

    - `ReturnExchangeValuation`

    - `SalesOrder`

    - `SalesOrderReturnSummaryView`

    - `SalesPaymentTransaction`

    - `InventoryImpactRequest`

    - `ReceivableImpactRequest`

    - `EInvoiceImpactRequest`

    - `OutboxMessage`

    - Entry context

- Commands / queries / events:

    - `ConfirmReturnExchange`

    - `CompleteReturnExchange`

    - `RecordSalesPayment`

    - `RecordSalesRefund`

    - `EvaluateReturnPricingImpact`

    - `ReturnExchangeConfirmed`

    - `ReturnExchangeValued`

    - `ReturnExchangeCompleted`

    - `GetSalesOrderReturnSummary`

    - `GetOrderIntegrationStatus`

- Permissions:

    - `sales.return_exchange.confirm`

    - `sales.return_exchange.complete`

    - `sales.return_exchange.view`

    - `sales.payment.record`

    - `sales.refund.record`

    - `sales.integration.view_sync_status`

- External dependencies:

    - Theme 4 — Return pricing impact

    - Theme 6 — Receivable

    - Theme 7 — Inventory

    - Theme 8 — E\-invoice

    - Theme 10 — Reporting projection

    - Platform Audit — Entry source, confirmation, payment/refund, blocked và reconciliation history

# 5\. UI/UX Design

## 5\.1 Design principles

Theme 5 áp dụng các nguyên tắc thiết kế chung của VET45 Product Vision và VET45 Design System, đồng thời bổ sung các nguyên tắc riêng cho hành trình bán hàng, thanh toán và xử lý sau bán\.

### 5\.1\.1 Mobile first, not mobile only

Các hành trình chính phải được thiết kế hoàn chỉnh trên mobile trước, đặc biệt trong bối cảnh nhân viên đang phục vụ khách hàng tại cửa hàng\.

- Các thao tác thường xuyên phải thực hiện thuận tiện bằng một tay\.

- Primary action cần nằm trong vùng dễ tiếp cận\.

- Tổng tiền và hành động tiếp theo phải luôn dễ nhận biết\.

- Keyboard, bottom sheet và sticky CTA không được che nội dung quan trọng\.

- Tablet và web có thể mở rộng bố cục nhưng không làm thay đổi business flow\.

    

### 5\.1\.2 Business\-flow first

UX phải phản ánh cách người dùng hoàn thành công việc thực tế, không phản ánh cấu trúc domain, entity hoặc module kỹ thuật\.

Luồng bán hàng chính được tổ chức liên tục:

> Tạo hoặc mở đơn nháp → thêm sản phẩm → gắn khách hàng nếu cần → thanh toán → hoàn tất đơn → xem kết quả giao dịch\.
> 
> Các khả năng chọn sản phẩm, chọn khách hàng, áp dụng giá, ghi nhận thanh toán, tạo công nợ và tác động tồn kho có thể thuộc các domain khác nhau nhưng phải tạo thành một trải nghiệm thống nhất\.
> 
> 

### 5\.1\.3 Clear over clever

Giao diện ưu tiên ngôn ngữ vận hành rõ ràng hơn cách diễn đạt sáng tạo hoặc mang tính kỹ thuật\.

- Label phải phản ánh đúng hành động nghiệp vụ\.

- Icon quan trọng cần đi kèm text\.

- Trạng thái phải được diễn đạt bằng ngôn ngữ người dùng hiểu được\.

- Không hiển thị trực tiếp tên event, integration job hoặc trạng thái kỹ thuật nếu người dùng không cần biết\.

- Khi có lỗi, giao diện phải cho biết điều gì xảy ra và người dùng nên làm gì tiếp theo\.

    

### 5\.1\.4 One primary action per screen

Mỗi màn hình hoặc trạng thái chính phải xác định một primary action rõ ràng\.

|Screen context|Primary action|
|---|---|
|Bán hàng \& đơn nháp|Tạo đơn mới hoặc Tiếp tục đơn|
|Soạn đơn bán hàng|Thanh toán|
|Chọn sản phẩm|Thêm vào đơn|
|Chọn khách hàng|Gắn vào đơn|
|Thanh toán|Xác nhận thanh toán|
|Kết quả giao dịch|Tạo đơn mới|
|Danh sách đơn|Tạo đơn|
|Điều chỉnh đơn|Lưu điều chỉnh|
|Hủy đơn|Xác nhận hủy đơn|
|Lập yêu cầu đổi/trả|Tiếp tục quyết toán|
|Quyết toán chênh lệch|Xác nhận đổi/trả|



Secondary và contextual actions không được cạnh tranh thị giác với primary action\. Destructive action phải được phân biệt rõ và yêu cầu xác nhận phù hợp\.

### 5\.1\.5 Progressive disclosure

Chỉ hiển thị thông tin cần thiết cho bước hiện tại; thông tin mở rộng được cung cấp khi người dùng cần kiểm tra sâu hơn\.

- Tổng tiền, số đã thanh toán, số còn phải thu và trạng thái đơn được ưu tiên\.

- Commercial snapshot chi tiết được mở rộng từ chi tiết đơn\.

- Timeline và integration status không chiếm không gian của hot path\.

- Các action ít dùng được đặt trong contextual action sheet\.

- Thông tin kỹ thuật phục vụ đối soát chỉ xuất hiện khi có lỗi hoặc trạng thái bất thường\.

    

### 5\.1\.6 Prevent business errors

Theme 5 tạo dữ liệu nguồn cho doanh thu, thanh toán, công nợ, tồn kho, hóa đơn và báo cáo\. Vì vậy, validation phải ưu tiên ngăn lỗi nghiệp vụ trước khi giao dịch được ghi nhận\.

- Không cho thanh toán nếu đơn chưa có dòng hàng hợp lệ\.

- Không cho ghi nhận số tiền không phù hợp với tổng cần thu\.

- Cảnh báo hoặc chặn khi giá, sản phẩm, khách hàng hoặc tồn kho không còn hợp lệ\.

- Revalidate dữ liệu ngay trước khi tạo official order\.

- Không cho submit lặp lại khi checkout đang xử lý hoặc có kết quả chưa xác định\.

- Bắt buộc xác nhận đối với hành động hủy, đổi/trả hoặc thay đổi có ảnh hưởng nghiệp vụ\.

    

### 5\.1\.7 Transaction state transparency

Người dùng phải luôn nhận biết được giao dịch đang ở trạng thái nào\.

Các chiều trạng thái không được gộp thành một label mơ hồ:

- Order lifecycle\.

- Lock status\.

- Payment status\.

- Return status\.

- Adjustment indicator\.

- Business integration status\.

- Delivery status\.

    

Giao diện chỉ tổng hợp các chiều trạng thái khi summary không làm mất thông tin quan trọng\. Chi tiết đơn phải cho phép người dùng kiểm tra từng trạng thái có liên quan\.

### 5\.1\.8 Preserve the original transaction

Official order là authoritative record và không được sửa tùy tiện sau khi hoàn tất\.

- Điều chỉnh sau bán phải tạo adjustment record và audit trail\.

- Không dùng flow điều chỉnh để sửa sản phẩm, số lượng, giá, chiết khấu, tổng tiền hoặc thanh toán\.

- Đơn chưa thanh toán có thể được hủy khi đáp ứng đầy đủ điều kiện\.

- Đơn đã có thanh toán không được hủy; người dùng được hướng sang đổi/trả và quyết toán\.

- Nghiệp vụ đổi/trả phải giữ liên kết với đơn gốc và không viết lại commercial snapshot ban đầu\.

    

### 5\.1\.9 Fast on the happy path, safe on exception paths

Core selling là luồng có tần suất cao nên cần tối ưu tốc độ\. Post\-sale có tần suất thấp hơn nhưng rủi ro dữ liệu và tài chính cao nên cần kiểm soát chặt hơn\.

- Happy path hạn chế số bước và thao tác không cần thiết\.

- Dữ liệu có thể tự động điền khi có nguồn đáng tin cậy\.

- Warning không chặn không được làm gián đoạn luồng quá mức\.

- Blocked state phải giải thích nguyên nhân và cung cấp đường xử lý\.

- Post\-sale cần permission, reason, confirmation, before/after và audit\.

    

## 5\.2 UX concepts

### 5\.2\.1 Primary user journey

Primary journey của Theme 5 là:

> Nhân viên bán hàng hoặc thu ngân tạo đơn, thêm sản phẩm, gắn khách hàng khi cần, ghi nhận thanh toán toàn phần hoặc một phần, hoàn tất giao dịch và nhìn thấy rõ số đã thu hoặc còn phải thu\.
> 
> Journey mở rộng sau giao dịch là:
> 
> Người dùng tra cứu đơn, kiểm tra trạng thái, xem lịch sử và thực hiện hành động sau bán được phép như điều chỉnh thông tin, hủy đơn chưa thanh toán hoặc đổi/trả và quyết toán chênh lệch\.
> 
> 

### 5\.2\.2 Business flow groups

|Business flow group|Purpose|UX characteristics|
|---|---|---|
|Core selling|Tạo đơn, hoàn thiện nội dung, thanh toán và tạo official order|Luồng tần suất cao; ưu tiên tốc độ, thao tác bằng một tay, phục hồi draft và giảm số bước|
|Inquiry \& control|Tìm đơn, xem trạng thái, lịch sử và xác định hành động tiếp theo|Ưu tiên khả năng scan, tìm kiếm, trạng thái rõ, traceability và contextual actions|
|Post\-sale|Điều chỉnh, hủy hoặc đổi/trả sau giao dịch|Tần suất thấp hơn nhưng rủi ro dữ liệu và tài chính cao; cần permission, validation, confirmation và audit|

### 5\.2\.3 Interaction model

Theme 5 sử dụng các interaction pattern sau:

- Full\-screen task flow: dành cho những công việc chính có nội dung dài hoặc nhiều bước như soạn đơn và lập phiếu đổi/trả\.

- Embedded checkout flow: dùng cho SG\-05 — Thanh toán \& hoàn tất đơn; được mở từ SG\-02 và luôn giữ draft context\. Trên mobile có thể trình bày bằng bottom sheet mở rộng hoặc full\-screen overlay, nhưng không có route hoặc entry point độc lập\.

- Push navigation: dùng khi chuyển sang một màn hình con nhưng vẫn cần giữ context của draft, official order hoặc phiếu đổi/trả hiện tại\.

- Bottom sheet: dùng cho chọn nhanh, action list, filter hoặc nhập dữ liệu ngắn\.

- Modal confirmation: dùng cho destructive action hoặc hành động có ảnh hưởng không thể hoàn tác đơn giản\.

- Inline editing: dùng cho số lượng, đơn vị bán hoặc dữ liệu ngắn trong order workspace\.

- Inline validation: đặt lỗi gần trường hoặc dòng hàng phát sinh vấn đề\.

- Sticky bottom CTA: dùng cho primary action trong những flow có nội dung dài\.

- Contextual action sheet: dùng tại chi tiết đơn khi action phụ thuộc trạng thái và permission\.

- Progressive expansion: dùng cho commercial details, timeline và integration details\.

### 5\.2\.4 Navigation concept

- Module Bán hàng là entry point chính của Core selling\.

- Người dùng có thể tạo đơn mới hoặc tiếp tục một đơn nháp từ SG\-01\.

- SG\-03 Chọn sản phẩm và SG\-04 Chọn khách hàng là flow nhánh, sau khi hoàn tất phải quay lại đúng draft trong SG\-02\.

- Khi tạo nhanh khách hàng thành công, khách hàng mới được tự động gắn vào draft\.

- Không cho tạo nhanh sản phẩm trong Theme 5; người dùng chỉ được chọn sản phẩm hiện có\.

- Sau khi checkout thành công, người dùng được đưa đến SG\-06 — Kết quả bán hàng\.

- Từ kết quả giao dịch, người dùng có thể tạo đơn mới hoặc mở chi tiết official order\.

- SG\-08 — Chi tiết \& lịch sử đơn hàng là hub cho các nghiệp vụ sau bán\.

- Sau khi hoàn thành điều chỉnh, hủy hoặc đổi/trả, người dùng được đưa về màn hình có ngữ cảnh phù hợp của đơn gốc\.

    

### 5\.2\.5 Post\-transaction control concept

- Official order và commercial snapshot không bị overwrite bởi các nghiệp vụ sau bán\.

- Mọi điều chỉnh cần lưu giá trị trước, giá trị sau, lý do, người thực hiện và thời gian\.

- Hệ thống xác định action eligibility từ trạng thái đơn, thanh toán, đổi/trả, integration và permission\.

- Hủy đơn không bao gồm hoàn tiền\.

- Đơn đã thanh toán hoặc thanh toán một phần được chuyển sang flow đổi/trả\.

- Timeline của đơn phải liên kết được với adjustment, cancellation và return/exchange record\.

- Trạng thái downstream được hiển thị theo hướng hỗ trợ hành động, không phơi bày chi tiết kỹ thuật không cần thiết\.

    

## 5\.3 UX architecture

### 5\.3\.1 End\-to\-end user journey

```Plain Text
flowchart TD
    A["Bán hàng"] --> B["Tạo mới hoặc mở đơn nháp"]
    B --> C["Soạn nội dung đơn"]
    C --> D["Gắn khách hàng nếu cần"]
    D --> E["Thanh toán & hoàn tất"]
    E --> F["Kết quả giao dịch"]
    F --> G["Tra cứu & chi tiết đơn"]
    G --> H["Nghiệp vụ sau bán"]
```

### 5\.3\.2 Business flow map

|Flow|Business flow group|Business flow|Purpose|
|---|---|---|---|
|BF\-01|Core selling|Khởi tạo \& tiếp tục đơn|Tạo đơn mới hoặc tiếp tục đơn nháp|
|BF\-02|Core selling|Soạn nội dung đơn|Thêm hàng và hoàn thiện nội dung giao dịch|
|BF\-03|Core selling|Bổ sung ngữ cảnh bán hàng|Gắn khách hàng hoặc xác nhận sử dụng khách lẻ|
|BF\-04|Core selling|Checkout \& hoàn tất|Kiểm tra, ghi nhận thanh toán và tạo official order|
|BF\-05|Inquiry \& control|Tra cứu \& theo dõi|Tìm đơn, xem chi tiết, trạng thái và lịch sử|
|BF\-06|Post\-sale|Điều chỉnh sau bán|Điều chỉnh thông tin phi tài chính được phép|
|BF\-07|Post\-sale|Hủy đơn|Hủy đơn chưa thanh toán khi đủ điều kiện|
|BF\-08|Post\-sale|Đổi/trả \& quyết toán|Xử lý hàng trả, hàng đổi và chênh lệch tiền|



### 5\.3\.3 Relationship between business flows

```Plain Text
flowchart TD
    BF01["BF-01<br/>Khởi tạo & tiếp tục đơn"]
    BF02["BF-02<br/>Soạn nội dung đơn"]
    BF03["BF-03<br/>Bổ sung ngữ cảnh bán hàng"]
    BF04["BF-04<br/>Checkout & hoàn tất"]
    BF05["BF-05<br/>Tra cứu & theo dõi"]
    BF06["BF-06<br/>Điều chỉnh sau bán"]
    BF07["BF-07<br/>Hủy đơn"]
    BF08["BF-08<br/>Đổi/trả & quyết toán"]

    BF01 --> BF02
    BF02 --> BF03
    BF03 --> BF02
    BF02 --> BF04
    BF04 --> BF05
    BF05 --> BF06
    BF05 --> BF07
    BF05 --> BF08
    BF06 --> BF05
    BF07 --> BF05
    BF08 --> BF05
```

### 5\.3\.4 Core selling flow

```Plain Text
flowchart TD
    A["BF-01<br/>Tạo mới hoặc mở đơn nháp"]
    B["BF-02<br/>Thêm và điều chỉnh dòng hàng"]
    C{"Có cần gắn khách hàng?"}
    D["BF-03<br/>Chọn hoặc tạo nhanh khách hàng"]
    E["BF-04<br/>Kiểm tra và thanh toán"]
    F["Official order"]

    A --> B
    B --> C
    C -->|"Có"| D
    C -->|"Không - dùng khách lẻ"| E
    D --> E
    E --> F
```

Kết quả của Core selling:

- Working draft được chuyển thành official order\.

- Commercial snapshot được tạo và khóa\.

- Trạng thái thanh toán được xác định\.

- Khoản còn phải thu được phát sinh khi thanh toán chưa đủ\.

- Các downstream impact request được tạo theo domain contract\.

- Người dùng được đưa tới kết quả giao dịch\.

    

### 5\.3\.5 Inquiry \& control flow

```Plain Text
flowchart TD
    A["BF-05<br/>Danh sách đơn"]
    B["Tìm kiếm và lọc"]
    C["Chi tiết đơn"]
    D["Trạng thái và lịch sử"]
    E{"Hành động tiếp theo"}

    A --> B
    B --> C
    C --> D
    D --> E
```

BF\-05 là điểm nối giữa giao dịch bán hàng và các nghiệp vụ sau bán\. Action eligibility được xác định từ:

- Order lifecycle\.

- Lock status\.

- Payment status\.

- Return status\.

- Adjustment indicator\.

- Integration status\.

- Permission\.

- Các nghiệp vụ đã phát sinh trước đó\.

    ### 5\.3\.6 Post\-sale flow

    ```mermaid
    flowchart TD
    A["BF-05<br/>Chi tiết đơn hàng"]
    B{"Đơn cần xử lý gì?"}
    C["BF-06<br/>Điều chỉnh thông tin"]
    D{"Trạng thái settlement?"}
    E["BF-07<br/>Hủy đơn"]
    F["BF-08<br/>Đổi/trả & quyết toán"]
    H["Kiểm tra / đối soát trạng thái"]
    G["Đơn và timeline được cập nhật"]

    A --> B
    B -->|"Sửa metadata được phép"| C
    B -->|"Hủy giao dịch"| D
    B -->|"Đổi/trả hàng"| F
    D -->|"Chưa phát sinh settlement"| E
    D -->|"Đã thanh toán hoặc một phần"| F
    D -->|"Đang xử lý hoặc chưa xác định"| H
    C --> G
    E --> G
    F --> G
    H --> A    ```

    Quy tắc điều hướng:

    - Đơn chưa phát sinh payment, receivable settlement hoặc nghĩa vụ tài chính liên quan có thể đi vào BF\-07 nếu đáp ứng các điều kiện hủy khác\.

    - Đơn đã thanh toán hoặc thanh toán một phần không được hủy; người dùng được chuyển sang BF\-08\.

    - Đơn có payment đang xử lý hoặc kết quả settlement chưa xác định phải được kiểm tra hoặc đối soát trước; chưa được hủy và cũng chưa tự động chuyển sang đổi/trả\.

    - Người dùng có thể chủ động bắt đầu BF\-08 khi cần trả hàng hoặc đổi hàng, không phụ thuộc việc đã từng cố gắng hủy đơn\.

    - Sau khi hoàn thành nghiệp vụ sau bán, hệ thống cập nhật read model, trạng thái tổng hợp và timeline của đơn\.

## 5\.4 Visual architecture

### 5\.4\.1 Mobile screen architecture

Các màn hình Theme 5 ưu tiên cấu trúc:

1. Top bar:

    - Back hoặc navigation control\.

    - Tên màn hình\.

    - Contextual action nếu cần\.

2. Status/context area:

    - Mã đơn hoặc trạng thái giao dịch\.

    - Warning hoặc blocked reason\.

3. Main content:

    - Dòng hàng, dữ liệu nhập hoặc thông tin nghiệp vụ chính\.

4. Summary area:

    - Tổng tiền\.

    - Đã thanh toán\.

    - Còn phải thu\.

    - Chênh lệch cần thu hoặc hoàn\.

5. Sticky action area:

    - Một primary action\.

    - Secondary action khi thực sự cần thiết\.

6. Feedback layer:

    - Inline validation\.

    - Snackbar/toast cho phản hồi nhẹ\.

    - Banner cho warning cần lưu ý\.

    - Modal hoặc sheet cho confirmation\.

        

### 5\.4\.2 Navigation patterns

|Pattern|Usage|
|---|---|
|Push screen|Chọn sản phẩm, chọn khách hàng, mở chi tiết đơn|
|Full\-screen task flow|Soạn đơn và lập phiếu đổi/trả|
|Embedded checkout flow|Thanh toán \& hoàn tất trong context của SG\-02; không có entry point độc lập|
|Bottom sheet|Filter, chọn action, nhập/chọn dữ liệu ngắn|
|Modal confirmation|Hủy đơn, bỏ draft, xác nhận destructive action|
|Inline expansion|Xem chi tiết giá, payment breakdown hoặc trạng thái tích hợp|
|Contextual action sheet|Hiển thị action hợp lệ tại chi tiết đơn|
|Return\-to\-context|Quay lại đúng draft, official order hoặc phiếu đổi/trả sau khi hoàn thành flow nhánh|

Navigation không được tạo quá nhiều tầng trên mobile\. Luồng thường xuyên cần hoàn thành với số bước tối thiểu và không làm mất context của draft hoặc official order\.

Việc một flow được trình bày bằng full\-screen overlay trên mobile không đồng nghĩa flow đó là một screen group hoặc navigation route độc lập\.

### 5\.4\.3 Information hierarchy

Thứ tự ưu tiên chung:

1. Trạng thái giao dịch hoặc nghiệp vụ hiện tại\.

2. Tổng tiền, số đã thu, số còn phải thu hoặc chênh lệch\.

3. Primary action\.

4. Dòng hàng và thông tin khách hàng\.

5. Warning hoặc blocked reason\.

6. Thông tin tham chiếu và commercial details\.

7. Timeline, audit và integration details\.

Trong Core selling, dữ liệu phục vụ thao tác nhanh được ưu tiên\. Trong Post\-sale, điều kiện, ảnh hưởng và audit được ưu tiên cao hơn tốc độ\.

### 5\.4\.4 Action hierarchy

- Primary action: một hành động chính rõ ràng trên mỗi màn hình\.

- Secondary action: hành động hỗ trợ nhưng không cạnh tranh với primary action\.

- Contextual action: chỉ xuất hiện khi trạng thái và permission cho phép\.

- Destructive action: sử dụng semantic danger và yêu cầu explicit confirmation\.

- Disabled action: phải hiển thị hoặc giải thích lý do không thể thực hiện\.

- Redirect action: dùng khi action ban đầu không hợp lệ nhưng có nghiệp vụ thay thế, ví dụ `Tạo yêu cầu đổi/trả`\.

    

### 5\.4\.5 State \& feedback model

|State|UI treatment|Expected behavior|
|---|---|---|
|Default|Nội dung và primary action bình thường|Cho phép tiếp tục công việc|
|Loading|Skeleton hoặc progress phù hợp|Không làm người dùng hiểu nhầm có thể thao tác|
|Empty|Giải thích ngắn và CTA phù hợp|Hướng người dùng tạo dữ liệu hoặc thay đổi điều kiện|
|Success|Confirmation rõ ràng|Cung cấp hành động tiếp theo|
|Warning|Semantic warning và lý do|Cho phép tiếp tục nếu business rule cho phép|
|Blocked|Lý do và hướng xử lý|Không cho thực hiện action bị chặn|
|Error|Mô tả lỗi và retry|Giữ dữ liệu người dùng đã nhập khi có thể|
|No permission|Giải thích giới hạn quyền|Không hiển thị dữ liệu hoặc action vượt quyền|
|Processing|Progress và chống submit lặp|Giữ nguyên transaction context|
|Uncertain|Không kết luận thất bại hoặc thành công|Cung cấp action kiểm tra trạng thái|
|Reconciliation required|Cảnh báo kiểm soát|Hướng tới flow kiểm tra hoặc đối soát|



### 5\.4\.6 Reusable component and pattern inventory

|Pattern/component|Primary purpose|Used by|
|---|---|---|
|Search \& select|Tìm và chọn business object|SG\-03, SG\-04, SG\-07, SG\-11|
|Search input with suggestions|Tìm theo từ khóa, SKU, barcode hoặc khách hàng|SG\-03, SG\-04, SG\-07|
|Compact business item card|Hiển thị item có thể scan nhanh|SG\-01, SG\-03, SG\-04, SG\-07, SG\-11|
|Draft order card|Hiển thị trạng thái và hành động với draft|SG\-01|
|Editable order line|Hiển thị và chỉnh sửa dòng hàng|SG\-02, SG\-11<br>|
|Return/exchange draft card|Hiển thị và tiếp tục phiếu đổi/trả đang lập|SG\-11|
|Returnable quantity indicator|Hiển thị số lượng còn có thể trả của dòng hàng gốc |SG\-08, SG\-11|
|Quantity editor|Điều chỉnh số lượng|SG\-02, SG\-11|
|Unit selector|Chọn đơn vị bán hợp lệ|SG\-02, SG\-03|
|Price display<br>|Hiển thị giá gốc, giá áp dụng và giảm giá|SG\-02, SG\-03, SG\-11|
|Price adjustment editor|Xem giá nguồn, giá áp dụng và điều chỉnh giá dòng hàng theo quyền|SG\-02|
|Private\-price action|Đề xuất lưu giá áp dụng thành giá riêng theo contract của Theme 4|SG\-02|
|Customer summary|Hiển thị khách lẻ hoặc khách hàng được gắn|SG\-02, SG\-04, SG\-05, SG\-08|
|Money summary|Hiển thị tổng, đã thu, còn phải thu hoặc chênh lệch|SG\-02, SG\-05, SG\-06, SG\-08, SG\-12, SG\-13|
|Payment method selector|Chọn phương thức thanh toán|SG\-05, SG\-12|
|Payment allocation editor|Phân bổ tiền theo phương thức|SG\-05, SG\-12|
|Sticky primary CTA|Giữ hành động chính dễ tiếp cận|SG\-02, SG\-05, SG\-09, SG\-11, SG\-12|
|Status chip|Nhận diện trạng thái nhanh|SG\-01, SG\-06, SG\-07, SG\-08, SG\-13|
|Business warning block|Giải thích warning hoặc blocked reason|SG\-02, SG\-05, SG\-08, SG\-09, SG\-10, SG\-12|
|Inline validation message|Hiển thị lỗi gần dữ liệu liên quan|SG\-02, SG\-04, SG\-05, SG\-09, SG\-11, SG\-12|
|Contextual action sheet|Hiển thị action phù hợp theo trạng thái|SG\-08|
|Reason selector/input|Ghi lý do điều chỉnh, hủy hoặc đổi/trả|SG\-09, SG\-10, SG\-11|
|Before/after comparison|Review thay đổi trước khi xác nhận|SG\-09|
|Destructive confirmation|Xác nhận hành động có rủi ro|SG\-01, SG\-10|
|Processing state|Hiển thị giao dịch đang xử lý|SG\-05, SG\-10, SG\-12|
|Uncertain result state|Xử lý kết quả chưa xác định|SG\-05, SG\-06, SG\-10, SG\-12, SG\-13|
|Success result pattern|Hiển thị kết quả và next action|SG\-06, SG\-10, SG\-13|
|Timeline/audit history|Hiển thị lịch sử nghiệp vụ|SG\-08, SG\-09, SG\-10, SG\-13|
|Settlement reconciliation block|Hiển thị payment đang xử lý, chưa xác định hoặc cần đối soát|SG\-05, SG\-08, SG\-10, SG\-12, SG\-13|
|Permission/blocked state|Giải thích giới hạn quyền|SG\-01, SG\-07, SG\-08, SG\-09, SG\-10, SG\-11, SG\-12|
|Filter sheet|Lọc danh sách trên mobile|SG\-01, SG\-07|
|Empty/no\-result pattern|Hướng xử lý khi không có dữ liệu|SG\-01, SG\-03, SG\-04, SG\-07, SG\-11|



Component inventory là baseline ban đầu\. Khi thiết kế từng Screen Group, component mới hoặc biến thể mới phải được ghi nhận trong Component Delta trước khi bổ sung vào VET45 Design System\.

### 5\.4\.7 Responsive considerations

- Mobile là baseline để xác định interaction, content priority và primary action\.

- Tablet/web có thể sử dụng bố cục hai cột cho list–detail hoặc content–summary\.

- Business flow, validation và action eligibility không thay đổi theo kích thước màn hình\.

- Trên màn hình lớn, summary có thể đặt ở side panel thay vì sticky bottom\.

- Modal hoặc bottom sheet trên mobile có thể chuyển thành dialog hoặc side panel trên web\.

- Table chỉ được sử dụng trên màn hình lớn khi giúp so sánh dữ liệu; mobile ưu tiên card/list\.

- Nội dung dài phải scroll tự nhiên; không resize text, icon hoặc component để ép vừa một viewport\.

    

## 5\.5 Screen groups

### 5\.5\.1 Epic–Business Flow–Screen Group alignment

|**Screen group**|**Screen group name**|**Primary task**|**Business flow**|**Business flow group**|**Epic**|**Notes**|
|---|---|---|---|---|---|---|
|SG\-01|Bán hàng \& đơn nháp<br>|Tạo đơn mới hoặc tiếp tục đơn nháp<br>|BF\-01 — Khởi tạo \& tiếp tục đơn|Core selling|EP\-01 — Lập đơn hàng \& lưu nháp|Luồng tần suất cao; ưu tiên tốc độ, khả năng phục hồi và tiếp tục công việc đang dở|
|SG\-02|Soạn đơn bán hàng|Hoàn thiện nội dung đơn và chuyển sang thanh toán|BF\-02 — Soạn nội dung đơn|Core selling|EP\-01 — Lập đơn hàng \& lưu nháp|Bao phủ dòng hàng, điều chỉnh giá, lưu giá riêng, draft persistence và checkout entry|
|SG\-03|Chọn sản phẩm|Tìm và chọn sản phẩm hiện có vào đơn|BF\-02 — Soạn nội dung đơn|Core selling|EP\-01 — Lập đơn hàng \& lưu nháp|Không cho tạo nhanh sản phẩm; ưu tiên tìm theo tên, SKU và barcode|
|SG\-04|Chọn khách hàng|Gắn khách hàng hoặc xác nhận dùng khách lẻ|BF\-03 — Bổ sung ngữ cảnh bán hàng|Core selling|EP\-01 — Lập đơn hàng \& lưu nháp|Cho phép tạo nhanh khách hàng rồi quay lại đúng draft đang soạn|
|SG\-05|Thanh toán \& hoàn tất đơn|Kiểm tra đơn, ghi nhận settlement và hoàn tất|BF\-04 — Checkout \& hoàn tất|Core selling|EP\-02 — Thanh toán \& hoàn tất đơn hàng|Embedded flow của SG\-02; không có entry point hoặc màn hình kiểm tra độc lập|
|SG\-06|Kết quả bán hàng|Xác nhận kết quả và chọn hành động tiếp theo|BF\-04 — Checkout \& hoàn tất|Core selling|EP\-02 — Thanh toán \& hoàn tất đơn hàng|Phân biệt official order success với payment hoặc downstream side effect còn đang xử lý|
|SG\-07|Danh sách đơn hàng|Tìm đúng đơn hàng cần xem hoặc xử lý|BF\-05 — Tra cứu \& theo dõi|Inquiry \& control|EP\-03 — Tra cứu \& theo dõi đơn hàng|Cần khả năng scan nhanh, tìm kiếm, lọc và nhận diện ba trục trạng thái|
|SG\-08|Chi tiết \& lịch sử đơn hàng|Hiểu giao dịch gốc, trạng thái, timeline và action eligibility|BF\-05 — Tra cứu \& theo dõi|Inquiry \& control|EP\-03 — Tra cứu \& theo dõi đơn hàng|Là hub cho toàn bộ nghiệp vụ sau bán; ưu tiên tính minh bạch và traceability|
|SG\-09|Điều chỉnh thông tin đơn|Điều chỉnh metadata thuộc adjustable field whitelist|BF\-06 — Điều chỉnh sau bán|Post\-sale|EP\-04 — Điều chỉnh thông tin đơn hàng sau bán|Chỉ gồm ghi chú nội bộ, mã tham chiếu ngoài, tag và metadata phi thương mại được whitelist|
|SG\-10|Hủy đơn hàng|Kiểm tra điều kiện và hủy đơn chưa phát sinh settlement|BF\-07 — Hủy đơn|Post\-sale|EP\-05 — Hủy đơn hàng sau bán|Đơn đã thanh toán hoặc một phần chuyển sang đổi/trả; settlement chưa xác định phải đối soát trước|
|SG\-11|Lập phiếu đổi/trả|Lập, lưu và tiếp tục phiếu đổi/trả; chọn hàng trả và hàng mới|BF\-08 — Đổi/trả \& quyết toán|Post\-sale|EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch|Giữ liên kết với đơn gốc, giới hạn số lượng còn được trả và hỗ trợ draft persistence|
|SG\-12|Quyết toán chênh lệch|Thu thêm, hoàn lại, cấn trừ công nợ hoặc xác nhận không chênh lệch|BF\-08 — Đổi/trả \& quyết toán|Post\-sale|EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch|Rủi ro tài chính cao; luôn hiển thị rõ valuation và cách quyết toán|
|SG\-13|Kết quả \& chi tiết đổi/trả|Xem kết quả, trạng thái và ảnh hưởng đến đơn gốc|BF\-08 — Đổi/trả \& quyết toán|Post\-sale|EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch|Hiển thị hàng trả, hàng mới, tiền thu/hoàn, công nợ và downstream impacts|

### 5\.5\.2 SG\-01 — Bán hàng \& đơn nháp

#### **Overview**

- Purpose: Cung cấp điểm vào chính cho hoạt động bán hàng, cho phép người dùng tạo đơn mới, tìm đơn nháp và tiếp tục công việc đang làm dở\.

- Related epic: EP\-01 — Lập đơn hàng \& lưu nháp\.

- Related business flow: BF\-01 — Khởi tạo \& tiếp tục đơn\.

- Business flow group: Core selling\.

- Primary users: Nhân viên bán hàng, thu ngân, chủ đơn vị trực tiếp bán hàng\.

- Primary task: Tạo đơn mới hoặc tiếp tục một đơn nháp\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: Người dùng phải có thể bắt đầu hoặc tiếp tục bán hàng trong một thao tác, đồng thời nhận biết ngay draft nào cần kiểm tra trước khi sử dụng\.

    

#### **Entry \& exit**

- Entry points:

    - Module `Bán hàng` từ navigation chính của Tenant App\.

    - Shortcut `Tạo đơn` từ Home\.

    - Quay lại từ SG\-02 sau khi lưu và đóng draft\.

    - Deep link đến một draft cụ thể nếu người dùng có permission\.

- Exit points:

    - SG\-02 — Soạn đơn bán hàng sau khi tạo draft mới\.

    - SG\-02 — Soạn đơn bán hàng sau khi mở một draft hợp lệ\.

    - SG\-02 với trạng thái cần revalidate sau khi mở draft có cảnh báo\.

    - Giữ tại SG\-01 sau khi bỏ một draft\.

    - Trở về màn hình trước nếu người dùng không có quyền truy cập\.

        

#### **Screen/state inventory**

|**State**|**Type**|**Purpose**|**Primary action**|**Notes**|
|---|---|---|---|---|
|D\-01|Screen — Default|Hiển thị danh sách đơn nháp người dùng được phép truy cập|Tạo đơn mới|Draft cập nhật gần nhất hiển thị trước|
|D\-02|Empty state|Xử lý trường hợp chưa có đơn nháp|Tạo đơn mới|Không hiển thị như lỗi hệ thống|
|D\-03|Search/no\-result state|Tìm draft và xử lý trường hợp không có kết quả phù hợp|Xóa tìm kiếm|Giữ nguyên danh sách khi xóa query|
|D\-04|Warning state|Cảnh báo draft cần kiểm tra lại dữ liệu tham chiếu|Kiểm tra \& tiếp tục|Revalidate trong SG\-02 trước khi checkout|
|D\-05|Blocked state|Thông báo người dùng không thể mở draft|Quay lại|Áp dụng khi mất quyền hoặc draft ngoài scope|
|D\-06|Confirmation modal|Xác nhận bỏ một draft|Bỏ đơn nháp|Destructive action|
|D\-07|Loading state|Tải danh sách draft hoặc xử lý tạo draft mới|—|Ngăn tạo draft lặp khi request đang xử lý|
|D\-08|Error state|Xử lý lỗi tải danh sách, mở draft hoặc tạo draft|Thử lại|Không tự động tạo draft thay thế|



#### UI Contract

**1\. Screen purpose**

SG\-01 phải giúp người dùng trả lời ngay hai câu hỏi:

- Tôi có thể tạo đơn mới ở đâu?

- Tôi có đơn nào đang làm dở để tiếp tục không?

SG\-01 không hiển thị official order\. Official order thuộc SG\-07 — Danh sách \& tìm kiếm đơn\.

**2\. Information hierarchy**

Thứ tự ưu tiên thông tin:

1. Primary CTA `Tạo đơn mới`\.

2. Danh sách đơn nháp\.

3. Trạng thái hoặc warning của từng draft\.

4. Thời điểm cập nhật gần nhất\.

5. Khách hàng, số dòng hàng và tổng tiền tạm tính\.

6. Search và filter hỗ trợ\.

7. Metadata bổ sung\.

    

**3\. Layout structure**

- Top bar:

    - Title: `Bán hàng`\.

    - Không dùng back icon khi đây là root screen của module\.

    - Có thể dùng back icon nếu SG\-01 được mở từ flow hoặc deep link bên ngoài module\.

- Primary action area:

    - CTA `Tạo đơn mới`\.

    - Trên mobile, CTA đặt ở vùng dễ tiếp cận và không bị che bởi Bottom navigation                \.

- Search area:

    - Search input nằm phía trên danh sách draft\.

    - Placeholder: `Tìm đơn nháp`\.

- Draft list:

    - Hiển thị theo card/list compact\.

    - Draft cập nhật gần nhất đứng đầu\.

    - Draft cần kiểm tra lại có warning rõ nhưng vẫn giữ khả năng mở nếu được phép\.

- Bottom navigation                :

    - Sử dụng navigation chung của Tenant App nếu SG\-01 là root screen\.

        

**4\. Displayed data**

Mỗi draft card hiển thị tối thiểu:

- Tên hoặc short reference của draft\.

- Thời điểm cập nhật gần nhất\.

- Khách hàng: tên khách hàng nếu đã gắn hoặc `Khách lẻ`\.

- Số dòng hàng\.

- Tổng số lượng nếu cần phân biệt với số dòng hàng\.

- Tổng tiền tạm tính\.

- Người tạo hoặc người phụ trách nếu người dùng có quyền xem draft của nhiều người\.

- Warning indicator nếu draft cần revalidate\.

- Status label: `Đang soạn` hoặc `Cần kiểm tra`\.

    

**5\. Input data**

- Search query\.

- Filter `Đơn của tôi` hoặc `Tất cả đơn nháp` khi có quyền\.

- Draft được chọn\.

- Confirmation khi bỏ draft\.

    

**6\. Element contract**

|**Element ID**|**Component**|**Content/label**|**Behavior**|**States/conditions**|
|---|---|---|---|---|
|SG01\-E01|Top bar|`Bán hàng`|Xác định module hiện tại|Root hoặc nested navigation|
|SG01\-E02|Primary button|`Tạo đơn mới`|Tạo working draft rồi chuyển sang SG\-02|Disabled khi request đang xử lý|
|SG01\-E03|Search input|`Tìm đơn nháp`|Tìm theo draft reference, khách hàng hoặc dữ liệu hỗ trợ|Default, focus, populated, no\-result|
|SG01\-E04|Filter control|`Đơn của tôi` / `Tất cả đơn nháp`|Thay đổi phạm vi draft|`Tất cả đơn nháp` chỉ hiện khi có quyền|
|SG01\-E05|Draft list|`Đơn nháp`|Hiển thị draft theo cập nhật giảm dần|Loading, populated, empty, error|
|SG01\-E06|Draft card|Draft summary|Mở draft tương ứng|Default, warning, blocked|
|SG01\-E07|Draft status|`Đang soạn` / `Cần kiểm tra`|Giải thích trạng thái|Neutral hoặc warning|
|SG01\-E08|Customer label|Tên khách hàng / `Khách lẻ`|Hiển thị customer context|Không chỉnh trực tiếp tại SG\-01|
|SG01\-E09|Draft metrics|Số dòng hàng · Tổng tiền tạm tính|Hỗ trợ scan nhanh|Có thể đổi sau revalidation|
|SG01\-E10|Updated time|`Cập nhật ...`|Cho biết độ mới của draft|Relative time phù hợp|
|SG01\-E11|Overflow action|`Bỏ đơn nháp`|Mở D\-06|Theo permission|
|SG01\-E12|Empty\-state CTA|`Tạo đơn mới`|Tạo draft đầu tiên|D\-02|
|SG01\-E13|Retry button|`Thử lại`|Retry action thất bại|D\-08|
|SG01\-E14|Back/close action|`Quay lại`|Rời blocked state|D\-05|



**7\. Primary action behavior**

- `Tạo đơn mới` tạo một working draft trong tenant/store context hiện tại\.

- CTA chuyển sang processing state ngay sau lần nhấn đầu tiên\.

- Không cho nhấn lặp trong khi request đang xử lý\.

- Thành công: chuyển sang SG\-02 với draft vừa tạo\.

- Thất bại: giữ tại SG\-01 và hiển thị D\-08\.

- Không tạo draft local giả khi chưa có authoritative response\.

    

**8\. Draft card behavior**

- Chạm card mở draft trong SG\-02\.

- Draft bình thường mở trực tiếp SG\-02\.

- Draft có warning mở D\-04 hoặc SG\-02 kèm warning cần xử lý\.

- Khi permission thay đổi hoặc draft ngoài scope, hiển thị D\-05\.

- Overflow action hoạt động độc lập với phần còn lại của card\.

    

**9\. Search and filter behavior**

- Search chỉ áp dụng trên tập draft người dùng được phép xem\.

- Search không thay đổi tenant/store scope\.

- Xóa query khôi phục danh sách theo filter hiện tại\.

- No\-result hiển thị D\-03 và CTA `Xóa tìm kiếm`\.

- Filter mặc định là `Đơn của tôi`\.

- `Tất cả đơn nháp` chỉ xuất hiện khi có permission xem draft của người khác\.

    

**10\. Draft discard behavior**

- `Bỏ đơn nháp` mở D\-06\.

- Confirmation hiển thị draft đang được bỏ\.

- Secondary action: `Giữ lại`\.

- Primary destructive action: `Bỏ đơn nháp`\.

- Thành công: đóng modal, loại draft khỏi danh sách và hiển thị `Đã bỏ đơn nháp`\.

- Thất bại: giữ draft trong danh sách và cho phép thử lại\.

    

**11\. Validation and business rules**

- Người dùng phải có tenant, store và permission context hợp lệ\.

- SG\-01 chỉ hiển thị working draft, không hiển thị official order\.

- Draft mở được không đồng nghĩa draft hợp lệ để checkout\.

- Draft có dữ liệu tham chiếu thay đổi phải được đánh dấu `Cần kiểm tra`\.

- Tổng tiền trên draft card là tổng tiền tạm tính\.

- Bỏ draft không ảnh hưởng official order, payment transaction hoặc external ledger\.

- Một request tạo draft chỉ được tạo một working draft\.

- Retry phải sử dụng cơ chế chống tạo trùng\.

    

**12\. Permission rules**

- `Create sales draft`: tạo draft mới\.

- `View own sales drafts`: xem draft của chính người dùng hoặc được giao\.

- `View all store sales drafts`: dùng filter `Tất cả đơn nháp`\.

- `Edit own sales draft`: mở draft của chính người dùng\.

- `Edit all store sales drafts`: mở draft của người khác trong store scope\.

- `Discard own sales draft`: bỏ draft của chính người dùng\.

- `Discard all store sales drafts`: bỏ draft của người khác\.

- Khi không có quyền tạo, CTA `Tạo đơn mới` bị ẩn hoặc disabled kèm lý do\.

    

**13\. Loading, empty, error and blocked handling**

- Loading: dùng skeleton và không hiển thị dữ liệu cũ như dữ liệu mới\.

- Empty: giải thích chưa có đơn nháp và hiển thị CTA `Tạo đơn mới`\.

- No result: hiển thị query hiện tại và CTA `Xóa tìm kiếm`\.

- Error: giữ search query/filter và hiển thị `Thử lại`\.

- Blocked: không hiển thị chi tiết ngoài permission và có CTA `Quay lại`\.

    

**14\. Feedback**

- Tạo draft thành công: chuyển trực tiếp sang SG\-02\.

- Bỏ draft thành công: hiển thị `Đã bỏ đơn nháp`\.

- Tải lại thành công: phục hồi danh sách, không cần success toast\.

- Mất quyền: dùng blocked message, không dùng generic error\.

- Draft cần kiểm tra: dùng semantic warning, không dùng danger\.

    

**15\. Accessibility**

- Draft card có vùng chạm đủ lớn\.

- Status không chỉ phân biệt bằng màu\.

- CTA và overflow action có accessible label\.

- Search input có screen reader label\.

- Số tiền được đọc theo đúng định dạng tiền tệ\.

- Focus order: top bar → CTA → search/filter → draft list → Bottom navigation                \.

    

**16\. Responsive behavior**

- Mobile: một cột, card full width, CTA trong vùng dễ tiếp cận\.

- Tablet: có thể hiển thị danh sách rộng hơn hoặc hai cột nếu vẫn dễ scan\.

- Web: có thể dùng list/table compact nhưng không thay đổi business flow\.

- Nội dung dài wrap hoặc truncate có kiểm soát; không thu nhỏ typography để ép vừa\.

    

#### Low\-fi wireframes

**D\-01 — Default: Có danh sách đơn nháp**

```Plain Text
┌─────────────────────────────────────┐
│ Topbar(Bán hàng)                │
├─────────────────────────────────────┤
│ [        + Tạo đơn mới            ] │
│ [ 🔍 Tìm đơn nháp                 ] │
│ [ Đơn của tôi ▾ ]                   │
│ ĐƠN NHÁP                            │
│ ┌─────────────────────────────────┐ │
│ │ Đang soạn                      │ │
│ │ Khách lẻ · 3 mặt hàng          │ │
│ │ Tạm tính             1.245.000đ│ │
│ │ Cập nhật 5 phút trước       ⋮  │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Đang soạn                      │ │
│ │ Nguyễn Văn An · 2 mặt hàng     │ │
│ │ Tạm tính               680.000đ│ │
│ │ Cập nhật 32 phút trước      ⋮  │ │
│ └─────────────────────────────────┘ │
│ Bottom navigation                   │
└─────────────────────────────────────┘
```

**D\-02 — Empty: Chưa có đơn nháp**

```Plain Text
┌─────────────────────────────────────┐
│ Topbar(Bán hàng)                │
├─────────────────────────────────────┤
│              [ 🧾 ]                 │
│       Chưa có đơn nháp              │
│  Các đơn đang làm dở sẽ xuất hiện   │
│  tại đây để anh/chị tiếp tục.       │
│ [        + Tạo đơn mới            ] │
│ Bottom navigation                   │
└─────────────────────────────────────┘
```

**D\-03 — Search: Không có kết quả**

```Plain Text
┌─────────────────────────────────────┐
│ Topbar(Bán hàng)                │
├─────────────────────────────────────┤
│ [        + Tạo đơn mới            ] │
│ [ 🔍 Nguyễn Minh                  ] │
│ [ Đơn của tôi ▾ ]                   │
│       Không tìm thấy đơn nháp       │
│  Không có đơn phù hợp với           │
│  “Nguyễn Minh”.                     │
│ [          Xóa tìm kiếm           ] │
│ Bottom navigation                   │
└─────────────────────────────────────┘
```

**D\-04 — Warning: Draft cần kiểm tra**

```Plain Text
┌─────────────────────────────────────┐
│ Topbar(Bán hàng)                │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ ⚠ Cần kiểm tra                 │ │
│ │ Nguyễn Văn An · 4 mặt hàng     │ │
│ │ Tạm tính             1.860.000đ│ │
│ │ Giá hoặc dữ liệu sản phẩm đã   │ │
│ │ thay đổi.                      │ │
│ │ [     Kiểm tra & tiếp tục     ]│ │
│ └─────────────────────────────────┘ │
│ Bottom navigation                   │
└─────────────────────────────────────┘
```

**D\-05 — Blocked: Không thể mở draft**

```Plain Text
┌─────────────────────────────────────┐
│ ←  Đơn nháp                         │
├─────────────────────────────────────┤
│              [ 🔒 ]                 │
│      Không thể mở đơn nháp          │
│  Anh/chị không còn quyền truy cập   │
│  hoặc đơn không thuộc cửa hàng này. │
│ [             Quay lại            ] │
└─────────────────────────────────────┘
```

**D\-06 — Confirmation: Bỏ đơn nháp**

```Plain Text
┌─────────────────────────────────────┐
│ ┌─────────────────────────────────┐ │
│ │        Bỏ đơn nháp?            │ │
│ │ Đơn của Nguyễn Văn An gồm      │ │
│ │ 2 mặt hàng sẽ bị loại khỏi     │ │
│ │ danh sách đơn nháp.            │ │
│ │ [          Giữ lại           ] │ │
│ │ [       Bỏ đơn nháp           ]│ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**D\-07 — Loading**

```Plain Text
┌─────────────────────────────────────┐
│ Topbar(Bán hàng)                │
├─────────────────────────────────────┤
│ [        + Tạo đơn mới            ] │
│ [ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ] │
│ ┌─────────────────────────────────┐ │
│ │ ░░░░░░░░░░                    │ │
│ │ ░░░░░░░░░░░░░░░░              │ │
│ │ ░░░░░░░░░░░░░░                │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**D\-08 — Error**

```Plain Text
┌─────────────────────────────────────┐
│ Topbar(Bán hàng)                │
├─────────────────────────────────────┤
│              [ ! ]                  │
│   Chưa tải được danh sách đơn nháp  │
│  Vui lòng kiểm tra kết nối và thử   │
│  lại. Các đơn nháp không bị đổi.    │
│ [             Thử lại             ] │
│ Bottom navigation                   │
└─────────────────────────────────────┘
```

#### Visuals

TBD\.

#### Traceability

TBD\.

### 5\.5\.3 SG\-02 — Soạn đơn bán hàng

#### **Overview**

- Purpose: Cung cấp workspace trung tâm để người dùng thêm sản phẩm, điều chỉnh dòng hàng, gắn khách hàng và hoàn thiện nội dung draft trước khi thanh toán\.

- Related epic: EP\-01 — Lập đơn hàng \& lưu nháp\.

- Related business flow: BF\-02 — Soạn nội dung đơn\.

- Business flow group: Core selling\.

- Primary users: Nhân viên bán hàng, thu ngân, chủ đơn vị trực tiếp bán hàng\.

- Primary task: Hoàn thiện nội dung đơn và chuyển sang thanh toán\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: Người dùng thao tác nhanh trên từng dòng hàng, luôn nhìn thấy tổng tiền tạm tính và biết rõ đơn đã đủ điều kiện thanh toán hay chưa\.

    

#### **Entry \& exit**

- Entry points:

    - SG\-01 sau khi tạo đơn mới hoặc mở đơn nháp\.

    - SG\-03 sau khi chọn sản phẩm\.

    - SG\-04 sau khi chọn hoặc tạo nhanh khách hàng\.

    - SG\-05 khi checkout phát hiện lỗi cần quay lại chỉnh sửa draft\.

    - Deep link đến draft cụ thể nếu có permission\.

- Exit points:

    - SG\-03 — Chọn sản phẩm\.

    - SG\-04 — Chọn khách hàng\.

    - SG\-05 — Thanh toán \& hoàn tất đơn\.

    - SG\-01 sau khi lưu và đóng hoặc bỏ draft\.

    - Giữ tại SG\-02 nếu draft có lỗi hoặc thay đổi chưa được lưu\.

        

#### **Screen/state inventory**

|State|Type|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|Screen — Empty order|Hiển thị draft mới chưa có sản phẩm|Thêm sản phẩm|CTA Thanh toán disabled|
|D\-02|Screen — Populated order|Hiển thị draft có các dòng hàng hợp lệ|Thanh toán|Tổng tiền và CTA luôn dễ thấy|
|D\-03|Bottom sheet — Edit line|Điều chỉnh số lượng hoặc đơn vị bán|Áp dụng|Reprice dòng hàng sau thay đổi|
|D\-04|Action sheet — Line actions|Hiển thị action phụ của dòng hàng|Chọn hành động|Có action xóa dòng hàng|
|D\-05|Warning state|Cảnh báo giá, tồn kho hoặc dữ liệu tham chiếu thay đổi|Kiểm tra \& tiếp tục|Phân biệt warning và blocked|
|D\-06|Blocked state|Chặn thanh toán do dòng hàng không hợp lệ|Sửa đơn|Chỉ rõ dòng hàng và nguyên nhân|
|D\-07|Save/sync warning|Thông báo thay đổi chưa được lưu|Thử lưu lại|Giữ dữ liệu đã nhập|
|D\-08|Confirmation modal|Xác nhận bỏ draft đang soạn|Bỏ đơn nháp|Destructive action|
|D\-09|Loading/revalidation state|Tải draft hoặc kiểm tra lại dữ liệu|—|Ngăn sửa trong lúc cập nhật|
|D\-10<br>|Error state|Xử lý lỗi tải hoặc cập nhật draft|Thử lại|Không làm mất dữ liệu đã nhập|
|D\-11|Bottom sheet — Price details \& adjustment|Xem giá nguồn, giá áp dụng và điều chỉnh giá theo quyền|Áp dụng giá|Không tự động tạo giá riêng|
|D\-12|Confirmation/sheet — Save private price|Kiểm tra và lưu giá áp dụng thành giá riêng|Lưu giá riêng|hực hiện qua contract của Theme 4|



#### UI Contract

**1\. Screen purpose**

SG\-02 phải giúp người dùng:

- Nhận biết draft đang soạn\.

- Thêm sản phẩm vào draft\.

- Xem và điều chỉnh từng dòng hàng\.

- Gắn hoặc thay đổi khách hàng\.

- Theo dõi tổng tiền tạm tính\.

- Nhận biết warning hoặc blocked condition\.

- Chuyển sang thanh toán khi draft đủ điều kiện\.

    

SG\-02 không checkout, không tạo official order và không ghi nhận payment transaction\. Các nghiệp vụ này thuộc SG\-05\.

**2\. Information hierarchy**

1. Draft context và trạng thái lưu\.

2. Khách hàng hoặc `Khách lẻ`\.

3. Danh sách dòng hàng\.

4. Warning hoặc blocked reason theo dòng\.

5. CTA thêm sản phẩm\.

6. Tổng tiền tạm tính\.

7. Primary CTA `Thanh toán`\.

8. Ghi chú và thông tin bổ sung\.

9. Action đóng hoặc bỏ draft\.

    

**3\. Layout structure**

- Top bar:

    - Back icon về SG\-01\.

    - Title `Tạo đơn` với draft mới hoặc `Soạn đơn` với draft có nội dung\.

    - Trạng thái `Đã lưu`, `Đang lưu` hoặc `Chưa lưu được`\.

    - Overflow action `Đóng đơn` và `Bỏ đơn nháp`\.

- Customer area:

    - Hiển thị `Khách lẻ` hoặc khách hàng đã gắn\.

    - Action `Chọn khách hàng` hoặc `Thay đổi`\.

- Product action:

    - CTA `Thêm sản phẩm` mở SG\-03\.

- Order line list:

    - Card/list compact\.

    - Hiển thị sản phẩm, đơn vị, số lượng, đơn giá và thành tiền\.

    - Warning hoặc blocked reason đặt sát dòng liên quan\.

- Summary area:

    - Hiển thị tổng tiền tạm tính và breakdown khi cần\.

- Sticky action area:

    - Primary CTA `Thanh toán` kèm tổng tiền\.

    - Disabled kèm lý do khi draft chưa đủ điều kiện\.

        

**4\. Displayed data**

- Draft\-level data:

    - Draft reference, store context và trạng thái lưu\.

    - Customer context\.

    - Số dòng hàng, tổng số lượng và tổng tiền tạm tính\.

    - Tổng giảm giá hoặc điều chỉnh giá nếu có\.

    - Ghi chú chung nếu Phase 1 hỗ trợ\.

- Line\-level data:

    - Tên sản phẩm, SKU hoặc mã nhận diện\.

    - Đơn vị bán, số lượng và đơn giá áp dụng\.

    - Giá trước/sau VAT theo pricing contract nếu cần\.

    - Discount/promotion result, thành tiền và warning\.

- Customer data:

    - `Khách lẻ`; hoặc tên, số điện thoại/mã khách hàng\.

    - Warning nếu khách hàng không còn hợp lệ\.

        

**5\. Input data**

- Sản phẩm và đơn vị từ SG\-03\.

- Khách hàng từ SG\-04\.

- Số lượng và đơn vị bán\.

- Đơn giá khi có permission sửa giá\.

- Lý do sửa giá nếu pricing rule yêu cầu\.

- Ghi chú nếu được hỗ trợ\.

- Action xóa dòng hàng hoặc bỏ draft\.

    

**6\. Element contract**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG02\-E01|Top bar|`Tạo đơn` / `Soạn đơn`|Hiển thị draft context|Draft mới hoặc đã có nội dung|
|SG02\-E02|Back action|`Quay lại`|Về SG\-01 nhưng giữ draft|Không có blocking modal|
|SG02\-E03|Save status|`Đã lưu` / `Đang lưu` / `Chưa lưu được`|Phản ánh persistence|Neutral, loading, warning|
|SG02\-E04|Overflow action|`Đóng đơn` / `Bỏ đơn nháp`|Đóng draft hoặc mở D\-08|Theo permission|
|SG02\-E05|Customer card|`Khách lẻ` hoặc tên khách|Mở SG\-04|Default, selected, warning|
|SG02\-E06|Customer action|`Chọn khách hàng` / `Thay đổi`|Mở SG\-04|Theo customer state|
|SG02\-E07|Add\-product button|`Thêm sản phẩm`|Mở SG\-03|Có quyền chỉnh draft|
|SG02\-E08|Order line list|Danh sách dòng hàng|Hiển thị draft|Empty, populated, warning, blocked|
|SG02\-E09|Product name|Tên sản phẩm|Nhận diện dòng|Truncate có kiểm soát|
|SG02\-E10|Product unit|Đơn vị bán|Hiển thị hoặc mở D\-03|Editable khi hợp lệ|
|SG02\-E11|Quantity control|Số lượng|Mở D\-03 hoặc chỉnh nhanh|Valid, warning, error|
|SG02\-E12|Unit price|Đơn giá|Hiển thị hoặc chỉnh theo quyền|Read\-only hoặc editable|
|SG02\-E13|Line total|Thành tiền|Cập nhật sau reprice|Read\-only|
|SG02\-E14|Line warning|Warning content|Giải thích vấn đề|Warning hoặc blocked|
|SG02\-E15|Line overflow|`Thao tác`|Mở D\-04|Theo line state|
|SG02\-E16|Order summary|`Tạm tính`|Hiển thị tổng tiền|Cập nhật theo draft|
|SG02\-E17|Summary expansion|`Xem chi tiết`|Mở price breakdown|Khi có dữ liệu hữu ích|
|SG02\-E18|Primary button|`Thanh toán`|Revalidate rồi mở SG\-05|Enabled hoặc disabled có lý do|
|SG02\-E19|Empty\-state CTA|`Thêm sản phẩm`|Mở SG\-03|D\-01|
|SG02\-E20|Retry save|`Thử lưu lại`|Retry persistence|D\-07/D\-10|
|SG02\-E21|Discard confirmation|`Bỏ đơn nháp`|Xác nhận xóa draft|D\-08|
|SG02\-E22|Price\-detail action|`Xem chi tiết giá`|Mở D\-11 với pricing breakdown hiện tại|Khi có pricing result|
|SG02\-E23|Price\-adjustment action|`Điều chỉnh giá`|Mở vùng nhập giá áp dụng|Có permission điều chỉnh giá|
|SG02\-E24|Applied\-price input|`Giá áp dụng`|Nhập manual price override|D\-11; validation theo Theme 4|
|SG02\-E25|Price\-reason input|`Lý do điều chỉnh`|Ghi căn cứ điều chỉnh giá|Required khi policy yêu cầu|
|SG02\-E26|Private\-price action|`Lưu thành giá riêng`|Mở D\-12|Có Customer, ProductUnit và permission phù hợp|
|SG02\-E27|Private\-price summary|Khách hàng · sản phẩm · đơn vị · giá|Review dữ liệu trước khi tạo/cập nhật giá riêng|D\-12|
|SG02\-E28|Confirm\-private\-price button|`Lưu giá riêng`|Gửi command sang Theme 4|D\-12; idempotent|



**7\. Primary action behavior**

- `Thanh toán` chỉ enabled khi draft có ít nhất một dòng và mọi dòng có sản phẩm, đơn vị, số lượng, pricing result hợp lệ; không có blocked condition; người dùng có permission checkout\.

- Khi chọn `Thanh toán`:

    - Lưu thay đổi chưa persist\.

    - Revalidate draft\.

    - Hợp lệ: chuyển sang SG\-05\.

    - Warning không chặn: hiển thị cảnh báo trước khi tiếp tục\.

    - Lỗi chặn: giữ tại SG\-02 và focus dòng cần xử lý\.

- Không tạo official order tại SG\-02\.

    

**8\. Add\-product behavior**

- `Thêm sản phẩm` mở SG\-03 và giữ draft context\.

- Sau khi chọn, SG\-03 trả ProductUnit và dữ liệu tham chiếu\.

- SG\-02 thêm/cập nhật dòng theo line identity rule, resolve pricing, tính lại summary và lưu draft\.

- Không cho tạo nhanh sản phẩm\.

    

**9\. Customer behavior**

- Chưa gắn khách hàng: hiển thị `Khách lẻ`\.

- Chọn customer card mở SG\-04\.

- Sau khi chọn/tạo nhanh: gắn customer reference, reprice nếu cần, cập nhật context và lưu draft\.

- Nếu thay khách làm đổi giá, hiển thị feedback và đánh dấu dòng chịu ảnh hưởng\.

- SG\-02 không chỉnh customer master data\.

    

**10\. Edit\-line behavior**

- Chạm quantity, unit hoặc edit action mở D\-03\.

- D\-03 chỉ hiển thị field được phép chỉnh\.

- Quantity phải lớn hơn 0, tuân thủ precision của ProductUnit và giới hạn hệ thống\.

- Unit chỉ chọn từ đơn vị hợp lệ; thay unit phải reprice\.

- Unit price read\-only nếu không có quyền; override phải tuân thủ rule và lý do nếu bắt buộc\.

- `Áp dụng` validate, cập nhật line, reprice, cập nhật summary và lưu draft\.

    

**11\. Line\-action behavior**

- D\-04 có thể gồm `Chỉnh sửa`, `Xem chi tiết giá`, `Xem cảnh báo` và `Xóa khỏi đơn`\.

- Xóa dòng khỏi draft; nếu là dòng cuối chuyển về D\-01\.

- Không xóa Product hoặc ProductUnit master data\.



**12\.** **Pricing behavior**

- Giá hiển thị là pricing result hiện tại do Theme 4 cung cấp\.

- Pricing breakdown phải phân biệt tối thiểu base price, giá áp dụng, discount/promotion, manual override và nguồn giá khi được phép hiển thị\.

- Hệ thống reprice khi thay sản phẩm, ProductUnit, số lượng, khách hàng hoặc pricing/promotion context\.

- SG\-02 không tự tính giá ngoài authoritative pricing contract\.

- Chọn `Xem chi tiết giá` mở D\-11 nhưng không thay đổi draft\.

- Chọn `Điều chỉnh giá` chỉ khả dụng khi người dùng có permission phù hợp\.

- Manual price override phải tuân thủ giới hạn, precision, minimum/maximum rule và reason policy do Theme 4 cung cấp\.

- `Áp dụng giá` chỉ cập nhật pricing context của dòng hàng hiện tại, reprice draft và lưu draft; không tự động tạo giá riêng\.

- `Lưu thành giá riêng` là một command độc lập với manual price override\.

- Action lưu giá riêng chỉ khả dụng khi draft đã gắn Customer cụ thể; không áp dụng cho `Khách lẻ`\.

- D\-12 phải hiển thị Customer, Product, ProductUnit, giá đề xuất và phạm vi áp dụng trước khi xác nhận\.

- Việc tạo hoặc cập nhật giá riêng phải thực hiện qua authoritative contract của Theme 4, có permission, validation, idempotency và conflict handling\.

- SG\-02 không tự suy luận việc nên tạo mới hay cập nhật price rule nếu Theme 4 chưa trả quyết định tương ứng\.

- Sau khi lưu giá riêng thành công, pricing result của draft phải được resolve lại và phản ánh nguồn giá mới\.

- Nếu lưu giá riêng thất bại, manual price override đang áp dụng cho draft không được tự động xóa nếu bản thân override đã được lưu hợp lệ\.

- Pricing được revalidate trước khi mở SG\-05 và trước checkout commit\.



**13\. Inventory behavior**

- Availability/tồn kho dùng dữ liệu Theme 7 cung cấp\.

- Draft không làm giảm tồn kho\.

- Inventory impact chỉ phát sinh khi official order hoàn tất\.

- Bán vượt tồn kho theo cấu hình: được phép thì warning; không được phép thì blocked\.

    

**14\. Save behavior**

- Auto\-save sau thay đổi có ý nghĩa và debounce phù hợp\.

- Trạng thái gồm `Đang lưu`, `Đã lưu`, `Chưa lưu được`\.

- Save dùng draft version/concurrency control\.

- Version conflict không overwrite authoritative data\.

- Mất kết nối: giữ local data an toàn nếu có thể và không hiển thị `Đã lưu`\.

    

**15\. Validation and business rules**

- Draft có thể tồn tại khi chưa có dòng hàng nhưng không thể sang SG\-05\.

- Mỗi dòng phải có Product, ProductUnit, số lượng và pricing result\.

- Số lượng bằng 0 không được lưu như dòng bán\.

- Product/unit không hợp lệ tạo blocked state\.

- Thay customer, quantity hoặc unit có thể làm đổi pricing\.

- Total phải tính lại sau mọi thay đổi ảnh hưởng giá trị và khớp authoritative result\.

- Draft chưa tạo payment transaction, receivable entry, stock movement, e\-invoice hoặc official reporting record\.

    

**16\. Permission rules**

- `View sales draft`: mở draft\.

- `Edit sales draft`: chỉnh dòng và customer context\.

- `Add sales line`: thêm sản phẩm\.

- `Remove sales line`: xóa dòng\.

- `Override sales price`: sửa giá theo pricing rule\.

- `Discard sales draft`: bỏ draft\.

- `Checkout sales draft`: dùng CTA Thanh toán\.

- View\-only: field read\-only; không có Thêm sản phẩm, Thanh toán, D\-03 hoặc xóa dòng\.

    

**17\. Loading, empty, error and blocked handling**

- Empty: D\-01; CTA `Thêm sản phẩm`; Thanh toán disabled với lý do\.

- Loading: skeleton customer, line list, summary; không dùng total cũ như authoritative data\.

- Warning: đặt sát dòng và có action xử lý\.

- Blocked: chỉ rõ dòng/nguyên nhân, disable Thanh toán và scroll/focus đến dòng lỗi\.

- Save error: `Chưa lưu được`, `Thử lưu lại`, giữ input\.

- Load error: D\-10 và không tạo draft thay thế\.

    

**18\. Feedback**

- Thêm sản phẩm: dòng mới xuất hiện và feedback nhẹ\.

- Cập nhật dòng: summary cập nhật sau authoritative response hoặc optimistic update có kiểm soát\.

- Xóa dòng: dòng biến mất; dòng cuối chuyển D\-01\.

- Chọn khách: customer card cập nhật\.

- Auto\-save thành công/thất bại: `Đã lưu`/`Chưa lưu được`\.

- Warning mới: hiển thị theo dòng và summary nếu ảnh hưởng checkout\.

    

**19\. Accessibility**

- Dòng hàng và controls có vùng chạm, accessible label phù hợp\.

- Warning/blocked không chỉ phân biệt bằng màu\.

- Tiền tệ được đọc đúng định dạng\.

- CTA disabled có accessible explanation\.

- Focus order: top bar → customer → thêm sản phẩm → lines → summary → thanh toán\.

- Bottom sheet D\-03/D\-04 trap focus phù hợp\.

    

**20\. Responsive behavior**

- Mobile: một cột, line card/list, summary và CTA sticky bottom\.

- Tablet: có thể chia content và summary thành hai vùng\.

- Web: có thể dùng table/grid và side summary\.

- Rules, validation và action eligibility không đổi theo viewport\.

- Nội dung dài scroll tự nhiên; không resize typography/component để ép vừa\.

    

#### Low\-fi wireframes

**D\-01 — Empty order**

```Plain Text
┌─────────────────────────────────────┐
│ <   Tạo đơn hàng                    ⋮     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 👤 Khách lẻ        Chọn khách  >│ │
│ └─────────────────────────────────┘ │
│              [ 🛒 ]                 │
│       Chưa có sản phẩm              │
│  Thêm sản phẩm để bắt đầu tạo đơn.  │
│ [          + Thêm sản phẩm        ] │
├─────────────────────────────────────┤
│ Tạm tính                         0đ │
│ [ Thanh toán                     ]  │
│   Thêm ít nhất một sản phẩm         │
└─────────────────────────────────────┘
```

**D\-02 — Populated order**

```Plain Text
┌─────────────────────────────────────┐
│ <   Tạo đơn hàng                   ⋮     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 👤 Nguyễn Văn An              >│ │
│ │ 0912 345 678                   │ │
│ └─────────────────────────────────┘ │
│ [          + Thêm sản phẩm        ] │
│ ┌─────────────────────────────────┐ │
│ │ Amoxicillin 500mg          ⋮   │ │
│ │ Hộp · 2 × 185.000đ  370.000đ   │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Vitamin ADE 100ml          ⋮   │ │
│ │ Chai · 3 × 120.000đ 360.000đ   │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ Tạm tính                   730.000đ │
│ [ Thanh toán · 730.000đ           ] │
└─────────────────────────────────────┘
```

**D\-03 — Edit line bottom sheet**

```Plain Text
┌─────────────────────────────────────┐
│ ╭─────────────────────────────────╮ │
│ │ Chỉnh sửa sản phẩm              │ │
│ │ Amoxicillin 500mg               │ │
│ │ Đơn vị  [ Hộp               ▾ ] │ │
│ │ Số lượng [−]    2    [+]        │ │
│ │ Đơn giá [ 185.000            ] │ │
│ │ Thành tiền           370.000đ  │ │
│ │ [          Áp dụng            ] │ │
│ ╰─────────────────────────────────╯ │
└─────────────────────────────────────┘
```

**D\-04 — Line action sheet**

```Plain Text
┌─────────────────────────────────────┐
│ ╭─────────────────────────────────╮ │
│ │ Amoxicillin 500mg               │ │
│ │ ✎  Chỉnh sửa                    │ │
│ │ ⓘ  Xem chi tiết giá             │ │
│ │ 🗑  Xóa khỏi đơn                │ │
│ │ [            Đóng             ] │ │
│ ╰─────────────────────────────────╯ │
└─────────────────────────────────────┘
```

**D\-05 — Warning state**

```Plain Text
┌─────────────────────────────────────┐
│ <   Tạo đơn hàng                  ⋮ │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ ⚠ Giá bán đã thay đổi          │ │
│ │ Vui lòng kiểm tra trước khi    │ │
│ │ thanh toán.                    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Amoxicillin 500mg          ⋮   │ │
│ │ 180.000đ → 185.000đ            │ │
│ │ ⚠ Giá đã được cập nhật          │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ Tạm tính                   370.000đ │
│ [ Kiểm tra & tiếp tục             ] │
└─────────────────────────────────────┘
```

**D\-06 — Blocked state**

```Plain Text
┌─────────────────────────────────────┐
│ <   Tạo đơn hàng                         │
├─────────────────────────────────────┤
│ ! Chưa thể thanh toán               │
│ ┌─────────────────────────────────┐ │
│ │ Amoxicillin 500mg              │ │
│ │ ! Đơn vị này không còn được bán │ │
│ │ [          Chọn lại đơn vị   ] │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ [ Thanh toán                     ]  │
│   Xử lý sản phẩm chưa hợp lệ         │
└─────────────────────────────────────┘
```

**D\-07 — Save/sync warning**

```Plain Text
┌─────────────────────────────────────┐
│ <   Tạo đơn hàng                    │
├─────────────────────────────────────┤
│ ⚠ Thay đổi chưa được lưu            │
│ Dữ liệu vẫn được giữ trên màn hình. │
│ [         Thử lưu lại             ] │
├─────────────────────────────────────┤
│ Tạm tính                   360.000đ │
│ [ Thanh toán                     ]  │
│   Lưu thay đổi trước khi thanh toán  │
└─────────────────────────────────────┘
```

**D\-08 — Discard confirmation**

```Plain Text
┌─────────────────────────────────────┐
│ ┌─────────────────────────────────┐ │
│ │        Bỏ đơn nháp?            │ │
│ │ Đơn có 2 mặt hàng, tạm tính    │ │
│ │ 730.000đ và không thể tiếp tục │ │
│ │ sau khi bỏ.                    │ │
│ │ [          Giữ lại           ] │ │
│ │ [       Bỏ đơn nháp           ]│ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**D\-09 — Loading/revalidation**

```Plain Text
┌─────────────────────────────────────┐
│ <   Tạo đơn hàng                         │
│ Đang kiểm tra...                    │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ ░░░░░░░░░░░░░░░░              │ │
│ │ ░░░░░░░░░░░░                  │ │
│ └─────────────────────────────────┘ │
│ Đang cập nhật giá và dữ liệu...     │
├─────────────────────────────────────┤
│ [ Thanh toán                     ]  │
└─────────────────────────────────────┘
```

**D\-10 — Error state**

```Plain Text
┌─────────────────────────────────────┐
│ <   Tạo đơn hàng                         │
├─────────────────────────────────────┤
│              [ ! ]                  │
│       Chưa tải được đơn nháp        │
│  Vui lòng kiểm tra kết nối và thử   │
│  lại. Đơn nháp không bị thay đổi.   │
│ [             Thử lại             ] │
│ [              Đóng               ] │
└─────────────────────────────────────┘
```

#### Visuals

TBD\.

#### Traceability

TBD\.

### 5\.5\.4 SG\-03 — Chọn sản phẩm



#### Overview



- Purpose: Cho phép người dùng tìm, nhận diện và chọn đúng sản phẩm cùng đơn vị bán để thêm vào draft bán hàng\.

- Related epic: EP\-01 — Lập đơn hàng \& lưu nháp\.

- Related business flow: BF\-02 — Soạn nội dung đơn\.

- Business flow group: Core selling\.

- Primary users: Nhân viên bán hàng, thu ngân, chủ đơn vị trực tiếp bán hàng\.

- Primary task: Chọn một ProductUnit hợp lệ để trả về SG\-02\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: Tối ưu tốc độ tìm và chọn trong luồng bán hàng tần suất cao, nhưng vẫn giúp người dùng phân biệt các sản phẩm gần giống nhau và nhận biết trạng thái bán/tồn kho trước khi chọn\.

- Scope boundary: SG\-03 chỉ chọn sản phẩm hiện có; không cho phép tạo nhanh hoặc chỉnh sửa sản phẩm\.

    

#### Entry \& exit



- Entry points:

    - CTA `Thêm sản phẩm` từ SG\-02\.

    - Action thay sản phẩm của một dòng hàng từ SG\-02, nếu nghiệp vụ cho phép\.

    - Quay lại từ màn hình chi tiết sản phẩm trong phạm vi SG\-03\.

        

- Exit points:

    - Chọn ProductUnit hợp lệ → trả kết quả về SG\-02\.

    - Đóng/quay lại → trở về SG\-02 mà không thay đổi draft\.

    - Mở chi tiết sản phẩm → giữ nguyên search/filter context trong SG\-03\.

    - Phiên làm việc hoặc quyền truy cập không còn hợp lệ → về trạng thái blocked hoặc điều hướng về điểm vào an toàn\.

        

#### Screen/state inventory



|State|Type|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|Screen — Default|Hiển thị search, bộ lọc và danh sách sản phẩm bán được|Chọn sản phẩm|Có thể ưu tiên sản phẩm gần đây/phổ biến khi chưa nhập query|
|D\-02|Screen — Search results|Hiển thị kết quả phù hợp với query|Chọn sản phẩm|Highlight thông tin giúp phân biệt sản phẩm|
|D\-03|Empty state|Xử lý trường hợp catalog không có sản phẩm khả dụng|Quay lại|Không có CTA tạo nhanh sản phẩm|
|D\-04|No\-result state|Xử lý query/filter không có kết quả|Xóa tìm kiếm|Có thể gợi ý bỏ bớt filter|
|D\-05|Bottom sheet — Chọn đơn vị bán|Chọn ProductUnit khi sản phẩm có nhiều đơn vị|Chọn đơn vị|Bỏ qua state này nếu chỉ có một đơn vị hợp lệ|
|D\-06|Product detail|Cung cấp thông tin bổ sung để phân biệt sản phẩm|Chọn sản phẩm|Là state trong SG\-03, không phải màn quản trị sản phẩm|
|D\-07|Warning state|Cảnh báo tồn kho thấp, bán vượt tồn hoặc thông tin cần chú ý|Vẫn chọn / Quay lại|Action phụ thuộc cấu hình bán vượt tồn|
|D\-08|Blocked state|Ngăn chọn sản phẩm/đơn vị không còn hợp lệ|Chọn sản phẩm khác|Nêu rõ nguyên nhân và không trả selection về SG\-02|
|D\-09|Loading state|Tải catalog, tìm kiếm hoặc availability|—|Dùng skeleton; không làm mất query/filter|
|D\-10|Error state|Xử lý lỗi tải hoặc tìm kiếm|Thử lại|Giữ nguyên context và không tự chọn sản phẩm|



#### UI Contract



**User intent**



- Tìm sản phẩm nhanh bằng tên, mã hoặc barcode\.

- Phân biệt các sản phẩm có tên gần giống nhau\.

- Biết sản phẩm có thể bán hay không tại context hiện tại\.

- Chọn đúng đơn vị bán\.

- Thêm sản phẩm vào draft mà không rời ngữ cảnh bán hàng\.

    

**Information hierarchy**



1. Search/barcode action\.

2. Kết quả phù hợp và khả năng chọn\.

3. Tên sản phẩm và mã nhận diện\.

4. Đơn vị bán, giá hiện hành và availability/tồn kho\.

5. Bộ lọc và thông tin bổ sung\.

    

**Layout anatomy**



- Top bar:

    - Title `Chọn sản phẩm`\.

    - Back/close action\.

- Search area:

    - Search input luôn dễ tiếp cận\.

    - Barcode scan action nếu thiết bị và permission hỗ trợ\.

- Filter area:

    - Category hoặc nhóm sản phẩm\.

    - Availability filter khi hữu ích\.

    - Chỉ hiển thị filter có giá trị trong sales context\.

- Result area:

    - Product cards/rows\.

    - Loading, empty, no\-result và error states tại cùng vùng\.

- Unit selection:

    - D\-05 dạng bottom sheet trên mobile\.

    - Hiển thị từng ProductUnit hợp lệ cùng giá/availability liên quan\.

        

**Displayed data**



- Tên sản phẩm\.

- Mã sản phẩm/SKU hoặc barcode phù hợp\.

- Ảnh thumbnail nếu có; ảnh không phải dữ liệu bắt buộc để nhận diện\.

- Đơn vị bán mặc định hoặc số lượng đơn vị khả dụng\.

- Giá hiện hành theo sales context; ghi rõ đây là giá tham chiếu nếu giá cuối cùng còn phụ thuộc khách hàng/số lượng\.

- Availability/tồn kho theo store/location hiện tại khi Theme 7 cung cấp\.

- Trạng thái `Ngừng bán`, `Không khả dụng`, `Tồn kho thấp` hoặc `Hết hàng` khi áp dụng\.

- Category/brand/variant attribute cần thiết để phân biệt sản phẩm\.

    

**User inputs**



- Search query\.

- Barcode/QR scan input nếu được hỗ trợ\.

- Category/filter selection\.

- Product selection\.

- ProductUnit selection trong D\-05\.

    

**Element inventory**



|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG03\-E01|Top bar|`Chọn sản phẩm`|Xác định task hiện tại|Luôn hiển thị|
|SG03\-E02|Back/close action|`Quay lại` / `Đóng`|Trở về SG\-02, không thay đổi draft|Disabled khi selection đang commit|
|SG03\-E03|Search input|`Tìm tên, mã hoặc barcode`|Search catalog trong sales scope|Default, focus, populated, error|
|SG03\-E04|Scan action|`Quét mã`|Mở scanner và tìm exact/possible match|Theo device capability và permission|
|SG03\-E05|Filter control|`Bộ lọc`|Mở filter options|Có badge khi filter active|
|SG03\-E06|Active filter chip|Tên filter|Loại từng filter|Chỉ hiện khi active|
|SG03\-E07|Result count|`... sản phẩm`|Phản ánh kết quả hiện tại|Ẩn khi loading/error nếu số liệu không chắc chắn|
|SG03\-E08|Product list|Danh sách sản phẩm|Hiển thị kết quả|Loading, populated, empty, no\-result, error|
|SG03\-E09|Product card|Tóm tắt sản phẩm|Chọn trực tiếp hoặc mở D\-05|Default, warning, blocked|
|SG03\-E10|Product identity|Tên · mã · variant|Giúp nhận diện|Tên tối đa hai dòng trên mobile|
|SG03\-E11|Product thumbnail|Ảnh sản phẩm|Hỗ trợ nhận diện|Có placeholder khi thiếu ảnh|
|SG03\-E12|Unit summary|Đơn vị mặc định / `... đơn vị`|Cho biết cách bán|Mở D\-05 khi có nhiều lựa chọn|
|SG03\-E13|Price label|Giá theo đơn vị|Hỗ trợ quyết định|Có thể là `Từ ...` nếu nhiều đơn vị|
|SG03\-E14|Availability label|Tồn kho/trạng thái|Cảnh báo trước khi chọn|Normal, warning, blocked, unavailable|
|SG03\-E15|Detail action|`Xem chi tiết`|Mở D\-06|Khi thông tin card chưa đủ|
|SG03\-E16|Unit option|Đơn vị · giá · availability|Chọn ProductUnit|D\-05|
|SG03\-E17|Clear\-search action|`Xóa tìm kiếm`|Xóa query, giữ filter hợp lệ|D\-04|
|SG03\-E18|Clear\-filter action|`Xóa bộ lọc`|Khôi phục catalog trong scope|Khi active filter gây no\-result|
|SG03\-E19|Retry button|`Thử lại`|Retry request thất bại|D\-10|
|SG03\-E20|Alternate action|`Chọn sản phẩm khác`|Đóng blocked/warning state|D\-07/D\-08|



**Search and scan behavior**



- Search trong tập sản phẩm người dùng được phép bán tại tenant/store hiện tại\.

- Query hỗ trợ tên, mã sản phẩm, SKU và barcode theo khả năng của catalog service\.

- Search text có debounce phù hợp; không gửi request cho từng phím nếu không cần thiết\.

- Xóa query khôi phục danh sách theo filter hiện tại\.

- Barcode exact match:

    - Một ProductUnit hợp lệ → chọn theo rule hoặc yêu cầu xác nhận ngắn nếu cần\.

    - Nhiều kết quả → hiển thị danh sách để người dùng phân biệt\.

    - Không có kết quả → hiển thị D\-04, không cung cấp CTA tạo sản phẩm\.

- Lỗi camera/permission không làm hỏng search bằng bàn phím\.

    

**Filter behavior**



- Filter chỉ thu hẹp tập kết quả trong sales scope, không mở rộng permission hoặc store scope\.

- Active filters luôn nhìn thấy và có thể xóa riêng lẻ\.

- Khi không có kết quả, ưu tiên gợi ý xóa filter trước khi coi catalog là rỗng\.

- Không dùng filter mặc định làm ẩn sản phẩm hợp lệ nếu người dùng không nhận biết được\.

    

**Product selection behavior**



- Product chỉ có một ProductUnit hợp lệ: chạm card trả ProductUnit về SG\-02\.

- Product có nhiều ProductUnit hợp lệ: chạm card mở D\-05\.

- ProductUnit được chọn phải trả về tối thiểu product ID, product\-unit ID và dữ liệu tham chiếu cần cho pricing/availability resolution\.

- SG\-02 là nơi tạo/cập nhật sales line, reprice và lưu draft\.

- SG\-03 không tự ghi dòng hàng vào draft nếu selection chưa được SG\-02 xác nhận\.

- Chống double\-select trong thời gian commit/return navigation\.

    

**Unit\-selection behavior**



- D\-05 chỉ hiển thị ProductUnit được phép bán tại context hiện tại\.

- Mỗi option nêu rõ unit name, conversion/pack information khi cần, giá tham chiếu và availability\.

- Đơn vị mặc định có thể được ưu tiên nhưng không được tự chọn nếu gây mơ hồ\.

- ProductUnit bị invalid trong lúc chọn chuyển D\-08 và yêu cầu chọn lại\.

    

**Product\-detail behavior**



- D\-06 dùng để hỗ trợ lựa chọn, không cung cấp create/edit/archive action\.

- Có thể hiển thị ảnh, mô tả ngắn, mã/barcode, variant, các đơn vị bán và availability\.

- Primary action vẫn là chọn ProductUnit hợp lệ\.

- Quay lại từ D\-06 giữ nguyên query, filter và vị trí danh sách khi có thể\.

    

**Availability and inventory behavior**



- Availability/tồn kho lấy từ contract do Theme 7 cung cấp; SG\-03 không tự tính tồn kho\.

- Draft không giữ chỗ và không làm giảm tồn kho\.

- Tồn kho thấp là warning, không mặc định blocked\.

- Hết hàng:

    - Nếu cấu hình cho bán vượt tồn → D\-07 và cho phép tiếp tục\.

    - Nếu không cho bán vượt tồn → D\-08 và không cho chọn\.

- Nếu availability chưa tải được nhưng policy cho phép bán, UI nêu `Chưa xác minh tồn kho` thay vì hiển thị số giả\.

    

**Pricing behavior**



- Giá tại SG\-03 là thông tin hỗ trợ chọn sản phẩm, không phải cam kết tổng tiền cuối cùng\.

- Giá cuối cùng được resolve/revalidate tại SG\-02 theo customer, quantity, unit, promotion và pricing context\.

- Khi chưa có giá hợp lệ:

    - Nếu policy cho phép resolve sau → warning và cho chọn\.

    - Nếu product không thể định giá để bán → blocked\.

- Không cho sửa giá tại SG\-03\.

    

**Business rules and invariants**



- Chỉ active/sellable Product và ProductUnit trong tenant/store scope mới được chọn\.

- Không cho phép tạo nhanh sản phẩm tại SG\-03\.

- Không cho phép chỉnh sửa Product hoặc ProductUnit master data tại SG\-03\.

- Một selection trả về đúng một ProductUnit\.

- Không coi thumbnail, cached price hoặc cached stock là authoritative nếu dữ liệu đã stale\.

- Chọn sản phẩm chưa tạo official order, payment, receivable, inventory movement hoặc e\-invoice\.

- Search/filter không được làm lộ sản phẩm ngoài permission scope\.

    

**Permissions**



- `View sellable products`: xem catalog bán hàng\.

- `View product price`: xem giá nếu permission model tách quyền giá\.

- `View inventory availability`: xem availability/tồn kho nếu được phép\.

- `Scan product barcode`: dùng camera/scanner khi platform yêu cầu quyền riêng\.

- SG\-03 không yêu cầu quyền tạo hoặc chỉnh sửa product master\.

- Không có quyền xem catalog → blocked state và quay lại SG\-02\.

    

**Empty, loading, error and blocked states**



- Empty catalog: D\-03; giải thích chưa có sản phẩm khả dụng; chỉ có `Quay lại` hoặc hướng dẫn liên hệ người có quyền, không có tạo nhanh\.

- No result: D\-04; hiển thị query/filter hiện tại; có `Xóa tìm kiếm` và/hoặc `Xóa bộ lọc`\.

- Loading: D\-09; skeleton trong result area; giữ search/filter ổn định\.

- Search error: D\-10; giữ query/filter và cho `Thử lại`\.

- Product blocked: D\-08; nêu sản phẩm/đơn vị và nguyên nhân; có `Chọn sản phẩm khác`\.

- Stale result: revalidate khi chọn; không trả stale ProductUnit về SG\-02 như một selection hợp lệ\.

    

**Feedback and messaging**



- Search không kết quả dùng neutral empty message, không dùng error semantic\.

- Tồn kho thấp hoặc chưa xác minh dùng warning semantic\.

- Không được phép bán hoặc ProductUnit invalid dùng blocked/error semantic\.

- Sau khi chọn thành công, chuyển về SG\-02; không cần success toast nếu dòng hàng mới đã xuất hiện rõ ràng\.

- Scanner thất bại nêu cách tiếp tục bằng search text\.

    

**Accessibility**



- Search input, scan action, filter và product cards có accessible label\.

- Product card là một vùng chạm rõ ràng; action phụ không chồng vùng chạm chính\.

- Trạng thái availability không chỉ biểu đạt bằng màu\.

- Giá, số lượng tồn và đơn vị được screen reader đọc theo đúng thứ tự/ngữ nghĩa\.

- D\-05 trap focus phù hợp và trả focus về product card khi đóng\.

- Focus order: top bar → search/scan → filters → result count → product list\.

    

**Responsive behavior**



- Mobile: một cột, search sticky khi danh sách dài; D\-05 là bottom sheet\.

- Tablet: có thể dùng grid hai cột hoặc master\-detail nếu vẫn dễ scan\.

- Web: có thể dùng list/table/grid và side filter\.

- Search, eligibility, selection và return contract không đổi theo viewport\.

- Nội dung dài truncate/wrap có kiểm soát; mã và variant quan trọng không bị che hoàn toàn\.

    

#### Low\-fi wireframes



**D\-01 — Default**



```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn sản phẩm             │
├──────────────────────────────┤
│ 🔎 Tìm tên, mã hoặc barcode  │
│ [Quét mã]        [Bộ lọc]    │
│ [Tất cả] [Thuốc] [Vật tư]    │
├──────────────────────────────┤
│ Sản phẩm gần đây             │
│ ┌──────────────────────────┐ │
│ │ [Ảnh] Sản phẩm A         │ │
│ │ SKU-001 · Chai           │ │
│ │ 120.000 ₫    Còn hàng    │ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ [Ảnh] Sản phẩm B         │ │
│ │ 3 đơn vị · Từ 45.000 ₫   │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```



**D\-02 — Search results**



```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn sản phẩm             │
├──────────────────────────────┤
│ 🔎 amoxi                  ×  │
│ [Bộ lọc]                    │
├──────────────────────────────┤
│ 4 sản phẩm                   │
│ ┌──────────────────────────┐ │
│ │ Amoxi 500 mg             │ │
│ │ AMX-500 · Hộp            │ │
│ │ 85.000 ₫     Còn hàng    │ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ Amoxi 250 mg             │ │
│ │ AMX-250 · Hộp            │ │
│ │ 62.000 ₫     Tồn thấp    │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```



**D\-03 — Empty catalog**



```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn sản phẩm             │
├──────────────────────────────┤
│                              │
│      Chưa có sản phẩm        │
│      khả dụng để bán         │
│                              │
│ Liên hệ người quản lý để     │
│ kiểm tra danh mục sản phẩm.  │
│                              │
│         [Quay lại]           │
└──────────────────────────────┘
```



**D\-04 — No result**



```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn sản phẩm             │
├──────────────────────────────┤
│ 🔎 xyz-123                ×  │
│ [Còn hàng ×] [Thuốc ×]       │
├──────────────────────────────┤
│ Không tìm thấy sản phẩm      │
│ phù hợp với tìm kiếm và      │
│ bộ lọc hiện tại.             │
│                              │
│     [Xóa tìm kiếm]           │
│     [Xóa bộ lọc]             │
└──────────────────────────────┘
```



**D\-05 — Chọn đơn vị bán**



```Plain Text
┌──────────────────────────────┐
│                              │
├──────────────────────────────┤
│ Chọn đơn vị bán          ×   │
│ Sản phẩm B                  │
│ ○ Viên                      │
│   5.000 ₫ · Còn hàng        │
│ ○ Vỉ (10 viên)              │
│   48.000 ₫ · Còn hàng       │
│ ○ Hộp (10 vỉ)               │
│   450.000 ₫ · Tồn thấp      │
└──────────────────────────────┘
```



**D\-06 — Product detail**



```Plain Text
┌──────────────────────────────┐
│ ‹  Chi tiết sản phẩm         │
├──────────────────────────────┤
│        [Ảnh sản phẩm]        │
│ Sản phẩm B                   │
│ SKU-002 · Barcode 893...     │
│ Nhóm: Vật tư                 │
│                              │
│ Đơn vị bán                   │
│ Viên · Vỉ · Hộp              │
│ Availability: Còn hàng       │
│                              │
│       [Chọn sản phẩm]        │
└──────────────────────────────┘
```



**D\-07 — Warning**



```Plain Text
┌──────────────────────────────┐
│ Tồn kho cần chú ý            │
├──────────────────────────────┤
│ Sản phẩm B · Hộp             │
│                              │
│ Số lượng khả dụng hiện thấp. │
│ Tồn kho sẽ được kiểm tra lại │
│ trước khi hoàn tất đơn.      │
│                              │
│ [Chọn sản phẩm khác]         │
│ [Vẫn chọn]                   │
└──────────────────────────────┘
```



**D\-08 — Blocked**



```Plain Text
┌──────────────────────────────┐
│ Không thể chọn sản phẩm      │
├──────────────────────────────┤
│ Sản phẩm B · Hộp không còn   │
│ khả dụng để bán tại cửa hàng │
│ hiện tại.                    │
│                              │
│    [Chọn sản phẩm khác]      │
└──────────────────────────────┘
```



**D\-09 — Loading**



```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn sản phẩm             │
├──────────────────────────────┤
│ 🔎 Tìm tên, mã hoặc barcode  │
│ [Quét mã]        [Bộ lọc]    │
├──────────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒            │
│                              │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒            │
└──────────────────────────────┘
```



**D\-10 — Error**



```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn sản phẩm             │
├──────────────────────────────┤
│ 🔎 amoxi                  ×  │
├──────────────────────────────┤
│ Không thể tải sản phẩm       │
│ Tìm kiếm và bộ lọc của anh   │
│ vẫn được giữ lại.            │
│                              │
│          [Thử lại]           │
│          [Quay lại]          │
└──────────────────────────────┘
```

**D\-11 — Price details \& adjustment**

```Plain Text
┌──────────────────────────────┐
│ Chi tiết giá             ×   │
├──────────────────────────────┤
│ Amoxi 500 mg · Hộp            │
│ Giá cơ sở         85.000 ₫    │
│ Giá riêng         82.000 ₫    │
│ Khuyến mại        -2.000 ₫    │
│ Giá áp dụng       80.000 ₫    │
│                              │
│ Điều chỉnh giá               │
│ [78.000                    ] │
│ Lý do                        │
│ [Khách hàng thỏa thuận     ] │
├──────────────────────────────┤
│ [Lưu thành giá riêng]        │
│ [Áp dụng giá]                │
└──────────────────────────────┘
```

**D\-12 — Save private price**

```Perl

┌──────────────────────────────┐
│ Lưu giá riêng            ×   │
├──────────────────────────────┤
│ Khách hàng                  │
│ Nguyễn Văn An · KH-0124      │
│                              │
│ Sản phẩm                    │
│ Amoxi 500 mg · Hộp           │
│                              │
│ Giá riêng mới     78.000 ₫   │
│ Giá đang áp dụng  80.000 ₫   │
├──────────────────────────────┤
│       [Lưu giá riêng]        │
└──────────────────────────────┘
```

#### Visuals



TBD\.



#### Traceability



TBD\.

### 5\.5\.5 SG\-04 — Chọn khách hàng

#### Overview

- Purpose: Cho phép người dùng tìm, chọn hoặc tạo nhanh khách hàng để gắn vào draft bán hàng\.

- Related epic: EP\-01 — Lập đơn hàng \& lưu nháp\.

- Related business flow: BF\-03 — Bổ sung ngữ cảnh bán hàng\.

- Business flow group: Core selling\.

- Primary users: Nhân viên bán hàng, thu ngân, chủ đơn vị trực tiếp bán hàng\.

- Primary task: Chọn một khách hàng hiện có hoặc tạo nhanh khách hàng mới để trả về SG\-02\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: Cho phép hoàn thành việc gắn khách hàng với ít thao tác nhất, nhưng vẫn kiểm soát dữ liệu trùng lặp và không biến luồng bán hàng thành màn quản trị hồ sơ khách hàng\.

- Scope boundary: SG\-04 cho phép tạo nhanh khách hàng với bộ dữ liệu tối thiểu; việc xem và chỉnh sửa hồ sơ đầy đủ thuộc Theme 3\.

    

#### Entry \& exit

- Entry points:

    - Customer card `Khách lẻ` hoặc action `Chọn khách hàng` từ SG\-02\.

    - Action `Thay đổi` trên customer card đã gắn trong SG\-02\.

    - Quay lại từ form tạo nhanh khách hàng trong SG\-04\.

- Exit points:

    - Chọn khách hàng hiện có → trả Customer reference về SG\-02\.

    - Tạo nhanh thành công → trả Customer mới về SG\-02\.

    - Chọn `Khách lẻ` → xóa Customer reference hiện tại và trở về SG\-02\.

    - Đóng/quay lại → trở về SG\-02 mà không thay đổi customer context\.

    - Mở hồ sơ khách hàng đầy đủ → điều hướng sang Theme 3 nếu người dùng có quyền và business flow cho phép\.

    - Mất quyền hoặc sales context không còn hợp lệ → hiển thị blocked state hoặc trở về điểm vào an toàn\.

        

#### Screen/state inventory

|State|Type|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|Screen — Default|Hiển thị search, lựa chọn Khách lẻ và danh sách khách hàng gần đây|Chọn khách hàng|`Khách lẻ` luôn dễ tiếp cận|
|D\-02|Screen — Search results|Hiển thị khách hàng phù hợp với query|Chọn khách hàng|Ưu tiên thông tin giúp phân biệt khách trùng tên|
|D\-03|Empty state|Xử lý trường hợp chưa có khách hàng trong phạm vi truy cập|Tạo nhanh khách hàng|Vẫn cho phép chọn Khách lẻ|
|D\-04|No\-result state|Xử lý query không có kết quả|Tạo nhanh khách hàng|Có thể prefill dữ liệu từ query|
|D\-05|Form — Tạo nhanh khách hàng|Thu thập bộ dữ liệu tối thiểu để tạo Customer|Tạo \& chọn khách hàng|Không thay thế form quản trị đầy đủ của Theme 3|
|D\-06|Duplicate warning|Cảnh báo khách hàng có khả năng đã tồn tại|Chọn khách hàng hiện có|Có thể tiếp tục tạo khi có quyền và đủ lý do|
|D\-07|Validation state|Hiển thị lỗi dữ liệu trên form tạo nhanh|Sửa thông tin|Validation đặt sát field|
|D\-08|Blocked state|Ngăn chọn hoặc tạo khách hàng không hợp lệ/ngoài quyền|Chọn khách hàng khác|Không làm thay đổi customer hiện tại của draft|
|D\-09|Loading state|Tải danh sách, tìm kiếm hoặc tạo khách hàng|—|Giữ query và dữ liệu form|
|D\-10|Error state|Xử lý lỗi tải, tìm kiếm hoặc tạo khách hàng|Thử lại|Không tạo bản ghi local giả|



#### UI Contract

**User intent**

- Tiếp tục bán cho khách lẻ mà không cần tạo hồ sơ\.

- Tìm nhanh khách hàng bằng tên, số điện thoại hoặc mã khách hàng\.

- Phân biệt các khách hàng có tên giống nhau\.

- Gắn đúng khách hàng vào draft\.

- Tạo nhanh khách hàng mới khi chưa tồn tại\.

- Quay lại đơn hàng mà không mất nội dung đang soạn\.

    

**Information hierarchy**

1. Lựa chọn `Khách lẻ`\.

2. Search theo tên, số điện thoại hoặc mã khách hàng\.

3. Kết quả phù hợp và thông tin phân biệt khách hàng\.

4. Action tạo nhanh khách hàng\.

5. Thông tin phụ như nhóm khách hàng, địa chỉ hoặc công nợ nếu được phép hiển thị\.

    

**Layout anatomy**

- Top bar:

    - Title `Chọn khách hàng`\.

    - Back/close action\.

- Walk\-in customer area:

    - Option `Khách lẻ`\.

    - Trạng thái selected nếu draft chưa gắn Customer\.

- Search area:

    - Search input\.

    - Clear\-search action\.

- Result area:

    - Danh sách khách hàng gần đây hoặc kết quả tìm kiếm\.

    - Loading, empty, no\-result và error state\.

- Quick\-create area:

    - CTA `Tạo nhanh khách hàng`\.

    - D\-05 có thể là full\-screen form hoặc bottom sheet tùy viewport\.

- Sticky action:

    - Không bắt buộc ở D\-01/D\-02 vì chạm customer card là hành động chọn\.

    - D\-05 có CTA `Tạo & chọn khách hàng`\.

        

**Displayed data**

- Tên khách hàng\.

- Mã khách hàng nếu có\.

- Số điện thoại đã masking theo permission/privacy policy khi cần\.

- Địa chỉ ngắn hoặc khu vực nếu cần phân biệt\.

- Nhóm khách hàng hoặc customer type nếu ảnh hưởng pricing\.

- Mã số thuế nếu là tổ chức và cần phân biệt\.

- Trạng thái active/blocked\.

- Cảnh báo công nợ hoặc hạn mức tín dụng nếu Theme 3 cung cấp và có ảnh hưởng đến giao dịch\.

- Chỉ báo khách hàng hiện đang được gắn vào draft\.

    

**User inputs**

- Search query\.

- Customer selection\.

- Lựa chọn `Khách lẻ`\.

- Dữ liệu tạo nhanh:

    - Tên khách hàng\.

    - Số điện thoại\.

    - Loại khách hàng nếu bắt buộc\.

    - Mã số thuế nếu người dùng chọn loại tổ chức và nghiệp vụ yêu cầu\.

    - Địa chỉ ngắn nếu cần cho giao dịch\.

- Xác nhận xử lý duplicate warning\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG04\-E01|Top bar|`Chọn khách hàng`|Xác định task hiện tại|Luôn hiển thị|
|SG04\-E02|Back/close action|`Quay lại` / `Đóng`|Trở về SG\-02, không thay đổi customer|Disabled khi create request đang commit|
|SG04\-E03|Walk\-in option|`Khách lẻ`|Trả customer context rỗng về SG\-02|Default hoặc selected|
|SG04\-E04|Search input|`Tìm tên, SĐT hoặc mã KH`|Search trong customer scope|Default, focus, populated, error|
|SG04\-E05|Clear\-search action|`Xóa`|Xóa query và khôi phục danh sách mặc định|Khi có query|
|SG04\-E06|Customer list|Danh sách khách hàng|Hiển thị recent/search results|Loading, populated, empty, no\-result, error|
|SG04\-E07|Customer card|Tóm tắt khách hàng|Chọn customer và trở về SG\-02|Default, selected, warning, blocked|
|SG04\-E08|Customer identity|Tên · mã khách hàng|Nhận diện khách hàng|Tên tối đa hai dòng trên mobile|
|SG04\-E09|Phone label|Số điện thoại|Phân biệt khách hàng|Masking theo permission|
|SG04\-E10|Secondary identity|Địa chỉ · MST · nhóm khách|Phân biệt khách trùng tên|Chỉ hiển thị dữ liệu hữu ích|
|SG04\-E11|Customer status|`Đang hoạt động` / `Bị khóa`|Cho biết eligibility|Neutral hoặc blocked|
|SG04\-E12|Customer warning|Công nợ/hạn mức/cảnh báo|Cung cấp context trước khi chọn|Theo contract của Theme 3|
|SG04\-E13|Quick\-create button|`Tạo nhanh khách hàng`|Mở D\-05|Có permission tạo customer|
|SG04\-E14|Name input|`Tên khách hàng`|Nhập tên Customer|Required|
|SG04\-E15|Phone input|`Số điện thoại`|Nhập và chuẩn hóa số điện thoại|Optional/required theo policy|
|SG04\-E16|Customer\-type input|`Cá nhân` / `Tổ chức`|Xác định field liên quan|Khi business model cần|
|SG04\-E17|Tax\-code input|`Mã số thuế`|Nhập MST|Khi là tổ chức hoặc có nhu cầu hóa đơn|
|SG04\-E18|Address input|`Địa chỉ`|Nhập địa chỉ ngắn|Optional theo quick\-create contract|
|SG04\-E19|Create\-and\-select button|`Tạo & chọn khách hàng`|Validate, duplicate check, create và trả về SG\-02|D\-05|
|SG04\-E20|Existing\-customer action|`Chọn khách hàng này`|Dùng record có khả năng trùng|D\-06|
|SG04\-E21|Continue\-create action|`Vẫn tạo mới`|Tiếp tục tạo sau cảnh báo|Theo permission/policy|
|SG04\-E22|Retry button|`Thử lại`|Retry request thất bại|D\-10|
|SG04\-E23|Alternate action|`Chọn khách hàng khác`|Rời blocked state|D\-08|



**Default and search behavior**

- Khi mở SG\-04, `Khách lẻ` hiển thị trước danh sách khách hàng\.

- Nếu draft đã có Customer, customer đó được đánh dấu selected\.

- Khi chưa có query, có thể hiển thị khách hàng gần đây hoặc thường dùng trong store scope\.

- Search chỉ áp dụng trong tập khách hàng người dùng được phép truy cập\.

- Query hỗ trợ tên, số điện thoại và mã khách hàng; mã số thuế có thể được hỗ trợ nếu customer service cung cấp\.

- Search text có debounce phù hợp\.

- Xóa query khôi phục danh sách mặc định\.

- Search không thay đổi tenant/store scope hoặc mở rộng permission\.

- Kết quả ưu tiên exact phone/customer\-code match trước fuzzy name match nếu service hỗ trợ\.

    

**Walk\-in customer behavior**

- `Khách lẻ` tương ứng với draft không có Customer reference\.

- Chọn `Khách lẻ` khi draft đã gắn Customer phải:

    - Xóa Customer reference khỏi draft\.

    - Reprice các dòng hàng nếu pricing phụ thuộc khách hàng\.

    - Cập nhật các điều kiện tín dụng/công nợ liên quan\.

    - Trở về SG\-02 và hiển thị customer card là `Khách lẻ`\.

- Không tạo một Customer master record tên `Khách lẻ`\.

- `Khách lẻ` không được dùng để lưu thông tin nhận diện tạm thời ngoài customer contract\.

    

**Existing\-customer selection behavior**

- Chạm customer card chọn Customer nếu record active và trong scope\.

- SG\-04 trả về tối thiểu customer ID và customer reference cần thiết\.

- SG\-02 chịu trách nhiệm:

    - Gắn Customer vào draft\.

    - Reprice nếu customer context ảnh hưởng pricing\.

    - Cập nhật tax/invoice, credit hoặc promotion eligibility\.

    - Lưu draft\.

- Không cho double\-select trong thời gian commit/return navigation\.

- Customer bị invalid hoặc mất quyền tại thời điểm chọn → D\-08\.

- Việc chọn Customer không chỉnh sửa Customer master data\.

    

**Quick\-create entry behavior**

- CTA `Tạo nhanh khách hàng` hiển thị tại D\-01, D\-03 và D\-04 nếu người dùng có quyền\.

- Từ D\-04, hệ thống có thể prefill query vào tên, số điện thoại hoặc mã số thuế khi nhận diện chắc chắn\.

- Prefill chỉ là dữ liệu nhập ban đầu, không được coi là đã xác minh\.

- Nếu không có quyền tạo, CTA bị ẩn hoặc disabled kèm lý do; người dùng vẫn có thể chọn `Khách lẻ`\.

    

**Quick\-create data contract**

- Bộ field mặc định:

    - `Tên khách hàng`: bắt buộc\.

    - `Số điện thoại`: không bắt buộc ở cấp dữ liệu chung, nhưng có thể bắt buộc theo tenant policy\.

    - `Loại khách hàng`: mặc định `Cá nhân`; cho phép chọn `Tổ chức` nếu mô hình dữ liệu hỗ trợ\.

    - `Mã số thuế`: optional; được validate khi nhập\.

    - `Địa chỉ`: optional\.

- Không đưa vào quick\-create:

    - Nhiều địa chỉ hoặc nhiều người liên hệ\.

    - Credit limit và payment terms\.

    - Customer tags phức tạp\.

    - Hồ sơ pháp lý đầy đủ\.

    - Custom fields không bắt buộc cho giao dịch\.

- Các dữ liệu quản trị nâng cao được bổ sung sau tại Theme 3\.

    

**Validation behavior**

- Tên khách hàng được trim, không rỗng sau normalize và tuân thủ giới hạn độ dài\.

- Số điện thoại được normalize theo contract; không dùng formatting để tạo hai giá trị khác nhau\.

- Mã số thuế được normalize, validate format khi nhập nhưng không mặc định coi là đã xác minh pháp lý\.

- Lỗi field hiển thị sát field\.

- CTA create disabled khi đang xử lý hoặc thiếu field bắt buộc; server\-side validation vẫn luôn được thực hiện\.

    

**Duplicate\-detection behavior**

- Duplicate check được thực hiện trước hoặc trong create command\.

- Tín hiệu duplicate gồm số điện thoại trùng chính xác, mã số thuế trùng chính xác hoặc tên/địa chỉ gần giống\.

- Exact match quan trọng mở D\-06 trước khi tạo record mới\.

- Primary action là `Chọn khách hàng này`\.

- `Vẫn tạo mới` chỉ hiển thị khi duplicate rule không phải hard constraint và người dùng có permission phù hợp\.

- Hard duplicate constraint không cho phép bypass\.

    

**Quick\-create submit behavior**

1. Client validation\.

2. Normalize dữ liệu\.

3. Duplicate check\.

4. Create Customer qua authoritative command\.

5. Nhận Customer reference\.

6. Trả Customer về SG\-02\.

    

- Trong khi xử lý, CTA chuyển loading, ngăn submit lặp và giữ dữ liệu form\.

- Thành công: trở về SG\-02 với Customer mới được gắn; SG\-02 reprice và lưu draft\.

- Thất bại: giữ dữ liệu đã nhập, hiển thị lỗi field hoặc D\-10 và không tạo Customer local giả\.

    

**Customer warning and eligibility behavior**

- Customer active và không có restriction → chọn trực tiếp\.

- Customer có warning không chặn giao dịch → cho phép chọn và chuyển warning context về SG\-02 khi cần\.

- Customer bị blocked, archived hoặc ngoài scope → không cho chọn và hiển thị D\-08\.

- Công nợ/hạn mức chỉ hiển thị khi Theme 3 cung cấp authoritative status\.

- SG\-04 không tự tính số dư công nợ hoặc hạn mức\.

    

**Pricing and downstream impact**

- Customer selection có thể ảnh hưởng bảng giá, chiết khấu, khuyến mại, thuế/hóa đơn, hình thức thanh toán, bán chịu và credit eligibility\.

- SG\-04 không tự tính lại giá\.

- SG\-02 reprice toàn bộ dòng bị ảnh hưởng và hiển thị feedback nếu giá thay đổi\.

- Customer selection chưa tạo official order, receivable entry, payment hoặc invoice\.

    

**Business rules and invariants**

- Draft có thể không gắn Customer và được hiểu là giao dịch `Khách lẻ`\.

- Một draft chỉ gắn tối đa một Customer tại một thời điểm\.

- Customer được chọn phải thuộc tenant scope và người dùng có quyền truy cập\.

- Không tạo Customer master record cho `Khách lẻ`\.

- Tạo nhanh phải dùng cùng Customer domain contract với Theme 3\.

- Không cho phép chỉnh sửa hồ sơ Customer đầy đủ tại SG\-04\.

- Exact phone/tax\-code duplicate tuân thủ constraint của Customer domain\.

- Retry create phải dùng cơ chế chống tạo trùng\.

- Customer mới chỉ được coi là tạo thành công sau authoritative response\.

- Quay lại/đóng SG\-04 không thay đổi customer hiện tại của draft\.

    

**Permissions**

- `View customers`: tìm và xem khách hàng trong scope\.

- `Select customer for sale`: gắn khách hàng vào draft\.

- `Create customer`: sử dụng tạo nhanh\.

- `View customer phone`: xem đầy đủ số điện thoại nếu permission model yêu cầu\.

- `View customer receivable/credit status`: xem warning công nợ/hạn mức\.

- `Bypass soft duplicate warning`: tiếp tục tạo khi chỉ có soft duplicate\.

- Không có quyền xem customer: vẫn cho phép `Khách lẻ`, đồng thời ẩn danh sách/search customer\.

- Không có quyền tạo: ẩn hoặc disable quick\-create; không ảnh hưởng việc chọn khách hiện có hoặc `Khách lẻ`\.

    

**Empty, loading, error and blocked states**

- Empty customer list: D\-03; hiển thị `Khách lẻ` và CTA tạo nhanh nếu có quyền\.

- No result: D\-04; giữ query, cho xóa search hoặc tạo nhanh\.

- Loading: D\-09; dùng skeleton, giữ query và customer hiện tại\.

- Search/load error: D\-10; giữ query và cho thử lại\.

- Create validation error: D\-07; giữ dữ liệu và đặt lỗi sát field\.

- Create request error: D\-10 trong context form; không đóng form\.

- Customer blocked: D\-08; không trả selection về SG\-02\.

- Stale search result: revalidate khi chọn\.

    

**Feedback and messaging**

- Không có kết quả tìm kiếm dùng neutral message\.

- Duplicate dùng warning semantic\.

- Customer bị khóa/không được phép chọn dùng blocked semantic\.

- Customer card trong SG\-02 là feedback chính sau khi chọn thành công\.

- Sau khi tạo nhanh, có thể hiển thị feedback nhẹ `Đã tạo khách hàng` tại SG\-02\.

- Khi reprice do thay khách hàng, SG\-02 nêu rõ tổng tiền hoặc dòng hàng đã thay đổi\.

    

**Accessibility**

- Search input, `Khách lẻ`, customer cards và quick\-create CTA có accessible label\.

- Trạng thái selected/warning/blocked không chỉ biểu đạt bằng màu\.

- Số điện thoại được screen reader đọc theo nhóm số phù hợp\.

- Field error được liên kết với input tương ứng\.

- D\-06 trap focus phù hợp và trả focus về form khi đóng\.

- Touch target đáp ứng kích thước tối thiểu của Design System\.

    

**Responsive behavior**

- Mobile: một cột; search có thể sticky; D\-05 là full\-screen form hoặc bottom sheet cao\.

- Tablet: có thể dùng danh sách rộng, master\-detail hoặc side sheet cho quick\-create\.

- Web: có thể dùng table/list và modal/side panel cho quick\-create\.

- Search, validation, duplicate rules và return contract không đổi theo viewport\.

- Keyboard không được che field đang focus hoặc CTA quan trọng\.

    

#### Low\-fi wireframes

**D\-01 — Default**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn khách hàng           │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ 👤 Khách lẻ           ✓  │ │
│ └──────────────────────────┘ │
│ 🔎 Tìm tên, SĐT hoặc mã KH   │
├──────────────────────────────┤
│ Khách hàng gần đây           │
│ ┌──────────────────────────┐ │
│ │ Nguyễn Văn An            │ │
│ │ 0912 345 678 · KH-0124   │ │
│ │ Cầu Giấy, Hà Nội         │ │
│ └──────────────────────────┘ │
│                              │
│   [+ Tạo nhanh khách hàng]   │
└──────────────────────────────┘
```

**D\-02 — Search results**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn khách hàng           │
├──────────────────────────────┤
│ 🔎 0912345678             ×  │
├──────────────────────────────┤
│ 1 khách hàng                 │
│ ┌──────────────────────────┐ │
│ │ Nguyễn Văn An            │ │
│ │ 0912 345 678 · KH-0124   │ │
│ │ Cầu Giấy, Hà Nội         │ │
│ └──────────────────────────┘ │
│   [+ Tạo nhanh khách hàng]   │
└──────────────────────────────┘
```

**D\-03 — Empty customer list**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn khách hàng           │
├──────────────────────────────┤
│ 👤 Khách lẻ                  │
│                              │
│    Chưa có khách hàng        │
│ Có thể tạo khách hàng mới    │
│ ngay trong đơn hàng.         │
│                              │
│   [+ Tạo nhanh khách hàng]   │
└──────────────────────────────┘
```

**D\-04 — No result**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn khách hàng           │
├──────────────────────────────┤
│ 🔎 0988 123 456           ×  │
├──────────────────────────────┤
│ Không tìm thấy khách hàng    │
│ phù hợp.                     │
│                              │
│       [Xóa tìm kiếm]         │
│   [+ Tạo nhanh khách hàng]   │
└──────────────────────────────┘
```

**D\-05 — Tạo nhanh khách hàng**

```Plain Text
┌──────────────────────────────┐
│ ‹  Tạo nhanh khách hàng      │
├──────────────────────────────┤
│ Tên khách hàng *             │
│ [Nguyễn Văn Bình           ] │
│ Số điện thoại                │
│ [0988 123 456              ] │
│ Loại khách hàng              │
│ [● Cá nhân] [○ Tổ chức]      │
│ Địa chỉ                      │
│ [Thanh Xuân, Hà Nội        ] │
├──────────────────────────────┤
│   [Tạo & chọn khách hàng]    │
└──────────────────────────────┘
```

**D\-06 — Duplicate warning**

```Plain Text
┌──────────────────────────────┐
│ Có thể khách hàng đã tồn tại │
├──────────────────────────────┤
│ SĐT 0988 123 456 trùng với:  │
│ Nguyễn Văn Bình              │
│ KH-0208 · Thanh Xuân         │
│                              │
│ [Chọn khách hàng này]        │
│ [Vẫn tạo mới]                │
│ [Quay lại kiểm tra]          │
└──────────────────────────────┘
```

**D\-07 — Validation state**

```Plain Text
┌──────────────────────────────┐
│ ‹  Tạo nhanh khách hàng      │
├──────────────────────────────┤
│ Tên khách hàng *             │
│ [                          ] │
│ ⚠ Vui lòng nhập tên          │
│ Số điện thoại                │
│ [098-ABC                   ] │
│ ⚠ Số điện thoại không hợp lệ │
├──────────────────────────────┤
│ [Tạo & chọn khách hàng]      │
└──────────────────────────────┘
```

**D\-08 — Blocked**

```Plain Text
┌──────────────────────────────┐
│ Không thể chọn khách hàng    │
├──────────────────────────────┤
│ Nguyễn Văn An · KH-0124      │
│                              │
│ Khách hàng đã bị khóa hoặc   │
│ không còn thuộc phạm vi      │
│ truy cập của anh.            │
│                              │
│    [Chọn khách hàng khác]    │
└──────────────────────────────┘
```

**D\-09 — Loading**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn khách hàng           │
├──────────────────────────────┤
│ 🔎 Tìm tên, SĐT hoặc mã KH   │
├──────────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒             │
│                              │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒             │
└──────────────────────────────┘
```

**D\-10 — Error**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chọn khách hàng           │
├──────────────────────────────┤
│ 🔎 Nguyễn Văn             ×  │
├──────────────────────────────┤
│ Không thể tải khách hàng     │
│ Tìm kiếm vẫn được giữ lại.   │
│                              │
│          [Thử lại]           │
│          [Quay lại]          │
└──────────────────────────────┘
```

#### Visuals

TBD\.

#### Traceability

TBD\.

### 5\.5\.6 SG\-05 — Thanh toán \& hoàn tất đơn

#### Overview

- Purpose: Cho phép người dùng kiểm tra số tiền phải thu, ghi nhận một hoặc nhiều khoản thanh toán và hoàn tất draft thành official order\.

- Related epic: EP\-02 — Thanh toán \& hoàn tất đơn hàng\.

- Related business flow: BF\-04 — Checkout \& hoàn tất

- Business flow group: Core selling\.

- Primary users: Thu ngân, nhân viên bán hàng, chủ đơn vị trực tiếp bán hàng\.

- Primary task: Thu đủ hoặc ghi nhận đúng nghĩa vụ thanh toán để hoàn tất đơn\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Presentation model: Embedded flow của SG\-02; mở dưới dạng bottom sheet/full\-screen overlay trên mobile và modal/side panel trên màn hình lớn, không có entry point độc lập trong navigation\.

- Design intent: Giữ tổng phải thu, số đã nhận, còn thiếu và tiền thừa luôn rõ ràng; ngăn người dùng tạo đơn chính thức hoặc giao dịch thanh toán trùng khi retry\.

    

#### Entry \& exit

- Entry points:

    - CTA `Thanh toán` từ SG\-02 sau khi draft vượt qua revalidation\.

    - Quay lại từ bước xác nhận trong chính SG\-05 để sửa phương thức hoặc số tiền\.

    - Retry sau lỗi thanh toán hoặc lỗi hoàn tất đơn, sử dụng cùng operation context\.

- Exit points:

    - Hoàn tất thành công → SG\-06 — Kết quả bán hàng\.

    - Đóng/quay lại trước khi commit → SG\-02, giữ nguyên draft và không tạo payment transaction\.

    - Draft không còn hợp lệ → đóng SG\-05 và trả về SG\-02 cùng warning/blocked details\.

    - Payment đã ghi nhận nhưng chưa hoàn tất được order → ở recovery state trong SG\-05; không cho tạo payment mới không kiểm soát\.

        

#### Screen/state inventory

|State|Type|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|Sheet — Payment overview|Hiển thị tổng phải thu và các phương thức thanh toán|Chọn phương thức|Entry state của SG\-05|
|D\-02|Sheet — Cash payment|Nhập số tiền khách đưa và tính tiền thừa|Xác nhận tiền mặt|Không cho số tiền âm|
|D\-03|Sheet — Bank transfer|Ghi nhận/chờ xác nhận chuyển khoản|Xác nhận chuyển khoản|Không coi ảnh chụp là bằng chứng authoritative|
|D\-04|Sheet — Credit/debt|Ghi nhận số tiền bán chịu/công nợ|Xác nhận công nợ|Chỉ hiện khi customer và permission hợp lệ|
|D\-05|Sheet — Split payment|Phân bổ số phải thu qua nhiều phương thức|Tiếp tục|Tổng phân bổ phải khớp nghĩa vụ thanh toán|
|D\-06|Confirmation|Xác nhận tổng cuối cùng và cách thanh toán|Hoàn tất đơn|Điểm commit chính|
|D\-07|Processing|Xử lý payment và tạo official order|—|Khóa thao tác lặp và không cho đóng tùy tiện|
|D\-08|Validation/warning|Hiển thị chênh lệch, thiếu tiền hoặc dữ liệu cần xác nhận|Sửa thanh toán|Không tạo order|
|D\-09|Blocked state|Chặn hoàn tất do draft, payment hoặc credit không hợp lệ|Quay lại sửa đơn|Nêu rõ nguyên nhân và bước xử lý|
|D\-10|Recovery/error state|Khôi phục sau lỗi hoặc kết quả commit chưa xác định|Kiểm tra trạng thái|Không retry mù|



#### UI Contract

**User intent**

- Biết chính xác tổng tiền khách cần thanh toán\.

- Chọn phương thức thanh toán phù hợp\.

- Nhập số tiền khách đưa và biết tiền thừa\.

- Kết hợp nhiều phương thức khi cần\.

- Ghi nhận bán chịu khi khách hàng đủ điều kiện\.

- Hoàn tất đơn đúng một lần và nhận kết quả rõ ràng\.

    

**Information hierarchy**

1. Tổng phải thu\.

2. Số đã phân bổ/đã nhận, còn thiếu và tiền thừa\.

3. Phương thức thanh toán và số tiền tương ứng\.

4. Customer/credit context nếu bán chịu\.

5. CTA hoàn tất và warning/blocked reason\.

    

**Layout anatomy**

- Header:

    - Title `Thanh toán`\.

    - Close/back action trước khi commit\.

- Amount summary:

    - Tổng phải thu\.

    - Đã phân bổ hoặc đã nhận\.

    - Còn thiếu hoặc tiền thừa\.

- Payment\-method area:

    - Tiền mặt\.

    - Chuyển khoản\.

    - Công nợ/bán chịu khi đủ điều kiện\.

    - Các phương thức khác chỉ khi có authoritative payment contract\.

- Payment\-detail area:

    - Input và thông tin riêng của phương thức đang chọn\.

- Confirmation area:

    - Tóm tắt các khoản thanh toán\.

    - Customer context\.

    - Total và downstream effects quan trọng\.

- Sticky action area:

    - CTA thay đổi theo state: `Tiếp tục`, `Xác nhận`, `Hoàn tất đơn`, `Kiểm tra trạng thái`\.

        

**Displayed data**

- Draft reference\.

- Customer: tên khách hàng hoặc `Khách lẻ`\.

- Tổng tiền hàng và các adjustment ảnh hưởng đến số phải thu nếu cần giải thích\.

- Tổng phải thu authoritative tại thời điểm checkout\.

- Danh sách payment allocations\.

- Số đã phân bổ/đã nhận\.

- Số còn thiếu\.

- Tiền khách đưa và tiền thừa với tiền mặt\.

- Tài khoản nhận/chỉ dẫn chuyển khoản nếu được cấu hình\.

- Credit eligibility, hạn mức khả dụng hoặc blocked reason nếu Theme 3 cung cấp\.

- Trạng thái xử lý payment/order\.

    

**User inputs**

- Phương thức thanh toán\.

- Số tiền theo từng phương thức\.

- Số tiền khách đưa đối với tiền mặt\.

- Reference/note chuyển khoản nếu policy yêu cầu\.

- Số tiền bán chịu\.

- Xác nhận hoàn tất đơn\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG05\-E01|Header|`Thanh toán`|Xác định embedded task|D\-01 đến D\-10|
|SG05\-E02|Close/back action|`Đóng` / `Quay lại`|Trở về SG\-02 hoặc state trước|Không khả dụng trong critical commit window|
|SG05\-E03|Amount due|`Cần thanh toán`|Hiển thị authoritative amount|Luôn nổi bật|
|SG05\-E04|Customer summary|Tên khách / `Khách lẻ`|Cung cấp credit context|Read\-only tại SG\-05|
|SG05\-E05|Payment\-method list|Danh sách phương thức|Chọn single hoặc split payment|Theo config và permission|
|SG05\-E06|Cash option|`Tiền mặt`|Mở D\-02|Khi phương thức khả dụng|
|SG05\-E07|Transfer option|`Chuyển khoản`|Mở D\-03|Khi tài khoản nhận được cấu hình|
|SG05\-E08|Credit option|`Công nợ`|Mở D\-04|Có Customer và đủ điều kiện|
|SG05\-E09|Split\-payment action|`Kết hợp phương thức`|Mở D\-05|Khi policy cho phép|
|SG05\-E10|Amount input|`Số tiền`|Nhập allocation amount|Currency input, không âm|
|SG05\-E11|Cash\-received input|`Khách đưa`|Tính tiền thừa|D\-02|
|SG05\-E12|Change amount|`Tiền thừa`|Hiển thị max\(khách đưa − tiền mặt cần thu, 0\)|D\-02, read\-only|
|SG05\-E13|Transfer account|Tài khoản nhận|Hỗ trợ khách chuyển tiền|D\-03, read\-only|
|SG05\-E14|Transfer reference|`Mã/Nội dung giao dịch`|Ghi nhận reference|Optional/required theo policy|
|SG05\-E15|Credit status|Hạn mức/công nợ|Giải thích eligibility|D\-04|
|SG05\-E16|Allocation list|Phương thức · số tiền|Hiển thị/cập nhật split payment|D\-05/D\-06|
|SG05\-E17|Remaining amount|`Còn thiếu`|Phản ánh phần chưa phân bổ|Cập nhật theo allocation|
|SG05\-E18|Continue button|`Tiếp tục`|Validate state hiện tại|D\-02 đến D\-05|
|SG05\-E19|Complete button|`Hoàn tất đơn`|Khởi tạo commit có idempotency|D\-06|
|SG05\-E20|Processing indicator|`Đang hoàn tất đơn…`|Phản ánh operation|D\-07|
|SG05\-E21|Fix\-payment action|`Sửa thanh toán`|Quay lại state nhập liệu|D\-08|
|SG05\-E22|Fix\-order action|`Quay lại sửa đơn`|Đóng SG\-05 và focus vấn đề tại SG\-02|D\-09|
|SG05\-E23|Check\-status action|`Kiểm tra trạng thái`|Query authoritative operation status|D\-10|



**Entry and revalidation behavior**

- CTA `Thanh toán` tại SG\-02 chỉ mở SG\-05 sau khi client preconditions được đáp ứng\.

- Khi mở SG\-05, hệ thống phải revalidate authoritative draft gồm dòng hàng, ProductUnit, pricing, promotion, customer, tax context và availability rule liên quan\.

- Tổng phải thu trong SG\-05 lấy từ checkout/revalidation result, không tự sao chép tổng cached ở SG\-02\.

- Nếu tổng hoặc dòng hàng thay đổi:

    - Cập nhật SG\-02 với authoritative result\.

    - Hiển thị warning giải thích thay đổi\.

    - Yêu cầu người dùng kiểm tra trước khi tiếp tục\.

- Nếu draft bị blocked, không hiển thị payment entry như thể có thể hoàn tất\.

    

**Payment\-method eligibility**

- Phương thức hiển thị phụ thuộc tenant/store configuration, permission, customer context và trạng thái hệ thống tích hợp\.

- Tiền mặt có thể dùng cho `Khách lẻ` hoặc Customer\.

- Chuyển khoản chỉ khả dụng khi có receiving account/config hợp lệ\.

- Công nợ chỉ khả dụng khi:

    - Draft gắn Customer hợp lệ\.

    - Customer được phép mua chịu\.

    - Người dùng có quyền ghi nhận công nợ\.

    - Hạn mức/credit rule cho phép hoặc có override được kiểm soát\.

- Phương thức không đủ điều kiện bị ẩn hoặc disabled kèm lý do\.

    

**Cash\-payment behavior**

- Mặc định số tiền mặt cần thu bằng phần còn thiếu\.

- `Khách đưa` phải lớn hơn hoặc bằng số tiền phân bổ cho tiền mặt nếu đơn phải thu đủ ngay\.

- Tiền thừa = tiền khách đưa − số tiền mặt cần thu; không ghi tiền thừa như payment allocation\.

- Quick amount chips có thể gồm đúng số cần thu và các mệnh giá làm tròn hữu ích\.

- Không cho nhập số âm, NaN hoặc vượt giới hạn currency contract\.

- Việc hiển thị tiền thừa không đồng nghĩa payment đã được ghi nhận\.

    

**Bank\-transfer behavior**

- Hiển thị đúng tài khoản nhận theo tenant/store context\.

- Có thể hỗ trợ QR thanh toán khi integration cung cấp dữ liệu authoritative\.

- Trạng thái chuyển khoản gồm:

    - Người dùng xác nhận thủ công theo permission/policy\.

    - Hệ thống xác nhận qua integration\.

    - Đang chờ xác nhận nếu business rule hỗ trợ pending payment\.

- Ảnh chụp hoặc nội dung người dùng nhập không tự chứng minh tiền đã về\.

- Reference được lưu cùng payment record khi có\.

- Không cho tạo hai payment transaction từ một lần nhấn hoặc một lần retry\.

    

**Credit/debt behavior**

- Không hiển thị `Công nợ` cho `Khách lẻ`\.

- SG\-05 lấy eligibility/hạn mức từ authoritative customer/receivable contract; không tự tính\.

- Số tiền bán chịu được coi là settlement allocation tạo receivable obligation khi order hoàn tất, không phải tiền đã thu\.

- Nếu vượt hạn mức:

    - Không có override → D\-09\.

    - Có controlled override → yêu cầu permission, reason và audit trail\.

- Thay đổi customer phải quay lại SG\-02, không thực hiện trong SG\-05\.

    

**Split\-payment behavior**

- Một đơn có thể có nhiều allocation nếu tenant policy cho phép\.

- Mỗi allocation gồm phương thức, số tiền và reference cần thiết\.

- Tổng allocation được dùng để settlement phải bằng tổng phải thu, trừ khi business rule cho phép phần còn lại thành công nợ\.

- Không cho allocation âm hoặc bằng 0\.

- Cùng một phương thức có thể được gộp thành một allocation, trừ khi cần tách theo transaction/reference\.

- Xóa/sửa allocation phải cập nhật ngay `Còn thiếu`\.

- Tiền thừa chỉ áp dụng cho phần tiền mặt; không dùng allocation vượt tổng để cân bằng phương thức khác\.

    

**Confirmation behavior**

- D\-06 hiển thị tối thiểu customer, tổng phải thu, từng allocation, tiền khách đưa/tiền thừa nếu có và phần công nợ nếu có\.

- `Hoàn tất đơn` là action commit duy nhất\.

- Trước commit cuối, hệ thống kiểm tra lại draft version và payment allocations\.

- Nếu draft version thay đổi, không overwrite; quay D\-08/D\-09 tùy mức độ\.

- CTA chuyển processing ngay lần nhấn đầu và không nhận nhấn lặp\.

    

**Commit and idempotency behavior**

- Một thao tác hoàn tất dùng một idempotency/operation key xuyên suốt các retry\.

- Operation chịu trách nhiệm phối hợp:

    - Khóa hoặc xác nhận draft version\.

    - Resolve/revalidate total cuối\.

    - Tạo payment transaction/receivable allocation cần thiết\.

    - Tạo official order đúng một lần\.

    - Ghi inventory/accounting/invoice side effects theo contract và boundary tương ứng\.

- UI không tự suy luận thành công chỉ vì request timeout\.

- Refresh, back\-forward hoặc retry không được tạo thêm official order/payment\.

    

**Processing behavior**

- D\-07 hiển thị operation đang xử lý và ngăn action xung đột\.

- Không cho đóng overlay bằng gesture vô tình trong critical commit window\.

- Nếu xử lý lâu, message chuyển từ loading ngắn sang `Đang kiểm tra trạng thái giao dịch`\.

- App restart/reconnect phải có khả năng khôi phục operation bằng operation key hoặc draft reference\.

    

**Failure and recovery behavior**

- Lỗi trước khi payment/order commit: giữ draft và allocations; cho sửa hoặc retry\.

- Kết quả chưa xác định sau timeout/network loss: D\-10 và query status trước khi retry\.

- Payment đã thành công nhưng order chưa xác nhận:

    - Không cho người dùng tạo payment mới\.

    - Hiển thị recovery state\.

    - Hệ thống reconcile/complete operation hoặc chuyển xử lý nghiệp vụ có kiểm soát\.

- Order đã tồn tại khi retry: điều hướng tới SG\-06 bằng authoritative order ID\.

- Payment bị từ chối/thất bại: đánh dấu allocation thất bại và cho chọn lại phương thức nếu policy cho phép\.

    

**Business rules and invariants**

- SG\-05 không có route/module entry độc lập; luôn cần draft context từ SG\-02\.

- Tổng phải thu phải là authoritative checkout total\.

- Tổng settlement allocations phải cân bằng nghĩa vụ thanh toán theo rule của đơn\.

- Không tạo official order khi còn validation hoặc blocked condition\.

- Một successful checkout operation chỉ tạo một official order\.

- Một payment attempt chỉ tạo tối đa một payment transaction cho cùng idempotency key\.

- Tiền thừa không làm tăng giá trị payment/order\.

- Bán chịu tạo receivable obligation, không được ghi nhận như tiền đã thu\.

- Đóng SG\-05 trước commit không tạo payment, receivable hoặc official order\.

- Payment/order status phải lấy từ backend; UI state không phải authoritative ledger\.

    

**Permissions**

- `Checkout sales draft`: mở SG\-05 và hoàn tất đơn\.

- `Accept cash payment`: ghi nhận tiền mặt\.

- `Accept bank transfer`: ghi nhận chuyển khoản\.

- `Create customer receivable`: ghi nhận bán chịu\.

- `Use split payment`: kết hợp phương thức\.

- `Override customer credit limit`: vượt hạn mức có kiểm soát\.

- `Confirm manual transfer`: xác nhận chuyển khoản thủ công nếu policy cho phép\.

- Không có permission tương ứng → phương thức/action bị ẩn hoặc disabled kèm lý do\.

    

**Validation, warning and blocked states**

- D\-08 dùng khi người dùng có thể sửa payment data trong SG\-05: thiếu tiền, allocation không cân bằng, input sai format hoặc reference bắt buộc còn thiếu\.

- D\-09 dùng khi cần sửa draft/customer hoặc không thể tiếp tục: giá/availability invalid, customer credit blocked, permission mất hiệu lực hoặc draft version conflict\.

- Validation đặt gần field và có summary khi nhiều lỗi\.

- Disabled CTA phải có lý do có thể nhận biết, không chỉ thay đổi màu\.

    

**Feedback and messaging**

- `Còn thiếu` dùng warning semantic khi lớn hơn 0\.

- `Tiền thừa` dùng neutral/informational semantic\.

- Payment pending dùng processing semantic, không hiển thị success\.

- Kết quả chưa xác định dùng message `Đang kiểm tra trạng thái`, không dùng `Thanh toán thất bại` khi chưa chắc chắn\.

- Thành công điều hướng SG\-06; không hiển thị success toast thay cho result screen\.

    

**Accessibility**

- Tổng phải thu, còn thiếu và tiền thừa có semantic label rõ ràng\.

- Currency input dùng keyboard phù hợp và accessible formatting\.

- Trạng thái phương thức, warning và blocked không chỉ biểu đạt bằng màu\.

- Bottom sheet/modal trap focus và trả focus về CTA `Thanh toán` của SG\-02 khi đóng\.

- Processing state được screen reader thông báo nhưng không lặp liên tục\.

- Focus order: header → tổng tiền → phương thức → input chi tiết → summary → CTA\.

    

**Responsive behavior**

- Mobile: bottom sheet mở rộng/full\-screen overlay; CTA sticky bottom; nội dung scroll phía trên\.

- Tablet: modal lớn hoặc side panel, amount summary luôn nhìn thấy\.

- Web: modal/side panel; có thể chia payment inputs và summary thành hai cột\.

- Business rules, validation và operation semantics không đổi theo viewport\.

- Keyboard không che amount input, validation hoặc CTA\.

    

#### Low\-fi wireframes

**D\-01 — Payment overview**

```Plain Text
┌──────────────────────────────┐
│ ×  Thanh toán                │
├──────────────────────────────┤
│ CẦN THANH TOÁN               │
│            1.250.000 ₫       │
│ Nguyễn Văn An · KH-0124      │
├──────────────────────────────┤
│ Chọn phương thức             │
│ [💵 Tiền mặt]                │
│ [🏦 Chuyển khoản]            │
│ [📒 Công nợ]                 │
│                              │
│ [Kết hợp phương thức]        │
└──────────────────────────────┘
```

**D\-02 — Cash payment**

```Plain Text

├──────────────────────────────┤
│ Cần thu       1.250.000 ₫    │
│ Khách đưa                    │
│ [1.500.000                ]  │
│      [0] [50%] [100%]        │
│                              │
│ Tiền thừa       250.000 ₫    │
├──────────────────────────────┤
│          [Tiếp tục]          │
└──────────────────────────────┘
```

**D\-03 — Bank transfer**

```Plain Text

├──────────────────────────────┤
│ Số tiền       1.250.000 ₫    │
│        [QR thanh toán]       │
│ VCB · 0123 456 789           │
│ CÔNG TY MẬU HIÊN             │
│ Nội dung: DH-002581          │
│                              │
│ Mã giao dịch (nếu có)        │
│ [                          ] │
├──────────────────────────────┤
│ [Xác nhận chuyển khoản]      │
└──────────────────────────────┘
```

**D\-04 — Credit/debt**

```Plain Text

├──────────────────────────────┤
│ Nguyễn Văn An                │
│ Hạn mức còn lại  5.000.000 ₫ │
│ Công nợ hiện tại 2.100.000 ₫ │
│                              │
│ Ghi nợ                       │
│ [1.250.000                ]  │
│ Sau giao dịch: 3.350.000 ₫   │
├──────────────────────────────┤
│     [Xác nhận công nợ]       │
└──────────────────────────────┘
```

**D\-05 — Split payment**

```Plain Text

├──────────────────────────────┤
│ Cần thanh toán  1.250.000 ₫  │
│                              │
│ Tiền mặt          500.000 ₫  │
│ Chuyển khoản      600.000 ₫  │
│ [+ Thêm phương thức]         │
│                              │
│ Đã phân bổ      1.100.000 ₫  │
│ Còn thiếu         150.000 ₫  │
├──────────────────────────────┤
│       [Tiếp tục]             │
└──────────────────────────────┘
```

**D\-06 — Confirmation**

```Plain Text
┌──────────────────────────────┐
│ ‹  Xác nhận thanh toán       │
├──────────────────────────────┤
│ Nguyễn Văn An                │
│ Tổng phải thu  1.250.000 ₫   │
│                              │
│ Tiền mặt         500.000 ₫   │
│ Chuyển khoản     750.000 ₫   │
│ Tổng thanh toán 1.250.000 ₫  │
│                              │
│ Đơn sẽ được hoàn tất sau     │
│ khi anh/chị xác nhận.             │
├──────────────────────────────┤
│           [Xác nhận]         │
└──────────────────────────────┘
```



#### Visuals

TBD\.

#### Traceability

TBD\.

### 5\.5\.7 SG\-06 — Kết quả bán hàng

#### Overview

- Purpose: Xác nhận kết quả checkout, cung cấp official order reference, tóm tắt thanh toán và cho phép người dùng thực hiện các tác vụ ngay sau bán\.

- Related epic: EP\-02 — Thanh toán \& hoàn tất đơn hàng\.

- Related business flow: BF\-04 — Checkout \& hoàn tất

- Business flow group: Core selling\.

- Primary users: Thu ngân, nhân viên bán hàng, chủ đơn vị trực tiếp bán hàng\.

- Primary task: Xác nhận đơn đã hoàn tất đúng một lần và chọn hành động tiếp theo\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: Người dùng phải nhận biết ngay đơn đã thành công hay chưa, số tiền và phương thức đã ghi nhận, tiền thừa/công nợ phát sinh, đồng thời không nhầm side effect đang chờ với thất bại của đơn\.

- Scope boundary: SG\-06 là result screen của checkout operation; không phải màn chỉnh sửa official order\.

    

#### Entry \& exit

- Entry points:

    - SG\-05 trả checkout result thành công cùng official order ID\.

    - Recovery operation xác nhận official order đã được tạo sau timeout/reconnect\.

    - Deep link nội bộ từ operation result nếu ứng dụng được khôi phục sau restart\.

- Exit points:

    - `Tạo đơn mới` → SG\-02 với một working draft mới\.

    - `Xem chi tiết đơn` → SG\-08 — Chi tiết đơn hàng\.

    - `Về bán hàng` → SG\-01\.

    - `In / Chia sẻ phiếu bán hàng` → action flow trong SG\-06 rồi trở về result screen\.

    - Side effect cần xử lý thêm → mở status/details tương ứng nhưng giữ official order context\.

        

#### Screen/state inventory

|State|Type|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|Result — Success|Xác nhận official order và payment hoàn tất|Tạo đơn mới|Default success state|
|D\-02|Result — Cash|Hiển thị tiền khách đưa và tiền thừa|Xong / Tạo đơn mới|Ưu tiên tiền thừa dễ nhìn|
|D\-03|Result — Transfer|Hiển thị giao dịch chuyển khoản đã ghi nhận|Tạo đơn mới|Có transaction reference khi có|
|D\-04|Result — Credit/debt|Hiển thị khoản công nợ mới phát sinh|Xem công nợ / Tạo đơn mới|Chỉ áp dụng Customer hợp lệ|
|D\-05|Result — Split payment|Tóm tắt nhiều payment allocations|Xem chi tiết|Tổng allocations phải cân bằng|
|D\-06|Action sheet — Receipt|In, tải hoặc chia sẻ chứng từ bán hàng|Chọn hành động|Không sửa dữ liệu order|
|D\-07|Processing/pending|Official order thành công nhưng một side effect đang xử lý|Kiểm tra trạng thái|Không đổi result thành failed|
|D\-08|Warning — Partial side\-effect failure|Order thành công nhưng in/e\-invoice/sync phụ trợ thất bại|Thử lại tác vụ|Không retry checkout|
|D\-09|Restricted action|Chặn action sau bán do quyền hoặc cấu hình|Đóng|Official order vẫn thành công|
|D\-10|Load/recovery error|Không tải được result details dù đã có operation/order reference|Thử lại|Không tạo đơn hoặc payment mới|



#### UI Contract

**User intent**

- Biết chắc đơn đã hoàn tất\.

- Nhận diện official order bằng mã đơn\.

- Kiểm tra tổng tiền và phương thức thanh toán\.

- Biết tiền thừa cần trả hoặc công nợ vừa phát sinh\.

- In/chia sẻ chứng từ khi cần\.

- Bắt đầu đơn tiếp theo nhanh chóng\.

    

**Information hierarchy**

1. Kết quả `Đã hoàn tất đơn`\.

2. Official order reference và tổng tiền\.

3. Kết quả settlement: đã thu, tiền thừa hoặc công nợ\.

4. Warning/pending side effects\.

5. Primary next action và secondary actions\.

    

**Layout anatomy**

- Result header:

    - Success icon và label `Đã hoàn tất đơn`\.

    - Official order code\.

- Amount summary:

    - Tổng đơn\.

    - Tổng đã thu và/hoặc công nợ\.

    - Tiền thừa nếu có\.

- Payment summary:

    - Các phương thức và số tiền\.

- Customer/order context:

    - Customer hoặc `Khách lẻ`\.

    - Thời điểm và cửa hàng/quầy nếu cần\.

- Side\-effect status:

    - Receipt, e\-invoice, inventory/accounting sync theo contract\.

- Action area:

    - Primary `Tạo đơn mới`\.

    - `Xem chi tiết đơn`\.

    - `In/Chia sẻ`\.

    - `Về bán hàng`\.

        

**Displayed data**

- Official order code và ID nội bộ dùng cho navigation\.

- Checkout completion time\.

- Customer hoặc `Khách lẻ`\.

- Tổng giá trị order\.

- Payment allocations đã ghi nhận\.

- Tổng đã thu\.

- Tiền khách đưa và tiền thừa nếu thanh toán tiền mặt\.

- Receivable amount nếu bán chịu\.

- Transaction/reference code khi được phép hiển thị\.

- Receipt/e\-invoice/sync status nếu có\.

- Người bán, store/counter context khi hữu ích\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG06\-E01|Result icon|Success semantic|Xác nhận checkout success|D\-01 đến D\-08|
|SG06\-E02|Result title|`Đã hoàn tất đơn`|Thông báo official order tồn tại|Không dùng cho unknown result|
|SG06\-E03|Order reference|`Đơn #...`|Mở/copy reference khi phù hợp|Luôn hiển thị|
|SG06\-E04|Total amount|`Tổng đơn`|Hiển thị official order total|Authoritative, read\-only|
|SG06\-E05|Customer summary|Tên khách / `Khách lẻ`|Cung cấp context|Read\-only|
|SG06\-E06|Payment summary|Phương thức · số tiền|Tóm tắt settlement|Single hoặc split|
|SG06\-E07|Cash received|`Khách đưa`|Hiển thị số nhận|D\-02|
|SG06\-E08|Change due|`Tiền thừa`|Nhấn mạnh số tiền cần trả khách|D\-02|
|SG06\-E09|Receivable amount|`Ghi công nợ`|Hiển thị obligation mới|D\-04|
|SG06\-E10|Transaction reference|Mã giao dịch|Hỗ trợ đối soát|Khi có và có quyền|
|SG06\-E11|Side\-effect status|Phiếu bán hàng · e\-invoice · sync status|Hiển thị trạng thái theo domain owner|D\-07/D\-08|
|SG06\-E12|New\-order button|`Tạo đơn mới`|Tạo working draft và mở SG\-02|Primary action|
|SG06\-E13|Order\-detail action|`Xem chi tiết đơn`|Mở SG\-08|Có permission xem order|
|SG06\-E14|Receipt action|`In / Chia sẻ phiếu bán hàng`|Mở D\-06|Theo device, configuration và permission|
|SG06\-E15|Return action|`Về bán hàng`|Mở SG\-01|Secondary action|
|SG06\-E16|Retry\-side\-effect action|`Thử lại tác vụ`|Chỉ retry tác vụ Theme 5 được quyền sở hữu|D\-08; không retry checkout hoặc tự retry e\-invoice|
|SG06\-E17<br>|Check\-status action|`Kiểm tra trạng thái`|Refresh side\-effect/result details|D\-07/D\-10|
|SG06\-E18|Close action|`Đóng`|Đóng restricted/action sheet|D\-06/D\-09|



**Success\-result behavior**

- SG\-06 chỉ dùng success presentation khi backend trả official order ID hoặc recovery xác nhận order tồn tại\.

- Không suy luận success từ client progress, payment input hoặc request đã gửi\.

- Mã đơn, total và settlement summary phải lấy từ authoritative checkout result/order projection\.

- Nếu result payload thiếu chi tiết phụ, vẫn xác nhận success khi official order đã tồn tại và tải bổ sung phần còn lại\.

- Refresh/reopen SG\-06 không tạo checkout operation mới\.

    

**Cash\-result behavior**

- D\-02 đặt `Tiền thừa` ở vùng nổi bật, dễ đọc trước khi người dùng rời màn hình\.

- Tiền thừa lấy từ checkout result, không tính lại bằng giá trị input stale\.

- `Tạo đơn mới` không tự động đánh dấu đã trả tiền thừa; trách nhiệm trao tiền là thao tác vật lý\.

- Không ghi tiền thừa thành payment hoặc adjustment của order\.

    

**Transfer\-result behavior**

- Chỉ hiển thị chuyển khoản `Đã ghi nhận` khi payment transaction đã được authoritative operation xác nhận theo policy\.

- Nếu transfer còn pending nhưng business rule vẫn tạo order, hiển thị rõ `Đang chờ xác nhận`, không dùng success semantic cho payment\.

- Transaction reference có thể copy nhưng phải tuân thủ permission/privacy\.

- Không cho người dùng xác nhận lại cùng transaction từ SG\-06\.

    

**Credit\-result behavior**

- D\-04 hiển thị số công nợ mới phát sinh và Customer chịu công nợ\.

- Không gọi receivable amount là `Đã thanh toán`\.

- Có thể hiển thị tổng công nợ sau giao dịch nếu Theme 3 cung cấp authoritative balance\.

- `Xem công nợ` điều hướng tới surface thuộc Theme 3; SG\-06 không chỉnh credit entry\.

    

**Split\-payment behavior**

- D\-05 hiển thị từng allocation và tổng settlement\.

- Cash change chỉ gắn với allocation tiền mặt\.

- Receivable allocation tách biệt với số tiền đã thu\.

- Nếu danh sách dài, result screen hiển thị tóm tắt và `Xem chi tiết`\.

    

    **Receipt, print and share behavior**

    - D\-06 có thể gồm `In phiếu bán hàng`, `Chia sẻ phiếu bán hàng`, `Tải PDF` hoặc `Gửi phiếu cho khách` theo capability\.

    - Phiếu bán hàng được tạo từ official order snapshot, không từ draft\.

    - Phiếu bán hàng nội bộ không đồng nghĩa với hóa đơn điện tử\.

    - Printer unavailable hoặc print thất bại không thay đổi order status\.

    - Retry print tạo print job mới nhưng không tạo order hoặc payment mới\.

    - Share action phải sử dụng artifact được tạo từ authoritative order data\.

    - SG\-06 chỉ hiển thị trạng thái hóa đơn điện tử do Theme 8 cung cấp\.

    - Nếu hóa đơn điện tử cần xử lý, action mặc định là `Xem trạng thái hóa đơn điện tử` hoặc điều hướng sang flow của Theme 8\.

    - SG\-06 không trực tiếp retry phát hành hóa đơn điện tử nếu chưa có cross\-theme command contract giao rõ quyền này cho Theme 5\.

    

**New\-order behavior**

- `Tạo đơn mới` tạo working draft mới với idempotency chống double tap rồi mở SG\-02\.

- Không reuse draft đã hoàn tất\.

- Không copy customer, lines hoặc payment mặc định trừ khi có feature riêng được đặc tả\.

- Nếu tạo draft mới thất bại, giữ SG\-06 để người dùng có thể retry hoặc về SG\-01\.

- Official order vừa hoàn tất không bị ảnh hưởng\.

    

**Order\-detail behavior**

- `Xem chi tiết đơn` mở SG\-08 bằng official order ID\.

- SG\-08 là read/command surface cho order sau bán; SG\-06 không nhúng toàn bộ order detail\.

- Nếu mất permission xem order, hiển thị D\-09 nhưng vẫn giữ result summary tối thiểu được phép\.

    

**Pending and side\-effect behavior**

- Official order success và downstream side\-effect status là hai lớp kết quả riêng\.

- Side effects có thể gồm inventory posting, accounting posting, receipt generation, e\-invoice processing hoặc external sync\.

- D\-07 dùng khi official order đã tồn tại nhưng một tác vụ phụ đang processing hoặc pending\.

- UI phải tiếp tục ghi rõ `Đơn đã hoàn tất`; không thay success header bằng loading toàn màn hình\.

- E\-invoice status trong SG\-06 là read\-only projection từ Theme 8, trừ khi có command contract khác được đặc tả\.

- Status polling hoặc realtime update không được chạy vô hạn; phải có action kiểm tra thủ công hoặc mở chi tiết đơn\.

    

**Partial side\-effect failure behavior**

- D\-08 không dùng wording `Hoàn tất đơn thất bại` nếu official order đã tồn tại\.

- Mỗi warning phải nêu tác vụ nào thất bại, ảnh hưởng gì và domain nào chịu trách nhiệm xử lý\.

- Retry chỉ áp dụng cho tác vụ Theme 5 được quyền sở hữu, ví dụ tạo lại phiếu bán hàng hoặc gửi lại print job\.

- Với e\-invoice, action mặc định là `Xem trạng thái hóa đơn điện tử`, không phải `Thử phát hành lại`\.

- Không retry checkout, payment hoặc tạo official order từ SG\-06\.

- Tác vụ cần can thiệp nghiệp vụ phải hiển thị order reference và correlation reference khi được phép\.



**Recovery behavior**

- Khi app trở lại từ SG\-05/D\-10 và operation xác nhận success, mở SG\-06 bằng official order ID\.

- D\-10 chỉ dùng khi không tải được details; nếu chưa xác định order có tồn tại hay không, tiếp tục recovery contract của SG\-05 thay vì hiển thị success giả\.

- Retry load result là read/query operation\.

- Nếu order đã bị thay đổi sau bán, SG\-06 hiển thị snapshot/result phù hợp và dẫn sang SG\-08 để xem trạng thái hiện tại\.

    

**Business rules and invariants**

- SG\-06 không được mở như success result nếu chưa có authoritative official order\.

- Một checkout operation ánh xạ tới tối đa một official order\.

- SG\-06 không tạo thêm payment transaction khi load, refresh, print, share hoặc retry side effect\.

- Result amounts phải khớp official order/payment records\.

- Công nợ không được trình bày như tiền đã thu\.

- Side\-effect pending/failure không tự động đảo trạng thái official order\.

- Không cho chỉnh line, price, customer hoặc payment allocation tại SG\-06\.

- Mọi thay đổi sau bán phải đi qua SG/command flow tương ứng\.

    

**Permissions**

- `View completed sales result`: xem result tối thiểu của operation vừa thực hiện\.

- `View sales order`: mở SG\-08\.

- `Print sales receipt`: in chứng từ\.

- `Share sales receipt`: chia sẻ/tải artifact\.

- `View payment details`: xem transaction/reference chi tiết\.

- `View customer receivable`: mở thông tin công nợ\.

- `Retry external side effect`: retry tác vụ được phép\.

- Action không có quyền bị ẩn hoặc disabled kèm lý do; không che mất xác nhận order đã thành công\.

    

**Feedback and messaging**

- Success header dùng wording `Đã hoàn tất đơn`, không dùng `Thanh toán thành công` nếu order có phần công nợ hoặc payment pending\.

- Tiền thừa dùng informational/high\-emphasis semantic\.

- Công nợ dùng neutral hoặc warning tùy credit status, không dùng payment\-success label\.

- Pending side effect dùng processing semantic\.

- Partial side\-effect failure dùng warning semantic và nêu order vẫn hoàn tất\.

- Load error dùng `Không tải được chi tiết kết quả`, không khuyến khích thanh toán lại\.

    

**Accessibility**

- Success status, order code, total và payment summary có semantic labels\.

- Tiền thừa được announce sau success nhưng không lặp liên tục\.

- Status không chỉ biểu đạt bằng icon/màu\.

- Actions có label cụ thể: `In phiếu bán hàng`, `Chia sẻ phiếu bán hàng`, không chỉ `Thêm`\.

- Focus ban đầu vào result title; tiếp theo order reference, amount summary, warnings và actions\.

- D\-06 trap focus và trả focus về receipt action khi đóng\.

    

**Responsive behavior**

- Mobile: một cột; primary action sticky hoặc nằm trong vùng dễ chạm; secondary actions dạng buttons/action sheet\.

- Tablet: result card giữa màn hình; payment và actions có thể chia hai vùng\.

- Web: result panel/card; chi tiết thanh toán và side\-effect status có thể hiển thị cạnh nhau\.

- Result semantics và action eligibility không đổi theo viewport\.

    

#### Low\-fi wireframes

**D\-01 — Success**

```Plain Text
┌──────────────────────────────┐
│              ✓               │
│      Đã hoàn tất đơn         │
│         #DH-002581           │
├──────────────────────────────┤
│ Tổng đơn       1.250.000 ₫   │
│ Đã thanh toán  1.250.000 ₫   │
│ Nguyễn Văn An                │
├──────────────────────────────┤
│       [Tạo đơn mới]          │
│ [Xem chi tiết] [In/Chia sẻ]  │
│         Về bán hàng          │
└──────────────────────────────┘
```

**D\-02 — Cash result**

```Plain Text
┌──────────────────────────────┐
│ ✓  Đã hoàn tất đơn           │
│ #DH-002581                   │
├──────────────────────────────┤
│ Tổng đơn       1.250.000 ₫   │
│ Khách đưa      1.500.000 ₫   │
│                              │
│ TIỀN THỪA        250.000 ₫   │
├──────────────────────────────┤
│       [Tạo đơn mới]          │
│       [In phiếu bán hàng]    │
└──────────────────────────────┘
```

**D\-03 — Transfer result**

```Plain Text
┌──────────────────────────────┐
│ ✓  Đã hoàn tất đơn           │
│ #DH-002582                   │
├──────────────────────────────┤
│ Chuyển khoản   1.250.000 ₫   │
│ Trạng thái     Đã ghi nhận   │
│ Mã giao dịch   VCB839201     │
├──────────────────────────────┤
│       [Tạo đơn mới]          │
│ [Xem chi tiết] [In/Chia sẻ]  │
└──────────────────────────────┘
```

**D\-04 — Credit/debt result**

```Plain Text
┌──────────────────────────────┐
│ ✓  Đã hoàn tất đơn           │
│ #DH-002583                   │
├──────────────────────────────┤
│ Nguyễn Văn An                │
│ Tổng đơn       1.250.000 ₫   │
│ Ghi công nợ    1.250.000 ₫   │
│ Tổng nợ mới    3.350.000 ₫   │
├──────────────────────────────┤
│       [Tạo đơn mới]          │
│        [Xem công nợ]         │
└──────────────────────────────┘
```

**D\-05 — Split payment result**

```Plain Text
┌──────────────────────────────┐
│ ✓  Đã hoàn tất đơn           │
│ #DH-002584                   │
├──────────────────────────────┤
│ Tổng đơn       1.250.000 ₫   │
│ Tiền mặt         500.000 ₫   │
│ Chuyển khoản     600.000 ₫   │
│ Công nợ          150.000 ₫   │
├──────────────────────────────┤
│       [Tạo đơn mới]          │
│        [Xem chi tiết]        │
└──────────────────────────────┘
```

**D\-06 — Receipt actions**

```Plain Text

├──────────────────────────────┤
│ Phiếu bán hàng           ×   │
│ [🖨 In phiếu bán hàng]       │
│ [↗ Chia sẻ phiếu]            │
│ [↓ Tải PDF]                  │
│ [✉ Gửi phiếu cho khách]      │
└──────────────────────────────┘
```

**D\-07 — Side effect pending**

```Plain Text
┌──────────────────────────────┐
│ ✓  Đã hoàn tất đơn           │
│ #DH-002585                   │
├──────────────────────────────┤
│ Tổng đơn       1.250.000 ₫   │
│ ✓ Thanh toán đã ghi nhận     │
│ ◌ Hóa đơn điện tử đang xử lý │
│ ✓ Đồng bộ kho đã tiếp nhận   │
├──────────────────────────────┤
│    [Kiểm tra trạng thái]     │
│       [Tạo đơn mới]          │
└──────────────────────────────┘
```



**D\-08 — Partial side\-effect failure**

```Markdown
┌──────────────────────────────┐
│ ✓  Đơn đã hoàn tất           │
│ #DH-002586                   │
├──────────────────────────────┤
│ ⚠ Hóa đơn điện tử chưa được  │
│ phát hành. Đơn hàng và thanh │
│ toán không bị ảnh hưởng.     │
│                              │
│ [Xem trạng thái hóa đơn]     │
│ [Xem chi tiết đơn]           │
└──────────────────────────────┘
```



**D\-09 — Restricted action**

```Plain Text
┌──────────────────────────────┐
│ Không thể thực hiện          │
├──────────────────────────────┤
│ Đơn #DH-002586 đã hoàn tất.  │
│                              │
│ Anh/chị không có quyền ...   │
│ ... của đơn hàng này.        │
│                              │
│            [Đóng]            │
└──────────────────────────────┘
```

**D\-10 — Load/recovery error**

```Plain Text

├──────────────────────────────┤
│ Đơn #DH-002581 đã được tạo.  │
│ Hiện chưa tải được toàn bộ   │
│ thông tin kết quả.           │
│                              │
│          [Thử lại]           │
│       [Về bán hàng]          │
└──────────────────────────────┘
```

#### Visuals

TBD\.

#### Traceability

TBD\.

### 5\.5\.8 SG\-07 — Danh sách đơn hàng

#### Overview

- Purpose: Cung cấp điểm tra cứu tập trung để người dùng tìm, lọc và mở các official order trong phạm vi được phép\.

- Related epic: EP\-03 — Tra cứu \& kiểm soát đơn hàng\.

- Related business flow: BF\-05 — Tra cứu \& theo dõi\.

- Business flow group: Inquiry \& control\.

- Primary users: Nhân viên bán hàng, thu ngân, quản lý cửa hàng, kế toán, chủ đơn vị\.

- Primary task: Tìm đúng đơn hàng và mở chi tiết để kiểm tra hoặc thực hiện nghiệp vụ tiếp theo\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: Tối ưu khả năng scan theo mã đơn, thời gian, khách hàng, tổng tiền và trạng thái; mọi filter phải minh bạch và không làm người dùng hiểu nhầm giữa không có dữ liệu với không có quyền\.

- Scope boundary: SG\-07 chỉ tra cứu và điều hướng; không chỉnh sửa, hủy hoặc đổi/trả trực tiếp trên list item\.

    

#### Entry \& exit

- Entry points:

    - Navigation `Đơn hàng` trong Tenant App\.

    - `Về bán hàng` hoặc liên kết tra cứu từ SG\-06\.

    - Deep link nội bộ có sẵn query/filter context\.

    - Liên kết từ khách hàng, payment, công nợ hoặc báo cáo khi contract liên theme hỗ trợ\.

- Exit points:

    - Chọn order → SG\-08 — Chi tiết đơn hàng\.

    - CTA bán hàng → SG\-01 hoặc SG\-02 theo navigation contract\.

    - Quay lại module trước → giữ hoặc khôi phục filter theo navigation policy\.

    - Mất scope/permission → blocked state hoặc điểm vào an toàn\.

        

#### Screen/state inventory

|State|Type|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|Screen — Default|Hiển thị đơn gần nhất trong scope mặc định|Mở đơn hàng|Sắp xếp mới nhất trước|
|D\-02|Screen — Search results|Hiển thị kết quả theo mã đơn, khách hàng hoặc reference|Mở đơn hàng|Exact order code được ưu tiên|
|D\-03|Screen — Filtered results|Hiển thị kết quả theo thời gian, trạng thái, cửa hàng và người bán|Mở đơn hàng|Active filters luôn nhìn thấy|
|D\-04|Empty state|Xử lý khi scope chưa có official order|Tạo đơn bán hàng|Không coi draft là official order|
|D\-05|No\-result state|Xử lý search/filter không có kết quả|Xóa tìm kiếm/bộ lọc|Giữ quyền và scope hiện tại|
|D\-06|Filter sheet|Chọn điều kiện lọc|Áp dụng|Có reset và result count khi khả dụng|
|D\-07|Loading/pagination state|Tải trang đầu hoặc tải thêm|—|Không làm nhảy vị trí list|
|D\-08|Refresh/stale state|Làm mới danh sách khi dữ liệu có thể đã thay đổi|Làm mới|Giữ query/filter|
|D\-09|Blocked state|Thông báo không có quyền hoặc scope không hợp lệ|Quay lại|Không hiển thị dữ liệu ngoài scope|
|D\-10|Error state|Xử lý lỗi tải, search hoặc pagination|Thử lại|Giữ kết quả đã tải nếu còn dùng được|



#### UI Contract

**User intent**

- Xem các đơn gần đây\.

- Tìm đơn bằng mã đơn, khách hàng hoặc thông tin liên quan\.

- Lọc theo khoảng thời gian và trạng thái\.

- Phân biệt nhanh đơn đã thanh toán, công nợ, đã hủy hoặc có đổi/trả\.

- Mở chi tiết đúng đơn để kiểm tra hoặc xử lý tiếp\.

    

**Information hierarchy**

1. Search và filter context\.

2. Mã đơn và thời điểm\.

3. Customer hoặc `Khách lẻ`\.

4. Tổng giá trị order\.

5. Order/payment/post\-sale status\.

6. Store và người bán khi cần phân biệt\.

    

**Layout anatomy**

- Top bar:

    - Title `Đơn hàng`\.

    - Optional sales shortcut\.

- Search area:

    - Search input\.

    - Clear\-search action\.

- Filter area:

    - Date preset/period\.

    - Filter button\.

    - Active filter chips\.

- Result summary:

    - Khoảng thời gian và số kết quả khi có\.

- Order list:

    - Order cards/rows\.

    - Loading, empty, no\-result, stale và error states\.

- Pagination/load\-more area:

    - Infinite scroll hoặc explicit load more theo platform contract\.

        

**Displayed data**

- Official order code\.

- Thời điểm hoàn tất/tạo order\.

- Customer hoặc `Khách lẻ`\.

- Tổng giá trị official order\.

- Settlement summary: đã thanh toán, một phần, công nợ hoặc trạng thái tương ứng\.

- Order state: hoàn tất, đã hủy hoặc state hợp lệ khác\.

- Post\-sale indicator: đã điều chỉnh hoặc có đổi/trả\.

- Store/counter context khi người dùng xem nhiều phạm vi\.

- Người bán/thu ngân khi cần kiểm soát\.

- External/reference code nếu cần tra cứu\.

    

**User inputs**

- Search query\.

- Date preset hoặc date range\.

- Order status filter\.

- Payment/settlement status filter\.

- Customer filter\.

- Store filter theo permission\.

- Seller/cashier filter theo permission\.

- Post\-sale status filter\.

- Sort option nếu được hỗ trợ\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG07\-E01|Top bar|`Đơn hàng`|Xác định module hiện tại|Luôn hiển thị|
|SG07\-E02|Sales shortcut|`Bán hàng` / icon|Mở SG\-01|Theo navigation model|
|SG07\-E03|Search input|`Tìm mã đơn, khách hàng…`|Search official orders trong scope|Default, focus, populated, error|
|SG07\-E04|Clear\-search action|`Xóa`|Xóa query, giữ filters|Khi có query|
|SG07\-E05|Date control|`Hôm nay` / khoảng ngày|Chọn nhanh hoặc mở date range|Có default rõ ràng|
|SG07\-E06|Filter button|`Bộ lọc`|Mở D\-06|Badge thể hiện số filter active|
|SG07\-E07|Active filter chip|Tên filter|Xóa từng filter|D\-03/D\-05|
|SG07\-E08|Result summary|Khoảng thời gian · số đơn|Giải thích tập kết quả|Ẩn count nếu chưa chắc chắn|
|SG07\-E09|Order list|Danh sách official order|Hiển thị kết quả|Loading, populated, empty, error|
|SG07\-E10|Order card|Tóm tắt order|Mở SG\-08|Default, warning, cancelled, returned|
|SG07\-E11|Order code|`#DH-...`|Nhận diện/copy khi phù hợp|Luôn hiển thị|
|SG07\-E12|Order time|Ngày giờ hoàn tất|Hỗ trợ phân biệt|Theo timezone tenant/store|
|SG07\-E13|Customer label|Tên khách / `Khách lẻ`|Cung cấp context|Read\-only|
|SG07\-E14|Order total|Tổng giá trị order|Hỗ trợ scan|Official value|
|SG07\-E15|Order\-status badge|`Hoàn tất` / `Đã hủy`|Hiển thị lifecycle status|Semantic label \+ color|
|SG07\-E16|Settlement badge|`Đã thanh toán` / `Công nợ` / `Thanh toán một phần`|Hiển thị settlement|Không gộp với order status|
|SG07\-E17|Post\-sale indicator|`Đã điều chỉnh` / `Có đổi trả`|Nêu downstream history|Khi có|
|SG07\-E18|Load\-more indicator|`Đang tải thêm…`|Phản ánh pagination|D\-07|
|SG07\-E19|Refresh action|`Làm mới`|Reload theo context hiện tại|D\-08/D\-10|
|SG07\-E20|Clear\-filters action|`Xóa bộ lọc`|Khôi phục filter mặc định|D\-05/D\-06|
|SG07\-E21|New\-sale action|`Tạo đơn bán hàng`|Mở sales flow|D\-04, theo permission|
|SG07\-E22|Retry button|`Thử lại`|Retry request thất bại|D\-10|



**Default scope behavior**

- Default period phải rõ ràng; đề xuất `Hôm nay` cho vận hành bán lẻ tần suất cao\.

- Default store scope lấy từ active store context của người dùng\.

- Người dùng chỉ thấy orders theo permission và data\-scope policy\.

- Danh sách mặc định sắp xếp theo completion/created time giảm dần\.

- Draft không xuất hiện trong SG\-07; draft thuộc SG\-01\.

- Cancelled order vẫn có thể xuất hiện nếu filter cho phép, không bị xóa khỏi lịch sử\.

    

**Search behavior**

- Search thực hiện trong official orders thuộc current permission scope\.

- Query có thể hỗ trợ:

    - Exact/partial official order code\.

    - Customer name, phone hoặc customer code theo permission\.

    - Payment/transfer reference khi service contract hỗ trợ\.

    - External order reference khi có\.

- Exact order code match được ưu tiên trên fuzzy customer match\.

- Search không tự mở rộng date range một cách vô hình\.

- Nếu query nằm ngoài period hiện tại, UI có thể gợi ý `Tìm trong khoảng thời gian rộng hơn`; chỉ thay đổi khi người dùng xác nhận\.

- Xóa query giữ nguyên filters và scroll reset về đầu kết quả\.

    

**Filter behavior**

- Filter sheet có thể gồm:

    - Khoảng thời gian\.

    - Order status\.

    - Settlement/payment status\.

    - Store\.

    - Người bán/thu ngân\.

    - Customer\.

    - Có điều chỉnh/đổi trả\.

- Chỉ hiển thị filter người dùng có quyền dùng và dữ liệu backend hỗ trợ\.

- Active filters luôn hiển thị ngoài sheet bằng chip hoặc summary dễ nhận biết\.

- `Xóa bộ lọc` trở về default scope, không trở về toàn bộ tenant nếu default scope hẹp hơn\.

- Filter count không tính date default như một active custom filter nếu UI đã thể hiện date riêng\.

- Áp dụng filter là read operation, không thay đổi order data\.

    

**Date and timezone behavior**

- Date range được diễn giải theo timezone của tenant/store theo contract\.

- `Hôm nay` dựa trên business timezone, không dựa mù vào device UTC\.

- Boundary đầu/cuối ngày phải nhất quán giữa UI và query API\.

- Hiển thị ngày giờ theo locale Việt Nam hoặc user preference\.

- Date range không hợp lệ phải được validate trước khi query\.

    

**Order\-card behavior**

- Toàn bộ card là vùng chạm chính mở SG\-08\.

- Card không chứa destructive action\.

- Nếu có quick action, quick action không chồng vùng chạm và không vượt quá scope inquiry\.

- Status không chỉ dùng màu; luôn có text label\.

- Card cancelled vẫn hiển thị official total theo snapshot và label `Đã hủy`\.

- Card có đổi/trả hiển thị indicator nhưng không thay total lịch sử bằng net value không giải thích\.

    

**Status model presentation**

- Order status, settlement status và post\-sale status là ba trục riêng\.

- Ví dụ hợp lệ:

    - `Hoàn tất` \+ `Đã thanh toán`\.

    - `Hoàn tất` \+ `Công nợ`\.

    - `Hoàn tất` \+ `Đã thanh toán` \+ `Có đổi trả`\.

    - `Đã hủy` \+ settlement state phù hợp\.

- Không dùng một badge duy nhất `Đã xong` để che mất ý nghĩa nghiệp vụ\.

- Không suy luận payment status chỉ từ order status\.

    

**Pagination and refresh behavior**

- API sử dụng cursor hoặc pagination ổn định để hạn chế order bị lặp/mất khi dữ liệu mới phát sinh\.

- Khi tải thêm thất bại, giữ các rows đã tải và hiển thị retry tại cuối list\.

- Pull\-to\-refresh/làm mới giữ query/filter nhưng tải lại từ đầu\.

- Khi danh sách có dữ liệu stale, hiển thị action `Làm mới`; không tự đổi vị trí list liên tục khi người dùng đang đọc\.

- Deduplicate rows theo official order ID\.

    

**Cross\-theme entry behavior**

- Deep link từ Customer có thể prefill customer filter nhưng vẫn áp dụng permission scope\.

- Deep link từ payment/receivable/report phải có official order ID hoặc query context rõ ràng\.

- Nếu order nằm ngoài active store nhưng người dùng có quyền xem, UI nêu store context\.

- Nếu không có quyền, không tiết lộ sự tồn tại hoặc chi tiết order ngoài thông báo được policy cho phép\.

    

**Business rules and invariants**

- SG\-07 chỉ hiển thị official orders, không hiển thị working drafts\.

- Mỗi row ánh xạ tới một official order ID\.

- Search/filter không mở rộng tenant/store/role scope\.

- Danh sách là projection phục vụ inquiry; official order detail tại SG\-08 là nguồn hiển thị chi tiết\.

- Không sửa, hủy hoặc đổi/trả order trực tiếp tại SG\-07\.

- Không thay đổi snapshot total do adjustment/return nếu không có presentation contract rõ ràng\.

- Refresh/pagination không tạo domain command hoặc side effect\.

    

**Permissions**

- `View own sales orders`: xem đơn do mình tạo/phụ trách\.

- `View store sales orders`: xem đơn trong store scope\.

- `View all tenant sales orders`: xem đa cửa hàng theo tenant scope\.

- `View customer identity`: xem thông tin nhận diện khách hàng\.

- `View payment status`: xem settlement status\.

- `View post-sale status`: xem adjustment/cancellation/return indicator\.

- `Start new sale`: sử dụng CTA tạo đơn\.

- Filter store/seller chỉ hiển thị khi permission tương ứng cho phép\.

    

**Empty, no\-result, loading and error states**

- D\-04 chỉ dùng khi default scope thực sự chưa có official order; có CTA tạo đơn nếu được phép\.

- D\-05 dùng khi query/filter không có kết quả; hiển thị active context và action xóa phù hợp\.

- D\-07 dùng skeleton cho initial load; pagination dùng indicator ở cuối list\.

- D\-08 dùng khi dữ liệu đã tải có thể stale nhưng vẫn đọc được\.

- D\-09 không dùng thay cho empty state; nêu rõ không có quyền hoặc scope không hợp lệ\.

- D\-10 giữ query/filter; lỗi pagination không thay toàn bộ list bằng error screen\.

    

**Feedback and messaging**

- No\-result dùng neutral semantic\.

- Order cancelled dùng subdued/danger semantic theo Design System nhưng vẫn đọc được\.

- `Công nợ` dùng status semantic phù hợp, không mặc định là error\.

- `Có đổi trả` và `Đã điều chỉnh` là informational history indicators\.

- Refresh thành công không cần toast nếu list cập nhật rõ ràng\.

    

**Accessibility**

- Search, date control, filter và order cards có accessible labels\.

- Screen reader đọc card theo thứ tự: mã đơn → thời gian → khách hàng → tổng → statuses\.

- Status không chỉ phân biệt bằng màu/icon\.

- Filter sheet trap focus; đóng sheet trả focus về filter button\.

- Result count được announce sau khi search/filter hoàn tất nhưng không lặp khi pagination\.

- Touch target đủ lớn và row/card có focus state rõ ràng\.

    

**Responsive behavior**

- Mobile: card list một cột; search/date có thể sticky; filter dùng bottom sheet\.

- Tablet: list rộng hoặc master\-detail với SG\-08 nếu navigation architecture cho phép\.

- Web: table/list có sortable columns được kiểm soát; filter dùng side panel\.

- Query semantics, permission scope và status model không đổi theo viewport\.

- Cột phụ có thể ẩn trên mobile nhưng thông tin nhận diện/status cốt lõi phải giữ lại\.

    

#### Low\-fi wireframes

**D\-01 — Default**

```Plain Text
┌──────────────────────────────┐
│ Đơn hàng                     │
├──────────────────────────────┤
│ 🔎 Tìm mã đơn, khách hàng…   │
│ [Hôm nay ▾]       [Bộ lọc]   │
├──────────────────────────────┤
│ Hôm nay · 24 đơn             │
│ ┌──────────────────────────┐ │
│ │ #DH-002586   17:42       │ │
│ │ Nguyễn Văn An            │ │
│ │ 1.250.000 ₫              │ │
│ │ Hoàn tất · Đã thanh toán │ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ #DH-002585   17:25       │ │
│ │ Khách lẻ · 620.000 (FAB +) |
│ │ Hoàn tất · Tiền mặt      │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

**D\-02 — Search results**

```Plain Text
┌──────────────────────────────┐
│ Đơn hàng                     │
├──────────────────────────────┤
│ 🔎 DH-002581              ×  │
│ [Hôm nay ▾]       [Bộ lọc]   │
├──────────────────────────────┤
│ 1 kết quả                    │
│ ┌──────────────────────────┐ │
│ │ #DH-002581   14:08       │ │
│ │ Nguyễn Văn An            │ │
│ │ 1.250.000 ₫              │ │
│ │ Hoàn tất · Công nợ       │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

**D\-03 — Filtered results**

```Plain Text
┌──────────────────────────────┐
│ Đơn hàng                     │
├──────────────────────────────┤
│ 🔎 Tìm mã đơn, khách hàng…   │
│ [7 ngày qua] [Công nợ ×]     │
│ [Cửa hàng HN ×] [Bộ lọc 2]   │
├──────────────────────────────┤
│ 12 đơn                       │
│ #DH-002581 · 1.250.000 ₫     │
│ Nguyễn Văn An · Công nợ      │
│ ──────────────────────────── │
│ #DH-002544 · 850.000 ₫       │
│ Công ty Minh Phát · Công nợ  │
└──────────────────────────────┘
```

**D\-04 — Empty**

```Plain Text
┌──────────────────────────────┐
│ Đơn hàng                     │
├──────────────────────────────┤
│                              │
│      Chưa có đơn hàng        │
│ Official order sẽ xuất hiện  │
│ sau khi hoàn tất bán hàng.   │
│                              │
│     [Tạo đơn bán hàng]       │
└──────────────────────────────┘
```

**D\-05 — No result**

```Plain Text
┌──────────────────────────────┐
│ Đơn hàng                     │
├──────────────────────────────┤
│ 🔎 Nguyễn Văn Bình        ×  │
│ [Hôm nay] [Đã hủy ×]         │
├──────────────────────────────┤
│ Không tìm thấy đơn phù hợp   │
│ với tìm kiếm và bộ lọc.      │
│                              │
│ [Xóa tìm kiếm]               │
│ [Xóa bộ lọc]                 │
└──────────────────────────────┘
```

**D\-06 — Filter sheet**

```Plain Text

├──────────────────────────────┤
│ Bộ lọc                   ×   │
│ Thời gian   [7 ngày qua ▾]   │
│ Trạng thái  [Hoàn tất ▾]     │
│ Thanh toán  [Công nợ ▾]      │
│ Cửa hàng    [Hà Nội ▾]       │
│ Người bán   [Tất cả ▾]       │
│                              │
│ [Xóa bộ lọc] [Áp dụng]       │
└──────────────────────────────┘
```

**D\-07 — Loading/pagination**

```Plain Text
┌──────────────────────────────┐
│ Đơn hàng                     │
├──────────────────────────────┤
│ 🔎 Tìm mã đơn, khách hàng…   │
│ [Hôm nay ▾]       [Bộ lọc]   │
├──────────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒             │
│                              │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒             │
└──────────────────────────────┘
```

**D\-09 — Blocked**

```Plain Text
┌──────────────────────────────┐
│ Không thể xem đơn hàng       │
├──────────────────────────────┤
│ Anh/chị không có quyền tra cứu│
│ đơn hàng trong phạm vi này.  │
│                              │
│          [Quay lại]          │
└──────────────────────────────┘
```

**D\-10 — Error**

```Plain Text
┌──────────────────────────────┐
│ Đơn hàng                     │
├──────────────────────────────┤
│ 🔎 Nguyễn Văn             ×  │
│ [7 ngày qua]      [Bộ lọc]   │
├──────────────────────────────┤
│ Không thể tải danh sách      │
│ Tìm kiếm và bộ lọc vẫn được  │
│ giữ lại.                     │
│          [Thử lại]           │
└──────────────────────────────┘
```

#### Visuals

TBD\.

#### Traceability

TBD\.

### 5\.5\.9 SG\-08 — Chi tiết \& lịch sử đơn hàng

#### Overview

- Purpose: Cung cấp một hub tra cứu đầy đủ cho official order, giúp người dùng hiểu giao dịch gốc, settlement, lịch sử sau bán, trạng thái downstream và các hành động tiếp theo được phép\.

- Related epic: EP\-03 — Tra cứu \& theo dõi đơn hàng\.

- Related business flow: BF\-05 — Tra cứu \& theo dõi\.

- Business flow group: Inquiry \& control\.

- Primary users: Nhân viên bán hàng, thu ngân, quản lý cửa hàng, kế toán, chủ đơn vị và người dùng kiểm soát có quyền\.

- Primary task: Kiểm tra một official order và khởi tạo đúng nghiệp vụ tiếp theo mà không làm thay đổi giao dịch gốc\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: Tách rõ commercial snapshot, trạng thái hiện hành và lịch sử phát sinh; ưu tiên khả năng kiểm tra, truy vết và giải thích action eligibility hơn tốc độ thao tác\.

- Scope boundary: SG\-08 là read\-and\-route hub; không trực tiếp sửa SalesOrder, ghi payment, thu công nợ, hủy đơn, tạo adjustment hoặc tạo ReturnExchangeOrder\.

    

#### Entry \& exit

- Entry points:

    - Chọn một order từ SG\-07 — Danh sách đơn hàng\.

    - Action `Xem chi tiết đơn` từ SG\-06 — Kết quả bán hàng\.

    - Quay lại từ SG\-09, SG\-10 hoặc SG\-11 sau khi hủy flow hoặc hoàn tất nghiệp vụ\.

    - Deep link hợp lệ từ Customer, payment, receivable, inventory, e\-invoice, reporting hoặc timeline activity\.

- Exit points:

    - Quay lại SG\-07 và giữ query/filter/scroll context\.

    - `Điều chỉnh thông tin` → SG\-09 với sales\_order\_id và source version\.

    - `Hủy đơn` → SG\-10 nếu action đủ điều kiện sơ bộ\.

    - `Đổi/trả hàng` → SG\-11 nếu action đủ điều kiện sơ bộ\.

    - `Xem công nợ` → surface của Theme 6 khi có quyền\.

    - `Xem trạng thái kho` → surface của Theme 7 khi có quyền\.

    - `Xem trạng thái hóa đơn điện tử` → surface của Theme 8 khi có quyền\.

    - `Xem/In/Chia sẻ phiếu bán hàng` → D\-04 trong SG\-08\.

        

#### Screen/state inventory

|State|Type|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|Screen — Default completed order|Hiển thị giao dịch gốc, summary và trạng thái chính|Xem thao tác|Commercial snapshot read\-only|
|D\-02|Expanded section — Payment \& receivable|Hiển thị settlement summary và transaction history|Xem công nợ|Không ghi nhận payment tại SG\-08|
|D\-03|Expanded section — Timeline \& post\-sale history|Hiển thị activity, adjustment, cancellation và đổi/trả|Mở nghiệp vụ nguồn|Timeline append\-only|
|D\-04|Receipt view/action sheet|Xem version hiện hành, in hoặc chia sẻ phiếu bán hàng|In/Chia sẻ phiếu|Phiếu bán hàng không phải hóa đơn điện tử|
|D\-05|Contextual action sheet — Eligible actions|Hiển thị các thao tác sau bán khả dụng|Chọn thao tác|Action còn phải qua precheck authoritative tại Epic đích|
|D\-06|Redirect/blocked — Cancellation unavailable|Giải thích vì sao không thể hủy và hướng sang đổi/trả hoặc đối soát|Tạo phiếu đổi/trả / Kiểm tra trạng thái|Không tự động tạo nghiệp vụ mới|
|D\-07|Related processing/reconciliation state|Hiển thị downstream pending, failed, uncertain hoặc reconciliation required|Kiểm tra trạng thái|Order vẫn có thể đã hoàn tất|
|D\-08|Screen variant — Cancelled order|Hiển thị cancellation summary nhưng giữ nguyên giao dịch gốc|Xem lịch sử hủy|Không cho hủy hoặc đổi/trả mới|
|D\-09|Screen variant — Adjusted/returned order|Hiển thị adjustment indicator và return summary|Xem lịch sử|fully\_returned không đồng nghĩa cancelled|
|D\-10|Loading/refreshing state|Tải detail hoặc làm mới projection sau nghiệp vụ|—|Giữ order context|
|D\-11|Error/stale state|Xử lý lỗi tải hoặc projection chưa bắt kịp|Thử lại|Không suy luận nghiệp vụ chưa xảy ra|
|D\-12|No\-permission/not\-found state|Chặn truy cập đơn ngoài scope hoặc không tồn tại|Quay lại|Không tiết lộ dữ liệu ngoài quyền|



#### UI Contract

**User intent**

- Kiểm tra chính xác khách hàng, dòng hàng và giá trị giao dịch tại thời điểm bán\.

- Biết đơn đã thanh toán bao nhiêu, còn phải thu bao nhiêu và đã phát sinh refund/void hay chưa\.

- Theo dõi adjustment, cancellation, đổi/trả và downstream processing trên cùng timeline\.

- Xem lại, in hoặc chia sẻ phiếu bán hàng\.

- Biết hành động nào hiện khả dụng và vì sao một hành động bị chặn\.

- Mở đúng flow sau bán mà không mất order context\.

    

**Information hierarchy**

1. Mã đơn và các chiều trạng thái hiện hành\.

2. Tổng phải trả, đã thanh toán, đã hoàn và còn phải thu\.

3. Customer snapshot và commercial snapshot của dòng hàng\.

4. Adjustment, cancellation hoặc return summary nếu có\.

5. Action eligibility và blocker cần xử lý\.

6. Payment transactions, phiếu bán hàng và integration status\.

7. Timeline/audit history và thông tin kỹ thuật được phép xem\.

    

**Layout anatomy**

- Top bar:

    - Back action\.

    - Title `Chi tiết đơn hàng`\.

    - Overflow/contextual action mở D\-05\.

- Status area:

    - Official order code\.

    - Order lifecycle, lock, payment, return và adjustment indicators\.

    - Banner pending/warning/blocked nếu cần\.

- Summary area:

    - Customer snapshot hoặc `Khách lẻ`\.

    - Thời điểm bán, cửa hàng và người bán\.

    - Tổng đơn, đã thanh toán, đã hoàn và còn phải thu\.

- Main content:

    - Dòng hàng và commercial details\.

    - Payment \& receivable\.

    - Phiếu bán hàng\.

    - Related processing status\.

    - Timeline \& lịch sử sau bán\.

- Action area:

    - Primary contextual action khi chỉ có một action nổi trội\.

    - `Thao tác` mở D\-05 khi có nhiều action\.

    - Action bị chặn được giải thích trong context, không chỉ disabled\.

        

**Displayed data**

- Official order ID/code\.

- Order lifecycle và lock status\.

- Payment status, return status và adjustment indicator\.

- Completion time theo business timezone\.

- Store, counter/shift và seller snapshot khi có\.

- Customer snapshot hoặc `Khách lẻ`\.

- Buyer tax snapshot khi có\.

- SalesOrderLine snapshot:

    - Tên và mã sản phẩm tại thời điểm bán\.

    - SKU/reference và ProductUnit snapshot\.

    - Số lượng, đơn giá, discount/promotion, thuế và thành tiền\.

- Monetary summary:

    - Tổng tiền hàng\.

    - Tổng chiết khấu\.

    - Tổng thuế\.

    - Điều chỉnh làm tròn\.

    - Tổng khách phải trả\.

- Settlement summary:

    - Tổng phải thu\.

    - Tổng đã thanh toán\.

    - Tổng đã hoàn\.

    - Số còn phải thu và ngày hẹn thanh toán khi có\.

- Adjustment, cancellation và return summary\.

- SalesReceipt version/status\.

- Integration business status và delivery status theo target\.

- SalesOrderTimelineView\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG08\-E01|Top bar|`Chi tiết đơn hàng`|Xác định screen hiện tại|Luôn hiển thị|
|SG08\-E02|Back action|`Quay lại`|Trở về source screen và giữ context|SG\-07/SG\-06/deep link|
|SG08\-E03|Overflow/action button|`Thao tác`|Mở D\-05|Có ít nhất một action có thể hiển thị|
|SG08\-E04|Order code|`#DH-...`|Nhận diện/copy khi phù hợp|Luôn hiển thị|
|SG08\-E05|Order lifecycle badge|`Hoàn tất` / `Đã hủy`|Hiển thị lifecycle|Không gộp với payment/return status|
|SG08\-E06|Payment status badge|`Đã thanh toán` / `Còn phải thu` / `Đang xử lý`|Hiển thị settlement|Theo Sales Settlement authoritative|
|SG08\-E07|Return status badge<br>|`Chưa trả` / `Đã trả một phần` / `Đã trả toàn bộ`|Hiển thị return dimension|Không đồng nghĩa lifecycle|
|SG08\-E08|Adjustment indicator|`Đã điều chỉnh`|Mở lịch sử adjustment|Khi có OrderAdjustment|
|SG08\-E09|Processing banner|Pending/failed/uncertain/reconciliation message|Mở D\-07|Khi downstream cần chú ý|
|SG08\-E10|Customer snapshot card|Snapshot khách / `Khách lẻ`|Hiển thị transaction context|Read\-only|
|SG08\-E11|Current\-customer link|`Xem hồ sơ hiện tại`|Mở Theme 3|Có customer\_partner\_id và permission|
|SG08\-E12|Order context|Cửa hàng · người bán · thời điểm|Hiển thị original context|Read\-only|
|SG08\-E13|Order\-line list|Dòng hàng snapshot|Hiển thị commercial transaction|Expanded/collapsed|
|SG08\-E14|Line\-commercial detail|Giá · giảm giá · thuế · thành tiền|Giải thích line value|Theo permission|
|SG08\-E15|Monetary summary|Tổng hàng · giảm giá · thuế · làm tròn · tổng đơn|Hiển thị official values|Read\-only|
|SG08\-E16|Settlement summary|Phải thu · đã thu · đã hoàn · còn phải thu|Mở D\-02|Theo permission|
|SG08\-E17|Payment transaction list|Collection/void/refund rows|Hiển thị lịch sử settlement|D\-02|
|SG08\-E18|Receivable link|`Xem công nợ`|Mở Theme 6|Có receivable context và permission|
|SG08\-E19|Receipt card|Phiếu bán hàng · version · status|Mở D\-04|Có receipt hoặc policy cho phép tạo|
|SG08\-E20|Integration status list|Receivable · Inventory · E\-invoice · Reporting|Mở D\-07/details|Theo target áp dụng|
|SG08\-E21|Timeline|SalesOrderTimelineView|Hiển thị/tải thêm activity|D\-03|
|SG08\-E22|Timeline item|Loại · actor · thời điểm · kết quả · lý do|Mở source record|Theo permission|
|SG08\-E23|Adjustment summary|Trường thay đổi · before/after · lý do|Mở SG\-09 history/details|Khi có adjustment|
|SG08\-E24|Cancellation summary|Lý do · actor · thời điểm · impact status|Mở SG\-10 history/details|D\-08|
|SG08\-E25|Return summary|Hàng trả · hàng mới · thu/hoàn/cấn trừ|Mở SG\-13/source record|D\-09|
|SG08\-E26|Adjust action|`Điều chỉnh thông tin`|Mở SG\-09|Có permission và preliminary eligibility|
|SG08\-E27|Cancel action|`Hủy đơn`|Mở SG\-10 hoặc D\-06|Theo lifecycle/settlement/permission|
|SG08\-E28|Return action|`Đổi/trả hàng`|Mở SG\-11|Có permission và preliminary eligibility|
|SG08\-E29|Receipt print action|`In phiếu bán hàng`|Tạo print activity/job|D\-04|
|SG08\-E30|Receipt share action|`Chia sẻ phiếu bán hàng`|Chọn channel và ghi activity|D\-04|
|SG08\-E31|Check\-status action|`Kiểm tra trạng thái`|Refresh related status|D\-07/D\-11|
|SG08\-E32|Retry action|`Thử lại`|Retry read hoặc technical item đủ điều kiện|D\-07/D\-11|



**Transaction snapshot behavior**

- SG\-08 hiển thị commercial snapshot đã commit của SalesOrder, không lấy tên, đơn vị, giá hoặc promotion hiện hành từ master data để thay nội dung lịch sử\.

- Thay đổi Product, ProductUnit, Partner hoặc pricing master sau bán không cập nhật ngược vào order detail\.

- Đơn đã hủy vẫn hiển thị đầy đủ transaction snapshot gốc\.

- Metadata được điều chỉnh qua EP\-04 có thể hiển thị giá trị hiện hành, nhưng phải cho phép nhận biết hoặc mở giá trị ban đầu và lịch sử điều chỉnh\.

- Read model của SG\-08 không phải source of truth và không được dùng để cập nhật ngược aggregate\.

    

**Customer snapshot behavior**

- Customer card mặc định hiển thị customer snapshot tại thời điểm bán hoặc `Khách lẻ`\.

- Nếu order có customer\_partner\_id và người dùng có quyền, `Xem hồ sơ hiện tại` mở hồ sơ Theme 3\.

- UI phải phân biệt rõ `Thông tin tại thời điểm bán` với `Hồ sơ hiện tại`\.

- Người dùng có quyền xem SalesOrder nhưng không có quyền xem Partner hiện tại vẫn được xem customer snapshot trong phạm vi order permission\.

- SG\-08 không cho đổi Customer của transaction gốc\.

    

**Line and commercial\-detail behavior**

- Mỗi dòng hiển thị tối thiểu product snapshot, ProductUnit, số lượng, đơn giá và thành tiền\.

- Commercial details mở rộng có thể hiển thị source price, discount/promotion, tax và rounding allocation khi có quyền\.

- Tổng của dòng và monetary summary phải khớp snapshot đã commit\.

- Dòng hàng không có edit, delete, quantity hoặc price override action\.

- Returnable quantity có thể hiển thị như informational projection nhưng phải được precheck lại trong SG\-11\.

    

**Payment and receivable behavior**

- D\-02 hiển thị tổng phải thu, tổng đã thanh toán, tổng đã hoàn, số còn phải thu và ngày hẹn thanh toán khi có\.

- Payment transaction phải phân biệt collection, void và refund\.

- Mỗi transaction hiển thị loại, số tiền, phương thức, thời điểm, actor, status và reference được phép xem\.

- SG\-08 không tự tính outstanding amount từ rows hiển thị; dùng Sales Settlement authoritative summary\.

- Receivable impact status không đồng nghĩa ledger authoritative của Theme 6\.

- `Xem công nợ` chỉ xuất hiện khi có receivable context và permission\.

- SG\-08 không ghi nhận payment mới, void payment, refund hoặc thu công nợ\.

    

**Timeline and post\-sale history behavior**

- Timeline là append\-only và tải theo thứ tự thời gian rõ ràng; không cho sửa hoặc xóa item\.

- Activity có thể bao gồm order completed, payment, void, refund, receipt, adjustment, cancellation, return/exchange và downstream processing\.

- Mỗi item hiển thị loại, actor hoặc system, timestamp, result và reason/description ngắn khi có\.

- Item có source record và permission phù hợp có thể mở nghiệp vụ nguồn\.

- Adjustment activity có thể hiển thị before/after diff theo permission\.

- Product analytics event hoặc technical log không được trình bày như business timeline item\.

- Deduplicate timeline item theo authoritative activity ID\.

    

**Receipt behavior**

- Receipt card hiển thị SalesReceipt hiện hành và version hiện tại\.

- Nếu chưa có persisted receipt và policy cho phép, SG\-08 có thể gọi generate receipt từ commercial snapshot\.

- SalesReceipt phải có nhãn `Phiếu bán hàng nội bộ — không phải hóa đơn điện tử`\.

- D\-04 cho phép xem version, in, chia sẻ hoặc tải artifact theo permission và capability\.

- Generate receipt phải idempotent theo SalesOrder và version context\.

- In/chia sẻ ghi SalesReceiptActivity với actor, timestamp và channel/device context\.

- Lỗi tạo/in/chia sẻ receipt không làm thay đổi order lifecycle hoặc payment status\.

- E\-invoice được hiển thị ở related status và mở Theme 8; không dùng receipt action để phát hành hóa đơn điện tử\.

    

**Integration\-status behavior**

- Related status có thể gồm Receivable, Inventory, E\-invoice và Reporting khi áp dụng\.

- UI phải tách business integration status khỏi delivery status\.

- Business status có thể gồm `Không yêu cầu`, `Đang xử lý`, `Đã tiếp nhận`, `Bị từ chối`, `Cần đối soát`, `Đã đối soát`\.

- Delivery status có thể gồm `Đã tạo`, `Trong hàng đợi`, `Đã gửi`, `Đã xác nhận`, `Thất bại`, `Chưa xác định` hoặc `Dead letter` với wording thân thiện theo permission\.

- Downstream failed không làm UI trình bày official order thành chưa hoàn tất\.

- Raw payload, stack trace và dữ liệu nhạy cảm không hiển thị cho người dùng thông thường\.

- Technical retry chỉ hiển thị khi record đủ điều kiện và người dùng có permission; retry dùng idempotency và không sửa payload nghiệp vụ đã commit\.

- `Cần đối soát` phải có hướng xử lý hoặc liên kết phù hợp\.

    

**Action\-eligibility behavior**

- D\-05 chỉ hiển thị action phù hợp với tenant, store scope, permission, order lifecycle, lock status, settlement và nghiệp vụ đang xử lý\.

- Việc action xuất hiện không bảo đảm command sẽ thành công; SG\-09, SG\-10 hoặc SG\-11 phải chạy precheck authoritative\.

- Người dùng không có permission không nhìn thấy action tương ứng\.

- Action disabled chỉ dùng khi việc giải thích có ích; phải hiển thị blocker rõ ràng\.

- Khi projection hoặc settlement đang uncertain, action có rủi ro tài chính bị chặn cho tới khi trạng thái được xác định\.

- Navigation sang Epic đích truyền tenant/store context, sales\_order\_id, source version và correlation context cần thiết\.

    

**Adjustment\-action behavior**

- `Điều chỉnh thông tin` chỉ mở SG\-09 khi người dùng có `sales.order.adjust` và order chưa bị chặn sơ bộ\.

- SG\-08 không hiển thị customer, line, price, settlement hoặc e\-invoice fields như editable metadata\.

- SG\-09 xác định adjustable field whitelist và precheck authoritative\.

- Sau adjustment thành công, SG\-08 tải lại effective metadata, adjustment indicator và timeline\.

    

**Cancellation\-action behavior**

- `Hủy đơn` chỉ mở SG\-10 khi người dùng có `sales.order.cancel`, lifecycle chưa cancelled và không có preliminary blocker rõ ràng\.

- Đơn chưa phát sinh settlement có thể đi vào SG\-10 để precheck đầy đủ\.

- Đơn đã thanh toán hoặc thanh toán một phần không được hủy; D\-06 giải thích và đề xuất `Tạo phiếu đổi/trả` nếu phù hợp\.

- Payment đang xử lý, uncertain hoặc reconciliation required không được chuyển thẳng sang hủy hoặc đổi/trả; D\-06/D\-07 hướng người dùng kiểm tra trạng thái trước\.

- SG\-08 không tạo SalesOrderCancellation\.

    

**Return/exchange\-action behavior**

- `Đổi/trả hàng` chỉ mở SG\-11 khi người dùng có `sales.return_exchange.create`, order chưa cancelled và không bị conflict sơ bộ\.

- Action có thể khả dụng cho đơn đã thanh toán, thanh toán một phần hoặc trường hợp nghiệp vụ đổi/trả hợp lệ khác\.

- Returnable quantity và price của hàng mới phải được SG\-11 revalidate\.

- Đơn fully\_returned không đồng nghĩa cancelled; việc cho lập thêm phiếu phụ thuộc remaining returnable quantity và policy\.

- SG\-08 không tạo ReturnExchangeOrder\.

    

**Refresh and eventual\-consistency behavior**

- Khi quay lại từ SG\-09, SG\-10, SG\-11 hoặc source record khác, SG\-08 tải lại detail, settlement, return, timeline và integration projections\.

- Nếu command đã thành công nhưng projection chưa bắt kịp, hiển thị `Đang cập nhật dữ liệu` và giữ operation reference khi có\.

- Không kết luận nghiệp vụ thất bại chỉ vì timeline hoặc badge chưa cập nhật tức thời\.

- Refresh là read operation và không gửi lại domain command\.

- Khi source version thay đổi, action sheet phải được tính lại trước khi người dùng chọn action\.

    

**Business rules and invariants**

- SG\-08 chỉ mở official SalesOrder; không mở draft hoặc CheckoutAttempt chưa tạo order\.

- Commercial snapshot và giao dịch gốc không được sửa trực tiếp\.

- Order lifecycle, payment status, return status, adjustment indicator và integration status là các chiều độc lập\.

- `fully_returned` không đồng nghĩa `cancelled`\.

- Payment hoặc downstream failure sau khi SalesOrder commit không tự động rollback official order\.

- Timeline và lịch sử chứng từ không bị ghi đè hoặc xóa từ SG\-08\.

- Action sau bán chỉ được khởi tạo qua Epic/SG đích có precheck và command riêng\.

- Deep link phải được kiểm tra tenant, membership, permission và store scope\.

    

**Permissions**

- `View sales order`: xem detail cơ bản\.

- `View sales order commercial details`: xem giá, discount, promotion và tax breakdown\.

- `View customer snapshot`: xem snapshot trong transaction\.

- `View current customer profile`: mở Theme 3\.

- `View payment details`: xem payment transactions\.

- `View receivable context`: mở Theme 6\.

- `View integration status`: xem related processing status\.

- `Retry eligible integration item`: technical retry item đủ điều kiện\.

- `View sales receipt`: xem receipt và version\.

- `Print sales receipt`: in phiếu bán hàng\.

- `Share sales receipt`: chia sẻ phiếu bán hàng\.

- `sales.order.adjust`: khởi tạo SG\-09\.

- `sales.order.cancel`: khởi tạo SG\-10\.

- `sales.return_exchange.create`: khởi tạo SG\-11\.

    

**Loading, error and blocked handling**

- D\-10 initial load dùng skeleton theo các vùng status, summary, lines và sections\.

- Refresh giữ nội dung cũ có nhãn stale khi dữ liệu vẫn an toàn để đọc\.

- D\-11 giữ sales\_order\_id, source context và cho `Thử lại`; không đưa người dùng sang checkout hoặc tạo order mới\.

- Lỗi tải một section không bắt buộc có thể hiển thị inline mà không thay toàn bộ detail bằng error screen\.

- D\-12 dùng cho no permission, invalid deep link hoặc order ngoài scope; không tiết lộ customer, amount hoặc status\.

- Order đã bị xóa khỏi projection nhưng authoritative lookup vẫn đang kiểm tra dùng neutral loading/uncertain state trước khi kết luận not found\.

    

**Feedback and messaging**

- `Hoàn tất` mô tả order lifecycle, không mặc định nghĩa là đã thanh toán đủ\.

- `Còn phải thu` là settlement state, không dùng error semantic mặc định\.

- `Đã trả toàn bộ` là return status, không dùng label `Đã hủy`\.

- Downstream pending/failed luôn đi kèm thông điệp order có bị ảnh hưởng hay không\.

- Action unavailable nêu lý do và next step khi có\.

- Refresh thành công không cần toast nếu data update hiển thị rõ ràng\.

    

**Accessibility**

- Screen reader đọc theo thứ tự: mã đơn → lifecycle → payment/return status → tổng tiền → customer → sections → actions\.

- Các chiều trạng thái không chỉ phân biệt bằng màu hoặc icon\.

- Accordion/expansion controls có expanded/collapsed state\.

- Monetary summary và transactions có semantic labels, không đọc ký hiệu rời rạc\.

- Timeline item nêu loại activity, actor, timestamp và result\.

- D\-05/D\-04 trap focus và trả focus về action đã mở sheet khi đóng\.

- Action bị chặn có accessible explanation\.

    

**Responsive behavior**

- Mobile: một cột; status và monetary summary đặt trước lines; sections dùng accordion/progressive expansion; action sheet ở bottom\.

- Tablet: có thể dùng hai cột content–summary hoặc master\-detail từ SG\-07\.

- Web: side summary sticky; lines/payment có thể dùng table; timeline ở panel riêng\.

- Commercial snapshot, action eligibility và permission không đổi theo viewport\.

- Nội dung kỹ thuật dài phải truncate/expand có kiểm soát; không làm biến mất business status cốt lõi\.

    

#### Low\-fi wireframes

**D\-01 — Default completed order**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chi tiết đơn hàng      ⋮  │
├──────────────────────────────┤
│ #DH-002586     17:42 17/07   │
│ [Hoàn tất] [Đã thanh toán]   │
│ [Chưa trả hàng]              │
├──────────────────────────────┤
│ Nguyễn Văn An · KH-0124      │
│ Cửa hàng Hà Nội · NV Minh    │
├──────────────────────────────┤
│ Amoxi 500 mg · Hộp           │
│ 2 × 85.000 ₫      170.000 ₫  │
│ Vật tư B · Chai              │
│ 3 × 360.000 ₫   1.080.000 ₫  │
├──────────────────────────────┤
│ Tổng đơn       1.250.000 ₫   │
│ Đã thanh toán  1.250.000 ₫   │
├──────────────────────────────┤
│ Thanh toán & công nợ       › │
│ Phiếu bán hàng             › │
│ Trạng thái liên quan       › │
│ Lịch sử đơn hàng           › │
├──────────────────────────────┤
│          [Thao tác]          │
└──────────────────────────────┘
```

**D\-02 — Payment \& receivable expanded**

```Plain Text

├──────────────────────────────┤
│ Tổng phải thu  1.250.000 ₫   │
│ Đã thanh toán    900.000 ₫   │
│ Đã hoàn                 0 ₫  │
│ Còn phải thu      350.000 ₫  │
│ Hẹn thanh toán     25/07/26  │
├──────────────────────────────┤
│ 17/07 · Tiền mặt             │
│ Thu              500.000 ₫   │
│ 17/07 · Chuyển khoản         │
│ Thu              400.000 ₫   │
├──────────────────────────────┤
│         [Xem công nợ]        │
└──────────────────────────────┘
```

**D\-03 — Timeline \& post\-sale history**

```Plain Text

├──────────────────────────────┤
│ 20/07 09:15                  │
│ ↺ Đổi/trả đã hoàn tất        │
│ Thu thêm 120.000 ₫ · NV Lan  │
│                    [Xem ›]   │
│ │                            │
│ 18/07 14:20                  │
│ ✎ Đã điều chỉnh ghi chú      │
│ “Giao buổi chiều” · NV Minh  │
│                    [Xem ›]   │
│ │                            │
│ 17/07 17:42                  │
│ ✓ Đơn hàng đã hoàn tất       │
│ Thanh toán 1.250.000 ₫       │
│                              │
│          [Tải thêm]          │
└──────────────────────────────┘
```

**D\-04 — Receipt view/actions**

```Plain Text
┌──────────────────────────────┐
│ Phiếu bán hàng           ×   │
├──────────────────────────────┤
│ Phiếu hiện hành · Version 2  │
│ Đơn #DH-002586               │
│ Cập nhật 18/07 14:20         │
│                              │
│ Phiếu bán hàng nội bộ        │
│ Không phải hóa đơn điện tử   │
│                              │
│ [Xem phiếu]                  │
│ [🖨 In phiếu bán hàng]       │
│ [↗ Chia sẻ phiếu bán hàng]   │
│ [Xem các version]            │
└──────────────────────────────┘
```

**D\-05 — Eligible actions**

```Plain Text

├──────────────────────────────┤
│ Thao tác                 ×   │
│ [✎ Điều chỉnh thông tin]     │
│ [↺ Đổi/trả hàng]             │
│ [⊘ Hủy đơn]                  │
│                              │
│ Hành động sẽ được kiểm tra   │
│ lại trước khi xác nhận.      │
└──────────────────────────────┘
```

**D\-06 — Cancellation unavailable**

```Plain Text
┌──────────────────────────────┐
│ Không thể hủy đơn            │
├──────────────────────────────┤
│ Đơn đã thanh toán 1.250.000 ₫│
│ nên không thể xử lý bằng hủy.│
│                              │
│ Nếu khách trả hoặc đổi hàng, │
│ hãy lập phiếu đổi/trả.       │
│                              │
│     [Tạo phiếu đổi/trả]      │
│             [Đóng]           │
└──────────────────────────────┘
```

**D\-07 — Processing/reconciliation**** \(không cần thiết\)**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chi tiết đơn hàng      ⋮  │
├──────────────────────────────┤
│ #DH-002586 · [Hoàn tất]      │
│ ⚠ Có trạng thái cần kiểm tra │
├──────────────────────────────┤
│ Kho              Đã tiếp nhận│
│ Công nợ          Đang xử lý  │
│ Hóa đơn điện tử  Cần đối soát│
│ Báo cáo          Đã tiếp nhận│
│                              │
│ Đơn hàng không bị hủy bởi    │
│ các trạng thái này.          │
├──────────────────────────────┤
│    [Kiểm tra trạng thái]     │
└──────────────────────────────┘
```

**D\-08 — Cancelled order**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chi tiết đơn hàng      ⋮  │
├──────────────────────────────┤
│ #DH-002410 · [Đã hủy]        │
│ [Chưa thanh toán]            │
├──────────────────────────────┤
│ Giao dịch gốc                │
│ Tổng đơn         850.000 ₫   │
│ Khách lẻ                     │
├──────────────────────────────┤
│ Lý do hủy                    │
│ Tạo nhầm đơn                 │
│ NV Minh · 18/07 09:05        │
│ Hoàn nguyên: Đã hoàn tất     │
│                              │
│       [Xem lịch sử hủy]      │
└──────────────────────────────┘
```

**D\-09 — Adjusted/returned order**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chi tiết đơn hàng      ⋮  │
├──────────────────────────────┤
│ #DH-002586 · [Hoàn tất]      │
│ [Đã điều chỉnh]              │
│ [Đã trả một phần]            │
├──────────────────────────────┤
│ Tóm tắt đổi/trả              │
│ Hàng trả          170.000 ₫  │
│ Hàng mới          290.000 ₫  │
│ Đã thu thêm       120.000 ₫  │
│                              │
│ [Xem phiếu đổi/trả]          │
│ [Xem lịch sử điều chỉnh]     │
└──────────────────────────────┘
```

**D\-10 — Loading/refreshing**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chi tiết đơn hàng         │
├──────────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒             │
├──────────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒             │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒             │
├──────────────────────────────┤
│       Đang tải dữ liệu…      │
└──────────────────────────────┘
```

**D\-11 — Error/stale**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chi tiết đơn hàng         │
├──────────────────────────────┤
│ Chưa tải được dữ liệu mới    │
│                              │
│ Nghiệp vụ vừa thực hiện có   │
│ thể đang được cập nhật.      │
│ Không thực hiện lại thao tác │
│ cho tới khi kiểm tra xong.   │
│                              │
│          [Thử lại]           │
│          [Quay lại]          │
└──────────────────────────────┘
```

**D\-12 — No permission/not found**

```Plain Text
┌──────────────────────────────┐
│ Không thể mở đơn hàng        │
├──────────────────────────────┤
│ Đơn hàng không tồn tại hoặc  │
│ anh không có quyền truy cập  │
│ trong phạm vi hiện tại.      │
│                              │
│          [Quay lại]          │
└──────────────────────────────┘
```

#### Visuals

TBD\.

#### Traceability

TBD\.

### 5\.5\.10 SG\-09 — Điều chỉnh thông tin ghi chú đơn

#### Overview

- Purpose: Cho phép người dùng tạo một OrderAdjustment cho metadata hỗ trợ vận hành thuộc adjustable field whitelist, đồng thời bảo toàn commercial snapshot và toàn bộ lịch sử giao dịch gốc\.

- Related epic: EP\-04 — Điều chỉnh thông tin đơn hàng sau bán\.

- Related business flow: BF\-06 — Điều chỉnh sau bán\.

- Business flow group: Post\-sale\.

- Primary users: Quản lý cửa hàng, chủ đơn vị và người dùng được cấp quyền điều chỉnh đơn hàng\.

- Primary task: Thay đổi một hoặc nhiều metadata hợp lệ, review before/after diff, cung cấp lý do và áp dụng adjustment an toàn\.

- Priority: P1\.

- Platform baseline: Mobile first\.

- Design intent: UI phải làm rõ ba lớp dữ liệu `Giá trị ban đầu tại checkout → Giá trị hiện hành → Giá trị đang đề xuất`, chỉ render field backend xác nhận được phép và không bao giờ ghi đè dữ liệu mới hơn một cách âm thầm\.

- Architectural role: SG\-09 là schema\-driven adjustment workspace\. Backend sở hữu eligibility/whitelist/validation authority; client sở hữu việc trình bày, nhập liệu, diff review và recovery an toàn\.

- Scope boundary: SG\-09 không chỉnh customer identity, buyer\-tax snapshot, store, seller, shift, transaction time, order code, SalesOrderLine, product/unit/quantity, price/discount/promotion/tax/rounding/total, settlement, payment/refund, receivable, inventory impact hoặc e\-invoice data\.

    

#### Entry \& exit

- Entry points:

    - Action `Điều chỉnh thông tin` từ SG\-08 — Chi tiết \& lịch sử đơn hàng\.

    - Action tạo adjustment mới từ một adjustment history item trong SG\-08, luôn dựa trên effective metadata mới nhất\.

    - Deep link nội bộ hợp lệ chứa tenant/store context, sales\_order\_id, source version hint và return route\.

    - Recovery từ một ApplyOrderAdjustment có kết quả chưa xác định, bằng operation/idempotency context\.

- Exit points:

    - Apply thành công → D\-09 hoặc D\-10, sau đó quay SG\-08 và refresh effective metadata, adjustment indicator, order list/search projection liên quan và timeline\.

    - Quay lại khi chưa thay đổi → SG\-08 ngay, không tạo OrderAdjustment\.

    - Quay lại khi có input chưa áp dụng → D\-06; xác nhận bỏ thay đổi mới thoát SG\-08\.

    - Precheck blocked/no permission → D\-02, sau đó về SG\-08 hoặc route xử lý phù hợp\.

    - Version/before\-value conflict → D\-11; tải authoritative state rồi sang D\-13 để chủ động lập change set mới\.

    - Policy/whitelist/reason drift → D\-12; chạy lại precheck và review lại toàn bộ\.

    - Commit result chưa xác định → D\-15; query authoritative result trước mọi retry hoặc exit có nguy cơ lặp command\.

        

#### Screen/state inventory

|State|Class|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|System state — Precheck loading|Kiểm tra eligibility, source version và field schema authoritative|—|Chưa tạo business record|
|D\-02|System state — Precheck blocked|Giải thích no permission, cancelled, locked, no\-fields hoặc policy unavailable|Quay lại / Thử lại|Không trả editable values khi không được phép|
|D\-03|Base screen — Edit ready|Hiển thị dynamic fields với current/original context|Nhập thay đổi|Pristine input state|
|D\-04|Base screen — Edit dirty|Quản lý một hoặc nhiều proposed values|Xem lại thay đổi|Chưa áp dụng vào order|
|D\-05|Validation state|Hiển thị field, cross\-field hoặc empty\-change\-set errors|Sửa thông tin|Không mất input|
|D\-06|Overlay — Discard confirmation|Ngăn mất proposed changes do back/close ngoài ý muốn|Bỏ thay đổi|Không áp dụng adjustment|
|D\-07|Review screen — Diff \& reason|Hiển thị toàn bộ change set và thu reason trước commit|Xác nhận điều chỉnh|Là điểm xác nhận cuối, không thêm modal lặp|
|D\-08|Processing state — Applying|Gửi ApplyOrderAdjustment với version/idempotency|—|Atomic, chặn double submit|
|D\-09|Result — Applied|Xác nhận authoritative OrderAdjustment result|Xem chi tiết đơn|Có ID, actor, reason và diff summary|
|D\-10|Result variant — Applied, projection syncing|Khẳng định commit thành công dù read projections chưa hội tụ|Xem chi tiết đơn|Không gửi lại command|
|D\-11|Conflict — Version/before value|Ngăn lost update khi effective metadata đã thay đổi|Tải dữ liệu mới|Không auto\-merge|
|D\-12|Conflict — Whitelist/reason/policy drift|Chặn request khi rule đã đổi|Kiểm tra lại|Toàn request không được áp dụng một phần|
|D\-13|Recovery workspace — Rebuild proposal|So sánh latest current với proposal cũ và lập change set mới có chủ đích|Xem lại lại|Proposal cũ chỉ là reference cục bộ|
|D\-14|Result — Known blocked/failed|Hiển thị kết quả chắc chắn không applied và hướng xử lý|Sửa lại / Quay lại|Không xuất hiện như applied history|
|D\-15|Recovery — Uncertain result|Khôi phục sau timeout/response loss|Kiểm tra kết quả|Không tạo idempotency key mới|



#### UI Contract

**Core data model**

- Mỗi editable field được biểu diễn bằng ba giá trị có vai trò khác nhau:

    - `Original value`: giá trị tại checkout/commercial snapshot, chỉ hiển thị khi có quyền và có ý nghĩa\.

    - `Current effective value`: baseline authoritative tại source version của precheck\.

    - `Proposed value`: input chưa áp dụng của người dùng trong flow hiện tại\.

- Change item chỉ tồn tại khi `Normalize(proposed) != Normalize(current)` theo field rule\.

- Before value gửi/review phải là current effective value của cùng source version, không phải original value\.

- Original value phục vụ truy vết; không được dùng làm baseline commit nếu effective value đã thay đổi\.

- Adjustment input state không phải business record, không phải current metadata và không được phát tán như dữ liệu đã lưu\.

    

**User intent**

- Biết đơn hiện có thể điều chỉnh hay không và trường nào thực sự được phép sửa\.

- Hiểu giá trị ban đầu, giá trị hiện hành và giá trị đang đề xuất mà không nhầm lẫn\.

- Cập nhật một hoặc nhiều metadata hỗ trợ vận hành trong cùng operation\.

- Nhìn thấy toàn bộ diff và giải trình lý do trước khi áp dụng\.

- Không ghi đè adjustment mới hơn của người khác\.

- Biết chắc adjustment đã applied, chưa applied hay chưa xác định kết quả\.

    

**Information hierarchy**

1. Order identity, eligibility và source freshness\.

2. Dynamic adjustable fields cùng current effective values\.

3. Dirty/validation state và change count\.

4. Before/after diff đầy đủ\.

5. Reason code, reason note và append\-only notice\.

6. Commit state/result hoặc conflict/recovery action\.

    

**Flow architecture**

|Step|User decision|System responsibility|Mutation status|
|---|---|---|---|
|Precheck|Mở flow|Xác minh scope, lifecycle, lock, version, permission và whitelist|Không mutation|
|Edit|Nhập proposed values|Normalize, validate và dựng input state|Chỉ local/session state|
|Review|Kiểm tra diff, chọn reason|Validate change set/reason trên cùng baseline|Chưa mutation|
|Apply|Xác nhận một lần|Revalidate authoritative state và commit atomically|Tạo OrderAdjustment nếu thành công|
|Result|Xem authoritative result|Phân biệt applied, blocked, conflict, failed, uncertain|Không gửi lại mù|



- Không dùng một confirmation modal chung sau D\-07; D\-07 đã chứa toàn bộ diff, reason và append\-only warning nên chính CTA `Xác nhận điều chỉnh` là explicit confirmation\.

- D\-06 chỉ dùng để xác nhận bỏ proposed changes, không dùng cho business commit\.

    

**Layout anatomy**

- Top bar:

    - Back action\.

    - Title `Điều chỉnh thông tin`\.

    - Official order code\.

    - Dirty status `Chưa áp dụng` khi có change item\.

- Scope/context area:

    - Order lifecycle/lock context ngắn gọn\.

    - Notice `Chỉ điều chỉnh thông tin hỗ trợ vận hành`\.

    - Action giải thích `Thông tin không thể điều chỉnh` khi hữu ích\.

- Dynamic form area:

    - Field groups theo metadata từ precheck\.

    - Current value; original value disclosure khi khác và có quyền\.

    - Help text, constraints, clear affordance và validation\.

- Review area:

    - Change count\.

    - Diff cards\.

    - Reason code/note\.

    - Append\-only notice\.

- Sticky action area:

    - Edit: `Xem lại N thay đổi`\.

    - Review: `Xác nhận điều chỉnh`\.

        

**Source\-of\-truth contract**

|Information|Source|Owner|SG\-09 rule|
|---|---|---|---|
|Eligibility/lifecycle/lock|PrecheckOrderAdjustment|Post\-sale Operations \+ Sales Order Lifecycle|Không suy luận từ SG\-08 projection|
|Adjustable fields|Adjustable field whitelist trong precheck|Tenant policy/Post\-sale Operations|Client không hard\-code field eligibility|
|Current effective values|Precheck authoritative context|Effective metadata chain|Là commit baseline|
|Original values|Checkout/commercial snapshot|SalesOrder|Chỉ phục vụ traceability|
|Field validation|Field schema/metadata|Policy/domain contract|Client hỗ trợ, backend quyết định|
|Reason options|Active reason catalog/policy|Post\-sale Operations/tenant policy|Revalidate khi apply|
|Applied result|ApplyOrderAdjustment result|Post\-sale Operations|Authoritative dù projection đang chậm|
|History|SalesOrderTimelineView/OrderAdjustment|Inquiry \+ Post\-sale Operations|Append\-only|



**Displayed data**

- Official order code và permitted contextual identity\.

- Lifecycle, lock state và source/effective metadata version ở mức cần thiết\.

- Precheck result/freshness khi blocked hoặc rule có thể stale\.

- Adjustable field definitions:

    - Stable field path dùng nội bộ\.

    - Localized label/help text\.

    - Control type\.

    - Current effective value\.

    - Original value khi được phép\.

    - Required/optional, clearable, max length, format, allowed values và normalization hint\.

    - Sensitivity/field\-level permission behavior\.

- Dirty field count và normalized diff\.

- Reason code options, reason\-note requirement và max length\.

- Adjustment result: ID, status, actor, applied time, reason và diff summary\.

- Conflict comparison: old baseline, latest current và previous proposal\.

    

**User inputs**

- Proposed value cho một hoặc nhiều field thuộc whitelist\.

- Explicit clear action khi field optional và rule cho phép xóa\.

- Reason code đang active và phù hợp\.

- Reason note khi reason code hoặc tenant policy yêu cầu\.

- Explicit confirmation tại D\-07\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG09\-E01|Top bar|`Điều chỉnh thông tin`|Giữ task/order context|D\-01 đến D\-15 khi permitted|
|SG09\-E02|Back action|`Quay lại`|Exit trực tiếp khi pristine; mở D\-06 khi dirty|Disabled trong critical commit window|
|SG09\-E03|Order identity|`Đơn #...`|Nhận diện source|Read\-only|
|SG09\-E04|Input\-state label|`Chưa áp dụng` · N thay đổi|Phân biệt proposal với saved data|D\-04/D\-05/D\-07|
|SG09\-E05|Scope notice|`Chỉ điều chỉnh thông tin hỗ trợ vận hành`|Giải thích boundary|D\-03/D\-04|
|SG09\-E06|Non\-adjustable explanation|`Thông tin không thể điều chỉnh`|Mở explanatory sheet|Khi hữu ích|
|SG09\-E07|Dynamic field group|Label · current · input · help|Render từ safe schema|D\-03/D\-04|
|SG09\-E08|Current\-value label|`Giá trị hiện hành`|Hiển thị commit baseline|Khi input control không tự thể hiện đủ|
|SG09\-E09|Original\-value disclosure|`Xem giá trị ban đầu`|Mở original snapshot|Current khác original \+ permission|
|SG09\-E10|Text input|Single/multiline metadata|Nhập và normalize theo rule|Renderer supported|
|SG09\-E11|Select input|Allowed values|Chọn option hợp lệ|Options từ schema|
|SG09\-E12|Tag/multi\-select|Internal tags|Add/remove, deduplicate theo policy|Field được whitelist|
|SG09\-E13|Clear action|`Xóa giá trị`|Tạo explicit empty proposal|Optional \+ clearable|
|SG09\-E14|Field help/counter|Format · max length · counter|Hỗ trợ nhập đúng|Theo schema|
|SG09\-E15|Field error|Error code/message|Gắn với field và focus|D\-05|
|SG09\-E16|Error summary|`Có N thông tin cần sửa`|Focus lỗi đầu tiên|Multiple errors|
|SG09\-E17|Review action|`Xem lại N thay đổi`|Normalize/validate và mở D\-07|Change set non\-empty|
|SG09\-E18|Diff card|Field · before · after · operation|Review full change set|D\-07|
|SG09\-E19|Reason selector|`Lý do điều chỉnh`|Chọn active reason code|D\-07, required|
|SG09\-E20|Reason\-note input|`Diễn giải bổ sung`|Nhập audit rationale|Required theo rule|
|SG09\-E21|Append\-only notice|`Điều chỉnh đã áp dụng không thể sửa hoặc xóa trực tiếp`|Nêu audit consequence|D\-07|
|SG09\-E22|Edit\-again action|`Sửa thông tin`|Trở D\-04 và giữ input/reason|D\-07|
|SG09\-E23|Apply action|`Xác nhận điều chỉnh`|Gửi ApplyOrderAdjustment|D\-07 valid/current|
|SG09\-E24|Processing indicator|`Đang áp dụng điều chỉnh…`|Phản ánh operation|D\-08|
|SG09\-E25|Success result|`Đã điều chỉnh thông tin đơn`|Hiển thị authoritative result|D\-09/D\-10|
|SG09\-E26|Detail action|`Xem chi tiết đơn`|Mở SG\-08 với operation context|D\-09/D\-10|
|SG09\-E27|New\-adjustment action|`Tạo điều chỉnh mới`|Chạy precheck từ latest current|D\-09, permission|
|SG09\-E28|Reload action|`Tải dữ liệu mới`|Re\-precheck authoritative state|D\-11/D\-12|
|SG09\-E29|Proposal comparison|Latest current · previous proposal|Hỗ trợ rebuild có chủ đích|D\-13|
|SG09\-E30|Reuse\-proposal action|`Dùng lại đề xuất`|Copy value thành input mới sau user action|Field vẫn adjustable|
|SG09\-E31|Use\-latest action|`Giữ giá trị mới nhất`|Không tạo change item cho field|D\-13|
|SG09\-E32|Discard action|`Bỏ thay đổi`|Bỏ input state và về SG\-08|D\-06|
|SG09\-E33|Check\-result action|`Kiểm tra kết quả`|Query operation/idempotency result|D\-15|
|SG09\-E34|Retry action|`Thử lại`|Retry precheck/read hoặc safe same\-context command|Theo state|



**Precheck behavior**

- SG\-09 gọi `PrecheckOrderAdjustment` trước khi render editable form\.

- Precheck xác minh tenant, membership, store scope, `sales.order.adjust`, official SalesOrder identity, lifecycle, lock status và source version hiện hành\.

- Chỉ official SalesOrder chưa cancelled được xem xét\.

- Order locked chỉ ready nếu tenant policy và permission đặc biệt cho phép\.

- Precheck trả whitelist, current effective values, original values được phép xem, field schema, reason context và blocker/next action\.

- Policy dependency unavailable không được coi là ready; dùng D\-02 với retry\.

- Precheck không tạo OrderAdjustment, domain event, payment transaction hoặc impact request\.

- Precheck result được validate lại tại apply; client không biến `ready` thành guarantee\.

    

**Schema\-driven rendering behavior**

- Eligibility của field hoàn toàn theo whitelist response; client không biến field đang hiển thị ở SG\-08 thành editable\.

- Client dùng registry các renderer an toàn đã hỗ trợ, ví dụ text, multiline text, select và multi\-select/tag\.

- Unknown/unsupported control type không fallback thành raw text hoặc JSON editor; field được chặn an toàn và flow chỉ tiếp tục nếu policy cho phép bỏ field đó\.

- Stable field path không dùng làm user\-facing label; label/help được localization\-aware\.

- Validation metadata không được dùng để thực thi code động từ server\.

- Sensitive field chỉ xuất hiện khi người dùng vừa có quyền xem vừa có quyền điều chỉnh\.

- Client không cho phép arbitrary field path injection vào change set\.

    

**Phase\-1 adjustable fields**

- Các nhóm field tối thiểu có thể được hỗ trợ khi xuất hiện trong whitelist:

    - Ghi chú nội bộ\.

    - Mã tham chiếu bên ngoài\.

    - Tag/nhãn nội bộ\.

    - Metadata phi thương mại khác được tenant policy mô tả rõ và renderer hỗ trợ\.

- Việc liệt kê nhóm field trong tài liệu không làm field trở thành editable nếu precheck không trả về\.

- Tạo tag mới chỉ khả dụng khi field metadata và permission tương ứng cho phép; mặc định chỉ chọn allowed values\.

    

**Non\-adjustable boundary**

- Không render dưới dạng input: customer\_partner\_id, customer snapshot, buyer\-tax snapshot, store, seller, shift, transaction time hoặc order code\.

- Không render dưới dạng input: SalesOrderLine, product/SKU, ProductUnit, quantity, unit price, source price, discount, promotion, tax, rounding hoặc order total\.

- Không render dưới dạng input: settlement, payment, void, refund, receivable, inventory impact hoặc e\-invoice reference/status\.

- Nếu người dùng muốn thay đổi hàng hóa hoặc giá trị giao dịch, explanation hướng về SG\-08 để chọn hủy hoặc đổi/trả theo điều kiện; không giả lập bằng metadata\.

- Request có bất kỳ field cấm/không còn whitelist phải bị backend từ chối toàn bộ; field hợp lệ khác không được áp dụng một phần\.

    

**Input\-state behavior**

- Input state bắt đầu từ current effective value của source version được precheck\.

- Thay đổi được giữ trong client/session navigation state trong flow; không gọi là draft nghiệp vụ hoặc dữ liệu đã lưu\.

- Reload/app termination có thể làm mất input state trừ khi sản phẩm có cơ chế local recovery được phê duyệt; không hứa auto\-save server ngoài SRS\.

- Dirty state dựa trên normalized proposed/current values, không chỉ dựa trên keystroke\.

- Back khi dirty mở D\-06; back khi pristine về SG\-08 trực tiếp\.

- Hủy flow bỏ input state, không tạo audit activity `applied` và không thay effective metadata\.

    

**Normalization and validation behavior**

- Validation có bốn lớp:

    - Control\-level: type, required, length, format và allowed values\.

    - Normalization: trim/canonicalize/deduplicate theo field contract\.

    - Change\-set: proposed khác current và không chứa field cấm\.

    - Apply\-time: authoritative permission, lifecycle, lock, whitelist, source version, before values và reason\.

- Text chỉ có khoảng trắng được normalize thành empty hoặc current\-equivalent theo field rule\.

- External reference normalization không tự thay đổi ý nghĩa hoặc tạo mã mới\.

- Tag duplicate được deduplicate theo policy và không tạo diff giả\.

- Optional field chỉ được clear nếu `clearable = true`; dùng explicit `Xóa giá trị` để tránh nhầm empty input với chưa tải\.

- Field normalized về current value bị loại khỏi change set\.

- Nếu mọi field bị loại, CTA review disabled và D\-05 giải thích `Chưa có thay đổi thực sự`\.

- Client validation phục vụ feedback nhanh; backend validation là authoritative\.

    

**Diff\-generation behavior**

- D\-07 chỉ chứa field thực sự thay đổi sau normalization\.

- Mỗi diff item hiển thị label, before value, after value và operation `Cập nhật`, `Thêm` hoặc `Xóa`\.

- Before value là current effective value cùng source version; original value chỉ mở qua disclosure riêng\.

- Null/empty before hiển thị `Chưa có thông tin`, không hiển thị literal `null`\.

- Valid empty after hiển thị `Đã xóa`, không để ô trắng gây hiểu nhầm\.

- Giá trị dài có expand/collapse nhưng review toàn bộ vẫn accessible\.

- Không có hidden field được tự thêm sau khi user vào review; change count và payload phải khớp\.

- Sensitive diff được mask hoặc field không được phép chỉnh ngay từ precheck\.

    

**Reason behavior**

- Reason được chọn tại D\-07 sau khi người dùng nhìn thấy toàn bộ diff, vì reason giải thích change set chứ không chỉ một input\.

- `reason_code` bắt buộc và phải active/phù hợp tại apply time\.

- Reason note optional mặc định, bắt buộc khi code là `OTHER/Khác` hoặc tenant policy yêu cầu\.

- Reason note được trim và validate max length; whitespace\-only được coi là empty\.

- Reason và diff hiển thị cùng review context\.

- Khi quay lại edit, reason được giữ trong flow; nếu change set đổi đáng kể, reason vẫn phải được review lại\.

- Reason catalog drift chuyển D\-12 và yêu cầu chọn lại, không silently map code\.

    

**Review and confirmation behavior**

- D\-07 là explicit final review và confirmation surface\.

- Hiển thị order identity, source freshness, change count, toàn bộ diff, reason và append\-only notice\.

- CTA chỉ enabled khi change set non\-empty, mọi field hợp lệ, reason hợp lệ và precheck context chưa được biết là stale\.

- `Sửa thông tin` giữ inputs/reason và quay D\-04\.

- Không dùng checkbox `Tôi đồng ý` nếu không có legal/policy requirement; explicit CTA cùng review đầy đủ là đủ\.

- Không dùng generic modal `Bạn có chắc không?` vì không thêm thông tin quyết định mới\.

    

**Apply and atomicity behavior**

- Apply gửi sales\_order\_id, source version, before values/change set, reason, actor context và idempotency key\.

- Backend revalidate tenant, store scope, membership, permission, lifecycle, lock, whitelist, validation, source version, before values và reason\.

- Multi\-field request được áp dụng atomically: tất cả field applied hoặc không field nào applied\.

- Thành công tạo đúng một OrderAdjustment status `applied`, lưu diff, actor, reason, source version và applied time\.

- Phát `OrderAdjustmentApplied` qua reliable event/outbox pattern của domain\.

- Cập nhật effective metadata/order detail/order list/search/timeline/reporting phi tài chính qua projection phù hợp\.

- Không sửa commercial snapshot và không tạo payment/refund/receivable/inventory/e\-invoice impact\.

    

**Idempotency behavior**

- Apply bắt buộc có idempotency key gắn với payload canonical\.

- Double tap khóa CTA ngay phía client; backend vẫn phải chống trùng\.

- Cùng key \+ cùng payload trả cùng OrderAdjustment result\.

- Cùng key \+ payload khác trả idempotency conflict; không tạo adjustment mới\.

- Retry sau response loss dùng cùng key/context, không sinh key mới do refresh\.

- Navigation về SG\-08 khi result uncertain phải giữ recovery reference hoặc cảnh báo rõ; không cho action lặp mù\.

    

**Concurrency and conflict behavior**

- Source version và before values đều được kiểm tra để chống lost update\.

- Version/before\-value mismatch trả D\-11; không last\-write\-wins và không auto\-merge\.

- D\-11 phải nói rõ request chưa được áp dụng\.

- `Tải dữ liệu mới` chạy lại precheck và chuyển D\-13 nếu vẫn eligible\.

- D\-13 trình bày `Giá trị mới nhất` và `Đề xuất trước đó` theo field; proposal cũ chỉ là local reference\.

- `Dùng lại đề xuất` là hành động explicit tạo proposed value mới trên baseline mới; không tự áp dụng hoặc tự tick sẵn\.

- `Giữ giá trị mới nhất` loại field khỏi change set mới\.

- Sau rebuild, người dùng phải review lại diff/reason và xác nhận bằng operation/idempotency context mới phù hợp\.

- Nếu field không còn whitelist, proposal được trình bày read\-only/masked theo permission và không thể đưa vào change set mới\.

    

**Policy and whitelist drift behavior**

- Field bị loại whitelist, permission bị thu hồi, reason code inactive hoặc lock policy đổi trước commit làm toàn request blocked\.

- Không áp dụng các field còn hợp lệ như partial success\.

- D\-12 liệt kê rule đã thay đổi ở mức an toàn và cho `Kiểm tra lại`\.

- Sau re\-precheck, form chỉ render fields hiện còn eligible; field cũ không bị silently dropped khỏi nhận thức của người dùng nếu họ đã đề xuất thay đổi\.

- Nếu không còn field adjustable, chuyển D\-02 thay vì form rỗng\.

    

**Known blocked/failed behavior**

- D\-14 dùng khi backend xác định chắc chắn request không applied\.

- Phân biệt `Blocked` do business/policy với `Failed` do technical failure đã xác định\.

- Blocked cung cấp next action phù hợp: tải lại, xin quyền, chờ unlock, về chi tiết đơn hoặc chọn nghiệp vụ khác\.

- Known technical failure trước commit có thể retry khi precheck/version còn hợp lệ; nếu không chắc đã commit thì phải dùng D\-15\.

- Blocked/failed không cập nhật effective metadata và không xuất hiện như applied timeline activity\.

    

**Uncertain\-result recovery behavior**

- Timeout, disconnect hoặc response loss sau submit không được trình bày là failed\.

- D\-15 giữ operation/idempotency context và gọi query/check result trước retry\.

- Nếu result là applied, mở D\-09/D\-10 bằng authoritative OrderAdjustment\.

- Nếu result là blocked/failed chắc chắn, mở D\-14\.

- Nếu operation còn processing, tiếp tục polling có giới hạn hoặc cho người dùng kiểm tra sau\.

- Chỉ khi backend xác nhận chưa commit mới cho retry cùng idempotency context\.

    

**Success and projection\-sync behavior**

- D\-09 chỉ xuất hiện khi command result xác nhận OrderAdjustment status `applied`\.

- Hiển thị adjustment ID, actor, time, reason và các field đã thay đổi; không chỉ hiển thị toast\.

- D\-10 dùng khi adjustment applied nhưng effective metadata/timeline/search projection chưa hội tụ\.

- Wording: `Đã điều chỉnh thông tin đơn — dữ liệu hiển thị đang cập nhật`; không gửi lại ApplyOrderAdjustment\.

- `Xem chi tiết đơn` truyền operation result/correlation context để SG\-08 có thể hiển thị post\-command syncing đúng\.

- `Tạo điều chỉnh mới` luôn chạy precheck mới từ effective current state; không sửa applied record cũ\.

- Đưa giá trị về trước đó là một adjustment mới, không phải undo/delete history\.

    

**Business rules and invariants**

- Mỗi OrderAdjustment liên kết đúng một official SalesOrder chưa cancelled tại apply time\.

- Field path phải thuộc whitelist tại precheck và apply\.

- Một request chứa field cấm bị reject toàn bộ\.

- Change set phải non\-empty sau normalization\.

- Multi\-field adjustment là atomic\.

- Applied adjustment là append\-only, không sửa/xóa/reopen để undo\.

- Effective metadata truy được original value và toàn bộ adjustment chain\.

- Commercial snapshot không bị overwrite\.

- Reason, actor, source version, before/after values và applied time là audit context bắt buộc\.

- SG\-09 không tạo tác động tài chính, công nợ, tồn kho hoặc hóa đơn điện tử\.

- Exit trước apply không thay đổi SalesOrder\.

    

**Permissions**

- `sales.order.view`: xem permitted order context\.

- `sales.order.adjust`: mở SG\-09, precheck và apply\.

- Field\-level permission/policy: giới hạn subset whitelist và sensitive values\.

- `sales.order.history.view`: xem adjustment history/diff sau apply\.

- Quyền xem original metadata: mở original\-value disclosure khi policy tách riêng\.

- Quyền xem reason/sensitive diff: xem audit detail tương ứng\.

- Không có permission adjustment → D\-02; không trả/render editable field definitions hoặc values\.

- Permission bị thu hồi sau review → backend block toàn request và mở D\-12/D\-14 phù hợp\.

    

**Loading, empty and error behavior**

- D\-01 dùng skeleton cho identity và field groups; không flash field từ whitelist cache cũ như editable\.

- Không có field adjustable → D\-02 với message riêng, không hiển thị empty form\.

- Policy dependency unavailable → `Chưa thể kiểm tra điều kiện`, không mặc định ready/blocked vĩnh viễn\.

- Field schema/renderer unsupported → safe blocker, không render raw fallback\.

- Validation error không xóa input hoặc reason\.

- Precheck/read retry không tái sử dụng response của sales\_order\_id khác\.

- Error summary focus lỗi đầu tiên; field error ở sát control\.

    

**Feedback and microcopy**

- Dùng `Điều chỉnh thông tin`, không dùng `Sửa đơn hàng` vì dễ hiểu là sửa giao dịch gốc\.

- Dùng `Chưa áp dụng`, không dùng `Đã lưu nháp` nếu chưa có server\-side draft\.

- Dùng `Giá trị hiện hành`, `Giá trị ban đầu` và `Đề xuất của anh` nhất quán\.

- Clear value hiển thị `Đã xóa`, không dùng dấu gạch ngang mơ hồ\.

- Conflict nói rõ `Yêu cầu chưa được áp dụng` trước khi hướng dẫn reload\.

- Success nói rõ `Giao dịch gốc được giữ nguyên` khi cần củng cố mental model\.

- Không toast lặp lại success khi đã có full result state\.

    

**Accessibility**

- Dynamic field label, current value, help, constraint và error được liên kết semantic\.

- Original/current/proposed không chỉ phân biệt bằng màu, strikethrough hoặc vị trí\.

- Diff đọc theo thứ tự field → operation → before → after\.

- Error summary có link/focus tới từng field\.

- Tag control hỗ trợ keyboard add/remove và công bố duplicate normalization\.

- Discard overlay trap focus và trả focus về back action khi đóng\.

- Processing được announce một lần; không lặp spinner message liên tục\.

- Conflict comparison có row/column headers semantic trên viewport rộng và stacked labels trên mobile\.

    

**Responsive behavior**

- Mobile: một cột, field group stacked, original disclosure inline, sticky review/apply CTA\.

- Mobile review: mỗi diff là card `Trước/Sau`; không dùng table ngang\.

- Tablet/web: form có guidance rail; review/conflict có thể dùng comparison grid\.

- Keyboard không che active field, error, reason note hoặc sticky CTA\.

- Long textarea mở rộng có giới hạn; CTA vẫn reachable mà không che content\.

- Whitelist, validation, atomicity và confirmation semantics không đổi theo viewport\.

    

#### Low\-fi wireframes

**D\-01 — Precheck loading**** \(không cần thiết\)**

```Plain Text
┌──────────────────────────────┐
│ ‹  Điều chỉnh thông tin      │
│ Đơn #DH-002586               │
├──────────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒       │
│ ▒▒▒▒▒▒▒▒▒▒▒▒                │
│                              │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒       │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒              │
│                              │
│ Đang kiểm tra thông tin có   │
│ thể điều chỉnh…              │
└──────────────────────────────┘
```



**D\-02 — Precheck blocked**

```Plain Text
┌──────────────────────────────┐
│ Không thể điều chỉnh         │
├──────────────────────────────┤
│ Đơn #DH-002586 đang bị khóa  │
│ theo chính sách hiện hành.   │
│                              │
│ Không có thông tin nào được  │
│ mở để chỉnh sửa.             │
│                              │
│ [Quay lại]        [Thử lại]  │
└──────────────────────────────┘
```



**D\-03 — Edit ready/pristine**

```Plain Text
┌──────────────────────────────┐
│ ‹  Điều chỉnh thông tin      │
│ Đơn #DH-002586               │
├──────────────────────────────┤
│ ℹ Chỉ điều chỉnh thông tin   │
│   hỗ trợ vận hành.           │
│ [Thông tin không thể sửa ›]  │
├──────────────────────────────┤
│ Ghi chú nội bộ               │
│ Giá trị hiện hành            │
│ Giao hàng buổi chiều         │
│ [Giao hàng buổi chiều      ] │
│                              │
│ Mã tham chiếu bên ngoài      │
│ [WEB-98421                 ] │
│                              │
│ Nhãn nội bộ                  │
│ [Ưu tiên ×] [+ Chọn nhãn]    │
├──────────────────────────────┤
│      [Xem lại thay đổi]      │
└──────────────────────────────┘
```



**D\-04 — Edit dirty**

```Plain Text
┌──────────────────────────────┐
│ ‹  Điều chỉnh thông tin      │
│ Chưa áp dụng · 2 thay đổi    │
├──────────────────────────────┤
│ Ghi chú nội bộ               │
│ [Giao trước 16:00          ] │
│ Đã thay đổi                  │
│ [Xem giá trị ban đầu ›]      │
│                              │
│ Mã tham chiếu bên ngoài      │
│ [WEB-98421-A               ] │
│ Đã thay đổi                  │
│                              │
│ Nhãn nội bộ                  │
│ [Ưu tiên ×] [Xóa giá trị]    │
├──────────────────────────────┤
│    [Xem lại 2 thay đổi]      │
└──────────────────────────────┘
```



**D\-05 — Validation state**

```Plain Text
┌──────────────────────────────┐
│ ‹  Điều chỉnh thông tin      │
├──────────────────────────────┤
│ ⚠ Có 2 thông tin cần sửa     │
│ [Tới lỗi đầu tiên]           │
├──────────────────────────────┤
│ Mã tham chiếu bên ngoài      │
│ [WEB/98421???????????????? ] │
│ Không đúng định dạng · 24/20 │
│                              │
│ Nhãn nội bộ                  │
│ [Ưu tiên] [Ưu tiên]          │
│ Nhãn bị trùng                │
├──────────────────────────────┤
│      [Xem lại thay đổi]      │
└──────────────────────────────┘
```



**D\-06 — Discard confirmation**

```Plain Text
┌──────────────────────────────┐
│ Bỏ các thay đổi?             │
├──────────────────────────────┤
│ 2 đề xuất chưa được áp dụng. │
│ Nếu rời đi, nội dung vừa nhập│
│ sẽ không thay đổi đơn hàng.  │
│                              │
│ [Tiếp tục chỉnh]             │
│ [Bỏ thay đổi]                │
└──────────────────────────────┘
```



**D\-07 — Diff, reason and final confirmation**

```Plain Text
┌──────────────────────────────┐
│ ‹  Xem lại 2 thay đổi        │
│ Đơn #DH-002586               │
├──────────────────────────────┤
│ GHI CHÚ NỘI BỘ · Cập nhật   │
│ Trước: Giao buổi chiều       │
│ Sau:   Giao trước 16:00      │
│                              │
│ MÃ THAM CHIẾU · Cập nhật    │
│ Trước: WEB-98421             │
│ Sau:   WEB-98421-A           │
├──────────────────────────────┤
│ Lý do điều chỉnh *           │
│ [Sai thông tin vận hành   ▾] │
│ Diễn giải bổ sung            │
│ [Khách xác nhận lại giờ giao]│
├──────────────────────────────┤
│ ℹ Điều chỉnh đã áp dụng không│
│   thể sửa hoặc xóa trực tiếp.│
│ [Sửa thông tin]              │
│ [Xác nhận điều chỉnh]        │
└──────────────────────────────┘
```



**D\-08 — Applying**** \(không cần thiết\)**

```Plain Text
┌──────────────────────────────┐
│                              │
│              ◌               │
│ Đang áp dụng điều chỉnh…     │
│                              │
│ Thay đổi được xử lý cùng lúc.│
│ Không gửi lại yêu cầu trong  │
│ khi kết quả đang được ghi nhận│
│                              │
└──────────────────────────────┘
```



**D\-09 — Applied result**

```Plain Text
┌──────────────────────────────┐
│              ✓               │
│ Đã điều chỉnh thông tin đơn  │
├──────────────────────────────┤
│ Đơn #DH-002586               │
│ Điều chỉnh #ADJ-00042        │
│ NV Minh · 20/07 10:15        │
│ Lý do: Sai thông tin vận hành│
│                              │
│ 2 trường đã được thay đổi    │
│ Giao dịch gốc được giữ nguyên│
├──────────────────────────────┤
│ [Tạo điều chỉnh mới]         │
│ [Xem chi tiết đơn]           │
└──────────────────────────────┘
```



**D\-10 — Applied, projection syncing**** \(không cần thiết, từ D\-10 này trở đi các state dưới chỉ cần ở dạng toast, không cần là 1 màn hình riêng\)**

```Plain Text
┌──────────────────────────────┐
│ ✓ Điều chỉnh đã được áp dụng │
├──────────────────────────────┤
│ #ADJ-00042                   │
│ Dữ liệu hiển thị của đơn và  │
│ timeline đang cập nhật.      │
│                              │
│ Không gửi lại điều chỉnh này.│
│                              │
│ [Kiểm tra cập nhật]          │
│ [Xem chi tiết đơn]           │
└──────────────────────────────┘
```



**D\-11 — Version/before\-value conflict**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Dữ liệu đã thay đổi        │
├──────────────────────────────┤
│ Yêu cầu chưa được áp dụng.   │
│ Một người khác đã cập nhật   │
│ thông tin sau khi anh mở form│
│                              │
│ Hệ thống không tự gộp hoặc   │
│ ghi đè giá trị mới hơn.      │
│                              │
│ [Quay lại] [Tải dữ liệu mới] │
└──────────────────────────────┘
```



**D\-12 — Whitelist/reason/policy drift**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Điều kiện đã thay đổi      │
├──────────────────────────────┤
│ Yêu cầu chưa được áp dụng.   │
│                              │
│ • “Nhãn nội bộ” không còn    │
│   được phép điều chỉnh.      │
│ • Lý do đã chọn không còn    │
│   hiệu lực.                  │
│                              │
│ [Quay lại]    [Kiểm tra lại] │
└──────────────────────────────┘
```



**D\-13 — Rebuild proposal explicitly**

```Plain Text
┌──────────────────────────────┐
│ ‹  Lập lại thay đổi          │
├──────────────────────────────┤
│ GHI CHÚ NỘI BỘ              │
│ Giá trị mới nhất             │
│ Giao sau 15:00               │
│                              │
│ Đề xuất trước đó             │
│ Giao trước 16:00             │
│                              │
│ [Giữ giá trị mới nhất]       │
│ [Dùng lại đề xuất]           │
├──────────────────────────────┤
│ Đề xuất cũ chưa tự động được │
│ đưa vào yêu cầu mới.         │
└──────────────────────────────┘
```



**D\-14 — Known blocked/failed result**

```Plain Text
┌──────────────────────────────┐
│ Không áp dụng điều chỉnh     │
├──────────────────────────────┤
│ Đơn đã bị khóa trước khi yêu │
│ cầu được xác nhận.           │
│                              │
│ Không trường nào được thay đổi│
│ và không có adjustment applied│
│                              │
│ [Về chi tiết đơn] [Thử lại]  │
└──────────────────────────────┘
```



**D\-15 — Uncertain\-result recovery**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Đang kiểm tra kết quả      │
├──────────────────────────────┤
│ Kết nối bị gián đoạn sau khi │
│ gửi yêu cầu điều chỉnh.      │
│                              │
│ Không tạo yêu cầu mới cho tới│
│ khi xác định được kết quả.   │
│                              │
│ [Về chi tiết đơn]            │
│ [Kiểm tra kết quả]           │
└──────────────────────────────┘
```



#### Visuals

TBD\.



#### Traceability

TBD\.

### 5\.5\.11 SG\-10 — Hủy đơn hàng

#### Overview

- Purpose: Cho phép người dùng hủy toàn bộ một official SalesOrder đã hoàn tất khi không còn tiền thực thu ròng cần hoàn, đồng thời bảo toàn giao dịch gốc và theo dõi các tác động hoàn nguyên\.

- Related epic: EP\-05 — Hủy đơn hàng sau bán\.

- Related business flow: BF\-07 — Hủy đơn\.

- Business flow group: Post\-sale\.

- Primary users: Quản lý cửa hàng, chủ đơn vị và người dùng được cấp quyền hủy đơn; kế toán/người kiểm soát xem kết quả và tác động\.

- Primary task: Kiểm tra eligibility/tác động, chọn lý do, xác nhận hủy toàn bộ và theo dõi kết quả hoàn nguyên\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: SG\-10 là một destructive decision flow\. UI phải phân biệt rõ `đủ điều kiện hủy`, `phải chuyển sang đổi/trả`, `chưa thể quyết định` và `đã có operation cạnh tranh`; sau commit phải tách cancellation decision, order lifecycle và downstream impact status\.

- Architectural role: SG\-10 điều phối precheck và user confirmation\. Post\-sale Operations sở hữu cancellation decision; Sales Order Lifecycle sở hữu trạng thái cancelled; các domain đích sở hữu hoàn nguyên tương ứng\.

- Scope boundary: SG\-10 không hoàn tiền đã thu, không đưa ra refund treatment/payment method, không sửa transaction gốc và không trực tiếp sửa receivable ledger, stock movement, pricing commitment hoặc e\-invoice\. Đơn có `net_confirmed_collection > 0` phải chuyển sang SG\-11 với `full_return_from_cancel_attempt`\.

    

#### Entry \& exit

- Entry points:

    - Action `Hủy đơn` từ SG\-08 — Chi tiết \& lịch sử đơn hàng\.

    - Deep link nội bộ hợp lệ tới cancellation operation/result của một SalesOrder\.

    - Resume một SalesOrderCancellation đang `requested`, `validating`, `confirmed` hoặc `processing`\.

    - Recovery sau timeout/reconnect bằng cancellation ID, operation reference hoặc idempotency context\.

- Exit points:

    - Precheck xác định còn tiền thực thu ròng → SG\-11 với source order và `entry_mode = full_return_from_cancel_attempt`\.

    - Có ReturnExchangeOrder draft → SG\-11 để tiếp tục/hủy/resolve draft trước khi quay lại SG\-10\.

    - Có ReturnExchangeOrder confirmed/processing/completed → SG\-13 hoặc result tương ứng; không tạo cancellation\.

    - Cancellation confirmed nhưng lifecycle đang xử lý → D\-10; sau đó D\-11 khi order authoritative là cancelled\.

    - Order đã cancelled → D\-11/D\-12 hoặc SG\-08 cancelled variant\.

    - Hủy/quay lại trước confirmation → SG\-08; không tạo cancellation hay impact chính thức\.

    - Version/settlement/precheck stale → D\-13; chạy lại precheck trước khi xác nhận\.

    - Confirmation result uncertain → D\-15; query authoritative result trước khi retry hoặc tạo operation khác\.

        

#### Screen/state inventory

|State|Class|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|System state — Precheck loading|Kiểm tra authoritative eligibility, settlement, conflicts và impacts|—|Chưa tạo cancellation/impact|
|D\-02|Decision screen — Ready|Hiển thị điều kiện đủ và impact preview|Tiếp tục hủy|`net_confirmed_collection = 0`|
|D\-03|Decision screen — Warning|Hiển thị warning không chặn cần xử lý/acknowledge|Vẫn tiếp tục|Không bypass hard blocker|
|D\-04|Redirect — Payment collected|Chặn cancellation và chuyển sang full return|Trả toàn bộ \& hoàn tiền|SG\-10 không refund|
|D\-05|Blocked — Competing operation|Chặn do cancellation hoặc return/exchange đang tồn tại|Mở operation hiện có|Không tạo record cạnh tranh|
|D\-06|Blocked — Uncertain dependency|Chưa thể kết luận do settlement/inventory/e\-invoice/policy chưa xác định|Kiểm tra trạng thái|Không giả định safe|
|D\-07|Form — Cancellation reason|Chọn reason code và nhập explanation khi cần|Xem lại yêu cầu|Precheck context được giữ|
|D\-08|Review — Destructive confirmation|Review order, settlement assertion, reason và impacts|Hủy đơn hàng|Điểm xác nhận cuối|
|D\-09|Processing — Confirmation|Gửi ConfirmSalesOrderCancellation|—|Chống double submit|
|D\-10|Processing — Cancellation confirmed, lifecycle pending|Cho biết decision đã ghi nhận nhưng order chưa authoritative cancelled|Kiểm tra trạng thái|Không tạo cancellation mới|
|D\-11|Result — Order cancelled|Xác nhận lifecycle cancelled và hiển thị cancellation summary|Xem chi tiết đơn|Order không thể mở lại|
|D\-12|Result/subview — Impact status|Theo dõi Receivable, Inventory, Pricing, E\-invoice và Reporting|Xử lý trạng thái|Tách business/delivery status|
|D\-13|Conflict — Stale/version changed|Chặn do order/settlement/reason/impact context thay đổi|Kiểm tra lại|Không auto\-merge|
|D\-14|Result — Known blocked/failed|Hiển thị confirmation chắc chắn không tạo cancellation hoặc chưa hủy lifecycle|Xử lý blocker|Có thể redirect SG\-11|
|D\-15|Recovery — Uncertain result|Khôi phục sau timeout/response loss|Kiểm tra kết quả|Dùng cùng idempotency context|
|D\-16|System state — No permission/not found|Bảo vệ tenant/store scope và không tiết lộ dữ liệu|Quay lại|Neutral disclosure|



#### UI Contract

**Core decision model**

SG\-10 không bắt đầu bằng form lý do; luôn bắt đầu bằng authoritative precheck\.

Decision order:

1. Xác minh tenant, membership, store scope và permission\.

2. Xác minh official SalesOrder lifecycle, lock, cancellation window và source version\.

3. Resolve SalesOrderCancellation/ReturnExchangeOrder đang tồn tại\.

4. Lấy Sales Settlement authoritative và xác định net confirmed collection\.

5. Xác định reversibility/impact context\.

6. Chỉ khi `ready` hoặc warning được phép mới cho nhập reason và review\.

    

- Không đưa người dùng vào destructive confirmation khi một dependency bắt buộc còn `uncertain`\.

- Precheck result là snapshot quyết định có version/reference; apply time vẫn phải revalidate\.

    

**User intent**

- Biết đơn có thực sự được phép hủy bằng cancellation hay phải dùng đổi/trả\.

- Hiểu khoản phải thu chưa thu, tồn kho, pricing và chứng từ nào dự kiến được hoàn nguyên\.

- Biết warning nào có thể chấp nhận và blocker nào phải xử lý trước\.

- Cung cấp lý do hủy đủ rõ cho audit\.

- Xác nhận hủy toàn bộ một cách có chủ đích, không double submit\.

- Biết order đã cancelled hay cancellation vẫn đang processing\.

- Theo dõi downstream impact mà không nhầm failure với việc order được mở lại\.

    

**Information hierarchy**

1. Order identity và precheck decision `Ready / Warning / Blocked / Uncertain`\.

2. Settlement assertion và net confirmed collection\.

3. Competing operation/blocker hoặc impact preview\.

4. Reason code/note\.

5. Destructive consequence và immutable history statement\.

6. Cancellation/lifecycle result\.

7. Downstream business/delivery/reconciliation status\.

    

**Flow architecture**

|Stage|User decision|System responsibility|Business mutation|
|---|---|---|---|
|Precheck|Mở flow|Xác minh order, settlement, conflicts và impacts|Không|
|Decision|Tiếp tục, redirect hoặc xử lý blocker|Giải thích đúng next\-best action|Không|
|Reason|Chọn căn cứ hủy|Validate reason theo precheck context|Không|
|Review|Xác nhận destructive consequence|Revalidate context và dựng canonical payload|Chưa, cho tới CTA|
|Confirm|Hủy đơn hàng|Commit cancellation decision và durable impacts; điều phối lifecycle|Có|
|Result|Xem lifecycle/impacts|Phân biệt cancelled, processing, failed, uncertain|Không gửi lại mù|



- D\-08 là final confirmation surface; không thêm generic modal `Bạn có chắc không?` sau đó\.

- D\-08 phải cung cấp đủ thông tin quyết định: order, total, settlement assertion, reason, impact preview và consequence\.

    

**Source\-of\-truth contract**

|Information|Source|Authoritative owner|SG\-10 rule|
|---|---|---|---|
|Order lifecycle/version/lock|SalesOrder authoritative context|Sales Order Lifecycle|Không chỉ dựa SG\-08 projection|
|Settlement eligibility|GetSalesOrderSettlement trong precheck/confirm|Sales Settlement|UI không tự tính từ rows lịch sử|
|Related cancellation|GetSalesOrderCancellation|Post\-sale Operations|Resume/open existing operation|
|Return/exchange conflicts|GetReturnExchangeOrdersBySalesOrder|Post\-sale Operations|Không tạo operation cạnh tranh|
|Impact preview|CancellationImpactSummary|Domain orchestration/policies|`Dự kiến`, chưa phải completed impact|
|Cancellation result|Confirm/GetSalesOrderCancellation|Post\-sale Operations|Decision authoritative|
|Order cancelled result|SalesOrder lifecycle/GetSalesOrderDetail|Sales Order Lifecycle|Chỉ gắn `Đã hủy` khi lifecycle cancelled|
|Downstream status|Impact/command status|Theme 4/6/7/8/10|Tách business và delivery status|



**Displayed data**

- Official order code, lifecycle, lock và expected/source version context\.

- Customer snapshot hoặc `Khách lẻ`, store, completion time và official total\.

- Settlement summary đủ quyền: confirmed collection, confirmed refund, confirmed void và net confirmed collection\.

- Settlement checked time/version hoặc precheck freshness reference ở dạng user\-appropriate\.

- Related SalesOrderCancellation/ReturnExchangeOrder conflict summary\.

- Cancellation eligibility, blocker codes/messages, warnings và next actions\.

- Impact preview:

    - Outstanding receivable chưa thu dự kiến giảm/đảo\.

    - Inventory lines/quantity hoặc impact summary dự kiến\.

    - Applied pricing commitment cần đảo hay `Không yêu cầu`\.

    - E\-invoice/chứng từ cần xử lý hay `Không yêu cầu`\.

    - Reporting impact\.

- Reason code options và reason note policy\.

- Cancellation ID/status, actor, reason, confirmation time và order lifecycle result\.

- Mỗi downstream target: business status, delivery status, updated time, safe failure summary và reconciliation state\.

    

**User inputs**

- Warning acknowledgement khi tenant policy yêu cầu\.

- Reason code đang active và phù hợp\.

- Reason note khi reason code là `Khác` hoặc tenant policy yêu cầu\.

- Explicit confirmation bằng CTA danger `Hủy đơn hàng` tại D\-08\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG10\-E01|Top bar|`Hủy đơn hàng`|Giữ task/order context|D\-01 đến D\-16 khi permitted|
|SG10\-E02|Back action|`Quay lại`|Về SG\-08 trước commit|Disabled critical commit window|
|SG10\-E03|Order context|`Đơn #...` · Customer · Total|Nhận diện source transaction|Read\-only|
|SG10\-E04|Decision banner|`Có thể hủy` / `Cần lưu ý` / `Không thể hủy` / `Chưa thể kiểm tra`|Tóm tắt precheck|D\-02 đến D\-06|
|SG10\-E05|Settlement assertion|`Không còn tiền thực thu ròng`|Giải thích core eligibility|Ready/warning/review|
|SG10\-E06|Settlement detail disclosure|Đã thu · đã void · đã hoàn · net|Mở breakdown theo permission|Khi cần đối chiếu|
|SG10\-E07|Blocker list|Code\-aware user message · next action|Điều hướng xử lý|D\-04/D\-05/D\-06/D\-14|
|SG10\-E08|Warning list|Impact/risk/hướng xử lý|Inform/acknowledge|D\-03|
|SG10\-E09|Warning acknowledgement|`Tôi đã hiểu nội dung cần lưu ý`|Cho tiếp tục khi policy yêu cầu|Không dùng cho hard blocker|
|SG10\-E10|Impact\-preview list|Receivable · Inventory · Pricing · E\-invoice · Reporting|Mở detail|D\-02/D\-03/D\-08|
|SG10\-E11|Continue action|`Tiếp tục hủy`|Mở D\-07|Ready/warning acknowledged|
|SG10\-E12|Full\-return redirect|`Trả toàn bộ & hoàn tiền`|Mở SG\-11 full\-return mode|D\-04/D\-14 payment blocker|
|SG10\-E13|Existing\-operation action|`Mở phiếu/yêu cầu hiện có`|Resume SG\-10/SG\-11/SG\-13|D\-05|
|SG10\-E14|Check\-status action|`Kiểm tra trạng thái`|Refresh authoritative dependency/operation|D\-06/D\-10/D\-15|
|SG10\-E15|Reason selector|`Lý do hủy`|Chọn active reason code|D\-07, required|
|SG10\-E16|Reason\-note input|`Diễn giải bổ sung`|Nhập audit rationale|Required theo rule|
|SG10\-E17|Review action|`Xem lại yêu cầu hủy`|Validate và mở D\-08|Current precheck \+ valid reason|
|SG10\-E18|Review summary|Order · total · settlement · reason · impacts|Final decision context|D\-08|
|SG10\-E19|Destructive action|`Hủy đơn hàng`|Gửi confirmation|D\-08|
|SG10\-E20|Processing indicator|`Đang xác nhận hủy…`|Phản ánh command|D\-09|
|SG10\-E21|Lifecycle\-processing result|`Yêu cầu hủy đã được ghi nhận`|Chặn operation mới, query lifecycle|D\-10|
|SG10\-E22|Cancellation result|`Đã hủy đơn` · Cancellation ID|Xác nhận lifecycle cancelled|D\-11|
|SG10\-E23|Impact\-status list|Target · business · delivery · updated|Theo dõi hoàn nguyên|D\-12|
|SG10\-E24|Technical retry|`Thử gửi lại`|Re\-fetch rồi retry eligible delivery|D\-12 \+ permission|
|SG10\-E25|Reconciliation action|`Xử lý đối soát`|Mở owner/reconciliation flow|D\-12 business rejection|
|SG10\-E26|Detail action|`Xem chi tiết đơn`|Mở SG\-08 cancelled variant|D\-11/D\-12|
|SG10\-E27|New\-order action|`Tạo đơn mới`|Khởi tạo SalesOrderWorkingState mới|D\-11|
|SG10\-E28|List action|`Về danh sách đơn`|Mở SG\-07|D\-11|
|SG10\-E29|Recheck action|`Kiểm tra lại`|Chạy lại full precheck|D\-13/D\-14 eligible|



**Precheck decision table**

|Authoritative finding|Decision|User\-facing action|Mutation|
|---|---|---|---|
|No permission/out of scope|Blocked|Quay lại|Không|
|Lifecycle already cancelled|Existing result|Xem lịch sử hủy|Không|
|Existing cancellation requested/validating|Resume|Kiểm tra/mở yêu cầu|Không tạo mới|
|Existing cancellation confirmed/processing|Resume result|Kiểm tra lifecycle|Không tạo mới|
|ReturnExchangeOrder draft|Blocked|Tiếp tục/hủy draft trong SG\-11|Không|
|ReturnExchangeOrder confirmed/processing/completed|Blocked|Mở phiếu đổi/trả|Không|
|Settlement pending/uncertain|Uncertain|Kiểm tra settlement|Không|
|`net_confirmed_collection > 0`|Redirect|Trả toàn bộ \& hoàn tiền|Không tạo cancellation|
|`net_confirmed_collection = 0`, dependency unresolved|Blocked/uncertain theo policy|Kiểm tra trạng thái|Không|
|`net_confirmed_collection = 0`, no hard blocker|Ready/warning|Tiếp tục hủy|Chưa mutation|



**Eligibility and settlement behavior**

- Chỉ SalesOrder lifecycle `completed` được xem xét hủy toàn bộ\.

- Core formula: `net_confirmed_collection = total_confirmed_collection - total_confirmed_refund - total_confirmed_void`\.

- Cancellation chỉ tiếp tục khi net confirmed collection bằng 0 ở precheck và command time\.

- Order từng có payment nhưng đã void/refund đầy đủ về net 0 không bị chặn chỉ vì lịch sử payment\.

- Outstanding receivable chưa thu không phải tiền phải hoàn; nó xuất hiện trong receivable reversal preview\.

- Payment pending, uncertain hoặc reconciliation required không được coi là 0\.

- Payment summary ở SG\-08 không thay thế authoritative Sales Settlement check\.

- SG\-10 không hiển thị refund amount, refund method, `Hoàn ngay`, `Hoàn sau` hoặc `Không cần hoàn`\.

    

**Payment\-collected redirect behavior**

- D\-04 dùng khi blocker code `PAYMENT_ALREADY_COLLECTED` hoặc authoritative equivalent\.

- Message giải thích nghiệp vụ cần trả hàng và quyết toán giá trị, không chỉ nói chung `Không đủ điều kiện`\.

- CTA mở SG\-11 với source order và `entry_mode = full_return_from_cancel_attempt`\.

- Redirect không tạo ReturnExchangeOrder trước khi SG\-11 precheck/start thành công\.

- Không tự copy cancellation reason thành return reason vì semantic khác; có thể truyền navigation origin để giải thích context\.

- Nếu settlement result vừa thay đổi từ net 0 sang net \>0 tại confirm, mở D\-14 với cùng redirect\.

    

**Competing\-operation behavior**

- ReturnExchangeOrder `confirmed`, `processing` hoặc `completed` là hard blocker\.

- ReturnExchangeOrder `draft` phải được tiếp tục/hủy/resolve và release reservation trước khi cancellation có thể ready\.

- SalesOrderCancellation `requested` hoặc `validating` phải resume/resolve; không tạo cancellation mới\.

- SalesOrderCancellation `confirmed` mở result/lifecycle\-processing state hiện có\.

- Cancellation `blocked`, `failed` hoặc `cancelled` không mặc định chặn vĩnh viễn; precheck mới quyết định\.

- Operation summary phải hiển thị type/status/updated time và safe next action, không lộ payload kỹ thuật\.

    

**Impact\-preview behavior**

- Trước confirmation, mọi impact dùng semantic `Dự kiến`, `Không yêu cầu`, `Cần kiểm tra` hoặc `Chưa xác định`; không dùng `Đã hoàn nguyên`\.

- Receivable: amount/requirement giảm hoặc đảo khoản phải thu chưa thu; không phải refund\.

- Inventory: các line/quantity hoặc impact summary cần hoàn nguyên nếu order đã/có thể đã ảnh hưởng stock\.

- Pricing: applied pricing commitment cần reverse hoặc `Không yêu cầu`\.

- E\-invoice: chứng từ/request liên quan cần xử lý hoặc `Không yêu cầu`\.

- Reporting: projection/update requirement\.

- `Không yêu cầu` phải khác `Không có dữ liệu` và `Chưa xác định`\.

- Raw command payload/technical error không hiển thị trong preview\.

- Impact summary thay đổi làm review stale và phải trình bày lại trước confirmation\.

    

**Warning behavior**

- Warning chỉ dùng cho condition policy cho phép tiếp tục; hard blocker không thể được acknowledge để bypass\.

- Mỗi warning nêu `Điều gì`, `Ảnh hưởng gì` và `Sau hủy cần làm gì`\.

- Acknowledgement chỉ xuất hiện khi tenant policy yêu cầu; không dùng checkbox mặc định cho mọi warning\.

- Warning acknowledgement gắn với precheck context; precheck mới làm acknowledgement cũ mất hiệu lực\.

- Dependency `uncertain` cần xác minh không được hạ thành warning nếu policy yêu cầu certainty\.

    

**Reason behavior**

- Reason code bắt buộc và phải active/phù hợp ở confirmation time\.

- Reason note optional mặc định, bắt buộc với `OTHER/Khác` hoặc tenant policy yêu cầu\.

- Reason note trim, validate max length và coi whitespace\-only là empty\.

- Reason form luôn giữ order code và precheck decision context\.

- Quay lại trước confirmation có thể giữ reason trong navigation session nhưng không tạo cancellation input business record\.

- Reason catalog drift chuyển D\-13 và yêu cầu chọn lại; không silently map\.

    

**Final\-review behavior**

- D\-08 hiển thị order/customer/total, settlement assertion net 0, checked freshness, reason và impact preview mới nhất\.

- Nêu rõ `Toàn bộ đơn sẽ chuyển sang Đã hủy và không thể mở lại`; commercial snapshot/history vẫn được giữ\.

- Không nói inventory/receivable/e\-invoice đã hoàn tất trước khi downstream result tồn tại\.

- Danger CTA label cụ thể `Hủy đơn hàng`; không auto\-focus CTA trên desktop và không đặt sát back action gây nhấn nhầm\.

- `Quay lại` giữ reason và trở D\-07\.

- CTA chỉ enabled khi precheck current, reason valid, warning resolved và không có blocker\.

    

**Confirmation and orchestration behavior**

- Confirm gửi cancellation context, sales\_order\_id, expected order version, expected settlement version/precheck reference, reason, actor và idempotency key\.

- Backend revalidate permission, lifecycle, lock, source/settlement version, current net collection, cancellation conflict, return/exchange conflict, reason và impact requirements\.

- Hợp lệ: tạo đúng một SalesOrderCancellation confirmed cùng source/settlement snapshots và durable impact requirements\.

- `CancelSalesOrder` là internal idempotent command; UI không gọi trực tiếp\.

- SalesOrder chỉ được hiển thị `Đã hủy` sau khi lifecycle authoritative chuyển `completed → cancelled`\.

- Cancellation decision và durable local outbox/impact records commit atomically trong domain sở hữu; không dùng distributed transaction xuyên domain\.

- Commercial snapshot, lines, settlement/payment history, receipt và adjustment history không bị xóa hoặc overwrite\.

    

**Cancellation\-versus\-lifecycle behavior**

- `SalesOrderCancellation confirmed` và `SalesOrder lifecycle cancelled` là hai facts liên quan nhưng có thể không xuất hiện cùng lúc ở UI do orchestration/consistency\.

- D\-10 dùng khi cancellation decision confirmed nhưng lifecycle command chưa có final success\.

- D\-10 wording `Yêu cầu hủy đã được ghi nhận — đang chuyển trạng thái đơn`; không dùng `Đã hủy đơn`\.

- Trong D\-10, chặn cancellation/return/exchange cạnh tranh và query theo correlation context\.

- Nếu lifecycle chuyển cancelled, mở D\-11\.

- Nếu lifecycle command bị business/technical issue cần xử lý, hiển thị processing/reconciliation route; không tạo cancellation thứ hai\.

    

**Idempotency and concurrency behavior**

- Confirm bắt buộc có idempotency key gắn canonical payload\.

- Double tap khóa danger CTA; backend idempotency vẫn là guarantee\.

- Cùng key \+ cùng payload trả cùng cancellation result\.

- Cùng key \+ payload khác trả conflict và không đổi record cũ\.

- Source order version hoặc settlement version thay đổi trả D\-13/D\-14; không auto\-merge\.

- Payment confirmed ngay trước command phải chặn trước `CancelSalesOrder` và route SG\-11\.

- ReturnExchangeOrder xuất hiện ngay trước command phải chặn toàn cancellation\.

- Refresh/reopen không tạo key mới khi operation cũ chưa được xác định\.

    

**Stale/conflict recovery behavior**

- Source order, settlement, reason catalog hoặc impact context thay đổi làm precheck/review stale\.

- D\-13 nói rõ cancellation chưa được confirmed nếu đó là authoritative result\.

- `Kiểm tra lại` chạy full precheck, không chỉ refresh màn hình\.

- Reason có thể giữ như local reference, nhưng người dùng phải review lại summary và reason validity trên context mới\.

- Nếu context mới net \>0, chuyển D\-04/D\-14; không cho tiếp tục hủy dù reason đã hợp lệ\.

- Nếu order đã cancelled bởi operation khác, mở existing D\-11 result\.

    

**Known blocked/failed behavior**

- D\-14 dùng khi confirmation result chắc chắn không tạo cancellation hoặc không chuyển lifecycle\.

- Phân biệt business blocker \(payment/conflict/permission\) với known technical failure\.

- Nếu cancellation decision đã confirmed nhưng lifecycle pending/failed, dùng D\-10/processing result, không nói toàn confirmation failed\.

- Business blocker cung cấp next\-best action: SG\-11, open existing operation, recheck hoặc return SG\-08\.

- Known failure trước commit có thể retry khi backend xác nhận chưa commit và context được rechecked\.

    

**Uncertain\-result recovery behavior**

- Timeout/response loss sau submit không được mặc định là failed\.

- D\-15 query cancellation bằng operation/idempotency/correlation context\.

- Nếu cancellation chưa confirmed và backend xác định safe, retry cùng context\.

- Nếu cancellation confirmed nhưng lifecycle pending, mở D\-10\.

- Nếu lifecycle cancelled, mở D\-11/D\-12\.

- Nếu blocker authoritative, mở D\-14\.

- Không tạo cancellation mới chỉ vì người dùng quay lại SG\-08 rồi mở flow lần nữa\.

    

**Cancelled\-result behavior**

- D\-11 chỉ dùng khi SalesOrder lifecycle authoritative là `cancelled` và cancellation result tương ứng đã được xác định\.

- Hiển thị order code, cancellation ID, reason, actor, confirmation time và settlement assertion net 0 tại thời điểm hủy\.

- Wording `Đã hủy đơn`; tuyệt đối không dùng `Đã hoàn tiền`\.

- Order cancelled không thể reopen hoặc chuyển về completed\.

- `Tạo đơn mới` khởi tạo SalesOrderWorkingState mới, không reuse order ID, lifecycle hoặc snapshot cũ\.

- Receipt cũ được giữ và có nhãn `Đã hủy`; version mới chỉ sinh theo policy\.

- Result không hiển thị refund action/amount pending\.

    

**Downstream\-impact behavior**

- D\-12 hiển thị Receivable, Inventory, Pricing, E\-invoice và Reporting khi áp dụng\.

- Mỗi target tách `Trạng thái nghiệp vụ` và `Trạng thái truyền nhận`\.

- Business status: `Không yêu cầu`, `Đang xử lý`, `Đã tiếp nhận`, `Bị từ chối`, `Cần đối soát`, `Đã đối soát`\.

- Delivery status: `Đã tạo`, `Trong hàng đợi`, `Đã gửi`, `Đã xác nhận`, `Thất bại`, `Chưa xác định`, `Dead letter`\.

- Receivable reversal chỉ giảm/đảo nghĩa vụ chưa thu, không phải refund\.

- Theme 6 sở hữu ledger; Theme 7 sở hữu stock movement; Theme 4 sở hữu pricing; Theme 8 sở hữu e\-invoice\.

- Downstream failure không rollback cancellation hoặc reopen SalesOrder\.

- Technical retry chỉ dùng cho eligible delivery record, re\-fetch trước submit và giữ payload/idempotency\.

- Business rejection không được technical retry để vượt rule; mở reconciliation/owner flow\.

- Mọi impact/retry truy được source cancellation và correlation context\.

    

**Business rules and invariants**

- SG\-10 chỉ áp dụng cho official SalesOrder lifecycle completed trước confirmation\.

- Cancellation chỉ confirm khi net confirmed collection bằng 0 tại command time\.

- SG\-10 không tạo refund transaction hoặc thu/hoàn tiền\.

- Một order chỉ có tối đa một cancellation confirmed có hiệu lực\.

- Order cancelled không thể mở lại\.

- Giao dịch gốc và mọi historical record được bảo toàn\.

- Cancellation confirmed là append\-only, không sửa/xóa\.

- Competing return/exchange phải được resolve trước\.

- Downstream failure không đảo ngược lifecycle cancelled\.

- Exit trước confirmation không thay đổi SalesOrder\.

    

**Permissions**

- `sales.order.view`: xem permitted source order context\.

- `sales.order.cancel`: chạy precheck, nhập reason và confirm cancellation\.

- `sales.return_exchange.create`: dùng redirect full return khi đã thu tiền\.

- `sales.integration.view_sync_status`: xem impact/delivery detail\.

- Permission retry technical delivery: retry item eligible\.

- Permission reconciliation: mở/tiến hành reconciliation flow\.

- `sales.receipt.view/print/share`: xem/in/chia sẻ receipt cũ của order cancelled\.

- `sales.payment.view`: xem settlement breakdown; không có quyền vẫn có thể thấy eligibility assertion được policy cho phép\.

- Không có cancel permission → D\-16/D\-02 neutral; không render reason/impact\-sensitive detail\.

- Permission bị thu hồi trước confirm → backend chặn và không tạo cancellation\.

    

**Loading, empty and error behavior**

- D\-01 dùng skeleton cho identity, decision, settlement và impacts; không flash ready từ cache cũ\.

- Precheck dependency unavailable không mặc định ready; D\-06 cho retry/check status\.

- Impact `not_required` không bị hiển thị như thiếu dữ liệu\.

- Không có warnings không render empty warning section\.

- Reason validation không xóa note\.

- Error tải impact detail có thể cô lập nếu decision authority vẫn đầy đủ; nếu policy cần impact certainty thì chặn confirmation\.

- Response muộn của sales\_order\_id khác bị bỏ qua\.

- D\-16 không tiết lộ customer, total, lifecycle hoặc blocker nội bộ\.

    

**Feedback and microcopy**

- Dùng `Hủy đơn hàng` cho destructive action; không dùng `Xóa đơn`\.

- Dùng `Không còn tiền thực thu ròng` thay vì `Không có thanh toán` vì order có thể từng thu rồi void/refund\.

- Dùng `Khoản phải thu chưa thu sẽ được giảm/đảo`, không dùng `Hoàn tiền công nợ`\.

- Dùng `Dự kiến hoàn nguyên` trước confirmation và status thực tế sau confirmation\.

- Dùng `Yêu cầu hủy đã được ghi nhận` ở D\-10; chỉ dùng `Đã hủy đơn` ở D\-11\.

- Downstream issue luôn nói rõ order có còn cancelled hay không\.

- Không toast success trùng với result screen\.

    

**Accessibility**

- Reading order: order identity → decision → settlement → blocker/warning → impacts → reason → confirmation\.

- Decision/status không chỉ dùng màu hoặc icon\.

- Impact preview/status có semantic target, business state và delivery state labels\.

- Warning acknowledgement gắn programmatically với warning set\.

- Reason error liên kết input; error summary focus field đầu tiên\.

- D\-08 danger CTA không auto\-focus; keyboard focus bắt đầu từ review title\.

- Processing announcement phát một lần; không lặp liên tục\.

- Dialog/overlay trap focus và trả focus về trigger\.

    

**Responsive behavior**

- Mobile: một cột, decision/settlement trước impact list, reason form riêng và sticky danger CTA ở review\.

- Mobile impact preview dùng stacked target cards; không dùng table ngang\.

- Tablet/web: review có thể chia order/settlement summary bên trái và impacts/reason bên phải\.

- D\-12 có thể dùng table ở viewport rộng nhưng giữ business/delivery semantics\.

- Sticky CTA không che warning, reason error, keyboard hoặc system navigation\.

- Eligibility, idempotency và confirmation semantics không đổi theo viewport\.

    

#### Low\-fi wireframes

**D\-01 — Precheck loading**** \(không cần thiết\)**

```Plain Text
┌──────────────────────────────┐
│ ‹  Hủy đơn hàng              │
│ Đơn #DH-002586               │
├──────────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒       │
│ ▒▒▒▒▒▒▒▒▒▒▒▒                │
│                              │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒       │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒              │
│                              │
│ Đang kiểm tra đơn, thanh toán│
│ và tác động dự kiến…         │
└──────────────────────────────┘
```



**D\-02 — Ready**

```Plain Text
┌──────────────────────────────┐
│ ‹  Hủy đơn hàng              │
│ Đơn #DH-002586               │
├──────────────────────────────┤
│ ✓ Có thể hủy                 │
│ Không còn tiền thực thu ròng │
│ Đã kiểm tra lúc 14:32        │
├──────────────────────────────┤
│ TÁC ĐỘNG DỰ KIẾN            │
│ Công nợ chưa thu   -350.000 ₫│
│ Tồn kho            Hoàn nguyên│
│ Pricing            Không yêu cầu│
│ Hóa đơn điện tử    Cần xử lý │
│ Báo cáo            Cập nhật  │
├──────────────────────────────┤
│          [Tiếp tục hủy]      │
└──────────────────────────────┘
```



**D\-03 — Warning**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Có nội dung cần lưu ý      │
├──────────────────────────────┤
│ E-invoice đã được yêu cầu.   │
│ Sau khi hủy, hệ thống sẽ gửi │
│ yêu cầu xử lý tới Theme 8.   │
│ Kết quả có thể cần đối soát. │
│                              │
│ ☐ Tôi đã hiểu nội dung trên  │
├──────────────────────────────┤
│ [Quay lại] [Vẫn tiếp tục]    │
└──────────────────────────────┘
```



**D\-04 — Payment collected redirect**

```Plain Text
┌──────────────────────────────┐
│ Không thể hủy đơn            │
├──────────────────────────────┤
│ Đơn còn 1.250.000 ₫ tiền đã  │
│ thu ròng. Hủy đơn không bao  │
│ gồm hoàn tiền.               │
│                              │
│ Hãy trả toàn bộ hàng và quyết│
│ toán khoản khách được nhận.  │
│                              │
│ [Quay lại]                   │
│ [Trả toàn bộ & hoàn tiền]    │
└──────────────────────────────┘
```



**D\-05 — Competing operation**** \(toast\)**

```Plain Text
┌──────────────────────────────┐
│ Đang có phiếu đổi/trả        │
├──────────────────────────────┤
│ Phiếu #DT-00128 · Nháp       │
│ Cập nhật 20/07 13:55         │
│ Phiếu đang giữ số lượng hàng │
│ có thể trả.                  │
│                              │
│ Hãy tiếp tục hoặc hủy phiếu  │
│ này trước khi hủy đơn.       │
│                              │
│ [Quay lại] [Mở phiếu hiện có]│
└──────────────────────────────┘
```



**D\-06 — Uncertain dependency**** \(toast\)**

```Plain Text
┌──────────────────────────────┐
│ Chưa thể kiểm tra điều kiện  │
├──────────────────────────────┤
│ Trạng thái thanh toán đang   │
│ được đối soát. Hệ thống chưa │
│ thể xác định tiền thực thu   │
│ ròng có bằng 0 hay không.    │
│                              │
│ Không tiếp tục hủy lúc này.  │
│                              │
│ [Quay lại] [Kiểm tra trạng thái]│
└──────────────────────────────┘
```



**D\-07 — Cancellation reason**

```Plain Text
┌──────────────────────────────┐
│ ‹  Lý do hủy đơn             │
│ #DH-002586                   │
├──────────────────────────────┤
│ ✓ Không còn tiền thực thu ròng│
├──────────────────────────────┤
│ Lý do hủy *                  │
│ [Tạo nhầm đơn             ▾] │
│                              │
│ Diễn giải bổ sung            │
│ [Khách chưa nhận hàng      ] │
│                              │
├──────────────────────────────┤
│      [Xem lại yêu cầu hủy]   │
└──────────────────────────────┘
```



**D\-08 — Destructive review**

```Plain Text
┌──────────────────────────────┐
│ ‹  Xem lại yêu cầu hủy       │
├──────────────────────────────┤
│ Đơn #DH-002586               │
│ Nguyễn Văn An · 1.250.000 ₫  │
│ Không còn tiền thực thu ròng │
├──────────────────────────────┤
│ Lý do: Tạo nhầm đơn          │
│ Khách chưa nhận hàng         │
├──────────────────────────────┤
│ Dự kiến: giảm công nợ, hoàn  │
│ nguyên kho, xử lý e-invoice. │
│                              │
│ Đơn sẽ chuyển sang Đã hủy và │
│ không thể mở lại. Lịch sử gốc│
│ vẫn được giữ.                │
├──────────────────────────────┤
│ [Quay lại] [Hủy đơn hàng]    │
└──────────────────────────────┘
```



**D\-09 — Confirmation processing**** \(không cần thiết\)**

```Plain Text
┌──────────────────────────────┐
│                              │
│              ◌               │
│ Đang xác nhận hủy đơn…       │
│                              │
│ Không gửi lại yêu cầu trong  │
│ khi kết quả đang được ghi nhận│
│                              │
└──────────────────────────────┘
```



**D\-10 — Cancellation confirmed, lifecycle pending**** \(không cần thiết\)**

```Plain Text
┌──────────────────────────────┐
│ ◷ Yêu cầu hủy đã được ghi nhận│
├──────────────────────────────┤
│ Cancellation #CAN-00042      │
│ Hệ thống đang chuyển trạng   │
│ thái đơn #DH-002586.         │
│                              │
│ Đơn chưa được gắn nhãn       │
│ “Đã hủy” cho tới khi hoàn tất│
│ bước này.                    │
│                              │
│        [Kiểm tra trạng thái] │
└──────────────────────────────┘
```



**D\-11 — Order cancelled**** \(toast\)**

```Plain Text
┌──────────────────────────────┐
│              ✓               │
│ Đã hủy đơn                   │
├──────────────────────────────┤
│ Đơn #DH-002586               │
│ Cancellation #CAN-00042      │
│ NV Minh · 20/07 14:35        │
│ Lý do: Tạo nhầm đơn          │
│                              │
│ Tiền thực thu ròng khi hủy: 0₫│
│ Đơn không thể mở lại.        │
├──────────────────────────────┤
│ [Xem trạng thái xử lý]       │
│ [Xem chi tiết đơn]           │
│ [Tạo đơn mới]                │
└──────────────────────────────┘
```



**D\-12 — Downstream impact status**

```Plain Text
┌──────────────────────────────┐
│ ‹  Trạng thái hoàn nguyên    │
│ #CAN-00042 · Đơn đã hủy      │
├──────────────────────────────┤
│ CÔNG NỢ                      │
│ Nghiệp vụ: Đã tiếp nhận      │
│ Truyền nhận: Đã xác nhận     │
├──────────────────────────────┤
│ TỒN KHO                      │
│ Nghiệp vụ: Đang xử lý        │
│ Truyền nhận: Trong hàng đợi  │
├──────────────────────────────┤
│ HÓA ĐƠN ĐIỆN TỬ             │
│ Nghiệp vụ: Cần đối soát      │
│ Truyền nhận: Đã xác nhận     │
│              [Xử lý đối soát]│
├──────────────────────────────┤
│ Đơn vẫn giữ trạng thái Đã hủy│
└──────────────────────────────┘
```



**D\-13 — Stale/version conflict**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Điều kiện đã thay đổi      │
├──────────────────────────────┤
│ Yêu cầu chưa được xác nhận.  │
│ Đơn hoặc settlement đã có    │
│ phiên bản mới hơn.           │
│                              │
│ Hệ thống không tự dùng lại   │
│ kết quả kiểm tra cũ.         │
│                              │
│ [Quay lại] [Kiểm tra lại]    │
└──────────────────────────────┘
```



**D\-14 — Known blocked at confirmation**

```Plain Text
┌──────────────────────────────┐
│ Không thể hủy đơn            │
├──────────────────────────────┤
│ Một khoản thanh toán mới đã  │
│ được ghi nhận trước lúc xác  │
│ nhận. Đơn chưa bị hủy.       │
│                              │
│ Tiền thực thu ròng: 500.000 ₫│
│                              │
│ [Về chi tiết đơn]            │
│ [Trả toàn bộ & hoàn tiền]    │
└──────────────────────────────┘
```



**D\-15 — Uncertain\-result recovery**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Đang kiểm tra kết quả      │
├──────────────────────────────┤
│ Kết nối bị gián đoạn sau khi │
│ gửi yêu cầu hủy.             │
│                              │
│ Không tạo yêu cầu mới trước  │
│ khi xác định kết quả hiện tại│
│                              │
│ [Về chi tiết đơn]            │
│ [Kiểm tra kết quả]           │
└──────────────────────────────┘
```



**D\-16 — No permission/not found**

```Plain Text
┌──────────────────────────────┐
│ Không thể mở yêu cầu hủy     │
├──────────────────────────────┤
│ Đơn hàng không tồn tại hoặc  │
│ anh không có quyền truy cập  │
│ trong phạm vi hiện tại.      │
│                              │
│ Không có dữ liệu giao dịch   │
│ nào được hiển thị.           │
│                              │
│          [Về danh sách đơn]  │
└──────────────────────────────┘
```



#### Visuals

TBD\.



#### Traceability

TBD\.

### 5\.5\.12 SG\-11 — Lập yêu cầu đổi/trả

#### Overview

- Purpose: Cho phép người dùng tạo và hoàn thiện ReturnExchangeOrder draft từ một SalesOrder nguồn, gồm hàng khách trả, hàng khách nhận đổi, reservation và valuation preview\.

- Related epic: EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch\.

- Related business flow: BF\-08 — Đổi/trả \& quyết toán\.

- Business flow group: Post\-sale\.

- Primary users: Nhân viên bán hàng, quản lý cửa hàng và người dùng được cấp quyền xử lý đổi/trả\.

- Primary task: Chọn đúng hàng khách trả, khai báo quantity/reason/condition, thêm hàng khách nhận và chuẩn bị một draft hợp lệ để chuyển sang SG\-12\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: SG\-11 là một two\-sided workspace: phía bắt buộc là `Hàng khách trả` từ commercial snapshot nguồn; phía tùy chọn là `Hàng khách nhận` dùng product/pricing hiện hành\. UI phải giữ nguồn gốc, quantity capacity, reservation và valuation explainable trong suốt flow\.

- Architectural role: SG\-11 sở hữu quá trình tạo/cập nhật draft và valuation preview, nhưng không xác nhận business fact cuối cùng\. SG\-12 sở hữu settlement plan/confirmation; SG\-13 hiển thị result và downstream impacts\.

- Scope boundary: SG\-11 không thu thêm, hoàn tiền, giảm/cấn trừ công nợ, xác nhận ReturnExchangeOrder, tạo stock movement hoặc e\-invoice impact\. Không cho tạo nhanh sản phẩm; customer context được kế thừa từ SalesOrder nguồn và không đổi trong flow\.

    

#### Entry \& exit

- Entry points:

    - Action `Đổi/trả hàng` từ SG\-08 với `entry_mode = standard`\.

    - Action `Trả toàn bộ & hoàn tiền` từ SG\-10 với `entry_mode = full_return_from_cancel_attempt`\.

    - Action `Tiếp tục phiếu đổi/trả` từ SG\-08/SG\-10 khi có active draft hợp lệ\.

    - Deep link nội bộ hợp lệ tới ReturnExchangeOrder draft trong tenant/store scope\.

    - Recovery sau Start/Update/Cancel result chưa xác định bằng draft/operation/idempotency context\.

- Exit points:

    - Draft saved, có ít nhất một returned line hợp lệ, reservations current và valuation current → SG\-12 — Quyết toán chênh lệch\.

    - `Lưu và đóng` → SG\-08; draft/version cùng reservation được giữ theo policy\.

    - `Hủy phiếu nháp` → SG\-08 sau khi cancellation của draft được xác nhận và reservations được release\.

    - Quay lại trước khi draft được tạo → SG\-08, không tạo business/financial/inventory impact\.

    - Precheck blocked → SG\-08 hoặc mở cancellation/existing operation phù hợp\.

    - Draft stale/conflict → ở lại SG\-11 để revalidate, reload hoặc rebuild proposal có chủ đích\.

    - Draft cancelled/expired/invalid → D\-18; không update/continue, chỉ mở source order/result phù hợp\.

        

#### Screen/state inventory

|State|Class|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|System state — Precheck/start loading|Kiểm tra source order, cancellation conflict và returnable lines|—|Chưa tạo impact chính thức|
|D\-02|System state — Precheck blocked|Giải thích cancelled order, return window, conflict, permission hoặc no\-returnable|Quay lại / mở operation|Không tạo draft|
|D\-03|Decision overlay — Existing draft found|Cho resume active draft thay vì tạo trùng|Tiếp tục phiếu nháp|Theo policy/idempotency|
|D\-04|Base workspace — Standard start|Chọn returned lines từ source order|Chọn hàng trả|Không prefill toàn bộ|
|D\-05|Base workspace — Quick full\-return|Review toàn bộ quantity còn có thể trả đã prefill|Hoàn thiện thông tin trả|Không có exchange line mặc định|
|D\-06|Editor — Returned line|Nhập quantity, line reason và item condition|Áp dụng|Persist theo discrete action|
|D\-07|Transition state — Full\-return scope changed|Thông báo flow không còn là quick full\-return|Tiếp tục|Không phải blocking modal|
|D\-08|Subview — Exchange product search|Tìm/quét product và chọn active unit|Chọn sản phẩm|Không tạo nhanh sản phẩm|
|D\-09|Editor — Exchange line|Nhập unit, quantity và xem current pricing/availability|Thêm/Áp dụng|Manual price theo permission|
|D\-10|Base workspace — Working draft|Quản lý returned/exchange lines, note và readiness|Tiếp tục quyết toán|Có thể lưu khi chưa hoàn thiện|
|D\-11|Subview — Valuation details|Giải thích return/exchange value, allocation, tax và rounding|Đóng|Preview, không phải transaction|
|D\-12|Persistence state — Saving/saved/uncertain|Phản ánh version update và save result|Kiểm tra kết quả|Không đóng khi result chưa xác định|
|D\-13|Resume state — Revalidation summary|So sánh saved data với authoritative current context|Xử lý thay đổi|Không silent replacement|
|D\-14|Conflict — Returnable/reservation|Xử lý quantity giảm, held quantity hoặc reservation expiry|Điều chỉnh quantity|Không auto\-re\-reserve khác amount|
|D\-15|Conflict — Product/pricing/inventory/valuation|Xử lý exchange line hoặc valuation stale/blocked|Kiểm tra lại|Không silently accept price|
|D\-16|Conflict — Draft version|Ngăn ghi đè draft đã được cập nhật nơi khác|Tải bản mới nhất|Không auto\-merge|
|D\-17|Destructive overlay — Cancel draft|Xác nhận cancel draft và release reservations|Hủy phiếu nháp|Idempotent|
|D\-18|Terminal state — Draft cancelled/expired/invalid|Chặn update/continue trên draft không còn editable|Về chi tiết đơn|Không reopen draft|



#### UI Contract

**Core workspace model**

- SG\-11 có hai line collections với nguồn dữ liệu/valuation khác nhau:

    - `Returned lines`: bắt buộc, tham chiếu SalesOrderLine nguồn, dùng commercial snapshot và return pricing impact\.

    - `Exchange lines`: tùy chọn, dùng product/unit/pricing/inventory hiện hành, không cần tham chiếu source line\.

- Một ReturnExchangeOrder hợp lệ cuối cùng phải có ít nhất một returned line; flow không được dùng để bán mới chỉ bằng exchange lines\.

- Customer, store và source SalesOrder context là read\-only trong SG\-11\.

- Draft có thể incomplete và vẫn lưu; readiness để sang SG\-12 là một trạng thái riêng\.

- Reservation là quyền giữ tạm thời, không phải completed return hoặc stock movement\.

    

**User intent**

- Biết đúng đơn nguồn, khách hàng và những dòng còn có thể trả\.

- Hiểu quantity đã bán, đã trả, đang được giữ và tối đa có thể chọn\.

- Ghi đúng line reason và item condition mà không mặc định hàng có thể bán lại\.

- Thêm hàng khách nhận bằng product/pricing hiện hành\.

- Biết draft đã lưu hay chưa và reservation còn hiệu lực hay không\.

- Hiểu return value, exchange value và chiều chênh lệch dự kiến\.

- Resume draft mà không bị hệ thống âm thầm đổi quantity, product, unit hoặc price\.

- Chuyển SG\-12 chỉ khi draft/valuation current và không có blocker\.

    

**Information hierarchy**

1. Source order/customer và entry\-mode context\.

2. Returned lines cùng capacity/reservation status\.

3. Exchange lines cùng current pricing/inventory status\.

4. Draft persistence/version/readiness\.

5. Valuation preview và settlement direction\.

6. Stale/conflict messages và required fixes\.

7. `Lưu và đóng` / `Tiếp tục quyết toán` / cancel draft\.

    

**Flow architecture**

|Stage|User decision|System responsibility|Official impact|
|---|---|---|---|
|Precheck/start|Mở standard/full\-return/resume|Xác minh source, conflicts, returnable lines; tạo/resume draft idempotently|Không|
|Returned lines|Chọn quantity/reason/condition|Validate source/capacity và reservation|Chỉ draft/reservation|
|Exchange lines|Chọn product/unit/quantity|Validate sellability, pricing và availability|Chỉ draft/reservation|
|Valuation|Review values/difference|Evaluate source\-return vs current\-exchange pricing|Không financial transaction|
|Save/resume|Tạm dừng/tiếp tục|Persist versioned draft và revalidate contexts|Không official return status|
|Continue|Sang quyết toán|Revalidate readiness và pass authoritative draft context|Chưa confirm|



**Layout anatomy**

- Top bar:

    - Back/close action\.

    - Title `Phiếu đổi/trả`\.

    - Draft code và persistence status\.

    - Overflow: `Hủy phiếu nháp` khi permitted\.

- Source context:

    - Source order code, customer snapshot, store và completion time\.

    - Entry\-mode notice/coverage summary\.

- Returned section:

    - Mandatory marker and selected/eligible count\.

    - Source\-line cards with capacity breakdown\.

    - Line reason/item condition/readiness\.

- Exchange section:

    - Optional marker\.

    - `Thêm hàng khách nhận` search/scan action\.

    - Exchange line price/availability/readiness\.

- Valuation module:

    - Return value, exchange value, net difference and direction\.

    - Stale/blocked state and detail link\.

- Draft note and validation summary\.

- Sticky actions:

    - `Lưu và đóng`\.

    - `Tiếp tục quyết toán`\.

        

**Source\-of\-truth contract**

|Information|Source|Owner|SG\-11 rule|
|---|---|---|---|
|Source order/lifecycle/customer|Precheck \+ SalesOrder context|Sales Order Lifecycle/Inquiry|Read\-only|
|Returnable quantities|GetReturnableOrderLines with draft context|Post\-sale Operations|UI không tự tính authority từ cached rows|
|Returned commercial values|SalesOrderLine snapshot \+ EvaluateReturnPricingImpact|SalesOrder \+ Theme 4|Không dùng giá hiện hành làm giá gốc|
|Exchange product/unit|Current catalog/sellability|Theme 2|Không dùng snapshot cũ|
|Exchange pricing|Current pricing preview|Theme 4|Revalidate khi thay context/confirm|
|Exchange availability/reservation|Current inventory contract|Theme 7|Không coi availability là stock movement|
|Draft/version|ReturnExchangeOrder|Post\-sale Operations|Expected\-version update, không merge|
|Valuation|ReturnExchangeValuation|Post\-sale Operations \+ Theme 4/settlement context|Preview, stale/blocked không continue|



**Displayed data**

- Draft ID, status, version, updated actor/time và save state\.

- Source SalesOrder code/version, customer snapshot, store và completion time\.

- Entry mode và quick full\-return coverage: eligible lines, prefilled lines, quantities previously returned/unavailable\.

- Returned line:

    - Source line/product/unit snapshot\.

    - Sold quantity, completed returned quantity, reserved quantity và authoritative returnable/max quantity\.

    - Quantity selected/held by current draft\.

    - Line reason, item condition và validation/reservation status\.

    - Return pricing reference/evaluation status and line value\.

- Exchange line:

    - Current product/SKU/barcode result, active unit and quantity\.

    - Current pricing source/preview, discount/tax/promotion and line total\.

    - Inventory availability/reservation and manual\-price indicator when applicable\.

- Valuation: return value, exchange value, net difference, required settlement type preview, allocation/rounding detail and freshness\.

- Draft\-level note and validation/readiness summary\.

    

**User inputs**

- Returned line selection\.

- Returned quantity, line reason code and item condition\.

- Optional bulk reason/condition action when all selected lines support same allowed values\.

- Exchange product, unit and quantity\.

- Manual price only when Theme 4 policy and permission explicitly allow\.

- Draft\-level note\.

- Explicit accept/rebuild action when current price/quantity differs from saved data\.

- Cancel\-draft confirmation\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG11\-E01|Top bar|`Phiếu đổi/trả`|Giữ task/source context|D\-01 đến D\-18 when permitted|
|SG11\-E02|Back action|`Quay lại`|Flush/check save hoặc cảnh báo uncertain|Disabled critical update window|
|SG11\-E03|Draft identity|`Nháp #...` · Version|Nhận diện editable record|Sau StartReturnExchange|
|SG11\-E04|Persistence status|`Đang lưu` / `Đã lưu` / `Chưa lưu được`|Phản ánh latest discrete update|D\-10/D\-12|
|SG11\-E05|Source\-order card|`Đơn #...` · Customer · Store|Hiển thị immutable source|Read\-only|
|SG11\-E06|Entry\-mode banner|`Trả toàn bộ từ yêu cầu hủy`|Giải thích prefill/coverage|D\-05/D\-07|
|SG11\-E07|Returned\-section header|`Hàng khách trả` · mandatory/count|Neo mandatory side|D\-04/D\-05/D\-10|
|SG11\-E08|Source\-line card|Snapshot · sold/returned/reserved/returnable|Chọn/mở D\-06|Returnable line only|
|SG11\-E09|Return selection|`Chọn trả`|Tạo/remove returned line via update|D\-04/D\-05|
|SG11\-E10|Return quantity|`Số lượng trả`|Nhập theo unit precision/max|D\-06|
|SG11\-E11|Reason selector|`Lý do trả`|Chọn active line reason|Required theo policy|
|SG11\-E12|Condition selector|`Tình trạng hàng`|Chọn inventory\-disposition input|Required theo policy|
|SG11\-E13|Bulk\-apply action|`Áp dụng cho các dòng đã chọn`|Gán reason/condition có chủ đích|Compatible allowed values only|
|SG11\-E14|Apply\-return action|`Áp dụng`|Persist line/update reservation/version|D\-06|
|SG11\-E15|Exchange\-section header|`Hàng khách nhận` · optional|Neo current\-catalog side|D\-10|
|SG11\-E16|Add\-exchange action|`Thêm hàng khách nhận`|Mở D\-08|Preferred after ≥1 returned line|
|SG11\-E17|Product search/scan|`Tên, SKU hoặc barcode`|Search/scan current sellable catalog|D\-08|
|SG11\-E18|Product\-unit chooser|Active selling units|Resolve barcode/unit ambiguity|D\-08/D\-09|
|SG11\-E19|Exchange quantity|`Số lượng nhận`|Validate precision/pricing/inventory|D\-09|
|SG11\-E20|Current\-price card|Price source · discount/tax · total|Giải thích current pricing|D\-09/D\-10|
|SG11\-E21|Manual\-price control|`Điều chỉnh giá`|Mở Theme 4 governed control|Permission/policy only|
|SG11\-E22|Availability status|Available/reserved/blocked|Phản ánh Theme 7 context|Exchange line|
|SG11\-E23|Exchange\-line actions|`Sửa` / `Xóa`|Versioned update|Draft only|
|SG11\-E24|Valuation summary|Hàng trả · hàng nhận · chênh lệch|Cập nhật sau saved line changes|D\-10|
|SG11\-E25|Difference direction|`Khách trả thêm` / `Dự kiến hoàn hoặc giảm nghĩa vụ` / `Không chênh lệch`|Nêu chiều, chưa settle|Current valuation|
|SG11\-E26|Valuation detail|`Xem chi tiết cách tính`|Mở D\-11|Valuation available|
|SG11\-E27|Draft note|`Ghi chú`|Lưu draft metadata|Optional|
|SG11\-E28|Validation/readiness summary|N blockers/missing fields|Focus required fix|D\-10|
|SG11\-E29|Save\-and\-close action|`Lưu và đóng`|Flush pending draft changes rồi exit|Result known/saved|
|SG11\-E30|Continue action|`Tiếp tục quyết toán`|Revalidate readiness rồi mở SG\-12|All gates pass|
|SG11\-E31|Revalidate action|`Kiểm tra thay đổi`|Fetch authoritative contexts|D\-13/D\-15|
|SG11\-E32|Reload\-latest action|`Tải bản mới nhất`|Replace working draft with latest version|D\-16|
|SG11\-E33|Resolve\-quantity action|`Điều chỉnh số lượng`|Open affected returned line|D\-14|
|SG11\-E34|Accept\-current\-price action|`Chấp nhận giá mới`|Explicitly rebuild exchange valuation|D\-15|
|SG11\-E35|Cancel\-draft action|`Hủy phiếu nháp`|Mở D\-17|Draft \+ permission|
|SG11\-E36|Confirm\-cancel\-draft|`Hủy phiếu nháp`|Cancel idempotently/release reservations|D\-17|
|SG11\-E37|Check\-result action|`Kiểm tra kết quả`|Query Start/Update/Cancel result|D\-12|



**Precheck and start behavior**

- SG\-11 gọi `PrecheckReturnExchange` với sales\_order\_id, actor, store scope và entry mode\.

- Precheck xác minh tenant, membership, permission, lifecycle, lock, return window, source version và cancellation conflict\.

- Chỉ SalesOrder `completed` được bắt đầu; `cancelled` là hard blocker\.

- SalesOrderCancellation `confirmed`, `processing`, `completed` là hard blocker; `requested`/`validating` phải được resolve\.

- `GetReturnableOrderLines` lấy quantity authoritative/reservation current; return\-summary projection không thay thế query này\.

- Không còn dòng có returnable quantity → D\-02, không tạo empty draft mới\.

- `StartReturnExchange` tạo đúng một draft bằng idempotency context; retry trả same draft\.

- Existing active draft được resume theo policy qua D\-03 thay vì tạo trùng mù\.

- Start/precheck không tạo payment/refund/receivable/inventory/e\-invoice impact\.

    

**Entry\-mode behavior**

- `standard`: không preselect toàn bộ returned lines; D\-04 hướng người dùng chọn ít nhất một dòng\.

- `full_return_from_cancel_attempt`: prefill mọi current returnable line/quantity, không tạo exchange line và dự kiến operation type là return\.

- Full\-return coverage phải nói rõ phần đã từng trả và phần không còn returnable; `toàn bộ` nghĩa là toàn bộ quantity hiện còn có thể trả\.

- Entry mode chỉ điều khiển prefill/navigation/UI, không phải lifecycle hoặc entity type riêng\.

- Giảm/xóa một prefilled quantity hoặc thêm exchange line làm quick full\-return chuyển thành standard return context\.

- D\-07 là inline banner/toast có action `Xem thay đổi`, không phải modal chặn; valuation và settlement preview được tính lại\.

    

**Returned\-line capacity behavior**

- Chỉ source SalesOrderLine có returnable quantity lớn hơn 0 được chọn mới; line đã chọn trong current draft vẫn phải hiển thị khi revalidation có conflict\.

- Domain formula: `returnable_quantity = sold_quantity - completed_returned_quantity - reserved_quantity`\.

- UI không tự suy luận max từ cached numbers khi draft context/reservation semantics phức tạp; dùng authoritative maximum từ response\.

- Khi data cho phép, phân biệt `Đang giữ trong phiếu này` với `Đang giữ ở phiếu khác` để tránh người dùng tưởng own reservation làm giảm quantity hai lần\.

- Quantity phải lớn hơn 0, không vượt max tại update/continue/confirm và theo precision của unit snapshot\.

- Fractional quantity dùng input/step/format phù hợp unit precision, không mặc định integer\.

- Dòng khác completed làm capacity giảm → D\-14; không silently clamp selected quantity\.

    

**Returned\-line commercial behavior**

- Returned line bắt buộc tham chiếu SalesOrderLine nguồn và có `line_role = returned`\.

- Product/unit/unit price/discount/tax/promotion context lấy từ source commercial snapshot\.

- Product master/giá hiện hành không thay source valuation baseline\.

- Hệ thống gọi `EvaluateReturnPricingImpact`; line blocked nếu pricing impact/promotion allocation không xác định được\.

- Line value hiển thị là evaluated return value, không đơn giản luôn bằng `quantity × original unit price` nếu promotion/tax/allocation áp dụng\.

- Returnable quantity/value trên screen luôn gắn source line identity để traceability\.

    

**Reason and item\-condition behavior**

- Mỗi returned line lưu reason code và item condition theo policy\.

- Reason/condition option phải còn active tại revalidation; option disabled yêu cầu chọn lại\.

- Item condition chỉ là input cho inventory disposition; không tự quyết định nhập kho bán được và chưa tạo stock movement\.

- Quick full\-return không mặc định condition cho mọi line\.

- Bulk apply chỉ khả dụng khi selected lines cùng chấp nhận reason/condition options; người dùng phải review line exceptions\.

- Draft có thể lưu với missing reason/condition nếu contract cho phép incomplete draft; continue bị chặn\.

    

**Exchange product\-search behavior**

- D\-08 hỗ trợ search theo name/SKU/reference và barcode scan\.

- Không cho tạo nhanh sản phẩm trong SG\-11\.

- Chỉ product/unit active, sellable, cùng tenant và phù hợp store context được chọn\.

- Barcode map nhiều units/products mở chooser; không tự chọn kết quả đầu\.

- Product hiện không sellable không được add, kể cả từng xuất hiện trong source order\.

- Product/unit result hiển thị enough identity để tránh nhầm variant/unit\.

    

**Exchange\-line behavior**

- Exchange line có `line_role = exchange`, thuộc same ReturnExchangeOrder và không bắt buộc source\-line reference\.

- Exchange line dùng customer/store/time/quantity pricing hiện hành từ Theme 4\.

- Quantity lớn hơn 0 và theo current unit precision\.

- Availability/reservation theo Theme 7/tenant policy; thiếu hàng có thể block theo policy\.

- Thêm cùng product\+unit nhiều lần tuân line\-identity policy; UI phải thông báo merge/separate result và valuation không double count\.

- Manual price chỉ hiển thị khi permission \+ Theme 4 policy cho phép, có source label và revalidation\.

- Xóa/cập nhật line là versioned draft update và làm valuation stale cho tới khi tính lại\.

- Exchange\-only draft có thể lưu nhưng không thể continue/confirm nếu không có returned line\.

    

**Persistence model**

- SG\-11 không gửi UpdateReturnExchange theo từng keystroke có thể gây reservation/version churn\.

- Line editor giữ local input; `Áp dụng`, `Thêm`, `Xóa`, bulk apply và explicit note save là discrete persistence points\.

- Mỗi successful update tăng draft version và trả updated reservations/valuation context\.

- Header phản ánh `Đang lưu`, `Đã lưu`, `Chưa lưu được` hoặc `Chưa xác định kết quả`\.

- `Lưu và đóng` flush pending allowed input, chờ authoritative save result rồi mới exit\.

- Save timeout không được coi là failed; D\-12 query draft/version/operation trước retry\.

- Only draft lifecycle editable; cancelled/expired/invalid draft không update\.

    

**Reservation behavior**

- Returned reservation giữ returnable quantity theo policy và ngăn concurrent draft sử dụng cùng capacity\.

- Exchange inventory reservation nếu áp dụng là current\-draft hold, không phải stock movement\.

- Reservation có status/expiry khi cần vận hành\.

- Hủy, expire hoặc invalidate draft release reservations theo policy\.

- Reservation expired không tự reacquire một amount khác; D\-14 cho re\-reserve hoặc điều chỉnh có chủ đích\.

- Re\-reserve result có thể giảm capacity; UI không silently lower selected quantity\.

- Reservation chưa làm SalesOrder return status chuyển `partially_returned`/`fully_returned`\.

    

**Valuation behavior**

- `return_value`: tổng evaluated returned lines theo source snapshots/allocation\.

- `exchange_value`: tổng validated exchange lines theo current pricing\.

- `net_difference = exchange_value - return_value`\.

- `net_difference > 0`: `Khách trả thêm`\.

- `net_difference < 0`: `Dự kiến hoàn hoặc giảm nghĩa vụ`; không mặc định gọi là cash refund\.

- `net_difference = 0` sau rounding: `Không chênh lệch`\.

- Required settlement type preview gồm none, collect, refund, receivable\_offset hoặc mixed theo current context\.

- Full return không exchange: exchange value = 0 và net difference = \-return value\.

- D\-11 hiển thị pricing/promotion/tax allocation, non\-refundable adjustment khi có và rounding detail\.

- Valuation không sở hữu authoritative payment/refund/receivable totals và không tạo transaction/ledger entry\.

- Valuation stale/blocked không được dùng để continue SG\-12\.

    

**Readiness gates**

|Gate|Save draft|Continue SG\-12|User resolution|
|---|---|---|---|
|Không có returned line|Cho phép theo draft policy|Chặn|Chọn ít nhất một hàng trả|
|Missing reason/condition|Cho phép incomplete draft|Chặn|Hoàn thiện affected lines|
|Returned quantity conflict|Giữ draft/conflict state|Chặn|Revalidate và điều chỉnh quantity|
|Exchange line unsellable/out of stock|Giữ draft/blocked line|Chặn theo policy|Xóa/thay line hoặc resolve inventory|
|Reservation expired|Giữ draft|Chặn|Re\-reserve/điều chỉnh|
|Valuation stale/blocked|Giữ draft|Chặn|Tính/kiểm tra lại valuation|
|Save result uncertain/version conflict|Không đóng như đã lưu|Chặn|Check result/reload latest|
|Cancellation conflict|Chỉ cancel draft khi allowed|Chặn|Resolve source cancellation|
|Mọi gate current/valid|Cho phép|Cho phép|Revalidate lần cuối rồi mở SG\-12|



**Continue\-to\-settlement behavior**

- CTA chỉ enabled khi có ≥1 valid returned line, all required line data complete, reservations current, exchange blockers resolved, draft saved/version current và valuation current\.

- Action chạy revalidation cuối của SG\-11 trên source order, returnable quantity, cancellation conflict, product/unit, pricing, inventory, permission, reservation và draft version\.

- Nếu valid, mở SG\-12 với draft ID/version và authoritative valuation context\.

- SG\-12 vẫn phải fetch/revalidate authoritative state; navigation payload không là source of truth\.

- Sang SG\-12 chưa xác nhận ReturnExchangeOrder và chưa tạo financial/inventory/e\-invoice impact\.

- Nếu fail, giữ SG\-11 và focus blocker theo information hierarchy\.

    

**Resume and revalidation behavior**

- Resume tải đầy đủ persisted lines, reasons, conditions, note, valuation, version và source context\.

- Sau đó revalidate lifecycle/cancellation, returnable quantities/reservations, product/unit sellability, pricing, inventory, permissions, settlement/valuation context\.

- D\-13 hiển thị saved value và current fact theo affected item; không thay silently\.

- Saved exchange price vẫn có thể hiển thị như reference nhưng được gắn `Giá đã lưu`; current price phải được lấy lại\.

- Saved returned quantity vượt current capacity phải được sửa/re\-reserve trước continue\.

- Cancellation confirmed trong lúc draft tồn tại làm draft blocked/invalid theo backend result; không cho continue\.

- Revalidation result cập nhật readiness nhưng không giả vờ draft đã applied\.

    

**Stale\-price and product/inventory behavior**

- Product/unit inactive: line blocked; không silently substitute product/unit khác\.

- Current price changed: D\-15 hiển thị saved price, current price và impact on valuation; `Chấp nhận giá mới` là explicit rebuild action\.

- Pricing preview expired/unavailable: valuation stale/blocked, không continue\.

- Inventory availability changed: show required/current/reserved quantity and policy\-specific blocker\.

- Promotion/tax allocation unable to evaluate: show valuation blocked; không fallback về naive price\.

- Customer/settlement context change làm allocation preview stale dù lines không đổi\.

    

**Draft\-version conflict behavior**

- Mọi UpdateReturnExchange gửi expected version\.

- Version mismatch mở D\-16; không auto\-merge returned lines, exchange lines, reasons, conditions hoặc note\.

- `Tải bản mới nhất` thay working draft bằng authoritative latest after warning about unsaved local editor state\.

- Unsaved note/line editor input có thể được giữ cục bộ như reference/copy aid, nhưng không tự đưa vào latest draft\.

- User muốn dùng lại input phải mở editor, áp dụng explicit và review version mới\.

- Double tap/retry cùng operation context không tạo duplicate line/reservation/update\.

    

**Cancel\-draft behavior**

- `Hủy phiếu nháp` là destructive action riêng, không đồng nghĩa back/close\.

- D\-17 nêu draft content sẽ không còn editable và reservations sẽ được release; source SalesOrder không thay đổi\.

- Cancel gửi expected version và idempotency context\.

- Multiple cancel retry trả same cancelled result\.

- Cancel result uncertain dùng D\-12 check result trước retry\.

- Draft cancelled không reopen/update/continue; D\-18 chỉ cung cấp source\-order navigation\.

    

**Business rules and invariants**

- Mỗi draft liên kết đúng một official SalesOrder completed và source customer/store context\.

- Final valid ReturnExchangeOrder phải có ít nhất một returned line\.

- Returned quantity không vượt authoritative capacity\.

- Returned lines dùng source commercial snapshot; exchange lines dùng current product/pricing\.

- Draft update versioned, không auto\-merge\.

- Reservation không phải completed return hoặc stock movement\.

- Draft không thay source return status, payment, receivable, inventory hoặc e\-invoice\.

- Stale/blocked valuation không continue\.

- Cancelled/expired/invalid draft không update hoặc confirm\.

- No quick product creation\.

- SG\-11 không tạo payment/refund/receivable transaction\.

    

**Permissions**

- `sales.order.view`: xem permitted source order context\.

- `sales.return_exchange.create`: precheck/start draft\.

- `sales.return_exchange.view`: xem/resume draft và valuation\.

- `sales.return_exchange.update`: add/update/delete lines, reason, condition và note\.

- `sales.return_exchange.cancel`: cancel draft\.

- Manual\-price permission \+ Theme 4 policy: chỉnh giá exchange khi được phép\.

- Permission xem commercial/pricing allocation: xem D\-11 detail\.

- Permission inventory availability/reservation: xem chi tiết Theme 7 context\.

- Không có create/update permission → D\-02/D\-18 phù hợp; không render editable controls\.

- Permission bị thu hồi khi đang mở → chặn update/continue, giữ audit context và xử lý reservation theo backend policy\.

    

**Loading, empty and error behavior**

- D\-01 không flash cached returnable lines như current\.

- Standard empty state nói `Chọn ít nhất một hàng khách trả`; không gọi là error trước khi user tương tác\.

- No returnable lines → D\-02; không tạo empty draft mới\.

- Product search failure cô lập exchange subview; persisted returned lines không mất\.

- Valuation error giữ line data nhưng đánh dấu blocked/unavailable\.

- Save/update uncertain không close như success\.

- Error summary focus first blocker; line errors nằm sát affected line/control\.

- Response muộn từ draft/order khác bị bỏ qua theo identity/version context\.

    

**Feedback and microcopy**

- Dùng `Hàng khách trả` và `Hàng khách nhận`, tránh hai nhãn đều là `Hàng đổi`\.

- Dùng `Có thể trả` cho authoritative capacity; dùng `Đang giữ trong phiếu này` cho own reservation khi có\.

- Dùng `Phiếu nháp`, không dùng `Đã đổi/trả` trước confirmation\.

- Dùng `Dự kiến hoàn hoặc giảm nghĩa vụ`, không mặc định `Sẽ hoàn tiền`\.

- Dùng `Giá theo đơn nguồn` cho returned side và `Giá hiện hành` cho exchange side\.

- Stale change message phải nói rõ saved value không bị tự động sửa\.

- Save status không hiển thị `Đã lưu` cho result uncertain\.

    

**Accessibility**

- Reading order: source context → returned section → exchange section → valuation → readiness → actions\.

- Mandatory/optional section không chỉ phân biệt bằng màu\.

- Quantity input công bố unit, min/max/current available and error\.

- Capacity breakdown dùng semantic labels, không chỉ compact equation\.

- Reason/condition label/error gắn đúng line identity\.

- Search results/scan ambiguity keyboard and screen\-reader navigable\.

- Valuation direction đọc bằng lời trước amount/sign\.

- Conflict comparison đọc saved/current/proposed theo thứ tự rõ\.

- Bottom sheet/editor trap focus và trả focus về line/action trigger\.

    

**Responsive behavior**

- Mobile: returned section trước exchange, editors là full\-screen/bottom sheet, valuation/sticky actions ở cuối an toàn\.

- Mobile không dùng side\-by\-side return/exchange columns vì dễ mất source context; dùng stacked sections với summary persistent\.

- Tablet/web: two\-column `Khách trả` và `Khách nhận`, valuation sticky ở side rail\.

- Large lists dùng search/filter và virtualized rendering nếu cần nhưng giữ selected\-line accessibility\.

- Valuation detail chuyển cards → table ở viewport rộng mà không đổi semantics\.

- Sticky actions không che last line, error, keyboard hoặc reservation expiry message\.

    

#### Low\-fi wireframes

**D\-01 — Precheck/start loading****\(không cần thiết\)**

```Plain Text
┌──────────────────────────────┐
│ ‹  Phiếu đổi/trả             │
│ Đơn #DH-002586               │
├──────────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒       │
│ ▒▒▒▒▒▒▒▒▒▒▒▒                │
│                              │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒       │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒              │
│                              │
│ Đang kiểm tra hàng có thể trả│
│ và các nghiệp vụ liên quan…  │
└──────────────────────────────┘
```



**D\-02 — Precheck blocked**

```Plain Text
┌──────────────────────────────┐
│ Không thể lập phiếu đổi/trả  │
├──────────────────────────────┤
│ Đơn #DH-002586 đã được hủy   │
│ hoặc không còn hàng có thể   │
│ trả trong phạm vi hiện tại.  │
│                              │
│ Không có phiếu nháp mới được │
│ tạo.                         │
│                              │
│          [Về chi tiết đơn]   │
└──────────────────────────────┘
```



**D\-03 — Existing draft found**

```Plain Text
┌──────────────────────────────┐
│ Đã có phiếu đang lập         │
├──────────────────────────────┤
│ Nháp #DT-00128 · Version 4   │
│ 2 hàng trả · 1 hàng nhận     │
│ Cập nhật 20/07 13:55         │
│                              │
│ Tiếp tục phiếu hiện có để    │
│ tránh tạo reservation trùng. │
│                              │
│ [Quay lại]                   │
│ [Tiếp tục phiếu nháp]        │
└──────────────────────────────┘
```



**D\-04 — Standard start**

```Plain Text
┌──────────────────────────────┐
│ ‹  Phiếu đổi/trả    Đã lưu   │
│ Nháp #DT-00128               │
├──────────────────────────────┤
│ Đơn #DH-002586 · Nguyễn An   │
├──────────────────────────────┤
│ HÀNG KHÁCH TRẢ · Bắt buộc   │
│ ☐ Thức ăn A · Gói            │
│ Bán 3 · Đã trả 1 · Có thể 2  │
│                              │
│ ☐ Thuốc B · Hộp              │
│ Bán 1 · Có thể trả 1         │
│                              │
│ Chọn ít nhất một hàng trả.   │
├──────────────────────────────┤
│ [Lưu và đóng] [Tiếp tục QT]  │
└──────────────────────────────┘
```



**D\-05 — Quick full\-return prefilled**

```Plain Text
┌──────────────────────────────┐
│ ‹  Trả toàn bộ      Đã lưu   │
│ Nháp #DT-00128               │
├──────────────────────────────┤
│ ℹ Từ yêu cầu hủy đơn         │
│ Đã chọn toàn bộ quantity hiện│
│ còn có thể trả: 3/4 dòng.    │
│ 1 dòng đã được trả trước đó. │
├──────────────────────────────┤
│ ☑ Thức ăn A · Trả 2/2    [›] │
│   Chưa chọn lý do/tình trạng │
│ ☑ Thuốc B · Trả 1/1      [›] │
│   Chưa chọn tình trạng       │
│ [Áp dụng thông tin hàng loạt]│
├──────────────────────────────┤
│ [Lưu và đóng] [Hoàn thiện ›] │
└──────────────────────────────┘
```



**D\-06 — Returned\-line editor**

```Plain Text
┌──────────────────────────────┐
│ ×  Thông tin hàng khách trả  │
├──────────────────────────────┤
│ Thức ăn A · Gói              │
│ Bán 3 · Đã trả 1             │
│ Đang giữ phiếu khác 0        │
│ Có thể chọn tối đa 2         │
│                              │
│ Số lượng trả                 │
│ [ − ]       2        [ + ]   │
│ Lý do trả *      [Chọn    ›] │
│ Tình trạng *     [Chọn    ›] │
│                              │
│                    [Áp dụng] │
└──────────────────────────────┘
```



**D\-07 — Full\-return scope changed**

```Plain Text
┌──────────────────────────────┐
│ ℹ Đã chuyển sang trả một phần│
├──────────────────────────────┤
│ Anh đã giảm quantity hoặc thêm│
│ hàng khách nhận. Phiếu không │
│ còn là luồng trả toàn bộ nhanh│
│                              │
│ Valuation sẽ được tính lại.  │
│                    [Đã hiểu] │
└──────────────────────────────┘
```



**D\-08 — Exchange product search**

```Plain Text
┌──────────────────────────────┐
│ ‹  Thêm hàng khách nhận      │
├──────────────────────────────┤
│ [⌕ Tên, SKU hoặc barcode] [▣]│
├──────────────────────────────┤
│ Sản phẩm C · SP-C            │
│ Hộp · 120.000 ₫ · Còn hàng   │
│                     [Chọn ›] │
│                              │
│ Sản phẩm D · SP-D            │
│ Chai/Gói · Chọn đơn vị       │
│                     [Chọn ›] │
├──────────────────────────────┤
│ Không hỗ trợ tạo sản phẩm mới│
└──────────────────────────────┘
```



**D\-09 — Exchange\-line editor**

```Plain Text
┌──────────────────────────────┐
│ ×  Hàng khách nhận           │
├──────────────────────────────┤
│ Sản phẩm C                   │
│ Đơn vị bán        [Hộp    ›] │
│ Số lượng          [2       ] │
│                              │
│ GIÁ HIỆN HÀNH                │
│ 120.000 ₫/Hộp · Theme 4      │
│ Thành tiền         240.000 ₫ │
│ Tồn khả dụng              12 │
│                              │
│                      [Thêm]  │
└──────────────────────────────┘
```



**D\-10 — Working draft**

```Plain Text
┌──────────────────────────────┐
│ ‹  Phiếu đổi/trả    Đã lưu   │
│ #DT-00128 · Version 6        │
├──────────────────────────────┤
│ HÀNG KHÁCH TRẢ · 2           │
│ Thức ăn A · 2 Gói · 200.000₫ │
│ Lỗi hàng · Chưa mở       [›] │
│ Thuốc B · 1 Hộp · 150.000 ₫  │
│ Không phù hợp · Còn nguyên[›]│
├──────────────────────────────┤
│ HÀNG KHÁCH NHẬN · 1          │
│ Sản phẩm C · 1 Hộp · 120.000₫│
│ Giá hiện hành · Còn hàng [›] │
│ [+ Thêm hàng khách nhận]     │
├──────────────────────────────┤
│ Hàng trả           350.000 ₫ │
│ Hàng nhận          120.000 ₫ │
│ Dự kiến hoàn/giảm  230.000 ₫ │
│ [Xem chi tiết cách tính]     │
├──────────────────────────────┤
│ [Lưu và đóng] [Tiếp tục QT ›]│
└──────────────────────────────┘
```



**D\-11 — Valuation details**

```Plain Text
┌──────────────────────────────┐
│ ×  Chi tiết cách tính        │
├──────────────────────────────┤
│ HÀNG TRẢ · Giá theo đơn nguồn│
│ Giá dòng            370.000 ₫│
│ Phân bổ khuyến mãi  -20.000 ₫│
│ Giá trị trả         350.000 ₫│
├──────────────────────────────┤
│ HÀNG NHẬN · Giá hiện hành    │
│ Giá trị nhận        120.000 ₫│
├──────────────────────────────┤
│ Chênh lệch         -230.000 ₫│
│ Dự kiến hoàn hoặc giảm nghĩa │
│ vụ; quyết toán ở bước sau.   │
│                       [Đóng] │
└──────────────────────────────┘
```



**D\-12 — Saving/uncertain**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Chưa xác định kết quả lưu  │
├──────────────────────────────┤
│ Kết nối bị gián đoạn khi cập │
│ nhật phiếu. Không gửi lại yêu│
│ cầu trước khi kiểm tra version│
│                              │
│ [Ở lại phiếu]                │
│ [Kiểm tra kết quả]           │
└──────────────────────────────┘
```



**D\-13 — Resume revalidation summary**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Dữ liệu hiện hành đã đổi   │
├──────────────────────────────┤
│ 2 nội dung cần kiểm tra:     │
│                              │
│ • Thức ăn A: quantity có thể │
│   trả đã giảm.               │
│ • Sản phẩm C: có giá mới.    │
│                              │
│ Dữ liệu đã lưu chưa bị tự    │
│ động thay thế.               │
│          [Kiểm tra thay đổi] │
└──────────────────────────────┘
```



**D\-14 — Returnable/reservation conflict**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Số lượng cần điều chỉnh    │
├──────────────────────────────┤
│ Thức ăn A · Gói              │
│ Đã lưu trong phiếu         5 │
│ Hiện có thể trả tối đa     3 │
│                              │
│ Reservation cũ đã hết hạn.   │
│ Hệ thống chưa tự giảm số lượng│
│                              │
│ [Xóa dòng] [Điều chỉnh SL]   │
└──────────────────────────────┘
```



**D\-15 — Price/product/inventory stale**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Giá hàng nhận đã thay đổi  │
├──────────────────────────────┤
│ Sản phẩm C · 1 Hộp           │
│ Giá đã lưu        120.000 ₫  │
│ Giá hiện hành     125.000 ₫  │
│                              │
│ Chênh lệch dự kiến sẽ thay đổi│
│ từ -230.000 ₫ thành -225.000 ₫│
│                              │
│ [Xóa dòng] [Chấp nhận giá mới]│
└──────────────────────────────┘
```



**D\-16 — Draft version conflict**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Phiếu đã được cập nhật     │
├──────────────────────────────┤
│ Một phiên khác đã lưu version│
│ mới hơn của #DT-00128.       │
│                              │
│ Hệ thống không tự gộp lines, │
│ quantity, reason hoặc note.  │
│                              │
│ [Về chi tiết đơn]            │
│ [Tải bản mới nhất]           │
└──────────────────────────────┘
```



**D\-17 — Cancel\-draft confirmation**

```Plain Text
┌──────────────────────────────┐
│ Hủy phiếu nháp?              │
├──────────────────────────────┤
│ Lines và ghi chú trong phiếu │
│ sẽ không còn chỉnh sửa được. │
│ Các reservation sẽ được giải │
│ phóng.                       │
│                              │
│ Đơn nguồn không bị thay đổi. │
│                              │
│ [Giữ phiếu] [Hủy phiếu nháp]│
└──────────────────────────────┘
```



**D\-18 — Draft cancelled/expired/invalid**

```Plain Text
┌──────────────────────────────┐
│ Phiếu không còn hiệu lực     │
├──────────────────────────────┤
│ Nháp #DT-00128 đã bị hủy, hết│
│ hạn hoặc bị chặn bởi nghiệp vụ│
│ mới hơn.                     │
│                              │
│ Không thể mở lại, cập nhật   │
│ hoặc chuyển sang quyết toán. │
│                              │
│          [Về chi tiết đơn]   │
└──────────────────────────────┘
```



#### Visuals

TBD\.



#### Traceability

TBD\.

### 5\.5\.13 SG\-12 — Quyết toán chênh lệch

#### Overview

- Purpose: Cho phép người dùng lập settlement plan cân bằng cho chênh lệch đổi/trả, review toàn bộ nghĩa vụ và xác nhận ReturnExchangeOrder một cách idempotent\.

- Related epic: EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch\.

- Related business flow: BF\-08 — Đổi/trả \& quyết toán\.

- Business flow group: Post\-sale\.

- Primary users: Nhân viên bán hàng, quản lý cửa hàng và người dùng có quyền quyết toán/confirm đổi trả\.

- Primary task: Phân bổ chênh lệch vào thu thêm, hoàn tiền, khoản phải thu, giảm/cấn trừ công nợ hoặc `không chênh lệch`, sau đó xác nhận phiếu đổi/trả\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: SG\-12 là obligation planner, không phải một ô nhập tiền\. UI phải diễn đạt đúng chiều nghĩa vụ, capacity của từng phương án, trạng thái plan và ranh giới owner domain để ngăn over\-allocation, wrong\-direction và double count\.

- Architectural role: SG\-12 sở hữu plan/review/final confirmation\. Post\-sale Operations commit ReturnExchangeOrder và durable requirements; Sales Settlement ghi payment/refund; Theme 6 sở hữu receivable ledger\. SG\-13 là canonical result/status hub sau confirmation\.

- Scope boundary: SG\-12 không sửa trực tiếp payment/refund transaction hoặc receivable ledger, không tự quyết định inventory disposition và không tiếp tục cho sửa lines sau final review\. Nếu hàng hóa/valuation thay đổi, quay lại SG\-11 và lập plan mới\.

    

#### Entry \& exit

- Entry points:

    - CTA `Tiếp tục quyết toán` từ SG\-11 với ReturnExchangeOrder draft/version và valuation context current\.

    - Resume draft đã có settlement plan nhưng chưa confirmed từ SG\-08 hoặc task context\.

    - Recovery sau ConfirmReturnExchange/payment/refund/receivable result chưa xác định bằng operation/correlation context\.

- Exit points:

    - `Quay lại kiểm tra hàng hóa` → SG\-11 trước confirmation; plan trở stale nếu lines/valuation thay đổi\.

    - `Lưu và đóng` → SG\-08 khi draft/plan update result đã xác định\.

    - Confirmation accepted → D\-18 rồi SG\-13 — Kết quả \& chi tiết đổi/trả\.

    - Valuation/line/source context stale → D\-14, quay SG\-11\.

    - Settlement/receivable/method context stale nhưng lines vẫn current → D\-14, rebuild plan tại SG\-12\.

    - Draft version conflict → D\-15, tải latest draft; không auto\-merge allocations\.

    - Không còn phương án hợp lệ hoặc thiếu permission → D\-16; lưu/đóng hoặc xử lý blocker\.

    - Confirmation result uncertain → D\-17; query authoritative result trước retry/exit có nguy cơ tạo trùng\.

        

#### Screen/state inventory

|State|Class|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|System state — Context loading|Lấy valuation, settlement, receivable, methods và policy authoritative|—|Không dùng plan cache như current|
|D\-02|Decision screen — Customer pays more|Giải thích nghĩa vụ dương và phương án collect/receivable|Lập kế hoạch|`net_difference > 0`|
|D\-03|Decision screen — Customer receives benefit|Giải thích nghĩa vụ âm và phương án refund/offset/reversal|Lập kế hoạch|`net_difference < 0`|
|D\-04|Decision screen — No difference|Xác nhận không có nghĩa vụ tiền mới|Xem lại \& xác nhận|`net_difference = 0` after rounding|
|D\-05|Planner — Collect|Phân bổ amount vào payment intent|Áp dụng|Sales Settlement owner|
|D\-06|Planner — Refund|Phân bổ amount vào refund intent|Áp dụng|Không vượt refund capacity|
|D\-07|Planner — Receivable|Tạo khoản phải thu hoặc giảm/cấn trừ nghĩa vụ hợp lệ|Áp dụng|Theme 6 owner|
|D\-08|Planner — Mixed|Kết hợp payment/refund và receivable allocations|Hoàn tất phân bổ|Tổng phải cân bằng|
|D\-09|Editor — Method \& amount|Chọn method, amount và permitted reference|Thêm/Cập nhật|Inputs luôn là số dương|
|D\-10|Validation state — Unbalanced/invalid|Hiển thị remaining, capacity, direction và permission errors|Sửa phân bổ|Không confirm|
|D\-11|Planner variant — Full\-return partial\-paid split|Tách refund đã thu và reversal chưa thu, tránh double count|Dùng kế hoạch|System\-recommended/mandatory split|
|D\-12|Review screen — Final confirmation|Review lines, valuation, plan, reason và impacts|Xác nhận đổi/trả|Điểm confirmation cuối|
|D\-13|Processing — Confirming|Gửi ConfirmReturnExchange với idempotency|—|Chặn double submit|
|D\-14|Conflict — Context stale|Xử lý valuation, settlement, receivable hoặc method thay đổi|Kiểm tra lại|Có thể route SG\-11|
|D\-15|Conflict — Draft/version changed|Ngăn ghi đè plan/draft mới hơn|Tải bản mới nhất|Không auto\-merge|
|D\-16|Blocked — Policy/permission/no viable plan|Giải thích vì sao không thể cân bằng/confirm|Đổi phương án / Lưu và đóng|Guest/credit/method/capacity cases|
|D\-17|Recovery — Uncertain/partial result|Query result và khóa processed/pending allocations|Kiểm tra kết quả|Không double count|
|D\-18|Handoff — Confirmed/processing|Xác nhận business fact đã ghi nhận và chuyển SG\-13|Xem kết quả|Không cho sửa/confirm lại|



#### UI Contract

**Core obligation model**

- `net_difference = exchange_value - return_value`\.

- UI tách dấu và amount:

    - `net_difference > 0` → direction `Khách trả thêm`, required amount = net difference\.

    - `net_difference < 0` → direction `Khách được hoàn hoặc giảm nghĩa vụ`, required amount = absolute net difference\.

    - `net_difference = 0` sau rounding → direction `Không chênh lệch`, required amount = 0\.

- Allocation input luôn là số không âm theo currency precision; người dùng không nhập amount âm để biểu diễn refund\.

- Direction quyết định tập allocation type được phép; không cho trộn collect với refund trong cùng requirement nếu business meaning không hỗ trợ\.

    

**Settlement\-plan equation**

- Plan tracking dùng bốn bucket không chồng lấn:

    - `processed_amount`: owner transaction/impact đã authoritative recorded cho operation hiện tại\.

    - `pending_amount`: owner command/impact đã tiếp nhận hoặc uncertain, không được phân bổ lại\.

    - `planned_amount`: allocation hợp lệ chưa submit trong confirmation hiện tại\.

    - `remaining_amount = required_amount - processed_amount - pending_amount - planned_amount`\.

- Plan balanced khi remaining amount bằng 0 sau currency rounding và không allocation nào invalid/stale\.

- Processed/pending allocation read\-only; retry phải theo correlation/idempotency của allocation đó\.

- Không lấy prior payment/refund của source order làm `processed_amount` của ReturnExchangeOrder; prior context chỉ xác định capacity/allocation requirement\.

    

**User intent**

- Biết ai đang có nghĩa vụ với ai và chính xác bao nhiêu\.

- Hiểu tại sao một phương án thu/hoàn/công nợ được phép hoặc bị chặn\.

- Phân bổ toàn bộ nghĩa vụ mà không vượt amount hoặc capacity\.

- Hiểu full return thanh toán một phần được tách refund và receivable reversal ra sao\.

- Review plan cùng hàng hóa/valuation trước final confirmation\.

- Không tạo payment/refund/receivable trùng khi response mất hoặc owner chỉ xử lý một phần\.

- Biết khi nào operation đã confirmed và phải chuyển SG\-13 thay vì sửa plan\.

    

**Information hierarchy**

1. ReturnExchangeOrder identity và valuation freshness\.

2. Direction \+ required amount bằng ngôn ngữ người dùng\.

3. Customer identity/credit eligibility và authoritative settlement context\.

4. Allowed settlement options/capacities\.

5. Allocation list và equation processed/pending/planned/remaining\.

6. Blocker/warning và plan readiness\.

7. Final review/confirmation\.

    

**Flow architecture**

|Stage|User decision|System responsibility|Mutation status|
|---|---|---|---|
|Load requirement|Mở SG\-12|Lấy current valuation/settlement/receivable/method/policy|Không official transaction|
|Choose plan|Chọn allowed channels|Validate direction, customer, capacity và permissions|Draft plan only|
|Balance|Phân bổ toàn bộ amount|Tính remaining và revalidate contexts|Draft plan only|
|Review|Kiểm tra lines/valuation/plan/reason|Dựng canonical confirmation payload|Chưa confirm|
|Confirm|Xác nhận đổi/trả|Commit ReturnExchangeOrder \+ durable requirements idempotently|Business fact created|
|Handoff|Xem processing/result|Chuyển canonical tracking sang SG\-13|Không sửa plan|



- D\-12 là final confirmation surface; không thêm generic modal lặp lại sau CTA\.

- Payment/refund/receivable allocation trước confirmation chỉ là intent/requirement, không phải transaction/ledger entry\.

    

**Source\-of\-truth contract**

|Information|Source|Owner|SG\-12 rule|
|---|---|---|---|
|Lines/draft/version|ReturnExchangeOrder draft|Post\-sale Operations|Read\-only lines tại SG\-12; quay SG\-11 để sửa|
|Return/exchange values|Current ReturnExchangeValuation|Post\-sale Operations \+ Theme 4|Stale/blocked không plan/confirm|
|Settlement/refund capacity|SalesOrderSettlement/current owner query|Sales Settlement|Không tự tính từ UI transaction rows|
|Customer identity/credit eligibility|Current customer/policy context|Theme 3 \+ tenant policy|Guest không dùng receivable|
|Outstanding/eligible receivables|Authoritative ledger context|Theme 6|Không sửa ledger trực tiếp|
|Payment/refund methods|Current method/policy context|Sales Settlement/Theme 1|Revalidate at confirm|
|Settlement plan|Versioned ReturnExchangeOrder context|Post\-sale Operations|Allocations phải balanced/current|
|Confirm result|ConfirmReturnExchange/GetReturnExchange|Post\-sale Operations|Authoritative business fact|
|Owner allocation status|Payment/refund/receivable impact queries|Sales Settlement/Theme 6|Processed/pending locked|



**Displayed data**

- ReturnExchangeOrder ID/status/version, source order code, customer and entry source\.

- Returned/exchange line count and values; valuation version/freshness\.

- Net difference, direction and required settlement type\.

- Customer identity \(`Khách lẻ` or identified\), credit eligibility and policy constraints\.

- Authoritative amounts relevant to capacity:

    - Net confirmed collection/refund capacity\.

    - Outstanding receivable tied/eligible for reversal or offset\.

    - New receivable eligibility/limit when net difference positive\.

- Active payment/refund methods and restrictions\.

- Allocation rows: type, owner, method/ledger context, amount, capacity, status and correlation indicator\.

- Processed, pending, planned and remaining totals\.

- Validation/blocker and updated time/context version\.

- Final\-review source summary, reason and expected owner impacts\.

    

**User inputs**

- Allocation type/channel from allowed options\.

- Payment/refund method and positive amount\.

- Eligible receivable target/type and positive amount\.

- Optional permitted transaction reference/note\.

- Acceptance of new context/plan after explicit revalidation\.

- Explicit final confirmation at D\-12\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG12\-E01|Top bar|`Quyết toán chênh lệch`|Giữ draft/source context|D\-01 đến D\-18 when permitted|
|SG12\-E02|Back action|`Quay lại kiểm tra hàng hóa`|Mở SG\-11 trước confirm|Disabled critical confirm window|
|SG12\-E03|Draft identity|`Phiếu #...` · Version|Nhận diện source draft|Always after load|
|SG12\-E04|Valuation summary|Hàng trả · hàng nhận · chênh lệch|Giải thích source obligation|Current/stale|
|SG12\-E05|Direction banner|`Khách trả thêm` / `Hoàn hoặc giảm nghĩa vụ` / `Không chênh lệch`|Dẫn dắt allowed plan|D\-02/D\-03/D\-04|
|SG12\-E06|Customer context|Customer/guest · credit eligibility|Giới hạn receivable options|D\-02 to D\-11|
|SG12\-E07|Settlement context|Đã thu · đã hoàn · refund capacity|Giải thích cash capacity|Permission\-masked as needed|
|SG12\-E08|Receivable context|Outstanding/eligible amount|Giải thích receivable capacity|Identified customer \+ permission|
|SG12\-E09|Option card|Thu thêm / Hoàn tiền / Phải thu / Giảm công nợ / Kết hợp|Mở planner|Allowed options only|
|SG12\-E10|Allocation list|Type · method/target · amount · status|Edit draft allocations|Pre\-confirm editable only|
|SG12\-E11|Add\-allocation action|`Thêm cách quyết toán`|Mở D\-09|Remaining \>0 \+ option available|
|SG12\-E12|Method selector|Active payment/refund methods|Chọn owner method|D\-09|
|SG12\-E13|Receivable selector|Eligible obligation/type|Chọn Theme 6 requirement|D\-07/D\-09|
|SG12\-E14|Amount input|`Số tiền`|Positive currency input|D\-05 to D\-09|
|SG12\-E15|Capacity hint|`Tối đa ...`|Giải thích limit|Method/allocation context|
|SG12\-E16|Apply\-allocation action|`Thêm` / `Cập nhật`|Versioned plan update|Valid input|
|SG12\-E17|Remove\-allocation action|`Xóa`|Remove planned allocation|Not processed/pending|
|SG12\-E18|Plan equation|Đã xử lý · Đang chờ · Đã lập · Còn lại|Tóm tắt balance|Always in planner/review|
|SG12\-E19|Validation summary|N blockers/errors|Focus resolution|D\-10/D\-16|
|SG12\-E20|Recommended\-plan banner|`Kế hoạch theo thanh toán hiện hành`|Explain deterministic full\-return split|D\-11|
|SG12\-E21|Use\-plan action|`Dùng kế hoạch này`|Persist proposed allocations|D\-11|
|SG12\-E22|Save\-and\-close action|`Lưu và đóng`|Flush plan/version then exit|Result known/saved|
|SG12\-E23|Review action|`Xem lại & xác nhận`|Revalidate and open D\-12|Balanced/current plan|
|SG12\-E24|Review content|Lines · valuation · plan · reason · impacts|Final decision context|D\-12|
|SG12\-E25|Confirm action|`Xác nhận đổi/trả`|Send ConfirmReturnExchange|D\-12|
|SG12\-E26|Processing indicator|`Đang xác nhận đổi/trả…`|Reflect command|D\-13|
|SG12\-E27|Revalidate action|`Kiểm tra lại`|Refresh required contexts|D\-14/D\-16|
|SG12\-E28|Reload\-latest action|`Tải bản mới nhất`|Replace current draft/plan view|D\-15|
|SG12\-E29|Check\-result action|`Kiểm tra kết quả`|Query confirmation/allocation operations|D\-17|
|SG12\-E30|Result action|`Xem kết quả`|Open SG\-13|D\-18|



**Context\-loading behavior**

- D\-01 fetches current draft/version, valuation, source settlement, customer/credit eligibility, receivable context, allowed methods, permissions and policy\.

- SG\-12 only starts planning when ReturnExchangeOrder is editable draft, has at least one returned line and valuation is current/not blocked\.

- Lines are read\-only in SG\-12; any line change routes back SG\-11 and invalidates plan\.

- Client must correlate all responses to draft ID/version and discard late responses for prior context\.

- Failure of a required context does not default to permissive allocation; use D\-16/retry\.

    

**Direction and amount\-presentation behavior**

- Primary banner uses customer\-centric wording, not just plus/minus sign\.

- Amount inputs are always positive; type label conveys `Thu` or `Hoàn/Giảm`\.

- Negative net difference may appear in valuation detail for audit, but planning summary shows absolute required amount with direction\.

- Rounding uses Theme 1 currency policy; microscopic difference rounded to zero produces settlement type `none`\.

- Direction change caused by new valuation invalidates entire plan\.

    

**Allowed\-plan matrix**

|Direction/context|Allowed allocation|Not allowed|Default UX|
|---|---|---|---|
|Customer pays more, guest|Collect|New receivable|Collect full required amount|
|Customer pays more, identified \+ credit eligible|Collect, new receivable, mixed|Refund/reversal|Offer policy\-recommended plan|
|Customer receives benefit, guest|Refund within capacity|Receivable offset/reversal without ledger|Refund plan or blocker|
|Customer receives benefit, identified \+ eligible receivable|Refund, reversal/offset, mixed|New customer credit beyond policy|Offer context\-based plan|
|Full return, partially paid|Refund collected portion \+ reverse unpaid receivable|Double refund/reversal|D\-11 recommended split|
|No difference|None|Any positive allocation|Direct review/confirm|



- Không có generic `Bỏ qua chênh lệch` hoặc `Xóa nợ` option trừ khi một policy/domain contract riêng được bổ sung; SG\-12 không tự tạo write\-off\.

    

**Collect behavior**

- Collect allocation chỉ dùng khi required direction là customer pays more\.

- Sum collect \+ new receivable allocations không vượt remaining positive obligation\.

- Collect method phải active, permitted and supported for current store/user\.

- Actual payment transaction chỉ được tạo after confirmation qua `RecordSalesPayment` và tham chiếu ReturnExchangeOrder\.

- Multiple collect methods chỉ khi policy supports split; each allocation has independent method/amount\.

- Guest phải collect đủ required amount vì không được tạo new receivable\.

- Payment method disabled before confirm makes allocation stale and requires reselection\.

    

**Refund behavior**

- Refund allocation chỉ dùng khi customer receives benefit\.

- Refund không vượt remaining obligation, current refundable capacity or method\-specific limit\.

- Prior refunds/voids/returns from source context are re\-evaluated to avoid duplicate benefit\.

- Actual refund transaction chỉ after confirmation qua `RecordSalesRefund` và tham chiếu ReturnExchangeOrder\.

- Refund method options follow owner/policy; UI không tự assume original method luôn khả dụng\.

- `Refund pending` is not available capacity for a new allocation; it enters pending bucket when associated with this ReturnExchangeOrder\.

    

**Receivable behavior**

- New receivable only for identified, eligible customer when direction is customer pays more\.

- Receivable reversal/offset only when direction is customer receives benefit and Theme 6 returns eligible ledger context\.

- Receivable allocation creates requirement/impact for Theme 6; SG\-12 never edits ledger directly\.

- Reversal/offset amount không vượt eligible outstanding receivable and remaining obligation\.

- `receivable_offset` does not create a new customer credit beyond eligible obligations\.

- Guest cannot create receivable or use arbitrary offset/reversal without ledger identity\.

- Business rejection from Theme 6 cannot be bypassed with technical retry\.

    

**Mixed\-plan behavior**

- Positive mixed plan = collect \+ new receivable\.

- Negative mixed plan = refund \+ receivable reversal/offset\.

- Allocation lines cannot cross direction or double count same capacity\.

- Plan shows owner domain per allocation so user understands what can process asynchronously\.

- Removing/editing planned allocation recomputes remaining; processed/pending allocation cannot be edited\.

- Mixed plan confirmation may produce partial downstream progress; canonical status after confirmation belongs SG\-13\.

    

**Full\-return partial\-payment behavior**

- D\-11 uses authoritative net collection/refund capacity and outstanding receivable tied/eligible for reversal\.

- Recommended allocation: refund actual collected portion and reverse unpaid receivable portion, adjusted for prior refund/return/policy\.

- `refund_amount + receivable_reversal_amount` must equal benefit amount handled for customer after rounding and prior effects\.

- UI explicitly says reversal is removal of unpaid obligation, not cash paid to customer\.

- Deterministic/policy\-mandated allocation can be locked; editable only within owner capacities/policy\.

- User still reviews plan; no automatic confirmation\.

    

**No\-difference behavior**

- D\-04 uses settlement type `none` and no method/amount input\.

- Plan equation is required 0, remaining 0\.

- Final confirmation still required because returned/exchange lines and downstream inventory/pricing/e\-invoice impacts remain\.

- SG\-12 must not create zero\-value payment/refund/receivable transactions\.

    

**Allocation editor behavior**

- Amount input accepts positive value only, formatted by currency precision\.

- Max is minimum of remaining amount, method capacity and permission/policy capacity\.

- Zero allocation is not stored\.

- User cannot directly edit processed/pending line; opens status/detail instead\.

- Method/reference normalization follows owner contract; no arbitrary free\-text method\.

- Duplicate method allocations follow policy: merge explicitly or keep separate identities; no double count\.

- Discrete `Thêm/Cập nhật/Xóa` operations persist versioned plan; not every keystroke updates draft\.

    

**Balance and validation behavior**

- D\-10 distinguishes:

    - `Chưa phân bổ hết` when remaining \>0\.

    - `Vượt nghĩa vụ` when sum exceeds required\.

    - `Vượt khả năng` when allocation exceeds refund/receivable/method capacity\.

    - `Sai chiều` when allocation type conflicts with direction\.

    - `Không đủ quyền/không đủ điều kiện` when policy blocks\.

    - `Dữ liệu đã cũ` when context version changed\.

- Review CTA only enabled when remaining =0, all allocations current/valid, draft plan saved and no required owner context uncertain\.

- UI does not silently reduce allocation to max; shows requested and max, asks user to update\.

    

**Persistence and resume behavior**

- Settlement plan is stored with ReturnExchangeOrder draft/version and the valuation/settlement/receivable contexts used\.

- Each plan update uses expected version; successful update increases version\.

- `Lưu và đóng` waits for known save result; uncertain result cannot be labeled saved\.

- Resume reconstructs planned allocations and re\-fetches all capacities/eligibility/methods\.

- Stored plan whose context changed is marked stale; no silent method switch, amount clamp or reallocation\.

- Processed/pending allocation discovered during recovery is locked and removed from available amount through plan equation\.

    

**Revalidation routing behavior**

- Line, quantity, product, unit, pricing or valuation change → D\-14 with primary route `Quay lại kiểm tra hàng hóa` to SG\-11\.

- Settlement totals, prior refund, credit eligibility, outstanding receivable or methods change while valuation remains valid → D\-14 and rebuild plan in SG\-12\.

- Direction/required amount change invalidates all planned allocations; preserve them only as read\-only reference\.

- Method disabled may invalidate only affected planned allocation, but final plan must be reviewed again\.

- Revalidation never silently changes plan then keeps confirmation enabled\.

    

**Version\-conflict behavior**

- Save/confirm uses expected ReturnExchangeOrder version\.

- Version mismatch opens D\-15; no auto\-merge lines, valuation or allocations\.

- `Tải bản mới nhất` replaces current working view with authoritative draft/plan after warning about local unsaved editor input\.

- Local unsaved allocation may be retained as copy/reference, not automatically inserted\.

- After reload, full context/revalidation and final review are required\.

    

**Policy/permission/no\-viable\-plan behavior**

- D\-16 handles guest receivable restriction, credit ineligibility, insufficient refund capacity, inactive methods, missing permissions or no combination that balances plan\.

- Message identifies which capacity/permission prevents completion without exposing sensitive ledger detail\.

- Save/close remains available when safe; confirmation remains blocked\.

- No viable plan must not be bypassed by arbitrary manual amount or write\-off\.

- Permission removed before confirmation blocks command even if plan previously valid\.

    

**Final\-review behavior**

- D\-12 shows source order/draft, returned/exchange summary, current valuation, direction/amount, every allocation, plan equation, reason and expected owner impacts\.

- Wording explains confirmation makes ReturnExchangeOrder a business fact; payment/refund/receivable/inventory requirements may continue processing\.

- Full\-return from cancellation attempt is identified as return/exchange, not order cancellation\.

- Original SalesOrder lifecycle remains completed; return status changes only after completed returns are recorded\.

- `Xác nhận đổi/trả` is the single final CTA; no generic second modal\.

- CTA not auto\-focused and disabled if any context stale/uncertain\.

    

**Confirm and orchestration behavior**

- Confirm sends return\_exchange\_id, expected version, lines/valuation references, settlement plan, reason, actor and idempotency context\.

- Backend revalidates permission, source lifecycle, cancellation conflict, returnable quantities, products, units, pricing, inventory, valuation and settlement requirement\.

- Valid command transitions draft → confirmed and emits `ReturnExchangeConfirmed` with durable impact/outbox records\.

- Payment/refund commands go to Sales Settlement; receivable requirement goes Theme 6; other impacts go owner domains\.

- Business decision and durable local records commit atomically in Post\-sale Operations; no distributed transaction across owners\.

- Confirmed order can move processing while mandatory requirements execute; SG\-12 no longer editable\.

    

**Idempotency and owner\-allocation behavior**

- ConfirmReturnExchange requires idempotency key; same key\+payload returns same result, different payload conflicts\.

- Each owner allocation/impact has correlation and idempotency traceable to ReturnExchangeOrder\.

- Double tap locks CTA; backend remains source of guarantee\.

- RecordSalesPayment/RecordSalesRefund and receivable impact must not duplicate on retry\.

- Owner success \+ response loss moves allocation to uncertain/pending until queried; never back to available amount by client assumption\.

- Mixed plan partial processing preserves processed/pending allocations and only retries unresolved allocation in its same context\.

    

**Uncertain/partial\-result behavior**

- D\-17 may appear when confirmation or owner result cannot be determined\.

- If ReturnExchangeOrder still definitely draft and no confirm commit, same confirm context may retry after backend check\.

- If confirmed/processing/completed, plan becomes read\-only and route SG\-13\.

- Processed/pending allocations display status and are locked; remaining cannot be reassigned until owner result is authoritative\.

- Business rejection becomes blocked/reconciliation\_required per policy; technical retry cannot bypass it\.

- SG\-12 does not become long\-term result tracker; once confirmation is known, D\-18 hands off SG\-13\.

    

**Confirmed handoff behavior**

- D\-18 only states what is authoritative: ReturnExchangeOrder confirmed/processing and operation ID/status\.

- It does not claim completed return, refund or receivable update until owner/business requirements record results\.

- Primary CTA `Xem kết quả` opens SG\-13 with return\_exchange\_id and correlation context\.

- Back navigation cannot reopen plan editing after confirmation\.

- Full return result remains ReturnExchangeOrder; no `SalesOrderCancelled` wording/event\.

    

**Business rules and invariants**

- Confirm requires at least one returned line\.

- Valuation and settlement plan must be current and balanced at command time\.

- Guest cannot create receivable or invalid offset/reversal\.

- Allocation total cannot exceed required obligation or owner capacity\.

- Full\-return partial\-paid allocation cannot double count refund and reversal\.

- Payment/refund only after confirmation and reference ReturnExchangeOrder\.

- Receivable ledger changes only through Theme 6\.

- Confirm is idempotent; retries do not duplicate transactions/impacts\.

- SalesOrder/SalesOrderLine commercial snapshot remains unchanged\.

- `fully_returned` does not mean SalesOrder cancelled\.

- Exit before confirm creates no official payment/refund/receivable/inventory effect\.

    

**Permissions**

- `sales.return_exchange.view`: view draft/valuation/plan\.

- `sales.return_exchange.update`: create/update settlement plan on draft\.

- `sales.return_exchange.confirm`: final confirmation\.

- `sales.payment.record`: use collect allocation\.

- `sales.refund.record`: use refund allocation\.

- Permission create receivable: use new receivable allocation\.

- Permission reverse/offset receivable: dùng allocation giảm/đảo công nợ khi khách được hưởng chênh lệch\.

- Permission view settlement detail/refund capacity: view sensitive context\.

- Permission view receivable detail: view eligible ledger context\.

- Missing method permission hides/disables that option with reason; it does not remap allocation automatically\.

- Loss of confirm/owner permission at command time blocks confirmation atomically\.

    

**Loading, empty and error behavior**

- D\-01 uses skeleton for valuation, customer and capacity contexts; it does not flash old plan as valid\.

- No\-difference is a valid D\-04 state, not empty/error\.

- Empty allowed\-method list with required amount \>0 is D\-16, not a blank planner\.

- Owner\-context failure required for safe capacity blocks confirmation\.

- Validation error preserves allocation input and focuses affected row\.

- Save/confirm timeout uses D\-17, not generic failure\.

- Late response from old draft/version is discarded\.

    

**Feedback and microcopy**

- Always state direction in words before amount\.

- Use `Hoàn tiền` only for refund allocation; use `Giảm/đảo công nợ` for receivable benefit\.

- Use `Ghi nhận phải thu` for positive receivable requirement\.

- Use `Đang chờ` for accepted/uncertain owner result; do not call it remaining\.

- Use `Còn phải phân bổ` for plan remaining\.

- Use `Kế hoạch quyết toán`, not `Thanh toán` as umbrella because plan may be refund/reversal/none\.

- Do not label full\-return confirmation as cancellation\.

    

**Accessibility**

- Reading order: direction → required amount → customer/capacity → allocations → equation → errors → action\.

- Direction not conveyed by sign/color alone\.

- Amount field exposes currency, positive\-only rule, min/max and error\.

- Option card has selected/disabled state and accessible reason\.

- Plan equation uses semantic labels, not only arithmetic symbols\.

- Allocation status announces processed/pending/planned/remaining distinctly\.

- Review list reads allocation type, owner/method, amount and status\.

- Error summary focuses first invalid allocation\.

- Sticky CTA and keyboard do not cover remaining amount or error\.

    

**Responsive behavior**

- Mobile: single column, direction/required amount sticky compact header, allocation cards and bottom CTA\.

- Mobile mixed plan uses stacked allocations; equation remains visible near CTA\.

- Tablet/web: planner and obligation/capacity summary can use two columns; review uses table with accessible headers\.

- Full\-return split visualization may use proportional bar only as supplement, never as sole numeric representation\.

- Processed/pending allocations remain visually locked across viewports\.

- Plan rules/confirmation semantics do not change with viewport\.

    

#### Low\-fi wireframes

**D\-01 — Context loading**

```Plain Text
┌──────────────────────────────┐
│ ‹  Quyết toán chênh lệch     │
│ Phiếu #DT-00128              │
├──────────────────────────────┤
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒       │
│ ▒▒▒▒▒▒▒▒▒▒▒▒                │
│                              │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒       │
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒              │
│                              │
│ Đang kiểm tra chênh lệch,    │
│ thanh toán và công nợ…       │
└──────────────────────────────┘
```



**D\-02 — Customer pays more**

```Plain Text
┌──────────────────────────────┐
│ ‹  Quyết toán chênh lệch     │
├──────────────────────────────┤
│ Hàng trả          800.000 ₫  │
│ Hàng nhận       1.100.000 ₫  │
│ KHÁCH TRẢ THÊM    300.000 ₫  │
├──────────────────────────────┤
│ Nguyễn Văn An · Đủ điều kiện │
│ công nợ tối đa 200.000 ₫     │
│                              │
│ ○ Thu thêm                   │
│ ○ Ghi nhận phải thu          │
│ ○ Kết hợp                    │
├──────────────────────────────┤
│          [Lập kế hoạch]      │
└──────────────────────────────┘
```



**D\-03 — Customer receives benefit**

```Plain Text
┌──────────────────────────────┐
│ ‹  Quyết toán chênh lệch     │
├──────────────────────────────┤
│ Hàng trả        1.000.000 ₫  │
│ Hàng nhận         600.000 ₫  │
│ HOÀN/GIẢM NGHĨA VỤ 400.000 ₫ │
├──────────────────────────────┤
│ Có thể hoàn tiền  250.000 ₫  │
│ Công nợ đủ giảm   150.000 ₫  │
│                              │
│ ○ Hoàn tiền                 │
│ ○ Giảm/cấn trừ công nợ       │
│ ○ Kết hợp                    │
├──────────────────────────────┤
│          [Lập kế hoạch]      │
└──────────────────────────────┘
```



**D\-04 — No difference**

```Plain Text
┌──────────────────────────────┐
│ ✓ Không chênh lệch           │
├──────────────────────────────┤
│ Hàng trả          250.000 ₫  │
│ Hàng nhận         250.000 ₫  │
│ Chênh lệch              0 ₫  │
│                              │
│ Không tạo thu thêm, hoàn tiền│
│ hoặc thay đổi công nợ.       │
│                              │
│ Plan: None · Còn lại 0 ₫     │
├──────────────────────────────┤
│          [Xem lại & xác nhận]│
└──────────────────────────────┘
```



**D\-05 — Collect planner**

```Plain Text
┌──────────────────────────────┐
│ ‹  Thu thêm                  │
├──────────────────────────────┤
│ Khách cần trả      300.000 ₫ │
│                              │
│ Tiền mặt                    ›│
│ Số tiền            300.000 ₫ │
│                     [Sửa] [×]│
├──────────────────────────────┤
│ Đã xử lý                 0 ₫ │
│ Đang chờ                 0 ₫ │
│ Đã lập              300.000 ₫│
│ CÒN PHÂN BỔ              0 ₫ │
├──────────────────────────────┤
│          [Xem lại & xác nhận]│
└──────────────────────────────┘
```



**D\-06 — Refund planner**

```Plain Text
┌──────────────────────────────┐
│ ‹  Hoàn tiền                 │
├──────────────────────────────┤
│ Khách được nhận    400.000 ₫ │
│ Có thể hoàn        400.000 ₫ │
│                              │
│ Chuyển khoản                 │
│ Hoàn               400.000 ₫ │
│                     [Sửa] [×]│
├──────────────────────────────┤
│ Đã lập              400.000 ₫│
│ CÒN PHÂN BỔ              0 ₫ │
├──────────────────────────────┤
│          [Xem lại & xác nhận]│
└──────────────────────────────┘
```



**D\-07 — Receivable planner**

```Plain Text
┌──────────────────────────────┐
│ ‹  Giảm công nợ              │
├──────────────────────────────┤
│ Khách: Nguyễn Văn An         │
│ Nghĩa vụ đủ điều kiện        │
│ #CN-00821          600.000 ₫ │
│                              │
│ Giảm/đảo công nợ   500.000 ₫ │
│                              │
│ ℹ Yêu cầu được gửi tới hệ thống│
│   công nợ; chưa cập nhật sổ. │
├──────────────────────────────┤
│                    [Áp dụng] │
└──────────────────────────────┘
```



**D\-08 — Mixed planner**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kế hoạch kết hợp          │
├──────────────────────────────┤
│ Cần xử lý        1.000.000 ₫ │
│                              │
│ Hoàn · Chuyển khoản 400.000 ₫│
│                         [Sửa]│
│ Giảm công nợ        600.000 ₫│
│ #CN-00821              [Sửa] │
│ [+ Thêm cách quyết toán]     │
├──────────────────────────────┤
│ Đã lập            1.000.000 ₫│
│ CÒN PHÂN BỔ              0 ₫ │
├──────────────────────────────┤
│          [Xem lại & xác nhận]│
└──────────────────────────────┘
```



**D\-09 — Method and amount editor**

```Plain Text
┌──────────────────────────────┐
│ ×  Thêm khoản hoàn           │
├──────────────────────────────┤
│ Phương thức                  │
│ [Chuyển khoản             ›] │
│                              │
│ Số tiền                      │
│ [250.000                  ] ₫│
│ Tối đa theo phương thức      │
│                    300.000 ₫ │
│                              │
│ Tham chiếu                   │
│ [GD-20260720              ]  │
│                              │
│                      [Thêm]  │
└──────────────────────────────┘
```



**D\-10 — Unbalanced/invalid plan**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Kế hoạch chưa cân bằng     │
├──────────────────────────────┤
│ Cần xử lý          400.000 ₫ │
│ Đã lập             250.000 ₫ │
│ CÒN PHẢI PHÂN BỔ   150.000 ₫ │
│                              │
│ Khoản hoàn 300.000 ₫ vượt    │
│ khả năng hiện tại 250.000 ₫. │
│                              │
│ [Sửa khoản hoàn]             │
│ [+ Thêm cách quyết toán]     │
└──────────────────────────────┘
```



**D\-11 — Full\-return partial\-paid split**

```Plain Text
┌──────────────────────────────┐
│ Kế hoạch theo đơn nguồn      │
├──────────────────────────────┤
│ Trả toàn bộ       1.000.000 ₫│
│                              │
│ HOÀN PHẦN ĐÃ THU             │
│ Chuyển khoản        400.000 ₫│
│                              │
│ ĐẢO PHẦN CHƯA THU            │
│ Công nợ #CN-00821   600.000 ₫│
│                              │
│ Tổng xử lý        1.000.000 ₫│
│ Còn lại                  0 ₫ │
│                              │
│          [Dùng kế hoạch này] │
└──────────────────────────────┘
```



**D\-12 — Final review**

```Plain Text
┌──────────────────────────────┐
│ ‹  Xem lại đổi/trả           │
├──────────────────────────────┤
│ Phiếu #DT-00128              │
│ Hàng trả · 2 dòng  1.000.000₫│
│ Hàng nhận · 0 dòng         0₫│
├──────────────────────────────┤
│ Hoàn tiền          400.000 ₫ │
│ Giảm công nợ       600.000 ₫ │
│ Còn phân bổ              0 ₫ │
├──────────────────────────────┤
│ Sau xác nhận, phiếu trở thành│
│ nghiệp vụ chính thức. Các yêu│
│ cầu có thể tiếp tục xử lý.   │
│ Đơn nguồn không bị hủy.      │
├──────────────────────────────┤
│ [Quay lại] [Xác nhận đổi/trả]│
└──────────────────────────────┘
```



**D\-13 — Confirming**

```Plain Text
┌──────────────────────────────┐
│                              │
│              ◌               │
│ Đang xác nhận đổi/trả…       │
│                              │
│ Không gửi lại yêu cầu trong  │
│ khi kết quả đang được ghi nhận│
│                              │
└──────────────────────────────┘
```



**D\-14 — Context stale**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Dữ liệu đã thay đổi        │
├──────────────────────────────┤
│ Giá trị hàng nhận đã đổi làm │
│ chênh lệch tăng 50.000 ₫.    │
│                              │
│ Kế hoạch cũ không còn hợp lệ │
│ và chưa được tự động sửa.    │
│                              │
│ [Lưu và đóng]                │
│ [Quay lại kiểm tra hàng hóa] │
└──────────────────────────────┘
```



**D\-15 — Draft/version conflict**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Phiếu đã được cập nhật     │
├──────────────────────────────┤
│ Một phiên khác đã lưu version│
│ mới hơn của #DT-00128.       │
│                              │
│ Hệ thống không tự gộp lines, │
│ valuation hoặc allocations.  │
│                              │
│ [Về chi tiết đơn]            │
│ [Tải bản mới nhất]           │
└──────────────────────────────┘
```



**D\-16 — No viable plan/policy blocked**

```Plain Text
┌──────────────────────────────┐
│ Không thể hoàn tất kế hoạch  │
├──────────────────────────────┤
│ Khách lẻ không được ghi nhận │
│ công nợ. Phương thức thu hiện│
│ tại cũng không khả dụng.     │
│                              │
│ Phiếu chưa được xác nhận.    │
│                              │
│ [Lưu và đóng]                │
│ [Kiểm tra lại phương thức]   │
└──────────────────────────────┘
```



**D\-17 — Uncertain/partial result**

```Plain Text
┌──────────────────────────────┐
│ ⚠ Đang kiểm tra kết quả      │
├──────────────────────────────┤
│ ✓ Hoàn tiền        200.000 ₫ │
│ ◷ Giảm công nợ     300.000 ₫ │
│   Đang chờ xác định          │
│                              │
│ Phần đã xử lý/đang chờ không │
│ thể được phân bổ lại.        │
│                              │
│ [Về chi tiết đơn]            │
│ [Kiểm tra kết quả]           │
└──────────────────────────────┘
```



**D\-18 — Confirmed handoff to SG\-13**

```Plain Text
┌──────────────────────────────┐
│ ✓ Phiếu đã được ghi nhận     │
├──────────────────────────────┤
│ #DT-00128 · Đang xử lý       │
│                              │
│ Kế hoạch quyết toán và các   │
│ yêu cầu liên quan đã được tạo│
│ theo kết quả xác nhận.       │
│                              │
│ Phiếu không còn chỉnh sửa hoặc│
│ xác nhận lại tại màn này.    │
│                              │
│              [Xem kết quả]   │
└──────────────────────────────┘
```



#### Visuals

TBD\.



#### Traceability

TBD\.

### 5\.5\.14 SG\-13 — Kết quả \& chi tiết đổi/trả

#### Overview

- Purpose: Cung cấp canonical result hub cho một ReturnExchangeOrder sau khi xác nhận, giúp người dùng theo dõi kết quả nghiệp vụ, quyết toán và các ảnh hưởng downstream mà không tạo lại hoặc sửa ngược business fact\.

- Related epic: EP\-06 — Đổi/trả hàng \& quyết toán chênh lệch\.

- Related business flow: BF\-08 — Đổi/trả \& quyết toán\.

- Business flow group: Post\-sale\.

- Primary users: Nhân viên bán hàng, quản lý cửa hàng, kế toán/đối soát và người dùng có quyền xem kết quả đổi/trả\.

- Primary task: Xem phiếu đổi/trả đã ghi nhận gì, ảnh hưởng thế nào đến đơn nguồn, tiền/công nợ và từng owner domain; xử lý đúng pending, delivery failure hoặc reconciliation khi có\.

- Priority: P0\.

- Platform baseline: Mobile first\.

- Design intent: SG\-13 không phải một màn `Thành công`\. UI phải tách rõ lifecycle của ReturnExchangeOrder, return status tổng hợp của đơn nguồn, settlement result và trạng thái từng downstream impact để người dùng biết phần nào đã là business fact, phần nào đang xử lý và phần nào cần can thiệp\.

- Architectural role: SG\-13 là read\-oriented canonical result/status hub sau confirmation\. Post\-sale Operations sở hữu ReturnExchangeOrder; Sales Settlement sở hữu payment/refund; Theme 6 sở hữu receivable ledger; Inventory, Pricing, E\-invoice và Delivery sở hữu kết quả trong domain tương ứng\.

- Scope boundary: SG\-13 không chỉnh sửa phiếu đã confirmed, không xác nhận lại operation, không sửa trực tiếp payment/refund/receivable/inventory record và không biến `fully_returned` thành `cancelled`\. Business correction sau confirmation phải đi qua compensating operation hoặc reconciliation flow theo policy\.

    

#### Entry \& exit

- Entry points:

    - CTA `Xem kết quả` từ SG\-12 sau khi ConfirmReturnExchange trả về `confirmed`, `processing` hoặc result đã biết\.

    - Deep link từ SG\-08/SG\-01/SG\-02/SG\-03/SG\-04/SG\-05/SG\-06/SG\-07/SG\-08 hoặc SG\-09 qua ReturnExchangeOrder ID\.

    - CTA từ SG\-08 — Chi tiết \& lịch sử đơn hàng tại mục `Đổi/trả` hoặc activity timeline\.

    - Task/notification về settlement, receivable, inventory, e\-invoice hoặc delivery cần theo dõi/đối soát\.

    - Recovery từ SG\-12 khi response xác nhận bị mất, dùng operation/correlation context để tìm authoritative result\.

- Exit points:

    - `Xem đơn nguồn` → SG\-08 — Chi tiết \& lịch sử đơn hàng\.

    - `Về danh sách đơn` → screen group tra cứu/danh sách phù hợp với entry context\.

    - `Xem quyết toán` → D\-11 trong SG\-13; không quay lại planner SG\-12 sau confirmation\.

    - `Xem trạng thái liên quan` → D\-13 trong SG\-13 hoặc deep link owner screen khi người dùng có quyền\.

    - `Xử lý đối soát` → owner\-specific reconciliation task/workspace với ReturnExchangeOrder/impact correlation giữ nguyên\.

    - `Thử gửi lại` → technical delivery retry của đúng impact hiện tại; không tạo ReturnExchangeOrder hoặc business transaction mới\.

    - ReturnExchangeOrder vẫn là `draft` → route SG\-11 hoặc SG\-12 theo draft stage; SG\-13 không render draft như một kết quả chính thức\.

    - Record authoritative là `cancelled` trước confirmation → route về draft/history context; không dùng outcome language\.

        

#### Screen/state inventory

|State|Class|Purpose|Primary action|Notes|
|---|---|---|---|---|
|D\-01|System state — Loading/recovery|Resolve authoritative ReturnExchangeOrder và các projections|—|Không suy ra result từ route payload/cache|
|D\-02|Result — Confirmed|Cho biết business fact đã được ghi nhận và impacts đang khởi tạo|Cập nhật trạng thái|Không cho confirm/edit lại|
|D\-03|Result — Processing|Theo dõi mandatory impacts/settlement đang xử lý|Cập nhật trạng thái|Hiển thị owner\-level progress|
|D\-04|Result — Completed, exchange \+ collect|Tóm tắt hàng trả, hàng nhận và khoản thu đã hoàn tất|Xem đơn nguồn|Composite completed example|
|D\-05|Result — Completed, refund/receivable|Tóm tắt hoàn tiền và giảm/cấn trừ công nợ không double count|Xem quyết toán|Có thể là return\-only hoặc mixed|
|D\-06|Result — Completed, no difference|Xác nhận hàng hóa hoàn tất nhưng không phát sinh nghĩa vụ tiền|Xem đơn nguồn|Không tạo zero\-value transaction|
|D\-07|Result — Completed, fully returned|Diễn đạt full return mà không biến đơn nguồn thành đã hủy|Xem đơn nguồn|Source lifecycle vẫn `completed`|
|D\-08|Detail — Returned items|Hiển thị immutable snapshot của các dòng trả trong phiếu|Quay lại kết quả|Tách current operation và aggregate source|
|D\-09|Detail — Exchange items|Hiển thị immutable commercial snapshot của hàng nhận đổi|Quay lại kết quả|Không render lại bằng master hiện tại|
|D\-10|Detail — Valuation|Giải thích giá trị trả, giá trị nhận, rounding và chênh lệch|Quay lại kết quả|Snapshot tại confirmation|
|D\-11|Detail — Settlement|Hiển thị payment/refund/receivable allocations và actual results|Quay lại kết quả|Planned khác processed/pending|
|D\-12|Detail — Source\-order impact|Hiển thị lifecycle và return status độc lập của đơn nguồn|Xem đơn nguồn|Return status là aggregate projection|
|D\-13|Detail — Integration status|Theo dõi business status và delivery status theo owner|Quay lại kết quả|Không gộp failure semantics|
|D\-14|Detail — Activity timeline|Trình bày business milestones và actor theo thời gian|Quay lại kết quả|Không thay raw event log|
|D\-15|Attention — Reconciliation required|Xử lý business rejection/invariant mismatch sau confirmation|Xử lý đối soát|Không technical retry mù|
|D\-16|Attention — Technical delivery failure|Cho retry/escalate một impact có business payload hợp lệ|Thử gửi lại|Reuse impact/correlation identity|
|D\-17|Partial state — Projection syncing/section unavailable|Giữ known result và đánh dấu phần dữ liệu đang cập nhật|Cập nhật trạng thái|Không hạ cấp business result|
|D\-18|Recovery — Uncertain confirmation result|Query operation/result trước mọi hành động có thể tạo trùng|Kiểm tra kết quả|Không confirm lại|
|D\-19|Terminal — Failed/not committed|Xác nhận operation không được commit và không có official impacts|Về phiếu đổi/trả|Chỉ dùng khi authoritative `not_committed`|
|D\-20|Access/error — Not found or not permitted|Xử lý record không tồn tại hoặc người dùng không được xem|Về danh sách đơn|Không tiết lộ dữ liệu bị hạn chế|



#### UI Contract

**Canonical state model**

- SG\-13 compose UI từ các state dimension độc lập:

    - `return_exchange_lifecycle`: `confirmed`, `processing`, `completed`, `failed`; `draft/cancelled` bị route guard khỏi result surface\.

    - `source_order_lifecycle`: lifecycle của SalesOrder, không bị ReturnExchangeOrder ghi đè\.

    - `source_return_status`: `not_returned`, `partially_returned`, `fully_returned` và projection freshness\.

    - `settlement_status`: `not_required`, `pending`, `partially_processed`, `completed`, `failed`, `reconciliation_required`\.

    - `owner_impact_status`: business status riêng của Inventory, Receivable, Pricing, E\-invoice và các owner khác\.

    - `delivery_status`: `not_required`, `queued`, `delivered`, `retry_scheduled`, `failed`, `dead_letter`, `unknown`\.

    - `read_model_freshness`: `current`, `updating`, `stale`, `unavailable`\.

- Không tạo một `overall_status` mới bằng cách tự tổng hợp ở client\. Header dùng lifecycle authoritative; attention summary diễn đạt các dimension cần chú ý\.

- `completed` nghĩa là các mandatory business requirements đã được ghi nhận theo policy; một delivery hoặc projection không bắt buộc vẫn có thể pending/failed và phải hiển thị riêng\.

- `confirmed` là business fact đã tồn tại\. User không được quay lại SG\-12 để sửa plan hoặc xác nhận lần hai\.

- `processing` không đồng nghĩa thất bại và không cho phép tạo phiếu thay thế để “thử lại”\.

- `failed` chỉ được trình bày là `Không ghi nhận` khi authoritative result xác nhận operation chưa commit; nếu chưa biết, dùng D\-18\.

    

**Semantic invariants**

- ReturnExchangeOrder là record độc lập liên kết SalesOrder nguồn; không sửa/xóa SalesOrder hoặc SalesOrderLine snapshot\.

- SalesOrder nguồn vẫn `completed` sau partial/full return, trừ khi được hủy riêng qua EP\-05\.

- `fully_returned` không đồng nghĩa `cancelled` và không phát `SalesOrderCancelled`\.

- Source return status là aggregate của các ReturnExchangeOrder `completed` đủ điều kiện, không chỉ trạng thái của phiếu đang xem\.

- Phiếu `confirmed` không editable/deletable; sai sót sau đó dùng compensating operation hoặc reconciliation theo policy\.

- Downstream pending/failure/reconciliation không rollback business fact đã confirmed và không reopen đơn nguồn\.

- Retry command/query phải idempotent; không tạo duplicate return, payment, refund, receivable hoặc inventory impact\.

    

**User intent**

- Biết phiếu đổi/trả đã được ghi nhận hay chưa và đang ở bước nào\.

- Hiểu chính xác hàng nào đã trả, hàng nào nhận đổi và valuation nào đã commit\.

- Biết khách đã trả thêm, được hoàn tiền hoặc được giảm nghĩa vụ bao nhiêu; phần nào đã xử lý, đang chờ hoặc cần đối soát\.

- Hiểu ảnh hưởng đến đơn nguồn mà không nhầm `đã trả toàn bộ` với `đã hủy`\.

- Biết owner domain nào đã ghi nhận business impact, owner nào chỉ gặp lỗi delivery và hành động nào an toàn\.

- Khôi phục đúng khi response mất hoặc projection chậm mà không xác nhận/tạo transaction trùng\.

    

**Information hierarchy**

1. ReturnExchangeOrder identity, lifecycle và freshness\.

2. Outcome statement bằng ngôn ngữ nghiệp vụ, kèm attention summary nếu có\.

3. Hàng trả, hàng nhận và committed valuation\.

4. Settlement result: thu thêm, hoàn tiền, receivable impact và remaining/pending\.

5. Ảnh hưởng đến SalesOrder nguồn: lifecycle và aggregate return status\.

6. Owner impacts, delivery/reconciliation status\.

7. Activity timeline, metadata và safe next actions\.

    

**Flow architecture**

|Stage|User need|System responsibility|Mutation rule|
|---|---|---|---|
|Resolve|Mở result bằng ID/operation|Tìm authoritative record, permission và freshness|Read only|
|Understand|Đọc outcome summary|Compose lifecycle \+ financial \+ source impact without collapsing states|Read only|
|Inspect|Mở lines/valuation/settlement/impact|Lấy committed snapshots và current owner results|Read only|
|Monitor|Theo dõi processing/pending|Refresh projections theo correlation/version|Read only|
|Recover|Result hoặc section chưa xác định|Query authority; không replay business command|Read/query only|
|Act|Retry delivery hoặc đối soát|Gọi đúng owner action với existing impact identity|Controlled owner mutation|
|Exit|Xem đơn nguồn hoặc danh sách|Giữ ReturnExchangeOrder context trong back stack/deep link|Không mutation|



**Source\-of\-truth contract**

|Information|Source|Owner|SG\-13 rule|
|---|---|---|---|
|ReturnExchangeOrder lifecycle/version|ReturnExchangeOrder authoritative record|Post\-sale Operations|Header source; không derive từ child statuses|
|Returned/exchange lines|Committed ReturnExchangeOrder line snapshots|Post\-sale Operations|Immutable display; không join lại master để thay snapshot|
|Committed valuation|ReturnExchangeValuation snapshot|Post\-sale Operations \+ Theme 4|Hiển thị amount/rounding/version đã confirm|
|Settlement requirement/plan|Committed settlement plan|Post\-sale Operations|Expected intent, không thay actual result|
|Payment/refund result|Sales payment/refund records|Sales Settlement|Status/reference/amount authoritative|
|Receivable result|Receivable impact/ledger query|Theme 6|Không suy ra từ settlement plan|
|Source lifecycle|SalesOrder|Sales|Luôn hiển thị độc lập với return status|
|Source return status|SalesOrder return\-summary projection|Post\-sale Operations|Aggregate \+ freshness label|
|Inventory impact|Inventory owner result|Inventory|Business status tách delivery status|
|Pricing impact|Pricing owner result|Theme 4|Hiển thị result/reconciliation, không revalue UI\-side|
|E\-invoice impact|E\-invoice owner result|Theme 8|Trạng thái tham chiếu; legal handling ngoài SG\-13|
|Integration delivery|Outbox/integration status query|Owning domain/integration layer|Retry đúng impact identity|
|Activity|Curated business milestones|Post\-sale Operations \+ owners|Không dùng raw event stream làm user timeline|



**Displayed data**

- ReturnExchangeOrder code/ID, lifecycle label, entry source, created/confirmed/completed timestamps, actor và location/store context\.

- Source SalesOrder code và customer snapshot phù hợp permission\.

- Reason code/label và note đã commit\.

- Returned lines: product/SKU snapshot, UoM, quantity của phiếu, condition/disposition nếu contract có, unit valuation và line value\.

- Exchange lines: product/SKU/UoM snapshot, quantity, unit price/discount/tax snapshot nếu có và line value\.

- Valuation: return value, exchange value, adjustment/rounding, net difference, direction và currency\.

- Settlement: committed allocations, actual payment/refund/receivable records, status, amount, method/target, reference, processed/pending/remaining totals\.

- Source impact: source lifecycle, aggregate return status, returned quantity summary, projection timestamp/freshness\.

- Owner impacts: owner, impact type, business status, delivery status, last update, correlation/reference và actionable issue\.

- Timeline: milestone, actor/system, occurred time, outcome và safe deep link\.

    

**Element inventory**

|Element ID|Component|Content/label|Behavior|States/conditions|
|---|---|---|---|---|
|SG13\-E01|Top bar|`Kết quả đổi/trả`|Giữ operation identity|D\-01 đến D\-20|
|SG13\-E02|Back action|Back theo entry context|Không replay command|Khi navigation context hợp lệ|
|SG13\-E03|Identity block|`Phiếu #...` · đơn nguồn · entry source|Copy/open permitted reference|Sau resolve|
|SG13\-E04|Lifecycle badge|Đã xác nhận / Đang xử lý / Hoàn tất / Không ghi nhận|Authoritative lifecycle|D\-02 đến D\-19|
|SG13\-E05|Freshness indicator|Vừa cập nhật / Đang cập nhật / Dữ liệu cũ|Mở refresh context|Khi không current|
|SG13\-E06|Outcome banner|Câu kết quả nghiệp vụ|Compose from committed result|D\-02 đến D\-07|
|SG13\-E07|Attention banner|Pending/failure/reconciliation summary|Focus affected module|D\-03/D\-15/D\-16/D\-17|
|SG13\-E08|Goods summary card|Hàng trả · hàng nhận|Mở D\-08/D\-09|Sau line load|
|SG13\-E09|Return detail action|`Xem hàng trả`|Mở D\-08|Có returned lines|
|SG13\-E10|Exchange detail action|`Xem hàng nhận`|Mở D\-09|Có exchange lines|
|SG13\-E11|Valuation card|Giá trị trả · nhận · chênh lệch|Mở D\-10|Sau valuation load|
|SG13\-E12|Settlement card|Thu/hoàn/công nợ · status|Mở D\-11|Required hoặc informative|
|SG13\-E13|Settlement status badge|Chưa cần / Đang xử lý / Một phần / Hoàn tất / Cần đối soát|Owner result|Never inferred from lifecycle alone|
|SG13\-E14|Source\-impact card|Lifecycle · return status|Mở D\-12 hoặc SG\-08|Sau source summary load|
|SG13\-E15|Owner\-impact list|Inventory · Receivable · Pricing · E\-invoice · Delivery|Mở D\-13|Applicable owners only|
|SG13\-E16|Business\-status badge|Chưa cần / Đã ghi nhận / Đang xử lý / Bị từ chối / Chưa rõ|Owner business result|D\-03/D\-13/D\-15|
|SG13\-E17|Delivery\-status badge|Đã gửi / Đang chờ / Gửi lỗi / Dead\-letter|Integration delivery|D\-13/D\-16|
|SG13\-E18|Timeline action|`Xem lịch sử xử lý`|Mở D\-14|Sau identity resolved|
|SG13\-E19|Refresh action|`Cập nhật trạng thái`|Conditional GET/query latest|D\-02/D\-03/D\-17|
|SG13\-E20|Source\-order action|`Xem đơn nguồn`|Mở SG\-08|Permitted source access|
|SG13\-E21|Settlement action|`Xem quyết toán`|Mở D\-11|Settlement exists|
|SG13\-E22|Integration action|`Xem trạng thái liên quan`|Mở D\-13|Impact exists|
|SG13\-E23|Reconcile action|`Xử lý đối soát`|Open owner\-specific task|D\-15 \+ permission|
|SG13\-E24|Retry\-delivery action|`Thử gửi lại`|Replay same impact delivery|D\-16 \+ eligible \+ permission|
|SG13\-E25|Check\-result action|`Kiểm tra kết quả`|Query by operation/idempotency context|D\-18|
|SG13\-E26|Back\-to\-draft action|`Về phiếu đổi/trả`|Route editable/new context|D\-19 only|
|SG13\-E27|Error recovery|`Thử lại`|Refetch non\-mutating data|D\-01/D\-17/D\-20 when eligible|
|SG13\-E28|List action|`Về danh sách đơn`|Safe exit|D\-04 to D\-20|
|SG13\-E29|Support reference|Operation/correlation reference|Copy for support|D\-15 to D\-19|
|SG13\-E30|Permission mask|Hidden/redacted field state|Prevent data disclosure|Any restricted section|



**State composition and precedence**

- UI resolves state in precedence order:

    1. Access/not\-found guard → D\-20\.

    2. Uncertain confirmation with no authoritative commit result → D\-18\.

    3. Authoritative `failed/not_committed` → D\-19\.

    4. Confirmed operation with reconciliation\-required business impact → D\-15 attention overlay on result\.

    5. Confirmed operation with technical delivery failure → D\-16 attention overlay on result\.

    6. Lifecycle `confirmed` → D\-02; `processing` → D\-03; `completed` → D\-04/D\-05/D\-06/D\-07 by outcome composition\.

    7. Projection lag/section failure → D\-17 without replacing known header result\.

- D\-15/D\-16 là attention mode gắn trên base result, không phải bằng chứng ReturnExchangeOrder đã rollback\.

- Nhiều issues cùng lúc được xếp theo severity và owner; header lifecycle giữ nguyên\.

    

**Lifecycle presentation behavior**

|Lifecycle|User\-facing label|Required message|Prohibited implication|
|---|---|---|---|
|`confirmed`|`Đã xác nhận`|Phiếu đã được ghi nhận; đang khởi tạo/tập hợp impacts|Không nói `Hoàn tất`|
|`processing`|`Đang xử lý`|Phiếu không cần xác nhận lại; hiển thị remaining mandatory work|Không nói `Thất bại` vì pending|
|`completed`|`Hoàn tất`|Mandatory business requirements đã ghi nhận theo policy|Không che downstream warning|
|`failed` \+ `not_committed`|`Không ghi nhận`|Operation không tạo business fact chính thức|Không nói có thể retry confirm nếu context stale|



- Raw enum có thể xuất hiện trong audit/support detail nhưng không thay user\-facing language\.

    

**Outcome\-summary composition**

- Outcome sentence ưu tiên facts: số dòng/quantity trả, số dòng/quantity nhận, settlement direction/result và source return status\.

- D\-04 example: `Đã hoàn tất đổi 2 mặt hàng. Đã thu thêm 350.000 ₫.`

- D\-05 example: `Đã hoàn tất trả hàng. Đã hoàn 400.000 ₫ và giảm khoản phải thu 600.000 ₫.`

- D\-06 example: `Đã hoàn tất đổi hàng. Không phát sinh chênh lệch cần quyết toán.`

- D\-07 example: `Đã trả toàn bộ hàng của đơn nguồn.` kèm statement bắt buộc `Đơn nguồn vẫn ở trạng thái Hoàn tất, không phải Đã hủy.`

- Processing sentence không dùng future guarantee; nói phần đã ghi nhận và phần còn đang xử lý\.

- Không dùng một icon check lớn để che warning; lifecycle, settlement và owner impacts vẫn đọc được độc lập\.

    

**Identity and entry\-source behavior**

- Header luôn hiển thị ReturnExchangeOrder code và SalesOrder source code; không chỉ hiển thị mã đơn nguồn\.

- Entry source được user\-label hóa, ví dụ `Lập từ chi tiết đơn` hoặc `Khởi tạo từ yêu cầu hủy`\.

- Phiếu full return khởi tạo từ cancel attempt vẫn mang identity ReturnExchangeOrder và label `Đổi/trả`, không đổi thành cancellation result\.

- Operation/correlation ID chỉ ở technical detail/support context, tránh làm primary identity\.

    

**Returned\-line detail behavior**

- D\-08 dùng committed line snapshot: product name/SKU/UoM, returned quantity, valuation and captured attributes\.

- Phân biệt `Phiếu này` với `Lũy kế đã trả của đơn nguồn`; aggregate value có freshness label\.

- Không thay product name/price snapshot bằng master data hiện tại\.

- Không cho sửa quantity/condition/disposition trong SG\-13\.

- Nếu line aggregate projection đang cập nhật, committed quantity vẫn hiển thị; aggregate row dùng `Đang cập nhật`\.

- Nếu quantity lớn, group theo line nguồn và hỗ trợ progressive disclosure; không merge các snapshot khác giá/UoM\.

    

**Exchange\-line detail behavior**

- D\-09 chỉ hiển thị khi có exchange lines; return\-only không render empty card\.

- Hiển thị commercial snapshot tại confirmation gồm product/SKU/UoM, quantity, unit price, adjustment/discount/tax nếu contract cung cấp và line value\.

- Master data thay đổi sau confirmation không làm đổi result\.

- Inventory fulfillment/delivery status không được trộn vào commercial line status; deep link sang D\-13/owner detail\.

    

**Valuation behavior**

- D\-10 hiển thị equation: `Giá trị hàng nhận - Giá trị hàng trả + điều chỉnh/rounding = chênh lệch` theo committed snapshot\.

- Direction dùng customer\-centric label: `Khách trả thêm`, `Khách được hoàn/giảm nghĩa vụ`, hoặc `Không chênh lệch`\.

- Amount trong detail có thể mang dấu để audit; outcome card dùng absolute amount \+ direction để tránh hiểu nhầm\.

- Rounding/currency precision dùng Theme 1 policy captured tại confirmation\.

- Valuation recalculation hiện tại, nếu có, chỉ là reconciliation context; không overwrite committed valuation\.

    

**Settlement\-result behavior**

- D\-11 tách `Kế hoạch đã xác nhận` khỏi `Kết quả owner`\.

- Mỗi allocation hiển thị type, positive amount, owner, method/receivable target, status và reference\.

- Status buckets:

    - `processed_amount`: actual owner record đã authoritative\.

    - `pending_amount`: owner operation accepted/uncertain; khóa khỏi replay mới\.

    - `failed_amount`: business rejected hoặc delivery failed; phân loại rõ\.

    - `remaining_amount`: obligation chưa được authoritative satisfied theo policy\.

- `processed + pending + remaining` được đối chiếu với required amount; failed amount không tự cộng hoặc trừ nếu owner semantics chưa xác định\.

- Refund và receivable reversal là hai loại benefit khác nhau: refund là tiền trả khách; reversal/offset là giảm nghĩa vụ chưa trả\.

- Full\-return partially\-paid phải hiển thị riêng actual refund và receivable reversal để không tạo cảm giác khách nhận cả hai bằng tiền\.

- `not_required` hiển thị `Không phát sinh quyết toán`; không tạo payment/refund/receivable row giá trị 0\.

- Planned allocation không được gắn nhãn `Đã thu/Đã hoàn` cho tới khi owner result xác nhận\.

- Owner business rejection mở D\-15; technical delivery failure mở D\-16; response unknown mở D\-17/D\-18 tùy confirmation certainty\.

    

**Source\-order impact behavior**

- D\-12 đặt hai hàng cạnh nhau về ngữ nghĩa:

    - `Trạng thái đơn: Hoàn tất` từ SalesOrder lifecycle\.

    - `Tình trạng trả hàng: Chưa trả / Đã trả một phần / Đã trả toàn bộ` từ return\-summary projection\.

- Không thay label trạng thái đơn bằng return status\.

- `partially_returned` và `fully_returned` chỉ cập nhật theo completed quantities/policy; confirmed/processing có thể hiển thị `Đang cập nhật sau khi phiếu hoàn tất`\.

- Aggregate return status phải tính tất cả completed ReturnExchangeOrder phù hợp của đơn nguồn\.

- Khi projection update chậm, hiển thị current known status \+ `Đang cập nhật`, không cho tạo phiếu mới chỉ để sửa trạng thái\.

- Full return bắt buộc có explanatory text `Đã trả toàn bộ không có nghĩa đơn đã hủy`\.

    

**Owner\-impact and delivery behavior**

- D\-13 dùng hai trường riêng:

    - `Business`: requirement/result trong owner domain\.

    - `Delivery`: việc truyền impact/message tới owner\.

- Một impact có thể `Business: Đã ghi nhận` và `Delivery: Không áp dụng` nếu owner action synchronous\.

- Một impact có thể `Business: Chưa rõ` và `Delivery: Đã gửi`; không được kết luận hoàn tất từ delivery receipt\.

- Technical delivery retry chỉ hiển thị khi payload/business requirement đã durable, failure retryable và user có quyền\.

- Retry giữ impact ID/correlation/idempotency key; không phát sinh business requirement mới\.

- `dead_letter` yêu cầu escalation/support hoặc reconciliation; không lặp retry vô hạn trên UI\.

- Business rejection/invariant mismatch không dùng CTA `Thử gửi lại`; route D\-15\.

    

**Activity timeline behavior**

- D\-14 ưu tiên milestones: draft created, confirmed, owner requirements created, settlement/inventory/receivable results, completed, reconciliation/retry action\.

- Mỗi entry hiển thị user/system actor, occurred time và concise outcome\.

- Out\-of\-order delivery không reorder business facts sai; dùng authoritative occurred time, kèm recorded time trong detail khi cần\.

- Raw message attempts nằm ở integration detail, không làm timeline người dùng nhiễu\.

- Timeline không phải source để client derive current status; status vẫn từ authoritative summary\.

    

**Reconciliation behavior**

- D\-15 xuất hiện khi owner business validation từ chối, invariant không cân bằng, duplicate/over\-return conflict được phát hiện sau commit hoặc policy yêu cầu manual decision\.

- Banner nói rõ ReturnExchangeOrder vẫn đã xác nhận/đang xử lý, phần nào cần đối soát và điều gì chưa được ghi nhận\.

- CTA mở task có owner, reason code, affected amount/line, correlation và available resolution policy\.

- Không cung cấp generic `Đánh dấu hoàn tất` hoặc sửa trực tiếp result\.

- Sau resolution, refresh authoritative status; compensating operation xuất hiện như record/timeline mới, không overwrite lịch sử\.

    

**Technical retry behavior**

- D\-16 chỉ dành cho delivery/transient technical failure đã được owner contract đánh dấu retryable\.

- Trước retry, refetch impact status để tránh retry sau khi background worker đã xử lý\.

- Retry command cần expected impact version và existing idempotency/correlation identity\.

- UI chuyển `Đang gửi lại`, khóa double tap và query result nếu response mất\.

- Permanent/dead\-letter hoặc vượt retry policy route support/reconciliation, không tiếp tục hiện primary retry\.

    

**Refresh, polling and freshness behavior**

- D\-02/D\-03 có bounded polling khi app foreground; backoff theo server hint và dừng khi terminal/attention state hoặc user rời màn\.

- Manual `Cập nhật trạng thái` dùng conditional/versioned query, không replay confirmation hay owner commands\.

- Header có timestamp `Cập nhật lúc ...`; section có freshness riêng nếu owner projections cập nhật khác nhau\.

- Late response chỉ được áp dụng nếu khớp ReturnExchangeOrder ID và không cũ hơn version hiện tại\.

- App resume, network regain hoặc notification deep link trigger refetch\.

    

**Partial\-data behavior**

- D\-17 giữ các fact đã authoritative thay vì thay cả trang bằng generic error\.

- Identity/lifecycle load thành công nhưng settlement/integration lỗi: render base result, section lỗi có `Thử lại` riêng\.

- Source return projection chậm: hiển thị committed operation \+ label source status `Đang cập nhật`\.

- Không hạ `completed` thành `processing` chỉ vì một read model tạm unavailable\.

- Nếu identity/lifecycle cũng không xác định sau confirmation attempt, dùng D\-18 chứ không D\-17\.

    

**Uncertain\-result behavior**

- D\-18 dùng operation ID, ReturnExchangeOrder candidate ID, idempotency key/correlation context để query authoritative outcome\.

- Primary CTA duy nhất là `Kiểm tra kết quả`; không hiển thị `Xác nhận lại`\.

- Nếu tìm thấy `confirmed/processing/completed`, chuyển base result tương ứng\.

- Chỉ chuyển D\-19 khi server xác nhận `not_committed`; timeout hoặc `not found yet` không đủ để kết luận thất bại\.

- Sau bounded recovery, cung cấp support reference và safe exit; operation vẫn được tiếp tục reconcile khi quay lại\.

    

**Failed/not\-committed behavior**

- D\-19 chỉ nói `Phiếu chưa được ghi nhận` khi authoritative confirmation result xác nhận no commit/no official impacts\.

- Hiển thị reason user\-actionable và context freshness; nếu muốn thử lại, route về SG\-11/SG\-12 với draft/version current hoặc tạo operation mới theo policy\.

- Không reuse stale valuation/settlement plan tự động\.

- Không dùng D\-19 cho confirmed operation có downstream failure\.

    

**Permission and security behavior**

- Base access yêu cầu `sales.return_exchange.view` và tenant/store scope phù hợp\.

- Settlement/payment/refund detail yêu cầu quyền tương ứng; khi thiếu quyền, hiển thị tổng được policy cho phép hoặc `Bạn không có quyền xem chi tiết`, không leak method/reference\.

- Receivable detail tuân Theme 6 permission; inventory/e\-invoice detail tuân owner permission\.

- Retry yêu cầu integration retry permission; reconciliation yêu cầu owner\-specific permission\.

- D\-20 dùng neutral wording cho not\-found và unauthorized khi cần chống enumeration\.

- Copy reference và deep link không được bypass permission checks\.

    

**Concurrency and idempotency behavior**

- Refetch trước technical retry/reconciliation action và dùng expected version\.

- Double tap refresh là read\-only và có thể coalesce; double tap retry chỉ tạo một retry request\.

- Background completion trong lúc user mở D\-15/D\-16 phải update action availability và không cho thao tác stale\.

- Processed/pending settlement allocation bị khóa; không tạo payment/refund mới từ SG\-13\.

- Một ReturnExchangeOrder chỉ có một canonical result route; retry/query không tạo duplicate screen identity\.

    

**Navigation and deep\-link behavior**

- Deep link tối thiểu chứa ReturnExchangeOrder ID; operation/correlation context là recovery aid, không phải source of truth\.

- Back từ D\-08 đến D\-14 quay base result và giữ scroll/filter state\.

- `Xem đơn nguồn` giữ link quay lại SG\-13 trong activity context\.

- Nếu owner detail mở app/module khác, truyền read\-only reference và return URL; không truyền sensitive snapshot ngoài permission scope\.

- Draft/cancelled route guard chuyển đúng pre\-confirmation context thay vì hiển thị fake result\.

    

**Responsive and accessibility behavior**

- Mobile: outcome, attention, goods, settlement, source impact và owner status xếp một cột; primary action sticky khi cần\.

- Tablet/desktop: base summary ở main column, status/metadata/timeline ở secondary column; không đổi information priority\.

- Status không chỉ phân biệt bằng màu; dùng label \+ icon \+ concise explanation\.

- Amount và direction có accessible label đầy đủ; screen reader không đọc dấu âm mà thiếu nghĩa vụ\.

- Touch target tối thiểu 44×44 px; retry/reconcile không đặt sát navigation/destructive action\.

- Progress không dựa vào animation; live\-region announcement chỉ cho lifecycle/attention change quan trọng\.

    

**Telemetry and audit signals**

- Track result opened, source route, lifecycle viewed, section expanded, refresh, uncertain recovery, retry, reconciliation handoff và owner deep link\.

- Correlate telemetry bằng opaque operation/reference; không đưa payment/customer\-sensitive fields vào analytics payload\.

- Audit record của retry/reconciliation gồm actor, impact ID, prior status, command result và timestamp\.

- UI telemetry không thay authoritative business audit\.

    

#### Low\-fi wireframes

**D\-01 — Loading/recovery**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ Đang tìm kết quả chính thức… │
│ ▓▓▓▓▓▓▓▓░░                   │
│                              │
│ Phiếu đổi/trả                │
│ [──────────────]             │
│ Trạng thái                   │
│ [──────────────]             │
│                              │
│ Không đóng hoặc xác nhận lại │
│ trong khi hệ thống kiểm tra. │
└──────────────────────────────┘
```



**D\-02 — Confirmed**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ ĐÃ XÁC NHẬN                  │
│ Phiếu #DT-000184             │
│ Đơn nguồn #DH-002586         │
│                              │
│ Phiếu đã được ghi nhận.      │
│ Các ảnh hưởng đang khởi tạo. │
│                              │
│ Hàng hóa              Đã ghi │
│ Quyết toán           Đang chờ│
│ Đơn nguồn        Chưa cập nhật│
│                              │
│ [ Cập nhật trạng thái ]      │
│   Xem đơn nguồn              │
└──────────────────────────────┘
```



**D\-03 — Processing**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ ĐANG XỬ LÝ                   │
│ Phiếu #DT-000184             │
│ Không cần xác nhận lại       │
│                              │
│ ✓ Hàng trả        Đã ghi nhận│
│ ◷ Thu thêm            Đang xử│
│ ✓ Kho hàng         Đã tiếp nhận│
│ ◷ Hóa đơn điện tử   Đang chờ │
│                              │
│ Cập nhật lúc 10:42           │
│ [ Cập nhật trạng thái ]      │
│   Xem trạng thái liên quan   │
└──────────────────────────────┘
```



**D\-04 — Completed, exchange \+ collect**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ HOÀN TẤT                     │
│ Phiếu #DT-000184             │
│                              │
│ Đã hoàn tất đổi 2 mặt hàng.  │
│ Đã thu thêm 350.000 ₫.       │
│                              │
│ HÀNG HÓA                     │
│ Trả 2 SP        Nhận 1 SP  › │
│ QUYẾT TOÁN                   │
│ Thu thêm       350.000 ₫  ✓ │
│ ĐƠN NGUỒN                    │
│ Hoàn tất · Đã trả một phần › │
│                              │
│ [ Xem đơn nguồn ]            │
│   Xem lịch sử xử lý          │
└──────────────────────────────┘
```



**D\-05 — Completed, refund and receivable reversal**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ HOÀN TẤT                     │
│ Phiếu #DT-000185             │
│                              │
│ Đã hoàn tất trả hàng.        │
│                              │
│ TIỀN HOÀN                    │
│ Đã hoàn          400.000 ₫ ✓│
│ GIẢM NGHĨA VỤ CÔNG NỢ       │
│ Đã giảm          600.000 ₫ ✓│
│                              │
│ Khách nhận bằng tiền:        │
│                  400.000 ₫   │
│ [ Xem quyết toán ]           │
│   Xem đơn nguồn              │
└──────────────────────────────┘
```



**D\-06 — Completed, no difference**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ HOÀN TẤT                     │
│ Phiếu #DT-000186             │
│                              │
│ Đã hoàn tất đổi hàng.        │
│ Không phát sinh chênh lệch   │
│ cần quyết toán.              │
│                              │
│ Giá trị hàng trả  800.000 ₫  │
│ Giá trị hàng nhận 800.000 ₫  │
│ Chênh lệch                0 ₫│
│                              │
│ Không có giao dịch tiền mới. │
│ [ Xem đơn nguồn ]            │
└──────────────────────────────┘
```



**D\-07 — Completed, fully returned**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ HOÀN TẤT                     │
│ Phiếu #DT-000187             │
│                              │
│ ĐÃ TRẢ TOÀN BỘ HÀNG          │
│ 4/4 sản phẩm của đơn nguồn   │
│ đã được trả.                 │
│                              │
│ Đơn #DH-002586               │
│ Trạng thái đơn: Hoàn tất     │
│ Trả hàng: Đã trả toàn bộ     │
│                              │
│ Đã trả toàn bộ không có      │
│ nghĩa đơn đã hủy.            │
│ [ Xem đơn nguồn ]            │
└──────────────────────────────┘
```



**D\-08 — Returned items detail**

```Plain Text
┌──────────────────────────────┐
│ ‹  Hàng đã trả               │
├──────────────────────────────┤
│ Phiếu #DT-000184             │
│ Snapshot khi xác nhận        │
│                              │
│ Vaccine A · SKU VA-01        │
│ Phiếu này              2 hộp │
│ Đơn giá trả       250.000 ₫  │
│ Thành tiền         500.000 ₫ │
│ Lũy kế đơn nguồn       2/5   │
│ ──────────────────────────── │
│ Thuốc B · SKU TB-02          │
│ Phiếu này               1 lọ │
│ Thành tiền         300.000 ₫ │
│                              │
│ [ Quay lại kết quả ]         │
└──────────────────────────────┘
```



**D\-09 — Exchange items detail**

```Plain Text
┌──────────────────────────────┐
│ ‹  Hàng nhận đổi             │
├──────────────────────────────┤
│ Phiếu #DT-000184             │
│ Snapshot thương mại đã chốt  │
│                              │
│ Vaccine C · SKU VC-03        │
│ Số lượng              1 hộp  │
│ Đơn giá          1.100.000 ₫ │
│ Điều chỉnh         +50.000 ₫ │
│ Thành tiền       1.150.000 ₫ │
│                              │
│ Tình trạng xuất kho       ›  │
│                              │
│ [ Quay lại kết quả ]         │
└──────────────────────────────┘
```



**D\-10 — Valuation detail**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chi tiết định giá         │
├──────────────────────────────┤
│ Bản định giá tại xác nhận    │
│ Version 7 · 20/07 10:35      │
│                              │
│ Giá trị hàng nhận 1.150.000 ₫│
│ Giá trị hàng trả   -800.000 ₫│
│ Điều chỉnh/rounding        0 ₫│
│ ──────────────────────────── │
│ KHÁCH TRẢ THÊM      350.000 ₫│
│                              │
│ Tiền tệ: VND                 │
│ [ Quay lại kết quả ]         │
└──────────────────────────────┘
```



**D\-11 — Settlement detail**

```Plain Text
┌──────────────────────────────┐
│ ‹  Chi tiết quyết toán       │
├──────────────────────────────┤
│ Nghĩa vụ           1.000.000 ₫│
│                              │
│ Hoàn tiền · Chuyển khoản     │
│ Đã xử lý           400.000 ₫ ✓│
│ Ref RF-00921                  │
│                              │
│ Giảm khoản phải thu          │
│ Đã ghi nhận        600.000 ₫ ✓│
│ Ref AR-00184                  │
│ ────────────────────────────  │
│ Đã xử lý         1.000.000 ₫  │
│ Đang chờ                    0 ₫│
│ Còn lại                     0 ₫│
│ [ Quay lại kết quả ]          │
└───────────────────────────────┘
```



**D\-12 — Source\-order impact**

```Plain Text
┌──────────────────────────────┐
│ ‹  Ảnh hưởng đến đơn nguồn   │
├──────────────────────────────┤
│ Đơn #DH-002586               │
│                              │
│ Trạng thái đơn               │
│ Hoàn tất                     │
│                              │
│ Tình trạng trả hàng          │
│ Đã trả một phần              │
│ 3/5 sản phẩm · cập nhật 10:44│
│                              │
│ Hai trạng thái được quản lý  │
│ độc lập.                     │
│ [ Xem đơn nguồn ]            │
│   Quay lại kết quả           │
└──────────────────────────────┘
```



**D\-13 — Integration status**

```Plain Text
┌──────────────────────────────┐
│ ‹  Trạng thái liên quan      │
├──────────────────────────────┤
│ KHO HÀNG                     │
│ Business: Đã ghi nhận      ✓ │
│ Delivery: Đã gửi           ✓ │
│ ──────────────────────────── │
│ QUYẾT TOÁN                  │
│ Business: Đang xử lý        ◷│
│ Delivery: Đã gửi            ✓│
│ ──────────────────────────── │
│ HÓA ĐƠN ĐIỆN TỬ             │
│ Business: Chưa rõ           !│
│ Delivery: Gửi lỗi           !│
│                              │
│ [ Xem lỗi gửi ]              │
│   Quay lại kết quả           │
└──────────────────────────────┘
```



**D\-14 — Activity timeline**

```Plain Text
┌──────────────────────────────┐
│ ‹  Lịch sử xử lý             │
├──────────────────────────────┤
│ 10:44  Hoàn tất phiếu        │
│        Hệ thống              │
│   │                          │
│ 10:43  Đã ghi giảm công nợ   │
│        Theme 6 · AR-00184    │
│   │                          │
│ 10:42  Đã hoàn tiền          │
│        Nguyễn An · RF-00921  │
│   │                          │
│ 10:35  Đã xác nhận đổi/trả   │
│        Nguyễn An             │
│                              │
│ [ Quay lại kết quả ]         │
└──────────────────────────────┘
```



**D\-15 — Reconciliation required**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ ĐANG XỬ LÝ · CẦN ĐỐI SOÁT    │
│ Phiếu #DT-000184             │
│                              │
│ Phiếu đã được xác nhận.      │
│ Khoản giảm công nợ 600.000 ₫ │
│ bị từ chối do nghĩa vụ đã đổi│
│                              │
│ Hàng trả          Đã ghi nhận│
│ Hoàn tiền          Đã xử lý  │
│ Công nợ            Cần xử lý │
│                              │
│ Không xác nhận lại phiếu.    │
│ [ Xử lý đối soát ]           │
│   Mã tham chiếu: RC-0184     │
└──────────────────────────────┘
```



**D\-16 — Technical delivery failure**

```Plain Text
┌──────────────────────────────┐
│ ‹  Lỗi gửi ảnh hưởng         │
├──────────────────────────────┤
│ HÓA ĐƠN ĐIỆN TỬ             │
│ Business payload: Đã lưu     │
│ Delivery: Gửi lỗi            │
│                              │
│ Lần thử gần nhất: 10:46      │
│ Lỗi kết nối tạm thời         │
│ Impact ID: EI-IMP-0092       │
│                              │
│ Gửi lại dùng đúng impact này,│
│ không tạo phiếu mới.         │
│                              │
│ [ Thử gửi lại ]              │
│   Để hệ thống tự thử lại     │
└──────────────────────────────┘
```



**D\-17 — Projection syncing/partial section unavailable**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ HOÀN TẤT                     │
│ Phiếu #DT-000184             │
│                              │
│ Kết quả phiếu đã được ghi nhận│
│                              │
│ Hàng hóa             Đã tải ✓│
│ Quyết toán           Đã tải ✓│
│ Đơn nguồn        Đang cập nhật│
│ Trạng thái liên quan Tạm lỗi !│
│                              │
│ Một số dữ liệu có thể chậm.  │
│ [ Cập nhật trạng thái ]      │
│   Xem phần đã có             │
└──────────────────────────────┘
```



**D\-18 — Uncertain confirmation result**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kiểm tra kết quả          │
├──────────────────────────────┤
│ CHƯA XÁC ĐỊNH KẾT QUẢ        │
│                              │
│ Kết nối bị gián đoạn sau khi │
│ gửi xác nhận đổi/trả.        │
│                              │
│ Hệ thống sẽ tìm phiếu theo   │
│ mã thao tác hiện tại.        │
│ Không xác nhận lại.          │
│                              │
│ Operation: OP-9F2…           │
│ [ Kiểm tra kết quả ]         │
│   Về danh sách đơn           │
└──────────────────────────────┘
```



**D\-19 — Failed/not committed**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ KHÔNG GHI NHẬN               │
│                              │
│ Phiếu đổi/trả chưa được tạo  │
│ thành business fact.         │
│ Không có ảnh hưởng chính thức│
│ từ thao tác này.             │
│                              │
│ Lý do: dữ liệu định giá đã đổi│
│ Mã: VALUATION_STALE          │
│                              │
│ [ Về phiếu đổi/trả ]         │
│   Về danh sách đơn           │
└──────────────────────────────┘
```



**D\-20 — Not found or not permitted**

```Plain Text
┌──────────────────────────────┐
│ ‹  Kết quả đổi/trả           │
├──────────────────────────────┤
│ Không thể mở kết quả này     │
│                              │
│ Phiếu không tồn tại, đã nằm  │
│ ngoài phạm vi cửa hàng hoặc  │
│ bạn không có quyền truy cập. │
│                              │
│ Kiểm tra lại đường dẫn hoặc  │
│ liên hệ quản lý nếu cần.     │
│                              │
│ [ Về danh sách đơn ]         │
│   Thử lại                    │
└──────────────────────────────┘
```



#### Visuals

TBD\.



#### Traceability

TBD\.

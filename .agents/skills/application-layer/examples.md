# Application Layer — Examples

> **Target state only.** Các ví dụ dưới đây mô tả layout mục tiêu khi module được implement. Code hiện tại trong `modules/sales/application/` chỉ là skeleton — copy pattern từ `packages/vet45_generator/test/fixtures/` cho đến khi IAM golden module (phase 2) hoàn thành.

Canonical domain flows: [ddd-domain-modeling/examples.md](../ddd-domain-modeling/examples.md) · Interim CQRS: `packages/vet45_generator/test/fixtures/lib/src/`

---

## Ví dụ 1 — Cấu trúc Sales application (thực tế)

**Lưu ý:** code hiện tại có thể chưa migrate hết sang `lib/src/` — convention mục tiêu như dưới.

```text
modules/sales/application/lib/
  application.dart              # public barrel
  src/
    contracts/
      command_base.dart, i_command.dart
      query_base.dart, i_query.dart
      i_iam_module.dart
    configurations/
      commands/i_command_handler.dart, internal_command_base.dart
      queries/i_query_handler.dart
    sales_order_drafts/
      start_sales_order_draft/
      add_product_to_draft/
      change_draft_line_quantity/
      apply_line_discount/
      validate_draft_for_checkout/
      get_all_sales_order_draft/          # query + handler + dto
    sales_orders/
      checkout_sales_order/
      confirm_sales_order/
      cancel_sales_order/
      ...
    return_exchanges/
      start_return_exchange_request/
      add_return_line/
      complete_return_exchange_request/
      ...
```

---

## Ví dụ 2 — Command + Handler (AddProductToDraft)

```dart
// sales_order_drafts/add_product_to_draft/add_product_to_draft_command.dart
final class AddProductToDraftCommand extends CommandBase<void> {
  AddProductToDraftCommand({
    String? id,
    required this.tenantId,
    required this.draftId,
    required this.productId,
    required this.quantity,
  }) : super(id);

  final String tenantId;
  final String draftId;
  final String productId;
  final int quantity;
}
```

```dart
// sales_order_drafts/add_product_to_draft/add_product_to_draft_command_handler.dart
final class AddProductToDraftCommandHandler
    implements ICommandHandler<AddProductToDraftCommand, void> {
  AddProductToDraftCommandHandler({
    required this.draftRepository,
    required this.productLookup,
    required this.stockChecker,
  });

  final ISalesOrderDraftRepository draftRepository;
  final IProductLookupPort productLookup;
  final IInventoryAvailabilityPort stockChecker;

  @override
  Future<void> handle(AddProductToDraftCommand command) async {
    final draft = await draftRepository.findById(command.draftId);
    if (draft == null) throw DraftNotFoundException(command.draftId);

    final product = await productLookup.getSnapshot(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    final stock = await stockChecker.getAvailable(
      tenantId: command.tenantId,
      productId: command.productId,
    );

    draft.addProduct(
      product: product,
      sellability: product.sellability,
      availableStock: stock,
      quantity: Quantity(command.quantity),
    );

    await draftRepository.save(draft);
  }
}
```

---

## Ví dụ 3 — Query + DTO (GetAllSalesOrderDraft)

```dart
// get_all_sales_order_draft/get_all_sales_order_draft_query.dart
final class GetAllSalesOrderDraftQuery extends QueryBase<SalesOrderDraftListDto> {
  GetAllSalesOrderDraftQuery({String? id, required this.tenantId}) : super(id);
  final String tenantId;
}
```

```dart
// get_all_sales_order_draft/sales_order_draft_dto.dart
final class SalesOrderDraftListDto {
  const SalesOrderDraftListDto({required this.items});
  final List<SalesOrderDraftItemDto> items;
}

final class SalesOrderDraftItemDto {
  const SalesOrderDraftItemDto({
    required this.id,
    required this.customerName,
    required this.lineCount,
    required this.totalAmountMinor,
  });
  final String id;
  final String customerName;
  final int lineCount;
  final int totalAmountMinor;
}
```

```dart
// get_all_sales_order_draft/get_all_sales_order_draft_query_handler.dart
final class GetAllSalesOrderDraftQueryHandler
    implements IQueryHandler<GetAllSalesOrderDraftQuery, SalesOrderDraftListDto> {
  GetAllSalesOrderDraftQueryHandler({required this.readGateway});
  final ISalesOrderDraftReadGateway readGateway;

  @override
  Future<SalesOrderDraftListDto> handle(GetAllSalesOrderDraftQuery query) {
    return readGateway.listByTenant(tenantId: query.tenantId);
  }
}
```

---

## Ví dụ 4 — Port cho infrastructure

```dart
// ports/i_sales_order_draft_read_gateway.dart
abstract interface class ISalesOrderDraftReadGateway {
  Future<SalesOrderDraftListDto> listByTenant({required String tenantId});
  Future<SalesOrderDraftDetailDto?> getById({
    required String tenantId,
    required String draftId,
  });
}
```

Infrastructure (`modules/sales/infrastructure/`):

```dart
final class SupabaseSalesOrderDraftReadGateway implements ISalesOrderDraftReadGateway {
  // query sales.v_draft_summary — no business rules here
}
```

---

## Ví dụ 5 — Checkout orchestration

```dart
final class CheckoutSalesOrderCommandHandler
    implements ICommandHandler<CheckoutSalesOrderCommand, SalesOrderId> {
  CheckoutSalesOrderCommandHandler({
    required this.draftRepository,
    required this.orderRepository,
    required this.snapshotReloader,
    required this.tenantPolicy,
  });

  @override
  Future<SalesOrderId> handle(CheckoutSalesOrderCommand command) async {
    final draft = await draftRepository.findById(command.draftId);
    // ... load snapshots, tenant credit policy

    draft.validateForCheckout();
    final order = SalesOrder.checkoutFromDraft(
      draft: draft,
      amountPaid: command.amountPaid,
      fulfillmentStatus: command.fulfillmentStatus,
      // ...
    );

    draft.markCheckedOut();
    await draftRepository.save(draft);
    await orderRepository.save(order);
    // domain events → integration events via outbox (RPC transaction)

    return order.id;
  }
}
```

---

## Ví dụ 6 — Integration event handler

```dart
// event_handlers/payment_confirmed_handler.dart
final class PaymentConfirmedIntegrationEventHandler {
  PaymentConfirmedIntegrationEventHandler({
    required this.commandScheduler,
  });

  final ICommandScheduler commandScheduler;

  Future<void> handle(PaymentConfirmedIntegrationEvent event) async {
    await commandScheduler.enqueue(
      RecordSalesOrderPaymentSummaryCommand(
        tenantId: event.tenantId,
        orderId: event.orderId,
        amountPaidMinor: event.amountPaidMinor,
        idempotencyKey: event.id,
      ),
    );
  }
}
```

---

## Ví dụ 7 — Presentation gọi application

```dart
// presentation — chỉ biết IIAMModule
await salesModule.executeCommandAsync(
  AddProductToDraftCommand(
    tenantId: tenantId,
    draftId: draftId,
    productId: productId,
    quantity: 1,
  ),
);

final drafts = await salesModule.executeQueryAsync(
  GetAllSalesOrderDraftQuery(tenantId: tenantId),
);
```

---

## Ví dụ 8 — Command naming (Sales module)

| Feature area | Commands |
|--------------|----------|
| `sales_order_drafts` | `StartSalesOrderDraft`, `AddProductToDraft`, `ValidateDraftForCheckout` |
| `sales_orders` | `CheckoutSalesOrder`, `ConfirmSalesOrder`, `CancelSalesOrder` |
| `return_exchanges` | `StartReturnExchangeRequest`, `CompleteReturnExchangeRequest` |

Tất cả extend `CommandBase<TResult>` — không dùng `Update*`, `Save*`.

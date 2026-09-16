import 'package:vet45_sales_application/application.dart';

import '../bloc/sales_order_draft/sales_compose_state.dart';
import '../models/sales_order/sales_checkout_draft_args.dart';
import '../models/sales_order_draft/sales_compose_line_vm.dart';

abstract final class SalesCheckoutDraftArgsMapper {
  static SalesCheckoutDraftArgs fromCompose(
    SalesComposeState state, {
    required StoreSnapshotDto store,
    required ActorSnapshotDto seller,
  }) {
    if (!state.canCheckout) {
      throw StateError('Checkout requires a current priced compose state.');
    }
    final currency = state.lines.first.pricing.appliedUnitPrice.currencyCode;
    if (state.lines.any((line) => line.pricing.appliedUnitPrice.currencyCode != currency)) {
      throw StateError('Checkout lines must use one currency.');
    }
    return SalesCheckoutDraftArgs(
      runtimeDraftId: state.draftId,
      sourceDraftId: state.draftVersion == null ? null : state.draftId,
      customerId: state.customer.isWalkIn ? null : state.customer.partnerId,
      customerDisplayName: state.customer.displayName,
      customerPhone: state.customer.phone,
      isWalkIn: state.customer.isWalkIn,
      currencyCode: currency,
      orderNote: state.orderNote,
      expectedSourceVersion: state.draftVersion,
      provisionalTotalAmountMinor: state.subtotalMinor,
      commercialSnapshot: SalesCommercialSnapshotInput(
        store: store,
        seller: seller,
        customer: state.customer.isWalkIn
            ? null
            : CustomerSnapshotDto(
                customerId:
                    state.customer.partnerId ??
                    (throw StateError('Named customer requires a customer ID.')),
                displayName: state.customer.displayName,
                phoneNumber: state.customer.phone,
                taxCode: state.customer.taxCode,
                buyerType: state.customer.buyerType,
                invoiceLegalName: state.customer.invoiceLegalName,
                invoiceAddress: state.customer.invoiceAddress,
                invoiceEmail: state.customer.invoiceEmail,
              ),
        lines: [
          for (final line in state.lines)
            SalesReceiptLineDto(
              lineId: line.identity.lineId,
              product: ProductSnapshotDto(
                productId: line.identity.productId,
                sku: null,
                displayName: line.identity.productName,
              ),
              unit: ProductUnitSnapshotDto(
                productUnitId: line.identity.productUnitId,
                unitCode: null,
                unitName: line.identity.unitLabel,
              ),
              quantity: QuantityDto(
                quantityMicros: line.input.quantity * QuantityDto.scale,
              ),
              unitPrice: line.pricing.appliedUnitPrice,
              discountTotal: MoneyDto(
                amountMinor: 0,
                currencyCode: line.pricing.appliedUnitPrice.currencyCode,
              ),
              lineTotal: line.lineTotal,
            ),
        ],
      ),
      lines: [
        for (final line in state.lines)
          CheckoutLineInput(
            productId: line.identity.productId,
            productUnitId: line.identity.productUnitId,
            quantity: QuantityDto(quantityMicros: line.input.quantity * QuantityDto.scale),
            unitPrice: line.pricing.appliedUnitPrice,
          ),
      ],
    );
  }
}

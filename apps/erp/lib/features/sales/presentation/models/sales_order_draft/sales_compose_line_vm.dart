import 'package:equatable/equatable.dart';
import 'package:erp/features/sales/data/models.dart';

import '../shared/sales_pricing_models.dart';
import '../shared/sales_sellable_product_vm.dart';
import 'compose_line_identity.dart';
import 'compose_line_pricing.dart';
import 'compose_line_stock_hint.dart';
import 'compose_line_user_input.dart';

export 'compose_line_identity.dart';
export 'compose_line_pricing.dart';
export 'compose_line_stock_hint.dart';
export 'compose_line_user_input.dart';

/// View model presentation cho **một dòng hàng** trên màn soạn đơn (SG-02 / EP-01).
///
/// Cấu trúc: [identity] + [input] + [pricing] (+ [stock] tùy chọn).
/// Tiền authoritative chỉ có khi [pricing] là [ComposeLinePricingReady].
/// Derived display: [SalesComposeLineDisplay].
final class SalesComposeLineVm extends Equatable {
  const SalesComposeLineVm._composed({
    required this.identity,
    required this.input,
    required this.pricing,
    this.stock,
  });

  const SalesComposeLineVm.composed({
    required ComposeLineIdentity identity,
    required ComposeLineUserInput input,
    required ComposeLinePricing pricing,
    ComposeLineStockHint? stock,
  }) : this._composed(
         identity: identity,
         input: input,
         pricing: pricing,
         stock: stock,
       );

  final ComposeLineIdentity identity;
  final ComposeLineUserInput input;
  final ComposeLinePricing pricing;
  final ComposeLineStockHint? stock;

  // --- Factories ---

  factory SalesComposeLineVm.fromProductSelection({
    required String lineId,
    required SalesProductSelection selection,
  }) {
    return SalesComposeLineVm.composed(
      identity: ComposeLineIdentity(
        lineId: lineId,
        productId: selection.productId,
        productUnitId: selection.productUnitId,
        productName: selection.productName,
        unitLabel: selection.unitLabel,
        catalogUnitPrice: selection.unitPrice,
      ),
      input: const ComposeLineUserInput(quantity: 1),
      pricing: ComposeLinePricingNotReady(
        provisionalAppliedUnitPrice: selection.unitPrice,
        provisionalListUnitPrice: selection.listUnitPrice,
        provisionalFloorUnitPrice: selection.floorUnitPrice,
      ),
      stock: selection.stockQuantity == null
          ? null
          : ComposeLineStockHint(availableQuantity: selection.stockQuantity),
    );
  }

  /// Khôi phục dòng từ draft đã lưu — pricing chưa authoritative (chờ preview).
  factory SalesComposeLineVm.fromSavedDraftRestore({
    required SalesOrderDraftLineDto saved,
  }) {
    final quantity = (saved.quantity.quantityMicros / QuantityDto.scale).round().clamp(1, 999999);
    final catalogUnitPrice = saved.listUnitPrice ?? saved.appliedUnitPrice;

    return SalesComposeLineVm.composed(
      identity: ComposeLineIdentity(
        lineId: saved.lineId,
        productId: saved.productId,
        productUnitId: saved.productUnitId,
        productName: saved.productName,
        unitLabel: saved.unitName,
        catalogUnitPrice: catalogUnitPrice,
      ),
      input: ComposeLineUserInput(
        quantity: quantity,
        manual: ComposeManualPricing(
          unitPriceMinor: saved.manualUnitPriceMinor,
          discountMinor: saved.manualDiscountMinor,
          discountBasisPoints: saved.manualDiscountBasisPoints,
        ),
      ),
      pricing: ComposeLinePricingNotReady(
        provisionalAppliedUnitPrice: saved.appliedUnitPrice,
        provisionalListUnitPrice: saved.listUnitPrice,
      ),
    );
  }

  /// Merge working line với dòng authoritative sau persist draft.
  factory SalesComposeLineVm.fromPersistedDraftMerge({
    required SalesOrderDraftLineDto persisted,
    required SalesComposeLineVm local,
  }) {
    final quantity = (persisted.quantity.quantityMicros / QuantityDto.scale).round().clamp(
      1,
      999999,
    );
    final catalogUnitPrice = local.identity.catalogUnitPrice;
    final draftAmounts = ComposePricedAmounts.fromDraftLine(
      saved: persisted,
      catalogUnitPrice: catalogUnitPrice,
    );
    final amounts = ComposePricedAmounts(
      listUnitPrice: persisted.listUnitPrice ?? local.pricing.listUnitPrice ?? catalogUnitPrice,
      appliedUnitPrice: persisted.appliedUnitPrice,
      unitDiscount: local.pricing.unitDiscount ?? draftAmounts.unitDiscount,
      lineTotal: persisted.lineTotal,
      floorUnitPrice: local.pricing.floorUnitPrice,
    );

    return SalesComposeLineVm.composed(
      identity: ComposeLineIdentity(
        lineId: persisted.lineId,
        productId: persisted.productId,
        productUnitId: persisted.productUnitId,
        productName: persisted.productName,
        unitLabel: persisted.unitName,
        catalogUnitPrice: catalogUnitPrice,
      ),
      input: ComposeLineUserInput(
        quantity: quantity,
        manual: ComposeManualPricing(
          unitPriceMinor: persisted.manualUnitPriceMinor,
          discountMinor: persisted.manualDiscountMinor,
          discountBasisPoints: persisted.manualDiscountBasisPoints,
        ),
      ),
      pricing: ComposeLinePricingReady(
        contextVersion: local.pricing.contextVersion >= 0 ? local.pricing.contextVersion : 0,
        amounts: amounts,
        meta: ComposePricingMeta(
          sourceCode: persisted.pricingSourceCode,
          blockingCodes: persisted.pricingBlockingCodes,
          warningCodes: persisted.pricingWarningCodes,
        ),
      ),
      stock: local.stock,
    );
  }

  SalesComposeLineVm withQuantity(int quantity) {
    return copyWith(input: input.copyWith(quantity: quantity));
  }

  SalesComposeLineVm withManualPricing({
    int? unitPriceMinor,
    bool clearUnitPriceMinor = false,
    int? discountMinor,
    bool clearDiscountMinor = false,
    int? discountBasisPoints,
    bool clearDiscountBasisPoints = false,
  }) {
    return copyWith(
      input: input.copyWith(
        manual: input.manual.copyWith(
          unitPriceMinor: unitPriceMinor,
          clearUnitPriceMinor: clearUnitPriceMinor,
          discountMinor: discountMinor,
          clearDiscountMinor: clearDiscountMinor,
          discountBasisPoints: discountBasisPoints,
          clearDiscountBasisPoints: clearDiscountBasisPoints,
        ),
      ),
    );
  }

  /// Gắn kết quả pricing preview authoritative lên dòng.
  SalesComposeLineVm withPricingPreview(
    SalesPricingLineResult result, {
    required int contextVersion,
  }) {
    return copyWith(
      pricing: ComposeLinePricingReady(
        contextVersion: contextVersion,
        amounts: ComposePricedAmounts.fromPreviewLine(result),
        meta: ComposePricingMeta.fromPreviewLine(result),
      ),
    );
  }

  /// Đánh dấu pricing stale — quay về provisional, bỏ số authoritative.
  SalesComposeLineVm withPricingStale() {
    return copyWith(
      pricing: ComposeLinePricingNotReady(
        provisionalAppliedUnitPrice: pricing.appliedUnitPrice,
        provisionalListUnitPrice: pricing.listUnitPrice,
        provisionalFloorUnitPrice: pricing.floorUnitPrice,
      ),
    );
  }

  SalesComposeLineVm withMergedBlockingCodes(Iterable<String> extra) {
    if (extra.isEmpty) return this;
    return switch (pricing) {
      ComposeLinePricingReady ready => copyWith(
        pricing: ready.copyWith(meta: ready.meta.mergeBlockers(extra)),
      ),
      ComposeLinePricingNotReady notReady => copyWith(
        pricing: _promoteNotReadyWithBlockers(notReady, extra),
      ),
    };
  }

  SalesComposeLineVm withCatalogSnapshot({
    MoneyDto? listUnitPrice,
    MoneyDto? floorUnitPrice,
    int? stockQuantity,
  }) {
    final nextStock = stockQuantity == null
        ? stock
        : ComposeLineStockHint(availableQuantity: stockQuantity);

    return switch (pricing) {
      ComposeLinePricingReady ready => copyWith(
        stock: nextStock,
        pricing: ready.copyWith(
          amounts: ComposePricedAmounts(
            listUnitPrice: listUnitPrice ?? ready.amounts.listUnitPrice,
            appliedUnitPrice: ready.amounts.appliedUnitPrice,
            unitDiscount: ready.amounts.unitDiscount,
            lineTotal: ready.amounts.lineTotal,
            floorUnitPrice: floorUnitPrice ?? ready.amounts.floorUnitPrice,
          ),
        ),
      ),
      ComposeLinePricingNotReady notReady => copyWith(
        stock: nextStock,
        pricing: ComposeLinePricingNotReady(
          provisionalAppliedUnitPrice: notReady.provisionalAppliedUnitPrice,
          provisionalListUnitPrice: listUnitPrice ?? notReady.provisionalListUnitPrice,
          provisionalFloorUnitPrice: floorUnitPrice ?? notReady.provisionalFloorUnitPrice,
        ),
      ),
    };
  }

  SalesComposeLineVm withRestorePricingDiagnostics({
    MoneyDto? listUnitPrice,
    MoneyDto? floorUnitPrice,
    String? sourceCode,
    List<String> warningCodes = const [],
    List<String> blockingCodes = const [],
  }) {
    return switch (pricing) {
      ComposeLinePricingReady ready => copyWith(
        pricing: ready.copyWith(
          amounts: ComposePricedAmounts(
            listUnitPrice: listUnitPrice ?? ready.amounts.listUnitPrice,
            appliedUnitPrice: ready.amounts.appliedUnitPrice,
            unitDiscount: ready.amounts.unitDiscount,
            lineTotal: ready.amounts.lineTotal,
            floorUnitPrice: floorUnitPrice,
          ),
          meta: ComposePricingMeta(
            sourceCode: sourceCode,
            blockingCodes: blockingCodes,
            warningCodes: warningCodes,
          ),
        ),
      ),
      ComposeLinePricingNotReady notReady => copyWith(
        pricing: ComposeLinePricingReady(
          contextVersion: -1,
          amounts: ComposePricedAmounts(
            listUnitPrice:
                listUnitPrice ??
                notReady.provisionalListUnitPrice ??
                notReady.provisionalAppliedUnitPrice,
            appliedUnitPrice: notReady.provisionalAppliedUnitPrice,
            unitDiscount: MoneyDto(
              amountMinor: 0,
              currencyCode: notReady.provisionalAppliedUnitPrice.currencyCode,
            ),
            lineTotal: MoneyDto(
              amountMinor: notReady.provisionalAppliedUnitPrice.amountMinor * input.quantity,
              currencyCode: notReady.provisionalAppliedUnitPrice.currencyCode,
            ),
            floorUnitPrice: floorUnitPrice,
          ),
          meta: ComposePricingMeta(
            sourceCode: sourceCode,
            blockingCodes: blockingCodes,
            warningCodes: warningCodes,
          ),
        ),
      ),
    };
  }

  SalesComposeLineVm copyWith({
    ComposeLineIdentity? identity,
    ComposeLineUserInput? input,
    ComposeLinePricing? pricing,
    ComposeLineStockHint? stock,
    bool clearStock = false,
  }) {
    return SalesComposeLineVm._composed(
      identity: identity ?? this.identity,
      input: input ?? this.input,
      pricing: pricing ?? this.pricing,
      stock: clearStock ? null : (stock ?? this.stock),
    );
  }

  static ComposeLinePricingReady _promoteNotReadyWithBlockers(
    ComposeLinePricingNotReady notReady,
    Iterable<String> extra,
  ) {
    final applied = notReady.provisionalAppliedUnitPrice;
    return ComposeLinePricingReady(
      contextVersion: -1,
      amounts: ComposePricedAmounts(
        listUnitPrice: notReady.provisionalListUnitPrice ?? applied,
        appliedUnitPrice: applied,
        unitDiscount: MoneyDto(amountMinor: 0, currencyCode: applied.currencyCode),
        lineTotal: MoneyDto(
          amountMinor: applied.amountMinor,
          currencyCode: applied.currencyCode,
        ),
        floorUnitPrice: notReady.provisionalFloorUnitPrice,
      ),
      meta: ComposePricingMeta(blockingCodes: [...extra]),
    );
  }

  @override
  List<Object?> get props => [identity, input, pricing, stock];
}

/// Derived display/commercial values — đọc qua sub-model, không delegate phẳng.
extension SalesComposeLineDisplay on SalesComposeLineVm {
  int get lineTotalMinor => switch (pricing) {
    ComposeLinePricingReady(:final amounts) => amounts.lineTotal.amountMinor,
    ComposeLinePricingNotReady(:final provisionalAppliedUnitPrice) =>
      provisionalAppliedUnitPrice.amountMinor * input.quantity,
  };

  MoneyDto get lineTotal => MoneyDto(
    amountMinor: lineTotalMinor,
    currencyCode: pricing.appliedUnitPrice.currencyCode,
  );

  String get unitPriceLabel => '${_formatMoney(pricing.appliedUnitPrice)}/${identity.unitLabel}';

  MoneyDto get resolvedListPrice => pricing.listUnitPrice ?? identity.catalogUnitPrice;

  int get listAmountMinor => resolvedListPrice.amountMinor * input.quantity;

  String? get warningText => stock?.warningText(identity.unitLabel);
  SalesStockWarningLevel get warningLevel => stock?.warningLevel ?? SalesStockWarningLevel.none;
  int get maxQuantity => stock?.maxQuantity ?? 9999;

  bool get hasSpecialPricing =>
      !input.manual.isEmpty ||
      pricing.sourceCode == 'MANUAL' ||
      pricing.sourceCode == 'CUSTOMER_PRIVATE_RULE' ||
      pricing.sourceCode == 'PRIVATE_RULE' ||
      pricing.sourceCode == 'CUSTOMER_PRICE' ||
      pricing.sourceCode == 'SPECIAL_PRICE' ||
      (pricing.listUnitPrice != null &&
          pricing.appliedUnitPrice.amountMinor != pricing.listUnitPrice!.amountMinor);

  static String _formatMoney(MoneyDto money) {
    final digits = money.amountMinor.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
    }
    return '${buffer.toString()}đ';
  }
}

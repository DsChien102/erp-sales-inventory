import 'package:get_it/get_it.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_pricing_application/application.dart' as pricing;
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../lookups/sales_partner_customer_lookup.dart';
import 'sales_draft_payload_fingerprint.dart';

/// ERP cross-module draft orchestrator (Catalog + Partner + Pricing → Sales).
abstract final class SalesDraftBackend {
  static SalesDraftPersistFn bindPersist([GetIt? getIt]) {
    final di = getIt ?? GetIt.instance;
    return (request) => _persist(di, request);
  }

  static SalesDraftRestoreFn bindRestore([GetIt? getIt]) {
    final di = getIt ?? GetIt.instance;
    return (draftId) => _restore(di, draftId);
  }

  static Future<SalesOrderDraftDto> _persist(
    GetIt di,
    SalesDraftPersistRequest request,
  ) async {
    if (request.lines.isEmpty) {
      throw const SalesExternalOperationException(
        'Đơn nháp phải có ít nhất một dòng hàng.',
      );
    }

    final tenantId = await di<IExecutionContext>().requireTenantId();
    final actorId = await di<IExecutionContext>().requireUserId();
    final storeId = await di<IActiveStoreContext>().requireActiveStoreId();

    final customerSnapshot = await _resolveCustomerForPersist(di, request.customer);
    final catalogOutcome = await _resolveProducts(
      di,
      tenantId: tenantId,
      storeId: storeId,
      productIds: request.lines.map((line) => line.identity.productId),
    );
    if (catalogOutcome.failed) {
      throw const SalesExternalOperationException(
        'Không kiểm tra được sản phẩm. Vui lòng thử lại.',
      );
    }
    final catalogSnapshots = _buildCatalogLines(
      lines: request.lines,
      catalog: catalogOutcome,
    );

    final pricingOutcome = await _previewPricing(
      di,
      tenantId: tenantId,
      storeId: storeId,
      customerId: customerSnapshot?.customerId,
      currencyCode: request.currencyCode,
      contextVersion: request.pricingContextVersion,
      lines: request.lines,
    );

    final fingerprint = SalesDraftPayloadFingerprint.compute(
      storeId: storeId,
      customerId: customerSnapshot?.customerId,
      currencyCode: request.currencyCode,
      orderNote: request.orderNote,
      pricingPreviewToken: pricingOutcome.previewToken ?? request.pricingPreviewToken,
      lines: request.lines,
    );

    final draftLines = <SalesOrderDraftLineInput>[
      for (final line in request.lines)
        _toDraftLineInput(
          line: line,
          catalog: catalogSnapshots[line.identity.lineId]!,
          pricing: pricingOutcome.linesById[line.identity.lineId],
          needsRevalidation: pricingOutcome.failed,
        ),
    ];

    final needsRevalidation =
        pricingOutcome.failed || draftLines.any((line) => line.needsRevalidation);

    if (request.isUpdate) {
      final draftId = request.draftId!.trim();
      final command = UpdateSalesOrderDraftCommand(
        tenantId: tenantId,
        actorId: actorId,
        draftId: draftId,
        storeId: storeId,
        customer: customerSnapshot,
        currencyCode: request.currencyCode,
        orderNote: _normalizeNote(request.orderNote),
        pricingPreviewToken: pricingOutcome.previewToken ?? request.pricingPreviewToken,
        needsRevalidation: needsRevalidation,
        lines: draftLines,
        expectedVersion: request.expectedVersion!,
        payloadHash: fingerprint.payloadHash,
        idempotencyKey: SalesDraftPayloadFingerprint.idempotencyKey(
          operation: 'update',
          identity: draftId,
          payloadHash: fingerprint.payloadHash,
        ),
      );
      return di<ISalesModule>().executeCommandAsync(command);
    }

    final command = SaveSalesOrderDraftCommand(
      tenantId: tenantId,
      actorId: actorId,
      storeId: storeId,
      customer: customerSnapshot,
      currencyCode: request.currencyCode,
      orderNote: _normalizeNote(request.orderNote),
      pricingPreviewToken: pricingOutcome.previewToken ?? request.pricingPreviewToken,
      needsRevalidation: needsRevalidation,
      lines: draftLines,
      payloadHash: fingerprint.payloadHash,
      idempotencyKey: SalesDraftPayloadFingerprint.idempotencyKey(
        operation: 'save',
        identity: request.composeSessionId.trim(),
        payloadHash: fingerprint.payloadHash,
      ),
    );
    return di<ISalesModule>().executeCommandAsync(command);
  }

  static Future<SalesDraftRestoreResult> _restore(
    GetIt di,
    String draftId,
  ) async {
    final trimmedDraftId = draftId.trim();
    if (trimmedDraftId.isEmpty) {
      throw const SalesExternalOperationException(
        'Mã đơn nháp không hợp lệ.',
      );
    }

    final tenantId = await di<IExecutionContext>().requireTenantId();
    final actorId = await di<IExecutionContext>().requireUserId();
    final storeId = await di<IActiveStoreContext>().requireActiveStoreId();
    final restore = await di<ISalesModule>().executeQueryAsync(
      GetSalesOrderDraftForRestoreQuery(
        tenantId: tenantId,
        actorId: actorId,
        draftId: trimmedDraftId,
        storeId: storeId,
      ),
    );
    final draft = restore.draft;
    final issues = <SalesDraftRestoreIssue>[];

    final customer = await _restoreCustomer(
      di,
      draft.customer,
      issues: issues,
    );

    final catalogOutcome = await _resolveProducts(
      di,
      tenantId: tenantId,
      storeId: storeId,
      productIds: draft.lines.map((line) => line.productId),
    );
    if (catalogOutcome.failed) {
      issues.add(
        const SalesDraftRestoreIssue(
          code: SalesDraftRestoreIssueCode.catalogUnavailable,
          message: 'Không kiểm tra được sản phẩm. Vui lòng thử lại.',
        ),
      );
    }

    final restoredLines = [
      for (final saved in draft.lines)
        _restoreLine(
          catalog: catalogOutcome,
          saved: saved,
          currencyCode: draft.total.currencyCode,
          issues: issues,
        ),
    ];

    final pricingOutcome = await _previewPricing(
      di,
      tenantId: tenantId,
      storeId: storeId,
      customerId: draft.customer?.customerId,
      currencyCode: draft.total.currencyCode,
      contextVersion: 0,
      lines: restoredLines,
    );

    if (pricingOutcome.failed) {
      issues.add(
        const SalesDraftRestoreIssue(
          code: SalesDraftRestoreIssueCode.pricingUnavailable,
          message: 'Không thể làm mới giá khi khôi phục đơn nháp.',
        ),
      );
    } else if (_pricingChanged(
      savedToken: draft.pricingPreviewToken,
      savedLines: draft.lines,
      preview: pricingOutcome,
    )) {
      issues.add(
        const SalesDraftRestoreIssue(
          code: SalesDraftRestoreIssueCode.pricingChanged,
          message: 'Giá hiện tại đã thay đổi so với lúc lưu nháp.',
        ),
      );
    }

    final linesWithPricing = [
      for (final line in restoredLines)
        _applyRestorePricing(line, pricingOutcome.linesById[line.identity.lineId]),
    ];

    return SalesDraftRestoreResult(
      draft: draft,
      customer: customer,
      lines: linesWithPricing,
      orderNote: draft.orderNote,
      issues: issues,
    );
  }

  static Future<CustomerSnapshotDto?> _resolveCustomerForPersist(
    GetIt di,
    SalesComposeCustomerVm customer,
  ) async {
    if (customer.isWalkIn || customer.partnerId == null || customer.partnerId!.trim().isEmpty) {
      return null;
    }
    final selection = await SalesPartnerCustomerLookup.bindResolve(di)(
      customer.partnerId!,
    );
    return CustomerSnapshotDto(
      customerId: selection.partnerId!,
      displayName: selection.displayName,
      phoneNumber: selection.phone,
    );
  }

  static Future<SalesComposeCustomerVm> _restoreCustomer(
    GetIt di,
    CustomerSnapshotDto? saved, {
    required List<SalesDraftRestoreIssue> issues,
  }) async {
    if (saved == null) {
      return SalesComposeCustomerVm.walkIn();
    }
    try {
      final selection = await SalesPartnerCustomerLookup.bindResolve(di)(
        saved.customerId,
      );
      return SalesComposeCustomerVm.fromSelection(selection);
    } on Object {
      issues.add(
        SalesDraftRestoreIssue(
          code: SalesDraftRestoreIssueCode.customerUnavailable,
          message: 'Khách hàng "${saved.displayName}" không còn khả dụng.',
        ),
      );
      return SalesComposeCustomerVm(
        displayName: saved.displayName,
        phone: saved.phoneNumber,
        partnerId: saved.customerId,
      );
    }
  }

  /// Resolves every distinct product of the order in a single Catalog call.
  ///
  /// A thrown query is infrastructure failure, so it is reported as
  /// [_CatalogResolutionOutcome.failed] instead of being mistaken for a product
  /// that stopped being sellable.
  static Future<_CatalogResolutionOutcome> _resolveProducts(
    GetIt di, {
    required String tenantId,
    required String storeId,
    required Iterable<String> productIds,
  }) async {
    final requested = <String>[];
    for (final productId in productIds) {
      final trimmed = productId.trim();
      if (trimmed.isNotEmpty && !requested.contains(trimmed)) {
        requested.add(trimmed);
      }
    }
    if (requested.isEmpty) {
      return const _CatalogResolutionOutcome(failed: false, byProductId: {});
    }
    try {
      final resolutions = await di<ICatalogModule>().executeQueryAsync(
        ResolveSellableProductsQuery(
          tenantId: tenantId,
          storeId: storeId,
          productIds: requested,
        ),
      );
      return _CatalogResolutionOutcome(
        failed: false,
        byProductId: {
          for (final resolution in resolutions) resolution.productId: resolution,
        },
      );
    } on Object {
      return const _CatalogResolutionOutcome(failed: true, byProductId: {});
    }
  }

  static Map<String, _CatalogLineSnapshot> _buildCatalogLines({
    required List<SalesComposeLineVm> lines,
    required _CatalogResolutionOutcome catalog,
  }) {
    final result = <String, _CatalogLineSnapshot>{};

    for (final line in lines) {
      final resolution = catalog.byProductId[line.identity.productId.trim()];
      if (resolution == null || resolution.resolution == SellableProductResolution.notFound) {
        throw const SalesExternalOperationException(
          'Sản phẩm không còn tồn tại trong danh mục. Vui lòng kiểm tra lại.',
        );
      }
      final product = resolution.product;
      if (resolution.resolution != SellableProductResolution.sellable ||
          product == null ||
          !product.isSellable) {
        throw const SalesExternalOperationException(
          'Sản phẩm không còn bán được. Vui lòng kiểm tra lại.',
        );
      }
      final unit = _findUnit(product, line.identity.productUnitId);
      if (unit == null || !unit.isActive || !unit.isSellable) {
        throw const SalesExternalOperationException(
          'Đơn vị bán không còn hợp lệ. Vui lòng kiểm tra lại.',
        );
      }
      result[line.identity.lineId] = _CatalogLineSnapshot(product: product, unit: unit);
    }
    return result;
  }

  static SellableProductUnitDto? _findUnit(
    SellableProductDto product,
    String productUnitId,
  ) {
    for (final candidate in product.units) {
      if (candidate.productUnitId == productUnitId) {
        return candidate;
      }
    }
    return null;
  }

  static SalesComposeLineVm _restoreLine({
    required _CatalogResolutionOutcome catalog,
    required SalesOrderDraftLineDto saved,
    required String currencyCode,
    required List<SalesDraftRestoreIssue> issues,
  }) {
    final base = SalesComposeLineVm.fromSavedDraftRestore(saved: saved);

    if (catalog.failed) {
      // The order-level catalogUnavailable issue already explains this; the
      // blocker keeps the line from being checked out on stale data.
      return base.withMergedBlockingCodes(['CATALOG_UNAVAILABLE']);
    }

    final resolution = catalog.byProductId[saved.productId.trim()];
    if (resolution == null || resolution.resolution == SellableProductResolution.notFound) {
      issues.add(
        SalesDraftRestoreIssue(
          code: SalesDraftRestoreIssueCode.productUnavailable,
          lineId: saved.lineId,
          message: 'Sản phẩm "${saved.productName}" không còn tồn tại trong danh mục.',
        ),
      );
      return base.withMergedBlockingCodes(['PRODUCT_NOT_FOUND']);
    }

    final product = resolution.product;
    if (resolution.resolution != SellableProductResolution.sellable ||
        product == null ||
        !product.isSellable) {
      issues.add(
        SalesDraftRestoreIssue(
          code: SalesDraftRestoreIssueCode.productUnavailable,
          lineId: saved.lineId,
          message: 'Sản phẩm "${saved.productName}" không còn bán được.',
        ),
      );
      return base.withMergedBlockingCodes(['PRODUCT_UNAVAILABLE']);
    }

    final unit = _findUnit(product, saved.productUnitId);
    if (unit == null || !unit.isActive || !unit.isSellable) {
      issues.add(
        SalesDraftRestoreIssue(
          code: SalesDraftRestoreIssueCode.unitUnavailable,
          lineId: saved.lineId,
          message: 'Đơn vị bán của "${saved.productName}" không còn hợp lệ.',
        ),
      );
      return base
          .withMergedBlockingCodes(['UNIT_UNAVAILABLE'])
          .withCatalogSnapshot(
            listUnitPrice: MoneyDto(
              amountMinor: unit?.listPriceMinor ?? base.resolvedListPrice.amountMinor,
              currencyCode: currencyCode,
            ),
            floorUnitPrice: unit?.floorPriceMinor == null
                ? null
                : MoneyDto(
                    amountMinor: unit!.floorPriceMinor!,
                    currencyCode: currencyCode,
                  ),
            stockQuantity: unit == null
                ? base.stock?.availableQuantity
                : (unit.availableStockMicros == null
                      ? null
                      : unit.availableStockMicros! ~/ QuantityDto.scale),
          );
    }

    return base.withCatalogSnapshot(
      listUnitPrice: MoneyDto(
        amountMinor: unit.listPriceMinor,
        currencyCode: currencyCode,
      ),
      floorUnitPrice: unit.floorPriceMinor == null
          ? null
          : MoneyDto(
              amountMinor: unit.floorPriceMinor!,
              currencyCode: currencyCode,
            ),
      stockQuantity: unit.availableStockMicros == null
          ? null
          : unit.availableStockMicros! ~/ QuantityDto.scale,
    );
  }

  static Future<_PricingOutcome> _previewPricing(
    GetIt di, {
    required String tenantId,
    required String storeId,
    required String? customerId,
    required String currencyCode,
    required int contextVersion,
    required List<SalesComposeLineVm> lines,
  }) async {
    try {
      final preview = await di<pricing.IPricingModule>().executeQueryAsync(
        pricing.PreviewSalesWorkingStatePricingQuery(
          tenantId: tenantId,
          storeId: storeId,
          customerId: customerId,
          currencyCode: currencyCode,
          contextVersion: contextVersion,
          effectiveAt: DateTime.now().toUtc(),
          lines: [
            for (final line in lines)
              pricing.SalesPricingLineInput(
                localLineId: line.identity.lineId,
                productId: line.identity.productId,
                productUnitId: line.identity.productUnitId,
                quantityMicros: line.input.quantity * QuantityDto.scale,
                manualUnitPriceMinor: line.input.manual.unitPriceMinor,
                manualDiscountMinor: line.input.manual.discountMinor,
                manualDiscountBasisPoints: line.input.manual.discountBasisPoints,
              ),
          ],
        ),
      );
      return _PricingOutcome(
        failed: false,
        previewToken: preview.previewToken,
        linesById: {
          for (final line in preview.lines) line.localLineId: line,
        },
      );
    } on Object {
      return const _PricingOutcome(failed: true, previewToken: null, linesById: {});
    }
  }

  static SalesOrderDraftLineInput _toDraftLineInput({
    required SalesComposeLineVm line,
    required _CatalogLineSnapshot catalog,
    required pricing.SalesPricingLinePreviewDto? pricing,
    required bool needsRevalidation,
  }) {
    final currency = line.pricing.appliedUnitPrice.currencyCode;
    final applied = pricing == null
        ? line.pricing.appliedUnitPrice
        : MoneyDto(
            amountMinor: pricing.appliedUnitPriceMinor,
            currencyCode: currency,
          );
    final lineTotal = pricing == null
        ? line.lineTotal
        : MoneyDto(
            amountMinor: pricing.lineTotalMinor,
            currencyCode: currency,
          );
    final listPrice = pricing?.listPriceMinor == null
        ? (line.pricing.listUnitPrice ??
              MoneyDto(
                amountMinor: catalog.unit.listPriceMinor,
                currencyCode: currency,
              ))
        : MoneyDto(
            amountMinor: pricing!.listPriceMinor!,
            currencyCode: currency,
          );

    return SalesOrderDraftLineInput(
      productId: catalog.product.productId,
      productSku: catalog.product.sku?.trim().isNotEmpty == true
          ? catalog.product.sku!.trim()
          : catalog.product.productId,
      productName: catalog.product.displayName,
      productUnitId: catalog.unit.productUnitId,
      unitCode: catalog.unit.unitCode,
      unitName: catalog.unit.unitName,
      quantity: QuantityDto(quantityMicros: line.input.quantity * QuantityDto.scale),
      appliedUnitPrice: applied,
      lineTotal: lineTotal,
      listUnitPrice: listPrice,
      manualUnitPriceMinor: line.input.manual.unitPriceMinor,
      manualDiscountMinor: line.input.manual.discountMinor,
      manualDiscountBasisPoints: line.input.manual.discountBasisPoints,
      pricingSourceCode: pricing?.sourceCode ?? line.pricing.sourceCode,
      pricingWarningCodes: pricing?.warningCodes ?? line.pricing.warningCodes,
      pricingBlockingCodes: pricing?.blockingCodes ?? line.pricing.blockingCodes,
      needsRevalidation: needsRevalidation || (pricing?.blockingCodes.isNotEmpty ?? false),
    );
  }

  static SalesComposeLineVm _applyRestorePricing(
    SalesComposeLineVm line,
    pricing.SalesPricingLinePreviewDto? pricingLine,
  ) {
    if (pricingLine == null) return line;
    final currency = line.pricing.appliedUnitPrice.currencyCode;
    return line.withRestorePricingDiagnostics(
      listUnitPrice: pricingLine.listPriceMinor == null
          ? line.pricing.listUnitPrice
          : MoneyDto(
              amountMinor: pricingLine.listPriceMinor!,
              currencyCode: currency,
            ),
      floorUnitPrice: pricingLine.floorPriceMinor == null
          ? null
          : MoneyDto(
              amountMinor: pricingLine.floorPriceMinor!,
              currencyCode: currency,
            ),
      sourceCode: pricingLine.sourceCode,
      warningCodes: pricingLine.warningCodes,
      blockingCodes: {
        ...line.pricing.blockingCodes,
        ...pricingLine.blockingCodes,
      }.toList(growable: false),
    );
  }

  static bool _pricingChanged({
    required String? savedToken,
    required List<SalesOrderDraftLineDto> savedLines,
    required _PricingOutcome preview,
  }) {
    if (preview.failed) return false;
    final currentToken = preview.previewToken?.trim();
    if ((savedToken?.trim() ?? '') != (currentToken ?? '')) {
      return true;
    }
    for (final saved in savedLines) {
      final current = preview.linesById[saved.lineId];
      if (current == null) return true;
      if (current.appliedUnitPriceMinor != saved.appliedUnitPrice.amountMinor) {
        return true;
      }
      if (current.lineTotalMinor != saved.lineTotal.amountMinor) {
        return true;
      }
    }
    return false;
  }

  static String? _normalizeNote(String? note) {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

final class _CatalogLineSnapshot {
  const _CatalogLineSnapshot({
    required this.product,
    required this.unit,
  });

  final SellableProductDto product;
  final SellableProductUnitDto unit;
}

final class _CatalogResolutionOutcome {
  const _CatalogResolutionOutcome({
    required this.failed,
    required this.byProductId,
  });

  /// True when the Catalog lookup itself failed — never a statement about the
  /// products.
  final bool failed;
  final Map<String, SellableProductResolutionDto> byProductId;
}

final class _PricingOutcome {
  const _PricingOutcome({
    required this.failed,
    required this.previewToken,
    required this.linesById,
  });

  final bool failed;
  final String? previewToken;
  final Map<String, pricing.SalesPricingLinePreviewDto> linesById;
}

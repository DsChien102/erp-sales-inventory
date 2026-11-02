import '../../iam/support/iam_test_session.dart';
import 'package:erp/core/session/session_controller.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import '../../partner/support/scripted_partner_repository.dart';
import 'package:vet45_pricing_application/application.dart' as pricing;
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/presentation/lookups/sales_partner_customer_lookup.dart';
import 'package:erp/features/sales/presentation/orchestration/sales_draft_backend.dart';
import 'package:erp/features/sales/presentation/orchestration/sales_draft_payload_fingerprint.dart';

void main() {
  late GetIt di;
  late ScriptedPartnerRepository partner;
  late PartnerDetailDto partnerDetail;
  late _RecordingCatalogModule catalog;
  late _RecordingPricingModule pricingModule;
  late _RecordingSalesModule sales;

  setUp(() {
    di = GetIt.asNewInstance();
    partnerDetail = _activeDetail;
    partner = ScriptedPartnerRepository(
      onCall: (method, _) {
        if (method == 'getDetail') return partnerDetail;
        throw StateError('Unexpected partner call $method');
      },
    );
    catalog = _RecordingCatalogModule();
    pricingModule = _RecordingPricingModule();
    sales = _RecordingSalesModule();
    di
      ..registerSingleton<PartnerRepository>(partner)
      ..registerSingleton<ICatalogModule>(catalog)
      ..registerSingleton<pricing.IPricingModule>(pricingModule)
      ..registerSingleton<ISalesModule>(sales)
      ..registerSingleton<IExecutionContext>(const _ExecutionContext())
      ..registerSingleton<SessionController>(
        testSessionController(tenantId: 'tenant-1', userId: 'user-1', activeStoreId: 'store-1'),
      );
  });

  group('SalesPartnerCustomerLookup.resolve', () {
    test('uses exact getDetail and rejects inactive partners', () async {
      final selection = await SalesPartnerCustomerLookup.bindResolve(di)(
        'partner-1',
      );
      expect(partner.invocations.single.method, 'getDetail');
      expect(partner.invocations.single.args['partnerId'], 'partner-1');
      expect(selection.partnerId, 'partner-1');
      expect(selection.isWalkIn, isFalse);

      partnerDetail = _inactiveDetail;
      await expectLater(
        SalesPartnerCustomerLookup.bindResolve(di)('partner-1'),
        throwsA(isA<SalesExternalOperationException>()),
      );
    });
  });

  group('SalesDraftPayloadFingerprint', () {
    test('same pending payload produces the same SHA-256 hash and idempotency key', () {
      final a = SalesDraftPayloadFingerprint.compute(
        storeId: 'store-1',
        customerId: 'partner-1',
        currencyCode: 'VND',
        orderNote: '  Giao chieu  ',
        pricingPreviewToken: 'tok-1',
        lines: [_line],
      );
      final b = SalesDraftPayloadFingerprint.compute(
        storeId: 'store-1',
        customerId: 'partner-1',
        currencyCode: 'VND',
        orderNote: '  Giao chieu  ',
        pricingPreviewToken: 'tok-1',
        lines: [_line],
      );

      expect(a.payloadHash, b.payloadHash);
      expect(a.payloadHash, hasLength(64));
      expect(
        SalesDraftPayloadFingerprint.idempotencyKey(
          operation: 'save',
          identity: 'session-1',
          payloadHash: a.payloadHash,
        ),
        'save:session-1:${a.payloadHash}',
      );

      final canonical = jsonDecode(a.canonicalJson) as Map<String, dynamic>;
      expect(canonical.keys.toList(), [
        'currencyCode',
        'customerId',
        'lines',
        'orderNote',
        'pricingPreviewToken',
        'storeId',
      ]);
      expect(canonical['orderNote'], 'Giao chieu');
    });

    test('changed payload produces a different fingerprint', () {
      final base = SalesDraftPayloadFingerprint.compute(
        storeId: 'store-1',
        customerId: 'partner-1',
        currencyCode: 'VND',
        orderNote: 'note',
        pricingPreviewToken: 'tok-1',
        lines: [_line],
      );
      final changed = SalesDraftPayloadFingerprint.compute(
        storeId: 'store-1',
        customerId: 'partner-1',
        currencyCode: 'VND',
        orderNote: 'note',
        pricingPreviewToken: 'tok-1',
        lines: [
          _line.withQuantity(3),
        ],
      );
      expect(changed.payloadHash, isNot(base.payloadHash));
    });
  });

  group('SalesDraftBackend.persist', () {
    test('save validates store, customer, product/unit, and pricing before Sales save', () async {
      catalog.productsById[_product.productId] = _product;
      pricingModule.preview = _pricingPreview;

      final result = await SalesDraftBackend.bindPersist(di)(
        SalesDraftPersistRequest(
          composeSessionId: 'session-1',
          customer: const SalesComposeCustomerVm(
            displayName: 'Backend Customer',
            phone: '0988123456',
            partnerId: 'partner-1',
          ),
          currencyCode: 'VND',
          orderNote: 'Giao chieu',
          pricingPreviewToken: 'stale-token',
          pricingContextVersion: 1,
          lines: [_line],
        ),
      );

      expect(partner.callsOf('getDetail'), hasLength(1));
      expect(
        catalog.queries.whereType<ResolveSellableProductsQuery>(),
        hasLength(1),
      );
      expect(
        pricingModule.queries.whereType<pricing.PreviewSalesWorkingStatePricingQuery>(),
        hasLength(1),
      );
      expect(sales.commands.single, isA<SaveSalesOrderDraftCommand>());
      final command = sales.commands.single as SaveSalesOrderDraftCommand;
      expect(command.storeId, 'store-1');
      expect(command.tenantId, 'tenant-1');
      expect(command.actorId, 'user-1');
      expect(command.customer?.customerId, 'partner-1');
      expect(command.customer?.displayName, 'Backend Customer');
      expect(command.orderNote, 'Giao chieu');
      expect(command.pricingPreviewToken, 'preview-token-1');
      expect(command.needsRevalidation, isFalse);
      expect(command.lines.single.productSku, 'SKU-001');
      expect(command.lines.single.unitCode, 'HOP');
      expect(command.lines.single.appliedUnitPrice.amountMinor, 120000);
      expect(command.lines.single.listUnitPrice?.amountMinor, 125000);
      expect(command.payloadHash, isNotEmpty);
      expect(command.idempotencyKey, startsWith('save:session-1:'));
      expect(result.draftId, 'draft-saved-1');
    });

    test('walk-in does not call Partner', () async {
      catalog.productsById[_product.productId] = _product;
      pricingModule.preview = _pricingPreview;

      await SalesDraftBackend.bindPersist(di)(
        SalesDraftPersistRequest(
          composeSessionId: 'session-walkin',
          customer: SalesComposeCustomerVm.walkIn(),
          currencyCode: 'VND',
          pricingContextVersion: 0,
          lines: [_line],
        ),
      );

      expect(partner.invocations, isEmpty);
      final command = sales.commands.single as SaveSalesOrderDraftCommand;
      expect(command.customer, isNull);
    });

    test('pricing failure still saves with needsRevalidation=true', () async {
      catalog.productsById[_product.productId] = _product;
      pricingModule.failure = StateError('pricing down');

      await SalesDraftBackend.bindPersist(di)(
        SalesDraftPersistRequest(
          composeSessionId: 'session-pricing',
          customer: SalesComposeCustomerVm.walkIn(),
          currencyCode: 'VND',
          pricingPreviewToken: 'client-token',
          pricingContextVersion: 2,
          lines: [_line],
        ),
      );

      final command = sales.commands.single as SaveSalesOrderDraftCommand;
      expect(command.needsRevalidation, isTrue);
      expect(command.pricingPreviewToken, 'client-token');
      expect(command.lines.single.appliedUnitPrice.amountMinor, 120000);
      expect(command.lines.single.needsRevalidation, isTrue);
    });

    test('missing or inactive customer prevents Sales mutation', () async {
      partnerDetail = _inactiveDetail;
      catalog.productsById[_product.productId] = _product;

      await expectLater(
        SalesDraftBackend.bindPersist(di)(
          SalesDraftPersistRequest(
            composeSessionId: 'session-bad-customer',
            customer: const SalesComposeCustomerVm(
              displayName: 'Inactive',
              partnerId: 'partner-1',
            ),
            currencyCode: 'VND',
            pricingContextVersion: 0,
            lines: [_line],
          ),
        ),
        throwsA(isA<SalesExternalOperationException>()),
      );
      expect(sales.commands, isEmpty);
    });

    test('missing or inactive product/unit prevents Sales mutation', () async {
      catalog.productsById[_product.productId] = _blockedProduct;

      await expectLater(
        SalesDraftBackend.bindPersist(di)(
          SalesDraftPersistRequest(
            composeSessionId: 'session-bad-product',
            customer: SalesComposeCustomerVm.walkIn(),
            currencyCode: 'VND',
            pricingContextVersion: 0,
            lines: [_line],
          ),
        ),
        throwsA(isA<SalesExternalOperationException>()),
      );
      expect(sales.commands, isEmpty);

      catalog.productsById[_product.productId] = _productMissingUnit;
      await expectLater(
        SalesDraftBackend.bindPersist(di)(
          SalesDraftPersistRequest(
            composeSessionId: 'session-bad-unit',
            customer: SalesComposeCustomerVm.walkIn(),
            currencyCode: 'VND',
            pricingContextVersion: 0,
            lines: [_line],
          ),
        ),
        throwsA(isA<SalesExternalOperationException>()),
      );
      expect(sales.commands, isEmpty);
    });

    test('resolves every line with one Catalog call', () async {
      catalog.productsById[_product.productId] = _product;
      catalog.productsById[_secondProduct.productId] = _secondProduct;
      pricingModule.preview = _pricingPreviewTwoLines;

      await SalesDraftBackend.bindPersist(di)(
        SalesDraftPersistRequest(
          composeSessionId: 'session-batch',
          customer: SalesComposeCustomerVm.walkIn(),
          currencyCode: 'VND',
          pricingContextVersion: 0,
          lines: [_line, _secondLine, _duplicateProductLine],
        ),
      );

      final resolveQueries = catalog.queries.whereType<ResolveSellableProductsQuery>().toList();
      expect(resolveQueries, hasLength(1));
      expect(resolveQueries.single.productIds, [
        _product.productId,
        _secondProduct.productId,
      ]);
    });

    test('Catalog outage blocks the save instead of blaming the product', () async {
      catalog.productsById[_product.productId] = _product;
      catalog.failure = StateError('catalog down');

      await expectLater(
        SalesDraftBackend.bindPersist(di)(
          SalesDraftPersistRequest(
            composeSessionId: 'session-catalog-down',
            customer: SalesComposeCustomerVm.walkIn(),
            currencyCode: 'VND',
            pricingContextVersion: 0,
            lines: [_line],
          ),
        ),
        throwsA(
          isA<SalesExternalOperationException>().having(
            (error) => error.toString(),
            'message',
            contains('Không kiểm tra được sản phẩm'),
          ),
        ),
      );
      expect(sales.commands, isEmpty);
    });

    test('product removed from the catalog reports a distinct message', () async {
      await expectLater(
        SalesDraftBackend.bindPersist(di)(
          SalesDraftPersistRequest(
            composeSessionId: 'session-missing-product',
            customer: SalesComposeCustomerVm.walkIn(),
            currencyCode: 'VND',
            pricingContextVersion: 0,
            lines: [_line],
          ),
        ),
        throwsA(
          isA<SalesExternalOperationException>().having(
            (error) => error.toString(),
            'message',
            contains('không còn tồn tại trong danh mục'),
          ),
        ),
      );
      expect(sales.commands, isEmpty);
    });

    test('update forwards current expectedVersion', () async {
      catalog.productsById[_product.productId] = _product;
      pricingModule.preview = _pricingPreview;

      await SalesDraftBackend.bindPersist(di)(
        SalesDraftPersistRequest(
          draftId: 'draft-9',
          expectedVersion: 4,
          composeSessionId: 'session-update',
          customer: SalesComposeCustomerVm.walkIn(),
          currencyCode: 'VND',
          pricingContextVersion: 1,
          lines: [_line],
        ),
      );

      expect(sales.commands.single, isA<UpdateSalesOrderDraftCommand>());
      final command = sales.commands.single as UpdateSalesOrderDraftCommand;
      expect(command.draftId, 'draft-9');
      expect(command.expectedVersion, 4);
      expect(command.idempotencyKey, startsWith('update:draft-9:'));
    });
  });

  group('SalesDraftBackend.restore', () {
    test('keeps saved snapshots while marking changed or inactive references', () async {
      sales.restoreDto = SalesOrderDraftForRestoreDto(
        draft: _savedDraft,
        savedAt: _savedDraft.savedAt,
        savedByActorId: _savedDraft.savedByActorId,
      );
      partnerDetail = _inactiveDetail;
      catalog.productsById[_product.productId] = _blockedProduct;
      pricingModule.preview = _pricingPreviewChanged;

      final result = await SalesDraftBackend.bindRestore(di)('draft-saved-1');

      expect(sales.queries.single, isA<GetSalesOrderDraftForRestoreQuery>());
      final query = sales.queries.single as GetSalesOrderDraftForRestoreQuery;
      expect(query.draftId, 'draft-saved-1');
      expect(query.storeId, 'store-1');
      expect(query.tenantId, 'tenant-1');
      expect(query.actorId, 'user-1');

      expect(result.draft.draftId, 'draft-saved-1');
      expect(result.customer.displayName, 'Saved Customer');
      expect(result.customer.partnerId, 'partner-1');
      expect(result.lines.single.identity.productName, 'Saved Product');
      expect(result.lines.single.pricing.appliedUnitPrice.amountMinor, 110000);
      expect(result.lines.single.pricing.blockingCodes, isNotEmpty);
      expect(result.orderNote, 'Saved note');

      final codes = result.issues.map((issue) => issue.code).toSet();
      expect(codes, contains(SalesDraftRestoreIssueCode.customerUnavailable));
      expect(codes, contains(SalesDraftRestoreIssueCode.productUnavailable));
      expect(codes, contains(SalesDraftRestoreIssueCode.pricingChanged));
      expect(
        result.issues
            .where(
              (issue) => issue.code == SalesDraftRestoreIssueCode.productUnavailable,
            )
            .single
            .lineId,
        'line-1',
      );
    });

    test('Catalog outage restores as retryable instead of unsellable', () async {
      sales.restoreDto = SalesOrderDraftForRestoreDto(
        draft: _savedDraft,
        savedAt: _savedDraft.savedAt,
        savedByActorId: _savedDraft.savedByActorId,
      );
      catalog.productsById[_product.productId] = _product;
      catalog.failure = StateError('catalog down');
      pricingModule.preview = _pricingPreview;

      final result = await SalesDraftBackend.bindRestore(di)('draft-saved-1');

      final codes = result.issues.map((issue) => issue.code).toSet();
      expect(codes, contains(SalesDraftRestoreIssueCode.catalogUnavailable));
      expect(codes, isNot(contains(SalesDraftRestoreIssueCode.productUnavailable)));
      expect(
        result.lines.single.pricing.blockingCodes,
        contains('CATALOG_UNAVAILABLE'),
      );
      expect(result.lines.single.pricing.appliedUnitPrice.amountMinor, 110000);
    });

    test('product removed from the catalog blocks with PRODUCT_NOT_FOUND', () async {
      sales.restoreDto = SalesOrderDraftForRestoreDto(
        draft: _savedDraft,
        savedAt: _savedDraft.savedAt,
        savedByActorId: _savedDraft.savedByActorId,
      );
      pricingModule.preview = _pricingPreview;

      final result = await SalesDraftBackend.bindRestore(di)('draft-saved-1');

      expect(
        result.lines.single.pricing.blockingCodes,
        contains('PRODUCT_NOT_FOUND'),
      );
      final issue = result.issues
          .where(
            (item) => item.code == SalesDraftRestoreIssueCode.productUnavailable,
          )
          .single;
      expect(issue.lineId, 'line-1');
      expect(issue.message, contains('không còn tồn tại trong danh mục'));
    });

    test('pricing unavailable adds explicit issue without wiping saved prices', () async {
      sales.restoreDto = SalesOrderDraftForRestoreDto(
        draft: _savedDraft,
        savedAt: _savedDraft.savedAt,
        savedByActorId: _savedDraft.savedByActorId,
      );
      catalog.productsById[_product.productId] = _product;
      pricingModule.failure = StateError('offline');

      final result = await SalesDraftBackend.bindRestore(di)('draft-saved-1');
      expect(
        result.issues.map((issue) => issue.code),
        contains(SalesDraftRestoreIssueCode.pricingUnavailable),
      );
      expect(result.lines.single.pricing.appliedUnitPrice.amountMinor, 110000);
    });
  });
}

const _money = MoneyDto(amountMinor: 120000, currencyCode: 'VND');

final _line = _composeLine(
  lineId: 'line-1',
  productId: '11111111-1111-1111-1111-111111111111',
  productUnitId: '22222222-2222-2222-2222-222222222222',
  productName: 'Thuoc A',
  unitLabel: 'Hop',
  quantity: 2,
  listUnitPrice: const MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
  floorUnitPrice: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
  stockQuantity: 12,
);

final _secondLine = _composeLine(
  lineId: 'line-2',
  productId: '33333333-3333-3333-3333-333333333333',
  productUnitId: '44444444-4444-4444-4444-444444444444',
  productName: 'Thuoc B',
  unitLabel: 'Vien',
  quantity: 1,
);

/// Second line on the same product — the batch must not ask for it twice.
final _duplicateProductLine = _composeLine(
  lineId: 'line-3',
  productId: '11111111-1111-1111-1111-111111111111',
  productUnitId: '22222222-2222-2222-2222-222222222222',
  productName: 'Thuoc A',
  unitLabel: 'Hop',
  quantity: 1,
);

SalesComposeLineVm _composeLine({
  required String lineId,
  required String productId,
  required String productUnitId,
  required String productName,
  required String unitLabel,
  required int quantity,
  MoneyDto baseUnitPrice = _money,
  MoneyDto appliedUnitPrice = _money,
  MoneyDto? listUnitPrice,
  MoneyDto? floorUnitPrice,
  int? stockQuantity,
}) {
  return SalesComposeLineVm.composed(
    identity: ComposeLineIdentity(
      lineId: lineId,
      productId: productId,
      productUnitId: productUnitId,
      productName: productName,
      unitLabel: unitLabel,
      catalogUnitPrice: baseUnitPrice,
    ),
    input: ComposeLineUserInput(quantity: quantity),
    pricing: ComposeLinePricingNotReady(
      provisionalAppliedUnitPrice: appliedUnitPrice,
      provisionalListUnitPrice: listUnitPrice,
      provisionalFloorUnitPrice: floorUnitPrice,
    ),
    stock: stockQuantity == null ? null : ComposeLineStockHint(availableQuantity: stockQuantity),
  );
}

const _unit = SellableProductUnitDto(
  productUnitId: '22222222-2222-2222-2222-222222222222',
  unitCode: 'HOP',
  unitName: 'Hop',
  barcode: '8930001',
  isDefault: true,
  isActive: true,
  isSellable: true,
  blockReason: null,
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
);

const _product = SellableProductDto(
  productId: '11111111-1111-1111-1111-111111111111',
  sku: 'SKU-001',
  displayName: 'Thuoc A',
  isSellable: true,
  blockReason: null,
  currencyCode: 'VND',
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
  units: [_unit],
);

const _secondUnit = SellableProductUnitDto(
  productUnitId: '44444444-4444-4444-4444-444444444444',
  unitCode: 'VIEN',
  unitName: 'Vien',
  barcode: '8930002',
  isDefault: true,
  isActive: true,
  isSellable: true,
  blockReason: null,
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
);

const _secondProduct = SellableProductDto(
  productId: '33333333-3333-3333-3333-333333333333',
  sku: 'SKU-002',
  displayName: 'Thuoc B',
  isSellable: true,
  blockReason: null,
  currencyCode: 'VND',
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 12000000,
  units: [_secondUnit],
);

final _blockedProduct = SellableProductDto(
  productId: _product.productId,
  sku: _product.sku,
  displayName: _product.displayName,
  isSellable: false,
  blockReason: 'INACTIVE',
  currencyCode: 'VND',
  listPriceMinor: 125000,
  floorPriceMinor: 100000,
  availableStockMicros: 0,
  units: const [_unit],
);

final _productMissingUnit = SellableProductDto(
  productId: _product.productId,
  sku: _product.sku,
  displayName: _product.displayName,
  isSellable: true,
  blockReason: null,
  currencyCode: 'VND',
  listPriceMinor: 125000,
  floorPriceMinor: null,
  availableStockMicros: null,
  units: const [],
);

final _pricingPreview = pricing.SalesWorkingStatePricingPreviewDto(
  contextVersion: 2,
  previewToken: 'preview-token-1',
  currencyCode: 'VND',
  lines: [
    pricing.SalesPricingLinePreviewDto(
      localLineId: 'line-1',
      appliedUnitPriceMinor: 120000,
      discountMinor: 0,
      lineTotalMinor: 240000,
      sourceCode: 'LIST',
      listPriceMinor: 125000,
      floorPriceMinor: 100000,
      warningCodes: const [],
      blockingCodes: const [],
    ),
  ],
);

final _pricingPreviewTwoLines = pricing.SalesWorkingStatePricingPreviewDto(
  contextVersion: 2,
  previewToken: 'preview-token-batch',
  currencyCode: 'VND',
  lines: [
    for (final localLineId in const ['line-1', 'line-2', 'line-3'])
      pricing.SalesPricingLinePreviewDto(
        localLineId: localLineId,
        appliedUnitPriceMinor: 120000,
        discountMinor: 0,
        lineTotalMinor: 120000,
        sourceCode: 'LIST',
        listPriceMinor: 125000,
        floorPriceMinor: 100000,
        warningCodes: const [],
        blockingCodes: const [],
      ),
  ],
);

final _pricingPreviewChanged = pricing.SalesWorkingStatePricingPreviewDto(
  contextVersion: 9,
  previewToken: 'preview-token-changed',
  currencyCode: 'VND',
  lines: [
    pricing.SalesPricingLinePreviewDto(
      localLineId: 'line-1',
      appliedUnitPriceMinor: 130000,
      discountMinor: 0,
      lineTotalMinor: 130000,
      sourceCode: 'LIST',
      listPriceMinor: 130000,
      floorPriceMinor: 100000,
      warningCodes: const [],
      blockingCodes: const [],
    ),
  ],
);

final _savedDraft = SalesOrderDraftDto(
  draftId: 'draft-saved-1',
  version: 2,
  status: SalesDraftStatus.active,
  storeId: 'store-1',
  savedAt: DateTime.utc(2026, 8, 11, 4),
  savedByActorId: 'user-1',
  customer: const CustomerSnapshotDto(
    customerId: 'partner-1',
    displayName: 'Saved Customer',
    phoneNumber: '0988000111',
  ),
  orderNote: 'Saved note',
  pricingPreviewToken: 'saved-token',
  needsRevalidation: false,
  lines: [
    SalesOrderDraftLineDto(
      lineId: 'line-1',
      productId: _product.productId,
      productSku: 'SKU-001',
      productName: 'Saved Product',
      productUnitId: _unit.productUnitId,
      unitCode: 'HOP',
      unitName: 'Hop',
      quantity: const QuantityDto(quantityMicros: 1000000),
      appliedUnitPrice: const MoneyDto(amountMinor: 110000, currencyCode: 'VND'),
      lineTotal: const MoneyDto(amountMinor: 110000, currencyCode: 'VND'),
      listUnitPrice: const MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
    ),
  ],
  total: const MoneyDto(amountMinor: 110000, currencyCode: 'VND'),
);

const _inactiveDetail = PartnerDetailDto(
  partnerId: 'partner-1',
  partnerType: PartnerType.person,
  status: PartnerStatus.inactive,
  displayName: 'Inactive Customer',
  roles: [PartnerRoleType.customer],
  availableActions: [],
  expectedVersion: 1,
);

const _activeDetail = PartnerDetailDto(
    partnerId: 'partner-1',
    partnerType: PartnerType.person,
    status: PartnerStatus.active,
    displayName: 'Backend Customer',
    roles: [PartnerRoleType.customer],
    availableActions: [],
    expectedVersion: 1,
    personProfile: PersonProfileDto(
      fullName: 'Backend Customer',
      phone: '0988123456',
    ),
  );

final class _RecordingCatalogModule implements ICatalogModule {
  final Map<String, SellableProductDto> productsById = {};
  final List<Object> queries = [];
  Object? failure;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    final error = failure;
    if (error != null) throw error;
    final raw = query as Object;
    if (raw is ResolveSellableProductsQuery) {
      return [
            for (final productId in raw.productIds) _resolve(productId),
          ]
          as TResult;
    }
    if (raw is SearchSellableProductsQuery) {
      final match = productsById[raw.keyword.trim()];
      return (match == null ? const <SellableProductDto>[] : [match]) as TResult;
    }
    if (raw is ListSellableProductUnitsQuery) {
      final match = productsById[raw.productId];
      return (match?.units ?? const <SellableProductUnitDto>[]) as TResult;
    }
    throw StateError('Unexpected catalog query $query');
  }

  SellableProductResolutionDto _resolve(String productId) {
    final product = productsById[productId];
    if (product == null) {
      return SellableProductResolutionDto(
        productId: productId,
        resolution: SellableProductResolution.notFound,
      );
    }
    if (!product.isSellable) {
      return SellableProductResolutionDto(
        productId: productId,
        resolution: SellableProductResolution.notSellable,
        notSellable: NotSellableProductDto(
          productId: productId,
          sku: product.sku,
          displayName: product.displayName,
          blockReason: product.blockReason,
        ),
      );
    }
    return SellableProductResolutionDto(
      productId: productId,
      resolution: SellableProductResolution.sellable,
      product: product,
    );
  }
}

final class _RecordingPricingModule implements pricing.IPricingModule {
  pricing.SalesWorkingStatePricingPreviewDto? preview;
  Object? failure;
  final List<Object> queries = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    final error = failure;
    if (error != null) throw error;
    final raw = query as Object;
    if (raw is pricing.PreviewSalesWorkingStatePricingQuery) {
      return preview as TResult;
    }
    throw StateError('Unexpected pricing query $query');
  }
}

final class _RecordingSalesModule implements ISalesModule {
  final List<Object> commands = [];
  final List<Object> queries = [];
  SalesOrderDraftForRestoreDto? restoreDto;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    final raw = command as Object;
    if (raw is SaveSalesOrderDraftCommand) {
      final save = raw;
      return SalesOrderDraftDto(
            draftId: 'draft-saved-1',
            version: 1,
            status: SalesDraftStatus.active,
            storeId: save.storeId,
            savedAt: DateTime.utc(2026, 8, 11, 5),
            savedByActorId: save.actorId,
            customer: save.customer,
            orderNote: save.orderNote,
            pricingPreviewToken: save.pricingPreviewToken,
            needsRevalidation: save.needsRevalidation,
            lines: [
              for (final line in save.lines)
                SalesOrderDraftLineDto(
                  lineId: 'line-persisted',
                  productId: line.productId,
                  productSku: line.productSku,
                  productName: line.productName,
                  productUnitId: line.productUnitId,
                  unitCode: line.unitCode,
                  unitName: line.unitName,
                  quantity: line.quantity,
                  appliedUnitPrice: line.appliedUnitPrice,
                  lineTotal: line.lineTotal,
                  listUnitPrice: line.listUnitPrice,
                  needsRevalidation: line.needsRevalidation,
                ),
            ],
            total: MoneyDto(
              amountMinor: save.lines.fold<int>(
                0,
                (sum, line) => sum + line.lineTotal.amountMinor,
              ),
              currencyCode: save.currencyCode,
            ),
          )
          as TResult;
    }
    if (raw is UpdateSalesOrderDraftCommand) {
      final update = raw;
      return SalesOrderDraftDto(
            draftId: update.draftId,
            version: update.expectedVersion + 1,
            status: SalesDraftStatus.active,
            storeId: update.storeId,
            savedAt: DateTime.utc(2026, 8, 11, 5),
            savedByActorId: update.actorId,
            customer: update.customer,
            orderNote: update.orderNote,
            pricingPreviewToken: update.pricingPreviewToken,
            needsRevalidation: update.needsRevalidation,
            lines: const [],
            total: MoneyDto(amountMinor: 0, currencyCode: update.currencyCode),
          )
          as TResult;
    }
    throw StateError('Unexpected sales command $command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    final raw = query as Object;
    if (raw is GetSalesOrderDraftForRestoreQuery) {
      return restoreDto as TResult;
    }
    throw StateError('Unexpected sales query $query');
  }
}

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}


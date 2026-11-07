import '../../iam/support/iam_test_session.dart';
import 'package:erp/core/session/session_controller.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import '../../partner/support/scripted_partner_repository.dart';
import '../support/fake_sales_draft_repository.dart';
import '../support/recording_sales_pricing_repository.dart';
import 'package:erp/features/pricing/data/models.dart' as pricing;
import 'package:erp/features/pricing/data/sales_pricing_repository.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation.dart';

import 'package:erp/features/sales/presentation/lookups/sales_partner_customer_lookup.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'package:erp/features/sales/logic/sales_draft_backend.dart';
import 'package:erp/features/sales/presentation/orchestration/sales_draft_payload_fingerprint.dart';

void main() {
  late GetIt di;
  late ScriptedPartnerRepository partner;
  late PartnerDetailDto partnerDetail;
  late _RecordingProductRepository catalog;
  late RecordingSalesPricingRepository pricingRepo;
  late FakeSalesDraftRepository sales;

  setUp(() {
    di = GetIt.asNewInstance();
    partnerDetail = _activeDetail;
    partner = ScriptedPartnerRepository(
      onCall: (method, _) {
        if (method == 'getDetail') return partnerDetail;
        throw StateError('Unexpected partner call $method');
      },
    );
    catalog = _RecordingProductRepository();
    pricingRepo = RecordingSalesPricingRepository();
    sales = FakeSalesDraftRepository();
    di
      ..registerSingleton<PartnerRepository>(partner)
      ..registerSingleton<ProductRepository>(catalog)
      ..registerSingleton<SalesPricingRepository>(pricingRepo)
      ..registerSingleton<SalesDraftRepository>(sales)
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
      pricingRepo.previewResponder =
          ({
            required storeId,
            customerId,
            required currencyCode,
            required contextVersion,
            required effectiveAt,
            required lines,
          }) => _pricingPreview;

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
        catalog.queries.whereType<_ResolveSellableProductsCall>(),
        hasLength(1),
      );
      expect(
        pricingRepo.previewCalls,
        hasLength(1),
      );
      expect(sales.saveCalls, hasLength(1));
      final command = sales.saveCalls.single;
      expect(command.storeId, 'store-1');
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
      pricingRepo.previewResponder =
          ({
            required storeId,
            customerId,
            required currencyCode,
            required contextVersion,
            required effectiveAt,
            required lines,
          }) => _pricingPreview;

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
      final command = sales.saveCalls.single;
      expect(command.customer, isNull);
    });

    test('pricing failure still saves with needsRevalidation=true', () async {
      catalog.productsById[_product.productId] = _product;
      pricingRepo.previewResponder =
          ({
            required storeId,
            customerId,
            required currencyCode,
            required contextVersion,
            required effectiveAt,
            required lines,
          }) => throw StateError('pricing down');

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

      final command = sales.saveCalls.single;
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
      expect(sales.saveCalls.length + sales.updateCalls.length, 0);
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
      expect(sales.saveCalls.length + sales.updateCalls.length, 0);

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
      expect(sales.saveCalls.length + sales.updateCalls.length, 0);
    });

    test('resolves every line with one Catalog call', () async {
      catalog.productsById[_product.productId] = _product;
      catalog.productsById[_secondProduct.productId] = _secondProduct;
      pricingRepo.previewResponder =
          ({
            required storeId,
            customerId,
            required currencyCode,
            required contextVersion,
            required effectiveAt,
            required lines,
          }) => _pricingPreviewTwoLines;

      await SalesDraftBackend.bindPersist(di)(
        SalesDraftPersistRequest(
          composeSessionId: 'session-batch',
          customer: SalesComposeCustomerVm.walkIn(),
          currencyCode: 'VND',
          pricingContextVersion: 0,
          lines: [_line, _secondLine, _duplicateProductLine],
        ),
      );

      final resolveQueries = catalog.queries.whereType<_ResolveSellableProductsCall>().toList();
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
      expect(sales.saveCalls.length + sales.updateCalls.length, 0);
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
      expect(sales.saveCalls.length + sales.updateCalls.length, 0);
    });

    test('update forwards current expectedVersion', () async {
      catalog.productsById[_product.productId] = _product;
      pricingRepo.previewResponder =
          ({
            required storeId,
            customerId,
            required currencyCode,
            required contextVersion,
            required effectiveAt,
            required lines,
          }) => _pricingPreview;

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

      expect(sales.updateCalls, hasLength(1));
      final command = sales.updateCalls.single;
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
      pricingRepo.previewResponder =
          ({
            required storeId,
            customerId,
            required currencyCode,
            required contextVersion,
            required effectiveAt,
            required lines,
          }) => _pricingPreviewChanged;

      final result = await SalesDraftBackend.bindRestore(di)('draft-saved-1');

      expect(sales.restoreCalls, hasLength(1));
      final query = sales.restoreCalls.single;
      expect(query.draftId, 'draft-saved-1');
      expect(query.storeId, 'store-1');

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
      pricingRepo.previewResponder =
          ({
            required storeId,
            customerId,
            required currencyCode,
            required contextVersion,
            required effectiveAt,
            required lines,
          }) => _pricingPreview;

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
      pricingRepo.previewResponder =
          ({
            required storeId,
            customerId,
            required currencyCode,
            required contextVersion,
            required effectiveAt,
            required lines,
          }) => _pricingPreview;

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
      pricingRepo.previewResponder =
          ({
            required storeId,
            customerId,
            required currencyCode,
            required contextVersion,
            required effectiveAt,
            required lines,
          }) => throw StateError('offline');

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

final class _ResolveSellableProductsCall {
  final String storeId;
  final List<String> productIds;
  const _ResolveSellableProductsCall({
    required this.storeId,
    required this.productIds,
  });
}

final class _RecordingProductRepository implements ProductRepository {
  final Map<String, SellableProductDto> productsById = {};
  final List<Object> queries = [];
  Object? failure;

  @override
  Future<List<SellableProductResolutionDto>> resolveSellable({
    required String storeId,
    required List<String> productIds,
  }) async {
    queries.add(_ResolveSellableProductsCall(storeId: storeId, productIds: productIds));
    final error = failure;
    if (error != null) throw error;
    return [
      for (final productId in productIds) _resolve(productId),
    ];
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

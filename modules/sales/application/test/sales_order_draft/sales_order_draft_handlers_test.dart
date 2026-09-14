import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _AllowAllPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {}
}

SalesOrderDraftLineInput _fullLineInput({
  int appliedMinor = 120000,
  int? manualDiscountMinor = 5000,
  bool needsRevalidation = false,
  String currencyCode = 'VND',
}) {
  return SalesOrderDraftLineInput(
    productId: 'product-1',
    productSku: 'SKU-1',
    productName: 'Thuoc A',
    productUnitId: 'unit-1',
    unitCode: 'BOX',
    unitName: 'Hop',
    quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
    appliedUnitPrice: MoneyDto(
      amountMinor: appliedMinor,
      currencyCode: currencyCode,
    ),
    lineTotal: MoneyDto(
      amountMinor: appliedMinor - (manualDiscountMinor ?? 0),
      currencyCode: currencyCode,
    ),
    listUnitPrice: MoneyDto(amountMinor: 130000, currencyCode: currencyCode),
    manualDiscountMinor: manualDiscountMinor,
    pricingSourceCode: 'list',
    pricingWarningCodes: const ['PRICE_STALE'],
    note: 'Line note',
    needsRevalidation: needsRevalidation,
  );
}

SalesOrderDraftLineDto _fullLineDto() {
  return SalesOrderDraftLineDto(
    lineId: 'line-1',
    productId: 'product-1',
    productSku: 'SKU-1',
    productName: 'Thuoc A',
    productUnitId: 'unit-1',
    unitCode: 'BOX',
    unitName: 'Hop',
    quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
    appliedUnitPrice: const MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
    lineTotal: const MoneyDto(amountMinor: 115000, currencyCode: 'VND'),
    listUnitPrice: const MoneyDto(amountMinor: 130000, currencyCode: 'VND'),
    manualDiscountMinor: 5000,
    pricingSourceCode: 'list',
    pricingWarningCodes: const ['PRICE_STALE'],
    note: 'Line note',
  );
}

CustomerSnapshotDto _customer() {
  return const CustomerSnapshotDto(
    customerId: 'customer-1',
    displayName: 'Nguyen Van A',
    phoneNumber: '0901234567',
    existingDebtMinor: 0,
  );
}

void main() {
  final savedAt = DateTime.utc(2026, 8, 6, 1);

  SalesOrderDraftDto draftDto({
    String draftId = 'draft-1',
    int version = 1,
    SalesDraftStatus status = SalesDraftStatus.active,
  }) {
    return SalesOrderDraftDto(
      draftId: draftId,
      version: version,
      status: status,
      storeId: 'store-1',
      customer: _customer(),
      orderNote: 'Giao buoi chieu',
      savedAt: savedAt,
      savedByActorId: 'actor-1',
      pricingPreviewToken: 'preview-token-1',
      needsRevalidation: false,
      lines: [_fullLineDto()],
      total: const MoneyDto(amountMinor: 115000, currencyCode: 'VND'),
    );
  }

  group('SalesOrderDraft lossless snapshot contract', () {
    test('save command preserves full snapshot through withExecutionContext', () {
      final command = SaveSalesOrderDraftCommand(
        storeId: 'store-1',
        customer: _customer(),
        currencyCode: 'VND',
        orderNote: 'Giao buoi chieu',
        pricingPreviewToken: 'preview-token-1',
        needsRevalidation: false,
        lines: [_fullLineInput()],
        idempotencyKey: 'idem-1',
        payloadHash: 'hash-1',
      ).withExecutionContext(tenantId: 'tenant-1', actorId: 'actor-1');

      expect(command.storeId, 'store-1');
      expect(command.customer?.displayName, 'Nguyen Van A');
      expect(command.orderNote, 'Giao buoi chieu');
      expect(command.pricingPreviewToken, 'preview-token-1');
      expect(command.needsRevalidation, isFalse);
      expect(command.lines.single.manualDiscountMinor, 5000);
      expect(command.lines.single.appliedUnitPrice.amountMinor, 120000);
      expect(command.lines.single.listUnitPrice?.amountMinor, 130000);
      expect(command.lines.single.pricingSourceCode, 'list');
      expect(command.lines.single.pricingWarningCodes, ['PRICE_STALE']);
      expect(command.lines.single.needsRevalidation, isFalse);
      expect(command.tenantId, 'tenant-1');
      expect(command.actorId, 'actor-1');
    });

    test('draft dto and restore wrapper keep matching saved metadata', () {
      final draft = draftDto();
      final restore = SalesOrderDraftForRestoreDto(
        draft: draft,
        savedAt: draft.savedAt,
        savedByActorId: draft.savedByActorId,
      );

      expect(draft.storeId, 'store-1');
      expect(draft.customer?.displayName, 'Nguyen Van A');
      expect(draft.orderNote, 'Giao buoi chieu');
      expect(draft.pricingPreviewToken, 'preview-token-1');
      expect(draft.needsRevalidation, isFalse);
      expect(draft.lines.single, isA<SalesOrderDraftLineDto>());
      expect(draft.lines.single.manualDiscountMinor, 5000);
      expect(draft.lines.single.appliedUnitPrice.amountMinor, 120000);
      expect(restore.savedAt, draft.savedAt);
      expect(restore.savedByActorId, draft.savedByActorId);
    });

    test('update/cancel/list/restore require storeId in compile-time fixtures', () {
      final update = UpdateSalesOrderDraftCommand(
        draftId: 'draft-1',
        storeId: 'store-1',
        customer: _customer(),
        currencyCode: 'VND',
        orderNote: 'Giao buoi chieu',
        pricingPreviewToken: 'preview-token-1',
        needsRevalidation: false,
        lines: [_fullLineInput()],
        expectedVersion: 1,
        idempotencyKey: 'idem-2',
        payloadHash: 'hash-2',
      );
      final cancel = CancelSalesOrderDraftCommand(
        draftId: 'draft-1',
        storeId: 'store-1',
        idempotencyKey: 'idem-3',
        expectedVersion: 2,
      );
      final list = ListSalesOrderDraftsQuery(storeId: 'store-1');
      final restore = GetSalesOrderDraftForRestoreQuery(
        draftId: 'draft-1',
        storeId: 'store-1',
      );

      expect(update.storeId, 'store-1');
      expect(cancel.storeId, 'store-1');
      expect(list.storeId, 'store-1');
      expect(restore.storeId, 'store-1');
    });
  });

  group('SalesOrderDraftContractMapper', () {
    SalesOrderDraftLineReadRow lineRow({
      bool needsRevalidation = false,
      int lineTotalMinor = 115000,
      int? manualDiscountMinor = 5000,
      String currencyCode = 'VND',
    }) {
      return SalesOrderDraftLineReadRow(
        lineId: 'line-1',
        productId: 'product-1',
        productSku: 'SKU-1',
        productName: 'Thuoc A',
        productUnitId: 'unit-1',
        unitCode: 'BOX',
        unitName: 'Hop',
        quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
        appliedUnitPrice: MoneyDto(
          amountMinor: 120000,
          currencyCode: currencyCode,
        ),
        lineTotal: MoneyDto(
          amountMinor: lineTotalMinor,
          currencyCode: currencyCode,
        ),
        listUnitPrice: MoneyDto(amountMinor: 130000, currencyCode: currencyCode),
        manualDiscountMinor: manualDiscountMinor,
        pricingSourceCode: 'list',
        pricingWarningCodes: const ['PRICE_STALE'],
        note: 'Line note',
        needsRevalidation: needsRevalidation,
      );
    }

    test('maps read row to active draft dto with summed total', () {
      final row = SalesOrderDraftReadRow(
        draftId: 'draft-1',
        version: 1,
        status: SalesDraftStatus.active,
        storeId: 'store-1',
        currencyCode: 'VND',
        savedAt: savedAt,
        savedByActorId: 'actor-1',
        orderNote: 'Giao buoi chieu',
        pricingPreviewToken: 'preview-token-1',
        needsRevalidation: false,
        customer: _customer(),
        lines: [lineRow()],
      );

      final dto = SalesOrderDraftContractMapper.toDraftDto(row);

      expect(dto.draftId, 'draft-1');
      expect(dto.version, 1);
      expect(dto.status, SalesDraftStatus.active);
      expect(dto.storeId, 'store-1');
      expect(dto.customer?.displayName, 'Nguyen Van A');
      expect(dto.customer?.existingDebtMinor, 0);
      expect(dto.orderNote, 'Giao buoi chieu');
      expect(dto.lines.single.productId, 'product-1');
      expect(dto.lines.single.appliedUnitPrice.amountMinor, 120000);
      expect(dto.total.amountMinor, 115000);
      expect(dto.savedAt, savedAt);
      expect(dto.savedByActorId, 'actor-1');
    });

    test('full round-trip preserves named customer and pricing snapshot', () {
      final mappedSavedAt = DateTime.utc(2026, 8, 11, 2);
      final row = SalesOrderDraftReadRow(
        draftId: 'draft-1',
        version: 2,
        status: SalesDraftStatus.active,
        storeId: 'store-1',
        currencyCode: 'VND',
        savedAt: mappedSavedAt,
        savedByActorId: 'actor-1',
        orderNote: 'Giao buoi chieu',
        pricingPreviewToken: 'preview-token-1',
        needsRevalidation: true,
        customer: const CustomerSnapshotDto(
          customerId: 'customer-1',
          displayName: 'Nguyen Van A',
          phoneNumber: '0901234567',
          existingDebtMinor: 50000,
        ),
        lines: [lineRow(needsRevalidation: true)],
      );

      final dto = SalesOrderDraftContractMapper.toDraftDto(row);
      final restore = SalesOrderDraftContractMapper.toRestoreDto(row);

      expect(dto.customer?.customerId, 'customer-1');
      expect(dto.customer?.existingDebtMinor, 0);
      expect(dto.lines.single.productName, 'Thuoc A');
      expect(dto.lines.single.appliedUnitPrice.amountMinor, 120000);
      expect(dto.lines.single.pricingWarningCodes, ['PRICE_STALE']);
      expect(dto.lines.single.needsRevalidation, isTrue);
      expect(dto.needsRevalidation, isTrue);
      expect(dto.savedAt, DateTime.utc(2026, 8, 11, 2));
      expect(restore.draft.savedAt, dto.savedAt);
      expect(restore.savedByActorId, 'actor-1');
    });

    test('maps walk-in customer as null and blank order note as null', () {
      final row = SalesOrderDraftReadRow(
        draftId: 'draft-2',
        version: 1,
        status: SalesDraftStatus.active,
        storeId: 'store-1',
        currencyCode: 'VND',
        savedAt: DateTime.utc(2026, 8, 11, 2),
        savedByActorId: 'actor-1',
        orderNote: '   ',
        customer: null,
        lines: [
          lineRow(manualDiscountMinor: null, lineTotalMinor: 120000),
        ],
      );

      final dto = SalesOrderDraftContractMapper.toDraftDto(row);

      expect(dto.customer, isNull);
      expect(dto.orderNote, isNull);
      expect(dto.lines.single.productName, 'Thuoc A');
      expect(dto.lines.single.appliedUnitPrice.amountMinor, 120000);
      expect(dto.savedAt, DateTime.utc(2026, 8, 11, 2));
    });

    test('maps legacy cust-walk-in snapshot to null walk-in', () {
      final row = SalesOrderDraftReadRow(
        draftId: 'draft-3',
        version: 1,
        status: SalesDraftStatus.active,
        storeId: 'store-1',
        currencyCode: 'VND',
        savedAt: DateTime.utc(2026, 8, 11, 2),
        savedByActorId: 'actor-1',
        customer: const CustomerSnapshotDto(
          customerId: 'cust-walk-in',
          displayName: 'Khach le',
        ),
        lines: [
          lineRow(manualDiscountMinor: null, lineTotalMinor: 120000),
        ],
      );

      final dto = SalesOrderDraftContractMapper.toDraftDto(row);

      expect(dto.customer, isNull);
    });
  });

  group('SalesOrderDraft handlers and validators', () {
    Matcher throwsContextInvalid() => throwsA(
      isA<SalesContractException>().having(
        (error) => error.code,
        'code',
        'CONTEXT_INVALID',
      ),
    );

    test('save validator rejects empty drafts before gateway call', () {
      final validator = SaveSalesOrderDraftCommandValidator();
      final command = SaveSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: const [],
        idempotencyKey: 'idem-1',
      );

      expect(() => validator.validate(command), throwsContextInvalid());
    });

    test('save validator rejects non-positive quantity', () async {
      final validator = SaveSalesOrderDraftCommandValidator();
      final command = SaveSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: [
          SalesOrderDraftLineInput(
            productId: 'product-1',
            productSku: 'SKU-1',
            productName: 'Thuoc A',
            productUnitId: 'unit-1',
            unitCode: 'BOX',
            unitName: 'Hop',
            quantity: const QuantityDto(quantityMicros: 0),
            appliedUnitPrice: const MoneyDto(
              amountMinor: 120000,
              currencyCode: 'VND',
            ),
            lineTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          ),
        ],
        idempotencyKey: 'idem-qty',
      );

      expect(() => validator.validate(command), throwsContextInvalid());
    });

    test('save validator rejects mismatched line currency', () async {
      final validator = SaveSalesOrderDraftCommandValidator();
      final command = SaveSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: [_fullLineInput(currencyCode: 'USD')],
        idempotencyKey: 'idem-currency',
      );

      expect(() => validator.validate(command), throwsContextInvalid());
    });

    test('save validator rejects two simultaneous manual discount modes', () async {
      final validator = SaveSalesOrderDraftCommandValidator();
      final command = SaveSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: [
          SalesOrderDraftLineInput(
            productId: 'product-1',
            productSku: 'SKU-1',
            productName: 'Thuoc A',
            productUnitId: 'unit-1',
            unitCode: 'BOX',
            unitName: 'Hop',
            quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
            appliedUnitPrice: const MoneyDto(
              amountMinor: 120000,
              currencyCode: 'VND',
            ),
            lineTotal: const MoneyDto(amountMinor: 110000, currencyCode: 'VND'),
            manualDiscountMinor: 5000,
            manualDiscountBasisPoints: 1000,
          ),
        ],
        idempotencyKey: 'idem-manual',
      );

      expect(() => validator.validate(command), throwsContextInvalid());
    });

    test('save validator rejects incorrect undiscounted lineTotal', () async {
      final validator = SaveSalesOrderDraftCommandValidator();
      final command = SaveSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: [
          SalesOrderDraftLineInput(
            productId: 'product-1',
            productSku: 'SKU-1',
            productName: 'Thuoc A',
            productUnitId: 'unit-1',
            unitCode: 'BOX',
            unitName: 'Hop',
            quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
            appliedUnitPrice: const MoneyDto(
              amountMinor: 120000,
              currencyCode: 'VND',
            ),
            lineTotal: const MoneyDto(amountMinor: 99999, currencyCode: 'VND'),
          ),
        ],
        idempotencyKey: 'idem-total',
      );

      expect(() => validator.validate(command), throwsContextInvalid());
    });

    test('save validator rejects cust-walk-in customer id', () async {
      final validator = SaveSalesOrderDraftCommandValidator();
      final command = SaveSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        customer: const CustomerSnapshotDto(
          customerId: 'cust-walk-in',
          displayName: 'Khach le',
        ),
        currencyCode: 'VND',
        lines: [_fullLineInput()],
        idempotencyKey: 'idem-walkin',
      );

      expect(() => validator.validate(command), throwsContextInvalid());
    });

    test('save validator accepts discounted lineTotal from pricing', () async {
      final validator = SaveSalesOrderDraftCommandValidator();
      final command = SaveSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        customer: _customer(),
        currencyCode: 'VND',
        lines: [_fullLineInput()],
        idempotencyKey: 'idem-ok',
      );

      await validator.validate(command);
    });

    test('update validator rejects empty display snapshot fields', () async {
      final validator = UpdateSalesOrderDraftCommandValidator();
      final command = UpdateSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        draftId: 'draft-1',
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: [
          SalesOrderDraftLineInput(
            productId: 'product-1',
            productSku: '',
            productName: 'Thuoc A',
            productUnitId: 'unit-1',
            unitCode: 'BOX',
            unitName: 'Hop',
            quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
            appliedUnitPrice: const MoneyDto(
              amountMinor: 120000,
              currencyCode: 'VND',
            ),
            lineTotal: const MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
          ),
        ],
        idempotencyKey: 'idem-snap',
        expectedVersion: 1,
      );

      expect(() => validator.validate(command), throwsContextInvalid());
    });

    test('update validator rejects out-of-range basis points', () async {
      final validator = UpdateSalesOrderDraftCommandValidator();
      final command = UpdateSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        draftId: 'draft-1',
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: [
          SalesOrderDraftLineInput(
            productId: 'product-1',
            productSku: 'SKU-1',
            productName: 'Thuoc A',
            productUnitId: 'unit-1',
            unitCode: 'BOX',
            unitName: 'Hop',
            quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
            appliedUnitPrice: const MoneyDto(
              amountMinor: 120000,
              currencyCode: 'VND',
            ),
            lineTotal: const MoneyDto(amountMinor: 108000, currencyCode: 'VND'),
            manualDiscountBasisPoints: 10001,
          ),
        ],
        idempotencyKey: 'idem-bps',
        expectedVersion: 1,
      );

      expect(() => validator.validate(command), throwsContextInvalid());
    });

    test('save handler delegates to draft gateway', () async {
      final gateway = _RecordingDraftGateway(saveResult: draftDto());
      final handler = SaveSalesOrderDraftCommandHandler(gateway: gateway);
      final command = SaveSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        customer: _customer(),
        currencyCode: 'VND',
        orderNote: 'Giao buoi chieu',
        pricingPreviewToken: 'preview-token-1',
        lines: [_fullLineInput()],
        idempotencyKey: 'idem-1',
      );

      final result = await handler.handle(command);

      expect(result.draftId, 'draft-1');
      expect(gateway.savedCommand, same(command));
    });

    test('update validator requires positive expected version', () {
      final validator = UpdateSalesOrderDraftCommandValidator();
      final command = UpdateSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        draftId: 'draft-1',
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: [_fullLineInput()],
        idempotencyKey: 'idem-2',
        expectedVersion: 0,
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('mutation and read handlers delegate to draft gateway', () async {
      final gateway = _RecordingDraftGateway(
        updateResult: draftDto(version: 2),
        cancelResult: draftDto(version: 3, status: SalesDraftStatus.cancelled),
        restoreResult: SalesOrderDraftForRestoreDto(
          draft: draftDto(),
          savedAt: savedAt,
          savedByActorId: 'actor-1',
        ),
        listResult: PagedSalesOrderDraftListDto(
          page: OpaqueCursorPageDto<SalesOrderDraftDto>(
            items: [draftDto()],
            hasMore: false,
          ),
        ),
      );

      final updateCommand = UpdateSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        draftId: 'draft-1',
        storeId: 'store-1',
        customer: _customer(),
        currencyCode: 'VND',
        orderNote: 'Giao buoi chieu',
        pricingPreviewToken: 'preview-token-1',
        lines: [_fullLineInput()],
        idempotencyKey: 'idem-2',
        expectedVersion: 1,
      );
      final cancelCommand = CancelSalesOrderDraftCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        draftId: 'draft-1',
        storeId: 'store-1',
        idempotencyKey: 'idem-3',
        expectedVersion: 2,
      );
      final restoreQuery = GetSalesOrderDraftForRestoreQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        draftId: 'draft-1',
        storeId: 'store-1',
      );
      final listQuery = ListSalesOrderDraftsQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
      );

      expect(
        (await UpdateSalesOrderDraftCommandHandler(gateway: gateway).handle(
          updateCommand,
        )).version,
        2,
      );
      expect(
        (await CancelSalesOrderDraftCommandHandler(gateway: gateway).handle(
          cancelCommand,
        )).status,
        SalesDraftStatus.cancelled,
      );
      expect(
        (await GetSalesOrderDraftForRestoreQueryHandler(
          gateway: gateway,
          permissionChecker: _AllowAllPermissionChecker(),
        ).handle(restoreQuery)).savedByActorId,
        'actor-1',
      );
      expect(
        (await ListSalesOrderDraftsQueryHandler(
          gateway: gateway,
          permissionChecker: _AllowAllPermissionChecker(),
        ).handle(listQuery)).page.items,
        hasLength(1),
      );
      expect(gateway.updatedCommand, same(updateCommand));
      expect(gateway.cancelledCommand, same(cancelCommand));
      expect(gateway.restoreQuery, same(restoreQuery));
      expect(gateway.listQuery, same(listQuery));
    });
  });
}

final class _RecordingDraftGateway implements ISalesOrderDraftGateway {
  _RecordingDraftGateway({
    SalesOrderDraftDto? saveResult,
    SalesOrderDraftDto? updateResult,
    SalesOrderDraftDto? cancelResult,
    SalesOrderDraftForRestoreDto? restoreResult,
    PagedSalesOrderDraftListDto? listResult,
  }) : _saveResult = saveResult,
       _updateResult = updateResult,
       _cancelResult = cancelResult,
       _restoreResult = restoreResult,
       _listResult = listResult;

  final SalesOrderDraftDto? _saveResult;
  final SalesOrderDraftDto? _updateResult;
  final SalesOrderDraftDto? _cancelResult;
  final SalesOrderDraftForRestoreDto? _restoreResult;
  final PagedSalesOrderDraftListDto? _listResult;

  SaveSalesOrderDraftCommand? savedCommand;
  UpdateSalesOrderDraftCommand? updatedCommand;
  CancelSalesOrderDraftCommand? cancelledCommand;
  GetSalesOrderDraftForRestoreQuery? restoreQuery;
  ListSalesOrderDraftsQuery? listQuery;

  @override
  Future<SalesOrderDraftDto> save(SaveSalesOrderDraftCommand command) async {
    savedCommand = command;
    return _saveResult!;
  }

  @override
  Future<SalesOrderDraftDto> update(UpdateSalesOrderDraftCommand command) async {
    updatedCommand = command;
    return _updateResult!;
  }

  @override
  Future<SalesOrderDraftDto> cancel(CancelSalesOrderDraftCommand command) async {
    cancelledCommand = command;
    return _cancelResult!;
  }

  @override
  Future<SalesOrderDraftForRestoreDto> getForRestore(
    GetSalesOrderDraftForRestoreQuery query,
  ) async {
    restoreQuery = query;
    return _restoreResult!;
  }

  @override
  Future<PagedSalesOrderDraftListDto> list(ListSalesOrderDraftsQuery query) async {
    listQuery = query;
    return _listResult!;
  }
}

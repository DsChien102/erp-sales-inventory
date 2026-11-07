import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart' hide SalesOrderLifecycleStatus;
import 'package:vet45_shared_application/application.dart';

import '../../support/fake_return_exchange_repository.dart';
import '../../support/module_backed_sales_repositories.dart';

void main() {
  SalesReturnExchangeSessionCubit build(
    _RecordingSalesModule module, {
    List<String> attemptIds = const ['attempt-1', 'attempt-2', 'attempt-3'],
  }) {
    final ids = attemptIds.iterator;
    return SalesReturnExchangeSessionCubit(
      orderId: 'order-1',
      returnExchangeRepository: ModuleBackedReturnExchangeRepository(module),
      orderRepository: ModuleBackedSalesOrderRepository(module),
      executionContext: const _ExecutionContext(),
      attemptFactory: SalesReturnExchangeAttemptFactory(
        newAttemptId: () {
          ids.moveNext();
          return ids.current;
        },
      ),
    );
  }

  Future<void> prepareReady(SalesReturnExchangeSessionCubit cubit) async {
    await cubit.load();
    cubit.setReturnQuantity('line-1', QuantityDto.scale);
  }

  test('load resolves context and authoritative order/policy/returnable data', () async {
    final module = _RecordingSalesModule();
    final cubit = build(module);
    addTearDown(cubit.close);

    await cubit.load();

    expect(module.queries.whereType<GetSalesOrderDetailQuery>(), hasLength(1));
    expect(module.queries.whereType<PrecheckReturnExchangeQuery>(), hasLength(1));
    expect(module.queries.whereType<GetReturnableOrderLinesQuery>(), hasLength(1));
    expect(
      module.queries.whereType<GetReturnExchangeFormPolicyQuery>(),
      isEmpty,
    );
    expect(cubit.state.status, SalesReturnExchangeSessionStatus.ready);
    expect(cubit.state.orderNumber, 'SO-2026-00125');
    expect(cubit.state.customerDisplayName, 'Khách A');
    expect(cubit.state.sourceOrderVersion, 7);
    expect(cubit.state.returnableLines, hasLength(1));
    expect(cubit.state.canProceed, isFalse);
  });

  test('session_never_emits_catalog_empty', () async {
    final module = _RecordingSalesModule();
    final cubit = build(module);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, SalesReturnExchangeSessionStatus.ready);
  });

  test('walk-in order without customer snapshot loads as Khách lẻ', () async {
    final cubit = build(_RecordingSalesModule(detail: _detail(walkIn: true)));
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, SalesReturnExchangeSessionStatus.ready);
    expect(cubit.state.customerDisplayName, 'Khách lẻ');
    expect(cubit.state.returnableLines, hasLength(1));
  });

  test('hides units already fully returned (returnable quantity 0)', () async {
    final cubit = build(
      _RecordingSalesModule(
        returnable: ReturnableOrderLinesDto(
          salesOrderId: 'order-1',
          sourceVersion: 7,
          lines: const [
            ReturnableOrderLineDto(
              salesOrderLineId: 'line-open',
              product: ProductSnapshotDto(
                productId: 'p-open',
                sku: 'SKU-OPEN',
                displayName: 'Còn trả được',
              ),
              unit: ProductUnitSnapshotDto(
                productUnitId: 'u-open',
                unitCode: 'BOX',
                unitName: 'Hộp',
              ),
              soldQuantity: QuantityDto(quantityMicros: QuantityDto.scale),
              returnableQuantity: QuantityDto(quantityMicros: QuantityDto.scale),
              originalUnitPrice: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
            ),
            ReturnableOrderLineDto(
              salesOrderLineId: 'line-exhausted',
              product: ProductSnapshotDto(
                productId: 'p-done',
                sku: 'SKU-DONE',
                displayName: 'Đã trả hết',
              ),
              unit: ProductUnitSnapshotDto(
                productUnitId: 'u-done',
                unitCode: 'BOX',
                unitName: 'Hộp',
              ),
              soldQuantity: QuantityDto(quantityMicros: QuantityDto.scale),
              returnableQuantity: QuantityDto(quantityMicros: 0),
              originalUnitPrice: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
            ),
          ],
        ),
      ),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.returnableLines, hasLength(1));
    expect(cubit.state.returnableLines.single.unitId, 'line-open');
  });

  test('blocked precheck disables proceed, empty policy still opens item selection', () async {
    final blocked = build(
      _RecordingSalesModule(
        precheck: ReturnExchangePrecheckDto(
          allowed: false,
          sourceVersion: 7,
          blockers: const [
            SalesBlockerDto(code: 'WINDOW_EXPIRED', message: 'Hết hạn đổi/trả.'),
          ],
        ),
      ),
    );
    addTearDown(blocked.close);
    await blocked.load();
    expect(blocked.state.status, SalesReturnExchangeSessionStatus.blocked);
    expect(blocked.state.canProceed, isFalse);

    final empty = build(
      _RecordingSalesModule(
        policy: ReturnExchangeFormPolicyDto(reasons: const [], conditions: const []),
      ),
    );
    addTearDown(empty.close);
    await empty.load();
    expect(empty.state.status, SalesReturnExchangeSessionStatus.ready);
    expect(empty.state.returnableLines, hasLength(1));
    expect(empty.state.canProceed, isFalse);
  });

  test('quantity clamps to backend micros and zero removes selected return line', () async {
    final cubit = build(_RecordingSalesModule());
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setReturnQuantity('line-1', QuantityDto.scale * 9);
    expect(cubit.state.returnEdits.single.quantityMicros, QuantityDto.scale * 2);
    expect(cubit.state.canProceed, isTrue);

    cubit.setReturnQuantity('line-1', 0);
    expect(cubit.state.returnEdits, isEmpty);
    expect(cubit.state.canProceed, isFalse);
  });

  test('returned line can proceed without temporary reason and condition policy', () async {
    final cubit = build(_RecordingSalesModule());
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setReturnQuantity('line-1', QuantityDto.scale);
    expect(cubit.state.canProceed, isTrue);
  });

  test('save without reason/condition sends start and reaches settlement handoff', () async {
    final module = _RecordingSalesModule(
      policy: ReturnExchangeFormPolicyDto(reasons: const [], conditions: const []),
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setReturnQuantity('line-1', QuantityDto.scale);
    final id = await cubit.saveAndGetReturnExchangeId();

    expect(id, 'return-1');
    expect(module.commands, hasLength(1));
    final start = module.commands.single as StartReturnExchangeCommand;
    expect(start.lines.single.reasonCode, isNull);
    expect(start.lines.single.conditionCode, isNull);
    expect(cubit.state.fieldError, isNull);
  });

  test('save without selected return line fails without sending command', () async {
    final module = _RecordingSalesModule(
      policy: ReturnExchangeFormPolicyDto(reasons: const [], conditions: const []),
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.load();

    final id = await cubit.saveAndGetReturnExchangeId();

    expect(id, isNull);
    expect(module.commands, isEmpty);
    expect(
      cubit.state.fieldError,
      'Chọn ít nhất một dòng trả với số lượng hợp lệ.',
    );
    expect(cubit.state.fieldError, isNot(contains('lý do')));
    expect(cubit.state.fieldError, isNot(contains('tình trạng')));
    expect(cubit.state.fieldError, isNot(contains('policy')));
  });

  test('addExchangeProduct uses the server preview price and tenant context', () async {
    final module = _RecordingSalesModule(
      preview: const ReturnExchangePricingPreviewDto(
        lines: [
          ReturnExchangePricedLineDto(
            productUnitId: 'u-1',
            unitPrice: MoneyDto(amountMinor: 80000, currencyCode: 'VND'),
            sourceCode: 'CUSTOMER_PRIVATE_RULE',
          ),
        ],
      ),
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.addExchangeProduct(
      const SalesProductSelection(
        productId: 'p-1',
        productUnitId: 'u-1',
        productName: 'Sản phẩm X',
        sku: 'SKU-X',
        unitLabel: 'Hộp',
        unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      ),
    );

    expect(cubit.state.exchangeEdits.single.unitPrice.amountMinor, 80000);
    final preview = module.queries.whereType<PreviewReturnExchangePricingQuery>().single;
    expect(preview.tenantId, 'tenant-1');
    expect(preview.actorId, 'actor-1');
  });

  test('PRICING_BLOCKED does not add the exchange line', () async {
    final module = _RecordingSalesModule(
      previewError: const SalesContractException('PRICING_BLOCKED'),
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.addExchangeProduct(
      const SalesProductSelection(
        productId: 'p-1',
        productUnitId: 'u-1',
        productName: 'Sản phẩm X',
        sku: 'SKU-X',
        unitLabel: 'Hộp',
        unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      ),
    );

    expect(cubit.state.exchangeEdits, isEmpty);
    expect(cubit.state.screenError, 'Sản phẩm này chưa có giá bán.');
  });

  test('refreshed exchange price forces a new save instead of reusing the old one', () async {
    final module = _RecordingSalesModule();
    final cubit = build(module);
    addTearDown(cubit.close);
    await prepareReady(cubit);
    await cubit.addExchangeProduct(
      const SalesProductSelection(
        productId: 'product-x',
        productUnitId: 'unit-x',
        productName: 'Vitamin C',
        sku: 'SKU-X',
        unitLabel: 'Hộp',
        unitPrice: MoneyDto(amountMinor: 1000, currencyCode: 'VND'),
      ),
    );
    expect(await cubit.saveAndGetReturnExchangeId(), isNotNull);
    expect(module.commands, hasLength(1));

    // Không đổi giá: lưu lại được bỏ qua (dòng không đổi).
    await cubit.refreshExchangePrices();
    expect(await cubit.saveAndGetReturnExchangeId(), isNotNull);
    expect(module.commands, hasLength(1));

    // Giá đổi (vd. sau PRICE_CHANGED ở quyết toán): phải lưu lại với giá mới.
    module.previewAmountMinor = 1200;
    await cubit.refreshExchangePrices();
    expect(cubit.state.exchangeEdits.single.unitPrice.amountMinor, 1200);
    expect(await cubit.saveAndGetReturnExchangeId(), isNotNull);
    expect(module.commands, hasLength(2));
  });

  test('network failure while previewing does not claim the price is unknown', () async {
    final module = _RecordingSalesModule(previewError: Exception('socket closed'));
    final cubit = build(module);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.addExchangeProduct(
      const SalesProductSelection(
        productId: 'p-1',
        productUnitId: 'u-1',
        productName: 'Sản phẩm X',
        sku: 'SKU-X',
        unitLabel: 'Hộp',
        unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      ),
    );

    expect(cubit.state.exchangeEdits, isEmpty);
    expect(cubit.state.screenError, 'Không lấy được giá sản phẩm. Vui lòng thử lại.');
  });

  test('PRICE_CHANGED reloads the session and refreshes exchange prices', () async {
    final module = _RecordingSalesModule(
      commandErrorsQueue: const [SalesContractException('PRICE_CHANGED')],
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await prepareReady(cubit);
    await cubit.addExchangeProduct(
      const SalesProductSelection(
        productId: 'product-x',
        productUnitId: 'unit-x',
        productName: 'Vitamin C',
        sku: 'SKU-X',
        unitLabel: 'Hộp',
        unitPrice: MoneyDto(amountMinor: 1000, currencyCode: 'VND'),
      ),
    );
    final previewBefore = module.queries.whereType<PreviewReturnExchangePricingQuery>().length;

    expect(await cubit.saveAndGetReturnExchangeId(), isNull);

    expect(
      cubit.state.screenError,
      'Giá món đổi đã thay đổi. Đã cập nhật giá mới, vui lòng kiểm tra lại.',
    );
    // load() làm mới giá đúng 1 lần; không gọi lại thêm lần nữa sau load().
    expect(
      module.queries.whereType<PreviewReturnExchangePricingQuery>().length,
      previewBefore + 1,
    );
  });

  test('exchange selection keeps product and product-unit IDs with catalog labels', () async {
    final cubit = build(_RecordingSalesModule());
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.addExchangeProduct(
      const SalesProductSelection(
        productId: 'product-x',
        productUnitId: 'unit-x',
        productName: 'Vitamin C',
        sku: 'SKU-X',
        unitLabel: 'Hộp',
        unitPrice: MoneyDto(amountMinor: 1000, currencyCode: 'VND'),
      ),
    );

    expect(cubit.state.exchangeEdits, hasLength(1));
    expect(cubit.state.exchangeEdits.single.productId, 'product-x');
    expect(cubit.state.exchangeEdits.single.productUnitId, 'unit-x');
    expect(cubit.state.exchangeEdits.single.productName, 'Vitamin C');
    expect(cubit.state.exchangeEdits.single.unitLabel, 'Hộp');
    expect(cubit.state.exchangeEdits.single.unitPrice.amountMinor, 1000);
    expect(cubit.state.exchangeEdits.single.quantityMicros, QuantityDto.scale);
  });

  test(
    'first proceed starts; later edit updates; unchanged session skips duplicate write',
    () async {
      final module = _RecordingSalesModule();
      final cubit = build(module);
      addTearDown(cubit.close);
      await prepareReady(cubit);

      final first = await cubit.saveAndGetReturnExchangeId();
      expect(first, 'return-1');
      expect(module.commands, hasLength(1));
      expect(module.commands.single, isA<StartReturnExchangeCommand>());
      final start = module.commands.single as StartReturnExchangeCommand;
      expect(start.expectedVersion, 7);
      expect(start.idempotencyKey, 'return-exchange:start:attempt-1');
      expect(start.lines.single.reasonCode, isNull);
      expect(start.lines.single.conditionCode, isNull);

      final same = await cubit.saveAndGetReturnExchangeId();
      expect(same, 'return-1');
      expect(module.commands, hasLength(1));

      cubit.setReturnQuantity('line-1', QuantityDto.scale * 2);
      final second = await cubit.saveAndGetReturnExchangeId();
      expect(second, 'return-1');
      expect(module.commands, hasLength(2));
      expect(module.commands[1], isA<UpdateReturnExchangeCommand>());
      final update = module.commands[1] as UpdateReturnExchangeCommand;
      expect(update.expectedVersion, 2);
      expect(update.idempotencyKey, 'return-exchange:update:attempt-2');
    },
  );

  test('start command keeps exchange selection snapshots for reference decision', () async {
    final module = _RecordingSalesModule();
    final cubit = build(module);
    addTearDown(cubit.close);
    await prepareReady(cubit);
    await cubit.addExchangeProduct(
      const SalesProductSelection(
        productId: 'product-x',
        productUnitId: 'unit-x',
        productName: 'Vitamin C',
        sku: 'SKU-X',
        unitLabel: 'Hộp',
        unitPrice: MoneyDto(amountMinor: 1000, currencyCode: 'VND'),
      ),
    );

    final first = await cubit.saveAndGetReturnExchangeId();

    expect(first, 'return-1');
    final start = module.commands.single as StartReturnExchangeCommand;
    final exchangeLine = start.lines.singleWhere(
      (line) => line.kind == ReturnExchangeLineKind.exchangeLine,
    );
    expect(exchangeLine.exchangeProductSnapshot?.displayName, 'Vitamin C');
    expect(exchangeLine.exchangeProductSnapshot?.sku, 'SKU-X');
    expect(exchangeLine.exchangeUnitSnapshot?.unitName, 'Hộp');
    expect(exchangeLine.exchangeUnitPrice?.amountMinor, 1000);
  });

  test('retryable dependency failure reuses attempt; edit invalidates it', () async {
    final module = _RecordingSalesModule(
      commandErrorsQueue: const [
        SalesContractException('DEPENDENCY_UNAVAILABLE'),
        null,
        SalesContractException('DEPENDENCY_UNAVAILABLE'),
        null,
      ],
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await prepareReady(cubit);

    expect(await cubit.saveAndGetReturnExchangeId(), isNull);
    expect(cubit.state.status, SalesReturnExchangeSessionStatus.retryableFailure);

    expect(await cubit.saveAndGetReturnExchangeId(), 'return-1');
    expect(module.commands, hasLength(2));
    expect(
      (module.commands[0] as StartReturnExchangeCommand).idempotencyKey,
      (module.commands[1] as StartReturnExchangeCommand).idempotencyKey,
    );

    cubit.setReturnQuantity('line-1', QuantityDto.scale * 2);
    expect(await cubit.saveAndGetReturnExchangeId(), isNull);
    expect(await cubit.saveAndGetReturnExchangeId(), 'return-1');
    expect(module.commands, hasLength(4));
    expect(
      (module.commands[1] as StartReturnExchangeCommand).idempotencyKey,
      isNot((module.commands[2] as UpdateReturnExchangeCommand).idempotencyKey),
    );
    expect(
      (module.commands[2] as UpdateReturnExchangeCommand).idempotencyKey,
      (module.commands[3] as UpdateReturnExchangeCommand).idempotencyKey,
    );
  });

  test('STALE_VERSION and RETURN_QUANTITY_EXCEEDED reload then mark stale', () async {
    for (final code in ['STALE_VERSION', 'RETURN_QUANTITY_EXCEEDED']) {
      final module = _RecordingSalesModule(
        commandErrorsQueue: [SalesContractException(code)],
      );
      final cubit = build(module);
      addTearDown(cubit.close);
      await prepareReady(cubit);

      final id = await cubit.saveAndGetReturnExchangeId();
      expect(id, isNull, reason: code);
      expect(cubit.state.status, SalesReturnExchangeSessionStatus.stale, reason: code);
      expect(
        module.queries.whereType<GetReturnableOrderLinesQuery>().length,
        greaterThan(1),
        reason: code,
      );
    }
  });

  test('discard before start performs no write; after start cancels once', () async {
    final module = _RecordingSalesModule();
    final cubit = build(module);
    addTearDown(cubit.close);
    await prepareReady(cubit);

    expect(await cubit.discard(), isTrue);
    expect(module.commands, isEmpty);
    expect(cubit.state.status, SalesReturnExchangeSessionStatus.discarded);

    final again = build(module);
    addTearDown(again.close);
    await prepareReady(again);
    await again.saveAndGetReturnExchangeId();
    expect(await again.discard(), isTrue);
    expect(module.commands.whereType<CancelReturnExchangeCommand>(), hasLength(1));
    expect(again.state.status, SalesReturnExchangeSessionStatus.discarded);
  });

  test('permission and blocked failures never emit ready after save', () async {
    for (final code in ['PERMISSION_DENIED', 'RETURN_EXCHANGE_BLOCKED']) {
      final module = _RecordingSalesModule(
        commandErrorsQueue: [SalesContractException(code)],
      );
      final cubit = build(module);
      addTearDown(cubit.close);
      await prepareReady(cubit);

      expect(await cubit.saveAndGetReturnExchangeId(), isNull, reason: code);
      expect(
        cubit.state.status,
        SalesReturnExchangeSessionStatus.failure,
        reason: code,
      );
    }
  });

  test('session_save_error_fallback', () async {
    const rawMessage = 'column reference "tenant_id" is ambiguous';
    final module = _RecordingSalesModule(
      commandErrorsQueue: const [
        SalesContractException(
          'DEPENDENCY_UNAVAILABLE',
          message: 'Sales return/exchange operation failed.',
          details: <String, Object?>{'rpcMessage': rawMessage},
        ),
      ],
    );
    final cubit = build(module);
    addTearDown(cubit.close);
    await prepareReady(cubit);

    expect(await cubit.saveAndGetReturnExchangeId(), isNull);
    expect(cubit.state.status, SalesReturnExchangeSessionStatus.retryableFailure);
    expect(cubit.state.screenError, 'Không lưu được phiếu đổi/trả. Vui lòng thử lại.');
  });

  test('save_retry_after_network_error_reuses_command_id', () async {
    final fakeRepo = FakeReturnExchangeRepository()
      ..startError = const AppException('NETWORK_ERROR');
    final cubit = SalesReturnExchangeSessionCubit(
      orderId: 'order-1',
      returnExchangeRepository: fakeRepo,
      orderRepository: ModuleBackedSalesOrderRepository(_RecordingSalesModule()),
      executionContext: const _ExecutionContext(),
      attemptFactory: SalesReturnExchangeAttemptFactory(
        newAttemptId: () => 'attempt-retry-1',
      ),
    );
    addTearDown(cubit.close);

    await cubit.load();
    cubit.setReturnQuantity('line-1', QuantityDto.scale);

    final res1 = await cubit.saveAndGetReturnExchangeId();
    expect(res1, isNull);
    expect(cubit.state.status, SalesReturnExchangeSessionStatus.retryableFailure);
    expect(cubit.state.screenError, 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.');
    expect(fakeRepo.startCalls, hasLength(1));

    // Bấm lại sau khi mạng hồi phục
    fakeRepo.startError = null;
    final res2 = await cubit.saveAndGetReturnExchangeId();
    expect(res2, 'draft-re-1');
    expect(cubit.state.status, SalesReturnExchangeSessionStatus.ready);
    expect(fakeRepo.startCalls, hasLength(2));
    expect(fakeRepo.startCalls[0].commandId, fakeRepo.startCalls[1].commandId);
    expect(fakeRepo.startCalls[0].idempotencyKey, fakeRepo.startCalls[1].idempotencyKey);
  });

  test('session_blockers_localized', () async {
    final module = _RecordingSalesModule(
      precheck: ReturnExchangePrecheckDto(
        allowed: false,
        sourceVersion: 7,
        blockers: const [
          SalesBlockerDto(
            code: 'ORDER_ALREADY_CANCELLED',
            message: 'Server English: Order was cancelled',
          ),
        ],
      ),
    );
    final cubit = build(module);
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state.status, SalesReturnExchangeSessionStatus.blocked);
    expect(cubit.state.blockers.single.message, 'Đơn đã được hủy.');
    expect(cubit.state.blockers.single.code, 'ORDER_ALREADY_CANCELLED');
  });
}

SalesOrderDetailDto _detail({bool walkIn = false}) => SalesOrderDetailDto(
  order: SalesOrderDto(
    salesOrderId: 'order-1',
    orderNumber: 'SO-2026-00125',
    version: 7,
    lifecycleStatus: SalesOrderLifecycleStatus.completed,
    lockStatus: SalesOrderLockStatus.unlocked,
    total: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
  ),
  committedAt: DateTime.utc(2026, 8, 12),
  store: const StoreSnapshotDto(
    storeId: 'store-1',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh'),
  customer: walkIn
      ? null
      : const CustomerSnapshotDto(
          customerId: 'customer-1',
          displayName: 'Khách A',
        ),
  lines: const [],
);

ReturnExchangePrecheckDto _precheck() => ReturnExchangePrecheckDto(
  allowed: true,
  sourceVersion: 7,
  blockers: const [],
);

ReturnableOrderLinesDto _returnable() => ReturnableOrderLinesDto(
  salesOrderId: 'order-1',
  sourceVersion: 7,
  lines: const [
    ReturnableOrderLineDto(
      salesOrderLineId: 'line-1',
      product: ProductSnapshotDto(
        productId: 'product-1',
        sku: 'SKU-1',
        displayName: 'Sản phẩm 1',
      ),
      unit: ProductUnitSnapshotDto(
        productUnitId: 'unit-1',
        unitCode: 'BOX',
        unitName: 'Hộp',
      ),
      soldQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
      returnableQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
      originalUnitPrice: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
    ),
  ],
);

ReturnExchangeFormPolicyDto _policy() => ReturnExchangeFormPolicyDto(
  reasons: const [
    ReturnExchangePolicyOptionDto(
      code: 'DAMAGED',
      displayName: 'Hỏng',
      sortOrder: 100,
    ),
    ReturnExchangePolicyOptionDto(
      code: 'WRONG_ITEM',
      displayName: 'Sai hàng',
      sortOrder: 200,
    ),
  ],
  conditions: const [
    ReturnExchangePolicyOptionDto(
      code: 'OPENED',
      displayName: 'Đã mở',
      sortOrder: 100,
    ),
    ReturnExchangePolicyOptionDto(
      code: 'SEALED',
      displayName: 'Nguyên seal',
      sortOrder: 200,
    ),
  ],
);

final class _RecordingSalesModule implements ISalesModule {
  _RecordingSalesModule({
    SalesOrderDetailDto? detail,
    ReturnExchangePrecheckDto? precheck,
    ReturnableOrderLinesDto? returnable,
    ReturnExchangeFormPolicyDto? policy,
    ReturnExchangeDraftDto? draft,
    this.preview,
    this.previewError,
    this.commandErrorsQueue = const <Object?>[],
  }) : detail = detail ?? _detail(),
       precheck = precheck ?? _precheck(),
       returnable = returnable ?? _returnable(),
       policy = policy ?? _policy(),
       draft =
           draft ??
           ReturnExchangeDraftDto(
             returnExchangeId: 'return-1',
             salesOrderId: 'order-1',
             version: 2,
             status: ReturnExchangeStatus.draft,
             lines: const [],
           );

  final SalesOrderDetailDto detail;
  final ReturnExchangePrecheckDto precheck;
  final ReturnableOrderLinesDto returnable;
  final ReturnExchangeFormPolicyDto policy;
  final ReturnExchangeDraftDto draft;
  final ReturnExchangePricingPreviewDto? preview;
  final Object? previewError;
  final List<Object?> commandErrorsQueue;
  int _commandCall = 0;

  /// Giá xem trước mặc định; đổi giữa test để giả lập giá vừa thay đổi.
  int previewAmountMinor = 1000;

  final List<Object> queries = <Object>[];
  final List<Object> commands = <Object>[];

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is GetSalesOrderDetailQuery) return detail as TResult;
    if (query is PrecheckReturnExchangeQuery) return precheck as TResult;
    if (query is GetReturnableOrderLinesQuery) return returnable as TResult;
    if (query is GetReturnExchangeFormPolicyQuery) return policy as TResult;
    if (query is PreviewReturnExchangePricingQuery) {
      final previewQuery = query as PreviewReturnExchangePricingQuery;
      final error = previewError;
      if (error != null) throw error;
      final configured = preview;
      if (configured != null) return configured as TResult;
      return ReturnExchangePricingPreviewDto(
            lines: [
              for (final line in previewQuery.lines)
                ReturnExchangePricedLineDto(
                  productUnitId: line.productUnitId,
                  unitPrice: MoneyDto(amountMinor: previewAmountMinor, currencyCode: 'VND'),
                  sourceCode: 'LIST',
                ),
            ],
          )
          as TResult;
    }
    throw UnsupportedError('unexpected query ${query.runtimeType}');
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    final index = _commandCall++;
    final error = index < commandErrorsQueue.length ? commandErrorsQueue[index] : null;
    if (error != null) throw error;
    if (command is StartReturnExchangeCommand || command is UpdateReturnExchangeCommand) {
      return draft as TResult;
    }
    if (command is CancelReturnExchangeCommand) {
      return ReturnExchangeResultDto(
            returnExchangeId: draft.returnExchangeId,
            salesOrderId: draft.salesOrderId,
            version: draft.version + 1,
            status: ReturnExchangeStatus.cancelled,
          )
          as TResult;
    }
    throw UnsupportedError('unexpected command ${command.runtimeType}');
  }
}

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'actor-1';
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart' hide SalesOrderLifecycleStatus;
import 'package:vet45_shared_application/application.dart';

void main() {
  SalesReturnExchangeSessionCubit build(
    _RecordingSalesModule module, {
    List<String> attemptIds = const ['attempt-1', 'attempt-2', 'attempt-3'],
  }) {
    final ids = attemptIds.iterator;
    return SalesReturnExchangeSessionCubit(
      orderId: 'order-1',
      salesModule: module,
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
    cubit.setReturnReason('line-1', 'DAMAGED');
    cubit.setReturnCondition('line-1', 'OPENED');
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
    expect(cubit.state.reasons, isEmpty);
    expect(cubit.state.conditions, isEmpty);
    expect(cubit.state.canProceed, isFalse);
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
    expect(empty.state.reasons, isEmpty);
    expect(empty.state.conditions, isEmpty);
    expect(empty.state.canProceed, isFalse);
  });

  test('quantity clamps to backend micros and zero removes selected return line', () async {
    final cubit = build(_RecordingSalesModule());
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setReturnQuantity('line-1', QuantityDto.scale * 9);
    expect(cubit.state.returnEdits.single.quantityMicros, QuantityDto.scale * 2);

    cubit.setReturnReason('line-1', 'DAMAGED');
    cubit.setReturnCondition('line-1', 'OPENED');
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

  test('exchange selection keeps product and product-unit IDs with catalog labels', () async {
    final cubit = build(_RecordingSalesModule());
    addTearDown(cubit.close);
    await cubit.load();

    cubit.addExchangeProduct(
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
    cubit.addExchangeProduct(
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

  test('dependency fallback exposes raw rpc message for diagnostics', () async {
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
    expect(cubit.state.screenError, rawMessage);
  });
}

SalesOrderDetailDto _detail() => SalesOrderDetailDto(
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
  customer: const CustomerSnapshotDto(
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
  final List<Object?> commandErrorsQueue;
  int _commandCall = 0;

  final List<Object> queries = <Object>[];
  final List<Object> commands = <Object>[];

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is GetSalesOrderDetailQuery) return detail as TResult;
    if (query is PrecheckReturnExchangeQuery) return precheck as TResult;
    if (query is GetReturnableOrderLinesQuery) return returnable as TResult;
    if (query is GetReturnExchangeFormPolicyQuery) return policy as TResult;
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

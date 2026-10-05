import 'package:test/test.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_inventory_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

const _tenantId = 'tenant-test';

void main() {
  test('scn_ensure_named_store', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
    );

    final result = await _ensure(port);

    expect(result.replayed, isFalse);
    expect(result.storeName, 'Mậu Hiên');
    expect(result.warehouseName, defaultWarehouseName);
    expect(port.stores.single.displayName, 'Mậu Hiên');
    expect(port.stores.single.code, defaultStoreCode);
    expect(port.stores.single.status, 'active');
    expect(port.warehouses.single.displayName, defaultWarehouseName);
    expect(port.warehouses.single.status, 'active');
    expect(port.assignments.single.status, 'active');
    expect(port.assignments.single.storeId, result.storeId);
    expect(port.assignments.single.warehouseId, result.warehouseId);
    expect(port.idempotencyRecords, hasLength(1));
    expect(port.idempotencyRecords.single.idempotencyKey, _tenantId);
    expect(port.idempotencyRecords.single.commandScope, defaultPairCommandScope);
    expect(port.idempotencyRecords.single.payloadHash, defaultPairPayloadHash);
    expect(port.idempotencyRecords.single.status, 'succeeded');
    expect(port.idempotencyRecords.single.resultType, defaultPairCommandScope);
    expect(port.idempotencyRecords.single.resultId, result.warehouseId);
    expect(port.idempotencyRecords.single.resultSnapshot['storeName'], 'Mậu Hiên');
    expect(port.idempotencyRecords.single.resultSnapshot['replayed'], isNull);
  });

  test('scn_ensure_fallback_store_name', () async {
    final port = FakeDefaultStoreWarehousePairPort(tenantDisplayName: '   ');

    final result = await _ensure(port);

    expect(result.storeName, fallbackStoreName);
    expect(result.warehouseName, defaultWarehouseName);
    expect(port.stores.single.displayName, fallbackStoreName);
  });

  test('scn_ensure_replay', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
    );
    final first = await _ensure(port);
    port.tenantDisplayName = 'Tên mới';

    final second = await _ensure(port, commandId: 'cmd-2');

    expect(second.replayed, isTrue);
    expect(second.storeId, first.storeId);
    expect(second.warehouseId, first.warehouseId);
    expect(second.storeName, 'Mậu Hiên');
    expect(second.warehouseName, defaultWarehouseName);
    expect(port.stores.single.displayName, 'Mậu Hiên');
    expect(port.warehouses, hasLength(1));
    expect(port.idempotencyRecords, hasLength(1));
    expect(port.helperCallCount, 1);
  });

  test('scn_second_rejected', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
    );
    final created = await _ensure(port);

    expect(
      () => port.insertActiveWarehouse(tenantId: _tenantId),
      throwsA(_code('DEFAULT_PAIR_LIMIT')),
    );
    expect(
      () => port.insertActiveAssignment(
        tenantId: _tenantId,
        storeId: created.storeId,
        warehouseId: created.warehouseId,
      ),
      throwsA(_code('DEFAULT_PAIR_LIMIT')),
    );
    expect(port.warehouses, hasLength(1));
    expect(port.assignments, hasLength(1));
  });

  test('scn_no_device_warehouse', () async {
    final command = EnsureDefaultStoreWarehousePairCommand(id: 'cmd-device');
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
    );

    final result = await _ensure(port, commandId: command.id);

    expect(command.id, 'cmd-device');
    expect(result.warehouseName, defaultWarehouseName);
    expect(port.idempotencyRecords.single.idempotencyKey, _tenantId);
    expect(port.idempotencyRecords.single.idempotencyKey, isNot(command.id));
    expect(port.warehouses, hasLength(1));
  });

  test('scn_missing_pair', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
    );

    await expectLater(_get(port), throwsA(_code('DEFAULT_PAIR_MISSING')));
    expect(port.warehouses, isEmpty);
  });

  test('scn_missing_pair_warehouse_only', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
      warehouses: [
        Warehouse(
          id: 'wh-only',
          tenantId: _tenantId,
          displayName: defaultWarehouseName,
          status: 'active',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );

    await expectLater(_get(port), throwsA(_code('DEFAULT_PAIR_MISSING')));
    expect(port.warehouses, hasLength(1));
  });

  test('scn_patch_missing_assignment', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
      warehouses: [
        Warehouse(
          id: 'wh-only',
          tenantId: _tenantId,
          displayName: defaultWarehouseName,
          status: 'active',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
      idempotencyRecords: [
        FakeDefaultPairIdempotencyRecord(
          tenantId: _tenantId,
          commandScope: defaultPairCommandScope,
          idempotencyKey: _tenantId,
          payloadHash: defaultPairPayloadHash,
          status: 'succeeded',
          correlationId: 'old-corr',
          resultType: defaultPairCommandScope,
          resultId: 'wh-only',
          resultSnapshot: const {
            'storeId': 'stale',
            'storeName': 'Tên cũ',
            'warehouseId': 'wh-only',
            'warehouseName': 'Tên kho cũ',
          },
        ),
      ],
    );

    final result = await _ensure(port);

    expect(result.replayed, isFalse);
    expect(result.warehouseId, 'wh-only');
    expect(result.warehouseName, defaultWarehouseName);
    expect(port.warehouses, hasLength(1));
    expect(port.warehouses.single.displayName, defaultWarehouseName);
    expect(port.assignments, hasLength(1));
    expect(port.assignments.single.warehouseId, 'wh-only');
    expect(port.idempotencyRecords, hasLength(1));
    expect(port.idempotencyRecords.single.resultSnapshot['storeName'], 'Mậu Hiên');
    expect(
      port.idempotencyRecords.single.resultSnapshot['warehouseName'],
      defaultWarehouseName,
    );
    expect(port.idempotencyRecords.single.resultId, 'wh-only');
  });

  test('scn_mismatch', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
    );
    final created = await _ensure(port);

    await expectLater(
      port.matches(
        tenantId: _tenantId,
        storeId: created.storeId,
        warehouseId: 'wh-other',
      ),
      throwsA(_code('DEFAULT_PAIR_MISMATCH')),
    );
    expect(port.warehouses, hasLength(1));
  });

  test('scn_tenant_member_rejected', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
      deniedPermissions: {InventoryPermissions.defaultPairEnsure},
    );

    await expectLater(
      _ensure(port),
      throwsA(_code('Permission denied: inventory.default_pair.ensure')),
    );
    expect(port.warehouses, isEmpty);
    expect(port.assignments, isEmpty);
  });

  test('scn_read_denied', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
    );
    await _ensure(port);
    final checker = FakePermissionChecker(
      deny: {InventoryPermissions.defaultPairRead},
    );

    await expectLater(
      _get(port, checker: checker),
      throwsA(_code('Permission denied: inventory.default_pair.read')),
    );
    expect(checker.required, [InventoryPermissions.defaultPairRead]);
    expect(port.warehouses, hasLength(1));
  });

  test('scn_tenant_missing', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
      tenantExists: false,
    );

    await expectLater(
      _ensure(port),
      throwsA(_code('RESOURCE_NOT_FOUND')),
    );
    expect(port.warehouses, isEmpty);
    expect(port.assignments, isEmpty);
  });

  test('scn_reactivate_default_store', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
      stores: [
        FakeTenantStore(
          id: 'store-inactive',
          code: defaultStoreCode,
          displayName: 'Tên cũ',
          status: 'inactive',
        ),
      ],
    );

    final result = await _ensure(port);

    expect(result.storeId, 'store-inactive');
    expect(result.storeName, 'Mậu Hiên');
    expect(port.stores.single.status, 'active');
    expect(port.stores.single.displayName, 'Mậu Hiên');
    expect(port.warehouses.single.displayName, defaultWarehouseName);
    expect(port.assignments, hasLength(1));
  });

  test('scn_active_store_without_default', () async {
    final port = FakeDefaultStoreWarehousePairPort(
      tenantDisplayName: 'Mậu Hiên',
      stores: [
        FakeTenantStore(
          id: 'store-branch',
          code: 'chi-nhanh',
          displayName: 'Chi nhánh',
          status: 'active',
        ),
      ],
    );

    await expectLater(
      _ensure(port),
      throwsA(_code('DEFAULT_STORE_MISSING')),
    );
    expect(port.helperCallCount, 0);
    expect(port.warehouses, isEmpty);
    expect(port.assignments, isEmpty);
    expect(
      port.idempotencyRecords.where((row) => row.status == 'succeeded'),
      isEmpty,
    );
  });
}

Future<EnsureDefaultStoreWarehousePairResultDto> _ensure(
  FakeDefaultStoreWarehousePairPort port, {
  String commandId = 'cmd-1',
}) {
  final handler = EnsureDefaultStoreWarehousePairCommandHandler(
    executionContext: FakeExecutionContext(tenantId: _tenantId),
    defaultStoreWarehousePairPort: port,
  );
  return handler.handle(EnsureDefaultStoreWarehousePairCommand(id: commandId));
}

Future<DefaultStoreWarehousePairDto> _get(
  FakeDefaultStoreWarehousePairPort port, {
  FakePermissionChecker? checker,
}) {
  final handler = GetDefaultStoreWarehousePairQueryHandler(
    permissionChecker: checker ?? FakePermissionChecker(),
    executionContext: FakeExecutionContext(tenantId: _tenantId),
    defaultStoreWarehousePairPort: port,
  );
  return handler.handle(GetDefaultStoreWarehousePairQuery());
}

Matcher _code(String message) {
  return isA<ApplicationException>().having(
    (error) => error.message,
    'message',
    message,
  );
}

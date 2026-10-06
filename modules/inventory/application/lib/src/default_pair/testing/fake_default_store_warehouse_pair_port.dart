import 'package:vet45_inventory_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_default_store_warehouse_pair_port.dart';
import '../shared/default_store_warehouse_pair_dto.dart';
import '../shared/ensure_default_store_warehouse_pair_result_dto.dart';

const defaultPairCommandScope = 'inventory.default_pair';
const defaultPairPayloadHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
const defaultWarehouseName = 'Kho mặc định';
const defaultStoreCode = 'default';
const fallbackStoreName = 'Default Store';

final class FakeTenantStore {
  FakeTenantStore({
    required this.id,
    required this.code,
    required this.displayName,
    required this.status,
  });

  final String id;
  final String code;
  String displayName;
  String status;
}

final class FakeDefaultPairIdempotencyRecord {
  FakeDefaultPairIdempotencyRecord({
    required this.tenantId,
    required this.commandScope,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.status,
    required this.correlationId,
    this.resultType,
    this.resultId,
    this.resultSnapshot = const {},
  });

  final String tenantId;
  final String commandScope;
  final String idempotencyKey;
  String payloadHash;
  String status;
  String? resultType;
  String? resultId;
  Map<String, String> resultSnapshot;
  String correlationId;
}

final class FakeDefaultStoreWarehousePairPort implements IDefaultStoreWarehousePairPort {
  FakeDefaultStoreWarehousePairPort({
    this.tenantDisplayName,
    this.tenantExists = true,
    Set<String> deniedPermissions = const {},
    List<FakeTenantStore> stores = const [],
    List<Warehouse> warehouses = const [],
    List<StoreWarehouseAssignment> assignments = const [],
    List<FakeDefaultPairIdempotencyRecord> idempotencyRecords = const [],
  }) : _deniedPermissions = Set<String>.of(deniedPermissions),
       _stores = List<FakeTenantStore>.of(stores),
       _warehouses = List<Warehouse>.of(warehouses),
       _assignments = List<StoreWarehouseAssignment>.of(assignments),
       _idempotencyRecords = List<FakeDefaultPairIdempotencyRecord>.of(
         idempotencyRecords,
       );

  String? tenantDisplayName;
  bool tenantExists;

  final Set<String> _deniedPermissions;
  final List<FakeTenantStore> _stores;
  final List<Warehouse> _warehouses;
  final List<StoreWarehouseAssignment> _assignments;
  final List<FakeDefaultPairIdempotencyRecord> _idempotencyRecords;
  int _sequence = 0;
  int helperCallCount = 0;

  List<FakeTenantStore> get stores => List.unmodifiable(_stores);
  List<Warehouse> get warehouses => List.unmodifiable(_warehouses);
  List<StoreWarehouseAssignment> get assignments => List.unmodifiable(_assignments);
  List<FakeDefaultPairIdempotencyRecord> get idempotencyRecords =>
      List.unmodifiable(_idempotencyRecords);

  @override
  Future<EnsureDefaultStoreWarehousePairResultDto> ensure({
    required String tenantId,
    required String correlationId,
  }) async {
    if (tenantId.isEmpty || correlationId.isEmpty) {
      throw const ApplicationException('CONTEXT_INVALID');
    }
    if (!tenantExists) {
      throw const ApplicationException('RESOURCE_NOT_FOUND');
    }
    if (_deniedPermissions.contains(InventoryPermissions.defaultPairEnsure)) {
      throw const ApplicationException(
        'Permission denied: inventory.default_pair.ensure',
      );
    }

    final activeWarehouses = _activeWarehouses(tenantId);
    final activeAssignments = _activeAssignments(tenantId);
    final complete = _completePair(activeWarehouses, activeAssignments);
    if (complete != null) {
      final store = _stores.firstWhere((item) => item.id == complete.storeId);
      return EnsureDefaultStoreWarehousePairResultDto(
        storeId: store.id,
        storeName: store.displayName,
        warehouseId: complete.warehouseId,
        warehouseName: complete.warehouseName,
        replayed: true,
      );
    }

    final canCreate = activeWarehouses.isEmpty && activeAssignments.isEmpty;
    final canPatch = activeWarehouses.length == 1 && activeAssignments.isEmpty;
    if (!canCreate && !canPatch) {
      throw const ApplicationException('DEFAULT_PAIR_LIMIT');
    }

    final store = _resolveStore(tenantId);
    final warehouse = canPatch
        ? activeWarehouses.single
        : _addWarehouse(tenantId, displayName: defaultWarehouseName);
    insertActiveAssignment(
      tenantId: tenantId,
      storeId: store.id,
      warehouseId: warehouse.id,
    );
    _writeIdempotency(
      tenantId: tenantId,
      correlationId: correlationId,
      store: store,
      warehouse: warehouse,
    );
    return EnsureDefaultStoreWarehousePairResultDto(
      storeId: store.id,
      storeName: store.displayName,
      warehouseId: warehouse.id,
      warehouseName: warehouse.displayName,
      replayed: false,
    );
  }

  @override
  Future<DefaultStoreWarehousePairDto> get({required String tenantId}) async {
    if (_deniedPermissions.contains(InventoryPermissions.defaultPairRead)) {
      throw const ApplicationException(
        'Permission denied: inventory.default_pair.read',
      );
    }
    final complete = _completePair(
      _activeWarehouses(tenantId),
      _activeAssignments(tenantId),
    );
    if (complete == null) {
      throw const ApplicationException('DEFAULT_PAIR_MISSING');
    }
    final store = _stores.firstWhere((item) => item.id == complete.storeId);
    return DefaultStoreWarehousePairDto(
      storeId: store.id,
      storeName: store.displayName,
      warehouseId: complete.warehouseId,
      warehouseName: complete.warehouseName,
    );
  }

  @override
  Future<void> matches({
    required String tenantId,
    required String storeId,
    required String warehouseId,
  }) async {
    final pair = await get(tenantId: tenantId);
    if (pair.storeId != storeId || pair.warehouseId != warehouseId) {
      throw const ApplicationException('DEFAULT_PAIR_MISMATCH');
    }
  }

  void seedActiveWarehouse({
    required String tenantId,
    String? id,
    String displayName = defaultWarehouseName,
  }) {
    _warehouses.add(
      Warehouse(
        id: id ?? _nextId('warehouse'),
        tenantId: tenantId,
        displayName: displayName,
        status: 'active',
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  void insertActiveWarehouse({
    required String tenantId,
    String displayName = defaultWarehouseName,
  }) {
    if (_activeWarehouses(tenantId).isNotEmpty) {
      throw const ApplicationException('DEFAULT_PAIR_LIMIT');
    }
    _addWarehouse(tenantId, displayName: displayName);
  }

  void insertActiveAssignment({
    required String tenantId,
    required String storeId,
    required String warehouseId,
  }) {
    if (_activeAssignments(tenantId).isNotEmpty) {
      throw const ApplicationException('DEFAULT_PAIR_LIMIT');
    }
    _assignments.add(
      StoreWarehouseAssignment(
        id: _nextId('assignment'),
        tenantId: tenantId,
        storeId: storeId,
        warehouseId: warehouseId,
        status: 'active',
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Warehouse _addWarehouse(String tenantId, {required String displayName}) {
    final warehouse = Warehouse(
      id: _nextId('warehouse'),
      tenantId: tenantId,
      displayName: displayName,
      status: 'active',
      createdAt: DateTime.now().toUtc(),
    );
    _warehouses.add(warehouse);
    return warehouse;
  }

  FakeTenantStore _resolveStore(String tenantId) {
    final active = _stores.where((store) => store.status == 'active').toList(growable: false);
    final defaultActive = active
        .where((store) => store.code == defaultStoreCode)
        .toList(growable: false);
    if (active.isNotEmpty && defaultActive.isEmpty) {
      throw const ApplicationException('DEFAULT_STORE_MISSING');
    }

    helperCallCount += 1;
    if (defaultActive.isNotEmpty) {
      return defaultActive.first;
    }

    final name = _storeName(tenantDisplayName);
    for (final store in _stores) {
      if (store.code == defaultStoreCode && store.status != 'active') {
        store
          ..status = 'active'
          ..displayName = name;
        return store;
      }
    }

    final created = FakeTenantStore(
      id: _nextId('store'),
      code: defaultStoreCode,
      displayName: name,
      status: 'active',
    );
    _stores.add(created);
    return created;
  }

  void _writeIdempotency({
    required String tenantId,
    required String correlationId,
    required FakeTenantStore store,
    required Warehouse warehouse,
  }) {
    final snapshot = <String, String>{
      'storeId': store.id,
      'storeName': store.displayName,
      'warehouseId': warehouse.id,
      'warehouseName': warehouse.displayName,
    };
    for (final record in _idempotencyRecords) {
      if (record.tenantId == tenantId &&
          record.commandScope == defaultPairCommandScope &&
          record.idempotencyKey == tenantId) {
        record
          ..payloadHash = defaultPairPayloadHash
          ..status = 'succeeded'
          ..resultType = defaultPairCommandScope
          ..resultId = warehouse.id
          ..resultSnapshot = snapshot
          ..correlationId = correlationId;
        return;
      }
    }
    _idempotencyRecords.add(
      FakeDefaultPairIdempotencyRecord(
        tenantId: tenantId,
        commandScope: defaultPairCommandScope,
        idempotencyKey: tenantId,
        payloadHash: defaultPairPayloadHash,
        status: 'succeeded',
        resultType: defaultPairCommandScope,
        resultId: warehouse.id,
        resultSnapshot: snapshot,
        correlationId: correlationId,
      ),
    );
  }

  List<Warehouse> _activeWarehouses(String tenantId) {
    return _warehouses
        .where(
          (warehouse) => warehouse.tenantId == tenantId && warehouse.status == 'active',
        )
        .toList(growable: false);
  }

  List<StoreWarehouseAssignment> _activeAssignments(String tenantId) {
    return _assignments
        .where(
          (assignment) => assignment.tenantId == tenantId && assignment.status == 'active',
        )
        .toList(growable: false);
  }

  _CompletePair? _completePair(
    List<Warehouse> activeWarehouses,
    List<StoreWarehouseAssignment> activeAssignments,
  ) {
    if (activeWarehouses.length != 1 || activeAssignments.length != 1) {
      return null;
    }
    final warehouse = activeWarehouses.single;
    final assignment = activeAssignments.single;
    if (assignment.warehouseId != warehouse.id) {
      return null;
    }
    return _CompletePair(
      storeId: assignment.storeId,
      warehouseId: warehouse.id,
      warehouseName: warehouse.displayName,
    );
  }

  String _nextId(String prefix) {
    _sequence += 1;
    return '$prefix-$_sequence';
  }

  static String _storeName(String? displayName) {
    final trimmed = displayName?.trim() ?? '';
    if (trimmed.isEmpty) {
      return fallbackStoreName;
    }
    return trimmed;
  }
}

final class _CompletePair {
  const _CompletePair({
    required this.storeId,
    required this.warehouseId,
    required this.warehouseName,
  });

  final String storeId;
  final String warehouseId;
  final String warehouseName;
}

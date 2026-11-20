import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/dashboard/data/models/default_store_warehouse_pair.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

final _unusedRpc = SupabaseRpc(_UnusedClient());

enum FakeDefaultPairMode { ready, missingThenEnsure, getError, ensureError }

class FakeDefaultPairRepository extends DefaultPairRepository {
  FakeDefaultPairRepository({
    this.mode = FakeDefaultPairMode.ready,
    this.pause,
  }) : super(rpc: _unusedRpc, tenantId: () async => 'tenant-test');

  final FakeDefaultPairMode mode;
  final Future<void> Function()? pause;
  int getCalls = 0;
  int ensureCalls = 0;

  static const defaultPair = DefaultStoreWarehousePair(
    storeId: 'store-ready',
    storeName: 'Default Store',
    warehouseId: 'wh-ready',
    warehouseName: 'Kho mặc định',
    replayed: false,
  );

  @override
  Future<DefaultStoreWarehousePair> get() async {
    getCalls++;
    if (pause != null) {
      await pause!();
    }
    switch (mode) {
      case FakeDefaultPairMode.ready:
        return defaultPair;
      case FakeDefaultPairMode.missingThenEnsure:
      case FakeDefaultPairMode.ensureError:
        throw const AppException('DEFAULT_PAIR_MISSING');
      case FakeDefaultPairMode.getError:
        throw const AppException(AppErrorCode.noPermission);
    }
  }

  @override
  Future<DefaultStoreWarehousePair> ensure() async {
    ensureCalls++;
    if (pause != null) {
      await pause!();
    }
    switch (mode) {
      case FakeDefaultPairMode.ready:
      case FakeDefaultPairMode.missingThenEnsure:
        return defaultPair;
      case FakeDefaultPairMode.getError:
        throw const AppException(AppErrorCode.noPermission);
      case FakeDefaultPairMode.ensureError:
        throw const AppException('DEFAULT_PAIR_LIMIT');
    }
  }
}


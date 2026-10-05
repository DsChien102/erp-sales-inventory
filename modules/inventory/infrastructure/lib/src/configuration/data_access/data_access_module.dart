import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../default_pair/default_store_warehouse_pair_gateway.dart';
import '../../errors/inventory_error_mapper.dart';
import '../processing/internal_commands/supabase_inventory_internal_command_client.dart';

final class InventoryDataAccessModule {
  const InventoryDataAccessModule();

  void load({
    required GetIt container,
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
  }) {
    final logger = loggerFactory.named('inventory.rpc');
    container
      ..registerSingleton<SupabaseSchemaRpcClient>(
        SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'inventory',
          mapError: mapInventoryTransportError,
          logger: logger,
        ),
      )
      ..registerSingleton<IDefaultStoreWarehousePairPort>(
        DefaultStoreWarehousePairGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IInventoryInternalCommandClient>(
        const SupabaseInventoryInternalCommandClient(),
      );
  }
}

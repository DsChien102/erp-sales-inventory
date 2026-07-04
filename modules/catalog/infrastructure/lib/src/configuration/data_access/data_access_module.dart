import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../domain/product/supabase_product_command_gateway.dart';
import '../../domain/product/supabase_product_duplicate_checker.dart';
import '../processing/internal_commands/i_catalog_internal_command_client.dart';
import '../processing/internal_commands/supabase_catalog_internal_command_client.dart';

/// Registers catalog gateways and checkers.
final class CatalogDataAccessModule {
  const CatalogDataAccessModule();

  void load({
    required GetIt container,
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
  }) {
    final logger = loggerFactory.named('catalog.rpc');

    container
      ..registerSingleton<SupabaseSchemaRpcClient>(
        SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'catalog',
          mapError: (error, [stackTrace]) => RpcException(error.toString()),
          logger: logger,
        ),
      )
      ..registerSingleton<IProductCommandGateway>(
        SupabaseProductCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProductDuplicateChecker>(
        SupabaseProductDuplicateChecker(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ICatalogInternalCommandClient>(
        const SupabaseCatalogInternalCommandClient(),
      );
  }
}

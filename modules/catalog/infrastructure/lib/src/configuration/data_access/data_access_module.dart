import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../domain/lifecycle/supabase_product_change_history_gateway.dart';
import '../../domain/pricing/supabase_product_price_band_gateway.dart';
import '../../domain/pricing/supabase_store_price_rule_gateway.dart';
import '../../domain/custom_fields/supabase_catalog_custom_field_config_gateway.dart';
import '../../domain/custom_fields/supabase_catalog_custom_field_read_gateway.dart';
import '../../domain/custom_fields/supabase_catalog_custom_field_value_gateway.dart';
import '../../domain/product/supabase_catalog_read_gateway.dart';
import '../../domain/product/supabase_catalog_unit_gateway.dart';
import '../../domain/product/supabase_product_command_gateway.dart';
import '../../domain/product/supabase_product_deletion_gateway.dart';
import '../../domain/product/supabase_product_duplicate_checker.dart';
import '../../domain/product/supabase_product_image_upload_gateway.dart';
import '../../domain/product/supabase_product_readiness_read_gateway.dart';
import '../../domain/stock/supabase_catalog_stock_gateway.dart';
import '../../domain/stock/supabase_product_stock_read_gateway.dart';
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
      ..registerSingleton<SupabaseProductCommandGateway>(
        SupabaseProductCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProductCommandGateway>(
        container.get<SupabaseProductCommandGateway>(),
      )
      ..registerSingleton<IGuidedProductCommandGateway>(
        container.get<SupabaseProductCommandGateway>(),
      )
      ..registerSingleton<IProductDeletionGateway>(
        SupabaseProductDeletionGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProductImageUploadPort>(
        SupabaseProductImageUploadGateway(
          supabase: supabase,
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProductDuplicateChecker>(
        SupabaseProductDuplicateChecker(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProductReadinessReadPort>(
        SupabaseProductReadinessReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ICatalogReadGateway>(
        SupabaseCatalogReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProductWritePort>(
        CatalogProductWritePort(
          readGateway: container.get<ICatalogReadGateway>(),
        ),
      )
      ..registerSingleton<ICatalogUnitGateway>(
        SupabaseCatalogUnitGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ICatalogCustomFieldConfigGateway>(
        SupabaseCatalogCustomFieldConfigGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ICatalogCustomFieldValueGateway>(
        SupabaseCatalogCustomFieldValueGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ICatalogCustomFieldReadGateway>(
        SupabaseCatalogCustomFieldReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ICatalogStockGateway>(
        SupabaseCatalogStockGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProductStockReadPort>(
        SupabaseProductStockReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IStorePriceRuleGateway>(
        SupabaseStorePriceRuleGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProductPriceBandGateway>(
        SupabaseProductPriceBandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProductChangeHistoryGateway>(
        SupabaseProductChangeHistoryGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ICatalogInternalCommandClient>(
        const SupabaseCatalogInternalCommandClient(),
      );
  }
}

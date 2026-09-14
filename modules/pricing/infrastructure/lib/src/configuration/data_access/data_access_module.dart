import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../domain/customer_price_rule/supabase_customer_price_rule_command_gateway.dart';
import '../../domain/customer_price_rule/supabase_customer_price_rule_read_gateway.dart';
import '../../domain/customer_price_rule/supabase_customer_price_rule_reenable_precheck_gateway.dart';
import '../../domain/customer_price_rule/supabase_pricing_create_context_gateway.dart';
import '../../domain/customer_price_rule/supabase_pricing_update_context_gateway.dart';
import '../../domain/customer_price_rule_import/excel_customer_price_rule_import_file_adapter.dart';
import '../../domain/customer_price_rule_import/supabase_customer_price_rule_import_gateway.dart';
import '../../domain/remembered_price_request/supabase_remembered_price_gateway.dart';
import '../../domain/sales_pricing/supabase_sales_pricing_read_gateway.dart';
import '../processing/internal_commands/supabase_pricing_internal_command_client.dart';

final class PricingDataAccessModule {
  const PricingDataAccessModule();

  void load({
    required GetIt container,
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
  }) {
    final rpcClient = SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'pricing',
      mapError: (error, [stackTrace]) => RpcException(error.toString()),
      logger: loggerFactory.named('pricing.rpc'),
    );
    container
      ..registerSingleton<SupabaseSchemaRpcClient>(rpcClient)
      ..registerSingleton<ICustomerPriceRuleCreateContextPort>(
        SupabasePricingCreateContextGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<ICustomerPriceRuleUpdateContextPort>(
        SupabasePricingUpdateContextGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<ICustomerPriceRuleCommandGateway>(
        SupabaseCustomerPriceRuleCommandGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<ICustomerPriceRuleReenablePrecheckPort>(
        SupabaseCustomerPriceRuleReenablePrecheckGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<IPricingReadGateway>(
        SupabaseCustomerPriceRuleReadGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<IPricingInternalCommandClient>(
        const SupabasePricingInternalCommandClient(),
      )
      ..registerSingleton<ICustomerPriceRuleImportFilePort>(
        const ExcelCustomerPriceRuleImportFileAdapter(),
      )
      ..registerSingleton<ICustomerPriceRuleImportGateway>(
        SupabaseCustomerPriceRuleImportGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<IRememberedPriceGateway>(
        SupabaseRememberedPriceGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<ISalesPricingReadGateway>(
        SupabaseSalesPricingReadGateway(rpcClient: rpcClient),
      );
  }
}

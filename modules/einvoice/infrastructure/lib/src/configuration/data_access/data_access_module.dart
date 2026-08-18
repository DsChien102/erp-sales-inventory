import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../adapters/misa/me_invoice_provider_adapter.dart';
import '../../adapters/misa/tenant_me_invoice_client_factory.dart';
import '../../data_access/supabase_automation_policy_gateway.dart';
import '../../data_access/supabase_configuration_readiness_read_gateway.dart';
import '../../data_access/supabase_issuance_profile_gateway.dart';
import '../../data_access/supabase_provider_connection_command_gateway.dart';
import '../../data_access/supabase_provider_connection_read_gateway.dart';

final class EinvoiceDataAccessModule {
  const EinvoiceDataAccessModule();

  void load({
    required GetIt container,
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required String misaAppId,
    String misaBaseUrl = MeInvoiceConfig.testBaseUrl,
  }) {
    final logger = loggerFactory.named('einvoice.rpc');

    container
      ..registerSingleton<SupabaseSchemaRpcClient>(
        SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'einvoice',
          mapError: (error, [stackTrace]) => RpcException(error.toString()),
          logger: logger,
        ),
      )
      ..registerSingleton<IProviderConnectionCommandGateway>(
        SupabaseProviderConnectionCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IProviderConnectionReadGateway>(
        SupabaseProviderConnectionReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IIssuanceProfileGateway>(
        SupabaseIssuanceProfileGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IAutomationPolicyGateway>(
        SupabaseAutomationPolicyGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IConfigurationReadinessReadGateway>(
        SupabaseConfigurationReadinessReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<TenantMeInvoiceClientFactory>(
        TenantMeInvoiceClientFactory(),
      )
      ..registerSingleton<IMeInvoiceProviderPort>(
        MeInvoiceProviderAdapter(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
          clientFactory: container.get<TenantMeInvoiceClientFactory>(),
          defaultAppId: misaAppId,
          defaultBaseUrl: misaBaseUrl,
        ),
      );
  }
}

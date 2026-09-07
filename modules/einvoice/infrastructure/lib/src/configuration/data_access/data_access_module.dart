import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../adapters/misa/me_invoice_delivery_observation_provider_adapter.dart';
import '../../adapters/misa/me_invoice_delivery_provider_adapter.dart';
import '../../adapters/misa/me_invoice_electronic_invoice_provider_adapter.dart';
import '../../adapters/misa/me_invoice_provider_adapter.dart';
import '../../adapters/misa/tenant_me_invoice_client_factory.dart';
import '../../adapters/misa/worker_only_electronic_invoice_provider_port.dart';
import '../../adapters/misa/worker_only_invoice_delivery_provider_port.dart';
import '../../adapters/misa/worker_only_me_invoice_provider_port.dart';
import '../../data_access/supabase_automation_policy_gateway.dart';
import '../../data_access/supabase_buyer_invoice_data_gateway.dart';
import '../../data_access/supabase_configuration_readiness_read_gateway.dart';
import '../../data_access/supabase_electronic_invoice_command_gateway.dart';
import '../../data_access/supabase_electronic_invoice_read_gateway.dart';
import '../../data_access/supabase_invoice_preview_gateway.dart';
import '../../data_access/supabase_issuance_profile_gateway.dart';
import '../../data_access/supabase_issuance_readiness_read_gateway.dart';
import '../../data_access/supabase_provider_connection_command_gateway.dart';
import '../../data_access/supabase_provider_connection_read_gateway.dart';
import '../../domain/delivery/supabase_delivery_command_gateway.dart';
import '../../domain/delivery/supabase_delivery_read_gateway.dart';
import '../../domain/delivery/supabase_delivery_reconciliation_gateway.dart';
import '../../domain/issuance/supabase_auto_issuance_gateway.dart';
import '../../domain/issuance/supabase_issuance_command_gateway.dart';
import '../../domain/issuance/supabase_issuance_reconciliation_gateway.dart';
import '../../domain/issuance/supabase_issuance_result_gateway.dart';
import '../../domain/issuance/supabase_order_invoice_projection_read_gateway.dart';
import '../../provider_interactions/supabase_provider_interaction_gateway.dart';
import '../../storage/invoice_document_signed_url_resolver.dart';
import '../../storage/supabase_invoice_document_storage_port.dart';

final class EinvoiceDataAccessModule {
  const EinvoiceDataAccessModule();

  void load({
    required GetIt container,
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    String misaAppId = '',
    String misaBaseUrl = MeInvoiceConfig.testBaseUrl,
    bool enableMisaHttp = false,
    bool misaEmailDeliveryEnabled = false,
  }) {
    final logger = loggerFactory.named('einvoice.rpc');

    if (!container.isRegistered<SupabaseSchemaRpcClient>()) {
      container.registerSingleton<SupabaseSchemaRpcClient>(
        SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'einvoice',
          mapError: (error, [stackTrace]) => RpcException(error.toString()),
          logger: logger,
        ),
      );
    }
    if (!container.isRegistered<IProviderConnectionCommandGateway>()) {
      container.registerSingleton<IProviderConnectionCommandGateway>(
        SupabaseProviderConnectionCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IProviderConnectionReadGateway>()) {
      container.registerSingleton<IProviderConnectionReadGateway>(
        SupabaseProviderConnectionReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IIssuanceProfileGateway>()) {
      container.registerSingleton<IIssuanceProfileGateway>(
        SupabaseIssuanceProfileGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IAutomationPolicyGateway>()) {
      container.registerSingleton<IAutomationPolicyGateway>(
        SupabaseAutomationPolicyGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IConfigurationReadinessReadGateway>()) {
      container.registerSingleton<IConfigurationReadinessReadGateway>(
        SupabaseConfigurationReadinessReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IIssuanceReadinessReadGateway>()) {
      container.registerSingleton<IIssuanceReadinessReadGateway>(
        SupabaseIssuanceReadinessReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IBuyerInvoiceDataGateway>()) {
      container.registerSingleton<IBuyerInvoiceDataGateway>(
        SupabaseBuyerInvoiceDataGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IInvoicePreviewGateway>()) {
      container.registerSingleton<IInvoicePreviewGateway>(
        SupabaseInvoicePreviewGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<TenantMeInvoiceClientFactory>()) {
      container.registerSingleton<TenantMeInvoiceClientFactory>(
        TenantMeInvoiceClientFactory(),
      );
    }
    if (!container.isRegistered<IMeInvoiceProviderPort>()) {
      container.registerSingleton<IMeInvoiceProviderPort>(
        enableMisaHttp
            ? MeInvoiceProviderAdapter(
                rpcClient: container.get<SupabaseSchemaRpcClient>(),
                clientFactory: container.get<TenantMeInvoiceClientFactory>(),
                defaultAppId: misaAppId,
                defaultBaseUrl: misaBaseUrl,
                emailDeliveryEnabled: misaEmailDeliveryEnabled,
                logger: loggerFactory.named('einvoice.misa'),
              )
            : WorkerOnlyMeInvoiceProviderPort(),
      );
    }
    if (!container.isRegistered<IIssuanceCommandGateway>()) {
      container.registerSingleton<IIssuanceCommandGateway>(
        SupabaseIssuanceCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IAutoIssuanceGateway>()) {
      container.registerSingleton<IAutoIssuanceGateway>(
        SupabaseAutoIssuanceGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IIssuanceResultGateway>()) {
      container.registerSingleton<IIssuanceResultGateway>(
        SupabaseIssuanceResultGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IIssuanceReconciliationGateway>()) {
      container.registerSingleton<IIssuanceReconciliationGateway>(
        SupabaseIssuanceReconciliationGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IOrderInvoiceProjectionReadGateway>()) {
      container.registerSingleton<IOrderInvoiceProjectionReadGateway>(
        SupabaseOrderInvoiceProjectionReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IDeliveryCommandGateway>()) {
      container.registerSingleton<IDeliveryCommandGateway>(
        SupabaseDeliveryCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IDeliveryReadGateway>()) {
      container.registerSingleton<IDeliveryReadGateway>(
        SupabaseDeliveryReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IDeliveryReconciliationGateway>()) {
      container.registerSingleton<IDeliveryReconciliationGateway>(
        SupabaseDeliveryReconciliationGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IInvoiceDeliveryProviderPort>()) {
      container.registerSingleton<IInvoiceDeliveryProviderPort>(
        enableMisaHttp
            ? MeInvoiceDeliveryProviderAdapter(
                logger: loggerFactory.named('einvoice.delivery'),
                rpcClient: container.get<SupabaseSchemaRpcClient>(),
                clientFactory: TenantMeInvoiceClientFactory(),
                defaultAppId: misaAppId,
                defaultBaseUrl: misaBaseUrl,
              )
            : WorkerOnlyInvoiceDeliveryProviderPort(),
      );
    }
    if (!container.isRegistered<IInvoiceDeliveryObservationProviderPort>()) {
      container.registerSingleton<IInvoiceDeliveryObservationProviderPort>(
        const MeInvoiceDeliveryObservationProviderAdapter(),
      );
    }
    if (!container.isRegistered<InvoiceDocumentSignedUrlResolver>()) {
      container.registerSingleton<InvoiceDocumentSignedUrlResolver>(
        InvoiceDocumentSignedUrlResolver(supabase: supabase),
      );
    }
    if (!container.isRegistered<IInvoiceDocumentStoragePort>()) {
      container.registerSingleton<IInvoiceDocumentStoragePort>(
        SupabaseInvoiceDocumentStoragePort(supabase: supabase),
      );
    }
    if (!container.isRegistered<IProviderInteractionGateway>()) {
      container.registerSingleton<IProviderInteractionGateway>(
        SupabaseProviderInteractionGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
    }
    if (!container.isRegistered<IElectronicInvoiceCommandGateway>()) {
      container.registerSingleton<IElectronicInvoiceCommandGateway>(
        SupabaseElectronicInvoiceCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
          signedUrlResolver: container.get<InvoiceDocumentSignedUrlResolver>(),
        ),
      );
    }
    if (!container.isRegistered<IElectronicInvoiceReadGateway>()) {
      container.registerSingleton<IElectronicInvoiceReadGateway>(
        SupabaseElectronicInvoiceReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
          signedUrlResolver: container.get<InvoiceDocumentSignedUrlResolver>(),
        ),
      );
    }
    if (!container.isRegistered<IElectronicInvoiceProviderPort>()) {
      container.registerSingleton<IElectronicInvoiceProviderPort>(
        enableMisaHttp
            ? MeInvoiceElectronicInvoiceProviderAdapter(
                rpcClient: container.get<SupabaseSchemaRpcClient>(),
                clientFactory: container.get<TenantMeInvoiceClientFactory>(),
                defaultAppId: misaAppId,
                defaultBaseUrl: misaBaseUrl,
              )
            : WorkerOnlyElectronicInvoiceProviderPort(),
      );
    }
  }
}

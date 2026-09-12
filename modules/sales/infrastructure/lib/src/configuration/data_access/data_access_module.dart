import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../adapters/unavailable_return_exchange_reference_port.dart';
import '../../domain/pricing/runtime_pricing_preview_port.dart';
import '../../domain/return_exchange_order/supabase_return_exchange_command_gateway.dart';
import '../../domain/return_exchange_order/supabase_return_exchange_read_gateway.dart';
import '../../domain/return_exchange_order/supabase_return_exchange_settlement_gateway.dart';
import '../../domain/sales_order/supabase_checkout_gateway.dart';
import '../../domain/sales_order/supabase_post_sale_actions_gateway.dart';
import '../../domain/sales_order/supabase_sales_order_inquiry_gateway.dart';
import '../../domain/sales_order/supabase_sales_order_read_gateway.dart';
import '../../domain/sales_order_cancellation/supabase_sales_order_cancellation_gateway.dart';
import '../../domain/sales_order_draft/supabase_sales_order_draft_gateway.dart';
import '../../domain/sales_receipt/supabase_sales_receipt_gateway.dart';
import '../processing/internal_commands/supabase_sales_internal_command_client.dart';

/// Registers sales gateways and repositories.
///
/// Draft persistence uses [SupabaseSalesOrderDraftGateway] against the `sales`
/// schema. Tests may inject an [ISalesOrderDraftGateway] override without a
/// production in-memory fallback.
final class SalesDataAccessModule {
  const SalesDataAccessModule();

  void load({
    required GetIt container,
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    ISalesOrderDraftGateway? salesOrderDraftGateway,
    ICheckoutGateway? checkoutGateway,
  }) {
    final rpcClient = SupabaseRpcClient(
      SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'sales',
        logger: loggerFactory.named('sales.rpc'),
        mapError: (error, [stackTrace]) => RpcException(
          error.toString(),
          cause: error,
        ),
      ),
    );
    container
      ..registerSingleton<IRpcClient>(rpcClient)
      ..registerSingleton<ISalesInternalCommandClient>(
        const SupabaseSalesInternalCommandClient(),
      )
      ..registerSingleton<ICheckoutGateway>(
        checkoutGateway ?? SupabaseCheckoutGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<ISalesOrderReadGateway>(
        SupabaseSalesOrderReadGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<ISalesOrderInquiryGateway>(
        SupabaseSalesOrderInquiryGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<IPostSaleActionsGateway>(
        SupabasePostSaleActionsGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<IReturnExchangeReadGateway>(
        SupabaseReturnExchangeReadGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<IReturnExchangeCommandGateway>(
        SupabaseReturnExchangeCommandGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<IReturnExchangeSettlementGateway>(
        SupabaseReturnExchangeSettlementGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<IReturnExchangeReferencePort>(
        UnavailableReturnExchangeReferencePort(),
      )
      ..registerSingleton<ISalesOrderCancellationGateway>(
        SupabaseSalesOrderCancellationGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<ISalesReceiptGateway>(
        SupabaseSalesReceiptGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<ISalesOrderDraftGateway>(
        salesOrderDraftGateway ?? SupabaseSalesOrderDraftGateway(rpcClient: rpcClient),
      )
      ..registerSingleton<IPricingPreviewPort>(
        const RuntimePricingPreviewPort(),
      );
  }
}

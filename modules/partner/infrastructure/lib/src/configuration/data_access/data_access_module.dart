import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../domain/business_partner/supabase_partner_command_gateway.dart';
import '../../domain/business_partner/supabase_partner_duplicate_checker.dart';
import '../../domain/business_partner/supabase_partner_read_gateway.dart';
import '../processing/internal_commands/supabase_partner_internal_command_client.dart';

/// Registers partner gateways and checkers.
final class PartnerDataAccessModule {
  const PartnerDataAccessModule();

  void load({
    required GetIt container,
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
  }) {
    final logger = loggerFactory.named('partner.rpc');

    container
      ..registerSingleton<SupabaseSchemaRpcClient>(
        SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'partner',
          mapError: (error, [stackTrace]) => RpcException(error.toString()),
          logger: logger,
        ),
      )
      ..registerSingleton<IPartnerCommandGateway>(
        SupabasePartnerCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IPartnerDuplicateChecker>(
        SupabasePartnerDuplicateChecker(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IPartnerReadGateway>(
        SupabasePartnerReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IPartnerInternalCommandClient>(
        const SupabasePartnerInternalCommandClient(),
      );
  }
}

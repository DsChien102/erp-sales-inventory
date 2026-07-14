import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../data_access/supabase_partner_command_gateway.dart';
import '../../data_access/supabase_partner_read_gateway.dart';
import '../../data_access/supabase_partner_repository.dart';
import '../processing/internal_commands/supabase_partner_internal_command_client.dart';

/// Registers partner gateways and repository.
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
      ..registerSingleton<SupabasePartnerReadGateway>(
        SupabasePartnerReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IPartnerReadGateway>(
        container.get<SupabasePartnerReadGateway>(),
      )
      ..registerSingleton<IPartnerDuplicateChecker>(
        SupabasePartnerDuplicateChecker(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IPartnerHistoryReadGateway>(
        container.get<SupabasePartnerReadGateway>(),
      )
      ..registerSingleton<IPartnerHistoryWriteGateway>(
        SupabasePartnerHistoryWriteGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IPartnerRepository>(
        SupabasePartnerRepository(
          readGateway: container.get<SupabasePartnerReadGateway>(),
        ),
      )
      ..registerSingleton<IPartnerInternalCommandClient>(
        SupabasePartnerInternalCommandClient(),
      );
  }
}


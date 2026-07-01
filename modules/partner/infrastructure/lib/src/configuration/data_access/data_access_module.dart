import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../domain/business_partner/supabase_partner_command_gateway.dart';
import '../../domain/business_partner/supabase_partner_duplicate_checker.dart';
import '../../domain/business_partner/supabase_partner_read_gateway.dart';

/// Registers partner gateways, handlers, and validators.
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
      ..registerSingleton<ICommandValidator<RegisterPartnerCommand>>(
        RegisterPartnerCommandValidator(),
      )
      ..registerSingleton<ICommandValidator<UpdatePartnerProfileCommand>>(
        UpdatePartnerProfileCommandValidator(),
      )
      ..registerSingleton<ICommandValidator<DeactivatePartnerCommand>>(
        DeactivatePartnerCommandValidator(),
      )
      ..registerSingleton<ICommandValidator<ReactivatePartnerCommand>>(
        ReactivatePartnerCommandValidator(),
      )
      ..registerSingleton<ICommandValidator<DeletePartnerCommand>>(
        DeletePartnerCommandValidator(),
      )
      ..registerSingleton(
        RegisterPartnerCommandHandler(
          commandGateway: container.get<IPartnerCommandGateway>(),
        ),
      )
      ..registerSingleton(
        UpdatePartnerProfileCommandHandler(
          commandGateway: container.get<IPartnerCommandGateway>(),
        ),
      )
      ..registerSingleton(
        DeactivatePartnerCommandHandler(
          commandGateway: container.get<IPartnerCommandGateway>(),
        ),
      )
      ..registerSingleton(
        ReactivatePartnerCommandHandler(
          commandGateway: container.get<IPartnerCommandGateway>(),
        ),
      )
      ..registerSingleton(
        DeletePartnerCommandHandler(
          commandGateway: container.get<IPartnerCommandGateway>(),
        ),
      )
      ..registerSingleton(
        CheckDuplicatePartnersQueryHandler(
          duplicateChecker: container.get<IPartnerDuplicateChecker>(),
        ),
      )
      ..registerSingleton(
        CheckDuplicatePartnersForUpdateQueryHandler(
          duplicateChecker: container.get<IPartnerDuplicateChecker>(),
        ),
      )
      ..registerSingleton(
        SearchPartnersQueryHandler(
          readGateway: container.get<IPartnerReadGateway>(),
        ),
      )
      ..registerSingleton(
        GetPartnerDetailQueryHandler(
          readGateway: container.get<IPartnerReadGateway>(),
        ),
      );
  }
}

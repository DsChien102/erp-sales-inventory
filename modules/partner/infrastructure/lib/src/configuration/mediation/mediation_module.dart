import 'package:get_it/get_it.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../access/partner_access_metadata_registry.dart';

/// Registers partner command/query handlers on shared buses.
final class PartnerMediationModule {
  const PartnerMediationModule();

  void load({
    required GetIt container,
    required CommandBus commandBus,
    required QueryBus queryBus,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
    ILogger? commandLogger,
  }) {
    final accessMetadata = partnerAccessMetadataRegistry;

    commandBus.register<RegisterPartnerCommand, RegisterPartnerResult>(
      DefaultCommandPipeline.buildBusinessPipeline<
        RegisterPartnerCommand,
        RegisterPartnerResult,
        RegisterPartnerCommandHandler
      >(
        container: container,
        handler: container.get<RegisterPartnerCommandHandler>(),
        invoke: (command, handler) => handler.handle(command),
        accessMetadata: accessMetadata,
        permissionChecker: permissionChecker,
        tenantAccessChecker: tenantAccessChecker,
        logger: commandLogger,
      ),
    );

    queryBus
      ..register<
        CheckDuplicatePartnersQuery,
        List<PartnerDuplicateMatchDto>
      >(
        (query) => container.get<CheckDuplicatePartnersQueryHandler>().handle(
          query,
        ),
      )
      ..register<SearchPartnersQuery, PartnerSearchResultDto>(
        (query) => container.get<SearchPartnersQueryHandler>().handle(query),
      );
  }
}

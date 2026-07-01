import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Scenario ids aligned with `docs/themes/TH-03-partner/harness/07-api-contracts.md`.
abstract final class FakePartnerScenario {
  // US-04 detail
  static const detailActive = 'detail_active';
  static const detailInactive = 'detail_inactive';
  static const detailNotFound = 'detail_not_found';
  static const detailRefresh = 'detail_refresh';

  // US-01 search
  static const searchEmpty = 'search_empty';
  static const searchResults = 'search_results';

  // US-02 register
  static const registerSaveOk = 'register_save_ok';
  static const registerDupWarning = 'register_dup_warning';
  static const registerPermissionDenied = 'register_permission_denied';

  // US-03 update
  static const updateSaveOk = 'update_save_ok';
  static const updateDupWarning = 'update_dup_warning';

  // Epic-02 US-01 status
  static const deactivateOk = 'deactivate_ok';
  static const reactivateOk = 'reactivate_ok';
  static const statusPermissionDenied = 'status_permission_denied';
  static const statusNetworkError = 'status_network_error';
}

/// Configurable [IPartnerModule] for widget and presentation tests.
final class FakePartnerModule implements IPartnerModule {
  FakePartnerModule({this.scenario = FakePartnerScenario.detailActive});

  final String scenario;

  /// Times [GetPartnerDetailQuery] was executed — useful for refresh flows.
  int detailLoadCount = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is RegisterPartnerCommand) {
      return _handleRegister<TResult>(command as RegisterPartnerCommand);
    }
    if (command is UpdatePartnerProfileCommand) {
      return _handleUpdate<TResult>(command as UpdatePartnerProfileCommand);
    }
    if (command is DeactivatePartnerCommand) {
      return _handleDeactivate<TResult>(command as DeactivatePartnerCommand);
    }
    if (command is ReactivatePartnerCommand) {
      return _handleReactivate<TResult>(command as ReactivatePartnerCommand);
    }
    if (command is DeletePartnerCommand) {
      return _handleDelete<TResult>(command as DeletePartnerCommand);
    }
    throw UnimplementedError('Unexpected command: ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetPartnerDetailQuery) {
      return _handleGetDetail<TResult>(query as GetPartnerDetailQuery);
    }
    if (query is SearchPartnersQuery) {
      return _handleSearch<TResult>(query as SearchPartnersQuery);
    }
    if (query is CheckDuplicatePartnersQuery) {
      return _handleCheckDuplicate<TResult>();
    }
    if (query is CheckDuplicatePartnersForUpdateQuery) {
      return _handleCheckDuplicateForUpdate<TResult>();
    }
    throw UnimplementedError('Unexpected query: ${query.runtimeType}');
  }

  TResult _handleRegister<TResult>(RegisterPartnerCommand command) {
    switch (scenario) {
      case FakePartnerScenario.registerPermissionDenied:
        throw ApplicationException('Permission denied');
      case FakePartnerScenario.registerDupWarning:
        if (!command.confirmDuplicate) {
          throw ApplicationException('Duplicate partners found');
        }
        return RegisterPartnerResult(
          businessPartnerId: 'partner-new-1',
          hasTaxCodeWarning: false,
        ) as TResult;
      case FakePartnerScenario.registerSaveOk:
      default:
        return RegisterPartnerResult(
          businessPartnerId: 'partner-new-1',
          hasTaxCodeWarning: false,
        ) as TResult;
    }
  }

  TResult _handleUpdate<TResult>(UpdatePartnerProfileCommand command) {
    switch (scenario) {
      case FakePartnerScenario.updateDupWarning:
        if (!command.confirmDuplicate) {
          throw ApplicationException('Duplicate partners found');
        }
        return UpdatePartnerProfileResult(
          businessPartnerId: command.partnerId,
          version: command.expectedVersion + 1,
          hasTaxCodeWarning: false,
        ) as TResult;
      case FakePartnerScenario.updateSaveOk:
      default:
        return UpdatePartnerProfileResult(
          businessPartnerId: command.partnerId,
          version: command.expectedVersion + 1,
          hasTaxCodeWarning: false,
        ) as TResult;
    }
  }

  TResult _handleGetDetail<TResult>(GetPartnerDetailQuery query) {
    detailLoadCount += 1;

    if (scenario == FakePartnerScenario.detailNotFound) {
      return null as TResult;
    }

    final status = scenario == FakePartnerScenario.detailInactive
        ? PartnerStatus.inactive
        : PartnerStatus.active;

    final displayName = switch (scenario) {
      FakePartnerScenario.detailRefresh =>
        detailLoadCount == 1 ? 'Nguyen Van An' : 'Nguyen Van B',
      _ => 'Nguyen Van An',
    };

    return PartnerDetailDto(
      id: query.partnerId,
      displayName: displayName,
      phone: '0912345678',
      roles: const {PartnerRole.customer},
      entityType: EntityType.individual,
      status: status,
      createdAt: DateTime.parse('2026-07-01T00:00:00Z'),
      updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
      version: detailLoadCount,
      createdBy: 'user-1',
      updatedBy: 'user-1',
      hasBusinessData: false,
    ) as TResult;
  }

  TResult _handleSearch<TResult>(SearchPartnersQuery query) {
    if (scenario == FakePartnerScenario.searchEmpty) {
      return const PartnerSearchResultDto(items: [], totalCount: 0) as TResult;
    }

    return PartnerSearchResultDto(
      items: [
        PartnerListItemDto(
          id: 'partner-1',
          displayName: 'Nguyen Van An',
          phone: '0912345678',
          roles: const {PartnerRole.customer},
          entityType: EntityType.individual,
          status: PartnerStatus.active,
          updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
        ),
      ],
      totalCount: 1,
    ) as TResult;
  }

  TResult _handleCheckDuplicate<TResult>() {
    if (scenario == FakePartnerScenario.registerDupWarning ||
        scenario == FakePartnerScenario.updateDupWarning) {
      return [
        const PartnerDuplicateMatchDto(
          field: PartnerDuplicateField.phone,
          businessPartnerId: 'partner-dup-1',
          displayName: 'Existing Partner',
          matchedValue: '0912345678',
        ),
      ] as TResult;
    }
    return <PartnerDuplicateMatchDto>[] as TResult;
  }

  TResult _handleCheckDuplicateForUpdate<TResult>() => _handleCheckDuplicate<TResult>();

  TResult _handleDeactivate<TResult>(DeactivatePartnerCommand command) {
    switch (scenario) {
      case FakePartnerScenario.statusPermissionDenied:
        throw ApplicationException('Permission denied');
      case FakePartnerScenario.statusNetworkError:
        throw ApplicationException('Network error');
      case FakePartnerScenario.deactivateOk:
      default:
        return DeactivatePartnerResult(
          businessPartnerId: command.partnerId,
          version: command.expectedVersion + 1,
        ) as TResult;
    }
  }

  TResult _handleReactivate<TResult>(ReactivatePartnerCommand command) {
    switch (scenario) {
      case FakePartnerScenario.statusPermissionDenied:
        throw ApplicationException('Permission denied');
      case FakePartnerScenario.statusNetworkError:
        throw ApplicationException('Network error');
      case FakePartnerScenario.reactivateOk:
      default:
        return ReactivatePartnerResult(
          businessPartnerId: command.partnerId,
          version: command.expectedVersion + 1,
        ) as TResult;
    }
  }

  TResult _handleDelete<TResult>(DeletePartnerCommand command) {
    return DeletePartnerResult(businessPartnerId: command.partnerId) as TResult;
  }
}

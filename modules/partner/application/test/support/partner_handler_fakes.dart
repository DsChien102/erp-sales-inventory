import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

Partner buildActivePersonPartner({
  String partnerId = 'p-1',
  String tenantId = 't-1',
  int version = 1,
}) {
  return Partner.reconstitute(
    id: PartnerId(partnerId),
    tenantId: TenantId(tenantId),
    partnerType: PartnerType.person,
    status: PartnerStatus.active,
    displayName: 'Nguyễn Văn A',
    roles: const [PartnerRole(role: PartnerRoleType.customer)],
    personProfile: PersonProfile(
      fullName: 'Nguyễn Văn A',
      phone: PhoneNumber('0901234567'),
    ),
    version: version,
  );
}

final class InMemoryPartnerRepository implements IPartnerRepository {
  InMemoryPartnerRepository({Map<String, Partner>? seed})
    : _partners = Map.of(seed ?? {});

  final Map<String, Partner> _partners;

  String _key(TenantId tenantId, PartnerId partnerId) =>
      '${tenantId.value}:${partnerId.value}';

  @override
  Future<Partner?> findById({
    required TenantId tenantId,
    required PartnerId partnerId,
  }) async {
    return _partners[_key(tenantId, partnerId)];
  }

  @override
  Future<void> add(Partner partner) async {
    _partners[_key(partner.tenantId, partner.id)] = partner;
  }

  @override
  Future<void> save(Partner partner, {required int expectedVersion}) async {
    _partners[_key(partner.tenantId, partner.id)] = partner;
  }
}

final class RecordingPartnerCommandGateway implements IPartnerCommandGateway {
  CreatePartnerCommand? lastCreate;
  DeactivatePartnerCommand? lastDeactivate;
  ReactivatePartnerCommand? lastReactivate;
  SoftDeletePartnerCommand? lastSoftDelete;
  UpdatePartnerProfileCommand? lastUpdateProfile;

  @override
  Future<AddOrganizationContactResult> addOrganizationContact(
    AddOrganizationContactCommand command,
  ) async {
    return AddOrganizationContactResult(
      organizationPartnerId: command.organizationPartnerId,
      personPartnerId: command.personPartnerId ?? 'p-contact-1',
    );
  }

  @override
  Future<CreatePartnerResult> createPartner(CreatePartnerCommand command) async {
    lastCreate = command;
    return const CreatePartnerResult(partnerId: 'p-new-1');
  }

  @override
  Future<DeactivatePartnerResult> deactivatePartner(
    DeactivatePartnerCommand command,
  ) async {
    lastDeactivate = command;
    return DeactivatePartnerResult(
      partnerId: command.partnerId,
      expectedVersion: command.expectedVersion + 1,
    );
  }

  @override
  Future<ReactivatePartnerResult> reactivatePartner(
    ReactivatePartnerCommand command,
  ) async {
    lastReactivate = command;
    return ReactivatePartnerResult(
      partnerId: command.partnerId,
      expectedVersion: command.expectedVersion + 1,
    );
  }

  @override
  Future<void> removeOrganizationContact(
    RemoveOrganizationContactCommand command,
  ) async {}

  @override
  Future<SoftDeletePartnerResult> softDeletePartner(
    SoftDeletePartnerCommand command,
  ) async {
    lastSoftDelete = command;
    return SoftDeletePartnerResult(
      partnerId: command.partnerId,
      expectedVersion: command.expectedVersion + 1,
    );
  }

  @override
  Future<TransformPartnerResult> transformPersonToOrganization(
    TransformPersonToOrganizationCommand command,
  ) async {
    return TransformPartnerResult(partnerId: command.partnerId);
  }

  @override
  Future<void> updateOrganizationContact(
    UpdateOrganizationContactCommand command,
  ) async {}

  @override
  Future<UpdatePartnerProfileResult> updatePartnerProfile(
    UpdatePartnerProfileCommand command,
  ) async {
    lastUpdateProfile = command;
    return UpdatePartnerProfileResult(
      partnerId: command.partnerId,
      expectedVersion: command.expectedVersion + 1,
    );
  }
}

final class RecordingPartnerReadGateway implements IPartnerReadGateway {
  SearchPartnersQuery? lastSearch;
  GetPartnerDetailQuery? lastDetail;
  CheckDeleteEligibilityQuery? lastDeleteEligibility;

  DeleteEligibilityDto deleteEligibility = const DeleteEligibilityDto(
    eligible: true,
  );

  PartnerSearchResultDto searchResult = const PartnerSearchResultDto(
    items: [],
    total: 0,
    page: 1,
    limit: 20,
  );

  PartnerDetailDto? detailResult;

  PartnerHistoryResultDto historyResult = const PartnerHistoryResultDto(
    items: [],
    total: 0,
    page: 1,
    limit: 20,
  );

  GetPartnerHistoryQuery? lastHistory;

  @override
  Future<DeleteEligibilityDto> checkDeleteEligibility(
    CheckDeleteEligibilityQuery query,
  ) async {
    lastDeleteEligibility = query;
    return deleteEligibility;
  }

  @override
  Future<PartnerDetailDto> getPartnerDetail(GetPartnerDetailQuery query) async {
    lastDetail = query;
    return detailResult ??
        PartnerDetailDto(
          partnerId: query.partnerId,
          partnerType: PartnerType.person,
          status: PartnerStatus.active,
          displayName: 'Nguyễn Văn A',
          roles: const [PartnerRoleType.customer],
          expectedVersion: 1,
          availableActions: const [PartnerAvailableAction.update],
        );
  }

  @override
  Future<PartnerHistoryResultDto> getPartnerHistory(
    GetPartnerHistoryQuery query,
  ) async {
    lastHistory = query;
    return historyResult;
  }

  @override
  Future<PartnerSearchResultDto> searchPartners(
    SearchPartnersQuery query,
  ) async {
    lastSearch = query;
    return searchResult;
  }
}

final class RecordingPartnerDuplicateChecker implements IPartnerDuplicateChecker {
  CheckDuplicatePartnersQuery? lastQuery;
  List<PartnerDuplicateMatchDto> matches = const [];

  @override
  Future<List<PartnerDuplicateMatchDto>> checkDuplicates(
    CheckDuplicatePartnersQuery query,
  ) async {
    lastQuery = query;
    return matches;
  }
}

final class RecordingPartnerHistoryWriteGateway
    implements IPartnerHistoryWriteGateway {
  RecordPartnerHistoryCommand? lastCommand;

  @override
  Future<void> upsertPartnerHistory(RecordPartnerHistoryCommand command) async {
    lastCommand = command;
  }
}

final class RecordingPartnerModule implements IPartnerModule {
  final List<ICommand<dynamic>> commands = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    return null as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnsupportedError('RecordingPartnerModule: query not supported');
  }
}

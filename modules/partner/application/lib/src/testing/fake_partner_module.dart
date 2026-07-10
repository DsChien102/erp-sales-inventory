import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../contracts/i_partner_module.dart';
import '../partner/commands/add_organization_contact/add_organization_contact_command.dart';
import '../partner/commands/add_organization_contact/add_organization_contact_result.dart';
import '../partner/queries/check_delete_eligibility/check_delete_eligibility_query.dart';
import '../partner/queries/check_delete_eligibility/delete_eligibility_dto.dart';
import '../partner/queries/check_duplicate/check_duplicate_partners_query.dart';
import '../partner/queries/check_duplicate/partner_duplicate_match_dto.dart';
import '../partner/queries/check_duplicate/partner_duplicate_match_field.dart';
import '../partner/queries/check_duplicate/partner_duplicate_match_level.dart';
import '../partner/commands/create_partner/create_partner_command.dart';
import '../partner/commands/create_partner/create_partner_result.dart';
import '../partner/commands/deactivate_partner/deactivate_partner_command.dart';
import '../partner/commands/deactivate_partner/deactivate_partner_result.dart';
import '../partner/queries/get_partner_detail/get_partner_detail_query.dart';
import '../partner/queries/get_partner_detail/organization_profile_dto.dart';
import '../partner/queries/get_partner_detail/partner_available_action.dart';
import '../partner/queries/get_partner_detail/partner_contact_dto.dart';
import '../partner/queries/get_partner_detail/partner_detail_dto.dart';
import '../partner/queries/get_partner_detail/person_profile_dto.dart';
import '../partner/shared/invoice_profile_input.dart';
import '../partner/shared/delivery_address_input.dart';
import '../partner/commands/reactivate_partner/reactivate_partner_command.dart';
import '../partner/commands/reactivate_partner/reactivate_partner_result.dart';
import '../partner/commands/remove_organization_contact/remove_organization_contact_command.dart';
import '../partner/queries/search_partners/partner_list_item_dto.dart';
import '../partner/queries/search_partners/partner_search_result_dto.dart';
import '../partner/queries/search_partners/search_partners_query.dart';
import '../partner/commands/soft_delete_partner/soft_delete_partner_command.dart';
import '../partner/commands/soft_delete_partner/soft_delete_partner_result.dart';
import '../partner/commands/transform_to_organization/transform_partner_result.dart';
import '../partner/commands/transform_to_organization/transform_person_to_organization_command.dart';
import '../partner/commands/update_organization_contact/update_organization_contact_command.dart';
import '../partner/commands/update_partner_profile/update_partner_profile_command.dart';
import '../partner/commands/update_partner_profile/update_partner_profile_result.dart';
import '../partner_history/queries/get_partner_history/get_partner_history_query.dart';
import '../partner_history/queries/get_partner_history/partner_history_item_dto.dart';
import '../partner_history/queries/get_partner_history/partner_history_result_dto.dart';
import '../partner_history/commands/record_partner_history/record_partner_history_command.dart';
import '../partner_history/shared/partner_transaction_type.dart';
import '../shared/partner_blocked_codes.dart';
import '../shared/partner_blocked_exception.dart';

/// Named fake scenarios from harness/07-api-contracts.md.
enum FakePartnerScenario {
  defaultMixed,
  createPersonOk,
  createOrganizationOk,
  createDupWarning,
  createExactDuplicate,
  createDupConfirmed,
  createValidationError,
  createPermissionDenied,
  searchEmpty,
  searchMixedTypes,
  searchFilteredStatus,
  detailPersonActive,
  detailOrganizationWithContacts,
  detailDeleted,
  historyEmpty,
  historyMixed,
  historyNoSourcePermission,
}
/// In-memory partner module for FE/widget tests.
final class FakePartnerModule implements IPartnerModule {
  FakePartnerModule({this.scenario = FakePartnerScenario.defaultMixed});

  final FakePartnerScenario scenario;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return switch (command) {
      CreatePartnerCommand c => _handleCreatePartner<TResult>(c),
      UpdatePartnerProfileCommand c => _handleUpdateProfile<TResult>(c),
      TransformPersonToOrganizationCommand c =>
        _handleTransform<TResult>(c),
      AddOrganizationContactCommand c => _handleAddContact<TResult>(c),
      UpdateOrganizationContactCommand _ =>
        Future.value(null as TResult),
      RemoveOrganizationContactCommand _ =>
        Future.value(null as TResult),
      DeactivatePartnerCommand c => _handleDeactivate<TResult>(c),
      ReactivatePartnerCommand c => _handleReactivate<TResult>(c),
      SoftDeletePartnerCommand c => _handleSoftDelete<TResult>(c),
      RecordPartnerHistoryCommand _ => Future.value(null as TResult),
      _ => throw UnsupportedError(
        'FakePartnerModule: unsupported command ${command.runtimeType}',
      ),
    };
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return switch (query) {
      SearchPartnersQuery q => _handleSearchPartners<TResult>(q),
      GetPartnerDetailQuery q => _handleGetDetail<TResult>(q),
      CheckDuplicatePartnersQuery q => _handleCheckDuplicate<TResult>(q),
      CheckDeleteEligibilityQuery q => _handleDeleteEligibility<TResult>(q),
      GetPartnerHistoryQuery q => _handleGetHistory<TResult>(q),
      _ => throw UnsupportedError(
        'FakePartnerModule: unsupported query ${query.runtimeType}',
      ),
    };
  }

  Future<TResult> _handleCreatePartner<TResult>(CreatePartnerCommand command) {
    switch (scenario) {
      case FakePartnerScenario.createValidationError:
        throw const PartnerBlockedException(
          PartnerBlockedCodes.validationError,
          message: 'Invalid partner payload',
        );
      case FakePartnerScenario.createPermissionDenied:
        throw const PartnerBlockedException(
          PartnerBlockedCodes.noPermission,
          message: 'Missing partner.create',
        );
      case FakePartnerScenario.createDupWarning:
        if (!command.confirmDuplicate) {
          throw const PartnerBlockedException(
            PartnerBlockedCodes.duplicateWarning,
            message: 'Duplicate partner detected',
          );
        }
        return Future.value(
          CreatePartnerResult(partnerId: 'p-new-dup') as TResult,
        );
      case FakePartnerScenario.createOrganizationOk:
        return Future.value(
          const CreatePartnerResult(partnerId: 'p-new-2') as TResult,
        );
      case FakePartnerScenario.createPersonOk:
      case FakePartnerScenario.createDupConfirmed:
      case FakePartnerScenario.defaultMixed:
        return Future.value(
          const CreatePartnerResult(partnerId: 'p-new-1') as TResult,
        );
      default:
        return Future.value(
          CreatePartnerResult(
            partnerId: command.partnerType == PartnerType.organization
                ? 'p-new-2'
                : 'p-new-1',
          ) as TResult,
        );
    }
  }

  Future<TResult> _handleUpdateProfile<TResult>(
    UpdatePartnerProfileCommand command,
  ) {
    return Future.value(
      UpdatePartnerProfileResult(
        partnerId: command.partnerId,
        expectedVersion: command.expectedVersion + 1,
      ) as TResult,
    );
  }

  Future<TResult> _handleTransform<TResult>(
    TransformPersonToOrganizationCommand command,
  ) {
    return Future.value(
      TransformPartnerResult(partnerId: command.partnerId) as TResult,
    );
  }

  Future<TResult> _handleAddContact<TResult>(
    AddOrganizationContactCommand command,
  ) {
    return Future.value(
      AddOrganizationContactResult(
        organizationPartnerId: command.organizationPartnerId,
        personPartnerId: command.personPartnerId ?? 'p-contact-new',
      ) as TResult,
    );
  }

  Future<TResult> _handleDeactivate<TResult>(DeactivatePartnerCommand command) {
    return Future.value(
      DeactivatePartnerResult(
        partnerId: command.partnerId,
        expectedVersion: command.expectedVersion + 1,
      ) as TResult,
    );
  }

  Future<TResult> _handleReactivate<TResult>(ReactivatePartnerCommand command) {
    return Future.value(
      ReactivatePartnerResult(
        partnerId: command.partnerId,
        expectedVersion: command.expectedVersion + 1,
      ) as TResult,
    );
  }

  Future<TResult> _handleSoftDelete<TResult>(SoftDeletePartnerCommand command) {
    return Future.value(
      SoftDeletePartnerResult(
        partnerId: command.partnerId,
        expectedVersion: command.expectedVersion + 1,
      ) as TResult,
    );
  }

  Future<TResult> _handleSearchPartners<TResult>(SearchPartnersQuery query) {
    switch (scenario) {
      case FakePartnerScenario.searchEmpty:
        return Future.value(
          const PartnerSearchResultDto(
            items: [],
            page: 1,
            limit: 20,
            total: 0,
          ) as TResult,
        );
      case FakePartnerScenario.searchFilteredStatus:
        return Future.value(
          PartnerSearchResultDto(
            items: [
              _listItem(
                partnerId: 'p-inactive-1',
                displayName: 'Đối tác ngừng hoạt động',
                partnerType: PartnerType.person,
                status: PartnerStatus.inactive,
              ),
            ],
            page: query.page,
            limit: query.limit,
            total: 1,
          ) as TResult,
        );
      case FakePartnerScenario.searchMixedTypes:
      case FakePartnerScenario.defaultMixed:
        return Future.value(
          PartnerSearchResultDto(
            items: [
              _listItem(
                partnerId: 'p-person-1',
                displayName: 'Nguyễn Văn A',
                partnerType: PartnerType.person,
                status: PartnerStatus.active,
              ),
              _listItem(
                partnerId: 'p-org-1',
                displayName: 'Công ty ABC',
                partnerType: PartnerType.organization,
                status: PartnerStatus.active,
                roles: const [PartnerRoleType.supplier],
              ),
            ],
            page: query.page,
            limit: query.limit,
            total: 2,
          ) as TResult,
        );
      default:
        return Future.value(
          PartnerSearchResultDto(
            items: const [],
            page: query.page,
            limit: query.limit,
            total: 0,
          ) as TResult,
        );
    }
  }

  Future<TResult> _handleGetDetail<TResult>(GetPartnerDetailQuery query) {
    switch (scenario) {
      case FakePartnerScenario.detailDeleted:
        throw const PartnerBlockedException(
          PartnerBlockedCodes.notFound,
          message: 'Partner not found',
        );
      case FakePartnerScenario.detailOrganizationWithContacts:
        return Future.value(
          PartnerDetailDto(
            partnerId: query.partnerId,
            partnerType: PartnerType.organization,
            status: PartnerStatus.active,
            displayName: 'Công ty ABC',
            roles: const [PartnerRoleType.customer, PartnerRoleType.supplier],
            availableActions: const [
              PartnerAvailableAction.update,
              PartnerAvailableAction.manageContacts,
              PartnerAvailableAction.deactivate,
              PartnerAvailableAction.viewHistory,
            ],
            expectedVersion: 1,
            createdAt: DateTime.utc(2026, 1, 15, 8, 30),
            updatedAt: DateTime.utc(2026, 3, 1, 10, 0),
            organizationProfile: const OrganizationProfileDto(
              organizationType: OrganizationType.company,
              organizationName: 'Công ty ABC',
              phone: '0901234567',
              email: 'contact@abc.vn',
              taxCode: '0312345678',
              invoice: InvoiceProfileInput(
                invoiceName: 'Công ty ABC',
                invoiceEmail: 'accounting@abc.vn',
                invoiceAddress: '1 Lê Lợi, Quận 1, TP.HCM',
              ),
            ),
            contacts: const [
              PartnerContactDto(
                personPartnerId: 'p-contact-1',
                displayName: 'Trần Thị B',
                phone: '0907654321',
                contactRole: 'Kế toán',
                isPrimary: true,
              ),
            ],
          ) as TResult,
        );
      case FakePartnerScenario.detailPersonActive:
      case FakePartnerScenario.defaultMixed:
        return Future.value(
          PartnerDetailDto(
            partnerId: query.partnerId,
            partnerType: PartnerType.person,
            status: PartnerStatus.active,
            displayName: 'Nguyễn Văn A',
            roles: const [PartnerRoleType.customer],
            availableActions: const [
              PartnerAvailableAction.update,
              PartnerAvailableAction.transform,
              PartnerAvailableAction.deactivate,
              PartnerAvailableAction.viewHistory,
            ],
            expectedVersion: 1,
            createdAt: DateTime.utc(2026, 1, 10, 9, 0),
            updatedAt: DateTime.utc(2026, 2, 20, 14, 15),
            personProfile: PersonProfileDto(
              title: PersonTitle('Ông'),
              fullName: 'Nguyễn Văn A',
              phone: '0901234567',
              email: 'nguyenvana@example.com',
              taxCode: '0101234567',
              invoice: InvoiceProfileInput(
                invoiceName: 'Nguyễn Văn A',
                invoiceEmail: 'invoice@example.com',
                invoiceAddress: '12 Nguyễn Huệ, Quận 1, TP.HCM',
              ),
              delivery: DeliveryAddressInput(
                province: 'Thành phố Hồ Chí Minh',
                commune: 'Phường Bến Nghé',
                address: '12 Nguyễn Huệ',
              ),
            ),
          ) as TResult,
        );
      default:
        return Future.value(
          PartnerDetailDto(
            partnerId: query.partnerId,
            partnerType: PartnerType.person,
            status: PartnerStatus.active,
            displayName: 'Partner',
            roles: const [PartnerRoleType.customer],
            availableActions: const [PartnerAvailableAction.update],
            expectedVersion: 1,
            personProfile: const PersonProfileDto(
              fullName: 'Partner',
              phone: '0900000000',
            ),
          ) as TResult,
        );
    }
  }

  Future<TResult> _handleCheckDuplicate<TResult>(
    CheckDuplicatePartnersQuery query,
  ) {
    if (scenario == FakePartnerScenario.createDupWarning ||
        scenario == FakePartnerScenario.createExactDuplicate ||
        scenario == FakePartnerScenario.createDupConfirmed) {
      final matches = [
        PartnerDuplicateMatchDto(
          partnerId: 'p-dup-1',
          displayName: 'Nguyễn Văn Trùng',
          matchedField: PartnerDuplicateMatchField.phone,
          matchLevel: scenario == FakePartnerScenario.createExactDuplicate
              ? PartnerDuplicateMatchLevel.exact
              : PartnerDuplicateMatchLevel.possible,
          partnerType: PartnerType.person,
          matchedValue: '0901234567',
        ),
      ];
      final filtered = query.excludePartnerId == null
          ? matches
          : matches
                .where((m) => m.partnerId != query.excludePartnerId)
                .toList(growable: false);
      return Future.value(filtered as TResult);
    }
    return Future.value(<PartnerDuplicateMatchDto>[] as TResult);
  }

  Future<TResult> _handleDeleteEligibility<TResult>(
    CheckDeleteEligibilityQuery query,
  ) {
    return Future.value(
      const DeleteEligibilityDto(eligible: true) as TResult,
    );
  }

  Future<TResult> _handleGetHistory<TResult>(GetPartnerHistoryQuery query) {
    switch (scenario) {
      case FakePartnerScenario.historyEmpty:
        return Future.value(
          PartnerHistoryResultDto(
            items: const [],
            page: query.page,
            limit: query.limit,
            total: 0,
          ) as TResult,
        );
      case FakePartnerScenario.historyNoSourcePermission:
        return Future.value(
          PartnerHistoryResultDto(
            items: [
              _historyItem(canOpenSource: false),
            ],
            page: query.page,
            limit: query.limit,
            total: 1,
          ) as TResult,
        );
      case FakePartnerScenario.historyMixed:
      case FakePartnerScenario.defaultMixed:
        return Future.value(
          PartnerHistoryResultDto(
            items: [
              _historyItem(
                historyId: 'h-sales-1',
                transactionType: PartnerTransactionType.salesOrder,
                sourceModule: 'sales',
                referenceCode: 'SO-001',
              ),
              _historyItem(
                historyId: 'h-inv-1',
                transactionType: PartnerTransactionType.inventoryInbound,
                sourceModule: 'inventory',
                referenceCode: 'IN-001',
                role: PartnerRoleType.supplier,
              ),
            ],
            page: query.page,
            limit: query.limit,
            total: 2,
          ) as TResult,
        );
      default:
        return Future.value(
          PartnerHistoryResultDto(
            items: const [],
            page: query.page,
            limit: query.limit,
            total: 0,
          ) as TResult,
        );
    }
  }

  static PartnerListItemDto _listItem({
    required String partnerId,
    required String displayName,
    required PartnerType partnerType,
    required PartnerStatus status,
    List<PartnerRoleType> roles = const [PartnerRoleType.customer],
  }) {
    return PartnerListItemDto(
      partnerId: partnerId,
      displayName: displayName,
      partnerType: partnerType,
      status: status,
      roles: roles,
      phone: '0901234567',
    );
  }

  static PartnerHistoryItemDto _historyItem({
    String historyId = 'h-1',
    PartnerRoleType role = PartnerRoleType.customer,
    PartnerTransactionType transactionType =
        PartnerTransactionType.salesOrder,
    String sourceModule = 'sales',
    String referenceCode = 'SO-001',
    bool canOpenSource = true,
  }) {
    return PartnerHistoryItemDto(
      historyId: historyId,
      role: role,
      transactionType: transactionType,
      sourceModule: sourceModule,
      sourceId: 'src-$historyId',
      referenceCode: referenceCode,
      transactionDate: DateTime(2026, 7, 1),
      status: 'completed',
      amount: 1_000_000,
      currency: 'VND',
      canOpenSource: canOpenSource,
    );
  }
}

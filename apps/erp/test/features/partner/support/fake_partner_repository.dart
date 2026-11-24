import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/partner/data/models/partner_action_log.dart';
import 'package:erp/features/partner/data/models/partner_detail.dart';
import 'package:erp/features/partner/data/models/partner_duplicate_match.dart';
import 'package:erp/features/partner/data/models/partner_enums.dart';
import 'package:erp/features/partner/data/models/partner_error_codes.dart';
import 'package:erp/features/partner/data/models/partner_inputs.dart';
import 'package:erp/features/partner/data/models/partner_list_item.dart';
import 'package:erp/features/partner/data/models/partner_write_results.dart';
import 'package:erp/features/partner/data/models/person_title.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

final _unusedRpc = SupabaseRpc(_UnusedClient());

/// Kịch bản đặt tên cho [FakePartnerRepository] (chuyển từ `FakePartnerScenario` của module cũ).
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
  searchByContact,
  detailPersonActive,
  detailPersonPrimaryContact,
  detailOrganizationWithContacts,
  detailDeleted,
  historyEmpty,
  historyMixed,
  historyNoSourcePermission,
  actionLogsEmpty,
  actionLogsMixed,
  transformPermissionDenied,
  transformStateChanged,
  transformDupWarning,
  deactivatePermissionDenied,
  deactivateStateChanged,
  deactivateInvalidStatus,
  reactivatePermissionDenied,
  reactivateStateChanged,
  reactivateInvalidStatus,
  softDeletePermissionDenied,
  softDeleteStateChanged,
  softDeleteHasTransactions,
  softDeleteNotEligible,
}

/// `PartnerRepository` trong bộ nhớ cho test cubit / widget (thay `FakePartnerModule`).
/// Mọi method public đều bị ghi đè; không method nào chạm RPC thật.
class FakePartnerRepository extends PartnerRepository {
  FakePartnerRepository({this.scenario = FakePartnerScenario.defaultMixed})
    : super(
        rpc: _unusedRpc,
        tenantId: () async => 'tenant-1',
        actorId: () async => 'user-1',
      );

  final FakePartnerScenario scenario;

  /// Tên method đã gọi, theo thứ tự.
  final calls = <String>[];

  final Map<String, PartnerStatus> _statusOverrides = {};
  final Map<String, int> _versionOverrides = {};

  static AppException _blocked(String code, String message) =>
      AppException(code, serverMessage: message);

  @override
  Future<PartnerSearchResultDto> search({
    String? query,
    PartnerType? partnerType,
    PartnerRoleType? role,
    bool requireBothRoles = false,
    bool requireAnyRole = false,
    PartnerStatus? status,
    int? updatedWithinDays,
    int page = 1,
    int limit = 20,
    String? sort,
  }) async {
    calls.add('search');
    switch (scenario) {
      case FakePartnerScenario.searchEmpty:
        return const PartnerSearchResultDto(items: [], page: 1, limit: 20, total: 0);
      case FakePartnerScenario.searchFilteredStatus:
        return PartnerSearchResultDto(
          items: [
            _listItem(
              partnerId: 'p-inactive-1',
              displayName: 'Đối tác ngừng hoạt động',
              partnerType: PartnerType.person,
              status: PartnerStatus.inactive,
            ),
          ],
          page: page,
          limit: limit,
          total: 1,
        );
      case FakePartnerScenario.searchByContact:
        return PartnerSearchResultDto(
          items: [
            _listItem(
              partnerId: 'p-org-contact-match',
              displayName: 'Công ty ABC',
              partnerType: PartnerType.organization,
              status: PartnerStatus.active,
              roles: const [PartnerRoleType.customer],
            ),
          ],
          page: page,
          limit: limit,
          total: 1,
        );
      case FakePartnerScenario.searchMixedTypes:
      case FakePartnerScenario.defaultMixed:
        return PartnerSearchResultDto(
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
          page: page,
          limit: limit,
          total: 2,
        );
      default:
        return PartnerSearchResultDto(items: const [], page: page, limit: limit, total: 0);
    }
  }

  @override
  Future<PartnerDetailDto> getDetail(String partnerId) async {
    calls.add('getDetail');
    final PartnerDetailDto dto;
    switch (scenario) {
      case FakePartnerScenario.detailDeleted:
        throw _blocked(PartnerErrorCodes.notFound, 'Partner not found');
      case FakePartnerScenario.detailOrganizationWithContacts:
        dto = PartnerDetailDto(
          partnerId: partnerId,
          partnerType: PartnerType.organization,
          status: PartnerStatus.active,
          displayName: 'Công ty ABC',
          roles: const [PartnerRoleType.customer, PartnerRoleType.supplier],
          availableActions: const [
            PartnerAvailableAction.update,
            PartnerAvailableAction.manageContacts,
            PartnerAvailableAction.deactivate,
            PartnerAvailableAction.delete,
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
              title: 'Chị',
              phone: '0907654321',
              phone2: '0281111222',
              email: 'tranthib@abc.vn',
              contactRole: 'Kế toán',
              isPrimary: true,
            ),
          ],
        );
      case FakePartnerScenario.detailPersonActive:
      case FakePartnerScenario.detailPersonPrimaryContact:
      case FakePartnerScenario.defaultMixed:
      case FakePartnerScenario.softDeleteNotEligible:
      case FakePartnerScenario.softDeleteHasTransactions:
        dto = PartnerDetailDto(
          partnerId: partnerId,
          partnerType: PartnerType.person,
          status: PartnerStatus.active,
          displayName: 'Nguyễn Văn A',
          roles: const [PartnerRoleType.customer],
          availableActions: const [
            PartnerAvailableAction.update,
            PartnerAvailableAction.transform,
            PartnerAvailableAction.deactivate,
            PartnerAvailableAction.delete,
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
            invoice: const InvoiceProfileInput(
              invoiceName: 'Nguyễn Văn A',
              invoiceEmail: 'invoice@example.com',
              invoiceAddress: '12 Nguyễn Huệ, Quận 1, TP.HCM',
            ),
            delivery: const DeliveryAddressInput(
              province: 'Thành phố Hồ Chí Minh',
              commune: 'Phường Bến Nghé',
              address: '12 Nguyễn Huệ',
            ),
          ),
          primaryContactOrganizationId: scenario == FakePartnerScenario.detailPersonPrimaryContact
              ? 'p-org-primary'
              : null,
          primaryContactOrganizationName: scenario == FakePartnerScenario.detailPersonPrimaryContact
              ? 'Công ty Minh Phát'
              : null,
        );
      default:
        dto = PartnerDetailDto(
          partnerId: partnerId,
          partnerType: PartnerType.person,
          status: PartnerStatus.active,
          displayName: 'Partner',
          roles: const [PartnerRoleType.customer],
          availableActions: const [PartnerAvailableAction.update],
          expectedVersion: 1,
          personProfile: const PersonProfileDto(fullName: 'Partner', phone: '0900000000'),
        );
    }
    return _applyStatusOverride(dto);
  }

  @override
  Future<List<PartnerDuplicateMatchDto>> checkDuplicates({
    String? phone,
    String? email,
    String? taxCode,
    String? name,
    String? excludePartnerId,
  }) async {
    calls.add('checkDuplicates');
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
      return excludePartnerId == null
          ? matches
          : matches.where((m) => m.partnerId != excludePartnerId).toList(growable: false);
    }
    return <PartnerDuplicateMatchDto>[];
  }

  @override
  Future<DeleteEligibilityDto> checkDeleteEligibility(String partnerId) async {
    calls.add('checkDeleteEligibility');
    if (scenario == FakePartnerScenario.softDeleteNotEligible ||
        scenario == FakePartnerScenario.softDeleteHasTransactions) {
      return const DeleteEligibilityDto(eligible: false, reason: 'HAS_TRANSACTIONS');
    }
    return const DeleteEligibilityDto(eligible: true);
  }

  @override
  Future<PartnerActionLogPage> getActionLogs(
    String partnerId, {
    int page = 1,
    int limit = 20,
  }) async {
    calls.add('getActionLogs');
    switch (scenario) {
      case FakePartnerScenario.actionLogsEmpty:
        return PartnerActionLogPage(items: const [], page: page, limit: limit, total: 0);
      case FakePartnerScenario.actionLogsMixed:
      case FakePartnerScenario.defaultMixed:
        return PartnerActionLogPage(
          items: [
            _actionLog(
              actionLogId: 'al-1',
              actionType: PartnerActionType.addContact,
              createdAt: DateTime(2026, 7, 16, 18, 26),
            ),
            _actionLog(
              actionLogId: 'al-2',
              actionType: PartnerActionType.update,
              createdAt: DateTime(2026, 7, 15, 23, 26),
              beforeState: const {
                'display_name': 'Nguyễn Văn A',
                'person_profile': {'phone': '0901234567', 'tax_code': null},
              },
              afterState: const {
                'display_name': 'Nguyễn Văn A',
                'person_profile': {'phone': '0907654321', 'tax_code': '2201018022'},
              },
            ),
            _actionLog(
              actionLogId: 'al-3',
              actionType: PartnerActionType.create,
              createdAt: DateTime(2026, 7, 14, 23, 26),
            ),
          ],
          page: page,
          limit: limit,
          total: 3,
        );
      default:
        return PartnerActionLogPage(items: const [], page: page, limit: limit, total: 0);
    }
  }

  @override
  Future<CreatePartnerResult> create({
    required PartnerType partnerType,
    required List<PartnerRoleType> roles,
    PersonProfileInput? personProfile,
    OrganizationProfileInput? organizationProfile,
    PersonProfileInput? organizationPrimaryContact,
    bool confirmDuplicate = false,
  }) async {
    calls.add('create');
    switch (scenario) {
      case FakePartnerScenario.createValidationError:
        throw _blocked(PartnerErrorCodes.validationError, 'Invalid partner payload');
      case FakePartnerScenario.createPermissionDenied:
        throw _blocked(PartnerErrorCodes.noPermission, 'Missing partner.create');
      case FakePartnerScenario.createDupWarning:
        if (!confirmDuplicate) {
          throw _blocked(PartnerErrorCodes.duplicateWarning, 'Duplicate partner detected');
        }
        return const CreatePartnerResult(partnerId: 'p-new-dup');
      case FakePartnerScenario.createOrganizationOk:
        return const CreatePartnerResult(partnerId: 'p-new-2');
      case FakePartnerScenario.createPersonOk:
      case FakePartnerScenario.createDupConfirmed:
      case FakePartnerScenario.defaultMixed:
        return const CreatePartnerResult(partnerId: 'p-new-1');
      default:
        return CreatePartnerResult(
          partnerId: partnerType == PartnerType.organization ? 'p-new-2' : 'p-new-1',
        );
    }
  }

  @override
  Future<UpdatePartnerProfileResult> update({
    required String partnerId,
    required int expectedVersion,
    required List<PartnerRoleType> roles,
    PersonProfileInput? personProfile,
    OrganizationProfileInput? organizationProfile,
    bool confirmDuplicate = false,
  }) async {
    calls.add('update');
    return UpdatePartnerProfileResult(
      partnerId: partnerId,
      expectedVersion: expectedVersion + 1,
    );
  }

  @override
  Future<String> transformToOrganization({
    required String partnerId,
    required int expectedVersion,
    required OrganizationProfileInput organizationProfile,
    bool confirmDuplicate = false,
  }) async {
    calls.add('transformToOrganization');
    switch (scenario) {
      case FakePartnerScenario.transformPermissionDenied:
        throw _blocked(PartnerErrorCodes.noPermission, 'Missing partner.transform');
      case FakePartnerScenario.transformStateChanged:
        throw _blocked(PartnerErrorCodes.stateChanged, 'Partner version mismatch');
      case FakePartnerScenario.transformDupWarning:
        if (!confirmDuplicate) {
          throw _blocked(
            PartnerErrorCodes.duplicateWarning,
            'PostgrestException(message: {"code":"DUPLICATE_WARNING","field":"phone"}, code: P0001)',
          );
        }
        return partnerId;
      default:
        return partnerId;
    }
  }

  @override
  Future<AddOrganizationContactResult> addContact({
    required String organizationPartnerId,
    String? personPartnerId,
    PersonProfileInput? newPersonProfile,
    String? contactRole,
    bool isPrimary = false,
  }) async {
    calls.add('addContact');
    return AddOrganizationContactResult(
      organizationPartnerId: organizationPartnerId,
      personPartnerId: personPartnerId ?? 'p-contact-new',
    );
  }

  @override
  Future<void> updateContact({
    required String organizationPartnerId,
    required String personPartnerId,
    String? contactRole,
    bool? isPrimary,
    String? note,
    PersonProfileInput? personProfile,
  }) async {
    calls.add('updateContact');
  }

  @override
  Future<void> removeContact({
    required String organizationPartnerId,
    required String personPartnerId,
  }) async {
    calls.add('removeContact');
  }

  @override
  Future<PartnerVersionResult> deactivate(
    String partnerId, {
    required int expectedVersion,
    String? reason,
  }) async {
    calls.add('deactivate');
    switch (scenario) {
      case FakePartnerScenario.deactivatePermissionDenied:
        throw _blocked(PartnerErrorCodes.noPermission, 'Missing partner.status.manage');
      case FakePartnerScenario.deactivateStateChanged:
        throw _blocked(PartnerErrorCodes.stateChanged, 'Partner version mismatch');
      case FakePartnerScenario.deactivateInvalidStatus:
        throw _blocked(PartnerErrorCodes.invalidStatus, 'Partner is not active');
      default:
        break;
    }
    return _changeStatus(partnerId, expectedVersion, PartnerStatus.inactive);
  }

  @override
  Future<PartnerVersionResult> reactivate(
    String partnerId, {
    required int expectedVersion,
    String? reason,
  }) async {
    calls.add('reactivate');
    switch (scenario) {
      case FakePartnerScenario.reactivatePermissionDenied:
        throw _blocked(PartnerErrorCodes.noPermission, 'Missing partner.status.manage');
      case FakePartnerScenario.reactivateStateChanged:
        throw _blocked(PartnerErrorCodes.stateChanged, 'Partner version mismatch');
      case FakePartnerScenario.reactivateInvalidStatus:
        throw _blocked(PartnerErrorCodes.invalidStatus, 'Partner is not inactive');
      default:
        break;
    }
    return _changeStatus(partnerId, expectedVersion, PartnerStatus.active);
  }

  @override
  Future<PartnerVersionResult> softDelete(
    String partnerId, {
    required int expectedVersion,
    String? reason,
  }) async {
    calls.add('softDelete');
    switch (scenario) {
      case FakePartnerScenario.softDeletePermissionDenied:
        throw _blocked(PartnerErrorCodes.noPermission, 'Missing partner.delete');
      case FakePartnerScenario.softDeleteStateChanged:
        throw _blocked(PartnerErrorCodes.stateChanged, 'Partner version mismatch');
      case FakePartnerScenario.softDeleteHasTransactions:
        throw _blocked(PartnerErrorCodes.hasTransactions, 'Partner has transactions');
      default:
        break;
    }
    return _changeStatus(partnerId, expectedVersion, PartnerStatus.deleted);
  }

  PartnerVersionResult _changeStatus(String partnerId, int expectedVersion, PartnerStatus status) {
    final nextVersion = expectedVersion + 1;
    _statusOverrides[partnerId] = status;
    _versionOverrides[partnerId] = nextVersion;
    return PartnerVersionResult(partnerId: partnerId, expectedVersion: nextVersion);
  }

  PartnerDetailDto _applyStatusOverride(PartnerDetailDto dto) {
    final status = _statusOverrides[dto.partnerId];
    if (status == null) return dto;

    final version = _versionOverrides[dto.partnerId] ?? dto.expectedVersion;
    final actions = _actionsForStatus(
      partnerType: dto.partnerType,
      status: status,
      base: dto.availableActions,
    );
    return PartnerDetailDto(
      partnerId: dto.partnerId,
      partnerType: dto.partnerType,
      status: status,
      displayName: dto.displayName,
      roles: dto.roles,
      availableActions: actions,
      expectedVersion: version,
      personProfile: dto.personProfile,
      organizationProfile: dto.organizationProfile,
      contacts: dto.contacts,
      primaryContactOrganizationId: dto.primaryContactOrganizationId,
      primaryContactOrganizationName: dto.primaryContactOrganizationName,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  List<PartnerAvailableAction> _actionsForStatus({
    required PartnerType partnerType,
    required PartnerStatus status,
    required List<PartnerAvailableAction> base,
  }) {
    final kept = base
        .where(
          (action) =>
              action != PartnerAvailableAction.deactivate &&
              action != PartnerAvailableAction.reactivate &&
              action != PartnerAvailableAction.transform,
        )
        .toList();
    if (status == PartnerStatus.active) {
      kept.add(PartnerAvailableAction.deactivate);
      if (partnerType == PartnerType.person) {
        kept.add(PartnerAvailableAction.transform);
      }
    } else if (status == PartnerStatus.inactive) {
      kept.add(PartnerAvailableAction.reactivate);
    }
    return kept;
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

  static PartnerActionLog _actionLog({
    required String actionLogId,
    required PartnerActionType actionType,
    required DateTime createdAt,
    String actorUserId = '8acac7ec-0000-4000-8000-000000000001',
    Map<String, dynamic>? beforeState,
    Map<String, dynamic>? afterState,
  }) {
    return PartnerActionLog(
      actionLogId: actionLogId,
      actionType: actionType,
      actorUserId: actorUserId,
      createdAt: createdAt,
      beforeState: beforeState,
      afterState: afterState,
    );
  }
}

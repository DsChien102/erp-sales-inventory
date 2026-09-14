import 'package:get_it/get_it.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// Map Partner search → Sales customer picker VMs (apps/erp boundary).
abstract final class SalesPartnerCustomerLookup {
  static SalesCustomerSearchFn bind([GetIt? getIt]) => bindSearch(getIt);

  static SalesCustomerSearchFn bindSearch([GetIt? getIt]) {
    final di = getIt ?? GetIt.instance;
    return (query) => _search(di, query);
  }

  static SalesCustomerDuplicateCheckFn bindDuplicateCheck([GetIt? getIt]) {
    final di = getIt ?? GetIt.instance;
    return (draft) => _checkDuplicate(di, draft);
  }

  static SalesCustomerCreateFn bindCreate([GetIt? getIt]) {
    final di = getIt ?? GetIt.instance;
    return (draft, {required confirmDuplicate}) => _create(
      di,
      draft,
      confirmDuplicate: confirmDuplicate,
    );
  }

  static SalesCustomerResolveFn bindResolve([GetIt? getIt]) {
    final di = getIt ?? GetIt.instance;
    return (partnerId) => _resolve(di, partnerId);
  }

  static Future<SalesCustomerSelection> _resolve(
    GetIt di,
    String partnerId,
  ) async {
    final trimmed = partnerId.trim();
    if (trimmed.isEmpty) {
      throw const SalesExternalOperationException(
        'Khách hàng không hợp lệ.',
      );
    }
    try {
      final partnerModule = di<IPartnerModule>();
      final executionContext = di<IExecutionContext>();
      final tenantId = await executionContext.requireTenantId();
      final detail = await partnerModule.executeQueryAsync(
        GetPartnerDetailQuery(
          tenantId: tenantId,
          partnerId: trimmed,
        ),
      );
      if (detail.status != PartnerStatus.active) {
        throw const SalesExternalOperationException(
          'Khách hàng không còn hoạt động.',
        );
      }
      if (!detail.roles.contains(PartnerRoleType.customer)) {
        throw const SalesExternalOperationException(
          'Đối tác không có vai trò khách hàng.',
        );
      }
      return _mapDetail(detail).toSelection();
    } on SalesExternalOperationException {
      rethrow;
    } catch (_) {
      throw const SalesExternalOperationException(
        'Không thể xác minh khách hàng. Vui lòng thử lại.',
      );
    }
  }

  static Future<List<SalesCustomerListItemVm>> _search(
    GetIt di,
    String query,
  ) async {
    final partnerModule = di<IPartnerModule>();
    final executionContext = di<IExecutionContext>();
    final tenantId = await executionContext.requireTenantId();

    final result = await partnerModule.executeQueryAsync(
      SearchPartnersQuery(
        tenantId: tenantId,
        query: query.trim().isEmpty ? null : query.trim(),
        role: PartnerRoleType.customer,
        status: PartnerStatus.active,
        updatedWithinDays: query.trim().isEmpty ? 30 : null,
        page: 1,
        limit: 40,
      ),
    );

    return result.items.map(_mapItem).toList(growable: false);
  }

  static Future<SalesCustomerListItemVm?> _checkDuplicate(
    GetIt di,
    SalesQuickCustomerDraft draft,
  ) async {
    final partnerModule = di<IPartnerModule>();
    final executionContext = di<IExecutionContext>();
    final tenantId = await executionContext.requireTenantId();

    final matches = await partnerModule.executeQueryAsync(
      CheckDuplicatePartnersQuery(
        tenantId: tenantId,
        phone: _nullable(_digitsOnly(draft.phone)),
        taxCode: _nullable(_digitsOnly(draft.taxCode ?? '')),
        name: _nullable(draft.displayName),
      ),
    );
    if (matches.isEmpty) return null;

    final detail = await partnerModule.executeQueryAsync(
      GetPartnerDetailQuery(
        tenantId: tenantId,
        partnerId: matches.first.partnerId,
      ),
    );
    return _mapDetail(detail);
  }

  static Future<SalesCustomerSelection> _create(
    GetIt di,
    SalesQuickCustomerDraft draft, {
    required bool confirmDuplicate,
  }) async {
    final partnerModule = di<IPartnerModule>();
    final executionContext = di<IExecutionContext>();
    final tenantId = await executionContext.requireTenantId();
    final actorId = await executionContext.requireUserId();

    try {
      final result = await partnerModule.executeCommandAsync(
        CreatePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerType: draft.type == SalesQuickCustomerType.person
              ? PartnerType.person
              : PartnerType.organization,
          roles: const [PartnerRoleType.customer],
          personProfile: draft.type == SalesQuickCustomerType.person ? _personProfile(draft) : null,
          organizationProfile: draft.type == SalesQuickCustomerType.organization
              ? _organizationProfile(draft)
              : null,
          confirmDuplicate: confirmDuplicate,
        ),
      );

      final detail = await partnerModule.executeQueryAsync(
        GetPartnerDetailQuery(
          tenantId: tenantId,
          partnerId: result.partnerId,
        ),
      );
      return _mapDetail(detail).toSelection();
    } on SalesCustomerOperationException {
      rethrow;
    } on PartnerBlockedException catch (error) {
      throw SalesCustomerOperationException(_mapBlocked(error));
    } catch (_) {
      throw const SalesCustomerOperationException(
        'Không thể kết nối để tạo khách hàng. Vui lòng thử lại.',
      );
    }
  }

  static SalesCustomerListItemVm _mapItem(PartnerListItemDto item) {
    final inactive = item.status != PartnerStatus.active;
    final parts = <String>[
      if (item.roles.contains(PartnerRoleType.customer)) 'Khách hàng',
      if (item.taxCode != null && item.taxCode!.trim().isNotEmpty) 'MST ${item.taxCode}',
      if (inactive) 'Không hoạt động',
    ];
    return SalesCustomerListItemVm(
      partnerId: item.partnerId,
      displayName: item.displayName,
      phone: item.phone,
      subtitle: parts.isEmpty ? null : parts.join(' · '),
      isBlocked: inactive,
      isOrganization: item.partnerType == PartnerType.organization,
      taxCode: item.taxCode,
    );
  }

  static SalesCustomerListItemVm _mapDetail(PartnerDetailDto detail) {
    final inactive = detail.status != PartnerStatus.active;
    final taxCode = detail.personProfile?.taxCode ?? detail.organizationProfile?.taxCode;
    final parts = <String>[
      if (detail.roles.contains(PartnerRoleType.customer)) 'Khách hàng',
      if (taxCode != null && taxCode.trim().isNotEmpty) 'MST $taxCode',
      if (inactive) 'Không hoạt động',
    ];
    return SalesCustomerListItemVm(
      partnerId: detail.partnerId,
      displayName: detail.displayName,
      phone: detail.personProfile?.phone ?? detail.organizationProfile?.phone,
      subtitle: parts.isEmpty ? null : parts.join(' · '),
      isBlocked: inactive,
      isOrganization: detail.partnerType == PartnerType.organization,
      taxCode: taxCode,
    );
  }

  static PersonProfileInput _personProfile(SalesQuickCustomerDraft draft) {
    final address = _nullable(draft.address ?? '');
    return PersonProfileInput(
      fullName: draft.displayName.trim(),
      phone: _digitsOnly(draft.phone),
      taxCode: _nullable(_digitsOnly(draft.taxCode ?? '')),
      delivery: address == null ? null : DeliveryAddressInput(address: address),
    );
  }

  static OrganizationProfileInput _organizationProfile(
    SalesQuickCustomerDraft draft,
  ) {
    return OrganizationProfileInput(
      organizationType: OrganizationType.other,
      organizationName: draft.displayName.trim(),
      phone: _digitsOnly(draft.phone),
      taxCode: _nullable(_digitsOnly(draft.taxCode ?? '')),
      companyAddress: _nullable(draft.address ?? ''),
    );
  }

  static String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _mapBlocked(PartnerBlockedException error) {
    return switch (error.code) {
      PartnerBlockedCodes.noPermission => 'Bạn chưa có quyền tạo khách hàng.',
      PartnerBlockedCodes.duplicateWarning =>
        'Khách hàng có thể đã tồn tại. Vui lòng kiểm tra lại.',
      _ => 'Không thể kết nối để tạo khách hàng. Vui lòng thử lại.',
    };
  }
}

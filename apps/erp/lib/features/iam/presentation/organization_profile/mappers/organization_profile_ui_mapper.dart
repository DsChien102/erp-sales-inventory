import 'package:erp/features/iam/data/models/tenant_profile.dart';

import '../models/organization_profile_ui_model.dart';

abstract final class OrganizationProfileUiMapper {
  static OrganizationProfileUiModel fromTenant(TenantProfile tenant) {
    final legal = tenant.legalProfile;
    return OrganizationProfileUiModel(
      id: tenant.tenantId,
      name: tenant.displayName,
      phone: tenant.contactPhone ?? '',
      email: tenant.contactEmail ?? '',
      address: tenant.contactAddressText ?? '',
      provinceCode: tenant.provinceCode,
      communeCode: tenant.communeCode,
      hasLegalProfile: legal != null,
      legalNoticeTitle: legal == null
          ? 'Chưa có hồ sơ pháp lý'
          : 'Đã có hồ sơ pháp lý',
      legalNoticeMessage: legal == null
          ? 'Có thể bổ sung sau. Một số tính năng pháp lý chưa sử dụng được.'
          : 'Hồ sơ pháp lý dùng cho chứng từ; thay đổi không sửa chứng từ lịch sử.',
      legalProfile: legal == null ? null : fromLegal(legal),
    );
  }

  static LegalProfileUiModel fromLegal(TenantLegalProfile legal) {
    return LegalProfileUiModel(
      entityType: legal.legalEntityType.code,
      entityTypeLabel: _entityTypeLabel(legal.legalEntityType),
      legalName: legal.legalName,
      taxCode: legal.taxCode,
      registeredAddress: legal.registeredAddressText ?? '',
      provinceCode: legal.provinceCode,
      communeCode: legal.communeCode,
      city: '',
      ward: '',
    );
  }

  static String _entityTypeLabel(LegalEntityType type) {
    return switch (type) {
      LegalEntityType.enterprise => 'Doanh nghiệp',
      LegalEntityType.householdBusiness => 'Hộ kinh doanh',
    };
  }
}

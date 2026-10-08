import 'package:erp/features/iam/data/models/tenant_profile.dart';
import 'package:vet45_iam_domain/domain.dart';

import '../models/organization_profile_ui_model.dart';

abstract final class OrganizationProfileUiMapper {
  static OrganizationProfileUiModel fromTenant(TenantProfile tenant) {
    final legal = tenant.legalProfile;
    return OrganizationProfileUiModel(
      id: tenant.tenantId,
      name: tenant.displayName,
      statusLabel: _statusLabel(tenant.status),
      statusDescription: _statusDescription(tenant.status),
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

  static String _statusLabel(TenantLifecycleStatus status) {
    return switch (status) {
      TenantLifecycleStatus.active => 'Hoạt động',
      TenantLifecycleStatus.provisioning => 'Đang khởi tạo',
      TenantLifecycleStatus.suspended => 'Tạm ngừng',
      TenantLifecycleStatus.closed => 'Đã đóng',
    };
  }

  static String _statusDescription(TenantLifecycleStatus status) {
    return switch (status) {
      TenantLifecycleStatus.active => 'Tổ chức đang hoạt động',
      TenantLifecycleStatus.provisioning => 'Tổ chức đang được khởi tạo',
      TenantLifecycleStatus.suspended => 'Tổ chức đang tạm ngừng',
      TenantLifecycleStatus.closed => 'Tổ chức đã đóng',
    };
  }
}

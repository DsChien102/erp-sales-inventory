import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/iam/presentation/audit_logs/catalog/tenant_audit_field_catalog.dart';

void main() {
  group('TenantAuditFieldCatalog', () {
    test('translates common payload keys to Vietnamese', () {
      expect(TenantAuditFieldCatalog.labelFor('status'), 'Trạng thái');
      expect(TenantAuditFieldCatalog.labelFor('role'), 'Vai trò');
      expect(TenantAuditFieldCatalog.labelFor('display_name'), 'Tên hiển thị');
      expect(TenantAuditFieldCatalog.labelFor('tax_code'), 'Mã số thuế');
      expect(TenantAuditFieldCatalog.labelFor('business_address'), 'Địa chỉ kinh doanh');
    });

    test('formats enum and boolean values accurately', () {
      expect(TenantAuditFieldCatalog.formatValue('status', 'active'), 'Đang hoạt động');
      expect(TenantAuditFieldCatalog.formatValue('status', 'suspended'), 'Tạm ngừng');
      expect(TenantAuditFieldCatalog.formatValue('role', 'store_owner'), 'Chủ sở hữu');
      expect(TenantAuditFieldCatalog.formatValue('is_active', true), 'Bật');
      expect(TenantAuditFieldCatalog.formatValue('is_active', false), 'Tắt');
      expect(TenantAuditFieldCatalog.formatValue('unknown', null), '—');
    });

    test('identifies sensitive credential keys', () {
      expect(TenantAuditFieldCatalog.isSensitive('password'), isTrue);
      expect(TenantAuditFieldCatalog.isSensitive('refresh_token'), isTrue);
      expect(TenantAuditFieldCatalog.isSensitive('otp_code'), isTrue);
      expect(TenantAuditFieldCatalog.isSensitive('display_name'), isFalse);
    });
  });
}

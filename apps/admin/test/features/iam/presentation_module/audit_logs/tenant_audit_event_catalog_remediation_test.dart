import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:admin/features/iam/presentation/audit_logs/catalog/tenant_audit_event_catalog.dart';

void main() {
  test('catalog matches localized terms and uses neutral unknown fallback', () {
    expect(
      TenantAuditEventCatalog.matchingEventCodes('  Tạm ngừng thành viên  '),
      contains(IamAuditEvents.membershipDeactivated),
    );

    const unknownCode = 'iam.internal.rotated_credential_bundle';
    final unknown = TenantAuditEventCatalog.entryFor(unknownCode);
    expect(unknown.title, 'Hoạt động quản trị');
    expect(unknown.eventCode, unknownCode);
  });
}

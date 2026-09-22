import 'package:admin/features/organizations/presentation/mappers/platform_tenant_ui_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  test('expired owner invitation remains visible when no owner membership exists', () {
    final organization = PlatformTenantUiMapper.fromDetail(
      PlatformTenantDetailDto(
        tenantId: 'tenant-1',
        name: 'Anh Quỳnh',
        code: '4e3d55f4',
        status: TenantLifecycleStatus.provisioning,
        createdAt: DateTime.parse('2026-09-21T09:33:37Z'),
        ownerInvitationEmail: 'dosychien9@gmail.com',
        ownerInvitationState: 'expired',
        ownerInvitationGivenName: 'Long',
        ownerInvitationFamilyName: 'Quỳnh Chí',
        ownerInvitationPhone: '0981287110',
      ),
    );

    expect(organization.ownerName, 'Quỳnh Chí Long');
    expect(organization.ownerEmail, 'dosychien9@gmail.com');
    expect(organization.ownerInvitationState, 'expired');
  });
}

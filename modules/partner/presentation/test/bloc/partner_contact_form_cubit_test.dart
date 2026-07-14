import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  group('PartnerContactFormCubit', () {
    test('loadPersonDetail loads person detail into state', () async {
      final cubit = PartnerContactFormCubit(
        partnerModule: FakePartnerModule(
          scenario: FakePartnerScenario.detailPersonActive,
        ),
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      );

      await cubit.loadPersonDetail('p-person-1');

      expect(cubit.state.status, PartnerContactFormStatus.initial);
      expect(cubit.state.personDetail, isNotNull);
      expect(cubit.state.personDetail!.partnerId, 'p-person-1');
      await cubit.close();
    });

    test('createContact executes AddOrganizationContactCommand with newPersonProfile', () async {
      final cubit = PartnerContactFormCubit(
        partnerModule: FakePartnerModule(),
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      );

      await cubit.createContact(
        organizationPartnerId: 'p-org-1',
        fullName: 'Nguyễn Văn An',
        phone: '0912345678',
        email: 'an@example.com',
        contactRole: 'Kế toán',
        isPrimary: true,
        note: 'Ghi chú',
      );

      expect(cubit.state.status, PartnerContactFormStatus.success);
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });

    test('editContact executes UpdateOrganizationContactCommand with personProfile', () async {
      final cubit = PartnerContactFormCubit(
        partnerModule: FakePartnerModule(
          scenario: FakePartnerScenario.detailPersonActive,
        ),
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      );

      await cubit.editContact(
        organizationPartnerId: 'p-org-1',
        personPartnerId: 'p-person-1',
        fullName: 'Nguyễn Văn An Sửa',
        phone: '0987654321',
        email: 'an_edit@example.com',
        contactRole: 'Quản lý',
        isPrimary: false,
        note: 'Sửa ghi chú',
      );

      expect(cubit.state.status, PartnerContactFormStatus.success);
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });

    test('linkExistingContact executes AddOrganizationContactCommand with personPartnerId', () async {
      final cubit = PartnerContactFormCubit(
        partnerModule: FakePartnerModule(),
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      );

      await cubit.linkExistingContact(
        organizationPartnerId: 'p-org-1',
        personPartnerId: 'p-person-1',
        contactRole: 'Giao nhận',
        isPrimary: false,
      );

      expect(cubit.state.status, PartnerContactFormStatus.success);
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  group('PartnerContactsCubit', () {
    test('loadContacts loads organization detail with contacts', () async {
      final cubit = PartnerContactsCubit(
        partnerModule: FakePartnerModule(
          scenario: FakePartnerScenario.detailOrganizationWithContacts,
        ),
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      );

      await cubit.loadContacts('p-org-1');

      expect(cubit.state, isA<PartnerContactsLoaded>());
      final loaded = cubit.state as PartnerContactsLoaded;
      expect(loaded.organization.partnerId, 'p-org-1');
      expect(loaded.organization.contacts, hasLength(1));
      expect(loaded.organization.contacts.first.displayName, 'Trần Thị B');
      await cubit.close();
    });

    test('searchContacts filters contact list locally', () async {
      final cubit = PartnerContactsCubit(
        partnerModule: FakePartnerModule(
          scenario: FakePartnerScenario.detailOrganizationWithContacts,
        ),
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      );

      await cubit.loadContacts('p-org-1');

      // Search matches "Trần"
      cubit.searchContacts('Trần');
      var loaded = cubit.state as PartnerContactsLoaded;
      expect(loaded.filteredContacts, hasLength(1));

      // Search does not match "Nguyễn"
      cubit.searchContacts('Nguyễn');
      loaded = cubit.state as PartnerContactsLoaded;
      expect(loaded.filteredContacts, isEmpty);

      await cubit.close();
    });

    test('setPrimaryContact executes command and reloads contacts', () async {
      final cubit = PartnerContactsCubit(
        partnerModule: FakePartnerModule(
          scenario: FakePartnerScenario.detailOrganizationWithContacts,
        ),
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      );

      await cubit.loadContacts('p-org-1');
      expect(cubit.state, isA<PartnerContactsLoaded>());

      await cubit.setPrimaryContact('p-contact-1');

      expect(cubit.state, isA<PartnerContactsLoaded>());
      final loaded = cubit.state as PartnerContactsLoaded;
      expect(loaded.isActionLoading, isFalse);
      expect(loaded.actionError, isNull);
      await cubit.close();
    });

    test('removeContact executes command and reloads contacts', () async {
      final cubit = PartnerContactsCubit(
        partnerModule: FakePartnerModule(
          scenario: FakePartnerScenario.detailOrganizationWithContacts,
        ),
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      );

      await cubit.loadContacts('p-org-1');
      expect(cubit.state, isA<PartnerContactsLoaded>());

      await cubit.removeContact('p-contact-1');

      expect(cubit.state, isA<PartnerContactsLoaded>());
      final loaded = cubit.state as PartnerContactsLoaded;
      expect(loaded.isActionLoading, isFalse);
      expect(loaded.actionError, isNull);
      await cubit.close();
    });
  });
}

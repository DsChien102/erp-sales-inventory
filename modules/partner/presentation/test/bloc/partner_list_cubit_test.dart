import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  test('fetchPartners loads mixed types from fake module', () async {
    final cubit = PartnerListCubit(
      partnerModule: FakePartnerModule(scenario: FakePartnerScenario.searchMixedTypes),
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    await cubit.fetchPartners();

    final state = cubit.state;
    expect(state, isA<PartnerListLoaded>());
    expect((state as PartnerListLoaded).items, hasLength(2));
    expect(state.total, 2);
    await cubit.close();
  });

  test('searchByKeyword refreshes with query', () async {
    final cubit = PartnerListCubit(
      partnerModule: FakePartnerModule(scenario: FakePartnerScenario.searchEmpty),
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
    );

    cubit.searchByKeyword('Minh');
    await cubit.stream.firstWhere((state) => state is PartnerListLoaded);

    expect((cubit.state as PartnerListLoaded).query, 'Minh');
    await cubit.close();
  });
}

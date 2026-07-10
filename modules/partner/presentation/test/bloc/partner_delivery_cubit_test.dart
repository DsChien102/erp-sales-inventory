import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  test('changing delivery province clears commune selection', () {
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.person,
      partnerModule: FakePartnerModule(),
      executionContext: FakeExecutionContext(),
    );

    cubit
      ..updateDeliveryProvince('Thành phố Hà Nội')
      ..updateDeliveryCommune('Phường Ba Đình')
      ..updateDeliveryProvince('Thành phố Hồ Chí Minh');

    expect(cubit.state.deliveryProvince, 'Thành phố Hồ Chí Minh');
    expect(cubit.state.deliveryCommune, isEmpty);
  });
}

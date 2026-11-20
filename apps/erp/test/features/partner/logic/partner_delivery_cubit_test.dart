import 'package:flutter_test/flutter_test.dart';
import '../support/fake_partner_repository.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  test('changing delivery province clears commune selection', () {
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.person,
      repository: FakePartnerRepository(),
    );

    cubit
      ..updateDeliveryProvince('Thành phố Hà Nội')
      ..updateDeliveryCommune('Phường Ba Đình')
      ..updateDeliveryProvince('Thành phố Hồ Chí Minh');

    expect(cubit.state.deliveryProvince, 'Thành phố Hồ Chí Minh');
    expect(cubit.state.deliveryCommune, isEmpty);
  });
}

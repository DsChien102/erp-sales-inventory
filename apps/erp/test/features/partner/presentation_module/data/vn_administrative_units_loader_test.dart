import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/partner/presentation/data/vn_administrative_units_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads provinces and wards from bundled asset', () async {
    final units = await VnAdministrativeUnitsLoader.load();

    expect(units, isNotEmpty);
    expect(units.first.fullName, isNotEmpty);
    expect(units.first.wards, isNotEmpty);
  });
}

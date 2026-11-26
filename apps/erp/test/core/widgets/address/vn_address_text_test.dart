import 'package:erp/core/widgets/address/vn_administrative_units_loader.dart';
import 'package:erp/core/widgets/address/vn_address_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const units = [
    VnAdministrativeUnit(
      code: '79',
      fullName: 'Thành phố Hồ Chí Minh',
      wards: [
        VnWard(
          code: '27139',
          fullName: 'Phường Bàn Cờ',
          provinceCode: '79',
        ),
      ],
    ),
  ];

  test('joins text, ward, province', () {
    expect(
      composeVnAddress(
        text: 'Số 12 Nguyễn Trãi',
        provinceCode: '79',
        communeCode: '27139',
        units: units,
      ),
      'Số 12 Nguyễn Trãi, Phường Bàn Cờ, Thành phố Hồ Chí Minh',
    );
  });

  test('skips parts already in the text', () {
    expect(
      composeVnAddress(
        text: 'Số 12 Nguyễn Trãi, phường bàn cờ',
        provinceCode: '79',
        communeCode: '27139',
        units: units,
      ),
      'Số 12 Nguyễn Trãi, phường bàn cờ, Thành phố Hồ Chí Minh',
    );
  });

  test('province only, unknown codes, empty text', () {
    expect(
      composeVnAddress(
        text: '',
        provinceCode: '79',
        communeCode: null,
        units: units,
      ),
      'Thành phố Hồ Chí Minh',
    );
    expect(
      composeVnAddress(
        text: 'Số 12 Nguyễn Trãi',
        provinceCode: '999',
        communeCode: '88888',
        units: units,
      ),
      'Số 12 Nguyễn Trãi',
    );
    expect(
      composeVnAddress(
        text: '   ',
        provinceCode: null,
        communeCode: null,
        units: units,
      ),
      '',
    );
  });
}

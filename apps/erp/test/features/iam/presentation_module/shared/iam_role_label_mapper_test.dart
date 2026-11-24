import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/iam/presentation.dart';

void main() {
  group('IamRoleLabelMapper', () {
    test('maps store_owner and owner to Chủ cửa hàng', () {
      expect(IamRoleLabelMapper.toDisplayLabel('store_owner'), 'Chủ cửa hàng');
      expect(IamRoleLabelMapper.toDisplayLabel('STORE_OWNER'), 'Chủ cửa hàng');
      expect(IamRoleLabelMapper.toDisplayLabel('owner'), 'Chủ cửa hàng');
      expect(IamRoleLabelMapper.toDisplayLabel('OWNER'), 'Chủ cửa hàng');
    });

    test('maps staff to Nhân viên bán hàng', () {
      expect(IamRoleLabelMapper.toDisplayLabel('staff'), 'Nhân viên bán hàng');
      expect(IamRoleLabelMapper.toDisplayLabel('STAFF'), 'Nhân viên bán hàng');
    });

    test('maps warehouse to Thủ kho', () {
      expect(IamRoleLabelMapper.toDisplayLabel('warehouse'), 'Thủ kho');
      expect(IamRoleLabelMapper.toDisplayLabel('WAREHOUSE'), 'Thủ kho');
    });

    test('maps accountant to Kế toán', () {
      expect(IamRoleLabelMapper.toDisplayLabel('accountant'), 'Kế toán');
      expect(IamRoleLabelMapper.toDisplayLabel('ACCOUNTANT'), 'Kế toán');
    });

    test('preserves already localized or unknown strings', () {
      expect(IamRoleLabelMapper.toDisplayLabel('Chủ cửa hàng'), 'Chủ cửa hàng');
      expect(IamRoleLabelMapper.toDisplayLabel('Kế toán'), 'Kế toán');
      expect(IamRoleLabelMapper.toDisplayLabel('Custom Role'), 'Custom Role');
    });

    test('handles null and empty input gracefully', () {
      expect(IamRoleLabelMapper.toDisplayLabel(null), '');
      expect(IamRoleLabelMapper.toDisplayLabel(''), '');
      expect(IamRoleLabelMapper.toDisplayLabel('   '), '');
    });
  });
}

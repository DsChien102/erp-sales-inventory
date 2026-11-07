// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';

import 'sales_contract_error.dart';

void main() {
  test('PERMISSION_DENIED đổi thành NO_PERMISSION', () {
    expect(salesContractError('PERMISSION_DENIED').code, 'NO_PERMISSION');
  });

  test('mã khác giữ nguyên, serverMessage là message', () {
    final e = salesContractError('STALE_VERSION', message: 'cũ');
    expect(e.code, 'STALE_VERSION');
    expect(e.serverMessage, 'cũ');
  });

  test('blockers là SalesBlockerDto đổi sang map', () {
    final e = salesContractError(
      'X',
      details: {
        'blockers': [SalesBlockerDto(code: 'X', message: 'm', field: 'f')],
      },
    );
    expect(e.details, {
      'blockers': [
        {'code': 'X', 'message': 'm', 'field': 'f'},
      ],
    });
  });

  test('details thường giữ nguyên', () {
    expect(salesContractError('X', details: {'k': 1}).details, {'k': 1});
  });

  test('details rỗng thì null', () {
    expect(salesContractError('X').details, isNull);
  });
}

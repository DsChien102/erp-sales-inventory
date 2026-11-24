import 'package:erp/features/assistant/data.dart';
import 'package:erp/features/assistant/presentation/assistant_cell_format.dart';
import 'package:erp/features/assistant/presentation/assistant_open_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tien', () {
    expect(formatAssistantCell(ColumnKind.tien, 1245000), '1.245.000đ');
    expect(formatAssistantCell(ColumnKind.tien, -990000), '-990.000đ');
    expect(formatAssistantCell(ColumnKind.tien, 1000.6), '1.001đ');
  });
  test('so', () {
    expect(formatAssistantCell(ColumnKind.so, 1234), '1.234');
    expect(formatAssistantCell(ColumnKind.so, 12.5), '12,5');
    expect(formatAssistantCell(ColumnKind.so, -3.25), '-3,3');
  });
  test('phan_tram', () {
    expect(formatAssistantCell(ColumnKind.phanTram, 32.5), '32,5%');
    expect(formatAssistantCell(ColumnKind.phanTram, -4), '-4%');
  });
  test('ngay', () {
    expect(formatAssistantCell(ColumnKind.ngay, '2026-11-16'), '16/11/2026');
    expect(formatAssistantCell(ColumnKind.ngay, 'hôm nay'), 'hôm nay');
  });
  test('chu / null / sai kiểu', () {
    expect(formatAssistantCell(ColumnKind.chu, 'Áo'), 'Áo');
    for (final k in ColumnKind.values) {
      expect(formatAssistantCell(k, null), '—');
    }
    expect(formatAssistantCell(ColumnKind.so, 'abc'), 'abc');
    expect(formatAssistantCell(ColumnKind.tien, double.nan), 'NaN');
  });

  test('assistantOpenLocation', () {
    expect(assistantOpenLocation(const OpenTarget(loai: 'san_pham', id: 'p1')), '/products/items/p1/view');
    expect(assistantOpenLocation(const OpenTarget(loai: 'khach_hang', id: 'c1')), '/partner/c1');
    expect(assistantOpenLocation(const OpenTarget(loai: 'don_ban', id: 'o1')), '/sales/orders/o1');
    expect(assistantOpenLocation(const OpenTarget(loai: 'x', id: 'o1')), isNull);
    expect(assistantOpenLocation(const OpenTarget(loai: 'don_ban', id: '')), isNull);
  });
}

import 'package:erp/features/einvoice/presentation/support/einvoice_datetime_copy.dart';
import 'package:flutter_test/flutter_test.dart';

String _two(int v) => v.toString().padLeft(2, '0');
String _fmt(DateTime l) =>
    '${_two(l.hour)}:${_two(l.minute)}, ${_two(l.day)}/${_two(l.month)}/${l.year}';

void main() {
  group('EInvoiceDateTimeCopy', () {
    test('formats in local time', () {
      final v = DateTime.utc(2026, 8, 4, 20, 30);
      final l = v.toLocal();
      expect(EInvoiceDateTimeCopy.syncedAt(v), 'Đồng bộ gần nhất: ${_fmt(l)}');
      expect(EInvoiceDateTimeCopy.updatedAt(v), 'Cập nhật gần nhất: ${_fmt(l)}');
    });

    test('local value is kept as is', () {
      expect(
        EInvoiceDateTimeCopy.syncedAt(DateTime(2026, 8, 5, 9, 5)),
        'Đồng bộ gần nhất: 09:05, 05/08/2026',
      );
    });
  });
}

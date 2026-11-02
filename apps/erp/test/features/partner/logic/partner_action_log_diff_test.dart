import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  group('PartnerActionLogDiff', () {
    test('returns empty when either snapshot is missing', () {
      expect(PartnerActionLogDiff.compute(null, {'a': 1}), isEmpty);
      expect(PartnerActionLogDiff.compute({'a': 1}, null), isEmpty);
      expect(PartnerActionLogDiff.compute(null, null), isEmpty);
    });

    test('detects nested profile field changes with Vietnamese labels', () {
      final changes = PartnerActionLogDiff.compute(
        {
          'display_name': 'Nguyễn Văn A',
          'person_profile': {
            'phone': '0901234567',
            'tax_code': null,
            'invoice': {'name': null, 'address': null, 'email': null},
          },
        },
        {
          'display_name': 'Nguyễn Văn A',
          'person_profile': {
            'phone': '0907654321',
            'tax_code': '2201018022',
            'invoice': {'name': null, 'address': '12 Nguyễn Huệ', 'email': null},
          },
        },
      );

      expect(changes, hasLength(3));
      expect(
        changes,
        containsAll([
          const PartnerFieldChange(
            label: 'SĐT chính',
            before: '0901234567',
            after: '0907654321',
            kind: PartnerFieldChangeKind.modified,
          ),
          const PartnerFieldChange(
            label: 'MST',
            before: PartnerActionLogDiff.emptyValueLabel,
            after: '2201018022',
            kind: PartnerFieldChangeKind.added,
          ),
          const PartnerFieldChange(
            label: 'Địa chỉ xuất hóa đơn',
            before: PartnerActionLogDiff.emptyValueLabel,
            after: '12 Nguyễn Huệ',
            kind: PartnerFieldChangeKind.added,
          ),
        ]),
      );
    });

    test('flags cleared fields as removed', () {
      final changes = PartnerActionLogDiff.compute(
        {
          'person_profile': {'tax_code': '2201018022'},
        },
        {
          'person_profile': {'tax_code': null},
        },
      );

      expect(changes, hasLength(1));
      expect(changes.single.kind, PartnerFieldChangeKind.removed);
      expect(changes.single.before, '2201018022');
    });

    test('ignores technical keys and contacts', () {
      final changes = PartnerActionLogDiff.compute(
        {
          'partner_id': 'p-1',
          'expected_version': 1,
          'updated_at': '2026-07-15T00:00:00Z',
          'contacts': [],
          'display_name': 'A',
        },
        {
          'partner_id': 'p-1',
          'expected_version': 2,
          'updated_at': '2026-07-16T00:00:00Z',
          'contacts': [
            {'person_partner_id': 'p-2'},
          ],
          'display_name': 'A',
        },
      );

      expect(changes, isEmpty);
    });

    test('maps enum-like values and role lists to Vietnamese', () {
      final changes = PartnerActionLogDiff.compute(
        {
          'status': 'active',
          'roles': ['customer'],
        },
        {
          'status': 'inactive',
          'roles': ['customer', 'supplier'],
        },
      );

      expect(
        changes,
        containsAll([
          const PartnerFieldChange(
            label: 'Trạng thái',
            before: 'Đang hoạt động',
            after: 'Ngừng hoạt động',
            kind: PartnerFieldChangeKind.modified,
          ),
          const PartnerFieldChange(
            label: 'Vai trò',
            before: 'Khách hàng',
            after: 'Khách hàng, Nhà cung cấp',
            kind: PartnerFieldChangeKind.modified,
          ),
        ]),
      );
    });

    test('treats blank strings as empty', () {
      final changes = PartnerActionLogDiff.compute(
        {
          'person_profile': {'note': '  '},
        },
        {
          'person_profile': {'note': null},
        },
      );

      expect(changes, isEmpty);
    });
  });
}

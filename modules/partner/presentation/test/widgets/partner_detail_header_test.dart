import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  for (final testCase in <(List<PartnerRoleType>, String)>[
    (const [], 'Chưa có vai trò'),
    (const [PartnerRoleType.customer], 'Khách hàng'),
    (const [PartnerRoleType.supplier], 'Nhà cung cấp'),
    (
      const [PartnerRoleType.customer, PartnerRoleType.supplier],
      'KH & NCC',
    ),
  ]) {
    testWidgets('detail header formats roles as ${testCase.$2}', (tester) async {
      final detail = PartnerDetailDto(
        partnerId: 'p-1',
        partnerType: PartnerType.person,
        status: PartnerStatus.active,
        displayName: 'Nguyễn Văn An',
        roles: testCase.$1,
        availableActions: const [],
        expectedVersion: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PartnerDetailHeader(dto: detail)),
        ),
      );

      expect(find.text('Cá nhân • ${testCase.$2}'), findsOneWidget);
    });
  }
}

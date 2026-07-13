import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('collapsed main info card does not preview phone number', (
    tester,
  ) async {
    const phone = '0981287110';
    const detail = PartnerDetailDto(
      partnerId: 'p-1',
      partnerType: PartnerType.person,
      status: PartnerStatus.active,
      displayName: 'Nguyễn Văn A',
      roles: [PartnerRoleType.customer],
      availableActions: [],
      expectedVersion: 1,
      personProfile: PersonProfileDto(
        fullName: 'Nguyễn Văn A',
        phone: phone,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PartnerDetailMainInfoCard(dto: detail)),
      ),
    );

    expect(find.text(phone), findsNothing);

    await tester.tap(find.text('Thông tin cá nhân'));
    await tester.pumpAndSettle();

    expect(find.text(phone), findsOneWidget);
  });
}

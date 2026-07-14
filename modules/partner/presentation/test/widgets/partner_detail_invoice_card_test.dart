import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  PartnerDetailDto detail({String? taxCode, String? invoiceAddress}) {
    return PartnerDetailDto(
      partnerId: 'p-1',
      partnerType: PartnerType.person,
      status: PartnerStatus.active,
      displayName: 'Nguyễn Văn A',
      roles: const [PartnerRoleType.customer],
      availableActions: const [],
      expectedVersion: 1,
      personProfile: PersonProfileDto(
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        taxCode: taxCode,
        invoice: InvoiceProfileInput(invoiceAddress: invoiceAddress),
      ),
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    String? taxCode,
    String? invoiceAddress,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerDetailInvoiceCard(
            dto: detail(
              taxCode: taxCode,
              invoiceAddress: invoiceAddress,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('collapsed badge only names missing invoice address', (tester) async {
    await pumpCard(
      tester,
      taxCode: '2201018022',
      invoiceAddress: null,
    );

    expect(find.text('Thiếu địa chỉ'), findsOneWidget);
    expect(find.text('Thiếu MST, địa chỉ'), findsNothing);
  });

  testWidgets('collapsed badge only names missing tax code', (tester) async {
    await pumpCard(
      tester,
      invoiceAddress: '12 Nguyễn Huệ',
    );

    expect(find.text('Thiếu MST'), findsOneWidget);
    expect(find.text('Thiếu MST, địa chỉ'), findsNothing);
  });

  testWidgets('collapsed badge names both missing invoice fields', (tester) async {
    await pumpCard(tester);

    expect(find.text('Thiếu MST, địa chỉ'), findsOneWidget);
  });

  testWidgets('collapsed badge is hidden when invoice fields are complete', (tester) async {
    await pumpCard(
      tester,
      taxCode: '2201018022',
      invoiceAddress: '12 Nguyễn Huệ',
    );

    expect(find.textContaining('Thiếu'), findsNothing);
  });
}

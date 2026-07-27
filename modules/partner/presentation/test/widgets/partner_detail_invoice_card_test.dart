import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  PartnerDetailDto organization({
    String? taxCode,
    String? invoiceName,
    String? invoiceAddress,
  }) {
    return PartnerDetailDto(
      partnerId: 'p-org',
      partnerType: PartnerType.organization,
      status: PartnerStatus.active,
      displayName: 'Công ty ABC',
      roles: const [PartnerRoleType.customer],
      availableActions: const [],
      expectedVersion: 1,
      organizationProfile: OrganizationProfileDto(
        organizationName: 'Công ty ABC',
        organizationType: OrganizationType.company,
        phone: '0901234567',
        taxCode: taxCode,
        invoice: InvoiceProfileInput(
          invoiceName: invoiceName,
          invoiceAddress: invoiceAddress,
        ),
      ),
    );
  }

  PartnerDetailDto person({String? taxCode, String? invoiceAddress}) {
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

  Future<void> pumpCard(WidgetTester tester, PartnerDetailDto dto) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerDetailInvoiceCard(dto: dto),
        ),
      ),
    );
  }

  testWidgets('person badge names missing MST and address', (tester) async {
    await pumpCard(tester, person());
    expect(find.text('Thiếu MST và địa chỉ'), findsOneWidget);
  });

  testWidgets('person badge only names missing invoice address', (tester) async {
    await pumpCard(
      tester,
      person(taxCode: '2201018022', invoiceAddress: null),
    );
    expect(find.text('Thiếu địa chỉ'), findsOneWidget);
  });

  testWidgets('org badge only names missing invoice address', (tester) async {
    await pumpCard(
      tester,
      organization(
        taxCode: '2201018022',
        invoiceName: 'Công ty ABC',
        invoiceAddress: null,
      ),
    );

    expect(find.text('Thiếu địa chỉ'), findsOneWidget);
    expect(find.textContaining('MST'), findsNothing);
  });

  testWidgets('org badge only names missing tax code', (tester) async {
    await pumpCard(
      tester,
      organization(
        invoiceName: 'Công ty ABC',
        invoiceAddress: '12 Nguyễn Huệ',
      ),
    );

    expect(find.text('Thiếu MST'), findsOneWidget);
  });

  testWidgets('org badge lists all missing required invoice fields', (tester) async {
    await pumpCard(tester, organization());

    expect(
      find.text('Thiếu MST, tên HĐ và địa chỉ'),
      findsOneWidget,
    );
  });

  testWidgets('org badge is hidden when required invoice fields are complete', (
    tester,
  ) async {
    await pumpCard(
      tester,
      organization(
        taxCode: '2201018022',
        invoiceName: 'Công ty ABC',
        invoiceAddress: '12 Nguyễn Huệ',
      ),
    );

    expect(find.textContaining('Thiếu'), findsNothing);
  });
}

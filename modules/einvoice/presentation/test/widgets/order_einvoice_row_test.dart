import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  Widget buildSubject({
    required OrderInvoiceProjectionDto projection,
    bool isBuyerNotReady = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: OrderEInvoiceRow(
          projection: projection,
          isBuyerNotReady: isBuyerNotReady,
          onTap: onTap,
        ),
      ),
    );
  }

  group('OrderEInvoiceRow', () {
    testWidgets('R01: buyer not ready shows helper and not-issued badge',
        (tester) async {
      final projection = FakeEInvoiceFixtures.projection(
        issuance: IssuanceDisplayState.notIssued,
      );
      await tester.pumpWidget(
        buildSubject(projection: projection, isBuyerNotReady: true),
      );

      expect(find.text(OrderEInvoiceCopy.rowTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.rowHelperNotReady), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.badgeNotIssued), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.rowHelperManage), findsNothing);
    });

    testWidgets('ready buyer shows manage helper regardless of issuance badge',
        (tester) async {
      final projection = FakeEInvoiceFixtures.projection(
        issuance: IssuanceDisplayState.notIssued,
      );
      await tester.pumpWidget(buildSubject(projection: projection));

      expect(find.text(OrderEInvoiceCopy.rowHelperManage), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.badgeNotIssued), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.rowHelperNotReady), findsNothing);
    });

    testWidgets('issued badge is independent from helper text', (tester) async {
      final projection = FakeEInvoiceFixtures.projection(
        issuance: IssuanceDisplayState.issued,
      );
      await tester.pumpWidget(buildSubject(projection: projection));

      expect(find.text(OrderEInvoiceCopy.rowHelperManage), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.badgeIssued), findsOneWidget);
    });

    testWidgets('processing badge shows Phát hành lifecycle label',
        (tester) async {
      final projection = FakeEInvoiceFixtures.projection(
        issuance: IssuanceDisplayState.processing,
      );
      await tester.pumpWidget(buildSubject(projection: projection));

      expect(find.text(OrderEInvoiceCopy.badgeProcessing), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.rowHelperManage), findsOneWidget);
    });

    testWidgets('failed badge shows Phát hành lỗi', (tester) async {
      final projection = FakeEInvoiceFixtures.projection(
        issuance: IssuanceDisplayState.failed,
      );
      await tester.pumpWidget(buildSubject(projection: projection));

      expect(find.text(OrderEInvoiceCopy.badgeIssueFailed), findsOneWidget);
    });

    testWidgets('invokes onTap callback', (tester) async {
      var tapped = false;
      final projection = FakeEInvoiceFixtures.projection(
        issuance: IssuanceDisplayState.notIssued,
      );
      await tester.pumpWidget(
        buildSubject(projection: projection, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(OrderEInvoiceRow));
      expect(tapped, isTrue);
    });
  });
}

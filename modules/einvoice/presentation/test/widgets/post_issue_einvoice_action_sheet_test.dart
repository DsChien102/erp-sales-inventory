import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  Widget buildSubject({
    PostIssueSheetState state = const PostIssueSheetState(),
  }) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: PostIssueEInvoiceActionSheet(state: state),
      ),
    );
  }

  group('PostIssueEInvoiceActionSheet', () {
    testWidgets('idle shows all actions and delivery badge', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text(OrderEInvoiceCopy.viewOfficialTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.documentsTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.sendTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.deliveryNotSent), findsOneWidget);
    });

    testWidgets('official-view loading shows spinner', (tester) async {
      await tester.pumpWidget(
        buildSubject(state: PostIssueSheetState.officialViewLoading),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('sent delivery status shows correct badge', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const PostIssueSheetState(
            deliveryStatus: DeliveryDisplayState.sent,
          ),
        ),
      );

      expect(find.text(OrderEInvoiceCopy.deliverySent), findsOneWidget);
    });

    testWidgets('sendFailed delivery status shows danger badge',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const PostIssueSheetState(
            deliveryStatus: DeliveryDisplayState.failed,
          ),
        ),
      );

      expect(find.text(OrderEInvoiceCopy.deliverySendFailed), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  Widget buildSubject({
    String? failureCode,
    String? lastFailureMessage,
  }) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: IssuanceFailureBanner(
          failureCode: failureCode,
          lastFailureMessage: lastFailureMessage,
        ),
      ),
    );
  }

  group('IssuanceFailureBanner', () {
    testWidgets('renders default failure message when no code or message provided', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text(OrderEInvoiceCopy.failureBannerTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.failureBannerDefaultMessage), findsOneWidget);
    });

    testWidgets('renders integrity failure message for COMMAND_INTEGRITY code', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          failureCode: 'COMMAND_INTEGRITY',
          lastFailureMessage: 'raw backend detail',
        ),
      );

      expect(find.text(OrderEInvoiceCopy.failureBannerTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.failureBannerIntegrityMessage), findsOneWidget);
      expect(find.text('raw backend detail'), findsNothing);
    });

    testWidgets('renders provider rejected failure message for PROVIDER_REJECTED code', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          failureCode: 'PROVIDER_REJECTED',
          lastFailureMessage: 'raw misa error',
        ),
      );

      expect(find.text(OrderEInvoiceCopy.failureBannerTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.failureBannerProviderRejectedMessage), findsOneWidget);
      expect(find.text('raw misa error'), findsNothing);
    });

    testWidgets('renders default copy for unknown code and ignores raw provider message', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          failureCode: 'SYSTEM_ERROR',
          lastFailureMessage: 'raw misa technical error',
        ),
      );

      expect(find.text(OrderEInvoiceCopy.failureBannerTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.failureBannerDefaultMessage), findsOneWidget);
      expect(find.text('raw misa technical error'), findsNothing);
    });
  });
}

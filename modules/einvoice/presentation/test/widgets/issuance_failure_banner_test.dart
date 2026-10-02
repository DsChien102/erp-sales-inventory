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

    testWidgets('renders provider rejected copy for PROVIDER_REJECTED without message', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(failureCode: 'PROVIDER_REJECTED'));

      expect(find.text(OrderEInvoiceCopy.failureBannerTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.failureBannerProviderRejectedMessage), findsOneWidget);
    });

    testWidgets('renders provider message when backend supplies one', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          failureCode: 'BuyerTaxCode_TaxCodeInvalid',
          lastFailureMessage: '  Mã số thuế người mua không hợp lệ ',
        ),
      );

      expect(find.text(OrderEInvoiceCopy.failureBannerTitle), findsOneWidget);
      expect(find.text('Mã số thuế người mua không hợp lệ'), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.failureBannerDefaultMessage), findsNothing);
    });

    testWidgets('renders default copy for unknown code with blank message', (tester) async {
      await tester.pumpWidget(
        buildSubject(failureCode: 'SYSTEM_ERROR', lastFailureMessage: '   '),
      );

      expect(find.text(OrderEInvoiceCopy.failureBannerTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.failureBannerDefaultMessage), findsOneWidget);
    });
  });
}

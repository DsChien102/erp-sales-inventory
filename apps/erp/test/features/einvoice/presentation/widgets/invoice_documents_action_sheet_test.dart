import 'dart:async';

import 'package:erp/features/einvoice/presentation/support/order_einvoice_post_issue_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/einvoice_action_item.dart';
import 'package:erp/features/einvoice/presentation/widgets/invoice_documents_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  Widget buildSubject({
    InvoiceDocumentsSheetState state = InvoiceDocumentsSheetState.idle,
    InvoiceDocumentActionHandler? onSelectPdf,
    InvoiceDocumentActionHandler? onSelectXml,
  }) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: InvoiceDocumentsActionSheet(
          state: state,
          onSelectPdf: onSelectPdf,
          onSelectXml: onSelectXml,
        ),
      ),
    );
  }

  Widget buildSheetHost({
    InvoiceDocumentActionHandler? onSelectPdf,
    InvoiceDocumentActionHandler? onSelectXml,
  }) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              unawaited(
                showInvoiceDocumentsActionSheet(
                  context,
                  onSelectPdf: onSelectPdf,
                  onSelectXml: onSelectXml,
                ),
              );
            },
            child: const Text('Mở'),
          ),
        ),
      ),
    );
  }

  group('InvoiceDocumentsActionSheet (app-owned)', () {
    testWidgets('idle shows two actions and does not request on open', (
      tester,
    ) async {
      var pdfTapped = false;
      var xmlTapped = false;
      await tester.pumpWidget(
        buildSubject(
          onSelectPdf: () async {
            pdfTapped = true;
            return false;
          },
          onSelectXml: () async {
            xmlTapped = true;
            return false;
          },
        ),
      );

      // Title now lives in the sheet chrome: covered by einvoice_sheets_adaptive_test.
      expect(find.byKey(const Key('action_save_pdf')), findsOneWidget);
      expect(find.byKey(const Key('action_save_xml')), findsOneWidget);
      expect(pdfTapped, isFalse);
      expect(xmlTapped, isFalse);
    });

    testWidgets(
      'th08_wgt_e03_u02_fr01_01 loadingPdf keeps copy stable and disables XML',
      (tester) async {
        var pdfTapped = false;
        var xmlTapped = false;
        await tester.pumpWidget(
          buildSubject(
            state: InvoiceDocumentsSheetState.loadingPdf,
            onSelectPdf: () async {
              pdfTapped = true;
              return false;
            },
            onSelectXml: () async {
              xmlTapped = true;
              return false;
            },
          ),
        );

        expect(find.text(OrderEInvoicePostIssueCopy.savePdfTitle), findsOneWidget);
        expect(
          find.text(OrderEInvoicePostIssueCopy.savePdfSupporting),
          findsOneWidget,
        );
        expect(find.text(OrderEInvoicePostIssueCopy.saveXmlTitle), findsOneWidget);
        expect(
          find.text(OrderEInvoicePostIssueCopy.saveXmlSupporting),
          findsOneWidget,
        );
        expect(find.byType(VLoading), findsOneWidget);

        final pdfItem = tester.widget<EInvoiceActionItem>(
          find.byKey(const Key('action_save_pdf')),
        );
        expect(pdfItem.loading, isTrue);
        expect(pdfItem.onTap, isNull);

        final xmlItem = tester.widget<EInvoiceActionItem>(
          find.byKey(const Key('action_save_xml')),
        );
        expect(xmlItem.loading, isFalse);
        expect(xmlItem.enabled, isFalse);
        expect(xmlItem.onTap, isNull);

        final chevrons = find.byWidgetPredicate(
          (w) => w is VIcon && w.icon == VIcons.chevronRight,
        );
        expect(chevrons, findsOneWidget);

        await tester.tap(find.byKey(const Key('action_save_pdf')));
        await tester.tap(find.byKey(const Key('action_save_xml')));
        await tester.pump();
        expect(pdfTapped, isFalse);
        expect(xmlTapped, isFalse);
      },
    );

    testWidgets(
      'loadingXml keeps copy stable and disables PDF',
      (tester) async {
        var pdfTapped = false;
        var xmlTapped = false;
        await tester.pumpWidget(
          buildSubject(
            state: InvoiceDocumentsSheetState.loadingXml,
            onSelectPdf: () async {
              pdfTapped = true;
              return false;
            },
            onSelectXml: () async {
              xmlTapped = true;
              return false;
            },
          ),
        );

        expect(find.text(OrderEInvoicePostIssueCopy.savePdfTitle), findsOneWidget);
        expect(find.text(OrderEInvoicePostIssueCopy.saveXmlTitle), findsOneWidget);
        expect(find.byType(VLoading), findsOneWidget);

        final pdfItem = tester.widget<EInvoiceActionItem>(
          find.byKey(const Key('action_save_pdf')),
        );
        expect(pdfItem.loading, isFalse);
        expect(pdfItem.enabled, isFalse);
        expect(pdfItem.onTap, isNull);

        final xmlItem = tester.widget<EInvoiceActionItem>(
          find.byKey(const Key('action_save_xml')),
        );
        expect(xmlItem.loading, isTrue);
        expect(xmlItem.onTap, isNull);

        await tester.tap(find.byKey(const Key('action_save_pdf')));
        await tester.tap(find.byKey(const Key('action_save_xml')));
        await tester.pump();
        expect(pdfTapped, isFalse);
        expect(xmlTapped, isFalse);
      },
    );

    testWidgets('successful native handoff closes SG-06', (tester) async {
      await tester.pumpWidget(
        buildSheetHost(onSelectPdf: () async => true),
      );

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('action_save_pdf')));
      await tester.pumpAndSettle();

      expect(find.byType(InvoiceDocumentsActionSheet), findsNothing);
    });

    testWidgets('failed native handoff keeps SG-06 open', (tester) async {
      await tester.pumpWidget(
        buildSheetHost(onSelectXml: () async => false),
      );

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('action_save_xml')));
      await tester.pumpAndSettle();

      expect(find.byType(InvoiceDocumentsActionSheet), findsOneWidget);
    });
  });
}

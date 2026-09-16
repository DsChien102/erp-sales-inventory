import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  Widget buildSubject({
    InvoiceDocumentsSheetState state = InvoiceDocumentsSheetState.idle,
    VoidCallback? onSelectPdf,
    VoidCallback? onSelectXml,
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

  group('InvoiceDocumentsActionSheet', () {
    testWidgets('idle shows title, both actions, and chevrons', (tester) async {
      await tester.pumpWidget(
        buildSubject(onSelectPdf: () {}, onSelectXml: () {}),
      );

      expect(find.text(InvoiceDocumentsCopy.sheetTitle), findsOneWidget);
      expect(find.text(InvoiceDocumentsCopy.savePdfTitle), findsOneWidget);
      expect(find.text(InvoiceDocumentsCopy.savePdfSupporting), findsOneWidget);
      expect(find.text(InvoiceDocumentsCopy.saveXmlTitle), findsOneWidget);
      expect(find.text(InvoiceDocumentsCopy.saveXmlSupporting), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final chevrons = find.byWidgetPredicate(
        (w) => w is VIcon && w.icon == VIcons.chevronRight,
      );
      expect(chevrons, findsNWidgets(2));
    });

    testWidgets('loadingPdf shows spinner and disables XML', (tester) async {
      var pdfTapped = false;
      var xmlTapped = false;
      await tester.pumpWidget(
        buildSubject(
          state: InvoiceDocumentsSheetState.loadingPdf,
          onSelectPdf: () => pdfTapped = true,
          onSelectXml: () => xmlTapped = true,
        ),
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

      await tester.tap(find.byKey(const Key('action_save_pdf')));
      await tester.pump();
      expect(pdfTapped, isFalse);

      await tester.tap(find.byKey(const Key('action_save_xml')));
      await tester.pump();
      expect(xmlTapped, isFalse);
    });

    testWidgets('loadingXml shows spinner and disables PDF', (tester) async {
      var pdfTapped = false;
      var xmlTapped = false;
      await tester.pumpWidget(
        buildSubject(
          state: InvoiceDocumentsSheetState.loadingXml,
          onSelectPdf: () => pdfTapped = true,
          onSelectXml: () => xmlTapped = true,
        ),
      );

      expect(find.byType(VLoading), findsOneWidget);

      final xmlItem = tester.widget<EInvoiceActionItem>(
        find.byKey(const Key('action_save_xml')),
      );
      expect(xmlItem.loading, isTrue);
      expect(xmlItem.onTap, isNull);

      final pdfItem = tester.widget<EInvoiceActionItem>(
        find.byKey(const Key('action_save_pdf')),
      );
      expect(pdfItem.enabled, isFalse);
      expect(pdfItem.onTap, isNull);

      await tester.tap(find.byKey(const Key('action_save_xml')));
      await tester.pump();
      expect(xmlTapped, isFalse);

      await tester.tap(find.byKey(const Key('action_save_pdf')));
      await tester.pump();
      expect(pdfTapped, isFalse);
    });

    testWidgets('select callbacks keep sheet open', (tester) async {
      var pdfTaps = 0;
      await tester.pumpWidget(
        buildSubject(onSelectPdf: () => pdfTaps++),
      );

      await tester.tap(find.byKey(const Key('action_save_pdf')));
      await tester.pump();

      expect(pdfTaps, 1);
      expect(find.byType(InvoiceDocumentsActionSheet), findsOneWidget);
    });

    testWidgets('show helper returns selected action and dismiss returns null', (tester) async {
      InvoiceDocumentsAction? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: VButton(
                label: 'Open',
                onPressed: () async {
                  result = await showInvoiceDocumentsActionSheet(context);
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('action_save_pdf')));
      await tester.pumpAndSettle();

      expect(result, InvoiceDocumentsAction.pdf);
    });
  });
}

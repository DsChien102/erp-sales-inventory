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

  testWidgets('open sheet updates delivery without remounting', (
    tester,
  ) async {
    final state = ValueNotifier(
      const PostIssueSheetState(
        deliveryStatus: DeliveryDisplayState.sending,
      ),
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: ValueListenableBuilder<PostIssueSheetState>(
            valueListenable: state,
            builder: (_, value, _) => PostIssueEInvoiceActionSheet(state: value),
          ),
        ),
      ),
    );
    expect(find.text(OrderEInvoiceCopy.deliverySending), findsOneWidget);
    state.value = const PostIssueSheetState(
      deliveryStatus: DeliveryDisplayState.sent,
    );
    await tester.pump();
    expect(find.text(OrderEInvoiceCopy.deliverySent), findsOneWidget);
    expect(find.text(OrderEInvoiceCopy.deliverySending), findsNothing);
  });

  testWidgets('pending resend disables send even when prior delivery was sent', (tester) async {
    await tester.pumpWidget(buildSubject(state: const PostIssueSheetState(
      deliveryStatus: DeliveryDisplayState.sent, isDeliveryPending: true,
    )));
    final action = tester.widget<EInvoiceActionItem>(find.byKey(const Key('action_send')));
    expect(action.enabled, isFalse);
    expect(action.onTap, isNull);
  });

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

    testWidgets('sendFailed delivery status shows danger badge', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const PostIssueSheetState(
            deliveryStatus: DeliveryDisplayState.failed,
          ),
        ),
      );

      expect(find.text(OrderEInvoiceCopy.deliverySendFailed), findsOneWidget);
    });

    testWidgets('sending delivery disables send action and keeps badge', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const PostIssueSheetState(
            deliveryStatus: DeliveryDisplayState.sending,
          ),
        ),
      );

      expect(find.text(OrderEInvoiceCopy.deliverySending), findsOneWidget);

      final sendItem = tester.widget<EInvoiceActionItem>(
        find.byKey(const Key('action_send')),
      );
      expect(sendItem.enabled, isFalse);
      expect(sendItem.onTap, isNull);

      final documentsItem = tester.widget<EInvoiceActionItem>(
        find.byKey(const Key('action_documents')),
      );
      expect(documentsItem.enabled, isTrue);

      final inkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const Key('action_send')),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.onTap, isNull);
    });
  });
}

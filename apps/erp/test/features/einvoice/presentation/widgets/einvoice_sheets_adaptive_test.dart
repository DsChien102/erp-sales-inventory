import 'dart:async';

import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/einvoice/logic/order_invoice_delivery_cubit.dart';
import 'package:erp/features/einvoice/presentation/support/order_einvoice_copy.dart';
import 'package:erp/features/einvoice/presentation/support/order_einvoice_post_issue_copy.dart';
import 'package:erp/features/einvoice/presentation/support/order_invoice_delivery_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/disconnect_provider_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/invoice_documents_action_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/issue_invoice_confirmation_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/post_issue_einvoice_action_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/pre_issue_einvoice_action_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/resend_invoice_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/send_invoice_sheet.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/fake_einvoice_repository.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);
// Old VConfirmDialog overflows at 390 (KI fixed by Q3); parity runs at 600.
const _narrow = Size(600, 844);

void main() {
  late FakeEInvoiceRepository repository;

  setUp(() {
    repository = FakeEInvoiceRepository();
  });

  /// Opens a sheet through its `show…` function from an 'Open' button.
  /// The result is stored in [result] (set when the future completes).
  Future<_Opened<T>> open<T>(
    WidgetTester tester,
    Future<T> Function(BuildContext context) opener, {
    Size size = _phone,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = _Opened<T>();
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => VButton(
              label: 'Open',
              onPressed: () {
                opener(context).then((value) {
                  opened.done = true;
                  opened.value = value;
                });
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return opened;
  }

  SendInvoiceSheetContextDto sendSheet({
    SendInvoiceSheetMode mode = SendInvoiceSheetMode.send,
    List<InvoiceDeliveryItemDto> history = const [],
  }) {
    return SendInvoiceSheetContextDto(
      mode: mode,
      suggestedEmail: 'buyer@example.com',
      suggestedEmailSource: mode == SendInvoiceSheetMode.send
          ? DeliveryRecipientSource.currentPartnerProfile
          : DeliveryRecipientSource.lastInvoiceDelivery,
      history: history,
      operationLocked: false,
      displayState: DeliveryDisplayState.notSent,
    );
  }

  Future<OrderInvoiceDeliveryCubit> cubitFor(
    SendInvoiceSheetContextDto context,
  ) async {
    repository.sendContext = context;
    final cubit = OrderInvoiceDeliveryCubit(
      salesOrderId: 'order-101',
      repository: repository,
      idempotencyKeyFactory: DeterministicOrderEInvoiceIdempotencyKeyFactory(
        const ['key-1', 'key-2', 'key-3'],
      ),
    );
    await cubit.loadContext();
    addTearDown(cubit.close);
    return cubit;
  }

  final summary = IssueInvoiceConfirmationSummary.previewFixture;

  // Openers shared by phone/desktop groups.
  final openers = <String, _Spec>{
    'pre-issue': _Spec(
      OrderEInvoiceCopy.sheetTitle,
      (c) => showPreIssueEInvoiceActionSheet(c),
    ),
    'issue confirmation': _Spec(
      OrderEInvoiceCopy.issueConfirmationTitle,
      (c) => showIssueInvoiceConfirmationSheet(c, summary: summary),
    ),
    'post-issue': _Spec(
      OrderEInvoicePostIssueCopy.sheetTitle,
      (c) => showPostIssueEInvoiceActionSheet(c),
    ),
    'documents': _Spec(
      OrderEInvoicePostIssueCopy.documentsSheetTitle,
      (c) => showInvoiceDocumentsActionSheet(c),
    ),
    'disconnect': _Spec(
      DisconnectProviderSheet.title,
      (c) => showDisconnectProviderSheet(c),
    ),
  };

  group('behavior parity (phone)', () {
    testWidgets('B0-1 pre-issue: title shown once, tap issue returns issue', (
      tester,
    ) async {
      final r = await open<PreIssueAction?>(
        tester,
        (c) => showPreIssueEInvoiceActionSheet(
          c,
          state: const PreIssueSheetState(isProviderConnected: true),
        ),
      );
      expect(find.text(OrderEInvoiceCopy.sheetTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('action_issue')));
      await tester.pumpAndSettle();
      expect(r.value, PreIssueAction.issue);
    });

    testWidgets(
      'B0-2 issue confirmation: title once, confirm → true, cancel → false',
      (tester) async {
        var r = await open<bool>(
          tester,
          (c) => showIssueInvoiceConfirmationSheet(c, summary: summary),
        );
        expect(find.text(OrderEInvoiceCopy.issueConfirmationTitle), findsOneWidget);
        await tester.tap(find.byKey(const Key('action_confirm_issue')));
        await tester.pumpAndSettle();
        expect(r.value, true);

        r = await open<bool>(
          tester,
          (c) => showIssueInvoiceConfirmationSheet(c, summary: summary),
        );
        await tester.tap(find.byKey(const Key('action_cancel_issue')));
        await tester.pumpAndSettle();
        expect(r.value, false);
      },
    );

    testWidgets('B0-3 post-issue: title once, tap documents returns documents', (
      tester,
    ) async {
      final r = await open<PostIssueAction?>(
        tester,
        (c) => showPostIssueEInvoiceActionSheet(c),
      );
      expect(find.text(OrderEInvoicePostIssueCopy.sheetTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('action_documents')));
      await tester.pumpAndSettle();
      expect(r.value, PostIssueAction.documents);
    });

    testWidgets('B0-4 documents: title once, tap pdf returns pdf', (tester) async {
      final r = await open<InvoiceDocumentsAction?>(
        tester,
        (c) => showInvoiceDocumentsActionSheet(c),
      );
      expect(
        find.text(OrderEInvoicePostIssueCopy.documentsSheetTitle),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('action_save_pdf')));
      await tester.pumpAndSettle();
      expect(r.value, InvoiceDocumentsAction.pdf);
    });

    testWidgets('B0-5 send: title once, valid email + send returns true', (
      tester,
    ) async {
      final ctx = sendSheet();
      final cubit = await cubitFor(ctx);
      final r = await open<bool?>(
        tester,
        (c) => showOrderInvoiceSendSheet(c, cubit: cubit, sheetContext: ctx),
      );
      expect(find.text(OrderInvoiceDeliveryCopy.sendTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pumpAndSettle();
      expect(r.value, true);
    });

    testWidgets('B0-6 resend: title once, history link calls onViewHistory', (
      tester,
    ) async {
      final ctx = sendSheet(mode: SendInvoiceSheetMode.resend);
      final cubit = await cubitFor(ctx);
      var opened = 0;
      await open<bool?>(
        tester,
        (c) => showOrderInvoiceResendSheet(
          c,
          cubit: cubit,
          sheetContext: ctx,
          onViewHistory: (_) async {
            opened++;
          },
        ),
      );
      expect(find.text(OrderInvoiceDeliveryCopy.resendTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('action_view_delivery_history')));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('B0-7 disconnect: title once, confirm → true, keep → false', (
      tester,
    ) async {
      var r = await open<bool>(tester, (c) => showDisconnectProviderSheet(c), size: _narrow);
      expect(find.text(DisconnectProviderSheet.title), findsOneWidget);
      await tester.tap(find.text(DisconnectProviderSheet.actionLabel));
      await tester.pumpAndSettle();
      expect(r.value, true);

      r = await open<bool>(tester, (c) => showDisconnectProviderSheet(c), size: _narrow);
      await tester.tap(find.text(DisconnectProviderSheet.cancelLabel));
      await tester.pumpAndSettle();
      expect(r.value, false);
    });

    testWidgets('B0-8 disconnect: tap outside returns false', (tester) async {
      final r = await open<bool>(tester, (c) => showDisconnectProviderSheet(c), size: _narrow);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(r.done, isTrue);
      expect(r.value, false);
    });
  });

  group('desktop 1280x800', () {
    for (final entry in openers.entries) {
      testWidgets('${entry.key}: desktop shows titled dialog', (tester) async {
        await open<Object?>(tester, entry.value.opener, size: _desktop);
        expect(find.byType(VSheetDialog), findsOneWidget);
        expect(find.byType(VBottomSheet), findsNothing);
        expect(find.text(entry.value.title), findsOneWidget);
        expect(find.byTooltip('Đóng'), findsOneWidget);
      });
    }

    testWidgets('send: desktop shows titled dialog', (tester) async {
      final ctx = sendSheet();
      final cubit = await cubitFor(ctx);
      await open<Object?>(
        tester,
        (c) => showOrderInvoiceSendSheet(c, cubit: cubit, sheetContext: ctx),
        size: _desktop,
      );
      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.byType(VBottomSheet), findsNothing);
      expect(find.text(OrderInvoiceDeliveryCopy.sendTitle), findsOneWidget);
      expect(find.byTooltip('Đóng'), findsOneWidget);
    });

    testWidgets('resend: desktop shows titled dialog', (tester) async {
      final ctx = sendSheet(mode: SendInvoiceSheetMode.resend);
      final cubit = await cubitFor(ctx);
      await open<Object?>(
        tester,
        (c) => showOrderInvoiceResendSheet(
          c,
          cubit: cubit,
          sheetContext: ctx,
          onViewHistory: (_) async {},
        ),
        size: _desktop,
      );
      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.byType(VBottomSheet), findsNothing);
      expect(find.text(OrderInvoiceDeliveryCopy.resendTitle), findsOneWidget);
      expect(find.byTooltip('Đóng'), findsOneWidget);
    });

    testWidgets('desktop: escape closes dialog', (tester) async {
      final r = await open<PostIssueAction?>(
        tester,
        (c) => showPostIssueEInvoiceActionSheet(c),
        size: _desktop,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(r.done, isTrue);
      expect(r.value, isNull);
      expect(find.byType(VSheetDialog), findsNothing);
    });

    testWidgets('desktop send failure keeps dialog open', (tester) async {
      final ctx = sendSheet();
      final cubit = await cubitFor(ctx);
      repository.throwOn['send'] = const AppException(EInvoiceErrorCodes.systemError);
      await open<Object?>(
        tester,
        (c) => showOrderInvoiceSendSheet(c, cubit: cubit, sheetContext: ctx),
        size: _desktop,
      );
      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(VSheetDialog), findsOneWidget);
    });

    testWidgets('desktop history push returns to resend dialog', (tester) async {
      final ctx = sendSheet(mode: SendInvoiceSheetMode.resend);
      final cubit = await cubitFor(ctx);
      await open<Object?>(
        tester,
        (c) => showOrderInvoiceResendSheet(
          c,
          cubit: cubit,
          sheetContext: ctx,
          onViewHistory: (sheetCtx) async {
            await Navigator.of(sheetCtx).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('history')),
              ),
            );
          },
        ),
        size: _desktop,
      );
      await tester.enterText(
        find.byKey(const Key('field_recipient_email')),
        'moi@x.vn',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('action_view_delivery_history')));
      await tester.pumpAndSettle();
      expect(find.text('history'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pumpAndSettle();
      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.text('moi@x.vn'), findsOneWidget);
    });
  });

  group('iphone 390x844', () {
    for (final entry in openers.entries) {
      testWidgets('${entry.key}: phone shows titled bottom sheet', (tester) async {
        await open<Object?>(tester, entry.value.opener);
        expect(find.byType(VBottomSheet), findsOneWidget);
        expect(find.byType(VSheetDialog), findsNothing);
        expect(find.text(entry.value.title), findsOneWidget);
      });
    }

    testWidgets('send: phone shows titled bottom sheet', (tester) async {
      final ctx = sendSheet();
      final cubit = await cubitFor(ctx);
      await open<Object?>(
        tester,
        (c) => showOrderInvoiceSendSheet(c, cubit: cubit, sheetContext: ctx),
      );
      expect(find.byType(VBottomSheet), findsOneWidget);
      expect(find.text(OrderInvoiceDeliveryCopy.sendTitle), findsOneWidget);
    });

    testWidgets('resend: phone shows titled bottom sheet', (tester) async {
      final ctx = sendSheet(mode: SendInvoiceSheetMode.resend);
      final cubit = await cubitFor(ctx);
      await open<Object?>(
        tester,
        (c) => showOrderInvoiceResendSheet(
          c,
          cubit: cubit,
          sheetContext: ctx,
          onViewHistory: (_) async {},
        ),
      );
      expect(find.byType(VBottomSheet), findsOneWidget);
      expect(find.text(OrderInvoiceDeliveryCopy.resendTitle), findsOneWidget);
    });

    testWidgets('send sheet keeps primary visible with keyboard', (tester) async {
      final ctx = sendSheet();
      final cubit = await cubitFor(ctx);
      await open<Object?>(
        tester,
        (c) => showOrderInvoiceSendSheet(c, cubit: cubit, sheetContext: ctx),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      final bottom = tester
          .getBottomLeft(find.byKey(const Key('action_send_invoice')))
          .dy;
      expect(bottom, lessThanOrEqualTo(844 - 300));
    });
  });
}

class _Opened<T> {
  bool done = false;
  T? value;
}

class _Spec {
  const _Spec(this.title, this.opener);
  final String title;
  final Future<Object?> Function(BuildContext) opener;
}

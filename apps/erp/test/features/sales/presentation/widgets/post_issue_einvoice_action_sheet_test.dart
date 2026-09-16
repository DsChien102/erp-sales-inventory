import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:erp/features/sales/presentation/support/order_einvoice_post_issue_copy.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/einvoice_action_item.dart';
import 'package:erp/features/sales/presentation/widgets/einvoice/post_issue_einvoice_action_sheet.dart';

void main() {
  Widget buildSubject({
    PostIssueSheetState state = const PostIssueSheetState(),
    VoidCallback? onViewOfficial,
  }) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: PostIssueEInvoiceActionSheet(
          state: state,
          onViewOfficial: onViewOfficial,
        ),
      ),
    );
  }

  group('PostIssueEInvoiceActionSheet (app-owned)', () {
    testWidgets('idle shows official/documents/send actions', (tester) async {
      await tester.pumpWidget(buildSubject(onViewOfficial: () {}));

      expect(find.text(OrderEInvoicePostIssueCopy.sheetTitle), findsOneWidget);
      expect(
        find.text(OrderEInvoicePostIssueCopy.viewOfficialTitle),
        findsOneWidget,
      );
      expect(
        find.text(OrderEInvoicePostIssueCopy.documentsTitle),
        findsOneWidget,
      );
      expect(find.text(OrderEInvoicePostIssueCopy.sendTitle), findsOneWidget);
    });

    testWidgets(
      'official view loading keeps copy and disables siblings',
      (tester) async {
        var officialTapped = false;
        await tester.pumpWidget(
          buildSubject(
            state: const PostIssueSheetState(isOfficialViewLoading: true),
            onViewOfficial: () => officialTapped = true,
          ),
        );

        expect(
          find.text(OrderEInvoicePostIssueCopy.viewOfficialTitle),
          findsOneWidget,
        );
        expect(
          find.text(OrderEInvoicePostIssueCopy.viewOfficialSupporting),
          findsOneWidget,
        );

        final official = tester.widget<EInvoiceActionItem>(
          find.byKey(const Key('action_view_official')),
        );
        expect(official.loading, isTrue);
        expect(official.onTap, isNull);

        expect(
          tester
              .widget<EInvoiceActionItem>(
                find.byKey(const Key('action_documents')),
              )
              .enabled,
          isFalse,
        );
        expect(
          tester.widget<EInvoiceActionItem>(find.byKey(const Key('action_send'))).enabled,
          isFalse,
        );

        await tester.tap(find.byKey(const Key('action_view_official')));
        await tester.pump();
        expect(officialTapped, isFalse);
      },
    );

    testWidgets('sending delivery disables send while keeping badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          state: const PostIssueSheetState(
            deliveryStatus: DeliveryDisplayState.sending,
          ),
          onViewOfficial: () {},
        ),
      );

      expect(
        find.text(OrderEInvoicePostIssueCopy.deliverySending),
        findsOneWidget,
      );
      expect(
        tester.widget<EInvoiceActionItem>(find.byKey(const Key('action_send'))).enabled,
        isFalse,
      );
    });

    testWidgets('deliveryPending disables send action', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const PostIssueSheetState(isDeliveryPending: true),
          onViewOfficial: () {},
        ),
      );

      expect(
        tester.widget<EInvoiceActionItem>(find.byKey(const Key('action_send'))).enabled,
        isFalse,
      );
    });

    testWidgets(
      'hasSecondaryAttention keeps badge and shows secondary supporting copy',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            state: const PostIssueSheetState(
              deliveryStatus: DeliveryDisplayState.sent,
              hasSecondaryAttention: true,
            ),
            onViewOfficial: () {},
          ),
        );

        expect(
          find.text(OrderEInvoicePostIssueCopy.deliverySent),
          findsOneWidget,
        );
        expect(
          find.text(OrderEInvoicePostIssueCopy.deliverySecondaryAttention),
          findsOneWidget,
        );
        expect(
          find.text(OrderEInvoicePostIssueCopy.sendSupporting),
          findsNothing,
        );
        expect(find.textContaining('Kiểm tra kết quả gửi'), findsNothing);
      },
    );

    testWidgets(
      'unknown delivery shows warning badge and keeps send enabled',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            state: const PostIssueSheetState(
              deliveryStatus: DeliveryDisplayState.unknown,
            ),
            onViewOfficial: () {},
          ),
        );

        expect(
          find.text(OrderEInvoicePostIssueCopy.deliveryUnknown),
          findsOneWidget,
        );
        final badge = tester.widget<VBadge>(
          find.descendant(
            of: find.byKey(const Key('action_send')),
            matching: find.byType(VBadge),
          ),
        );
        expect(badge.tone, VComponentTone.warning);
        expect(
          tester.widget<EInvoiceActionItem>(find.byKey(const Key('action_send'))).enabled,
          isTrue,
        );
        expect(find.textContaining('Kiểm tra'), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });
}

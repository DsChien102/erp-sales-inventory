import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/presentation/support/order_einvoice_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/order_einvoice_row.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_cubit.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/einvoice/presentation/support/order_einvoice_post_issue_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/order_einvoice_section.dart';
import 'package:erp/features/einvoice/presentation/widgets/post_issue_einvoice_action_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/resend_invoice_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/send_invoice_sheet.dart';
import 'package:erp/features/sales/logic/sales_order_detail_state.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_detail_vm.dart';
import 'package:erp/features/sales/presentation/widgets/sales_order_detail_documents_section.dart';

import '../support/fake_einvoice_configuration_repository.dart';
import '../support/fake_einvoice_repository.dart';
import 'package:erp/features/einvoice/data/i_invoice_viewer_launcher.dart';

const _salesOrderId = 'so-fake-001';

OrderInvoiceProjectionDto _projection({
  IssuanceDisplayState issuance = IssuanceDisplayState.notIssued,
  DeliveryDisplayState delivery = DeliveryDisplayState.notSent,
  bool hasSecondaryAttention = false,
  List<OrderInvoiceAction> actions = const [],
}) {
  return OrderInvoiceProjectionDto(
    salesOrderId: _salesOrderId,
    issuanceDisplayState: issuance,
    deliveryDisplayState: delivery,
    hasSecondaryAttention: hasSecondaryAttention,
    actions: actions,
  );
}

void main() {
  group('SG02-R01 mount contract', () {
    late String pageSource;

    setUpAll(() {
      pageSource = File(
        'lib/features/sales/presentation/pages/sales_order_detail_page.dart',
      ).readAsStringSync();
    });

    test('order detail page mounts OrderEInvoiceSection, not the placeholder sheet', () {
      expect(
        pageSource,
        contains('OrderEInvoiceSection('),
        reason: 'SG02-R01 must compose the real E-Invoice surface',
      );
      expect(
        pageSource,
        isNot(contains('showSalesResultEInvoiceSheet')),
        reason: 'placeholder sheet must not be used on order detail',
      );
      expect(pageSource, contains('EInvoiceRepository'));
      expect(
        pageSource,
        contains('hasLoadedInitialProjection'),
        reason: 'detail must mount even when first projection read fails',
      );
      expect(
        pageSource,
        isNot(contains('state.eInvoiceProjection != null &&')),
        reason: 'do not gate section mount on successful first projection',
      );
    });

    test('detail mapper no longer hardcodes eInvoiceStatus', () {
      final mapper = File(
        'lib/features/sales/presentation/support/sales_order_detail_mapper.dart',
      ).readAsStringSync();
      expect(
        mapper,
        isNot(contains('eInvoiceStatus: SalesEInvoiceStatus.notIssued')),
        reason: 'status must come from the projection, not a constant',
      );
    });
  });

  group('SG02-R02 mount contract', () {
    test('sales result section mounts live OrderEInvoiceSection without sheet', () {
      final sectionSource = File(
        'lib/features/sales/presentation/widgets/sales_result_documents_section.dart',
      ).readAsStringSync();
      expect(sectionSource, contains("key: const Key('sales_result_einvoice_section')"));
      expect(sectionSource, isNot(contains('Future<void> _openEInvoice')));
      expect(sectionSource, isNot(contains('showModalBottomSheet<void>')));
      expect(sectionSource, isNot(contains("badgeLabel: 'Chưa phát hành'")));
      expect(sectionSource, contains('hasLoadedInitialProjection: false'));
    });
  });

  group('Theme 05 host runtime', () {
    testWidgets(
      'th08_e2e_e03_u01_sc01_01 order detail opens official viewer from issued row',
      (tester) async {
        final repository = FakeEInvoiceRepository.forScenario(
          FakeEInvoiceScenario.officialViewOk,
        );
        final configurationRepository = FakeEInvoiceConfigurationRepository();
        final launcher = _RecordingLauncher();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: Scaffold(
              key: const Key('order_detail_host'),
              body: SalesOrderDetailDocumentsSection(
                isCancelled: false,
                eInvoiceStatus: SalesEInvoiceStatus.issued,
                historyStatus: SalesOrderDetailSectionStatus.loaded,
                returnSlips: const [],
                onOpenReceipt: () {},
                onOpenReturnList: () {},
                onOpenHistory: () {},
                onRetryHistory: () {},
                eInvoiceSection: OrderEInvoiceSection(
                  key: const Key('btn_sg08_einvoice'),
                  salesOrderId: _salesOrderId,
                  orderVersion: 1,
                  orderCode: 'DH-001',
                  initialProjection: _projection(
                    issuance: IssuanceDisplayState.issued,
                    actions: const [OrderInvoiceAction.view],
                  ),
                  repository: repository,
                  configurationRepository: configurationRepository,
                  viewerLauncher: launcher,
                  idempotencyKeyFactory: const OrderEInvoiceIdempotencyKeyFactory(),
                ),
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('order_detail_host')), findsOneWidget);
        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();
        expect(find.byType(PostIssueEInvoiceActionSheet), findsOneWidget);

        await tester.tap(find.byKey(const Key('action_view_official')));
        await tester.pumpAndSettle();

        expect(
          repository.calls.where((c) => c == 'requestOfficialView'),
          hasLength(1),
        );
        expect(launcher.launchedUrls, ['https://view.fake/invoice']);
        expect(find.byKey(const Key('order_detail_host')), findsOneWidget);
        expect(find.byType(SalesOrderDetailDocumentsSection), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'th08_e2e_e04_u02_sc01_01 order detail send sheet submits and keeps host',
      (tester) async {
        final repository = FakeEInvoiceRepository.forScenario(
          FakeEInvoiceScenario.sendOk,
        );
        final sendGate = Completer<void>();
        repository.holdOn['send'] = sendGate;
        final configurationRepository = FakeEInvoiceConfigurationRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: Scaffold(
              key: const Key('order_detail_host'),
              body: SalesOrderDetailDocumentsSection(
                isCancelled: false,
                eInvoiceStatus: SalesEInvoiceStatus.issued,
                historyStatus: SalesOrderDetailSectionStatus.loaded,
                returnSlips: const [],
                onOpenReceipt: () {},
                onOpenReturnList: () {},
                onOpenHistory: () {},
                onRetryHistory: () {},
                eInvoiceSection: OrderEInvoiceSection(
                  key: const Key('btn_sg08_einvoice'),
                  salesOrderId: _salesOrderId,
                  orderVersion: 1,
                  orderCode: 'DH-001',
                  initialProjection: _projection(
                    issuance: IssuanceDisplayState.issued,
                    delivery: DeliveryDisplayState.notSent,
                    actions: const [OrderInvoiceAction.view],
                  ),
                  repository: repository,
                  configurationRepository: configurationRepository,
                  idempotencyKeyFactory: DeterministicOrderEInvoiceIdempotencyKeyFactory(const [
                    'key-send-1',
                  ]),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();
        expect(find.byType(PostIssueEInvoiceActionSheet), findsOneWidget);

        await tester.tap(find.byKey(const Key('action_send')));
        await tester.pumpAndSettle();
        expect(find.byType(OrderInvoiceSendSheet), findsOneWidget);
        expect(find.text('buyer@fake.test'), findsOneWidget);

        await tester.tap(find.byKey(const Key('action_send_invoice')));
        await tester.pump();
        expect(find.byType(OrderInvoiceSendSheet), findsOneWidget);
        expect(
          tester.widget<VButton>(find.byKey(const Key('action_send_invoice'))).isLoading,
          isTrue,
        );
        expect(
          repository.sendCalls,
          hasLength(1),
        );

        sendGate.complete();
        await tester.pumpAndSettle();
        expect(find.byType(OrderInvoiceSendSheet), findsNothing);
        expect(find.byKey(const Key('order_detail_host')), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'th08_e2e_e04_u01_sc01_01 auto-send projection never emits auto command',
      (tester) async {
        final repository = FakeEInvoiceRepository.forScenario(
          FakeEInvoiceScenario.sendOk,
        );
        final configurationRepository = FakeEInvoiceConfigurationRepository();
        late OrderEInvoiceCubit? cubit;

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: Scaffold(
              body: OrderEInvoiceSection(
                salesOrderId: _salesOrderId,
                orderVersion: 1,
                orderCode: 'DH-001',
                initialProjection: _projection(
                  issuance: IssuanceDisplayState.issued,
                  delivery: DeliveryDisplayState.notSent,
                  actions: const [OrderInvoiceAction.view],
                ),
                repository: repository,
                configurationRepository: configurationRepository,
                onCubitCreated: (c) => cubit = c,
              ),
            ),
          ),
        );
        await tester.pump();

        cubit!.emit(
          cubit!.state.copyWith(
            projection: _projection(
              issuance: IssuanceDisplayState.issued,
              delivery: DeliveryDisplayState.sending,
              actions: const [OrderInvoiceAction.view],
            ).copyWithPending(true),
          ),
        );
        await tester.pump();
        expect(find.text(OrderEInvoiceCopy.badgeIssued), findsOneWidget);

        cubit!.emit(
          cubit!.state.copyWith(
            projection: _projection(
              issuance: IssuanceDisplayState.issued,
              delivery: DeliveryDisplayState.sent,
              actions: const [OrderInvoiceAction.view],
            ),
          ),
        );
        await tester.pump();
        expect(find.text(OrderEInvoiceCopy.badgeIssued), findsOneWidget);
        expect(
          repository.sendCalls,
          isEmpty,
        );

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'th08_e2e_e04_u03_sc04_01 prior sent + secondary attention keeps sent badge',
      (tester) async {
        final repository = FakeEInvoiceRepository.forScenario(
          FakeEInvoiceScenario.sendSheetResend,
        );
        final configurationRepository = FakeEInvoiceConfigurationRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: Scaffold(
              body: OrderEInvoiceSection(
                salesOrderId: _salesOrderId,
                orderVersion: 1,
                orderCode: 'DH-001',
                initialProjection: _projection(
                  issuance: IssuanceDisplayState.issued,
                  delivery: DeliveryDisplayState.sent,
                  hasSecondaryAttention: true,
                  actions: const [OrderInvoiceAction.view],
                ),
                repository: repository,
                configurationRepository: configurationRepository,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();

        expect(
          find.text(OrderEInvoicePostIssueCopy.deliverySent),
          findsOneWidget,
        );
        expect(
          find.text(OrderEInvoicePostIssueCopy.deliverySecondaryAttention),
          findsOneWidget,
        );
        expect(
          find.text(OrderEInvoicePostIssueCopy.deliverySendFailed),
          findsNothing,
        );

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'th08_e2e_e04_u02_sc08_01 UNKNOWN unlocks manual resend once',
      (tester) async {
        final repository = FakeEInvoiceRepository.forScenario(
          FakeEInvoiceScenario.sendSheetUnknown,
        );
        final configurationRepository = FakeEInvoiceConfigurationRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: Scaffold(
              body: OrderEInvoiceSection(
                salesOrderId: _salesOrderId,
                orderVersion: 1,
                orderCode: 'DH-001',
                initialProjection: _projection(
                  issuance: IssuanceDisplayState.issued,
                  delivery: DeliveryDisplayState.unknown,
                  actions: const [OrderInvoiceAction.view],
                ),
                repository: repository,
                configurationRepository: configurationRepository,
                idempotencyKeyFactory: DeterministicOrderEInvoiceIdempotencyKeyFactory(const [
                  'key-unknown-1',
                ]),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(OrderEInvoiceRow));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('action_send')));
        await tester.pumpAndSettle();

        expect(find.byType(OrderInvoiceResendSheet), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);

        await tester.tap(find.byKey(const Key('action_send_invoice')));
        await tester.pumpAndSettle();

        expect(
          repository.sendCalls,
          hasLength(1),
        );

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}

extension on OrderInvoiceProjectionDto {
  OrderInvoiceProjectionDto copyWithPending(bool pending) {
    return OrderInvoiceProjectionDto(
      salesOrderId: salesOrderId,
      issuanceDisplayState: issuanceDisplayState,
      deliveryDisplayState: deliveryDisplayState,
      hasSecondaryAttention: hasSecondaryAttention,
      deliveryPending: pending,
      actions: actions,
    );
  }
}

final class _RecordingLauncher implements IInvoiceViewerLauncher {
  final List<String> launchedUrls = [];

  @override
  Future<bool> launch(String url) async {
    launchedUrls.add(url);
    return true;
  }
}

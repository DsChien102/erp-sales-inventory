import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_misa/e_invoice.dart';

import 'support/slice5_delivery_integration_harness.dart';

void main() {
  late Slice5TestHarness harness;

  setUp(() {
    harness = Slice5TestHarness()..setUp();
  });

  group('TH-08 Slice 5 EP-04 delivery (fakes)', () {
    test('scn_e04_u01_fr01_01', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );

      await harness.startAutoDelivery();
      expect(
        harness.internalClient.countPending(SendInvoiceEmailCommand.type),
        1,
      );
      await harness.runWorker();

      expect(harness.fakeMeInvoiceClient.sendEmailCount, 1);
      expect(harness.state.deliveries.length, 1);
      final delivery = harness.soleDelivery()!;
      expect(delivery.deliveryIntent, 'INITIAL_SEND');
      expect(delivery.triggerType, 'AUTOMATIC');
      expect(delivery.recipientSnapshot['source'], 'CURRENT_PARTNER_PROFILE');
      expect(delivery.status, 'SUCCEEDED');
    });

    test('e2e_e04_u01_sc01_01', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );

      await harness.publishRegisteredEvent(eventId: 'evt-reg-1');
      await harness.runWorker();
      expect(harness.fakeMeInvoiceClient.sendEmailCount, 1);

      // Replay outbox/inbox with same deterministic auto key converges.
      await harness.publishRegisteredEvent(eventId: 'evt-reg-2');
      await harness.runWorker();

      expect(harness.state.deliveries.length, 1);
      expect(harness.fakeMeInvoiceClient.sendEmailCount, 1);
      expect(
        harness.internalClient.countByType(SendInvoiceEmailCommand.type),
        1,
      );
    });

    test('scn_e04_u02_fr08_01', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );

      final result = await harness.sendElectronicInvoice(
        recipientEmail: 'manual.changed@buyer.test',
        idempotencyKey: 'manual-initial-1',
      );
      expect(result.status, DeliveryStatus.processing);
      await harness.runWorker();

      final delivery = harness.soleDelivery()!;
      expect(delivery.deliveryIntent, 'INITIAL_SEND');
      expect(delivery.recipientSnapshot['source'], 'USER_INPUT');
      expect(
        delivery.recipientSnapshot['toEmail'],
        'manual.changed@buyer.test',
      );
      expect(delivery.triggerType, 'MANUAL');
    });

    test('e2e_e04_u02_sc01_01', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );

      await harness.sendElectronicInvoice(
        recipientEmail: 'initial@buyer.test',
        idempotencyKey: 'manual-initial-2',
      );
      await harness.runWorker();
      expect(harness.soleDelivery()!.status, 'SUCCEEDED');

      final sheet = await harness.getSendSheet();
      expect(sheet.mode, SendInvoiceSheetMode.resend);

      await harness.sendElectronicInvoice(
        recipientEmail: 'resend.new@buyer.test',
        idempotencyKey: 'manual-resend-1',
      );
      await harness.runWorker();

      final deliveries = harness.deliveriesChronological();
      expect(deliveries, hasLength(2));
      expect(deliveries[0].deliveryIntent, 'INITIAL_SEND');
      expect(deliveries[1].deliveryIntent, 'RESEND');
      expect(
        deliveries[1].recipientSnapshot['toEmail'],
        'resend.new@buyer.test',
      );
      expect(harness.fakeMeInvoiceClient.sendEmailCount, 2);
    });

    test('scn_e04_u03_fr04_01', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );

      await harness.startAutoDelivery();
      await harness.runWorker();

      final history = await harness.getHistory();
      expect(history.displayState, DeliveryDisplayState.sent);
      expect(history.deliveries, hasLength(1));
      expect(history.deliveries.single.status, DeliveryStatus.succeeded);

      expect(harness.state.resultEvents, hasLength(1));
      final event = harness.state.resultEvents.single;
      expect(event.deliveryStatus, 'succeeded');
      expect(event.deliveryDisplayState, 'sent');
      expect(event.toPayload(), isNot(contains('password')));
      expect(event.toPayload().keys, isNot(contains('recipient_email')));
    });

    test('e2e_e04_u03_sc01_01', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        const MeInvoiceResult.failed('meinvoice_network_timeout'),
      );

      await harness.startAutoDelivery();
      await harness.runWorker();

      final delivery = harness.soleDelivery()!;
      expect(delivery.status, 'UNKNOWN');
      expect(harness.state.reconciliationCases.values, hasLength(1));
      expect(harness.state.attentionEvents, isEmpty);
      expect(harness.fakeMeInvoiceClient.sendEmailCount, 1);

      // Replay worker on same command after SUBMITTED barrier → zero email calls.
      final sendCmd = harness.internalClient.commands.firstWhere(
        (c) => c.commandType == SendInvoiceEmailCommand.type,
      );
      sendCmd.processedAt = null;
      sendCmd.claimToken = null;
      await harness.runWorker();
      expect(harness.fakeMeInvoiceClient.sendEmailCount, 1);

      await harness.runWorker(); // reconcile check 1
      final caseRecord = harness.state.reconciliationCases.values.single;
      expect(caseRecord.status, 'UNRESOLVED');
      expect(harness.state.attentionEvents, hasLength(1));
      expect(
        harness.state.attentionEvents.single.safeErrorCode,
        'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
      );
    });

    test('th08_s5_manual_resend_after_unknown_availability_first', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        const MeInvoiceResult.failed('meinvoice_network_timeout'),
      );
      await harness.startAutoDelivery();
      await harness.runWorker();

      final unknownDelivery = harness.soleDelivery()!;
      expect(unknownDelivery.status, 'UNKNOWN');
      expect(unknownDelivery.deliveryNo, 1);

      final sheet = await harness.getSendSheet();
      expect(sheet.mode, SendInvoiceSheetMode.resend);
      expect(sheet.operationLocked, isFalse);
      expect(sheet.displayState, DeliveryDisplayState.unknown);

      // Auto-send with a new identity after initial UNKNOWN must not create
      // another delivery (prior INITIAL_SEND still claimed).
      final autoReplay = await harness.startAutoDelivery(
        triggerId: 'tr-auto-after-unknown',
        idempotencyKey: '11111111-2222-4333-8444-555555555555',
      );
      expect(autoReplay.disposition, AutoDeliveryDisposition.skipped);
      expect(
        autoReplay.skipReason,
        AutoDeliverySkipReason.initialDeliveryAlreadyClaimed,
      );
      expect(harness.state.deliveries.length, 1);

      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );
      final started = await harness.sendElectronicInvoice(
        recipientEmail: 'resend.after.unknown@buyer.test',
        idempotencyKey: 'manual-after-unknown-1',
      );
      expect(started.deliveryId, isNotNull);
      expect(started.deliveryId, isNot(unknownDelivery.id));

      expect(harness.state.deliveries.length, 2);
      expect(
        harness.state.deliveries.values
            .where((d) => d.id == unknownDelivery.id)
            .single
            .status,
        'UNKNOWN',
      );
      final processing = harness.state.deliveries.values
          .where((d) => d.id == started.deliveryId)
          .single;
      expect(processing.status, 'QUEUED');
      expect(processing.deliveryNo, 2);
      expect(processing.deliveryIntent, 'RESEND');

      final history = await harness.getHistory();
      expect(history.deliveries, hasLength(2));
      expect(
        history.deliveries.map((d) => d.status),
        containsAll([DeliveryStatus.unknown, DeliveryStatus.processing]),
      );

      await expectLater(
        harness.sendElectronicInvoice(
          recipientEmail: 'third@buyer.test',
          idempotencyKey: 'manual-after-unknown-2',
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (e) => e.code,
            'code',
            EInvoiceBlockedCodes.operationInProgress,
          ),
        ),
      );
    });

    test('scn_e04_race_auto_manual_initial', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );

      AutoDeliveryResultDto? autoResult;
      Object? manualError;
      try {
        autoResult = await harness.startAutoDelivery();
      } catch (e) {
        manualError = e;
      }
      try {
        await harness.sendElectronicInvoice(
          recipientEmail: 'race@buyer.test',
          idempotencyKey: 'race-manual-1',
        );
      } catch (e) {
        manualError ??= e;
      }

      expect(harness.state.deliveries.length, 1);
      expect(
        harness.internalClient.countByType(SendInvoiceEmailCommand.type),
        1,
      );
      expect(
        autoResult?.disposition == AutoDeliveryDisposition.started ||
            manualError != null,
        isTrue,
      );
    });

    test('scn_e04_recipient_partner_profile', () async {
      final sheet = await harness.getSendSheet();
      expect(sheet.suggestedEmail, 'partner@buyer.test');
      expect(
        sheet.suggestedEmailSource,
        DeliveryRecipientSource.currentPartnerProfile,
      );
    });

    test('scn_e04_recipient_buyer_snapshot_fallback', () async {
      harness.state.partners[Slice5TestHarness.buyerPartnerId] =
          Slice5PartnerRecipient(
            partnerId: Slice5TestHarness.buyerPartnerId,
            isActive: true,
          );
      final sheet = await harness.getSendSheet();
      expect(sheet.suggestedEmail, 'snapshot@buyer.test');
      expect(
        sheet.suggestedEmailSource,
        DeliveryRecipientSource.buyerInvoiceSnapshot,
      );
    });

    test('scn_e04_recipient_history_suggestion', () async {
      harness.state.partners[Slice5TestHarness.buyerPartnerId] =
          Slice5PartnerRecipient(
            partnerId: Slice5TestHarness.buyerPartnerId,
            isActive: true,
          );
      harness.state.deliveries['del-history'] = Slice5DeliveryRecord(
        id: 'del-history',
        tenantId: Slice5TestHarness.tenantId,
        electronicInvoiceId: Slice5TestHarness.electronicInvoiceId,
        salesOrderId: Slice5TestHarness.salesOrderId,
        deliveryNo: 1,
        deliveryIntent: 'RESEND',
        triggerType: 'MANUAL',
        recipientSnapshot: {
          'toEmail': 'history.partner@buyer.test',
          'source': 'USER_INPUT',
          'buyerPartnerId': Slice5TestHarness.buyerPartnerId,
        },
        idempotencyKey: 'history-success',
        intentHash: 'hash-history',
        initiatedByActorType: 'USER',
        initiatedByActorId: Slice5TestHarness.actorId,
        startedAt: Slice5TestHarness.fixedNow,
      )..status = 'SUCCEEDED';

      final sheet = await harness.getSendSheet();
      expect(sheet.suggestedEmail, 'history.partner@buyer.test');
      expect(
        sheet.suggestedEmailSource,
        DeliveryRecipientSource.lastSuccessfulPartnerDelivery,
      );
    });

    test('scn_e04_recipient_inactive_partner_uses_snapshot', () async {
      harness.state.partners[Slice5TestHarness.buyerPartnerId] =
          Slice5PartnerRecipient(
            partnerId: Slice5TestHarness.buyerPartnerId,
            invoiceEmail: 'inactive@buyer.test',
            isActive: false,
          );
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );
      await harness.startAutoDelivery();
      await harness.runWorker();
      expect(
        harness.soleDelivery()!.recipientSnapshot['source'],
        'BUYER_INVOICE_SNAPSHOT',
      );
    });

    test('scn_e04_recipient_retail_no_partner', () async {
      final invoice =
          harness.state.invoicesBySalesOrder[Slice5TestHarness.salesOrderId]!;
      harness.replaceInvoice(
        Slice5ElectronicInvoice(
          electronicInvoiceId: invoice.electronicInvoiceId,
          tenantId: invoice.tenantId,
          salesOrderId: invoice.salesOrderId,
          providerConnectionId: invoice.providerConnectionId,
          providerInvoiceReference: invoice.providerInvoiceReference,
          invoiceSeries: invoice.invoiceSeries,
          buyerSnapshotEmail: 'retail@buyer.test',
        ),
      );
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );
      await harness.startAutoDelivery();
      await harness.runWorker();
      expect(
        harness.soleDelivery()!.recipientSnapshot['toEmail'],
        'retail@buyer.test',
      );
    });

    test('scn_e04_recipient_effective_vs_snapshot_divergence', () async {
      final invoice =
          harness.state.invoicesBySalesOrder[Slice5TestHarness.salesOrderId]!;
      harness.replaceInvoice(
        Slice5ElectronicInvoice(
          electronicInvoiceId: invoice.electronicInvoiceId,
          tenantId: invoice.tenantId,
          salesOrderId: invoice.salesOrderId,
          providerConnectionId: invoice.providerConnectionId,
          providerInvoiceReference: invoice.providerInvoiceReference,
          invoiceSeries: invoice.invoiceSeries,
          buyerPartnerId: Slice5TestHarness.buyerPartnerId,
          buyerSnapshotEmail: 'snapshot@buyer.test',
          effectiveBuyerEmail: 'effective@buyer.test',
        ),
      );
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );
      await harness.startAutoDelivery();
      await harness.runWorker();
      expect(
        harness.soleDelivery()!.recipientSnapshot['toEmail'],
        'partner@buyer.test',
      );
    });

    test('scn_e04_tenant_isolation', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        MeInvoiceResult.ok(
          MeInvoiceSendEmailResponse.itemized([
            const MeInvoiceSendEmailResultItem(
              transactionId: 'tx-s5-1',
              sendEmailStatus: 3,
            ),
          ]),
        ),
      );
      await harness.startAutoDelivery();
      await harness.runWorker();
      expect(
        harness.state.deliveries.values.every(
          (d) => d.tenantId == Slice5TestHarness.tenantId,
        ),
        isTrue,
      );
    });

    test('scn_e04_auto_skip_policy_off', () async {
      harness.state.autoSendEnabled = false;
      final result = await harness.startAutoDelivery();
      expect(result.disposition, AutoDeliveryDisposition.skipped);
      expect(result.skipReason, AutoDeliverySkipReason.policyOff);
      expect(harness.internalClient.commands, isEmpty);
    });

    test('scn_e04_auto_skip_no_email_capability', () async {
      harness
              .state
              .connections['${Slice5TestHarness.tenantId}:${Slice5TestHarness.providerConnectionId}']!
              .supportsEmailDelivery =
          false;
      await expectLater(
        harness.startAutoDelivery(),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (e) => e.code,
            'code',
            EInvoiceBlockedCodes.deliveryNotSupported,
          ),
        ),
      );
      expect(harness.internalClient.commands, isEmpty);
    });

    test('scn_e04_auto_skip_invalid_recipient', () async {
      harness.state.partners[Slice5TestHarness.buyerPartnerId] =
          Slice5PartnerRecipient(partnerId: Slice5TestHarness.buyerPartnerId);
      final invoice =
          harness.state.invoicesBySalesOrder[Slice5TestHarness.salesOrderId]!;
      harness.replaceInvoice(
        Slice5ElectronicInvoice(
          electronicInvoiceId: invoice.electronicInvoiceId,
          tenantId: invoice.tenantId,
          salesOrderId: invoice.salesOrderId,
          providerConnectionId: invoice.providerConnectionId,
          providerInvoiceReference: invoice.providerInvoiceReference,
          invoiceSeries: invoice.invoiceSeries,
          buyerPartnerId: Slice5TestHarness.buyerPartnerId,
        ),
      );
      final result = await harness.startAutoDelivery();
      expect(result.disposition, AutoDeliveryDisposition.skipped);
      expect(result.skipReason, AutoDeliverySkipReason.invalidOrMissingEmail);
      expect(harness.internalClient.commands, isEmpty);
    });

    test('scn_e04_manual_skip_capability_removed', () async {
      harness
              .state
              .connections['${Slice5TestHarness.tenantId}:${Slice5TestHarness.providerConnectionId}']!
              .supportsEmailDelivery =
          false;
      await expectLater(
        harness.sendElectronicInvoice(
          recipientEmail: 'manual@buyer.test',
          idempotencyKey: 'manual-cap-removed',
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (e) => e.code,
            'code',
            EInvoiceBlockedCodes.deliveryNotSupported,
          ),
        ),
      );
      expect(harness.internalClient.commands, isEmpty);
    });

    test('scn_e04_retry_two_429_then_success', () async {
      harness.fakeMeInvoiceClient
        ..enqueueSendEmailResult(
          const MeInvoiceResult.failed('rate_limited', rateLimited: true),
        )
        ..enqueueSendEmailResult(
          const MeInvoiceResult.failed('rate_limited', rateLimited: true),
        )
        ..enqueueSendEmailResult(
          MeInvoiceResult.ok(
            MeInvoiceSendEmailResponse.itemized([
              const MeInvoiceSendEmailResultItem(
                transactionId: 'tx-s5-1',
                sendEmailStatus: 3,
              ),
            ]),
          ),
        );

      await harness.startAutoDelivery();
      await harness.runWorker();
      await harness.runWorker();
      await harness.runWorker();

      expect(harness.fakeMeInvoiceClient.sendEmailCount, 3);
      expect(harness.soleDelivery()!.status, 'SUCCEEDED');
    });

    test('scn_e04_retry_max_three_exhaustion', () async {
      for (var i = 0; i < 3; i++) {
        harness.fakeMeInvoiceClient.enqueueSendEmailResult(
          const MeInvoiceResult.failed('rate_limited', rateLimited: true),
        );
      }

      await harness.startAutoDelivery();
      await harness.runWorker();
      await harness.runWorker();
      await harness.runWorker();

      expect(harness.soleDelivery()!.status, 'FAILED');
      expect(harness.fakeMeInvoiceClient.sendEmailCount, 3);
    });

    test('scn_e04_dead_letter_queued', () async {
      await harness.startAutoDelivery();
      final delivery = harness.soleDelivery()!;
      expect(delivery.status, 'QUEUED');
      await harness.recordCommandDeadLetter(
        deliveryId: delivery.id,
        retryCount: delivery.retryCount,
      );
      expect(harness.state.deliveries[delivery.id]!.status, 'FAILED');
    });

    test('scn_e04_dead_letter_submitted', () async {
      harness.fakeMeInvoiceClient.enqueueSendEmailResult(
        const MeInvoiceResult.failed('meinvoice_network_timeout'),
      );
      await harness.startAutoDelivery();
      await harness.runWorker();
      expect(harness.soleDelivery()!.status, 'UNKNOWN');
      expect(harness.state.reconciliationCases, isNotEmpty);
    });

    test('scn_e04_capable_reconciliation_terminal', () async {
      final capableHarness = Slice5TestHarness()
        ..setUp(supportsDeliveryObservation: true);
      capableHarness.fakeMeInvoiceClient.enqueueSendEmailResult(
        const MeInvoiceResult.failed('meinvoice_network_timeout'),
      );
      await capableHarness.startAutoDelivery();
      await capableHarness.runWorker();
      capableHarness.capableObservationPort.enqueue(
        const DeliveryObservedSucceeded(providerReference: 'prov-terminal'),
      );
      await capableHarness.runWorker();
      expect(capableHarness.soleDelivery()!.status, 'SUCCEEDED');
      expect(capableHarness.fakeMeInvoiceClient.sendEmailCount, 1);
    });

    test('scn_e04_capable_reconciliation_five_undetermined', () async {
      final capableHarness = Slice5TestHarness()
        ..setUp(supportsDeliveryObservation: true);
      capableHarness.fakeMeInvoiceClient.enqueueSendEmailResult(
        const MeInvoiceResult.failed('meinvoice_network_timeout'),
      );
      await capableHarness.startAutoDelivery();
      await capableHarness.runWorker();

      for (var i = 0; i < 4; i++) {
        capableHarness.capableObservationPort.enqueue(
          const DeliveryObservationUndetermined('PROVIDER_DELIVERY_PENDING'),
        );
        await capableHarness.runWorker();
        expect(
          capableHarness.state.reconciliationCases.values.single.status,
          'PENDING',
        );
      }
      capableHarness.capableObservationPort.enqueue(
        const DeliveryObservationUndetermined('PROVIDER_DELIVERY_PENDING'),
      );
      await capableHarness.runWorker();
      expect(
        capableHarness.state.reconciliationCases.values.single.status,
        'UNRESOLVED',
      );
      expect(capableHarness.state.attentionEvents, hasLength(1));
      expect(capableHarness.fakeMeInvoiceClient.sendEmailCount, 1);
    });

    test('scn_e04_capable_late_terminal_no_new_delivery', () async {
      final capableHarness = Slice5TestHarness()
        ..setUp(supportsDeliveryObservation: true);
      capableHarness.fakeMeInvoiceClient.enqueueSendEmailResult(
        const MeInvoiceResult.failed('meinvoice_network_timeout'),
      );
      await capableHarness.startAutoDelivery();
      await capableHarness.runWorker();
      for (var i = 0; i < 4; i++) {
        capableHarness.capableObservationPort.enqueue(
          const DeliveryObservationUndetermined('PROVIDER_DELIVERY_PENDING'),
        );
        await capableHarness.runWorker();
      }
      expect(capableHarness.state.deliveries.length, 1);
      final beforeEmailCount =
          capableHarness.fakeMeInvoiceClient.sendEmailCount;

      capableHarness.capableObservationPort.enqueue(
        const DeliveryObservedSucceeded(providerReference: 'late-terminal'),
      );
      await capableHarness.runWorker();
      expect(
        capableHarness.fakeMeInvoiceClient.sendEmailCount,
        beforeEmailCount,
      );
      expect(capableHarness.soleDelivery()!.status, 'SUCCEEDED');
    });

    test('scn_e04_prior_success_resend_attention', () async {
      harness.fakeMeInvoiceClient
        ..enqueueSendEmailResult(
          MeInvoiceResult.ok(
            MeInvoiceSendEmailResponse.itemized([
              const MeInvoiceSendEmailResultItem(
                transactionId: 'tx-s5-1',
                sendEmailStatus: 3,
              ),
            ]),
          ),
        )
        ..enqueueSendEmailResult(
          const MeInvoiceResult.failed('meinvoice_network_timeout'),
        );

      await harness.startAutoDelivery();
      await harness.runWorker();

      await harness.sendElectronicInvoice(
        recipientEmail: 'resend.fail@buyer.test',
        idempotencyKey: 'resend-after-success',
      );
      await harness.runWorker();

      final history = await harness.getHistory();
      expect(history.displayState, DeliveryDisplayState.sent);
      expect(history.hasSecondaryAttention, isTrue);
    });
  });
}

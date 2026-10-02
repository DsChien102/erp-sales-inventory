import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  IssuanceReadinessInput readyInput({
    bool orderCompleted = true,
    EffectiveBuyerInvoiceData? buyer,
    List<ReadinessWarning> configWarnings = const [],
  }) => IssuanceReadinessInput(
    orderCompleted: orderCompleted,
    hasElectronicInvoice: false,
    hasActiveOperation: false,
    configReady: true,
    providerConnected: true,
    providerSupportsPreview: true,
    buyer:
        buyer ??
        const EffectiveBuyerInvoiceData(
          buyerType: BuyerType.retail,
          name: 'NTD',
        ),
    buyerCompletionState: BuyerCompletionStatus.locked,
    configWarnings: configWarnings,
  );

  group('RequestInvoicePreviewCommandHandler', () {
    test('scn_e02_u01_fr07_01: ready order enqueues preview and returns pending result', () async {
      final readinessGateway = FakeIssuanceReadinessReadGateway(
        result: readyInput(
          configWarnings: const [
            ReadinessWarning(code: 'W1', message: 'Cảnh báo 1'),
          ],
        ),
      );
      final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final handler = RequestInvoicePreviewCommandHandler(
        readinessGateway: readinessGateway,
        previewGateway: previewGateway,
      );

      final result = await handler.handle(
        RequestInvoicePreviewCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
          expectedOrderVersion: 2,
        ),
      );

      expect(previewGateway.enqueuedFor, 'so-1');
      expect(result.viewerRef, isNull);
      expect(result.failureCode, isNull);
      expect(result.warnings, ['Cảnh báo 1']);
    });

    test('scn_e02_u01_fr08_01: org missing tax code still previews (canPreview)', () async {
      final readinessGateway = FakeIssuanceReadinessReadGateway(
        result: readyInput(
          buyer: const EffectiveBuyerInvoiceData(
            buyerType: BuyerType.organization,
            name: 'Cty A',
            address: 'HN',
          ),
        ),
      );
      final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-2');
      final handler = RequestInvoicePreviewCommandHandler(
        readinessGateway: readinessGateway,
        previewGateway: previewGateway,
      );

      final result = await handler.handle(
        RequestInvoicePreviewCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-2',
          expectedOrderVersion: 1,
        ),
      );

      expect(previewGateway.enqueuedFor, 'so-2');
      expect(result.viewerRef, isNull);
      expect(result.failureCode, isNull);
    });

    test(
      'scn_e02_u01_fr02_01: order not completed blocks preview with ISSUANCE_NOT_READY',
      () async {
        final readinessGateway = FakeIssuanceReadinessReadGateway(
          result: readyInput(orderCompleted: false),
        );
        final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-3');
        final handler = RequestInvoicePreviewCommandHandler(
          readinessGateway: readinessGateway,
          previewGateway: previewGateway,
        );

        expect(
          () => handler.handle(
            RequestInvoicePreviewCommand(
              tenantId: 't1',
              actorId: 'a1',
              salesOrderId: 'so-3',
              expectedOrderVersion: 1,
            ),
          ),
          throwsA(
            isA<EInvoiceBlockedException>().having(
              (e) => e.code,
              'code',
              EInvoiceBlockedCodes.issuanceNotReady,
            ),
          ),
        );
        expect(previewGateway.enqueuedFor, isNull);
      },
    );
  });

  group('GetInvoicePreviewQueryHandler', () {
    test('returns cached preview when present', () async {
      const cachedDto = InvoicePreviewResultDto(
        viewerRef: 'https://preview.provider.com/view/123',
        failureCode: 'PROVIDER_REJECTED_INVOICE_DATA',
        warnings: ['warn'],
      );
      final previewGateway = FakeInvoicePreviewGateway(
        requestId: 'req-1',
        cached: cachedDto,
      );
      final handler = GetInvoicePreviewQueryHandler(
        previewGateway: previewGateway,
      );

      final result = await handler.handle(
        GetInvoicePreviewQuery(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
        ),
      );

      expect(result.viewerRef, 'https://preview.provider.com/view/123');
      expect(result.failureCode, 'PROVIDER_REJECTED_INVOICE_DATA');
      expect(result.warnings, ['warn']);
    });

    test('returns empty pending default when cached is null', () async {
      final previewGateway = FakeInvoicePreviewGateway(
        requestId: 'req-1',
        cached: null,
      );
      final handler = GetInvoicePreviewQueryHandler(
        previewGateway: previewGateway,
      );

      final result = await handler.handle(
        GetInvoicePreviewQuery(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
        ),
      );

      expect(result.viewerRef, isNull);
      expect(result.failureCode, isNull);
      expect(result.warnings, isEmpty);
    });
  });

  group('RequestInvoicePreviewCommandValidator', () {
    final validator = RequestInvoicePreviewCommandValidator();

    test('validates required fields', () async {
      expect(
        () => validator.validate(
          RequestInvoicePreviewCommand(
            tenantId: '',
            actorId: 'a1',
            salesOrderId: 'so1',
            expectedOrderVersion: 1,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => validator.validate(
          RequestInvoicePreviewCommand(
            tenantId: 't1',
            actorId: '',
            salesOrderId: 'so1',
            expectedOrderVersion: 1,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => validator.validate(
          RequestInvoicePreviewCommand(
            tenantId: 't1',
            actorId: 'a1',
            salesOrderId: '',
            expectedOrderVersion: 1,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      await expectLater(
        validator.validate(
          RequestInvoicePreviewCommand(
            tenantId: 't1',
            actorId: 'a1',
            salesOrderId: 'so1',
            expectedOrderVersion: 1,
          ),
        ),
        completes,
      );
    });
  });
}

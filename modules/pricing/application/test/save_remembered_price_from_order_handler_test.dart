import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

void main() {
  group('SaveRememberedPriceFromOrderCommandHandler', () {
    test('creates a new request id distinct from command id', () async {
      final gateway = _RecordingGateway();
      final handler = SaveRememberedPriceFromOrderCommandHandler(
        gateway: gateway,
      );

      final outcome = await handler.handle(_command(id: 'command-1'));

      expect(gateway.callCount, 1);
      expect(gateway.lastRequest, isNotNull);
      expect(gateway.lastRequest!.id, isNot('command-1'));
      expect(outcome.resultType, RememberedPriceResultType.created);
      expect(gateway.lastRequest!.status, RememberedPriceRequestStatus.processed);
    });

    test('passes normalized UTC soldAt, currency, and idempotency into domain',
        () async {
      final gateway = _RecordingGateway();
      final handler = SaveRememberedPriceFromOrderCommandHandler(
        gateway: gateway,
      );

      await handler.handle(
        SaveRememberedPriceFromOrderCommand(
          id: 'command-1',
          tenantId: '00000000-0000-4000-8000-000000000100',
          actorId: '00000000-0000-4000-8000-000000000099',
          sourceOrderId: '00000000-0000-4000-8000-000000000101',
          sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
          customerId: '00000000-0000-4000-8000-000000000103',
          productId: '00000000-0000-4000-8000-000000000104',
          productUnitId: '00000000-0000-4000-8000-000000000105',
          soldPriceMinor: 90000,
          currencyCode: ' vnd ',
          soldAt: DateTime.parse('2026-07-16T08:30:00+07:00'),
          idempotencyKey: ' order-line-102 ',
        ),
      );

      final request = gateway.lastRequest!;
      expect(request.soldAt, DateTime.utc(2026, 7, 16, 1, 30));
      expect(request.soldPrice.currencyCode, 'VND');
      expect(request.idempotencyKey, 'order-line-102');
    });

    test('does not reject nullable customerId', () async {
      final gateway = _RecordingGateway(
        outcome: const RememberedPriceOutcomeDto(
          requestId: 'request-1',
          resultType: RememberedPriceResultType.skipped,
          reasonCode: 'ANONYMOUS_CUSTOMER',
          warnings: [],
          isReplay: false,
        ),
      );
      final handler = SaveRememberedPriceFromOrderCommandHandler(
        gateway: gateway,
      );

      await handler.handle(_command(customerId: null));

      expect(gateway.lastRequest!.customerId, isNull);
      expect(
        gateway.lastRequest!.status,
        RememberedPriceRequestStatus.skipped,
      );
    });

    test('records skipped and blocked outcomes on the aggregate', () async {
      for (final entry in {
        RememberedPriceResultType.skipped: RememberedPriceRequestStatus.skipped,
        RememberedPriceResultType.blocked: RememberedPriceRequestStatus.blocked,
      }.entries) {
        final gateway = _RecordingGateway(
          outcome: RememberedPriceOutcomeDto(
            requestId: 'request-1',
            resultType: entry.key,
            reasonCode: 'TEST_REASON',
            warnings: const [],
            isReplay: false,
          ),
        );
        final handler = SaveRememberedPriceFromOrderCommandHandler(
          gateway: gateway,
        );

        await handler.handle(_command());

        expect(gateway.lastRequest!.status, entry.value);
        expect(gateway.lastRequest!.domainEvents, isNull);
      }
    });

    test('propagates gateway exceptions without conversion', () async {
      final gateway = _RecordingGateway(
        error: const PricingBlockedException(PricingBlockedCodes.systemError),
      );
      final handler = SaveRememberedPriceFromOrderCommandHandler(
        gateway: gateway,
      );

      await expectLater(
        handler.handle(_command()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.systemError,
          ),
        ),
      );
      expect(gateway.lastRequest!.status, RememberedPriceRequestStatus.received);
    });
  });
}

SaveRememberedPriceFromOrderCommand _command({
  String? id,
  String? customerId = '00000000-0000-4000-8000-000000000103',
}) => SaveRememberedPriceFromOrderCommand(
  id: id,
  tenantId: '00000000-0000-4000-8000-000000000100',
  actorId: '00000000-0000-4000-8000-000000000099',
  sourceOrderId: '00000000-0000-4000-8000-000000000101',
  sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
  customerId: customerId,
  productId: '00000000-0000-4000-8000-000000000104',
  productUnitId: '00000000-0000-4000-8000-000000000105',
  soldPriceMinor: 90000,
  currencyCode: 'VND',
  soldAt: DateTime.utc(2026, 7, 16, 1, 30),
  idempotencyKey: 'order-line-102',
);

final class _RecordingGateway implements IRememberedPriceGateway {
  _RecordingGateway({
    this.outcome = const RememberedPriceOutcomeDto(
      requestId: 'request-1',
      resultType: RememberedPriceResultType.created,
      ruleId: 'rule-1',
      ruleVersion: 1,
      warnings: [],
      isReplay: false,
    ),
    this.error,
  });

  final RememberedPriceOutcomeDto outcome;
  final PricingBlockedException? error;
  int callCount = 0;
  RememberedPriceRequest? lastRequest;

  @override
  Future<RememberedPriceOutcomeDto> save(RememberedPriceRequest request) async {
    callCount++;
    lastRequest = request;
    if (error != null) {
      throw error!;
    }
    return RememberedPriceOutcomeDto(
      requestId: request.id,
      resultType: outcome.resultType,
      ruleId: outcome.ruleId,
      ruleVersion: outcome.ruleVersion,
      reasonCode: outcome.reasonCode,
      warnings: outcome.warnings,
      isReplay: outcome.isReplay,
    );
  }
}

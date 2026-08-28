import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

final class _FakeIssuanceReadinessReadGateway implements IIssuanceReadinessReadGateway {
  _FakeIssuanceReadinessReadGateway(this._input);

  final IssuanceReadinessInput _input;
  String? lastTenantId;
  String? lastActorId;
  String? lastSalesOrderId;

  @override
  Future<IssuanceReadinessInput> load({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    lastTenantId = tenantId;
    lastActorId = actorId;
    lastSalesOrderId = salesOrderId;
    return _input;
  }
}

void main() {
  group('GetIssuanceReadinessQueryHandler', () {
    test('evaluates ready input correctly and delegates to gateway', () async {
      const input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: EffectiveBuyerInvoiceData(
          buyerType: BuyerType.individual,
          name: 'Nguyen Van A',
          email: 'a@example.com',
          address: '123 St',
        ),
        buyerCompletionState: BuyerCompletionStatus.open,
      );

      final gateway = _FakeIssuanceReadinessReadGateway(input);
      final handler = GetIssuanceReadinessQueryHandler(
        readinessGateway: gateway,
      );

      final result = await handler.handle(
        GetIssuanceReadinessQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-123',
        ),
      );

      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastActorId, 'actor-1');
      expect(gateway.lastSalesOrderId, 'order-123');
      expect(result.level, IssuanceReadinessLevel.ready);
      expect(result.blockers, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.buyerCompletionState, BuyerCompletionStatus.open);
    });

    test('evaluates notReady with blockers correctly', () async {
      const input = IssuanceReadinessInput(
        orderCompleted: false,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: EffectiveBuyerInvoiceData(
          buyerType: BuyerType.individual,
          name: 'Nguyen Van A',
          email: 'a@example.com',
          address: '123 St',
        ),
        buyerCompletionState: BuyerCompletionStatus.open,
      );

      final gateway = _FakeIssuanceReadinessReadGateway(input);
      final handler = GetIssuanceReadinessQueryHandler(
        readinessGateway: gateway,
      );

      final result = await handler.handle(
        GetIssuanceReadinessQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-123',
        ),
      );

      expect(result.level, IssuanceReadinessLevel.notReady);
      expect(result.blockers, hasLength(1));
      expect(result.blockers.first.code, 'ORDER_NOT_COMPLETED');
      expect(result.blockers.first.message, 'Đơn hàng chưa Hoàn tất');
    });
  });
}

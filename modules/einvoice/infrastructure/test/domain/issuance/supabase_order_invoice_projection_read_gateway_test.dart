import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_order_invoice_projection_read_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_einvoice_rpc_supabase.dart';

SupabaseSchemaRpcClient _rpcClient(FakeEinvoiceRpcSupabase supabase) {
  return SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'einvoice',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );
}

void main() {
  group('SupabaseOrderInvoiceProjectionReadGateway', () {
    test('maps projection row with issue action for failed status', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('get_order_invoice_projection', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_actor_id': 'actor-1',
            'p_sales_order_id': 'order-1',
          });
          return [
            {
              'sales_order_id': 'order-1',
              'issuance_display_state': 'failed',
              'delivery_display_state': 'NOT_SENT',
              'has_secondary_attention': false,
              'actions': ['issue'],
            },
          ];
        });
      final gateway = SupabaseOrderInvoiceProjectionReadGateway(
        rpcClient: _rpcClient(supabase),
      );

      final projection = await gateway.getBySalesOrder(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
      );

      expect(projection.salesOrderId, 'order-1');
      expect(projection.issuanceDisplayState, IssuanceDisplayState.failed);
      expect(projection.deliveryDisplayState, DeliveryDisplayState.notSent);
      expect(projection.hasSecondaryAttention, isFalse);
      expect(projection.actions, [OrderInvoiceAction.issue]);
    });

    test(
      'maps projection row with empty actions for processing status',
      () async {
        final supabase = FakeEinvoiceRpcSupabase()
          ..registerHandler('get_order_invoice_projection', (params) async {
            return [
              {
                'sales_order_id': 'order-1',
                'issuance_display_state': 'processing',
                'delivery_display_state': 'SENDING',
                'has_secondary_attention': false,
                'actions': <String>[],
              },
            ];
          });
        final gateway = SupabaseOrderInvoiceProjectionReadGateway(
          rpcClient: _rpcClient(supabase),
        );

        final projection = await gateway.getBySalesOrder(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        );

        expect(projection.salesOrderId, 'order-1');
        expect(
          projection.issuanceDisplayState,
          IssuanceDisplayState.processing,
        );
        expect(projection.deliveryDisplayState, DeliveryDisplayState.sending);
        expect(projection.actions, isEmpty);
      },
    );

    test('maps projection row with view action for issued status', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('get_order_invoice_projection', (params) async {
          return [
            {
              'sales_order_id': 'order-1',
              'issuance_display_state': 'issued',
              'delivery_display_state': 'SENT',
              'has_secondary_attention': true,
              'actions': ['view'],
            },
          ];
        });
      final gateway = SupabaseOrderInvoiceProjectionReadGateway(
        rpcClient: _rpcClient(supabase),
      );

      final projection = await gateway.getBySalesOrder(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
      );

      expect(projection.salesOrderId, 'order-1');
      expect(projection.issuanceDisplayState, IssuanceDisplayState.issued);
      expect(projection.deliveryDisplayState, DeliveryDisplayState.sent);
      expect(projection.hasSecondaryAttention, isTrue);
      expect(projection.actions, [OrderInvoiceAction.view]);
    });

    test('fails closed on unknown display state', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('get_order_invoice_projection', (_) async {
          return [
            {
              'sales_order_id': 'order-1',
              'issuance_display_state': 'UNKNOWN_STATE',
              'actions': ['issue'],
            },
          ];
        });
      final gateway = SupabaseOrderInvoiceProjectionReadGateway(
        rpcClient: _rpcClient(supabase),
      );

      await expectLater(
        gateway.getBySalesOrder(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
        throwsA(isA<EInvoiceBlockedException>()),
      );
    });
  });
}

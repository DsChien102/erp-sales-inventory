import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/supabase_delivery_read_gateway.dart';
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
  group('SupabaseDeliveryReadGateway', () {
    late FakeEinvoiceRpcSupabase supabase;
    late SupabaseDeliveryReadGateway gateway;

    setUp(() {
      supabase = FakeEinvoiceRpcSupabase();
      gateway = SupabaseDeliveryReadGateway(rpcClient: _rpcClient(supabase));
    });

    test(
      'getSendSheetContext maps nullable suggestion and history items',
      () async {
        final startedAt = DateTime.utc(2026, 9, 1, 10);
        supabase.registerHandler('get_send_invoice_sheet_context', (
          params,
        ) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_actor_id': 'actor-1',
            'p_sales_order_id': 'order-1',
          });
          return [
            {
              'mode': 'resend',
              'suggested_email': 'buyer@example.com',
              'suggested_email_source': 'LAST_INVOICE_DELIVERY',
              'history': [
                {
                  'deliveryId': 'd-1',
                  'deliveryNo': 1,
                  'kind': 'INITIAL_SEND',
                  'triggerType': 'AUTOMATIC',
                  'recipientEmail': 'buyer@example.com',
                  'status': 'SUCCEEDED',
                  'initiatedByActorType': 'SYSTEM',
                  'initiatedByActorId': null,
                  'startedAt': startedAt.toIso8601String(),
                  'completedAt': startedAt
                      .add(const Duration(minutes: 1))
                      .toIso8601String(),
                  'failureCode': null,
                },
              ],
              'operation_locked': false,
              'display_state': 'SENT',
            },
          ];
        });

        final sheet = await gateway.getSendSheetContext(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        );

        expect(sheet.mode, SendInvoiceSheetMode.resend);
        expect(sheet.suggestedEmail, 'buyer@example.com');
        expect(
          sheet.suggestedEmailSource,
          DeliveryRecipientSource.lastInvoiceDelivery,
        );
        expect(sheet.operationLocked, isFalse);
        expect(sheet.displayState, DeliveryDisplayState.sent);
        expect(sheet.history, hasLength(1));
        expect(sheet.history.single.kind, DeliveryKind.initial);
        expect(sheet.history.single.triggerType, DeliveryTriggerType.automatic);
        expect(sheet.history.single.status, DeliveryStatus.succeeded);
        expect(
          sheet.history.single.initiatedByActorType,
          DeliveryActorType.system,
        );
        expect(sheet.history.single.initiatedByActorId, isNull);
      },
    );

    test('getSendSheetContext allows blank suggestion', () async {
      supabase.registerHandler('get_send_invoice_sheet_context', (_) async {
        return [
          {
            'mode': 'send',
            'suggested_email': null,
            'suggested_email_source': null,
            'history': <Map<String, dynamic>>[],
            'operation_locked': true,
            'display_state': 'SENDING',
          },
        ];
      });

      final sheet = await gateway.getSendSheetContext(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
      );

      expect(sheet.mode, SendInvoiceSheetMode.send);
      expect(sheet.suggestedEmail, isNull);
      expect(sheet.suggestedEmailSource, isNull);
      expect(sheet.operationLocked, isTrue);
      expect(sheet.displayState, DeliveryDisplayState.sending);
      expect(sheet.history, isEmpty);
    });

    test('getHistory maps secondary attention after prior success', () async {
      final startedAt = DateTime.utc(2026, 9, 2, 8);
      supabase.registerHandler('get_invoice_delivery_history', (params) async {
        expect(params, {
          'p_tenant_id': 'tenant-1',
          'p_actor_id': 'actor-1',
          'p_sales_order_id': 'order-1',
        });
        return [
          {
            'deliveries': [
              {
                'deliveryId': 'd-1',
                'deliveryNo': 1,
                'kind': 'INITIAL_SEND',
                'triggerType': 'MANUAL',
                'recipientEmail': 'a@example.com',
                'status': 'SUCCEEDED',
                'initiatedByActorType': 'USER',
                'initiatedByActorId': 'actor-1',
                'startedAt': startedAt.toIso8601String(),
                'completedAt': startedAt.toIso8601String(),
                'failureCode': null,
              },
              {
                'deliveryId': 'd-2',
                'deliveryNo': 2,
                'kind': 'RESEND',
                'triggerType': 'MANUAL',
                'recipientEmail': 'a@example.com',
                'status': 'UNKNOWN',
                'initiatedByActorType': 'USER',
                'initiatedByActorId': 'actor-1',
                'startedAt': startedAt
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
                'completedAt': startedAt
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
                'failureCode': 'PROVIDER_TIMEOUT',
              },
            ],
            'display_state': 'SENT',
            'has_secondary_attention': true,
          },
        ];
      });

      final history = await gateway.getHistory(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
      );

      expect(history.displayState, DeliveryDisplayState.sent);
      expect(history.hasSecondaryAttention, isTrue);
      expect(history.deliveries, hasLength(2));
      expect(history.deliveries.last.status, DeliveryStatus.unknown);
      expect(history.deliveries.last.kind, DeliveryKind.resend);
      expect(history.deliveries.last.failureCode, 'PROVIDER_TIMEOUT');
    });

    test('maps NO_PERMISSION safely', () async {
      supabase.registerHandler('get_invoice_delivery_history', (_) async {
        throw RpcException('NO_PERMISSION: einvoice.send required');
      });

      await expectLater(
        gateway.getHistory(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (e) => e.code,
            'code',
            EInvoiceBlockedCodes.noPermission,
          ),
        ),
      );
    });
  });
}

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('SupabaseSalesReceiptGateway', () {
    test('S14 maps the complete immutable receipt document', () async {
      final rpc = _FakeRpcClient(response: _receiptJson());
      final gateway = SupabaseSalesReceiptGateway(rpcClient: rpc);

      final dto = await gateway.generate(_generateCommand());

      expect(rpc.lastProcedure, 'generate_sales_receipt');
      expect(rpc.lastParams?['p_command_id'], isA<String>());
      expect(rpc.lastParams?['p_tenant_id'], 'tenant-1');
      expect(rpc.lastParams?['p_actor_id'], 'actor-1');
      expect(rpc.lastParams?['p_sales_order_id'], 'order-1');
      expect(rpc.lastParams?['p_idempotency_key'], 'idem-1');
      expect(rpc.lastParams, isNot(contains('command_id')));
      expect(rpc.lastParams, isNot(contains('tenant_id')));
      expect(rpc.lastParams, isNot(contains('actor_id')));
      expect(dto.status, SalesReceiptStatus.generated);
      expect(dto.generatedAt, DateTime.utc(2026, 8, 12, 2, 41));
      expect(dto.document.soldAt, DateTime.utc(2026, 8, 12, 2, 41));
      expect(dto.document.lines.single.product.sku, isNull);
      expect(dto.document.lines.single.unit.unitCode, isNull);
      expect(dto.document.payments.single.method, SalesPaymentMethod.cash);
      expect(dto.document.dueAt, isNull);
      expect(() => dto.document.lines.add(dto.document.lines.single), throwsUnsupportedError);
      expect(() => dto.document.payments.add(dto.document.payments.single), throwsUnsupportedError);
    });

    test('legacy receipt without settlementSnapshot still maps', () async {
      final rpc = _FakeRpcClient(response: _receiptJson());
      final gateway = SupabaseSalesReceiptGateway(rpcClient: rpc);

      final dto = await gateway.generate(_generateCommand());

      expect(dto.document.orderTotal.amountMinor, 100000);
      expect(dto.document.settlementSnapshot, isNull);
    });

    test('settlementSnapshot does not replace original orderTotal', () async {
      final json = _receiptJson();
      final document = Map<String, dynamic>.from(json['document'] as Map);
      document['orderTotal'] = <String, dynamic>{
        'amountMinor': 1000000,
        'currencyCode': 'VND',
      };
      document['settlementSnapshot'] = <String, dynamic>{
        'originalPayable': <String, dynamic>{'amountMinor': 1000000, 'currencyCode': 'VND'},
        'adjustment': <String, dynamic>{'amountMinor': -200000, 'currencyCode': 'VND'},
        'currentPayable': <String, dynamic>{'amountMinor': 800000, 'currencyCode': 'VND'},
        'collected': <String, dynamic>{'amountMinor': 0, 'currencyCode': 'VND'},
        'refunded': <String, dynamic>{'amountMinor': 0, 'currencyCode': 'VND'},
        'netCollected': <String, dynamic>{'amountMinor': 0, 'currencyCode': 'VND'},
        'outstanding': <String, dynamic>{'amountMinor': 800000, 'currencyCode': 'VND'},
        'adjustmentSources': <Map<String, dynamic>>[
          <String, dynamic>{
            'sourceKind': 'return_exchange',
            'sourceId': 'slip-1',
            'amount': <String, dynamic>{'amountMinor': -200000, 'currencyCode': 'VND'},
          },
        ],
      };
      json['document'] = document;
      final rpc = _FakeRpcClient(response: json);
      final gateway = SupabaseSalesReceiptGateway(rpcClient: rpc);

      final dto = await gateway.generate(_generateCommand());

      expect(dto.document.orderTotal.amountMinor, 1000000);
      expect(dto.document.settlementSnapshot?.adjustment.amountMinor, -200000);
      expect(dto.document.settlementSnapshot?.currentPayable.amountMinor, 800000);
      expect(dto.document.settlementSnapshot?.adjustmentSources.single.sourceKind, 'return_exchange');
    });

    test('S14 activity returns the same complete receipt envelope', () async {
      final rpc = _FakeRpcClient(response: _receiptJson());
      final gateway = SupabaseSalesReceiptGateway(rpcClient: rpc);

      final dto = await gateway.recordPrinted(
        RecordSalesReceiptPrintedCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          receiptId: 'receipt-1',
          idempotencyKey: 'idem-1',
          payloadHash: 'hash-1',
          correlationId: 'corr-1',
        ),
      );

      expect(rpc.lastProcedure, 'record_sales_receipt_activity');
      expect(rpc.lastParams?['p_activity_type'], 'printed');
      expect(rpc.lastParams?['p_receipt_id'], 'receipt-1');
      expect(rpc.lastParams?['p_idempotency_key'], 'idem-1');
      expect(rpc.lastParams, isNot(contains('activity_type')));
      expect(rpc.lastParams, isNot(contains('receipt_id')));
      expect(dto.document.receiptNumber, 'PBH-20260812-0129');
      expect(dto.document.orderTotal.currencyCode, 'VND');
    });

    test('S14 maps IDEMPOTENCY_CONFLICT envelope to SalesContractException', () async {
      final rpc = _FakeRpcClient(
        error: RpcException(
          jsonEncode({'code': 'IDEMPOTENCY_CONFLICT', 'message': 'Key reused.'}),
        ),
      );
      final gateway = SupabaseSalesReceiptGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.generate(_generateCommand()),
        throwsA(
          isA<SalesContractException>().having((e) => e.code, 'code', 'IDEMPOTENCY_CONFLICT'),
        ),
      );
    });

    for (final malformed in <String, Map<String, dynamic>>{
      'document': {
        'receiptId': 'receipt-1',
        'salesOrderId': 'order-1',
        'version': 1,
        'status': 'generated',
        'generatedAt': '2026-08-12T02:41:00.000Z',
      },
      'lines': _withDocumentField('lines', <String, dynamic>{}),
      'quantityMicros': _withLineField('quantityMicros', 'not-an-integer'),
      'enum': _withDocumentField('payments', <dynamic>[
        <String, dynamic>{
          'method': 'crypto',
          'amount': <String, dynamic>{'amountMinor': 60000, 'currencyCode': 'VND'},
          'status': 'confirmed',
        },
      ]),
      'money': _withDocumentField('orderTotal', <String, dynamic>{
        'amountMinor': 100000,
        'currencyCode': '',
      }),
    }.entries) {
      test('S14 translates malformed ${malformed.key} to DEPENDENCY_UNAVAILABLE', () async {
        final gateway = SupabaseSalesReceiptGateway(
          rpcClient: _FakeRpcClient(response: malformed.value),
        );

        await expectLater(
          () => gateway.getReceipt(
            GetSalesReceiptQuery(tenantId: 'tenant-1', actorId: 'actor-1', receiptId: 'receipt-1'),
          ),
          throwsA(
            isA<SalesContractException>().having((e) => e.code, 'code', 'DEPENDENCY_UNAVAILABLE'),
          ),
        );
      });
    }
  });
}

GenerateSalesReceiptCommand _generateCommand() => GenerateSalesReceiptCommand(
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  salesOrderId: 'order-1',
  idempotencyKey: 'idem-1',
  payloadHash: 'hash-1',
  correlationId: 'corr-1',
);

Map<String, dynamic> _withDocumentField(String key, Object? value) {
  final json = _receiptJson();
  (json['document'] as Map<String, dynamic>)[key] = value;
  return json;
}

Map<String, dynamic> _withLineField(String key, Object? value) {
  final json = _receiptJson();
  final document = json['document'] as Map<String, dynamic>;
  (document['lines'] as List<dynamic>).single[key] = value;
  return json;
}

Map<String, dynamic> _receiptJson() => <String, dynamic>{
  'receiptId': 'receipt-1',
  'salesOrderId': 'order-1',
  'version': 1,
  'status': 'generated',
  'generatedAt': '2026-08-12T02:41:00.000Z',
  'document': <String, dynamic>{
    'receiptNumber': 'PBH-20260812-0129',
    'orderNumber': 'SO-000129',
    'soldAt': '2026-08-12T02:41:00.000Z',
    'store': <String, dynamic>{
      'storeId': 'store-1',
      'storeCode': 'HCM-01',
      'displayName': 'Store One',
    },
    'seller': <String, dynamic>{'actorId': 'actor-1', 'displayName': 'Minh Anh'},
    'customer': <String, dynamic>{
      'customerId': 'customer-1',
      'displayName': 'Nguyen Van An',
      'phoneNumber': null,
      'taxCode': null,
      'existingDebtMinor': 0,
    },
    'lines': <Map<String, dynamic>>[
      <String, dynamic>{
        'lineId': 'line-1',
        'product': <String, dynamic>{
          'productId': 'product-1',
          'sku': null,
          'displayName': 'Vaccine A',
        },
        'unit': <String, dynamic>{
          'productUnitId': 'unit-1',
          'unitCode': null,
          'unitName': 'Vial',
        },
        'quantityMicros': 1000000,
        'unitPrice': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
        'discountTotal': <String, dynamic>{'amountMinor': 0, 'currencyCode': 'VND'},
        'lineTotal': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
      },
    ],
    'subtotal': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
    'discountTotal': <String, dynamic>{'amountMinor': 0, 'currencyCode': 'VND'},
    'orderTotal': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
    'paidTotal': <String, dynamic>{'amountMinor': 60000, 'currencyCode': 'VND'},
    'outstandingTotal': <String, dynamic>{'amountMinor': 40000, 'currencyCode': 'VND'},
    'payments': <Map<String, dynamic>>[
      <String, dynamic>{
        'method': 'cash',
        'amount': <String, dynamic>{'amountMinor': 60000, 'currencyCode': 'VND'},
        'status': 'confirmed',
      },
    ],
    'dueAt': null,
  },
};

final class _FakeRpcClient implements IRpcClient {
  _FakeRpcClient({this.response = const <String, dynamic>{}, this.error});

  final Map<String, dynamic> response;
  final Object? error;
  String? lastProcedure;
  Map<String, dynamic>? lastParams;

  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async {
    lastProcedure = procedure;
    lastParams = params;
    if (error != null) throw error!;
    return response;
  }
}

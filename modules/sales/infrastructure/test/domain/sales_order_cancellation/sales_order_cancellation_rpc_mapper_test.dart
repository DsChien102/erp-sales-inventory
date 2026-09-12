import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';

void main() {
  group('SalesOrderCancellationRpcMapper', () {
    test('maps confirm parameters with exact wire keys', () {
      final command = _confirmCommand();

      expect(
        SalesOrderCancellationRpcMapper.confirmParams(command),
        <String, dynamic>{
          'command_id': command.id,
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'sales_order_id': 'order-1',
          'reason_text': 'Customer request',
          'idempotency_key': 'idem-1',
          'payload_hash': 'hash-1',
          'correlation_id': 'corr-1',
          'causation_id': null,
          'expected_order_version': 7,
          'expected_settlement_version': 3,
        },
      );
    });

    test('maps precheck query parameters', () {
      expect(
        SalesOrderCancellationRpcMapper.precheckParams(
          PrecheckSalesOrderCancellationQuery(
            id: 'query-1',
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            expectedSourceVersion: 4,
          ),
        ),
        <String, dynamic>{
          'query_id': 'query-1',
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'sales_order_id': 'order-1',
          'expected_source_version': 4,
        },
      );
    });

    test('maps detail query parameters', () {
      expect(
        SalesOrderCancellationRpcMapper.detailParams(
          GetSalesOrderCancellationQuery(
            id: 'query-2',
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            expectedSourceVersion: 8,
          ),
        ),
        <String, dynamic>{
          'query_id': 'query-2',
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'sales_order_id': 'order-1',
          'expected_source_version': 8,
        },
      );
    });

    test('decodes a ready precheck', () {
      final dto = SalesOrderCancellationRpcMapper.precheckFromJson(
        <String, dynamic>{
          'allowed': true,
          'sourceVersion': 7,
          'sourceSettlementVersion': 3,
          'blockers': <Object?>[],
        },
      );

      expect(dto.allowed, isTrue);
      expect(dto.sourceVersion, 7);
      expect(dto.sourceSettlementVersion, 3);
      expect(dto.blockers, isEmpty);
    });

    test('decodes a blocked precheck with blockers', () {
      final dto = SalesOrderCancellationRpcMapper.precheckFromJson(
        <String, dynamic>{
          'allowed': false,
          'sourceVersion': 2,
          'sourceSettlementVersion': 1,
          'blockers': <Map<String, dynamic>>[
            <String, dynamic>{
              'code': 'PAYMENT_COLLECTED',
              'message': 'Net confirmed collection is positive.',
              'field': 'settlement',
            },
          ],
        },
      );

      expect(dto.allowed, isFalse);
      expect(dto.blockers.single.code, 'PAYMENT_COLLECTED');
      expect(dto.blockers.single.field, 'settlement');
    });

    test('decodes confirmed, processing, and completed results', () {
      expect(
        SalesOrderCancellationRpcMapper.resultFromJson(_resultJson('confirmed')).status,
        SalesOrderCancellationStatus.confirmed,
      );
      expect(
        SalesOrderCancellationRpcMapper.resultFromJson(_resultJson('processing')).status,
        SalesOrderCancellationStatus.processing,
      );
      expect(
        SalesOrderCancellationRpcMapper.resultFromJson(_resultJson('completed')).status,
        SalesOrderCancellationStatus.completed,
      );
    });

    test('decodes detail reason and cancelledAt as UTC', () {
      final detail = SalesOrderCancellationRpcMapper.detailFromJson(<String, dynamic>{
        'result': _resultJson('completed'),
        'reason': <String, dynamic>{
          'reasonText': 'Customer request',
        },
        'cancelledAt': '2026-08-10T02:03:04Z',
        'cancelledByActorId': 'actor-7',
        'cancelledByActorName': 'Minh Anh',
        'netConfirmedCollectionMinor': 0,
      });

      expect(detail.result.cancellationId, 'cancellation-1');

      expect(detail.reason.reasonText, 'Customer request');
      expect(detail.cancelledAt.isUtc, isTrue);
      expect(detail.cancelledAt, DateTime.utc(2026, 8, 10, 2, 3, 4));
      expect(detail.cancelledByActorId, 'actor-7');
      expect(detail.cancelledByActorName, 'Minh Anh');
      expect(detail.netConfirmedCollectionMinor, 0);
    });

    test('decodes blank reasonText and ignores legacy reasonCode', () {
      final detail = SalesOrderCancellationRpcMapper.detailFromJson(<String, dynamic>{
        'result': _resultJson('completed'),
        'reason': <String, dynamic>{
          'reasonCode': 'CUSTOMER_REQUEST',
          'reasonText': '',
        },
        'cancelledAt': '2026-08-10T09:00:00+07:00',
        'cancelledByActorId': 'actor-7',
        'netConfirmedCollectionMinor': 0,
      });

      expect(detail.reason.reasonText, isEmpty);
      expect(detail.cancelledAt.isUtc, isTrue);
      expect(detail.cancelledAt, DateTime.utc(2026, 8, 10, 2, 0, 0));
    });

    test('rejects null reasonText', () {
      expect(
        () => SalesOrderCancellationRpcMapper.detailFromJson(<String, dynamic>{
          'result': _resultJson('completed'),
          'reason': <String, dynamic>{
            'reasonCode': 'CUSTOMER_REQUEST',
            'reasonText': null,
          },
          'cancelledAt': '2026-08-10T02:03:04Z',
        }),
        throwsFormatException,
      );
    });

    test('rejects missing required precheck fields', () {
      expect(
        () => SalesOrderCancellationRpcMapper.precheckFromJson(<String, dynamic>{
          'allowed': true,
          'sourceVersion': 1,
          'blockers': <Object?>[],
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown precheck fields', () {
      expect(
        () => SalesOrderCancellationRpcMapper.precheckFromJson(<String, dynamic>{
          'allowed': true,
          'sourceVersion': 1,
          'sourceSettlementVersion': 1,
          'blockers': <Object?>[],
          'extra': true,
        }),
        throwsFormatException,
      );
    });

    test('rejects missing required result fields', () {
      expect(
        () => SalesOrderCancellationRpcMapper.resultFromJson(<String, dynamic>{
          'cancellationId': 'cancellation-1',
          'salesOrderId': 'order-1',
          'status': 'confirmed',
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown result fields', () {
      expect(
        () => SalesOrderCancellationRpcMapper.resultFromJson(<String, dynamic>{
          ..._resultJson('confirmed'),
          'extra': 'nope',
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown result status', () {
      expect(
        () => SalesOrderCancellationRpcMapper.resultFromJson(_resultJson('pending')),
        throwsFormatException,
      );
    });

    test('rejects missing detail fields', () {
      expect(
        () => SalesOrderCancellationRpcMapper.detailFromJson(<String, dynamic>{
          'result': _resultJson('confirmed'),
          'reason': <String, dynamic>{
            'reasonCode': 'CUSTOMER_REQUEST',
            'reasonText': 'Customer request',
          },
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown detail fields', () {
      expect(
        () => SalesOrderCancellationRpcMapper.detailFromJson(<String, dynamic>{
          'result': _resultJson('confirmed'),
          'reason': <String, dynamic>{
            'reasonCode': 'CUSTOMER_REQUEST',
            'reasonText': 'Customer request',
          },
          'cancelledAt': '2026-08-10T02:03:04Z',
          'extra': 1,
        }),
        throwsFormatException,
      );
    });

    test('list reasons params are the exact snake_case identity triple', () {
      final params = SalesOrderCancellationRpcMapper.listReasonsParams(
        ListSalesOrderCancellationReasonsQuery(
          id: 'query-1',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
        ),
      );

      expect(params, <String, dynamic>{
        'query_id': 'query-1',
        'tenant_id': 'tenant-1',
        'actor_id': 'actor-1',
      });
    });

    test('decodes reason policies preserving backend order', () {
      final policies = SalesOrderCancellationRpcMapper.reasonsFromJson(
        <String, dynamic>{
          'items': <Object?>[
            <String, dynamic>{
              'reasonCode': 'DUPLICATE',
              'displayName': 'Nhập trùng đơn',
              'requiresNote': false,
              'sortOrder': 100,
            },
            <String, dynamic>{
              'reasonCode': 'OTHER',
              'displayName': 'Khác',
              'requiresNote': true,
              'sortOrder': 900,
            },
          ],
        },
      );

      expect(policies, hasLength(2));
      expect(policies.first.reasonCode, 'DUPLICATE');
      expect(policies.first.requiresNote, isFalse);
      expect(policies.last.reasonCode, 'OTHER');
      expect(policies.last.displayName, 'Khác');
      expect(policies.last.requiresNote, isTrue);
      expect(policies.last.sortOrder, 900);
    });

    test('decodes an empty reason catalog to an empty list', () {
      final policies = SalesOrderCancellationRpcMapper.reasonsFromJson(
        <String, dynamic>{'items': <Object?>[]},
      );
      expect(policies, isEmpty);
    });

    test('rejects an unknown envelope key', () {
      expect(
        () => SalesOrderCancellationRpcMapper.reasonsFromJson(<String, dynamic>{
          'items': <Object?>[],
          'extra': true,
        }),
        throwsFormatException,
      );
    });

    test('rejects a reason policy with an unknown key', () {
      expect(
        () => SalesOrderCancellationRpcMapper.reasonsFromJson(<String, dynamic>{
          'items': <Object?>[
            <String, dynamic>{
              'reasonCode': 'OTHER',
              'displayName': 'Khác',
              'requiresNote': true,
              'sortOrder': 900,
              'extra': 1,
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('rejects a reason policy missing a required key', () {
      expect(
        () => SalesOrderCancellationRpcMapper.reasonsFromJson(<String, dynamic>{
          'items': <Object?>[
            <String, dynamic>{
              'reasonCode': 'OTHER',
              'displayName': 'Khác',
              'requiresNote': true,
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('rejects a wrong-typed requiresNote', () {
      expect(
        () => SalesOrderCancellationRpcMapper.reasonsFromJson(<String, dynamic>{
          'items': <Object?>[
            <String, dynamic>{
              'reasonCode': 'OTHER',
              'displayName': 'Khác',
              'requiresNote': 'yes',
              'sortOrder': 900,
            },
          ],
        }),
        throwsFormatException,
      );
    });
  });
}

ConfirmSalesOrderCancellationCommand _confirmCommand() => ConfirmSalesOrderCancellationCommand(
  id: 'command-1',
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  salesOrderId: 'order-1',
  reason: const CancellationReasonDto(
    reasonText: 'Customer request',
  ),
  idempotencyKey: 'idem-1',
  payloadHash: 'hash-1',
  correlationId: 'corr-1',
  expectedVersion: 7,
  expectedSettlementVersion: 3,
);

Map<String, dynamic> _resultJson(String status) => <String, dynamic>{
  'cancellationId': 'cancellation-1',
  'salesOrderId': 'order-1',
  'salesOrderVersion': 8,
  'status': status,
};

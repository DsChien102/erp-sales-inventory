import 'package:erp/features/einvoice/logic/invoice_delivery_history_cubit.dart';
import 'package:erp/features/einvoice/logic/invoice_delivery_history_state.dart';
import 'package:erp/features/einvoice/logic/invoice_delivery_history_vm.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _RecordingMediator implements IModuleMediator {
  final List<dynamic> queries = [];
  Object? queryResult;
  Exception? errorToThrow;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (errorToThrow != null) throw errorToThrow!;
    if (queryResult != null) return queryResult as TResult;
    return null as TResult;
  }
}

void main() {
  InvoiceDeliveryItemDto delivery({
    required int no,
    DeliveryActorType actor = DeliveryActorType.user,
    DeliveryStatus status = DeliveryStatus.succeeded,
    String email = 'buyer@example.com',
    String? failureCode,
    String? actorId,
  }) {
    final at = DateTime.utc(2026, 8, no);
    return InvoiceDeliveryItemDto(
      deliveryId: 'del-$no',
      deliveryNo: no,
      kind: no == 1 ? DeliveryKind.initial : DeliveryKind.resend,
      triggerType: DeliveryTriggerType.manual,
      recipientEmail: email,
      status: status,
      initiatedByActorType: actor,
      initiatedByActorId: actorId,
      startedAt: at,
      completedAt: status == DeliveryStatus.processing ? null : at,
      failureCode: failureCode,
    );
  }

  group('InvoiceDeliveryHistoryRowVm', () {
    test('maps status labels/tones without actor id or failure code', () {
      final row = InvoiceDeliveryHistoryRowVm.fromDto(
        delivery(
          no: 1,
          actor: DeliveryActorType.system,
          status: DeliveryStatus.failed,
          failureCode: 'PROVIDER_TIMEOUT',
          actorId: 'actor-secret-99',
        ),
      );

      expect(row.statusLabel, 'Gửi lỗi');
      expect(row.tone, VComponentTone.danger);
      expect(row.actorLabel, 'Tự động');
      expect(row.actorLabel, isNot(contains('actor-secret')));
      expect(row.recipientEmail, 'buyer@example.com');
    });

    test('maps unknown and user actor', () {
      final row = InvoiceDeliveryHistoryRowVm.fromDto(
        delivery(
          no: 2,
          actor: DeliveryActorType.user,
          status: DeliveryStatus.unknown,
          actorId: 'user-1',
        ),
      );
      expect(row.statusLabel, 'Không xác định kết quả');
      expect(row.tone, VComponentTone.warning);
      expect(row.actorLabel, 'Người dùng');
    });
  });

  group('InvoiceDeliveryHistoryCubit', () {
    late FakeExecutionContext executionContext;
    late _RecordingMediator mediator;

    setUp(() {
      executionContext = FakeExecutionContext(
        tenantId: 'tenant-test',
        userId: 'actor-test',
      );
      mediator = _RecordingMediator();
    });

    InvoiceDeliveryHistoryCubit createCubit() {
      return InvoiceDeliveryHistoryCubit(
        salesOrderId: 'order-101',
        executionContext: executionContext,
        mediator: mediator,
      );
    }

    test(
      'th08_s5 history is mapped newest first without mutating DTO list',
      () async {
        final source = [
          delivery(no: 1),
          delivery(no: 3),
          delivery(no: 2),
        ];
        mediator.queryResult = InvoiceDeliveryHistoryDto(
          deliveries: source,
          displayState: DeliveryDisplayState.sent,
          hasSecondaryAttention: true,
        );

        final cubit = createCubit();
        addTearDown(cubit.close);
        await cubit.load();

        expect(cubit.state.rows.map((row) => row.deliveryNo), [3, 2, 1]);
        expect(source.map((row) => row.deliveryNo), [1, 3, 2]);
        expect(cubit.state.hasSecondaryAttention, isTrue);
        expect(cubit.state.displayState, DeliveryDisplayState.sent);
        expect(
          mediator.queries.single,
          isA<GetInvoiceDeliveryHistoryQuery>()
              .having((q) => q.salesOrderId, 'salesOrderId', 'order-101')
              .having((q) => q.tenantId, 'tenantId', 'tenant-test')
              .having((q) => q.actorId, 'actorId', 'actor-test'),
        );
      },
    );

    test('query failure maps safe error and retry loads again', () async {
      mediator.errorToThrow = Exception('NO_PERMISSION: denied');
      final cubit = createCubit();
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.status, InvoiceDeliveryHistoryStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Bạn không có quyền gửi hóa đơn điện tử.',
      );
      expect(cubit.state.errorMessage, isNot(contains('NO_PERMISSION')));

      mediator.errorToThrow = null;
      mediator.queryResult = const InvoiceDeliveryHistoryDto(
        deliveries: [],
        displayState: DeliveryDisplayState.notSent,
        hasSecondaryAttention: false,
      );
      await cubit.load();

      expect(mediator.queries, hasLength(2));
      expect(cubit.state.status, InvoiceDeliveryHistoryStatus.loaded);
      expect(cubit.state.isEmpty, isTrue);
    });
  });
}

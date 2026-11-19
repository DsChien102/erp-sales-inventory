import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/invoice_delivery_history_cubit.dart';
import 'package:erp/features/einvoice/logic/invoice_delivery_history_state.dart';
import 'package:erp/features/einvoice/logic/invoice_delivery_history_vm.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../support/fake_einvoice_repository.dart';

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
          status: DeliveryStatus.succeeded,
        ),
      );
      expect(row.actorLabel, 'Tự động');
      expect(row.statusLabel, 'Đã gửi');
      expect(row.tone, VComponentTone.success);
    });

    test('prefers user label when actor id present', () {
      final row = InvoiceDeliveryHistoryRowVm.fromDto(
        delivery(
          no: 2,
          actor: DeliveryActorType.user,
          status: DeliveryStatus.failed,
          failureCode: 'SEND_FAILED',
          actorId: 'usr-1',
        ),
      );
      expect(row.actorLabel, 'Người dùng');
      expect(row.statusLabel, 'Gửi lỗi');
      expect(row.tone, VComponentTone.danger);
    });
  });

  group('InvoiceDeliveryHistoryCubit', () {
    late FakeEInvoiceRepository repository;

    setUp(() {
      repository = FakeEInvoiceRepository();
    });

    InvoiceDeliveryHistoryCubit createCubit() {
      return InvoiceDeliveryHistoryCubit(
        salesOrderId: 'order-101',
        repository: repository,
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
        repository.history = InvoiceDeliveryHistoryDto(
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
        expect(repository.calls, contains('getDeliveryHistory'));
      },
    );

    test('query failure maps safe error and retry loads again', () async {
      repository.throwOn['getDeliveryHistory'] = const AppException(EInvoiceErrorCodes.noPermission);
      final cubit = createCubit();
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.status, InvoiceDeliveryHistoryStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Bạn không có quyền gửi hóa đơn điện tử.',
      );
      expect(cubit.state.errorMessage, isNot(contains('NO_PERMISSION')));

      repository.throwOn.remove('getDeliveryHistory');
      repository.history = const InvoiceDeliveryHistoryDto(
        deliveries: [],
        displayState: DeliveryDisplayState.notSent,
        hasSecondaryAttention: false,
      );
      await cubit.load();

      expect(repository.calls.where((c) => c == 'getDeliveryHistory'), hasLength(2));
      expect(cubit.state.status, InvoiceDeliveryHistoryStatus.loaded);
      expect(cubit.state.isEmpty, isTrue);
    });
  });
}

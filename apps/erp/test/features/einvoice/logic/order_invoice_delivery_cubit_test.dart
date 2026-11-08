import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/einvoice/logic/order_invoice_delivery_cubit.dart';
import 'package:erp/features/einvoice/logic/order_invoice_delivery_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_einvoice_repository.dart';

void main() {
  group('OrderInvoiceDeliveryCubit', () {
    late FakeEInvoiceRepository repository;
    late DeterministicOrderEInvoiceIdempotencyKeyFactory keys;

    setUp(() {
      repository = FakeEInvoiceRepository();
      keys = DeterministicOrderEInvoiceIdempotencyKeyFactory(const [
        'key-1',
        'key-2',
        'key-3',
      ]);
    });

    OrderInvoiceDeliveryCubit createDeliveryCubit({
      SendInvoiceSheetContextDto? queryResult,
      Object? queryError,
    }) {
      if (queryResult != null) repository.sendContext = queryResult;
      if (queryError != null) repository.throwOn['getSendSheetContext'] = queryError;
      return OrderInvoiceDeliveryCubit(
        salesOrderId: 'order-101',
        repository: repository,
        idempotencyKeyFactory: keys,
      );
    }

    Future<OrderInvoiceDeliveryCubit> readyCubit({
      SendInvoiceSheetContextDto? sheetContext,
      bool operationLocked = false,
    }) async {
      final context =
          sheetContext ??
          SendInvoiceSheetContextDto(
            mode: SendInvoiceSheetMode.send,
            suggestedEmail: 'buyer@example.com',
            suggestedEmailSource: DeliveryRecipientSource.currentPartnerProfile,
            history: const [],
            operationLocked: operationLocked,
            displayState: DeliveryDisplayState.notSent,
          );
      final cubit = createDeliveryCubit(queryResult: context);
      await cubit.loadContext();
      repository.throwOn.remove('getSendSheetContext');
      return cubit;
    }

    test('th08_s5 loads authoritative send sheet context through repository', () async {
      final cubit = createDeliveryCubit(
        queryResult: const SendInvoiceSheetContextDto(
          mode: SendInvoiceSheetMode.send,
          suggestedEmail: 'buyer@example.com',
          suggestedEmailSource: DeliveryRecipientSource.currentPartnerProfile,
          history: [],
          operationLocked: false,
          displayState: DeliveryDisplayState.notSent,
        ),
      );

      final context = await cubit.loadContext();

      expect(context?.suggestedEmail, 'buyer@example.com');
      expect(cubit.state.status, OrderInvoiceDeliveryStatus.ready);
      expect(repository.calls.where((c) => c == 'getSendSheetContext'), hasLength(1));
      await cubit.close();
    });

    test('th08_s5 query failure returns null with safe error copy', () async {
      final cubit = createDeliveryCubit(
        queryError: const AppException(
          EInvoiceErrorCodes.noPermission,
          serverMessage: 'actor mismatch',
        ),
      );

      final context = await cubit.loadContext();

      expect(context, isNull);
      expect(cubit.state.status, OrderInvoiceDeliveryStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Bạn không có quyền gửi hóa đơn điện tử.',
      );
      expect(cubit.state.errorMessage, isNot(contains('RPC')));
      expect(cubit.state.errorMessage, isNot(contains('NO_PERMISSION')));
      await cubit.close();
    });

    test('th08_s5 accepted send emits accepted and returns true', () async {
      final cubit = await readyCubit();
      repository.sendResult = const SendInvoiceResultDto(
        deliveryId: 'delivery-1',
        status: DeliveryStatus.processing,
      );

      final result = await cubit.submit(' Buyer@Example.com ');

      expect(result, isTrue);
      expect(cubit.state.status, OrderInvoiceDeliveryStatus.accepted);
      expect(cubit.state.acceptedDeliveryId, 'delivery-1');
      expect(repository.sendCalls, hasLength(1));
      expect(repository.sendCalls.single.recipientEmail, 'Buyer@Example.com');
      expect(repository.sendCalls.single.idempotencyKey, 'key-1');
      await cubit.close();
    });

    test('th08_s5 double submit while pending creates one command', () async {
      final cubit = await readyCubit();
      final completer = Completer<void>();
      repository.holdOn['send'] = completer;

      final first = cubit.submit('buyer@example.com');
      final second = cubit.submit('buyer@example.com');

      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isSubmitting, isTrue);
      expect(repository.calls.where((c) => c == 'send'), hasLength(1));

      completer.complete();
      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(repository.calls.where((c) => c == 'send'), hasLength(1));
      await cubit.close();
    });

    test('th08_s5 retry same email after failure reuses idempotency key', () async {
      final cubit = await readyCubit();
      repository.throwOn['send'] = const AppException(EInvoiceErrorCodes.systemError);

      expect(await cubit.submit('buyer@example.com'), isFalse);
      expect(cubit.state.status, OrderInvoiceDeliveryStatus.failure);

      repository.throwOn.remove('send');
      repository.sendResult = const SendInvoiceResultDto(
        deliveryId: 'delivery-2',
        status: DeliveryStatus.processing,
      );

      expect(await cubit.submit('buyer@example.com'), isTrue);
      expect(repository.sendCalls, hasLength(2));
      expect(repository.sendCalls[0].idempotencyKey, 'key-1');
      expect(repository.sendCalls[1].idempotencyKey, 'key-1');
      await cubit.close();
    });

    test('th08_s5 changing email creates a new idempotency key', () async {
      final cubit = await readyCubit();
      repository.throwOn['send'] = const AppException(EInvoiceErrorCodes.systemError);
      await cubit.submit('buyer@example.com');

      repository.throwOn.remove('send');
      repository.sendResult = const SendInvoiceResultDto(
        deliveryId: 'delivery-2',
        status: DeliveryStatus.processing,
      );
      await cubit.submit('other@example.com');

      expect(repository.sendCalls, hasLength(2));
      expect(repository.sendCalls[0].idempotencyKey, 'key-1');
      expect(repository.sendCalls[1].idempotencyKey, 'key-2');
      await cubit.close();
    });

    test('th08_s5 operationLocked does not send command', () async {
      final cubit = await readyCubit(operationLocked: true);

      final result = await cubit.submit('buyer@example.com');

      expect(result, isFalse);
      expect(repository.calls.where((c) => c == 'send'), isEmpty);
      await cubit.close();
    });

    test('th08_s5 empty email does not send command', () async {
      final cubit = await readyCubit();

      expect(await cubit.submit('   '), isFalse);
      expect(repository.calls.where((c) => c == 'send'), isEmpty);
      await cubit.close();
    });

    test('th08_s5 OPERATION_IN_PROGRESS locks further submit attempts', () async {
      final cubit = await readyCubit();
      repository.throwOn['send'] = const AppException(EInvoiceErrorCodes.operationInProgress);

      expect(await cubit.submit('buyer@example.com'), isFalse);
      expect(cubit.state.lockedAfterConflict, isTrue);
      expect(cubit.state.operationLocked, isTrue);
      expect(
        cubit.state.errorMessage,
        'Yêu cầu gửi trước đang được xử lý. Vui lòng chờ kết quả.',
      );

      repository.throwOn.remove('send');
      repository.sendResult = const SendInvoiceResultDto(
        deliveryId: 'delivery-1',
        status: DeliveryStatus.processing,
      );
      expect(await cubit.submit('buyer@example.com'), isFalse);
      expect(repository.calls.where((c) => c == 'send'), hasLength(1));
      await cubit.close();
    });
  });
}

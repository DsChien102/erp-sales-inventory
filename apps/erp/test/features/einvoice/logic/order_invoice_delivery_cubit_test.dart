import 'dart:async';

import 'package:erp/features/einvoice/logic/order_einvoice_idempotency_key_factory.dart';
import 'package:erp/features/einvoice/logic/order_invoice_delivery_cubit.dart';
import 'package:erp/features/einvoice/logic/order_invoice_delivery_state.dart';
import 'package:erp/features/sales/presentation/support/order_invoice_delivery_error_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _RecordingMediator implements IModuleMediator {
  final List<dynamic> commands = [];
  final List<dynamic> queries = [];

  Object? commandResult;
  Future<Object?>? commandResultFuture;
  Object? queryResult;
  Exception? errorToThrow;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    if (errorToThrow != null) throw errorToThrow!;
    if (commandResultFuture != null) {
      return (await commandResultFuture) as TResult;
    }
    if (commandResult != null) return commandResult as TResult;
    return null as TResult;
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
  group('OrderInvoiceDeliveryCubit', () {
    late FakeExecutionContext executionContext;
    late _RecordingMediator mediator;
    late DeterministicOrderEInvoiceIdempotencyKeyFactory keys;

    setUp(() {
      executionContext = FakeExecutionContext(
        tenantId: 'tenant-test',
        userId: 'actor-test',
      );
      mediator = _RecordingMediator();
      keys = DeterministicOrderEInvoiceIdempotencyKeyFactory(const [
        'key-1',
        'key-2',
        'key-3',
      ]);
    });

    OrderInvoiceDeliveryCubit createDeliveryCubit({
      Object? queryResult,
      Exception? queryError,
    }) {
      if (queryResult != null) mediator.queryResult = queryResult;
      if (queryError != null) mediator.errorToThrow = queryError;
      return OrderInvoiceDeliveryCubit(
        salesOrderId: 'order-101',
        executionContext: executionContext,
        mediator: mediator,
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
      mediator.errorToThrow = null;
      return cubit;
    }

    test(
      'th08_s5 loads authoritative send sheet context through mediator',
      () async {
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
        expect(
          mediator.queries.whereType<GetSendInvoiceSheetContextQuery>(),
          hasLength(1),
        );
        final query = mediator.queries.whereType<GetSendInvoiceSheetContextQuery>().single;
        expect(query.tenantId, 'tenant-test');
        expect(query.actorId, 'actor-test');
        expect(query.salesOrderId, 'order-101');
        await cubit.close();
      },
    );

    test('th08_s5 query failure returns null with safe error copy', () async {
      final cubit = createDeliveryCubit(
        queryError: Exception('RPC error: NO_PERMISSION: actor mismatch'),
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
      mediator.commandResult = const SendInvoiceResultDto(
        deliveryId: 'delivery-1',
        status: DeliveryStatus.processing,
      );

      final result = await cubit.submit(' Buyer@Example.com ');

      expect(result, isTrue);
      expect(cubit.state.status, OrderInvoiceDeliveryStatus.accepted);
      expect(cubit.state.acceptedDeliveryId, 'delivery-1');
      final command = mediator.commands.whereType<SendElectronicInvoiceCommand>().single;
      expect(command.recipientEmail, 'Buyer@Example.com');
      expect(command.idempotencyKey, 'key-1');
      await cubit.close();
    });

    test('th08_s5 double submit while pending creates one command', () async {
      final cubit = await readyCubit();
      final completer = Completer<SendInvoiceResultDto>();
      mediator.commandResultFuture = completer.future;

      final first = cubit.submit('buyer@example.com');
      final second = cubit.submit('buyer@example.com');

      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isSubmitting, isTrue);
      expect(
        mediator.commands.whereType<SendElectronicInvoiceCommand>(),
        hasLength(1),
      );

      completer.complete(
        const SendInvoiceResultDto(
          deliveryId: 'delivery-1',
          status: DeliveryStatus.processing,
        ),
      );
      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(
        mediator.commands.whereType<SendElectronicInvoiceCommand>(),
        hasLength(1),
      );
      await cubit.close();
    });

    test(
      'th08_s5 retry same email after failure reuses idempotency key',
      () async {
        final cubit = await readyCubit();
        mediator.errorToThrow = Exception('TimeoutException: provider');

        expect(await cubit.submit('buyer@example.com'), isFalse);
        expect(cubit.state.status, OrderInvoiceDeliveryStatus.failure);

        mediator.errorToThrow = null;
        mediator.commandResult = const SendInvoiceResultDto(
          deliveryId: 'delivery-2',
          status: DeliveryStatus.processing,
        );

        expect(await cubit.submit('buyer@example.com'), isTrue);
        final commands = mediator.commands.whereType<SendElectronicInvoiceCommand>().toList();
        expect(commands, hasLength(2));
        expect(commands[0].idempotencyKey, 'key-1');
        expect(commands[1].idempotencyKey, 'key-1');
        await cubit.close();
      },
    );

    test('th08_s5 changing email creates a new idempotency key', () async {
      final cubit = await readyCubit();
      mediator.errorToThrow = Exception('TimeoutException: provider');
      await cubit.submit('buyer@example.com');

      mediator.errorToThrow = null;
      mediator.commandResult = const SendInvoiceResultDto(
        deliveryId: 'delivery-2',
        status: DeliveryStatus.processing,
      );
      await cubit.submit('other@example.com');

      final commands = mediator.commands.whereType<SendElectronicInvoiceCommand>().toList();
      expect(commands[0].idempotencyKey, 'key-1');
      expect(commands[1].idempotencyKey, 'key-2');
      await cubit.close();
    });

    test('th08_s5 operationLocked does not send command', () async {
      final cubit = await readyCubit(operationLocked: true);
      mediator.commandResult = const SendInvoiceResultDto(
        deliveryId: 'delivery-1',
        status: DeliveryStatus.processing,
      );

      final result = await cubit.submit('buyer@example.com');

      expect(result, isFalse);
      expect(mediator.commands.whereType<SendElectronicInvoiceCommand>(), isEmpty);
      await cubit.close();
    });

    test('th08_s5 empty email does not send command', () async {
      final cubit = await readyCubit();

      expect(await cubit.submit('   '), isFalse);
      expect(mediator.commands.whereType<SendElectronicInvoiceCommand>(), isEmpty);
      await cubit.close();
    });

    test(
      'th08_s5 OPERATION_IN_PROGRESS locks further submit attempts',
      () async {
        final cubit = await readyCubit();
        mediator.errorToThrow = Exception('OPERATION_IN_PROGRESS: locked');

        expect(await cubit.submit('buyer@example.com'), isFalse);
        expect(cubit.state.lockedAfterConflict, isTrue);
        expect(cubit.state.operationLocked, isTrue);
        expect(
          cubit.state.errorMessage,
          'Yêu cầu gửi trước đang được xử lý. Vui lòng chờ kết quả.',
        );

        mediator.errorToThrow = null;
        mediator.commandResult = const SendInvoiceResultDto(
          deliveryId: 'delivery-1',
          status: DeliveryStatus.processing,
        );
        expect(await cubit.submit('buyer@example.com'), isFalse);
        expect(
          mediator.commands.whereType<SendElectronicInvoiceCommand>(),
          hasLength(1),
        );
        await cubit.close();
      },
    );

    test('OrderInvoiceDeliveryErrorMessage never echoes raw codes', () {
      expect(
        OrderInvoiceDeliveryErrorMessage.of('NO_PERMISSION'),
        isNot(contains('NO_PERMISSION')),
      );
      expect(
        OrderInvoiceDeliveryErrorMessage.of('weird'),
        OrderInvoiceDeliveryErrorMessage.fallback,
      );
    });
  });
}

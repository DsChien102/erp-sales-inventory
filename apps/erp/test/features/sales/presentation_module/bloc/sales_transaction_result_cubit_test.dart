import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../support/module_backed_sales_repositories.dart';

import 'package:erp/features/sales/logic/sales_transaction_result_cubit.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_state.dart';

void main() {
  group('SalesTransactionResultCubit', () {
    test('loads the three authoritative result DTOs through the mediator', () async {
      final module = _RecordingSalesModule();
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(module.commands, isEmpty);
      expect(module.reads, ['checkout', 'order', 'payment']);
      expect(module.readArgs, ['store-1/attempt-1', 'order-1', 'order-1']);
      expect(cubit.state.status, SalesTransactionResultStatus.loaded);
      expect(cubit.state.result!.checkout, same(module.checkout));
      expect(cubit.state.result!.order, same(module.order));
      expect(cubit.state.result!.payment, same(module.payment));
    });

    test('recovers an uncertain attempt by polling only its status query', () async {
      final module = _RecordingSalesModule(
        attemptResponses: [_uncertainCheckout(), _succeededCheckout()],
      );
      final cubit = _cubit(module: module, recoveryBackoff: const [Duration.zero]);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesTransactionResultStatus.loaded);
      expect(module.reads.where((r) => r == 'checkout'), hasLength(2));
      expect(module.reads.skip(2), ['order', 'payment']);
    });

    test('maps an ambiguous attempt transport failure into bounded recovery', () async {
      final module = _RecordingSalesModule(
        attemptResponses: [const _Failure(_AmbiguousTransportFailure()), _succeededCheckout()],
      );
      final cubit = _cubit(module: module, recoveryBackoff: const [Duration.zero]);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesTransactionResultStatus.loaded);
      expect(module.reads.where((r) => r == 'checkout'), hasLength(2));
      expect(module.commands, isEmpty);
    });

    test('maps UNCERTAIN_RESULT from the attempt query into bounded recovery', () async {
      final module = _RecordingSalesModule(
        attemptResponses: [
          const _Failure(AppException('UNCERTAIN_RESULT')),
          _succeededCheckout(),
        ],
      );
      final cubit = _cubit(module: module, recoveryBackoff: const [Duration.zero]);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesTransactionResultStatus.loaded);
      expect(module.reads.where((r) => r == 'checkout'), hasLength(2));
      expect(module.commands, isEmpty);
    });

    test('fails immediately for a stable initial attempt error without polling', () async {
      final delays = <Duration>[];
      final module = _RecordingSalesModule(
        attemptResponses: [const _Failure(AppException('NO_PERMISSION'))],
      );
      final cubit = _cubit(
        module: module,
        recoveryBackoff: const [Duration(seconds: 1)],
        delay: (duration) async => delays.add(duration),
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesTransactionResultStatus.failure);
      expect(cubit.state.issues, [SalesTransactionResultIssue.permissionDenied]);
      expect(module.reads.where((r) => r == 'checkout'), hasLength(1));
      expect(delays, isEmpty);
    });

    test('stops recovery when a later attempt read returns a stable error', () async {
      final delays = <Duration>[];
      final module = _RecordingSalesModule(
        attemptResponses: [
          _uncertainCheckout(),
          const _Failure(AppException('STALE_VERSION')),
        ],
      );
      final cubit = _cubit(
        module: module,
        recoveryBackoff: const [Duration(seconds: 1), Duration(seconds: 2)],
        delay: (duration) async => delays.add(duration),
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesTransactionResultStatus.failure);
      expect(cubit.state.issues, [SalesTransactionResultIssue.staleVersion]);
      expect(module.reads.where((r) => r == 'checkout'), hasLength(2));
      expect(delays, [const Duration(seconds: 1)]);
    });

    test('fails with uncertain issue after bounded recovery is exhausted', () async {
      final module = _RecordingSalesModule(
        attemptResponses: [_uncertainCheckout(), _uncertainCheckout(), _uncertainCheckout()],
      );
      final cubit = _cubit(
        module: module,
        recoveryBackoff: const [Duration.zero, Duration.zero],
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesTransactionResultStatus.failure);
      expect(cubit.state.issues, [SalesTransactionResultIssue.uncertainResult]);
      expect(module.reads.where((r) => r == 'checkout'), hasLength(3));
    });

    test('keeps the committed order when payment projection is pending', () async {
      final module = _RecordingSalesModule(
        paymentResponse: const _Failure(AppException('PROJECTION_PENDING')),
      );
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesTransactionResultStatus.partial);
      expect(cubit.state.order, same(module.order));
      expect(cubit.state.payment, isNull);
      expect(cubit.state.issues, [SalesTransactionResultIssue.projectionPending]);
    });

    test('fails when the authoritative sales order is not found', () async {
      final module = _RecordingSalesModule(
        orderResponse: const _Failure(AppException('NOT_FOUND')),
      );
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SalesTransactionResultStatus.failure);
      expect(cubit.state.order, isNull);
      expect(cubit.state.issues, [SalesTransactionResultIssue.notFound]);
    });

    test('retry starts new mediator reads after a secondary failure', () async {
      final module = _RecordingSalesModule(
        attemptResponses: [_succeededCheckout(), _succeededCheckout()],
        paymentResponse: const _Failure(AppException('NO_PERMISSION')),
      );
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      module.paymentResponse = null;
      await cubit.retryLoad();

      expect(cubit.state.status, SalesTransactionResultStatus.loaded);
      expect(module.reads.where((r) => r == 'checkout'), hasLength(2));
      expect(module.reads.where((r) => r == 'order'), hasLength(2));
      expect(module.commands, isEmpty);
    });

    test('ignores an earlier response after retry starts a newer generation', () async {
      final firstAttempt = Completer<CheckoutResultDto>();
      final module = _RecordingSalesModule(
        attemptResponses: [firstAttempt.future, _succeededCheckout()],
      );
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      final firstLoad = cubit.load();
      await Future<void>.delayed(Duration.zero);
      await cubit.retryLoad();
      final loadedResult = cubit.state.result;

      firstAttempt.complete(_uncertainCheckout());
      await firstLoad;

      expect(cubit.state.status, SalesTransactionResultStatus.loaded);
      expect(cubit.state.result, same(loadedResult));
      expect(module.reads.where((r) => r == 'checkout'), hasLength(2));
    });

    test('does not emit after close while waiting for recovery delay', () async {
      final delayCompleter = Completer<void>();
      final module = _RecordingSalesModule(attemptResponses: [_uncertainCheckout()]);
      final cubit = _cubit(
        module: module,
        recoveryBackoff: const [Duration(seconds: 1)],
        delay: (_) => delayCompleter.future,
      );

      final loading = cubit.load();
      await Future<void>.delayed(Duration.zero);
      final statesBeforeClose = <SalesTransactionResultState>[];
      final subscription = cubit.stream.listen(statesBeforeClose.add);
      await cubit.close();
      delayCompleter.complete();
      await loading;
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(statesBeforeClose, isEmpty);
      expect(module.reads.where((r) => r == 'checkout'), hasLength(1));
    });

    test('generates a receipt and retains its typed document', () async {
      final module = _RecordingSalesModule();
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.ensureReceipt();

      expect(module.commands.single, isA<GenerateSalesReceiptCommand>());
      final command = module.commands.single as GenerateSalesReceiptCommand;
      expect(command.idempotencyKey, 'sales-receipt:tenant-1:order-1:v4');
      expect(command.expectedVersion, 4);
      expect(cubit.state.receipt.document.receiptNumber, 'PBH-20260812-0129');
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
    });

    test('loads a known receipt identity instead of generating it', () async {
      final module = _RecordingSalesModule();
      final cubit = _cubit(module: module, knownReceiptId: 'receipt-known');
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.ensureReceipt();

      final query = module.queries.whereType<GetSalesReceiptQuery>().single;
      expect(query.receiptId, 'receipt-known');
      expect(query.expectedSourceVersion, 4);
      expect(module.commands, isEmpty);
      expect(cubit.state.receipt.document.receiptNumber, 'PBH-20260812-0129');
    });

    test('uses a stable generation idempotency key for the order version', () async {
      final module = _RecordingSalesModule(
        generateResponses: [_Failure(Exception('offline')), _receipt()],
      );
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.ensureReceipt();
      await cubit.ensureReceipt();

      final commands = module.commands.whereType<GenerateSalesReceiptCommand>().toList();
      expect(commands, hasLength(2));
      expect(commands[1].idempotencyKey, commands[0].idempotencyKey);
      expect(commands.first.idempotencyKey, 'sales-receipt:tenant-1:order-1:v4');
    });

    test(
      'does not issue receipt contracts before an authoritative result supplies its version',
      () async {
        final module = _RecordingSalesModule();
        final cubit = _cubit(module: module);
        addTearDown(cubit.close);

        await cubit.ensureReceipt();

        expect(module.commands, isEmpty);
        expect(module.queries, isEmpty);
        expect(cubit.state.receipt.status, SalesReceiptOperationStatus.error);
        expect(cubit.state.receipt.issue, SalesTransactionResultIssue.contextInvalid);
      },
    );

    test('suppresses duplicate receipt generation while it is in progress', () async {
      final generate = Completer<SalesReceiptDto>();
      final module = _RecordingSalesModule(generateResponses: [generate.future]);
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      final first = cubit.ensureReceipt();
      await Future<void>.delayed(Duration.zero);
      final second = cubit.ensureReceipt();
      generate.complete(_receipt());
      await Future.wait([first, second]);

      expect(module.commands.whereType<GenerateSalesReceiptCommand>(), hasLength(1));
    });

    test('keeps the loaded order result when receipt generation fails', () async {
      final module = _RecordingSalesModule(generateResponses: [_Failure(Exception('offline'))]);
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      final loadedResult = cubit.state.result;
      await cubit.ensureReceipt();

      expect(cubit.state.status, SalesTransactionResultStatus.loaded);
      expect(cubit.state.result, same(loadedResult));
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.error);
    });

    test('prints on the device before recording its receipt activity', () async {
      final events = <String>[];
      final module = _RecordingSalesModule(events: events);
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);
      Future<void> print(SalesReceiptDocumentDto document) async {
        events.add('device:${document.receiptNumber}');
      }

      await cubit.load();
      await cubit.ensureReceipt();
      events.clear();
      await cubit.printReceipt(print);

      expect(events, ['device:PBH-20260812-0129', 'RecordSalesReceiptPrintedCommand']);
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.ready);
    });

    test('shares on the device before recording its receipt activity', () async {
      final events = <String>[];
      final module = _RecordingSalesModule(events: events);
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.ensureReceipt();
      events.clear();
      await cubit.shareReceipt((_) async => events.add('device:share'));

      expect(events, ['device:share', 'RecordSalesReceiptSharedCommand']);
    });

    test('keeps the receipt ready for retry when print device operation fails', () async {
      final module = _RecordingSalesModule();
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.ensureReceipt();
      module.commands.clear();
      await cubit.printReceipt((_) => Future<void>.error(Exception('printer unavailable')));

      expect(module.commands, isEmpty);
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.error);
      expect(cubit.state.receipt.issue, SalesTransactionResultIssue.transportFailure);
      expect(cubit.state.receipt.document.receiptNumber, 'PBH-20260812-0129');
    });

    test('keeps the receipt ready for retry when share device operation fails', () async {
      final module = _RecordingSalesModule();
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.ensureReceipt();
      module.commands.clear();
      await cubit.shareReceipt((_) => Future<void>.error(Exception('share unavailable')));

      expect(module.commands, isEmpty);
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.error);
      expect(cubit.state.receipt.issue, SalesTransactionResultIssue.transportFailure);
      expect(cubit.state.receipt.document.receiptNumber, 'PBH-20260812-0129');
    });

    test('suppresses concurrent device receipt operations', () async {
      final device = Completer<void>();
      final module = _RecordingSalesModule();
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);
      var deviceCalls = 0;

      await cubit.load();
      await cubit.ensureReceipt();
      module.commands.clear();
      final first = cubit.printReceipt((_) {
        deviceCalls += 1;
        return device.future;
      });
      await Future<void>.delayed(Duration.zero);
      final second = cubit.shareReceipt((_) async => deviceCalls += 1);
      device.complete();
      await Future.wait<void>([first, second]);

      expect(deviceCalls, 1);
      expect(module.commands.whereType<RecordSalesReceiptPrintedCommand>(), hasLength(1));
      expect(module.commands.whereType<RecordSalesReceiptSharedCommand>(), isEmpty);
    });

    test('keeps a successful device action when receipt activity recording fails', () async {
      final events = <String>[];
      final module = _RecordingSalesModule(
        events: events,
        printedResponse: _Failure(Exception('audit unavailable')),
      );
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.ensureReceipt();
      events.clear();
      await cubit.printReceipt((_) async => events.add('device:print'));

      expect(events, ['device:print', 'RecordSalesReceiptPrintedCommand']);
      expect(cubit.state.receipt.status, SalesReceiptOperationStatus.activityWarning);
      expect(cubit.state.receipt.document.receiptNumber, 'PBH-20260812-0129');
    });

    test('retries failed activity without repeating a successful device action', () async {
      final events = <String>[];
      final module = _RecordingSalesModule(
        events: events,
        printedResponses: [_Failure(Exception('audit unavailable')), _receipt()],
      );
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.ensureReceipt();
      events.clear();
      await cubit.printReceipt((_) async => events.add('device:print'));
      await cubit.printReceipt((_) async => events.add('device:print'));

      expect(events, [
        'device:print',
        'RecordSalesReceiptPrintedCommand',
        'RecordSalesReceiptPrintedCommand',
      ]);
      final activityCommands = module.commands
          .whereType<RecordSalesReceiptPrintedCommand>()
          .toList();
      expect(activityCommands[1].idempotencyKey, activityCommands[0].idempotencyKey);
      expect(activityCommands[1].id, activityCommands[0].id);
    });

    test('retains a failed print audit across share and retries only that audit', () async {
      final module = _RecordingSalesModule(
        printedResponses: [_Failure(Exception('audit unavailable')), _receipt(), _receipt()],
      );
      final cubit = _cubit(module: module);
      addTearDown(cubit.close);
      var printDeviceCalls = 0;

      await cubit.load();
      await cubit.ensureReceipt();
      module.commands.clear();
      await cubit.printReceipt((_) async => printDeviceCalls += 1);
      final failedPrint = module.commands.whereType<RecordSalesReceiptPrintedCommand>().single;
      await cubit.shareReceipt((_) async {});
      await cubit.ensureReceipt();
      await cubit.printReceipt((_) async => printDeviceCalls += 1);
      final printCommands = module.commands.whereType<RecordSalesReceiptPrintedCommand>().toList();

      expect(cubit.state.receipt.hasPrintActivityWarning, isFalse);
      expect(printDeviceCalls, 1);
      expect(printCommands, hasLength(2));
      expect(printCommands.last.id, failedPrint.id);
      expect(printCommands.last.idempotencyKey, failedPrint.idempotencyKey);
    });

    test(
      'retries failed share audit without repeating share and gives a new operation a new ID',
      () async {
        final module = _RecordingSalesModule(
          sharedResponses: [_Failure(Exception('audit unavailable')), _receipt(), _receipt()],
        );
        final cubit = _cubit(module: module);
        addTearDown(cubit.close);
        var shareDeviceCalls = 0;

        await cubit.load();
        await cubit.ensureReceipt();
        module.commands.clear();
        await cubit.shareReceipt((_) async => shareDeviceCalls += 1);
        final failedShare = module.commands.whereType<RecordSalesReceiptSharedCommand>().single;
        expect(cubit.state.receipt.hasShareActivityWarning, isTrue);
        await cubit.shareReceipt((_) async => shareDeviceCalls += 1);
        await cubit.shareReceipt((_) async => shareDeviceCalls += 1);
        final shareCommands = module.commands.whereType<RecordSalesReceiptSharedCommand>().toList();

        expect(shareDeviceCalls, 2);
        expect(shareCommands, hasLength(3));
        expect(shareCommands[1].id, failedShare.id);
        expect(shareCommands[1].idempotencyKey, failedShare.idempotencyKey);
        expect(shareCommands[2].id, isNot(failedShare.id));
        expect(shareCommands[2].idempotencyKey, isNot(failedShare.idempotencyKey));
      },
    );

    test(
      'retry_activity_reuses_command_id_and_key verifies retried activity reuses commandId and idempotencyKey',
      () async {
        final module = _RecordingSalesModule(
          printedResponses: [_Failure(Exception('audit network error')), _receipt()],
        );
        final cubit = _cubit(module: module);
        addTearDown(cubit.close);

        await cubit.load();
        await cubit.ensureReceipt();
        module.commands.clear();

        await cubit.printReceipt((_) async {});
        expect(cubit.state.receipt.hasPrintActivityWarning, isTrue);

        await cubit.printReceipt((_) async {});
        expect(cubit.state.receipt.hasPrintActivityWarning, isFalse);

        final commands = module.commands.whereType<RecordSalesReceiptPrintedCommand>().toList();
        expect(commands, hasLength(2));
        expect(commands[1].id, commands[0].id);
        expect(commands[1].idempotencyKey, commands[0].idempotencyKey);
      },
    );
  });
}

SalesTransactionResultCubit _cubit({
  required _RecordingSalesModule module,
  String? knownReceiptId,
  List<Duration> recoveryBackoff = const [Duration.zero],
  Future<void> Function(Duration)? delay,
  SalesReceiptRepository? receiptRepository,
}) => SalesTransactionResultCubit(
  storeId: 'store-1',
  idempotencyKey: 'attempt-1',
  salesOrderId: 'order-1',
  knownReceiptId: knownReceiptId,
  checkoutRepository: _CheckoutRepo(module),
  orderRepository: _OrderRepo(module),
  paymentRepository: _PaymentRepo(module),
  receiptRepository: receiptRepository ?? ModuleBackedSalesReceiptRepository(module),
  recoveryBackoff: recoveryBackoff,
  delay: delay,
);

final class _RecordingSalesModule implements ISalesModule {
  _RecordingSalesModule({
    List<Object>? attemptResponses,
    List<Object>? generateResponses,
    List<Object>? printedResponses,
    List<Object>? sharedResponses,
    this.events,
    this.orderResponse,
    this.paymentResponse,
    this.printedResponse,
  }) : attemptResponses = attemptResponses ?? [_succeededCheckout()],
       generateResponses = generateResponses ?? <Object>[],
       printedResponses = printedResponses ?? <Object>[],
       sharedResponses = sharedResponses ?? <Object>[];

  final List<Object> commands = <Object>[];
  final List<Object> queries = <Object>[];

  /// Thứ tự ba lần đọc qua repository ('checkout' | 'order' | 'payment').
  final List<String> reads = <String>[];
  final List<String> readArgs = <String>[];

  Future<T> read<T>(String kind, String arg, Object? override, Object fallback) async {
    reads.add(kind);
    readArgs.add(arg);
    final Object response = override ?? fallback;
    if (response is _Failure) throw response.error;
    if (response is Future<Object>) return await response as T;
    return response as T;
  }

  final List<Object> attemptResponses;
  final List<Object> generateResponses;
  final List<Object> printedResponses;
  final List<Object> sharedResponses;
  final List<String>? events;
  Object? orderResponse;
  Object? paymentResponse;
  Object? printedResponse;

  final CheckoutResultDto checkout = _succeededCheckout();
  final SalesOrderResultDto order = _order();
  final SalesOrderPaymentSummaryDto payment = _payment();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    events?.add(command.runtimeType.toString());
    final Object response = switch (command) {
      GenerateSalesReceiptCommand() =>
        generateResponses.isEmpty ? _receipt() : generateResponses.removeAt(0),
      RecordSalesReceiptPrintedCommand() =>
        printedResponses.isNotEmpty ? printedResponses.removeAt(0) : printedResponse ?? _receipt(),
      RecordSalesReceiptSharedCommand() =>
        sharedResponses.isEmpty ? _receipt() : sharedResponses.removeAt(0),
      _ => throw UnsupportedError('Unexpected command $command'),
    };
    if (response is _Failure) throw response.error;
    if (response is Future<Object>) return await response as TResult;
    return response as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    final Object response;
    if (query is GetSalesReceiptQuery) {
      response = _receipt();
    } else {
      throw UnsupportedError('Unexpected query $query');
    }
    if (response is _Failure) throw response.error;
    if (response is Future<Object>) return await response as TResult;
    return response as TResult;
  }
}

final class _CheckoutRepo implements SalesCheckoutRepository {
  _CheckoutRepo(this.m);
  final _RecordingSalesModule m;

  @override
  Future<CheckoutResultDto> getResult({required String storeId, required String idempotencyKey}) =>
      m.read<CheckoutResultDto>(
        'checkout',
        '$storeId/$idempotencyKey',
        m.attemptResponses.removeAt(0),
        m.checkout,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _OrderRepo implements SalesOrderRepository {
  _OrderRepo(this.m);
  final _RecordingSalesModule m;

  @override
  Future<SalesOrderResultDto> get({required String salesOrderId}) =>
      m.read<SalesOrderResultDto>('order', salesOrderId, m.orderResponse, m.order);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _PaymentRepo implements SalesPaymentRepository {
  _PaymentRepo(this.m);
  final _RecordingSalesModule m;

  @override
  Future<SalesOrderPaymentSummaryDto> getSummary({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => m.read<SalesOrderPaymentSummaryDto>('payment', salesOrderId, m.paymentResponse, m.payment);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _Failure {
  const _Failure(this.error);

  final Object error;
}

final class _AmbiguousTransportFailure implements Exception {
  const _AmbiguousTransportFailure();
}

CheckoutResultDto _succeededCheckout() => const CheckoutResultDto(
  idempotencyKey: 'attempt-1',
  salesOrderId: 'order-1',
  salesOrderVersion: 4,
  status: CheckoutResultStatus.succeeded,
);

CheckoutResultDto _uncertainCheckout() => const CheckoutResultDto(
  idempotencyKey: 'attempt-1',
  salesOrderId: 'order-1',
  salesOrderVersion: 4,
  status: CheckoutResultStatus.uncertain,
);

SalesOrderResultDto _order() => SalesOrderResultDto(
  order: const SalesOrderDto(
    salesOrderId: 'order-1',
    orderNumber: 'SO-001',
    version: 4,
    lifecycleStatus: SalesOrderLifecycleStatus.completed,
    lockStatus: SalesOrderLockStatus.unlocked,
    total: MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
  ),
  committedAt: DateTime.utc(2026, 8, 12, 8),
  store: const StoreSnapshotDto(storeId: 'store-1', storeCode: 'S1', displayName: 'Store 1'),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Seller 1'),
  customer: const CustomerSnapshotDto(customerId: 'customer-1', displayName: 'Customer 1'),
);

SalesOrderPaymentSummaryDto _payment() => const SalesOrderPaymentSummaryDto(
  status: SalesSettlementStatus.paid,
  orderTotal: MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
  paidTotal: MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
  outstandingTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
);

SalesReceiptDto _receipt() => SalesReceiptDto(
  receiptId: 'receipt-1',
  salesOrderId: 'order-1',
  version: 4,
  status: SalesReceiptStatus.generated,
  generatedAt: DateTime.utc(2026, 8, 12, 8),
  document: SalesReceiptDocumentDto(
    receiptNumber: 'PBH-20260812-0129',
    orderNumber: 'SO-001',
    soldAt: DateTime.utc(2026, 8, 12, 8),
    store: const StoreSnapshotDto(storeId: 'store-1', storeCode: 'S1', displayName: 'Store 1'),
    seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Seller 1'),
    lines: const <SalesReceiptLineDto>[],
    subtotal: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
    discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    orderTotal: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
    paidTotal: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
    outstandingTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    payments: const <PaymentIntentSummaryDto>[],
  ),
);

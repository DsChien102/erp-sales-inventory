import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_cubit.dart';
import 'package:erp/features/einvoice/presentation/widgets/order_einvoice_polling_host.dart';

import '../support/fake_einvoice_configuration_repository.dart';
import '../support/fake_einvoice_repository.dart';

class _TestEInvoiceRepository extends FakeEInvoiceRepository {
  int reads = 0;

  @override
  Future<OrderInvoiceProjectionDto> getProjection(String salesOrderId) async {
    reads++;
    await super.getProjection(salesOrderId);
    return projection;
  }
}

void main() {
  late _TestEInvoiceRepository repository;
  late FakeEInvoiceConfigurationRepository configurationRepository;

  setUp(() {
    repository = _TestEInvoiceRepository();
    configurationRepository = FakeEInvoiceConfigurationRepository();
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sending,
      actions: [],
    );
  });

  OrderEInvoiceCubit createCubit({OrderInvoiceProjectionDto? initialProjection}) {
    return OrderEInvoiceCubit(
      salesOrderId: 'order',
      orderVersion: 1,
      initialProjection: initialProjection ?? repository.projection,
      repository: repository,
      configurationRepository: configurationRepository,
    );
  }

  Widget wrapHost(OrderEInvoiceCubit cubit, {bool tickerEnabled = true}) {
    return MaterialApp(
      home: TickerMode(
        enabled: tickerEnabled,
        child: BlocProvider.value(
          value: cubit,
          child: const OrderEInvoicePollingHost(child: SizedBox()),
        ),
      ),
    );
  }

  Future<void> closeSubject(
    WidgetTester tester,
    OrderEInvoiceCubit cubit,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  }

  testWidgets('polls every five seconds and stops on definite failure', (
    tester,
  ) async {
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    final cubit = createCubit();

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(repository.reads, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(repository.reads, 2);

    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.failed,
      actions: [OrderInvoiceAction.issue],
    );
    await tester.pump(const Duration(seconds: 5));
    expect(cubit.state.isTerminal, isTrue);
    final readsAtFailure = repository.reads;

    await tester.pump(const Duration(seconds: 10));
    expect(repository.reads, readsAtFailure);

    await closeSubject(tester, cubit);
  });

  testWidgets('sticky sent resend polls only while its route is visible', (
    tester,
  ) async {
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sent,
      deliveryPending: true,
      actions: [],
    );
    final cubit = createCubit();

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(repository.reads, 1);

    await tester.pumpWidget(wrapHost(cubit, tickerEnabled: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(repository.reads, 1);

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(repository.reads, 2);

    await closeSubject(tester, cubit);
  });

  testWidgets('polls issued delivery, pauses on lifecycle and page inactive', (
    tester,
  ) async {
    final cubit = createCubit();

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(repository.reads, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(repository.reads, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.reads, 2);

    cubit.setPageActive(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(repository.reads, 2);

    cubit.setPageActive(true);
    await tester.pump();
    expect(repository.reads, 3);

    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sent,
      actions: [],
    );
    await tester.pump(const Duration(seconds: 5));
    expect(repository.reads, 4);
    expect(cubit.state.shouldPoll, isFalse);

    final readsAtTerminal = repository.reads;
    await tester.pump(const Duration(seconds: 10));
    expect(repository.reads, readsAtTerminal);

    await closeSubject(tester, cubit);
    await tester.pump(const Duration(seconds: 10));
    expect(repository.reads, readsAtTerminal);
  });

  testWidgets('auth failure when starting poll does not surface takeException', (
    tester,
  ) async {
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    repository.throwOn['getProjection'] = const AppException(
      EInvoiceErrorCodes.providerAuthFailed,
    );
    final cubit = createCubit(initialProjection: repository.projection);

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      cubit.state.projection.issuanceDisplayState,
      IssuanceDisplayState.processing,
    );

    await closeSubject(tester, cubit);
  });

  testWidgets('projection fetch error on mount and tick keeps last projection', (
    tester,
  ) async {
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    repository.throwOn['getProjection'] = StateError('network down');
    final cubit = createCubit(initialProjection: repository.projection);

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      cubit.state.projection.issuanceDisplayState,
      IssuanceDisplayState.processing,
    );

    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
    expect(
      cubit.state.projection.issuanceDisplayState,
      IssuanceDisplayState.processing,
    );

    repository.throwOn.remove('getProjection');
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.issued,
      actions: [],
    );
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
    expect(
      cubit.state.projection.issuanceDisplayState,
      IssuanceDisplayState.issued,
    );

    await closeSubject(tester, cubit);
  });

  testWidgets('closed terminal orders do not refetch on app resume', (
    tester,
  ) async {
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.issued,
      actions: [],
    );
    final closed = createCubit();
    await tester.pumpWidget(wrapHost(closed));
    await tester.pump();
    final readsAfterMount = repository.reads;
    await closeSubject(tester, closed);
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(repository.reads, readsAfterMount);
  });

  testWidgets('processing order refetches on resume via polling host', (
    tester,
  ) async {
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    final cubit = createCubit();
    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(repository.reads, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.reads, 2);

    await closeSubject(tester, cubit);
  });

  testWidgets(
    'auto-send notSent→sending→sent keeps issued and stops poll at terminal',
    (tester) async {
      repository.projection = const OrderInvoiceProjectionDto(
        salesOrderId: 'order',
        issuanceDisplayState: IssuanceDisplayState.issued,
        deliveryDisplayState: DeliveryDisplayState.notSent,
        actions: [OrderInvoiceAction.view],
      );
      final cubit = createCubit();
      await tester.pumpWidget(wrapHost(cubit));
      await tester.pump();
      expect(cubit.state.shouldPoll, isFalse);
      expect(
        cubit.state.projection.issuanceDisplayState,
        IssuanceDisplayState.issued,
      );

      repository.projection = const OrderInvoiceProjectionDto(
        salesOrderId: 'order',
        issuanceDisplayState: IssuanceDisplayState.issued,
        deliveryDisplayState: DeliveryDisplayState.sending,
        deliveryPending: true,
        actions: [OrderInvoiceAction.view],
      );
      cubit.emit(cubit.state.copyWith(projection: repository.projection));
      await tester.pump();
      expect(cubit.state.shouldPoll, isTrue);

      await tester.pump(const Duration(seconds: 5));
      expect(repository.reads, greaterThanOrEqualTo(2));
      expect(
        cubit.state.projection.issuanceDisplayState,
        IssuanceDisplayState.issued,
      );

      repository.projection = const OrderInvoiceProjectionDto(
        salesOrderId: 'order',
        issuanceDisplayState: IssuanceDisplayState.issued,
        deliveryDisplayState: DeliveryDisplayState.sent,
        deliveryPending: false,
        actions: [OrderInvoiceAction.view],
      );
      await tester.pump(const Duration(seconds: 5));
      expect(cubit.state.shouldPoll, isFalse);
      expect(
        cubit.state.projection.issuanceDisplayState,
        IssuanceDisplayState.issued,
      );
      final readsAtSent = repository.reads;
      await tester.pump(const Duration(seconds: 10));
      expect(repository.reads, readsAtSent);

      await closeSubject(tester, cubit);
    },
  );

  testWidgets(
    'unknown delivery does not keep projection polling after issued',
    (tester) async {
      repository.projection = const OrderInvoiceProjectionDto(
        salesOrderId: 'order',
        issuanceDisplayState: IssuanceDisplayState.issued,
        deliveryDisplayState: DeliveryDisplayState.unknown,
        deliveryPending: false,
        actions: [OrderInvoiceAction.view],
      );
      final cubit = createCubit();
      await tester.pumpWidget(wrapHost(cubit));
      await tester.pump();
      expect(cubit.state.shouldPoll, isFalse);
      final readsAfterMount = repository.reads;

      await tester.pump(const Duration(seconds: 10));
      expect(repository.reads, readsAfterMount);
      expect(
        cubit.state.projection.issuanceDisplayState,
        IssuanceDisplayState.issued,
      );

      await closeSubject(tester, cubit);
    },
  );

  testWidgets('refresh while poll in flight reuses the read', (tester) async {
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    final gate = Completer<void>();
    repository.holdOn['getProjection'] = gate;
    final cubit = createCubit();

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(repository.reads, 1);

    unawaited(cubit.refresh());
    await tester.pump();
    expect(repository.reads, 1);

    gate.complete();
    await tester.pump();
    expect(repository.reads, 1);

    await closeSubject(tester, cubit);
  });

  testWidgets('closing cubit stops polling', (tester) async {
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    final cubit = createCubit();

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(repository.reads, 1);

    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await tester.pump(const Duration(seconds: 15));
    expect(repository.reads, 1);
  });

  testWidgets('retry from failed never flashes back to failed', (tester) async {
    repository.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.failed,
      actions: [OrderInvoiceAction.retryIssue],
    );
    final cubit = createCubit();

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(cubit.state.projection.issuanceDisplayState, IssuanceDisplayState.failed);

    final states = <IssuanceDisplayState>[];
    final sub = cubit.stream.listen((s) => states.add(s.projection.issuanceDisplayState));

    unawaited(cubit.issueOrRetry());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));

    final firstProcessing = states.indexOf(IssuanceDisplayState.processing);
    expect(firstProcessing, isNonNegative);
    expect(states.skip(firstProcessing), isNot(contains(IssuanceDisplayState.failed)));
    expect(cubit.state.projection.issuanceDisplayState, IssuanceDisplayState.processing);

    await tester.pumpWidget(const SizedBox());
    unawaited(sub.cancel());
    unawaited(cubit.close());
    await tester.pump();
  });
}

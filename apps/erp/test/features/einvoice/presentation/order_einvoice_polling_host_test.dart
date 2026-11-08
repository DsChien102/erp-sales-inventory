import 'package:async_query/async_query.dart';
import 'package:async_query_flutter/async_query_flutter.dart';
import 'package:erp/features/einvoice/logic/order_einvoice_cubit.dart';
import 'package:erp/features/einvoice/presentation/widgets/order_einvoice_polling_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

class _ProjectionMediator implements IModuleMediator {
  int reads = 0;
  OrderInvoiceProjectionDto projection = const OrderInvoiceProjectionDto(
    salesOrderId: 'order',
    issuanceDisplayState: IssuanceDisplayState.issued,
    deliveryDisplayState: DeliveryDisplayState.sending,
    actions: [],
  );

  @override
  Future<T> executeQueryAsync<T>(IQuery<T> query) async {
    if (query is GetOrderInvoiceProjectionQuery) {
      reads++;
      return projection as T;
    }
    if (query is GetIssuanceReadinessQuery) {
      return const IssuanceReadinessDto(
            level: IssuanceReadinessLevel.ready,
            blockers: [],
            warnings: [],
            buyerCompletionState: BuyerCompletionStatus.open,
          )
          as T;
    }
    if (query is GetIssuanceAttemptStatusQuery) {
      return const IssuanceAttemptStatusDto(
            attemptId: 'attempt-1',
            status: IssuanceAttemptStatus.failed,
            internalFinalizationStatus: InternalFinalizationStatus.pending,
            hasElectronicInvoice: false,
            hasActiveOperation: false,
            failureCode: 'PROVIDER_REJECTED',
            lastErrorMessage: 'Nhà cung cấp từ chối hóa đơn',
          )
          as T;
    }
    throw UnsupportedError('unexpected query $query');
  }

  @override
  Future<T> executeCommandAsync<T>(ICommand<T> command) => throw UnimplementedError();
}

void main() {
  late QueryClient queryClient;
  late _ProjectionMediator mediator;

  setUp(() {
    queryClient = QueryClient(
      options: const QueryClientOptions(
        queries: QueryOptionsDefaults(retry: 0, staleTime: Duration.zero),
      ),
    );
    mediator = _ProjectionMediator();
  });

  tearDown(() => queryClient.dispose());

  OrderEInvoiceCubit createCubit({OrderInvoiceProjectionDto? initialProjection}) {
    return OrderEInvoiceCubit(
      salesOrderId: 'order',
      orderVersion: 1,
      initialProjection: initialProjection ?? mediator.projection,
      executionContext: FakeExecutionContext(
        tenantId: 'tenant',
        userId: 'actor',
      ),
      mediator: mediator,
      queryClient: queryClient,
    );
  }

  Widget wrapHost(OrderEInvoiceCubit cubit, {bool tickerEnabled = true}) {
    return QueryClientProvider(
      client: queryClient,
      child: MaterialApp(
        home: TickerMode(
          enabled: tickerEnabled,
          child: BlocProvider.value(
            value: cubit,
            child: const OrderEInvoicePollingHost(child: SizedBox()),
          ),
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
    // Cancel per-query GC timers before Flutter's post-test invariant check.
    queryClient.clear();
  }

  testWidgets('polls every five seconds and stops on definite failure', (
    tester,
  ) async {
    mediator.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    final cubit = createCubit();

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(mediator.reads, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(mediator.reads, 2);

    mediator.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.failed,
      actions: [OrderInvoiceAction.issue],
    );
    await tester.pump(const Duration(seconds: 5));
    expect(cubit.state.isTerminal, isTrue);
    final readsAtFailure = mediator.reads;

    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, readsAtFailure);

    await closeSubject(tester, cubit);
  });

  testWidgets('sticky sent resend polls only while its route is visible', (
    tester,
  ) async {
    mediator.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sent,
      deliveryPending: true,
      actions: [],
    );
    final cubit = createCubit();

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(mediator.reads, 1);

    await tester.pumpWidget(wrapHost(cubit, tickerEnabled: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, 1);

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(mediator.reads, 2);

    await closeSubject(tester, cubit);
  });

  testWidgets('polls issued delivery, pauses on lifecycle and page inactive', (
    tester,
  ) async {
    final cubit = createCubit();

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(mediator.reads, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(mediator.reads, 2);

    cubit.setPageActive(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, 2);

    cubit.setPageActive(true);
    await tester.pump();
    expect(mediator.reads, 3);

    mediator.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sent,
      actions: [],
    );
    await tester.pump(const Duration(seconds: 5));
    expect(mediator.reads, 4);
    expect(cubit.state.shouldPoll, isFalse);

    final readsAtTerminal = mediator.reads;
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, readsAtTerminal);

    await closeSubject(tester, cubit);
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, readsAtTerminal);
  });

  testWidgets('auth failure when starting poll does not surface takeException', (
    tester,
  ) async {
    mediator.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    final cubit = OrderEInvoiceCubit(
      salesOrderId: 'order',
      orderVersion: 1,
      initialProjection: mediator.projection,
      executionContext: FakeExecutionContext(
        tenantId: 'tenant',
        userId: 'actor',
        failTenant: true,
      ),
      mediator: mediator,
      queryClient: queryClient,
    );

    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(mediator.reads, 0);
    expect(
      cubit.state.projection.issuanceDisplayState,
      IssuanceDisplayState.processing,
    );

    await closeSubject(tester, cubit);
  });

  testWidgets('projection fetch error on mount and tick keeps last projection', (
    tester,
  ) async {
    final failing = _FailingThenOkMediator();
    final cubit = OrderEInvoiceCubit(
      salesOrderId: 'order',
      orderVersion: 1,
      initialProjection: const OrderInvoiceProjectionDto(
        salesOrderId: 'order',
        issuanceDisplayState: IssuanceDisplayState.processing,
        actions: [],
      ),
      executionContext: FakeExecutionContext(
        tenantId: 'tenant',
        userId: 'actor',
      ),
      mediator: failing,
      queryClient: queryClient,
    );

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

    failing.failProjection = false;
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
    mediator.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.issued,
      actions: [],
    );
    final closed = createCubit();
    await tester.pumpWidget(wrapHost(closed));
    await tester.pump();
    final readsAfterMount = mediator.reads;
    await closeSubject(tester, closed);
    await tester.pump();

    // Recreate client after clear so subsequent lifecycle signal is isolated.
    queryClient = QueryClient(
      options: const QueryClientOptions(
        queries: QueryOptionsDefaults(retry: 0, staleTime: Duration.zero),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(mediator.reads, readsAfterMount);
  });

  testWidgets('processing order refetches on resume via polling host', (
    tester,
  ) async {
    mediator.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.processing,
      actions: [],
    );
    final cubit = createCubit();
    await tester.pumpWidget(wrapHost(cubit));
    await tester.pump();
    expect(mediator.reads, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(mediator.reads, 2);

    await closeSubject(tester, cubit);
  });

  testWidgets(
    'auto-send notSent→sending→sent keeps issued and stops poll at terminal',
    (tester) async {
      mediator.projection = const OrderInvoiceProjectionDto(
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

      mediator.projection = const OrderInvoiceProjectionDto(
        salesOrderId: 'order',
        issuanceDisplayState: IssuanceDisplayState.issued,
        deliveryDisplayState: DeliveryDisplayState.sending,
        deliveryPending: true,
        actions: [OrderInvoiceAction.view],
      );
      cubit.emit(cubit.state.copyWith(projection: mediator.projection));
      await tester.pump();
      expect(cubit.state.shouldPoll, isTrue);

      await tester.pump(const Duration(seconds: 5));
      expect(mediator.reads, greaterThanOrEqualTo(2));
      expect(
        cubit.state.projection.issuanceDisplayState,
        IssuanceDisplayState.issued,
      );

      mediator.projection = const OrderInvoiceProjectionDto(
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
      final readsAtSent = mediator.reads;
      await tester.pump(const Duration(seconds: 10));
      expect(mediator.reads, readsAtSent);

      await closeSubject(tester, cubit);
    },
  );

  testWidgets(
    'unknown delivery does not keep projection polling after issued',
    (tester) async {
      mediator.projection = const OrderInvoiceProjectionDto(
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
      final readsAfterMount = mediator.reads;

      await tester.pump(const Duration(seconds: 10));
      expect(mediator.reads, readsAfterMount);
      expect(
        cubit.state.projection.issuanceDisplayState,
        IssuanceDisplayState.issued,
      );

      await closeSubject(tester, cubit);
    },
  );
}

final class _FailingThenOkMediator implements IModuleMediator {
  bool failProjection = true;

  @override
  Future<T> executeQueryAsync<T>(IQuery<T> query) async {
    if (query is GetOrderInvoiceProjectionQuery) {
      if (failProjection) {
        throw StateError('network down');
      }
      return const OrderInvoiceProjectionDto(
            salesOrderId: 'order',
            issuanceDisplayState: IssuanceDisplayState.issued,
            actions: [],
          )
          as T;
    }
    if (query is GetIssuanceReadinessQuery) {
      return const IssuanceReadinessDto(
            level: IssuanceReadinessLevel.ready,
            blockers: [],
            warnings: [],
            buyerCompletionState: BuyerCompletionStatus.open,
          )
          as T;
    }
    throw UnsupportedError('unexpected query $query');
  }

  @override
  Future<T> executeCommandAsync<T>(ICommand<T> command) => throw UnimplementedError();
}

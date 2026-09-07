import 'package:erp/features/sales/presentation/bloc/order_einvoice_cubit.dart';
import 'package:erp/features/sales/presentation/widgets/order_einvoice_polling_host.dart';
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
    throw UnsupportedError('optional display query');
  }

  @override
  Future<T> executeCommandAsync<T>(ICommand<T> command) => throw UnimplementedError();
}

void main() {
  testWidgets('sticky sent resend polls only while its route is visible', (tester) async {
    final mediator = _ProjectionMediator();
    mediator.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order', issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sent, deliveryPending: true, actions: [],
    );
    final cubit = OrderEInvoiceCubit(
      salesOrderId: 'order', orderVersion: 1, initialProjection: mediator.projection,
      executionContext: FakeExecutionContext(tenantId: 'tenant', userId: 'actor'), mediator: mediator,
    );
    Widget host(bool enabled) => MaterialApp(home: TickerMode(enabled: enabled,
      child: BlocProvider.value(value: cubit,
        child: const OrderEInvoicePollingHost(child: SizedBox())),
    ));
    await tester.pumpWidget(host(true));
    await tester.pump(const Duration(seconds: 5));
    expect(mediator.reads, 1);
    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, 1);
    await tester.pumpWidget(host(true));
    await tester.pump(const Duration(seconds: 5));
    expect(mediator.reads, 2);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });

  testWidgets('polls issued delivery every five seconds, pauses and stops', (tester) async {
    final mediator = _ProjectionMediator();
    final cubit = OrderEInvoiceCubit(
      salesOrderId: 'order',
      orderVersion: 1,
      initialProjection: mediator.projection,
      executionContext: FakeExecutionContext(tenantId: 'tenant', userId: 'actor'),
      mediator: mediator,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const OrderEInvoicePollingHost(child: SizedBox()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(mediator.reads, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(mediator.reads, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 5));
    expect(mediator.reads, 2);
    cubit.setPageActive(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, 2);
    cubit.setPageActive(true);
    await tester.pump();
    mediator.projection = const OrderInvoiceProjectionDto(
      salesOrderId: 'order',
      issuanceDisplayState: IssuanceDisplayState.issued,
      deliveryDisplayState: DeliveryDisplayState.sent,
      actions: [],
    );
    await tester.pump(const Duration(seconds: 5));
    expect(mediator.reads, 3);
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, 3);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await tester.pump(const Duration(seconds: 10));
    expect(mediator.reads, 3);
  });
}

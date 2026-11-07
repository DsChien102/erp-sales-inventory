import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// SG-06 — Màn kết quả bán hàng (EP-02/US-06..07).
class SalesTransactionResultPage extends StatefulWidget {
  const SalesTransactionResultPage({
    super.key,
    required this.args,
    this.salesModule,
    this.executionContext,
  });

  final SalesCheckoutResultArgs args;
  final ISalesModule? salesModule;
  final IExecutionContext? executionContext;

  @override
  State<SalesTransactionResultPage> createState() => _SalesTransactionResultPageState();
}

class _SalesTransactionResultPageState extends State<SalesTransactionResultPage> {
  late final SalesTransactionResultCubit _cubit;

  @override
  void initState() {
    super.initState();
    final salesModule = widget.salesModule ?? GetIt.instance<ISalesModule>();
    final executionContext = widget.executionContext ?? GetIt.instance<IExecutionContext>();
    _cubit = SalesTransactionResultCubit(
      idempotencyKey: widget.args.idempotencyKey,
      storeId: widget.args.storeId,
      salesOrderId: widget.args.salesOrderId,
      checkoutRepository: GetIt.instance<SalesCheckoutRepository>(),
      orderRepository: GetIt.instance<SalesOrderRepository>(),
      paymentRepository: GetIt.instance<SalesPaymentRepository>(),
      salesModule: salesModule,
      executionContext: executionContext,
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SalesTransactionResultCubit, SalesTransactionResultState>(
        builder: (context, state) {
          final cubit = context.read<SalesTransactionResultCubit>();
          final isFailure = state.status == SalesTransactionResultStatus.failure;

          return VPageScaffold(
            key: const Key('wgt_sg06_result_page'),
            title: 'Kết quả bán hàng',
            showBackButton: false,
            bottomBar: SalesTransactionResultActionBar(
              onGoHome: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(SalesNav.ordersList);
                }
              },
              onCreateNewOrder: () =>
                  const SalesComposeRoute().pushReplacement(context),
              isErrorState: isFailure,
              onRetryLoad: cubit.retryLoad,
            ),
            body: SalesTransactionResultBody(
              onViewOrderDetail: () => SalesOrderDetailRoute(
                orderId: widget.args.salesOrderId,
              ).pushReplacement(context),
            ),
          );
        },
      ),
    );
  }
}

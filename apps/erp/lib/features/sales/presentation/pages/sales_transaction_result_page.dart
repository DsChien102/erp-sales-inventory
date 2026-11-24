import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

/// SG-06 — Màn kết quả bán hàng (EP-02/US-06..07).
class SalesTransactionResultPage extends StatefulWidget {
  const SalesTransactionResultPage({
    super.key,
    required this.args,
    this.receiptRepository,
  });

  final SalesCheckoutResultArgs args;
  final SalesReceiptRepository? receiptRepository;

  @override
  State<SalesTransactionResultPage> createState() => _SalesTransactionResultPageState();
}

class _SalesTransactionResultPageState extends State<SalesTransactionResultPage> {
  late final SalesTransactionResultCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SalesTransactionResultCubit(
      idempotencyKey: widget.args.idempotencyKey,
      storeId: widget.args.storeId,
      salesOrderId: widget.args.salesOrderId,
      checkoutRepository: GetIt.instance<SalesCheckoutRepository>(),
      orderRepository: GetIt.instance<SalesOrderRepository>(),
      paymentRepository: GetIt.instance<SalesPaymentRepository>(),
      receiptRepository: widget.receiptRepository ?? GetIt.instance<SalesReceiptRepository>(),
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
              onCreateNewOrder: () => const SalesComposeRoute().pushReplacement(context),
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

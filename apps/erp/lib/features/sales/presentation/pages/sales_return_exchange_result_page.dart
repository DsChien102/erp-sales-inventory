import 'package:erp/core/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/receivable/presentation/receivable_navigation.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/presentation.dart';

/// SG-13 — Kết quả đổi/trả (thin composition root, identity-only route).
class SalesReturnExchangeResultPage extends StatefulWidget {
  const SalesReturnExchangeResultPage({
    super.key,
    required this.orderId,
    required this.returnExchangeId,
  });

  final String orderId;
  final String returnExchangeId;

  @override
  State<SalesReturnExchangeResultPage> createState() => _SalesReturnExchangeResultPageState();
}

class _SalesReturnExchangeResultPageState extends State<SalesReturnExchangeResultPage> {
  late final SalesReturnExchangeDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SalesReturnExchangeDetailCubit(
      orderId: widget.orderId,
      returnExchangeId: widget.returnExchangeId,
      returnExchangeRepository: GetIt.instance<ReturnExchangeRepository>(),
      orderRepository: GetIt.instance<SalesOrderRepository>(),
      session: GetIt.instance<SessionController>(),
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _goHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    } else {
      context.go(SalesNav.ordersList);
    }
  }

  void _viewOrderDetail() {
    final nav = Navigator.of(context);
    var popped = false;
    if (nav.canPop()) {
      nav.popUntil((route) {
        if (SalesNav.isOrderDetailRoute(route, widget.orderId)) {
          popped = true;
          return true;
        }
        return route.isFirst;
      });
    }
    if (!popped) {
      SalesOrderDetailRoute(orderId: widget.orderId).go(context);
    }
  }

  void _viewSlipDetail() {
    SalesReturnDetailRoute(
      orderId: widget.orderId,
      returnExchangeId: widget.returnExchangeId,
    ).push(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SalesReturnExchangeDetailCubit, SalesReturnExchangeDetailState>(
        builder: (context, state) {
          final customerId = state.orderDetail?.customer?.customerId;
          return VPageScaffold(
            key: const Key('wgt_sg13_return_result_page'),
            title: 'Kết quả đổi/trả',
            showBackButton: true,
            leading: IconButton(
              key: const Key('btn_return_result_back'),
              icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
              onPressed: _goHome,
            ),
            body: SalesReturnExchangeResultBody(
              state: state,
              onGoHome: _goHome,
              onViewOrderDetail: _viewOrderDetail,
              onViewReturnSlipDetail: _viewSlipDetail,
              onRetry: () => _cubit.refresh(),
              onViewCustomerReceivable: customerId == null
                  ? null
                  : () => openCustomerReceivable(context, customerId),
            ),
          );
        },
      ),
    );
  }
}

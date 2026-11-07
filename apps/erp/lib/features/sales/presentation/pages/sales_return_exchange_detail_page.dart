import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// SG-13 — Chi tiết phiếu đổi/trả (thin composition root, identity-only route).
class SalesReturnExchangeDetailPage extends StatefulWidget {
  const SalesReturnExchangeDetailPage({
    super.key,
    required this.orderId,
    required this.returnExchangeId,
  });

  final String orderId;
  final String returnExchangeId;

  @override
  State<SalesReturnExchangeDetailPage> createState() => _SalesReturnExchangeDetailPageState();
}

class _SalesReturnExchangeDetailPageState extends State<SalesReturnExchangeDetailPage> {
  late final SalesReturnExchangeDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SalesReturnExchangeDetailCubit(
      orderId: widget.orderId,
      returnExchangeId: widget.returnExchangeId,
      returnExchangeRepository: GetIt.instance<ReturnExchangeRepository>(),
      orderRepository: GetIt.instance<SalesOrderRepository>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _backToOrderDetail() {
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

  Future<void> _openActions() async {
    final detail = _cubit.state.detail;
    if (detail == null) {
      if (!mounted) return;
      VToast.show(
        context,
        title: 'Chưa có dữ liệu phiếu',
        message: 'Không thể in/chia sẻ khi thiếu chi tiết authoritative.',
        type: VToastType.warning,
      );
      return;
    }

    final action = await showSalesReturnExchangeSlipSheet(context);
    if (!mounted || action == null) return;

    final orderNumber = _cubit.state.orderNumber;
    final customerDisplayName = _cubit.state.customerDisplayName;
    final fileName = SalesSlipPdfGenerator.sanitizeFileName(
      detail.referenceNumber,
    );

    if (action == SalesReturnExchangeSlipAction.view) {
      SalesReturnPreviewRoute(
        orderId: widget.orderId,
        returnExchangeId: widget.returnExchangeId,
      ).push(context);
      return;
    }

    try {
      final pdfBytes = await SalesSlipPdfGenerator.generateReturnExchange(
        detail: detail,
        orderNumber: orderNumber,
        customerDisplayName: customerDisplayName,
      );
      if (!mounted) return;
      if (action == SalesReturnExchangeSlipAction.print) {
        await SalesPdfRunner.print(
          context: context,
          bytes: pdfBytes,
          name: fileName,
        );
      } else if (action == SalesReturnExchangeSlipAction.share) {
        await SalesPdfRunner.share(
          context: context,
          bytes: pdfBytes,
          filename: fileName,
        );
      }
    } catch (error) {
      if (!mounted) return;
      VToast.show(
        context,
        title: 'Xuất PDF thất bại',
        message: '$error',
        type: VToastType.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SalesReturnExchangeDetailCubit, SalesReturnExchangeDetailState>(
        builder: (context, state) {
          return VPageScaffold(
            key: const Key('wgt_sg13_return_detail_page'),
            title: 'Chi tiết phiếu đổi/trả',
            showBackButton: true,
            leading: IconButton(
              key: const Key('btn_return_detail_back'),
              icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
              onPressed: _backToOrderDetail,
            ),
            bottomBar: state.detail != null
                ? VPagePadding(
                    vertical: VSpacing.space3,
                    child: VButton(
                      key: const Key('btn_return_detail_actions'),
                      label: 'Thao tác',
                      variant: VButtonVariant.primary,
                      tone: VComponentTone.success,
                      size: VButtonSize.large,
                      fullWidth: true,
                      trailingIcon: const VIcon(
                        icon: VIcons.expandLess,
                        iconColor: VIconColor.white,
                        iconSize: VIconSize.sm,
                      ),
                      onPressed: _openActions,
                    ),
                  )
                : null,
            body: SalesReturnExchangeDetailBody(
              state: state,
              onRetry: () => _cubit.refresh(),
              onOpenSourceOrder: _backToOrderDetail,
            ),
          );
        },
      ),
    );
  }
}

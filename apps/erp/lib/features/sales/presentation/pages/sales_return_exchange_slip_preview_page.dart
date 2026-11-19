import 'package:erp/core/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/presentation.dart';

/// Thin composition root — load return-exchange detail by ID rồi xem PDF.
class SalesReturnExchangeSlipPreviewPage extends StatefulWidget {
  const SalesReturnExchangeSlipPreviewPage({
    super.key,
    required this.orderId,
    required this.returnExchangeId,
  });

  final String orderId;
  final String returnExchangeId;

  @override
  State<SalesReturnExchangeSlipPreviewPage> createState() =>
      _SalesReturnExchangeSlipPreviewPageState();
}

class _SalesReturnExchangeSlipPreviewPageState extends State<SalesReturnExchangeSlipPreviewPage> {
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SalesReturnExchangeDetailCubit, SalesReturnExchangeDetailState>(
        builder: (context, state) {
          final detail = state.detail;
          if (state.status == SalesReturnExchangeDetailStatus.loading ||
              state.status == SalesReturnExchangeDetailStatus.initial) {
            return const VPageScaffold(
              key: Key('wgt_sg13_slip_preview_loading'),
              title: 'Phiếu đổi/trả',
              showBackButton: true,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (detail == null) {
            return VPageScaffold(
              key: const Key('wgt_sg13_slip_preview_error'),
              title: 'Phiếu đổi/trả',
              showBackButton: true,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VText(
                        state.screenError ?? 'Không tải được phiếu đổi/trả để xem trước.',
                        variant: VTextVariant.bodyDefault,
                        textAlign: TextAlign.center,
                      ),
                      const VGap.md(),
                      VButton(
                        key: const Key('btn_sg13_slip_preview_retry'),
                        label: 'Thử lại',
                        onPressed: () => _cubit.refresh(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SalesSlipPreviewPage(
            detail: detail,
            orderNumber: state.orderNumber,
            customerDisplayName: state.customerDisplayName,
            storeName: state.storeDisplayName,
            storeCode: state.storeCode,
            customerPhoneNumber: state.customerPhone,
          );
        },
      ),
    );
  }
}

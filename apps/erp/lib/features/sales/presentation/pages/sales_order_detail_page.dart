import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// SG-08 — Tra cứu chi tiết giao dịch gốc & Lịch sử (EP-03/US-02..07).
class SalesOrderDetailPage extends StatefulWidget {
  const SalesOrderDetailPage({
    super.key,
    required this.orderId,
    this.showHistory = true,
  });

  final String orderId;
  final bool showHistory;

  @override
  State<SalesOrderDetailPage> createState() => _SalesOrderDetailPageState();
}

class _SalesOrderDetailPageState extends State<SalesOrderDetailPage> {
  late final SalesOrderDetailCubit _cubit;
  int _selectedTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _cubit = SalesOrderDetailCubit(
      orderId: widget.orderId,
      salesModule: GetIt.instance<ISalesModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openActionsSheet(SalesOrderDetailVm vm) async {
    final state = _cubit.state;
    final actions = state.actions;
    if (state.actionsStatus != SalesOrderDetailSectionStatus.loaded || actions == null) {
      VToast.show(
        context,
        title: 'Không thể tải thao tác',
        message: state.actionsErrorMessage ?? 'Vui lòng thử lại sau.',
        type: VToastType.warning,
      );
      return;
    }
    final hasCollectedPayment = (state.payment?.paidTotalMinor ?? 0) > 0;
    final action = await showSalesOrderActionsSheet(
      context,
      canReturnExchange: actions.canReturnExchange,
      canCancel: actions.canCancel && !hasCollectedPayment,
      cancelDisabledReason: hasCollectedPayment ? 'Đơn đã có thanh toán, vui lòng đổi/trả' : null,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case SalesOrderSheetAction.returnExchange:
        await _navigateAfterPrecheck(_cubit.requestReturnExchange);
      case SalesOrderSheetAction.cancel:
        final intent = await _cubit.requestCancel();
        if (!mounted) return;
        if (intent == null) {
          _surfacePostSaleFeedback();
          return;
        }
        final cancelled = await showSalesOrderCancelSheet(
          context,
          vm: vm,
          onConfirmCancel: (_, note) => _confirmCancellationFromSheet(note),
        );
        if (!mounted || cancelled != true) return;
        await _cubit.refresh();
    }
  }

  Future<void> _navigateAfterPrecheck(
    Future<SalesPostSaleNavigationIntent?> Function() request,
  ) async {
    final intent = await request();
    if (!mounted) return;
    if (intent == null) {
      _surfacePostSaleFeedback();
      return;
    }

    switch (intent) {
      case SalesPostSaleNavigationIntent.cancel:
        final core = _cubit.state.core;
        if (core == null) return;
        final cancelled = await showSalesOrderCancelSheet(
          context,
          vm: core,
          onConfirmCancel: (_, note) => _confirmCancellationFromSheet(note),
        );
        if (!mounted || cancelled != true) return;
        await _cubit.refresh();
      case SalesPostSaleNavigationIntent.returnExchange:
        await SalesReturnNewRoute(orderId: widget.orderId).push(context);
    }
  }

  Future<bool> _confirmCancellationFromSheet(String note) async {
    final error = await _cubit.confirmCancellation(note: note);
    if (error != null) {
      _showCancellationFailure(error);
      return false;
    }
    return true;
  }

  void _showCancellationFailure(String message) {
    if (!mounted) return;
    final normalized = message.trim();
    VToast.show(
      context,
      title: 'Không thể huỷ đơn',
      message: normalized.isEmpty ? 'Vui lòng thử lại sau.' : normalized,
      type: VToastType.warning,
    );
  }

  void _surfacePostSaleFeedback() {
    final message = _cubit.state.postSaleFeedbackMessage;
    if (message == null || message.isEmpty) return;
    VToast.show(
      context,
      title: 'Không thể tiếp tục',
      message: message,
      type: VToastType.warning,
    );
  }

  Future<void> _openReceipt() async {
    final sheetAction = await showSalesResultReceiptSheet(context);
    if (!mounted || sheetAction == null) return;

    try {
      if (sheetAction == SalesResultReceiptAction.view) {
        final receipt = await _cubit.viewReceipt();
        if (!mounted) return;
        if (_surfaceReceiptFeedback()) return;
        if (receipt == null) return;
        await SalesOrderPreviewRoute(
          orderId: widget.orderId,
          $extra: receipt,
        ).push(context);
        return;
      }
      if (sheetAction == SalesResultReceiptAction.print) {
        await _cubit.printReceipt((document) async {
          final pdfBytes = await SalesReceiptPdfGenerator.generate(document);
          if (!mounted) return;
          await SalesPdfRunner.print(
            context: context,
            bytes: pdfBytes,
            name: SalesReceiptPdfGenerator.sanitizeFileName(document.receiptNumber),
          );
        });
        if (!mounted) return;
        _surfaceReceiptFeedback();
        return;
      }
      if (sheetAction == SalesResultReceiptAction.share) {
        await _cubit.shareReceipt((document) async {
          final pdfBytes = await SalesReceiptPdfGenerator.generate(document);
          if (!mounted) return;
          await SalesPdfRunner.share(
            context: context,
            bytes: pdfBytes,
            filename: SalesReceiptPdfGenerator.sanitizeFileName(document.receiptNumber),
          );
        });
        if (!mounted) return;
        _surfaceReceiptFeedback();
      }
    } catch (error) {
      if (!mounted) return;
      VToast.show(
        context,
        title: 'Thao tác phiếu thất bại',
        message: '$error',
        type: VToastType.danger,
      );
    }
  }

  /// Opens the e-invoice management sheet for this order. US-06 delivery
  /// tracking is deferred, so the sheet shows the cosmetic `notRequired` state
  /// until the e-invoice integration owner exists.
  Future<void> _openEInvoice() async {
    await showSalesResultEInvoiceSheet(
      context,
      status: IntegrationDeliveryStatus.notRequired,
    );
  }

  /// Surfaces receipt section error/warning via VToast. Returns true when feedback
  /// was shown for a blocking error (caller should stop navigation).
  bool _surfaceReceiptFeedback() {
    final receipt = _cubit.state.receipt;
    if (receipt.status == SalesReceiptOperationStatus.error) {
      VToast.show(
        context,
        title: 'Thao tác phiếu thất bại',
        message: _receiptIssueMessage(receipt.issue),
        type: VToastType.danger,
      );
      return true;
    }
    if (receipt.status == SalesReceiptOperationStatus.activityWarning) {
      VToast.show(
        context,
        title: 'Đã xử lý trên thiết bị',
        message: 'Cần đồng bộ hoạt động phiếu. Bạn có thể thử lại.',
        type: VToastType.warning,
      );
      return true;
    }
    return false;
  }

  String _receiptIssueMessage(SalesTransactionResultIssue? issue) {
    return switch (issue) {
      SalesTransactionResultIssue.permissionDenied => 'Bạn không có quyền thao tác phiếu bán hàng.',
      SalesTransactionResultIssue.projectionPending =>
        'Dữ liệu phiếu đang đồng bộ. Vui lòng thử lại sau.',
      SalesTransactionResultIssue.staleVersion =>
        'Đơn hàng đã thay đổi. Hãy tải lại chi tiết rồi thử lại.',
      SalesTransactionResultIssue.dependencyUnavailable =>
        'Dịch vụ phiếu tạm thời không khả dụng. Vui lòng thử lại.',
      SalesTransactionResultIssue.contextInvalid => 'Thiếu ngữ cảnh đơn hàng để tạo phiếu.',
      _ => 'Không thể hoàn tất thao tác phiếu. Vui lòng thử lại.',
    };
  }

  void _openPaymentDebt(SalesOrderDetailVm vm, SalesOrderPaymentVm payment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SalesOrderPaymentDebtPage(
          orderNumber: vm.orderNumber,
          customerName: vm.customerName,
          payment: payment,
        ),
      ),
    );
  }

  void _openHistory(SalesOrderDetailVm vm, SalesOrderHistoryVm history) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SalesOrderHistoryPage(
          orderNumber: vm.orderNumber,
          customerName: vm.customerName,
          history: history,
          fallbackActorName: vm.sellerName,
        ),
      ),
    );
  }

  void _openReturnList(SalesOrderDetailVm vm, List<SalesReturnExchangeSlipItemVm> returns) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SalesOrderReturnListPage(
          orderId: vm.orderId,
          orderNumber: vm.orderNumber,
          customerName: vm.customerName,
          returns: returns,
          onOpenReturnDetail: (returnExchangeId) {
            SalesReturnDetailRoute(
              orderId: vm.orderId,
              returnExchangeId: returnExchangeId,
            ).push(context);
          },
        ),
      ),
    );
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(SalesNav.ordersList);
    }
  }

  Widget _buildLeading(BuildContext context) {
    return IconButton(
      key: const Key('btn_order_detail_back'),
      icon: VIcon(
        icon: VIcons.chevronLeft,
        color: context.vColors.textPrimary,
      ),
      onPressed: _handleBack,
    );
  }

  Widget _statusScaffold({required Widget body, Key? scaffoldKey}) {
    return VPageScaffold(
      key: scaffoldKey,
      title: 'Chi tiết đơn hàng',
      showBackButton: true,
      leading: _buildLeading(context),
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SalesOrderDetailCubit, SalesOrderDetailState>(
        builder: (context, state) {
          switch (state.status) {
            case SalesOrderDetailStatus.initial:
            case SalesOrderDetailStatus.loading:
              return _statusScaffold(
                scaffoldKey: const Key('wgt_sg08_loading'),
                body: const Center(child: CircularProgressIndicator()),
              );
            case SalesOrderDetailStatus.blocked:
              return _statusScaffold(
                body: SalesOrderDetailErrorState(
                  kind: SalesOrderDetailErrorKind.blocked,
                  message: state.errorMessage,
                  onBack: _handleBack,
                ),
              );
            case SalesOrderDetailStatus.notFound:
              return _statusScaffold(
                body: SalesOrderDetailErrorState(
                  kind: SalesOrderDetailErrorKind.notFound,
                  message: state.errorMessage,
                  onBack: _handleBack,
                ),
              );
            case SalesOrderDetailStatus.projectionPending:
              return _statusScaffold(
                body: SalesOrderDetailErrorState(
                  kind: SalesOrderDetailErrorKind.projectionPending,
                  message: state.errorMessage,
                  onRetry: _cubit.load,
                ),
              );
            case SalesOrderDetailStatus.error:
              return _statusScaffold(
                body: SalesOrderDetailErrorState(
                  kind: SalesOrderDetailErrorKind.error,
                  message: state.errorMessage,
                  onRetry: _cubit.load,
                ),
              );
            case SalesOrderDetailStatus.loaded:
              final vm = state.core;
              if (vm == null) {
                return _statusScaffold(
                  body: SalesOrderDetailErrorState(
                    kind: SalesOrderDetailErrorKind.error,
                    onRetry: _cubit.load,
                  ),
                );
              }
              final returns = state.history?.returns ?? const [];
              final effectiveTabIndex = returns.isEmpty ? 0 : _selectedTabIndex;
              return PopScope(
                canPop: Navigator.of(context).canPop(),
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) {
                    context.go(SalesNav.ordersList);
                  }
                },
                child: VPageScaffold(
                  key: const Key('wgt_sg08_order_detail_page'),
                  title: 'Chi tiết đơn hàng',
                  showBackButton: true,
                  leading: _buildLeading(context),
                  bottomBar: vm.isCancelled
                      ? null
                      : SalesDetailActionBar(
                          vm: vm,
                          actionsReady:
                              state.actionsStatus == SalesOrderDetailSectionStatus.loaded ||
                              state.actionsStatus == SalesOrderDetailSectionStatus.error ||
                              state.actionsStatus == SalesOrderDetailSectionStatus.blocked,
                          onOpenActions: () => _openActionsSheet(vm),
                        ),
                  body: SalesOrderDetailBody(
                    vm: vm,
                    selectedTabIndex: effectiveTabIndex,
                    onTabSelected: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    payment: state.payment,
                    paymentStatus: state.paymentStatus,
                    paymentErrorMessage: state.paymentErrorMessage,
                    historyStatus: state.historyStatus,
                    returnSlips: returns,
                    cancellation: state.cancellation,
                    cancellationStatus: state.cancellationStatus,
                    cancellationErrorMessage: state.cancellationErrorMessage,
                    onRetryCancellation: _cubit.retryCancellationSection,
                    onOpenPaymentDebt: () {
                      final payment = state.payment;
                      if (payment == null) return;
                      _openPaymentDebt(vm, payment);
                    },
                    onOpenReturnList: () {
                      final returns = state.history?.returns ?? const [];
                      if (returns.isEmpty) return;
                      _openReturnList(vm, returns);
                    },
                    onOpenHistory: () {
                      final history = state.history;
                      if (history == null) return;
                      _openHistory(vm, history);
                    },
                    historyErrorMessage: state.historyErrorMessage,
                    onOpenReceipt: _openReceipt,
                    onOpenEInvoice: _openEInvoice,
                    onRetryPayment: _cubit.retryPaymentSection,
                    onRetryHistory: _cubit.retryHistorySection,
                    showHistory: widget.showHistory,
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

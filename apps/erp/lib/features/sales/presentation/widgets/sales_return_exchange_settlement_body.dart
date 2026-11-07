import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

import 'package:erp/features/sales/logic/sales_return_exchange_settlement_state.dart';
import '../models/return_exchange_order/sales_return_exchange_settlement_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';

/// SG-12 — Read-only settlement plan body (authoritative DTO amounts only).
class SalesReturnExchangeSettlementBody extends StatelessWidget {
  const SalesReturnExchangeSettlementBody({
    super.key,
    required this.state,
    this.onRetry,
    this.onSettledNowChanged,
    this.onDueDateChanged,
    this.onMethodChanged,
  });

  final SalesReturnExchangeSettlementState state;
  final VoidCallback? onRetry;

  /// Notifies the amount the customer settles right now, as the field changes.
  final ValueChanged<int>? onSettledNowChanged;

  /// Notifies the chosen payment due date (null clears it).
  final ValueChanged<DateTime?>? onDueDateChanged;

  /// Notifies the chosen collection method.
  final ValueChanged<SalesPaymentMethod>? onMethodChanged;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SalesReturnExchangeSettlementStatus.initial:
      case SalesReturnExchangeSettlementStatus.loading:
        return const Center(
          key: Key('wgt_sg12_loading'),
          child: CircularProgressIndicator(),
        );
      case SalesReturnExchangeSettlementStatus.blocked:
        return _panel(
          key: 'wgt_sg12_blocked',
          title: 'Không thể quyết toán',
          messages: state.blockers.map((b) => b.message).toList(),
        );
      case SalesReturnExchangeSettlementStatus.failure:
        return _panel(
          key: 'wgt_sg12_failure',
          title: 'Không tải được quyết toán',
          messages: [state.screenError ?? 'Lỗi không xác định'],
          onRetry: onRetry,
        );
      case SalesReturnExchangeSettlementStatus.ready:
      case SalesReturnExchangeSettlementStatus.stale:
      case SalesReturnExchangeSettlementStatus.retryableFailure:
      case SalesReturnExchangeSettlementStatus.confirming:
      case SalesReturnExchangeSettlementStatus.processing:
      case SalesReturnExchangeSettlementStatus.success:
        final settlement = state.effectiveSettlement;
        if (settlement == null) {
          if (state.screenError != null) {
            return _panel(
              key: 'wgt_sg12_failure',
              title: 'Không tải được quyết toán',
              messages: [state.screenError!],
              onRetry: onRetry,
            );
          }
          return _panel(
            key: 'wgt_sg12_failure',
            title: 'Thiếu kế hoạch quyết toán',
            messages: const ['Hệ thống chưa trả settlement plan.'],
            onRetry: onRetry,
          );
        }
        return _ReadyBody(
          orderNumber: state.orderNumber,
          customerDisplayName: state.customerDisplayName,
          isWalkIn: state.isWalkIn,
          settlement: settlement,
          valuation: state.valuation,
          screenError: state.screenError,
          onRetry: onRetry,
          dueDate: state.paymentDueDate,
          method: state.paymentMethod,
          onSettledNowChanged: onSettledNowChanged,
          onDueDateChanged: onDueDateChanged,
          onMethodChanged: onMethodChanged,
        );
    }
  }

  Widget _panel({
    required String key,
    required String title,
    required List<String> messages,
    VoidCallback? onRetry,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.vColors;
        return SingleChildScrollView(
          key: Key(key),
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VText(
                title,
                variant: VTextVariant.headingH4,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const VGap.sm(),
              for (final message in messages) ...[
                VText(
                  message,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textSecondary,
                ),
                const VGap.xs(),
              ],
              if (onRetry != null) ...[
                const VGap.md(),
                VButton(
                  key: const Key('btn_sg12_retry'),
                  label: 'Thử lại',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReadyBody extends StatefulWidget {
  const _ReadyBody({
    required this.orderNumber,
    this.customerDisplayName = '',
    this.isWalkIn = false,
    required this.settlement,
    required this.valuation,
    required this.screenError,
    required this.onRetry,
    required this.dueDate,
    required this.method,
    required this.onSettledNowChanged,
    required this.onDueDateChanged,
    required this.onMethodChanged,
  });

  final String orderNumber;
  final String customerDisplayName;
  final bool isWalkIn;
  final SalesReturnExchangeSettlementVm settlement;
  final ReturnExchangeValuationDto? valuation;
  final String? screenError;
  final VoidCallback? onRetry;
  final DateTime? dueDate;
  final SalesPaymentMethod method;
  final ValueChanged<int>? onSettledNowChanged;
  final ValueChanged<DateTime?>? onDueDateChanged;
  final ValueChanged<SalesPaymentMethod>? onMethodChanged;

  @override
  State<_ReadyBody> createState() => _ReadyBodyState();
}

class _ReadyBodyState extends State<_ReadyBody> {
  late final TextEditingController _amountController;
  bool _planExpanded = false;

  static const _methods = <SalesPaymentMethod>[
    SalesPaymentMethod.cash,
    SalesPaymentMethod.manualBankTransfer,
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: MoneyFormatter.formatMinorPlain(_primaryAmountMinor),
    )..addListener(_onAmountChanged);
  }

  @override
  void didUpdateWidget(covariant _ReadyBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settlement != widget.settlement) {
      _amountController.text = MoneyFormatter.formatMinorPlain(_primaryAmountMinor);
    }
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_onAmountChanged)
      ..dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
    widget.onSettledNowChanged?.call(_settledNowMinor);
    // Paying in full again removes the shortfall, so drop any pending due date.
    if (_isCollect && _outstandingMinor == 0 && widget.dueDate != null) {
      widget.onDueDateChanged?.call(null);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = widget.dueDate;
    final initial = (current == null || current.isBefore(today)) ? today : current;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      widget.onDueDateChanged?.call(picked);
    }
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  /// Amount the customer settles right now, parsed from the editable field.
  int get _settledNowMinor => MoneyFormatter.parseMinor(_amountController.text);

  /// Outstanding balance that follows the edited "settle now" amount.
  ///
  /// Collect: debt still owed by the customer after paying now.
  /// Refund: amount still to hand back after refunding now.
  int get _outstandingMinor {
    final remainder = _isCollect
        ? widget.settlement.customerCollectMinor - _settledNowMinor
        : widget.settlement.storeRefundMinor -
              widget.settlement.receivableReverseMinor -
              _settledNowMinor;
    return remainder > 0 ? remainder : 0;
  }

  int get _primaryAmountMinor {
    if (widget.settlement.customerCollectMinor > 0) {
      return widget.settlement.customerCollectMinor;
    }
    if (widget.settlement.storeRefundMinor > 0) {
      return widget.settlement.storeRefundMinor;
    }
    return 0;
  }

  bool get _isCollect => widget.settlement.customerCollectMinor > 0;

  // A return on an unpaid order refunds nothing but still reduces the order
  // debt, so only a zero net difference means "no difference".
  bool get _isZeroDifference => widget.settlement.netDifferenceMinor == 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final headerBuffer = StringBuffer();
    if (widget.orderNumber.isNotEmpty) {
      headerBuffer.write(widget.orderNumber);
    }
    if (widget.customerDisplayName.isNotEmpty) {
      if (headerBuffer.isNotEmpty) headerBuffer.write(' · ');
      headerBuffer.write(widget.customerDisplayName);
    }
    final subheaderText = headerBuffer.isNotEmpty ? headerBuffer.toString() : 'Quyết toán đổi/trả';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            subheaderText,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          if (widget.screenError != null) ...[
            const VGap.md(),
            VBanner(
              key: const Key('wgt_sg12_screen_error'),
              title: widget.screenError!,
              status: VBannerStatus.warning,
              trailing: widget.onRetry == null
                  ? null
                  : VButton(
                      label: 'Tải lại',
                      variant: VButtonVariant.secondary,
                      size: VButtonSize.small,
                      onPressed: widget.onRetry,
                    ),
            ),
          ],
          const VGap.md(),
          VCard(
            backgroundColor: colors.surface,
            border: Border.all(color: colors.borderDefault),
            padding: const EdgeInsets.all(VSpacing.space4),
            child: _isZeroDifference
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _highlightAmount(context),
                      const VGap.md(),
                      VText(
                        'Không cần thu thêm, hoàn tiền hoặc ghi nhận công nợ.',
                        variant: VTextVariant.bodyDefault,
                        color: colors.textPrimary,
                      ),
                    ],
                  )
                : !_isCollect
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Server split (Sales): refund up to what was collected; the
                      // rest reduces this order's own debt. Cross-order debt offset
                      // belongs to Receivable, so the switch below is locked.
                      _highlightAmount(context),
                      if (widget.settlement.receivableReverseMinor > 0) ...[
                        const VGap.sm(),
                        VCard(
                          key: const Key('wgt_sg12_debt_reduction'),
                          backgroundColor: colors.surfaceAlt,
                          border: Border.all(color: colors.borderDefault),
                          padding: const EdgeInsets.symmetric(
                            horizontal: VSpacing.space3,
                            vertical: VSpacing.space3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const VText(
                                'Giảm nợ đơn này',
                                variant: VTextVariant.bodyDefault,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              VText(
                                MoneyFormatter.formatMinor(
                                  widget.settlement.receivableReverseMinor,
                                ),
                                variant: VTextVariant.bodyDefault,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const VGap.xs(),
                        VText(
                          'Phần khách chưa thanh toán cho hàng trả được trừ khỏi nợ của đơn, không hoàn tiền.',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                        const VGap.md(),
                        Row(
                          children: [
                            VSwitch(
                              key: const Key('sw_sg12_offset_debt'),
                              value: false,
                              enabled: false,
                              tone: VComponentTone.success,
                            ),
                            const VGap.horizontalSm(),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VText(
                                    'Cấn trừ công nợ hiện tại',
                                    variant: VTextVariant.bodyDefault,
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  VText(
                                    'Sẽ áp dụng khi có module công nợ.',
                                    key: const Key('txt_sg12_offset_debt_pending'),
                                    variant: VTextVariant.bodySmall,
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.settlement.storeRefundMinor > 0) ...[
                        const VGap.md(),
                        const VText(
                          'Phương thức hoàn',
                          variant: VTextVariant.bodyDefault,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const VGap.sm(),
                        // Refund supports one method; "Kết hợp" (split) is not
                        // supported by the confirm RPC, so it is not offered.
                        VSegmentedControl(
                          key: const Key('seg_sg12_settlement_method'),
                          segments: const ['Tiền mặt', 'Chuyển khoản'],
                          selectedIndex: _methods.indexOf(widget.method),
                          tone: VComponentTone.success,
                          onChanged: (index) {
                            widget.onMethodChanged?.call(_methods[index]);
                          },
                        ),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _highlightAmount(context),
                      const VGap.md(),
                      const VText(
                        'Khách thanh toán ngay',
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const VGap.sm(),
                      VTextField(
                        key: const Key('txt_sg12_settlement_amount'),
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        suffixText: 'đ',
                        inputFormatters: const [_VndGroupingFormatter()],
                        // Walk-ins cannot carry a receivable, so they pay in full.
                        enabled: !widget.isWalkIn,
                      ),
                      if (widget.isWalkIn) ...[
                        const VGap.xs(),
                        VText(
                          'Thu đủ, không phát sinh công nợ.',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ],
                      const VGap.md(),
                      const VText(
                        'Phương thức thu',
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const VGap.sm(),
                      VSegmentedControl(
                        key: const Key('seg_sg12_settlement_method'),
                        segments: const ['Tiền mặt', 'Chuyển khoản'],
                        selectedIndex: _methods.indexOf(widget.method),
                        tone: VComponentTone.success,
                        onChanged: (index) {
                          widget.onMethodChanged?.call(_methods[index]);
                        },
                      ),
                      if (widget.method != SalesPaymentMethod.cash) ...[
                        const VGap.md(),
                        _QrPaymentBlock(
                          amountMinor: _primaryAmountMinor,
                        ),
                      ],
                      const VGap.lg(),
                      _amountRow(
                        context,
                        'Công nợ phát sinh',
                        _outstandingMinor,
                        secondary: true,
                      ),
                      if (_outstandingMinor > 0) ...[
                        const VGap.md(),
                        Row(
                          children: [
                            const VText(
                              'Ngày hẹn thanh toán',
                              variant: VTextVariant.bodyDefault,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            VText(
                              '*',
                              variant: VTextVariant.bodyDefault,
                              color: colors.danger,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const VGap.sm(),
                        InkWell(
                          key: const Key('fld_sg12_due_date'),
                          onTap: _pickDueDate,
                          borderRadius: BorderRadius.circular(VRadius.r8),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(
                              horizontal: VSpacing.space3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              border: Border.all(color: colors.borderDefault),
                              borderRadius: BorderRadius.circular(VRadius.r8),
                            ),
                            child: Row(
                              children: [
                                VIcon(
                                  icon: VIcons.calendar,
                                  size: 20,
                                  color: colors.textSecondary,
                                ),
                                const VGap.horizontalSm(),
                                Expanded(
                                  child: VText(
                                    widget.dueDate != null
                                        ? _formatDate(widget.dueDate!)
                                        : 'Chọn ngày hẹn',
                                    variant: VTextVariant.bodyDefault,
                                    color: widget.dueDate != null
                                        ? colors.textPrimary
                                        : colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const VGap.md(),
          VCard(
            key: const Key('wgt_sg12_settlement_plan'),
            backgroundColor: colors.surface,
            border: Border.all(color: colors.borderDefault),
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  key: const Key('btn_sg12_plan_toggle'),
                  onTap: () => setState(() => _planExpanded = !_planExpanded),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const VText(
                              'Tóm tắt đổi/trả',
                              variant: VTextVariant.bodyDefault,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const VGap.xs(),
                            VText(
                              'Chênh lệch ${_signedMoney(widget.settlement.netDifferenceMinor)}',
                              variant: VTextVariant.bodySmall,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      VIcon(
                        icon: _planExpanded ? VIcons.chevronUp : VIcons.chevronDown,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                if (_planExpanded) ...[
                  if (widget.valuation != null) ...[
                    const VGap.md(),
                    KeyedSubtree(
                      key: const Key('wgt_sg12_plan_breakdown'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _amountRow(
                            context,
                            'Giá trị hàng trả',
                            widget.valuation!.returnValue.amountMinor,
                            secondary: true,
                          ),
                          const VGap.sm(),
                          _amountRow(
                            context,
                            'Giá trị hàng đổi',
                            widget.valuation!.exchangeValue.amountMinor,
                            secondary: true,
                          ),
                          const VGap.sm(),
                          KeyedSubtree(
                            key: widget.settlement.storeRefundMinor > 0
                                ? const Key('wgt_sg12_plan_refund')
                                : widget.settlement.customerCollectMinor > 0
                                ? const Key('wgt_sg12_plan_collect')
                                : const Key('wgt_sg12_plan_diff'),
                            child: _amountRow(
                              context,
                              'Chênh lệch',
                              widget.settlement.netDifferenceMinor,
                              secondary: true,
                              isSigned: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const VGap.xl(),
        ],
      ),
    );
  }

  Widget _highlightAmount(BuildContext context) {
    final colors = context.vColors;
    final String label;
    final int amountMinor;
    if (widget.settlement.customerCollectMinor > 0) {
      label = 'Phải thu thêm';
      amountMinor = widget.settlement.customerCollectMinor;
    } else if (widget.settlement.netDifferenceMinor < 0) {
      label = 'Cần hoàn tiền';
      amountMinor = widget.settlement.storeRefundMinor;
    } else {
      label = 'Không phát sinh chênh lệch';
      amountMinor = 0;
    }

    return VCard(
      key: const Key('wgt_sg12_primary_amount'),
      backgroundColor: colors.successBg,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space3,
        vertical: VSpacing.space3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VText(
            label,
            variant: VTextVariant.bodyDefault,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          VText(
            MoneyFormatter.formatMinor(amountMinor),
            variant: VTextVariant.bodyDefault,
            color: colors.success,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    int amountMinor, {
    bool secondary = false,
    bool isSigned = false,
  }) {
    final colors = context.vColors;
    final amountText = isSigned
        ? _signedMoney(amountMinor)
        : MoneyFormatter.formatMinor(amountMinor);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: secondary ? VTextVariant.bodySmall : VTextVariant.bodyDefault,
          color: secondary ? colors.textSecondary : colors.textPrimary,
          style: secondary ? null : const TextStyle(fontWeight: FontWeight.bold),
        ),
        VText(
          amountText,
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _signedMoney(int amountMinor) {
    final prefix = amountMinor > 0
        ? '+'
        : amountMinor < 0
        ? '-'
        : '';
    return '$prefix${MoneyFormatter.formatMinor(amountMinor.abs())}';
  }
}

class _QrPaymentBlock extends StatelessWidget {
  const _QrPaymentBlock({
    required this.amountMinor,
  });

  final int amountMinor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QrPlaceholder(),
        const VGap.horizontalMd(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VText(
                'QR cửa hàng · ACB',
                variant: VTextVariant.bodyDefault,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const VGap.xs(),
              const VText('1028 6888', variant: VTextVariant.bodySmall),
              const VGap.xs(),
              VText(
                'Nguyễn Văn A',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
              const VGap.xs(),
              VText(
                'Số tiền trên QR',
                variant: VTextVariant.bodySmall,
                color: colors.textMuted,
              ),
              const VGap.xs(),
              VText(
                MoneyFormatter.formatMinor(amountMinor),
                variant: VTextVariant.bodySmall,
                color: colors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: CustomPaint(
        key: const Key('wgt_sg12_qr_placeholder'),
        painter: _QrPlaceholderPainter(),
      ),
    );
  }
}

class _QrPlaceholderPainter extends CustomPainter {
  static const _cells = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _cells;
    final paint = Paint()..color = Colors.black;

    void drawCell(int x, int y) {
      canvas.drawRect(
        Rect.fromLTWH(x * cell, y * cell, cell, cell),
        paint,
      );
    }

    void finder(int x, int y) {
      for (var yy = 0; yy < 4; yy++) {
        for (var xx = 0; xx < 4; xx++) {
          if (xx == 0 || yy == 0 || xx == 3 || yy == 3 || (xx == 1 && yy == 1)) {
            drawCell(x + xx, y + yy);
          }
        }
      }
    }

    finder(0, 0);
    finder(9, 0);
    finder(0, 9);

    const cells = <(int, int)>[
      (5, 0),
      (6, 0),
      (4, 1),
      (7, 1),
      (5, 2),
      (8, 2),
      (4, 4),
      (6, 4),
      (8, 4),
      (12, 4),
      (1, 5),
      (3, 5),
      (5, 5),
      (7, 5),
      (9, 5),
      (11, 5),
      (0, 6),
      (2, 6),
      (6, 6),
      (8, 6),
      (10, 6),
      (12, 6),
      (1, 7),
      (4, 7),
      (5, 7),
      (9, 7),
      (11, 7),
      (3, 8),
      (6, 8),
      (7, 8),
      (10, 8),
      (12, 8),
      (5, 9),
      (8, 9),
      (4, 10),
      (6, 10),
      (9, 10),
      (11, 10),
      (5, 11),
      (7, 11),
      (10, 11),
      (12, 11),
      (4, 12),
      (6, 12),
      (8, 12),
      (11, 12),
    ];

    for (final (x, y) in cells) {
      drawCell(x, y);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Regroups the VND amount with `.` separators on every edit so deleting a
/// digit never leaves a stale grouping such as `450.00`.
class _VndGroupingFormatter extends TextInputFormatter {
  const _VndGroupingFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(selection: TextSelection.collapsed(offset: 0));
    }
    final formatted = MoneyFormatter.formatMinorPlain(MoneyFormatter.parseMinor(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

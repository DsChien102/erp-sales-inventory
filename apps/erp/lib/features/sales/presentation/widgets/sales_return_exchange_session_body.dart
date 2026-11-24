import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';

import 'package:erp/features/sales/logic/sales_return_exchange_session_state.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'sales_return_exchange_session_line_rows.dart';

/// SG-11 — Body hiển thị session trả/đổi từ [SalesReturnExchangeSessionState].
class SalesReturnExchangeSessionBody extends StatelessWidget {
  const SalesReturnExchangeSessionBody({
    super.key,
    required this.state,
    this.onRetry,
    required this.onReturnQuantityChanged,
    required this.onExchangeQuantityChanged,
    this.onAddExchangePressed,
  });

  final SalesReturnExchangeSessionState state;
  final VoidCallback? onRetry;
  final void Function(String salesOrderLineId, int quantityMicros) onReturnQuantityChanged;
  final void Function(String productUnitId, int quantityMicros) onExchangeQuantityChanged;
  final VoidCallback? onAddExchangePressed;

  bool get _canAddExchange => state.returnEdits.any((edit) => edit.quantityMicros > 0);

  bool get _showContent {
    switch (state.status) {
      case SalesReturnExchangeSessionStatus.ready:
      case SalesReturnExchangeSessionStatus.retryableFailure:
      case SalesReturnExchangeSessionStatus.stale:
      case SalesReturnExchangeSessionStatus.saving:
        return true;
      case SalesReturnExchangeSessionStatus.failure:
        return state.returnableLines.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SalesReturnExchangeSessionStatus.initial:
      case SalesReturnExchangeSessionStatus.loading:
        return const Center(
          key: Key('wgt_sg11_loading'),
          child: CircularProgressIndicator(),
        );
      case SalesReturnExchangeSessionStatus.blocked:
        return _MessagePanel(
          key: const Key('wgt_sg11_blocked'),
          title: 'Không thể đổi/trả đơn ${state.orderNumber}',
          messages: state.blockers.map((b) => b.message).toList(),
          onRetry: onRetry,
        );
      case SalesReturnExchangeSessionStatus.failure:
        if (!_showContent) {
          return _MessagePanel(
            key: const Key('wgt_sg11_error'),
            title: 'Không thể tải phiên đổi/trả',
            messages: [
              if (state.screenError != null) state.screenError!,
            ],
            onRetry: onRetry,
          );
        }
        return _SessionContent(
          state: state,
          canAddExchange: _canAddExchange,
          onRetry: onRetry,
          onReturnQuantityChanged: onReturnQuantityChanged,
          onExchangeQuantityChanged: onExchangeQuantityChanged,
          onAddExchangePressed: onAddExchangePressed,
        );
      case SalesReturnExchangeSessionStatus.discarded:
        return const SizedBox.shrink();
      case SalesReturnExchangeSessionStatus.ready:
      case SalesReturnExchangeSessionStatus.retryableFailure:
      case SalesReturnExchangeSessionStatus.stale:
      case SalesReturnExchangeSessionStatus.saving:
        return _SessionContent(
          state: state,
          canAddExchange: _canAddExchange,
          onRetry: onRetry,
          onReturnQuantityChanged: onReturnQuantityChanged,
          onExchangeQuantityChanged: onExchangeQuantityChanged,
          onAddExchangePressed: onAddExchangePressed,
        );
    }
  }
}

class _SessionContent extends StatelessWidget {
  const _SessionContent({
    required this.state,
    required this.canAddExchange,
    required this.onRetry,
    required this.onReturnQuantityChanged,
    required this.onExchangeQuantityChanged,
    required this.onAddExchangePressed,
  });

  final SalesReturnExchangeSessionState state;
  final bool canAddExchange;
  final VoidCallback? onRetry;
  final void Function(String salesOrderLineId, int quantityMicros) onReturnQuantityChanged;
  final void Function(String productUnitId, int quantityMicros) onExchangeQuantityChanged;
  final VoidCallback? onAddExchangePressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final editsEnabled = state.status != SalesReturnExchangeSessionStatus.saving;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            '${state.orderNumber} · ${state.customerDisplayName}',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const VGap.xs(),
          VText(
            'Chọn hàng trả và số lượng.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          if (state.screenError != null) ...[
            const VGap.md(),
            VBanner(
              key: const Key('wgt_sg11_screen_error'),
              title: state.screenError!,
              status: VBannerStatus.error,
              trailing: onRetry == null
                  ? null
                  : VButton(
                      key: const Key('btn_sg11_retry'),
                      label: 'Thử lại',
                      variant: VButtonVariant.secondary,
                      size: VButtonSize.small,
                      onPressed: onRetry,
                    ),
            ),
          ],
          if (state.fieldError != null) ...[
            const VGap.sm(),
            VBanner(
              key: const Key('wgt_sg11_field_error'),
              title: state.fieldError!,
              status: VBannerStatus.warning,
            ),
          ],
          const VGap.md(),
          const VText(
            'Hàng trả',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.xs(),
          VCard(
            backgroundColor: colors.surface,
            border: Border.all(color: colors.borderDefault),
            padding: const EdgeInsets.all(VSpacing.space2),
            child: Column(
              children: [
                for (var i = 0; i < state.returnableLines.length; i++) ...[
                  if (i > 0) Divider(color: colors.borderDefault, height: 1),
                  SalesReturnExchangeReturnLineRow(
                    line: state.returnableLines[i],
                    edit: _returnEdit(state.returnableLines[i].unitId),
                    enabled: editsEnabled,
                    onQuantityChanged: onReturnQuantityChanged,
                  ),
                ],
              ],
            ),
          ),
          const VGap.md(),
          const VText(
            'Hàng đổi',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.xs(),
          if (state.exchangeEdits.isNotEmpty) ...[
            VCard(
              backgroundColor: colors.surface,
              border: Border.all(color: colors.borderDefault),
              padding: const EdgeInsets.all(VSpacing.space2),
              child: Column(
                children: [
                  for (var i = 0; i < state.exchangeEdits.length; i++) ...[
                    if (i > 0) Divider(color: colors.borderDefault, height: 1),
                    SalesReturnExchangeExchangeLineRow(
                      edit: state.exchangeEdits[i],
                      enabled: editsEnabled,
                      onQuantityChanged: onExchangeQuantityChanged,
                    ),
                  ],
                ],
              ),
            ),
            const VGap.sm(),
          ],
          VButton(
            key: const Key('btn_add_exchange_product'),
            label: 'Chọn hàng đổi',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: canAddExchange && editsEnabled ? onAddExchangePressed : null,
          ),
          const VGap.md(),
          _ExpectedSummaryCard(state: state),
          const VGap.xl(),
        ],
      ),
    );
  }

  SalesReturnLineEdit? _returnEdit(String salesOrderLineId) {
    for (final edit in state.returnEdits) {
      if (edit.salesOrderLineId == salesOrderLineId) return edit;
    }
    return null;
  }
}

class _ExpectedSummaryCard extends StatelessWidget {
  const _ExpectedSummaryCard({required this.state});

  final SalesReturnExchangeSessionState state;

  int get _returnValueMinor {
    var total = 0;
    for (final edit in state.returnEdits) {
      if (edit.quantityMicros <= 0) continue;
      final line = _returnableLine(edit.salesOrderLineId);
      if (line == null) continue;
      total += _lineAmountMinor(
        unitPriceMinor: line.originalUnitPrice.amountMinor,
        quantityMicros: edit.quantityMicros,
      );
    }
    return total;
  }

  int get _exchangeValueMinor {
    var total = 0;
    for (final edit in state.exchangeEdits) {
      if (edit.quantityMicros <= 0) continue;
      total += _lineAmountMinor(
        unitPriceMinor: edit.unitPrice.amountMinor,
        quantityMicros: edit.quantityMicros,
      );
    }
    return total;
  }

  int get _differenceMinor => _exchangeValueMinor - _returnValueMinor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final difference = _differenceMinor;
    final differenceColor = difference > 0
        ? colors.warning
        : difference < 0
        ? colors.success
        : colors.textPrimary;
    final differenceBgColor = difference > 0
        ? colors.warning.withValues(alpha: 0.10)
        : difference < 0
        ? colors.success.withValues(alpha: 0.10)
        : colors.surfaceAlt;

    return VCard(
      key: const Key('wgt_sg11_expected_summary'),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VText(
            'Tóm tắt dự kiến',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.md(),
          _ExpectedSummaryRow(
            label: 'Giá trị hàng trả',
            amountMinor: _returnValueMinor,
          ),
          const VGap.sm(),
          _ExpectedSummaryRow(
            label: 'Giá trị hàng đổi',
            amountMinor: _exchangeValueMinor,
          ),
          const VGap.md(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space3,
              vertical: VSpacing.space3,
            ),
            decoration: BoxDecoration(
              color: differenceBgColor,
              borderRadius: BorderRadius.circular(VRadius.r8),
            ),
            child: _ExpectedSummaryRow(
              label: 'Chênh lệch',
              amountMinor: difference,
              labelWeight: FontWeight.bold,
              valueColor: differenceColor,
            ),
          ),
        ],
      ),
    );
  }

  ReturnableOrderLineDto? _returnableLine(String salesOrderLineId) {
    for (final line in state.returnableLines) {
      if (line.unitId == salesOrderLineId) return line;
    }
    return null;
  }

  int _lineAmountMinor({
    required int unitPriceMinor,
    required int quantityMicros,
  }) {
    return unitPriceMinor * quantityMicros ~/ QuantityDto.scale;
  }
}

class _ExpectedSummaryRow extends StatelessWidget {
  const _ExpectedSummaryRow({
    required this.label,
    required this.amountMinor,
    this.labelWeight,
    this.valueColor,
  });

  final String label;
  final int amountMinor;
  final FontWeight? labelWeight;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      children: [
        Expanded(
          child: VText(
            label,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
            style: TextStyle(fontWeight: labelWeight),
          ),
        ),
        VText(
          MoneyFormatter.formatMinor(amountMinor),
          variant: VTextVariant.bodySmall,
          color: valueColor ?? colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    super.key,
    required this.title,
    required this.messages,
    this.onRetry,
  });

  final String title;
  final List<String> messages;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VIcon(icon: VIcons.warning, color: colors.danger),
              const VGap.xs(),
              Expanded(
                child: VText(
                  title,
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
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
              key: const Key('btn_sg11_reload'),
              label: 'Tải lại',
              variant: VButtonVariant.secondary,
              fullWidth: true,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

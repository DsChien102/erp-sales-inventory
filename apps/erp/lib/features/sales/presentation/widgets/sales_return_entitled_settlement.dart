import 'package:erp/features/receivable/logic/receivable_format.dart';
import 'package:erp/features/receivable/presentation/widgets/receivable_parts.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/logic/return_settlement_preview.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// SG-13 nhánh "khách được hưởng" (TH-06 EP-03), dựng theo `app/sg13.js`:
/// khách được hưởng bao nhiêu, chia thế nào, và chọn đơn nhận cấn trừ.
class SalesReturnEntitledSettlement extends StatelessWidget {
  const SalesReturnEntitledSettlement({
    super.key,
    required this.orderCode,
    required this.customerDisplayName,
    required this.entitledMinor,
    required this.returnValueMinor,
    required this.exchangeValueMinor,
    required this.preview,
    required this.candidates,
    required this.selectedIds,
    required this.onToggle,
    required this.method,
    required this.onMethodChanged,
    this.today,
  });

  final String orderCode;
  final String customerDisplayName;
  final int entitledMinor;
  final int returnValueMinor;
  final int exchangeValueMinor;
  final ReturnSettlementPreview preview;
  final List<ReturnExchangeOffsetCandidateDto> candidates;
  final Set<String> selectedIds;
  final ValueChanged<String>? onToggle;
  final SalesPaymentMethod method;
  final ValueChanged<SalesPaymentMethod>? onMethodChanged;
  final DateTime? today;

  static const _methods = <SalesPaymentMethod>[
    SalesPaymentMethod.cash,
    SalesPaymentMethod.manualBankTransfer,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final now = today ?? DateTime.now();
    final sub = [
      if (orderCode.isNotEmpty) orderCode,
      if (customerDisplayName.isNotEmpty) customerDisplayName,
    ].join(' · ');
    final sharesById = {for (final o in preview.offsets) o.salesOrderId: o.amountMinor};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sub.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.space4,
              VSpacing.space3,
              VSpacing.space4,
              0,
            ),
            child: Text(
              sub,
              style: VTypography.labelDefault.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpacing.space4, VSpacing.space5, VSpacing.space4, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Khách được hưởng',
                style: VTypography.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                formatVnd(entitledMinor),
                key: const Key('wgt_sg13_entitled_amount'),
                style: receivableMoneyStyle(
                  context,
                  fontSize: 28,
                  height: 1.3,
                  color: colors.success,
                ).copyWith(letterSpacing: -0.5),
              ),
              Text(
                'Chênh lệch −${formatVnd(entitledMinor)} · '
                'Hàng trả ${formatVndBare(returnValueMinor)} · '
                'Hàng đổi ${formatVndBare(exchangeValueMinor)}',
                style: VTypography.bodySmall.copyWith(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _flow(context),
        if (preview.showOffsetBlock) ...[
          const ReceivableSectionTitle('CẤN TRỪ VÀO ĐƠN KHÁC'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
            child: Text(
              'Trừ vào nợ đơn khác của khách thay vì hoàn tiền.',
              style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          for (final c in candidates)
            _OffsetRow(
              candidate: c,
              today: now,
              on: selectedIds.contains(c.salesOrderId),
              shareMinor: sharesById[c.salesOrderId] ?? 0,
              onToggle: onToggle,
            ),
        ],
        const SizedBox(height: VSpacing.space6),
      ],
    );
  }

  Widget _flow(BuildContext context) {
    final colors = context.vColors;
    final offsetSum = preview.offsetTotalMinor;
    final segs = <(Color, int)>[
      if (preview.reduceOwnDebtMinor > 0) (colors.info, preview.reduceOwnDebtMinor),
      if (offsetSum > 0) (colors.primary, offsetSum),
      if (preview.refundMinor > 0) (VColors.neutral400, preview.refundMinor),
    ];
    return Container(
      key: const Key('wgt_sg13_flow'),
      margin: const EdgeInsets.fromLTRB(VSpacing.space4, VSpacing.space3, VSpacing.space4, 0),
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (segs.isNotEmpty)
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.pill),
                child: Container(
                  height: 8,
                  color: VColors.neutral200,
                  child: Row(
                    children: [
                      for (var i = 0; i < segs.length; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: (segs[i].$2 ~/ 1000).clamp(1, 1 << 30),
                          child: ColoredBox(color: segs[i].$1, child: const SizedBox.expand()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (preview.reduceOwnDebtMinor > 0) ...[
            const SizedBox(height: VSpacing.space2),
            _FlowRow(
              key: const Key('wgt_sg12_debt_reduction'),
              dot: colors.info,
              label: 'Giảm nợ đơn này',
              note: 'Trừ vào nợ của chính đơn này',
              value: formatVnd(preview.reduceOwnDebtMinor),
            ),
          ],
          if (preview.showOffsetBlock) ...[
            const SizedBox(height: VSpacing.space2),
            _FlowRow(
              dot: colors.primary,
              label: 'Cấn trừ vào đơn khác',
              value: formatVnd(offsetSum),
            ),
          ],
          const SizedBox(height: VSpacing.space2),
          _FlowRow(
            dot: VColors.neutral400,
            label: 'Hoàn cho khách',
            value: formatVnd(preview.refundMinor),
          ),
          if (preview.refundMinor > 0) ...[
            const SizedBox(height: VSpacing.space2),
            Text(
              'Phương thức hoàn',
              style: VTypography.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: VSpacing.space2),
            VSegmentedControl(
              key: const Key('seg_sg12_settlement_method'),
              segments: const ['Tiền mặt', 'CK'],
              selectedIndex: _methods.indexOf(method).clamp(0, _methods.length - 1),
              tone: VComponentTone.success,
              onChanged: (index) => onMethodChanged?.call(_methods[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    super.key,
    required this.dot,
    required this.label,
    required this.value,
    this.note,
  });

  final Color dot;
  final String label;
  final String? note;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 12,
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: VSpacing.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: VTypography.bodyDefault.copyWith(fontSize: 14, color: colors.textPrimary),
              ),
              if (note != null)
                Text(
                  note!,
                  style: VTypography.bodySmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: VSpacing.space2),
        Text(
          value,
          softWrap: false,
          textAlign: TextAlign.right,
          style: receivableMoneyStyle(context),
        ),
      ],
    );
  }
}

class _OffsetRow extends StatelessWidget {
  const _OffsetRow({
    required this.candidate,
    required this.today,
    required this.on,
    required this.shareMinor,
    required this.onToggle,
  });

  final ReturnExchangeOffsetCandidateDto candidate;
  final DateTime today;
  final bool on;
  final int shareMinor;
  final ValueChanged<String>? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final due = orderDueLabel(
      dueDate: candidate.dueDate,
      overdueDays: candidate.overdueDays,
      today: today,
    );
    void toggle() => onToggle?.call(candidate.salesOrderId);
    final title = '${candidate.orderCode} · còn nợ ${formatVnd(candidate.outstandingMinor)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(VSpacing.space4, 0, VSpacing.space4, VSpacing.space2),
      child: Semantics(
        checked: on,
        button: true,
        container: true,
        // TH-06 5.6: đọc đủ hạn nợ ("Quá hạn N ngày"), không chỉ màu đỏ.
        label: '$title, ${due.text}, Trừ ${formatVndBare(shareMinor)}',
        excludeSemantics: true,
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.card),
            side: BorderSide(color: colors.borderDefault),
          ),
          child: InkWell(
            key: Key('wgt_sg13_offset_${candidate.salesOrderId}'),
            borderRadius: BorderRadius.circular(VRadius.card),
            onTap: onToggle == null ? null : toggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: VSpacing.minTouchTarget,
                    child: Center(
                      child: VCheckbox(
                        value: on,
                        enabled: onToggle != null,
                        onChanged: (_) => toggle(),
                      ),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space2),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        VSpacing.space2,
                        VSpacing.space3,
                        VSpacing.space2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VTypography.labelDefault.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(child: ReceivableDueBadge(due, fontSize: 13)),
                              const SizedBox(width: VSpacing.space2),
                              Text(
                                'Trừ ${formatVndBare(shareMinor)}',
                                softWrap: false,
                                style: receivableMoneyStyle(
                                  context,
                                  fontWeight: shareMinor == 0 ? FontWeight.w600 : FontWeight.w700,
                                  color: shareMinor == 0 ? colors.textMuted : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

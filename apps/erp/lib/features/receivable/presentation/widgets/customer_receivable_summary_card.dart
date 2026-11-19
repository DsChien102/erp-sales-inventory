import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/receivable_models.dart';
import '../../data/receivable_repository.dart';
import '../../logic/receivable_format.dart';
import '../receivable_navigation.dart';
import 'receivable_parts.dart';

/// PT-07: khối Công nợ ở hồ sơ khách (TH-06 EP-04). Đang tải hoặc lỗi thì ẩn,
/// để không làm hỏng hồ sơ.
class CustomerReceivableSummaryCard extends StatefulWidget {
  const CustomerReceivableSummaryCard({
    super.key,
    required this.customerId,
    this.repository,
    this.today,
  });

  final String customerId;
  final ReceivableRepository? repository;
  final DateTime? today;

  @override
  State<CustomerReceivableSummaryCard> createState() => _CustomerReceivableSummaryCardState();
}

class _CustomerReceivableSummaryCardState extends State<CustomerReceivableSummaryCard> {
  CustomerReceivableSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CustomerReceivableSummaryCard old) {
    super.didUpdateWidget(old);
    if (old.customerId != widget.customerId) {
      _summary = null;
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.customerId;
    try {
      final repo = widget.repository ?? getIt<ReceivableRepository>();
      final s = await repo.getSummary(id);
      if (mounted && id == widget.customerId) setState(() => _summary = s);
    } on Object {
      // Lỗi: ẩn khối.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();
    final colors = context.vColors;
    final has = s.outstandingMinor > 0;
    final sub = has
        ? 'Còn nợ ${formatVnd(s.outstandingMinor)} · ${s.openOrderCount} đơn'
        : 'Không còn nợ';
    final due = has && s.maxOverdueDays > 0
        ? customerDueLabel(
            maxOverdueDays: s.maxOverdueDays,
            nextDueDate: null,
            today: widget.today ?? DateTime.now(),
          )
        : null;
    return Semantics(
      button: true,
      container: true,
      label: ['Công nợ', sub, if (due != null) due.text].join(', '),
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
          side: BorderSide(color: colors.borderDefault),
        ),
        child: InkWell(
          key: const Key('wgt_pt07_receivable_card'),
          borderRadius: BorderRadius.circular(VRadius.card),
          onTap: () async {
              await openCustomerReceivable(context, widget.customerId);
              if (mounted) _load();
            },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Công nợ',
                          style: VTypography.labelDefault.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          style: VTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                        if (due != null) ...[
                          const SizedBox(height: 2),
                          ReceivableDueBadge(due),
                        ],
                      ],
                    ),
                  ),
                  VIcon(icon: VIcons.chevronRight, size: 20, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

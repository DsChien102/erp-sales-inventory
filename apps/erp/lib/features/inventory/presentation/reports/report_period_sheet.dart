import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/reports_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Nút "Tháng 11/2026 ▾" + dòng `dd/MM – dd/MM/yyyy · Số liệu đến …` (`.bj15-toolbar`).
class ReportPeriodBar extends StatelessWidget {
  const ReportPeriodBar({
    super.key,
    required this.period,
    this.asOf,
    required this.onTap,
    this.trailing,
  });

  final ReportPeriod period;
  final DateTime? asOf;
  final VoidCallback onTap;

  /// Cạnh nút kỳ (web): ví dụ công tắc "Theo sản phẩm | Theo đơn".
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final range = reportPeriodRange(period);
    final text = asOf == null ? range : '$range · Số liệu đến ${asOfText(asOf!)}';
    final button = VButton(
      label: reportPeriodLabel(period),
      variant: VButtonVariant.secondary,
      leading: VIcons.calendar,
      trailing: VIcons.chevronDown,
      onPressed: onTap,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailing != null && inventoryIsWide(context))
          Row(
            children: [
              button,
              const SizedBox(width: VSpacing.space3),
              Flexible(child: trailing!),
            ],
          )
        else
          Align(alignment: Alignment.centerLeft, child: button),
        const SizedBox(height: VSpacing.space2),
        Text(
          text,
          style: VTypography.bodySmall.copyWith(
            color: context.vColors.textSecondary,
            height: 20 / 13,
          ),
        ),
      ],
    );
  }
}

/// Sheet "Chọn kỳ": Tháng này / Tháng trước trả kỳ ngay; Tùy chọn → hai ô ngày + Áp dụng.
class ReportPeriodSheet {
  const ReportPeriodSheet._();

  static Future<ReportPeriod?> show(
    BuildContext context, {
    required ReportPeriod current,
    required DateTime today,
  }) {
    return showVAdaptiveSheet<ReportPeriod>(
      context: context,
      title: 'Chọn kỳ',
      child: _ReportPeriodSheetBody(current: current, today: today),
    );
  }
}

class _ReportPeriodSheetBody extends StatefulWidget {
  const _ReportPeriodSheetBody({required this.current, required this.today});

  final ReportPeriod current;
  final DateTime today;

  @override
  State<_ReportPeriodSheetBody> createState() => _ReportPeriodSheetBodyState();
}

class _ReportPeriodSheetBodyState extends State<_ReportPeriodSheetBody> {
  static const _thisKey = 'THIS';
  static const _lastKey = 'LAST';
  static const _customKey = 'CUSTOM';

  late String _selected = switch (kindOf(widget.current, widget.today)) {
    ReportPeriodKind.thisMonth => _thisKey,
    ReportPeriodKind.lastMonth => _lastKey,
    ReportPeriodKind.custom => _customKey,
  };
  late DateTime? _from = widget.current.from;
  late DateTime? _to = widget.current.to;
  bool _submitted = false;

  void _select(String key) {
    if (key == _thisKey) {
      Navigator.of(context).pop(ReportPeriod.thisMonth(widget.today));
      return;
    }
    if (key == _lastKey) {
      Navigator.of(context).pop(ReportPeriod.lastMonth(widget.today));
      return;
    }
    setState(() => _selected = _customKey);
  }

  void _apply() {
    final error = customRangeError(_from, _to);
    if (error != null) {
      setState(() => _submitted = true);
      return;
    }
    Navigator.of(context).pop(ReportPeriod(from: _from!, to: _to!));
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _selected == _customKey;
    final error = _submitted ? customRangeError(_from, _to) : null;
    final fromError = error != null && _from == null ? error : null;
    final toError = error != null && _from != null ? error : (_to == null ? error : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        K7FilterChips(
          items: const [
            K7Filter(key: _thisKey, label: 'Tháng này'),
            K7Filter(key: _lastKey, label: 'Tháng trước'),
            K7Filter(key: _customKey, label: 'Tùy chọn'),
          ],
          selected: _selected,
          onSelected: _select,
        ),
        if (isCustom) ...[
          const SizedBox(height: VSpacing.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DateField(
                  label: 'Từ ngày',
                  value: _from,
                  error: fromError,
                  lastDate: widget.today,
                  onChanged: (d) => setState(() => _from = d),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: _DateField(
                  label: 'Đến ngày',
                  value: _to,
                  error: toError,
                  lastDate: widget.today,
                  onChanged: (d) => setState(() => _to = d),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: VSpacing.space4),
        Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Quay lại',
                variant: VButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (isCustom) ...[
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VButton(
                  label: 'Áp dụng',
                  fullWidth: true,
                  onPressed: _apply,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.error,
    required this.lastDate,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final String? error;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return VField(
      invalid: error != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ignore: deprecated_member_use
          VDatePicker(
            label: label,
            value: value,
            firstDate: DateTime(2020),
            lastDate: lastDate,
            tone: error != null ? VComponentTone.danger : VComponentTone.neutral,
            onChanged: onChanged,
          ),
          if (error != null) VFieldError(error!),
        ],
      ),
    );
  }
}

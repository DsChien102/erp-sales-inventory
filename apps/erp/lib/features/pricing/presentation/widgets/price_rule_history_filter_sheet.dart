import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// D-03 SG-06 — Filter bottom sheet cho lịch sử giá riêng.
class PriceRuleHistoryFilterState {
  const PriceRuleHistoryFilterState({
    this.activityType = 'Tất cả',
    this.actor = 'Tất cả',
    this.timeRange = 'Tất cả',
  });

  final String activityType;
  final String actor;
  final String timeRange;

  bool get isFiltered =>
      activityType != 'Tất cả' ||
      actor != 'Tất cả' ||
      timeRange != 'Tất cả';

  PriceRuleHistoryFilterState copyWith({
    String? activityType,
    String? actor,
    String? timeRange,
  }) {
    return PriceRuleHistoryFilterState(
      activityType: activityType ?? this.activityType,
      actor: actor ?? this.actor,
      timeRange: timeRange ?? this.timeRange,
    );
  }
}

class PriceRuleHistoryFilterSheet extends StatefulWidget {
  const PriceRuleHistoryFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
    required this.actorOptions,
  });

  final PriceRuleHistoryFilterState initialFilter;
  final ValueChanged<PriceRuleHistoryFilterState> onApply;
  final List<String> actorOptions;

  static Future<PriceRuleHistoryFilterState?> show({
    required BuildContext context,
    required PriceRuleHistoryFilterState initialFilter,
    required List<String> actorOptions,
  }) {
    return showVBottomSheet<PriceRuleHistoryFilterState>(
      context: context,
      semanticLabel: 'Bộ lọc lịch sử giá riêng',
      child: PriceRuleHistoryFilterSheetHost(
        initialFilter: initialFilter,
        actorOptions: actorOptions,
      ),
    );
  }

  @override
  State<PriceRuleHistoryFilterSheet> createState() =>
      _PriceRuleHistoryFilterSheetState();
}

class PriceRuleHistoryFilterSheetHost extends StatelessWidget {
  const PriceRuleHistoryFilterSheetHost({
    super.key,
    required this.initialFilter,
    required this.actorOptions,
  });

  final PriceRuleHistoryFilterState initialFilter;
  final List<String> actorOptions;

  @override
  Widget build(BuildContext context) {
    return PriceRuleHistoryFilterSheet(
      initialFilter: initialFilter,
      onApply: (filter) => Navigator.of(context).pop(filter),
      actorOptions: actorOptions,
    );
  }
}

class _PriceRuleHistoryFilterSheetState
    extends State<PriceRuleHistoryFilterSheet> {
  late PriceRuleHistoryFilterState _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  void _reset() {
    setState(() {
      _filter = const PriceRuleHistoryFilterState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space2,
            VSpacing.space4,
            VSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VText(
                'Bộ lọc lịch sử',
                variant: VTextVariant.headingH3,
                style: const TextStyle(fontWeight: FontWeight.w700),
                color: colors.textPrimary,
              ),
              const VGap.md(),
              _FilterGroup(
                title: 'Loại hoạt động',
                options: const [
                  'Tất cả',
                  'Tạo giá riêng',
                  'Sửa giá',
                  'Tắt',
                  'Bật lại',
                ],
                selected: _filter.activityType,
                onSelected: (val) =>
                    setState(() => _filter = _filter.copyWith(activityType: val)),
              ),
              const VGap.md(),
              _FilterGroup(
                title: 'Người thực hiện',
                options: widget.actorOptions,
                selected: _filter.actor,
                onSelected: (val) =>
                    setState(() => _filter = _filter.copyWith(actor: val)),
              ),
              const VGap.md(),
              _FilterGroup(
                title: 'Thời gian',
                options: const [
                  'Tất cả',
                  '7 ngày gần đây',
                  '30 ngày gần đây',
                  '90 ngày gần đây',
                ],
                selected: _filter.timeRange,
                onSelected: (val) =>
                    setState(() => _filter = _filter.copyWith(timeRange: val)),
              ),
              const VGap.lg(),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Đặt lại',
                      variant: VButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () {
                        _reset();
                        widget.onApply(const PriceRuleHistoryFilterState());
                      },
                    ),
                  ),
                  const VGap.horizontalMd(),
                  Expanded(
                    child: VButton(
                      label: 'Áp dụng',
                      variant: VButtonVariant.primary,
                      fullWidth: true,
                      onPressed: () => widget.onApply(_filter),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          title,
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.w600),
          color: colors.textPrimary,
        ),
        const VGap.xs(),
        Wrap(
          spacing: VSpacing.space2,
          runSpacing: VSpacing.space2,
          children: options.map((opt) {
            final isSelected = opt == selected;
            return VChip(
              label: opt,
              selected: isSelected,
              onTap: () => onSelected(opt),
            );
          }).toList(),
        ),
      ],
    );
  }
}

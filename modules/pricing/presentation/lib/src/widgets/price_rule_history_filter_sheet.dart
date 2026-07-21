import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// D-03 SG-06 — Filter bottom sheet cho lịch sử giá riêng.
class PriceRuleHistoryFilterState {
  const PriceRuleHistoryFilterState({
    this.activityType = 'Tất cả',
    this.source = 'Tất cả',
    this.actor = 'Tất cả',
    this.timeRange = 'Tất cả',
  });

  final String activityType;
  final String source;
  final String actor;
  final String timeRange;

  bool get isFiltered =>
      activityType != 'Tất cả' ||
      source != 'Tất cả' ||
      actor != 'Tất cả' ||
      timeRange != 'Tất cả';

  PriceRuleHistoryFilterState copyWith({
    String? activityType,
    String? source,
    String? actor,
    String? timeRange,
  }) {
    return PriceRuleHistoryFilterState(
      activityType: activityType ?? this.activityType,
      source: source ?? this.source,
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
    this.actorOptions,
  });

  final PriceRuleHistoryFilterState initialFilter;
  final ValueChanged<PriceRuleHistoryFilterState> onApply;
  final List<String>? actorOptions;

  static Future<PriceRuleHistoryFilterState?> show({
    required BuildContext context,
    required PriceRuleHistoryFilterState initialFilter,
    List<String>? actorOptions,
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
    this.actorOptions,
  });

  final PriceRuleHistoryFilterState initialFilter;
  final List<String>? actorOptions;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VText(
                    'Bộ lọc lịch sử',
                    variant: VTextVariant.headingH4,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    color: colors.textPrimary,
                  ),
                  VButton(
                    label: 'Xóa tất cả',
                    variant: VButtonVariant.ghost,
                    size: VButtonSize.small,
                    foregroundColor: colors.danger,
                    onPressed: _reset,
                  ),
                ],
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
                  'Nhập Excel',
                  'Từ đơn hàng',
                ],
                selected: _filter.activityType,
                onSelected: (val) =>
                    setState(() => _filter = _filter.copyWith(activityType: val)),
              ),
              const VGap.md(),
              _FilterGroup(
                title: 'Nguồn',
                options: const [
                  'Tất cả',
                  'Tạo thủ công',
                  'Nhập Excel',
                  'Từ đơn hàng',
                  'Migration',
                ],
                selected: _filter.source,
                onSelected: (val) =>
                    setState(() => _filter = _filter.copyWith(source: val)),
              ),
              const VGap.md(),
              _FilterGroup(
                title: 'Người thực hiện',
                options: widget.actorOptions ?? const [
                  'Tất cả',
                  'Nguyễn Văn A',
                  'Hệ thống',
                  'Quản trị viên',
                ],
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
                  'Tùy chọn',
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
                      onPressed: _reset,
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

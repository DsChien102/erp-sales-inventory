import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

import '../models/price_rule_list_filters.dart';

/// D-03 — Bộ lọc nâng cao giá riêng / nhớ giá (SG-01).
class PriceRuleFilterBottomSheet extends StatefulWidget {
  const PriceRuleFilterBottomSheet({super.key, required this.initial});

  final PriceRuleAdvancedFilter initial;

  static Future<PriceRuleAdvancedFilter?> show(
    BuildContext context, {
    required PriceRuleAdvancedFilter initial,
  }) {
    return showVBottomSheet<PriceRuleAdvancedFilter>(
      context: context,
      title: 'Bộ lọc giá riêng / nhớ giá',
      child: PriceRuleFilterBottomSheet(initial: initial),
    );
  }

  @override
  State<PriceRuleFilterBottomSheet> createState() =>
      _PriceRuleFilterBottomSheetState();
}

class _PriceRuleFilterBottomSheetState
    extends State<PriceRuleFilterBottomSheet> {
  late PriceRuleAdvancedFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  void _resetAndApply() {
    Navigator.of(context).pop(PriceRuleAdvancedFilter.empty);
  }

  void _apply() => Navigator.of(context).pop(_filter);

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VGap.md(),
              _SectionTitle(title: 'Trạng thái'),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  _chip(
                    label: 'Tất cả',
                    selected: _filter.status == null,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(status: null),
                    ),
                  ),
                  _chip(
                    label: 'Đang áp dụng',
                    selected:
                        _filter.status == CustomerPriceRuleDerivedStatus.applying,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        status: CustomerPriceRuleDerivedStatus.applying,
                      ),
                    ),
                  ),
                  _chip(
                    label: 'Đã tắt',
                    selected:
                        _filter.status == CustomerPriceRuleDerivedStatus.disabled,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        status: CustomerPriceRuleDerivedStatus.disabled,
                      ),
                    ),
                  ),
                  _chip(
                    label: 'Hết hiệu lực',
                    selected:
                        _filter.status == CustomerPriceRuleDerivedStatus.expired,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        status: CustomerPriceRuleDerivedStatus.expired,
                      ),
                    ),
                  ),
                  _chip(
                    label: 'Cần kiểm tra',
                    selected: _filter.status ==
                        CustomerPriceRuleDerivedStatus.needsReview,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        status: CustomerPriceRuleDerivedStatus.needsReview,
                      ),
                    ),
                  ),
                ],
              ),
              const VGap.md(),
              _SectionTitle(title: 'Cảnh báo'),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  _chip(
                    label: 'Tất cả',
                    selected: _filter.warning == null,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(warning: null),
                    ),
                  ),
                  _chip(
                    label: 'Dưới giá sàn',
                    selected:
                        _filter.warning == PriceRuleWarningFilter.belowFloor,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        warning: PriceRuleWarningFilter.belowFloor,
                      ),
                    ),
                  ),
                  _chip(
                    label: 'Trùng rule',
                    selected: _filter.warning ==
                        PriceRuleWarningFilter.duplicateRule,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        warning: PriceRuleWarningFilter.duplicateRule,
                      ),
                    ),
                  ),
                  _chip(
                    label: 'Dữ liệu lỗi',
                    selected:
                        _filter.warning == PriceRuleWarningFilter.dataError,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        warning: PriceRuleWarningFilter.dataError,
                      ),
                    ),
                  ),
                ],
              ),
              const VGap.md(),
              _SectionTitle(title: 'Nguồn tạo'),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  _chip(
                    label: 'Tất cả',
                    selected: _filter.source == null,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(source: null),
                    ),
                  ),
                  _chip(
                    label: 'Tạo thủ công',
                    selected:
                        _filter.source == CustomerPriceRuleSourceType.manual,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        source: CustomerPriceRuleSourceType.manual,
                      ),
                    ),
                  ),
                  _chip(
                    label: 'Nhập Excel',
                    selected: _filter.source ==
                        CustomerPriceRuleSourceType.excelImport,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        source: CustomerPriceRuleSourceType.excelImport,
                      ),
                    ),
                  ),
                  _chip(
                    label: 'Từ đơn hàng',
                    selected: _filter.source ==
                        CustomerPriceRuleSourceType.salesOrder,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        source: CustomerPriceRuleSourceType.salesOrder,
                      ),
                    ),
                  ),
                  _chip(
                    label: 'Migration',
                    selected: _filter.source ==
                        CustomerPriceRuleSourceType.migration,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        source: CustomerPriceRuleSourceType.migration,
                      ),
                    ),
                  ),
                ],
              ),
              const VGap.md(),
              _SectionTitle(title: 'Thời gian cập nhật'),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  _chip(
                    label: '7 ngày gần đây',
                    selected: _filter.updatedWithin ==
                        PriceRuleUpdatedWithin.last7Days,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        updatedWithin: _filter.updatedWithin ==
                                PriceRuleUpdatedWithin.last7Days
                            ? null
                            : PriceRuleUpdatedWithin.last7Days,
                      ),
                    ),
                  ),
                  _chip(
                    label: '30 ngày gần đây',
                    selected: _filter.updatedWithin ==
                        PriceRuleUpdatedWithin.last30Days,
                    onTap: () => setState(
                      () => _filter = _filter.copyWith(
                        updatedWithin: _filter.updatedWithin ==
                                PriceRuleUpdatedWithin.last30Days
                            ? null
                            : PriceRuleUpdatedWithin.last30Days,
                      ),
                    ),
                  ),
                  VChip(
                    label: 'Tùy chọn',
                    icon: VIcons.calendar,
                    selected: false,
                    onTap: () {
                      // Custom range — placeholder theo design.
                    },
                  ),
                ],
              ),
              VGap.sm(),
              VText(
                'Đang chọn ${_filter.activeCount} bộ lọc',
                variant: VTextVariant.caption,
                color: colors.textMuted,
              ),
              const VGap.md(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Row(
            children: [
              Expanded(
                child: VButton(
                  variant: VButtonVariant.secondary,
                  label: 'Đặt lại',
                  onPressed: _resetAndApply,
                ),
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: VButton(
                  variant: VButtonVariant.primary,
                  label: 'Áp dụng',
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return VChip(
      label: label,
      selected: selected,
      tone: VComponentTone.primary,
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return VText(
      title,
      variant: VTextVariant.bodySmall,
      color: context.vColors.textSecondary,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}

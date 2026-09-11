import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/price_rule_list_filters.dart';

/// D-05 — Sắp xếp danh sách giá riêng (SG-01).
class PriceRuleSortBottomSheet extends StatefulWidget {
  const PriceRuleSortBottomSheet({super.key, required this.initialSort});

  final PriceRuleSortOption initialSort;

  static Future<PriceRuleSortOption?> show(
    BuildContext context, {
    required PriceRuleSortOption initialSort,
  }) {
    return showVBottomSheet<PriceRuleSortOption>(
      context: context,
      child: PriceRuleSortBottomSheet(initialSort: initialSort),
    );
  }

  @override
  State<PriceRuleSortBottomSheet> createState() =>
      _PriceRuleSortBottomSheetState();
}

class _PriceRuleSortBottomSheetState extends State<PriceRuleSortBottomSheet> {
  late PriceRuleSortOption _selected;

  static const _choices = <VChoiceOption<PriceRuleSortOption>>[
    VChoiceOption(
      value: PriceRuleSortOption.updatedAtDesc,
      label: 'Cập nhật gần nhất',
    ),
    VChoiceOption(
      value: PriceRuleSortOption.updatedAtAsc,
      label: 'Cập nhật cũ nhất',
    ),
    VChoiceOption(
      value: PriceRuleSortOption.customerNameAsc,
      label: 'Tên khách hàng A-Z',
    ),
    VChoiceOption(
      value: PriceRuleSortOption.customerNameDesc,
      label: 'Tên khách hàng Z-A',
    ),
    VChoiceOption(
      value: PriceRuleSortOption.priceDesc,
      label: 'Giá riêng cao → thấp',
    ),
    VChoiceOption(
      value: PriceRuleSortOption.priceAsc,
      label: 'Giá riêng thấp → cao',
    ),
    VChoiceOption(
      value: PriceRuleSortOption.warningsFirst,
      label: 'Cảnh báo cần xử lý trước',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSort;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
          child: VChoiceList<PriceRuleSortOption>(
            title: 'Sắp xếp danh sách',
            choices: _choices,
            selected: [_selected],
            onChanged: (selected) {
              if (selected.isEmpty) return;
              setState(() => _selected = selected.first);
            },
          ),
        ),
        const VGap.sm(),
        Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: VButton(
            variant: VButtonVariant.primary,
            label: 'Áp dụng',
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ),
      ],
    );
  }
}

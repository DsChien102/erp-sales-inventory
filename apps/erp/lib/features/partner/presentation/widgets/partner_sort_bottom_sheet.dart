import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_list_state.dart';

class PartnerSortBottomSheet extends StatefulWidget {
  const PartnerSortBottomSheet({
    super.key,
    required this.initialSort,
  });

  final PartnerSortOption initialSort;

  static Future<PartnerSortOption?> show(
    BuildContext context, {
    required PartnerSortOption initialSort,
  }) {
    return showVBottomSheet<PartnerSortOption>(
      context: context,
      child: PartnerSortBottomSheet(initialSort: initialSort),
    );
  }

  @override
  State<PartnerSortBottomSheet> createState() => _PartnerSortBottomSheetState();
}

class _PartnerSortBottomSheetState extends State<PartnerSortBottomSheet> {
  late PartnerSortOption _selectedSort;

  static const _choices = <VChoiceOption<PartnerSortOption>>[
    VChoiceOption(
      value: PartnerSortOption.updatedAtDesc,
      label: 'Cập nhật gần nhất',
    ),
    VChoiceOption(
      value: PartnerSortOption.updatedAtAsc,
      label: 'Cập nhật cũ nhất',
    ),
    VChoiceOption(
      value: PartnerSortOption.nameAsc,
      label: 'Tên A-Z',
    ),
    VChoiceOption(
      value: PartnerSortOption.nameDesc,
      label: 'Tên Z-A',
    ),
    VChoiceOption(
      value: PartnerSortOption.roleAsc,
      label: 'Vai trò giao dịch A-Z',
    ),
    VChoiceOption(
      value: PartnerSortOption.roleDesc,
      label: 'Vai trò giao dịch Z-A',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialSort;
  }

  void _apply() {
    Navigator.of(context).pop(_selectedSort);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
          child: VChoiceList<PartnerSortOption>(
            title: 'Sắp xếp danh sách',
            choices: _choices,
            selected: [_selectedSort],
            onChanged: (selected) {
              if (selected.isEmpty) return;
              setState(() => _selectedSort = selected.first);
            },
          ),
        ),
        const VGap.sm(),
        Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: VButton(
            variant: VButtonVariant.primary,
            label: 'Áp dụng',
            onPressed: _apply,
          ),
        ),
      ],
    );
  }
}

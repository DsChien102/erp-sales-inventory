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
    return showModalBottomSheet<PartnerSortOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PartnerSortBottomSheet(
        initialSort: initialSort,
      ),
    );
  }

  @override
  State<PartnerSortBottomSheet> createState() => _PartnerSortBottomSheetState();
}

class _PartnerSortBottomSheetState extends State<PartnerSortBottomSheet> {
  late PartnerSortOption _selectedSort;

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
    return VBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
            child: Text(
              'Sắp xếp danh sách',
              style: VTypography.headingH4.copyWith(
                color: context.vColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          _buildRadioItem('Cập nhật gần nhất', PartnerSortOption.updatedAtDesc),
          _buildRadioItem('Cập nhật cũ nhất', PartnerSortOption.updatedAtAsc),
          _buildRadioItem('Tên A-Z', PartnerSortOption.nameAsc),
          _buildRadioItem('Tên Z-A', PartnerSortOption.nameDesc),
          _buildRadioItem('Vai trò giao dịch A-Z', PartnerSortOption.roleAsc),
          _buildRadioItem('Vai trò giao dịch Z-A', PartnerSortOption.roleDesc),
          const SizedBox(height: VSpacing.space2),
          Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: VButton(
              variant: VButtonVariant.primary,
              label: 'Áp dụng',
              onPressed: _apply,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioItem(String label, PartnerSortOption value) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSort = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: 8,
        ),
        child: Row(
          children: [
            // Using standard Radio if VRadio complains about groupValue, but we will try VRadio first with groupValue, wait no, let's just use Radio.
            // Oh wait, VRadio doesn't take groupValue in the latest version it seems? Or it does but it's an info.
            Radio<PartnerSortOption>(
              value: value,
              groupValue: _selectedSort,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSort = val;
                  });
                }
              },
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Text(
                label,
                style: VTypography.bodyDefault.copyWith(
                  color: context.vColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


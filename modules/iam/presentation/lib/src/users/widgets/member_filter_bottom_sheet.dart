import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Filter criteria model for organization members list.
class MemberFilterCriteria {
  final String status; // 'Tất cả', 'Hoạt động', 'Tạm ngừng'
  final String role; // 'Tất cả', 'Quản trị', 'Bán hàng', 'Kế toán'
  final String sort; // 'Tất cả', 'Tên A–Z', 'Tên Z–A'

  const MemberFilterCriteria({
    this.status = 'Tất cả',
    this.role = 'Tất cả',
    this.sort = 'Tất cả',
  });

  bool get isFilterActive =>
      status != 'Tất cả' || role != 'Tất cả' || sort != 'Tất cả';

  MemberFilterCriteria copyWith({
    String? status,
    String? role,
    String? sort,
  }) {
    return MemberFilterCriteria(
      status: status ?? this.status,
      role: role ?? this.role,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberFilterCriteria &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          role == other.role &&
          sort == other.sort;

  @override
  int get hashCode => status.hashCode ^ role.hashCode ^ sort.hashCode;
}

/// Bottom Sheet TA-BS-01 — Lọc thành viên.
class MemberFilterBottomSheet extends StatefulWidget {
  final MemberFilterCriteria initialCriteria;
  final ValueChanged<MemberFilterCriteria>? onApply;

  const MemberFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    this.onApply,
  });

  @override
  State<MemberFilterBottomSheet> createState() =>
      _MemberFilterBottomSheetState();
}

class _MemberFilterBottomSheetState extends State<MemberFilterBottomSheet> {
  late MemberFilterCriteria _currentCriteria;

  static const List<String> _statusOptions = [
    'Tất cả',
    'Hoạt động',
    'Tạm ngừng',
  ];

  static const List<String> _roleOptions = [
    'Tất cả',
    'Quản trị',
    'Bán hàng',
    'Kế toán',
  ];

  static const List<String> _sortOptions = [
    'Tất cả',
    'Tên A–Z',
    'Tên Z–A',
  ];

  @override
  void initState() {
    super.initState();
    _currentCriteria = widget.initialCriteria;
  }

  void _resetFilter() {
    const reset = MemberFilterCriteria();
    setState(() {
      _currentCriteria = reset;
    });
    Navigator.of(context).pop(reset);
    widget.onApply?.call(reset);
  }

  void _applyFilter() {
    Navigator.of(context).pop(_currentCriteria);
    widget.onApply?.call(_currentCriteria);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.only(
        left: VSpacing.space4,
        right: VSpacing.space4,
        top: VSpacing.space2,
        bottom: VSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Bộ lọc thành viên',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.md(),

          // Section 1: Trạng thái
          const _FilterSectionTitle(title: 'Trạng thái'),
          const VGap.xs(),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _statusOptions.map((opt) {
              final isSelected = _currentCriteria.status == opt;
              return _SelectableFilterChip(
                label: opt,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentCriteria = _currentCriteria.copyWith(status: opt);
                  });
                },
              );
            }).toList(),
          ),
          const VGap.md(),

          // Section 2: Vai trò
          const _FilterSectionTitle(title: 'Vai trò'),
          const VGap.xs(),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _roleOptions.map((opt) {
              final isSelected = _currentCriteria.role == opt;
              return _SelectableFilterChip(
                label: opt,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentCriteria = _currentCriteria.copyWith(role: opt);
                  });
                },
              );
            }).toList(),
          ),
          const VGap.md(),

          // Section 3: Sắp xếp
          const _FilterSectionTitle(title: 'Sắp xếp'),
          const VGap.xs(),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _sortOptions.map((opt) {
              final isSelected = _currentCriteria.sort == opt;
              return _SelectableFilterChip(
                label: opt,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentCriteria = _currentCriteria.copyWith(sort: opt);
                  });
                },
              );
            }).toList(),
          ),
          const VGap.lg(),

          // Buttons row
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Đặt lại',
                  variant: VButtonVariant.outline,
                  fullWidth: true,
                  onPressed: _resetFilter,
                ),
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: VButton(
                  label: 'Áp dụng',
                  variant: VButtonVariant.primary,
                  tone: VComponentTone.success,
                  fullWidth: true,
                  onPressed: _applyFilter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  final String title;

  const _FilterSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VText(
      title,
      variant: VTextVariant.bodyDefault,
      style: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SelectableFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? VColors.successBg : colors.surface,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(
            color: isSelected ? VColors.success : colors.borderDefault,
            width: 1.0,
          ),
        ),
        child: VText(
          label,
          variant: VTextVariant.bodySmall,
          style: TextStyle(
            color: isSelected ? VColors.success : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

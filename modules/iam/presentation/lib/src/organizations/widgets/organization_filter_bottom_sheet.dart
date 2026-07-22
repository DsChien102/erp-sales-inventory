import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Class chứa các tiêu chí lọc nâng cao cho danh sách tổ chức.
class OrganizationFilterCriteria {
  final OrganizationStatus status;
  final String lifecycle;
  final String completion;

  const OrganizationFilterCriteria({
    this.status = OrganizationStatus.all,
    this.lifecycle = 'Tất cả',
    this.completion = 'Tất cả',
  });

  /// Kiểm tra có đang áp dụng bất kỳ bộ lọc nào khác mặc định không.
  bool get isFilterActive =>
      status != OrganizationStatus.all ||
      lifecycle != 'Tất cả' ||
      completion != 'Tất cả';

  OrganizationFilterCriteria copyWith({
    OrganizationStatus? status,
    String? lifecycle,
    String? completion,
  }) {
    return OrganizationFilterCriteria(
      status: status ?? this.status,
      lifecycle: lifecycle ?? this.lifecycle,
      completion: completion ?? this.completion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationFilterCriteria &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          lifecycle == other.lifecycle &&
          completion == other.completion;

  @override
  int get hashCode => status.hashCode ^ lifecycle.hashCode ^ completion.hashCode;
}

/// Bottom Sheet Bộ lọc tổ chức nền tảng.
class OrganizationFilterBottomSheet extends StatefulWidget {
  final OrganizationFilterCriteria initialCriteria;
  final ValueChanged<OrganizationFilterCriteria>? onApply;

  const OrganizationFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    this.onApply,
  });

  @override
  State<OrganizationFilterBottomSheet> createState() =>
      _OrganizationFilterBottomSheetState();
}

class _OrganizationFilterBottomSheetState
    extends State<OrganizationFilterBottomSheet> {
  late OrganizationFilterCriteria _currentCriteria;

  static const List<OrganizationStatus> _statusOptions = [
    OrganizationStatus.all,
    OrganizationStatus.settingUp,
    OrganizationStatus.active,
  ];

  static const List<String> _lifecycleOptions = [
    'Tất cả',
    'Tạm ngừng',
    'Đã đóng',
    'Có cảnh báo',
  ];

  static const List<String> _completionOptions = [
    'Tất cả',
    'Đủ điều kiện',
    'Còn thiếu',
  ];

  @override
  void initState() {
    super.initState();
    _currentCriteria = widget.initialCriteria;
  }

  void _resetFilter() {
    const reset = OrganizationFilterCriteria();
    setState(() {
      _currentCriteria = reset;
    });
    Navigator.of(context).pop();
    widget.onApply?.call(reset);
  }

  void _applyFilter() {
    Navigator.of(context).pop();
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
            'Bộ lọc tổ chức nền tảng',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.md(),

          // Nhóm 1: Trạng thái
          _FilterSectionTitle(title: 'Trạng thái'),
          const SizedBox(height: 8),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _statusOptions.map((status) {
              final isSelected = _currentCriteria.status == status;
              return VChip(
                label: status.filterLabel,
                emphasis: isSelected
                    ? VComponentEmphasis.strong
                    : VComponentEmphasis.medium,
                onTap: () {
                  setState(() {
                    _currentCriteria =
                        _currentCriteria.copyWith(status: status);
                  });
                },
              );
            }).toList(),
          ),
          const VGap.md(),

          // Nhóm 2: Vòng đời
          _FilterSectionTitle(title: 'Vòng đời'),
          const SizedBox(height: 8),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _lifecycleOptions.map((option) {
              final isSelected = _currentCriteria.lifecycle == option;
              return VChip(
                label: option,
                emphasis: isSelected
                    ? VComponentEmphasis.strong
                    : VComponentEmphasis.medium,
                onTap: () {
                  setState(() {
                    _currentCriteria =
                        _currentCriteria.copyWith(lifecycle: option);
                  });
                },
              );
            }).toList(),
          ),
          const VGap.md(),

          // Nhóm 3: Mức hoàn thiện
          _FilterSectionTitle(title: 'Mức hoàn thiện'),
          const SizedBox(height: 8),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _completionOptions.map((option) {
              final isSelected = _currentCriteria.completion == option;
              return VChip(
                label: option,
                emphasis: isSelected
                    ? VComponentEmphasis.strong
                    : VComponentEmphasis.medium,
                onTap: () {
                  setState(() {
                    _currentCriteria =
                        _currentCriteria.copyWith(completion: option);
                  });
                },
              );
            }).toList(),
          ),
          const VGap.lg(),

          // Thanh Nút Đặt lại & Áp dụng
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
              const SizedBox(width: 12),
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

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/audit_log_filter_criteria.dart';
import '../models/audit_log_ui_model.dart';

/// Bottom Sheet Bộ lọc nhật ký nền tảng (PA-D-02 BottomSheet).
class AuditLogFilterBottomSheet extends StatefulWidget {
  final AuditLogFilterCriteria initialCriteria;
  final ValueChanged<AuditLogFilterCriteria>? onApply;

  const AuditLogFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    this.onApply,
  });

  @override
  State<AuditLogFilterBottomSheet> createState() => _AuditLogFilterBottomSheetState();
}

class _AuditLogFilterBottomSheetState extends State<AuditLogFilterBottomSheet> {
  late AuditLogFilterCriteria _currentCriteria;

  static const List<String> _timeRangeOptions = [
    '24 giờ',
    '7 ngày',
    '30 ngày',
  ];

  static const List<({String label, AuditLogStatus? status})> _statusOptions = [
    (label: 'Tất cả', status: null),
    (label: 'Thành công', status: AuditLogStatus.success),
    (label: 'Bị chặn', status: AuditLogStatus.blocked),
    (label: 'Lỗi', status: AuditLogStatus.error),
  ];

  static const List<String> _actorTypeOptions = [
    'Tất cả',
    'Người dùng',
    'Hệ thống',
  ];

  @override
  void initState() {
    super.initState();
    _currentCriteria = widget.initialCriteria;
  }

  void _resetFilter() {
    const reset = AuditLogFilterCriteria();
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
            'Bộ lọc nhật ký nền tảng',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.md(),

          // Nhóm 1: Thời gian
          const _FilterSectionTitle(title: 'Thời gian'),
          const SizedBox(height: 8),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _timeRangeOptions.map((option) {
              final isSelected = _currentCriteria.timeRange == option;
              return VChip(
                label: option,
                tone: isSelected ? VComponentTone.primary : VComponentTone.neutral,
                onTap: () {
                  setState(() {
                    _currentCriteria = _currentCriteria.copyWith(timeRange: option);
                  });
                },
              );
            }).toList(),
          ),
          const VGap.md(),

          // Nhóm 2: Kết quả
          const _FilterSectionTitle(title: 'Kết quả'),
          const SizedBox(height: 8),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _statusOptions.map((option) {
              final isSelected = _currentCriteria.status == option.status;
              return VChip(
                label: option.label,
                tone: isSelected ? VComponentTone.primary : VComponentTone.neutral,
                onTap: () {
                  setState(() {
                    _currentCriteria = _currentCriteria.copyWith(
                      status: option.status,
                      clearStatus: option.status == null,
                    );
                  });
                },
              );
            }).toList(),
          ),
          const VGap.md(),

          // Nhóm 3: Loại chủ thể
          const _FilterSectionTitle(title: 'Loại chủ thể'),
          const SizedBox(height: 8),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _actorTypeOptions.map((option) {
              final isSelected = _currentCriteria.actorType == option;
              return VChip(
                label: option,
                tone: isSelected ? VComponentTone.primary : VComponentTone.neutral,
                onTap: () {
                  setState(() {
                    _currentCriteria = _currentCriteria.copyWith(actorType: option);
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
                  variant: VButtonVariant.secondary,
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

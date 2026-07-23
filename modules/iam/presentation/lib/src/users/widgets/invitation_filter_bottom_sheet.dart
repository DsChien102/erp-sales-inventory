import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Filter criteria model for invitations list.
class InvitationFilterCriteria {
  final String status; // 'Tất cả', 'Đang chờ', 'Sắp hết hạn'
  final String sendResult; // 'Tất cả', 'Đã gửi', 'Gửi lỗi', 'Thu hồi'
  final String timeRange; // 'Tất cả', '7 ngày', '30 ngày', 'Tùy chọn'

  const InvitationFilterCriteria({
    this.status = 'Tất cả',
    this.sendResult = 'Tất cả',
    this.timeRange = 'Tất cả',
  });

  bool get isFilterActive =>
      status != 'Tất cả' || sendResult != 'Tất cả' || timeRange != 'Tất cả';

  InvitationFilterCriteria copyWith({
    String? status,
    String? sendResult,
    String? timeRange,
  }) {
    return InvitationFilterCriteria(
      status: status ?? this.status,
      sendResult: sendResult ?? this.sendResult,
      timeRange: timeRange ?? this.timeRange,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitationFilterCriteria &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          sendResult == other.sendResult &&
          timeRange == other.timeRange;

  @override
  int get hashCode => status.hashCode ^ sendResult.hashCode ^ timeRange.hashCode;
}

/// Bottom Sheet TA-BS-02 — Lọc lời mời.
class InvitationFilterBottomSheet extends StatefulWidget {
  final InvitationFilterCriteria initialCriteria;
  final ValueChanged<InvitationFilterCriteria>? onApply;

  const InvitationFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    this.onApply,
  });

  @override
  State<InvitationFilterBottomSheet> createState() =>
      _InvitationFilterBottomSheetState();
}

class _InvitationFilterBottomSheetState
    extends State<InvitationFilterBottomSheet> {
  late InvitationFilterCriteria _currentCriteria;

  static const List<String> _statusOptions = [
    'Tất cả',
    'Đang chờ',
    'Sắp hết hạn',
  ];

  static const List<String> _sendResultOptions = [
    'Tất cả',
    'Đã gửi',
    'Gửi lỗi',
    'Thu hồi',
  ];

  static const List<String> _timeRangeOptions = [
    'Tất cả',
    '7 ngày',
    '30 ngày',
    'Tùy chọn',
  ];

  @override
  void initState() {
    super.initState();
    _currentCriteria = widget.initialCriteria;
  }

  void _resetFilter() {
    const reset = InvitationFilterCriteria();
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
            'Bộ lọc lời mời',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.md(),

          // Section 1: Trạng thái
          const _FilterSectionTitle(title: 'Trạng thái'),
          const SizedBox(height: 8),
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

          // Section 2: Kết quả gửi
          const _FilterSectionTitle(title: 'Kết quả gửi'),
          const SizedBox(height: 8),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _sendResultOptions.map((opt) {
              final isSelected = _currentCriteria.sendResult == opt;
              return _SelectableFilterChip(
                label: opt,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentCriteria =
                        _currentCriteria.copyWith(sendResult: opt);
                  });
                },
              );
            }).toList(),
          ),
          const VGap.md(),

          // Section 3: Thời gian
          const _FilterSectionTitle(title: 'Thời gian'),
          const SizedBox(height: 8),
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: _timeRangeOptions.map((opt) {
              final isSelected = _currentCriteria.timeRange == opt;
              return _SelectableFilterChip(
                label: opt,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentCriteria =
                        _currentCriteria.copyWith(timeRange: opt);
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
        child: Text(
          label,
          style: VTypography.bodySmall.copyWith(
            color: isSelected ? VColors.success : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

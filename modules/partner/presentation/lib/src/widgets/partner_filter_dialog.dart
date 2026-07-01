import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/partner_filter_counts.dart';

class PartnerFilterResult {
  const PartnerFilterResult({
    this.role,
    this.profileType,
    this.status,
  });

  final String? role;
  final String? profileType;
  final String? status;
}

class PartnerFilterDialog extends StatefulWidget {
  final String? initialRole;
  final String? initialProfileType;
  final String? initialStatus;
  final PartnerFilterCounts counts;

  const PartnerFilterDialog({
    super.key,
    this.initialRole,
    this.initialProfileType,
    this.initialStatus,
    this.counts = const PartnerFilterCounts(),
  });

  @override
  State<PartnerFilterDialog> createState() => _PartnerFilterDialogState();
}

class _PartnerFilterDialogState extends State<PartnerFilterDialog> {
  String? _selectedRole;
  String? _selectedProfileType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _selectedProfileType = widget.initialProfileType;
    _selectedStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final counts = widget.counts;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(VSpacing.space4),
        decoration: BoxDecoration(
          color: dynamicColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: dynamicColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Text(
              'VAI TRÒ',
              style: VTypography.bodySmall.copyWith(
                color: dynamicColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: VSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: _buildChip(
                    'Tất cả (${counts.total})',
                    null,
                    _selectedRole,
                    (val) => setState(() => _selectedRole = val),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Expanded(
                  child: _buildChip(
                    'Khách hàng (${counts.customer})',
                    'Khách hàng',
                    _selectedRole,
                    (val) => setState(() => _selectedRole = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: _buildChip(
                    'Nhà cung cấp (${counts.supplier})',
                    'Nhà cung cấp',
                    _selectedRole,
                    (val) => setState(() => _selectedRole = val),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Expanded(
                  child: _buildChip(
                    'KH & NCC (${counts.both})',
                    'Khách hàng & NCC',
                    _selectedRole,
                    (val) => setState(() => _selectedRole = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space4),
            Text(
              'LOẠI HỒ SƠ',
              style: VTypography.bodySmall.copyWith(
                color: dynamicColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: VSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: _buildChip(
                    'Tất cả (${counts.total})',
                    null,
                    _selectedProfileType,
                    (val) => setState(() => _selectedProfileType = val),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Expanded(
                  child: _buildChip(
                    'Cá nhân (${counts.individual})',
                    'Cá nhân',
                    _selectedProfileType,
                    (val) => setState(() => _selectedProfileType = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: _buildChip(
                    'Công ty (${counts.company})',
                    'Công ty',
                    _selectedProfileType,
                    (val) => setState(() => _selectedProfileType = val),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Expanded(
                  child: _buildChip(
                    'Hộ kinh doanh (${counts.household})',
                    'Hộ kinh doanh',
                    _selectedProfileType,
                    (val) => setState(() => _selectedProfileType = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space4),
            Text(
              'TRẠNG THÁI',
              style: VTypography.bodySmall.copyWith(
                color: dynamicColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: VSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: _buildChip(
                    'Đang hoạt động (${counts.active})',
                    'Đang hoạt động',
                    _selectedStatus,
                    (val) => setState(() => _selectedStatus = val),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Expanded(
                  child: _buildChip(
                    'Ngừng hoạt động (${counts.inactive})',
                    'Ngừng hoạt động',
                    _selectedStatus,
                    (val) => setState(() => _selectedStatus = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        const PartnerFilterResult(
                          status: 'Đang hoạt động',
                        ),
                      );
                    },
                    label: 'Đặt lại',
                    variant: VButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        PartnerFilterResult(
                          role: _selectedRole,
                          profileType: _selectedProfileType,
                          status: _selectedStatus,
                        ),
                      );
                    },
                    label: 'Áp dụng',
                    variant: VButtonVariant.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space4),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    String label,
    String? value,
    String? selectedValue,
    ValueChanged<String?> onSelected,
  ) {
    final isSelected = value == selectedValue;
    final dynamicColors = context.vColors;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? dynamicColors.primary.withValues(alpha: 0.1)
              : dynamicColors.surface,
          borderRadius: BorderRadius.circular(VRadius.input),
          border: Border.all(
            color: isSelected
                ? dynamicColors.primary
                : dynamicColors.borderDefault,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: VTypography.bodyDefault.copyWith(
            color: isSelected
                ? dynamicColors.primary
                : dynamicColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

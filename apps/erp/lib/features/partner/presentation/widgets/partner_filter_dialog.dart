import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerFilterDialog extends StatefulWidget {
  final String? initialRole;
  final String? initialStatus;

  const PartnerFilterDialog({
    super.key,
    this.initialRole,
    this.initialStatus,
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
    _selectedProfileType = null;
    _selectedStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

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
                Expanded(child: _buildChip('Tất cả (5)', null, _selectedRole, (val) => setState(() => _selectedRole = val))),
                const SizedBox(width: VSpacing.space2),
                Expanded(child: _buildChip('Khách hàng (2)', 'Khách hàng', _selectedRole, (val) => setState(() => _selectedRole = val))),
              ],
            ),
            const SizedBox(height: VSpacing.space2),
            Row(
              children: [
                Expanded(child: _buildChip('Nhà cung cấp (2)', 'Nhà cung cấp', _selectedRole, (val) => setState(() => _selectedRole = val))),
                const SizedBox(width: VSpacing.space2),
                Expanded(child: _buildChip('KH & NCC (1)', 'Khách hàng & NCC', _selectedRole, (val) => setState(() => _selectedRole = val))),
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
                Expanded(child: _buildChip('Tất cả (5)', null, _selectedProfileType, (val) => setState(() => _selectedProfileType = val))),
                const SizedBox(width: VSpacing.space2),
                Expanded(child: _buildChip('Cá nhân (2)', 'Cá nhân', _selectedProfileType, (val) => setState(() => _selectedProfileType = val))),
              ],
            ),
            const SizedBox(height: VSpacing.space2),
            Row(
              children: [
                Expanded(child: _buildChip('Công ty (3)', 'Công ty', _selectedProfileType, (val) => setState(() => _selectedProfileType = val))),
                const SizedBox(width: VSpacing.space2),
                Expanded(child: _buildChip('Hộ kinh doanh (0)', 'Hộ kinh doanh', _selectedProfileType, (val) => setState(() => _selectedProfileType = val))),
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
                Expanded(child: _buildChip('Đang hoạt động (4)', 'Đang hoạt động', _selectedStatus, (val) => setState(() => _selectedStatus = val))),
                const SizedBox(width: VSpacing.space2),
                Expanded(child: _buildChip('Ngừng hoạt động (1)', 'Ngừng hoạt động', _selectedStatus, (val) => setState(() => _selectedStatus = val))),
              ],
            ),

            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'role': null,
                        'status': 'Đang hoạt động',
                      });
                    },
                    label: 'Đặt lại',
                    variant: VButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'role': _selectedRole,
                        'status': _selectedStatus,
                      });
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

  Widget _buildChip(String label, String? value, String? selectedValue, ValueChanged<String?> onSelected) {
    final isSelected = value == selectedValue;
    final dynamicColors = context.vColors;

    return GestureDetector(
      onTap: () {
        onSelected(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? dynamicColors.primary.withValues(alpha: 0.1) : dynamicColors.surface,
          borderRadius: BorderRadius.circular(VRadius.input),
          border: Border.all(
            color: isSelected ? dynamicColors.primary : dynamicColors.borderDefault,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: VTypography.bodyDefault.copyWith(
            color: isSelected ? dynamicColors.primary : dynamicColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';
import '../bloc/partner_list_state.dart';

class PartnerFilterBottomSheet extends StatefulWidget {
  const PartnerFilterBottomSheet({
    super.key,
    required this.initialRole,
    required this.initialPartnerType,
    required this.initialStatus,
  });

  final PartnerRoleFilter? initialRole;
  final PartnerType? initialPartnerType;
  final PartnerStatus? initialStatus;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    PartnerRoleFilter? role,
    PartnerType? partnerType,
    PartnerStatus? status,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PartnerFilterBottomSheet(
        initialRole: role,
        initialPartnerType: partnerType,
        initialStatus: status,
      ),
    );
  }

  @override
  State<PartnerFilterBottomSheet> createState() => _PartnerFilterBottomSheetState();
}

class _PartnerFilterBottomSheetState extends State<PartnerFilterBottomSheet> {
  PartnerRoleFilter? _selectedRole;
  PartnerType? _selectedPartnerType;
  PartnerStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _selectedPartnerType = widget.initialPartnerType;
    _selectedStatus = widget.initialStatus;
  }

  void _reset() {
    Navigator.of(context).pop(<String, dynamic>{
      'role': null,
      'partnerType': null,
      'status': null,
    });
  }

  void _apply() {
    Navigator.of(context).pop({
      'role': _selectedRole,
      'partnerType': _selectedPartnerType,
      'status': _selectedStatus,
    });
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: VSpacing.space1),
                Text(
                  'Bộ lọc KH & NCC',
                  style: VTypography.headingH4.copyWith(
                    color: context.vColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VSpacing.space4),
                _buildSectionTitle('Vai trò giao dịch'),
                const SizedBox(height: VSpacing.space3),
                Wrap(
                  spacing: VSpacing.space2,
                  runSpacing: VSpacing.space2,
                  children: [
                    _buildFilterChip(
                      label: 'Khách hàng',
                      isSelected: _selectedRole == PartnerRoleFilter.customer,
                      onTap: () {
                        setState(() {
                          _selectedRole = _selectedRole == PartnerRoleFilter.customer ? null : PartnerRoleFilter.customer;
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: 'Nhà cung cấp',
                      isSelected: _selectedRole == PartnerRoleFilter.supplier,
                      onTap: () {
                        setState(() {
                          _selectedRole = _selectedRole == PartnerRoleFilter.supplier ? null : PartnerRoleFilter.supplier;
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: 'KH & NCC',
                      isSelected: _selectedRole == PartnerRoleFilter.both,
                      onTap: () {
                        setState(() {
                          _selectedRole = _selectedRole == PartnerRoleFilter.both ? null : PartnerRoleFilter.both;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.space4),
                _buildSectionTitle('Loại hồ sơ'),
                const SizedBox(height: VSpacing.space3),
                Wrap(
                  spacing: VSpacing.space2,
                  runSpacing: VSpacing.space2,
                  children: [
                    _buildFilterChip(
                      label: 'Cá nhân',
                      isSelected: _selectedPartnerType == PartnerType.person,
                      onTap: () {
                        setState(() {
                          _selectedPartnerType = _selectedPartnerType == PartnerType.person ? null : PartnerType.person;
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: 'Tổ chức',
                      isSelected: _selectedPartnerType == PartnerType.organization,
                      onTap: () {
                        setState(() {
                          _selectedPartnerType = _selectedPartnerType == PartnerType.organization ? null : PartnerType.organization;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.space4),
                _buildSectionTitle('Trạng thái'),
                const SizedBox(height: VSpacing.space3),
                Wrap(
                  spacing: VSpacing.space2,
                  runSpacing: VSpacing.space2,
                  children: [
                    _buildFilterChip(
                      label: 'Tất cả',
                      isSelected: _selectedStatus == null,
                      onTap: () {
                        setState(() {
                          _selectedStatus = null;
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: 'Đang hoạt động',
                      isSelected: _selectedStatus == PartnerStatus.active,
                      onTap: () {
                        setState(() {
                          _selectedStatus = PartnerStatus.active;
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: 'Ngừng hoạt động',
                      isSelected: _selectedStatus == PartnerStatus.inactive,
                      onTap: () {
                        setState(() {
                          _selectedStatus = PartnerStatus.inactive;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.space4),
                _buildSectionTitle('Thời gian cập nhật'),
                const SizedBox(height: VSpacing.space3),
                Wrap(
                  spacing: VSpacing.space2,
                  runSpacing: VSpacing.space2,
                  children: [
                    _buildFilterChip(
                      label: '7 ngày gần đây',
                      isSelected: false,
                      onTap: () {},
                    ),
                    _buildFilterChip(
                      label: '30 ngày gần đây',
                      isSelected: false,
                      onTap: () {},
                    ),
                    _buildFilterChip(
                      label: 'Tùy chọn',
                      isSelected: false,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.space4),
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
                    onPressed: _reset,
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: VTypography.bodySmall.copyWith(
        color: context.vColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.vColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderDefault,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: VTypography.bodyDefault.copyWith(
            color: isSelected ? colors.primary : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

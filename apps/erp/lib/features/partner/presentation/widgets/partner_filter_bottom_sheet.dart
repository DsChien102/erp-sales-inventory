import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

import '../../logic/partner_list_state.dart';

class PartnerFilterBottomSheet extends StatefulWidget {
  const PartnerFilterBottomSheet({
    super.key,
    required this.initialRole,
    required this.initialPartnerType,
    required this.initialStatus,
    required this.initialUpdatedTimeFilter,
  });

  final PartnerRoleFilter? initialRole;
  final PartnerType? initialPartnerType;
  final PartnerStatus? initialStatus;
  final PartnerUpdatedTimeFilter? initialUpdatedTimeFilter;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    PartnerRoleFilter? role,
    PartnerType? partnerType,
    PartnerStatus? status,
    PartnerUpdatedTimeFilter? updatedTimeFilter,
  }) {
    return showVAdaptiveSheet<Map<String, dynamic>>(
      context: context,
      child: PartnerFilterBottomSheet(
        initialRole: role,
        initialPartnerType: partnerType,
        initialStatus: status,
        initialUpdatedTimeFilter: updatedTimeFilter,
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
  PartnerUpdatedTimeFilter? _selectedUpdatedTimeFilter;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _selectedPartnerType = widget.initialPartnerType;
    _selectedStatus = widget.initialStatus;
    _selectedUpdatedTimeFilter = widget.initialUpdatedTimeFilter;
  }

  void _reset() {
    Navigator.of(context).pop(<String, dynamic>{
      'role': null,
      'partnerType': null,
      'status': null,
      'updatedTimeFilter': null,
    });
  }

  void _apply() {
    Navigator.of(context).pop({
      'role': _selectedRole,
      'partnerType': _selectedPartnerType,
      'status': _selectedStatus,
      'updatedTimeFilter': _selectedUpdatedTimeFilter,
    });
  }

  void _toggleRole(PartnerRoleFilter value) {
    setState(() {
      _selectedRole = _selectedRole == value ? null : value;
    });
  }

  void _togglePartnerType(PartnerType value) {
    setState(() {
      _selectedPartnerType = _selectedPartnerType == value ? null : value;
    });
  }

  void _toggleUpdatedTime(PartnerUpdatedTimeFilter value) {
    setState(() {
      _selectedUpdatedTimeFilter = _selectedUpdatedTimeFilter == value ? null : value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: VSpacing.space1),
              VText(
                'Bộ lọc KH & NCC',
                variant: VTextVariant.headingH4,
                color: context.vColors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: VSpacing.space4),
              _buildSectionTitle('Vai trò giao dịch'),
              const SizedBox(height: VSpacing.space3),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  VChip(
                    label: 'Khách hàng',
                    tone: _selectedRole == PartnerRoleFilter.customer
                        ? VComponentTone.primary
                        : VComponentTone.neutral,
                    onTap: () => _toggleRole(PartnerRoleFilter.customer),
                  ),
                  VChip(
                    label: 'Nhà cung cấp',
                    tone: _selectedRole == PartnerRoleFilter.supplier
                        ? VComponentTone.primary
                        : VComponentTone.neutral,
                    onTap: () => _toggleRole(PartnerRoleFilter.supplier),
                  ),
                  VChip(
                    label: 'KH & NCC',
                    tone: _selectedRole == PartnerRoleFilter.both
                        ? VComponentTone.primary
                        : VComponentTone.neutral,
                    onTap: () => _toggleRole(PartnerRoleFilter.both),
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
                  VChip(
                    label: 'Cá nhân',
                    tone: _selectedPartnerType == PartnerType.person
                        ? VComponentTone.primary
                        : VComponentTone.neutral,
                    onTap: () => _togglePartnerType(PartnerType.person),
                  ),
                  VChip(
                    label: 'Tổ chức',
                    tone: _selectedPartnerType == PartnerType.organization
                        ? VComponentTone.primary
                        : VComponentTone.neutral,
                    onTap: () => _togglePartnerType(PartnerType.organization),
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
                  VChip(
                    label: 'Tất cả',
                    tone: _selectedStatus == null
                        ? VComponentTone.primary
                        : VComponentTone.neutral,
                    onTap: () => setState(() => _selectedStatus = null),
                  ),
                  VChip(
                    label: 'Đang hoạt động',
                    tone: _selectedStatus == PartnerStatus.active
                        ? VComponentTone.primary
                        : VComponentTone.neutral,
                    onTap: () => setState(
                      () => _selectedStatus = PartnerStatus.active,
                    ),
                  ),
                  VChip(
                    label: 'Ngừng hoạt động',
                    tone: _selectedStatus == PartnerStatus.inactive
                        ? VComponentTone.primary
                        : VComponentTone.neutral,
                    onTap: () => setState(
                      () => _selectedStatus = PartnerStatus.inactive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space4),
              _buildSectionTitle('Thời gian cập nhật'),
              const SizedBox(height: VSpacing.space3),
              Row(
                key: const Key('partner_updated_time_filters'),
                children: [
                  Expanded(
                    child: VChip(
                      label: '7 ngày gần đây',
                      tone: _selectedUpdatedTimeFilter ==
                              PartnerUpdatedTimeFilter.last7Days
                          ? VComponentTone.primary
                          : VComponentTone.neutral,
                      onTap: () => _toggleUpdatedTime(
                        PartnerUpdatedTimeFilter.last7Days,
                      ),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space2),
                  Expanded(
                    child: VChip(
                      label: '30 ngày gần đây',
                      tone: _selectedUpdatedTimeFilter ==
                              PartnerUpdatedTimeFilter.last30Days
                          ? VComponentTone.primary
                          : VComponentTone.neutral,
                      onTap: () => _toggleUpdatedTime(
                        PartnerUpdatedTimeFilter.last30Days,
                      ),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space2),
                  Expanded(
                    child: VChip(
                      label: 'Tùy chọn',
                      icon: VIcons.calendar,
                      onTap: () {},
                    ),
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return VText(
      title,
      variant: VTextVariant.bodySmall,
      color: context.vColors.textSecondary,
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }
}

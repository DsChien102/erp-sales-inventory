import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';
import 'package:flutter/material.dart';

import '../../shared/iam_role_label_mapper.dart';
import '../invitation_role_options.dart';
import '../models/user_ui_model.dart';
import '../widgets/change_role_bottom_sheet.dart';
import '../widgets/role_radio_list.dart';
import '../widgets/select_role_narrow.dart';
import '../widgets/select_role_wide.dart';

/// Màn hình Chọn vai trò (ID-18).
class OrganizationSelectRolePage extends StatefulWidget {
  const OrganizationSelectRolePage({
    super.key,
    required this.member,
    required this.onConfirm,
    this.invitationRoleOptions,
  });

  final MemberUiModel member;
  final Future<bool> Function(String roleCode) onConfirm;
  final List<InvitationRoleOption>? invitationRoleOptions;

  @override
  State<OrganizationSelectRolePage> createState() =>
      _OrganizationSelectRolePageState();
}

class _OrganizationSelectRolePageState
    extends State<OrganizationSelectRolePage> {
  String? _selectedRoleCode;

  static const List<String> _canonicalRoleCodes = [
    'staff',
    'accountant',
    'warehouse',
    'store_owner',
  ];

  List<RoleChoice> get _orderedRoles {
    final fromInvite = widget.invitationRoleOptions;
    if (fromInvite != null && fromInvite.isNotEmpty) {
      return [
        for (final option in fromInvite)
          RoleChoice(
            id: option.roleId,
            title: option.label,
            description: IamRoleLabelMapper.description(option.label),
            isCurrent: option.label == widget.member.role,
          ),
      ];
    }

    final base = [
      for (final code in _canonicalRoleCodes)
        RoleChoice(
          id: code,
          title: IamRoleLabelMapper.toDisplayLabel(code),
          description: IamRoleLabelMapper.description(code),
          isCurrent: IamRoleLabelMapper.toDisplayLabel(code) == widget.member.role,
        ),
    ];

    final currentIdx = base.indexWhere((r) => r.isCurrent);
    if (currentIdx <= 0) return base;
    final current = base.removeAt(currentIdx);
    base.insert(0, current);
    return base;
  }

  Future<void> _onContinue(List<RoleChoice> roles) async {
    final code = _selectedRoleCode;
    if (code == null) return;
    final selected = roles.firstWhere(
      (r) => r.id == code,
      orElse: () => roles.first,
    );
    final confirmed = await showChangeRoleBottomSheet(
      context: context,
      memberName: widget.member.name,
      fromRole: widget.member.role,
      toRole: selected.title,
      onConfirm: () => widget.onConfirm(selected.id),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final wide = isWideLayout(context);
    final roles = _orderedRoles;

    return VPageScaffold(
      title: 'Chọn vai trò',
      bottomBar: Container(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: colors.borderDefault),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Hủy',
                  variant: VButtonVariant.secondary,
                  tone: VComponentTone.neutral,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const VGap.horizontalSm(),
              Expanded(
                child: VButton(
                  label: 'Tiếp tục',
                  variant: VButtonVariant.primary,
                  tone: VComponentTone.primary,
                  fullWidth: true,
                  onPressed: _selectedRoleCode == null
                      ? null
                      : () => _onContinue(roles),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ColoredBox(
        color: colors.surfaceAlt,
        child: wide
            ? SelectRoleWide(
                member: widget.member,
                roles: roles,
                selectedRoleCode: _selectedRoleCode,
                onChanged: (code) => setState(() => _selectedRoleCode = code),
              )
            : SelectRoleNarrow(
                member: widget.member,
                roles: roles,
                selectedRoleCode: _selectedRoleCode,
                onChanged: (code) => setState(() => _selectedRoleCode = code),
              ),
      ),
    );
  }
}

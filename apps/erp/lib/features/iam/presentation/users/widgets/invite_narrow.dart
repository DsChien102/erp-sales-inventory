import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../bloc/organization_invite_member_state.dart';
import 'role_radio_list.dart';

class InviteNarrow extends StatelessWidget {
  const InviteNarrow({
    super.key,
    required this.state,
    required this.emailController,
    required this.choices,
    required this.onEmailChanged,
    required this.onRoleSelected,
  });

  final OrganizationInviteMemberState state;
  final TextEditingController emailController;
  final List<RoleChoice> choices;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        VCard(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VField(
                invalid: state.emailError != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VFieldLabel('Email', isRequired: true),
                    VEmailField(
                      hintText: 'nhanvien@example.com',
                      controller: emailController,
                      enabled: !state.isSubmitting,
                      validateOnChanged: false,
                      onChanged: onEmailChanged,
                    ),
                    if (state.emailError != null) VFieldError(state.emailError!),
                  ],
                ),
              ),
              const VGap.sm(),
              VText(
                'Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
        // `.t1-invitem`: khe 12 giữa hai thẻ; nhãn "Vai trò ban đầu *" nằm trong thẻ.
        const SizedBox(height: VSpacing.space3),
        VField(
          invalid: state.roleError != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleRadioList(
                roles: choices,
                value: state.selectedRoleId,
                invalid: state.roleError != null,
                onChanged: state.isSubmitting ? null : onRoleSelected,
                header: const VFieldLabel('Vai trò ban đầu', isRequired: true),
              ),
              if (state.roleError != null) VFieldError(state.roleError!),
            ],
          ),
        ),
        const VGap.sm(),
        VText(
          'Vai trò có thể thay đổi sau khi tham gia.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
      ],
    );
  }
}

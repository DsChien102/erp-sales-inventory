import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../bloc/organization_invite_member_state.dart';
import 'role_radio_grid.dart';
import 'role_radio_list.dart';

class InviteWide extends StatelessWidget {
  const InviteWide({
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VText(
                'Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(VRadius.card),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          if (state.emailError != null)
                            VFieldError(state.emailError!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    VField(
                      invalid: state.roleError != null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // VFieldLabel đã có khe 8 bên dưới.
                          const VFieldLabel('Vai trò ban đầu', isRequired: true),
                          RoleRadioGrid(
                            roles: choices,
                            value: state.selectedRoleId,
                            invalid: state.roleError != null,
                            onChanged:
                                state.isSubmitting ? null : onRoleSelected,
                          ),
                          const SizedBox(height: 8),
                          if (state.roleError != null)
                            VFieldError(state.roleError!)
                          else
                            const VFieldDescription(
                              'Vai trò có thể thay đổi sau khi tham gia.',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

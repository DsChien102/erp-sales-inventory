import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

import '../bloc/partner_create_cubit.dart';

class PartnerRoleSection extends StatelessWidget {
  const PartnerRoleSection({super.key});

  static const double _buttonGap = VSpacing.space3;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PartnerCreateCubit>().state;
    final cubit = context.read<PartnerCreateCubit>();
    final colors = context.vColors;
    final selected = state.roles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.space4,
        0,
        VSpacing.space4,
        VSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Chọn vai trò giao dịch của hồ sơ này.',
            textAlign: TextAlign.start,
            variant: VTextVariant.bodySmall,
            color: context.vColors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space3),
          Row(
            children: [
              Expanded(
                child: _RoleButton(
                  key: const Key('role_customer'),
                  label: 'Khách hàng',
                  selected: selected.length == 1 && selected.contains(PartnerRoleType.customer),
                  onPressed: () => cubit.updateRoles(const [PartnerRoleType.customer]),
                ),
              ),
              const SizedBox(width: _buttonGap),
              Expanded(
                child: _RoleButton(
                  key: const Key('role_supplier'),
                  label: 'Nhà cung cấp',
                  selected: selected.length == 1 && selected.contains(PartnerRoleType.supplier),
                  onPressed: () => cubit.updateRoles(const [PartnerRoleType.supplier]),
                ),
              ),
            ],
          ),
          const SizedBox(height: _buttonGap),
          Row(
            children: [
              Expanded(
                child: _RoleButton(
                  key: const Key('role_both'),
                  label: 'KH & NCC',
                  selected: selected.length == 2,
                  onPressed: () => cubit.updateRoles(
                    const [PartnerRoleType.customer, PartnerRoleType.supplier],
                  ),
                ),
              ),
              const SizedBox(width: _buttonGap),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          if (state.errors['roles'] case final error?) ...[
            const SizedBox(height: VSpacing.space2),
            VText(
              error,
              variant: VTextVariant.bodySmall,
              color: colors.danger,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return VButton(
      label: label,
      fullWidth: true,
      size: VButtonSize.large,
      variant: selected ? VButtonVariant.primary : VButtonVariant.outline,
      onPressed: onPressed,
    );
  }
}

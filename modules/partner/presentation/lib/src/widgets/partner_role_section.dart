import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

import '../bloc/partner_create_cubit.dart';

class PartnerRoleSection extends StatelessWidget {
  const PartnerRoleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PartnerCreateCubit>().state;
    final cubit = context.read<PartnerCreateCubit>();
    final selected = state.roles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn vai trò giao dịch của hồ sơ này.',
          style: VTypography.bodySmall.copyWith(
            color: context.vColors.textSecondary,
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        Wrap(
          spacing: VSpacing.space2,
          runSpacing: VSpacing.space2,
          children: [
            _RoleButton(
              key: const Key('role_customer'),
              label: 'Khách hàng',
              selected: selected.length == 1 && selected.contains(PartnerRoleType.customer),
              onPressed: () => cubit.updateRoles(const [PartnerRoleType.customer]),
            ),
            _RoleButton(
              key: const Key('role_supplier'),
              label: 'Nhà cung cấp',
              selected: selected.length == 1 && selected.contains(PartnerRoleType.supplier),
              onPressed: () => cubit.updateRoles(const [PartnerRoleType.supplier]),
            ),
            _RoleButton(
              key: const Key('role_both'),
              label: 'KH & NCC',
              selected: selected.length == 2,
              onPressed: () => cubit.updateRoles(
                const [PartnerRoleType.customer, PartnerRoleType.supplier],
              ),
            ),
          ],
        ),
        if (state.errors['roles'] case final error?) ...[
          const SizedBox(height: VSpacing.space2),
          Text(
            error,
            style: VTypography.bodySmall.copyWith(color: VColors.danger),
          ),
        ],
      ],
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
      variant: selected ? VButtonVariant.primary : VButtonVariant.outline,
      onPressed: onPressed,
    );
  }
}

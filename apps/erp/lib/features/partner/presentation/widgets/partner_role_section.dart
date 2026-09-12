import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

import '../bloc/partner_create_cubit.dart';

class PartnerRoleSection extends StatelessWidget {
  const PartnerRoleSection({super.key});

  static const double _chipGap = VSpacing.space2;

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
          const VGap.md(),
          Wrap(
            spacing: _chipGap,
            runSpacing: _chipGap,
            children: [
              VChip(
                key: const Key('role_customer'),
                label: 'Khách hàng',
                tone: selected.contains(PartnerRoleType.customer)
                    ? VComponentTone.primary
                    : VComponentTone.neutral,
                onTap: () => cubit.toggleRole(PartnerRoleType.customer),
              ),
              VChip(
                key: const Key('role_supplier'),
                label: 'Nhà cung cấp',
                tone: selected.contains(PartnerRoleType.supplier)
                    ? VComponentTone.primary
                    : VComponentTone.neutral,
                onTap: () => cubit.toggleRole(PartnerRoleType.supplier),
              ),
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

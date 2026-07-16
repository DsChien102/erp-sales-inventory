import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_presentation/presentation.dart';

/// Result count label + sort control for partner list.
class PartnerListHeaderRow extends StatelessWidget {
  const PartnerListHeaderRow({
    super.key,
    required this.onSortTap,
  });

  final ValueChanged<PartnerListState> onSortTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPagePadding(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<PartnerListCubit, PartnerListState>(
            builder: (context, state) {
              final hasFilter =
                  state.query != null ||
                  state.partnerType != null ||
                  state.roleFilter != null ||
                  state.status != null;
              final hasAnyFilter = hasFilter || state.updatedTimeFilter != null;
              final total = switch (state) {
                PartnerListLoaded(:final total) => total,
                _ => 0,
              };
              return VText(
                hasAnyFilter ? '$total kết quả phù hợp' : 'Danh sách đối tác',
                variant: VTextVariant.bodyDefault,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
            },
          ),
          BlocBuilder<PartnerListCubit, PartnerListState>(
            builder: (context, state) {
              return InkWell(
                onTap: () => onSortTap(state),
                child: Row(
                  children: [
                    VIcon(
                      iconData: Icons.swap_vert,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    const VGap.horizontalXs(),
                    VText(
                      'Sắp xếp',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

Future<PartnerType?> showPartnerCreateActionSheet(BuildContext context) {
  return showVBottomSheet<PartnerType>(
    context: context,
    title: 'Thêm KH & NCC mới',
    child: const PartnerCreateActionSheet(),
  );
}

class PartnerCreateActionSheet extends StatelessWidget {
  const PartnerCreateActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CreateTypeCard(
            key: const Key('partner_create_person'),
            icon: Icons.person_outline,
            title: 'Tạo cá nhân',
            description: 'Dành cho khách hàng hoặc cá nhân không có pháp nhân',
            onTap: () => Navigator.of(context).pop(PartnerType.person),
          ),
          const SizedBox(height: VSpacing.space3),
          _CreateTypeCard(
            key: const Key('partner_create_organization'),
            icon: Icons.apartment_outlined,
            title: 'Tạo tổ chức',
            description: 'Dành cho công ty, cửa hàng, đại lý, đơn vị kinh doanh',
            onTap: () => Navigator.of(context).pop(PartnerType.organization),
          ),
          const SizedBox(height: VSpacing.space4),
        ],
      ),
    );
  }
}

class _CreateTypeCard extends StatelessWidget {
  const _CreateTypeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      onTap: onTap,
      child: Row(
        children: [
          VIconBox(
            iconData: icon,
            backgroundColor: colors.surfaceBrand,
            iconColor: colors.primary,
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: VTypography.headingH4.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VSpacing.space1),
                Text(
                  description,
                  style: VTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: VSpacing.space2),
          const VIcon(icon: VIcons.chevronRight),
        ],
      ),
    );
  }
}

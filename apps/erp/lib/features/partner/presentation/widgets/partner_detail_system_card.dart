import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

import 'partner_detail_expandable_card.dart';

/// Card «Lịch sử thao tác» — when tapped, it goes straight to the history page.
class PartnerDetailSystemCard extends StatelessWidget {
  const PartnerDetailSystemCard({
    super.key,
    required this.dto,
    this.onTapHistory,
  });

  final PartnerDetailDto dto;
  final VoidCallback? onTapHistory;

  @override
  Widget build(BuildContext context) {
    return PartnerDetailExpandableCard(
      title: 'Lịch sử thao tác ',
      icon: VIcons.settings,
      onTap: onTapHistory,
      child: const SizedBox.shrink(),
    );
  }
}

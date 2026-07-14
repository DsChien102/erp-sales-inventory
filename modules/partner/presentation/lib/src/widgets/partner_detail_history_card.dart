import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'partner_detail_expandable_card.dart';

/// Placeholder for the SG-06 partner transaction history preview.
class PartnerDetailHistoryCard extends StatelessWidget {
  const PartnerDetailHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PartnerDetailExpandableCard(
      title: 'Lịch sử gần đây',
      icon: Icons.history_toggle_off_rounded,
      onTap: () => VToast.show(
        context,
        title: 'Tính năng đang phát triển',
        message: 'Lịch sử làm việc sẽ được phát triển sau.',
        type: VToastType.info,
      ),
      child: const SizedBox.shrink(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_design_system/design_system.dart';

import '../utils/product_change_history_formatters.dart';
import 'product_control_center_section_card.dart';

class ProductControlCenterMetaSection extends StatelessWidget {
  const ProductControlCenterMetaSection({
    super.key,
    required this.note,
    required this.changeHistoryPreview,
    this.onEditNote,
    this.onViewChangeHistory,
  });

  final String? note;
  final List<ProductChangeHistoryEntryDto> changeHistoryPreview;
  final VoidCallback? onEditNote;
  final VoidCallback? onViewChangeHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: VSpacing.space2,
      children: [
        ProductControlCenterSectionCard(
          title: 'Ghi chú',
          icon: Icons.description_outlined,
          subtitle: note?.isNotEmpty == true ? 'Đã điền ghi chú' : 'Chưa có ghi chú',
          onEdit: onEditNote,
        ),
        ProductControlCenterSectionCard(
          title: 'Lịch sử thay đổi',
          icon: Icons.history,
          subtitle: _changeHistorySubtitle(),
          actionText: 'Xem',
          onEdit: onViewChangeHistory,
        ),
      ],
    );
  }

  String _changeHistorySubtitle() {
    if (changeHistoryPreview.isEmpty) {
      return 'Chưa có lịch sử';
    }

    final preview = changeHistoryPreview.first;
    final summary = formatProductChangeHistorySummary(
      summary: preview.summary,
      changeType: preview.changeType,
    );
    final date = formatProductChangeHistoryDateTime(preview.occurredAt).substring(0, 10);
    return '$summary · $date';
  }
}

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'audit_manifest.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class EInvoiceSg02Tab extends StatelessWidget {
  const EInvoiceSg02Tab({super.key});

  static const _group = EInvoiceScreenGroup.sg02;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final specimens = EInvoiceAuditManifest.forGroup(_group);
    return previewList([
      PreviewSection(
        title: '${_group.id} — HĐĐT trên đơn hàng và xem trước',
        description:
            '${_group.epicRef} / Slice ${_group.sliceRef} FE — chưa implement.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Widget preview sẽ được thêm khi slice S2 FE land.',
              style: VTypography.bodyDefault,
            ),
            const SizedBox(height: VSpacing.space2),
            Text(
              '${specimens.length} specimens trong nhóm này.',
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

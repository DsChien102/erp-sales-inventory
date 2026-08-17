import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'audit_manifest.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

/// Intro + full audit checklist for TH-08 §6.5 screen/state specimens.
class EInvoiceOverviewTab extends StatelessWidget {
  const EInvoiceOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final entries = EInvoiceAuditManifest.entries;
    return previewList([
      PreviewSection(
        title: 'E-Invoice presentation example',
        description:
            'Audit catalog cho bounded-context E-Invoice (TH-08). '
            'Fake-only — không ERP shell, không live Supabase, không env:doctor. '
            'DS example = primitives; tab này = BC widgets (khi implement).',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Package: vet45_einvoice_presentation',
              style: VTypography.bodyDefault,
            ),
            const SizedBox(height: VSpacing.space1),
            Text(
              'Specimens: ${entries.length} (SRS §6.5 MVP — SG-04/05 excluded)',
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space1),
            Text(
              'Fake module: vet45_einvoice_application/testing.dart → FakeEInvoiceModule',
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Audit checklist',
        description:
            'Mọi specimen §6.5 — cột planned path để review trước khi implement slice FE.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in entries) ...[
              _AuditRow(entry: entry),
              const SizedBox(height: VSpacing.space3),
            ],
          ],
        ),
      ),
    ]);
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});

  final EInvoiceAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                entry.specimenId,
                style: VTypography.bodyDefault.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            auditStatusBadge(context, entry.statusLabel),
          ],
        ),
        const SizedBox(height: VSpacing.space1),
        Text(entry.title, style: VTypography.bodySmall),
        const SizedBox(height: VSpacing.space1),
        Text(
          '${entry.screenGroup.id} · ${entry.surfaceType}',
          style: VTypography.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: VSpacing.space1),
        Text(
          entry.plannedWidgetPath,
          style: VTypography.caption.copyWith(
            color: colors.textSecondary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

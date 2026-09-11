import 'package:flutter/material.dart';
import 'package:erp/features/partner/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class PartnerSheetsTab extends StatelessWidget {
  const PartnerSheetsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final person = PartnerPreviewFixtures.personActive;
    final inactive = PartnerPreviewFixtures.personInactive;

    return previewList([
      PreviewSection(
        title: 'showPartnerDetailActionSheet',
        description: 'Active person (has transform) + inactive.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Detail actions — active person',
              onPressed: () => showPartnerDetailActionSheet(context, dto: person),
            ),
            PreviewActionButton(
              label: 'Detail actions — inactive',
              onPressed: () {
                showPartnerDetailActionSheet(context, dto: inactive);
              },
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Status / delete confirmation sheets',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Deactivate confirmation',
              onPressed: () {
                showPartnerDeactivateConfirmationSheet(
                  context,
                  primaryContactOrganizationName: 'Công ty Minh Phát',
                );
              },
            ),
            PreviewActionButton(
              label: 'Reactivate confirmation',
              onPressed: () => showPartnerReactivateConfirmationSheet(context),
            ),
            PreviewActionButton(
              label: 'Soft-delete confirmation',
              onPressed: () => showPartnerSoftDeleteConfirmationSheet(context),
            ),
            PreviewActionButton(
              label: 'Delete blocked sheet',
              onPressed: () {
                showPartnerDeleteBlockedSheet(
                  context,
                  showDeactivateAction: true,
                );
              },
            ),
            PreviewActionButton(
              label: 'Delete primary contact blocked',
              onPressed: () {
                showPartnerDeletePrimaryContactBlockedSheet(
                  context,
                  organizationName: 'Công ty ABC',
                );
              },
            ),
          ],
        ),
      ),
    ]);
  }
}

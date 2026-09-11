import 'package:flutter/material.dart';
import 'package:erp/features/partner/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class PartnerTransformTab extends StatelessWidget {
  const PartnerTransformTab({super.key});

  @override
  Widget build(BuildContext context) {
    final person = PartnerPreviewFixtures.personActive;
    const organization = PartnerPreviewFixtures.transformOrganization;

    return previewList([
      PreviewSection(
        title: 'PartnerTransformStepOneView',
        child: PreviewEmbedFrame(
          height: 560,
          child: PartnerTransformStepOneView(
            partner: person,
            onCancel: () {},
            onContinue: (_) {},
          ),
        ),
      ),
      PreviewSection(
        title: 'PartnerTransformPreviewView',
        description: 'Default + error banner.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Default',
              child: PreviewEmbedFrame(
                height: 520,
                child: PartnerTransformPreviewView(
                  partner: person,
                  organization: organization,
                  onBack: () {},
                  onContinue: () {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'With error',
              child: PreviewEmbedFrame(
                height: 520,
                child: PartnerTransformPreviewView(
                  partner: person,
                  organization: organization,
                  errorMessage: 'Không thể chuyển đổi (preview).',
                  onBack: () {},
                  onContinue: () {},
                ),
              ),
            ),
          ],
        ),
      ),
      const PreviewSection(
        title: 'PartnerTransformBlockingBanner',
        child: PartnerTransformBlockingBanner(),
      ),
      PreviewSection(
        title: 'PartnerTransformConfirmationDialog',
        child: PreviewActionButton(
          label: 'Open confirmation dialog',
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (dialogContext) => PartnerTransformConfirmationDialog(
                onBack: () => Navigator.of(dialogContext).pop(),
                onConfirm: () => Navigator.of(dialogContext).pop(),
              ),
            );
          },
        ),
      ),
      PreviewSection(
        title: 'showPartnerTransformSuccessToast',
        child: PreviewActionButton(
          label: 'Show transform success toast',
          onPressed: () => showPartnerTransformSuccessToast(context),
        ),
      ),
      PreviewSection(
        title: 'PartnerTransformBlockedState',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'No permission',
              child: PartnerTransformBlockedState.noPermission(
                onActionPressed: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Stale data',
              child: PartnerTransformBlockedState.staleData(
                onActionPressed: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'showPartnerTransformPrimaryContactBlockedSheet',
        child: PreviewActionButton(
          label: 'Primary contact blocked sheet',
          onPressed: () {
            showPartnerTransformPrimaryContactBlockedSheet(
              context,
              organizationName: 'Công ty ABC',
            );
          },
        ),
      ),
    ]);
  }
}

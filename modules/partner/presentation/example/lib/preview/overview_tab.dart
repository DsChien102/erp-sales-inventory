import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview_helpers.dart';
import 'preview_section.dart';

/// Intro + full coverage checklist for exported Partner presentation widgets.
class PartnerOverviewTab extends StatelessWidget {
  const PartnerOverviewTab({super.key});

  static const covered = <String>[
    'PartnerListItemTile',
    'PartnerListItemSkeletonTile',
    'PartnerListSearchBar',
    'PartnerListQuickFilters',
    'PartnerActiveFilters',
    'PartnerFilterBottomSheet',
    'PartnerSortBottomSheet',
    'PartnerWardSearchDropdown',
    'PartnerDetailView',
    'PartnerDetailHeader',
    'PartnerDetailMainInfoCard',
    'PartnerDetailInvoiceCard',
    'PartnerDetailDeliveryCard',
    'PartnerDetailNoteCard',
    'PartnerDetailSystemCard',
    'PartnerDetailHistoryCard',
    'PartnerDetailLoadingSkeleton',
    'PartnerDetailWarningBanner',
    'PartnerDetailInactiveBanner',
    'PartnerDetailErrorState',
    'PartnerOperationFeedbackState',
    'showPartnerOperationFeedbackDialog',
    'showPartnerCreateActionSheet',
    'PartnerCreateForm',
    'showPartnerDuplicateSheet',
    'showPartnerCreateSuccessToast (+ update/deactivate/reactivate/softDelete)',
    'showPartnerLeaveFormDialog',
    'PartnerDetailContactsCard',
    'showPartnerContactAddMethodSheet',
    'showPartnerContactActionSheet',
    'showPartnerContactChangePrimaryDialog',
    'showPartnerContactRemoveDialog',
    'PartnerContactForm',
    'PartnerContactSelectList',
    'PartnerTransformStepOneView',
    'PartnerTransformPreviewView',
    'PartnerTransformBlockingBanner',
    'PartnerTransformConfirmationDialog',
    'showPartnerTransformSuccessToast',
    'PartnerTransformBlockedState',
    'showPartnerTransformPrimaryContactBlockedSheet',
    'showPartnerDetailActionSheet',
    'showPartnerDeactivateConfirmationSheet',
    'showPartnerReactivateConfirmationSheet',
    'showPartnerSoftDeleteConfirmationSheet',
    'showPartnerDeleteBlockedSheet',
    'showPartnerDeletePrimaryContactBlockedSheet',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return previewList([
      PreviewSection(
        title: 'Partner presentation example',
        description:
            'Golden catalog cho bounded-context Partner. Fake-only — không '
            'ERP shell, không live Supabase, không env:doctor. DS example = '
            'primitives; tab này = BC widgets.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Package: vet45_partner_presentation',
              style: VTypography.bodyDefault,
            ),
            const SizedBox(height: VSpacing.space1),
            Text(
              'Coverage: ${covered.length} public widgets / show* helpers',
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Coverage checklist',
        description:
            'Tất cả export widget trong presentation.dart đã có PreviewSection.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final name in covered) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_box, size: 18, color: colors.success),
                  const SizedBox(width: VSpacing.space2),
                  Expanded(child: Text(name, style: VTypography.bodySmall)),
                ],
              ),
              const SizedBox(height: VSpacing.space2),
            ],
          ],
        ),
      ),
    ]);
  }
}

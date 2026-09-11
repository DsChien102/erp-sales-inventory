import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class PartnerDetailTab extends StatelessWidget {
  const PartnerDetailTab({super.key});

  @override
  Widget build(BuildContext context) {
    final person = PartnerPreviewFixtures.personActive;
    final org = PartnerPreviewFixtures.organizationWithContacts;
    final inactive = PartnerPreviewFixtures.personInactive;

    return previewList([
      PreviewSection(
        title: 'PartnerDetailView',
        description:
            'Full detail composition via PartnerDetailCubit + FakePartnerModule.',
        child: PreviewEmbedFrame(
          height: 520,
          child: BlocProvider(
            create: (_) => PartnerDetailCubit(
              partnerModule: FakePartnerModule(
                scenario: FakePartnerScenario.detailOrganizationWithContacts,
              ),
              executionContext: FakeExecutionContext(),
            )..loadDetail('preview-org-1'),
            child: const PartnerDetailView(),
          ),
        ),
      ),
      PreviewSection(
        title: 'PartnerDetailHeader',
        description: 'Active person + inactive person.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Active',
              child: PartnerDetailHeader(dto: person),
            ),
            PreviewStateRow(
              label: 'Inactive',
              child: PartnerDetailHeader(dto: inactive),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'PartnerDetailMainInfoCard',
        description: 'Person + organization, initially expanded.',
        child: Column(
          children: [
            PartnerDetailMainInfoCard(dto: person, initiallyExpanded: true),
            const SizedBox(height: VSpacing.space3),
            PartnerDetailMainInfoCard(dto: org, initiallyExpanded: true),
          ],
        ),
      ),
      PreviewSection(
        title: 'PartnerDetailInvoiceCard',
        child: PartnerDetailInvoiceCard(dto: org, initiallyExpanded: true),
      ),
      PreviewSection(
        title: 'PartnerDetailDeliveryCard',
        child: PartnerDetailDeliveryCard(dto: person, initiallyExpanded: true),
      ),
      PreviewSection(
        title: 'PartnerDetailNoteCard',
        child: PartnerDetailNoteCard(dto: person, initiallyExpanded: true),
      ),
      PreviewSection(
        title: 'PartnerDetailSystemCard',
        child: PartnerDetailSystemCard(dto: org, onTapHistory: () {}),
      ),
      const PreviewSection(
        title: 'PartnerDetailHistoryCard',
        child: PartnerDetailHistoryCard(),
      ),
      const PreviewSection(
        title: 'PartnerDetailLoadingSkeleton',
        child: PartnerDetailLoadingSkeleton(),
      ),
      PreviewSection(
        title: 'Status banners',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            PreviewStateRow(
              label: 'Warning',
              child: PartnerDetailWarningBanner(
                description: 'Thiếu MST / địa chỉ xuất hóa đơn (preview).',
              ),
            ),
            PreviewStateRow(
              label: 'Inactive',
              child: PartnerDetailInactiveBanner(),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'PartnerDetailErrorState',
        child: PartnerDetailErrorState(
          icon: VIcons.lock,
          title: 'Không có quyền xem',
          description: 'Bạn không có quyền truy cập hồ sơ này.',
          actionLabel: 'Quay lại',
          onActionPressed: () {},
        ),
      ),
      PreviewSection(
        title: 'PartnerOperationFeedbackState',
        description: 'noPermission / sourceChanged / error.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'No permission',
              child: PartnerOperationFeedbackState.noPermission(
                onActionPressed: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Source changed',
              child: PartnerOperationFeedbackState.sourceChanged(
                onActionPressed: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Error',
              child: PartnerOperationFeedbackState.error(
                onActionPressed: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'showPartnerOperationFeedbackDialog',
        child: PreviewActionButton(
          label: 'Open feedback dialog (no permission)',
          onPressed: () {
            showPartnerOperationFeedbackDialog(
              context,
              kind: PartnerOperationFeedbackKind.noPermission,
              onActionPressed: () {},
            );
          },
        ),
      ),
    ]);
  }
}

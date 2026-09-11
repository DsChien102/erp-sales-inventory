import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class PartnerCreateTab extends StatelessWidget {
  const PartnerCreateTab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'showPartnerCreateActionSheet',
        child: PreviewActionButton(
          label: 'Open create action sheet',
          onPressed: () => showPartnerCreateActionSheet(context),
        ),
      ),
      PreviewSection(
        title: 'PartnerCreateForm',
        description:
            'Person create form via PartnerCreateCubit + FakePartnerModule.',
        child: PreviewEmbedFrame(
          height: 560,
          child: BlocProvider(
            create: (_) => PartnerCreateCubit(
              partnerType: PartnerType.person,
              partnerModule: FakePartnerModule(
                scenario: FakePartnerScenario.createPersonOk,
              ),
              executionContext: FakeExecutionContext(),
            ),
            child: PartnerCreateForm(
              onCancel: () {},
              onOpenExisting: (_) {},
            ),
          ),
        ),
      ),
      PreviewSection(
        title: 'showPartnerDuplicateSheet',
        description: 'Possible + exact match levels.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Duplicate — possible',
              onPressed: () {
                showPartnerDuplicateSheet(
                  context: context,
                  level: PartnerDuplicateMatchLevel.possible,
                  matches: PartnerPreviewFixtures.duplicateMatches,
                  onBack: () {},
                  onOpenExisting: () {},
                  onContinue: () {},
                );
              },
            ),
            PreviewActionButton(
              label: 'Duplicate — exact',
              onPressed: () {
                showPartnerDuplicateSheet(
                  context: context,
                  level: PartnerDuplicateMatchLevel.exact,
                  matches: PartnerPreviewFixtures.duplicateMatches,
                  onBack: () {},
                  onOpenExisting: () {},
                );
              },
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Success toasts',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Create success',
              onPressed: () => showPartnerCreateSuccessToast(context),
            ),
            PreviewActionButton(
              label: 'Update success',
              onPressed: () => showPartnerUpdateSuccessToast(context),
            ),
            PreviewActionButton(
              label: 'Deactivate success',
              onPressed: () => showPartnerDeactivateSuccessToast(context),
            ),
            PreviewActionButton(
              label: 'Reactivate success',
              onPressed: () => showPartnerReactivateSuccessToast(context),
            ),
            PreviewActionButton(
              label: 'Soft-delete success',
              onPressed: () => showPartnerSoftDeleteSuccessToast(context),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'showPartnerLeaveFormDialog',
        child: PreviewActionButton(
          label: 'Leave form dialog',
          onPressed: () {
            showPartnerLeaveFormDialog(context: context, onLeave: () {});
          },
        ),
      ),
    ]);
  }
}

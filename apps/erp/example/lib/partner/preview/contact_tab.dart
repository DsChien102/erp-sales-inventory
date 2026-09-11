import 'package:flutter/material.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class PartnerContactTab extends StatelessWidget {
  const PartnerContactTab({super.key});

  @override
  Widget build(BuildContext context) {
    final org = PartnerPreviewFixtures.organizationWithContacts;
    final contact = PartnerPreviewFixtures.primaryContact;

    return previewList([
      PreviewSection(
        title: 'PartnerDetailContactsCard',
        description: 'Filled + empty.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Filled',
              child: PartnerDetailContactsCard(
                dto: org,
                initiallyExpanded: true,
                onTapAdd: () {},
                onTapViewAll: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Empty',
              child: PartnerDetailContactsCard(
                dto: PartnerPreviewFixtures.personActive,
                initiallyExpanded: true,
                onTapAdd: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Contact sheets / dialogs',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Add method sheet',
              onPressed: () => showPartnerContactAddMethodSheet(context),
            ),
            PreviewActionButton(
              label: 'Contact action sheet',
              onPressed: () {
                showPartnerContactActionSheet(context, contact: contact);
              },
            ),
            PreviewActionButton(
              label: 'Change primary dialog',
              onPressed: () {
                showPartnerContactChangePrimaryDialog(
                  context,
                  currentPrimaryName: 'Trần Thị B',
                  newPrimaryName: 'Lê Văn C',
                );
              },
            ),
            PreviewActionButton(
              label: 'Remove contact dialog',
              onPressed: () => showPartnerContactRemoveDialog(context),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'PartnerContactForm',
        description: 'Create / edit / submitting / error.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Create',
              child: PreviewEmbedFrame(
                height: 480,
                child: PartnerContactForm(
                  isSubmitting: false,
                  onSubmit: (
                    fullName,
                    phone,
                    email,
                    contactRole,
                    isPrimary,
                    note,
                  ) {},
                  onCancel: () {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Edit',
              child: PreviewEmbedFrame(
                height: 480,
                child: PartnerContactForm(
                  contact: contact,
                  isSubmitting: false,
                  onSubmit: (
                    fullName,
                    phone,
                    email,
                    contactRole,
                    isPrimary,
                    note,
                  ) {},
                  onCancel: () {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Submitting',
              child: PreviewEmbedFrame(
                height: 200,
                child: PartnerContactForm(
                  isSubmitting: true,
                  onSubmit: (
                    fullName,
                    phone,
                    email,
                    contactRole,
                    isPrimary,
                    note,
                  ) {},
                  onCancel: () {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Error',
              child: PreviewEmbedFrame(
                height: 240,
                child: PartnerContactForm(
                  isSubmitting: false,
                  errorMessage: 'Không lưu được liên hệ (preview).',
                  onSubmit: (
                    fullName,
                    phone,
                    email,
                    contactRole,
                    isPrimary,
                    note,
                  ) {},
                  onCancel: () {},
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'PartnerContactSelectList',
        description: 'Search via FakePartnerModule(searchMixedTypes).',
        child: PreviewEmbedFrame(
          height: 480,
          child: PartnerContactSelectList(
            partnerModule: FakePartnerModule(
              scenario: FakePartnerScenario.searchMixedTypes,
            ),
            executionContext: FakeExecutionContext(),
            onSelect: (_) {},
            onCancel: () {},
          ),
        ),
      ),
    ]);
  }
}

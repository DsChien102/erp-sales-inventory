import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

import '../../logic/partner_create_cubit.dart';
import '../../logic/partner_create_state.dart';
import 'partner_delivery_section.dart';
import 'partner_duplicate_sheet.dart';
import 'partner_form_section.dart';
import 'partner_invoice_section.dart';
import 'partner_note_section.dart';
import 'partner_organization_section.dart';
import 'partner_person_section.dart';
import 'partner_primary_contact_section.dart';
import 'partner_role_section.dart';
import 'partner_section_shell.dart';

class PartnerCreateForm extends StatelessWidget {
  const PartnerCreateForm({
    super.key,
    required this.onCancel,
    required this.onOpenExisting,
  });

  final VoidCallback onCancel;
  final ValueChanged<String> onOpenExisting;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PartnerCreateCubit, PartnerCreateState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && current.status == PartnerCreateStatus.duplicate,
      listener: _showDuplicate,
      child: BlocBuilder<PartnerCreateCubit, PartnerCreateState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(VSpacing.space4),
                  children: [
                    _LockedTypeCard(partnerType: state.partnerType),
                    if (state.generalError != null) ...[
                      const SizedBox(height: VSpacing.space3),
                      _MessageCard(
                        message: state.generalError!,
                      ),
                    ],
                    const SizedBox(height: VSpacing.space3),
                    ..._sections(context, state),
                    const SizedBox(height: VSpacing.space4),
                  ],
                ),
              ),
              _StickyActions(
                onCancel: onCancel,
                onSubmit: context.read<PartnerCreateCubit>().submit,
                isLoading: state.isSubmitting,
                isReadOnly: state.isReadOnly,
                canSubmit: state.canSubmit,
                saveLabel: state.isEditMode ? 'Lưu thay đổi' : 'Lưu & Xem',
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDuplicate(
    BuildContext context,
    PartnerCreateState state,
  ) async {
    final level = state.duplicateLevel;
    if (level == null || state.duplicateMatches.isEmpty) return;
    final cubit = context.read<PartnerCreateCubit>();
    final firstMatch = state.duplicateMatches.first;
    await showPartnerDuplicateSheet(
      context: context,
      level: level,
      matches: state.duplicateMatches,
      onBack: () {
        Navigator.of(context).pop();
        cubit.dismissDuplicate();
      },
      onOpenExisting: () {
        Navigator.of(context).pop();
        onOpenExisting(firstMatch.partnerId);
      },
      onContinue: level == PartnerDuplicateMatchLevel.possible
          ? () {
              Navigator.of(context).pop();
              cubit.confirmPossibleDuplicate();
            }
          : null,
    );
  }

  List<Widget> _sections(BuildContext context, PartnerCreateState state) {
    final cubit = context.read<PartnerCreateCubit>();
    final entries =
        <
          ({
            PartnerCreateSection section,
            String title,
            Widget child,
            String? summary,
            String? expandedTrailingText,
            bool showActions,
            Key key,
          })
        >[
          (
            section: PartnerCreateSection.role,
            title: '2. Vai trò giao dịch',
            child: const PartnerRoleSection(),
            summary: _roleSummary(state.roles),
            expandedTrailingText: null,
            showActions: true,
            key: const Key('section_role'),
          ),
          (
            section: PartnerCreateSection.main,
            title: state.partnerType == PartnerType.person
                ? '3. Thông tin cá nhân'
                : '3. Thông tin tổ chức',
            child: state.partnerType == PartnerType.person
                ? const PartnerPersonSection()
                : const PartnerOrganizationSection(),
            summary: state.partnerType == PartnerType.person
                ? _emptyToNull(state.fullName)
                : _emptyToNull(state.organizationName),
            expandedTrailingText: null,
            showActions: true,
            key: const Key('section_main'),
          ),
          if (state.partnerType == PartnerType.organization && !state.isEditMode)
            (
              section: PartnerCreateSection.primaryContact,
              title: '4. Người liên hệ chính',
              child: const PartnerPrimaryContactSection(),
              summary: state.primaryContactEnabled
                  ? _emptyToNull(state.primaryContactName) ?? 'Đã bật'
                  : 'Tùy chọn',
              expandedTrailingText: 'Tùy chọn',
              showActions: true,
              key: const Key('section_primary_contact'),
            ),
          (
            section: PartnerCreateSection.invoice,
            title:
                '${state.partnerType == PartnerType.person || state.isEditMode ? 4 : 5}. Hóa đơn / thuế',
            child: const PartnerInvoiceSection(),
            summary: _emptyToNull(state.taxCode),
            expandedTrailingText: null,
            showActions: true,
            key: const Key('section_invoice'),
          ),
          (
            section: PartnerCreateSection.delivery,
            title:
                '${state.partnerType == PartnerType.person || state.isEditMode ? 5 : 6}. Địa chỉ giao hàng',
            child: const PartnerDeliverySection(),
            summary: _emptyToNull(state.deliveryProvince) ?? 'Tùy chọn',
            expandedTrailingText: null,
            showActions: true,
            key: const Key('section_delivery'),
          ),
          (
            section: PartnerCreateSection.note,
            title:
                '${state.partnerType == PartnerType.person || state.isEditMode ? 6 : 7}. Ghi chú',
            child: const PartnerNoteSection(),
            summary: state.note.trim().isEmpty ? 'Tùy chọn' : 'Đã nhập',
            expandedTrailingText: null,
            showActions: false,
            key: const Key('section_note'),
          ),
        ];

    return entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.space3),
            child: PartnerFormSection(
              key: entry.key,
              title: entry.title,
              isExpanded: state.activeSection == entry.section,
              isCompleted: state.completedSections.contains(entry.section),
              summary: entry.summary,
              expandedTrailingText: entry.expandedTrailingText,
              showActions: entry.showActions,
              onTap: () => cubit.setActiveSection(entry.section),
              onSkip: cubit.skipActiveSection,
              onNext: cubit.continueActiveSection,
              child: entry.child,
            ),
          ),
        )
        .toList();
  }

  static String? _roleSummary(List<PartnerRoleType> roles) {
    if (roles.length == 2) return 'KH & NCC';
    if (roles.contains(PartnerRoleType.customer)) return 'Khách hàng';
    if (roles.contains(PartnerRoleType.supplier)) return 'Nhà cung cấp';
    return null;
  }

  static String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();
}

class _LockedTypeCard extends StatelessWidget {
  const _LockedTypeCard({required this.partnerType});

  final PartnerType partnerType;

  @override
  Widget build(BuildContext context) {
    return PartnerSectionShell(
      child: PartnerSectionHeader(
        title: '1. Loại hồ sơ',
        trailingText: partnerType == PartnerType.person ? 'Cá nhân' : 'Tổ chức',
        trailingIcon: VIcon(
          icon: VIcons.lock,
          size: 20,
          color: context.vColors.textMuted,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return VBanner(
      status: VBannerStatus.error,
      title: message,
    );
  }
}

class _StickyActions extends StatelessWidget {
  const _StickyActions({
    required this.onCancel,
    required this.onSubmit,
    required this.isLoading,
    required this.isReadOnly,
    required this.canSubmit,
    required this.saveLabel,
  });

  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool isReadOnly;
  final bool canSubmit;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final canPressSave = canSubmit && !isReadOnly && !isLoading;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.space4,
        VSpacing.space3,
        VSpacing.space4,
        VSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: VButton(
              label: 'Hủy',
              variant: VButtonVariant.secondary,
              onPressed: isLoading ? null : onCancel,
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: VButton(
              key: const Key('btn_save_view'),
              label: saveLabel,
              isLoading: isLoading,
              onPressed: canPressSave ? onSubmit : null,
            ),
          ),
        ],
      ),
    );
  }
}

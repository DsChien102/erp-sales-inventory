import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import '../bloc/partner_create_cubit.dart';
import '../bloc/partner_create_state.dart';
import 'partner_delivery_section.dart';
import 'partner_duplicate_sheet.dart';
import 'partner_form_section.dart';
import 'partner_invoice_section.dart';
import 'partner_note_section.dart';
import 'partner_organization_section.dart';
import 'partner_person_section.dart';
import 'partner_primary_contact_section.dart';
import 'partner_role_section.dart';

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
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  children: [
                    _LockedTypeCard(partnerType: state.partnerType),
                    if (state.generalError != null) ...[
                      const SizedBox(height: VSpacing.space3),
                      _MessageCard(
                        message: state.generalError!,
                        blocked: state.isReadOnly,
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
            Key key,
          })
        >[
          (
            section: PartnerCreateSection.role,
            title: '2. Vai trò giao dịch',
            child: const PartnerRoleSection(),
            summary: _roleSummary(state.roles),
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
            key: const Key('section_main'),
          ),
          if (state.partnerType == PartnerType.organization)
            (
              section: PartnerCreateSection.primaryContact,
              title: '4. Người liên hệ chính',
              child: const PartnerPrimaryContactSection(),
              summary: state.primaryContactEnabled
                  ? _emptyToNull(state.primaryContactName) ?? 'Đã bật'
                  : 'Tùy chọn',
              key: const Key('section_primary_contact'),
            ),
          (
            section: PartnerCreateSection.invoice,
            title: '${state.partnerType == PartnerType.person ? 4 : 5}. Hóa đơn / thuế',
            child: const PartnerInvoiceSection(),
            summary: _emptyToNull(state.taxCode),
            key: const Key('section_invoice'),
          ),
          (
            section: PartnerCreateSection.delivery,
            title: '${state.partnerType == PartnerType.person ? 5 : 6}. Địa chỉ giao hàng',
            child: const PartnerDeliverySection(),
            summary: _emptyToNull(state.deliveryProvince) ?? 'Tùy chọn',
            key: const Key('section_delivery'),
          ),
          (
            section: PartnerCreateSection.note,
            title: '${state.partnerType == PartnerType.person ? 6 : 7}. Ghi chú',
            child: const PartnerNoteSection(),
            summary: state.note.trim().isEmpty ? 'Tùy chọn' : 'Đã nhập',
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
    final colors = context.vColors;
    return VCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '1. Loại hồ sơ',
              style: VTypography.bodyDefault.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            partnerType == PartnerType.person ? 'Cá nhân' : 'Tổ chức',
            style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(width: VSpacing.space2),
          VIcon(
            iconData: Icons.lock_outline,
            size: 16,
            color: colors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.blocked});

  final String message;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    return VCard(
      child: Row(
        children: [
          VIcon(
            iconData: blocked ? Icons.lock_outline : Icons.error_outline,
            color: VColors.danger,
          ),
          const SizedBox(width: VSpacing.space2),
          Expanded(
            child: Text(
              message,
              style: VTypography.bodyDefault.copyWith(color: VColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyActions extends StatelessWidget {
  const _StickyActions({
    required this.onCancel,
    required this.onSubmit,
    required this.isLoading,
    required this.isReadOnly,
  });

  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
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
              variant: VButtonVariant.outline,
              onPressed: isLoading ? null : onCancel,
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: VButton(
              key: const Key('btn_save_view'),
              label: 'Lưu & Xem',
              isLoading: isLoading,
              onPressed: isReadOnly || isLoading ? null : onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

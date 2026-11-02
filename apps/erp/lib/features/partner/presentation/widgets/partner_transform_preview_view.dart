import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

import 'partner_transform_blocking_banner.dart';
import 'partner_transform_preview_card.dart';
import 'partner_transform_stepper.dart';

class PartnerTransformPreviewView extends StatelessWidget {
  const PartnerTransformPreviewView({
    super.key,
    required this.partner,
    required this.organization,
    required this.onBack,
    required this.onContinue,
    this.errorMessage,
  });

  final PartnerDetailDto partner;
  final OrganizationProfileInput organization;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final person = partner.personProfile;
    assert(person != null, 'Transform preview requires a person profile');
    final colors = context.vColors;
    final error = errorMessage?.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.space3,
        VSpacing.space3,
        VSpacing.space3,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PartnerTransformStepper(currentStep: 2),
          const SizedBox(height: VSpacing.space3),
          Align(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
            ),
          ),
          if (error != null && error.isNotEmpty) ...[
            const SizedBox(height: VSpacing.space3),
            PartnerTransformBlockingBanner(message: error),
          ],
          const SizedBox(height: VSpacing.space4),
          _PreviewSection(
            title: 'Trước khi chuyển',
            child: PartnerTransformPreviewCard(
              displayName: person!.fullName,
              subtitle: 'Cá nhân  •  ${_roleLabel(partner.roles)}',
              phone: person.phone,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
            child: Icon(
              Icons.arrow_downward_rounded,
              color: colors.primary,
              size: 28,
            ),
          ),
          _PreviewSection(
            title: 'Sau khi chuyển',
            child: PartnerTransformPreviewCard(
              displayName: organization.organizationName,
              subtitle: 'Tổ chức  •  ${_roleLabel(partner.roles)}',
              phone: organization.phone,
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          VText(
            'Người liên hệ chính (từ hồ sơ cá nhân)',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerTransformPreviewCard(
            displayName: person.fullName,
            subtitle: 'Người liên hệ chính',
            phone: person.phone,
          ),
          const SizedBox(height: VSpacing.space3),
          const VBanner(
            status: VBannerStatus.info,
            title: 'Lịch sử giao dịch và dữ liệu liên quan sẽ được giữ nguyên.',
          ),
          const SizedBox(height: VSpacing.space4),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: VSpacing.space3),
            child: Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('transform_preview_back'),
                    label: 'Quay lại',
                    variant: VButtonVariant.secondary,
                    foregroundColor: colors.success,
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    key: const Key('transform_preview_continue'),
                    label: 'Xác nhận',
                    onPressed: onContinue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(List<PartnerRoleType> roles) {
    final isCustomer = roles.contains(PartnerRoleType.customer);
    final isSupplier = roles.contains(PartnerRoleType.supplier);
    if (isCustomer && isSupplier) return 'KH & NCC';
    if (isSupplier) return 'Nhà cung cấp';
    return 'Khách hàng';
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: context.vColors.surfaceAlt,
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            title,
            variant: VTextVariant.bodyDefault,
            color: context.vColors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: VSpacing.space2),
          child,
        ],
      ),
    );
  }
}

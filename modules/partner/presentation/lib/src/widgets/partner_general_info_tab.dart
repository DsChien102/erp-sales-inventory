import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/partner_list_state.dart';

/// Hiển thị hồ sơ chi tiết đối tác (US-04).
class PartnerGeneralInfoTab extends StatelessWidget {
  final PartnerItemModel partner;

  const PartnerGeneralInfoTab({
    super.key,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection(
            context,
            title: 'THÔNG TIN CƠ BẢN',
            children: [
              _buildRow(
                context,
                'Loại hồ sơ',
                _valueOrPlaceholder(partner.profileType),
              ),
              _buildRow(
                context,
                'Mã số thuế',
                _valueOrPlaceholder(partner.taxId),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          _buildSection(
            context,
            title: 'THÔNG TIN LIÊN HỆ',
            children: [
              _buildRow(context, 'Số điện thoại', partner.phone),
              _buildRow(
                context,
                'Email',
                _valueOrPlaceholder(partner.email),
                isValueGray: partner.email.isEmpty,
              ),
              _buildRow(
                context,
                'Địa chỉ',
                _valueOrPlaceholder(partner.address),
                isValueGray: partner.address.isEmpty,
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          _buildSection(
            context,
            title: 'GHI CHÚ',
            children: [
              _buildRow(
                context,
                'Ghi chú',
                _valueOrPlaceholder(partner.note),
                isValueGray: partner.note.isEmpty,
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          _buildSection(
            context,
            title: 'THÔNG TIN HỆ THỐNG',
            children: [
              _buildRow(
                context,
                'Người tạo',
                _valueOrPlaceholder(partner.creator),
                isValueGray: partner.creator.isEmpty,
              ),
              _buildRow(
                context,
                'Thời điểm tạo',
                _valueOrPlaceholder(partner.createdAt),
                isValueGray: partner.createdAt.isEmpty,
              ),
              _buildRow(
                context,
                'Người cập nhật',
                _valueOrPlaceholder(partner.updatedBy),
                isValueGray: partner.updatedBy.isEmpty,
              ),
              _buildRow(
                context,
                'Cập nhật lúc',
                _valueOrPlaceholder(partner.updatedAt),
                isValueGray: partner.updatedAt.isEmpty,
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  static String _valueOrPlaceholder(String value) {
    return value.isNotEmpty ? value : 'Chưa cập nhật';
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final dynamicColors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: dynamicColors.borderDefault),
      ),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: VTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: dynamicColors.textSecondary,
            ),
          ),
          const SizedBox(height: VSpacing.space4),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    bool isValueGray = false,
  }) {
    final dynamicColors = context.vColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: VTypography.bodyDefault.copyWith(
                color: isValueGray
                    ? dynamicColors.textSecondary
                    : dynamicColors.textPrimary,
                fontStyle: isValueGray ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

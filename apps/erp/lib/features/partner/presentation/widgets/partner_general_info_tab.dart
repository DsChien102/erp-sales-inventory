import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/partner_list_state.dart';

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
              _buildRow(context, 'Loại hồ sơ', partner.profileType.isNotEmpty ? partner.profileType : 'Chưa cập nhật'),
              _buildRow(context, 'Mã số thuế', partner.taxId.isNotEmpty ? partner.taxId : 'Chưa cập nhật'),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          _buildSection(
            context,
            title: 'THÔNG TIN LIÊN HỆ',
            children: [
              _buildRow(context, 'Số điện thoại', partner.phone),
              _buildRow(context, 'Email', partner.email.isNotEmpty ? partner.email : 'Chưa cập nhật', isValueGray: partner.email.isEmpty),
              _buildRow(context, 'Địa chỉ', partner.address.isNotEmpty ? partner.address : 'Chưa cập nhật', isValueGray: partner.address.isEmpty),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          _buildSection(
            context,
            title: 'GHI CHÚ',
            children: [
              Text(
                partner.note.isNotEmpty ? partner.note : 'Chưa cập nhật',
                style: VTypography.bodyDefault.copyWith(
                  color: partner.note.isNotEmpty ? context.vColors.textPrimary : context.vColors.textSecondary,
                  fontStyle: partner.note.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          _buildSection(
            context,
            title: 'THÔNG TIN HỆ THỐNG',
            children: [
              _buildRow(context, 'Người tạo', partner.creator.isNotEmpty ? partner.creator : 'Chưa cập nhật'),
              _buildRow(context, 'Thời điểm tạo', partner.createdAt.isNotEmpty ? partner.createdAt : 'Chưa cập nhật'),
              _buildRow(context, 'Cập nhật bởi', partner.updatedBy.isNotEmpty ? partner.updatedBy : 'Chưa cập nhật'),
              _buildRow(context, 'Cập nhật lúc', partner.updatedAt.isNotEmpty ? partner.updatedAt : 'Chưa cập nhật'),
            ],
          ),
          const SizedBox(height: 80), // Padding cho bottom navigation
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
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

  Widget _buildRow(BuildContext context, String label, String value, {bool isValueGray = false}) {
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
                color: isValueGray ? dynamicColors.textSecondary : dynamicColors.textPrimary,
                fontStyle: isValueGray ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/models.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_control_center_section_card.dart';

class ProductControlCenterIdentitySection extends StatelessWidget {
  const ProductControlCenterIdentitySection({
    super.key,
    required this.profile,
    this.onEditProfile,
    this.onEditImages,
  });

  final ProductProfileSummaryDto profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onEditImages;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: VSpacing.space2,
      children: [
        ProductControlCenterSectionCard(
          title: 'Hồ sơ sản phẩm',
          icon: VIcons.clipboard,
          subtitle: '${profile.sku ?? 'Chưa có mã SKU'} · ${profile.barcode ?? 'Chưa có mã vạch'}',
          onEdit: onEditProfile,
        ),
        ProductControlCenterSectionCard(
          title: 'Ảnh sản phẩm',
          icon: VIcons.camera,
          subtitle: '${profile.images.length} ảnh',
          onEdit: onEditImages,
        ),
      ],
    );
  }
}

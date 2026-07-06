import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

class ProductControlCenterRouteArgs {
  final ProductListItemModel product;
  const ProductControlCenterRouteArgs({required this.product});
}

class ProductControlCenterPage extends StatelessWidget {
  const ProductControlCenterPage({
    super.key,
    required this.product,
  });

  final ProductListItemModel product;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isReady = product.readinessStatus == ProductReadinessStatus.ready;

    // Determine missing items for Slice 1 and Slice 2
    final missingList = <String>[];
    if (product.baseUnit == null || product.baseUnit!.trim().isEmpty) {
      missingList.add('Đơn vị cơ sở');
    }
    if (product.images == null || product.images!.isEmpty) {
      missingList.add('Ảnh sản phẩm');
    }
    if (product.stockQty == null) {
      missingList.add('Tồn kho khởi tạo');
    }
    if (product.listPrice == null) {
      missingList.add('Khung giá bán');
    }

    return Scaffold(
      backgroundColor: dynamicColors.background,
      appBar: AppBar(
        backgroundColor: dynamicColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: dynamicColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/products/items');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              style: VTypography.headingH3.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            VBadge(
              label: isReady ? 'Sẵn sàng bán' : 'Thiếu dữ liệu',
              status: isReady ? VBadgeStatus.success : VBadgeStatus.danger,
              isSmall: true,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: dynamicColors.borderDefault, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Header Card using VCard
            Padding(
              padding: const EdgeInsets.all(16),
              child: VCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Thumbnail image box using dynamic VIconBox placeholder
                    (product.images != null && product.images!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.images!.first,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => VIconBox(
                                size: 64,
                                iconSize: 32,
                                iconData: Icons.image_outlined,
                                backgroundColor: dynamicColors.surfaceAlt,
                                iconColor: dynamicColors.textMuted,
                              ),
                            ),
                          )
                        : VIconBox(
                            size: 64,
                            iconSize: 32,
                            iconData: Icons.image_outlined,
                            backgroundColor: dynamicColors.surfaceAlt,
                            iconColor: dynamicColors.textMuted,
                          ),
                    const SizedBox(width: 16),
                    // Price and Stock details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.listPrice != null
                                ? 'Giá niêm yết: ${_formatCurrency(product.listPrice)}'
                                : 'Giá niêm yết: --',
                            style: VTypography.bodyDefault.copyWith(
                              color: dynamicColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.stockQty != null
                                ? 'Tồn (${product.baseUnit ?? 'cơ sở'}): ${product.stockQty}'
                                : 'Tồn (${product.baseUnit ?? 'cơ sở'}): Chưa thiết lập',
                            style: VTypography.bodySmall.copyWith(
                              color: dynamicColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Readiness Alert Banner using warning colors from VColorScheme
            if (missingList.isNotEmpty) ...[
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: dynamicColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Checklist cần bổ sung',
                                style: VTypography.headingH3.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: dynamicColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...missingList.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: dynamicColors.warning,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: VTypography.bodyDefault.copyWith(
                                            color: dynamicColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              VButton(
                                label: 'Đóng',
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dynamicColors.warningBg,
                    border: Border.all(color: dynamicColors.warning.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: dynamicColors.warning,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cần bổ sung (${missingList.length})',
                              style: VTypography.bodyDefault.copyWith(
                                color: dynamicColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bấm để xem checklist và bổ sung từng mục.',
                              style: VTypography.bodySmall.copyWith(
                                color: dynamicColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: dynamicColors.warning),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Slice 1 Sections/Cards
            _buildSectionCard(
              context: context,
              icon: Icons.assignment_outlined,
              title: 'Hồ sơ sản phẩm',
              subtitle: product.sku ?? 'Chưa thiết lập SKU',
              onEdit: () {
                VToast.show(
                  context,
                  title: 'Chỉnh sửa',
                  message: 'Chức năng sửa thông tin sẽ khả dụng trong slice tiếp theo.',
                  type: VToastType.info,
                );
              },
            ),

            _buildSectionCard(
              context: context,
              icon: Icons.camera_alt_outlined,
              title: 'Ảnh sản phẩm',
              subtitle: (product.images == null || product.images!.isEmpty)
                  ? 'Chưa có ảnh'
                  : 'Đã có ${product.images!.length} ảnh',
              onEdit: () {
                VToast.show(
                  context,
                  title: 'Chỉnh sửa',
                  message: 'Chức năng sửa ảnh sẽ khả dụng trong slice tiếp theo.',
                  type: VToastType.info,
                );
              },
            ),

            _buildSectionCard(
              context: context,
              icon: Icons.straighten,
              title: 'Đơn vị đo lường',
              subtitle: 'Cơ sở: ${product.baseUnit ?? 'Chưa thiết lập'}',
              onEdit: () {
                VToast.show(
                  context,
                  title: 'Chỉnh sửa',
                  message: 'Chức năng sửa đơn vị sẽ khả dụng trong slice tiếp theo.',
                  type: VToastType.info,
                );
              },
            ),

            _buildSectionCard(
              context: context,
              icon: Icons.inventory_2_outlined,
              title: 'Tồn kho khởi tạo',
              subtitle: product.stockQty != null
                  ? 'Tồn kho: ${product.stockQty} ${product.baseUnit ?? ''}'
                  : 'Chưa thiết lập tồn kho',
              onEdit: () {
                VToast.show(
                  context,
                  title: 'Chỉnh sửa',
                  message: 'Chức năng sửa tồn kho sẽ khả dụng trong slice tiếp theo.',
                  type: VToastType.info,
                );
              },
            ),

            _buildSectionCard(
              context: context,
              icon: Icons.payments_outlined,
              title: 'Giá vốn & Định giá',
              subtitle: product.baseCost != null
                  ? 'Giá vốn: ${_formatCurrency(product.baseCost)} · Giá bán: ${product.listPrice != null ? _formatCurrency(product.listPrice) : 'Chưa thiết lập'}'
                  : 'Chưa thiết lập định giá',
              onEdit: () {
                VToast.show(
                  context,
                  title: 'Chỉnh sửa',
                  message: 'Chức năng sửa định giá sẽ khả dụng trong slice tiếp theo.',
                  type: VToastType.info,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double? value) {
    if (value == null) return '--';
    final intVal = value.round();
    final buffer = StringBuffer();
    final s = intVal.toString();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} đ';
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
  }) {
    final dynamicColors = context.vColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: VCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left Icon rounded box using VIconBox and dynamic colors
            VIconBox(
              iconData: icon,
              size: 40,
              iconSize: 20,
              backgroundColor: dynamicColors.surfaceBrand,
              iconColor: dynamicColors.primary,
            ),
            const SizedBox(width: 16),
            // Middle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: VTypography.bodySmall.copyWith(
                      color: dynamicColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Edit Action
            TextButton(
              onPressed: onEdit,
              child: Text(
                'Sửa',
                style: VTypography.bodyDefault.copyWith(
                  color: dynamicColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

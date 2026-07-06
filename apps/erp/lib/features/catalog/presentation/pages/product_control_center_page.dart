import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'product_readiness_checklist_page.dart';

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
    return BlocProvider(
      create: (_) => ProductControlCenterCubit(
        catalogModule: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
      )..loadReadiness(product.id),
      child: _ProductControlCenterView(product: product),
    );
  }
}

class _ProductControlCenterView extends StatelessWidget {
  const _ProductControlCenterView({required this.product});

  final ProductListItemModel product;

  IconData _getIconForChecklistGroup(ReadinessChecklistGroup group) {
    switch (group) {
      case ReadinessChecklistGroup.profile:
        return Icons.assignment_outlined;
      case ReadinessChecklistGroup.images:
        return Icons.camera_alt_outlined;
      case ReadinessChecklistGroup.units:
        return Icons.straighten;
      case ReadinessChecklistGroup.stock:
        return Icons.inventory_2_outlined;
      case ReadinessChecklistGroup.basePrice:
        return Icons.monetization_on_outlined;
      case ReadinessChecklistGroup.priceBand:
        return Icons.local_offer_outlined;
      case ReadinessChecklistGroup.customFields:
        return Icons.list_alt_outlined;
      case ReadinessChecklistGroup.lifecycle:
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isReady = product.readinessStatus == ProductReadinessStatus.ready;

    return Scaffold(
      key: const Key('wgt_e02_u03_fr01_01'),
      backgroundColor: dynamicColors.background,
      appBar: VAppBar(
        title: product.name,
        titleStyle: VTypography.headingH3.copyWith(
          color: dynamicColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
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
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: VBadge(
                label: isReady ? 'Sẵn sàng bán' : 'Thiếu dữ liệu',
                status: isReady ? VBadgeStatus.success : VBadgeStatus.danger,
                isSmall: true,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ProductControlCenterCubit, ProductControlCenterState>(
        builder: (context, state) {
          final readinessView = state.readinessView;
          final isLoading = state.status == ProductControlCenterStatus.loading ||
              state.status == ProductControlCenterStatus.initial;
          
          final blockersCount = readinessView?.readinessSummary.blockers.length ?? 0;

          return SingleChildScrollView(
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
                                'Giá niêm yết: --',
                                style: VTypography.bodyDefault.copyWith(
                                  color: dynamicColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tồn (${product.baseUnit ?? 'cơ sở'}): Chưa thiết lập',
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
                if (readinessView != null && blockersCount > 0) ...[
                  GestureDetector(
                    key: const Key('btn_readiness_checklist_banner'),
                    onTap: () {
                      context.push(
                        '/products/items/pcc/checklist',
                        extra: ProductReadinessChecklistRouteArgs(readinessView: readinessView),
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
                            Icons.error_outline,
                            color: dynamicColors.warning,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cần bổ sung ($blockersCount)',
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (readinessView != null)
                  ...readinessView.checklist.map((item) {
                    final isComplete = item.status == ReadinessChecklistItemStatus.complete;
                    return _buildSectionCard(
                      context: context,
                      icon: _getIconForChecklistGroup(item.group),
                      title: item.label,
                      subtitle: item.description ?? (isComplete ? 'Hoàn tất' : 'Chưa thiết lập'),
                      onEdit: () {
                        VToast.show(
                          context,
                          title: 'Chỉnh sửa',
                          message: 'Chức năng sửa thông tin sẽ khả dụng trong slice tiếp theo.',
                          type: VToastType.info,
                        );
                      },
                    );
                  }),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
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

  String _priceBandSubtitle(ProductListItemModel product) {
    if (product.listPrice == null && product.floorPrice == null) {
      return 'Chưa thiết lập khung giá bán';
    }

    final listPart = product.listPrice != null
        ? 'Niêm yết: ${_formatCurrency(product.listPrice)}'
        : 'Niêm yết: --';
    final floorPart = product.floorPrice != null
        ? 'Sàn: ${_formatCurrency(product.floorPrice)}'
        : 'Sàn: --';
    final unit = product.baseUnit?.trim();
    final unitSuffix =
        unit != null && unit.isNotEmpty ? ' · Đơn vị: $unit' : '';

    return '$listPart · $floorPart$unitSuffix';
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    Key? key,
  }) {
    final dynamicColors = context.vColors;
    return Padding(
      key: key,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

import '../widgets/product_control_center_operational_section.dart';
import '../widgets/product_control_center_profile_card.dart';
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
      )..loadControlCenter(product.id),
      child: _ProductControlCenterView(product: product),
    );
  }
}

class _ProductControlCenterView extends StatelessWidget {
  const _ProductControlCenterView({required this.product});

  final ProductListItemModel product;

  void _showEditPlaceholder(BuildContext context) {
    VToast.show(
      context,
      title: 'Chỉnh sửa',
      message: 'Chức năng sửa thông tin sẽ khả dụng trong slice tiếp theo.',
      type: VToastType.info,
    );
  }

  Future<void> _openChecklist(BuildContext context) async {
    final cubit = context.read<ProductControlCenterCubit>();
    await cubit.loadReadinessForChecklist(product.id);
    if (!context.mounted) return;

    final readinessView = cubit.state.readinessView;
    if (readinessView == null) return;

    context.push(
      '/products/items/pcc/checklist',
      extra: ProductReadinessChecklistRouteArgs(readinessView: readinessView),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return KeyedSubtree(
      key: const Key('wgt_e01_u02_fr01_01'),
      child: Scaffold(
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
            BlocBuilder<ProductControlCenterCubit, ProductControlCenterState>(
              builder: (context, state) {
                final isReady = state.controlCenter?.readinessSummary.status ==
                    ReadinessStatus.readyToSell;

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: VBadge(
                      label: isReady ? 'Sẵn sàng bán' : 'Thiếu dữ liệu',
                      status:
                          isReady ? VBadgeStatus.success : VBadgeStatus.danger,
                      isSmall: true,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<ProductControlCenterCubit, ProductControlCenterState>(
          builder: (context, state) {
            final controlCenter = state.controlCenter;
            final isLoading = state.status == ProductControlCenterStatus.loading ||
                state.status == ProductControlCenterStatus.initial;

            if (state.status == ProductControlCenterStatus.failure) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Không thể tải chi tiết sản phẩm',
                  style: VTypography.bodyDefault.copyWith(
                    color: dynamicColors.textSecondary,
                  ),
                ),
              );
            }

            final blockersCount =
                controlCenter?.readinessSummary.blockers.length ?? 0;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controlCenter != null)
                    ProductControlCenterProfileCard(
                      profile: controlCenter.profile,
                      priceBand: controlCenter.priceBand,
                      stock: controlCenter.stock,
                    )
                  else if (isLoading)
                    const SizedBox(height: 96),

                  if (controlCenter != null && blockersCount > 0) ...[
                    GestureDetector(
                      key: const Key('btn_readiness_checklist_banner'),
                      onTap: () => _openChecklist(context),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dynamicColors.warningBg,
                          border: Border.all(
                            color: dynamicColors.warning.withValues(alpha: 0.3),
                          ),
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
                  else if (controlCenter != null)
                    ProductControlCenterOperationalSection(
                      units: controlCenter.units,
                      stock: controlCenter.stock,
                      basePrice: controlCenter.basePrice,
                      priceBand: controlCenter.priceBand,
                      onEdit: () => _showEditPlaceholder(context),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

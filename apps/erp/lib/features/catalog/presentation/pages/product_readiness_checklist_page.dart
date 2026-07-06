import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductReadinessChecklistRouteArgs {
  final ProductReadinessViewDto readinessView;
  const ProductReadinessChecklistRouteArgs({required this.readinessView});
}

class ProductReadinessChecklistPage extends StatelessWidget {
  const ProductReadinessChecklistPage({
    super.key,
    required this.readinessView,
  });

  final ProductReadinessViewDto readinessView;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Scaffold(
      backgroundColor: dynamicColors.background,
      appBar: AppBar(
        backgroundColor: dynamicColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: dynamicColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sẵn sàng vận hành',
              style: VTypography.headingH3.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              readinessView.productName,
              style: VTypography.bodySmall.copyWith(
                color: dynamicColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: dynamicColors.borderDefault, height: 1),
        ),
      ),
      body: ProductReadinessChecklistBody(
        readinessView: readinessView,
        onActionTap: (actionId) {
          VToast.show(
            context,
            title: 'Thao tác',
            message: 'Tính năng ($actionId) đang được xây dựng.',
            type: VToastType.info,
          );
        },
      ),
    );
  }
}

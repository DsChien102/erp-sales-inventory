import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/logic/costing/cost_versions_cubit.dart';
import 'package:erp/features/inventory/logic/costing/cost_versions_state.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

/// Sheet "Lịch sử giá vốn" mở từ SCR-003 (chỉ chủ cửa hàng).
Future<void> showCostVersionsSheet(
  BuildContext context, {
  required String productId,
}) {
  return showVAdaptiveSheet<void>(
    context: context,
    title: 'Lịch sử giá vốn',
    child: _CostVersionsSheetBody(productId: productId),
  );
}

class _CostVersionsSheetBody extends StatelessWidget {
  const _CostVersionsSheetBody({required this.productId});

  final String productId;

  CostingRepository _resolveRepo(BuildContext context) {
    try {
      return context.read<CostingRepository>();
    } catch (_) {
      return getIt<CostingRepository>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => CostVersionsCubit(_resolveRepo(ctx))..load(productId),
      child: BlocBuilder<CostVersionsCubit, CostVersionsState>(
        builder: (context, state) {
          final cubit = context.read<CostVersionsCubit>();

          Widget content;
          if (state.status == CostVersionsStatus.loading) {
            content = const InventoryLoading(
              blocks: [
                InventorySkeletonBlock.row,
                InventorySkeletonBlock.row,
                InventorySkeletonBlock.row,
              ],
            );
          } else if (state.status == CostVersionsStatus.error ||
              state.data == null) {
            content = InventoryEmpty(
              title: 'Không tải được lịch sử giá vốn',
              description: state.message ?? 'Kiểm tra kết nối rồi thử lại.',
              actionLabel: 'Thử lại',
              onAction: () => cubit.load(productId),
            );
          } else if (state.data!.versions.isEmpty) {
            content = VText(
              'Chưa có giá vốn chính thức',
              variant: VTextVariant.bodyDefault,
              color: context.vColors.textSecondary,
            );
          } else {
            final data = state.data!;
            content = Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: data.versions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: context.vColors.borderDefault,
                ),
                itemBuilder: (_, i) {
                  final v = data.versions[i];
                  return VListRow(
                    title: '${moneyWithSpace(v.unitCost.round())}/${data.uom}',
                    subtitle:
                        '${methodCopy(v.method).$1} · Công bố ${formatDateDdMmYyyy(v.publishedAt)} · ${v.runCode}',
                    onTap: null,
                  );
                },
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                const SizedBox(height: VSpacing.space4),
                VButton(
                  label: 'Đóng',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_cubit.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_rules.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

class StockThresholdSinglePage extends StatelessWidget {
  final String productId;

  const StockThresholdSinglePage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StockPolicyCubit(
        repository: getIt<StockPolicyRepository>(),
      )..load(),
      child: _StockThresholdSingleView(productId: productId),
    );
  }
}

class _StockThresholdSingleView extends StatefulWidget {
  final String productId;

  const _StockThresholdSingleView({required this.productId});

  @override
  State<_StockThresholdSingleView> createState() =>
      _StockThresholdSingleViewState();
}

class _StockThresholdSingleViewState extends State<_StockThresholdSingleView> {
  String? _threshold;
  String? _target;

  String _previewText(num available, bool hasExpired, bool hasNearExpiry) {
    final t = num.tryParse(_threshold?.trim() ?? '');
    final g = num.tryParse(_target?.trim() ?? '');
    if (t == null || g == null) return '';

    final inds = stockIndicators(
      available: available,
      threshold: t,
      hasExpired: hasExpired,
      hasNearExpiry: hasNearExpiry,
    );

    const checkOrder = [
      StockIndicator.out,
      StockIndicator.expired,
      StockIndicator.low,
      StockIndicator.nearExpiry,
    ];

    for (final ind in checkOrder) {
      if (inds.contains(ind)) {
        return ind.label;
      }
    }
    return 'Không có cảnh báo';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StockPolicyCubit>();
    final state = cubit.state;

    if (state.status == StockPolicyStatus.loading) {
      return const Scaffold(
        appBar: VAppBar(title: 'Đang tải...', showBackButton: true),
        body: Padding(
          padding: EdgeInsets.all(VSpacing.space4),
          child: InventoryLoading(),
        ),
      );
    }

    if (state.status == StockPolicyStatus.denied) {
      return Scaffold(
        appBar: const VAppBar(title: 'Ngưỡng tồn', showBackButton: true),
        body: Center(
          child: InventoryDenied(
            what: 'xem hoặc thay đổi chính sách tồn',
            next: 'Liên hệ chủ cửa hàng nếu cần.',
            onExit: () => context.go('/warehouse'),
          ),
        ),
      );
    }

    final product = state.snapshot?.products
        .where((p) => p.productId == widget.productId)
        .firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: const VAppBar(title: 'Không tìm thấy', showBackButton: true),
        body: const Center(
          child: Text('Sản phẩm không tồn tại.'),
        ),
      );
    }

    _threshold ??= product.threshold?.toString() ?? '';
    _target ??= product.target?.toString() ?? '';

    final curThreshold = _threshold!;
    final curTarget = _target!;

    final err = thresholdRowError(
      curThreshold,
      curTarget,
      configured: product.configured,
    );
    final isBlocked = singleBlocked(
      curThreshold,
      curTarget,
      configured: product.configured,
    );
    final preview = (!isBlocked && err == null)
        ? _previewText(
            product.available,
            product.hasExpired,
            product.hasNearExpiry,
          )
        : '';

    return Scaffold(
      appBar: VAppBar(
        title: product.name,
        subtitle: 'Ngưỡng tồn',
        showBackButton: true,
      ),
      bottomNavigationBar: state.readOnly
          ? null
          : Container(
              decoration: BoxDecoration(
                color: context.vColors.surface,
                border: Border(
                  top: BorderSide(color: context.vColors.borderDefault),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space4,
                    vertical: VSpacing.space3,
                  ),
                  child: Center(
                    heightFactor: 1.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: InventoryFooter(
                        actions: [
                          InventoryFooterAction(
                            label: 'Lưu',
                            primary: true,
                            onPressed: isBlocked
                                ? null
                                : () async {
                                    final ok = await cubit.saveSingle(
                                      widget.productId,
                                      curThreshold,
                                      curTarget,
                                    );
                                    if (ok && context.mounted) {
                                      VToast.show(
                                        context,
                                        title:
                                            'Đã lưu chính sách · Lần ${cubit.state.savedRevision ?? 1}',
                                        message: '',
                                        type: VToastType.success,
                                      );
                                      Navigator.of(context).pop(true);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!(state.snapshot?.isOwner ?? false)) ...[
                  const InventoryLocked(
                    title: 'Chỉ chủ cửa hàng thay đổi được chính sách.',
                    description: 'Bạn có thể xem các mức hiện tại.',
                  ),
                  const SizedBox(height: VSpacing.space3),
                ],
                Text(
                  'Khả dụng ${product.available} ${product.uom}',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: context.vColors.textPrimary,
                  ),
                ),
                const SizedBox(height: VSpacing.space3),
                Text(
                  'Ngưỡng cảnh báo',
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w600,
                    color: context.vColors.textPrimary,
                  ),
                ),
                const SizedBox(height: VSpacing.space1),
                K7EditCell(
                  value: curThreshold,
                  enabled: !state.readOnly,
                  unit: product.uom,
                  semanticLabel: 'Ngưỡng cảnh báo — ${product.name}',
                  onChanged: (val) => setState(() => _threshold = val),
                ),
                const SizedBox(height: VSpacing.space3),
                Text(
                  'Mức tồn mục tiêu',
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w600,
                    color: context.vColors.textPrimary,
                  ),
                ),
                const SizedBox(height: VSpacing.space1),
                K7EditCell(
                  value: curTarget,
                  enabled: !state.readOnly,
                  unit: product.uom,
                  errorText: err,
                  semanticLabel: 'Mức tồn mục tiêu — ${product.name}',
                  onChanged: (val) => setState(() => _target = val),
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: VSpacing.space3),
                  Text(
                    'Sau khi lưu: $preview',
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      color: context.vColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: VSpacing.space3),
                Text(
                  'Thay đổi chính sách không làm đổi số tồn.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 18 / 12,
                    color: context.vColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

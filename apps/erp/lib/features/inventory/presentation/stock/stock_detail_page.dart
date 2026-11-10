import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/logic/stock/stale_watcher.dart';
import 'package:erp/features/inventory/logic/stock/stock_detail_cubit.dart';
import 'package:erp/features/inventory/logic/stock/stock_detail_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/stock/stock_detail_body.dart';
import 'package:erp/features/inventory/presentation/stock/stock_list_page.dart';
import 'package:erp/features/inventory/presentation/stock/stock_provenance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class StockDetailPage extends StatelessWidget {
  final String productId;
  final String? initialName;
  final String? initialSubtitle;
  final StaleWatcher? stale;

  const StockDetailPage({
    super.key,
    required this.productId,
    this.initialName,
    this.initialSubtitle,
    this.stale,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StockDetailCubit(
        repository: getIt<StockRepository>(),
        stale: stale,
      )..load(productId),
      child: _StockDetailView(
        productId: productId,
        initialName: initialName,
        initialSubtitle: initialSubtitle,
      ),
    );
  }
}

class _StockDetailView extends StatefulWidget {
  final String productId;
  final String? initialName;
  final String? initialSubtitle;

  const _StockDetailView({
    required this.productId,
    this.initialName,
    this.initialSubtitle,
  });

  @override
  State<_StockDetailView> createState() => _StockDetailViewState();
}

class _StockDetailViewState extends State<_StockDetailView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<StockDetailCubit>().checkStale();
    }
  }

  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/warehouse/stock');
    }
  }

  Future<void> _editThreshold(BuildContext context, String productId) async {
    final cubit = context.read<StockDetailCubit>();
    final saved = await context.push<bool>(
      '/warehouse/stock-policy/product/$productId',
    );
    if (!mounted) return;
    if (saved == true) {
      await cubit.refresh();
    } else {
      cubit.checkStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StockDetailCubit>();
    final state = cubit.state;
    final isWide = inventoryIsWide(context);
    final detail = state.data;

    final isDenied = state.status == StockDetailStatus.denied;
    final title = isDenied
        ? 'Chi tiết tồn kho'
        : (detail?.name ?? widget.initialName ?? 'Chi tiết tồn kho');
    final subtitle = isDenied
        ? null
        : (detail != null
            ? '${detail.code} · ${detail.uom}'
            : widget.initialSubtitle);

    return Scaffold(
      appBar: VAppBar(
        title: title,
        subtitle: subtitle,
        showBackButton: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () => _back(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (isDenied) {
            return Center(
              child: InventoryDenied(
                what: 'xem tồn kho',
                next:
                    'Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần.',
                onExit: () => context.go('/warehouse'),
              ),
            );
          }

          if (state.status == StockDetailStatus.loading && detail == null) {
            return const Padding(
              padding: EdgeInsets.all(VSpacing.space4),
              child: InventoryLoading(
                blocks: [
                  InventorySkeletonBlock.card,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                ],
              ),
            );
          }

          if (state.status == StockDetailStatus.loadError && detail == null) {
            return Center(
              child: InventoryEmpty(
                title: 'Không thể tải chi tiết tồn kho',
                description: state.error?.userMessage() ??
                    'Đã có lỗi xảy ra khi tải dữ liệu.',
                actionLabel: 'Thử lại',
                onAction: () => cubit.load(widget.productId),
              ),
            );
          }

          if (detail == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 1160 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${detail.warehouseName} · Dữ liệu đến ${formatStockContextAsOf(detail.asOf)}',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 20 / 13,
                        color: Color(0xFF4A535E),
                      ),
                    ),
                    const SizedBox(height: VSpacing.space3),
                    if (state.stale) ...[
                      InventoryStale(
                        title: 'Dữ liệu có thể đã cũ',
                        description:
                            'Dữ liệu đến ${formatStockAsOfDot(detail.asOf)}. Hãy làm mới trước khi sử dụng.',
                        actionLabel: 'Làm mới',
                        onAction: cubit.refresh,
                      ),
                      const SizedBox(height: VSpacing.space3),
                    ],
                    StockDetailBody(
                      detail: detail,
                      onEditThreshold: () =>
                          _editThreshold(context, detail.productId),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:erp/core/di/injection.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_result_cubit.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_result_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k4_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _signedMoney(int vnd) {
  if (vnd > 0) return '+${MoneyFormatter.formatMinor(vnd)}';
  return MoneyFormatter.formatMinor(vnd);
}

/// SCR-047: Màn hình kết quả sau khi hoàn tất hoặc hủy phiên kiểm kê.
class StocktakeResultPage extends StatelessWidget {
  const StocktakeResultPage({
    super.key,
    required this.sessionId,
    required this.onBackToList,
    required this.onViewStock,
  });

  final String sessionId;
  final VoidCallback onBackToList;
  final VoidCallback onViewStock;

  StocktakeRepository _resolveRepo(BuildContext context) {
    try {
      return context.read<StocktakeRepository>();
    } catch (_) {
      return getIt<StocktakeRepository>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StocktakeResultCubit(
        repository: _resolveRepo(context),
        sessionId: sessionId,
      )..load(),
      child: _StocktakeResultView(
        onBackToList: onBackToList,
        onViewStock: onViewStock,
      ),
    );
  }
}

class _StocktakeResultView extends StatelessWidget {
  const _StocktakeResultView({
    required this.onBackToList,
    required this.onViewStock,
  });

  final VoidCallback onBackToList;
  final VoidCallback onViewStock;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StocktakeResultCubit>();
    final state = cubit.state;
    final session = state.session;

    if (state.status == StocktakeResultLoadStatus.loading) {
      return const VPageScaffold(
        title: 'Kết quả kiểm kê',
        showBackButton: false,
        body: Padding(
          padding: EdgeInsets.all(VSpacing.space4),
          child: InventoryLoading(
            blocks: [
              InventorySkeletonBlock.text,
              InventorySkeletonBlock.card,
              InventorySkeletonBlock.row,
            ],
          ),
        ),
      );
    }

    if (state.status == StocktakeResultLoadStatus.error || session == null) {
      return VPageScaffold(
        title: 'Kết quả kiểm kê',
        showBackButton: false,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: InventoryEmpty(
              title: 'Không tải được kết quả kiểm kê',
              description: 'Kiểm tra kết nối rồi thử lại.',
              actionLabel: 'Thử lại',
              onAction: cubit.load,
            ),
          ),
        ),
      );
    }

    if (session.status == StocktakeStatus.cancelled) {
      return K4ResultPage(
        screenTitle: 'Kết quả kiểm kê',
        kind: K4Kind.warning,
        title: 'Đã hủy phiên',
        description: 'Không tạo điều chỉnh. Lịch sử đếm được giữ.',
        facts: [
          VKeyValueRow(label: 'Phiên', value: session.code, mono: true),
          VKeyValueRow(label: 'Phạm vi', value: session.scopeLabel),
          VKeyValueRow(
            label: 'Lý do',
            value: (session.cancelReason != null &&
                    session.cancelReason!.isNotEmpty)
                ? session.cancelReason!
                : '—',
          ),
          if (session.cancelledAt != null)
            VKeyValueRow(
              label: 'Thời điểm',
              value: _formatDateTime(session.cancelledAt!),
              mono: true,
            ),
        ],
        next: [
          InventoryFooterAction(
            label: 'Về kiểm kê',
            primary: true,
            onPressed: onBackToList,
          ),
        ],
      );
    }

    if (session.resultKind == StocktakeResultKind.matched) {
      return K4ResultPage(
        screenTitle: 'Kết quả kiểm kê',
        kind: K4Kind.success,
        title: 'Đã hoàn tất kiểm kê',
        description: 'Kết quả thực tế khớp số sổ. Không cần tạo điều chỉnh.',
        facts: [
          VKeyValueRow(label: 'Phiên', value: session.code, mono: true),
          VKeyValueRow(label: 'Phạm vi', value: session.scopeLabel),
          if (session.completedAt != null)
            VKeyValueRow(
              label: 'Hoàn tất lúc',
              value: _formatDateTime(session.completedAt!),
              mono: true,
            ),
        ],
        next: [
          InventoryFooterAction(
            label: 'Về kiểm kê',
            onPressed: onBackToList,
          ),
          InventoryFooterAction(
            label: 'Xem tồn kho',
            primary: true,
            onPressed: onViewStock,
          ),
        ],
      );
    }

    final adjustedLines = session.lines
        .where((l) => (l.adjustQty ?? 0) != 0)
        .toList(growable: false);
    final shortCount = adjustedLines.where((l) => l.adjustQty! < 0).length;
    final overCount = adjustedLines.where((l) => l.adjustQty! > 0).length;
    final stockChanges = session.stockChanges.map((sc) {
      final unitSuffix =
          sc.baseUom.trim().isNotEmpty ? ' ${sc.baseUom.trim()}' : '';
      return K4StockChange(
        product: sc.productName,
        before: '${formatQuantity(sc.before.toDouble())}$unitSuffix',
        after: '${formatQuantity(sc.after.toDouble())}$unitSuffix',
      );
    }).toList(growable: false);

    return K4ResultPage(
      screenTitle: 'Kết quả kiểm kê',
      kind: K4Kind.success,
      title: 'Đã hoàn tất kiểm kê',
      description: 'Điều chỉnh chênh lệch đã được ghi vào tồn kho.',
      facts: [
        VKeyValueRow(label: 'Phiên', value: session.code, mono: true),
        VKeyValueRow(label: 'Phạm vi', value: session.scopeLabel),
        VKeyValueRow(
          label: 'Đã điều chỉnh',
          value: '${adjustedLines.length} dòng',
          mono: true,
        ),
        VKeyValueRow(
          label: 'Thiếu / thừa',
          value: 'Thiếu $shortCount · thừa $overCount mặt hàng',
        ),
        if (session.adjustmentValueVnd != null)
          VKeyValueRow(
            label: 'Giá trị điều chỉnh',
            value: _signedMoney(session.adjustmentValueVnd!),
            mono: true,
          ),
        VKeyValueRow(
          label: 'Người ghi nhận',
          value: session.completedByName ?? '—',
        ),
        if (session.completedAt != null)
          VKeyValueRow(
            label: 'Ghi nhận lúc',
            value: _formatDateTime(session.completedAt!),
            mono: true,
          ),
      ],
      stockChanges: stockChanges,
      next: [
        InventoryFooterAction(
          label: 'Về kiểm kê',
          onPressed: onBackToList,
        ),
        InventoryFooterAction(
          label: 'Xem tồn kho',
          primary: true,
          onPressed: onViewStock,
        ),
      ],
    );
  }
}


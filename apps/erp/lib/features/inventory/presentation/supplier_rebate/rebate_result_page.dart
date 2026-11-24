import 'package:erp/core/di/injection.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_detail_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_detail_state.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k4_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

String _moneyOrDash(int? vnd) =>
    vnd == null ? '—' : '${MoneyFormatter.formatMinorPlain(vnd)} đ';

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
}

/// Màn kết quả sau khi ghi nhận chiết khấu đạt mốc (K4).
class RebateResultPage extends StatelessWidget {
  const RebateResultPage({
    super.key,
    required this.programId,
    this.previewInventoryTotal,
  });

  final String programId;
  final int? previewInventoryTotal;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProgramDetailCubit(
        repository: getIt<SupplierProgramRepository>(),
      )..load(programId),
      child: _RebateResultView(
        programId: programId,
        previewInventoryTotal: previewInventoryTotal,
      ),
    );
  }
}

class _RebateResultView extends StatelessWidget {
  const _RebateResultView({
    required this.programId,
    this.previewInventoryTotal,
  });

  final String programId;
  final int? previewInventoryTotal;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ProgramDetailCubit>();
    final state = cubit.state;
    final detail = state.data;
    final rebate = detail?.rebate;

    if (state.status == ProgramDetailStatus.loading) {
      return const VPageScaffold(
        title: 'Kết quả',
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

    if (state.status != ProgramDetailStatus.ready ||
        detail == null ||
        rebate == null) {
      return VPageScaffold(
        title: 'Kết quả',
        showBackButton: false,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: InventoryEmpty(
              title: 'Không tải được kết quả chiết khấu',
              description: 'Kiểm tra kết nối rồi thử lại.',
              actionLabel: 'Thử lại',
              onAction: cubit.refresh,
            ),
          ),
        ),
      );
    }

    final row = detail.row;
    final colors = context.vColors;
    final facts = <VKeyValueRow>[
      VKeyValueRow(
        label: 'Giảm giá trị tồn',
        value: _moneyOrDash(rebate.inventoryPartVnd),
        mono: true,
      ),
      VKeyValueRow(
        label: 'Giảm giá vốn hàng đã bán',
        value: _moneyOrDash(rebate.cogsPartVnd),
        mono: true,
      ),
      VKeyValueRow(
        label: 'Chứng từ',
        value: '${rebate.documentNo} · ${_formatDate(rebate.documentDate)}',
        mono: true,
      ),
    ];

    final stockChanges = [
      for (final a in rebate.allocations)
        if (a.avgCostBefore != null &&
            a.avgCostAfter != null &&
            a.avgCostAfter != a.avgCostBefore)
          K4StockChange(
            product: a.name,
            before: _avgCostSingle(a.avgCostBefore!, a.uom),
            after: _avgCostSingle(a.avgCostAfter!, a.uom),
          ),
    ];

    final changed = rebate.inventoryPartVnd != null &&
        stockChangedSincePreview(
          previewInventoryTotal,
          rebate.inventoryPartVnd!,
        );

    return K4ResultPage(
      screenTitle: 'Kết quả',
      kind: K4Kind.success,
      title: 'Đã ghi nhận chiết khấu',
      description:
          '${_moneyOrDash(rebate.rebateAmountVnd)} từ ${row.supplierName} cho chương trình "${row.name}".',
      facts: facts,
      stockChanges: stockChanges,
      extra: changed
          ? VText(
              'Tồn đã đổi từ lúc xem trước, số đã tính lại theo tồn hiện tại.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
              textAlign: TextAlign.center,
            )
          : null,
      next: [
        InventoryFooterAction(
          label: 'Về Kho',
          onPressed: () => context.go('/warehouse'),
        ),
        InventoryFooterAction(
          label: 'Xem chương trình',
          primary: true,
          onPressed: () =>
              context.go('/warehouse/supplier-programs/$programId'),
        ),
      ],
    );
  }

  String _avgCostSingle(num value, String uom) {
    final perUom = uom.trim().isNotEmpty ? '/${uom.trim()}' : '';
    return '${MoneyFormatter.formatMinorPlain(value.round())} đ$perUom';
  }
}


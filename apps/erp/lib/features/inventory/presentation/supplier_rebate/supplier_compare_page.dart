import 'package:erp/core/di/injection.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/supplier_compare_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/supplier_compare_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k6_task_list.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_row_below.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

/// Màn so sánh nhà cung cấp theo sản phẩm (P5).
class SupplierComparePage extends StatelessWidget {
  const SupplierComparePage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupplierCompareCubit(
        rebates: getIt<SupplierRebateRepository>(),
        productId: productId,
      )..load(),
      child: _SupplierCompareView(productId: productId),
    );
  }
}

class _SupplierCompareView extends StatelessWidget {
  const _SupplierCompareView({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierCompareCubit, SupplierCompareState>(
      builder: (context, state) {
        final subtitle = switch (state) {
          SupplierCompareLoaded(:final data) => data.name,
          _ => null,
        };

        return VPageScaffold(
          title: 'So sánh nhà cung cấp',
          subtitle: subtitle,
          contentMaxWidth: VPageScaffold.fullWidth,
          leading: context.canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Quay lại',
                  onPressed: () => context.pop(),
                )
              : null,
          body: switch (state) {
            SupplierCompareLoading() => const Center(
              child: InventoryLoading(),
            ),
            SupplierCompareError() => InventoryEmpty(
              title: 'Không tải được so sánh',
              description: 'Kiểm tra kết nối rồi thử lại.',
              actionLabel: 'Thử lại',
              onAction: () => context.read<SupplierCompareCubit>().load(),
            ),
            SupplierCompareLoaded(:final data, :final cheapestId) =>
              data.suppliers.isEmpty
                  ? const InventoryEmpty(
                      title: 'Chưa nhập sản phẩm này từ nhà cung cấp nào.',
                      description: '',
                    )
                  : _CompareContent(
                      productId: productId,
                      data: data,
                      cheapestId: cheapestId,
                    ),
          },
        );
      },
    );
  }
}

class _CompareContent extends StatelessWidget {
  const _CompareContent({
    required this.productId,
    required this.data,
    required this.cheapestId,
  });

  final String productId;
  final SupplierCompare data;
  final String? cheapestId;

  String _formatUnitMoney(num value) =>
      '${MoneyFormatter.formatMinorPlain(value.round())} đ/${data.uom}';

  String _formatDateDdMm(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  String _lastCostLabel(SupplierCompareRow row) {
    final cost = row.lastLandedUnitCost;
    if (cost == null) return '—';
    final base = _formatUnitMoney(cost);
    final on = row.lastReceivedOn;
    return on == null ? base : '$base (${_formatDateDdMm(on)})';
  }

  String _avgCostLabel(SupplierCompareRow row) {
    final cost = row.avgLandedUnitCost;
    if (cost == null) return '—';
    return _formatUnitMoney(cost);
  }

  void _openProgram(BuildContext context, String programId) {
    context.push('/warehouse/supplier-programs/${Uri.encodeComponent(programId)}');
  }

  Future<void> _addOffer(BuildContext context, String supplierId) async {
    await context.push(
      '/warehouse/supplier-programs/new'
      '?supplierId=${Uri.encodeQueryComponent(supplierId)}'
      '&productId=${Uri.encodeQueryComponent(productId)}',
    );
    if (context.mounted) {
      context.read<SupplierCompareCubit>().load();
    }
  }

  Widget _buildSupplierName(BuildContext context, SupplierCompareRow row) {
    final isCheapest = cheapestId != null && cheapestId == row.partnerId;
    if (!isCheapest) {
      return VText(
        row.name,
        variant: VTextVariant.bodyDefault,
        style: const TextStyle(fontWeight: FontWeight.w600),
      );
    }
    return Wrap(
      spacing: VSpacing.space2,
      runSpacing: VSpacing.space1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        VText(
          row.name,
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const VBadge(
          label: 'Rẻ nhất',
          tone: VComponentTone.success,
        ),
      ],
    );
  }

  Widget _buildOfferBlock(BuildContext context, SupplierCompareRow row) {
    final colors = context.vColors;
    if (row.isSystem) {
      return VText(
        '—',
        variant: VTextVariant.bodySmall,
        color: colors.textSecondary,
      );
    }
    final program = row.program;
    if (program != null) {
      return K6TaskRow(
        title: program.name,
        subtitle: programKindShort(program.kind),
        status: K6Status(
          label: programStatusLabel(program.status),
          tone: programStatusTone(program.status),
        ),
        below: ProgramRowBelow(program),
        onTap: () => _openProgram(context, program.id),
      );
    }
    final other = row.otherProgram;
    if (other != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          VText(
            'Đang có chương trình khác: ${other.name}',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space1),
          VButton(
            variant: VButtonVariant.link,
            size: VButtonSize.small,
            label: 'Xem chương trình',
            onPressed: () => _openProgram(context, other.id),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        VText(
          'Ưu đãi: Không có',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const SizedBox(height: VSpacing.space1),
        VButton(
          label: 'Thêm ưu đãi',
          variant: VButtonVariant.tertiary,
          size: VButtonSize.small,
          leading: VIcons.add,
          onPressed: () => _addOffer(context, row.partnerId),
        ),
      ],
    );
  }

  Widget _buildMobileCard(BuildContext context, SupplierCompareRow row) {
    final colors = context.vColors;
    final paid = formatProgramQuantity(row.paidQty);
    final free = formatProgramQuantity(row.freeQty);

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSupplierName(context, row),
          const SizedBox(height: VSpacing.space3),
          VKeyValueRow(
            label: 'Giá gốc gần nhất',
            value: _lastCostLabel(row),
          ),
          const SizedBox(height: VSpacing.space1),
          VKeyValueRow(
            label: 'Bình quân giá gốc',
            value: _avgCostLabel(row),
          ),
          const SizedBox(height: VSpacing.space2),
          VText(
            '${row.receiptCount} lần nhập · mua $paid · tặng $free ${data.uom}',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          if (!row.isSystem) ...[
            const SizedBox(height: VSpacing.space3),
            const VDivider(),
            const SizedBox(height: VSpacing.space3),
            _buildOfferBlock(context, row),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isWide = inventoryIsWide(context);
    final pagePadding = isWide
        ? const EdgeInsets.all(VSpacing.space6)
        : const EdgeInsets.all(VSpacing.space4);

    return SingleChildScrollView(
      padding: pagePadding,
      child: VContentWidth(
        maxWidth: const VResponsiveValue(
          mobile: double.infinity,
          tablet: 960,
          desktop: 1120,
        ),
        child: K7Table<SupplierCompareRow>(
            rows: data.suppliers,
            columnWidths: const {
              0: FixedColumnWidth(145),
              1: FixedColumnWidth(145),
              2: FixedColumnWidth(125),
              3: FixedColumnWidth(85),
              4: FixedColumnWidth(125),
              5: FixedColumnWidth(295),
            },
            columns: [
              K7Column(
                label: 'Nhà cung cấp',
                cell: (row) => _buildSupplierName(context, row),
              ),
              K7Column(
                label: 'Giá gốc gần nhất',
                cell: (row) => VText(
                  _lastCostLabel(row),
                  variant: VTextVariant.bodySmall,
                ),
              ),
              K7Column(
                label: 'Bình quân giá gốc',
                cell: (row) => VText(
                  _avgCostLabel(row),
                  variant: VTextVariant.bodySmall,
                ),
              ),
              K7Column(
                label: 'Số lần nhập',
                numeric: true,
                cell: (row) => VText(
                  '${row.receiptCount}',
                  variant: VTextVariant.bodySmall,
                ),
              ),
              K7Column(
                label: 'SL mua / tặng',
                cell: (row) => VText(
                  '${formatProgramQuantity(row.paidQty)} / '
                  '${formatProgramQuantity(row.freeQty)} ${data.uom}',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ),
              K7Column(
                label: 'Ưu đãi',
                cell: (row) => _buildOfferBlock(context, row),
              ),
            ],
            mobileRow: (row) => _buildMobileCard(context, row),
          ),
        ),
      );
  }
}

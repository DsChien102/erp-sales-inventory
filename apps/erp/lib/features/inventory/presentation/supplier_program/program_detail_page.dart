import 'package:erp/core/di/injection.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_detail_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_detail_state.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_end_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class ProgramDetailPage extends StatelessWidget {
  final String programId;
  final List<Widget> Function(ProgramDetail)? extraSections;

  const ProgramDetailPage({
    super.key,
    required this.programId,
    this.extraSections,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProgramDetailCubit(
        repository: getIt<SupplierProgramRepository>(),
      )..load(programId),
      child: _ProgramDetailView(
        programId: programId,
        extraSections: extraSections,
      ),
    );
  }
}

class _ProgramDetailView extends StatelessWidget {
  final String programId;
  final List<Widget> Function(ProgramDetail)? extraSections;

  const _ProgramDetailView({
    required this.programId,
    this.extraSections,
  });

  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/warehouse/supplier-programs');
    }
  }

  Future<void> _onEdit(BuildContext context, ProgramDetailCubit cubit) async {
    await context.push('/warehouse/supplier-programs/$programId/edit');
    if (context.mounted) {
      await cubit.refresh();
    }
  }

  Future<void> _onEnd(
    BuildContext context,
    ProgramDetailCubit cubit,
    ProgramDetail detail,
  ) async {
    final confirmed = await showProgramEndSheet(
      context,
      programName: detail.row.name,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await cubit.end();
    if (!context.mounted) return;
    if (ok) {
      VToast.show(
        context,
        title: 'Đã kết thúc chương trình',
        message: '',
        type: VToastType.success,
      );
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _formatMoney(int vnd) => '${MoneyFormatter.formatMinorPlain(vnd)} đ';

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ProgramDetailCubit>();
    final state = cubit.state;
    final detail = state.data;
    final title = detail?.row.name ?? 'Chi tiết chương trình';

    final actions = <InventoryFooterAction>[
      if (state.canEnd)
        InventoryFooterAction(
          label: 'Kết thúc chương trình',
          onPressed: state.ending || detail == null
              ? null
              : () => _onEnd(context, cubit, detail),
        ),
      if (state.canEdit)
        InventoryFooterAction(
          label: 'Sửa',
          primary: true,
          onPressed: state.ending ? null : () => _onEdit(context, cubit),
        ),
    ];

    return VPageScaffold(
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _back(context),
      ),
      bottomBar: state.status == ProgramDetailStatus.ready && actions.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              child: InventoryFooter(actions: actions),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (state.status == ProgramDetailStatus.loading) {
            return const Padding(
              padding: EdgeInsets.all(VSpacing.space4),
              child: InventoryLoading(
                blocks: [
                  InventorySkeletonBlock.card,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                ],
              ),
            );
          }

          if (state.status == ProgramDetailStatus.notFound) {
            return Center(
              child: InventoryEmpty(
                title: 'Không tìm thấy chương trình',
                description: '',
                actionLabel: 'Về danh sách',
                onAction: () => context.go('/warehouse/supplier-programs'),
              ),
            );
          }

          if (state.status == ProgramDetailStatus.loadError || detail == null) {
            return Center(
              child: InventoryEmpty(
                title: 'Không tải được chương trình',
                description: 'Kiểm tra kết nối rồi thử lại.',
                actionLabel: 'Thử lại',
                onAction: cubit.refresh,
              ),
            );
          }

          final row = detail.row;
          final colors = context.vColors;
          final uom = row.commonUom;
          final uomSuffix =
              (uom != null && uom.trim().isNotEmpty) ? ' ${uom.trim()}' : '';
          final extra = extraSections?.call(detail) ?? const <Widget>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: VContentWidth(
              maxWidth: const VResponsiveValue<double>(
                mobile: double.infinity,
                tablet: 640,
                desktop: 720,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.versionConflict && state.actionError != null) ...[
                    InventoryStale(
                      title: state.actionError!,
                      description: '',
                      actionLabel: 'Tải lại',
                      onAction: cubit.refresh,
                    ),
                    const SizedBox(height: VSpacing.space3),
                  ] else if (state.actionError != null) ...[
                    VBanner(
                      tone: VComponentTone.danger,
                      title: state.actionError!,
                    ),
                    const SizedBox(height: VSpacing.space3),
                  ],

                  // Đầu: tên + badge trạng thái
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: VText(
                          row.name,
                          variant: VTextVariant.headingH4,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: VSpacing.space2),
                      VBadge(
                        label: programStatusLabel(row.status),
                        tone: programStatusTone(row.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.space4),

                  // 1. Thông tin
                  VSection(
                    title: 'Thông tin',
                    child: VKeyValueGroup(
                      rows: [
                        InkWell(
                          onTap: () =>
                              context.push('/partner/${row.supplierId}'),
                          child: VKeyValueRow(
                            label: 'Nhà cung cấp',
                            value: row.supplierName,
                            trailing: VIcon(
                              icon: VIcons.chevronRight,
                              size: 16,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        VKeyValueRow(
                          label: 'Loại',
                          value: programKindShort(row.kind),
                        ),
                        VKeyValueRow(
                          label: 'Bắt đầu',
                          value: _formatDate(row.startedOn),
                        ),
                        if (row.status == ProgramStatus.ended &&
                            detail.endedAt != null)
                          VKeyValueRow(
                            label: 'Kết thúc',
                            value: _formatDate(detail.endedAt!),
                          ),
                        VKeyValueRow(
                          label: 'Ưu đãi',
                          value: programSummary(row),
                        ),
                        if (detail.note != null &&
                            detail.note!.trim().isNotEmpty)
                          VKeyValueRow(
                            label: 'Ghi chú',
                            value: detail.note!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpacing.space4),

                  // 2. Sản phẩm áp dụng ({n})
                  VSection(
                    title: 'Sản phẩm áp dụng (${detail.products.length})',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final p in detail.products) ...[
                          VListRow(
                            title: p.name,
                            subtitle: '${p.code} · ${p.baseUom}',
                            type: VListRowType.navigation,
                            onTap: () => context.push(
                              '/warehouse/stock/${p.productId}',
                            ),
                          ),
                          const SizedBox(height: VSpacing.space1),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpacing.space4),

                  // 3. Bậc giảm giá (loại 1) hoặc Tiến độ (loại 3)
                  if (row.kind == ProgramKind.tierDiscount) ...[
                    VSection(
                      title: 'Bậc giảm giá',
                      child: VKeyValueGroup(
                        rows: [
                          for (final t in row.tiers)
                            VKeyValueRow(
                              label:
                                  'Từ ${formatProgramQuantity(t.minQty)}$uomSuffix',
                              value: '${formatPercent(t.discountPercent)}%',
                              mono: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: VSpacing.space4),
                  ] else if (row.kind == ProgramKind.volumeRebate) ...[
                    VSection(
                      title: 'Tiến độ',
                      child: Builder(
                        builder: (context) {
                          final target = row.targetQty ?? 0;
                          final progress = row.progressQty;
                          final ratio = target > 0
                              ? (progress / target).clamp(0.0, 1.0).toDouble()
                              : 0.0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (row.status == ProgramStatus.reached) ...[
                                const VBanner(
                                  tone: VComponentTone.warning,
                                  title:
                                      'Đã đạt mốc, chờ ghi nhận chiết khấu',
                                ),
                                const SizedBox(height: VSpacing.space3),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: VProgress(value: ratio),
                                  ),
                                  const SizedBox(width: VSpacing.space3),
                                  VText(
                                    '${formatProgramQuantity(progress)} / ${formatProgramQuantity(target)}$uomSuffix',
                                    variant: VTextVariant.bodySmallMono,
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: VSpacing.space3),
                              VKeyValueGroup(
                                rows: [
                                  VKeyValueRow(
                                    label: 'Căn cứ chiết khấu',
                                    value: _formatMoney(detail.baseAmountVnd),
                                    mono: true,
                                  ),
                                  for (final r in detail.receipts)
                                    VKeyValueRow(
                                      label: _formatDate(r.createdAt),
                                      value:
                                          '${formatProgramQuantity(r.paidQty)}$uomSuffix · ${_formatMoney(r.purchaseAmountVnd)}',
                                      mono: true,
                                    ),
                                ],
                              ),
                              if (detail.receipts.isEmpty) ...[
                                const SizedBox(height: VSpacing.space2),
                                VText(
                                  'Phiếu đã tính: Chưa có phiếu nhận.',
                                  variant: VTextVariant.bodySmall,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: VSpacing.space4),
                  ],

                  for (final s in extra) ...[
                    s,
                    const SizedBox(height: VSpacing.space4),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

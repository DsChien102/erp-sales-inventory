import 'package:erp/core/di/injection.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/projected_cost_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/projected_cost_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

/// Khối "Giá vốn dự kiến" trên P3 cho chương trình loại 3 đang chạy (ACTIVE).
class ProjectedCostSection extends StatelessWidget {
  const ProjectedCostSection({
    super.key,
    required this.programId,
    required this.products,
  });

  final String programId;
  final List<ProgramProduct> products;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectedCostCubit(
        rebates: getIt<SupplierRebateRepository>(),
        programId: programId,
        products: products,
      )..load(),
      child: _ProjectedCostView(products: products),
    );
  }
}

class _ProjectedCostView extends StatefulWidget {
  const _ProjectedCostView({required this.products});

  final List<ProgramProduct> products;

  @override
  State<_ProjectedCostView> createState() => _ProjectedCostViewState();
}

class _ProjectedCostViewState extends State<_ProjectedCostView> {
  final _extraController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _extraController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _syncControllers(ProjectedCostState state) {
    if (_extraController.text != state.extraText) {
      _extraController.text = state.extraText;
    }
    if (_priceController.text != state.priceText) {
      _priceController.text = state.priceText;
    }
  }

  String _resolveUom(ProjectedCostState state) {
    final resUom = state.result?.uom.trim();
    if (resUom != null && resUom.isNotEmpty) return resUom;
    for (final p in widget.products) {
      if (p.productId == state.productId && p.baseUom.trim().isNotEmpty) {
        return p.baseUom.trim();
      }
    }
    return '';
  }

  bool _hasPositiveExtra(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return false;
    final parsed = num.tryParse(normalized);
    return parsed != null && parsed > 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectedCostCubit, ProjectedCostState>(
      builder: (context, state) {
        _syncControllers(state);
        final cubit = context.read<ProjectedCostCubit>();
        final colors = context.vColors;
        final res = state.result;
        final uom = _resolveUom(state);
        final uomWithSpace = uom.isNotEmpty ? ' $uom' : '';
        final perUom = uom.isNotEmpty ? '/$uom' : '';
        final hasExtra = _hasPositiveExtra(state.extraText);

        return VSection(
          title: 'Giá vốn dự kiến',
          trailing: const VBadge(
            label: 'Dự kiến, chưa ghi sổ',
            tone: VComponentTone.neutral,
          ),
          child: state.error
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(
                      'Không tính được giá vốn dự kiến.',
                      variant: VTextVariant.bodySmall,
                      color: colors.danger,
                    ),
                    const SizedBox(height: VSpacing.space1),
                    VButton(
                      label: 'Thử lại',
                      variant: VButtonVariant.tertiary,
                      onPressed: cubit.load,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.products.length > 1) ...[
                      VField(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const VFieldLabel('Sản phẩm'),
                            VSelect<String>(
                              value: state.productId.isEmpty
                                  ? null
                                  : state.productId,
                              items: [
                                for (final p in widget.products)
                                  DropdownMenuItem<String>(
                                    value: p.productId,
                                    child: Text(p.name),
                                  ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  cubit.selectProduct(val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: VSpacing.space3),
                    ],
                    VField(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VFieldLabel('Mua thêm'),
                          VTextField(
                            controller: _extraController,
                            suffixText: uom.isNotEmpty ? uom : null,
                            keyboardType: TextInputType.number,
                            onChanged: cubit.setExtraQty,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: VSpacing.space3),
                    VField(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VFieldLabel('Đơn giá'),
                          VTextField(
                            controller: _priceController,
                            suffixText: uom.isNotEmpty ? 'đ/$uom' : 'đ',
                            keyboardType: TextInputType.number,
                            onChanged: cubit.setUnitPrice,
                          ),
                          const VFieldDescription('Gồm VAT'),
                        ],
                      ),
                    ),
                    if (res != null &&
                        hasExtra &&
                        res.reachesTarget != null) ...[
                      const SizedBox(height: VSpacing.space3),
                      if (res.reachesTarget == true)
                        Row(
                          children: [
                            VIcon(
                              icon: VIcons.success,
                              size: 16,
                              color: colors.success,
                            ),
                            const SizedBox(width: VSpacing.space1),
                            Expanded(
                              child: VText(
                                'Đạt mốc ${formatProgramQuantity(res.targetQty)}'
                                '$uomWithSpace sau lần mua này',
                                variant: VTextVariant.bodySmall,
                                tone: VComponentTone.success,
                              ),
                            ),
                          ],
                        )
                      else
                        VText(
                          'Còn thiếu ${formatProgramQuantity(res.missingQty)}'
                          '$uomWithSpace để đạt mốc',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                    ],
                    if (res != null) ...[
                      const SizedBox(height: VSpacing.space3),
                      VKeyValueGroup(
                        rows: [
                          if (hasExtra && res.reachesTarget == true)
                            VKeyValueRow(
                              label: 'Chiết khấu ước tính',
                              value: res.financialMasked ||
                                      res.rebateEstimate == null
                                  ? '—'
                                  : '${MoneyFormatter.formatMinorPlain(res.rebateEstimate!)} đ',
                              mono: true,
                            ),
                          VKeyValueRow(
                            label: 'Bình quân hiện tại',
                            value: res.financialMasked || res.avgNow == null
                                ? '—'
                                : '${MoneyFormatter.formatMinorPlain(res.avgNow!.round())} đ$perUom',
                            mono: true,
                          ),
                          VKeyValueRow(
                            label: 'Bình quân dự kiến',
                            value:
                                res.financialMasked || res.avgProjected == null
                                    ? '—'
                                    : '${MoneyFormatter.formatMinorPlain(res.avgProjected!.round())} đ$perUom',
                            mono: true,
                          ),
                        ],
                      ),
                    ] else if (state.loading) ...[
                      const SizedBox(height: VSpacing.space3),
                      const VSkeleton(
                        width: double.infinity,
                        height: 64,
                        borderRadius: VRadius.r12,
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

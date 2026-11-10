import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/k6_task_list.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_row_below.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class SupplierProgramsSection extends StatefulWidget {
  final String partnerId;

  const SupplierProgramsSection({
    super.key,
    required this.partnerId,
  });

  @override
  State<SupplierProgramsSection> createState() =>
      _SupplierProgramsSectionState();
}

class _SupplierProgramsSectionState extends State<SupplierProgramsSection> {
  bool _loading = true;
  bool _hasError = false;
  List<ProgramRow> _programs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SupplierProgramsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partnerId != widget.partnerId) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<SupplierProgramRepository>()) {
      setState(() {
        _programs = const [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final all = await getIt<SupplierProgramRepository>().list();
      final effective = all
          .where(
            (r) =>
                r.supplierId == widget.partnerId &&
                (r.status == ProgramStatus.active ||
                    r.status == ProgramStatus.reached),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _programs = effective;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<SupplierProgramRepository>()) {
      return const SizedBox.shrink();
    }
    final colors = context.vColors;

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: VText(
                  'Chương trình ưu đãi',
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              InkWell(
                onTap: () async {
                  await context.push(
                    '/warehouse/supplier-programs?supplierId=${widget.partnerId}',
                  );
                  if (mounted) _load();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(
                      'Xem tất cả',
                      variant: VTextVariant.bodySmall,
                      color: colors.primary,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: VSpacing.space1),
                    VIcon(
                      icon: VIcons.chevronRight,
                      size: 16,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space3),
          if (_loading)
            const VSkeleton(height: 44, width: double.infinity)
          else if (_hasError)
            Row(
              children: [
                Expanded(
                  child: VText(
                    'Không tải được chương trình ưu đãi.',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ),
                VButton(
                  label: 'Thử lại',
                  variant: VButtonVariant.tertiary,
                  onPressed: _load,
                ),
              ],
            )
          else if (_programs.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(
                  'Chưa có chương trình đang chạy.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: VSpacing.space2),
                VButton(
                  label: 'Tạo chương trình',
                  variant: VButtonVariant.tertiary,
                  leading: VIcons.add,
                  onPressed: () async {
                    await context.push(
                      '/warehouse/supplier-programs/new?supplierId=${widget.partnerId}',
                    );
                    if (mounted) _load();
                  },
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _programs.length; i++) ...[
                  K6TaskRow(
                    title: _programs[i].name,
                    subtitle: programKindShort(_programs[i].kind),
                    status: K6Status(
                      label: programStatusLabel(_programs[i].status),
                      tone: programStatusTone(_programs[i].status),
                    ),
                    below: ProgramRowBelow(_programs[i]),
                    onTap: () async {
                      await context.push(
                        '/warehouse/supplier-programs/${_programs[i].id}',
                      );
                      if (mounted) _load();
                    },
                  ),
                  if (i < _programs.length - 1)
                    const SizedBox(height: VSpacing.space2),
                ],
              ],
            ),
        ],
      ),
    );
  }
}


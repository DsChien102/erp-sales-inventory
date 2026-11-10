import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_draft.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_state.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_end_sheet.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_product_picker_sheet.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_tier_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class ProgramFormPage extends StatelessWidget {
  final String? supplierId;
  final String? programId;

  const ProgramFormPage.create({
    super.key,
    this.supplierId,
  }) : programId = null;

  const ProgramFormPage.edit({
    super.key,
    required String this.programId,
  }) : supplierId = null;

  bool get isEdit => programId != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ProgramFormCubit(
          repository: getIt<SupplierProgramRepository>(),
        );
        if (programId != null) {
          cubit.startEdit(programId!);
        } else {
          cubit.startCreate(supplierId: supplierId);
        }
        return cubit;
      },
      child: _ProgramFormView(isEdit: isEdit),
    );
  }
}

class _ProgramFormView extends StatefulWidget {
  final bool isEdit;

  const _ProgramFormView({required this.isEdit});

  @override
  State<_ProgramFormView> createState() => _ProgramFormViewState();
}

class _ProgramFormViewState extends State<_ProgramFormView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _supplierKey = GlobalKey();
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _productsKey = GlobalKey();
  final GlobalKey _paramsKey = GlobalKey();
  final GlobalKey _startedOnKey = GlobalKey();

  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late final TextEditingController _buyQtyController;
  late final TextEditingController _freeQtyController;
  late final TextEditingController _targetQtyController;
  late final TextEditingController _rebatePctController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _noteController = TextEditingController();
    _buyQtyController = TextEditingController();
    _freeQtyController = TextEditingController();
    _targetQtyController = TextEditingController();
    _rebatePctController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    _buyQtyController.dispose();
    _freeQtyController.dispose();
    _targetQtyController.dispose();
    _rebatePctController.dispose();
    super.dispose();
  }

  void _syncControllers(ProgramFormDraft draft) {
    if (_nameController.text != draft.name) {
      _nameController.text = draft.name;
    }
    if (_noteController.text != draft.note) {
      _noteController.text = draft.note;
    }
    if (ProgramFormDraft.parseNum(_buyQtyController.text) !=
            ProgramFormDraft.parseNum(draft.buyQty) &&
        _buyQtyController.text != draft.buyQty) {
      _buyQtyController.text = draft.buyQty;
    }
    if (ProgramFormDraft.parseNum(_freeQtyController.text) !=
            ProgramFormDraft.parseNum(draft.freeQty) &&
        _freeQtyController.text != draft.freeQty) {
      _freeQtyController.text = draft.freeQty;
    }
    if (ProgramFormDraft.parseNum(_targetQtyController.text) !=
            ProgramFormDraft.parseNum(draft.targetQty) &&
        _targetQtyController.text != draft.targetQty) {
      _targetQtyController.text = draft.targetQty;
    }
    if (ProgramFormDraft.parseNum(_rebatePctController.text) !=
            ProgramFormDraft.parseNum(draft.rebatePercent) &&
        _rebatePctController.text != draft.rebatePercent) {
      _rebatePctController.text = draft.rebatePercent;
    }
  }

  void _leave(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/warehouse/supplier-programs');
    }
  }

  void _scrollToFirstError(Map<String, String> errors) {
    GlobalKey? targetKey;
    if (errors.containsKey('supplier')) {
      targetKey = _supplierKey;
    } else if (errors.containsKey('name')) {
      targetKey = _nameKey;
    } else if (errors.containsKey('products')) {
      targetKey = _productsKey;
    } else if (errors.keys.any(
      (k) =>
          k.startsWith('tier') ||
          k == 'buyQty' ||
          k == 'freeQty' ||
          k == 'targetQty' ||
          k == 'rebatePercent',
    )) {
      targetKey = _paramsKey;
    } else if (errors.containsKey('startedOn')) {
      targetKey = _startedOnKey;
    }
    final ctx = targetKey?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  Future<void> _onSubmit(
    BuildContext context,
    ProgramFormCubit cubit,
  ) async {
    await cubit.submit();
    if (!mounted) return;
    final st = cubit.state;
    if (st.showErrors && st.errors.isNotEmpty) {
      _scrollToFirstError(st.errors);
    }
  }

  Future<void> _pickProducts(
    BuildContext context,
    ProgramFormCubit cubit,
    ProgramFormState state,
  ) async {
    final products = state.options?.products ?? const [];
    final picked = await showProgramProductPickerSheet(
      context: context,
      products: products,
      selectedIds: state.draft.productIds,
      allowMultiple: state.draft.kind != ProgramKind.buyXGetY,
    );
    if (picked == null) return;
    cubit.update((d) => d.copyWith(productIds: picked));
  }

  Future<void> _endFromLocked(
    BuildContext context,
    ProgramFormState state,
  ) async {
    final detail = state.editingDetail;
    if (detail == null) return;
    final confirmed = await showProgramEndSheet(
      context,
      programName: detail.row.name,
    );
    if (!confirmed || !context.mounted) return;

    final cubit = context.read<ProgramFormCubit>();
    final ok = await cubit.end();
    if (!context.mounted) return;
    if (ok) {
      VToast.show(
        context,
        title: 'Đã kết thúc chương trình',
        message: '',
        type: VToastType.success,
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        context.go('/warehouse/supplier-programs/${detail.row.id}');
      }
    }
  }

  String? _commonSelectedUom(ProgramFormState state) {
    final ids = state.draft.productIds;
    if (ids.isEmpty || state.options == null) return null;
    final byId = {for (final p in state.options!.products) p.productId: p};
    final uoms = <String>{};
    for (final id in ids) {
      final p = byId[id];
      if (p != null && p.baseUom.isNotEmpty) {
        uoms.add(p.baseUom);
      }
    }
    return uoms.length == 1 ? uoms.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ProgramFormCubit>();
    final state = cubit.state;
    _syncControllers(state.draft);

    final title = widget.isEdit ? 'Sửa chương trình' : 'Tạo chương trình';
    final canShowFooter = state.status == ProgramFormStatus.editing ||
        state.status == ProgramFormStatus.saving;
    final overlapping = state.overlapping;

    return BlocListener<ProgramFormCubit, ProgramFormState>(
      listenWhen: (prev, curr) =>
          prev.savedProgramId != curr.savedProgramId &&
          curr.savedProgramId != null,
      listener: (context, state) {
        final id = state.savedProgramId;
        if (id != null) {
          VToast.show(
            context,
            title: 'Đã lưu chương trình',
            message: '',
            type: VToastType.success,
          );
          if (widget.isEdit && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.pushReplacement('/warehouse/supplier-programs/$id');
          }
        }
      },
      child: VPageScaffold(
        title: title,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _leave(context),
        ),
        bottomBar: canShowFooter
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.space4,
                  vertical: VSpacing.space3,
                ),
                child: InventoryFooter(
                  actions: [
                    InventoryFooterAction(
                      label: 'Huỷ',
                      onPressed: () => _leave(context),
                    ),
                    InventoryFooterAction(
                      label: 'Lưu',
                      primary: true,
                      onPressed: overlapping != null ||
                              state.status == ProgramFormStatus.saving
                          ? null
                          : () => _onSubmit(context, cubit),
                    ),
                  ],
                ),
              )
            : null,
        body: Builder(
          builder: (context) {
            if (state.status == ProgramFormStatus.loading) {
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

            if (state.status == ProgramFormStatus.loadError) {
              return Center(
                child: InventoryEmpty(
                  title: 'Không tải được chương trình',
                  description: 'Kiểm tra kết nối rồi thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: cubit.reload,
                ),
              );
            }

            if (state.status == ProgramFormStatus.locked) {
              final isEnded = state.editingDetail?.row.status ==
                      ProgramStatus.ended ||
                  state.editingDetail?.row.status == ProgramStatus.recorded;
              final canEndLocked = state.editingDetail?.row.status ==
                      ProgramStatus.active ||
                  state.editingDetail?.row.status == ProgramStatus.reached;
              final lockedTitle = isEnded
                  ? 'Chương trình đã kết thúc nên không sửa được.'
                  : 'Chương trình đã có phiếu nhận gắn nên không sửa được tham số.';
              return Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.versionConflict) ...[
                      InventoryStale(
                        title: state.endError ??
                            'Dữ liệu đã thay đổi ở nơi khác.',
                        description: 'Tải lại để xem bản mới nhất.',
                        onAction: () => context.read<ProgramFormCubit>().load(),
                      ),
                      const SizedBox(height: VSpacing.space3),
                    ] else if (state.endError != null) ...[
                      VBanner(
                        title: state.endError!,
                        tone: VComponentTone.danger,
                      ),
                      const SizedBox(height: VSpacing.space3),
                    ],
                    InventoryLocked(
                      title: lockedTitle,
                      description: '',
                    ),
                    if (canEndLocked) ...[
                      const SizedBox(height: VSpacing.space3),
                      VButton(
                        label: 'Kết thúc chương trình',
                        variant: VButtonVariant.secondary,
                        tone: VComponentTone.danger,
                        isLoading: state.ending,
                        onPressed: state.ending
                            ? null
                            : () => _endFromLocked(context, state),
                      ),
                    ],
                  ],
                ),
              );
            }

            final draft = state.draft;
            final showErrors = state.showErrors;
            final errors = state.errors;
            final suppliers = state.options?.suppliers ?? const [];
            final products = state.options?.products ?? const [];
            final productsById = {for (final p in products) p.productId: p};
            final uom = _commonSelectedUom(state);
            final colors = context.vColors;

            final supplierError = showErrors ? errors['supplier'] : null;
            final nameError = showErrors ? errors['name'] : null;
            final productsError = showErrors ? errors['products'] : null;
            final buyQtyError = showErrors ? errors['buyQty'] : null;
            final freeQtyError = showErrors ? errors['freeQty'] : null;
            final targetQtyError = showErrors ? errors['targetQty'] : null;
            final rebatePctError = showErrors ? errors['rebatePercent'] : null;
            final startedOnError = showErrors ? errors['startedOn'] : null;

            return SingleChildScrollView(
              controller: _scrollController,
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
                    if (state.versionConflict && state.submitError != null) ...[
                      InventoryStale(
                        title: state.submitError!,
                        description: '',
                        actionLabel: 'Tải lại',
                        onAction: cubit.reload,
                      ),
                      const SizedBox(height: VSpacing.space3),
                    ] else if (state.submitError != null) ...[
                      VBanner(
                        tone: VComponentTone.danger,
                        title: state.submitError!,
                      ),
                      const SizedBox(height: VSpacing.space3),
                    ],

                    // 1. Nhà cung cấp
                    KeyedSubtree(
                      key: _supplierKey,
                      child: state.isEdit
                          ? VKeyValueGroup(
                              rows: [
                                VKeyValueRow(
                                  label: 'Nhà cung cấp',
                                  value: state.editingDetail?.row.supplierName ??
                                      '',
                                ),
                              ],
                            )
                          : VField(
                              invalid: supplierError != null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const VFieldLabel(
                                    'Nhà cung cấp',
                                    isRequired: true,
                                  ),
                                  VSelect<String>(
                                    value: draft.supplierId,
                                    hintText: 'Chọn nhà cung cấp',
                                    items: [
                                      for (final s in suppliers)
                                        DropdownMenuItem<String>(
                                          value: s.partnerId,
                                          child: Text(s.displayName),
                                        ),
                                    ],
                                    onChanged: (val) => cubit.update(
                                      (d) => val == null
                                          ? d.copyWith(clearSupplier: true)
                                          : d.copyWith(supplierId: val),
                                    ),
                                  ),
                                  if (supplierError != null)
                                    VFieldError(supplierError),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: VSpacing.space3),

                    // Cảnh báo trùng chương trình đang chạy
                    if (overlapping != null &&
                        overlapping.activeProgram != null) ...[
                      VBanner(
                        tone: VComponentTone.warning,
                        title:
                            'NCC này đang có chương trình "${overlapping.activeProgram!.name}".',
                        description:
                            'Kết thúc chương trình đó trước khi tạo chương trình mới.',
                        footer: VButton(
                          label: 'Xem chương trình',
                          variant: VButtonVariant.secondary,
                          onPressed: () => context.push(
                            '/warehouse/supplier-programs/${overlapping.activeProgram!.id}',
                          ),
                        ),
                      ),
                      const SizedBox(height: VSpacing.space3),
                    ],

                    // 2. Loại ưu đãi
                    if (state.isEdit)
                      VKeyValueGroup(
                        rows: [
                          VKeyValueRow(
                            label: 'Loại ưu đãi',
                            value: programKindLong(draft.kind),
                          ),
                        ],
                      )
                    else
                      VField(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const VFieldLabel('Loại ưu đãi', isRequired: true),
                            VChoiceList<ProgramKind>(
                              choices: [
                                for (final k in ProgramKind.values)
                                  VChoiceOption<ProgramKind>(
                                    value: k,
                                    label: programKindLong(k),
                                  ),
                              ],
                              selected: [draft.kind],
                              onChanged: (sel) {
                                if (sel.isEmpty) return;
                                cubit.update((d) => d.copyWith(kind: sel.first));
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: VSpacing.space3),

                    // 3. Tên chương trình
                    KeyedSubtree(
                      key: _nameKey,
                      child: VField(
                        invalid: nameError != null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const VFieldLabel(
                              'Tên chương trình',
                              isRequired: true,
                            ),
                            VTextField(
                              controller: _nameController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(120),
                              ],
                              onChanged: (v) =>
                                  cubit.update((d) => d.copyWith(name: v)),
                            ),
                            if (nameError != null) VFieldError(nameError),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: VSpacing.space3),

                    // 4. Sản phẩm
                    KeyedSubtree(
                      key: _productsKey,
                      child: VField(
                        invalid: productsError != null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const VFieldLabel('Sản phẩm', isRequired: true),
                            for (final pid in draft.productIds) ...[
                              Builder(
                                builder: (context) {
                                  final p = productsById[pid];
                                  final name = p?.name ?? pid;
                                  final subtitle = p != null
                                      ? '${p.code} · ${p.baseUom}'
                                      : '';
                                  return VListRow(
                                    title: name,
                                    subtitle: subtitle,
                                    type: VListRowType.plain,
                                    trailing: IconButton(
                                      tooltip: 'Xoá sản phẩm',
                                      icon: VIcon(
                                        icon: VIcons.close,
                                        size: 18,
                                        color: colors.textSecondary,
                                      ),
                                      onPressed: () {
                                        cubit.update(
                                          (d) => d.copyWith(
                                            productIds: d.productIds
                                                .where((id) => id != pid)
                                                .toList(),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: VSpacing.space1),
                            ],
                            VButton(
                              label: 'Chọn sản phẩm',
                              variant: VButtonVariant.secondary,
                              leading: VIcons.add,
                              onPressed: () =>
                                  _pickProducts(context, cubit, state),
                            ),
                            if (productsError != null)
                              VFieldError(productsError),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: VSpacing.space4),

                    // 5. Tham số theo loại
                    KeyedSubtree(
                      key: _paramsKey,
                      child: VSection(
                        title: 'Tham số',
                        child: switch (draft.kind) {
                          ProgramKind.tierDiscount => ProgramTierRows(
                              tiers: draft.tiers,
                              uom: uom,
                              errors: errors,
                              showErrors: showErrors,
                              onTierChanged: (idx, {minQty, percent}) {
                                cubit.update((d) {
                                  final next = [...d.tiers];
                                  final cur = next[idx];
                                  next[idx] = (
                                    minQty: minQty ?? cur.minQty,
                                    percent: percent ?? cur.percent,
                                  );
                                  return d.copyWith(tiers: next);
                                });
                              },
                              onRemoveTier: (idx) {
                                cubit.update((d) {
                                  final next = [...d.tiers]..removeAt(idx);
                                  return d.copyWith(tiers: next);
                                });
                              },
                              onAddTier: () {
                                cubit.update((d) {
                                  if (d.tiers.length >= 5) return d;
                                  return d.copyWith(
                                    tiers: [
                                      ...d.tiers,
                                      (minQty: '', percent: ''),
                                    ],
                                  );
                                });
                              },
                            ),
                          ProgramKind.buyXGetY => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    VText(
                                      'Mua',
                                      variant: VTextVariant.bodyDefault,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: VSpacing.space2),
                                    Expanded(
                                      child: VNumberField(
                                        controller: _buyQtyController,
                                        allowDecimal: false,
                                        invalid: buyQtyError != null,
                                        onChanged: (val) => cubit.update(
                                          (d) => d.copyWith(
                                            buyQty: val?.toString() ?? '',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: VSpacing.space2),
                                    VText(
                                      'tặng',
                                      variant: VTextVariant.bodyDefault,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: VSpacing.space2),
                                    Expanded(
                                      child: VNumberField(
                                        controller: _freeQtyController,
                                        allowDecimal: false,
                                        suffixText: uom,
                                        invalid: freeQtyError != null,
                                        onChanged: (val) => cubit.update(
                                          (d) => d.copyWith(
                                            freeQty: val?.toString() ?? '',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (buyQtyError != null) ...[
                                  const SizedBox(height: VSpacing.space1),
                                  VText(
                                    buyQtyError,
                                    variant: VTextVariant.bodySmall,
                                    color: colors.danger,
                                  ),
                                ],
                                if (freeQtyError != null) ...[
                                  const SizedBox(height: VSpacing.space1),
                                  VText(
                                    freeQtyError,
                                    variant: VTextVariant.bodySmall,
                                    color: colors.danger,
                                  ),
                                ],
                              ],
                            ),
                          ProgramKind.volumeRebate => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    VText(
                                      'Mốc',
                                      variant: VTextVariant.bodyDefault,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: VSpacing.space2),
                                    Expanded(
                                      child: VNumberField(
                                        controller: _targetQtyController,
                                        allowDecimal: true,
                                        decimalPlaces: 3,
                                        suffixText: uom,
                                        invalid: targetQtyError != null,
                                        onChanged: (val) => cubit.update(
                                          (d) => d.copyWith(
                                            targetQty: val?.toString() ?? '',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: VSpacing.space2),
                                    VText(
                                      'Chiết khấu',
                                      variant: VTextVariant.bodyDefault,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: VSpacing.space2),
                                    Expanded(
                                      child: VNumberField(
                                        controller: _rebatePctController,
                                        allowDecimal: true,
                                        decimalPlaces: 2,
                                        suffixText: '%',
                                        invalid: rebatePctError != null,
                                        onChanged: (val) => cubit.update(
                                          (d) => d.copyWith(
                                            rebatePercent:
                                                val?.toString() ?? '',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (targetQtyError != null) ...[
                                  const SizedBox(height: VSpacing.space1),
                                  VText(
                                    targetQtyError,
                                    variant: VTextVariant.bodySmall,
                                    color: colors.danger,
                                  ),
                                ],
                                if (rebatePctError != null) ...[
                                  const SizedBox(height: VSpacing.space1),
                                  VText(
                                    rebatePctError,
                                    variant: VTextVariant.bodySmall,
                                    color: colors.danger,
                                  ),
                                ],
                                const SizedBox(height: VSpacing.space2),
                                VText(
                                  'Số lượng vượt mốc vẫn tính vào căn cứ chiết khấu.',
                                  variant: VTextVariant.bodySmall,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                        },
                      ),
                    ),
                    const SizedBox(height: VSpacing.space4),

                    // 6. Ngày bắt đầu
                    KeyedSubtree(
                      key: _startedOnKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ignore: deprecated_member_use
                          VDatePicker(
                            label: 'Ngày bắt đầu',
                            value: draft.startedOn,
                            onChanged: (date) => cubit.update(
                              (d) => d.copyWith(startedOn: date),
                            ),
                          ),
                          if (startedOnError != null) ...[
                            const SizedBox(height: VSpacing.space1),
                            VText(
                              startedOnError,
                              variant: VTextVariant.bodySmall,
                              color: colors.danger,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: VSpacing.space3),

                    // 7. Ghi chú
                    VField(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VFieldLabel('Ghi chú'),
                          VTextArea(
                            controller: _noteController,
                            onChanged: (v) =>
                                cubit.update((d) => d.copyWith(note: v)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:erp/core/di/injection.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_record_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_record_state.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/supplier_rebate/rebate_allocation_view.dart';
import 'package:erp/features/inventory/presentation/supplier_rebate/rebate_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

/// Màn ghi nhận chiết khấu đạt mốc (P4).
class RebateRecordPage extends StatelessWidget {
  const RebateRecordPage({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RebateRecordCubit(
        rebates: getIt<SupplierRebateRepository>(),
        programs: getIt<SupplierProgramRepository>(),
        programId: programId,
      )..load(),
      child: _RebateRecordView(programId: programId),
    );
  }
}

class _RebateRecordView extends StatefulWidget {
  const _RebateRecordView({required this.programId});

  final String programId;

  @override
  State<_RebateRecordView> createState() => _RebateRecordViewState();
}

class _RebateRecordViewState extends State<_RebateRecordView> {
  final _docNoController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _docNoController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _syncControllers(RebateRecordState state) {
    if (_docNoController.text != state.documentNo) {
      _docNoController.text = state.documentNo;
    }
    if (_amountController.text != state.amountText) {
      _amountController.text = state.amountText;
    }
    if (_reasonController.text != state.reason) {
      _reasonController.text = state.reason;
    }
  }

  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/warehouse/supplier-programs/${widget.programId}');
    }
  }

  Future<void> _openConfirmSheet(
    BuildContext context,
    RebateRecordCubit cubit,
    RebateRecordState state,
  ) async {
    final amountVnd =
        parseMoneyInput(state.amountText) ?? state.preview?.amountVnd ?? 0;
    final affectedCount = (state.preview?.allocations ?? const [])
        .where((a) => (a.inventoryPartVnd ?? 0) > 0)
        .length;

    final confirmed = await showRebateConfirmSheet(
      context,
      amountVnd: amountVnd,
      affectedProductCount: affectedCount,
    );
    if (!context.mounted) return;
    if (confirmed) {
      await cubit.confirm();
    } else {
      cubit.cancelConfirm();
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RebateRecordCubit, RebateRecordState>(
      listenWhen: (prev, curr) =>
          (!prev.confirming && curr.confirming) ||
          (prev.status != RebateRecordStatus.recorded &&
              curr.status == RebateRecordStatus.recorded),
      listener: (context, state) {
        final cubit = context.read<RebateRecordCubit>();
        if (state.status == RebateRecordStatus.recorded) {
          final previewMatchesResult = state.preview != null &&
              state.result != null &&
              state.preview!.amountVnd == state.result!.amountVnd;
          context.go(
            '/warehouse/supplier-programs/${widget.programId}/rebate/result',
            extra: previewMatchesResult ? state.preview!.inventoryPartTotal : null,
          );
          return;
        }
        if (state.confirming) {
          _openConfirmSheet(context, cubit, state);
        }
      },
      builder: (context, state) {
        _syncControllers(state);
        final cubit = context.read<RebateRecordCubit>();
        final showFormFooter = state.status == RebateRecordStatus.ready ||
            state.status == RebateRecordStatus.submitting ||
            state.status == RebateRecordStatus.recorded;
        final isSubmitting = state.status == RebateRecordStatus.submitting;

        return VPageScaffold(
          title: 'Ghi nhận chiết khấu',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: isSubmitting ? null : () => _back(context),
          ),
          bottomBar: showFormFooter
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space4,
                    vertical: VSpacing.space3,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.errorCode != null) ...[
                        VBanner(
                          tone: VComponentTone.danger,
                          title: inventoryErrorMessage(
                            AppException(state.errorCode!),
                            fallback:
                                'Không ghi nhận được chiết khấu. Thử lại.',
                          ),
                        ),
                        const SizedBox(height: VSpacing.space2),
                      ],
                      InventoryFooter(
                        actions: [
                          InventoryFooterAction(
                            label: 'Huỷ',
                            onPressed:
                                isSubmitting ? null : () => _back(context),
                          ),
                          InventoryFooterAction(
                            label: 'Ghi nhận',
                            primary: true,
                            onPressed: isSubmitting ? null : cubit.submit,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
          body: _buildBody(context, cubit, state, isSubmitting),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    RebateRecordCubit cubit,
    RebateRecordState state,
    bool isSubmitting,
  ) {
    switch (state.status) {
      case RebateRecordStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(VSpacing.space4),
          child: InventoryLoading(
            blocks: [
              InventorySkeletonBlock.card,
              InventorySkeletonBlock.row,
              InventorySkeletonBlock.card,
            ],
          ),
        );

      case RebateRecordStatus.loadError:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: InventoryEmpty(
              title: 'Không tải được chương trình',
              description: 'Kiểm tra kết nối rồi thử lại.',
              actionLabel: 'Thử lại',
              onAction: cubit.load,
            ),
          ),
        );

      case RebateRecordStatus.notOwner:
        return _LockedStateBody(
          title: 'Chỉ chủ cửa hàng ghi nhận được chiết khấu.',
          buttonLabel: 'Về chương trình',
          onPressed: () =>
              context.go('/warehouse/supplier-programs/${widget.programId}'),
        );

      case RebateRecordStatus.notReached:
        return _LockedStateBody(
          title: 'Chương trình chưa đạt mốc hoặc đã ghi nhận.',
          buttonLabel: 'Về chương trình',
          onPressed: () =>
              context.go('/warehouse/supplier-programs/${widget.programId}'),
        );

      case RebateRecordStatus.stale:
        return Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: InventoryStale(
            title: 'Chương trình đã được ghi nhận chiết khấu',
            description: '',
            actionLabel: 'Xem chương trình',
            onAction: () =>
                context.go('/warehouse/supplier-programs/${widget.programId}'),
          ),
        );

      case RebateRecordStatus.ready:
      case RebateRecordStatus.submitting:
      case RebateRecordStatus.recorded:
        final preview = state.preview;
        final program = state.program;
        if (preview == null || program == null) {
          return const SizedBox.shrink();
        }

        final uom = preview.uom ?? program.row.commonUom;
        final uomSuffix =
            (uom != null && uom.trim().isNotEmpty) ? ' ${uom.trim()}' : '';
        final showErrors = state.showErrors;
        final errors = state.errors;
        final docNoErr = showErrors ? errors['documentNo'] : null;
        final docDateErr = showErrors ? errors['documentDate'] : null;
        final amountErr = showErrors ? errors['amount'] : null;
        final reasonErr = showErrors ? errors['reason'] : null;
        final parsedAmount = parseMoneyInput(state.amountText);
        final showReason =
            needsOverrideReason(parsedAmount, preview.proposedAmountVnd);

        final now = DateTime.now();
        final today = _dateOnly(now);
        final rawStart = _dateOnly(program.row.startedOn);
        final firstDate = rawStart.isAfter(today) ? today : rawStart;

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
                VSection(
                  title: 'Căn cứ',
                  child: VKeyValueGroup(
                    rows: [
                      VKeyValueRow(
                        label: 'Nhà cung cấp',
                        value: preview.supplierName,
                      ),
                      VKeyValueRow(
                        label: 'Đã mua',
                        value:
                            '${formatProgramQuantity(preview.progressQty)} / '
                            '${formatProgramQuantity(preview.targetQty)}$uomSuffix',
                        mono: true,
                      ),
                      VKeyValueRow(
                        label: 'Tổng tiền mua',
                        value:
                            '${MoneyFormatter.formatMinorPlain(preview.baseAmountVnd)} đ',
                        mono: true,
                      ),
                      VKeyValueRow(
                        label: 'Mức chiết khấu',
                        value: '${formatPercent(preview.rebatePercent)}%',
                        mono: true,
                      ),
                      VKeyValueRow(
                        label: 'Đề xuất',
                        value:
                            '${MoneyFormatter.formatMinorPlain(preview.proposedAmountVnd)} đ',
                        mono: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VSpacing.space4),
                VField(
                  invalid: docNoErr != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VFieldLabel('Số chứng từ', isRequired: true),
                      VTextField(
                        controller: _docNoController,
                        hintText: 'VD: CK-2026-11',
                        enabled: !isSubmitting,
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                        onChanged: cubit.setDocumentNo,
                      ),
                      if (docNoErr != null) VFieldError(docNoErr),
                    ],
                  ),
                ),
                const SizedBox(height: VSpacing.space3),
                VField(
                  invalid: docDateErr != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ignore: deprecated_member_use
                      VDatePicker(
                        label: 'Ngày chứng từ',
                        // ignore: deprecated_member_use
                        required: true,
                        value: state.documentDate,
                        firstDate: firstDate,
                        lastDate: today,
                        enabled: !isSubmitting,
                        tone: docDateErr != null
                            ? VComponentTone.danger
                            : VComponentTone.neutral,
                        onChanged: cubit.setDocumentDate,
                      ),
                      if (docDateErr != null) VFieldError(docDateErr),
                    ],
                  ),
                ),
                const SizedBox(height: VSpacing.space3),
                VField(
                  invalid: amountErr != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VFieldLabel('Số tiền ghi nhận', isRequired: true),
                      VTextField(
                        controller: _amountController,
                        suffixText: 'đ',
                        keyboardType: TextInputType.number,
                        enabled: !isSubmitting,
                        onChanged: cubit.setAmountText,
                      ),
                      if (amountErr != null) VFieldError(amountErr),
                    ],
                  ),
                ),
                if (showReason) ...[
                  const SizedBox(height: VSpacing.space3),
                  VField(
                    invalid: reasonErr != null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VFieldLabel(
                          'Lý do khác đề xuất',
                          isRequired: true,
                        ),
                        VTextArea(
                          controller: _reasonController,
                          maxLength: 300,
                          enabled: !isSubmitting,
                          onChanged: cubit.setReason,
                        ),
                        if (reasonErr != null) VFieldError(reasonErr),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: VSpacing.space4),
                RebateAllocationView(
                  preview: preview,
                  previewLoading: state.previewLoading,
                  previewErrorCode: state.previewErrorCode,
                ),
                const SizedBox(height: VSpacing.space4),
                const VBanner(
                  tone: VComponentTone.info,
                  title:
                      'Hàng đang tồn được coi là thuộc các lần nhập của chương trình (tối đa số đã mua). Ghi nhận xong không sửa được.',
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _LockedStateBody extends StatelessWidget {
  const _LockedStateBody({
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InventoryLocked(title: title, description: ''),
          const SizedBox(height: VSpacing.space3),
          Align(
            alignment: Alignment.centerLeft,
            child: VButton(
              label: buttonLabel,
              variant: VButtonVariant.secondary,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}


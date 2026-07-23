import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// S1 & S5 — Tạo / Sửa giá riêng (US-03 — SG-03).
class PricingFormPage extends StatefulWidget {
  const PricingFormPage({super.key, this.initialRule});

  final CustomerPriceRuleDetailDto? initialRule;

  @override
  State<PricingFormPage> createState() => _PricingFormPageState();
}

class _PricingFormPageState extends State<PricingFormPage> {
  late final PriceRuleFormCubit _cubit;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _allowPop = false;
  bool _leaveDialogOpen = false;

  bool get _isEdit => widget.initialRule != null;

  @override
  void initState() {
    super.initState();
    final getIt = GetIt.instance;
    _cubit = PriceRuleFormCubit(
      existingRule: widget.initialRule,
      mode: _isEdit ? PriceRuleFormMode.edit : PriceRuleFormMode.create,
      pricingModule: getIt<IPricingModule>(),
      executionContext: getIt<IExecutionContext>(),
    );

    if (_isEdit) {
      final initialAmount = widget.initialRule!.price.amountMinor;
      final formatted = VMoneyValidator.format(initialAmount);
      _priceController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      _noteController.text = widget.initialRule!.note ?? '';
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onPriceChanged(int? amountDong) {
    _cubit.updatePrice(amountDong);
  }

  void _onSuccess(BuildContext context, CustomerPriceRuleDetailDto rule) {
    final message = _isEdit ? 'Đã cập nhật giá riêng' : 'Đã tạo giá riêng thành công';
    VToast.show(
      context,
      title: 'Thành công',
      message: message,
      type: VToastType.success,
    );
    setState(() => _allowPop = true);
    if (_isEdit) {
      context.pop(rule);
    } else if (context.canPop()) {
      context.pop(rule);
    } else {
      context.go('/pricing/${rule.id}');
    }
  }

  bool _isFormDirty(PriceRuleFormState state) {
    return state is PriceRuleFormEditing && state.isDirty;
  }

  Future<void> _requestLeave() async {
    final state = _cubit.state;
    if (!_isFormDirty(state)) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    if (_leaveDialogOpen) return;
    _leaveDialogOpen = true;
    final leave = await showPriceRuleLeaveFormDialog(context);
    if (!mounted) return;
    _leaveDialogOpen = false;
    if (!leave) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<PriceRuleFormCubit, PriceRuleFormState>(
        listener: (context, state) {
          if (state is PriceRuleFormSuccess) {
            _onSuccess(context, state.rule);
          } else if (state is PriceRuleFormError) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: _mapErrorToMessage(state.code),
              type: VToastType.danger,
            );
          }
        },
        child: BlocBuilder<PriceRuleFormCubit, PriceRuleFormState>(
          builder: (context, state) {
            if (state is PriceRuleFormNoPermission) {
              return VPageScaffold(
                title: _isEdit ? 'Sửa giá riêng' : 'Tạo giá riêng',
                showBackButton: true,
                body: PriceRuleFormNoPermissionState(
                  isEdit: _isEdit,
                  onClose: () => context.pop(),
                ),
              );
            }

            final form = state is PriceRuleFormEditing ? state : const PriceRuleFormEditing();
            final initialRule = widget.initialRule;
            final canPop = _allowPop || !form.isDirty;

            // VAppBar default back dùng Navigator.pop() (force) — bỏ qua PopScope.
            // Leading custom + PopScope: back/Hủy/_requestLeave; swipe/system back qua canPop.
            final leaveLeading = Padding(
              padding: const EdgeInsets.all(VSpacing.space2),
              child: VIconBox(
                key: const Key('btn_price_rule_form_back'),
                icon: VIcons.arrowBack,
                size: 40,
                backgroundColor: Colors.transparent,
                onTap: _requestLeave,
              ),
            );

            if (_isEdit && form.hasStateChanged) {
              return PopScope<Object?>(
                canPop: canPop,
                onPopInvokedWithResult: (didPop, _) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (!didPop) _requestLeave();
                },
                child: VPageScaffold(
                  key: const Key('wgt_e02_u06_fr01_01'),
                  title: 'Sửa giá riêng',
                  showBackButton: false,
                  leading: leaveLeading,
                  body: PriceRuleFormStateChangedState(
                    onReload: _cubit.reloadExistingRule,
                  ),
                ),
              );
            }

            return PopScope<Object?>(
              canPop: canPop,
              onPopInvokedWithResult: (didPop, _) {
                FocusManager.instance.primaryFocus?.unfocus();
                if (!didPop) _requestLeave();
              },
              child: VPageScaffold(
                key: Key(_isEdit ? 'wgt_e02_u06_fr01_01' : 'wgt_e02_u04_fr01_01'),
                title: _isEdit ? 'Sửa giá riêng' : 'Tạo giá riêng',
                subtitle: _isEdit ? initialRule?.customer.displayName : null,
                showBackButton: false,
                leading: leaveLeading,
                body: PriceRuleFormBody(
                  cubit: _cubit,
                  form: form,
                  priceController: _priceController,
                  noteController: _noteController,
                  isEdit: _isEdit,
                  onPriceChanged: _onPriceChanged,
                  lastUpdatedAt: initialRule?.updatedAt,
                  lastUpdatedBy: initialRule?.updatedBy,
                  onViewConflictingRule: (ruleId) {
                    context.push('/pricing/$ruleId');
                  },
                  onPickCustomer: () => context.push<Map<String, String>>('/pricing/pick-customer'),
                  onPickProduct: () => context.push<Map<String, String>>('/pricing/pick-product'),
                  onPickUnit: () => context.push<Map<String, String>>(
                    '/pricing/pick-unit/${form.productId}',
                  ),
                ),
                bottomBar: _BottomBar(
                  cubit: _cubit,
                  form: form,
                  isEdit: _isEdit,
                  initialRule: initialRule,
                  onCancel: _requestLeave,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _mapErrorToMessage(String code) => switch (code) {
    PricingBlockedCodes.duplicateActiveRule =>
      'Đã tồn tại giá riêng đang hoạt động trùng thời gian. '
          'Vui lòng điều chỉnh khoảng hiệu lực hoặc chọn đối tượng khác.',
    PricingBlockedCodes.belowFloorBlocked => 'Giá nhập thấp hơn giá sàn quy định.',
    PricingBlockedCodes.referenceInvalid => 'Khách hàng hoặc sản phẩm không hợp lệ.',
    PricingBlockedCodes.noPermission => 'Bạn không có quyền thực hiện.',
    PricingBlockedCodes.stateChanged => 'Dữ liệu đã thay đổi. Vui lòng tải lại.',
    PricingBlockedCodes.validationError => 'Thông tin nhập không hợp lệ.',
    PricingBlockedCodes.systemError => 'Không thể lưu giá riêng. Vui lòng thử lại.',
    _ => 'Lỗi: $code',
  };
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.cubit,
    required this.form,
    required this.isEdit,
    required this.onCancel,
    this.initialRule,
  });

  final PriceRuleFormCubit cubit;
  final PriceRuleFormEditing form;
  final bool isEdit;
  final VoidCallback onCancel;
  final CustomerPriceRuleDetailDto? initialRule;

  String _formatMinor(int amountMinor) {
    return '${amountMinor.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không giới hạn';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _onSave(BuildContext context) async {
    String? changeReason;
    if (isEdit && initialRule != null && form.rulePriceMinor != null) {
      final rule = initialRule!;
      final result = await PriceRuleSaveConfirmSheet.show(
        context: context,
        oldPriceLabel: _formatMinor(rule.price.amountMinor),
        newPriceLabel: _formatMinor(form.rulePriceMinor!),
        oldFromLabel: _formatDate(rule.effectivePeriod.effectiveFrom),
        newFromLabel: _formatDate(form.effectiveFrom),
        oldToLabel: _formatDate(rule.effectivePeriod.effectiveTo),
        newToLabel: _formatDate(form.effectiveTo),
      );
      if (result == null || !result.confirmed) return;
      changeReason = result.changeReason;
    }
    await cubit.submit(changeReason: changeReason);
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = form.isSubmitting;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Hủy',
                variant: VButtonVariant.secondary,
                fullWidth: true,
                onPressed: isSubmitting ? null : onCancel,
              ),
            ),
            const VGap.horizontalMd(),
            Expanded(
              child: VButton(
                label: isSubmitting ? 'Đang lưu...' : 'Lưu',
                variant: VButtonVariant.primary,
                fullWidth: true,
                onPressed: (isSubmitting || !form.isValid) ? null : () => _onSave(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

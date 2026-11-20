import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_state.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_supplier_field.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';

class ReceiptHeaderPage extends StatefulWidget {
  const ReceiptHeaderPage({
    super.key,
    required this.onContinue,
    this.onDiscard,
  });

  final VoidCallback onContinue;
  final VoidCallback? onDiscard;

  @override
  State<ReceiptHeaderPage> createState() => _ReceiptHeaderPageState();
}

class _ReceiptHeaderPageState extends State<ReceiptHeaderPage> {
  String? _supplierError;
  late final TextEditingController _docNoController;
  bool _isDiscarding = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ReceiptDraftCubit>();
    _docNoController = TextEditingController(text: cubit.state.draft.docNo);
  }

  @override
  void dispose() {
    _docNoController.dispose();
    super.dispose();
  }

  void _leave(BuildContext context) {
    if (widget.onDiscard != null) {
      widget.onDiscard!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/warehouse/receipts');
    }
  }

  void _handleBack(BuildContext context) {
    final cubit = context.read<ReceiptDraftCubit>();
    if (!cubit.isDirty) {
      _leave(context);
      return;
    }

    showVAdaptiveSheet(
      context: context,
      title: 'Bỏ phiếu đang lập?',
      child: Builder(
        builder: (sheetContext) {
          return Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thông tin và các dòng hàng đã nhập sẽ mất.',
                  style: VTypography.bodyDefault,
                ),
                const SizedBox(height: VSpacing.space4),
                VButton(
                  variant: VButtonVariant.primary,
                  tone: VComponentTone.danger,
                  label: 'Bỏ phiếu',
                  onPressed: () {
                    setState(() {
                      _isDiscarding = true;
                    });
                    Navigator.of(sheetContext).pop();
                    _leave(context);
                  },
                ),
                const SizedBox(height: VSpacing.space2),
                VButton(
                  variant: VButtonVariant.secondary,
                  label: 'Ở lại',
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onPressContinue() {
    final cubit = context.read<ReceiptDraftCubit>();
    if (cubit.state.draft.supplier == null) {
      setState(() {
        _supplierError = 'Chọn nhà cung cấp trong danh sách.';
      });
      return;
    }

    setState(() {
      _supplierError = null;
    });

    cubit.addInitialProductLine();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ReceiptDraftCubit>();
    final state = cubit.state;

    if (state.status == ReceiptDraftStatus.loading) {
      return const Scaffold(
        body: Center(child: InventoryLoading()),
      );
    }

    if (state.status == ReceiptDraftStatus.loadFailed) {
      return Scaffold(
        body: Center(
          child: InventoryEmpty(
            title: 'Không thể tải dữ liệu',
            description: 'Vui lòng kiểm tra lại kết nối và thử lại.',
            actionLabel: 'Thử lại',
            onAction: () => cubit.load(),
          ),
        ),
      );
    }

    final suppliers = state.options?.suppliers ?? const [];

    return PopScope(
      canPop: _isDiscarding || !cubit.isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack(context);
        }
      },
      child: VPageScaffold(
        title: 'Thông tin nhận hàng',
        leading: BackButton(
          onPressed: () => _handleBack(context),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReceiptSupplierField(
                suppliers: suppliers,
                selected: state.draft.supplier,
                errorText: _supplierError,
                onChanged: (s) {
                  setState(() {
                    _supplierError = null;
                  });
                  cubit.selectSupplier(s);
                },
              ),
              const SizedBox(height: VSpacing.space4),
              VField(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VFieldLabel('Số chứng từ'),
                    const SizedBox(height: VSpacing.space1),
                    VTextField(
                      key: const Key('receipt_doc_no'),
                      controller: _docNoController,
                      hintText: 'VD: HĐ 0001523',
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(60),
                      ],
                      onChanged: (val) {
                        cubit.setDocNo(val);
                      },
                    ),
                    const SizedBox(height: VSpacing.space1),
                    const VFieldDescription(
                      'Số hoá đơn hoặc phiếu giao hàng từ nhà cung cấp (nếu có).',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VSpacing.space6),
              VButton(
                variant: VButtonVariant.primary,
                label: 'Tiếp tục',
                fullWidth: true,
                onPressed: _onPressContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

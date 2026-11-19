import 'package:erp/core/di/injection.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../data/receivable_models.dart';
import '../../data/receivable_repository.dart';
import '../../logic/customer_collection_cubit.dart';
import '../../logic/customer_collection_state.dart';
import '../../logic/receivable_format.dart';
import '../../logic/receivable_allocation.dart';
import 'receivable_parts.dart';

sealed class CollectionSheetOutcome {
  const CollectionSheetOutcome();
}

final class CollectionCollected extends CollectionSheetOutcome {
  const CollectionCollected(this.result, this.amountMinor);

  final CustomerCollectionResult result;
  final int amountMinor;
}

final class CollectionNeedsReload extends CollectionSheetOutcome {
  const CollectionNeedsReload();
}

final class CollectionCancelled extends CollectionSheetOutcome {
  const CollectionCancelled();
}

/// CN-03 — sheet đáy trên iPhone, hộp thoại trên web. Đóng không có giá trị = hủy.
Future<CollectionSheetOutcome> showCustomerCollectionSheet(
  BuildContext context, {
  required String customerId,
  required String customerName,
  required List<OpenReceivableOrder> orders,
  ReceivableRepository? repository,
  DateTime? today,
}) async {
  final repo = repository ?? getIt<ReceivableRepository>();
  final body = BlocProvider(
    create: (_) => CustomerCollectionCubit(
      repository: repo,
      customerId: customerId,
      orders: orders,
    ),
    child: CustomerCollectionSheet(customerName: customerName, today: today),
  );
  // Không dùng `showVAdaptiveSheet`: nút đóng của hộp thoại DS đóng thẳng, bỏ qua hỏi "Bỏ khoản thu đang nhập?".
  final wide = MediaQuery.sizeOf(context).width >= VBreakpoints.desktop;
  final outcome = wide
      ? await showDialog<CollectionSheetOutcome>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            backgroundColor: dialogContext.vColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sheet)),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: VSpacing.screenMobile,
              vertical: VSpacing.space4,
            ),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: body),
          ),
        )
      : await showVBottomSheet<CollectionSheetOutcome>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          semanticLabel: 'Thu tiền',
          child: body,
        );
  return outcome ?? const CollectionCancelled();
}

/// Số có dấu chấm nghìn (`10.000.000`), con trỏ luôn ở cuối.
class _GroupedDigitsFormatter extends TextInputFormatter {
  const _GroupedDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = MoneyFormatter.formatMinorPlain(int.tryParse(digits) ?? 0);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CustomerCollectionSheet extends StatefulWidget {
  const CustomerCollectionSheet({super.key, required this.customerName, this.today});

  final String customerName;
  final DateTime? today;

  @override
  State<CustomerCollectionSheet> createState() => _CustomerCollectionSheetState();
}

class _CustomerCollectionSheetState extends State<CustomerCollectionSheet> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  CustomerCollectionCubit get _cubit => context.read<CustomerCollectionCubit>();

  /// Số trong ô theo cubit (khi tick / bỏ tick cubit ghi đè số gõ tay — TH-06 9.3).
  void _syncAmount(CustomerCollectionState s) {
    if (MoneyFormatter.parseMinor(_amount.text) == s.amountMinor) return;
    final text = s.amountMinor == 0 ? '' : formatVndBare(s.amountMinor);
    _amount.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _requestClose() async {
    final s = _cubit.state;
    if (s.phase == CollectionPhase.submitting) return;
    if (s.step == CollectionStep.confirm) {
      _cubit.backToForm();
      return;
    }
    if (!s.isDirty) {
      Navigator.of(context).pop(const CollectionCancelled());
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmBox(
        title: 'Bỏ khoản thu đang nhập?',
        stay: 'Ở lại',
        confirm: 'Bỏ',
        destructive: true,
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop(const CollectionCancelled());
  }

  Future<void> _onChanged(CustomerCollectionState s) async {
    if (s.phase == CollectionPhase.success && s.result != null) {
      Navigator.of(context).pop(CollectionCollected(s.result!, s.amountMinor));
    } else if (s.phase == CollectionPhase.changed) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ConfirmBox(
          title: 'Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại.',
          confirm: 'Tải lại',
        ),
      );
      if (mounted) Navigator.of(context).pop(const CollectionNeedsReload());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    return BlocConsumer<CustomerCollectionCubit, CustomerCollectionState>(
      listener: (context, s) {
        _syncAmount(s);
        _onChanged(s);
      },
      listenWhen: (a, b) => a.amountMinor != b.amountMinor || a.phase != b.phase,
      builder: (context, s) {
        final confirm = s.step == CollectionStep.confirm;
        final locked = s.phase == CollectionPhase.submitting;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _requestClose();
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VSpacing.space4,
                        VSpacing.space3,
                        56,
                        VSpacing.space2,
                      ),
                      child: Text(
                        confirm ? 'Xác nhận thu tiền?' : 'Thu tiền',
                        style: VTypography.headingH3.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!confirm)
                      Positioned(
                        top: 0,
                        right: VSpacing.space2,
                        child: SizedBox.square(
                          dimension: VSpacing.minTouchTarget,
                          child: IconButton(
                            tooltip: 'Đóng',
                            onPressed: locked ? null : _requestClose,
                            icon: VIcon(icon: VIcons.close, color: colors.textMuted),
                          ),
                        ),
                      ),
                  ],
                ),
                const VDivider(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      VSpacing.space4,
                      VSpacing.space3,
                      VSpacing.space4,
                      0,
                    ),
                    child: confirm ? _ConfirmBody(state: s, name: widget.customerName) : _FormBody(
                      state: s,
                      name: widget.customerName,
                      today: widget.today ?? DateTime.now(),
                      amount: _amount,
                      reference: _reference,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VSpacing.space4,
                    VSpacing.space3,
                    VSpacing.space4,
                    VSpacing.space4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: VButton(
                          label: 'Quay lại',
                          variant: VButtonVariant.secondary,
                          onPressed: locked ? null : _requestClose,
                        ),
                      ),
                      const SizedBox(width: VSpacing.space3),
                      Expanded(
                        child: confirm
                            ? VButton(label: 'Xác nhận', onPressed: _cubit.submit)
                            : VButton(
                                label: locked ? 'Đang ghi nhận...' : 'Xác nhận thu',
                                onPressed: s.preview.canSubmit && !locked ? _cubit.openConfirm : null,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.state,
    required this.name,
    required this.today,
    required this.amount,
    required this.reference,
  });

  final CustomerCollectionState state;
  final String name;
  final DateTime today;
  final TextEditingController amount;
  final TextEditingController reference;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerCollectionCubit>();
    final colors = context.vColors;
    final p = state.preview;
    final locked = state.phase == CollectionPhase.submitting;
    final label = VTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: colors.textPrimary);
    const gap = SizedBox(height: VSpacing.space3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$name · Còn nợ ${formatVnd(p.customerTotal)}',
          style: VTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        gap,
        _OrderList(state: state, today: today, locked: locked),
        gap,
        Text('Số tiền', style: label),
        const SizedBox(height: VSpacing.space2),
        VTextField(
          controller: amount,
          enabled: !locked,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.end,
          suffixText: 'đ',
          semanticLabel: 'Số tiền',
          inputFormatters: const [_GroupedDigitsFormatter()],
          textStyle: VTypography.headingH2.copyWith(
            color: colors.textPrimary,
            fontFeatures: tabularFigures,
          ),
          onChanged: cubit.setAmountText,
        ),
        gap,
        Text('Phương thức', style: label),
        const SizedBox(height: VSpacing.space2),
        VSegmentedControl(
          segments: const ['Tiền mặt', 'Chuyển khoản'],
          selectedIndex: state.method == CollectionMethod.cash ? 0 : 1,
          enabled: !locked,
          semanticLabel: 'Phương thức',
          onChanged: (i) => cubit.setMethod(
            i == 0 ? CollectionMethod.cash : CollectionMethod.manualBankTransfer,
          ),
        ),
        if (state.method == CollectionMethod.manualBankTransfer) ...[
          gap,
          Text('Mã giao dịch (Không bắt buộc)', style: label),
          const SizedBox(height: VSpacing.space2),
          VTextField(
            controller: reference,
            enabled: !locked,
            semanticLabel: 'Mã giao dịch',
            onChanged: cubit.setReference,
          ),
        ],
        gap,
        _Derived(preview: p),
        if (state.phase == CollectionPhase.error) ...[
          gap,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    state.errorMessage ?? '',
                    style: VTypography.bodyDefault.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.danger,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              VButton(
                label: 'Thử lại',
                variant: VButtonVariant.secondary,
                onPressed: cubit.submit,
              ),
            ],
          ),
        ],
        const SizedBox(height: VSpacing.space2),
      ],
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.state, required this.today, required this.locked});

  final CustomerCollectionState state;
  final DateTime today;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerCollectionCubit>();
    final colors = context.vColors;
    final orders = cubit.orders;
    final p = state.preview;
    final byId = {for (final a in p.allocations) a.salesOrderId: a};
    final allOn = orders.isNotEmpty && state.selectedIds.length == orders.length;
    final someOn = state.selectedIds.isNotEmpty && !allOn;
    return Semantics(
      container: true,
      label: 'Chọn đơn nhận tiền',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            checked: allOn,
            mixed: someOn,
            label: someOn ? 'Tất cả đơn · trả hết, một phần' : null,
            child: InkWell(
              onTap: locked ? null : cubit.toggleAll,
              child: Container(
                constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
                padding: const EdgeInsets.only(right: VSpacing.space3),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: VSpacing.minTouchTarget,
                      child: Center(
                        child: VCheckbox(
                          value: allOn,
                          enabled: !locked,
                          onChanged: (_) => cubit.toggleAll(),
                        ),
                      ),
                    ),
                    const SizedBox(width: VSpacing.space2),
                    Expanded(
                      child: Text(
                        'Tất cả đơn · trả hết',
                        style: VTypography.labelDefault.copyWith(color: colors.textPrimary),
                      ),
                    ),
                    Text(
                      formatVndBare(p.customerTotal),
                      style: receivableMoneyStyle(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (final o in orders) ...[
            const SizedBox(height: VSpacing.space2),
            _OrderTile(
              order: o,
              today: today,
              on: state.selectedIds.contains(o.salesOrderId),
              allocation: byId[o.salesOrderId],
              anyAllocation: p.allocations.isNotEmpty,
              locked: locked,
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.today,
    required this.on,
    required this.allocation,
    required this.anyAllocation,
    required this.locked,
  });

  final OpenReceivableOrder order;
  final DateTime today;
  final bool on;
  final CollectionAllocation? allocation;
  final bool anyAllocation;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerCollectionCubit>();
    final colors = context.vColors;
    final due = orderDueLabel(dueDate: order.dueDate, overdueDays: order.overdueDays, today: today);
    String? result;
    var resultOff = false;
    if (!on) {
      result = 'Không thu';
      resultOff = true;
    } else if (allocation != null) {
      final after = allocation!.outstandingAfterMinor;
      result =
          'Trừ ${formatVndBare(allocation!.allocatedMinor)} → ${after == 0 ? 'hết nợ' : 'còn ${formatVndBare(after)}'}';
    } else if (anyAllocation) {
      result = 'Chưa nhận';
      resultOff = true;
    }
    return Semantics(
      checked: on,
      container: true,
      child: Material(
        color: on ? colors.surfaceBrand : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
          side: BorderSide(color: on ? colors.borderBrand : colors.borderDefault),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(VRadius.card),
          onTap: locked ? null : () => cubit.toggleOrder(order.salesOrderId),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(0, VSpacing.space2, VSpacing.space3, VSpacing.space2),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: VSpacing.minTouchTarget,
                  child: Center(
                    child: VCheckbox(
                      value: on,
                      enabled: !locked,
                      onChanged: (_) => cubit.toggleOrder(order.salesOrderId),
                    ),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderCode,
                        style: VTypography.labelDefault.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ReceivableDueBadge(due, wrap: true),
                    ],
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Còn nợ ${formatVndBare(order.outstandingMinor)}',
                      softWrap: false,
                      style: receivableMoneyStyle(context),
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        result,
                        softWrap: false,
                        style: VTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: resultOff ? colors.textMuted : colors.success,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Derived extends StatelessWidget {
  const _Derived({required this.preview});

  final CollectionPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    if (preview.applicable.isEmpty) {
      return Text(
        'Chọn ít nhất một đơn để thu.',
        style: VTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      );
    }
    final over = preview.over;
    final hasAlloc = preview.allocations.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (over)
          Semantics(
            liveRegion: true,
            child: Text(
              'Số tiền vượt quá tổng còn nợ của các đơn đã chọn.',
              style: VTypography.bodyDefault.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.danger,
              ),
            ),
          ),
        if (hasAlloc)
          Container(
            padding: const EdgeInsets.fromLTRB(0, VSpacing.space3, 0, VSpacing.space1),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.borderDefault)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Khách còn nợ sau khi thu',
                  style: VTypography.labelDefault.copyWith(color: colors.textPrimary),
                ),
                Text(
                  formatVnd(preview.afterMinor),
                  style: receivableMoneyStyle(context, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({required this.state, required this.name});

  final CustomerCollectionState state;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cubit = context.read<CustomerCollectionCubit>();
    final p = state.preview;
    final method = state.method == CollectionMethod.cash ? 'Tiền mặt' : 'Chuyển khoản';
    final scope = p.applicable.length == cubit.orders.length
        ? ' · tất cả đơn'
        : p.applicable.length == 1
        ? ' · đơn ${p.applicable.first.orderCode}'
        : ' · ${p.applicable.length} đơn đã chọn';
    final codes = {for (final o in cubit.orders) o.salesOrderId: o.orderCode};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Thu ${formatVnd(state.amountMinor)} $method từ $name$scope',
          style: VTypography.bodyDefault.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        if (p.allocations.isNotEmpty) ...[
          const ReceivableSectionTitle('SẼ TRỪ VÀO', horizontal: 0),
          for (final a in p.allocations)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VSpacing.space1),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      codes[a.salesOrderId] ?? '',
                      style: VTypography.bodyDefault.copyWith(fontFeatures: tabularFigures),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatVndBare(a.allocatedMinor),
                      textAlign: TextAlign.end,
                      style: VTypography.labelDefault.copyWith(fontFeatures: tabularFigures),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 108),
                    child: Text(
                      a.outstandingAfterMinor == 0
                          ? '→ hết nợ'
                          : '→ còn ${formatVndBare(a.outstandingAfterMinor)}',
                      style: VTypography.bodyDefault.copyWith(
                        color: colors.textSecondary,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: VSpacing.space2),
            padding: const EdgeInsets.only(top: VSpacing.space2),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.borderDefault)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khách còn nợ sau khi thu',
                  style: VTypography.labelDefault.copyWith(color: colors.textPrimary),
                ),
                Text(formatVnd(p.afterMinor), style: receivableMoneyStyle(context, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
        const SizedBox(height: VSpacing.space2),
      ],
    );
  }
}

/// Hộp thoại nhỏ của prototype `dialog()`: tiêu đề + nút (một hoặc hai).
class _ConfirmBox extends StatelessWidget {
  const _ConfirmBox({
    required this.title,
    required this.confirm,
    this.stay,
    this.destructive = false,
  });

  final String title;
  final String confirm;
  final String? stay;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sheet)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: VTypography.headingH3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: VSpacing.space4),
              Row(
                children: [
                  if (stay != null) ...[
                    Expanded(
                      child: VButton(
                        label: stay!,
                        variant: VButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: VSpacing.space3),
                  ],
                  Expanded(
                    child: VButton(
                      label: confirm,
                      tone: destructive ? VComponentTone.danger : null,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

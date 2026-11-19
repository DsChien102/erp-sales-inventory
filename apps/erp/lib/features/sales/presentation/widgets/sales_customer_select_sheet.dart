import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../bloc/shared/sales_customer_picker_cubit.dart';
import '../bloc/shared/sales_customer_picker_state.dart';
import '../models/shared/sales_customer_selection.dart';
import '../support/sales_external_lookups.dart';
import 'sales_customer_picker_body.dart';
import 'sales_customer_picker_card.dart';
import 'sales_customer_picker_search_bar.dart';

Future<SalesCustomerSelection?> showSalesCustomerSelectSheet(
  BuildContext context, {
  required SalesCustomerSearchFn searchCustomers,
  String? selectedPartnerId,
  bool selectedWalkIn = true,
  VoidCallback? onCreateCustomer,
}) {
  return showVBottomSheet<SalesCustomerSelection>(
    context: context,
    child: _SalesCustomerSelectSheet(
      searchCustomers: searchCustomers,
      selectedPartnerId: selectedPartnerId,
      selectedWalkIn: selectedWalkIn,
      onCreateCustomer: onCreateCustomer,
    ),
  );
}

class _SalesCustomerSelectSheet extends StatefulWidget {
  const _SalesCustomerSelectSheet({
    required this.searchCustomers,
    this.selectedPartnerId,
    this.selectedWalkIn = true,
    this.onCreateCustomer,
  });

  final SalesCustomerSearchFn searchCustomers;
  final String? selectedPartnerId;
  final bool selectedWalkIn;
  final VoidCallback? onCreateCustomer;

  @override
  State<_SalesCustomerSelectSheet> createState() => _SalesCustomerSelectSheetState();
}

class _SalesCustomerSelectSheetState extends State<_SalesCustomerSelectSheet> {
  late final SalesCustomerPickerCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SalesCustomerPickerCubit(searchCustomers: widget.searchCustomers);
    _cubit.loadInitial();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _selectWalkIn() {
    Navigator.of(context).pop(SalesCustomerSelection.walkIn());
  }

  void _selectCustomer(SalesCustomerListItemVm item) {
    if (item.isBlocked) {
      VToast.show(
        context,
        title: 'Không thể chọn',
        message: 'Khách hàng không còn hoạt động.',
        type: VToastType.warning,
      );
      return;
    }
    Navigator.of(context).pop(item.toSelection());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SalesCustomerPickerCubit, SalesCustomerPickerState>(
        builder: (context, state) {
          final media = MediaQuery.of(context);
          final screenH = media.size.height;
          final bottomInset = media.viewInsets.bottom;
          final topSafe = media.viewPadding.top;
          // showVBottomSheet bọc child trong Padding(bottom: keyboardInset) và thêm
          // handle (~20px) bên trong ConstrainedBox 0.95·screenH. Chiều cao SizedBox
          // phải trừ các phần này để không overflow, và chừa status bar để không dính nóc.
          final capByFraction = screenH * 0.95 - 20 - bottomInset;
          final capByTop = screenH - bottomInset - topSafe - 12 - 20;
          final cap = capByFraction < capByTop ? capByFraction : capByTop;
          final preferred = screenH * 0.72;
          final sheetH = (preferred < cap ? preferred : cap).clamp(0.0, screenH);
          return SizedBox(
            height: sheetH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const VPagePadding(
                  child: VText(
                    'Chọn khách hàng',
                    variant: VTextVariant.headingH4,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const VGap.md(),
                VPagePadding(
                  child: SalesCustomerPickerSearchBar(onSearch: _cubit.search),
                ),
                const VGap.md(),
                VPagePadding(
                  child: SalesCustomerPickerCard(
                    key: const Key('card_sg04_walk_in'),
                    title: 'Khách lẻ',
                    subtitle: 'Không phát sinh công nợ',
                    selected: widget.selectedWalkIn,
                    onTap: _selectWalkIn,
                  ),
                ),
                const VGap.sm(),
                Expanded(
                  child: SalesCustomerPickerBody(
                    state: state,
                    onTapCustomer: _selectCustomer,
                    selectedPartnerId: widget.selectedPartnerId,
                    // CTA tạo nhanh chỉ ở nút đáy sheet (3C).
                  ),
                ),
                if (widget.onCreateCustomer != null)
                  VPagePadding(
                    vertical: VSpacing.space3,
                    child: VButton(
                      key: const Key('btn_sg04_open_create_customer_sheet'),
                      label: 'Tạo nhanh khách hàng',
                      variant: VButtonVariant.secondary,
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onCreateCustomer?.call();
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

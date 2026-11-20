import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';

import '../../logic/invoice_delivery_history_cubit.dart';
import '../../logic/invoice_delivery_history_state.dart';
import '../support/order_invoice_delivery_copy.dart';
import '../widgets/invoice_delivery_history_view.dart';

/// Full-screen SG07-D01 delivery history host (authoritative query).
class InvoiceDeliveryHistoryPage extends StatelessWidget {
  const InvoiceDeliveryHistoryPage({
    super.key,
    required this.salesOrderId,
    required this.repository,
  });

  final String salesOrderId;
  final EInvoiceRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvoiceDeliveryHistoryCubit(
        salesOrderId: salesOrderId,
        repository: repository,
      )..load(),
      child: const _InvoiceDeliveryHistoryPageBody(),
    );
  }
}

class _InvoiceDeliveryHistoryPageBody extends StatelessWidget {
  const _InvoiceDeliveryHistoryPageBody();

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      title: OrderInvoiceDeliveryCopy.historyPageTitle,
      showBackButton: true,
      body: BlocBuilder<InvoiceDeliveryHistoryCubit, InvoiceDeliveryHistoryState>(
        builder: (context, state) {
          return InvoiceDeliveryHistoryView(
            state: state,
            onRetry: () => context.read<InvoiceDeliveryHistoryCubit>().load(),
          );
        },
      ),
    );
  }
}

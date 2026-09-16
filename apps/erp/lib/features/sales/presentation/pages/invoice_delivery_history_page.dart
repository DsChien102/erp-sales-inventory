import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../bloc/invoice_delivery_history_cubit.dart';
import '../bloc/invoice_delivery_history_state.dart';
import '../support/order_invoice_delivery_copy.dart';
import '../widgets/einvoice/invoice_delivery_history_view.dart';

/// Full-screen SG07-D01 delivery history host (authoritative query).
class InvoiceDeliveryHistoryPage extends StatelessWidget {
  const InvoiceDeliveryHistoryPage({
    super.key,
    required this.salesOrderId,
    required this.mediator,
    required this.executionContext,
  });

  final String salesOrderId;
  final IModuleMediator mediator;
  final IExecutionContext executionContext;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvoiceDeliveryHistoryCubit(
        salesOrderId: salesOrderId,
        executionContext: executionContext,
        mediator: mediator,
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

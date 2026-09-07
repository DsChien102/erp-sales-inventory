import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../bloc/order_einvoice_cubit.dart';
import 'order_einvoice_polling_host.dart';
import '../bloc/order_einvoice_state.dart';
import '../services/i_invoice_document_exporter.dart';
import '../services/i_invoice_viewer_launcher.dart';
import '../support/order_einvoice_idempotency_key_factory.dart';

class OrderEInvoiceSection extends StatelessWidget {
  const OrderEInvoiceSection({
    super.key,
    required this.salesOrderId,
    required this.orderVersion,
    required this.orderCode,
    this.orderTotalFormatted,
    required this.initialProjection,
    this.initialReadiness,
    this.isBuyerNotReady = false,
    required this.mediator,
    required this.executionContext,
    this.viewerLauncher,
    this.documentExporter,
    this.idempotencyKeyFactory,
    this.onCubitCreated,
    this.cubit,
  });

  /// Optional externally owned state, shared with page diagnostics.
  final OrderEInvoiceCubit? cubit;
  final String salesOrderId;
  final int orderVersion;
  final String orderCode;
  final String? orderTotalFormatted;
  final OrderInvoiceProjectionDto initialProjection;
  final IssuanceReadinessDto? initialReadiness;
  final bool isBuyerNotReady;
  final IModuleMediator mediator;
  final IExecutionContext executionContext;
  final IInvoiceViewerLauncher? viewerLauncher;
  final IInvoiceDocumentExporter? documentExporter;
  final OrderEInvoiceIdempotencyKeyFactory? idempotencyKeyFactory;
  final void Function(OrderEInvoiceCubit)? onCubitCreated;

  @override
  Widget build(BuildContext context) {
    final child = OrderEInvoicePollingHost(
      child: _OrderEInvoiceSectionView(
        orderCode: orderCode,
        orderTotalFormatted: orderTotalFormatted,
      ),
    );
    if (cubit != null) {
      return BlocProvider.value(value: cubit!, child: child);
    }
    return BlocProvider(
      create: (ctx) {
        final cubit = OrderEInvoiceCubit(
          salesOrderId: salesOrderId,
          orderVersion: orderVersion,
          initialProjection: initialProjection,
          initialReadiness: initialReadiness,
          isBuyerNotReady: isBuyerNotReady,
          executionContext: executionContext,
          mediator: mediator,
          viewerLauncher: viewerLauncher,
          documentExporter: documentExporter,
          idempotencyKeyFactory:
              idempotencyKeyFactory ?? const OrderEInvoiceIdempotencyKeyFactory(),
        );
        onCubitCreated?.call(cubit);
        return cubit;
      },
      child: child,
    );
  }
}

class _OrderEInvoiceSectionView extends StatelessWidget {
  const _OrderEInvoiceSectionView({
    required this.orderCode,
    this.orderTotalFormatted,
  });

  final String orderCode;
  final String? orderTotalFormatted;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderEInvoiceCubit, OrderEInvoiceState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading =
            state.status == OrderEInvoiceStatus.submitting ||
            state.status == OrderEInvoiceStatus.previewing ||
            state.status == OrderEInvoiceStatus.downloading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            OrderEInvoiceRow(
              projection: state.projection,
              isBuyerNotReady: state.isBuyerNotReady,
              onTap: () => _handleRowTap(context, state),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleRowTap(
    BuildContext context,
    OrderEInvoiceState state,
  ) async {
    final cubit = context.read<OrderEInvoiceCubit>();
    final issuanceState = state.projection.issuanceDisplayState;

    if (issuanceState == IssuanceDisplayState.processing) {
      return;
    }

    if (issuanceState == IssuanceDisplayState.issued) {
      PostIssueSheetState sheetState(OrderEInvoiceState value) => PostIssueSheetState(
        deliveryStatus: value.projection.deliveryDisplayState ?? DeliveryDisplayState.notSent,
        isDeliveryPending: value.projection.deliveryPending,
      );
      final action = await showPostIssueEInvoiceActionSheet(
        context,
        state: sheetState(cubit.state),
        states: cubit.stream.map(sheetState),
      );

      if (!context.mounted) return;

      if (action == PostIssueAction.viewOfficial) {
        await cubit.openOfficialView();
      } else if (action == PostIssueAction.documents) {
        final docAction = await showInvoiceDocumentsActionSheet(context);
        if (!context.mounted) return;
        if (docAction == InvoiceDocumentsAction.pdf) {
          final ok = await cubit.downloadDocument(InvoiceDocumentType.pdf);
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã tải hóa đơn PDF. Đang mở hộp thoại lưu tệp...'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else if (docAction == InvoiceDocumentsAction.xml) {
          final ok = await cubit.downloadDocument(InvoiceDocumentType.xml);
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã tải hóa đơn XML. Đang mở hộp thoại lưu tệp...'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else if (action == PostIssueAction.send) {
        final sheetContext = await cubit.getSendSheetContext();
        if (!context.mounted) return;

        String? recipientEmail;
        if (sheetContext?.mode == SendInvoiceSheetMode.resend) {
          final historyItem = sheetContext?.history.firstOrNull;
          final res = await showResendInvoiceSheet(
            context,
            latestEmail: historyItem?.recipientEmail ?? sheetContext?.suggestedEmail ?? '',
            latestDateTime: historyItem?.completedAt != null
                ? '${historyItem!.completedAt!.hour.toString().padLeft(2, '0')}:${historyItem.completedAt!.minute.toString().padLeft(2, '0')} ${historyItem.completedAt!.day.toString().padLeft(2, '0')}/${historyItem.completedAt!.month.toString().padLeft(2, '0')}/${historyItem.completedAt!.year}'
                : '—',
            initialEmail: sheetContext?.suggestedEmail ?? historyItem?.recipientEmail,
          );
          recipientEmail = res?.recipientEmail;
        } else {
          final res = await showSendInvoiceSheet(
            context,
            invoiceNumber: state.templateNumber ?? orderCode,
            invoiceSymbol: state.templateSymbol ?? '—',
            initialEmail: sheetContext?.suggestedEmail ?? '',
          );
          recipientEmail = res?.recipientEmail;
        }

        if (!context.mounted || recipientEmail == null || recipientEmail.trim().isEmpty) {
          return;
        }

        final ok = await cubit.sendInvoiceEmail(recipientEmail);
        if (ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đang gửi hóa đơn tới $recipientEmail...'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      return;
    }

    final isPreviewSupported =
        !state.isBuyerNotReady &&
        !(state.readiness?.blockers.any(
              (b) => b.code == 'PREVIEW_UNSUPPORTED',
            ) ??
            false);

    final action = await showPreIssueEInvoiceActionSheet(
      context,
      state: PreIssueSheetState(
        isBuyerNotReady: state.isBuyerNotReady,
        isPreviewEnabled: isPreviewSupported,
        isFailed: issuanceState == IssuanceDisplayState.failed,
        failureCode: state.failureCode,
        lastFailureMessage: state.lastFailureMessage,
      ),
    );

    if (!context.mounted) return;

    if (action == PreIssueAction.preview) {
      await cubit.requestPreview();
    } else if (action == PreIssueAction.issue) {
      await cubit.ensureIssuanceTemplateDisplay();
      if (!context.mounted) return;
      final display = cubit.state;
      final confirmed = await showIssueInvoiceConfirmationSheet(
        context,
        summary: IssueInvoiceConfirmationSummary(
          orderReference: orderCode,
          orderTotal: orderTotalFormatted ?? '—',
          templateNumber: display.templateNumber ?? '—',
          templateSymbol: display.templateSymbol ?? '—',
          authorityMode: display.authorityMode ?? '—',
        ),
      );

      if (confirmed) {
        await cubit.issueOrRetry();
      }
    }
  }
}

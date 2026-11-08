import 'dart:async';

import 'package:async_query_flutter/async_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:erp/features/sales/presentation/support/order_einvoice_error_message.dart';
import 'package:vet45_shared_application/application.dart';

import '../../logic/i_invoice_document_exporter.dart';
import '../../logic/i_invoice_viewer_launcher.dart';
import '../../logic/order_einvoice_cubit.dart';
import '../../logic/order_einvoice_idempotency_key_factory.dart';
import '../../logic/order_einvoice_state.dart';
import '../../logic/order_invoice_delivery_cubit.dart';
import '../pages/invoice_delivery_history_page.dart';
import 'invoice_documents_action_sheet.dart';
import 'issue_invoice_confirmation_sheet.dart';
import 'order_einvoice_polling_host.dart';
import 'order_einvoice_row.dart';
import 'post_issue_einvoice_action_sheet.dart';
import 'pre_issue_einvoice_action_sheet.dart';
import 'resend_invoice_sheet.dart';
import 'send_invoice_sheet.dart';

class OrderEInvoiceSection extends StatelessWidget {
  const OrderEInvoiceSection({
    super.key,
    required this.salesOrderId,
    required this.orderVersion,
    required this.orderCode,
    this.orderTotalFormatted,
    required this.initialProjection,
    this.hasLoadedInitialProjection = true,
    this.initialReadiness,
    this.isBuyerNotReady = false,
    this.buyerPartnerId,
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

  /// False when host seeds a placeholder projection before the first read.
  final bool hasLoadedInitialProjection;
  final IssuanceReadinessDto? initialReadiness;
  final bool isBuyerNotReady;

  /// Partner to open when the buyer-correction link is tapped. Empty hides the link.
  final String? buyerPartnerId;
  final IModuleMediator mediator;
  final IExecutionContext executionContext;
  final IInvoiceViewerLauncher? viewerLauncher;
  final IInvoiceDocumentExporter? documentExporter;
  final OrderEInvoiceIdempotencyKeyFactory? idempotencyKeyFactory;
  final void Function(OrderEInvoiceCubit)? onCubitCreated;

  @override
  Widget build(BuildContext context) {
    final child = BlocListener<OrderEInvoiceCubit, OrderEInvoiceState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null && current.errorMessage != previous.errorMessage,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message == null || message.isEmpty) return;
        VToast.show(
          context,
          title: 'Hóa đơn điện tử',
          message: message,
          type: VToastType.danger,
        );
      },
      child: OrderEInvoicePollingHost(
        child: _OrderEInvoiceSectionView(
          orderCode: orderCode,
          orderTotalFormatted: orderTotalFormatted,
          buyerPartnerId: buyerPartnerId,
          executionContext: executionContext,
          mediator: mediator,
          idempotencyKeyFactory:
              idempotencyKeyFactory ?? const OrderEInvoiceIdempotencyKeyFactory(),
        ),
      ),
    );
    if (cubit != null) {
      return BlocProvider.value(value: cubit!, child: child);
    }
    final queryClient = QueryClientProvider.of(context);
    return BlocProvider(
      create: (ctx) {
        final cubit = OrderEInvoiceCubit(
          salesOrderId: salesOrderId,
          orderVersion: orderVersion,
          initialProjection: initialProjection,
          hasLoadedInitialProjection: hasLoadedInitialProjection,
          initialReadiness: initialReadiness,
          isBuyerNotReady: isBuyerNotReady,
          executionContext: executionContext,
          mediator: mediator,
          queryClient: queryClient,
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
    this.buyerPartnerId,
    required this.executionContext,
    required this.mediator,
    required this.idempotencyKeyFactory,
  });

  final String orderCode;
  final String? orderTotalFormatted;
  final String? buyerPartnerId;
  final IExecutionContext executionContext;
  final IModuleMediator mediator;
  final OrderEInvoiceIdempotencyKeyFactory idempotencyKeyFactory;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderEInvoiceCubit, OrderEInvoiceState>(
      builder: (context, state) {
        return OrderEInvoiceRow(
          projection: state.projection,
          isBuyerNotReady: state.isBuyerNotReady,
          onTap: state.canInteract ? () => _handleRowTap(context, state) : null,
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

    final canRetry =
        issuanceState == IssuanceDisplayState.failed &&
        (state.projection.actions.contains(OrderInvoiceAction.issue) ||
            state.projection.actions.contains(OrderInvoiceAction.retryIssue));

    if (issuanceState == IssuanceDisplayState.processing ||
        (issuanceState == IssuanceDisplayState.failed && !canRetry)) {
      return;
    }

    if (issuanceState == IssuanceDisplayState.issued) {
      PostIssueSheetState sheetState(OrderEInvoiceState value) => PostIssueSheetState(
        deliveryStatus: value.projection.deliveryDisplayState ?? DeliveryDisplayState.notSent,
        isDeliveryPending: value.projection.deliveryPending,
        isOfficialViewLoading: value.isOpeningOfficialView,
        hasSecondaryAttention: value.projection.hasSecondaryAttention,
      );
      final action = await showPostIssueEInvoiceActionSheet(
        context,
        state: sheetState(cubit.state),
        states: cubit.stream.map(sheetState),
        onViewOfficial: () {
          unawaited(cubit.openOfficialView());
        },
      );

      if (!context.mounted) return;

      if (action == PostIssueAction.documents) {
        InvoiceDocumentsSheetState docsSheetState(OrderEInvoiceState value) {
          if (value.status != OrderEInvoiceStatus.downloading) {
            return InvoiceDocumentsSheetState.idle;
          }
          return value.downloadingDocumentType == InvoiceDocumentType.xml
              ? InvoiceDocumentsSheetState.loadingXml
              : InvoiceDocumentsSheetState.loadingPdf;
        }

        await showInvoiceDocumentsActionSheet(
          context,
          state: docsSheetState(cubit.state),
          states: cubit.stream.map(docsSheetState),
          onSelectPdf: () => cubit.downloadDocument(InvoiceDocumentType.pdf),
          onSelectXml: () => cubit.downloadDocument(InvoiceDocumentType.xml),
        );
      } else if (action == PostIssueAction.send) {
        await _openDeliveryFlow(context, cubit);
      }
      return;
    }

    final isPreviewSupported =
        !state.isBuyerNotReady &&
        !(state.readiness?.blockers.any(
              (b) => b.code == 'PREVIEW_UNSUPPORTED',
            ) ??
            false);

    bool providerConnected(OrderEInvoiceState value) {
      final blockers = value.readiness?.blockers;
      if (blockers == null) return true;
      return !blockers.any((blocker) => blocker.code == EInvoiceBlockedCodes.providerNotConnected);
    }

    PreIssueSheetState preIssueSheetState(OrderEInvoiceState value) {
      final issuance = value.projection.issuanceDisplayState;
      final partnerId = buyerPartnerId?.trim();
      return PreIssueSheetState(
        isPreviewLoading: value.status == OrderEInvoiceStatus.previewing,
        isBuyerNotReady: value.isBuyerNotReady,
        showBuyerCorrection: partnerId != null && partnerId.isNotEmpty,
        isPreviewEnabled: isPreviewSupported,
        isProviderConnected: providerConnected(value),
        isFailed: issuance == IssuanceDisplayState.failed,
        failureCode: value.failureCode,
        lastFailureMessage: value.lastFailureMessage,
      );
    }

    final action = await showPreIssueEInvoiceActionSheet(
      context,
      state: preIssueSheetState(cubit.state),
      states: cubit.stream.map(preIssueSheetState),
      onPreview: () {
        unawaited(_previewAndDismissSheetOnError(context, cubit));
      },
    );

    if (action == null) {
      cubit.cancelPreview();
      return;
    }

    if (!context.mounted) return;

    if (action == PreIssueAction.correctBuyer) {
      final partnerId = buyerPartnerId?.trim();
      if (partnerId != null && partnerId.isNotEmpty) {
        context.push('/partner/$partnerId/edit');
      }
      return;
    }

    if (action == PreIssueAction.issue) {
      final hasSavedTemplate = await cubit.ensureIssuanceTemplateDisplay();
      if (!context.mounted) return;
      if (!hasSavedTemplate) {
        VToast.show(
          context,
          title: 'Hóa đơn điện tử',
          message: OrderEInvoiceErrorMessage.of(
            const EInvoiceBlockedException(EInvoiceBlockedCodes.configNotReady),
          ),
          type: VToastType.danger,
        );
        return;
      }
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

  Future<void> _previewAndDismissSheetOnError(
    BuildContext context,
    OrderEInvoiceCubit cubit,
  ) async {
    await cubit.requestPreview();
    if (!context.mounted) return;
    final message = cubit.state.errorMessage;
    if (message == null || message.isEmpty) return;
    Navigator.of(context).pop();
  }

  Future<void> _openDeliveryFlow(
    BuildContext context,
    OrderEInvoiceCubit cubit,
  ) async {
    final deliveryCubit = OrderInvoiceDeliveryCubit(
      salesOrderId: cubit.state.salesOrderId,
      executionContext: executionContext,
      mediator: mediator,
      idempotencyKeyFactory: idempotencyKeyFactory,
    );
    try {
      final sheetContext = await deliveryCubit.loadContext();
      if (!context.mounted || sheetContext == null) {
        final message = deliveryCubit.state.errorMessage;
        if (message != null && context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }

      final accepted = sheetContext.mode == SendInvoiceSheetMode.send
          ? await showOrderInvoiceSendSheet(
              context,
              cubit: deliveryCubit,
              sheetContext: sheetContext,
            )
          : await showOrderInvoiceResendSheet(
              context,
              cubit: deliveryCubit,
              sheetContext: sheetContext,
              onViewHistory: (sheetNavContext) => Navigator.of(sheetNavContext).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => InvoiceDeliveryHistoryPage(
                    salesOrderId: cubit.state.salesOrderId,
                    mediator: mediator,
                    executionContext: executionContext,
                  ),
                ),
              ),
            );

      if (accepted == true && context.mounted) {
        await cubit.refresh();
      }
    } finally {
      await deliveryCubit.close();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:erp/features/sales/presentation.dart';

import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg06ResultTab extends StatelessWidget {
  const SalesSg06ResultTab({super.key});

  static const _loadedState = SalesTransactionResultState(
    status: SalesTransactionResultStatus.loaded,
  );

  static final _historyLoaded = InvoiceDeliveryHistoryState(
    status: InvoiceDeliveryHistoryStatus.loaded,
    displayState: DeliveryDisplayState.sent,
    rows: [
      InvoiceDeliveryHistoryRowVm(
        deliveryId: 'del-2',
        deliveryNo: 2,
        statusLabel: 'Gửi lỗi',
        recipientEmail: 'accounting@company.com',
        occurredAt: DateTime(2026, 8, 5, 16, 20),
        actorLabel: 'Người dùng',
        tone: VComponentTone.danger,
      ),
      InvoiceDeliveryHistoryRowVm(
        deliveryId: 'del-1',
        deliveryNo: 1,
        statusLabel: 'Đã gửi',
        recipientEmail: 'customer@company.com',
        occurredAt: DateTime(2026, 8, 5, 16, 12),
        actorLabel: 'Tự động',
        tone: VComponentTone.success,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return previewList([
      const PreviewSection(
        title: 'SalesResultLoadingView',
        child: SizedBox(height: 120, child: SalesResultLoadingView()),
      ),
      PreviewSection(
        title: 'SalesResultFailureView',
        child: SalesResultFailureView(
          message: 'Đơn đã được tạo. Thử tải lại và không thanh toán lại.',
          onRetry: () {},
        ),
      ),
      PreviewSection(
        title: 'SalesReceiptEntryCard / SalesEInvoiceEntryCard',
        description: 'Hàng chứng từ dùng chung cho hub SG-06 và SG-08.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewStateRow(
              label: 'Phiếu — idle',
              child: SalesReceiptEntryCard(onTap: () {}),
            ),
            const PreviewStateRow(
              label: 'Phiếu — đang tạo (khóa tap)',
              child: SalesReceiptEntryCard(
                subtitle: 'Đang tạo phiếu bán hàng',
                onTap: null,
              ),
            ),
            PreviewStateRow(
              label: 'Phiếu — lỗi',
              child: SalesReceiptEntryCard(
                title: 'Tạo lại phiếu bán hàng',
                subtitle: 'Không thể tạo phiếu, hãy thử lại',
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'HĐĐT — chưa phát hành',
              child: SalesEInvoiceEntryCard(
                badgeLabel: 'Chưa phát hành',
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'HĐĐT — đang xử lý',
              child: SalesEInvoiceEntryCard(
                badgeLabel: 'Đang xử lý',
                badgeTone: VComponentTone.primary,
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'HĐĐT — đã phát hành',
              child: SalesEInvoiceEntryCard(
                badgeLabel: 'Đã phát hành',
                badgeTone: VComponentTone.success,
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'HĐĐT — lỗi',
              child: SalesEInvoiceEntryCard(
                badgeLabel: 'Lỗi',
                badgeTone: VComponentTone.danger,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
      const PreviewSection(
        title: 'SalesResultPartialBanner',
        child: SalesResultPartialBanner(
          issues: [SalesTransactionResultIssue.projectionPending],
        ),
      ),
      PreviewSection(
        title: 'SalesResultHeaderCard / CustomerCard / PaymentSummary',
        description:
            'Leaf widgets nhận SalesTransactionResultState. Body đầy đủ '
            'cần Cubit — không preview ở catalog.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Header',
              child: SalesResultHeaderCard(
                state: _loadedState,
                onViewOrderDetail: () {},
              ),
            ),
            const PreviewStateRow(
              label: 'Customer',
              child: SalesResultCustomerCard(state: _loadedState),
            ),
            const PreviewStateRow(
              label: 'Payment summary',
              child: SalesResultPaymentSummaryCard(state: _loadedState),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesTransactionResultActionBar',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Success',
              child: SalesTransactionResultActionBar(
                onGoHome: () {},
                onCreateNewOrder: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Error',
              child: SalesTransactionResultActionBar(
                isErrorState: true,
                onGoHome: () {},
                onCreateNewOrder: () {},
                onRetryLoad: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'HĐĐT post-issued / SG-06 (app-owned S4)',
        description:
            'Specimen idle + loading; catalog không gọi MISA hay OS file exporter.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewStateRow(
              label: 'SG-02 O05 — post-issued idle',
              child: PostIssueEInvoiceActionSheet(onViewOfficial: () {}),
            ),
            PreviewStateRow(
              label: 'SG-02 O06 — official view loading',
              child: PostIssueEInvoiceActionSheet(
                state: PostIssueSheetState.officialViewLoading,
                onViewOfficial: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Prior sent + secondary attention',
              child: PostIssueEInvoiceActionSheet(
                state: const PostIssueSheetState(
                  deliveryStatus: DeliveryDisplayState.sent,
                  hasSecondaryAttention: true,
                ),
                onViewOfficial: () {},
              ),
            ),
            const PreviewStateRow(
              label: 'SG-06 O01 — documents idle',
              child: InvoiceDocumentsActionSheet(),
            ),
            const PreviewStateRow(
              label: 'SG-06 O02 — loading PDF (XML disabled)',
              child: InvoiceDocumentsActionSheet(
                state: InvoiceDocumentsSheetState.loadingPdf,
              ),
            ),
            const PreviewStateRow(
              label: 'SG-06 O03 — loading XML (PDF disabled)',
              child: InvoiceDocumentsActionSheet(
                state: InvoiceDocumentsSheetState.loadingXml,
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'HĐĐT SG-07 — gửi và lịch sử',
        description:
            'App-owned specimens; const/fake only — không gọi mediator/worker/MISA.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewStateRow(
              label: 'SG07-O01-A suggestion Partner',
              child: _catalogRecipientForm(
                title: OrderInvoiceDeliveryCopy.sendTitle,
                email: 'buyer@partner.test',
                sourceLabel: 'Hồ sơ khách hàng',
              ),
            ),
            PreviewStateRow(
              label: 'SG07-O01-B email rỗng',
              child: _catalogRecipientForm(
                title: OrderInvoiceDeliveryCopy.sendTitle,
                email: '',
              ),
            ),
            PreviewStateRow(
              label: 'SG07-O01-C invalid',
              child: _catalogRecipientForm(
                title: OrderInvoiceDeliveryCopy.sendTitle,
                email: 'bad',
                showValidationError: true,
              ),
            ),
            PreviewStateRow(
              label: 'SG07-O01-D loading',
              child: _catalogRecipientForm(
                title: OrderInvoiceDeliveryCopy.sendTitle,
                email: 'buyer@partner.test',
                isSubmitting: true,
              ),
            ),
            PreviewStateRow(
              label: 'SG07-O02 resend',
              child: _catalogRecipientForm(
                title: OrderInvoiceDeliveryCopy.resendTitle,
                email: 'accounting@company.com',
                summary: OrderInvoiceDeliveryCopy.latestDeliverySummary(
                  email: 'accounting@company.com',
                  dateTime: '05/08/2026, 16:20',
                ),
                showHistoryLink: true,
              ),
            ),
            PreviewStateRow(
              label: 'SG07-O02 locked PROCESSING — history enabled',
              child: _catalogRecipientForm(
                title: OrderInvoiceDeliveryCopy.resendTitle,
                email: 'accounting@company.com',
                operationLocked: true,
                showHistoryLink: true,
              ),
            ),
            PreviewStateRow(
              label: 'SG07-O02 sau UNKNOWN — CTA enabled',
              child: _catalogRecipientForm(
                title: OrderInvoiceDeliveryCopy.resendTitle,
                email: 'buyer@fake.test',
                showHistoryLink: true,
              ),
            ),
            PreviewStateRow(
              label: 'SG07-D01 nhiều delivery',
              child: SizedBox(
                height: 280,
                child: InvoiceDeliveryHistoryView(
                  state: _historyLoaded,
                  onRetry: () {},
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Sheets',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Receipt actions',
              onPressed: () => showSalesResultReceiptSheet(context),
            ),
            const PreviewStateRow(
              label: 'E-invoice',
              child: VText(
                'HĐĐT production hiển thị OrderEInvoiceSection trực tiếp trên '
                'SalesResultDocumentsSection (SG02-R02); trạng thái dùng projection '
                'qua IModuleMediator. Sheet post-issued/SG-06 nằm ở specimen phía trên.',
                variant: VTextVariant.bodySmall,
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

Widget _catalogRecipientForm({
  required String title,
  required String email,
  String? sourceLabel,
  String? summary,
  bool showValidationError = false,
  bool isSubmitting = false,
  bool operationLocked = false,
  bool showHistoryLink = false,
}) {
  final controller = TextEditingController(text: email);
  return Material(
    color: Colors.transparent,
    child: Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          VText(
            title,
            variant: VTextVariant.headingH3,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (summary != null) ...[
            const VGap.sm(),
            VText(summary, variant: VTextVariant.bodyDefault),
          ],
          const VGap.md(),
          InvoiceDeliveryRecipientForm(
            emailController: controller,
            primaryLabel: OrderInvoiceDeliveryCopy.sendAction,
            isSubmitting: isSubmitting,
            operationLocked: operationLocked,
            showValidationError: showValidationError,
            onChanged: (_) {},
            onPrimary:
                (isSubmitting ||
                    operationLocked ||
                    showValidationError ||
                    !OrderInvoiceDeliveryCopy.isValidEmail(email))
                ? null
                : () {},
            onCancel: isSubmitting ? null : () {},
            sourceLabel: sourceLabel == null
                ? null
                : VText(sourceLabel, variant: VTextVariant.bodySmall),
            footerAboveActions: showHistoryLink
                ? Align(
                    alignment: Alignment.center,
                    child: VButton(
                      label: OrderInvoiceDeliveryCopy.viewHistory,
                      variant: VButtonVariant.link,
                      onPressed: isSubmitting ? null : () {},
                    ),
                  )
                : null,
          ),
        ],
      ),
    ),
  );
}

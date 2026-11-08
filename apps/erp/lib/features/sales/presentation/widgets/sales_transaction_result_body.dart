import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_cubit.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_state.dart';
import 'sales_result_customer_card.dart';
import 'sales_result_failure_view.dart';
import 'sales_result_documents_section.dart';
import 'sales_result_header_card.dart';
import 'sales_result_loading_view.dart';
import 'sales_result_partial_banner.dart';
import 'sales_result_payment_summary_card.dart';
import 'package:erp/features/einvoice/data/i_invoice_viewer_launcher.dart';
import 'package:erp/features/einvoice/data/i_invoice_document_exporter.dart';

class SalesTransactionResultBody extends StatelessWidget {
  const SalesTransactionResultBody({
    super.key,
    required this.onViewOrderDetail,
    this.eInvoiceRepository,
    this.eInvoiceConfigurationRepository,
    this.viewerLauncher,
    this.documentExporter,
  });

  final VoidCallback onViewOrderDetail;
  final EInvoiceRepository? eInvoiceRepository;
  final EInvoiceConfigurationRepository? eInvoiceConfigurationRepository;
  final IInvoiceViewerLauncher? viewerLauncher;
  final IInvoiceDocumentExporter? documentExporter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesTransactionResultCubit, SalesTransactionResultState>(
      builder: (context, state) {
        final cubit = context.read<SalesTransactionResultCubit>();
        if (state.status == SalesTransactionResultStatus.loading ||
            state.status == SalesTransactionResultStatus.initial) {
          return const SalesResultLoadingView();
        }
        if (state.status == SalesTransactionResultStatus.failure) {
          return SalesResultFailureView(
            message: 'Đơn đã được tạo. Thử tải lại và không thanh toán lại.',
            onRetry: cubit.retryLoad,
          );
        }

        return SingleChildScrollView(
          child: VPagePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const VGap.sm(),
                SalesResultHeaderCard(
                  state: state,
                  onViewOrderDetail: onViewOrderDetail,
                ),
                const VGap.md(),
                SalesResultCustomerCard(state: state),
                const VGap.md(),
                if (state.status == SalesTransactionResultStatus.partial) ...[
                  SalesResultPartialBanner(issues: state.issues),
                  const VGap.md(),
                ],
                if (state.receipt.status == SalesReceiptOperationStatus.error) ...[
                  _buildReceiptErrorBanner(),
                  const VGap.md(),
                ],
                SalesResultPaymentSummaryCard(state: state),
                const VGap.md(),
                SalesResultDocumentsSection(
                  state: state,
                  cubit: cubit,
                  eInvoiceRepository: eInvoiceRepository,
                  eInvoiceConfigurationRepository: eInvoiceConfigurationRepository,
                  viewerLauncher: viewerLauncher,
                  documentExporter: documentExporter,
                ),
                const VGap.xl(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptErrorBanner() {
    return const VBanner(
      title: 'Đơn văn đã hoàn tất. Chưa thể tạo phiếu bán hàng. Không thanh toán hoặc tạo lại đơn.',
      status: VBannerStatus.warning,
    );
  }
}

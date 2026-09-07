import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

import 'preview_helpers.dart';
import 'preview_section.dart';

class EInvoiceSg03Tab extends StatelessWidget {
  const EInvoiceSg03Tab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return previewList([
      // --- O01-A / O02 ---
      PreviewSection(
        title: 'SG03-O01-A — Chi tiết đơn hàng / Xác nhận phát hành',
        description: 'IssueInvoiceConfirmationSheet · order detail host',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IssueInvoiceConfirmationSheet(
              summary: IssueInvoiceConfirmationSummary.previewFixture,
              onConfirm: previewNoop,
              onCancel: previewNoop,
            ),
            Builder(
              builder: (ctx) => PreviewActionButton(
                label: 'Open confirmation sheet',
                onPressed: () => showIssueInvoiceConfirmationSheet(
                  ctx,
                  summary: IssueInvoiceConfirmationSummary.previewFixture,
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SG03-O02 — Kết quả bán hàng / Xác nhận phát hành',
        description:
            'IssueInvoiceConfirmationSheet · same widget, sales result host',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IssueInvoiceConfirmationSheet(
              summary: IssueInvoiceConfirmationSummary.previewFixture,
              onConfirm: previewNoop,
              onCancel: previewNoop,
            ),
            Builder(
              builder: (ctx) => PreviewActionButton(
                label: 'Open confirmation sheet (sales result)',
                onPressed: () => showIssueInvoiceConfirmationSheet(
                  ctx,
                  summary: IssueInvoiceConfirmationSummary.previewFixture,
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SG03-O01-B — Cảnh báo thiếu mã số thuế',
        description:
            'GAP-01 unresolved — do not invent warning confirmation UI',
        child: Text(
          'Unresolved: SRS/Audit yêu cầu warning confirmation; '
          'approved design không có frame và chỉ confirm khi READY.',
          style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
        ),
      ),

      // --- R01 / R02 / R03 ---
      PreviewSection(
        title: 'SG03-R01 — Chi tiết đơn hàng — Đang xử lý',
        description: 'OrderEInvoiceRow · processing (reuse SG-02)',
        child: OrderEInvoiceRow(
          projection: FakeEInvoiceFixtures.projection(
            issuance: IssuanceDisplayState.processing,
          ),
          onTap: previewNoop,
        ),
      ),
      PreviewSection(
        title: 'SG03-R02 — Chi tiết đơn hàng — Phát hành lỗi',
        description: 'OrderEInvoiceRow · failed + IssueFailureToast',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderEInvoiceRow(
              projection: FakeEInvoiceFixtures.projection(
                issuance: IssuanceDisplayState.failed,
              ),
              onTap: previewNoop,
            ),
            const SizedBox(height: VSpacing.space2),
            const IssuanceFailureBanner(failureCode: 'COMMAND_INTEGRITY'),
            const SizedBox(height: VSpacing.space2),
            Builder(
              builder: (ctx) => PreviewActionButton(
                label: 'Show issue failure toast',
                onPressed: () => IssueFailureToast.show(ctx),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SG03-R03 — Kết quả bán hàng — Đang xử lý',
        description: 'OrderEInvoiceRow · processing (reuse SG-02)',
        child: OrderEInvoiceRow(
          projection: FakeEInvoiceFixtures.projection(
            issuance: IssuanceDisplayState.processing,
          ),
          onTap: previewNoop,
        ),
      ),

      // --- T01 / T02 ---
      PreviewSection(
        title: 'SG03-T01 — Chi tiết đơn hàng — Phát hành thành công',
        description: 'OrderEInvoiceRow · issued + IssueSuccessToast',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderEInvoiceRow(
              projection: FakeEInvoiceFixtures.projection(
                issuance: IssuanceDisplayState.issued,
                delivery: DeliveryDisplayState.sent,
              ),
              onTap: previewNoop,
            ),
            const SizedBox(height: VSpacing.space2),
            Builder(
              builder: (ctx) => PreviewActionButton(
                label: 'Show issue success toast',
                onPressed: () => IssueSuccessToast.show(ctx),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SG03-T02 — Kết quả bán hàng — Phát hành thành công',
        description:
            'OrderEInvoiceRow · issued + IssueSuccessToast (sales result host)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderEInvoiceRow(
              projection: FakeEInvoiceFixtures.projection(
                issuance: IssuanceDisplayState.issued,
                delivery: DeliveryDisplayState.sent,
              ),
              onTap: previewNoop,
            ),
            const SizedBox(height: VSpacing.space2),
            Builder(
              builder: (ctx) => PreviewActionButton(
                label: 'Show issue success toast (sales result)',
                onPressed: () => IssueSuccessToast.show(ctx),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

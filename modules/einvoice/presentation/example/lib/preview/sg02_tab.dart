import 'package:flutter/material.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

import 'preview_helpers.dart';
import 'preview_section.dart';

class EInvoiceSg02Tab extends StatelessWidget {
  const EInvoiceSg02Tab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      // --- R01 / R02 ---
      PreviewSection(
        title: 'SG02-R01 — Chi tiết đơn hàng — Chưa phát hành',
        description: 'OrderEInvoiceRow · notIssued',
        child: OrderEInvoiceRow(
          projection: FakeEInvoiceFixtures.projection(
            issuance: IssuanceDisplayState.notIssued,
          ),
          isBuyerNotReady: true,
          onTap: previewNoop,
        ),
      ),
      PreviewSection(
        title: 'SG02-R02 — Kết quả bán hàng — Chưa phát hành',
        description:
            'OrderEInvoiceRow · notIssued (same widget, salesResult context)',
        child: OrderEInvoiceRow(
          projection: FakeEInvoiceFixtures.projection(
            issuance: IssuanceDisplayState.notIssued,
          ),
          isBuyerNotReady: true,
          onTap: previewNoop,
        ),
      ),
      PreviewSection(
        title: 'SG02-R01 variant — Đã phát hành',
        description: 'OrderEInvoiceRow · issued',
        child: OrderEInvoiceRow(
          projection: FakeEInvoiceFixtures.projection(
            issuance: IssuanceDisplayState.issued,
            delivery: DeliveryDisplayState.sent,
          ),
          onTap: previewNoop,
        ),
      ),
      PreviewSection(
        title: 'SG02-R01 variant — Đang xử lý',
        description: 'OrderEInvoiceRow · processing',
        child: OrderEInvoiceRow(
          projection: FakeEInvoiceFixtures.projection(
            issuance: IssuanceDisplayState.processing,
          ),
          onTap: previewNoop,
        ),
      ),

      // --- O01–O04 + buyerNotReady ---
      PreviewSection(
        title: 'SG02-O01 — Menu HĐĐT trước phát hành (idle)',
        description: 'PreIssueEInvoiceActionSheet · idle',
        child: const PreIssueEInvoiceActionSheet(
          state: PreIssueSheetState.idle,
        ),
      ),
      PreviewSection(
        title: 'SG02-O02 — Preview loading',
        description: 'PreIssueEInvoiceActionSheet · previewLoading',
        child: const PreIssueEInvoiceActionSheet(
          state: PreIssueSheetState.previewLoading,
        ),
      ),
      PreviewSection(
        title: 'SG02-O07 — Buyer NOT_READY',
        description: 'PreIssueEInvoiceActionSheet · buyerNotReady',
        child: const PreIssueEInvoiceActionSheet(
          state: PreIssueSheetState.buyerNotReady,
        ),
      ),
      PreviewSection(
        title: 'SG02-O08 — Phát hành lỗi (Retry scenario banner)',
        description: 'PreIssueEInvoiceActionSheet · isFailed + failureCode',
        child: const PreIssueEInvoiceActionSheet(
          state: PreIssueSheetState(
            isFailed: true,
            failureCode: 'COMMAND_INTEGRITY',
          ),
        ),
      ),

      // --- D01 / D02 ---
      PreviewSection(
        title: 'SG02-D01 — Blocker: Thiết lập HĐĐT',
        description: 'ConfigurationBlockerResult',
        child: PreviewEmbedFrame(
          height: 480,
          child: ConfigurationBlockerResult(
            onOpenSettings: previewNoop,
            onBack: previewNoop,
          ),
        ),
      ),
      PreviewSection(
        title: 'SG02-D02 — Blocker: Thông tin đơn hàng',
        description: 'OrderDataBlockerResult',
        child: PreviewEmbedFrame(
          height: 480,
          child: OrderDataBlockerResult(
            onUpdateProfile: previewNoop,
            onBack: previewNoop,
          ),
        ),
      ),

      // --- T01 ---
      PreviewSection(
        title: 'SG02-T01 — Preview failure toast',
        description: 'Tap button to show toast',
        child: Builder(
          builder: (ctx) => PreviewActionButton(
            label: 'Show preview failure toast',
            onPressed: () => PreviewFailureToast.show(ctx),
          ),
        ),
      ),

      for (final status in [
        DeliveryDisplayState.sending,
        DeliveryDisplayState.sent,
        DeliveryDisplayState.failed,
      ])
        PreviewSection(
          title: 'SG02-O05 — Email · ${status.name}',
          child: PostIssueEInvoiceActionSheet(
            state: PostIssueSheetState(
              deliveryStatus: status,
            ),
          ),
        ),
      // --- O05 (delivery variants) ---
      const PreviewSection(
        title: 'SG02-O05-A — Đã phát hành · Chưa gửi',
        description: 'PostIssueEInvoiceActionSheet · notSent',
        child: PostIssueEInvoiceActionSheet(state: PostIssueSheetState.idle),
      ),
      const PreviewSection(
        title: 'SG02-O05-B — Đã phát hành · Đang gửi',
        description: 'PostIssueEInvoiceActionSheet · sending',
        child: PostIssueEInvoiceActionSheet(
          state: PostIssueSheetState(
            deliveryStatus: DeliveryDisplayState.sending,
          ),
        ),
      ),
      const PreviewSection(
        title: 'SG02-O05-C — Đã phát hành · Đã gửi',
        description: 'PostIssueEInvoiceActionSheet · sent',
        child: PostIssueEInvoiceActionSheet(
          state: PostIssueSheetState(deliveryStatus: DeliveryDisplayState.sent),
        ),
      ),
      const PreviewSection(
        title: 'SG02-O05-D — Đã phát hành · Gửi lỗi',
        description: 'PostIssueEInvoiceActionSheet · sendFailed',
        child: PostIssueEInvoiceActionSheet(
          state: PostIssueSheetState(
            deliveryStatus: DeliveryDisplayState.failed,
          ),
        ),
      ),
      const PreviewSection(
        title: 'SG02-O06 — Official-view loading',
        description: 'PostIssueEInvoiceActionSheet · officialViewLoading',
        child: PostIssueEInvoiceActionSheet(
          state: PostIssueSheetState.officialViewLoading,
        ),
      ),
    ]);
  }
}

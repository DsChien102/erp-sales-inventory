/// Single source of truth for TH-08 §6.5 screen/state specimens (38 MVP items).
abstract final class EInvoiceAuditManifest {
  static const entries = <EInvoiceAuditEntry>[
    // SG-01 — EP-01 / Slice S1
    EInvoiceAuditEntry(
      specimenId: 'SG01-D01',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Tổng quan — Chưa sẵn sàng',
      surfaceType: 'Full-screen route',
      plannedWidgetPath:
          'apps/erp/lib/features/einvoice/presentation/pages/einvoice_configuration_overview_page.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG01-D02',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Tổng quan — Sẵn sàng',
      surfaceType: 'Full-screen route',
      plannedWidgetPath:
          'apps/erp/lib/features/einvoice/presentation/pages/einvoice_configuration_overview_page.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG01-D04-A',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Kết nối MISA — Chưa kết nối',
      surfaceType: 'Full-screen editor',
      plannedWidgetPath:
          'apps/erp/lib/features/einvoice/presentation/pages/provider_connection_page.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG01-D04-B',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Kết nối MISA — Đã kết nối',
      surfaceType: 'Full-screen editor',
      plannedWidgetPath:
          'apps/erp/lib/features/einvoice/presentation/pages/provider_connection_page.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG01-D05',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Cấu hình phát hành mặc định',
      surfaceType: 'Full-screen editor',
      plannedWidgetPath:
          'apps/erp/lib/features/einvoice/presentation/pages/default_issuance_configuration_page.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG01-D06',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Chính sách tự động',
      surfaceType: 'Full-screen editor',
      plannedWidgetPath:
          'apps/erp/lib/features/einvoice/presentation/pages/automation_policy_page.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG01-O01',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Xác nhận ngắt kết nối',
      surfaceType: 'Confirmation Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/disconnect_provider_sheet.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG01-O02',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Thao tác kết nối',
      surfaceType: 'Action Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/provider_connection_action_sheet.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG01-S01',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Không có quyền',
      surfaceType: 'State Message',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/configuration_permission_denied_state.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG01-S02',
      screenGroup: EInvoiceScreenGroup.sg01,
      title: 'Không tải được thiết lập',
      surfaceType: 'State Message',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/configuration_load_error_state.dart',
      status: AuditStatus.done,
    ),

    // SG-02 — EP-02+03 / Slice S2
    EInvoiceAuditEntry(
      specimenId: 'SG02-R01',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Chi tiết đơn hàng — HĐĐT chưa phát hành',
      surfaceType: 'Contextual row',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/order_einvoice_row.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-R02',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Kết quả bán hàng — HĐĐT chưa phát hành',
      surfaceType: 'Contextual row',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/order_einvoice_row.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-O01',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Menu HĐĐT trước phát hành',
      surfaceType: 'Action Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/pre_issue_einvoice_action_sheet.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-O02',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Đang chuẩn bị bản xem trước',
      surfaceType: 'Action Sheet variant',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/pre_issue_einvoice_action_sheet.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-O03',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Kết quả bán hàng — Menu HĐĐT',
      surfaceType: 'Action Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/pre_issue_einvoice_action_sheet.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-O04',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Kết quả bán hàng — Đang chuẩn bị preview',
      surfaceType: 'Action Sheet variant',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/pre_issue_einvoice_action_sheet.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-D01',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Blocker — Thiết lập HĐĐT',
      surfaceType: 'Full-screen result',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/configuration_blocker_result.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-D02',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Blocker — Thông tin đơn hàng',
      surfaceType: 'Full-screen result',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/order_data_blocker_result.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-T01',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Không thể tạo bản xem trước',
      surfaceType: 'Toast on source owner',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/preview_failure_toast.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-O05',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Menu HĐĐT sau phát hành',
      surfaceType: 'Action Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/post_issue_einvoice_action_sheet.dart',
      status: AuditStatus.done,
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG02-O06',
      screenGroup: EInvoiceScreenGroup.sg02,
      title: 'Đang mở hóa đơn từ MISA',
      surfaceType: 'Action Sheet variant',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/post_issue_einvoice_action_sheet.dart',
      status: AuditStatus.done,
    ),

    // SG-03 — EP-02 / Slice S3
    EInvoiceAuditEntry(
      specimenId: 'SG03-O01-A',
      screenGroup: EInvoiceScreenGroup.sg03,
      title: 'Xác nhận phát hành hóa đơn điện tử',
      surfaceType: 'Confirmation Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/issue_invoice_confirmation_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG03-O01-B',
      screenGroup: EInvoiceScreenGroup.sg03,
      title: 'Cảnh báo thiếu mã số thuế',
      surfaceType: 'Confirmation Sheet variant',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/issue_invoice_confirmation_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG03-R01',
      screenGroup: EInvoiceScreenGroup.sg03,
      title: 'Chi tiết đơn hàng — Đang xử lý',
      surfaceType: 'Contextual row',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/order_einvoice_row.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG03-R02',
      screenGroup: EInvoiceScreenGroup.sg03,
      title: 'Chi tiết đơn hàng — Phát hành lỗi',
      surfaceType: 'Contextual row + feedback',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/order_einvoice_row.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG03-T01',
      screenGroup: EInvoiceScreenGroup.sg03,
      title: 'Chi tiết đơn hàng — Phát hành thành công',
      surfaceType: 'Toast on source owner',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/issue_success_toast.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG03-O02',
      screenGroup: EInvoiceScreenGroup.sg03,
      title: 'Kết quả bán hàng — Xác nhận phát hành',
      surfaceType: 'Confirmation Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/issue_invoice_confirmation_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG03-R03',
      screenGroup: EInvoiceScreenGroup.sg03,
      title: 'Kết quả bán hàng — Đang xử lý',
      surfaceType: 'Contextual row',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/order_einvoice_row.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG03-T02',
      screenGroup: EInvoiceScreenGroup.sg03,
      title: 'Kết quả bán hàng — Phát hành thành công',
      surfaceType: 'Toast on source owner',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/issue_success_toast.dart',
    ),

    // SG-06 — EP-03 / Slice S4
    EInvoiceAuditEntry(
      specimenId: 'SG06-O01',
      screenGroup: EInvoiceScreenGroup.sg06,
      title: 'Chọn tài liệu XML/PDF',
      surfaceType: 'Action Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/invoice_documents_action_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG06-O02',
      screenGroup: EInvoiceScreenGroup.sg06,
      title: 'Đang chuẩn bị bản PDF',
      surfaceType: 'Action Sheet variant',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/invoice_documents_action_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG06-O03',
      screenGroup: EInvoiceScreenGroup.sg06,
      title: 'Đang chuẩn bị tệp XML',
      surfaceType: 'Action Sheet variant',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/invoice_documents_action_sheet.dart',
    ),

    // SG-07 — EP-04 / Slice S5
    EInvoiceAuditEntry(
      specimenId: 'SG07-O01-A',
      screenGroup: EInvoiceScreenGroup.sg07,
      title: 'Gửi hóa đơn — Có email đề xuất',
      surfaceType: 'Send Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/send_invoice_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG07-O01-B',
      screenGroup: EInvoiceScreenGroup.sg07,
      title: 'Gửi hóa đơn — Chưa có email',
      surfaceType: 'Send Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/send_invoice_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG07-O01-C',
      screenGroup: EInvoiceScreenGroup.sg07,
      title: 'Gửi hóa đơn — Email không hợp lệ',
      surfaceType: 'Send Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/send_invoice_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG07-O01-D',
      screenGroup: EInvoiceScreenGroup.sg07,
      title: 'Đang gửi hóa đơn',
      surfaceType: 'Send Sheet variant',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/send_invoice_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG07-O02',
      screenGroup: EInvoiceScreenGroup.sg07,
      title: 'Gửi lại hóa đơn',
      surfaceType: 'Resend Sheet',
      plannedWidgetPath:
          'modules/einvoice/presentation/lib/src/widgets/resend_invoice_sheet.dart',
    ),
    EInvoiceAuditEntry(
      specimenId: 'SG07-D01',
      screenGroup: EInvoiceScreenGroup.sg07,
      title: 'Lịch sử gửi hóa đơn',
      surfaceType: 'Full-screen route',
      plannedWidgetPath:
          'apps/erp/lib/features/einvoice/presentation/pages/invoice_delivery_history_page.dart',
    ),
  ];

  static List<EInvoiceAuditEntry> forGroup(EInvoiceScreenGroup group) => entries
      .where((entry) => entry.screenGroup == group)
      .toList(growable: false);
}

enum AuditStatus { pending, stub, done }

enum EInvoiceScreenGroup {
  sg01('SG-01', 'EP-01', 'S1'),
  sg02('SG-02', 'EP-02', 'S2'),
  sg03('SG-03', 'EP-02', 'S3'),
  sg06('SG-06', 'EP-03', 'S4'),
  sg07('SG-07', 'EP-04', 'S5');

  const EInvoiceScreenGroup(this.id, this.epicRef, this.sliceRef);

  final String id;
  final String epicRef;
  final String sliceRef;
}

class EInvoiceAuditEntry {
  const EInvoiceAuditEntry({
    required this.specimenId,
    required this.screenGroup,
    required this.title,
    required this.surfaceType,
    required this.plannedWidgetPath,
    this.status = AuditStatus.pending,
  });

  final String specimenId;
  final EInvoiceScreenGroup screenGroup;
  final String title;
  final String surfaceType;
  final String plannedWidgetPath;
  final AuditStatus status;

  String get statusLabel => switch (status) {
    AuditStatus.pending => 'Chưa làm',
    AuditStatus.stub => 'Stub',
    AuditStatus.done => 'Done',
  };
}

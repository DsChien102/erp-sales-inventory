import 'package:equatable/equatable.dart';

import 'receipt_header_draft.dart';
import 'receipt_item_draft.dart';

enum ReceiptStatus {
  pendingApproval,
  completed,
  rejected,
  processing,
  executionUnknown,
  executionRejected,
}

class ReceiptDocumentModel extends Equatable {
  const ReceiptDocumentModel({
    required this.id,
    required this.header,
    required this.items,
    required this.status,
    required this.submittedById,
    required this.submittedByName,
    required this.submittedAt,
    this.decidedById,
    this.decidedByName,
    this.decidedAt,
    this.rejectReason,
    this.executedAt,
  });

  final String id;
  final ReceiptHeaderDraft header;
  final List<ReceiptItemDraft> items;
  final ReceiptStatus status;
  final String submittedById;
  final String submittedByName;
  final DateTime submittedAt;
  final String? decidedById;
  final String? decidedByName;
  final DateTime? decidedAt;
  final String? rejectReason;
  final DateTime? executedAt;

  double get totalPhysicalStock =>
      items.fold(0.0, (sum, i) => sum + i.totalPhysicalStock);

  int get totalItemsCount => items.length;

  ReceiptDocumentModel copyWith({
    String? id,
    ReceiptHeaderDraft? header,
    List<ReceiptItemDraft>? items,
    ReceiptStatus? status,
    String? submittedById,
    String? submittedByName,
    DateTime? submittedAt,
    String? decidedById,
    String? decidedByName,
    DateTime? decidedAt,
    String? rejectReason,
    DateTime? executedAt,
  }) {
    return ReceiptDocumentModel(
      id: id ?? this.id,
      header: header ?? this.header,
      items: items ?? this.items,
      status: status ?? this.status,
      submittedById: submittedById ?? this.submittedById,
      submittedByName: submittedByName ?? this.submittedByName,
      submittedAt: submittedAt ?? this.submittedAt,
      decidedById: decidedById ?? this.decidedById,
      decidedByName: decidedByName ?? this.decidedByName,
      decidedAt: decidedAt ?? this.decidedAt,
      rejectReason: rejectReason ?? this.rejectReason,
      executedAt: executedAt ?? this.executedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        header,
        items,
        status,
        submittedById,
        submittedByName,
        submittedAt,
        decidedById,
        decidedByName,
        decidedAt,
        rejectReason,
        executedAt,
      ];
}

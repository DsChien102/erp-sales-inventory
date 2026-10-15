import 'package:equatable/equatable.dart';

import '../data/models/receipt_actor.dart';
import '../data/models/receipt_document_model.dart';

sealed class ReceiptApprovalState extends Equatable {
  const ReceiptApprovalState();

  @override
  List<Object?> get props => [];
}

class ReceiptApprovalInitial extends ReceiptApprovalState {
  const ReceiptApprovalInitial();
}

class ReceiptApprovalLoading extends ReceiptApprovalState {
  const ReceiptApprovalLoading();
}

class ReceiptApprovalLoaded extends ReceiptApprovalState {
  const ReceiptApprovalLoaded({
    required this.document,
    required this.actor,
    this.isProcessing = false,
    this.actionError,
  });

  final ReceiptDocumentModel document;
  final ReceiptActor actor;
  final bool isProcessing;
  final String? actionError;

  bool get isSelfApproval => document.submittedById == actor.id;
  bool get isDecided => document.status != ReceiptStatus.pendingApproval;
  bool get canDecide => !isSelfApproval && !isDecided;

  ReceiptApprovalLoaded copyWith({
    ReceiptDocumentModel? document,
    ReceiptActor? actor,
    bool? isProcessing,
    String? actionError,
    bool clearActionError = false,
  }) {
    return ReceiptApprovalLoaded(
      document: document ?? this.document,
      actor: actor ?? this.actor,
      isProcessing: isProcessing ?? this.isProcessing,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [document, actor, isProcessing, actionError];
}

class ReceiptApprovalSuccess extends ReceiptApprovalState {
  const ReceiptApprovalSuccess(this.document);

  final ReceiptDocumentModel document;

  @override
  List<Object?> get props => [document];
}

class ReceiptApprovalPermissionDenied extends ReceiptApprovalState {
  const ReceiptApprovalPermissionDenied();
}

class ReceiptApprovalNotFound extends ReceiptApprovalState {
  const ReceiptApprovalNotFound();
}

class ReceiptApprovalError extends ReceiptApprovalState {
  const ReceiptApprovalError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';

import '../data/receivable_models.dart';
import 'receivable_allocation.dart';

enum CollectionStep { form, confirm }

enum CollectionPhase { idle, submitting, error, changed, success }

class CustomerCollectionState extends Equatable {
  const CustomerCollectionState({
    required this.preview,
    this.selectedIds = const {},
    this.amountMinor = 0,
    this.method = CollectionMethod.cash,
    this.externalReference = '',
    this.step = CollectionStep.form,
    this.phase = CollectionPhase.idle,
    this.errorMessage,
    this.idempotencyKey,
    this.result,
  });

  final Set<String> selectedIds;
  final int amountMinor;
  final CollectionMethod method;
  final String externalReference;
  final CollectionStep step;
  final CollectionPhase phase;
  final String? errorMessage;
  final String? idempotencyKey;
  final CustomerCollectionResult? result;
  final CollectionPreview preview;

  bool get isDirty => amountMinor > 0 || selectedIds.isNotEmpty;

  @override
  List<Object?> get props => [
    selectedIds,
    amountMinor,
    method,
    externalReference,
    step,
    phase,
    errorMessage,
    idempotencyKey,
    result,
    preview,
  ];
}

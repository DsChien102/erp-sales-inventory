import 'package:equatable/equatable.dart';

/// Authoritative S21 available-actions flags from
/// [AvailablePostSaleActionsDto] — not inferred from lifecycle alone.
class SalesOrderActionsVm extends Equatable {
  const SalesOrderActionsVm({
    required this.canCancel,
    required this.canReturnExchange,
  });

  final bool canCancel;
  final bool canReturnExchange;

  SalesOrderActionsVm copyWith({
    bool? canCancel,
    bool? canReturnExchange,
  }) {
    return SalesOrderActionsVm(
      canCancel: canCancel ?? this.canCancel,
      canReturnExchange: canReturnExchange ?? this.canReturnExchange,
    );
  }

  @override
  List<Object?> get props => [canCancel, canReturnExchange];
}

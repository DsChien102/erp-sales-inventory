import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Soft reference to originating draft (not a cross-aggregate load).
final class SalesOrderDraftRef extends ValueObject {
  SalesOrderDraftRef({required this.draftId, required this.draftVersion});

  final String draftId;
  final int draftVersion;

  @override
  List<Object?> get props => [draftId, draftVersion];
}

import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Snapshot of external/internal blockers for cancellation precheck.
final class CancellationPrecheckSnapshot extends ValueObject {
  CancellationPrecheckSnapshot({
    required this.passed,
    required this.sourceOrderVersion,
    required this.sourceSettlementVersion,
    required this.netConfirmedCollectionMinor,
    this.blockerCodes = const [],
  });

  final bool passed;
  final int sourceOrderVersion;
  final int sourceSettlementVersion;
  final int netConfirmedCollectionMinor;
  final List<String> blockerCodes;

  bool get isConfirmable =>
      passed &&
      blockerCodes.isEmpty &&
      sourceOrderVersion > 0 &&
      sourceSettlementVersion > 0 &&
      netConfirmedCollectionMinor == 0;

  @override
  List<Object?> get props => [
    passed,
    sourceOrderVersion,
    sourceSettlementVersion,
    netConfirmedCollectionMinor,
    blockerCodes,
  ];
}

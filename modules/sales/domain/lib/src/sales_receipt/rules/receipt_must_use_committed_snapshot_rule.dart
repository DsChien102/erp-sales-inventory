import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ReceiptMustUseCommittedSnapshotRule implements IBusinessRule {
  const ReceiptMustUseCommittedSnapshotRule({
    required this.hasCommittedOrderId,
    required this.contentHash,
  });

  final bool hasCommittedOrderId;
  final String contentHash;

  @override
  bool isBroken() => !hasCommittedOrderId || contentHash.trim().isEmpty;

  @override
  String get message => 'Receipt must be generated from a committed sales order snapshot.';
}

import 'sales_blocker_dto.dart';

final class CancellationPrecheckDto {
  CancellationPrecheckDto({
    required this.allowed,
    required this.sourceVersion,
    required this.sourceSettlementVersion,
    required List<SalesBlockerDto> blockers,
  }) : blockers = List.unmodifiable(blockers);

  final bool allowed;
  final int sourceVersion;
  final int sourceSettlementVersion;
  final List<SalesBlockerDto> blockers;
}

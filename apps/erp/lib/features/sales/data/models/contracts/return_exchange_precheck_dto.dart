import 'sales_blocker_dto.dart';

final class ReturnExchangePrecheckDto {
  ReturnExchangePrecheckDto({
    required this.allowed,
    required this.sourceVersion,
    required List<SalesBlockerDto> blockers,
  }) : blockers = List.unmodifiable(blockers);

  final bool allowed;
  final int sourceVersion;
  final List<SalesBlockerDto> blockers;
}

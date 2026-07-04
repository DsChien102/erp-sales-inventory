import 'package:vet45_catalog_domain/domain.dart';

import 'readiness_blocker_dto.dart';

final class ReadinessSummaryDto {
  const ReadinessSummaryDto({
    required this.status,
    this.blockers = const [],
  });

  final ReadinessStatus status;
  final List<ReadinessBlockerDto> blockers;
}

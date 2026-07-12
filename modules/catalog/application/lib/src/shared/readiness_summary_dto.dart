import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/product_readiness/shared/readiness_blocker_dto.dart';

final class ReadinessSummaryDto {
  const ReadinessSummaryDto({
    required this.status,
    this.blockers = const [],
  });

  final ReadinessStatus status;
  final List<ReadinessBlockerDto> blockers;

  factory ReadinessSummaryDto.fromDomain(ProductReadiness readiness) {
    return ReadinessSummaryDto(
      status: readiness.status,
      blockers: readiness.blockers
          .map(
            (blocker) => ReadinessBlockerDto(
              code: blocker.code,
              message: blocker.message,
              group: blocker.group,
            ),
          )
          .toList(growable: false),
    );
  }
}

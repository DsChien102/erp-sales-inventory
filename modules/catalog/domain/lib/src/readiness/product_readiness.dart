import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'readiness_blocker.dart';
import 'readiness_status.dart';

final class ProductReadiness extends ValueObject {
  const ProductReadiness({
    required this.status,
    this.blockers = const [],
  });

  final ReadinessStatus status;
  final List<ReadinessBlocker> blockers;

  /// Seeds readiness after guided minimal create.
  factory ProductReadiness.seedFromCreate({
    required bool hasBaseUnit,
    required bool hasImages,
  }) {
    final blockers = <ReadinessBlocker>[
      if (!hasBaseUnit) ReadinessBlocker.missingBaseUnit(),
      if (!hasImages) ReadinessBlocker.missingImage(),
      ReadinessBlocker.missingPrice(),
    ];

    return ProductReadiness(
      status: blockers.isEmpty
          ? ReadinessStatus.readyToSell
          : ReadinessStatus.incomplete,
      blockers: List.unmodifiable(blockers),
    );
  }

  @override
  List<Object?> get props => [status, blockers];
}
